# 前端實施步驟 · 總控

本文件是前端實施的**索引入口**，僅列階段、Step 標題與進度。
每個階段的詳細內容在對應的 `phaseN_*.md` 文件中，修改時只讀取所需階段文件即可。

技術棧：**Vue 3.4 + TypeScript + Vite 5 + Element Plus 2 + Pinia 2 + Vue Router 4 + Axios + bpmn-js 17**

---

## 整體進度

```
階段一 (Step 1-2)    項目初始化 + 依賴安裝         ░░░░░░░░░░  ⏳ 待開始    Day 1
階段二 (Step 3-5)    基礎設施（Axios/Pinia/Router）  ░░░░░░░░░░  ⏳ 待開始    Day 1-2
階段三 (Step 6-8)    佈局框架                       ░░░░░░░░░░  ⏳ 待開始    Day 2-3
階段四 (Step 9-12)   bpmn-js 設計器核心             ░░░░░░░░░░  ⏳ 待開始    Day 3-5
階段五 (Step 13-15)  Flowable 屬性面板              ░░░░░░░░░░  ⏳ 待開始    Day 5-6
階段六 (Step 16-18)  流程管理頁                     ░░░░░░░░░░  ⏳ 待開始    Day 6-7
階段七 (Step 19-22)  實例&任務&歷史頁               ░░░░░░░░░░  ⏳ 待開始    Day 7-9
階段八 (Step 23-24)  構建 + 部署                    ░░░░░░░░░░  ⏳ 待開始    Day 9-10
```

圖例：✅ 已完成　🔄 進行中　⏳ 待開始　⏸️ 暫停

---

## 階段 ↔ 文件對照

| 階段 | 文件 | Step 範圍 |
|---|---|---|
| 階段一 項目初始化 | [phase1_init.md](./phase1_init.md) | Step 1 ~ 2 |
| 階段二 基礎設施 | [phase2_infra.md](./phase2_infra.md) | Step 3 ~ 5 |
| 階段三 佈局框架 | [phase3_layout.md](./phase3_layout.md) | Step 6 ~ 8 |
| 階段四 bpmn-js 設計器 | [phase4_bpmn_designer.md](./phase4_bpmn_designer.md) | Step 9 ~ 12 |
| 階段五 Flowable 屬性面板 | [phase5_properties_panel.md](./phase5_properties_panel.md) | Step 13 ~ 15 |
| 階段六 流程管理頁 | [phase6_process_mgmt.md](./phase6_process_mgmt.md) | Step 16 ~ 18 |
| 階段七 實例&任務&歷史 | [phase7_instance_task.md](./phase7_instance_task.md) | Step 19 ~ 22 |
| 階段八 構建部署 | [phase8_build.md](./phase8_build.md) | Step 23 ~ 24 |

---

## Step 清單與進度

### 階段一：項目初始化 → [phase1_init.md](./phase1_init.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 1 | 創建 Vue 3 + Vite + TS 項目，安裝核心依賴 | ⏳ |
| 2 | 配置 vite.config.ts（代理後端 API）+ tsconfig.json + ESLint | ⏳ |

### 階段二：基礎設施 → [phase2_infra.md](./phase2_infra.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 3 | Axios 封裝（request.ts + 攔截器 + 統一響應類型） | ⏳ |
| 4 | 後端 API 模塊（process.ts / instance.ts / task.ts / history.ts） | ⏳ |
| 5 | Pinia 狀態管理 + Vue Router 路由配置 | ⏳ |

### 階段三：佈局框架 → [phase3_layout.md](./phase3_layout.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 6 | 主佈局（layout/index.vue — 左側菜單 + 頂部導航 + 內容區） | ⏳ |
| 7 | 側邊欄菜單（Sidebar.vue）+ 路由跳轉 | ⏳ |
| 8 | 全局樣式（styles/index.scss + bpmn.scss） | ⏳ |

### 階段四：bpmn-js 設計器 → [phase4_bpmn_designer.md](./phase4_bpmn_designer.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 9 | 安裝 bpmn-js 依賴，創建 BpmnDesigner.vue 組件，初始化畫布 | ⏳ |
| 10 | 添加 Flowable moddle 擴展（FlowableModdle.json），支持 flowable:assignee 等屬性 | ⏳ |
| 11 | 設計器工具欄（新建/導入/導出/放大縮小/保存/部署） | ⏳ |
| 12 | 設計器頁面（views/designer/index.vue），對接後端部署接口 | ⏳ |

### 階段五：Flowable 屬性面板 → [phase5_properties_panel.md](./phase5_properties_panel.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 13 | 屬性面板框架（PropertiesPanel/index.vue），監聽畫布元素選中事件 | ⏳ |
| 14 | 用戶任務屬性（UserTaskPanel.vue）：assignee / candidateUsers / candidateGroups | ⏳ |
| 15 | 連線條件（SequenceFlowPanel.vue）+ 流程屬性（ProcessPanel.vue） | ⏳ |

### 階段六：流程管理頁 → [phase6_process_mgmt.md](./phase6_process_mgmt.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 16 | 流程管理列表頁（views/process/index.vue）：查詢/刪除/版本標記 | ⏳ |
| 17 | 查看 XML 對話框（Codemirror/CodeMirror 語法高亮顯示 BPMN XML） | ⏳ |
| 18 | 流程圖預覽（BpmnViewer.vue 只讀模式展示已部署的流程圖） | ⏳ |

### 階段七：實例&任務&歷史 → [phase7_instance_task.md](./phase7_instance_task.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 19 | 流程實例管理頁（views/instance/index.vue）：列表/發起/掛起/激活/終止 | ⏳ |
| 20 | 任務管理頁（views/task/index.vue）：待辦列表/審批/駁回/轉辦 | ⏳ |
| 21 | 歷史查詢頁（views/history/index.vue）：已完成流程 + 審批記錄時間線 | ⏳ |
| 22 | 流程圖高亮回放（調用後端 `/api/history/diagram`，圖片形式展示） | ⏳ |

### 階段八：構建部署 → [phase8_build.md](./phase8_build.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 23 | 環境變量配置（.env.development / .env.production） | ⏳ |
| 24 | 生產構建 + Nginx 部署配置 | ⏳ |

---

## 關鍵里程碑

| 里程碑 | 驗收標準 |
|---|---|
| F1: 項目能跑 | Vite 啟動，Element Plus 組件正常渲染，路由跳轉正常 |
| F2: 設計器可用 | bpmn-js 畫布可拖拽繪製流程圖，能保存/導出 BPMN XML |
| F3: 屬性面板通 | 點擊用戶任務節點，屬性面板顯示 assignee 輸入框，修改後 XML 正確包含屬性 |
| F4: 部署流程 | 設計器中點擊「部署」，後端成功創建流程定義，流程管理頁可查到 |
| F5: 全流程演示 | 設計 → 部署 → 發起實例 → 查待辦 → 審批 → 查歷史，全流程跑通 |
| F6: 可部署 | 生產構建成功，Nginx 正常訪問 |

---

## 前後端對接時序

```
後端 M2 (流程定義通) ✅ → 前端可開始 階段四/六 (設計器 + 流程管理對接)
後端 M3 (流程跑起來) ✅ → 前端可開始 階段七 (實例 + 任務管理)
後端 M4 (歷史可查)  ✅ → 前端可開始 Step 22 (歷史高亮回放)
```

---

## 環境信息

| 項 | 值 |
|---|---|
| Node | v20+ |
| npm / pnpm | pnpm 推薦 |
| 工作目錄 | `D:\software\develop_tools\git\gitee\flowable-micro-server\` |
| 前端目錄 | `flowable-designer-ui/`（Step 1 創建） |
| 後端 API | `http://localhost:9090/workflow`（Vite dev proxy 轉發） |

---

## 使用約定

- **未來對話開頭**：僅載入本文件 `control_step.md` 了解全局
- **修改某階段**：只讀取對應的 `phaseN_*.md`，不載入其他階段文件
