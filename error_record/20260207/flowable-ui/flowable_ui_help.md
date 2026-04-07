# Flowable UI 操作教程

> 适用版本：Flowable 6.8.x Docker 部署（flowable/flowable-ui）
>
> 访问地址：`http://服务器IP:8080/flowable-ui`
>
> 默认账号：`admin` / `test`

---

## 目录

1. [IDM App - 用户与权限管理](#1-idm-app---用户与权限管理)
2. [Modeler App - 流程建模设计](#2-modeler-app---流程建模设计)
3. [Task App - 任务发起与审批](#3-task-app---任务发起与审批)
4. [Admin App - 管理与监控](#4-admin-app---管理与监控)
5. [完整演示：请假审批流程](#5-完整演示请假审批流程)

---

## 1. IDM App - 用户与权限管理

IDM（Identity Management）用于管理用户、分组和权限。在画流程图之前，先创建好参与流程的用户。

### 1.1 创建用户

1. 进入主页，点击 **IDM App**
2. 点击顶部菜单 **Users（用户）**
3. 点击右上角 **Create user（创建用户）**
4. 填写信息：
   - **ID**：用户唯一标识（如 `zhangsan`）
   - **First name**：名
   - **Last name**：姓
   - **Email**：邮箱
   - **Password**：密码
5. 点击 **Save** 保存

建议创建以下测试用户：

| ID | 姓名 | 角色说明 |
|---|---|---|
| zhangsan | 张三 | 流程发起人 |
| lisi | 李四 | 部门经理（一级审批） |
| wangwu | 王五 | 总经理（二级审批） |

### 1.2 创建分组

1. 点击顶部菜单 **Groups（分组）**
2. 点击 **Create group**
3. 填写：
   - **ID**：分组标识（如 `managers`）
   - **Name**：分组名称（如 `经理组`）
4. 保存后，点击该分组
5. 点击 **Add user** 将用户添加到分组

### 1.3 设置权限

1. 点击顶部菜单 **Privileges（权限）**
2. 系统内置以下权限：
   - **Access the Modeler application**：允许使用建模器
   - **Access the workflow application**：允许使用 Task App
   - **Access the admin application**：允许使用管理后台
   - **Access the IDM application**：允许使用用户管理
   - **Access the REST API**：允许调用 REST 接口
3. 点击对应权限，添加用户或分组

---

## 2. Modeler App - 流程建模设计

Modeler 是核心功能，用于通过拖拽方式设计 BPMN 流程图。

### 2.1 创建流程模型

1. 进入主页，点击 **Modeler App**
2. 点击 **Create Process（创建流程）**
3. 填写基本信息：
   - **Process name**：流程名称（如 `请假审批流程`）
   - **Process key**：流程标识（如 `leave-process`，唯一，后续 API 调用用这个）
   - **Description**：流程描述
4. 点击 **Create** 进入流程设计器

### 2.2 流程设计器界面说明

```
┌──────────────────────────────────────────────┐
│  工具栏（保存、撤销、重做、剪切、复制等）          │
├──────────┬───────────────────────────────────┤
│          │                                   │
│  组件面板  │         画布区域                   │
│  （左侧）  │    （拖拽组件到这里）               │
│          │                                   │
├──────────┴───────────────────────────────────┤
│              属性面板（底部/右侧）               │
│         （选中组件后编辑其属性）                  │
└──────────────────────────────────────────────┘
```

### 2.3 常用组件说明

| 组件 | 图标 | 用途 |
|---|---|---|
| **Start Event** | 圆圈（细线） | 流程开始节点 |
| **End Event** | 圆圈（粗线） | 流程结束节点 |
| **User Task** | 圆角矩形（人形图标） | 需要人工处理的任务节点 |
| **Service Task** | 圆角矩形（齿轮图标） | 自动执行的任务（调用服务） |
| **Exclusive Gateway** | 菱形（X） | 排他网关，条件分支（只走一条） |
| **Parallel Gateway** | 菱形（+） | 并行网关，同时走多条分支 |
| **Sequence Flow** | 箭头线 | 连接各节点的流转线 |

### 2.4 画一个简单审批流程

**目标流程：** 开始 → 经理审批 → 结束

1. 画布上已有 **Start Event**（开始节点）
2. 从左侧面板拖一个 **User Task** 到画布
3. 点击 Start Event，拖动箭头连接到 User Task
4. 选中 User Task，在属性面板中设置：
   - **Name**：`经理审批`
   - **Assignments（分配）**：
     - 点击 **Assigned to**
     - 填写 `lisi`（指定李四审批）
5. 从左侧拖一个 **End Event** 到画布
6. 将 User Task 连接到 End Event
7. 点击工具栏 **Save（保存）**图标

### 2.5 设置条件分支（进阶）

如果需要根据条件走不同分支：

1. 拖入一个 **Exclusive Gateway**（排他网关）
2. 从网关拉出多条线到不同的 User Task
3. 点击连线，在属性面板设置 **Flow condition**：
   - 例如：`${days <= 3}` 走经理审批
   - 例如：`${days > 3}` 走总经理审批

### 2.6 部署流程

1. 保存流程模型后，返回 Modeler 首页
2. 点击流程模型右侧的 **...（更多操作）**
3. 选择 **Publish / Export**
4. 或者在 **Task App** 中创建 App 来部署（见下文）

### 2.7 通过 App 部署流程

1. 在 Modeler 首页，点击顶部 **Apps** 标签
2. 点击 **Create App**
3. 填写 App 名称（如 `审批应用`）
4. 点击 **Edit included models** → 选择刚才创建的流程模型
5. 保存后，点击右上角 **Publish（发布）** 按钮
6. 发布成功后，流程即部署到引擎中

---

## 3. Task App - 任务发起与审批

Task App 用于发起流程实例、查看待办、处理任务。

### 3.1 发起流程

1. 进入主页，点击 **Task App**（或部署后的自定义 App）
2. 点击左侧菜单 **Processes（流程）**
3. 点击右上角 **Start a process（发起流程）**
4. 选择已部署的流程（如 `请假审批流程`）
5. 如果流程定义了表单，填写表单内容
6. 点击 **Start process**

### 3.2 查看我的待办

1. 点击左侧菜单 **Tasks（任务）**
2. 默认显示 **Involved tasks**（我参与的任务）
3. 可切换筛选：
   - **My tasks**：分配给我的任务
   - **Queued tasks**：候选人任务（需要签收）
   - **Involved tasks**：我参与的所有任务
   - **Completed tasks**：已完成的任务

### 3.3 处理任务（审批）

1. 在待办列表中点击一个任务
2. 查看任务详情：
   - 流程名称、发起人、创建时间
   - 表单内容（如果有）
   - 附件、评论
3. 操作选项：
   - **Complete（完成）**：同意/通过，流程继续往下走
   - **Claim（签收）**：如果任务分配给候选组，需要先签收
   - **Add a comment**：添加审批意见
   - **Involve people**：添加相关人员
   - **Add attachment**：上传附件

### 3.4 切换用户测试

验证完整流程需要切换不同用户：

1. 点击右上角用户名 → **Sign out**
2. 用其他用户登录（如 `lisi` / 密码）
3. 进入 Task App 查看待办任务并处理

### 3.5 查看流程进度

1. 在 Processes 页面，点击一个运行中的流程实例
2. 可以看到：
   - 流程图（高亮当前节点）
   - 已完成的节点
   - 流程变量
   - 历史记录

---

## 4. Admin App - 管理与监控

Admin App 用于监控引擎状态、管理部署、排查问题。

### 4.1 配置引擎端点

首次使用 Admin App 需要配置连接的引擎：

1. 进入 **Admin App**
2. 如果提示配置端点，使用默认值即可：
   - **Server address**：`http://localhost:8080`（Docker 内部地址）
   - **Context root**：`flowable-ui`
   - **REST root**：`process-api`、`cmmn-api`、`dmn-api` 等
   - **用户名/密码**：`admin` / `test`

### 4.2 流程引擎管理

点击顶部菜单 **Process Engine**：

#### 4.2.1 Deployments（部署管理）

- 查看所有已部署的流程
- 点击部署记录可查看包含的流程定义
- 可以删除部署

#### 4.2.2 Definitions（流程定义）

- 查看所有流程定义及版本
- 点击可查看流程图
- 查看该定义下的所有实例

#### 4.2.3 Process Instances（流程实例）

- 查看所有运行中/已完成的流程实例
- 可按状态筛选：
  - **Active**：运行中
  - **Completed**：已完成
  - **Suspended**：已挂起
- 点击实例可查看：
  - 流程图（高亮当前位置）
  - 变量列表
  - 任务列表
  - 子流程
- 可以操作：
  - **Delete**：删除实例
  - **Suspend**：挂起实例

#### 4.2.4 Tasks（任务管理）

- 查看所有任务
- 可按状态筛选
- 查看任务详情、分配人、创建时间

#### 4.2.5 Jobs（定时任务/异步任务）

- 查看异步 Job 执行情况
- **Dead letter jobs**：执行失败的任务（重点关注）
- 可以重试或删除失败的 Job

### 4.3 常用排查操作

| 问题 | 在哪里看 |
|---|---|
| 流程部署失败 | Deployments → 查看错误信息 |
| 流程卡住不动 | Process Instances → 查看当前节点 |
| 任务没分配到人 | Tasks → 检查 Assignee |
| 异步任务失败 | Jobs → Dead letter jobs |
| 流程变量不对 | Process Instances → Variables |

---

## 5. 完整演示：请假审批流程

以下是一个从零开始的完整操作流程。

### 第1步：创建用户（IDM App）

1. 登录 `admin / test`
2. 进入 IDM App
3. 创建用户：
   - `zhangsan`（张三 - 员工）
   - `lisi`（李四 - 经理）
4. 给所有用户授予 **Access the workflow application** 权限
 

### 第3步：部署流程（Modeler App）

1. 切换到 Apps 标签
2. 创建 App：
   - Name：`请假应用`
   - Icon & Theme：选一个颜色和图标
3. Edit included models → 勾选「请假审批」
4. 保存 → **Publish（发布）**

### 第4步：发起流程（Task App）

1. 退出登录，用 `zhangsan` 登录
2. 进入 Task App，会看到刚发布的「请假应用」
3. 点击进入 → Processes → Start a process
4. 选择「请假审批」→ Start process
5. 流程发起成功

### 第5步：审批任务（Task App）

1. 退出登录，用 `lisi` 登录
2. 进入 Task App → 「请假应用」
3. 在 Tasks 中看到待办：「经理审批」
4. 点击任务 → 可添加评论
5. 点击 **Complete** 完成审批
6. 流程结束

### 第6步：查看记录（Admin App）

1. 用 `admin` 登录
2. 进入 Admin App → Process Engine → Process Instances
3. 切换到 **Completed** 状态
4. 可以看到刚才完成的流程实例
5. 点击查看完整的执行历史

---

## 附录：常用 REST API

流程部署成功后，业务系统可通过 REST API 调用（默认需要 Basic Auth）：

```bash
# 查看已部署的流程定义
curl -u admin:test http://服务器IP:8080/flowable-ui/process-api/repository/process-definitions

# 发起流程
curl -u admin:test -X POST \
  http://服务器IP:8080/flowable-ui/process-api/runtime/process-instances \
  -H "Content-Type: application/json" \
  -d '{
    "processDefinitionKey": "leave-approval",
    "variables": [
      {"name": "applicant", "value": "zhangsan"},
      {"name": "days", "value": 3}
    ]
  }'

# 查询待办任务
curl -u admin:test \
  "http://服务器IP:8080/flowable-ui/process-api/runtime/tasks?assignee=lisi"

# 完成任务
curl -u admin:test -X POST \
  http://服务器IP:8080/flowable-ui/process-api/runtime/tasks/{taskId} \
  -H "Content-Type: application/json" \
  -d '{"action": "complete"}'
```

---

## 附录：注意事项

1. **数据持久化**：默认使用内嵌 H2 数据库，Docker 重启后数据丢失。生产环境请挂载外部 MySQL
2. **安全**：默认无 HTTPS，生产环境需配置 Nginx 反向代理 + SSL
3. **性能**：单机 Docker 部署适合验证和小规模使用，高并发场景需集群部署
4. **版本**：此教程基于 Flowable 6.8.x，7.x 版本界面和 API 可能有差异
