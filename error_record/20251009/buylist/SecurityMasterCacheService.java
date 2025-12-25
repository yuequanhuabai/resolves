package cn.bochk.pap.server.business.service;

import cn.bochk.pap.server.business.dal.AssetTypeDo;
import cn.bochk.pap.server.business.dal.TableSwitchLogDo;
import cn.bochk.pap.server.business.mapper.AssetTypeMapper;
import cn.bochk.pap.server.business.mapper.SecurityMasterMapper;
import cn.bochk.pap.server.business.mapper.TableSwitchLogMapper;
import com.alibaba.excel.util.StringUtils;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Lazy;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

/**
 * SecurityMaster 缓存服务
 * 负责将 SECURITY_MASTER_* 表的数据加载到 Redis
 *
 * @author liuhb
 */
@Service
@Slf4j
@Lazy
public class SecurityMasterCacheService {

    public static final String REDIS_KEY_MAPPING = "security_master:mapping";
    public static final String REDIS_KEY_PREFIX_DATA = "security_master:data:";

    @Resource
    private AssetTypeMapper assetTypeMapper;

    @Resource
    private TableSwitchLogMapper tableSwitchLogMapper;

    @Resource
    private SecurityMasterMapper securityMasterMapper;

    @Resource
    private RedisTemplate<String, Object> redisTemplate;

    @Resource
    private BatchBusinessDateResultService batchBusinessDateResultService;

    /**
     * 系统启动时全量加载 SECURITY_MASTER 数据到 Redis
     * 改为从 ASSET_TYPE 表读取配置
     */
    @PostConstruct
    public void initCache() {
        log.info("========== 开始加载 SecurityMaster 数据到 Redis ==========");
        long startTime = System.currentTimeMillis();

        try {
            // 0. 启动时先清空所有缓存，确保数据一致性
            clearAllCacheOnStartup();

            // 从table_switch_log里获取表数据;
            Date businessDate = getBusinessDate();

            LambdaQueryWrapper<TableSwitchLogDo> objectLambdaQueryWrapper = new LambdaQueryWrapper<>();
            objectLambdaQueryWrapper.eq(TableSwitchLogDo::getIsValid, "Y");
            objectLambdaQueryWrapper.eq(TableSwitchLogDo::getBusinessDate, businessDate);
            List<TableSwitchLogDo> tableSwitchLogDos = tableSwitchLogMapper.selectList(objectLambdaQueryWrapper);
            if (CollectionUtils.isEmpty(tableSwitchLogDos)) {
                log.info("从 tableSwitchLog 表查询到 {} 条启用 tableSwitchLog 的配置", tableSwitchLogDos.size());
                return;
            }

            // <表名无后缀为key，全表名为value>
            LinkedHashMap<String, String> collect = tableSwitchLogDos.stream().filter(item ->
                            StringUtils.isNotBlank(item.getTargetTable()) &&
                                    StringUtils.isNotBlank(item.getTableSuffix())
                    )
                    .collect(Collectors.toMap(
                            item -> item.getTargetTable().trim(),
                            item -> item.getTargetTable().trim() + "_" + item.getTableSuffix().trim(),
                            (oldValue, newValue) -> oldValue,
                            LinkedHashMap::new
                    ));


            // 1. 从 ASSET_TYPE 表查询所有启用 BuyList 的配置
            List<AssetTypeDo> assetTypeConfigs = assetTypeMapper.selectBuyListEnabledAssetTypes();

            if (assetTypeConfigs == null || assetTypeConfigs.isEmpty()) {
                log.warn("ASSET_TYPE 表中没有启用 BuyList 的配置（BUY_LIST='Y'），跳过数据加载");
                return;
            }

            log.info("从 ASSET_TYPE 表查询到 {} 条启用 BuyList 的配置", assetTypeConfigs.size());

            int totalTables = 0;
            int totalRecords = 0;

            // 2. 构建映射关系 Map: {businessType}:{assetType} → tableName
            Map<String, String> mappingMap = new HashMap<>();

            // 3. 遍历每条配置，加载对应的 SECURITY_MASTER 表数据
            for (AssetTypeDo config : assetTypeConfigs) {
                try {
                    String assetType = config.getAssetType();
                    String systemCode = config.getSystemCode();
                    String customerTierId = config.getCustomerTierId();
                    String matchField = config.getField();

                    // 4. 拼接表名：SECURITY_MASTER_{SYSTEM_CODE}_{CUSTOMER_TIER_ID}
                    String tableName = config.getSecurityMasterTableName();
                    String fullTableName = collect.get(tableName);

                    // 5. 添加到映射 Map: {customerTierId}:{assetType} → fullTableName
                    String mappingField = customerTierId + ":" + assetType;
                    mappingMap.put(mappingField, fullTableName);

                    // 5. 校验匹配字段
                    if (matchField == null || matchField.trim().isEmpty()) {
                        log.warn("配置缺少匹配字段: assetType={}, systemCode={}, 跳过表 {}",
                                assetType, systemCode, fullTableName);
                        continue;
                    }

                    // 6. 查询该表的数据
                    List<Map<String, Object>> dataList = securityMasterMapper.selectSecurityMasterData(fullTableName, matchField);

                    // 7. 构建 Map<匹配字段值, CLIENT_ID>
                    Map<String, String> dataMap = new HashMap<>();
                    for (Map<String, Object> row : dataList) {
                        String matchFieldValue = (String) row.get("match_field_value");
                        String clientId = (String) row.get("CLIENT_ID");

                        if (matchFieldValue != null && clientId != null) {
                            dataMap.put(matchFieldValue, clientId);
                        }
                    }

                    // 8. 保存第二层数据到 Redis: tableName → Map<匹配字段值, CLIENT_ID>
                    if (!dataMap.isEmpty()) {
                        String dataKey = REDIS_KEY_PREFIX_DATA + fullTableName;
                        redisTemplate.opsForHash().putAll(dataKey, dataMap);
                        // 为数据缓存设置过期时间（1 小时）
                        redisTemplate.expire(dataKey, 1, TimeUnit.HOURS);

                        totalTables++;
                        totalRecords += dataMap.size();

                        log.info("✓ 表 {} 数据加载成功，共 {} 条记录（assetType={}, matchField={}）",
                                fullTableName, dataMap.size(), assetType, matchField);
                    } else {
                        log.warn("表 {} 没有数据或数据为空（assetType={}, matchField={}）",
                                fullTableName, assetType, matchField);
                    }

                } catch (Exception e) {
                    log.error("加载表数据失败: assetType={}, systemCode={}, 错误: {}",
                            config.getAssetType(), config.getSystemCode(), e.getMessage(), e);
                }
            }

            // 6. 一次性保存所有映射关系到 Redis
            if (!mappingMap.isEmpty()) {
                redisTemplate.opsForHash().putAll(REDIS_KEY_MAPPING, mappingMap);
                // 为映射关系缓存设置过期时间（1 小时）
                redisTemplate.expire(REDIS_KEY_MAPPING, 1, TimeUnit.HOURS);
                log.info("✓ 映射关系已保存到 Redis，共 {} 条映射", mappingMap.size());
            }

            long endTime = System.currentTimeMillis();
            log.info("========== SecurityMaster 数据加载完成 ==========");
            log.info("共加载 {} 张表，总计 {} 条记录，耗时 {} ms", totalTables, totalRecords, (endTime - startTime));

        } catch (Exception e) {
            log.error("SecurityMaster 数据加载失败", e);
        }
    }

    /**
     * 获取表名（从 Redis 第一层缓存）
     *
     * @param assetType    资产类型
     * @param businessType 业务类型（1=Private Banking, 2=Retail Banking）
     * @return 表名，例如 SECURITY_MASTER_BND_1
     */
    public String getTableName(String assetType, Integer businessType) {
        String mappingField = businessType + ":" + assetType;
        Object tableName = redisTemplate.opsForHash().get(REDIS_KEY_MAPPING, mappingField);
        if (tableName != null) {
            return (String) tableName;
        }
        // 如果缓存不存在（可能已过期），尝试重新加载一次缓存
        log.info("找不到映射缓存，尝试重新加载 SecurityMaster 缓存...");
        refreshCache();
        tableName = redisTemplate.opsForHash().get(REDIS_KEY_MAPPING, mappingField);
        return tableName != null ? (String) tableName : null;
    }

    /**
     * 获取 CLIENT_ID（从 Redis 第二层缓存）
     *
     * @param tableName   表名
     * @param productCode 产品代码（对应 ISIN、TICKER 等字段的值）
     * @return CLIENT_ID
     */
    public String getClientId(String tableName, String productCode) {
        String dataKey = REDIS_KEY_PREFIX_DATA + tableName;
        Object clientId = redisTemplate.opsForHash().get(dataKey, productCode);
        if (clientId != null) {
            return (String) clientId;
        }
        // 数据缓存可能已过期，尝试重新加载一次缓存
        log.info("找不到数据缓存，尝试重新加载 SecurityMaster 缓存...");
        refreshCache();
        clientId = redisTemplate.opsForHash().get(dataKey, productCode);
        return clientId != null ? (String) clientId : null;
    }

    /**
     * 根据 assetType、businessType 和 productCode 直接查询 CLIENT_ID
     *
     * @param assetType    资产类型
     * @param businessType 业务类型
     * @param productCode  产品代码
     * @return CLIENT_ID，如果找不到返回 null
     */
    public String getClientId(String assetType, Integer businessType, String productCode) {
        // 1. 先获取表名
        String tableName = getTableName(assetType, businessType);
        if (tableName == null) {
            log.debug("找不到 assetType={}, businessType={} 对应的表名", assetType, businessType);
            return null;
        }

        // 2. 再获取 clientId
        return getClientId(tableName, productCode);
    }

    /**
     * 清除所有缓存（谨慎使用）
     */
    public void clearAllCache() {
        log.warn("开始清除所有 SecurityMaster 缓存...");
        // 删除映射关系缓存
        redisTemplate.delete(REDIS_KEY_MAPPING);
        // 删除所有数据缓存
        redisTemplate.delete(redisTemplate.keys(REDIS_KEY_PREFIX_DATA + "*"));
        log.info("SecurityMaster 缓存已清除");
    }

    /**
     * 手动刷新缓存
     */
    public void refreshCache() {
        log.info("手动刷新 SecurityMaster 缓存...");
        clearAllCache();
        initCache();
    }

    /**
     * 启动时清空缓存（私有方法）
     * 确保每次启动时 Redis 数据与数据库完全一致
     */
    private void clearAllCacheOnStartup() {
        log.info("清空旧的 SecurityMaster 缓存数据...");

        try {
            // 1. 删除映射关系缓存 security_master:mapping
            Boolean deletedMapping = redisTemplate.delete(REDIS_KEY_MAPPING);
            log.info("  ✓ 映射关系缓存: {}", deletedMapping != null && deletedMapping ? "已删除" : "不存在或已清空");

            // 2. 删除所有数据缓存 security_master:data:*
            Set<String> dataKeys = redisTemplate.keys(REDIS_KEY_PREFIX_DATA + "*");
            if (dataKeys != null && !dataKeys.isEmpty()) {
                Long deletedCount = redisTemplate.delete(dataKeys);
                log.info("  ✓ 数据缓存: 已删除 {} 个key", deletedCount);
            } else {
                log.info("  ✓ 数据缓存: 无旧数据");
            }

            log.info("缓存清空完成，开始重新加载数据...");

        } catch (Exception e) {
            log.warn("清空缓存时发生异常（继续加载）: {}", e.getMessage());
            // 不抛出异常，继续执行加载逻辑
        }
    }

    private Date getBusinessDate() {
        return batchBusinessDateResultService.getBuinessDate();
    }
}
