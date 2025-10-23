# Flowable 工作流引擎使用实战指南

> **作者**: Claude Code
> **日期**: 2025-10-23
> **项目**: PAP (Private & Retail Banking Management System)
> **Flowable 版本**: 7.0.1
> **适用场景**: Spring Boot 3.x + Flowable 7.x

---

## 📚 目录

1. [快速开始](#快速开始)
2. [环境搭建](#环境搭建)
3. [流程定义与部署](#流程定义与部署)
4. [流程实例管理](#流程实例管理)
5. [任务管理](#任务管理)
6. [流程变量操作](#流程变量操作)
7. [事件监听器开发](#事件监听器开发)
8. [与业务系统集成](#与业务系统集成)
9. [常见场景实战](#常见场景实战)
10. [常见问题与解决方案](#常见问题与解决方案)

---

## 快速开始

### 5分钟快速体验

#### 1. 添加依赖

```xml
<!-- pom.xml -->
<dependencies>
    <!-- Flowable Spring Boot Starter -->
    <dependency>
        <groupId>org.flowable</groupId>
        <artifactId>flowable-spring-boot-starter</artifactId>
        <version>7.0.1</version>
    </dependency>

    <!-- Spring Boot Web -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <!-- 数据库驱动 -->
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
    </dependency>
</dependencies>
```

---

#### 2. 配置数据源

```yaml
# application.yml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/flowable?useUnicode=true&characterEncoding=utf8
    username: root
    password: password
    driver-class-name: com.mysql.cj.jdbc.Driver

flowable:
  database-schema-update: true  # 自动创建表
  async-executor-activate: true  # 启用异步执行器
```

---

#### 3. 创建流程定义

在 `src/main/resources/processes/` 目录下创建 `vacation.bpmn20.xml`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
             xmlns:flowable="http://flowable.org/bpmn"
             targetNamespace="Examples">

  <process id="vacation" name="请假流程" isExecutable="true">

    <!-- 开始事件 -->
    <startEvent id="start"/>

    <!-- 提交申请 -->
    <userTask id="submitTask" name="提交请假申请"
              flowable:assignee="${startUserId}"/>

    <!-- 经理审批 -->
    <userTask id="managerApproval" name="经理审批"
              flowable:candidateGroups="managers"/>

    <!-- 排他网关：根据审批结果决定流向 -->
    <exclusiveGateway id="decision"/>

    <!-- 审批通过 -->
    <userTask id="hrTask" name="HR归档"
              flowable:candidateGroups="hr"/>

    <!-- 审批拒绝 -->
    <userTask id="rejectTask" name="拒绝通知"
              flowable:assignee="${startUserId}"/>

    <!-- 结束事件 -->
    <endEvent id="end"/>

    <!-- 流程流转 -->
    <sequenceFlow sourceRef="start" targetRef="submitTask"/>
    <sequenceFlow sourceRef="submitTask" targetRef="managerApproval"/>
    <sequenceFlow sourceRef="managerApproval" targetRef="decision"/>

    <sequenceFlow sourceRef="decision" targetRef="hrTask" name="同意">
      <conditionExpression>${approved == true}</conditionExpression>
    </sequenceFlow>

    <sequenceFlow sourceRef="decision" targetRef="rejectTask" name="拒绝">
      <conditionExpression>${approved == false}</conditionExpression>
    </sequenceFlow>

    <sequenceFlow sourceRef="hrTask" targetRef="end"/>
    <sequenceFlow sourceRef="rejectTask" targetRef="end"/>
  </process>
</definitions>
```

---

#### 4. 编写控制器

```java
@RestController
@RequestMapping("/vacation")
public class VacationController {

    @Resource
    private RuntimeService runtimeService;

    @Resource
    private TaskService taskService;

    // 发起请假流程
    @PostMapping("/start")
    public String startVacation(@RequestParam String employeeName,
                                @RequestParam Integer days) {
        Map<String, Object> variables = new HashMap<>();
        variables.put("employeeName", employeeName);
        variables.put("days", days);
        variables.put("startUserId", "10001");

        ProcessInstance processInstance = runtimeService
            .startProcessInstanceByKey("vacation")
            .businessKey("VAC-" + System.currentTimeMillis())
            .variables(variables)
            .start();

        return "流程已启动，流程实例ID: " + processInstance.getId();
    }

    // 查询待办任务
    @GetMapping("/tasks")
    public List<Map<String, Object>> getTasks(@RequestParam String userId) {
        List<Task> tasks = taskService.createTaskQuery()
            .taskAssignee(userId)
            .list();

        return tasks.stream().map(task -> {
            Map<String, Object> map = new HashMap<>();
            map.put("taskId", task.getId());
            map.put("taskName", task.getName());
            map.put("processInstanceId", task.getProcessInstanceId());
            return map;
        }).collect(Collectors.toList());
    }

    // 完成任务（经理审批）
    @PostMapping("/approve")
    public String approve(@RequestParam String taskId,
                          @RequestParam Boolean approved) {
        Map<String, Object> variables = new HashMap<>();
        variables.put("approved", approved);

        taskService.complete(taskId, variables);

        return "审批完成";
    }
}
```

---

#### 5. 启动应用

```bash
mvn spring-boot:run
```

#### 6. 测试流程

```bash
# 1. 发起请假
curl -X POST "http://localhost:8080/vacation/start?employeeName=张三&days=3"

# 2. 查询待办任务
curl "http://localhost:8080/vacation/tasks?userId=manager001"

# 3. 经理审批
curl -X POST "http://localhost:8080/vacation/approve?taskId=xxx&approved=true"
```

---

## 环境搭建

### Maven 依赖配置

```xml
<!-- pap-dependencies/pom.xml -->
<properties>
    <flowable.version>7.0.1</flowable.version>
</properties>

<dependencyManagement>
    <dependencies>
        <!-- Flowable BOM -->
        <dependency>
            <groupId>org.flowable</groupId>
            <artifactId>flowable-bom</artifactId>
            <version>${flowable.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<!-- 项目依赖 -->
<dependencies>
    <!-- Flowable Spring Boot Starter -->
    <dependency>
        <groupId>org.flowable</groupId>
        <artifactId>flowable-spring-boot-starter</artifactId>
    </dependency>

    <!-- Flowable Spring Boot Starter Process (核心) -->
    <dependency>
        <groupId>org.flowable</groupId>
        <artifactId>flowable-spring-boot-starter-process</artifactId>
    </dependency>

    <!-- Flowable UI (可选，提供流程设计器) -->
    <dependency>
        <groupId>org.flowable</groupId>
        <artifactId>flowable-spring-boot-starter-ui-modeler</artifactId>
    </dependency>
</dependencies>
```

---

### 数据库配置

Flowable 支持多种数据库：

#### MySQL

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/flowable?useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&nullCatalogMeansCurrent=true
    username: root
    password: password
    driver-class-name: com.mysql.cj.jdbc.Driver
```

#### SQL Server

```yaml
spring:
  datasource:
    url: jdbc:sqlserver://localhost:1433;DatabaseName=flowable;encrypt=false
    username: sa
    password: password
    driver-class-name: com.microsoft.sqlserver.jdbc.SQLServerDriver
```

#### Oracle

```yaml
spring:
  datasource:
    url: jdbc:oracle:thin:@localhost:1521:xe
    username: flowable
    password: password
    driver-class-name: oracle.jdbc.OracleDriver
```

#### PostgreSQL

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/flowable
    username: postgres
    password: password
    driver-class-name: org.postgresql.Driver
```

---

### Flowable 配置

```yaml
flowable:
  # 数据库表更新策略
  database-schema-update: true
  # 可选值:
  # - false: 不检查表结构
  # - true: 自动创建/更新表
  # - create-drop: 每次启动时删除并重建表

  # 异步执行器
  async-executor-activate: true  # 启用异步执行器
  async-executor-core-pool-size: 8  # 核心线程数
  async-executor-max-pool-size: 8  # 最大线程数

  # 历史级别
  history-level: full
  # 可选值:
  # - none: 不记录历史
  # - activity: 记录流程实例和活动
  # - audit: 记录流程实例、活动和变量
  # - full: 记录所有信息（包括表单属性）

  # 流程定义缓存
  process-definition-cache-limit: 100

  # 邮件服务器配置（可选）
  mail:
    server:
      host: smtp.example.com
      port: 587
      username: noreply@example.com
      password: password
```

---

### Spring Boot 配置类

```java
@Configuration
public class FlowableConfiguration {

    /**
     * 配置异步执行器线程池
     */
    @Bean(name = "applicationTaskExecutor")
    @ConditionalOnMissingBean(name = "applicationTaskExecutor")
    public AsyncListenableTaskExecutor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(8);
        executor.setMaxPoolSize(8);
        executor.setQueueCapacity(100);
        executor.setThreadNamePrefix("flowable-task-");
        executor.setAwaitTerminationSeconds(30);
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAllowCoreThreadTimeOut(true);
        executor.initialize();
        return executor;
    }

    /**
     * 自定义流程引擎配置
     */
    @Bean
    public EngineConfigurationConfigurer<SpringProcessEngineConfiguration>
        processEngineConfigurationConfigurer() {
        return configuration -> {
            // 设置字体（解决流程图中文乱码）
            configuration.setActivityFontName("宋体");
            configuration.setLabelFontName("宋体");
            configuration.setAnnotationFontName("宋体");

            // 禁用安全性检查（开发环境）
            configuration.setDisableIdmEngine(true);
        };
    }
}
```

---

## 流程定义与部署

### BPMN 2.0 基础元素

#### 1. 开始事件 (Start Event)

```xml
<!-- 普通开始事件 -->
<startEvent id="start"/>

<!-- 定时开始事件 -->
<startEvent id="timerStart">
  <timerEventDefinition>
    <timeCycle>0 0 9 * * ?</timeCycle>  <!-- 每天9点 -->
  </timerEventDefinition>
</startEvent>

<!-- 消息开始事件 -->
<startEvent id="messageStart">
  <messageEventDefinition messageRef="newOrderMessage"/>
</startEvent>
```

---

#### 2. 用户任务 (User Task)

```xml
<!-- 直接分配 -->
<userTask id="approveTask" name="审批"
          flowable:assignee="${managerId}"/>

<!-- 候选用户 -->
<userTask id="approveTask" name="审批"
          flowable:candidateUsers="${candidateUserIds}"/>

<!-- 候选组 -->
<userTask id="approveTask" name="审批"
          flowable:candidateGroups="managers,directors"/>

<!-- 动态分配 -->
<userTask id="approveTask" name="审批"
          flowable:assignee="${taskCandidateInvoker.calculateAssignee(execution)}"/>

<!-- 表单属性 -->
<userTask id="approveTask" name="审批">
  <extensionElements>
    <flowable:formProperty id="approved" name="是否同意"
                           type="boolean" required="true"/>
    <flowable:formProperty id="comment" name="审批意见"
                           type="string"/>
  </extensionElements>
</userTask>
```

---

#### 3. 服务任务 (Service Task)

```xml
<!-- 调用Java类 -->
<serviceTask id="sendEmail" name="发送邮件"
             flowable:class="cn.bochk.pap.server.bpm.task.SendEmailTask"/>

<!-- 调用表达式 -->
<serviceTask id="notify" name="发送通知"
             flowable:expression="${notifyService.send(execution)}"/>

<!-- 委托表达式 -->
<serviceTask id="calculate" name="计算"
             flowable:delegateExpression="${calculationDelegate}"/>
```

**Java类实现**:
```java
public class SendEmailTask implements JavaDelegate {

    @Override
    public void execute(DelegateExecution execution) {
        // 获取流程变量
        String email = (String) execution.getVariable("email");
        String content = (String) execution.getVariable("content");

        // 发送邮件
        sendEmail(email, content);

        // 设置返回变量
        execution.setVariable("emailSent", true);
    }
}
```

---

#### 4. 排他网关 (Exclusive Gateway)

```xml
<exclusiveGateway id="decision"/>

<sequenceFlow sourceRef="decision" targetRef="approve" name="同意">
  <conditionExpression>${approved == true}</conditionExpression>
</sequenceFlow>

<sequenceFlow sourceRef="decision" targetRef="reject" name="拒绝">
  <conditionExpression>${approved == false}</conditionExpression>
</sequenceFlow>

<!-- 默认流向（当所有条件都不满足时） -->
<sequenceFlow sourceRef="decision" targetRef="defaultTask"
              id="defaultFlow"/>
<exclusiveGateway id="decision" default="defaultFlow"/>
```

---

#### 5. 并行网关 (Parallel Gateway)

```xml
<!-- 分支：同时执行多个任务 -->
<parallelGateway id="fork"/>

<sequenceFlow sourceRef="fork" targetRef="task1"/>
<sequenceFlow sourceRef="fork" targetRef="task2"/>
<sequenceFlow sourceRef="fork" targetRef="task3"/>

<!-- 合并：等待所有分支完成 -->
<parallelGateway id="join"/>

<sequenceFlow sourceRef="task1" targetRef="join"/>
<sequenceFlow sourceRef="task2" targetRef="join"/>
<sequenceFlow sourceRef="task3" targetRef="join"/>
```

---

#### 6. 子流程 (Sub Process)

```xml
<!-- 内嵌子流程 -->
<subProcess id="subProcess1" name="审批子流程">
  <startEvent id="subStart"/>
  <userTask id="subTask1" name="初审"/>
  <userTask id="subTask2" name="复审"/>
  <endEvent id="subEnd"/>

  <sequenceFlow sourceRef="subStart" targetRef="subTask1"/>
  <sequenceFlow sourceRef="subTask1" targetRef="subTask2"/>
  <sequenceFlow sourceRef="subTask2" targetRef="subEnd"/>
</subProcess>

<!-- 调用子流程 -->
<callActivity id="callSubProcess" name="调用子流程"
              calledElement="subProcessKey">
  <extensionElements>
    <flowable:in source="parentVar" target="childVar"/>
    <flowable:out source="childResult" target="parentResult"/>
  </extensionElements>
</callActivity>
```

---

#### 7. 定时器事件 (Timer Event)

```xml
<!-- 定时边界事件 -->
<userTask id="approveTask" name="审批"/>

<boundaryEvent id="timer" cancelActivity="true"
               attachedToRef="approveTask">
  <timerEventDefinition>
    <timeDuration>PT2H</timeDuration>  <!-- 2小时 -->
  </timerEventDefinition>
</boundaryEvent>

<sequenceFlow sourceRef="timer" targetRef="escalation"/>

<!-- 时间格式 -->
<!-- PT2H: 2小时 -->
<!-- PT30M: 30分钟 -->
<!-- P1D: 1天 -->
<!-- 0 0 9 * * ?: 每天9点（Cron表达式） -->
```

---

#### 8. 结束事件 (End Event)

```xml
<!-- 普通结束 -->
<endEvent id="end"/>

<!-- 终止结束（终止所有执行流） -->
<endEvent id="terminateEnd">
  <terminateEventDefinition/>
</endEvent>

<!-- 错误结束 -->
<endEvent id="errorEnd">
  <errorEventDefinition errorRef="error001"/>
</endEvent>
```

---

### 流程部署方式

#### 方式1：自动部署（推荐）

将 BPMN 文件放在 `src/main/resources/processes/` 目录下，Spring Boot 启动时自动部署。

```
src/main/resources/
└── processes/
    ├── vacation.bpmn20.xml
    ├── purchase.bpmn20.xml
    └── benchmark.bpmn20.xml
```

---

#### 方式2：编程式部署

```java
@Service
public class ProcessDeployService {

    @Resource
    private RepositoryService repositoryService;

    public String deployProcess(String resourcePath) {
        Deployment deployment = repositoryService.createDeployment()
            .name("请假流程")
            .category("HR")
            .addClasspathResource(resourcePath)
            .deploy();

        return deployment.getId();
    }

    public String deployFromString(String bpmnXml) {
        Deployment deployment = repositoryService.createDeployment()
            .name("动态流程")
            .addString("dynamic.bpmn20.xml", bpmnXml)
            .deploy();

        return deployment.getId();
    }

    public String deployFromInputStream(InputStream inputStream) {
        Deployment deployment = repositoryService.createDeployment()
            .name("上传流程")
            .addInputStream("uploaded.bpmn20.xml", inputStream)
            .deploy();

        return deployment.getId();
    }
}
```

---

#### 方式3：通过 REST API 部署

```bash
curl -X POST \
  http://localhost:8080/flowable-rest/repository/deployments \
  -H 'Content-Type: multipart/form-data' \
  -F 'file=@vacation.bpmn20.xml'
```

---

### 查询流程定义

```java
@Service
public class ProcessDefinitionQueryService {

    @Resource
    private RepositoryService repositoryService;

    // 查询最新版本的流程定义
    public ProcessDefinition getLatestProcessDefinition(String key) {
        return repositoryService.createProcessDefinitionQuery()
            .processDefinitionKey(key)
            .latestVersion()
            .singleResult();
    }

    // 查询所有版本
    public List<ProcessDefinition> getAllVersions(String key) {
        return repositoryService.createProcessDefinitionQuery()
            .processDefinitionKey(key)
            .orderByProcessDefinitionVersion().desc()
            .list();
    }

    // 查询所有流程定义
    public List<ProcessDefinition> getAllProcessDefinitions() {
        return repositoryService.createProcessDefinitionQuery()
            .latestVersion()  // 只查询最新版本
            .list();
    }

    // 分页查询
    public List<ProcessDefinition> getPagedProcessDefinitions(int page, int size) {
        return repositoryService.createProcessDefinitionQuery()
            .latestVersion()
            .orderByProcessDefinitionName().asc()
            .listPage((page - 1) * size, size);
    }
}
```

---

### 删除流程定义

```java
@Service
public class ProcessDefinitionManageService {

    @Resource
    private RepositoryService repositoryService;

    // 删除部署（级联删除）
    public void deleteDeployment(String deploymentId) {
        repositoryService.deleteDeployment(
            deploymentId,
            true  // cascade = true，级联删除流程实例
        );
    }

    // 挂起流程定义
    public void suspendProcessDefinition(String processDefinitionId) {
        repositoryService.suspendProcessDefinitionById(processDefinitionId);
        // 挂起后，无法启动新的流程实例
    }

    // 激活流程定义
    public void activateProcessDefinition(String processDefinitionId) {
        repositoryService.activateProcessDefinitionById(processDefinitionId);
    }
}
```

---

## 流程实例管理

### 启动流程实例

#### 基础启动

```java
@Service
public class ProcessInstanceService {

    @Resource
    private RuntimeService runtimeService;

    // 最简单的启动方式
    public String startProcess(String processKey) {
        ProcessInstance processInstance = runtimeService
            .startProcessInstanceByKey(processKey);
        return processInstance.getId();
    }

    // 带业务主键
    public String startProcessWithBusinessKey(String processKey, String businessKey) {
        ProcessInstance processInstance = runtimeService
            .startProcessInstanceByKey(processKey)
            .businessKey(businessKey)
            .start();
        return processInstance.getId();
    }

    // 带流程变量
    public String startProcessWithVariables(String processKey, Map<String, Object> variables) {
        ProcessInstance processInstance = runtimeService
            .startProcessInstanceByKey(processKey)
            .variables(variables)
            .start();
        return processInstance.getId();
    }

    // 完整示例
    public String startProcess(String processKey, String businessKey, Map<String, Object> variables) {
        ProcessInstance processInstance = runtimeService
            .startProcessInstanceByKey(processKey)
            .businessKey(businessKey)
            .variables(variables)
            .name("流程实例名称")  // 可选
            .start();

        return processInstance.getId();
    }
}
```

---

#### PAP 项目中的启动方式

```java
// BpmProcessInstanceServiceImpl.java
public String createProcessInstance(Long userId, BpmProcessInstanceCreateReqDTO reqDTO) {
    // 1. 获取流程定义
    ProcessDefinition processDefinition =
        processDefinitionService.getProcessDefinition(reqDTO.getProcessDefinitionKey());

    // 2. 构建流程实例
    ProcessInstanceBuilder builder = runtimeService.createProcessInstanceBuilder()
        .processDefinitionId(processDefinition.getId())
        .businessKey(reqDTO.getBusinessKey())
        .variables(reqDTO.getVariables())
        .name(reqDTO.getName());

    // 3. 启动流程
    ProcessInstance processInstance = builder.start();

    // 4. 发送消息通知
    messageService.sendProcessStartMessage(processInstance);

    return processInstance.getId();
}
```

---

### 查询流程实例

```java
@Service
public class ProcessInstanceQueryService {

    @Resource
    private RuntimeService runtimeService;

    @Resource
    private HistoryService historyService;

    // 查询运行中的流程实例
    public ProcessInstance getRunningProcessInstance(String processInstanceId) {
        return runtimeService.createProcessInstanceQuery()
            .processInstanceId(processInstanceId)
            .includeProcessVariables()  // 包含流程变量
            .singleResult();
    }

    // 查询历史流程实例（包括运行中和已结束）
    public HistoricProcessInstance getHistoricProcessInstance(String processInstanceId) {
        return historyService.createHistoricProcessInstanceQuery()
            .processInstanceId(processInstanceId)
            .includeProcessVariables()
            .singleResult();
    }

    // 根据业务主键查询
    public ProcessInstance getProcessInstanceByBusinessKey(String businessKey) {
        return runtimeService.createProcessInstanceQuery()
            .processInstanceBusinessKey(businessKey)
            .singleResult();
    }

    // 查询某用户发起的流程
    public List<HistoricProcessInstance> getProcessInstancesByStartUser(String userId) {
        return historyService.createHistoricProcessInstanceQuery()
            .startedBy(userId)
            .orderByProcessInstanceStartTime().desc()
            .list();
    }

    // 分页查询
    public List<HistoricProcessInstance> getPagedProcessInstances(int page, int size) {
        return historyService.createHistoricProcessInstanceQuery()
            .orderByProcessInstanceStartTime().desc()
            .listPage((page - 1) * size, size);
    }

    // 统计数量
    public long countRunningProcessInstances(String processKey) {
        return runtimeService.createProcessInstanceQuery()
            .processDefinitionKey(processKey)
            .count();
    }
}
```

---

### 流程实例操作

```java
@Service
public class ProcessInstanceOperationService {

    @Resource
    private RuntimeService runtimeService;

    // 挂起流程实例
    public void suspendProcessInstance(String processInstanceId) {
        runtimeService.suspendProcessInstanceById(processInstanceId);
        // 挂起后，无法完成任务
    }

    // 激活流程实例
    public void activateProcessInstance(String processInstanceId) {
        runtimeService.activateProcessInstanceById(processInstanceId);
    }

    // 删除流程实例
    public void deleteProcessInstance(String processInstanceId, String deleteReason) {
        runtimeService.deleteProcessInstance(processInstanceId, deleteReason);
    }

    // 终止流程实例（更优雅的方式）
    public void terminateProcessInstance(String processInstanceId) {
        // 获取当前执行实例
        Execution execution = runtimeService.createExecutionQuery()
            .processInstanceId(processInstanceId)
            .singleResult();

        // 触发终止
        runtimeService.trigger(execution.getId());
    }
}
```

---

## 任务管理

### 查询任务

```java
@Service
public class TaskQueryService {

    @Resource
    private TaskService taskService;

    // 查询用户的待办任务
    public List<Task> getUserTodoTasks(String userId) {
        return taskService.createTaskQuery()
            .taskAssignee(userId)
            .active()  // 只查询激活状态的任务
            .orderByTaskCreateTime().desc()
            .list();
    }

    // 查询用户的候选任务
    public List<Task> getUserCandidateTasks(String userId) {
        return taskService.createTaskQuery()
            .taskCandidateUser(userId)
            .active()
            .orderByTaskCreateTime().desc()
            .list();
    }

    // 查询用户组的任务
    public List<Task> getGroupTasks(String groupId) {
        return taskService.createTaskQuery()
            .taskCandidateGroup(groupId)
            .active()
            .orderByTaskCreateTime().desc()
            .list();
    }

    // 查询流程实例的所有任务
    public List<Task> getProcessInstanceTasks(String processInstanceId) {
        return taskService.createTaskQuery()
            .processInstanceId(processInstanceId)
            .list();
    }

    // 查询历史任务
    public List<HistoricTaskInstance> getHistoricTasks(String userId) {
        return historyService.createHistoricTaskInstanceQuery()
            .taskAssignee(userId)
            .orderByHistoricTaskInstanceEndTime().desc()
            .list();
    }

    // 分页查询待办任务
    public PageResult<Task> getPagedTasks(String userId, int page, int size) {
        TaskQuery query = taskService.createTaskQuery()
            .taskAssignee(userId)
            .active()
            .orderByTaskCreateTime().desc();

        long count = query.count();
        List<Task> tasks = query.listPage((page - 1) * size, size);

        return new PageResult<>(tasks, count);
    }

    // 统计待办数量
    public long countTodoTasks(String userId) {
        return taskService.createTaskQuery()
            .taskAssignee(userId)
            .active()
            .count();
    }
}
```

---

### 任务操作

#### 1. 认领任务 (Claim)

```java
public void claimTask(String taskId, String userId) {
    taskService.claim(taskId, userId);
    // 候选任务 → 个人任务
}
```

#### 2. 完成任务 (Complete)

```java
public void completeTask(String taskId, Map<String, Object> variables) {
    // 添加审批意见
    taskService.addComment(taskId, processInstanceId, "同意");

    // 完成任务
    taskService.complete(taskId, variables);
}

// PAP 项目示例
public void approveTask(BpmTaskApproveReqVO reqVO) {
    // 1. 获取任务
    Task task = taskService.createTaskQuery()
        .taskId(reqVO.getId())
        .singleResult();

    // 2. 添加评论
    taskService.addComment(reqVO.getId(), task.getProcessInstanceId(), reqVO.getComment());

    // 3. 设置变量
    Map<String, Object> variables = new HashMap<>();
    variables.put("approved", true);
    variables.put("approver", getLoginUserNickname());
    variables.put("approveTime", LocalDateTime.now());

    // 4. 完成任务
    taskService.complete(reqVO.getId(), variables);
}
```

#### 3. 委派任务 (Delegate)

```java
public void delegateTask(String taskId, String targetUserId) {
    taskService.delegateTask(taskId, targetUserId);
    // 任务状态变为 DELEGATED
    // targetUserId 完成后，任务返回给原 assignee
}
```

#### 4. 转办任务 (Transfer)

```java
public void transferTask(String taskId, String targetUserId) {
    taskService.setAssignee(taskId, targetUserId);
    // 任务直接转给 targetUserId
}
```

#### 5. 退回任务 (Reject)

```java
public void rejectTask(String taskId, String targetActivityId) {
    // 获取任务
    Task task = taskService.createTaskQuery().taskId(taskId).singleResult();

    // 获取流程定义
    BpmnModel bpmnModel = repositoryService.getBpmnModel(task.getProcessDefinitionId());

    // 执行退回
    runtimeService.createChangeActivityStateBuilder()
        .processInstanceId(task.getProcessInstanceId())
        .moveActivityIdTo(task.getTaskDefinitionKey(), targetActivityId)
        .changeState();
}
```

---

### 任务评论

```java
@Service
public class TaskCommentService {

    @Resource
    private TaskService taskService;

    // 添加评论
    public void addComment(String taskId, String processInstanceId, String message) {
        taskService.addComment(taskId, processInstanceId, message);
    }

    // 获取任务评论
    public List<Comment> getTaskComments(String taskId) {
        return taskService.getTaskComments(taskId);
    }

    // 获取流程实例的所有评论
    public List<Comment> getProcessInstanceComments(String processInstanceId) {
        return taskService.getProcessInstanceComments(processInstanceId);
    }

    // PAP 项目中的评论类型
    public void addTypedComment(String taskId, String processInstanceId,
                                BpmCommentTypeEnum type, String message) {
        Comment comment = taskService.addComment(taskId, processInstanceId, type.getType(), message);
        // type: APPROVE, REJECT, TRANSFER, DELEGATE, etc.
    }
}
```

---

## 流程变量操作

### 设置流程变量

```java
@Service
public class ProcessVariableService {

    @Resource
    private RuntimeService runtimeService;

    @Resource
    private TaskService taskService;

    // 1. 启动流程时设置
    public void setVariablesOnStart(String processKey, Map<String, Object> variables) {
        runtimeService.startProcessInstanceByKey(processKey)
            .variables(variables)
            .start();
    }

    // 2. 运行时设置（全局变量）
    public void setProcessVariable(String processInstanceId, String variableName, Object value) {
        runtimeService.setVariable(processInstanceId, variableName, value);
    }

    public void setProcessVariables(String processInstanceId, Map<String, Object> variables) {
        runtimeService.setVariables(processInstanceId, variables);
    }

    // 3. 任务完成时设置
    public void setVariablesOnComplete(String taskId, Map<String, Object> variables) {
        taskService.complete(taskId, variables);
    }

    // 4. 设置任务局部变量
    public void setTaskLocalVariable(String taskId, String variableName, Object value) {
        taskService.setVariableLocal(taskId, variableName, value);
    }
}
```

---

### 获取流程变量

```java
@Service
public class ProcessVariableQueryService {

    @Resource
    private RuntimeService runtimeService;

    @Resource
    private TaskService taskService;

    @Resource
    private HistoryService historyService;

    // 1. 获取流程实例变量
    public Object getProcessVariable(String processInstanceId, String variableName) {
        return runtimeService.getVariable(processInstanceId, variableName);
    }

    public Map<String, Object> getProcessVariables(String processInstanceId) {
        return runtimeService.getVariables(processInstanceId);
    }

    // 2. 从任务获取变量
    public Object getTaskVariable(String taskId, String variableName) {
        return taskService.getVariable(taskId, variableName);
    }

    public Map<String, Object> getTaskVariables(String taskId) {
        return taskService.getVariables(taskId);
    }

    // 3. 获取任务局部变量
    public Map<String, Object> getTaskLocalVariables(String taskId) {
        return taskService.getVariablesLocal(taskId);
    }

    // 4. 从历史记录获取变量
    public List<HistoricVariableInstance> getHistoricVariables(String processInstanceId) {
        return historyService.createHistoricVariableInstanceQuery()
            .processInstanceId(processInstanceId)
            .list();
    }
}
```

---

### 变量类型

Flowable 支持多种变量类型：

```java
// 1. 基本类型
variables.put("approved", true);  // Boolean
variables.put("count", 10);  // Integer
variables.put("amount", 1000.5);  // Double
variables.put("name", "张三");  // String

// 2. 日期类型
variables.put("startDate", new Date());
variables.put("endDate", LocalDateTime.now());

// 3. 序列化对象
Employee employee = new Employee("张三", "研发部");
variables.put("employee", employee);  // 对象必须实现 Serializable

// 4. JSON 对象（推荐）
Map<String, Object> jsonData = new HashMap<>();
jsonData.put("name", "张三");
jsonData.put("age", 30);
variables.put("userData", jsonData);

// 5. 文件（二进制）
byte[] fileContent = Files.readAllBytes(path);
variables.put("attachment", fileContent);
```

---

## 事件监听器开发

### 全局事件监听器

```java
@Component
public class GlobalProcessEventListener implements FlowableEventListener {

    @Override
    public void onEvent(FlowableEvent event) {
        switch (event.getType()) {
            case PROCESS_STARTED:
                handleProcessStarted(event);
                break;
            case PROCESS_COMPLETED:
                handleProcessCompleted(event);
                break;
            case TASK_CREATED:
                handleTaskCreated(event);
                break;
            case TASK_COMPLETED:
                handleTaskCompleted(event);
                break;
            default:
                break;
        }
    }

    private void handleProcessStarted(FlowableEvent event) {
        FlowableEngineEntityEvent entityEvent = (FlowableEngineEntityEvent) event;
        ProcessInstance processInstance = (ProcessInstance) entityEvent.getEntity();
        log.info("流程启动: {}", processInstance.getId());
    }

    private void handleProcessCompleted(FlowableEvent event) {
        log.info("流程结束: {}", event.getProcessInstanceId());
    }

    private void handleTaskCreated(FlowableEvent event) {
        FlowableEngineEntityEvent entityEvent = (FlowableEngineEntityEvent) event;
        Task task = (Task) entityEvent.getEntity();
        log.info("任务创建: {}, 处理人: {}", task.getName(), task.getAssignee());
    }

    @Override
    public boolean isFailOnException() {
        return false;  // 监听器异常不影响流程执行
    }

    @Override
    public boolean isFireOnTransactionLifecycleEvent() {
        return false;
    }

    @Override
    public String getOnTransaction() {
        return null;
    }
}
```

**注册监听器**:
```java
@Bean
public EngineConfigurationConfigurer<SpringProcessEngineConfiguration>
    eventListenerConfigurer(GlobalProcessEventListener listener) {
    return configuration -> {
        configuration.setEventListeners(Collections.singletonList(listener));
    };
}
```

---

### 流程结束监听器（PAP 项目）

```java
// BpmProcessInstanceEventPublisher.java
@Component
public class BpmProcessInstanceEventPublisher implements FlowableEventListener {

    private final ApplicationEventPublisher publisher;

    public BpmProcessInstanceEventPublisher(ApplicationEventPublisher publisher) {
        this.publisher = publisher;
    }

    @Override
    public void onEvent(FlowableEvent event) {
        // 只处理流程完成和取消事件
        if (event.getType() != FlowableEngineEventType.PROCESS_COMPLETED &&
            event.getType() != FlowableEngineEventType.PROCESS_CANCELLED) {
            return;
        }

        // 获取流程实例
        HistoricProcessInstance instance = getHistoricProcessInstance(event);

        // 构建业务事件
        BpmProcessInstanceStatusEvent statusEvent = new BpmProcessInstanceStatusEvent(this);
        statusEvent.setId(instance.getId());
        statusEvent.setProcessDefinitionKey(instance.getProcessDefinitionKey());
        statusEvent.setBusinessKey(instance.getBusinessKey());
        statusEvent.setStatus(calculateStatus(event));

        // 发布 Spring 事件
        publisher.publishEvent(statusEvent);
    }

    private Integer calculateStatus(FlowableEvent event) {
        if (event.getType() == FlowableEngineEventType.PROCESS_COMPLETED) {
            return BpmProcessInstanceStatusEnum.APPROVE.getStatus();  // 2
        } else {
            return BpmProcessInstanceStatusEnum.REJECT.getStatus();  // 3
        }
    }
}
```

---

### 业务监听器

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
        // 更新业务表状态
        benchmarkService.updateProcessStatus(
            event.getBusinessKey(),  // 业务ID
            event.getStatus()  // 2-通过, 3-拒绝
        );
    }
}
```

---

## 与业务系统集成

### 集成架构

```
业务系统
    ↓
BPM API 层 (封装 Flowable)
    ↓
Flowable Service
    ↓
数据库
```

### 1. 定义 BPM API 接口

```java
// BpmProcessInstanceApi.java
public interface BpmProcessInstanceApi {

    /**
     * 创建流程实例
     */
    String createProcessInstance(Long userId, BpmProcessInstanceCreateReqDTO reqDTO);
}

// DTO 定义
@Data
public class BpmProcessInstanceCreateReqDTO {
    private String processDefinitionKey;  // 流程定义key
    private String businessKey;  // 业务主键
    private Map<String, Object> variables;  // 流程变量
    private String name;  // 流程实例名称
}
```

---

### 2. 实现 API

```java
// BpmProcessInstanceApiImpl.java
@Service
public class BpmProcessInstanceApiImpl implements BpmProcessInstanceApi {

    @Resource
    private BpmProcessInstanceService processInstanceService;

    @Override
    public String createProcessInstance(Long userId, BpmProcessInstanceCreateReqDTO reqDTO) {
        return processInstanceService.createProcessInstance(userId, reqDTO);
    }
}
```

---

### 3. 业务服务调用

```java
// BenchmarkServiceImpl.java
@Service
public class BenchmarkServiceImpl implements BenchmarkService {

    @Resource
    private BenchmarkMapper benchmarkMapper;

    @Resource
    private BpmProcessInstanceApi processInstanceApi;  // 注入 BPM API

    @Resource
    private NotifySendService notifySendService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateBenchmark(List<BenchmarkDetailsReqVo> updateReqVO) {
        // 1. 更新业务数据（版本控制）
        BenchmarkDO oldData = benchmarkMapper.selectById(id);

        // 标记旧数据失效
        oldData.setDelFlag(1);
        oldData.setValidEndDatetime(LocalDateTime.now());
        benchmarkMapper.updateById(oldData);

        // 插入新版本数据
        BenchmarkDO newData = BeanUtils.copyProperties(oldData, BenchmarkDO.class);
        newData.setId(IdUtils.getUUID());
        newData.setRecordVersion(oldData.getRecordVersion() + 1);
        newData.setDelFlag(0);
        newData.setValidStartDatetime(LocalDateTime.now());
        benchmarkMapper.insert(newData);

        // 2. 发起工作流
        Map<String, Object> variables = new HashMap<>();
        String processInstanceId = processInstanceApi.createProcessInstance(
            getLoginUserId(),
            new BpmProcessInstanceCreateReqDTO()
                .setProcessDefinitionKey("benchmark")
                .setBusinessKey(newData.getId())
                .setVariables(variables)
        );

        // 3. 回写流程实例ID
        benchmarkMapper.updateById(
            new BenchmarkDO()
                .setId(newData.getId())
                .setProcessInstanceId(processInstanceId)
                .setStatus(1)  // pending
        );

        // 4. 发送通知
        notifySendService.sendSingleNotifyToAdmin(
            getLoginUserId(),
            "BENCHMARK_SUBMITTED",
            Map.of("name", newData.getName())
        );
    }
}
```

---

### 4. 流程结束后回写业务状态

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
        // 流程结束时，更新业务表状态
        benchmarkService.updateProcessStatus(
            event.getBusinessKey(),  // 业务ID
            event.getStatus()  // 2-通过, 3-拒绝
        );
    }
}

// BenchmarkServiceImpl.java
@Override
public void updateProcessStatus(String id, Integer status) {
    benchmarkMapper.updateById(
        new BenchmarkDO()
            .setId(id)
            .setStatus(status)
            .setChecker(getLoginUserNickname())
            .setCheckerDatetime(LocalDateTime.now())
    );
}
```

---

## 常见场景实战

### 场景1：请假审批流程

#### 1. 流程设计

```xml
<process id="vacation" name="请假流程">
  <startEvent id="start"/>

  <!-- 提交申请 -->
  <userTask id="submit" name="提交请假" flowable:assignee="${startUserId}"/>

  <!-- 部门经理审批 -->
  <userTask id="deptManagerApprove" name="部门经理审批"
            flowable:candidateGroups="deptManagers"/>

  <!-- 排他网关：根据请假天数决定流向 -->
  <exclusiveGateway id="daysGateway"/>

  <!-- 3天以内：直接通过 -->
  <sequenceFlow sourceRef="daysGateway" targetRef="hrArchive" name="≤3天">
    <conditionExpression>${days <= 3}</conditionExpression>
  </sequenceFlow>

  <!-- 超过3天：需要总经理审批 -->
  <sequenceFlow sourceRef="daysGateway" targetRef="gmApprove" name=">3天">
    <conditionExpression>${days > 3}</conditionExpression>
  </sequenceFlow>

  <userTask id="gmApprove" name="总经理审批"
            flowable:candidateGroups="generalManagers"/>

  <userTask id="hrArchive" name="HR归档"
            flowable:candidateGroups="hr"/>

  <endEvent id="end"/>
</process>
```

#### 2. 业务实现

```java
@Service
public class VacationService {

    @Resource
    private VacationMapper vacationMapper;

    @Resource
    private BpmProcessInstanceApi processInstanceApi;

    // 提交请假申请
    @Transactional
    public String submitVacation(VacationSubmitReqVO reqVO) {
        // 1. 保存业务数据
        VacationDO vacation = new VacationDO();
        vacation.setEmployeeId(getLoginUserId());
        vacation.setStartDate(reqVO.getStartDate());
        vacation.setEndDate(reqVO.getEndDate());
        vacation.setDays(reqVO.getDays());
        vacation.setReason(reqVO.getReason());
        vacation.setStatus(0);  // 待审批
        vacationMapper.insert(vacation);

        // 2. 发起流程
        Map<String, Object> variables = new HashMap<>();
        variables.put("days", reqVO.getDays());
        variables.put("employeeName", getLoginUserNickname());
        variables.put("startUserId", String.valueOf(getLoginUserId()));

        String processInstanceId = processInstanceApi.createProcessInstance(
            getLoginUserId(),
            new BpmProcessInstanceCreateReqDTO()
                .setProcessDefinitionKey("vacation")
                .setBusinessKey(vacation.getId().toString())
                .setVariables(variables)
        );

        // 3. 更新流程实例ID
        vacationMapper.updateById(
            new VacationDO()
                .setId(vacation.getId())
                .setProcessInstanceId(processInstanceId)
        );

        return processInstanceId;
    }
}
```

---

### 场景2：采购审批流程（会签）

#### 1. 流程设计

```xml
<process id="purchase" name="采购流程">
  <startEvent id="start"/>

  <!-- 多实例用户任务：部门经理会签 -->
  <userTask id="multiApprove" name="部门经理会签"
            flowable:candidateUsers="${managerIds}">
    <multiInstanceLoopCharacteristics isSequential="false"
        flowable:collection="managerIds"
        flowable:elementVariable="managerId">
      <!-- 完成条件：所有人都同意 -->
      <completionCondition>${nrOfCompletedInstances == nrOfInstances}</completionCondition>
    </multiInstanceLoopCharacteristics>
  </userTask>

  <!-- 排他网关：检查是否所有人都同意 -->
  <exclusiveGateway id="allApproved"/>

  <sequenceFlow sourceRef="allApproved" targetRef="gmApprove" name="全部同意">
    <conditionExpression>${allApproved == true}</conditionExpression>
  </sequenceFlow>

  <sequenceFlow sourceRef="allApproved" targetRef="reject" name="有人拒绝">
    <conditionExpression>${allApproved == false}</conditionExpression>
  </sequenceFlow>

  <userTask id="gmApprove" name="总经理审批"/>
  <endEvent id="end"/>
</process>
```

#### 2. 会签逻辑

```java
// 设置会签候选人
List<String> managerIds = Arrays.asList("10001", "10002", "10003");
variables.put("managerIds", managerIds);

// 监听任务完成事件
@Component
public class PurchaseTaskListener implements TaskListener {

    @Override
    public void notify(DelegateTask delegateTask) {
        // 获取会签变量
        Integer nrOfInstances = (Integer) delegateTask.getVariable("nrOfInstances");
        Integer nrOfCompletedInstances = (Integer) delegateTask.getVariable("nrOfCompletedInstances");
        Integer nrOfActiveInstances = (Integer) delegateTask.getVariable("nrOfActiveInstances");

        // 检查是否所有人都完成
        if (nrOfCompletedInstances.equals(nrOfInstances)) {
            // 检查是否所有人都同意
            boolean allApproved = checkAllApproved(delegateTask);
            delegateTask.setVariable("allApproved", allApproved);
        }
    }
}
```

---

### 场景3：超时自动审批

#### 1. BPMN 定义

```xml
<userTask id="approve" name="审批">
  <!-- 超时边界事件 -->
  <boundaryEvent id="timeout" cancelActivity="true"
                 attachedToRef="approve">
    <timerEventDefinition>
      <timeDuration>PT2H</timeDuration>  <!-- 2小时后超时 -->
    </timerEventDefinition>
  </boundaryEvent>
</userTask>

<!-- 超时后自动执行 -->
<serviceTask id="autoApprove" name="自动同意"
             flowable:expression="${autoApprovalService.approve(execution)}"/>

<sequenceFlow sourceRef="timeout" targetRef="autoApprove"/>
```

#### 2. 自动审批服务

```java
@Service
public class AutoApprovalService {

    @Resource
    private TaskService taskService;

    public void approve(DelegateExecution execution) {
        // 获取超时的任务
        String taskId = execution.getCurrentActivityId();

        // 记录超时日志
        log.warn("任务超时自动审批: taskId={}", taskId);

        // 设置变量
        execution.setVariable("approved", true);
        execution.setVariable("approver", "SYSTEM");
        execution.setVariable("approveTime", LocalDateTime.now());
        execution.setVariable("autoApproved", true);
    }
}
```

---

### 场景4：动态审批人

#### 1. BPMN 定义

```xml
<userTask id="approve" name="审批"
          flowable:assignee="${taskCandidateInvoker.calculateAssignee(execution)}"/>
```

#### 2. 动态计算审批人

```java
@Service
public class TaskCandidateInvoker {

    @Resource
    private AdminUserApi adminUserApi;

    @Resource
    private DeptApi deptApi;

    public String calculateAssignee(DelegateExecution execution) {
        // 获取提交人
        String startUserId = execution.getVariable("startUserId", String.class);

        // 获取提交人部门
        AdminUserRespDTO user = adminUserApi.getUser(Long.valueOf(startUserId));
        Long deptId = user.getDeptId();

        // 获取部门负责人
        DeptRespDTO dept = deptApi.getDept(deptId);
        Long leaderId = dept.getLeaderUserId();

        return String.valueOf(leaderId);
    }
}
```

---

## 常见问题与解决方案

### Q1: 流程图中文乱码

**问题**: 流程图中文显示为方块。

**解决方案**:
```java
@Bean
public EngineConfigurationConfigurer<SpringProcessEngineConfiguration>
    processEngineConfigurationConfigurer() {
    return configuration -> {
        configuration.setActivityFontName("宋体");
        configuration.setLabelFontName("宋体");
        configuration.setAnnotationFontName("宋体");
    };
}
```

---

### Q2: 数据库表未自动创建

**问题**: 启动时没有自动创建 Flowable 表。

**解决方案**:
```yaml
flowable:
  database-schema-update: true
```

---

### Q3: 流程变量无法序列化

**问题**: `NotSerializableException: class xxx is not serializable`

**解决方案**:
```java
// 方式1: 实现 Serializable 接口
public class Employee implements Serializable {
    private static final long serialVersionUID = 1L;
    // ...
}

// 方式2: 使用 JSON 存储
Map<String, Object> employeeJson = new HashMap<>();
employeeJson.put("name", "张三");
employeeJson.put("age", 30);
variables.put("employee", employeeJson);

// 方式3: 只存储业务ID，需要时查询
variables.put("employeeId", "10001");
```

---

### Q4: 任务查询不到

**问题**: 用户查询不到自己的待办任务。

**排查步骤**:
```java
// 1. 检查任务是否存在
Task task = taskService.createTaskQuery()
    .taskId(taskId)
    .singleResult();
if (task == null) {
    // 任务不存在
}

// 2. 检查任务状态
if (task.isSuspended()) {
    // 任务被挂起
}

// 3. 检查任务分配
if (task.getAssignee() == null) {
    // 任务未分配，可能是候选任务
    List<Task> candidateTasks = taskService.createTaskQuery()
        .taskCandidateUser(userId)
        .list();
}

// 4. 检查任务是否被委派
if (DelegationState.PENDING.equals(task.getDelegationState())) {
    // 任务被委派，需要先处理委派
}
```

---

### Q5: 流程实例无法删除

**问题**: `Cannot delete process instance: has active child process instances`

**解决方案**:
```java
// 使用级联删除
runtimeService.deleteProcessInstance(processInstanceId, "取消流程", true);

// 或者先删除子流程
List<ProcessInstance> subProcesses = runtimeService.createProcessInstanceQuery()
    .superProcessInstanceId(processInstanceId)
    .list();

for (ProcessInstance subProcess : subProcesses) {
    runtimeService.deleteProcessInstance(subProcess.getId(), "级联删除", true);
}

runtimeService.deleteProcessInstance(processInstanceId, "删除主流程", true);
```

---

### Q6: 事务回滚导致流程异常

**问题**: 业务数据回滚了，但流程实例已创建。

**解决方案**:
```java
@Service
public class BenchmarkServiceImpl {

    @Transactional(rollbackFor = Exception.class)
    public void updateBenchmark(List<BenchmarkDetailsReqVo> updateReqVO) {
        try {
            // 1. 业务数据操作
            benchmarkMapper.updateById(updateObj);
            benchmarkMapper.insert(insertObj);

            // 2. 发起流程（在同一事务中）
            String processInstanceId = processInstanceApi.createProcessInstance(...);

            // 3. 更新流程ID
            benchmarkMapper.updateById(newData.setProcessInstanceId(processInstanceId));

            // 任何异常都会导致整个事务回滚
        } catch (Exception e) {
            log.error("更新失败", e);
            throw e;  // 重新抛出，触发回滚
        }
    }
}
```

---

### Q7: 并发任务处理

**问题**: 多个用户同时处理同一个任务。

**解决方案**:
```java
public void completeTask(String taskId) {
    try {
        // Flowable 内部使用乐观锁
        taskService.complete(taskId);
    } catch (FlowableOptimisticLockingException e) {
        throw new BusinessException("任务已被其他用户处理");
    }
}
```

---

### Q8: 流程定义版本管理

**问题**: 如何升级流程定义而不影响运行中的流程？

**解决方案**:
```java
// 1. 部署新版本流程定义
Deployment deployment = repositoryService.createDeployment()
    .name("Benchmark流程 v2")
    .addClasspathResource("processes/benchmark_v2.bpmn20.xml")
    .deploy();

// 2. 运行中的流程继续使用旧版本
// 新启动的流程自动使用最新版本

// 3. 迁移运行中的流程（可选）
ProcessDefinition newProcessDef = repositoryService
    .createProcessDefinitionQuery()
    .processDefinitionKey("benchmark")
    .latestVersion()
    .singleResult();

List<ProcessInstance> oldInstances = runtimeService
    .createProcessInstanceQuery()
    .processDefinitionKey("benchmark")
    .processDefinitionVersion(1)  // 旧版本
    .list();

for (ProcessInstance instance : oldInstances) {
    runtimeService.createProcessInstanceMigrationBuilder()
        .migrateToProcessDefinition(newProcessDef.getId())
        .migrate(instance.getId());
}
```

---

## 附录：常用 API 速查

### RuntimeService

```java
// 启动流程
runtimeService.startProcessInstanceByKey(key);

// 查询流程实例
runtimeService.createProcessInstanceQuery()...list();

// 设置变量
runtimeService.setVariable(processInstanceId, name, value);

// 挂起/激活
runtimeService.suspendProcessInstanceById(id);
runtimeService.activateProcessInstanceById(id);

// 删除流程
runtimeService.deleteProcessInstance(id, reason);
```

### TaskService

```java
// 查询任务
taskService.createTaskQuery()...list();

// 认领任务
taskService.claim(taskId, userId);

// 完成任务
taskService.complete(taskId, variables);

// 委派任务
taskService.delegateTask(taskId, targetUserId);

// 设置处理人
taskService.setAssignee(taskId, userId);

// 添加评论
taskService.addComment(taskId, processInstanceId, message);
```

### HistoryService

```java
// 查询历史流程实例
historyService.createHistoricProcessInstanceQuery()...list();

// 查询历史任务
historyService.createHistoricTaskInstanceQuery()...list();

// 查询历史活动
historyService.createHistoricActivityInstanceQuery()...list();

// 查询历史变量
historyService.createHistoricVariableInstanceQuery()...list();
```

### RepositoryService

```java
// 部署流程
repositoryService.createDeployment()...deploy();

// 查询流程定义
repositoryService.createProcessDefinitionQuery()...list();

// 获取流程图
repositoryService.getProcessDiagram(processDefinitionId);

// 挂起/激活流程定义
repositoryService.suspendProcessDefinitionById(id);
repositoryService.activateProcessDefinitionById(id);

// 删除部署
repositoryService.deleteDeployment(deploymentId, cascade);
```

---

**文档结束** | 本文档详细介绍了 Flowable 在 PAP 项目中的实际使用方法，涵盖从环境搭建、流程定义、任务管理到与业务系统集成的完整流程。通过实战案例和常见问题解答，帮助开发者快速掌握 Flowable 工作流引擎的使用。
