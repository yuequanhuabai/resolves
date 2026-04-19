# 後端架構文檔 — Spring Boot 3 + Flowable 7

## 一、整體架構

```
                         ┌─────────────────────────────────────────┐
                         │     流程引擎微服務 flowable-engine-server  │
                         │                                         │
業務服務A ──┐             │  ┌─────────────┐    ┌───────────────┐  │
            │  HTTP/REST  │  │ Controller  │    │ Flowable      │  │
業務服務B ──┼────────────▶│  │  (REST API) │───▶│ Engine 7.1.0  │──┼──▶ SQL Server
            │             │  └─────────────┘    └───────────────┘  │   (flowable_db)
業務服務C ──┘             │                                         │
                         │  ┌─────────────┐                        │
前端設計器 ──────────────▶│  │ Modeler API │  流程設計/部署          │
 (Vue3+bpmn-js)          │  └─────────────┘                        │
                         └─────────────────────────────────────────┘
```

---

## 二、技術選型

| 組件 | 版本 | 說明 |
|---|---|---|
| Java | 17 | Spring Boot 3 最低要求 |
| Spring Boot | 3.2.5 | 主框架 |
| Flowable | 7.1.0 | 流程引擎（已適配 jakarta.* 命名空間） |
| SQL Server | 與 HR 系統共用（`106.55.7.17:1433`） | 流程數據持久化，獨立庫 `flowable_db` |
| mssql-jdbc | 12.x | SQL Server JDBC 驅動 |
| HikariCP | 隨 Spring Boot | 連接池 |
| Knife4j | 4.5.0 | API 文檔（`/doc.html`） |
| Lombok | 隨 Spring Boot | 代碼簡化 |

---

## 三、項目結構（Maven 多模塊）

採用 **Maven Archetype + 多模塊**架構，對齊 HR 項目風格。3 個子模塊職責清晰，依賴鏈 `flowable-api → flowable-engine → flowable-common`。

```
flowable-engine-server/                          # 父工程（packaging: pom，無代碼）
├── pom.xml                                      # 父 POM（dependencyManagement 統一版本）
├── Dockerfile                                   # Docker 打包（從 flowable-api/target 取 jar）
├── docker-compose.yml                           # 容器編排（可選）
│
├── flowable-common/                             # 公共層（最底層）
│   ├── pom.xml
│   └── src/main/java/com/en/workflow/common/
│       └── dto/
│           └── R.java                           # 統一響應包裝（全模塊共用）
│
├── flowable-engine/                             # 引擎層（核心邏輯）
│   ├── pom.xml                                  # 依賴 flowable-common + Flowable starter
│   └── src/main/java/com/en/workflow/engine/
│       ├── config/
│       │   └── FlowableConfig.java              # 引擎定制（字體/中文）
│       ├── service/
│       │   ├── ProcessDefinitionService.java
│       │   ├── ProcessInstanceService.java
│       │   ├── FlowableTaskService.java
│       │   └── FlowableHistoryService.java
│       └── dto/
│           ├── request/
│           │   ├── StartProcessRequest.java
│           │   └── CompleteTaskRequest.java
│           └── response/
│               ├── ProcessDefinitionVO.java
│               ├── ProcessInstanceVO.java
│               └── TaskVO.java
│
└── flowable-api/                                # 啟動層（唯一可執行模塊）
    ├── pom.xml                                  # 依賴 flowable-engine + mssql-jdbc + knife4j
    └── src/main/
        ├── java/com/en/workflow/api/
        │   ├── WorkflowApplication.java         # 啟動類
        │   ├── config/
        │   │   └── CorsConfig.java              # 跨域（HTTP 邊界才需要）
        │   └── controller/
        │       ├── ProcessDefinitionController.java
        │       ├── ProcessInstanceController.java
        │       ├── TaskController.java
        │       └── HistoryController.java
        └── resources/
            ├── application.yml                  # 主配置（只放在啟動模塊才被讀取）
            ├── application-dev.yml              # 開發環境（SQL Server 連接）
            └── processes/                       # BPMN 文件自動部署目錄（可選）
```

### 模塊依賴鏈

```
flowable-api  ──▶  flowable-engine  ──▶  flowable-common
    │
    ├── mssql-jdbc (runtime)
    ├── knife4j
    └── spring-boot-maven-plugin（打 fat jar）
```

### 為什麼這樣拆？

| 模塊 | 職責 | 未來擴展 |
|---|---|---|
| **flowable-common** | 通用 POJO、異常、工具 | 可被未來的 `flowable-adapter-*` 模塊復用 |
| **flowable-engine** | 引擎配置 + Service 層 | 流程邏輯核心，可被其它啟動層（如 CLI 工具）復用 |
| **flowable-api** | 啟動類 + Controller + HTTP 邊界 | 唯一可執行模塊，未來可加 `flowable-api-mq` 等多種入口 |

---

## 四、對外 API 總覽

| 模塊 | 接口 | 方法 | 說明 |
|---|---|---|---|
| **流程定義** | `/api/process/deploy` | POST | 上傳 BPMN 文件部署流程 |
| | `/api/process/deploy-xml` | POST | 通過 BPMN XML 字符串部署 |
| | `/api/process/list` | GET | 查詢已部署流程列表（每個 Key 最新版本） |
| | `/api/process/delete/{deploymentId}` | DELETE | 刪除部署（級聯刪除實例） |
| | `/api/process/resource/{processDefinitionId}` | GET | 獲取流程定義 XML |
| **流程實例** | `/api/instance/start` | POST | 發起流程實例 |
| | `/api/instance/list` | GET | 查詢運行中的流程實例 |
| | `/api/instance/get-by-business-key` | GET | 通過 businessKey 查詢實例 |
| | `/api/instance/suspend/{instanceId}` | PUT | 掛起流程實例 |
| | `/api/instance/activate/{instanceId}` | PUT | 激活流程實例 |
| | `/api/instance/delete/{instanceId}` | DELETE | 終止並刪除實例 |
| **任務** | `/api/task/todo` | GET | 查詢指定用戶待辦任務 |
| | `/api/task/candidate` | GET | 查詢候選人待簽收任務 |
| | `/api/task/claim` | POST | 簽收任務 |
| | `/api/task/complete` | POST | 完成任務（審批通過） |
| | `/api/task/reject` | POST | 駁回任務到上一節點 |
| | `/api/task/delegate` | POST | 轉辦任務 |
| | `/api/task/detail/{taskId}` | GET | 任務詳情 |
| | `/api/task/list-by-instance/{instanceId}` | GET | 流程實例當前任務 |
| **歷史** | `/api/history/instances` | GET | 已完成流程查詢 |
| | `/api/history/activities/{instanceId}` | GET | 審批活動記錄 |
| | `/api/history/comments/{instanceId}` | GET | 審批意見查詢 |
| | `/api/history/diagram/{instanceId}` | GET | 流程圖（高亮已走節點，PNG） |

---

## 五、數據庫說明

與 HR 系統共用同一 SQL Server 實例，使用獨立數據庫：

| 項 | 值 |
|---|---|
| 服務器 | `106.55.7.17:1433` |
| 數據庫名 | `flowable_db` |
| 用戶名 | `sa` |
| 建庫語句 | `CREATE DATABASE flowable_db` |
| 自動建表 | Flowable 啟動時自動創建約 70+ 張表（`ACT_*`、`FLW_*` 前綴） |

---

## 六、業務系統調用方式

### 方式一：Feign Client（推薦）

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

### 方式二：HTTP 直接調用

```bash
# 發起流程
curl -X POST http://flowable-engine:9090/workflow/api/instance/start \
  -H "Content-Type: application/json" \
  -d '{"processKey": "leave-approval", "businessKey": "LEAVE-001", "variables": {"manager": "lisi"}}'

# 查詢待辦
curl "http://flowable-engine:9090/workflow/api/task/todo?assignee=lisi"

# 審批通過
curl -X POST http://flowable-engine:9090/workflow/api/task/complete \
  -H "Content-Type: application/json" \
  -d '{"taskId": "xxx", "comment": "同意", "variables": {"approved": true}}'
```

---

## 七、關鍵設計原則

1. **不耦合業務**：引擎只管流程流轉，不寫任何業務邏輯代碼
2. **通過變量傳遞數據**：業務系統將審批人、業務 ID 等通過流程變量傳入
3. **通過 businessKey 關聯**：每個流程實例綁定一個 `businessKey`（如訂單號），業務系統通過它關聯自己的業務數據
4. **前端直接部署**：Vue3 + bpmn-js 設計完成後，調用 `/api/process/deploy-xml` 直接發布為流程定義
5. **回調通知（可選）**：通過 Flowable `TaskListener` + Webhook 回調業務系統，無需業務系統輪詢

---

> 詳細實施步驟請查看 [flowble-backend-steps/control_step.md](flowble-backend-steps/control_step.md)
