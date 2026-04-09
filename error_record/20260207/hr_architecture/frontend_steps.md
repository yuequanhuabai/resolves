# 前端實施步驟

## 階段一：項目初始化

### Step 1：創建 Vue 3 項目

1. 使用 Vite 創建項目：
   ```bash
   npm create vite@latest hr-ui -- --template vue-ts
   ```
2. 安裝核心依賴：
   ```bash
   npm install vue-router@4 pinia axios element-plus @element-plus/icons-vue
   npm install -D sass unplugin-auto-import unplugin-vue-components
   ```
3. 配置 `vite.config.ts`：
   - 路徑別名 `@` → `src/`
   - Element Plus 自動導入
   - 開發代理 `/api` → `http://localhost:8080`
4. 配置 `tsconfig.json` 路徑別名
5. 創建環境變量文件 `.env.development` / `.env.production`

### Step 2：配置 ESLint + Prettier

1. 安裝 ESLint + Vue 插件 + Prettier
2. 統一代碼風格：
   - 單引號
   - 無分號
   - 2 空格縮進

---

## 階段二：基礎設施

### Step 3：Axios 封裝

1. 創建 `src/api/request.ts`：
   - 創建 Axios 實例，baseURL 取自環境變量
   - 請求攔截器：注入 `Authorization: Bearer {token}`
   - 響應攔截器：
     - code === 200 → 返回 data
     - code === 401 → 清 Token，跳轉 `/login`
     - 其它 → ElMessage.error(msg)
2. 統一請求/響應類型定義：
   ```typescript
   // api/types/common.d.ts
   interface ApiResponse<T> {
     code: number
     msg: string
     data: T
   }
   interface PageResult<T> {
     rows: T[]
     total: number
   }
   ```

### Step 4：Pinia 狀態管理

1. 創建 `src/store/index.ts` — Pinia 實例
2. 創建 `src/store/modules/user.ts`：
   ```
   state: { token, userInfo, roles, permissions }
   actions: login(), logout(), getInfo()
   ```
3. 創建 `src/store/modules/app.ts`：
   ```
   state: { sidebar: { collapsed }, device }
   actions: toggleSidebar()
   ```
4. 創建 `src/store/modules/permission.ts`：
   ```
   state: { routes, addRoutes }
   actions: generateRoutes(menus)
   ```
5. 創建 `src/store/modules/tagsView.ts`：
   ```
   state: { visitedViews, cachedViews }
   actions: addView(), delView()
   ```

### Step 5：路由配置

1. 創建 `src/router/staticRoutes.ts` — 靜態路由：
   ```
   /login       → 登入頁
   /404         → 404 頁
   /401         → 401 頁
   /redirect    → 重定向輔助路由
   ```
2. 創建 `src/router/index.ts` — 路由實例
3. 創建 `src/router/permission.ts` — 路由守衛：
   ```
   流程:
   ├── 有 Token？
   │   ├── 訪問 /login → 重定向到 /
   │   └── 訪問其它頁面
   │       ├── 已有用戶信息 → 放行
   │       └── 未有用戶信息
   │           ├── 調用 getInfo() 獲取用戶信息 + 權限
   │           ├── 調用 getRouters() 獲取後端菜單
   │           ├── generateRoutes() 生成動態路由
   │           ├── router.addRoute() 動態注入
   │           └── next({ ...to, replace: true })
   └── 無 Token？
       ├── 白名單路徑 → 放行
       └── 其它 → 重定向 /login
   ```

### Step 6：Token 工具

1. 創建 `src/utils/auth.ts`：
   - `getToken()` — 從 localStorage 讀取
   - `setToken(token)` — 存入 localStorage
   - `removeToken()` — 清除

---

## 階段三：佈局框架

### Step 7：主佈局

1. 創建 `src/layout/index.vue` — 整體佈局結構：
   ```
   ┌─────────┬───────────────────┐
   │ Sidebar  │ Navbar            │
   │          ├───────────────────┤
   │          │ TagsView          │
   │          ├───────────────────┤
   │          │ AppMain           │
   └─────────┴───────────────────┘
   ```
2. 使用 Element Plus 的 `el-container` / `el-aside` / `el-header` / `el-main`

### Step 8：側邊欄菜單

1. 創建 `src/layout/components/Sidebar/index.vue`：
   - 使用 `el-menu` 渲染菜單
   - 支持摺疊/展開
2. 創建 `src/layout/components/Sidebar/SidebarItem.vue`：
   - 遞歸組件，渲染多級菜單
   - 根據 menu_type 渲染 el-sub-menu 或 el-menu-item
   - 渲染圖標 + 菜單名稱

### Step 9：頂部導航欄

1. 創建 `src/layout/components/Navbar.vue`：
   - 左側：漢堡按鈕 (摺疊側邊欄) + 麵包屑
   - 右側：用戶頭像 + 下拉菜單 (個人中心 / 退出登入)
2. 創建 `src/layout/components/Breadcrumb.vue`：
   - 根據當前路由的 matched 自動生成麵包屑

### Step 10：標籤頁導航

1. 創建 `src/layout/components/TagsView.vue`：
   - 已訪問頁面的標籤列表
   - 支持關閉、關閉其它、關閉所有
   - 右鍵菜單
   - 與 tagsView store 聯動

### Step 11：全局樣式

1. 創建 `src/styles/index.scss` — 全局入口
2. 創建 `src/styles/variables.module.scss` — SCSS 變量
3. 創建 `src/styles/sidebar.scss` — 側邊欄樣式
4. 創建 `src/styles/element-plus.scss` — Element Plus 樣式覆蓋
5. 創建 `src/styles/transition.scss` — 頁面過渡動畫

---

## 階段四：公共組件

### Step 12：分頁組件

1. 創建 `src/components/Pagination/index.vue`：
   - 封裝 `el-pagination`
   - Props: total, page, limit
   - 事件: @pagination (pageNum/pageSize 變化時觸發)

### Step 13：權限指令

1. 創建 `src/directive/permission/hasPerms.ts`：
   ```
   v-hasPerms="['sys:user:add']"
   邏輯: 從 user store 取 permissions，判斷是否包含
   不包含 → el.parentNode.removeChild(el)
   ```
2. 在 main.ts 中全局註冊

### Step 14：公共業務組件

1. `src/components/DeptTree/index.vue` — 部門樹選擇
   - 搜索過濾
   - 點擊節點事件
   - 用於用戶管理頁左側
2. `src/components/TreeSelect/index.vue` — 樹形下拉
   - 基於 el-tree-select
   - 用於選擇上級部門/上級菜單
3. `src/components/IconSelect/index.vue` — 圖標選擇器
   - 展示 Element Plus 圖標列表
   - 用於菜單管理
4. `src/components/RightToolbar/index.vue` — 表格工具欄
   - 刷新按鈕
   - 列顯示/隱藏設定

---

## 階段五：登入功能

### Step 15：登入頁

1. 創建 `src/views/login/index.vue`：
   - 表單: 用戶名 + 密碼 + 記住我
   - 校驗: 用戶名/密碼不能為空
   - 提交:
     ```
     調用 userStore.login({ username, password })
     → 成功 → router.push(redirect || '/')
     → 失敗 → ElMessage.error
     ```
   - 樣式: 居中卡片式佈局

### Step 16：API 對接

1. 創建 `src/api/auth.ts`：
   ```typescript
   login(data: LoginData): Promise<{ token: string }>
   logout(): Promise<void>
   getInfo(): Promise<UserInfo>
   getRouters(): Promise<MenuItem[]>
   ```
2. user store 的 login/getInfo/logout action 調用這些 API

### Step 17：動態路由生成

1. 在 `src/store/modules/permission.ts` 中實現 `generateRoutes()`：
   - 接收後端菜單數據
   - 遞歸轉換為 Vue Router 路由配置
   - 處理 component 字段：`() => import(`@/views/${component}.vue`)`
   - 追加 404 兜底路由
2. 在路由守衛中調用

### Step 18：端到端驗證

1. 啟動後端 + 前端
2. 驗證: 登入 → 跳轉首頁 → 側邊欄顯示菜單 → 點擊菜單跳轉頁面
3. 驗證: 退出登入 → 清 Token → 跳轉登入頁
4. 驗證: 直接訪問受保護頁面 → 跳轉登入頁

---

## 階段六：業務頁面

### Step 19：用戶管理頁

1. 創建 `src/views/system/user/index.vue`
2. 創建 `src/api/system/user.ts` — CRUD 接口
3. 頁面結構：
   - 左側: DeptTree 組件（點擊部門篩選右側表格）
   - 右側上方: 搜索表單 (用戶名/手機/狀態)
   - 右側中間: 操作按鈕 (新增/匯出，權限控制)
   - 右側下方: 用戶表格 + 分頁
4. 新增/修改彈窗 (`el-dialog`)：
   - 表單: 用戶名、暱稱、密碼、部門(TreeSelect)、崗位(下拉)、角色(多選)、手機、郵箱、性別、狀態
   - 校驗規則
5. 重置密碼彈窗
6. 狀態開關 (`el-switch`)

### Step 20：角色管理頁

1. 創建 `src/views/system/role/index.vue`
2. 創建 `src/api/system/role.ts`
3. 頁面結構：
   - 搜索: 角色名/角色標識/狀態
   - 表格: 角色名、標識、排序、狀態、創建時間、操作
   - 操作: 編輯、刪除、權限分配
4. 新增/修改彈窗
5. 權限分配彈窗：
   - 菜單權限: `el-tree` 帶勾選框，加載完整菜單樹
   - 數據權限: 下拉選擇範圍
   - 自定義數據權限: 部門樹勾選

### Step 21：部門管理頁

1. 創建 `src/views/system/dept/index.vue`
2. 創建 `src/api/system/dept.ts`
3. 頁面結構：
   - 搜索: 部門名/狀態
   - 樹形表格 (`el-table` + `row-key` + `tree-props`)
   - 操作: 新增子部門、編輯、刪除
4. 新增/修改彈窗：
   - 上級部門: TreeSelect
   - 部門名、負責人、手機、郵箱、排序、狀態
5. 展開/摺疊全部按鈕

### Step 22：崗位管理頁

1. 創建 `src/views/system/post/index.vue`
2. 創建 `src/api/system/post.ts`
3. 標準 CRUD 頁面：
   - 搜索: 崗位編碼/崗位名稱/狀態
   - 表格 + 分頁
   - 新增/修改彈窗

### Step 23：菜單管理頁

1. 創建 `src/views/system/menu/index.vue`
2. 創建 `src/api/system/menu.ts`
3. 頁面結構：
   - 搜索: 菜單名/狀態
   - 樹形表格
   - 操作: 新增子菜單、編輯、刪除
4. 新增/修改彈窗：
   - 菜單類型: 目錄(M) / 菜單(C) / 按鈕(F)
   - 根據類型動態顯示欄位：
     - 目錄: 菜單名、圖標、排序
     - 菜單: + 路由地址、組件路徑
     - 按鈕: + 權限標識
   - 上級菜單: TreeSelect
   - 圖標: IconSelect

---

## 階段七：輔助頁面

### Step 24：Dashboard 首頁

1. 創建 `src/views/dashboard/index.vue`
2. 展示基本統計信息：
   - 用戶總數、部門數、角色數、崗位數
   - 歡迎語 + 快捷入口

### Step 25：錯誤頁面

1. 創建 `src/views/error/401.vue` — 未授權
2. 創建 `src/views/error/404.vue` — 頁面不存在
3. 路由中配置 404 兜底

### Step 26：個人中心

1. 創建 `src/views/profile/index.vue`：
   - 基本信息展示/修改
   - 修改密碼
   - 頭像上傳

---

## 階段八：優化 + 構建

### Step 27：體驗優化

1. 頁面加載 loading 動畫
2. 表格 loading 狀態
3. 按鈕 loading 防重複提交
4. 表格空狀態提示
5. 刪除操作二次確認 (`ElMessageBox.confirm`)

### Step 28：生產構建

1. 配置 `vite.config.ts` 生產優化：
   - 代碼分割 (vendor chunk)
   - gzip 壓縮
   - 去除 console.log
2. 運行 `npm run build` 驗證
3. Nginx 配置：
   ```nginx
   location / {
       root /usr/share/nginx/html;
       try_files $uri $uri/ /index.html;
   }
   location /api/ {
       proxy_pass http://localhost:8080/api/;
   }
   ```

---

## 實施順序總結

```
階段一 (Step 1-2)    項目初始化           ██░░░░░░░░  預計 Day 1
階段二 (Step 3-6)    基礎設施             ████░░░░░░  預計 Day 1-2
階段三 (Step 7-11)   佈局框架             ██████░░░░  預計 Day 2-4
階段四 (Step 12-14)  公共組件             ███████░░░  預計 Day 4-5
階段五 (Step 15-18)  登入功能             ████████░░  預計 Day 5-6
階段六 (Step 19-23)  業務頁面 (核心)       █████████░  預計 Day 6-10
階段七 (Step 24-26)  輔助頁面             █████████▌  預計 Day 10-11
階段八 (Step 27-28)  優化 + 構建          ██████████  預計 Day 11-12
```

### 關鍵里程碑

| 里程碑 | 驗收標準 |
|--------|---------|
| F1: 項目能跑 | Vite 啟動，Element Plus 組件正常渲染 |
| F2: 佈局完成 | 側邊欄 + 頂欄 + 標籤頁 + 內容區 佈局正常 |
| F3: 能登入 | 登入 → Token 存儲 → 動態路由加載 → 菜單顯示 |
| F4: CRUD 通 | 用戶/角色/部門/崗位/菜單 頁面可正常增刪改查 |
| F5: 權限生效 | 菜單按角色動態展示，按鈕按權限顯示/隱藏 |
| F6: 可部署 | 生產構建成功，Nginx 部署正常訪問 |

### 前後端對接時序

```
後端 M2 (能登入) 完成後 → 前端開始 階段五 (登入對接)
後端 M3 (CRUD 通) 完成後 → 前端開始 階段六 (業務頁面)
兩端可並行開發，前端用 Mock 數據先行
```
