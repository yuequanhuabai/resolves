  ---
流程状态 1、2、3 的定义和机制全解析

一、核心答案

流程状态不是 Flowable 原生的，而是芋道框架自定义的扩展！

状态值定义在：BpmProcessInstanceStatusEnum.java

public enum BpmProcessInstanceStatusEnum implements ArrayValuable<Integer> {
NOT_START(-1, "未开始"),
RUNNING(1, "审批中"),      // ⭐ 发起
APPROVE(2, "审批通过"),     // ⭐ 通过
REJECT(3, "审批不通过"),    // ⭐ 驳回
CANCEL(4, "已取消");
}

  ---
二、这不是 Flowable 原生机制

Flowable 原生状态

Flowable 引擎本身只有以下几种状态：
- ProcessInstance.isEnded(): 流程是否结束
- ProcessInstance.isSuspended(): 流程是否挂起
- Task.isEnded(): 任务是否完成

Flowable 没有"审批通过"或"审批驳回"的概念，它只知道流程是否完成。

芋道框架的扩展

芋道框架通过 流程变量（Process Variables） 机制扩展了流程状态：

// 定义状态变量名
public static final String PROCESS_INSTANCE_VARIABLE_STATUS = "PROCESS_STATUS";

这个状态值存储在 Flowable 的 流程变量表 中，而不是 Flowable 的核心表。

  ---
三、状态值的完整生命周期

阶段 1：发起流程 - 设置为 RUNNING (1)

位置: BpmProcessInstanceServiceImpl.createProcessInstance0() 第 753-754 行

private String createProcessInstance0(Long userId, ProcessDefinition definition, ...) {
// ...
Map<String, Object> variables = new HashMap<>();

      // ⭐ 设置流程状态为"审批中"
      variables.put(BpmnVariableConstants.PROCESS_INSTANCE_VARIABLE_STATUS,
                    BpmProcessInstanceStatusEnum.RUNNING.getStatus());  // 值为 1

      // 启动流程实例，变量会存储到 ACT_RU_VARIABLE 表
      ProcessInstance instance = processInstanceBuilder
          .variables(variables)
          .start();

      return instance.getId();
}

数据存储位置：
- Flowable 表：ACT_RU_VARIABLE
- 变量名：PROCESS_STATUS
- 变量值：1 (RUNNING)

  ---
阶段 2：审批驳回 - 设置为 REJECT (3)

位置: BpmTaskServiceImpl.rejectTask() → BpmProcessInstanceServiceImpl.updateProcessInstanceReject() 第 880-882 行

@Override
public void rejectTask(Long userId, @Valid BpmTaskRejectReqVO reqVO) {
// 1. 校验任务和流程实例
Task task = validateTask(userId, reqVO.getId());
ProcessInstance instance = processInstanceService.getProcessInstance(task.getProcessInstanceId());

      // 2. 更新任务状态为不通过
      updateTaskStatusAndReason(task.getId(), BpmTaskStatusEnum.REJECT.getStatus(), reqVO.getReason());

      // 3. ⭐ 更新流程实例状态为 REJECT
      processInstanceService.updateProcessInstanceReject(instance, reqVO.getReason());

      // 4. 结束流程
      moveTaskToEnd(task.getProcessInstanceId(), ...);
}

// 更新流程状态
public void updateProcessInstanceReject(ProcessInstance processInstance, String reason) {
// ⭐ 设置流程变量 PROCESS_STATUS = 3 (REJECT)
runtimeService.setVariable(
processInstance.getProcessInstanceId(),
BpmnVariableConstants.PROCESS_INSTANCE_VARIABLE_STATUS,
BpmProcessInstanceStatusEnum.REJECT.getStatus()  // 值为 3
);

      // 设置驳回原因
      runtimeService.setVariable(
          processInstance.getProcessInstanceId(),
          BpmnVariableConstants.PROCESS_INSTANCE_VARIABLE_REASON,
          BpmReasonEnum.REJECT_TASK.format(reason)
      );
}

  ---
阶段 3：流程完成 - 判断是通过还是驳回

位置: BpmProcessInstanceServiceImpl.processProcessInstanceCompleted() 第 901-915 行

@Override
public void processProcessInstanceCompleted(ProcessInstance instance) {
FlowableUtils.execute(instance.getTenantId(), () -> {
// 1. ⭐ 从流程变量中获取当前状态
Integer status = (Integer) instance.getProcessVariables()
.get(BpmnVariableConstants.PROCESS_INSTANCE_VARIABLE_STATUS);

          String reason = (String) instance.getProcessVariables()
              .get(BpmnVariableConstants.PROCESS_INSTANCE_VARIABLE_REASON);

          // 2. ⭐ 关键判断：如果状态还是 RUNNING(1)，说明审批通过了
          // 为什么？因为如果是驳回，在 rejectTask 中已经设置为 REJECT(3)
          if (Objects.equals(status, BpmProcessInstanceStatusEnum.RUNNING.getStatus())) {
              status = BpmProcessInstanceStatusEnum.APPROVE.getStatus();  // 改为 2
              runtimeService.setVariable(instance.getId(),
                  BpmnVariableConstants.PROCESS_INSTANCE_VARIABLE_STATUS, status);
          }

          // 3. 发送事件给业务系统
          processInstanceEventPublisher.sendProcessInstanceResultEvent(
              BpmProcessInstanceConvert.INSTANCE.buildProcessInstanceStatusEvent(this, instance, status)
          );
      });
}

  ---
四、状态转换逻辑图

┌─────────────────────────────────────────────────────────────┐
│ 发起流程                                                     │
│ createProcessInstance()                                     │
│ ↓                                                           │
│ variables.put("PROCESS_STATUS", 1)  // RUNNING             │
└───────────────────┬─────────────────────────────────────────┘
↓
┌──────────────────────┐
│  流程审批中           │
│  status = 1 (RUNNING) │
└──────────┬────────────┘
│
┌────────────┴────────────┐
│                         │
✅ 审批通过               ❌ 审批驳回
│                         │
↓                         ↓
┌──────────────────┐    ┌──────────────────────┐
│ approveTask()    │    │ rejectTask()         │
│ 完成任务         │    │ ↓                    │
│ (不修改状态)     │    │ setVariable(         │
│                  │    │   "PROCESS_STATUS", 3│
│                  │    │ )  // REJECT         │
└────────┬─────────┘    └─────────┬────────────┘
│                        │
│                        │
└────────┬───────────────┘
↓
┌────────────────────────────┐
│ 流程完成事件                │
│ processProcessInstanceCompleted() │
└────────────┬───────────────┘
↓
┌────────────────────────────┐
│ 读取 PROCESS_STATUS        │
└────────────┬───────────────┘
│
┌──────────┴──────────┐
│                     │
status = 1            status = 3
(仍是 RUNNING)        (已是 REJECT)
│                     │
↓                     ↓
改为 status = 2       保持 status = 3
(APPROVE)             (REJECT)
│                     │
└──────────┬──────────┘
↓
┌────────────────────────────┐
│ 发送状态事件                │
│ BpmProcessInstanceStatusEvent │
│ - status: 2 或 3            │
└────────────┬───────────────┘
↓
┌────────────────────────────┐
│ 业务监听器处理              │
│ BpmBenchmarkStatusListener  │
│ updateProcessStatus(id, status) │
└────────────────────────────┘

  ---
五、关键判断逻辑解析

为什么审批通过时状态还是 1？

答案：因为 approveTask() 方法不会修改流程状态！

@Override
public void approveTask(Long userId, @Valid BpmTaskApproveReqVO reqVO) {
Task task = validateTask(userId, reqVO.getId());

      // 只更新任务状态
      updateTaskStatusAndReason(task.getId(),
          BpmTaskStatusEnum.APPROVE.getStatus(), reqVO.getReason());

      // 完成任务（让流程继续流转）
      taskService.complete(task.getId(), reqVO.getVariables());

      // ⭐ 注意：这里没有调用 setVariable() 修改 PROCESS_STATUS
}

为什么审批驳回时状态是 3？

答案：因为 rejectTask() 方法显式设置了状态为 3！

@Override
public void rejectTask(Long userId, @Valid BpmTaskRejectReqVO reqVO) {
// ...

      // ⭐ 显式设置流程状态为 REJECT (3)
      processInstanceService.updateProcessInstanceReject(instance, reqVO.getReason());

      // 结束流程
      moveTaskToEnd(task.getProcessInstanceId(), ...);
}

流程完成时如何判断是通过还是驳回？

判断逻辑：
// 读取流程变量中的状态
Integer status = instance.getProcessVariables().get("PROCESS_STATUS");

if (status == 1) {  // 还是 RUNNING
// 说明是正常审批通过（没有人调用 rejectTask）
status = 2;  // 改为 APPROVE
} else if (status == 3) {  // 已经是 REJECT
// 说明之前有人调用了 rejectTask
// 保持 REJECT 状态
}

  ---
六、数据存储位置

Flowable 数据表

| 表名              | 字段            | 值示例            | 说明     |
  |-----------------|---------------|----------------|--------|
| ACT_RU_VARIABLE | NAME_         | PROCESS_STATUS | 变量名    |
|                 | TEXT_ 或 LONG_ | 1 / 2 / 3      | 状态值    |
|                 | PROC_INST_ID_ | proc-12345     | 流程实例ID |
| ACT_HI_VARINST  | （同上）          | （历史数据）         | 历史变量表  |

业务数据表

| 表名        | 字段                  | 值示例        | 说明     |
  |-----------|---------------------|------------|--------|
| benchmark | approval_status     | 1 / 2 / 3  | 业务审批状态 |
|           | process_instance_id | proc-12345 | 关联流程实例 |

  ---
七、这是扩展配置还是自定义逻辑？

答案：自定义逻辑，不是 Flowable 配置

| 方式             | 说明                     |
  |----------------|------------------------|
| ❌ Flowable 配置  | Flowable 没有提供审批状态的配置选项 |
| ❌ Flowable 扩展点 | 不是通过 Flowable 的扩展接口实现  |
| ✅ 芋道框架自定义      | 通过流程变量 + 事件监听器实现       |

实现机制

1. 流程变量存储状态
   ↓
2. 在关键节点修改变量
    - 发起: variables.put("PROCESS_STATUS", 1)
    - 驳回: setVariable("PROCESS_STATUS", 3)
    - 完成: 判断后设置为 2 或保持 3
      ↓
3. 流程完成时读取变量
   ↓
4. 通过 Spring 事件发送给业务系统
   ↓
5. 业务监听器接收并更新业务数据

  ---
八、为什么要这样设计？

设计优势

| 优势     | 说明                                             |
  |--------|------------------------------------------------|
| 业务语义清晰 | "审批中"、"审批通过"、"审批驳回" 比 Flowable 的 isEnded() 更直观 |
| 状态持久化  | 状态存储在流程变量中，可以随时查询历史                            |
| 与业务解耦  | 流程状态和业务状态分离，互不影响                               |
| 易于扩展   | 可以增加更多自定义状态（如"退回"、"转办"等）                       |

对比 Flowable 原生

| 维度   | Flowable 原生               | 芋道框架扩展                     |
  |------|---------------------------|----------------------------|
| 状态表达 | isEnded() / isSuspended() | RUNNING / APPROVE / REJECT |
| 业务含义 | 技术状态                      | 业务状态                       |
| 查询便利 | 需要判断多个字段                  | 直接读取 PROCESS_STATUS        |
| 扩展性  | 受限于引擎设计                   | 可自由扩展                      |

  ---
九、完整示例代码

发起流程（设置状态为 1）

// BenchmarkServiceImpl.startProcess()
public void startProcess(String businessId, Map<String, Object> processInstanceVariables) {
// Flowable API 内部会设置 PROCESS_STATUS = 1
String processInstanceId = processInstanceApi.createProcessInstance(
getLoginUserId(),
new BpmProcessInstanceCreateReqDTO()
.setProcessDefinitionKey("PROCESS_BENCHMARK")
.setBusinessKey(businessId)
.setVariables(processInstanceVariables)
);

      // 将流程实例ID写回业务表
      benchmarkMapper.updateById(new BenchmarkDO()
          .setId(businessId)
          .setProcessInstanceId(processInstanceId)
          .setApprovalStatus(1)  // 业务状态也设为 1
      );
}

审批通过（状态保持 1，流程完成后改为 2）

// 审批人点击"通过"按钮
taskService.complete(taskId, variables);

// 流程完成后，自动转换
// status = 1 (RUNNING) → status = 2 (APPROVE)

审批驳回（设置状态为 3）

// 审批人点击"驳回"按钮
public void rejectTask(Long userId, BpmTaskRejectReqVO reqVO) {
// 设置流程状态为 REJECT (3)
runtimeService.setVariable(
processInstanceId,
"PROCESS_STATUS",
3  // BpmProcessInstanceStatusEnum.REJECT.getStatus()
);

      // 结束流程
      moveTaskToEnd(processInstanceId, reason);
}

业务系统接收状态（2 或 3）

// BpmBenchmarkStatusListener
protected void onEvent(BpmProcessInstanceStatusEvent event) {
// event.getStatus() 的值是 2 (通过) 或 3 (驳回)
benchmarkService.updateProcessStatus(
event.getBusinessKey(),
event.getStatus()  // 2 或 3
);
}

// BenchmarkServiceImpl
public void updateProcessStatus(String id, Integer status) {
// 创建新版本，更新业务状态
BenchmarkDO newBenchmark = createNewBenchmarkVersion(oldBenchmark, status);

      // status = 2: approval_status=2, biz_status=2
      // status = 3: approval_status=3, biz_status=3
}

  ---
十、总结

核心要点

1. 流程状态 1、2、3 不是 Flowable 原生的，是芋道框架自定义的
2. 状态存储在流程变量中，变量名为 PROCESS_STATUS
3. 状态转换逻辑：
   - 发起时设置为 1 (RUNNING)
   - 驳回时设置为 3 (REJECT)
   - 正常完成时从 1 改为 2 (APPROVE)
4. 判断依据：流程完成时，如果状态还是 1，说明是通过；如果是 3，说明是驳回
5. 实现方式：流程变量 + 事件监听器 + 业务回调

设计精髓

这种设计巧妙地利用了 Flowable
的流程变量机制，在不修改引擎代码的情况下，实现了业务语义丰富的审批状态管理。这是一种非侵入式扩展的最佳实践！