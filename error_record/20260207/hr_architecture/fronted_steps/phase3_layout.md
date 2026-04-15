## 階段三：佈局框架

### Step 7：主佈局 ⏳

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

使用 Element Plus 的 `<el-container>` / `<el-aside>` / `<el-header>` / `<el-main>`。

### Step 8：側邊欄菜單 ⏳

1. `layout/components/Sidebar/index.vue`：
   - `<el-menu>` 渲染從 `permission` store 來的 `routes`
   - 支持摺疊（`collapse` prop 與 `app.sidebar.collapsed` 同步）
2. `layout/components/Sidebar/SidebarItem.vue`（**遞歸組件**）：
   - 根據 `menu_type`：目錄/有子節點 → `<el-sub-menu>`，葉子 → `<el-menu-item>`
   - 渲染 icon + 名稱

### Step 9：頂部導航欄 ⏳

1. `layout/components/Navbar.vue`：
   - 左：漢堡按鈕（觸發 `app.toggleSidebar`）+ 麵包屑
   - 右：用戶頭像 + 下拉菜單（個人中心 / 退出登入）
2. `layout/components/Breadcrumb.vue`：
   - 監聽 `route.matched`，自動生成 `<el-breadcrumb>`

### Step 10：標籤頁導航 ⏳

`layout/components/TagsView.vue`：
- 列出 `tagsView.visitedViews`
- 支持關閉、關閉其它、關閉所有（右鍵菜單）
- 與 `keep-alive` 的 `cachedViews` 聯動

### Step 11：全局樣式 ⏳

| 文件 | 用途 |
|---|---|
| `styles/index.scss` | 全局入口（被 `main.ts` import） |
| `styles/variables.module.scss` | SCSS 變量 + `:export` 給 TS 用 |
| `styles/sidebar.scss` | 側邊欄樣式 |
| `styles/element-plus.scss` | EP 主題色覆蓋 |
| `styles/transition.scss` | 頁面過渡動畫 |

#### 階段三驗收

打開 `/`，看到完整三欄佈局；側邊欄能摺疊；麵包屑跟隨路由變化；標籤頁能新增/關閉。
（此時菜單可先用靜態 mock 數據填充，動態路由放階段五）

---
