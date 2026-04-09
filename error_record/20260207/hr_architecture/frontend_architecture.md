# 前端架構文檔 — Vue 3 + Element Plus

## 一、項目結構

```
hr-ui/
├── public/
│   └── favicon.ico
├── src/
│   ├── api/                             # 接口請求
│   │   ├── request.ts                   # Axios 實例 + 攔截器
│   │   ├── auth.ts                      # 登入/登出/用戶信息
│   │   ├── system/
│   │   │   ├── user.ts                  # 用戶管理接口
│   │   │   ├── role.ts                  # 角色管理接口
│   │   │   ├── dept.ts                  # 部門管理接口
│   │   │   ├── post.ts                  # 崗位管理接口
│   │   │   └── menu.ts                  # 菜單管理接口
│   │   └── types/                       # 接口類型定義
│   │       ├── auth.d.ts
│   │       └── system.d.ts
│   │
│   ├── views/                           # 頁面
│   │   ├── login/
│   │   │   └── index.vue                # 登入頁
│   │   ├── dashboard/
│   │   │   └── index.vue                # 首頁儀表盤
│   │   ├── system/
│   │   │   ├── user/
│   │   │   │   └── index.vue            # 用戶管理 (左部門樹 + 右用戶表格)
│   │   │   ├── role/
│   │   │   │   └── index.vue            # 角色管理
│   │   │   ├── dept/
│   │   │   │   └── index.vue            # 部門管理 (樹形表格)
│   │   │   ├── post/
│   │   │   │   └── index.vue            # 崗位管理
│   │   │   └── menu/
│   │   │       └── index.vue            # 菜單管理 (樹形表格)
│   │   └── error/
│   │       ├── 401.vue
│   │       └── 404.vue
│   │
│   ├── components/                      # 公共組件
│   │   ├── Pagination/                  # 分頁組件
│   │   │   └── index.vue
│   │   ├── DeptTree/                    # 部門樹選擇組件
│   │   │   └── index.vue
│   │   ├── RoleSelect/                  # 角色選擇組件
│   │   │   └── index.vue
│   │   ├── IconSelect/                  # 圖標選擇器
│   │   │   └── index.vue
│   │   ├── RightToolbar/                # 表格右側工具欄 (刷新/列設定)
│   │   │   └── index.vue
│   │   └── TreeSelect/                  # 樹形下拉選擇
│   │       └── index.vue
│   │
│   ├── layout/                          # 佈局框架
│   │   ├── index.vue                    # 主佈局
│   │   ├── components/
│   │   │   ├── Sidebar/                 # 左側菜單
│   │   │   │   ├── index.vue
│   │   │   │   └── SidebarItem.vue      # 遞歸菜單項
│   │   │   ├── Navbar.vue               # 頂部導航欄
│   │   │   ├── AppMain.vue              # 主內容區
│   │   │   ├── Breadcrumb.vue           # 麵包屑
│   │   │   ├── TagsView.vue             # 標籤頁導航
│   │   │   └── Settings.vue             # 佈局設定抽屜
│   │   └── hooks/
│   │       └── useResize.ts             # 響應式側邊欄
│   │
│   ├── router/                          # 路由
│   │   ├── index.ts                     # 路由實例
│   │   ├── staticRoutes.ts              # 靜態路由 (登入、404 等)
│   │   └── permission.ts                # 路由守衛 (動態路由加載)
│   │
│   ├── store/                           # Pinia 狀態管理
│   │   ├── index.ts
│   │   ├── modules/
│   │   │   ├── user.ts                  # 用戶狀態 (Token, 用戶信息, 權限)
│   │   │   ├── permission.ts            # 路由權限 (動態路由生成)
│   │   │   ├── app.ts                   # 應用設定 (側邊欄摺疊等)
│   │   │   └── tagsView.ts              # 標籤頁狀態
│   │   └── types.ts
│   │
│   ├── directive/                       # 自定義指令
│   │   └── permission/
│   │       └── hasPerms.ts              # v-hasPerms 按鈕級權限
│   │
│   ├── utils/                           # 工具函數
│   │   ├── auth.ts                      # Token 存取 (localStorage)
│   │   ├── validate.ts                  # 校驗規則
│   │   └── tree.ts                      # 樹形數據處理
│   │
│   ├── styles/                          # 全局樣式
│   │   ├── index.scss                   # 入口
│   │   ├── variables.module.scss        # SCSS 變量 (供 JS 使用)
│   │   ├── sidebar.scss                 # 側邊欄樣式
│   │   ├── element-plus.scss            # Element Plus 覆蓋
│   │   └── transition.scss              # 過渡動畫
│   │
│   ├── App.vue
│   ├── main.ts
│   └── env.d.ts                         # 環境變量類型
│
├── .env.development                     # 開發環境變量
├── .env.production                      # 生產環境變量
├── index.html
├── package.json
├── tsconfig.json
├── vite.config.ts
└── eslint.config.js
```

---

## 二、技術棧明細

| 用途 | 技術 | 版本 |
|------|------|------|
| 框架 | Vue 3 (Composition API + setup 語法糖) | 3.4+ |
| 語言 | TypeScript | 5.x |
| UI 組件 | Element Plus | 2.x |
| 構建工具 | Vite | 5.x |
| 路由 | Vue Router | 4.x |
| 狀態管理 | Pinia | 2.x |
| HTTP 請求 | Axios | 1.x |
| CSS 預處理 | SCSS | - |
| 代碼規範 | ESLint + Prettier | - |
| 圖標 | @element-plus/icons-vue | - |

---

## 三、核心機制

### 3.1 Axios 請求封裝

```
請求攔截器:
  1. 從 localStorage 取 Token
  2. 設入 Header: Authorization: Bearer {token}

響應攔截器:
  code === 200  → 返回 data
  code === 401  → 清除 Token，跳轉登入頁
  code === 403  → 提示 "無權限"
  其它           → ElMessage.error(msg)
```

### 3.2 動態路由

```
流程:
  1. 用戶登入成功 → 存 Token
  2. 路由守衛觸發 → 調用 /api/auth/routers 獲取菜單數據
  3. 後端返回菜單樹 (含 component 路徑)
  4. 前端遞歸將菜單樹轉為 Vue Router 路由配置
  5. router.addRoute() 動態注入
  6. 跳轉目標頁面

路由配置映射:
  後端 component: "system/user/index"
  → 前端 import(`@/views/${component}.vue`)
```

### 3.3 權限控制

```
路由級:
  - 動態路由本身只包含用戶有權訪問的菜單
  - 無權頁面路由不存在 → 自動 404

按鈕級:
  - 自定義指令 v-hasPerms="['sys:user:add']"
  - 指令內部: 從 store 取用戶權限集合，判斷是否包含
  - 不包含 → 移除 DOM 節點
```

### 3.4 狀態管理 (Pinia)

```
user store:
  state:  { token, userInfo, roles, permissions }
  actions: { login(), logout(), getInfo() }

permission store:
  state:  { routes, addRoutes }
  actions: { generateRoutes(menus) }

app store:
  state:  { sidebar: { collapsed }, device }
  actions: { toggleSidebar() }

tagsView store:
  state:  { visitedViews, cachedViews }
  actions: { addView(), delView(), delOtherViews() }
```

---

## 四、頁面設計

### 4.1 登入頁

```
┌──────────────────────────────────────┐
│              系統名稱                  │
│                                        │
│     ┌──────────────────────┐          │
│     │  帳號                  │          │
│     ├──────────────────────┤          │
│     │  密碼                  │          │
│     ├──────────────────────┤          │
│     │  [記住我]    [登 入]   │          │
│     └──────────────────────┘          │
└──────────────────────────────────────┘
```

### 4.2 主佈局

```
┌─────┬──────────────────────────────────┐
│     │ Navbar [麵包屑]     [用戶頭像 ▼] │
│  S  ├──────────────────────────────────┤
│  i  │ [標籤1] [標籤2] [標籤3]          │
│  d  ├──────────────────────────────────┤
│  e  │                                    │
│  b  │         AppMain 內容區             │
│  a  │                                    │
│  r  │                                    │
│     │                                    │
└─────┴──────────────────────────────────┘
```

### 4.3 用戶管理頁

```
┌────────┬───────────────────────────────────────┐
│        │  [搜索條件: 用戶名/手機/狀態] [搜索][重置] │
│  部門  │──────────────────────────────────────── │
│  樹形  │  [新增] [匯出]                    [列設定]│
│  篩選  │──────────────────────────────────────── │
│        │  用戶名 | 暱稱 | 部門 | 手機 | 狀態 | 操作 │
│  ├ 總公司│  admin  | 管理員| 研發  | 138..| 正常 | 改 刪│
│  │ ├ 研發│  zhang  | 張三  | 研發  | 139..| 正常 | 改 刪│
│  │ ├ 人事│  ...    | ...  | ...  | ...  | ...  | ... │
│  │ └ 財務│──────────────────────────────────────── │
│        │           [分頁: < 1 2 3 ... >]           │
└────────┴───────────────────────────────────────┘
```

### 4.4 角色管理頁

```
┌─────────────────────────────────────────────────┐
│  [搜索條件: 角色名/角色標識/狀態] [搜索][重置]      │
│─────────────────────────────────────────────────│
│  [新增]                                  [列設定]│
│─────────────────────────────────────────────────│
│  角色名 | 角色標識 | 排序 | 狀態 | 創建時間 | 操作  │
│  管理員  | admin   | 1   | 正常 | 2024-... | 改 刪 權│
│  普通用戶| common  | 2   | 正常 | 2024-... | 改 刪 權│
│─────────────────────────────────────────────────│
│           [分頁: < 1 2 3 ... >]                  │
└─────────────────────────────────────────────────┘

角色權限分配彈窗 (點擊 "權"):
┌──────────────────────────────┐
│  角色名: 普通用戶              │
│                                │
│  菜單權限:                     │
│  ☑ 系統管理                   │
│    ☑ 用戶管理                 │
│      ☑ 用戶查詢               │
│      ☐ 用戶新增               │
│      ☐ 用戶修改               │
│    ☑ 角色管理                 │
│    ☐ 菜單管理                 │
│                                │
│  數據權限: [本部門及以下 ▼]     │
│                                │
│         [確定]  [取消]          │
└──────────────────────────────┘
```

### 4.5 部門管理頁

```
┌─────────────────────────────────────────────────┐
│  [搜索條件: 部門名/狀態] [搜索][重置]              │
│─────────────────────────────────────────────────│
│  [新增] [展開/摺疊]                              │
│─────────────────────────────────────────────────│
│  部門名稱          | 負責人 | 排序 | 狀態 | 操作   │
│  ├ 總公司          | 王總   | 1   | 正常 | 改 刪 增│
│  │ ├ 研發部        | 李經理 | 1   | 正常 | 改 刪 增│
│  │ │ ├ 前端組      | 張組長 | 1   | 正常 | 改 刪 增│
│  │ │ └ 後端組      | 陳組長 | 2   | 正常 | 改 刪 增│
│  │ ├ 人事部        | 趙經理 | 2   | 正常 | 改 刪 增│
│  │ └ 財務部        | 劉經理 | 3   | 正常 | 改 刪 增│
└─────────────────────────────────────────────────┘
```

### 4.6 崗位管理頁

```
標準 CRUD 表格頁: 搜索 + 表格 + 分頁
欄位: 崗位編碼 | 崗位名稱 | 排序 | 狀態 | 創建時間 | 操作
```

### 4.7 菜單管理頁

```
樹形表格 (同部門管理):
欄位: 菜單名稱 | 圖標 | 排序 | 權限標識 | 組件路徑 | 狀態 | 操作
新增/修改彈窗包含: 菜單類型(目錄/菜單/按鈕)、上級菜單(樹選擇)、圖標選擇
```

---

## 五、前後端交互

### 5.1 環境變量

```bash
# .env.development
VITE_APP_TITLE=人事管理系統
VITE_APP_BASE_API=/api

# .env.production
VITE_APP_TITLE=人事管理系統
VITE_APP_BASE_API=/api
```

### 5.2 Vite 代理配置

```typescript
// vite.config.ts
export default defineConfig({
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true
      }
    }
  }
})
```

### 5.3 API 調用模式

```typescript
// api/system/user.ts
import request from '@/api/request'

export function listUser(params: UserQuery) {
  return request.get('/system/user', { params })
}

export function getUser(userId: number) {
  return request.get(`/system/user/${userId}`)
}

export function addUser(data: UserDTO) {
  return request.post('/system/user', data)
}

export function updateUser(data: UserDTO) {
  return request.put('/system/user', data)
}

export function deleteUser(userId: number) {
  return request.delete(`/system/user/${userId}`)
}
```

---

## 六、組件設計規範

### 6.1 頁面組件模式

每個 CRUD 頁面遵循統一模式：

```vue
<template>
  <!-- 1. 搜索區域 -->
  <el-form :inline="true">...</el-form>

  <!-- 2. 操作按鈕 -->
  <el-row>
    <el-button v-hasPerms="['sys:xxx:add']">新增</el-button>
  </el-row>

  <!-- 3. 數據表格 -->
  <el-table v-loading="loading" :data="tableData">...</el-table>

  <!-- 4. 分頁 -->
  <pagination :total="total" v-model:page="queryParams.pageNum"
              v-model:limit="queryParams.pageSize" @pagination="getList" />

  <!-- 5. 新增/修改彈窗 -->
  <el-dialog v-model="dialogVisible">
    <el-form ref="formRef" :model="form" :rules="rules">...</el-form>
  </el-dialog>
</template>
```

### 6.2 命名規範

```
文件命名:   kebab-case (index.vue, user-form.vue)
組件命名:   PascalCase (Pagination, DeptTree)
API 函數:   camelCase (listUser, addUser)
路由 name:  PascalCase (SystemUser, SystemRole)
Store:      camelCase (useUserStore, usePermissionStore)
```
