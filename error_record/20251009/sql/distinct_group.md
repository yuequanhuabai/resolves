# 联表查询去重方案：DISTINCT vs GROUP BY

## 问题背景

在 `BuyListMapper.selectPageWithDetails` 方法中，使用 LEFT JOIN 联表查询时，如果主表（`buy_list`）与明细表（`buy_list_details`）是一对多关系，会导致主表数据重复的问题。

### 示例场景

假设数据如下：

**buy_list 表（主表）**
| id | name | business_type | status |
|----|------|---------------|--------|
| 1  | List A | 1 | 1 |
| 2  | List B | 2 | 1 |

**buy_list_details 表（明细表）**
| id | buy_list_id | asset_type | product_code |
|----|-------------|------------|--------------|
| 1  | 1           | 股票       | 600000       |
| 2  | 1           | 债券       | 123456       |
| 3  | 1           | 基金       | 000001       |
| 4  | 2           | 股票       | 600001       |

### 当前查询的问题

使用 LEFT JOIN 查询时，结果会是：

```
buy_list.id=1, name="List A", asset_type="股票"
buy_list.id=1, name="List A", asset_type="债券"    ← 主表数据重复
buy_list.id=1, name="List A", asset_type="基金"    ← 主表数据重复
buy_list.id=2, name="List B", asset_type="股票"
```

**导致的问题：**
1. 分页不准确（1 条 buy_list 被计为 3 条）
2. 总记录数错误（应该是 2 条，实际返回 4）
3. 前端需要额外处理重复数据

---

## 解决方案一：使用 DISTINCT 去重

### 原理说明

`DISTINCT` 关键字会对查询结果进行去重，保留唯一的记录。在 MyBatis Plus Join 中，使用 `.distinct()` 方法。

### 完整代码示例

```java
@Mapper
public interface BuyListMapper extends BaseMapperX<BuyListDO> {

    /**
     * 方案一：使用 DISTINCT 去重
     */
    default PageResult<BuyListRespVO> selectPageWithDetails(BuyListReqVO reqVO) {
        // 使用 MPJLambdaWrapper 实现联表查询
        MPJLambdaWrapper<BuyListDO> wrapper = new MPJLambdaWrapper<BuyListDO>()
                // 关键：添加 DISTINCT 去重
                .distinct()
                // 只查询主表字段，避免明细表字段影响去重
                .selectAll(BuyListDO.class)
                // 主表条件
                .eqIfExists(BuyListDO::getBusinessType, reqVO.getBusinessType())
                // LEFT JOIN 明细表
                .leftJoin(BuyListDetailsDo.class,
                         BuyListDetailsDo::getBuyListId,
                         BuyListDO::getId);

        // 添加明细表条件（如果需要按明细表字段筛选）
        if (reqVO.getAssetType() != null) {
            wrapper.eq(BuyListDetailsDo::getAssetType, reqVO.getAssetType());
        }

        // 添加主表条件
        if (reqVO.getStatus() != null) {
            wrapper.eq(BuyListDO::getStatus, reqVO.getStatus());
        }
        if (reqVO.getMaker() != null) {
            wrapper.eq(BuyListDO::getMaker, reqVO.getMaker());
        }
        if (reqVO.getChecker() != null) {
            wrapper.eq(BuyListDO::getChecker, reqVO.getChecker());
        }

        wrapper.eq(BuyListDO::getDelFlag, 0)
               .orderByDesc(BuyListDO::getValidStartDatetime);

        // 执行联表查询分页
        Page<BuyListDO> page = new Page<>(reqVO.getPageNo(), reqVO.getPageSize());
        IPage<BuyListDO> result = selectJoinPage(page, BuyListDO.class, wrapper);

        // 转换结果
        return new PageResult<>(
                result.getRecords().stream()
                        .map(this::convertToRespVO)
                        .collect(java.util.stream.Collectors.toList()),
                result.getTotal()
        );
    }

    default BuyListRespVO convertToRespVO(BuyListDO buyListDO) {
        return BeanUtils.toBean(buyListDO, BuyListRespVO.class);
    }
}
```

### 生成的 SQL

```sql
SELECT DISTINCT buy_list.*
FROM buy_list
LEFT JOIN buy_list_details
  ON buy_list_details.buy_list_id = buy_list.id
WHERE buy_list.business_type = ?
  AND buy_list_details.asset_type = ?
  AND buy_list.status = ?
  AND buy_list.del_flag = 0
ORDER BY buy_list.valid_start_datetime DESC
LIMIT ?, ?
```

### DISTINCT 的工作原理

1. **去重依据**：比较 SELECT 子句中的**所有字段**
2. **比较过程**：逐行比较，如果所有字段值都相同，则去重
3. **保留规则**：保留第一条遇到的记录

### 使用 DISTINCT 的注意事项

#### ✅ 优点
1. **语法简单**：只需添加 `.distinct()` 即可
2. **适用场景**：只查询主表字段时效果最好
3. **自动去重**：数据库层面自动处理，无需应用层处理

#### ⚠️ 缺点与限制

**1. 性能问题**
```java
// DISTINCT 需要对结果集进行全量比较
// 数据量大时可能影响性能
.distinct()  // 可能触发 filesort 或临时表
```

**2. 查询字段限制**
```java
// ❌ 错误：查询了明细表字段，DISTINCT 会失效
.selectAll(BuyListDO.class)
.select(BuyListDetailsDo::getAssetType)  // 明细表字段会导致无法去重
.distinct()

// ✅ 正确：只查询主表字段
.selectAll(BuyListDO.class)
.distinct()
```

**为什么？** 因为不同的明细记录 `asset_type` 不同，DISTINCT 会认为这是不同的记录。

**3. ORDER BY 字段限制**
```sql
-- ❌ 某些数据库（如 PostgreSQL）可能报错
SELECT DISTINCT buy_list.*
FROM buy_list
LEFT JOIN buy_list_details ON ...
ORDER BY buy_list_details.asset_type  -- 排序字段不在 SELECT 中
```

**4. 与 COUNT(*) 的问题**
```sql
-- DISTINCT 会影响总记录数的计算
-- MyBatis Plus 分页查询会自动执行 COUNT，可能需要特殊处理
SELECT COUNT(DISTINCT buy_list.id) FROM ...  -- 正确的 COUNT 方式
```

#### 💡 最佳实践

```java
// 推荐写法：明确指定主表主键，确保去重准确
MPJLambdaWrapper<BuyListDO> wrapper = new MPJLambdaWrapper<BuyListDO>()
    .distinct()
    // 明确查询主表所有字段
    .selectAll(BuyListDO.class)
    // 不要 select 明细表的字段
    .leftJoin(BuyListDetailsDo.class,
             BuyListDetailsDo::getBuyListId,
             BuyListDO::getId)
    // 明细表字段只用于 WHERE 条件
    .eq(BuyListDetailsDo::getAssetType, "股票");
```

---

## 解决方案二：使用 GROUP BY 分组

### 原理说明

`GROUP BY` 按指定字段分组，每组只返回一条记录。通过对主表主键分组，可以有效去重并支持聚合查询。

### 完整代码示例

```java
@Mapper
public interface BuyListMapper extends BaseMapperX<BuyListDO> {

    /**
     * 方案二：使用 GROUP BY 分组去重
     */
    default PageResult<BuyListRespVO> selectPageWithDetails(BuyListReqVO reqVO) {
        // 使用 MPJLambdaWrapper 实现联表查询
        MPJLambdaWrapper<BuyListDO> wrapper = new MPJLambdaWrapper<BuyListDO>()
                // 查询主表所有字段
                .selectAll(BuyListDO.class)
                // 可选：查询明细表的聚合数据
                .selectCount(BuyListDetailsDo::getId, "details_count")  // 统计明细数量
                // 主表条件
                .eqIfExists(BuyListDO::getBusinessType, reqVO.getBusinessType())
                // LEFT JOIN 明细表
                .leftJoin(BuyListDetailsDo.class,
                         BuyListDetailsDo::getBuyListId,
                         BuyListDO::getId);

        // 添加明细表条件
        if (reqVO.getAssetType() != null) {
            wrapper.eq(BuyListDetailsDo::getAssetType, reqVO.getAssetType());
        }

        // 添加主表条件
        if (reqVO.getStatus() != null) {
            wrapper.eq(BuyListDO::getStatus, reqVO.getStatus());
        }
        if (reqVO.getMaker() != null) {
            wrapper.eq(BuyListDO::getMaker, reqVO.getMaker());
        }
        if (reqVO.getChecker() != null) {
            wrapper.eq(BuyListDO::getChecker, reqVO.getChecker());
        }

        wrapper.eq(BuyListDO::getDelFlag, 0)
               // 关键：按主表主键分组
               .groupBy(BuyListDO::getId)
               // ORDER BY 必须在 GROUP BY 之后
               .orderByDesc(BuyListDO::getValidStartDatetime);

        // 执行联表查询分页
        Page<BuyListDO> page = new Page<>(reqVO.getPageNo(), reqVO.getPageSize());
        IPage<BuyListDO> result = selectJoinPage(page, BuyListDO.class, wrapper);

        // 转换结果
        return new PageResult<>(
                result.getRecords().stream()
                        .map(this::convertToRespVO)
                        .collect(java.util.stream.Collectors.toList()),
                result.getTotal()
        );
    }

    default BuyListRespVO convertToRespVO(BuyListDO buyListDO) {
        return BeanUtils.toBean(buyListDO, BuyListRespVO.class);
    }
}
```

### 生成的 SQL

```sql
SELECT buy_list.*, COUNT(buy_list_details.id) as details_count
FROM 
    
    buy_list
LEFT JOIN buy_list_details
  ON buy_list_details.buy_list_id = buy_list.id
WHERE buy_list.business_type = ?
  AND buy_list_details.asset_type = ?
  AND buy_list.status = ?
  AND buy_list.del_flag = 0

GROUP BY buy_list.id
ORDER BY buy_list.valid_start_datetime DESC
LIMIT ?, ?
```

### GROUP BY 的工作原理

1. **分组依据**：按 `GROUP BY` 指定的字段分组
2. **每组一条**：每组只返回一条记录
3. **聚合支持**：可以使用聚合函数（COUNT、SUM、MAX 等）

### 使用 GROUP BY 的注意事项

#### ✅ 优点

1. **语义清晰**：明确表示"按主键分组"
2. **支持聚合**：可以统计每个主表记录关联的明细数量
3. **性能稳定**：通常比 DISTINCT 性能更好（有索引时）
4. **兼容性好**：各数据库支持良好

#### ⚠️ 缺点与限制

**1. SQL MODE 限制（MySQL 5.7+ 的坑）**

MySQL 5.7+ 默认启用了 `ONLY_FULL_GROUP_BY` 模式，要求：
> SELECT 子句中的非聚合字段必须出现在 GROUP BY 中

```sql
-- ❌ MySQL 5.7+ 会报错
SELECT buy_list.id, buy_list.name, buy_list.status
FROM buy_list
GROUP BY buy_list.id  -- name 和 status 没在 GROUP BY 中
-- Error: Expression #2 of SELECT list is not in GROUP BY clause

-- ✅ 正确写法（方案1）：所有非聚合字段都加入 GROUP BY
GROUP BY buy_list.id, buy_list.name, buy_list.status, ...

-- ✅ 正确写法（方案2）：使用 ANY_VALUE
SELECT buy_list.id,
       ANY_VALUE(buy_list.name) as name,
       ANY_VALUE(buy_list.status) as status
FROM buy_list
GROUP BY buy_list.id
```

**在 MyBatis Plus Join 中的解决方案：**

```java
// 方案1：GROUP BY 所有主表字段（推荐）
wrapper.groupBy(BuyListDO::getId,
                BuyListDO::getName,
                BuyListDO::getBusinessType,
                BuyListDO::getStatus,
                BuyListDO::getMaker,
                BuyListDO::getChecker,
                BuyListDO::getMakerDatetime,
                BuyListDO::getCheckerDatetime,
                BuyListDO::getRecordVersion,
                BuyListDO::getValidStartDatetime,
                BuyListDO::getValidEndDatetime,
                BuyListDO::getDelFlag,
                BuyListDO::getSystemVersion,
                BuyListDO::getProcessInstanceId);

// 方案2：只 GROUP BY 主键（需要关闭 ONLY_FULL_GROUP_BY）
wrapper.groupBy(BuyListDO::getId);
```

**如何关闭 ONLY_FULL_GROUP_BY？**

```yaml
# application.yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/db?sessionVariables=sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
```

或者在数据库配置：
```sql
-- 临时关闭（当前会话）
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- 永久关闭（修改 my.cnf）
[mysqld]
sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
```

**2. 查询字段限制**

```java
// ❌ GROUP BY 后不能直接查询明细表的非聚合字段
wrapper.selectAll(BuyListDO.class)
       .select(BuyListDetailsDo::getAssetType)  // 错误！明细表字段不确定
       .groupBy(BuyListDO::getId);

// ✅ 只能查询明细表的聚合值
wrapper.selectAll(BuyListDO.class)
       .selectCount(BuyListDetailsDo::getId, "details_count")
       .selectMax(BuyListDetailsDo::getAssetType, "max_asset_type")
       .groupBy(BuyListDO::getId);
```

**3. 性能考虑**

```sql
-- GROUP BY 需要索引支持，否则会很慢
-- 确保 buy_list.id 有索引（主键自动有）
CREATE INDEX idx_buy_list_id ON buy_list(id);

-- 如果 GROUP BY 多个字段，建议创建联合索引
CREATE INDEX idx_group ON buy_list(id, valid_start_datetime);
```

#### 💡 最佳实践

**推荐写法：明确分组字段**

```java
MPJLambdaWrapper<BuyListDO> wrapper = new MPJLambdaWrapper<BuyListDO>()
    .selectAll(BuyListDO.class)
    // 统计每个 buy_list 关联的明细数量
    .selectCount(BuyListDetailsDo::getId, "detailsCount")
    .leftJoin(BuyListDetailsDo.class,
             BuyListDetailsDo::getBuyListId,
             BuyListDO::getId)
    .eq(BuyListDetailsDo::getAssetType, "股票")
    // 关键：按主键分组
    .groupBy(BuyListDO::getId)
    .orderByDesc(BuyListDO::getValidStartDatetime);
```

**如果需要统计信息，GROUP BY 是最佳选择：**

```java
// 查询 buy_list 及其关联的明细数量
wrapper.selectAll(BuyListDO.class)
       .selectCount(BuyListDetailsDo::getId, "detailsCount")
       .selectSum(BuyListDetailsDo::getAmount, "totalAmount")  // 假设有金额字段
       .groupBy(BuyListDO::getId);

// 在 RespVO 中接收聚合数据
@Data
public class BuyListRespVO {
    private String id;
    private String name;
    // ... 其他主表字段

    @TableField(exist = false)  // 非数据库字段
    private Long detailsCount;  // 明细数量

    @TableField(exist = false)
    private BigDecimal totalAmount;  // 总金额
}
```

---

## 方案对比总结

| 对比项 | DISTINCT | GROUP BY |
|--------|----------|----------|
| **语法复杂度** | 简单，一行代码 | 稍复杂，需要指定分组字段 |
| **性能** | 中等（大数据量可能慢） | 较好（有索引时） |
| **去重原理** | 比较所有 SELECT 字段 | 按指定字段分组 |
| **查询字段限制** | 不能查询明细表字段 | 不能查询明细表非聚合字段 |
| **聚合支持** | ❌ 不支持 | ✅ 支持 COUNT、SUM 等 |
| **MySQL 兼容性** | ✅ 无特殊要求 | ⚠️ 需要处理 ONLY_FULL_GROUP_BY |
| **适用场景** | 只查询主表，无需统计 | 需要统计明细数量/金额 |
| **推荐指数** | ⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## 完整代码示例对比

### DISTINCT 完整方案

```java
@Mapper
public interface BuyListMapper extends BaseMapperX<BuyListDO> {

    default PageResult<BuyListRespVO> selectPageWithDetails(BuyListReqVO reqVO) {
        MPJLambdaWrapper<BuyListDO> wrapper = new MPJLambdaWrapper<BuyListDO>()
                .distinct()  // 🔑 关键点
                .selectAll(BuyListDO.class)
                .eqIfExists(BuyListDO::getBusinessType, reqVO.getBusinessType())
                .leftJoin(BuyListDetailsDo.class,
                         BuyListDetailsDo::getBuyListId,
                         BuyListDO::getId);

        if (reqVO.getAssetType() != null) {
            wrapper.eq(BuyListDetailsDo::getAssetType, reqVO.getAssetType());
        }
        if (reqVO.getStatus() != null) {
            wrapper.eq(BuyListDO::getStatus, reqVO.getStatus());
        }
        if (reqVO.getMaker() != null) {
            wrapper.eq(BuyListDO::getMaker, reqVO.getMaker());
        }
        if (reqVO.getChecker() != null) {
            wrapper.eq(BuyListDO::getChecker, reqVO.getChecker());
        }

        wrapper.eq(BuyListDO::getDelFlag, 0)
               .orderByDesc(BuyListDO::getValidStartDatetime);

        Page<BuyListDO> page = new Page<>(reqVO.getPageNo(), reqVO.getPageSize());
        IPage<BuyListDO> result = selectJoinPage(page, BuyListDO.class, wrapper);

        return new PageResult<>(
                result.getRecords().stream()
                        .map(this::convertToRespVO)
                        .collect(java.util.stream.Collectors.toList()),
                result.getTotal()
        );
    }

    default BuyListRespVO convertToRespVO(BuyListDO buyListDO) {
        return BeanUtils.toBean(buyListDO, BuyListRespVO.class);
    }
}
```

### GROUP BY 完整方案（推荐）

```java
@Mapper
public interface BuyListMapper extends BaseMapperX<BuyListDO> {

    default PageResult<BuyListRespVO> selectPageWithDetails(BuyListReqVO reqVO) {
        MPJLambdaWrapper<BuyListDO> wrapper = new MPJLambdaWrapper<BuyListDO>()
                .selectAll(BuyListDO.class)
                // 统计明细数量（可选）
                .selectCount(BuyListDetailsDo::getId, "detailsCount")
                .eqIfExists(BuyListDO::getBusinessType, reqVO.getBusinessType())
                .leftJoin(BuyListDetailsDo.class,
                         BuyListDetailsDo::getBuyListId,
                         BuyListDO::getId);

        if (reqVO.getAssetType() != null) {
            wrapper.eq(BuyListDetailsDo::getAssetType, reqVO.getAssetType());
        }
        if (reqVO.getStatus() != null) {
            wrapper.eq(BuyListDO::getStatus, reqVO.getStatus());
        }
        if (reqVO.getMaker() != null) {
            wrapper.eq(BuyListDO::getMaker, reqVO.getMaker());
        }
        if (reqVO.getChecker() != null) {
            wrapper.eq(BuyListDO::getChecker, reqVO.getChecker());
        }

        wrapper.eq(BuyListDO::getDelFlag, 0)
               .groupBy(BuyListDO::getId)  // 🔑 关键点
               .orderByDesc(BuyListDO::getValidStartDatetime);

        Page<BuyListDO> page = new Page<>(reqVO.getPageNo(), reqVO.getPageSize());
        IPage<BuyListDO> result = selectJoinPage(page, BuyListDO.class, wrapper);

        return new PageResult<>(
                result.getRecords().stream()
                        .map(this::convertToRespVO)
                        .collect(java.util.stream.Collectors.toList()),
                result.getTotal()
        );
    }

    default BuyListRespVO convertToRespVO(BuyListDO buyListDO) {
        return BeanUtils.toBean(buyListDO, BuyListRespVO.class);
    }
}
```

---

## 推荐方案

### 场景 1：只查询主表数据，不需要统计
✅ **推荐使用 DISTINCT**
- 代码简洁
- 性能足够
- 无需处理 SQL MODE

### 场景 2：需要统计明细数量或聚合数据
✅ **必须使用 GROUP BY**
- 支持 COUNT、SUM、AVG 等聚合函数
- 语义更清晰
- 性能更好（有索引时）

### 场景 3：数据量很大（百万级以上）
✅ **建议避免联表查询**
- 改用单表查询 + 应用层组装
- 使用缓存减少数据库压力
- 考虑数据库读写分离

---

## 最佳实践建议

### 1. 优先考虑单表查询

```java
// 不推荐：复杂联表查询
leftJoin(...).leftJoin(...).leftJoin(...)

// 推荐：单表查询 + Service 层组装
public PageResult<BuyListRespVO> getListPageWithDetails(BuyListReqVO reqVO) {
    // 1. 查询主表分页
    PageResult<BuyListDO> pageResult = buyListMapper.selectPage(reqVO);

    // 2. 提取主表 ID
    List<String> ids = pageResult.getList().stream()
        .map(BuyListDO::getId)
        .collect(Collectors.toList());

    // 3. 批量查询明细表
    List<BuyListDetailsDo> details = detailsMapper.selectByBuyListIds(ids);

    // 4. 组装数据
    Map<String, List<BuyListDetailsDo>> detailsMap = details.stream()
        .collect(Collectors.groupingBy(BuyListDetailsDo::getBuyListId));

    // 5. 转换为 VO
    List<BuyListRespVO> respList = pageResult.getList().stream()
        .map(buyList -> {
            BuyListRespVO vo = BeanUtils.toBean(buyList, BuyListRespVO.class);
            vo.setDetails(detailsMap.get(buyList.getId()));
            return vo;
        })
        .collect(Collectors.toList());

    return new PageResult<>(respList, pageResult.getTotal());
}
```

### 2. 确保索引优化

```sql
-- 主表主键索引（自动创建）
PRIMARY KEY (id)

-- 明细表外键索引
CREATE INDEX idx_buy_list_id ON buy_list_details(buy_list_id);

-- 常用查询字段索引
CREATE INDEX idx_status_maker ON buy_list(status, maker);
CREATE INDEX idx_asset_type ON buy_list_details(asset_type);
```

### 3. 监控 SQL 性能

```yaml
# application.yaml - 开启 SQL 日志
mybatis-plus:
  configuration:
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl

# 生产环境使用慢查询日志
spring:
  datasource:
    hikari:
      leak-detection-threshold: 60000  # 连接泄漏检测
```

### 4. 使用 EXPLAIN 分析查询

```sql
EXPLAIN SELECT DISTINCT buy_list.*
FROM buy_list
LEFT JOIN buy_list_details ON ...
WHERE ...;

-- 关注：
-- 1. type：至少是 ref，最好是 eq_ref
-- 2. Extra：避免 Using filesort 和 Using temporary
-- 3. rows：扫描行数尽量少
```

---

## 总结

1. **DISTINCT** 适合简单去重场景，代码简洁
2. **GROUP BY** 适合需要统计聚合的场景，功能更强
3. **最佳实践**：优先考虑单表查询 + 应用层组装
4. **性能优化**：合理建立索引，监控慢查询
5. **MySQL 5.7+**：注意 ONLY_FULL_GROUP_BY 限制

根据你的业务场景选择合适的方案！
