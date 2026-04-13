//package cn.bochk.pap.server.business.service;
//
//import cn.bochk.pap.server.business.dal.AssetTypeDo;
//import cn.bochk.pap.server.business.dal.TableSwitchLogDo;
//import cn.bochk.pap.server.business.mapper.AssetTypeMapper;
//import cn.bochk.pap.server.business.mapper.SecurityMasterMapper;
//import cn.bochk.pap.server.business.mapper.TableSwitchLogMapper;
//import com.alibaba.excel.util.StringUtils;
//import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
//import jakarta.annotation.PostConstruct;
//import jakarta.annotation.Resource;
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.context.annotation.Lazy;
//import org.springframework.data.redis.core.RedisTemplate;
//import org.springframework.stereotype.Service;
//import org.springframework.util.CollectionUtils;
//
//import java.util.*;
//import java.util.concurrent.TimeUnit;
//import java.util.stream.Collectors;
//
///**
// * SecurityMaster 缓存服务
// * 负责将 SECURITY_MASTER_* 表的数据加载到 Redis
// *
// * @author liuhb
// */
//@Service
//@Slf4j
//@Lazy
//public class SecurityMasterCacheService {
//
//    public static final String REDIS_KEY_MAPPING = "br_security_master:mapping";
//    public static final String REDIS_KEY_PREFIX_DATA = "br_security_master:data:";
//
//    @Resource
//    private AssetTypeMapper assetTypeMapper;
//
//    @Resource
//    private TableSwitchLogMapper tableSwitchLogMapper;
//
//    @Resource
//    private SecurityMasterMapper securityMasterMapper;
//
//    @Resource
//    private RedisTemplate<String, Object> redisTemplate;
//
//    @Resource
//    private BatchBusinessDateResultService batchBusinessDateResultService;
//
//
//    /**
//     * 从table_switch_log里面获取 <BR_SECURITY_MASTER_BND,BR_SECURITY_MASTER_BND_1> 的map
//     * 改为从 ASSET_TYPE 表读取配置
//     */
//    @PostConstruct
//    public void initCache() {
//        log.info("========== 开始加载 SecurityMaster 数据到 Redis ==========");
//        long startTime = System.currentTimeMillis();
//
//        try {
//            // 从table_switch_log 里获取数据map：<BR_SECURITY_MASTER_BND,BR_SECURITY_MASTER_BND_1>
//            LinkedHashMap<String, String> collect = getStringStringLinkedHashMap();
//            if (collect == null) {
//                log.error("get table_switch_log data is null");
//                return;
//            }
//
//
//            // 1. 从 ASSET_TYPE 表查询所有启用 BuyList 的配置
//            List<AssetTypeDo> assetTypeConfigs = assetTypeMapper.selectBuyListEnabledAssetTypes();
//
//            if (assetTypeConfigs == null || assetTypeConfigs.isEmpty()) {
//                log.error("ASSET_TYPE 表中没有启用 BuyList 的配置（BUY_LIST='Y'），跳过数据加载");
//                return;
//            }
//
//            log.info("从 ASSET_TYPE 表查询到 {} 条启用 BuyList 的配置", assetTypeConfigs.size());
//
//            // 2. 构建映射关系 Map: assetType → Set<fullTableName>（用于 Redis 存储）
//            Map<String, Set<String>> map = getAssetTypeFullTableNameMap(assetTypeConfigs, collect);
//
//            // 3. 获取资产类型对应的Map： assetType → [matchfield → [clientId1, clientId2]]
//            // 每条配置只查询对应的一张表，相同 assetType 的结果会合并
//            Map<String, List<Map<String, Object>>> extracted = getMultiAssetTypeClientIdMap(assetTypeConfigs, collect);
//
//
//            int totalAssetTypes = 0;
//            int totalRecords = 0;
//
//            // 构建 assetType -> matchField 的映射（取第一个配置的 matchField）
//            Map<String, String> assetTypeToMatchFieldMap = new HashMap<>();
//            for (AssetTypeDo config : assetTypeConfigs) {
//                String assetType = config.getAssetType();
//                if (!assetTypeToMatchFieldMap.containsKey(assetType)) {
//                    assetTypeToMatchFieldMap.put(assetType, config.getField());
//                }
//            }
//
//
//            clearAllCache();
//
//            // 3. 遍历已合并的数据（按 assetType 去重），存入 Redis
//            for (Map.Entry<String, List<Map<String, Object>>> entry : extracted.entrySet()) {
//                try {
//                    String assetType = entry.getKey();
//                    List<Map<String, Object>> dataList = entry.getValue();
//                    String matchField = assetTypeToMatchFieldMap.get(assetType);
//
//                    // 校验匹配字段
//                    if (matchField == null || matchField.trim().isEmpty()) {
//                        log.warn("配置缺少匹配字段: assetType={}", assetType);
//                        continue;
//                    }
//
//                    // 构建 Map<matchFieldValue, [CLIENT_ID1,CLIENT_ID2]>
//                    Map<String, Set<String>> dataMap = new HashMap<>();
//                    if (!CollectionUtils.isEmpty(dataList)) {
//                        for (Map<String, Object> row : dataList) {
//                            String matchFieldValue = (String) row.get("match_field_value");
//                            String clientId = (String) row.get("CLIENT_ID");
//
//                            if (matchFieldValue != null && clientId != null) {
//                                dataMap.computeIfAbsent(matchFieldValue.trim(), k -> new HashSet<>())
//                                        .add(clientId.trim());
//                            } else {
//                                log.error("---------matchFieldValue is null or clientId is null---------");
//                            }
//                        }
//                    }
//
//                    // 保存数据到 Redis: assetType → Map<匹配字段值, CLIENT_ID>（数据为空时也存入空 Map）
//                    String dataKey = REDIS_KEY_PREFIX_DATA + assetType.trim();
//                    redisTemplate.opsForHash().putAll(dataKey, dataMap);
//
//                    // 为数据缓存设置过期时间（1 小时）
//                    redisTemplate.expire(dataKey, 1, TimeUnit.HOURS);
//
//                    totalAssetTypes++;
//                    totalRecords += dataMap.size();
//
//                    if (!dataMap.isEmpty()) {
//                        log.info("✓ 资产类型 {} 数据加载成功，共 {} 条记录（matchField={}）",
//                                assetType, dataMap.size(), matchField);
//                    } else {
//                        log.warn("✓ 资产类型 {} 数据为空，已存入空缓存（matchField={}）",
//                                assetType, matchField);
//                    }
//                } catch (Exception e) {
//                    log.error("加载数据到 Redis 失败: assetType={}, 错误: {}",
//                            entry.getKey(), e.getMessage(), e);
//                }
//            }
//
//            // 6. 一次性保存所有映射关系到 Redis
//            if (!map.isEmpty()) {
//                redisTemplate.opsForHash().putAll(REDIS_KEY_MAPPING, map);
//                // 为映射关系缓存设置过期时间（1 小时）
//                redisTemplate.expire(REDIS_KEY_MAPPING, 1, TimeUnit.HOURS);
//                log.info("✓ 映射关系已保存到 Redis，共 {} 条映射", map.size());
//            }
//
//            long endTime = System.currentTimeMillis();
//            log.info("========== SecurityMaster 数据加载完成 ==========");
//            log.info("共查询 {} 张表，合并后 {} 个资产类型，总计 {} 条记录，耗时 {} ms",
//                    assetTypeConfigs.size(), totalAssetTypes, totalRecords, (endTime - startTime));
//
//        } catch (Exception e) {
//            log.error("SecurityMaster 数据加载失败", e);
//        }
//    }
//
//
//    /**
//     * 获取指定 assetType 的完整数据 Map
//     * 注意：由于 Redis 使用 JSON 序列化，Set 会被反序列化为 ArrayList，需要手动转换
//     *
//     * @param assetType 资产类型
//     * @return Map<productCode, Set<clientId>>
//     */
//    @SuppressWarnings("unchecked")
//    public Map<String, List<String>> getAssetTypeDataMap(String assetType) {
//        String dataKey = REDIS_KEY_PREFIX_DATA + assetType.trim();
//        Map<Object, Object> entries = redisTemplate.opsForHash().entries(dataKey);
//
//        if (CollectionUtils.isEmpty(entries)) {
//            initCache();
//        }
//        entries = redisTemplate.opsForHash().entries(dataKey);
//        // 直接强转
//        return (Map) entries;
//    }
//
//    private Map<String, List<Map<String, Object>>> getMultiAssetTypeClientIdMap(
//            List<AssetTypeDo> assetTypeConfigs,
//            LinkedHashMap<String, String> tableNameMapping) throws Exception {
//
//        Map<String, List<Map<String, Object>>> allDataMap = new HashMap<>();
//
//        // 统计信息
//        int totalQueryCount = 0;
//        int totalRecordCount = 0;
//        List<String> tablesWithData = new ArrayList<>();
//        List<String> tablesWithoutData = new ArrayList<>();
//        Map<String, Integer> tableRecordCountMap = new LinkedHashMap<>();
//
//        log.info("========== 开始查询 BR_SECURITY_MASTER 表数据 ==========");
//
//        // 遍历每条配置，每条配置只查询对应的一张表
//        for (AssetTypeDo config : assetTypeConfigs) {
//            try {
//                String assetType = config.getAssetType();
//                String matchField = config.getField();
//                String conditionSql = config.getConditionSql();
//
//                // 校验匹配字段
//                if (matchField == null || matchField.trim().isEmpty()) {
//                    log.warn("配置缺少匹配字段: assetType={}", assetType);
//                    continue;
//                }
//
//                // 根据该配置的 systemCode 直接获取对应的 fullTableName
//                String tableNameKey = config.getSecurityMasterTableName();
//                String fullTableName = tableNameMapping.get(tableNameKey);
//
//                if (fullTableName == null) {
//                    log.warn("无法获取表名: assetType={}, tableNameKey={}", assetType, tableNameKey);
//                    continue;
//                }
//
//                // 查询该配置对应的表数据（每条配置只查询一次）
//                List<Map<String, Object>> tempDataList;
//                try {
//                    tempDataList = securityMasterMapper.selectSecurityMasterData(
//                            fullTableName, matchField, conditionSql);
//                } catch (Exception queryEx) {
//                    log.error("查询表异常: assetType={}, 表名={}, conditionSql={}, 异常信息={}",
//                            assetType, fullTableName, conditionSql, queryEx.getMessage(), queryEx);
//                    throw queryEx;
//                }
//
//                // 统计查询次数和记录数
//                totalQueryCount++;
//                int recordCount = (tempDataList != null) ? tempDataList.size() : 0;
//                totalRecordCount += recordCount;
//                tableRecordCountMap.put(fullTableName, tableRecordCountMap.getOrDefault(fullTableName, 0) + recordCount);
//
//                // 记录有数据和无数据的表，并打印相应日志
//                if (recordCount > 0) {
//                    if (!tablesWithData.contains(fullTableName)) {
//                        tablesWithData.add(fullTableName);
//                    }
//                    log.info("查询表成功: assetType={}, 表名={}, conditionSql={}, 记录数={}",
//                            assetType, fullTableName, conditionSql, recordCount);
//                } else {
//                    if (!tablesWithoutData.contains(fullTableName) && !tablesWithData.contains(fullTableName)) {
//                        tablesWithoutData.add(fullTableName);
//                    }
//                    log.warn("查询数据为空: assetType={}, 表名={}, conditionSql={}",
//                            assetType, fullTableName, conditionSql);
//                }
//
//                // 相同 assetType 的数据进行合并（数据为空时也放入空数组）
//                if (allDataMap.containsKey(assetType)) {
//                    if (tempDataList != null && !tempDataList.isEmpty()) {
//                        allDataMap.get(assetType).addAll(tempDataList);
//                    }
//                } else {
//                    allDataMap.put(assetType, tempDataList != null ? new ArrayList<>(tempDataList) : new ArrayList<>());
//                }
//
//            } catch (Exception e) {
//                log.error("加载表数据失败: assetType={}, systemCode={}, 错误: {}",
//                        config.getAssetType(), config.getSystemCode(), e.getMessage(), e);
//                throw new Exception(e);
//            }
//        }
//
//        // 打印统计汇总日志
//        log.info("========== BR_SECURITY_MASTER 查询统计汇总 ==========");
//        log.info("总查询次数: {} 次", totalQueryCount);
//        log.info("总记录数: {} 条", totalRecordCount);
//        log.info("有数据的表 ({} 张): {}", tablesWithData.size(), tablesWithData);
//        log.info("无数据的表 ({} 张): {}", tablesWithoutData.size(), tablesWithoutData);
//        log.info("各表记录数明细: {}", tableRecordCountMap);
//        log.info("===================================================");
//
//        return allDataMap;
//    }
//
//    private Map<String, Set<String>> getAssetTypeFullTableNameMap(List<AssetTypeDo> assetTypeConfigs, LinkedHashMap<String, String> collect) {
//        Map<String, Set<String>> mapping = new HashMap<>();
//        for (AssetTypeDo config : assetTypeConfigs) {
//
//            String assetType = config.getAssetType();
//
//            // 4. 拼接表名：BR_SECURITY_MASTER_{SYSTEM_CODE}
//            String tableNameKey = config.getSecurityMasterTableName();
//            String fullTableName = collect.get(tableNameKey);
//
//            if (mapping.containsKey(assetType)) {
//                Set<String> strings = mapping.get(assetType);
//                strings.add(fullTableName);
//                mapping.put(assetType, strings);
//            } else {
//                Set<String> tableList = new HashSet<>();
//                tableList.add(fullTableName);
//                mapping.put(assetType, tableList);
//            }
//        }
//        return mapping;
//    }
//
//    private LinkedHashMap<String, String> getStringStringLinkedHashMap() {
//        // 从table_switch_log里获取表数据;
//        Date businessDate = getBusinessDate();
//
//        LambdaQueryWrapper<TableSwitchLogDo> objectLambdaQueryWrapper = new LambdaQueryWrapper<>();
//        objectLambdaQueryWrapper.eq(TableSwitchLogDo::getIsValid, "Y");
//        objectLambdaQueryWrapper.eq(TableSwitchLogDo::getBusinessDate, businessDate);
//        List<TableSwitchLogDo> tableSwitchLogDos = tableSwitchLogMapper.selectList(objectLambdaQueryWrapper);
//        if (CollectionUtils.isEmpty(tableSwitchLogDos)) {
//            log.info("从 tableSwitchLog 表查询到 {} 条启用 tableSwitchLog 的配置", tableSwitchLogDos.size());
//            return null;
//        }
//
//        // <表名无后缀为key，全表名为value>
//        // <BR_SECURITY_MASTER_BND,BR_SECURITY_MASTER_BND_1>
//        LinkedHashMap<String, String> collect = tableSwitchLogDos.stream().filter(item ->
//                        StringUtils.isNotBlank(item.getTargetTable()) &&
//                                StringUtils.isNotBlank(item.getTableSuffix())
//                )
//                .collect(Collectors.toMap(
//                        item -> item.getTargetTable().trim(),
//                        item -> item.getTargetTable().trim() + "_" + item.getTableSuffix().trim(),
//                        (oldValue, newValue) -> oldValue,
//                        LinkedHashMap::new
//                ));
//        return collect;
//    }
//
//    /**
//     * 获取表名（从 Redis 第一层缓存）
//     *
//     * @param assetType    资产类型
//     * @return 表名，例如 SECURITY_MASTER_BND_1
//     */
//    public Set<String> getTableName(String assetType) {
//        Set<String> tableNameList = (Set<String>) redisTemplate.opsForHash().get(REDIS_KEY_MAPPING, assetType);
//        if (!CollectionUtils.isEmpty(tableNameList)) {
//            return tableNameList;
//        }
//        // 如果缓存不存在（可能已过期），尝试重新加载一次缓存
//        log.info("找不到映射缓存，尝试重新加载 SecurityMaster 缓存...");
//        initCache();
//        Set<String> tableNameSet = (Set<String>) redisTemplate.opsForHash().get(REDIS_KEY_MAPPING, assetType);
//        return tableNameSet;
//    }
//
//    public Set<String> getClientIdSet(String assetType, String matchField) {
//        String dataKey = REDIS_KEY_PREFIX_DATA + assetType;
//
//        // 先检查 key 是否存在
//        Boolean keyExists = redisTemplate.hasKey(dataKey);
//
//        if (Boolean.TRUE.equals(keyExists)) {
//            // key 存在，获取数据
//            Set<String> clientIdSet = (Set<String>) redisTemplate.opsForHash().get(dataKey, matchField);
//            if (CollectionUtils.isEmpty(clientIdSet)) {
//                log.warn("assetType={} 的缓存存在，但 matchField={} 对应的数据为空", assetType, matchField);
//                return new HashSet<>();
//            }
//            log.info("获取 clientIdSet 成功: assetType={}, matchField={}, 数量={}", assetType, matchField, clientIdSet.size());
//            return clientIdSet;
//        }
//
//        // key 不存在，可能是缓存过期，尝试重新加载
//        log.info("assetType={} 的缓存不存在，尝试重新加载 SecurityMaster 缓存...", assetType);
//        initCache();
//
//        // 再次检查
//        keyExists = redisTemplate.hasKey(dataKey);
//        if (Boolean.TRUE.equals(keyExists)) {
//            Set<String> clientIdSet = (Set<String>) redisTemplate.opsForHash().get(dataKey, matchField);
//            if (CollectionUtils.isEmpty(clientIdSet)) {
//                log.warn("重新加载后，assetType={} 的缓存存在，但 matchField={} 对应的数据为空", assetType, matchField);
//                return new HashSet<>();
//            }
//            log.info("重新加载后获取 clientIdSet 成功: assetType={}, matchField={}, 数量={}", assetType, matchField, clientIdSet.size());
//            return clientIdSet;
//        }
//
//        log.error("重新加载后仍无法获取 assetType={} 的缓存", assetType);
//        return new HashSet<>();
//    }
//
//    /**
//     * 清除所有缓存（谨慎使用）
//     */
//    public void clearAllCache() {
//        log.warn("开始清除所有 SecurityMaster 缓存...");
//        // 删除映射关系缓存
//        redisTemplate.delete(REDIS_KEY_MAPPING);
//        // 删除所有数据缓存
//        redisTemplate.delete(redisTemplate.keys(REDIS_KEY_PREFIX_DATA + "*"));
//        log.info("SecurityMaster 缓存已清除");
//    }
//
//    private Date getBusinessDate() {
//        return batchBusinessDateResultService.getBusinessDate();
//    }
//}
