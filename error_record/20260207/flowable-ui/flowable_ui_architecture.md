# 前端架構文檔 — Vue 3 + bpmn-js 流程設計器

## 一、整體功能

```
flowable-designer-ui/
│
├── 流程設計器（核心）
│   ├── bpmn-js 拖拽畫布        ← 設計 BPMN 流程圖
│   ├── Flowable 屬性面板        ← 配置 assignee/candidateGroups/條件等
│   ├── 工具欄（保存/部署/導入/導出）
│   └── 部署發布 → 調用後端 /api/process/deploy-xml
│
├── 流程管理
│   ├── 已部署流程列表（查詢/刪除/查看 XML/預覽流程圖）
│   └── 版本管理
│
├── 流程實例管理
│   ├── 運行中實例列表
│   ├── 發起流程實例（傳入 businessKey + variables）
│   ├── 掛起 / 激活 / 終止
│   └── 流程圖實時狀態預覽
│
└── 任務管理（演示用）
    ├── 待辦任務列表
    ├── 審批（通過/駁回）
    ├── 轉辦
    └── 歷史流程查詢 + 流程圖高亮回放
```

---

## 二、技術選型

| 組件 | 版本 | 說明 |
|---|---|---|
| Vue | 3.4 | 前端框架 |
| Vite | 5.x | 構建工具 |
| TypeScript | 5.x | 類型支持 |
| Element Plus | 2.x | UI 組件庫 |
| Pinia | 2.x | 狀態管理 |
| Vue Router | 4.x | 路由 |
| Axios | 1.x | HTTP 請求 |
| bpmn-js | 17.x | BPMN 2.0 流程圖設計器 |
| bpmn-js-properties-panel | 3.x | bpmn-js 屬性面板框架 |
| @bpmn-io/properties-panel | 3.x | 屬性面板 UI 基礎庫 |

---

## 三、項目結構

```
flowable-designer-ui/
├── public/
│   └── favicon.ico
├── src/
│   ├── api/                             # 接口請求
│   │   ├── request.ts                   # Axios 實例 + 攔截器
│   │   ├── process.ts                   # 流程定義接口
│   │   ├── instance.ts                  # 流程實例接口
│   │   ├── task.ts                      # 任務接口
│   │   ├── history.ts                   # 歷史接口
│   │   └── types/                       # 接口類型定義
│   │       └── workflow.d.ts
│   │
│   ├── views/                           # 頁面
│   │   ├── designer/
│   │   │   └── index.vue                # 流程設計器主頁（bpmn-js 畫布）
│   │   ├── process/
│   │   │   └── index.vue                # 流程管理列表頁
│   │   ├── instance/
│   │   │   └── index.vue                # 流程實例管理頁
│   │   ├── task/
│   │   │   └── index.vue                # 任務管理頁
│   │   ├── history/
│   │   │   └── index.vue                # 歷史查詢頁
│   │   └── error/
│   │       └── 404.vue
│   │
│   ├── components/                      # 公共組件
│   │   ├── BpmnDesigner/
│   │   │   ├── index.vue                # bpmn-js 設計器主組件
│   │   │   ├── toolbar.vue              # 工具欄（保存/部署/縮放/對齊）
│   │   │   └── BpmnViewer.vue           # 只讀流程圖預覽組件（用於歷史高亮）
│   │   ├── PropertiesPanel/
│   │   │   ├── index.vue                # 屬性面板主組件
│   │   │   ├── panels/
│   │   │   │   ├── UserTaskPanel.vue    # 用戶任務屬性（assignee/候選人/候選組）
│   │   │   │   ├── SequenceFlowPanel.vue # 連線條件表達式
│   │   │   │   └── ProcessPanel.vue     # 流程屬性（名稱/Key）
│   │   │   └── FlowableModdle.json      # Flowable 屬性擴展定義
│   │   └── ProcessViewer/
│   │       └── index.vue                # 流程圖高亮查看組件
│   │
│   ├── layout/                          # 佈局
│   │   ├── index.vue                    # 主佈局
│   │   └── components/
│   │       ├── Sidebar.vue              # 左側菜單
│   │       └── Navbar.vue               # 頂部導航
│   │
│   ├── router/
│   │   └── index.ts                     # 路由配置
│   │
│   ├── store/
│   │   └── modules/
│   │       └── process.ts               # 流程相關狀態
│   │
│   ├── utils/
│   │   ├── bpmn.ts                      # BPMN XML 解析/生成工具
│   │   └── request.ts                   # Axios 封裝
│   │
│   ├── styles/
│   │   ├── index.scss                   # 全局樣式
│   │   └── bpmn.scss                    # bpmn-js 畫布樣式覆蓋
│   │
│   ├── App.vue
│   └── main.ts
│
├── index.html
├── vite.config.ts                       # Vite 配置（代理後端 API）
├── tsconfig.json
└── package.json
```

---

## 四、bpmn-js 核心說明

### 4.1 Flowable moddle 擴展

bpmn-js 默認不識別 `flowable:assignee` 等 Flowable 專屬屬性，需要自定義 `FlowableModdle.json` 擴展文件。

```json
// src/components/PropertiesPanel/FlowableModdle.json（簡化示例）
{
  "name": "Flowable",
  "uri": "http://flowable.org/bpmn",
  "prefix": "flowable",
  "xml": { "tagAlias": "lowerCase" },
  "associations": [],
  "types": [
    {
      "name": "UserTask",
      "extends": ["bpmn:UserTask"],
      "properties": [
        { "name": "assignee", "isAttr": true, "type": "String" },
        { "name": "candidateUsers", "isAttr": true, "type": "String" },
        { "name": "candidateGroups", "isAttr": true, "type": "String" }
      ]
    },
    {
      "name": "SequenceFlow",
      "extends": ["bpmn:SequenceFlow"],
      "properties": [
        { "name": "conditionExpression", "type": "bpmn:FormalExpression" }
      ]
    }
  ]
}
```

### 4.2 設計器初始化

```typescript
import BpmnModeler from 'bpmn-js/lib/Modeler'
import flowableModdle from './FlowableModdle.json'

const modeler = new BpmnModeler({
  container: '#bpmn-canvas',
  additionalModules: [ /* 自定義模塊 */ ],
  moddleExtensions: {
    flowable: flowableModdle
  }
})
```

### 4.3 部署到後端

設計完成後，通過 `modeler.saveXML()` 獲取 BPMN XML，調用後端 `/api/process/deploy-xml` 直接部署：

```typescript
const { xml } = await modeler.saveXML({ format: true })
await deployByXml({ name: processName, processKey, bpmnXml: xml })
```

---

## 五、頁面功能清單

| 頁面 | 路由 | 功能 |
|---|---|---|
| 流程設計器 | `/designer` | 拖拽設計 BPMN 流程圖，配置屬性，發布為流程定義 |
| 流程管理 | `/process` | 查詢已部署流程，刪除，查看 XML，預覽流程圖 |
| 流程實例 | `/instance` | 發起實例，查詢運行中實例，掛起/激活/終止 |
| 任務管理 | `/task` | 查詢待辦，審批通過/駁回，轉辦 |
| 歷史查詢 | `/history` | 已完成流程查詢，流程圖高亮回放 |

---

## 六、前後端對接 API 映射

| 前端操作 | 調用後端接口 |
|---|---|
| 設計器發布流程 | `POST /api/process/deploy-xml` |
| 上傳 BPMN 文件部署 | `POST /api/process/deploy` |
| 流程管理列表 | `GET /api/process/list` |
| 查看流程 XML | `GET /api/process/resource/{id}` |
| 刪除流程 | `DELETE /api/process/delete/{deploymentId}` |
| 發起流程實例 | `POST /api/instance/start` |
| 查詢運行中實例 | `GET /api/instance/list` |
| 掛起/激活實例 | `PUT /api/instance/suspend/{id}` 或 `activate` |
| 查詢待辦任務 | `GET /api/task/todo?assignee=xxx` |
| 審批通過 | `POST /api/task/complete` |
| 駁回任務 | `POST /api/task/reject` |
| 查看歷史流程圖 | `GET /api/history/diagram/{instanceId}` |

---

## 七、環境信息

| 項 | 值 |
|---|---|
| Node | v20+ |
| 工作目錄 | `D:\software\develop_tools\git\gitee\flowable-micro-server\` |
| 前端目錄 | `flowable-designer-ui/`（Step 1 創建） |
| 後端 API | `http://localhost:9090/workflow`（Vite dev proxy 轉發） |

---

> 詳細實施步驟請查看 [flowble-ui-steps/control_step.md](flowble-ui-steps/control_step.md)
