现在让我绘制完整的分析报告：

  ---
操作员多次修改与审批员查看机制分析

一、核心问题回答

问题 1：操作员可以在同一流程任务上多次操作吗？

答案：❌ 当前代码实现 NOT 支持！

问题 2：审批员只会看到最后一个未审批前的操作结果吗？

答案：✅ 理论上可以，但需要流程撤回机制支持（当前未启用）

  ---
二、当前代码实现分析

2.1 操作员提交流程

提交逻辑（BenchmarkServiceImpl.handleSubsequentSave）

private void handleSubsequentSave(String benchmarkId, List<BenchmarkDetailsReqVO> updateReqVO, boolean flag) {
// 1. 获取旧记录
BenchmarkDO oldBenchmark = benchmarkMapper.selectById(benchmarkId);

      // 2. 验证版本号
      if (!flag){
          validateRecordVersion(updateReqVO.get(0), oldBenchmark);
      }

      // 3. 创建新版本
      BenchmarkDO newBenchmark = createNewBenchmarkVersion(oldBenchmark, null);

      // 4. 插入新明细数据
      insertBenchmarkDetailsRecursive(updateReqVO, newBenchmark, 1);

      // 5. ⭐ 启动流程
      startProcess(newBenchmark.getId(), processInstanceVariables);

      // 6. 发送通知
      sendNotification();
}

关键发现：
- ✅ 每次调用都会创建新版本
- ✅ 每次都会启动新流程 (startProcess)
- ❌ 没有检查是否已有进行中的流程
- ❌ 没有取消旧流程的逻辑

  ---
2.2 流程状态管理

startProcess 方法（第 434-447 行）

public void startProcess(String businessId, Map<String, Object> processInstanceVariables) {
try {
// 创建流程实例
String processInstanceId = processInstanceApi.createProcessInstance(
getLoginUserId(),
new BpmProcessInstanceCreateReqDTO()
.setProcessDefinitionKey(PROCESS_KEY)
.setBusinessKey(businessId)  // ⭐ 使用新版本ID
.setVariables(processInstanceVariables)
);

          // 更新 benchmark 的流程实例ID
          benchmarkMapper.updateById(new BenchmarkDO()
              .setId(businessId)
              .setProcessInstanceId(processInstanceId)
              .setApprovalStatus(1)  // 设置为审批中
          );
      } catch (RuntimeException e) {
          log.error("启动流程失败，业务ID: {}, 错误信息: {}", businessId, e.getMessage());
          benchmarkMapper.updateById(new BenchmarkDO()
              .setId(businessId)
              .setApprovalStatus(4)  // 失败状态
          );
          throw new ServerException(500, "流程启动失败");
      }
}

关键发现：
- ✅ 每个新版本都有自己的 processInstanceId
- ❌ 旧版本的流程不会被取消
- ❌ 可能存在多个进行中的流程实例

  ---
2.3 流程取消功能状态

BPM 框架中的取消方法（已注释）

// BpmProcessInstanceServiceImpl.java (820-845行)
// @Override
// public void cancelProcessInstanceByStartUser(Long userId, @Valid BpmProcessInstanceCancelReqVO cancelReqVO) {
//     // 流程取消逻辑
// }

// BpmProcessInstanceController.java (139-143行)
// @DeleteMapping("/cancel-by-start-user")
// @Operation(summary = "用户取消流程实例")
// public CommonResult<Boolean> cancelProcessInstanceByStartUser(...) {
//     processInstanceService.cancelProcessInstanceByStartUser(getLoginUserId(), cancelReqVO);
//     return success(true);
// }

关键发现：
- ❌ 流程取消功能已被注释掉（未启用）
- ❌ 操作员无法撤回已提交的流程
- ❌ 多次提交会创建多个并行流程

  ---
三、数据版本管理机制

3.1 版本创建逻辑

操作员多次提交的数据流

【第1次提交】
v1 (id="bm-001", bizStatus=1, approval_status=1, processInstanceId="proc-001")
↓ 启动流程 proc-001

【第2次提交（同一 businessId）】
调用: updateBenchmark() → handleSubsequentSave()
↓
UPDATE v1: delFlag=1, validEndDatetime=null  // ⭐ 标记删除但不关闭流程
INSERT v2: id="bm-002", bizStatus=1, approval_status=1, processInstanceId="proc-002"
↓ 启动新流程 proc-002  // ⭐ 旧流程 proc-001 仍在运行！

【结果】
- v1: delFlag=1, processInstanceId="proc-001" (流程仍运行)
- v2: delFlag=0, processInstanceId="proc-002" (新流程)
- 流程实例: proc-001 (运行中) + proc-002 (运行中)  ❌ 并行冲突

  ---
3.2 审批员查看的数据

getBenchmark 方法（第 103-130 行）

public List<BenchmarkDetailsRespVO> getBenchmark(String id) {
// 1. ⭐ 查询时过滤 delFlag=0 的记录
BenchmarkDO benchmarkDO = benchmarkMapper.selectOne(
new LambdaQueryWrapperX<BenchmarkDO>()
.eq(BenchmarkDO::getId, id)
.eq(BenchmarkDO::getDelFlag, FlagEnum.NORMAL_FLAG.getFlag())  // 只查有效记录
);

      if (benchmarkDO == null) {
          log.warn("未找到 benchmark 记录 (或已被删除): {}", id);
          return Collections.emptyList();
      }

      // 2. 查询明细数据
      List<BenchmarkDetailsDo> detailsDos = benchmarkDetailsMapper.selectList(
          new LambdaQueryWrapperX<BenchmarkDetailsDo>()
              .eq(BenchmarkDetailsDo::getBenchmarkId, id)
      );

      // 3. 构建树形结构返回
      return buildDynamicTree(detailsDos, benchmarkDO);
}

关键发现：
- ✅ 查询时只返回 delFlag=0 的记录
- ✅ 如果操作员多次提交，旧版本（delFlag=1）不会被查到
- ✅ 审批员看到的是最新版本的数据

  ---
四、问题场景模拟

场景 1：操作员连续提交两次

【时间线】
10:00 - 操作员提交 v1
- 创建 v1 (id="bm-001", delFlag=0, processInstanceId="proc-001")
- 启动流程 proc-001

10:10 - 操作员再次修改并提交 v2
- UPDATE v1: delFlag=1
- INSERT v2 (id="bm-002", delFlag=0, processInstanceId="proc-002")
- 启动流程 proc-002
- ❌ proc-001 仍在运行！

【审批员 A 审批 proc-001】
- 查询 businessKey="bm-001"
- ❌ 查不到数据（v1 的 delFlag=1）
- ⚠️ 审批异常或显示空数据

【审批员 B 审批 proc-002】
- 查询 businessKey="bm-002"
- ✅ 看到 v2 的数据
- ✅ 正常审批

问题总结：
1. ❌ 旧流程（proc-001）的审批人看不到数据（因为 v1 被标记删除）
2. ❌ 存在多个并行流程实例
3. ❌ 可能导致数据不一致

  ---
场景 2：理想的多次提交机制（需要实现）

【理想流程】
10:00 - 操作员提交 v1
- 创建 v1 (delFlag=0, processInstanceId="proc-001")
- 启动流程 proc-001

10:10 - 操作员撤回并重新提交 v2
- ⭐ 取消流程 proc-001 (调用 cancelProcessInstance)
- UPDATE v1: delFlag=1
- INSERT v2 (delFlag=0, processInstanceId="proc-002")
- 启动流程 proc-002

【审批员审批 proc-002】
- 查询 businessKey="bm-002"
- ✅ 看到 v2 的最新数据
- ✅ 正常审批
- ✅ proc-001 已被取消，不会产生冲突

  ---
五、当前代码的问题分析

问题 1：缺少流程取消机制

现象：
// handleSubsequentSave() 中
BenchmarkDO newBenchmark = createNewBenchmarkVersion(oldBenchmark, null);
// ❌ 没有取消旧版本的流程
// ❌ 直接启动新流程
startProcess(newBenchmark.getId(), processInstanceVariables);

影响：
- 多次提交会产生多个并行的流程实例
- 旧流程的审批人看不到数据（因为旧版本被标记删除）
- 可能导致审批异常

  ---
问题 2：版本管理与流程绑定不一致

现象：
// createUpdateBenchmark() 中
if(bizStatus == 1 && status == null) {  // 操作员重新提交
updateObj.setDelFlag(1);  // 标记删除
// ❌ 但没有更新或取消 processInstanceId
}

影响：
- 数据版本（delFlag=1）已失效
- 但流程实例（processInstanceId）仍有效
- 版本管理和流程管理脱节

  ---
问题 3：审批员查询可能失败

现象：
// getBenchmark() 中
BenchmarkDO benchmarkDO = benchmarkMapper.selectOne(
new LambdaQueryWrapperX<BenchmarkDO>()
.eq(BenchmarkDO::getId, id)
.eq(BenchmarkDO::getDelFlag, FlagEnum.NORMAL_FLAG.getFlag())  // 只查 delFlag=0
);

影响：
- 如果审批员审批的是旧流程，businessKey 指向旧版本ID
- 旧版本的 delFlag=1，查询结果为空
- 审批界面可能显示空数据或报错

  ---
六、是否支持目标功能？

目标功能 1：操作员多次修改提交

| 功能点     | 当前状态  | 说明           |
  |---------|-------|--------------|
| 创建新版本   | ✅ 支持  | 每次提交都创建新版本   |
| 标记旧版本失效 | ✅ 支持  | 设置 delFlag=1 |
| 取消旧流程   | ❌ 不支持 | 流程取消功能已注释    |
| 防止并行流程  | ❌ 不支持 | 没有检查机制       |

结论：❌ 部分支持，存在严重缺陷

  ---
目标功能 2：审批员看到最新数据

| 功能点                | 当前状态  | 说明                      |
  |--------------------|-------|-------------------------|
| 查询过滤失效版本           | ✅ 支持  | WHERE delFlag=0         |
| 流程 businessKey 正确性 | ❌ 有风险 | 旧流程的 businessKey 指向失效版本 |
| 数据一致性              | ❌ 有风险 | 并行流程可能导致冲突              |

结论：⚠️ 理论可行，实际有风险

  ---
七、修复建议

建议 1：启用流程取消机制

private void handleSubsequentSave(String benchmarkId, List<BenchmarkDetailsReqVO> updateReqVO, boolean flag) {
BenchmarkDO oldBenchmark = benchmarkMapper.selectById(benchmarkId);

      // ⭐ 新增：取消旧流程
      if (oldBenchmark.getProcessInstanceId() != null) {
          cancelProcessInstance(oldBenchmark.getProcessInstanceId(), "操作员重新提交");
      }

      // 创建新版本
      BenchmarkDO newBenchmark = createNewBenchmarkVersion(oldBenchmark, null);

      // 启动新流程
      startProcess(newBenchmark.getId(), processInstanceVariables);
}

// 新增方法
private void cancelProcessInstance(String processInstanceId, String reason) {
try {
runtimeService.deleteProcessInstance(processInstanceId, reason);
log.info("已取消流程实例: {}, 原因: {}", processInstanceId, reason);
} catch (Exception e) {
log.warn("取消流程实例失败: {}", processInstanceId, e);
}
}

  ---
建议 2：增加并行流程检查

private void handleSubsequentSave(String benchmarkId, List<BenchmarkDetailsReqVO> updateReqVO, boolean flag) {
BenchmarkDO oldBenchmark = benchmarkMapper.selectById(benchmarkId);

      // ⭐ 检查是否有进行中的流程
      if (oldBenchmark.getApprovalStatus() == 1) {  // 审批中
          throw new ServerException(400, "当前有正在审批的流程，请先撤回或等待审批完成");
      }

      // ... 后续逻辑
}

  ---
建议 3：修改版本管理逻辑

private BenchmarkDO createUpdateBenchmark(BenchmarkDO benchmarkDO, Integer status) {
BenchmarkDO updateObj = new BenchmarkDO();
BeanUtils.copyProperties(benchmarkDO, updateObj);

      if(benchmarkDO.getBizStatus().equals(1) && Objects.isNull(status)) {
          updateObj.setDelFlag(1);
          updateObj.setValidEndDatetime(null);

          // ⭐ 新增：清空流程实例ID
          updateObj.setProcessInstanceId(null);
          updateObj.setApprovalStatus(4);  // 已取消
      }

      updateObj.setEditFlag(1);
      return updateObj;
}

  ---
八、总结

当前实现状态

| 需求       | 实现状态    | 风险等级 |
  |----------|---------|------|
| 操作员多次提交  | ⚠️ 部分支持 | 🔴 高 |
| 审批员看最新数据 | ✅ 理论可行  | 🟡 中 |
| 流程取消机制   | ❌ 未实现   | 🔴 高 |
| 数据版本管理   | ✅ 已实现   | 🟢 低 |
| 并行流程控制   | ❌ 未实现   | 🔴 高 |

核心问题

1. 流程取消功能被注释，无法撤回已提交的流程
2. 多次提交会创建并行流程，可能导致审批混乱
3. 旧流程的审批人可能看不到数据（因为旧版本被标记删除）

建议方案

方案 A：禁止多次提交
- 在提交时检查 approval_status
- 如果已有流程在审批，抛出异常

方案 B：支持流程撤回（推荐）
- 启用流程取消功能
- 重新提交时自动取消旧流程
- 确保只有一个有效流程

方案 C：修改查询逻辑
- 审批时通过 processInstanceId 反查对应版本
- 不依赖 delFlag 过滤

  ---
最终答案：
- ❌ 当前代码不完全支持操作员多次修改提交
- ✅ 审批员可以看到最新数据，但有并行流程风险
- 🔧 需要启用流程取消机制才能完善此功能