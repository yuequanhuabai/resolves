# 計劃：HR 系統與 Flowable 流程引擎集成

## Context

HR 人事管理系統（hr-backend + hr-ui）需要引入流程審批能力（如請假申請）。
Flowable 流程引擎作為獨立服務，HR 系統作為業務方調用它。
兩個系統分開部署，通過 HTTP API 對接。

**前提**：管理員先在流程引擎設計器設計並部署流程圖，HR 系統才能發起流程。

## 系統信息

| 系統 | 端口 | 基礎路徑 | 認證 |
|------|------|---------|------|
| HR Backend | 8080 | `/api` | JWT Bearer Token |
| HR Frontend | 5173 | — | token 存 localStorage |
| Flowable Engine | 9090 | `/workflow` | 無 |
| Flowable Designer UI | 3000 | — | 無 |

## 改動範圍（4個項目）

---

## A. HR Backend 改動

### A1. 新增內部接口（無需認證，供流程設計器調用）

**新建文件**：`hr-system/src/main/java/com/hr/system/controller/InternalController.java`
- `GET /internal/user/simple-list` → 返回 `List<{userId, username, nickname}>`
- `GET /internal/role/simple-list` → 返回 `List<{roleId, roleName, roleKey}>`

**修改文件**：`hr-framework/src/main/java/com/hr/framework/config/SecurityConfig.java`
- 在白名單中加入 `/internal/**`（不需要 token 訪問）

### A2. 新增工作流對接模塊

**新建文件**：`hr-system/src/main/java/com/hr/system/service/WorkflowClient.java`
- 用 RestTemplate 調用 Flowable 引擎接口
- `startProcess(processKey, userId, businessKey, variables)` → POST `http://localhost:9090/workflow/api/instance/start`
- `getMyTasks(userId)` → GET `http://localhost:9090/workflow/api/task/todo?assignee={userId}`
- `completeTask(taskId, variables)` → POST `http://localhost:9090/workflow/api/task/complete`
- `rejectTask(taskId, comment)` → POST `http://localhost:9090/workflow/api/task/reject`

**新建文件**：`hr-system/src/main/java/com/hr/system/controller/WorkflowController.java`
- 路徑前綴：`/workflow`（完整為 `/api/workflow`）
- `POST /workflow/start` — 發起流程（從 Spring Security 獲取當前登錄用戶作為 initiator）
- `GET /workflow/my-tasks` — 查詢當前用戶待辦
- `POST /workflow/task/{taskId}/complete` — 審批通過
- `POST /workflow/task/{taskId}/reject` — 駁回

**修改文件**：`hr-admin/src/main/resources/application.yml`
```yaml
workflow:
  engine:
    url: http://localhost:9090/workflow
```

---

## B. Flowable Designer UI 改動

### B1. 代理配置

**修改文件**：`flowable-designer-ui/vite.config.ts`
- 新增代理：`/hr-api` → `http://localhost:8080`（轉發到 HR 後端內部接口）

### B2. 新增 HR 用戶/角色 API

**新建文件**：`flowable-designer-ui/src/api/hrUser.ts`
- `listHrUsers()` → GET `/hr-api/internal/user/simple-list`
- `listHrRoles()` → GET `/hr-api/internal/role/simple-list`

### B3. 改造 UserTaskPanel

**修改文件**：`flowable-designer-ui/src/components/PropertiesPanel/panels/UserTaskPanel.vue`

當前：assignee / candidateUsers / candidateGroups 均為文本輸入

改後：
- `assignee` → `el-select`（從 HR 用戶列表單選，存 `username`）
- `candidateUsers` → `el-select multiple`（多選 HR 用戶，以逗號拼接存儲）
- `candidateGroups` → `el-select multiple`（多選 HR 角色，存 `roleKey`）
- 組件 `onMounted` 時調 `listHrUsers()` 和 `listHrRoles()` 加載數據
- HR 不可用時降級顯示文本輸入（try/catch 靜默處理）

---

## C. HR Frontend 改動

### C1. 新增工作流 API

**新建文件**：`hr-ui/src/api/workflow.ts`
- `startProcess(data)` → POST `/workflow/start`（通過 HR 後端轉發）
- `getMyTasks()` → GET `/workflow/my-tasks`
- `completeTask(taskId, variables)` → POST `/workflow/task/{taskId}/complete`
- `rejectTask(taskId, comment)` → POST `/workflow/task/{taskId}/reject`

### C2. 新增頁面

**新建文件**：`hr-ui/src/views/workflow/apply/index.vue`
- 請假申請表單（假期類型、開始/結束日期、原因）
- 選擇要使用的流程（下拉，從 Flowable 查已部署流程列表）
- 提交 → 調 `startProcess`

**新建文件**：`hr-ui/src/views/workflow/task/index.vue`
- 我的待辦列表（任務名稱、流程名稱、發起人、發起時間）
- 每行操作：「審批」按鈕 → 彈出對話框填寫意見 → 通過/駁回

### C3. 新增路由

**修改文件**：`hr-ui/src/router/index.ts`（或動態路由配置）
- 新增 `/workflow/apply` → 請假申請
- 新增 `/workflow/task` → 我的待辦

---

## 執行順序

1. A1 — HR Backend 內部接口 + SecurityConfig 白名單
2. B1+B2+B3 — 流程設計器 UserTask 改為 HR 用戶下拉
3. A2 — HR Backend 工作流對接（WorkflowClient + WorkflowController）
4. C1+C2+C3 — HR 前端工作流頁面

## 驗收流程

```
1. 流程引擎設計器：UserTask 審批人下拉出現 HR 用戶列表 → 選一個用戶 → 部署
2. HR 前端請假申請頁：填表 → 提交 → 後端發起流程實例
3. 審批人登錄 HR → 我的待辦 → 看到剛才的任務
4. 點擊審批通過 → 流程推進到下一節點或結束
```
