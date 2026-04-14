## 階段二：基礎設施

> 本階段建立 HTTP 通信、狀態管理、路由、Token 工具四大底座。執行某個 Step 時，會在這裡擴充詳細的代碼/產物清單。

### Step 3：Axios 封裝 ✅（合併 Step 6 Token 工具）

> 因請求攔截器需要 `getToken()`，順便把 Step 6 的 `utils/auth.ts` 提前做掉。Step 6 在本步一併完成。

#### 產物清單

| 檔案 | 職責 |
|---|---|
| `src/utils/auth.ts` | `getToken` / `setToken` / `removeToken`，localStorage key = `hr-token` |
| `src/api/types/common.d.ts` | `ApiResponse<T>` / `PageResult<T>` / `PageQuery` |
| `src/api/request.ts` | Axios 實例 + 請求/響應攔截器 + 401 重登提示 |

#### 關鍵決策

**響應攔截器自動解包 `data`**

後端 `R<T>` 結構 `{code, msg, data}`，攔截器直接返回 `data`（類型 `T`），業務代碼不用 `.data.data`。

```ts
if (code === BUSINESS_OK) return data    // 成功 → 解包
if (code === HTTP_UNAUTHORIZED) → 彈窗 + 跳登入
else → ElMessage.error(msg)
```

**401 處理：ElMessageBox 重登提示 + 防抖**

- 用 `ElMessageBox.confirm` 彈「是否重新登入」而非直接跳轉（避免用戶正在填的表單數據丟得莫名其妙）
- `isReloginPrompting` 布爾鎖防止多個並發 401 請求彈出多個對話框
- 確認後 `removeToken()` + `window.location.href = '/login'`（不用 router.push，整頁刷新清空所有殘留狀態）

**雙通道觸發 401：**
1. HTTP 2xx 但業務 code=401（後端返回 `R.fail(401, ...)`）
2. HTTP 狀態碼本身 401（後端未登入時 Spring Security 直接返回）

兩條路徑都調 `handleUnauthorized()`，統一行為。

**超時：15 秒**（後端查詢操作偶爾會慢，比默認的 0/無限稍緊一點）

#### request 輔助函數（可選）

導出了 `request<T>()` 泛型函數方便 API 層顯式聲明返回類型：

```ts
export function getUser(id: number) {
  return request<SysUser>({ url: `/system/user/${id}` })
}
```

也可以直接用 `service.get/post/...`，兩種都支持。

#### 驗收（完成於 2026-04-15）

- `npx eslint` 零錯誤
- `npx vue-tsc --noEmit` 類型檢查通過
- 實際聯調推到 Step 16（登入 API 對接）時才能跑通，Step 3 先提供基礎設施

### Step 4：Pinia 狀態管理 ✅（合併 Step 16 登入 API）

> user store 需要 `authApi.login/logout/getInfo`，順便把 Step 16 的 `api/auth.ts` 提前做掉。

#### 產物清單

| 檔案 | 職責 |
|---|---|
| `src/api/types/auth.d.ts` | `LoginBody` / `LoginResult` / `UserInfo` / `MenuItem` 類型 |
| `src/api/auth.ts` | `login` / `logout` / `getInfo` / `getRouters` 4 個 API 函數 |
| `src/store/index.ts` | `createPinia()` 實例 |
| `src/store/modules/user.ts` | token + userInfo + roles + permissions + login/logout/getInfo/resetState |
| `src/store/modules/app.ts` | sidebarCollapsed + device + toggleSidebar/setDevice |
| `src/store/modules/permission.ts` | menus + dynamicRoutes + routesGenerated（Step 17 才真正生成路由） |
| `src/store/modules/tagsView.ts` | visitedViews + cachedViews + addView/delView/delOthersViews/delAllViews |
| `src/main.ts` | `createApp(App).use(pinia).mount('#app')` |

#### 寫法選擇：Setup Stores

全部用 `defineStore('x', () => {...})` 函數式寫法，不用舊的 Options 寫法。理由：
- 跟 `<script setup>` 風格一致
- 可以像普通 Composable 那樣導入 ref/computed/watch
- 類型推斷更好

```ts
export const useUserStore = defineStore('user', () => {
  const token = ref<string>(getToken() || '')
  const userInfo = ref<UserInfo | null>(null)
  // ...
  return { token, userInfo, login, logout, ... }
})
```

使用時：`const userStore = useUserStore(); userStore.token`

#### 關鍵決策

**user store：token 初始化從 localStorage 取**
```ts
const token = ref<string>(getToken() || '')
```
頁面刷新後 store 重建，從 localStorage 恢復 token。

**user store：logout 用 `try/finally` 確保清理**
即使後端 logout 接口失敗（比如網絡斷了），前端也必須清空 token 和用戶信息，否則會卡在「已登出但狀態還在」的殘留狀態。

**app store：sidebar 摺疊狀態持久化到 localStorage**
key = `hr-sidebar-collapsed`，避免每次刷新都重置。

**permission store：本步只存菜單樹，不生成真正路由**
`setMenus(menus)` + `setDynamicRoutes(routes)` 分兩步；真正 `MenuItem[] → RouteRecordRaw[]` 的轉換邏輯留到 Step 17（需要處理動態 `import(`@/views/${component}.vue`)`）。

**tagsView store：4 個 action**
- `addView(route)` — 路由變化時加頁籤
- `delView(path)` — 關閉單個頁籤（同時從 cachedViews 移除，讓 keep-alive 釋放）
- `delOthersViews(path)` — 關閉其他
- `delAllViews()` — 全關

#### api/auth.ts 端點對照

| 前端函數 | 後端端點 | 返回 |
|---|---|---|
| `login(data)` | `POST /login` | `{ token }` |
| `logout()` | `POST /logout` | void |
| `getInfo()` | `GET /getInfo` | `UserInfo`（含 roles / permissions） |
| `getRouters()` | `GET /getRouters` | `MenuItem[]`（菜單樹） |

類型安全：用 `request<T>` 泛型顯式聲明返回類型，攔截器自動解包，業務代碼直接拿 `T`。

#### 驗收（完成於 2026-04-15）

- `npx eslint src/` 零錯誤
- `npx vue-tsc --noEmit` 類型檢查通過
- 實際聯調要等 Step 5（路由）+ Step 15（登入頁）

### Step 5：路由配置 ✅（部分併入 Step 15/24/25 佔位頁面）

#### 產物清單

| 檔案 | 職責 |
|---|---|
| `src/router/staticRoutes.ts` | 靜態路由：`/login` `/404` `/401` `/redirect/:path(.*)` `/` `/dashboard` |
| `src/router/index.ts` | `createRouter` + history 模式 + `scrollBehavior` 回頂 |
| `src/router/permission.ts` | 全局路由守衛 + 白名單 + token 檢查 + 用戶信息加載 |
| `src/views/login/index.vue` | 登入頁（**佔位**，Step 15 重寫 UI） |
| `src/views/dashboard/index.vue` | 首頁（**佔位**，展示用戶信息 + 退出按鈕） |
| `src/views/error/404.vue` / `401.vue` | 錯誤頁（`el-result` 組件） |
| `src/views/redirect/index.vue` | 路由刷新輔助（TagsView Refresh 用） |
| `src/App.vue` | 改為單行 `<router-view />` |
| `src/main.ts` | 加 `app.use(router)` + `import './router/permission'` |

#### 守衛流程

```
router.beforeEach:
├── 有 token
│   ├── 訪問 /login → next('/')
│   ├── userStore.userInfo 已存在 → next()
│   └── userInfo 未加載：
│       ├── await userStore.getInfo()
│       ├── await getRouters() → permissionStore.setMenus(menus)
│       ├── permissionStore.setDynamicRoutes([])  // Step 17 才真正生成
│       └── next({ ...to, replace: true })
│       └─ 出錯：resetState + ElMessage + next(/login?redirect=...)
└── 無 token
    ├── to.path ∈ 白名單 → next()
    └── 否則 → next('/login?redirect=' + to.fullPath)
```

**白名單：** `['/login', '/404', '/401']`

#### 關鍵決策

**`/redirect/:path(.*)` 輔助路由**
- 用於 TagsView 的「刷新當前頁籤」功能
- 用法：`router.push('/redirect' + currentPath)` → 觸發組件重建
- `.*` 表示匹配任意深度的 path（含 `/`）

**動態路由本步不生成**
- `permissionStore.setDynamicRoutes([])` 只佔位，不實際 `router.addRoute()`
- 訪問 `/system/user` 等業務路由目前會 404
- 真正的 `MenuItem[] → RouteRecordRaw[]` 轉換 + `router.addRoute()` 在 Step 17 實現

**`getInfo` 失敗時的回滾**
- catch 裡調 `userStore.resetState()` + `permissionStore.resetRoutes()`，避免部分狀態髒
- 跳 `/login?redirect=fullPath`，登入後自動回原頁

**`main.ts` 中 `import './router/permission'`**
- 只 import 不取 export，純為觸發模塊執行（`router.beforeEach` 掛載）
- 必須放在 `use(router)` 後或同時，確保 router 實例已創建

#### 佔位頁面說明

**login/index.vue：** 可跑通登入流程的最小表單（用戶名默認 `admin`、密碼 `admin123`），Step 15 重寫為卡片式 UI + 校驗 + 記住我。

**dashboard/index.vue：** 展示當前 userInfo + 退出按鈕，用於驗收守衛流程。Step 24 重寫為統計卡片 + 快捷入口。

**error/404.vue、401.vue：** `el-result` 組件，Step 25 美化（加插畫）。

#### 驗收（完成於 2026-04-15）

- `npx eslint src/` 零錯誤
- `npx vue-tsc --noEmit` 類型檢查通過
- 端到端測試需後端一起啟動（見下文）

#### 端到端測試步驟（需要前後端都啟動）

1. 後端啟動：`hr-backend` IDE 跑 `HrApplication`
2. 前端啟動：`cd hr-ui && npm run dev`
3. 瀏覽器打開 `http://localhost:5173`
4. 無 token → 自動跳 `/login?redirect=/dashboard`
5. 填 `admin / admin123` → 登入
6. 自動跳 `/dashboard`，顯示 userInfo（userId=1、roles=[admin]、permissions>0）
7. 點「退出登入」→ 跳 `/login`
8. 直接訪問 `http://localhost:5173/dashboard` → 有 token 就放行，無則跳登入
9. 刷新頁面（F5）→ token 在 localStorage，保持登入狀態

### Step 6：Token 工具 ✅（已併入 Step 3 完成）

`src/utils/auth.ts`：
- `getToken()` / `setToken(token)` / `removeToken()`
- 存儲位置：`localStorage`，key = `hr-token`

**提前完成的原因：** Axios 請求攔截器依賴 `getToken()`，Step 3 做時一併實現。

#### 階段二驗收

`main.ts` 引入 pinia + router；瀏覽器訪問 `/`，未登入跳 `/login`，登入頁能渲染（即使 API 還沒對接）。

---

## 當前未解 Bug（2026-04-15）

### 登入後 token 未保存到 localStorage，`/getInfo` 報 401

**現象：**
- 前端點擊登入按鈕
- 後端日誌顯示 `SELECT * FROM sys_user WHERE username = ?` + `UPDATE sys_user SET login_ip...` 正常執行（admin 用戶登入成功）
- 但 `localStorage` 無 `hr-token` 鍵
- 隨後 `/api/getInfo` 返回 401 `Full authentication is required`
- 用戶反饋 Network 面板看不到 `/login` 請求，但控制台有 `Request failed with status code 401`

**矛盾點：**
後端 SQL 確實跑了 = login 請求到了後端 → 但前端 Network 看不到 = 可能是過濾器設置或 Preserve log 未開。

**已確認的正確配置：**
- 後端 `context-path=/api`，endpoint `POST /api/login`，返回 `R<Map<String,String>>` = `{code, msg, data:{token}}`
- Vite proxy `/api` → `http://localhost:8080`（不 rewrite，路徑保留）
- 前端 `authApi.login` → `request({ url: '/login', method: 'post' })` → 實際 URL `/api/login`
- 響應攔截器 `code===200` 時返回 `data` 字段 → `authApi.login` 拿到 `{token}`
- `userStore.login` 解構 `{token: newToken}` → `setToken(newToken)`

**最可疑假設：** login 響應體結構和 `ApiResponse<{token}>` 實際不匹配，導致 `data` 是 undefined，解構 `{token}` 拋錯 → token 沒存 → 後續 getInfo 無 Authorization 頭 → 401。

**下次排查步驟：**
1. Network 面板開 Preserve log + 過濾器選 All，重試登入
2. 重點看 `POST /api/login` 的 **Response body** 實際結構
3. Console 看 401 錯誤的完整堆棧，定位拋出位置
4. 確認地址欄翻譯圖標為「顯示原文」狀態（翻譯會破壞 Vue 事件綁定）

---
