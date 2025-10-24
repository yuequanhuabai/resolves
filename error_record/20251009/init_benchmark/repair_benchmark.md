# Benchmark 保存失败问题修复方案

## 问题描述

使用 `test001` 账号登录后，在 "业务表单" -> "Benchmark" -> "Private Banking" 页面：
1. 点击唯一一条 benchmark 数据进入详情页
2. 点击编辑按钮
3. 修改权重：
   - Fixed Income -> Government Debt -> EUR Government Bonds: 50.00%
   - Alte222: 50.00%
4. 点击保存后，后端报错
5. 数据库中 benchmark 表没有数据保存成功（仍为空）

## 问题分析

### 预期行为

根据业务逻辑，应该有两种情况：

#### 情况1：首次初始化（benchmark_detail 表为空）
1. **查询阶段**：从 `bench_grouping` 表查询模板数据返显到前端
2. **保存阶段**：
   - 更新 `benchmark` 表的状态字段
   - **全部插入**到 `benchmark_detail` 表
   - 启动 BPM 流程

#### 情况2：非首次保存（benchmark_detail 表有数据）
1. **查询阶段**：从 `benchmark_detail` 表查询数据返显
2. **保存阶段**：
   - 更新旧 `benchmark` 记录的状态为已删除
   - **新增**一条新的 `benchmark` 记录
   - 将旧 `benchmark_detail` 记录标记为删除（`del_flag=1`）
   - **递归解析前端数据**，批量插入新的 `benchmark_detail` 记录（`del_flag=0`）
   - 启动 BPM 流程

### 实际问题

**核心问题：首次保存时 `benchmark` 表的 `businessId` 字段未初始化，导致数据一致性问题和事务回滚。**

## 问题根因

### 代码位置

文件：`BenchmarkServiceImpl.java:199-222`

方法：`handleFirstSave()`

### 问题代码

```java
private void handleFirstSave(String benchmarkId, List<BenchmarkDetailsReqVo> updateReqVO) {
    // 1. 获取benchmark记录
    BenchmarkDO benchmarkDO = benchmarkMapper.selectById(benchmarkId);
    if (benchmarkDO == null) {
        throw new ServerException(400, "Benchmark不存在: " + benchmarkId);
    }

    // ❌ 2. 只UPDATE了4个字段，businessId仍然是null
    benchmarkDO.setRecordVersion(0);
    benchmarkDO.setDelFlag(0);
    benchmarkDO.setMaker(getLoginUserNickname());
    benchmarkDO.setMakerDatetime(LocalDateTime.now());
    benchmarkMapper.updateById(benchmarkDO);

    // ❌ 3. 插入details时，businessId为null
    insertBenchmarkDetailsRecursive(updateReqVO, benchmarkDO, null, 1);
    // 第353行：detail.setBusinessId(newBenchmark.getBusinessId());
    // 获取到的是 null！

    // 4. 启动BPM流程
    Map<String, Object> processInstanceVariables = new HashMap<>();
    startProcess(benchmarkId, processInstanceVariables);

    // 5. 发送通知
    sendNotification();
}
```

### 问题链路追踪

1. **`handleFirstSave` 方法**（第199行）
   - 查询到 `benchmarkDO`，但 `businessId` 字段为 `null`
   - UPDATE 时没有设置 `businessId`

2. **`insertBenchmarkDetailsRecursive` 方法**（第341行）
   - 第353行：`detail.setBusinessId(newBenchmark.getBusinessId())`
   - 所有插入 `benchmark_details` 的记录的 `businessId` 都是 `null`

3. **数据一致性问题**
   - `businessId` 是版本管理的核心字段（参见 `updateProcessStatus` 方法第140-147行）
   - 缺少 `businessId` 导致：
     - 版本管理逻辑失败
     - 可能触发数据库约束错误
     - 流程启动可能失败

4. **事务回滚**
   - 方法上有 `@Transactional(rollbackFor = Exception.class)` 注解（第155行）
   - 任何异常都会导致整个事务回滚
   - 用户看到的结果就是：**benchmark 表仍然为空**

### 为什么会出现这个问题？

可能的原因：
1. `benchmark` 表的初始数据是通过 SQL 手动插入的，缺少 `businessId` 字段
2. 缺少标准的 `createBenchmark` 接口来初始化完整的字段
3. `handleFirstSave` 方法编写时遗漏了 `businessId` 的初始化逻辑

## 修复方案

### 方案1：修改 `handleFirstSave` 方法（推荐）

**文件位置**：`pocpro/pap-server/src/main/java/cn/bochk/pap/server/business/service/Impl/BenchmarkServiceImpl.java`

**修改方法**：`handleFirstSave(String benchmarkId, List<BenchmarkDetailsReqVo> updateReqVO)`

**修改后的代码**：

```java
/**
 * 处理首次保存（初始化）
 *
 * @param benchmarkId benchmark ID
 * @param updateReqVO 请求数据
 */
private void handleFirstSave(String benchmarkId, List<BenchmarkDetailsReqVo> updateReqVO) {
    // 1. 获取benchmark记录
    BenchmarkDO benchmarkDO = benchmarkMapper.selectById(benchmarkId);
    if (benchmarkDO == null) {
        throw new ServerException(400, "Benchmark不存在: " + benchmarkId);
    }

    // ✅ 2. 检查并初始化businessId（关键修复）
    if (benchmarkDO.getBusinessId() == null || benchmarkDO.getBusinessId().isEmpty()) {
        // 首次初始化时，将benchmarkId作为businessId
        benchmarkDO.setBusinessId(benchmarkId);
        log.info("首次保存，初始化businessId: {}", benchmarkId);
    }

    // ✅ 3. UPDATE benchmark表为初始状态（补充必要字段）
    benchmarkDO.setRecordVersion(0);  // 版本号设为0
    benchmarkDO.setDelFlag(0);  // 未删除
    benchmarkDO.setMaker(getLoginUserNickname());  // 制作人
    benchmarkDO.setMakerDatetime(LocalDateTime.now());  // 制作时间
    benchmarkDO.setMakerBusinessDate(LocalDateTime.now());  // ✅ 业务日期
    benchmarkDO.setValidStartDatetime(LocalDateTime.now());  // ✅ 生效开始时间
    benchmarkDO.setValidEndDatetime(null);  // 生效结束时间为空

    // 执行更新
    int updateCount = benchmarkMapper.updateById(benchmarkDO);
    if (updateCount == 0) {
        throw new ServerException(500, "更新Benchmark失败，可能存在版本冲突");
    }
    log.info("首次保存，更新benchmark成功，ID: {}, businessId: {}", benchmarkId, benchmarkDO.getBusinessId());

    // 4. 递归INSERT所有details（现在businessId不为null了）
    insertBenchmarkDetailsRecursive(updateReqVO, benchmarkDO, null, 1);

    // 5. 启动BPM流程
    Map<String, Object> processInstanceVariables = new HashMap<>();
    startProcess(benchmarkId, processInstanceVariables);

    // 6. 发送通知
    sendNotification();
}
```

### 方案2：数据库补丁（临时方案）

如果当前 `benchmark` 表已经有数据但 `businessId` 为空，需要先执行以下 SQL 修复现有数据：

```sql
-- 查看当前benchmark表的businessId情况
SELECT id, business_id, name, status, del_flag
FROM benchmark
WHERE business_id IS NULL OR business_id = '';

-- 修复现有数据：将id赋值给businessId
UPDATE benchmark
SET business_id = id
WHERE business_id IS NULL OR business_id = '';

-- 验证修复结果
SELECT id, business_id, name, status, del_flag
FROM benchmark;
```

### 方案3：增加日志（辅助调试）

在 `insertBenchmarkDetailsRecursive` 方法开始处添加日志：

```java
private void insertBenchmarkDetailsRecursive(
        List<BenchmarkDetailsReqVo> reqVos,
        BenchmarkDO newBenchmark,
        String parentId,
        int currentLevel) {

    // ✅ 添加日志验证businessId
    log.info("开始插入benchmark_details，benchmarkId: {}, businessId: {}, parentId: {}, level: {}",
        newBenchmark.getId(),
        newBenchmark.getBusinessId(),  // 验证是否为null
        parentId,
        currentLevel);

    // 如果businessId为null，提前抛出异常
    if (newBenchmark.getBusinessId() == null || newBenchmark.getBusinessId().isEmpty()) {
        throw new ServerException(500, "Benchmark的businessId不能为空，无法插入details");
    }

    List<BenchmarkDetailsDo> insertDetails = new ArrayList<>();

    // ... 后续代码保持不变
}
```

## 修复步骤

### 步骤1：备份数据（重要）

```sql
-- 备份benchmark表
CREATE TABLE benchmark_backup_20250124 AS SELECT * FROM benchmark;

-- 备份benchmark_details表
CREATE TABLE benchmark_details_backup_20250124 AS SELECT * FROM benchmark_details;

-- 验证备份
SELECT COUNT(*) FROM benchmark_backup_20250124;
SELECT COUNT(*) FROM benchmark_details_backup_20250124;
```

### 步骤2：修复现有数据

```sql
-- 修复benchmark表的businessId
UPDATE benchmark
SET business_id = id
WHERE business_id IS NULL OR business_id = '';

-- 验证修复
SELECT id, business_id, name, record_version, del_flag
FROM benchmark
WHERE business_id IS NOT NULL;
```

### 步骤3：修改代码

1. 打开文件：`pocpro/pap-server/src/main/java/cn/bochk/pap/server/business/service/Impl/BenchmarkServiceImpl.java`

2. 找到 `handleFirstSave` 方法（约199行）

3. 按照上述**方案1**中的代码替换整个方法

4. 建议同时添加**方案3**中的日志代码

### 步骤4：编译和部署

```bash
# 进入项目目录
cd D:\software\developmentTools\Git\gitee\newpap\pap\pocpro

# 清理并编译
mvn clean package -DskipTests

# 部署（根据实际部署方式）
# 方式1：直接运行
# java -jar pap-server/target/pap-server.jar

# 方式2：替换现有jar包并重启服务
```

### 步骤5：验证修复

#### 1. 数据库验证

```sql
-- 验证benchmark表
SELECT
    id,
    business_id,
    name,
    status,
    record_version,
    del_flag,
    maker,
    maker_datetime,
    valid_start_datetime
FROM benchmark
ORDER BY maker_datetime DESC
LIMIT 5;

-- 验证benchmark_details表
SELECT
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
FROM benchmark_details
ORDER BY benchmark_id, asset_level, sort_order
LIMIT 10;
```

#### 2. 功能验证

1. 使用 `test001` 账号登录（密码：`123456`）
2. 进入 "业务表单" -> "Benchmark" -> "Private Banking"
3. 点击唯一的一条数据进入详情页
4. 点击"Edit"按钮
5. 修改权重：
   - Fixed Income -> Government Debt -> EUR Government Bonds: `50.00%`
   - Alte222: `50.00%`
6. 点击"Save"按钮
7. 观察：
   - 前端是否显示"Save successful"
   - 是否自动跳转回列表页
   - 数据是否正确保存

#### 3. 检查日志

查看后端日志，确认以下信息：

```log
# 应该看到的日志
[INFO] 首次保存，初始化businessId: xxx
[INFO] 首次保存，更新benchmark成功，ID: xxx, businessId: xxx
[INFO] 开始插入benchmark_details，benchmarkId: xxx, businessId: xxx, parentId: null, level: 1
```

## 验证SQL脚本

### 完整验证脚本

```sql
-- ===== 修复前检查 =====

-- 1. 检查benchmark表的businessId情况
SELECT
    COUNT(*) as total_count,
    COUNT(business_id) as has_business_id,
    COUNT(*) - COUNT(business_id) as missing_business_id
FROM benchmark;

-- 2. 检查具体哪些记录缺少businessId
SELECT id, name, business_id, status, del_flag
FROM benchmark
WHERE business_id IS NULL OR business_id = '';

-- ===== 执行修复 =====

-- 3. 备份数据
CREATE TABLE IF NOT EXISTS benchmark_backup_20250124 AS SELECT * FROM benchmark;
CREATE TABLE IF NOT EXISTS benchmark_details_backup_20250124 AS SELECT * FROM benchmark_details;

-- 4. 修复businessId
UPDATE benchmark
SET business_id = id
WHERE business_id IS NULL OR business_id = '';

-- ===== 修复后验证 =====

-- 5. 验证修复结果
SELECT
    COUNT(*) as total_count,
    COUNT(business_id) as has_business_id,
    COUNT(*) - COUNT(business_id) as still_missing
FROM benchmark;

-- 6. 查看修复后的数据
SELECT
    id,
    business_id,
    name,
    status,
    record_version,
    del_flag,
    maker,
    DATE_FORMAT(maker_datetime, '%Y-%m-%d %H:%i:%s') as maker_datetime
FROM benchmark
ORDER BY maker_datetime DESC;

-- ===== 保存后验证 =====

-- 7. 验证benchmark表新增记录
SELECT
    id,
    business_id,
    name,
    status,
    record_version,
    del_flag,
    process_instance_id,
    DATE_FORMAT(maker_datetime, '%Y-%m-%d %H:%i:%s') as maker_datetime,
    DATE_FORMAT(valid_start_datetime, '%Y-%m-%d %H:%i:%s') as valid_start_datetime
FROM benchmark
WHERE business_id IS NOT NULL
ORDER BY maker_datetime DESC
LIMIT 5;

-- 8. 验证benchmark_details表数据
SELECT
    bd.id,
    bd.business_id,
    bd.benchmark_id,
    bd.parent_id,
    bd.asset_classification,
    bd.asset_level,
    bd.weight,
    bd.record_version,
    b.name as benchmark_name
FROM benchmark_details bd
LEFT JOIN benchmark b ON bd.benchmark_id = b.id
WHERE bd.business_id IS NOT NULL
ORDER BY bd.benchmark_id, bd.asset_level, bd.sort_order
LIMIT 20;

-- 9. 验证树形结构完整性（检查父子关系）
SELECT
    CONCAT(REPEAT('  ', asset_level - 1), asset_classification) as tree_structure,
    asset_level,
    weight,
    parent_id,
    id
FROM benchmark_details
WHERE benchmark_id = (SELECT id FROM benchmark ORDER BY maker_datetime DESC LIMIT 1)
ORDER BY asset_level, sort_order;

-- 10. 验证权重总和
SELECT
    benchmark_id,
    asset_level,
    SUM(weight) as total_weight
FROM benchmark_details
WHERE parent_id IS NULL  -- 只统计一级节点
GROUP BY benchmark_id, asset_level
HAVING SUM(weight) <> 100.00;  -- 找出不等于100的记录
```

## 常见问题

### Q1: 修复后仍然报错怎么办？

**A**: 检查以下几点：
1. 确认数据库中 `businessId` 已经填充
2. 查看后端日志，找到具体的错误信息
3. 检查 `benchmark_details` 表是否有 `businessId` 字段
4. 确认流程引擎（Flowable）是否正常启动

### Q2: 如何确认修复成功？

**A**: 三个验证点：
1. 数据库中 `benchmark` 表有新记录，且 `businessId` 不为空
2. 数据库中 `benchmark_details` 表有新记录，且 `businessId` 不为空
3. 前端显示 "Save successful" 并自动返回列表页

### Q3: 是否影响现有数据？

**A**:
- 修复代码不会影响已保存的数据
- 只影响**首次保存**的逻辑
- 建议先在测试环境验证

### Q4: 为什么需要设置 businessId = id？

**A**:
- `businessId` 用于版本管理，同一业务的多个版本共享一个 `businessId`
- 首次创建时，`id` 就是唯一标识，可以作为 `businessId`
- 后续版本会生成新的 `id`，但保持相同的 `businessId`

### Q5: 修复后如何处理历史数据？

**A**:
```sql
-- 如果已经有一些保存失败的脏数据
DELETE FROM benchmark WHERE business_id IS NULL;
DELETE FROM benchmark_details WHERE business_id IS NULL;

-- 或者标记为删除
UPDATE benchmark SET del_flag = 1 WHERE business_id IS NULL;
```

## 附录

### A. 数据表结构

#### benchmark 表

| 字段名 | 类型 | 说明 | 是否必填 |
|--------|------|------|----------|
| id | VARCHAR | 主键 | 是 |
| business_id | VARCHAR | 业务ID（版本管理） | **是** |
| name | VARCHAR | 名称 | 是 |
| status | INT | 状态 | 是 |
| business_type | INT | 业务类型 | 是 |
| benchmark_type | INT | Benchmark类型 | 是 |
| record_version | INT | 数据版本号 | 是 |
| del_flag | INT | 删除标识 | 是 |
| maker | VARCHAR | 制作人 | 否 |
| maker_datetime | DATETIME | 制作时间 | 否 |
| valid_start_datetime | DATETIME | 生效开始时间 | 否 |
| valid_end_datetime | DATETIME | 生效结束时间 | 否 |
| process_instance_id | VARCHAR | 流程实例ID | 否 |

#### benchmark_details 表

| 字段名 | 类型 | 说明 | 是否必填 |
|--------|------|------|----------|
| id | VARCHAR | 主键 | 是 |
| business_id | VARCHAR | 业务ID | **是** |
| benchmark_id | VARCHAR | Benchmark表主键 | 是 |
| parent_id | VARCHAR | 父节点ID | 否 |
| asset_classification | VARCHAR | 资产分类 | 是 |
| asset_level | INT | 资产层级 | 是 |
| weight | DECIMAL | 权重 | 是 |
| record_version | INT | 数据版本号 | 是 |
| sort_order | INT | 排序 | 否 |

### B. 相关文件清单

| 文件路径 | 说明 |
|---------|------|
| `pocpro/pap-server/src/main/java/cn/bochk/pap/server/business/service/Impl/BenchmarkServiceImpl.java` | 核心服务实现（需修改） |
| `pocpro/pap-server/src/main/java/cn/bochk/pap/server/business/controller/BenchmarkController.java` | 控制器 |
| `pocpro/pap-server/src/main/java/cn/bochk/pap/server/business/dal/BenchmarkDO.java` | Benchmark实体 |
| `pocpro/pap-server/src/main/java/cn/bochk/pap/server/business/dal/BenchmarkDetailsDo.java` | BenchmarkDetails实体 |
| `poc-pro-ui/src/views/benchmark/detail/index.vue` | 前端详情页 |
| `poc-pro-ui/src/api/benchmark/index.ts` | 前端API定义 |

### C. 测试用例

#### 测试用例1：首次保存

**前置条件**：
- benchmark 表有一条记录（id=xxx, business_id=xxx）
- benchmark_details 表为空

**操作步骤**：
1. 登录系统
2. 进入 Benchmark Private Banking 页面
3. 点击数据进入详情页
4. 点击 Edit
5. 修改叶子节点权重，确保总和为 100%
6. 点击 Save

**预期结果**：
- 提示 "Save successful"
- benchmark 表：record_version=0, status=1, business_id 不为空
- benchmark_details 表：插入所有节点数据，business_id 不为空
- 流程启动成功

#### 测试用例2：二次保存

**前置条件**：
- benchmark 表有一条记录（record_version=0）
- benchmark_details 表有对应数据

**操作步骤**：
1. 登录系统
2. 进入 Benchmark Private Banking 页面
3. 点击数据进入详情页
4. 点击 Edit
5. 修改叶子节点权重
6. 点击 Save

**预期结果**：
- 提示 "Save successful"
- benchmark 表：
  - 旧记录：del_flag=1 或 status=4
  - 新记录：record_version=1, status=1, 新的id, 相同的business_id
- benchmark_details 表：
  - 旧数据保持不变
  - 新增一批记录，关联到新的benchmark_id
- 流程启动成功

---

## 总结

**问题核心**：`businessId` 字段未初始化导致首次保存失败

**修复关键**：在 `handleFirstSave` 方法中添加 `businessId` 初始化逻辑

**影响范围**：仅影响首次保存流程，不影响已有数据

**修复难度**：低（只需修改一个方法）

**风险评估**：低（修改点明确，逻辑简单）

---

**文档版本**：v1.0
**创建时间**：2025-01-24
**最后更新**：2025-01-24
**修复状态**：待验证
