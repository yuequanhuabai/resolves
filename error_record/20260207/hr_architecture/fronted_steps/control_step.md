# 前端實施步驟 · 總控

本文件是前端實施的**索引入口**，僅列階段、Step 標題與進度。
每個階段的詳細內容在對應的 `phaseN_*.md` 檔案中，修改時只讀取所需階段檔即可。

技術棧：**Vue 3.4 + TypeScript + Vite 5 + Element Plus 2 + Pinia 2 + Vue Router 4 + Axios**

---

## 整體進度

```
階段一 (Step 1-2)    項目初始化           ██████████  ✅ 已完成    Day 1
階段二 (Step 3-6)    基礎設施             ██████████  ✅ 已完成    Day 1-2
階段三 (Step 7-11)   佈局框架             ██████████  ✅ 已完成    Day 2-4
階段四 (Step 12-14)  公共組件             ░░░░░░░░░░  ⏳ 待開始    Day 4-5
階段五 (Step 15-18)  登入功能             ░░░░░░░░░░  ⏳ 待開始    Day 5-6
階段六 (Step 19-23)  業務頁面 (核心 CRUD)  ░░░░░░░░░░  ⏳ 待開始    Day 6-10
階段七 (Step 24-26)  輔助頁面             ░░░░░░░░░░  ⏳ 待開始    Day 10-11
階段八 (Step 27-28)  優化 + 構建          ░░░░░░░░░░  ⏳ 待開始    Day 11-12
```

圖例：✅ 已完成　🔄 進行中　⏳ 待開始　⏸️ 暫停

---

## 階段 ↔ 檔案對照

| 階段 | 檔案 | Step 範圍 |
|---|---|---|
| 階段一 項目初始化 | [phase1_init.md](./phase1_init.md) | Step 1 ~ 2 |
| 階段二 基礎設施 | [phase2_infra.md](./phase2_infra.md) | Step 3 ~ 6 |
| 階段三 佈局框架 | [phase3_layout.md](./phase3_layout.md) | Step 7 ~ 11 |
| 階段四 公共組件 | [phase4_components.md](./phase4_components.md) | Step 12 ~ 14 |
| 階段五 登入功能 | [phase5_login.md](./phase5_login.md) | Step 15 ~ 18 |
| 階段六 業務頁面 | [phase6_business.md](./phase6_business.md) | Step 19 ~ 23 |
| 階段七 輔助頁面 | [phase7_aux.md](./phase7_aux.md) | Step 24 ~ 26 |
| 階段八 優化構建 | [phase8_build.md](./phase8_build.md) | Step 27 ~ 28 |

---

## Step 清單與進度

### 階段一：項目初始化 → [phase1_init.md](./phase1_init.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 1 | 創建 Vue 3 + Vite + TS 項目，安裝核心依賴，配置 vite/tsconfig | ✅ |
| 2 | 配置 ESLint + Prettier | ✅ |

### 階段二：基礎設施 → [phase2_infra.md](./phase2_infra.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 3 | Axios 封裝 (request.ts + 攔截器 + 統一響應類型) | ✅ |
| 4 | Pinia 狀態管理 (user / app / permission / tagsView) | ✅ |
| 5 | 路由配置 (staticRoutes / 路由實例 / 守衛) | ✅ |
| 6 | Token 工具 (utils/auth.ts) | ✅ |

### 階段三：佈局框架 → [phase3_layout.md](./phase3_layout.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 7 | 主佈局 (layout/index.vue) | ✅ |
| 8 | 側邊欄菜單 (Sidebar + 遞歸 SidebarItem) | ✅ |
| 9 | 頂部導航欄 (Navbar + Breadcrumb) | ✅ |
| 10 | 標籤頁導航 (TagsView) | ✅ |
| 11 | 全局樣式 (styles/) | ✅ |

### 階段四：公共組件 → [phase4_components.md](./phase4_components.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 12 | 分頁組件 (Pagination) | ✅ |
| 13 | 權限指令 (v-hasPerms) | ⏳ |
| 14 | 公共業務組件 (DeptTree / TreeSelect / IconSelect / RightToolbar) | ⏳ |

### 階段五：登入功能 → [phase5_login.md](./phase5_login.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 15 | 登入頁 (views/login) | ⏳ |
| 16 | API 對接 (api/auth.ts) | ⏳ |
| 17 | 動態路由生成 (permission store generateRoutes) | ⏳ |
| 18 | 端到端驗證 (登入 → 跳轉 → 菜單) | ⏳ |

### 階段六：業務頁面 → [phase6_business.md](./phase6_business.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 19 | 用戶管理頁 (含部門樹篩選) | ⏳ |
| 20 | 角色管理頁 (含菜單權限分配) | ⏳ |
| 21 | 部門管理頁 (樹形表格) | ⏳ |
| 22 | 崗位管理頁 | ⏳ |
| 23 | 菜單管理頁 (樹形 + 三類動態欄位) | ⏳ |

### 階段七：輔助頁面 → [phase7_aux.md](./phase7_aux.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 24 | Dashboard 首頁 | ⏳ |
| 25 | 錯誤頁面 (401 / 404) | ⏳ |
| 26 | 個人中心 | ⏳ |

### 階段八：優化 + 構建 → [phase8_build.md](./phase8_build.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 27 | 體驗優化 (loading / 防重複 / 二次確認) | ⏳ |
| 28 | 生產構建 + Nginx 部署 | ⏳ |

---

## 關鍵里程碑

| 里程碑 | 驗收標準 |
|---|---|
| F1: 項目能跑 | Vite 啟動，Element Plus 組件正常渲染 |
| F2: 佈局完成 | 側邊欄 + 頂欄 + 標籤頁 + 內容區 佈局正常 |
| F3: 能登入 | 登入 → Token 存儲 → 動態路由加載 → 菜單顯示 |
| F4: CRUD 通 | 用戶/角色/部門/崗位/菜單 頁面可正常增刪改查 |
| F5: 權限生效 | 菜單按角色動態展示，按鈕按權限顯示/隱藏 |
| F6: 可部署 | 生產構建成功，Nginx 部署正常訪問 |

---

## 前後端對接時序

```
後端 M2 (能登入) ✅ → 前端可開始 階段五 (登入對接)
後端 M3 (CRUD 通) ✅ → 前端可開始 階段六 (業務頁面)
```

當前後端已完成至 Step 21（M3 達成），Step 22 接口測試暫緩（後續用 Java + JUnit + 壓測）。
前端可全速開發，無阻塞。

---

## 環境信息

| 項 | 值 |
|---|---|
| Node | v24.14.1 |
| npm | 11.11.0 |
| 工作目錄 | `D:\software\develop_tools\git\gitee\human_resource\` |
| 前端目錄 | `hr-ui/`（Step 1 創建） |
| 後端 API | `http://localhost:8080/api`（Vite dev proxy 轉發） |

---

## 使用約定

- **未來對話開頭**：僅載入本文件 `control_step.md` 了解全局
- **修改某階段**：只讀取對應的 `phaseN_*.md`，不載入其他階段檔
- **原始備份**：根目錄 `frontend_steps.md` / `frontend_architecture.md` 保留不動
