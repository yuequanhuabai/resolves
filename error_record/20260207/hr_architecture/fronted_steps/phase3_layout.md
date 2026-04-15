## 階段三：佈局框架

### Step 7：主佈局 ✅（完成於 2026-04-15）

`src/layout/index.vue` — 整體結構：

```
┌─────────┬───────────────────┐
│         │ Navbar             │
│ Sidebar ├───────────────────┤
│         │ TagsView           │
│         ├───────────────────┤
│         │ AppMain (router-view + transition + keep-alive) │
└─────────┴───────────────────┘
```

#### 產物清單

| 檔案 | 職責 |
|---|---|
| `src/layout/index.vue` | 主佈局容器，`el-container` + 深色 aside + 白色 header + TagsView 條 + AppMain |
| `src/layout/components/AppMain.vue` | 內容區，`<router-view>` + `<transition>` + `<keep-alive>`（`include` 接 `tagsView.cachedViews`） |
| `src/router/staticRoutes.ts`（修改） | `/` 改為 Layout 組件，`/dashboard` 成為 children，渲染在 AppMain 的 `<router-view>` |

#### 關鍵決策

- **Sidebar / Navbar / TagsView 本步用佔位塊**（文字 + 淡色背景），Step 8/9/10 替換為真實組件；這樣驗收時就能確認「三欄結構 + router-view 聯動」工作正常，而不用等所有子組件都完成
- **aside 寬度響應 `app.sidebarCollapsed`**：摺疊 64px，展開 210px，用 `transition: width 0.2s` 平滑切換
- **AppMain 用 `<component :is="Component" :key="route.path" />` 寫法**：`:key` 讓路由切換強制重建組件（不加 key 的話同一組件複用導致某些頁面切換無反應）
- **`<keep-alive :include>`**：只緩存 `tagsView.cachedViews` 裡的頁面，其它切走就銷毀；對應後續 Step 10 TagsView 關閉頁籤時能真正釋放內存

#### 驗收

- 登入後看到三欄結構，深色側邊欄 + 白色頂欄 + 中間內容區
- 點「摺疊」按鈕 aside 寬度從 210px 收到 64px，logo 變「HR」
- 刷新頁面摺疊狀態保持（Step 4 app store 已持久化 localStorage）
- 退出按鈕能清 token 跳 /login

#### 踩坑記錄：登出返回「不支援 GET」

**現象：** 前端 POST `/api/logout`，後端報錯「不支援的 HTTP 方法：GET，支援的方法為：POST」。

**根因：** 後端 `SecurityConfig` 沒禁用 Spring Security 默認的 `LogoutFilter`，它攔截 POST `/logout` 後做 session 清理並 302 跳 `/login?logout`，瀏覽器自動發 GET `/login`，而 Controller 只有 `@PostMapping("/login")`，所以報錯。

**修復：** 後端 `SecurityConfig.filterChain` 加 `.logout(logout -> logout.disable())`。詳見 `backend_steps/phase3_framework.md` 末尾踩坑記錄。

**延伸：** 登出堅持用 POST 不是偶然 ——
1. GET 會被 `<img src="/logout">` 之類意外觸發
2. REST 語義 GET 應冪等，登出會刪 Redis key 屬狀態變更
3. 瀏覽器對 GET 鏈接有預取行為
4. 與 login 的 POST 對稱

---



### Step 8：側邊欄菜單 ✅（完成於 2026-04-15）

#### 產物清單

| 檔案 | 職責 |
|---|---|
| `src/layout/components/Sidebar/index.vue` | `<el-menu>` 容器，讀 `permission.menus`，綁當前路由高亮，支持摺疊 |
| `src/layout/components/Sidebar/SidebarItem.vue` | **遞歸組件**，按 children 渲染 `<el-sub-menu>` 或 `<el-menu-item>` |
| `src/layout/index.vue`（修改） | Sidebar 佔位塊替換為 `<Sidebar />` |

#### 關鍵決策

- **數據源**：`permissionStore.menus`（登入時 `getRouters()` 拉取，Step 4 已存好）
- **過濾規則**：`visible !== 0`（隱藏菜單）、`menuType === 'F'`（按鈕類型）直接跳過，不渲染
- **路徑拼接**：`SidebarItem.resolvePath()` 處理相對路徑 —— 子節點 `path` 不以 `/` 開頭時拼父路徑（`/system` + `user` → `/system/user`），與 RuoYi 慣例一致
- **`<el-menu router>`**：開啟後點擊自動 `router.push`，無需手動監聽
- **`unique-opened`**：同層子菜單一次只展開一個，避免左側菜單炸開
- **icon 動態渲染**：`<component :is="item.icon" />` 依賴 auto-import 把 EP 圖標註冊進全局；後端若返回非組件名字符串會 warning，但不影響菜單本身

#### 已知限制（Step 17 解決）

動態路由尚未生成，點擊菜單項跳轉後是 404。本步只驗收：
- 菜單渲染正確（遞歸層級 + 圖標 + 名稱）
- 當前路由高亮（`/dashboard` 時首頁項高亮）
- 摺疊展開聯動 app store

#### 驗收（完成於 2026-04-15）

- 登入後側邊欄渲染出系統管理下的完整菜單樹
- 漢堡按鈕切換摺疊/展開，圖標保留文字隱藏
- 路由高亮跟隨當前 path

---



### Step 9：頂部導航欄 ✅（完成於 2026-04-15）

#### 產物清單

| 檔案 | 職責 |
|---|---|
| `src/layout/components/Navbar.vue` | 頂欄：漢堡按鈕 + Breadcrumb + 用戶下拉（個人中心/退出） |
| `src/layout/components/Breadcrumb.vue` | 讀 `route.matched` 自動生成麵包屑，過濾 `meta.hidden`/無 title 節點 |
| `src/layout/index.vue`（修改） | 刪掉內嵌 header 代碼，替換為 `<Navbar />`；退出邏輯移到 Navbar |

#### 關鍵決策

- **Breadcrumb 用 `route.matched`**：它是所有層級匹配的路由數組，`/system/user` 會匹配 `[Layout, 系統管理, 用戶管理]`，天然對應麵包屑層級；不用自己維護狀態
- **退出二次確認**：`ElMessageBox.confirm` 包在 try/catch，用戶點取消時 ElMessageBox reject，靜默處理即可
- **漢堡圖標切換**：摺疊顯示 `<Expand>`，展開顯示 `<Fold>`，語義正確
- **職責拆分**：Layout 不再關心用戶信息、退出、麵包屑，只負責三欄結構 + 組件組裝；對後續維護更清晰

### Step 10：標籤頁導航 ✅（完成於 2026-04-15）

#### 產物清單

| 檔案 | 職責 |
|---|---|
| `src/layout/components/TagsView.vue` | 標籤頁完整實現（列表 + 切換 + 關閉 + 右鍵菜單 + 滾動） |
| `src/layout/index.vue`（修改） | 佔位條替換為 `<TagsView />` |
| `src/router/staticRoutes.ts`（修改） | Dashboard 加 `meta.affix: true`（固定頁籤） |

#### 關鍵決策

- **自動加頁籤**：`watch(() => route.path, { immediate: true })`，路由變化即 `tagsViewStore.addView(route)`，首屏也會加 dashboard 頁籤
- **關閉活躍頁籤自動跳轉**：關閉當前頁時找剩餘最後一個，都沒了兜底 `/dashboard`
- **右鍵菜單**：`position: fixed` + `event.clientX/clientY` 精準定位；`onMounted/onBeforeUnmount` 綁全局 click 關閉
- **固定頁籤**：`meta.affix: true` 的標籤不渲染關閉按鈕，但 `delAllViews` 目前未排除（關掉後跳 `/dashboard` 會自動 addView 回來，效果沒差）
- **激活項自動滾動可見**：路由切換時 `scrollIntoView({ inline: 'center' })`，避免被擠出視口

#### 驗收（完成於 2026-04-15）

- 登入進首頁 → TagsView 顯示「首頁」藍色圓點標籤
- 右鍵任意標籤 → 彈菜單（關閉 / 關閉其他 / 關閉所有）
- Dashboard 標籤無關閉按鈕（affix）
- 關閉當前活躍標籤 → 自動跳前一個

### Step 11：全局樣式 ✅（完成於 2026-04-15）

#### 產物清單

| 檔案 | 職責 |
|---|---|
| `src/styles/variables.scss` | 主題色 / 側邊欄色 / 佈局尺寸 / 過渡變量 |
| `src/styles/reset.scss` | html/body 全屏 + 字體棧 + box-sizing |
| `src/styles/index.scss` | 全局入口，`@use reset` + 全局滾動條 |
| `src/main.ts`（修改） | `import './style.css'` → `import './styles/index.scss'` |
| ~~`src/style.css`~~ | Vite 模板遺留樣式，刪除 |

#### 對原設計的偏離

原文件列了 5 個 SCSS（含 sidebar/element-plus/transition 獨立文件），實際做了 3 個。原因：
- **不做 `variables.module.scss` 的 `:export`**：當前 TS 代碼沒有引用 SCSS 變量的場景，`:export` 徒增複雜度
- **不拆 sidebar.scss / element-plus.scss / transition.scss**：這些樣式已在對應組件的 scoped CSS 裡正常工作，提出去只會割裂

**務實原則**：全局樣式只寫「確實需要全局生效」的東西（reset、滾動條、字體棧），組件自己的樣式留在組件裡。

#### 關鍵決策

- 用 `@use` 而非舊的 `@import`（Sass 新模塊系統）
- 只做 `::-webkit-scrollbar`，Firefox 的 `scrollbar-width/color` 語法差異大，暫不做跨瀏覽器統一
- 變量文件獨立但不在 index.scss 自動引入：SCSS 變量作用域特性決定了只有 `@use` 的組件能用，未來組件需要時 `@use '@/styles/variables' as *;`

#### 驗收（完成於 2026-04-15）

- `npm run dev` 正常啟動，佈局無變化
- 滾動條變細（6px 灰色圓角）
- 字體棧生效（Mac SF Pro、Win 微軟雅黑）

---

## 階段三總驗收

| Step | 標題 | 狀態 |
|---|---|---|
| 7 | 主佈局 | ✅ |
| 8 | 側邊欄菜單 | ✅ |
| 9 | 頂部導航欄 | ✅ |
| 10 | 標籤頁導航 | ✅ |
| 11 | 全局樣式 | ✅ |

**階段三完成後**：應用外殼全部就位 —— 三欄佈局 + 菜單遞歸 + 麵包屑 + 標籤頁 + 全局樣式。業務頁面只需放在 AppMain 下的路由中即可套用整套外殼。

完成後進入 → **階段四：公共組件（Step 12 分頁組件）**

---
