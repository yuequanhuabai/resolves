# Flowable 7.x + Spring Boot 3 独立流程引擎微服务 — 主体架构

> 目标：搭建一个独立的流程引擎微服务，不耦合任何业务代码，对外仅暴露 REST API，业务系统通过 HTTP 调用。

---

## 整体架构

```
                         ┌─────────────────────────────────────┐
                         │       流程引擎微服务（本项目）          │
                         │                                     │
业务服务A ──┐             │  ┌───────────┐    ┌──────────────┐  │
            │  HTTP/REST  │  │ Controller│    │ Flowable     │  │
业务服务B ──┼────────────▶│  │  (REST    │───▶│ Engine       │──┼──▶ MySQL
            │             │  │   API)    │    │ (7.x)        │  │
业务服务C ──┘             │  └───────────┘    └──────────────┘  │
                         │                                     │
前端(bpmn-js) ──────────▶│  ┌───────────┐                     │
                         │  │ Modeler   │  流程图设计/部署       │
                         │  │ API       │                      │
                         │  └───────────┘                      │
                         └─────────────────────────────────────┘
```

---

## 技术选型

| 组件 | 版本 | 说明 |
|---|---|---|
| Java | 17+ | Spring Boot 3 最低要求 |
| Spring Boot | 3.2.x | 主框架 |
| Flowable | 7.1.0 | 流程引擎 |
| MySQL | 8.0+ | 流程数据持久化 |
| Knife4j/Swagger | 4.x | API 文档 |
| bpmn-js | 最新版 | 前端流程设计器（可选，后续集成） |

---

## 项目模块结构

```
flowable-engine-server/
├── pom.xml                          # Maven 主配置
├── src/
│   └── main/
│       ├── java/
│       │   └── com/example/workflow/
│       │       ├── WorkflowApplication.java          # 启动类
│       │       ├── config/
│       │       │   ├── FlowableConfig.java           # Flowable 引擎配置
│       │       │   ├── CorsConfig.java               # 跨域配置
│       │       │   └── SecurityConfig.java           # 安全配置（可选）
│       │       ├── controller/
│       │       │   ├── ProcessDefinitionController.java  # 流程定义（部署/查询/删除）
│       │       │   ├── ProcessInstanceController.java    # 流程实例（发起/挂起/终止）
│       │       │   ├── TaskController.java               # 任务（查询/审批/驳回/转办）
│       │       │   └── HistoryController.java            # 历史记录（查询/流程图）
│       │       ├── service/
│       │       │   ├── ProcessDefinitionService.java
│       │       │   ├── ProcessInstanceService.java
│       │       │   ├── TaskService.java
│       │       │   └── HistoryService.java
│       │       ├── dto/
│       │       │   ├── request/                      # 请求参数
│       │       │   │   ├── StartProcessRequest.java
│       │       │   │   ├── CompleteTaskRequest.java
│       │       │   │   └── DeployProcessRequest.java
│       │       │   └── response/                     # 响应结果
│       │       │       ├── R.java                    # 统一响应包装
│       │       │       ├── ProcessDefinitionVO.java
│       │       │       ├── ProcessInstanceVO.java
│       │       │       └── TaskVO.java
│       │       └── listener/                         # 流程监听器（可选）
│       │           └── GlobalTaskListener.java
│       └── resources/
│           ├── application.yml                       # 主配置
│           ├── application-dev.yml                   # 开发环境配置
│           └── processes/                            # BPMN 流程文件（可选，自动部署）
│               └── leave-approval.bpmn20.xml
└── Dockerfile                                        # Docker 打包
```

---

## 主体架构步骤（共 8 步）

### 步骤 1：初始化项目

创建 Spring Boot 3.2.x Maven 项目，配置 JDK 17，引入基础依赖。

### 步骤 2：引入 Flowable 依赖

添加 Flowable 7.x Spring Boot Starter 及 REST 相关依赖。

### 步骤 3：配置数据源与 Flowable 引擎

配置 MySQL 数据源，Flowable 自动建表策略，异步执行器等核心参数。

### 步骤 4：编写流程定义 API（部署/查询/删除）

实现流程的部署（上传 BPMN 文件）、查询已部署流程列表、删除部署。

### 步骤 5：编写流程实例 API（发起/挂起/终止）

实现根据流程 Key 发起流程、传入业务变量、挂起/激活/终止流程实例。

### 步骤 6：编写任务 API（查询/审批/驳回/转办）

实现待办任务查询、完成任务（审批通过）、驳回到上一节点、转办给他人。

### 步骤 7：编写历史记录 API（查询/流程图高亮）

实现已完成流程查询、审批记录查询、生成带高亮的流程图图片。

### 步骤 8：Docker 打包与部署

编写 Dockerfile，构建镜像，配置外部化参数，部署到 Linux 服务器。

---

## 对外 API 总览

| 模块 | 接口 | 方法 | 说明 |
|---|---|---|---|
| **流程定义** | `/api/process/deploy` | POST | 上传 BPMN 文件部署流程 |
| | `/api/process/list` | GET | 查询已部署流程列表 |
| | `/api/process/delete/{deploymentId}` | DELETE | 删除部署 |
| | `/api/process/resource/{processDefinitionId}` | GET | 获取流程图 XML |
| **流程实例** | `/api/instance/start` | POST | 发起流程实例 |
| | `/api/instance/list` | GET | 查询流程实例列表 |
| | `/api/instance/suspend/{instanceId}` | PUT | 挂起流程实例 |
| | `/api/instance/activate/{instanceId}` | PUT | 激活流程实例 |
| | `/api/instance/delete/{instanceId}` | DELETE | 终止并删除实例 |
| **任务** | `/api/task/todo` | GET | 查询待办任务 |
| | `/api/task/complete` | POST | 完成任务（审批通过） |
| | `/api/task/reject` | POST | 驳回任务 |
| | `/api/task/delegate` | POST | 转办任务 |
| | `/api/task/detail/{taskId}` | GET | 任务详情 |
| **历史** | `/api/history/instances` | GET | 已完成流程查询 |
| | `/api/history/activities/{instanceId}` | GET | 审批记录 |
| | `/api/history/diagram/{instanceId}` | GET | 流程图（高亮已走节点） |

---

## 业务系统调用方式

### 方式一：Feign Client（推荐）

```java
@FeignClient(name = "workflow-engine", url = "${workflow.engine.url}")
public interface WorkflowClient {

    @PostMapping("/api/instance/start")
    R<ProcessInstanceVO> startProcess(@RequestBody StartProcessRequest request);

    @GetMapping("/api/task/todo")
    R<List<TaskVO>> getTodoTasks(@RequestParam String assignee);

    @PostMapping("/api/task/complete")
    R<Void> completeTask(@RequestBody CompleteTaskRequest request);
}
```

### 方式二：RestTemplate

```java
restTemplate.postForObject(
    "http://workflow-engine:9090/api/instance/start",
    request,
    R.class
);
```

### 方式三：直接 HTTP 调用

```bash
curl -X POST http://workflow-engine:9090/api/instance/start \
  -H "Content-Type: application/json" \
  -d '{"processKey": "leave-approval", "businessKey": "LEAVE-2024001", "variables": {"days": 3}}'
```

---

## 关键设计原则

1. **不耦合业务**：流程引擎只管流程流转，不写任何业务逻辑代码
2. **通过变量传递业务数据**：业务系统将业务 ID、审批人等通过流程变量传入
3. **通过 businessKey 关联**：每个流程实例绑定一个 businessKey（如订单号），业务系统通过它关联自己的业务数据
4. **回调通知（可选）**：流程节点变化时，通过 Flowable 监听器回调业务系统的 Webhook

---

> 详细的每一步操作请查看 [flowable_springboot3_create_step.md](flowable_springboot3_create_step.md)
