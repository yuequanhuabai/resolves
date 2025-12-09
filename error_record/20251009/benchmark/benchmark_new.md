很好！现在我可以详细回答你的问题了。

  ---
📝 方案2可行性分析：不创建新流程，仅更新业务数据

  ---
✅ 第一部分：这种方案可以实现吗？
-- INSERT --
答案：部分可以实现，但有限制条件

让我按照不同场景分析：

| 场景          | 是否可以实现    | Flowable 支持程度 | 说明            |
  |-------------|-----------|---------------|---------------|
| 1. 编辑草稿状态数据 | ✅ 完全可以    | 100%          | 流程未启动，只需更新业务表 |
| 2. 编辑审批中的数据 | ⚠️ 可以但有风险 | 70%           | 需要同步更新流程变量    |
| 3. 编辑已通过的数据 | ❌ 不建议     | 30%           | 违反审批逻辑，需重新审批  |
| 4. 编辑已打回的数据 | ✅ 可以      | 90%           | 属于修改后重新提交场景   |

  ---
详细分析每个场景

场景1: 草稿状态（approvalStatus=0, 未启动流程）

状态：bizStatus=0（待提交），approvalStatus=0（草稿）
流程实例：processInstanceId = null

✅ 完全可以实现
- 因为流程还未启动，只需要更新业务数据库表
- 不涉及 Flowable 流程引擎
- 这是最安全、最简单的场景

  ---
场景2: 审批中的数据（approvalStatus=1, 流程运行中）

状态：bizStatus=1（已提交），approvalStatus=1（pending）
流程实例：processInstanceId = "xxx"（ACT_RU_EXECUTION 表中存在）
待办任务：ACT_RU_TASK 表中有任务等待审批人处理

⚠️ 可以实现，但需要特别处理

Flowable 框架支持：
1. 更新流程变量 - ✅ 完全支持
   // Flowable 提供的 API
   runtimeService.setVariables(processInstanceId, newVariables);
2. 更新业务数据 - ✅ 框架层面不限制
   - Flowable 不会阻止你修改业务表
   - 但需要确保数据一致性
3. 不重新发起流程 - ✅ 可以
   - 保持原 processInstanceId 不变
   - 继续使用当前流程实例

存在的风险：

🔴 风险1：审批人已经看过旧数据
时间线：
T1: 用户提交 Benchmark（权重：A=50%, B=50%）
T2: 审批人打开审批页面，看到数据
T3: 用户修改数据（权重：A=80%, B=20%）← 此时审批人还未提交审批
T4: 审批人点击"通过"
问题： 审批人批准的是 T2 时刻的数据，但实际通过的是 T3 修改后的数据！

🔴 风险2：流程变量与业务数据不一致
// 如果流程中有这样的条件判断：
<sequenceFlow sourceRef="task1" targetRef="task2">
<conditionExpression>${totalWeight == 100}</conditionExpression>
</sequenceFlow>
修改业务数据后，如果不同步更新流程变量，会导致流程走向错误。

🔴 风险3：审计追溯困难
审计需求："这个审批通过的数据，当时提交的版本是什么？"
如果允许修改 → 无法追溯原始提交数据

  ---
场景3: 已审批通过的数据（approvalStatus=2, 流程已结束）

状态：bizStatus=2（approved），approvalStatus=2（通过）
流程实例：已结束（ACT_HI_PROCINST.END_TIME_ 不为空）

❌ 不建议实现

技术上可以做：
- ✅ 更新业务数据库 - 没有技术限制
- ✅ 流程已结束 - 不需要处理流程实例

但违反业务逻辑：
1. 审批结果失效：审批人批准的是旧数据，现在数据变了，相当于审批结果无效
2. 合规性问题：金融/财务系统中，已审批数据不得修改是强制要求
3. 正确做法：应该重新发起审批流程

  ---
场景4: 已打回的数据（approvalStatus=3, 流程已结束）

状态：bizStatus=3（rejected），approvalStatus=3（驳回）
流程实例：已结束（被拒绝）

✅ 可以实现

这是最合理的"修改后重新提交"场景：
1. 原流程已结束（被驳回）
2. 用户修改数据
3. 两种处理方式：
   - 方式A：更新数据 + 启动新流程 ✅
   - 方式B：更新数据 + 不启动流程，改为草稿状态 ✅

  ---
🏗️ 第二部分：主体逻辑实现方式

  ---
核心设计思路：状态机驱动的差异化处理

用户点击"保存"按钮
↓
判断当前 bizStatus 和 approvalStatus
↓
根据状态选择不同的处理策略

  ---
完整状态机逻辑图

┌─────────────────────────────────────────────────────────┐
│                   用户保存操作入口                        │
│              updateBenchmark(updateReqVO)               │
└────────────────────┬────────────────────────────────────┘
↓
查询当前 Benchmark 记录
↓
┌───────────────┴───────────────┐
│     获取 bizStatus 状态        │
└───────────────┬───────────────┘
↓
┌────────────┴────────────┐
│  状态判断（5种场景）     │
└────────────┬────────────┘
↓
┌────────────────┼────────────────┐
│                │                │
↓                ↓                ↓
┌───────┐      ┌──────────┐     ┌──────────┐
│ 场景1 │      │  场景2   │     │  场景3   │
│草稿态 │      │审批中    │     │已通过    │
│biz=0  │      │biz=1/4   │     │biz=2     │
└───┬───┘      └────┬─────┘     └────┬─────┘
│               │                 │
↓               ↓                 ↓
┌─────────┐   ┌──────────────┐  ┌──────────────┐
│策略A:   │   │策略B:        │  │策略D:        │
│仅更新   │   │有条件更新    │  │强制新流程    │
│业务数据 │   │+同步流程变量 │  │（不允许修改）│
└─────────┘   └──────────────┘  └──────────────┘
↓               ↓                 ↓
不启动流程     不启动新流程        启动新流程
保持原状态     保持processId       新processId

  ---
策略A：草稿状态修改（bizStatus=0）

前置条件检查：
├─ bizStatus == 0（待提交）
├─ approvalStatus == 0（草稿）
└─ processInstanceId == null（无流程）

处理步骤：
1️⃣ 验证权重总和 = 100%
2️⃣ 直接 UPDATE benchmark 表（不插入新记录）
└─ 因为还未审批，无需版本管理
3️⃣ DELETE 旧的 benchmark_details 记录
4️⃣ INSERT 新的 benchmark_details 记录
5️⃣ 不启动流程
6️⃣ 返回成功

伪代码逻辑：
─────────────────────────────────────────
if (oldBenchmark.getBizStatus() == 0) {
// 校验数据
validateRootWeights(updateReqVO);

      // 直接更新主表（不创建新版本）
      BenchmarkDO updateObj = new BenchmarkDO();
      updateObj.setId(benchmarkId);
      // 只更新业务字段，不改状态
      benchmarkMapper.updateById(updateObj);

      // 删除旧 details
      benchmarkDetailsMapper.delete(
          new LambdaQueryWrapperX<>()
              .eq(BenchmarkDetailsDo::getBenchmarkId, benchmarkId)
      );

      // 插入新 details
      insertBenchmarkDetailsRecursive(updateReqVO, oldBenchmark, 1);

      // 不启动流程！
      return;
}

优点：
- ✅ 无版本膨胀
- ✅ 无流程冗余
- ✅ 符合用户预期（草稿可随意修改）

  ---
策略B：审批中修改（bizStatus=1或4）

前置条件检查：
├─ bizStatus == 1（已提交）或 == 4（重新提交）
├─ approvalStatus == 1（pending）
└─ processInstanceId != null（流程运行中）

处理步骤：
1️⃣ 询问用户：是否允许修改审批中的数据？
├─ 选项A：允许修改（更新数据 + 同步流程变量）
└─ 选项B：撤回流程后修改（取消流程 → 改为草稿）

如果选择 A（危险操作，需权限控制）：
2️⃣ 验证权重总和
3️⃣ UPDATE benchmark 表（记录修改时间）
4️⃣ 重新插入 benchmark_details
5️⃣ 同步更新流程变量（关键！）
└─ runtimeService.setVariables(processInstanceId, variables)
6️⃣ 记录修改日志（审计用）
7️⃣ 通知审批人：数据已变更
8️⃣ 不启动新流程（继续用原流程）

如果选择 B（推荐方式）：
2️⃣ 取消当前流程实例
└─ processInstanceApi.cancelProcessInstance(processInstanceId, "用户撤回")
3️⃣ UPDATE benchmark 状态：
├─ bizStatus = 0（改回草稿）
├─ approvalStatus = 0
└─ processInstanceId = null
4️⃣ 更新业务数据
5️⃣ 提示用户：已撤回，请重新提交

伪代码逻辑（方式A）：
─────────────────────────────────────────
if (oldBenchmark.getBizStatus() == 1 || oldBenchmark.getBizStatus() == 4) {
// 权限检查：只有发起人才能修改审批中的数据
if (!oldBenchmark.getMaker().equals(getLoginUserNickname())) {
throw new ServerException(403, "只有发起人可以修改审批中的数据");
}

      // 检查流程是否还在运行
      ProcessInstance instance = runtimeService.createProcessInstanceQuery()
          .processInstanceId(oldBenchmark.getProcessInstanceId())
          .singleResult();
      if (instance == null) {
          throw new ServerException(400, "流程已结束，无法修改");
      }

      // 更新数据（不创建新版本）
      updateBenchmarkInPlace(benchmarkId, updateReqVO);

      // 同步流程变量
      Map<String, Object> variables = buildProcessVariables(updateReqVO);
      runtimeService.setVariables(oldBenchmark.getProcessInstanceId(), variables);

      // 记录修改日志
      logBenchmarkModification(benchmarkId, "审批中修改");

      // 通知审批人
      notifyApproverDataChanged(oldBenchmark.getProcessInstanceId());

      // 不启动新流程！
      return;
}

风险提示：
- ⚠️ 需要在前端显示警告："修改审批中的数据可能导致审批人困惑"
- ⚠️ 必须记录修改日志，用于审计
- ⚠️ 最好增加权限控制：只有特定角色才能修改审批中的数据

  ---
策略C：已打回修改（bizStatus=3）

前置条件检查：
├─ bizStatus == 3（已驳回）
├─ approvalStatus == 3
└─ processInstanceId != null（流程已结束）

处理步骤：
1️⃣ 验证权重总和
2️⃣ 两种处理方式供选择：

     方式1：保存为草稿（不立即提交）
     ├─ UPDATE benchmark 状态：bizStatus=0, approvalStatus=0
     ├─ processInstanceId 保持不变（记录历史）
     └─ 用户后续手动点"提交"时再启动流程

     方式2：保存并重新提交
     ├─ 创建新版本（版本号+1）
     ├─ 标记旧版本 delFlag=1
     └─ 启动新流程

伪代码逻辑（方式1 - 推荐）：
─────────────────────────────────────────
if (oldBenchmark.getBizStatus() == 3) {
// 更新数据
updateBenchmarkInPlace(benchmarkId, updateReqVO);

      // 改回草稿状态
      BenchmarkDO updateStatus = new BenchmarkDO();
      updateStatus.setId(benchmarkId);
      updateStatus.setBizStatus(0);
      updateStatus.setApprovalStatus(0);
      // 保留 processInstanceId（审计用）
      benchmarkMapper.updateById(updateStatus);

      // 不启动流程，等用户手动提交
      return;
}

  ---
策略D：已通过修改（bizStatus=2）

前置条件检查：
├─ bizStatus == 2（已通过）
├─ approvalStatus == 2
└─ processInstanceId != null（流程已完成）

处理步骤：
1️⃣ 强制要求：必须创建新版本 + 新流程
└─ 理由：已审批数据不得直接修改（合规要求）
2️⃣ 执行完整的版本控制流程：
├─ 标记旧版本 delFlag=1
├─ 插入新版本 recordVersion+1
├─ 复制 details 数据
└─ 启动新流程
3️⃣ 提示用户：已通过的数据修改需重新审批

伪代码逻辑：
─────────────────────────────────────────
if (oldBenchmark.getBizStatus() == 2) {
// 不允许直接修改，必须走版本控制
throw new ServerException(400,
"已审批通过的数据不可修改，请重新发起审批流程");

      // 或者自动转为新版本：
      handleSubsequentSave(benchmarkId, updateReqVO, false);
}

  ---
🔑 关键技术点

1. 如何同步流程变量？

// 构建流程变量（与业务数据对应）
Map<String, Object> buildProcessVariables(List<BenchmarkDetailsReqVO> details) {
Map<String, Object> vars = new HashMap<>();

      // 示例：传递关键业务数据到流程
      vars.put("totalWeight", calculateTotalWeight(details));
      vars.put("benchmarkName", getBenchmarkName());
      vars.put("lastModifiedTime", LocalDateTime.now());
      vars.put("modifiedBy", getLoginUserNickname());

      // 如果流程有条件判断，需要传递判断变量
      vars.put("needSecondApproval", needSecondApproval(details));

      return vars;
}

// 调用 Flowable API 更新
runtimeService.setVariables(processInstanceId, variables);

2. 如何通知审批人数据已变更？

// 方式1：在流程中添加事件监听器
// 当变量更新时，自动发送通知

// 方式2：手动发送通知
void notifyApproverDataChanged(String processInstanceId) {
// 查询当前待办任务
List<Task> tasks = taskService.createTaskQuery()
.processInstanceId(processInstanceId)
.list();

      // 给每个审批人发消息
      tasks.forEach(task -> {
          notifySendService.sendSingleNotifyToUser(
              task.getAssignee(),
              "BENCHMARK_DATA_CHANGED",
              Map.of("processInstanceId", processInstanceId)
          );
      });
}

3. 如何记录修改日志？

// 方案1：在 benchmark 表增加字段
// modified_count INT  -- 修改次数
// last_modified_time DATETIME  -- 最后修改时间
// last_modified_by VARCHAR  -- 最后修改人

// 方案2：增加审计表
CREATE TABLE benchmark_audit_log (
id VARCHAR(64) PRIMARY KEY,
benchmark_id VARCHAR(64),
operation_type VARCHAR(20),  -- 'MODIFY_IN_APPROVAL'
old_data TEXT,  -- JSON
new_data TEXT,  -- JSON
operator VARCHAR(64),
operate_time DATETIME
);

  ---
⚖️ 方案对比总结

| 方案                | 优点                   | 缺点                          | 适用场景                   |
  |-------------------|----------------------|-----------------------------|------------------------|
| 方案1：每次创建新流程（当前实现） | • 流程清晰• 审计完整         | • 孤儿流程• 数据冗余• 审批混乱          | ❌
  不推荐                  |
| 方案2：不创建新流程（仅更新数据） | • 无流程冗余• 性能好• 符合用户习惯 | • 审计风险• 需同步流程变量•
  审批人可能看到旧数据 | ✅ 草稿状态⚠️ 审批中（需控制）❌ 已通过 |
| 方案3：混合策略（按状态区分）   | • 兼顾合规性和用户体验• 灵活     | • 实现复杂• 需要完善的状态机            |
  ✅ 最推荐                  |

  ---
🎯 最终建议

推荐实现混合策略：

草稿状态（biz=0）       → 直接更新，不启动流程
审批中（biz=1/4）       → 撤回流程 → 改为草稿 → 提示重新提交
已打回（biz=3）         → 更新数据 → 改为草稿 → 等待重新提交
已通过（biz=2）         → 强制创建新版本 + 新流程

核心原则：
1. ✅ 草稿阶段：随意修改，无限制
2. ⚠️ 审批阶段：允许撤回后修改
3. ❌ 已审批：不允许修改，必须新流程
4. 📝 所有修改都要记录日志

这样既能避免流程冗余，又能保证审批合规性！