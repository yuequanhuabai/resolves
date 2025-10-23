# Flowable 工作流引擎原理深度解析

> **作者**: Claude Code
> **日期**: 2025-10-23
> **项目**: PAP (Private & Retail Banking Management System)
> **Flowable 版本**: 7.0.1
> **分析方法**: 基于 PAP 项目源码的 Flowable 原理剖析

---

## 📚 目录

1. [Flowable 概述](#flowable-概述)
2. [Flowable 核心概念](#flowable-核心概念)
3. [Flowable 架构设计](#flowable-架构设计)
4. [Flowable 五大核心 Service](#flowable-五大核心-service)
5. [Flowable 数据库表结构](#flowable-数据库表结构)
6. [流程实例生命周期](#流程实例生命周期)
7. [任务分配机制](#任务分配机制)
8. [事件监听机制](#事件监听机制)
9. [流程变量管理](#流程变量管理)
10. [Flowable 与 Spring 集成原理](#flowable-与-spring-集成原理)
11. [总结与最佳实践](#总结与最佳实践)

---

## Flowable 概述

### 什么是 Flowable?

Flowable 是一个**轻量级的业务流程引擎**，它提供了 BPMN 2.0 标准的实现，用于管理企业的工作流和业务流程。Flowable 是从 Activiti 分支出来的项目，在保持核心功能的基础上，进行了大量的优化和增强。

### Flowable 的特点

| 特点 | 说明 |
|------|------|
| **BPMN 2.0 标准** | 完全符合 BPMN 2.0 规范 |
| **轻量级** | 核心jar包小于3MB，易于集成 |
| **高性能** | 异步执行器，支持高并发 |
| **易扩展** | 提供丰富的扩展点和监听器 |
| **Spring 集成** | 与 Spring/Spring Boot 无缝集成 |
| **多种数据库** | 支持MySQL、Oracle、PostgreSQL、SQL Server等 |
| **RESTful API** | 提供完整的 REST API |

### PAP 项目中的 Flowable 版本

```xml
<!-- pom.xml -->
<flowable.version>7.0.1</flowable.version>
```

**版本特性**:
- Spring Boot 3.x 完全兼容
- 改进的异步执行器性能
- 更好的多租户支持
- 增强的事件监听机制

---

## Flowable 核心概念

### 1. ProcessEngine (流程引擎)

ProcessEngine 是 Flowable 的核心，所有的服务都通过它获取。

```
ProcessEngine
    ├── RepositoryService (流程定义管理)
    ├── RuntimeService (流程实例管理)
    ├── TaskService (任务管理)
    ├── HistoryService (历史数据查询)
    ├── ManagementService (引擎管理)
    └── FormService (表单服务)
```

**PAP 项目中的配置**:
```java
// BpmFlowableConfiguration.java
@Configuration
public class BpmFlowableConfiguration {

    @Bean
    public EngineConfigurationConfigurer<SpringProcessEngineConfiguration>
        bpmProcessEngineConfigurationConfigurer(...) {
        return configuration -> {
            // 注册监听器
            configuration.setEventListeners(listeners);
            // 设置 ActivityBehaviorFactory
            configuration.setActivityBehaviorFactory(bpmActivityBehaviorFactory);
            // 设置自定义函数
            configuration.setCustomFlowableFunctionDelegates(delegates);
        };
    }
}
```

---

### 2. ProcessDefinition (流程定义)

流程定义是流程的**模板**，定义了流程的结构和规则。

**核心属性**:
- **id**: 流程定义的唯一标识（自动生成，如：`benchmark:1:4028`）
- **key**: 流程定义的业务标识（如：`benchmark`）
- **name**: 流程名称
- **version**: 版本号（同一个key可以有多个版本）
- **deploymentId**: 部署ID

**存储位置**:
- BPMN XML文件 → 解析 → 存储到 `act_re_procdef` 表
- BpmnModel对象 → 序列化 → 存储到 `act_ge_bytearray` 表

**版本管理**:
```
benchmark:1:4028 (版本1)
benchmark:2:4056 (版本2)  ← 最新版本
benchmark:3:4084 (版本3)  ← 最新版本
```

每次部署同一个key的流程时，版本号自动+1。

---

### 3. ProcessInstance (流程实例)

流程实例是流程定义的**运行时实例**，每次发起流程都会创建一个新的流程实例。

**核心属性**:
- **id**: 流程实例的唯一标识
- **processDefinitionId**: 关联的流程定义ID
- **businessKey**: 业务主键（关联业务数据）
- **startUserId**: 流程发起人
- **variables**: 流程变量

**生命周期**:
```
创建 → 运行中 → 挂起/激活 → 结束
```

**存储位置**:
- 运行中: `act_ru_execution` 表
- 历史记录: `act_hi_procinst` 表

---

### 4. Task (任务)

任务是流程中需要人工处理的节点。

**任务类型**:
- **UserTask**: 用户任务（需要人工审批）
- **ServiceTask**: 服务任务（自动执行）
- **ScriptTask**: 脚本任务（执行脚本）
- **ReceiveTask**: 接收任务（等待外部信号）

**核心属性**:
- **id**: 任务ID
- **name**: 任务名称
- **assignee**: 任务处理人
- **candidateUsers**: 候选用户
- **candidateGroups**: 候选组
- **variables**: 任务变量

**存储位置**:
- 运行中: `act_ru_task` 表
- 历史记录: `act_hi_taskinst` 表

---

### 5. Execution (执行实例)

Execution 代表流程执行的**路径**。

**Execution vs ProcessInstance**:
- ProcessInstance 是特殊的 Execution（根执行实例）
- 当流程中有并行网关时，会产生多个 Execution
- 每个 Execution 代表一条执行路径

```
流程实例 (ProcessInstance)
    ├── Execution 1 (主路径)
    ├── Execution 2 (并行路径A)
    └── Execution 3 (并行路径B)
```

---

### 6. HistoricProcessInstance (历史流程实例)

包含已结束和运行中的所有流程实例。

**关系**:
```
HistoricProcessInstance = ProcessInstance (运行中) + 已结束的流程实例
```

**使用场景**:
- 查询所有流程实例（无论是否结束）
- 流程追溯和审计
- 报表统计

---

## Flowable 架构设计

### 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│  业务应用层                                                  │
│  ├─ BenchmarkService                                        │
│  ├─ BuyListService                                          │
│  └─ ModelPortfolioService                                   │
├─────────────────────────────────────────────────────────────┤
│  BPM 封装层 (项目自定义)                                     │
│  ├─ BpmProcessInstanceApi                                   │
│  ├─ BpmTaskService                                          │
│  ├─ BpmProcessInstanceEventPublisher                        │
│  └─ BpmTaskCandidateInvoker                                 │
├─────────────────────────────────────────────────────────────┤
│  Flowable 服务层                                             │
│  ├─ RepositoryService (流程定义)                             │
│  ├─ RuntimeService (流程实例)                                │
│  ├─ TaskService (任务管理)                                   │
│  ├─ HistoryService (历史查询)                                │
│  └─ ManagementService (引擎管理)                             │
├─────────────────────────────────────────────────────────────┤
│  Flowable 引擎核心                                           │
│  ├─ ProcessEngineConfiguration                              │
│  ├─ CommandExecutor (命令执行器)                             │
│  ├─ AsyncExecutor (异步执行器)                               │
│  └─ EventDispatcher (事件分发器)                             │
├─────────────────────────────────────────────────────────────┤
│  持久化层                                                    │
│  ├─ MyBatis (ORM框架)                                       │
│  └─ JDBC DataSource                                         │
├─────────────────────────────────────────────────────────────┤
│  数据库层                                                    │
│  └─ MySQL/Oracle/PostgreSQL/SQL Server                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Flowable 五大核心 Service

### 1. RepositoryService (流程定义管理)

**职责**: 管理流程定义和部署。

**核心功能**:
```java
RepositoryService repositoryService;

// 1. 部署流程定义
Deployment deployment = repositoryService.createDeployment()
    .name("Benchmark流程")
    .addClasspathResource("processes/benchmark.bpmn20.xml")
    .deploy();

// 2. 查询流程定义
ProcessDefinition processDefinition = repositoryService
    .createProcessDefinitionQuery()
    .processDefinitionKey("benchmark")
    .latestVersion()  // 获取最新版本
    .singleResult();

// 3. 获取流程图
InputStream diagram = repositoryService
    .getProcessDiagram(processDefinition.getId());

// 4. 删除部署
repositoryService.deleteDeployment(deploymentId, true); // true=级联删除
```

**PAP 项目中的使用**:
```java
// BpmProcessDefinitionService.java
public BpmnModel getProcessDefinitionBpmnModel(String processDefinitionId) {
    return repositoryService.getBpmnModel(processDefinitionId);
}
```

---

### 2. RuntimeService (流程实例管理)

**职责**: 管理运行中的流程实例和执行实例。

**核心功能**:
```java
RuntimeService runtimeService;

// 1. 启动流程实例
ProcessInstance processInstance = runtimeService
    .startProcessInstanceByKey("benchmark")
    .businessKey("A001")  // 业务主键
    .variable("day", 7)   // 流程变量
    .start();

// 2. 查询流程实例
ProcessInstance instance = runtimeService
    .createProcessInstanceQuery()
    .processInstanceId(processInstanceId)
    .includeProcessVariables()  // 包含流程变量
    .singleResult();

// 3. 设置流程变量
runtimeService.setVariable(processInstanceId, "approved", true);

// 4. 挂起/激活流程实例
runtimeService.suspendProcessInstanceById(processInstanceId);
runtimeService.activateProcessInstanceById(processInstanceId);

// 5. 删除流程实例
runtimeService.deleteProcessInstance(processInstanceId, "取消流程");
```

**PAP 项目中的使用**:
```java
// BpmProcessInstanceServiceImpl.java:125
public ProcessInstance getProcessInstance(String id) {
    return runtimeService.createProcessInstanceQuery()
        .includeProcessVariables()
        .processInstanceId(id)
        .singleResult();
}
```

---

### 3. TaskService (任务管理)

**职责**: 管理用户任务。

**核心功能**:
```java
TaskService taskService;

// 1. 查询待办任务
List<Task> tasks = taskService.createTaskQuery()
    .taskAssignee(userId)  // 分配给某用户
    .active()  // 激活状态
    .orderByTaskCreateTime().desc()
    .list();

// 2. 查询候选任务
List<Task> candidateTasks = taskService.createTaskQuery()
    .taskCandidateUser(userId)  // 候选用户
    .list();

// 3. 认领任务
taskService.claim(taskId, userId);

// 4. 完成任务
Map<String, Object> variables = new HashMap<>();
variables.put("approved", true);
taskService.complete(taskId, variables);

// 5. 委派任务
taskService.delegateTask(taskId, targetUserId);

// 6. 添加评论
taskService.addComment(taskId, processInstanceId, "同意审批");
```

**PAP 项目中的使用**:
```java
// BpmTaskServiceImpl.java:138
public Long getTaskTodoCount(Long userId) {
    TaskQuery taskQuery = taskService.createTaskQuery()
        .taskAssignee(String.valueOf(userId))
        .active()
        .includeProcessVariables()
        .orderByTaskCreateTime().desc();
    return taskQuery.count();
}
```

---

### 4. HistoryService (历史数据查询)

**职责**: 查询历史数据（已结束和运行中的）。

**核心功能**:
```java
HistoryService historyService;

// 1. 查询历史流程实例
HistoricProcessInstance historicProcessInstance = historyService
    .createHistoricProcessInstanceQuery()
    .processInstanceId(processInstanceId)
    .includeProcessVariables()
    .singleResult();

// 2. 查询历史任务
List<HistoricTaskInstance> tasks = historyService
    .createHistoricTaskInstanceQuery()
    .processInstanceId(processInstanceId)
    .orderByHistoricTaskInstanceEndTime().desc()
    .list();

// 3. 查询历史活动
List<HistoricActivityInstance> activities = historyService
    .createHistoricActivityInstanceQuery()
    .processInstanceId(processInstanceId)
    .orderByHistoricActivityInstanceStartTime().asc()
    .list();

// 4. 查询历史变量
List<HistoricVariableInstance> variables = historyService
    .createHistoricVariableInstanceQuery()
    .processInstanceId(processInstanceId)
    .list();
```

**PAP 项目中的使用**:
```java
// BpmProcessInstanceServiceImpl.java:138
public HistoricProcessInstance getHistoricProcessInstance(String id) {
    return historyService.createHistoricProcessInstanceQuery()
        .processInstanceId(id)
        .includeProcessVariables()
        .singleResult();
}
```

---

### 5. ManagementService (引擎管理)

**职责**: 管理引擎、作业和定时器。

**核心功能**:
```java
ManagementService managementService;

// 1. 查询定时任务
List<Job> jobs = managementService.createTimerJobQuery().list();

// 2. 执行定时任务
managementService.moveTimerToExecutableJob(jobId);
managementService.executeJob(jobId);

// 3. 查询死信任务
List<Job> deadLetterJobs = managementService.createDeadLetterJobQuery().list();

// 4. 数据库表查询
TableMetaData tableMetaData = managementService.getTableMetaData("act_ru_task");
```

---

## Flowable 数据库表结构

Flowable 使用约 **28 张核心表**，分为 5 大类：

### 1. 通用表 (General - GE)

| 表名 | 说明 |
|------|------|
| **act_ge_property** | 属性配置表（存储引擎级别的配置） |
| **act_ge_bytearray** | 二进制数据表（存储流程定义、流程图等） |

### 2. 流程定义表 (Repository - RE)

| 表名 | 说明 |
|------|------|
| **act_re_deployment** | 部署信息表 |
| **act_re_procdef** | 流程定义表 |
| **act_re_model** | 流程模型表 |

**示例数据**:
```sql
-- act_re_procdef
id                   | key       | name          | version | deployment_id
---------------------|-----------|---------------|---------|---------------
benchmark:1:4028     | benchmark | Benchmark流程 | 1       | 4025
benchmark:2:4056     | benchmark | Benchmark流程 | 2       | 4053
```

### 3. 运行时表 (Runtime - RU)

| 表名 | 说明 |
|------|------|
| **act_ru_execution** | 流程执行实例表 |
| **act_ru_task** | 任务表（待办任务） |
| **act_ru_variable** | 流程变量表 |
| **act_ru_identitylink** | 用户关系表（候选人、候选组） |
| **act_ru_event_subscr** | 事件订阅表 |
| **act_ru_job** | 作业表（异步任务） |
| **act_ru_timer_job** | 定时任务表 |
| **act_ru_suspended_job** | 挂起任务表 |
| **act_ru_deadletter_job** | 死信任务表 |

**act_ru_task 核心字段**:
```sql
id_              VARCHAR(64)   -- 任务ID
name_            VARCHAR(255)  -- 任务名称
assignee_        VARCHAR(255)  -- 处理人
create_time_     DATETIME      -- 创建时间
proc_inst_id_    VARCHAR(64)   -- 流程实例ID
proc_def_id_     VARCHAR(64)   -- 流程定义ID
task_def_key_    VARCHAR(255)  -- 任务定义key
```

### 4. 历史表 (History - HI)

| 表名 | 说明 |
|------|------|
| **act_hi_procinst** | 历史流程实例表 |
| **act_hi_taskinst** | 历史任务表 |
| **act_hi_actinst** | 历史活动节点表 |
| **act_hi_varinst** | 历史变量表 |
| **act_hi_identitylink** | 历史用户关系表 |
| **act_hi_comment** | 历史评论表 |
| **act_hi_attachment** | 历史附件表 |
| **act_hi_detail** | 历史详细信息表 |

**act_hi_procinst 核心字段**:
```sql
id_                  VARCHAR(64)   -- 流程实例ID
proc_def_id_         VARCHAR(64)   -- 流程定义ID
business_key_        VARCHAR(255)  -- 业务主键
start_user_id_       VARCHAR(255)  -- 发起人
start_time_          DATETIME      -- 开始时间
end_time_            DATETIME      -- 结束时间
duration_            BIGINT        -- 持续时间（毫秒）
delete_reason_       VARCHAR(4000) -- 删除原因
```

### 5. 事件日志表 (Event Log - EVT)

| 表名 | 说明 |
|------|------|
| **act_evt_log** | 事件日志表 |

---

### 表之间的关系

```
act_re_procdef (流程定义)
    ↓ 1:N
act_hi_procinst (历史流程实例)
    ↓ 1:N
act_hi_taskinst (历史任务)
    ↓ 1:N
act_hi_actinst (历史活动)

运行时:
act_ru_execution (执行实例)
    ↓ 1:N
act_ru_task (任务)
    ↓ 1:N
act_ru_identitylink (用户关系)
```

---

## 流程实例生命周期

### 生命周期状态图

```
┌─────────────┐
│   创建流程  │
└──────┬──────┘
       │ createProcessInstance()
       ↓
┌─────────────┐
│   运行中    │ ← activate()
│  (RUNNING)  │
└──┬────┬─────┘
   │    │ suspend()
   │    ↓
   │  ┌─────────────┐
   │  │   挂起      │
   │  │ (SUSPENDED) │
   │  └──────┬──────┘
   │         │ activate()
   │         ↓
   │  (返回运行中)
   │
   │ complete()
   ↓
┌─────────────┐
│   已完成    │
│ (COMPLETED) │
└─────────────┘
```

### 详细流程

#### 1. 创建流程实例

```java
// BpmProcessInstanceServiceImpl.java
public String createProcessInstance(Long userId, BpmProcessInstanceCreateReqDTO reqDTO) {
    // 1. 验证流程定义
    ProcessDefinition processDefinition =
        processDefinitionService.getProcessDefinition(reqDTO.getProcessDefinitionKey());

    // 2. 构建流程实例
    ProcessInstanceBuilder processInstanceBuilder = runtimeService
        .createProcessInstanceBuilder()
        .processDefinitionId(processDefinition.getId())
        .businessKey(reqDTO.getBusinessKey())  // 业务主键
        .variables(reqDTO.getVariables());  // 流程变量

    // 3. 启动流程
    ProcessInstance processInstance = processInstanceBuilder.start();

    return processInstance.getId();
}
```

**执行流程**:
```
1. 解析流程定义 (BPMN XML)
2. 创建流程实例记录 (act_ru_execution + act_hi_procinst)
3. 初始化流程变量 (act_ru_variable)
4. 执行开始事件 (StartEvent)
5. 进入第一个用户任务节点
6. 创建任务记录 (act_ru_task + act_hi_taskinst)
7. 计算任务候选人
8. 发送消息通知
```

---

#### 2. 任务审批

```java
// BpmTaskServiceImpl.java
public void approveTask(BpmTaskApproveReqVO reqVO) {
    // 1. 验证任务
    Task task = taskService.createTaskQuery()
        .taskId(reqVO.getId())
        .singleResult();

    // 2. 添加审批意见
    taskService.addComment(
        reqVO.getId(),
        task.getProcessInstanceId(),
        "同意"
    );

    // 3. 设置流程变量
    Map<String, Object> variables = new HashMap<>();
    variables.put("approved", true);

    // 4. 完成任务
    taskService.complete(reqVO.getId(), variables);
}
```

**执行流程**:
```
1. 验证任务是否存在
2. 检查任务处理人权限
3. 保存审批意见 (act_hi_comment)
4. 设置流程变量
5. 完成任务 (删除 act_ru_task 记录)
6. 更新历史任务 (act_hi_taskinst.end_time)
7. 执行流程引擎
8. 进入下一个节点
9. 如果是用户任务，创建新任务
10. 如果是结束事件，结束流程
```

---

#### 3. 流程结束

```
1. 执行结束事件 (EndEvent)
2. 删除运行时数据:
   - act_ru_execution (执行实例)
   - act_ru_task (任务)
   - act_ru_variable (变量)
3. 更新历史数据:
   - act_hi_procinst.end_time = NOW()
   - act_hi_procinst.duration = end_time - start_time
4. 发布流程结束事件 (BpmProcessInstanceStatusEvent)
5. 触发监听器 (BpmProcessInstanceStatusEventListener)
```

**PAP 项目中的监听器**:
```java
// BpmBenchmarkStatusListener.java
@Component
public class BpmBenchmarkStatusListener extends BpmProcessInstanceStatusEventListener {

    @Resource
    private BenchmarkService benchmarkService;

    @Override
    protected String getProcessDefinitionKey() {
        return "benchmark";  // 只监听 benchmark 流程
    }

    @Override
    protected void onEvent(BpmProcessInstanceStatusEvent event) {
        // 流程结束时，更新业务表状态
        benchmarkService.updateProcessStatus(
            event.getBusinessKey(),  // 业务ID
            event.getStatus()  // 流程状态（2-通过，3-拒绝）
        );
    }
}
```

---

## 任务分配机制

Flowable 支持多种任务分配策略：

### 1. 直接分配 (Assignee)

**BPMN 定义**:
```xml
<userTask id="approveTask" name="审批" flowable:assignee="${userId}">
</userTask>
```

**代码实现**:
```java
// 流程变量
variables.put("userId", "10001");

// 启动流程
runtimeService.startProcessInstanceByKey("benchmark")
    .variables(variables)
    .start();
```

**结果**:
- 任务直接分配给指定用户
- `act_ru_task.assignee_ = 10001`

---

### 2. 候选用户 (Candidate Users)

**BPMN 定义**:
```xml
<userTask id="approveTask" name="审批"
    flowable:candidateUsers="${candidateUserIds}">
</userTask>
```

**代码实现**:
```java
// 流程变量
variables.put("candidateUserIds", "10001,10002,10003");

// 任务查询
List<Task> tasks = taskService.createTaskQuery()
    .taskCandidateUser("10001")  // 10001的候选任务
    .list();

// 认领任务
taskService.claim(taskId, "10001");
```

**结果**:
- 任务没有assignee，但有多个候选人
- `act_ru_identitylink` 表记录候选关系
- 任何候选人都可以认领（claim）任务

---

### 3. 候选组 (Candidate Groups)

**BPMN 定义**:
```xml
<userTask id="approveTask" name="审批"
    flowable:candidateGroups="${candidateGroupIds}">
</userTask>
```

**代码实现**:
```java
// 流程变量
variables.put("candidateGroupIds", "managers,directors");

// 任务查询
List<Task> tasks = taskService.createTaskQuery()
    .taskCandidateGroup("managers")  // managers组的候选任务
    .list();
```

---

### 4. PAP 项目的自定义分配策略

PAP 项目实现了**动态候选人计算**机制：

```java
// BpmTaskCandidateInvoker.java
public class BpmTaskCandidateInvoker {

    // 候选人策略列表
    private final List<BpmTaskCandidateStrategy> strategyList;

    public Set<Long> calculateTaskCandidateUsers(TaskInfo task) {
        // 1. 从任务中获取策略配置
        String strategyType = getStrategyType(task);
        String strategyParam = getStrategyParam(task);

        // 2. 查找对应的策略
        BpmTaskCandidateStrategy strategy = findStrategy(strategyType);

        // 3. 计算候选人
        Set<Long> users = strategy.calculateUsers(task, strategyParam);

        return users;
    }
}
```

**支持的策略**:

| 策略 | 说明 | 示例 |
|------|------|------|
| **ROLE** | 角色 | 所有"经理"角色的用户 |
| **DEPT_MEMBER** | 部门成员 | 财务部的所有成员 |
| **DEPT_LEADER** | 部门负责人 | 提交人所在部门的负责人 |
| **POST** | 岗位 | 所有"主管"岗位的用户 |
| **USER** | 用户 | 指定用户 |
| **START_USER** | 发起人 | 流程发起人 |

**实现示例**:
```java
// BpmTaskCandidateRoleStrategy.java
@Component
public class BpmTaskCandidateRoleStrategy implements BpmTaskCandidateStrategy {

    @Override
    public BpmTaskCandidateStrategyEnum getStrategy() {
        return BpmTaskCandidateStrategyEnum.ROLE;
    }

    @Override
    public Set<Long> calculateUsers(TaskInfo task, String param) {
        // param = "100,101" (角色ID列表)
        Set<Long> roleIds = StrUtils.splitToLongSet(param);

        // 查询这些角色下的所有用户
        List<AdminUserRespDTO> users = adminUserApi.getUserListByRoleIds(roleIds);

        return convertSet(users, AdminUserRespDTO::getId);
    }
}
```

---

## 事件监听机制

Flowable 提供了强大的事件监听机制，用于在流程执行过程中的关键节点触发自定义逻辑。

### 事件类型

| 事件类型 | 触发时机 |
|---------|---------|
| **PROCESS_STARTED** | 流程启动时 |
| **PROCESS_COMPLETED** | 流程完成时 |
| **PROCESS_CANCELLED** | 流程取消时 |
| **TASK_CREATED** | 任务创建时 |
| **TASK_ASSIGNED** | 任务分配时 |
| **TASK_COMPLETED** | 任务完成时 |
| **ACTIVITY_STARTED** | 活动开始时 |
| **ACTIVITY_COMPLETED** | 活动完成时 |

### PAP 项目的事件监听实现

#### 1. 事件发布器

```java
// BpmProcessInstanceEventPublisher.java
public class BpmProcessInstanceEventPublisher implements FlowableEventListener {

    private final ApplicationEventPublisher publisher;

    @Override
    public void onEvent(FlowableEvent event) {
        // 只处理流程结束事件
        if (event.getType() != FlowableEngineEventType.PROCESS_COMPLETED &&
            event.getType() != FlowableEngineEventType.PROCESS_CANCELLED) {
            return;
        }

        // 获取流程实例信息
        HistoricProcessInstance instance = getHistoricProcessInstance(event);

        // 构建事件对象
        BpmProcessInstanceStatusEvent statusEvent = new BpmProcessInstanceStatusEvent(this);
        statusEvent.setId(instance.getId());
        statusEvent.setProcessDefinitionKey(instance.getProcessDefinitionKey());
        statusEvent.setBusinessKey(instance.getBusinessKey());
        statusEvent.setStatus(getStatus(event));  // 2-通过, 3-拒绝

        // 发布Spring事件
        publisher.publishEvent(statusEvent);
    }
}
```

#### 2. 业务监听器

```java
// BpmBenchmarkStatusListener.java
@Component
public class BpmBenchmarkStatusListener extends BpmProcessInstanceStatusEventListener {

    @Resource
    private BenchmarkService benchmarkService;

    @Override
    protected String getProcessDefinitionKey() {
        return "benchmark";
    }

    @Override
    protected void onEvent(BpmProcessInstanceStatusEvent event) {
        // 更新业务表状态
        benchmarkService.updateProcessStatus(
            event.getBusinessKey(),
            event.getStatus()
        );
    }
}
```

### 事件流转图

```
Flowable引擎
    ↓ 流程结束
FlowableEvent (PROCESS_COMPLETED)
    ↓
BpmProcessInstanceEventPublisher.onEvent()
    ↓ 发布Spring事件
BpmProcessInstanceStatusEvent
    ↓
BpmBenchmarkStatusListener.onApplicationEvent()
    ↓ 过滤 processDefinitionKey
BpmBenchmarkStatusListener.onEvent()
    ↓
BenchmarkService.updateProcessStatus()
    ↓
UPDATE benchmark SET status=2, checker='张三'
```

---

## 流程变量管理

### 流程变量的作用域

```
流程实例级别 (Process Instance Scope)
    ├── 全局变量 (Global Variables)
    │   └── 整个流程实例可访问
    │
    └── 任务级别 (Task Scope)
        ├── 局部变量 (Local Variables)
        └── 只在当前任务可访问
```

### 设置流程变量

```java
// 1. 启动流程时设置
Map<String, Object> variables = new HashMap<>();
variables.put("day", 7);
variables.put("amount", 10000);
runtimeService.startProcessInstanceByKey("benchmark")
    .variables(variables)
    .start();

// 2. 运行时设置（全局变量）
runtimeService.setVariable(processInstanceId, "approved", true);

// 3. 任务完成时设置
taskService.complete(taskId, variables);

// 4. 任务局部变量
taskService.setVariableLocal(taskId, "comment", "同意");
```

### 获取流程变量

```java
// 1. 获取单个变量
Object day = runtimeService.getVariable(processInstanceId, "day");

// 2. 获取所有变量
Map<String, Object> variables = runtimeService.getVariables(processInstanceId);

// 3. 从流程实例中获取
ProcessInstance instance = runtimeService.createProcessInstanceQuery()
    .processInstanceId(processInstanceId)
    .includeProcessVariables()  // 包含变量
    .singleResult();
Map<String, Object> vars = instance.getProcessVariables();

// 4. 从历史记录获取
HistoricProcessInstance historicInstance = historyService
    .createHistoricProcessInstanceQuery()
    .processInstanceId(processInstanceId)
    .includeProcessVariables()
    .singleResult();
Map<String, Object> vars = historicInstance.getProcessVariables();
```

### 变量在BPMN中的使用

```xml
<!-- 1. 网关条件 -->
<exclusiveGateway id="gateway1">
  <sequenceFlow targetRef="approve" name="同意">
    <conditionExpression>${approved == true}</conditionExpression>
  </sequenceFlow>
  <sequenceFlow targetRef="reject" name="拒绝">
    <conditionExpression>${approved == false}</conditionExpression>
  </sequenceFlow>
</exclusiveGateway>

<!-- 2. 任务分配 -->
<userTask id="task1" flowable:assignee="${assignee}">
</userTask>

<!-- 3. 服务任务 -->
<serviceTask id="notify"
    flowable:expression="${notifyService.send(execution.processInstanceId)}">
</serviceTask>
```

### PAP 项目中的流程变量

```java
// BenchmarkServiceImpl.java:155
Map<String, Object> processInstanceVariables = new HashMap<>();
// 可以添加业务相关的变量
// processInstanceVariables.put("day", day);

String processInstanceId = processInstanceApi.createProcessInstance(
    getLoginUserId(),
    new BpmProcessInstanceCreateReqDTO()
        .setProcessDefinitionKey(PROCESS_KEY)
        .setVariables(processInstanceVariables)
        .setBusinessKey(String.valueOf(insertObj.getId()))
);
```

### 变量存储位置

```
运行时:
act_ru_variable
    ├── name_ (变量名)
    ├── type_ (变量类型: string, integer, boolean, serializable)
    ├── text_ (字符串值)
    ├── long_ (长整型值)
    ├── double_ (浮点型值)
    └── bytearray_id_ (序列化对象ID)

历史:
act_hi_varinst (历史变量实例)
```

---

## Flowable 与 Spring 集成原理

### 1. 自动配置

Flowable 提供了 Spring Boot Starter，自动配置所有核心组件：

```xml
<dependency>
    <groupId>org.flowable</groupId>
    <artifactId>flowable-spring-boot-starter</artifactId>
    <version>7.0.1</version>
</dependency>
```

**自动配置的组件**:
```
FlowableAutoConfiguration
    ├── ProcessEngine (流程引擎)
    ├── RepositoryService
    ├── RuntimeService
    ├── TaskService
    ├── HistoryService
    ├── ManagementService
    └── AsyncExecutor (异步执行器)
```

---

### 2. 数据源集成

Flowable 使用 Spring 的 DataSource：

```yaml
# application.yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/flowable
    username: root
    password: password
    driver-class-name: com.mysql.cj.jdbc.Driver
```

Flowable 会自动:
1. 检测数据库表是否存在
2. 如果不存在，自动创建表（默认行为）
3. 如果存在，检查版本并自动升级

**配置选项**:
```yaml
flowable:
  database-schema-update: true  # 自动更新表结构
  # 可选值:
  # - false: 不检查
  # - true: 自动创建/更新
  # - create-drop: 每次重启都重建表
```

---

### 3. 事务管理

Flowable 完全集成 Spring 的事务管理：

```java
@Service
public class BenchmarkServiceImpl {

    @Transactional(rollbackFor = Exception.class)
    public void updateBenchmark(List<BenchmarkDetailsReqVo> updateReqVO) {
        // 1. 更新业务数据
        benchmarkMapper.updateById(updateObj);

        // 2. 发起流程（与业务数据在同一事务中）
        String processInstanceId = processInstanceApi.createProcessInstance(...);

        // 3. 更新流程ID
        benchmarkMapper.updateById(new BenchmarkDO()
            .setId(insertObj.getId())
            .setProcessInstanceId(processInstanceId));

        // 如果任何步骤失败，所有操作都会回滚
    }
}
```

**事务传播**:
- Flowable 的操作会加入当前 Spring 事务
- 如果 Spring 事务回滚，Flowable 的操作也会回滚
- 保证业务数据和流程数据的一致性

---

### 4. 异步执行器

Flowable 使用 Spring 的 TaskExecutor：

```java
// BpmFlowableConfiguration.java:36
@Bean(name = "applicationTaskExecutor")
public AsyncListenableTaskExecutor taskExecutor() {
    ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
    executor.setCorePoolSize(8);
    executor.setMaxPoolSize(8);
    executor.setQueueCapacity(100);
    executor.setThreadNamePrefix("flowable-task-Executor-");
    executor.setAwaitTerminationSeconds(30);
    executor.setWaitForTasksToCompleteOnShutdown(true);
    executor.setAllowCoreThreadTimeOut(true);
    executor.initialize();
    return executor;
}
```

**异步执行器的作用**:
- 处理异步任务（ServiceTask with async=true）
- 处理定时任务（TimerEvent）
- 提高并发性能

---

### 5. 自定义配置

PAP 项目通过 `EngineConfigurationConfigurer` 自定义配置：

```java
@Bean
public EngineConfigurationConfigurer<SpringProcessEngineConfiguration>
    bpmProcessEngineConfigurationConfigurer(...) {
    return configuration -> {
        // 1. 注册事件监听器
        configuration.setEventListeners(
            ListUtil.toList(listeners.iterator())
        );

        // 2. 设置自定义的 ActivityBehaviorFactory
        configuration.setActivityBehaviorFactory(
            bpmActivityBehaviorFactory
        );

        // 3. 注册自定义函数
        configuration.setCustomFlowableFunctionDelegates(
            ListUtil.toList(customFlowableFunctionDelegates.iterator())
        );
    };
}
```

---

## 总结与最佳实践

### Flowable 核心原理总结

| 核心概念 | 本质 | 存储位置 |
|---------|------|---------|
| **ProcessDefinition** | 流程模板 | act_re_procdef |
| **ProcessInstance** | 流程实例 | act_ru_execution + act_hi_procinst |
| **Task** | 待办任务 | act_ru_task + act_hi_taskinst |
| **Execution** | 执行路径 | act_ru_execution |
| **Variable** | 流程变量 | act_ru_variable + act_hi_varinst |

### 数据流转原理

```
1. 部署流程
   BPMN XML → 解析 → act_re_procdef + act_ge_bytearray

2. 启动流程
   ProcessDefinition → 创建 ProcessInstance → act_ru_execution
                                             → act_hi_procinst

3. 执行任务
   进入UserTask → 创建Task → act_ru_task + act_hi_taskinst
                           → 计算候选人 → act_ru_identitylink

4. 完成任务
   taskService.complete() → 删除 act_ru_task
                          → 更新 act_hi_taskinst
                          → 流程引擎继续执行
                          → 进入下一个节点

5. 结束流程
   到达EndEvent → 删除 act_ru_execution
                → 更新 act_hi_procinst.end_time
                → 发布事件 → 触发监听器
```

### 最佳实践

#### 1. 流程设计

- ✅ 流程定义的 key 使用业务含义的名称（如：`benchmark`）
- ✅ 使用版本管理，支持流程升级
- ✅ 合理使用子流程，拆分复杂流程
- ✅ 使用网关控制流转逻辑

#### 2. 任务分配

- ✅ 优先使用候选人/候选组，而非直接分配
- ✅ 实现动态候选人计算策略
- ✅ 支持任务认领（claim）机制
- ✅ 记录任务处理人和处理时间

#### 3. 流程变量

- ✅ 使用有意义的变量名
- ✅ 避免存储大对象（使用 businessKey 关联业务数据）
- ✅ 区分全局变量和局部变量
- ✅ 在流程结束后清理不必要的变量

#### 4. 事件监听

- ✅ 使用事件监听器解耦业务逻辑
- ✅ 在监听器中更新业务表状态
- ✅ 避免在监听器中执行耗时操作
- ✅ 使用 Spring 事件机制进行二次分发

#### 5. 性能优化

- ✅ 使用异步执行器处理异步任务
- ✅ 定期清理历史数据
- ✅ 使用索引优化查询
- ✅ 避免在流程中存储大量数据

#### 6. 与业务系统集成

- ✅ 使用 businessKey 关联业务数据
- ✅ 业务数据和流程数据使用同一事务
- ✅ 通过 API 层封装 Flowable 调用
- ✅ 流程结束后同步更新业务状态

---

## 附录：关键代码位置

| 功能模块 | 文件路径 |
|---------|---------|
| **Flowable配置** | `pap-server/bpm/framework/flowable/config/BpmFlowableConfiguration.java` |
| **流程实例API** | `pap-server/bpm/api/task/BpmProcessInstanceApi.java` |
| **流程实例Service** | `pap-server/bpm/service/task/BpmProcessInstanceServiceImpl.java` |
| **任务Service** | `pap-server/bpm/service/task/BpmTaskServiceImpl.java` |
| **事件发布器** | `pap-server/bpm/framework/flowable/core/event/BpmProcessInstanceEventPublisher.java` |
| **事件监听器基类** | `pap-server/bpm/api/event/BpmProcessInstanceStatusEventListener.java` |
| **业务监听器** | `pap-server/business/listener/BpmBenchmarkStatusListener.java` |
| **候选人计算** | `pap-server/bpm/framework/flowable/core/candidate/BpmTaskCandidateInvoker.java` |

---

**文档结束** | 通过深入剖析 Flowable 的核心原理，我们理解了工作流引擎如何通过 **流程定义**、**流程实例**、**任务**、**执行实例** 等核心概念，配合 **五大Service** 和 **数据库表结构**，实现企业级的流程管理。PAP 项目的实践展示了如何通过 **事件监听**、**候选人计算**、**Spring集成** 等机制，将 Flowable 无缝融入业务系统。
