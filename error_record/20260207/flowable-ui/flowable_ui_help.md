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
5. [完整演示：请假两级审批流程](#5-完整演示请假两级审批流程)
6. [常见问题排查](#附录常见问题排查)

---

## 1. IDM App - 用户与权限管理

IDM（Identity Management）用于管理用户、分组和权限。在画流程图之前，先创建好参与流程的用户。

操作顺序：**先创建用户 → 再创建分组 → 最后设置权限**（因为分组需要添加已有用户，权限需要分配给已有用户或分组）。

### 1.1 创建用户

1. 进入主页，点击 **IDM App**
2. 点击顶部菜单 **Users（用户）**
3. 点击右上角 **Create user（创建用户）**
4. 填写信息：
   - **ID**：用户唯一标识（如 `zhangsan`）
   - **First name**：名（如 `三`）
   - **Last name**：姓（如 `张`）
   - **Email**：邮箱（如 `zhangsan@test.com`）
   - **Password**：密码
   - **Tenant**：租户标识，用于多租户隔离（多组织共用一套系统时区分不同组织）。**单组织使用或测试学习时留空不填即可**
5. 点击 **Save** 保存

> **注意：First name 和 Last name 必须填写！** 后续在分组中添加用户时，系统通过姓名和邮箱搜索用户，而不是通过 ID 搜索。如果姓名为空，将无法在分组中搜索到该用户。

建议创建以下测试用户：

| ID | First name | Last name | Email | 角色说明 |
|---|---|---|---|---|
| zhangsan | 三 | 张 | zhangsan@test.com | 业务发起人 |
| lisi | 四 | 李 | lisi@test.com | 经理（一级审批） |
| wangwu | 五 | 王 | wangwu@test.com | 董事长（二级审批） |

### 1.2 创建分组

1. 点击顶部菜单 **Groups（分组）**
2. 点击 **Create group**
3. 填写：
   - **ID**：分组标识（如 `initiators`）
   - **Name**：分组名称（如 `业务发起人`）
4. 保存后，点击该分组
5. 点击 **Add user**，搜索用户的**姓名**（如搜索 `张` 或 `三`），将用户添加到分组

> **注意：** 搜索用户时请输入 First name、Last name 或 Email，不支持通过用户 ID 搜索。

建议创建以下分组：

| ID | Name | 包含用户 |
|---|---|---|
| initiators | 业务发起人 | zhangsan（张三） |
| managers | 经理组 | lisi（李四） |
| directors | 董事长 | wangwu（王五） |

### 1.3 设置权限

1. 点击顶部菜单 **Privileges（权限）**
2. 系统内置以下权限：

| 权限 | 作用 | 建议授予给谁 |
|---|---|---|
| **Access identity management application** | 访问 IDM App，管理用户、分组、权限 | 仅 admin |
| **Access admin application** | 访问 Admin App，监控引擎、管理部署和流程实例 | 仅 admin |
| **Access modeler application** | 访问 Modeler App，设计和编辑流程图 | admin（或流程设计人员） |
| **Access the workflow application** | 访问 Task App，发起流程、处理审批任务 | **所有业务用户**（zhangsan、lisi、wangwu） |
| **Access the REST API** | 允许通过 REST API 调用流程引擎 | 需要接口调用时才开启 |

3. 点击对应权限，添加用户或分组

> **典型审批场景的权限配置：** 普通业务用户（发起人、审批人）只需要授予 **Access the workflow application** 即可。流程设计用 admin 账号完成，无需给业务用户开放 Modeler 和 Admin 权限。

---

## 2. Modeler App - 流程建模设计

Modeler 是核心功能，用于通过拖拽方式设计 BPMN 流程图。使用 `admin` 账号登录操作。

### 2.1 创建流程模型

1. 进入主页，点击 **Modeler App**
2. 点击 **Create Process（创建流程）**
3. 填写基本信息：
   - **Process name**：流程名称（如 `两级审批流程`）
   - **Process key**：流程标识（如 `two-level-approval`，唯一，后续 API 调用用这个）
   - **Description**：流程描述（如 `业务发起人→经理审批→董事长审批`）
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

> **注意区分两种网关：** 排他网关（X）是多条分支只走一条，并行网关（+）是多条分支同时都走。审批场景中"同意/拒绝"分支用排他网关。

### 2.4 流程图节点属性说明

#### 2.4.1 Start Event（开始节点）属性

点击开始节点，在属性面板中可以看到以下属性：

| 属性 | 作用 | 建议 |
|---|---|---|
| **Name** | 节点显示名称 | 填 `发起申请` |
| **Initiator** | 变量名，用来保存流程发起人的用户 ID | **填 `initiator`**（重要！后续打回修改时需要用 `${initiator}` 引用发起人） |
| **Id** | 节点唯一标识，自动生成 | 不用改 |
| **Documentation** | 节点备注说明 | 不用填 |
| **Form reference** | 关联表单编辑器创建的表单 | 暂不用填 |
| **Form key** | 关联外部表单的 key | 不用填 |
| **Form properties** | 内联定义简单表单字段 | 暂不用填 |
| **Validate form fields** | 是否校验表单字段 | 不用填 |
| **Execution listeners** | 节点触发时执行的 Java 监听器 | 不用填 |

> **重要提示：Initiator 属性必须填写！** 如果留空，后续流程中使用 `${initiator}` 引用发起人时会报错。

#### 2.4.2 User Task（用户任务节点）属性

点击用户任务节点，属性面板中的属性较多，按用途分组说明：

**核心属性（需要设置）：**

| 属性 | 作用 | 说明 |
|---|---|---|
| **Name** | 节点显示名称，审批人看到的任务标题 | 如 `经理审批`、`董事长审批` |
| **Assignments** | 指定谁来处理这个任务 | 见下方详细说明 |
| **Form properties** | 定义审批表单字段（如同意/拒绝下拉框） | 见下方详细说明 |
| **Id** | 节点唯一标识，自动生成 | 不用改 |

**Assignments 分配方式：**

点击 Assignments 后弹出窗口，有两种类型可选：

| 类型 | 说明 |
|---|---|
| **Identity store** | 从系统用户库中搜索选择用户，适合固定人员审批 |
| **Fixed values** | 手动输入用户 ID 或表达式，适合动态分配（如 `${initiator}`） |

两种类型选一种即可，不需要都填。

**Identity store 类型下的选项：**

| 选项 | 含义 | 示例 |
|---|---|---|
| **Assigned to** | 直接指定一个人处理 | 选择 `li si`（任务直接分给李四） |
| **Candidate users** | 候选用户，多人中任一人签收后处理 | 选择多个用户 |
| **Candidate groups** | 候选用户组，组内任一人签收后处理 | 选择 `经理组` |

> **注意：** Identity store 下还有一个复选框 **Allow process initiator to complete task**，**不要勾选**。勾选后发起人可以自己完成审批任务，等于自己审批自己，失去审批意义。

**Fixed values 类型下的选项：**

| 选项 | 含义 | 示例 |
|---|---|---|
| **Assignee** | 手动输入用户 ID 或表达式 | `${initiator}`（动态分配给发起人） |
| **Candidate users** | 手动输入候选用户 ID | 多个用户 ID |
| **Candidate groups** | 手动输入候选组 ID | 组 ID |

**表单相关属性：**

| 属性 | 作用 |
|---|---|
| **Form reference** | 关联用表单编辑器创建的独立表单（**推荐使用**） |
| **Form key** | 关联外部表单的 key |
| **Form properties** | 内联定义简单表单字段 |
| **Validate form fields** | 是否校验表单必填项 |

> **重要：Form properties（内联表单）在 Flowable UI 的 Task App 中不会渲染！** 即使配置了字段，审批人在 Task App 中也看不到表单，只会看到一个 Complete 按钮。必须使用 **Form reference** 关联通过 Form Editor 创建的独立表单，表单才能正常显示。

**多实例相关属性（会签场景才用，普通审批不用填）：**

| 属性 | 作用 |
|---|---|
| **Multi-instance type** | 多实例类型：Parallel（并行会签）/ Sequential（串行会签） |
| **Cardinality** | 实例数量 |
| **Collection** | 审批人列表变量 |
| **Element variable** | 循环中的当前审批人变量名 |
| **Completion condition** | 完成条件（如半数通过） |
| **Variable aggregations** | 多实例变量聚合方式 |

**高级属性（不用动）：**

| 属性 | 作用 |
|---|---|
| **Documentation** | 节点备注说明 |
| **Exclusive** | 排他执行，默认 true |
| **Asynchronous** | 是否异步执行 |
| **Priority** | 任务优先级 |
| **Due date** | 任务截止日期 |
| **Category** | 任务分类标签 |
| **Skip expression** | 满足条件时跳过此节点 |
| **Is for compensation** | 是否为补偿任务 |
| **Task listeners** | 任务生命周期监听器 |
| **Execution listeners** | 执行监听器 |
| **ID variable** | 自定义变量名存储任务 ID |

#### 2.4.3 流程公共属性

点击画布空白区域，可以看到整个流程的公共属性：

| 属性 | 作用 | 建议 |
|---|---|---|
| **Name** | 流程名称 | 已填 |
| **Process identifier** | 流程唯一标识 | 已填 |
| **Documentation** | 流程说明 | 已填 |
| **Is executable** | 流程是否可执行 | **必须勾选**，否则无法运行 |
| **Potential starter user** | 限制哪些用户可以发起流程 | 留空表示不限制 |
| **Potential starter group** | 限制哪些用户组可以发起流程 | 留空表示不限制 |
| **Process version string** | 版本号说明，仅文档用途 | 不用填 |
| **Process author** | 流程设计者 | 不用填 |
| **Target namespace** | XML 命名空间 | 不用填 |
| **Set a specific history level** | 自定义历史记录级别 | 不用填 |
| **Eager execution fetching** | 性能优化选项 | 不勾选 |
| **Signal/Message/Escalation definitions** | 定义信号、消息、升级事件 | 不用填 |
| **Data Objects** | 流程级数据对象 | 不用填 |
| **Execution/Event listeners** | 流程级监听器 | 不用填 |

### 2.5 使用 Form Editor 创建表单

由于 Form properties（内联表单）在 Task App 中不会渲染，必须使用 Form Editor 创建独立表单。

#### 2.5.1 创建请假申请表单

1. 进入 Modeler 首页，点击顶部 **Forms** 标签
2. 点击 **Create Form**
3. 名称填 `请假申请表单`，点击 Create
4. 进入表单编辑器，从左侧拖入组件：
   - **Text** → Label: `请假原因`，勾选 Override id，Id 填 `reason`
   - **Number** → Label: `请假天数`，勾选 Override id，Id 填 `days`
   - **Date** → Label: `开始日期`，勾选 Override id，Id 填 `startDate`
5. 根据需要勾选 **Required**
6. 保存

#### 2.5.2 创建审批表单

1. 再创建一个表单，名称 `审批表单`
2. 拖入组件：
   - **Text** → Label: `请假原因`，Id: `reason`，勾选 **Read-only**（审批人只能看不能改）
   - **Number** → Label: `请假天数`，Id: `days`，勾选 **Read-only**
   - **Date** → Label: `开始日期`，Id: `startDate`，勾选 **Read-only**
   - **Dropdown** → Label: `审批结果`，Id: `approved`
3. 设置 Dropdown 的选项（Options 标签）：
   - 点击 **+ Add a new option**
   - 添加两个选项：`true` 和 `false`
4. 保存

> **审批表单中申请信息必须设为 Read-only！** 如果不勾选 Read-only，审批人可以修改发起人填写的申请内容。只有 Dropdown（审批结果）不勾选 Read-only，让审批人可以选择同意/驳回。

> **Dropdown 选项的坑：** Flowable Form Editor 的 Dropdown 选项只有一个输入框，输入的内容同时作为显示值和存储值。**必须填写 `true` 和 `false`**（而不是"同意"/"驳回"），否则网关条件 `${approved=='true'}` 匹配不上会报错。

#### 2.5.3 表单、流程模型、App 的关系

```
App（审批应用）
 └── 流程模型（请假模型）
      ├── Start Event → 关联 → 请假申请表单
      ├── 经理审批   → 关联 → 审批表单
      ├── 董事长审批 → 关联 → 审批表单
      └── 修改重提   → 关联 → 请假申请表单
```

三者是引用关系，修改了表单或流程模型后，只需要重新 **Publish App** 即可生效，不需要重新绑定关联关系。

### 2.6 画两级审批流程（含拒绝打回）

**目标流程：** 发起申请（直接填写表单）→ 经理审批 → 董事长审批 → 结束。任何一级审批拒绝，打回给发起人修改后重新提交。

```
                               同意                            同意
○(带表单) → [经理审批] → ◇ ──────→ [董事长审批] → ◇ ──────→ ◉ 通过
                ↑          │ 拒绝                     │ 拒绝
                │          ↓                          │
                └─── [修改重提] ←─────────────────────┘
                    (${initiator})
```

> **设计说明：** Start Event 关联申请表单，发起流程时直接弹出表单一步完成，不需要单独的「填写申请」节点。由于 Start Event 不能接收回流，所以拒绝打回时用一个「修改重提」节点来承接。

#### 第1步：设置开始节点

1. 点击画布上的 **Start Event**（开始圆圈）
2. 在属性面板设置：
   - **Name**：`发起申请`
   - **Initiator**：`initiator`
   - **Form reference**：选择 `请假申请表单`

这样用户点击 Start process 时会直接弹出申请表单，填写完成后流程启动并进入下一个节点。

#### 第2步：创建经理审批节点

1. 点击 Start Event，在弹出的图标中点击 **圆角矩形（Task）**，自动创建节点并连线
2. 设置属性：
   - **Name**：`经理审批`
   - **Assignments**：选 Identity store 类型，Assigned to 选择 `li si`，**不勾选** Allow process initiator to complete task
   - **Form reference**：选择 `审批表单`

#### 第3步：创建董事长审批节点

1. 点击「经理审批」，点击弹出的 **圆角矩形** 图标创建节点
2. 设置属性：
   - **Name**：`董事长审批`
   - **Assignments**：选 Identity store 类型，Assigned to 选择 `wang wu`，**不勾选** Allow process initiator to complete task
   - **Form reference**：选择 `审批表单`（和经理审批用同一个）

#### 第4步：创建结束节点

1. 点击「董事长审批」，点击弹出的 **粗线圆圈（End Event）** 图标

此时流程为：开始 → 经理审批 → 董事长审批 → 结束（先保存一版）。

#### 第5步：添加排他网关和拒绝分支

**在经理审批后添加网关1：**

1. 删除「经理审批」→「董事长审批」的连线（点击连线，按 Delete）
2. 点击「经理审批」，点击弹出的 **菱形（Exclusive Gateway）** 图标，创建网关1
3. 从网关1 连线到「董事长审批」
4. 设置连线属性：
   - **Name**：`同意`
   - **Flow condition**：`${approved=='true'}`

**在董事长审批后添加网关2：**

1. 删除「董事长审批」→「结束」的连线
2. 点击「董事长审批」，创建 **Exclusive Gateway**（网关2）
3. 从网关2 连线到结束节点
4. 设置连线属性：
   - **Name**：`同意`
   - **Flow condition**：`${approved=='true'}`

> **注意：排他网关的每条出线都必须设置 Flow condition！** 如果漏设条件，校验时会告警："Exclusive gateway has at least one outgoing sequence without a condition"，发布后运行也会报错。

#### 第6步：创建修改重提节点并连线

1. 在流程图下方空白区域，从左侧面板拖入一个 **User Task**
2. 设置属性：
   - **Name**：`修改重提`
   - **Assignments**：选 **Fixed values** 类型，Assignee 填 `${initiator}`，**勾选** Allow process initiator to complete task
   - **Form reference**：选择 `请假申请表单`（和 Start Event 用同一个表单，让发起人修改申请内容）
3. 从网关1 连线到「修改重提」，设置连线：
   - **Name**：`拒绝`
   - **Flow condition**：`${approved=='false'}`
4. 从网关2 连线到「修改重提」，设置连线：
   - **Name**：`拒绝`
   - **Flow condition**：`${approved=='false'}`
5. 从「修改重提」连线回「经理审批」（不需要设置条件）

> **Allow process initiator to complete task 的使用规则：**
> - 「修改重提」节点：**必须勾选**（这个节点就是给发起人自己操作的）
> - 「经理审批」「董事长审批」节点：**不要勾选**（防止发起人自己审批自己）

#### 第7步：保存

1. 点击工具栏 **Save** 图标
2. 建议勾选 **Save this as a new version** 复选框（保留历史版本，方便回退）
3. 点击 **Save**

### 2.7 连线技巧

- **创建连线**：点击节点后，从弹出的图标中选择目标组件类型，会自动创建节点并连线。也可以拖动节点边缘的箭头到另一个已有节点来创建连线。
- **直线变折线**：Flowable Modeler 不支持手动给直线添加折点。折线是在移动节点时由系统自动生成的。生成折线后会出现红色折点，可以拖拽红色折点调整折线形状。绿色的点是连接点（头尾），不可拖动。
- **折线技巧**：如果想让某条连线变成折线，可以临时拖动相关节点的位置让系统自动生成折线和红色折点，然后再把节点移回原位，折线和折点会保留下来。也可以在连线路径上临时放置一个 Task 节点让线绕路产生折线，删除该 Task 后折线会保留。

### 2.8 部署流程

#### 2.8.1 通过 App 部署（推荐）

1. 返回 Modeler 首页，点击顶部 **Apps** 标签
2. 点击 **Create App**
3. 填写 App 名称（如 `审批应用`），选择图标和颜色
4. 点击 **Edit included models** → 勾选刚才创建的流程模型
5. 保存时会出现复选框 **Publish?** — 勾选后保存并立即发布，省去单独点 Publish 的步骤
6. 如果没有勾选 Publish，保存后需要手动点击右上角 **Publish（发布）** 按钮
7. 发布成功后，流程即部署到引擎中

> **更新流程后重新发布：** 修改流程图后，除了保存流程模型，还需要回到 App 重新 Publish。否则运行的还是旧版本。

#### 2.8.2 直接部署

1. 保存流程模型后，返回 Modeler 首页
2. 点击流程模型右侧的 **...（更多操作）**
3. 选择 **Publish / Export**

> **发布报错 "Exception during command execution" 的排查：**
>
> 这个错误通常是流程图有问题，常见原因：
> - 连线缺失 — 某个节点没有连出去的线（比如网关只连了一条分支）
> - 网关条件没设 — 排他网关出去的连线没有写 Flow condition
> - 节点 ID 重复 — 复制粘贴节点导致 ID 冲突
> - Assignments 为空 — User Task 没有设置审批人
>
> 排查方法：回到 Modeler 打开流程图，检查每个节点都有进线和出线、排他网关的每条出线都设了 Flow condition、所有 User Task 都设了 Assignments。修正后重新保存并发布。
>
> 验证是否发布成功：用业务用户登录 Task App 查看是否出现该应用，或用 admin 进入 Admin App → Process Engine → Deployments 查看部署记录。

#### 2.8.3 删除多余的部署

在 Modeler 中删除 App 模型只是删除了设计文件，**已经部署到引擎中的 App 不会自动删除**，业务用户登录后仍然能看到旧的 App。需要在 Admin App 中手动删除：

1. 用 admin 登录，进入 **Admin App**
2. 点击 **Process Engine** → **Deployments**
3. 找到多余的旧部署记录
4. 点击进去，点击 **Delete** 删除

删除后业务用户刷新页面就不会再看到多余的 App 了。

---

## 3. Task App - 任务发起与审批

Task App 用于发起流程实例、查看待办、处理任务。

> **注意区分 Task App 和自定义 App：** 用户登录后主页会看到一个系统自带的 **Task App**（默认应用，不可删除）以及通过 Modeler 发布的自定义 App（如「审批应用」）。**请进入自定义 App 操作**，在里面才能看到对应的流程和任务。如果进错了 App，会看不到任务。

### 3.1 Task App 界面说明

进入 App 后有三个页签：

| 页签 | 作用 | 说明 |
|---|---|---|
| **Tasks** | 查看和处理待办任务（审批、签收等） | **主要使用** |
| **Processes** | 查看和发起流程实例 | 发起流程、查看流程进度 |
| **Cases** | CMMN 案例管理 | 和 BPMN 审批流程无关，不用管 |

### 3.2 发起流程

1. 进入主页，点击部署后的自定义 App（如「审批应用」）
2. 点击 **Processes** 页签
3. 点击 **+ Start a process**
4. 选择已部署的流程（如 `请假审批流程`）
5. 如果 Start Event 关联了表单，会弹出表单让你填写
6. 填写完成后点击 **Start process**，流程启动并直接流转到下一个审批节点

> **Start Event 是否关联表单决定了发起体验：**
> - **关联了表单**：点击 Start process 时直接弹出表单，填写后一步完成发起（推荐）
> - **没有关联表单**：点击 Start process 直接启动流程，如果需要填写信息则需要在 Tasks 中找到对应任务再填写

### 3.3 查看我的待办

1. 点击 **Tasks** 页签
2. 默认显示 **Involved tasks**（我参与的任务）
3. 可切换筛选：
   - **My tasks**：分配给我的任务
   - **Queued tasks**：候选人任务（需要签收）
   - **Involved tasks**：我参与的所有任务
   - **Completed tasks**：已完成的任务

### 3.4 处理任务（审批）

1. 在待办列表中点击一个任务
2. 查看任务详情：
   - 流程名称、发起人、创建时间
   - 表单内容（通过 Form reference 关联的表单会显示在这里）
   - 附件、评论
3. 操作选项：
   - **Complete（完成）**：填写表单后点击完成，流程继续往下走
   - **Claim（签收）**：如果任务分配给候选组，需要先签收
   - **Add a comment**：添加审批意见
   - **Involve people**：添加相关人员
   - **Add attachment**：上传附件

> **如果看不到表单只有 Complete 按钮：** 说明表单没有正确关联。检查流程图中对应节点的 **Form reference** 是否选择了表单。注意 Form properties（内联表单）在 Task App 中不会渲染，必须使用 Form reference。

### 3.5 切换用户测试

验证完整流程需要切换不同用户（建议使用浏览器无痕模式同时登录多个账号）：

1. 点击右上角用户名 → **Sign out**
2. 用其他用户登录（如 `lisi` / 密码）
3. **进入对应的自定义 App**（不是默认的 Task App）
4. 在 Tasks 中查看待办任务并处理

### 3.6 查看流程进度

1. 在 **Processes** 页签，点击一个运行中的流程实例
2. 可以看到：
   - **Show diagram**：查看流程图（高亮当前节点）
   - **Active tasks**：当前待处理的任务及分配人
   - **Completed tasks**：已完成的节点及完成人
   - **Cancel process**：取消流程

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

## 5. 完整演示：请假两级审批流程

以下是一个从零开始的完整操作流程。

### 第1步：创建用户（IDM App）

1. 用 `admin / test` 登录
2. 进入 IDM App → Users
3. 创建三个用户（注意 First name 和 Last name 必须填写）：

| ID | First name | Last name | Email | 角色 |
|---|---|---|---|---|
| zhangsan | 三 | 张 | zhangsan@test.com | 业务发起人 |
| lisi | 四 | 李 | lisi@test.com | 经理（一级审批） |
| wangwu | 五 | 王 | wangwu@test.com | 董事长（二级审批） |

### 第2步：设置权限（IDM App）

1. 进入 Privileges
2. 点击 **Access the workflow application**
3. 添加 zhangsan、lisi、wangwu 三个用户

### 第3步：创建表单（Modeler App）

1. 进入 Modeler App → Forms 标签
2. 创建 `请假申请表单`：Text（请假原因）、Number（请假天数）、Date（开始日期）
3. 创建 `审批表单`：Text（请假原因，只读）、Number（请假天数，只读）、Date（开始日期，只读）、Dropdown（审批结果，选项：true / false）

### 第4步：画流程图（Modeler App）

1. 进入 Processes 标签 → Create Process
2. 按照 [2.6 画两级审批流程](#26-画两级审批流程含拒绝打回) 的步骤画图
3. 各节点关联对应的表单（Form reference）
4. 保存

### 第5步：部署流程（Modeler App）

1. 切换到 Apps 标签
2. Create App → Name：`审批应用`，选图标和颜色
3. Edit included models → 勾选流程模型
4. 保存时勾选 **Publish** 直接发布

### 第6步：发起流程（zhangsan）

1. 用 `zhangsan` 登录（建议用浏览器无痕模式）
2. 主页点击「审批应用」进入
3. Processes → + Start a process → 选择流程
4. 弹出申请表单，填写请假原因、天数、日期
5. 点击 **Start process**，流程发起并直接流转到经理审批

### 第7步：经理审批（lisi）

1. 用 `lisi` 登录
2. 主页点击「审批应用」进入（**注意不要进错 App**）
3. Tasks 中看到「经理审批」待办
4. 可以看到请假信息（只读），Dropdown 选择 `true`（同意）或 `false`（驳回）
5. 点击 **Complete**
6. 如果同意 → 流转到董事长审批；如果拒绝 → 打回给 zhangsan 重新填写

### 第8步：董事长审批（wangwu）

1. 用 `wangwu` 登录
2. 主页点击「审批应用」进入
3. Tasks 中看到「董事长审批」待办
4. Dropdown 选择 `true`（同意）或 `false`（驳回）
5. 点击 **Complete**
6. 如果同意 → 流程结束；如果拒绝 → 打回给 zhangsan 重新填写

### 第9步：查看记录（Admin App）

1. 用 `admin` 登录
2. 进入 Admin App → Process Engine → Process Instances
3. 切换到 **Completed** 状态
4. 可以看到完成的流程实例
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

## 附录：常见问题排查

### 问题1：分组中搜索不到用户

**现象：** 在 Groups 中点击 Add user，搜索用户 ID 找不到。

**原因：** 系统通过 First name、Last name、Email 搜索用户，不支持通过 ID 搜索。

**解决：** 确保用户的 First name 和 Last name 已填写，搜索时输入姓名而不是 ID。

### 问题2：审批人看不到表单，只有 Complete 按钮

**现象：** 审批人打开任务后看不到任何表单字段，只有一个 Complete 按钮和一些默认操作（添加评论、附件等）。

**原因：** 使用了 Form properties（内联表单），这在 Flowable UI 的 Task App 中不会渲染。

**解决：** 使用 Form Editor 创建独立表单，通过 **Form reference** 关联到对应的 User Task 节点。

### 问题3：排他网关报错 "No outgoing sequence flow could be selected"

**现象：** 审批人点击 Complete 后报错。Docker 日志中显示：`No outgoing sequence flow of the exclusive gateway 'xxx' could be selected for continuing the process`

**原因：** 有以下几种可能：
1. 排他网关的出线没有设置 Flow condition
2. 审批结果变量 `approved` 没有被正确设置（表单没有渲染导致变量为空）
3. Dropdown 选项的值和网关条件不匹配（如选项值写成了"同意"/"驳回"，但条件判断的是 `'true'`/`'false'`）

**解决：** 
- 确保排他网关的每条出线都设了 Flow condition
- 确保使用 Form reference（不是 Form properties）
- 确保 Dropdown 选项值填写 `true` 和 `false`，和条件 `${approved=='true'}` 匹配

### 问题4：发布报错 "Exception during command execution"

**现象：** 点击 Publish 时报错。

**原因：** 流程图存在结构问题（连线缺失、网关条件未设、节点无审批人等）。

**解决：** 点击流程设计器的校验按钮检查告警，逐个修复。常见检查项：每个节点都有进线和出线、排他网关的每条出线都设了条件、所有 User Task 都设了 Assignments。

### 问题5：修改流程后审批人看到的还是旧版本

**现象：** 修改了流程图或表单并重新发布，但正在运行的流程实例没有变化。

**原因：** 流程实例启动时会绑定当时的流程定义版本，不会自动更新到新版本。

**解决：** 
1. 在 Admin App → Process Instances 中删除旧的流程实例
2. 重新发起新的流程实例（使用新版本的流程定义）

### 问题6：用户登录后看到多余的 App

**现象：** 业务用户登录主页看到很多旧的 App。

**原因：** 在 Modeler 中删除 App 模型只是删除了设计文件，已部署到引擎中的 App 不会自动删除。

**解决：** 用 admin 登录 Admin App → Process Engine → Deployments，找到多余的旧部署记录，逐个 Delete。

### 问题7：审批人看不到待办任务

**现象：** 流程显示任务已分配给某用户，但该用户登录后 Tasks 和 Processes 都是空的。

**原因：** 
1. 用户进错了 App（进了默认的 Task App 而不是自定义的「审批应用」）
2. 用户没有 Access the workflow application 权限

**解决：** 确保进入正确的自定义 App，确认用户已授予 workflow 权限。

### 问题8：查看 Docker 日志

当遇到运行时报错时，可以通过 Docker 日志定位问题：

```bash
# 查看最近的日志
docker logs flowable --tail 200

# 过滤错误信息
docker logs flowable --tail 300 2>&1 | grep -E "ERROR|Caused by|Exception"
```

也可以通过浏览器 F12 → Network 标签查看请求的 Response 错误信息。

---

## 附录：注意事项

1. **数据持久化**：默认使用内嵌 H2 数据库，Docker 重启后数据丢失。生产环境请挂载外部 MySQL
2. **安全**：默认无 HTTPS，生产环境需配置 Nginx 反向代理 + SSL
3. **性能**：单机 Docker 部署适合验证和小规模使用，高并发场景需集群部署
4. **版本**：此教程基于 Flowable 6.8.x，7.x 版本界面和 API 可能有差异
