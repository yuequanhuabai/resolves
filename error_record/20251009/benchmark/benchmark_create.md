BenchmarkServiceImpl.createUpdateBenchmark 方法深度解析

一、方法概述

方法签名

private BenchmarkDO createUpdateBenchmark(BenchmarkDO benchmarkDO, Integer status)

核心作用

这个方法负责准备"旧记录"的更新对象，目的是标记旧版本为失效状态。

它是版本管理的第一步，为即将插入的新版本腾出空间。

  ---
二、两种触发场景

触发场景对比

| 触发角色           | 调用位置                                                                    | status 参数 |
触发时机         |
|----------------|-------------------------------------------------------------------------|-----------|--------------|
| 操作人员 (Maker)   | handleSubsequentSave() → createNewBenchmarkVersion(oldBenchmark, null)  | null      |
用户在页面修改数据并提交 |
| 审批人员 (Checker) | updateProcessStatus() → createNewBenchmarkVersion(oldBenchmark, status) | 2 或 3     |
审批人审批通过/驳回时  |

  ---
三、方法执行流程

整体流程图

┌─────────────────────────────────────────────────────────────┐
│ createUpdateBenchmark(benchmarkDO, status)                  │
└───────────────────┬─────────────────────────────────────────┘
↓
┌──────────────────────┐
│ 第1步：复制旧记录     │
│ BeanUtils.copyProperties() │
└──────────┬───────────┘
↓
┌──────────────────────────────────┐
│ 第2步：根据 bizStatus 判断        │
│                                  │
│ ├─ bizStatus = 0 (系统初始化)    │
│ ├─ bizStatus = 2 (审批通过)      │
│ └─ bizStatus = 1/4 (已提交/重启) │
│      ├─ status = null (操作人员)  │
│      └─ status = 2/3 (审批人员)   │
└──────────┬───────────────────────┘
↓
┌──────────────────────────────────┐
│ 第3步：设置不可编辑标志           │
│ editFlag = 1                     │
└──────────┬───────────────────────┘
↓
┌──────────────────────────────────┐
│ 返回更新对象                      │
└──────────────────────────────────┘

  ---
四、分支详解：基于 bizStatus 的处理逻辑

分支 1: bizStatus = 0 (系统初始化) - 第 272-277 行

if(benchmarkDO.getBizStatus().equals(StatusEnum.system.getValue())){  // 0
updateObj.setValidStartDatetime(LocalDateTime.now());
updateObj.setMaker(getLoginUserNickname());
updateObj.setMakerDatetime(LocalDateTime.now());
updateObj.setMakerBusinessDate(LocalDateTime.now());
updateObj.setDelFlag(FlagEnum.NORMAL_FLAG.getFlag());  // 0 (不删除)
}

触发场景：操作人员首次提交初始化的 Benchmark

业务含义：
- 数据刚从系统初始化状态（biz_status=0）变为已提交状态
- 这是第一次有人填写数据并提交

操作说明：
| 字段                 | 设置值      | 含义           |
|--------------------|----------|--------------|
| validStartDatetime | now()    | 记录生效开始时间     |
| maker              | 当前登录用户昵称 | 记录制单人        |
| makerDatetime      | now()    | 制单时间         |
| makerBusinessDate  | now()    | 制单业务日期       |
| delFlag            | 0        | 保持正常状态，不删除 ⭐ |

为什么不删除？
- 因为这是首次提交，需要保留这条初始化记录
- 新版本会基于这条记录创建
- 后续审批时才会标记删除

数据示例：
【操作前】
id: "bm-001"
bizStatus: 0 (系统初始化)
delFlag: 0
maker: null
validStartDatetime: null

【操作后 - 旧记录更新】
id: "bm-001"
bizStatus: 0 (不变)
delFlag: 0 (保持正常) ⭐
maker: "张三"
makerDatetime: 2024-12-08 10:00:00
validStartDatetime: 2024-12-08 10:00:00
editFlag: 1 (不可编辑)

  ---
分支 2: bizStatus = 2 (审批通过) - 第 278-280 行

else if(benchmarkDO.getBizStatus().equals(2)){
updateObj.setDelFlag(FlagEnum.NORMAL_FLAG.getFlag());  // 0 (不删除)
}

触发场景：操作人员在已通过的 Benchmark 基础上再次发起修改

业务含义：
- 当前记录是已审批通过的版本（biz_status=2）
- 操作人员要基于这个通过的版本重新修改并提交

操作说明：
| 字段      | 设置值 | 含义       |
|---------|-----|----------|
| delFlag | 0   | 保持正常状态 ⭐ |

为什么不删除？
- 审批通过的版本是重要的历史记录，不能删除
- 新版本会基于这个通过版本创建
- 这个版本需要保留作为历史参考

数据示例：
【操作前】
id: "bm-002"
bizStatus: 2 (审批通过)
approvalStatus: 2
delFlag: 0
validStartDatetime: 2024-12-07 10:00:00

【操作后 - 旧记录更新】
id: "bm-002"
bizStatus: 2 (不变)
delFlag: 0 (保持正常) ⭐
editFlag: 1 (不可编辑)

  ---
分支 3: bizStatus = 1 或 4 (已提交/重新发起) - 第 281-293 行

这是最复杂的分支，根据 status 参数区分操作人员和审批人员的操作。

3.1 操作人员触发 - status = null (第 282-284 行)

if(Objects.isNull(status)){  // 操作人员重新提交
updateObj.setValidEndDatetime(null);
updateObj.setDelFlag(FlagEnum.DEL_FLAG.getFlag());  // 1 (删除)
}

触发场景：
- 操作人员在"已提交"或"重新发起"状态的记录上再次编辑并提交
- 典型场景：审批中的数据被撤回后重新修改提交

调用链路：
用户在页面修改数据
→ BenchmarkServiceImpl.updateBenchmark()
→ handleSubsequentSave()
→ createNewBenchmarkVersion(oldBenchmark, null)  // ⭐ status=null
→ createUpdateBenchmark(benchmarkDO, null)

操作说明：
| 字段               | 设置值  | 含义      |
|------------------|------|---------|
| validEndDatetime | null | 不设置结束时间 |
| delFlag          | 1    | 标记删除 ⭐  |

为什么 validEndDatetime = null？
- 因为这是操作人员自己重新提交，不是正式的审批结束
- 只是标记这个版本失效，但不记录具体的结束时间
- 结束时间会在审批完成时才设置

数据示例：
【操作前】
id: "bm-003"
bizStatus: 1 (已提交，审批中)
approvalStatus: 1
delFlag: 0
validStartDatetime: 2024-12-08 09:00:00
validEndDatetime: null

【操作后 - 旧记录更新】
id: "bm-003"
bizStatus: 1 (不变)
delFlag: 1 (标记删除) ⭐
validEndDatetime: null (不设置结束时间) ⭐
editFlag: 1 (不可编辑)

  ---
3.2 审批人员触发 - status = 2 或 3 (第 285-292 行)

else {  // 审批人员审批完成
updateObj.setDelFlag(FlagEnum.DEL_FLAG.getFlag());  // 1 (删除)
updateObj.setValidEndDatetime(LocalDateTime.now());  // 设置结束时间

      // ⭐ 同时更新历史记录
      BenchmarkDO benchmarkHisDO = benchmarkMapper.selectById(benchmarkDO.getHistoryId());
      benchmarkHisDO.setValidEndDatetime(updateObj.getValidEndDatetime());
      benchmarkHisDO.setDelFlag(FlagEnum.DEL_FLAG.getFlag());
      benchmarkMapper.updateById(benchmarkHisDO);
}

触发场景：
- 审批人审批通过（status=2）或驳回（status=3）
- 流程完成，需要正式标记旧版本失效

调用链路：
审批人点击"通过"/"驳回"
→ Flowable 流程完成
→ BpmBenchmarkStatusListener.onEvent()
→ BenchmarkServiceImpl.updateProcessStatus(id, status)  // ⭐ status=2/3
→ createNewBenchmarkVersion(oldBenchmark, status)
→ createUpdateBenchmark(benchmarkDO, status)

操作说明：
| 字段               | 设置值   | 含义       |
|------------------|-------|----------|
| delFlag          | 1     | 标记删除 ⭐   |
| validEndDatetime | now() | 记录结束时间 ⭐ |

关键操作：同时更新历史记录（第 288-291 行）：
BenchmarkDO benchmarkHisDO = benchmarkMapper.selectById(benchmarkDO.getHistoryId());
benchmarkHisDO.setValidEndDatetime(updateObj.getValidEndDatetime());
benchmarkHisDO.setDelFlag(FlagEnum.DEL_FLAG.getFlag());
benchmarkMapper.updateById(benchmarkHisDO);

为什么要同时更新历史记录？
- 确保整个版本链的一致性
- 当前记录和它引用的历史记录应该同时失效
- 方便查询：只需要 WHERE delFlag=0 就能找到当前有效版本

数据示例（审批通过）：
【操作前】
当前记录:
id: "bm-004"
bizStatus: 1 (已提交)
historyId: "bm-003"
delFlag: 0
validStartDatetime: 2024-12-08 10:00:00
validEndDatetime: null

历史记录:
id: "bm-003"
bizStatus: 2 (审批通过)
delFlag: 0
validStartDatetime: 2024-12-07 10:00:00

【操作后 - 旧记录更新】
当前记录:
id: "bm-004"
delFlag: 1 (标记删除) ⭐
validEndDatetime: 2024-12-08 11:00:00 ⭐
editFlag: 1

历史记录:
id: "bm-003"
delFlag: 1 (同时标记删除) ⭐
validEndDatetime: 2024-12-08 11:00:00 ⭐

  ---
五、完整对比表

基于 bizStatus 和 status 的处理矩阵

| bizStatus    | status 参数 | 触发角色 | delFlag | validEndDatetime | 更新历史记录 | 业务场景       |
  |--------------|-----------|------|---------|------------------|--------|------------|
| 0 (系统初始化)    | -         | 操作人员 | 0 (不删除) | now()            | ❌      | 首次提交       |
| 2 (审批通过)     | -         | 操作人员 | 0 (不删除) | -                | ❌      | 基于通过版本再次修改 |
| 1/4 (已提交/重启) | null      | 操作人员 | 1 (删除)  | null             | ❌      | 重新提交/撤回后修改 |
| 1/4 (已提交/重启) | 2/3       | 审批人员 | 1 (删除)  | now()            | ✅      | 审批通过/驳回    |

  ---
六、关键设计决策解析

决策 1：为什么 bizStatus=0/2 不删除？

答案：保留重要的历史记录

// bizStatus = 0: 首次提交的初始化记录
// bizStatus = 2: 审批通过的版本
updateObj.setDelFlag(FlagEnum.NORMAL_FLAG.getFlag());  // 0

原因：
- bizStatus=0: 这是原始数据，需要保留作为基准
- bizStatus=2: 审批通过的版本是重要里程碑，必须保留
- 这些记录虽然不再是"当前版本"，但作为历史追溯很重要

  ---
决策 2：为什么操作人员重新提交时 validEndDatetime=null？

if(Objects.isNull(status)){  // 操作人员
updateObj.setValidEndDatetime(null);  // 不设置结束时间
updateObj.setDelFlag(FlagEnum.DEL_FLAG.getFlag());
}

原因：
- 操作人员的重新提交不是正式的"审批结束"
- 只是版本迭代过程中的一个中间状态
- 真正的结束时间应该由审批完成时设置

对比审批人员：
else {  // 审批人员
updateObj.setValidEndDatetime(LocalDateTime.now());  // 设置结束时间
}

  ---
决策 3：为什么审批时要同时更新历史记录？

BenchmarkDO benchmarkHisDO = benchmarkMapper.selectById(benchmarkDO.getHistoryId());
benchmarkHisDO.setValidEndDatetime(updateObj.getValidEndDatetime());
benchmarkHisDO.setDelFlag(FlagEnum.DEL_FLAG.getFlag());
benchmarkMapper.updateById(benchmarkHisDO);

原因：
1. 版本链一致性：当前版本失效时，它引用的历史版本也应该失效
2. 查询简化：只需要 WHERE delFlag=0 就能找到当前有效版本
3. 数据完整性：避免出现"当前版本删除，历史版本还有效"的矛盾状态

版本链示例：
v1 (historyId=null) ← v2 (historyId=v1) ← v3 (historyId=v2, 当前审批中)

【审批通过时】
UPDATE v3: delFlag=1, validEndDatetime=now  // 当前记录
UPDATE v2: delFlag=1, validEndDatetime=now  // 历史记录 ⭐

【结果】
v1 (delFlag=0) ← v2 (delFlag=1) ← v3 (delFlag=1) ← v4 (delFlag=0, 新版本)

  ---
七、完整场景示例

场景 1：操作人员首次提交（bizStatus=0）

【1. 初始状态】
id: "bm-001"
bizStatus: 0 (系统初始化)
delFlag: 0
maker: null

【2. 操作人员填写数据并提交】
调用: handleSubsequentSave() → createNewBenchmarkVersion(oldBenchmark, null)

【3. createUpdateBenchmark 执行】
if(bizStatus == 0) {
updateObj.setMaker("张三");
updateObj.setMakerDatetime(now);
updateObj.setDelFlag(0);  // 不删除 ⭐
}

【4. 旧记录更新结果】
id: "bm-001"
bizStatus: 0
delFlag: 0 (保留) ⭐
maker: "张三"
makerDatetime: 2024-12-08 10:00:00
editFlag: 1

【5. 同时插入新记录】
id: "bm-002"
bizStatus: 1 (已提交)
approvalStatus: 1 (审批中)
historyId: "bm-001"
recordVersion: 2

  ---
场景 2：操作人员重新提交（bizStatus=1, status=null）

【1. 初始状态】
id: "bm-002"
bizStatus: 1 (已提交，审批中)
approvalStatus: 1
delFlag: 0
historyId: "bm-001"

【2. 操作人员撤回并重新修改提交】
调用: handleSubsequentSave() → createNewBenchmarkVersion(oldBenchmark, null)

【3. createUpdateBenchmark 执行】
if(bizStatus == 1 && status == null) {  // 操作人员
updateObj.setDelFlag(1);              // 标记删除 ⭐
updateObj.setValidEndDatetime(null);  // 不设置结束时间 ⭐
}

【4. 旧记录更新结果】
id: "bm-002"
delFlag: 1 (标记删除) ⭐
validEndDatetime: null ⭐
editFlag: 1

【5. 同时插入新记录】
id: "bm-003"
bizStatus: 1 (已提交)
approvalStatus: 1 (审批中)
historyId: "bm-001"  // 继承历史ID
recordVersion: 3

  ---
场景 3：审批人员审批通过（bizStatus=1, status=2）

【1. 初始状态】
当前记录:
id: "bm-003"
bizStatus: 1 (已提交)
delFlag: 0
historyId: "bm-001"

历史记录:
id: "bm-001"
bizStatus: 0
delFlag: 0

【2. 审批人审批通过】
调用: updateProcessStatus(id, 2) → createNewBenchmarkVersion(oldBenchmark, 2)

【3. createUpdateBenchmark 执行】
if(bizStatus == 1 && status != null) {  // 审批人员
updateObj.setDelFlag(1);
updateObj.setValidEndDatetime(now);

      // 同时更新历史记录 ⭐
      benchmarkHisDO = selectById("bm-001");
      benchmarkHisDO.setDelFlag(1);
      benchmarkHisDO.setValidEndDatetime(now);
      updateById(benchmarkHisDO);
}

【4. 旧记录更新结果】
当前记录:
id: "bm-003"
delFlag: 1 ⭐
validEndDatetime: 2024-12-08 11:00:00 ⭐
editFlag: 1

历史记录:
id: "bm-001"
delFlag: 1 ⭐ (同时更新)
validEndDatetime: 2024-12-08 11:00:00 ⭐
editFlag: 1

【5. 同时插入新记录】
id: "bm-004"
bizStatus: 2 (审批通过)
approvalStatus: 2
historyId: "bm-003"
recordVersion: 4
delFlag: 0 (当前有效版本)

  ---
八、核心总结

createUpdateBenchmark 方法的本质

这是一个"版本失效标记器"，根据不同的业务状态和触发角色，采取不同的失效策略：

| 触发角色 | 关键特征          | 失效策略                 |
  |------|---------------|----------------------|
| 操作人员 | status = null | 标记删除但不设置结束时间         |
| 审批人员 | status = 2/3  | 标记删除并设置结束时间，同时更新历史记录 |

设计精髓

1. 版本链管理：通过 historyId 建立版本链，审批时同时失效整个链条
2. 时间语义：
   - 操作人员重提：validEndDatetime=null（非正式结束）
   - 审批完成：validEndDatetime=now()（正式结束）
3. 保留策略：
   - 初始化记录（bizStatus=0）：保留
   - 通过记录（bizStatus=2）：保留
   - 审批中记录（bizStatus=1/4）：删除
4. 编辑控制：所有旧记录都设置 editFlag=1（不可编辑）

关键代码行解析

// 第 271 行：复制旧记录
BeanUtils.copyProperties(benchmarkDO, updateObj);

// 第 282 行：操作人员 vs 审批人员的判断
if(Objects.isNull(status)){  // 操作人员
updateObj.setValidEndDatetime(null);  // 不设置结束时间
} else {  // 审批人员
updateObj.setValidEndDatetime(LocalDateTime.now());  // 设置结束时间
// 同时更新历史记录...
}

// 第 294 行：所有旧记录都不可编辑
updateObj.setEditFlag(FlagEnum.NO_EDIT_FLAG.getFlag());

这种设计确保了：
- ✅ 操作人员和审批人员的职责分离
- ✅ 版本链的完整性和一致性
- ✅ 审计追踪的准确性
- ✅ 数据的可回溯性