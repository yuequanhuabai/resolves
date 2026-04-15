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

## 踩坑記錄：登入後 `/getInfo` 始終 401（2026-04-15 已解決）

### 症狀

- `POST /api/login` → 200，返回 `{code:200, data:{token:"eyJ..."}}` ✅
- 前端正確保存 token，發起 `GET /api/getInfo` 帶 `Authorization: Bearer eyJ...`
- 後端返回 `{code:401, msg:"認證失敗，請重新登入"}`
- 後端日誌：`Full authentication is required to access this resource`

### 排查軌跡（三層剝洋蔥）

**第一層：前端 Network 請求確認**
在 `api/request.ts` 的攔截器裡加 `console.log` 打印請求/響應完整內容。
確認 login 請求發出、響應正常、token 在 header 裡傳遞。問題不在前端。

**第二層：Redis 服務本身**
後端用 JWT + Redis 混合方案（JWT 只存 UUID，真正的 LoginUser 存 Redis）。
`Get-NetTCPConnection -LocalPort 6379` 發現遠程服務器 Redis 沒啟動一個月。
啟動後 `systemctl start redis`，問題依舊。

**第三層：Redis 序列化**
在 `TokenService.createToken` 和 `getLoginUser` 加詳細日誌，發現：
- 寫入成功：`[TokenService] 寫入 Redis key=login_token:xxx`
- 讀取拋異常：
  ```
  Problem deserializing 'setterless' property ("authorities"):
  no way to handle typed deser with setterless yet
  ```

### 根本原因：Jackson 序列化/反序列化不對稱

`LoginUser implements UserDetails`，被迫實現了 `getAuthorities()`。這是一個**計算型 getter**：

```java
@Override
public Collection<? extends GrantedAuthority> getAuthorities() {
    // 從 permissions 和 roles 現場推導，不是真實字段
    return permissions.stream().map(SimpleGrantedAuthority::new)...
}
```

`GenericJackson2JsonRedisSerializer`（底層 Jackson）的行為：

| 階段 | 規則 | 結果 |
|---|---|---|
| **序列化** | 掃描所有 public getter，當成字段寫出去 | `getAuthorities()` 被當「authorities 字段」寫進 JSON |
| **反序列化** | 對每個 JSON 字段找 setter 或真實 field 塞值 | 找不到 → 走 setterless 兜底 → 撞上多態類型（`@class:SimpleGrantedAuthority`）→ 投降 |

異常拋出時，**整個 LoginUser 對象為 null**（Jackson 是全有或全無，不是部分成功）：

```
authorities 字段炸  →  LoginUser = null
                 →  TokenService.getLoginUser() 返回 null
                 →  JwtAuthenticationFilter 不設 SecurityContext
                 →  /getInfo 觸發 AuthenticationEntryPointImpl → 401
```

**雖然 JWT token 本身完全有效**（簽名對、key 對、Redis 裡能找到對應 JSON），但那份 JSON 讀不回 Java 對象，token 就廢了。

### 修復

`hr-framework/security/LoginUser.java` 給所有計算型 getter 加 `@JsonIgnore`：

```java
@JsonIgnore
@Override
public Collection<? extends GrantedAuthority> getAuthorities() { ... }

@JsonIgnore @Override public boolean isAccountNonExpired() { return true; }
@JsonIgnore @Override public boolean isAccountNonLocked() { return true; }
@JsonIgnore @Override public boolean isCredentialsNonExpired() { return true; }
@JsonIgnore @Override public boolean isEnabled() { return true; }
```

序列化時 Jackson 跳過這些 getter，JSON 不再冗餘寫入。反序列化後業務層調 `getAuthorities()` 照樣從 `permissions + roles` 現算，零功能損失。

修復後還需：
1. 重啟後端（LoginUser 類需重新加載）
2. `redis-cli flushdb` 清掉舊的壞 JSON（否則重啟後仍讀舊格式）

### 經驗教訓

1. **JWT + Redis 混合方案的脆弱點**：JWT 只是索引，所有身份信息綁在 Redis 那個對象的序列化/反序列化能力上。對象讀不回 = token 作廢。
2. **`UserDetails` + `GenericJackson2JsonRedisSerializer` 是經典踩坑組合**。RuoYi 原項目用 `FastJsonRedisSerializer` 對這類 getter-only 屬性更寬容，切換序列化器時會踩這個雷。
3. **計算型 getter 要顯式告訴 Jackson 別當字段**。凡是「方法名是 getXxx/isXxx，但對象裡沒有對應 field 或 setter」的 getter，一律 `@JsonIgnore`。
4. **診斷多層協作的 Bug 按鏈路順序逐層剝離**：前端打印 → 中間件服務存活 → 序列化協議細節。跳層看很容易把時間浪費在「懷疑人生」。

### 附加產出

- `api/request.ts` 的三處 `console.log`（請求/響應/錯誤）保留著作為日常調試工具
- `TokenService` 的 `[TokenService] 寫入/讀 Redis` 日誌保留，便於後續類似問題快速定位

---
