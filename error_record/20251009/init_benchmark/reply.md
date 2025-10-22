# Benchmark保存逻辑重构计划（基于benchmark_detail表判断初始化）

## 核心变更

### 判断逻辑变更
- ❌ **移除**：不再使用 `isTemplate` 字段判断
- ✅ **改为**：查询 `benchmark_detail` 表判断
  - 表为空 → 初始化
  - 表有数据 → 非初始化保存

---

## 一、代码修改清单

### 1. BenchmarkDetailsReqVo.java
**文件**：`pap-server/src/main/java/cn/bochk/pap/server/business/vo/req/BenchmarkDetailsReqVo.java`

**操作**：
- ✅ 保留 `benchmarkId` 字段（必需，用于后端查询）
- ❌ 移除 `isTemplate` 字段（不再使用）

### 2. BenchmarkServiceImpl.java - updateBenchmark()方法
**文件**：`pap-server/src/main/java/cn/bochk/pap/server/business/service/Impl/BenchmarkServiceImpl.java`

**完全重写此方法**：

```java
@Override
@Transactional(rollbackFor = Exception.class)
public void updateBenchmark(List<BenchmarkDetailsReqVo> updateReqVO) {
    // 1. 校验权重总和
    validateRootWeights(updateReqVO);

    // 2. 获取benchmarkId
    String benchmarkId = updateReqVO.get(0).getBenchmarkId();

    // 3. 查询detail表判断是否初始化
    List<BenchmarkDetailsDo> existingDetails = benchmarkDetailsMapper.selectList(
        new LambdaQueryWrapperX<>()
            .eq(BenchmarkDetailsDo::getBenchmarkId, benchmarkId)
    );

    if (existingDetails == null || existingDetails.isEmpty()) {
        // 情况1：初始化
        handleFirstSave(benchmarkId, updateReqVO);
    } else {
        // 情况2：非初始化保存
        handleSubsequentSave(benchmarkId, updateReqVO);
    }
}
```

### 3. 新增方法：handleFirstSave()（情况1：初始化）

```java
/**
 * 处理首次保存（初始化）
 */
private void handleFirstSave(String benchmarkId, List<BenchmarkDetailsReqVo> updateReqVO) {
    // 1. 获取benchmark记录
    BenchmarkDO benchmarkDO = benchmarkMapper.selectById(benchmarkId);

    // 2. UPDATE benchmark表为初始状态
    benchmarkDO.setRecordVersion(0);  // 强制设置为0
    benchmarkDO.setDelFlag(0);
    benchmarkDO.setMaker(getLoginUserNickname());
    benchmarkDO.setMakerDatetime(LocalDateTime.now());
    benchmarkMapper.updateById(benchmarkDO);

    // 3. 递归INSERT所有details（record_version=0）
    insertBenchmarkDetailsRecursive(updateReqVO, benchmarkDO, null, 1);

    // 4. 启动BPM流程
    Map<String, Object> processInstanceVariables = new HashMap<>();
    startProcess(benchmarkId, processInstanceVariables);

    // 5. 发送通知
    sendNotification();
}
```

### 4. 新增方法：handleSubsequentSave()（情况2：非初始化保存）

```java
/**
 * 处理后续保存（非初始化）
 */
private void handleSubsequentSave(String benchmarkId, List<BenchmarkDetailsReqVo> updateReqVO) {
    // 1. 获取旧benchmark记录
    BenchmarkDO oldBenchmark = benchmarkMapper.selectById(benchmarkId);

    // 2. 验证版本号
    validateRecordVersion(updateReqVO.get(0), oldBenchmark);

    // 3. 版本管理：标记旧记录 + INSERT新记录
    BenchmarkDO newBenchmark = createNewBenchmarkVersion(oldBenchmark);

    // 4. 递归INSERT新版本details（旧数据保持不变）
    insertBenchmarkDetailsRecursive(updateReqVO, newBenchmark, null, 1);

    // 5. 启动BPM流程
    Map<String, Object> processInstanceVariables = new HashMap<>();
    startProcess(newBenchmark.getId(), processInstanceVariables);

    // 6. 发送通知
    sendNotification();
}
```

### 5. 新增方法：createNewBenchmarkVersion()

```java
/**
 * 创建新版本benchmark（版本管理）
 */
private BenchmarkDO createNewBenchmarkVersion(BenchmarkDO oldBenchmark) {
    // 1. UPDATE旧记录：标记删除
    oldBenchmark.setDelFlag(1);
    oldBenchmark.setValidEndDatetime(LocalDateTime.now());
    benchmarkMapper.updateById(oldBenchmark);

    // 2. INSERT新记录
    BenchmarkDO newBenchmark = new BenchmarkDO();
    BeanUtils.copyProperties(oldBenchmark, newBenchmark);
    newBenchmark.setId(IdUtils.getUUID());  // 新UUID
    newBenchmark.setDelFlag(0);
    newBenchmark.setRecordVersion(oldBenchmark.getRecordVersion() + 1);  // 版本+1
    newBenchmark.setValidStartDatetime(LocalDateTime.now());
    newBenchmark.setValidEndDatetime(null);
    newBenchmark.setMaker(getLoginUserNickname());
    newBenchmark.setMakerDatetime(LocalDateTime.now());
    benchmarkMapper.insert(newBenchmark);

    return newBenchmark;
}
```

### 6. 移除不再使用的方法
- `updateBenchmarkForFirstSave()`
- `markOldDetailsAsDeleted()`
- 旧的 `updateMainBenchmark()` 逻辑（保留原来的createUpdateBenchmark和createInsertBenchmark方法作为参考）

### 7. 修改查询逻辑：getBenchmark()方法

**添加del_flag过滤**：
```java
@Override
public List<BenchmarkDetailsRespVo> getBenchmark(String id) {
    // 1. 查询benchmark（只查del_flag=0的）
    BenchmarkDO benchmarkDO = benchmarkMapper.selectOne(
        new LambdaQueryWrapperX<>()
            .eq(BenchmarkDO::getId, id)
            .eq(BenchmarkDO::getDelFlag, 0)  // 新增过滤
    );

    if (benchmarkDO == null) {
        return Collections.emptyList();
    }

    // 2. 查询details
    List<BenchmarkDetailsDo> detailsDos = benchmarkDetailsMapper.selectList(
        new LambdaQueryWrapperX<>()
            .eq(BenchmarkDetailsDo::getBenchmarkId, id)
    );

    // 3. 如果details为空，返回模板
    if (detailsDos == null || detailsDos.isEmpty()) {
        return getDefaultTemplateData();
    }

    // 4. 构建树形结构
    return buildDynamicTree(detailsDos, benchmarkDO);
}
```

---

## 二、文档更新清单

### 1. add_update_logic_en.md

**需要更新的章节**：

#### 章节 2.2：BenchmarkDetailsReqVo定义
```java
@Data
public class BenchmarkDetailsReqVo {
    private String id;
    private String benchmarkId;  // ✅ 保留
    private String assetClassification;
    private String weight;
    private String recordVersion;
    // ❌ 移除 isTemplate 字段
    private List<BenchmarkDetailsReqVo> children;
}
```

#### 章节 3.6：updateBenchmark()方法
- 完全重写为基于查询判断的逻辑
- 移除所有isTemplate相关判断

#### 章节 3.8-3.11：辅助方法
- 新增 handleFirstSave()
- 新增 handleSubsequentSave()
- 新增 createNewBenchmarkVersion()
- 移除 updateBenchmarkForFirstSave()
- 移除 markOldDetailsAsDeleted()

#### 章节 4.1-4.2：流程图
- 更新为"查询detail表判断"的流程
- 移除isTemplate相关说明

#### 章节 5.1：核心机制
- 更新判断逻辑说明
- 移除isTemplate字段说明

#### 章节 5.3：判断逻辑
- 完全重写为基于查询的判断

#### FAQ Q5：
- 更新为"为什么使用查询判断而不是传递标识字段"

---

## 三、关键业务逻辑总结

### 判断初始化的方式
```java
List<BenchmarkDetailsDo> existingDetails =
    benchmarkDetailsMapper.selectList(benchmarkId);

if (existingDetails.isEmpty()) {
    // 初始化
} else {
    // 非初始化保存
}
```

### 情况1：初始化
- **Benchmark表**：UPDATE（record_version=0, del_flag=0）
- **Details表**：全量INSERT（record_version=0，无del_flag字段）

### 情况2：非初始化保存
- **Benchmark表**：旧记录del_flag=1 + INSERT新记录（record_version+1）
- **Details表**：旧数据不变 + 全量INSERT新数据（record_version=新benchmark的version）

### 查询过滤
- Benchmark表：只查 del_flag=0 的记录
- Details表：通过 benchmark_id 关联查询

---

## 四、执行步骤

1. ✅ 创建 reply.md 文件（包含本计划内容）
2. ⬜ 修改 BenchmarkDetailsReqVo（移除isTemplate）
3. ⬜ 重写 updateBenchmark() 方法
4. ⬜ 添加 handleFirstSave() 方法
5. ⬜ 添加 handleSubsequentSave() 方法
6. ⬜ 添加 createNewBenchmarkVersion() 方法
7. ⬜ 修改 getBenchmark() 查询方法（添加del_flag过滤）
8. ⬜ 删除废弃方法
9. ⬜ 更新文档 add_update_logic_en.md

---

## 五、注意事项

1. **不修改数据库结构**：benchmark_details表不添加del_flag字段
2. **旧数据保留**：非初始化保存时，旧details记录不删除不修改
3. **版本隔离**：通过不同的benchmark_id实现版本隔离
4. **查询优化**：始终只查询del_flag=0的benchmark及其关联的details
5. **版本号一致性**：details的record_version必须与关联的benchmark的record_version一致

---

## 六、数据流转示例

### 初始化流程
```
1. 用户访问 GET /benchmark/{id}
   → benchmark表有记录（v0, del_flag=0）
   → benchmark_details表为空
   → 返回模板数据

2. 用户填写后保存 POST /benchmark/update
   → 查询details表为空 → 判断为初始化
   → UPDATE benchmark: record_version=0, del_flag=0
   → INSERT details: record_version=0, benchmark_id=原benchmark的id
   → 启动流程
```

### 修改流程
```
1. 用户访问 GET /benchmark/{id}
   → benchmark表有记录（v1, del_flag=0）
   → benchmark_details表有数据
   → 返回真实数据

2. 用户修改后保存 POST /benchmark/update
   → 查询details表有数据 → 判断为非初始化
   → UPDATE旧benchmark: del_flag=1
   → INSERT新benchmark: id=新UUID, record_version=2, del_flag=0
   → INSERT新details: benchmark_id=新benchmark的id, record_version=2
   → 旧details保留不动
   → 启动流程
```

---

## 七、版本管理说明

### Benchmark表版本管理
- 每次保存创建新记录，旧记录标记del_flag=1
- 通过record_version字段跟踪版本号
- 查询时只查del_flag=0的记录

### BenchmarkDetails表版本管理
- 通过不同的benchmark_id关联不同版本
- 旧版本details通过关联旧benchmark_id实现隔离
- 查询时通过benchmark_id过滤，自动只返回当前版本的details

### 数据查询逻辑
```sql
-- 查询最新版本的benchmark
SELECT * FROM benchmark
WHERE id = ? AND del_flag = 0;

-- 查询对应的details
SELECT * FROM benchmark_details
WHERE benchmark_id = ?;
-- 因为benchmark_id是最新版本的id，所以自动过滤出最新版本的details
```
