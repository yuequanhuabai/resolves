# 登入流程 · 宏觀架構

> 本文件從宏觀角度梳理「用戶點擊登入按鈕 → 進入首頁 → 渲染菜單」的完整鏈路，聚焦**誰調用誰、數據怎麼流**，不糾結具體代碼細節。定位 Bug 時按圖索驥，找到可疑環節再鑽進對應文件讀代碼。

---

## 一、角色全景

```
┌─────────────────────────┐         ┌──────────────────────────┐
│  瀏覽器 (hr-ui, :5173)  │         │  後端 (hr-backend, :8080) │
│                         │         │                          │
│  Vue 3 + Pinia + Axios  │  HTTP   │  Spring Boot + Security  │
│  Vue Router             │ ◄─────► │  JWT + MyBatis + SQLServer│
└─────────────────────────┘         └──────────────────────────┘
          │                                      │
          └──── Vite Dev Proxy ─── /api → :8080 ─┘
```

**關鍵約定：**
- 前端 baseURL = `/api`，所有請求都帶 `/api` 前綴
- Vite dev server 代理 `/api/*` → `http://localhost:8080/api/*`（**不 rewrite**，路徑原樣轉發）
- 後端 `context-path=/api`，所以最終 endpoint 落在 `/api/login` / `/api/getInfo` 等

---

## 二、完整時序（Happy Path）

```
用戶輸入 admin/admin123 → 點擊[登入]
  │
  ├─① 【前端】views/login/index.vue::onSubmit()
  │    └─ 調用 userStore.login({username, password})
  │
  ├─② 【前端】store/modules/user.ts::login()
  │    └─ 調用 authApi.login(data)  ──► api/auth.ts
  │
  ├─③ 【前端】api/request.ts (axios 實例)
  │    │  請求攔截器：無 token，不加 Authorization
  │    └─ POST /api/login  body={username, password}
  │
  ├─④ 【代理】Vite :5173/api/login  →  後端 :8080/api/login
  │
  ├─⑤ 【後端】SecurityFilterChain
  │    │  /login 在 permitAll 白名單 → 放行，不走 JWT 過濾器
  │    └─ 進入 Controller
  │
  ├─⑥ 【後端】AuthController::login()
  │    ├─ LoginService.login(username, password)
  │    │    ├─ AuthenticationManager.authenticate(UsernamePasswordAuthToken)
  │    │    │    └─ UserDetailsServiceImpl.loadUserByUsername()
  │    │    │         └─ SELECT * FROM sys_user WHERE username=? AND deleted=0
  │    │    ├─ BCrypt 密碼校驗
  │    │    ├─ UPDATE sys_user SET login_ip=?, login_time=GETDATE()
  │    │    ├─ TokenService.createToken(loginUser)
  │    │    │    ├─ 生成 UUID (jti)
  │    │    │    ├─ loginUser 緩存到 Redis/本地 (key=login_tokens:{uuid})
  │    │    │    └─ 用 JWT 密鑰簽發 token (payload 含 jti)
  │    │    └─ 返回 token 字串
  │    └─ return R.ok(Map.of("token", xxx))
  │            → JSON: {code:200, msg:"操作成功", data:{token:"eyJ..."}}
  │
  ├─⑦ 【前端】api/request.ts 響應攔截器
  │    │  code===200 → return response.data.data  (脫一層殼)
  │    └─ authApi.login() resolve 值 = {token: "eyJ..."}
  │
  ├─⑧ 【前端】userStore.login() 繼續
  │    ├─ 解構 {token: newToken}
  │    ├─ setToken(newToken)        → localStorage['hr-token'] = "eyJ..."
  │    └─ this.token = newToken     → Pinia 響應式狀態更新
  │
  ├─⑨ 【前端】views/login/index.vue::onSubmit() 繼續
  │    └─ router.push('/')           → 觸發路由守衛
  │
  ├─⑩ 【前端】router/permission.ts::beforeEach
  │    ├─ hasToken = true (剛存的)
  │    ├─ userStore.userInfo === null（還沒拉過）
  │    ├─ await userStore.getInfo()
  │    │    └─ GET /api/getInfo  (請求攔截器此時帶上 Authorization: Bearer eyJ...)
  │    │         │
  │    │         ├─【後端】JwtAuthenticationFilter
  │    │         │    ├─ 從 Header 提取 token
  │    │         │    ├─ TokenService.parseToken() 驗簽 + 取 jti
  │    │         │    ├─ 從 Redis/緩存取 LoginUser
  │    │         │    └─ 塞進 SecurityContextHolder
  │    │         │
  │    │         └─【後端】AuthController.getInfo()
  │    │              └─ return R.ok({userId, username, roles[], permissions[], ...})
  │    │
  │    │  前端收到 → user store 存 userInfo / roles / permissions
  │    │
  │    ├─ await getRouters()
  │    │    └─ GET /api/getRouters → 返回該用戶的菜單樹 MenuItem[]
  │    │
  │    ├─ permissionStore.setMenus(menus)
  │    ├─ permissionStore.setDynamicRoutes([])   ← Step 17 才真正生成路由
  │    └─ next({ ...to, replace: true })         ← 守衛放行，最終進 /dashboard
  │
  └─⑪ 【前端】/dashboard 渲染用戶信息
        （Step 7 完成佈局後，側邊欄渲染菜單）
```

---

## 三、四個關鍵接口一覽

| 接口 | 方法 | 入參 | 出參 | 是否需要 token |
|---|---|---|---|---|
| `/api/login` | POST | `{username, password}` | `{token}` | ❌ |
| `/api/logout` | POST | — | — | ✅ |
| `/api/getInfo` | GET | — | `{userId, username, roles[], permissions[], ...}` | ✅ |
| `/api/getRouters` | GET | — | `MenuItem[]` (菜單樹) | ✅ |

**白名單（無需 token）：** `/login`、`/captchaImage`、Swagger、靜態資源
其餘全部走 `JwtAuthenticationFilter` → 校驗失敗由 `AuthenticationEntryPointImpl` 返回 `{code:401, msg:"Full authentication is required..."}`

---

## 四、前端三大分層

```
┌─────────────────────────────────────────────────────────┐
│ 視圖層 (Vue Components)                                  │
│   views/login/index.vue — 表單 + 提交                   │
│   views/dashboard/index.vue — 登入後首頁                 │
└──────────────────┬──────────────────────────────────────┘
                   │ 調用 store action
┌──────────────────▼──────────────────────────────────────┐
│ 狀態層 (Pinia Stores)                                    │
│   user store       — token / userInfo / roles / perms   │
│   permission store — menus / dynamicRoutes              │
│   app store        — sidebar 摺疊等 UI 狀態             │
│   tagsView store   — 多頁籤                              │
└──────────────────┬──────────────────────────────────────┘
                   │ 調用 API 函數
┌──────────────────▼──────────────────────────────────────┐
│ 網絡層 (api/*)                                           │
│   api/auth.ts     — login / logout / getInfo / getRouters│
│   api/request.ts  — Axios 實例 + 攔截器（統一解包/401）  │
│   utils/auth.ts   — Token 存取 (localStorage)           │
└─────────────────────────────────────────────────────────┘
```

**貫穿三層的路由守衛：** `router/permission.ts` 在每次導航前檢查 token 並協調以上三層。

---

## 五、後端三大分層

```
┌─────────────────────────────────────────────────────────┐
│ 過濾器層 (Spring Security)                               │
│   SecurityFilterChain — 白名單 + 授權規則                │
│   JwtAuthenticationFilter — 解析 Bearer token → 填充 SCH│
│   AuthenticationEntryPointImpl — 未認證統一返回 401 JSON │
│   AccessDeniedHandlerImpl — 無權限統一返回 403 JSON      │
└──────────────────┬──────────────────────────────────────┘
                   │ 放行後進入
┌──────────────────▼──────────────────────────────────────┐
│ Controller 層                                            │
│   AuthController — login / logout / getInfo / getRouters │
└──────────────────┬──────────────────────────────────────┘
                   │ 調用
┌──────────────────▼──────────────────────────────────────┐
│ Service 層 + 基礎設施                                    │
│   LoginService        — 認證編排                         │
│   TokenService        — JWT 簽發/解析 + LoginUser 緩存   │
│   UserDetailsServiceImpl — 查庫 + 組裝 LoginUser         │
│   PermissionService   — @ss.hasPermi('xxx') 支持          │
│   SecurityUtils       — 從 SecurityContext 拿當前用戶    │
└─────────────────────────────────────────────────────────┘
```

---

## 六、Token 生命週期

```
簽發（登入成功）
  TokenService.createToken(loginUser)
    ├─ uuid = UUID.randomUUID().toString()        ← jti
    ├─ loginUser.setToken(uuid)
    ├─ 緩存：key="login_tokens:" + uuid, value=loginUser, TTL=30min
    └─ JWT 簽名：{"login_user_key": uuid} + secret → eyJ...
         └─ 返回給前端

保存（前端）
  localStorage['hr-token'] = eyJ...
  userStore.token = eyJ...  (Pinia 響應式)

攜帶（後續所有請求）
  axios 請求攔截器：Authorization: Bearer eyJ...

校驗（後端每次請求）
  JwtAuthenticationFilter:
    1. 從 Header 取 token
    2. Jwts.parser().verifyWith(key).parse(token) → 取 jti
    3. 從緩存拿 LoginUser（若無 → 視為過期 → 401）
    4. 過期時間 < 20min 時自動 refresh TTL
    5. SecurityContextHolder.setAuthentication(...)

銷毀（登出）
  前端：removeToken()
  後端：loginService.logout() → 刪除緩存 key
```

---

## 七、前端 401 的兩條路徑

前端響應攔截器會被觸發的 401 有兩種來源：

```
路徑 A：HTTP 2xx 但業務 code=401
  後端手動 R.fail(401, "...") 返回，HTTP 狀態碼是 200
  → 走 response interceptor 的 success 分支，檢查到 code=401
  → handleUnauthorized()

路徑 B：HTTP 狀態碼本身 401
  Spring Security 未認證直接攔截，由 AuthenticationEntryPointImpl 寫回 401
  → 走 response interceptor 的 error 分支
  → 檢查 error.response.status === 401
  → handleUnauthorized()
```

兩條路徑最終都走 `ElMessageBox.confirm` 重登提示（`isReloginPrompting` 布爾鎖防重複彈窗）。

---

## 八、宏觀定位 Bug 的檢查清單

面對「登入不成功」類 Bug，按這個順序排查，每一層都有明確的驗證手段：

| 層 | 驗證方法 | 異常症狀 |
|---|---|---|
| 1. 前端事件 | Console 加 `console.log` 在 `onSubmit` 開頭 | 點了按鈕但沒打印 → 事件綁定失效（例如 Chrome 翻譯破壞 DOM） |
| 2. 前端請求發出 | Network 面板（過濾 All + Preserve log）| 沒看到 `POST /api/login` → axios 前面就拋了 |
| 3. 代理轉發 | Network 看請求 URL + 狀態 | 404/502 → Vite proxy 配置或後端沒起 |
| 4. 後端接收 | 後端日誌 `[DispatcherServlet] POST /login` | 沒日誌 → 被過濾器攔截（白名單） |
| 5. 後端邏輯 | SQL 日誌 + `UPDATE login_time` | 沒 SQL → 認證/密碼校驗失敗；有 SQL 則登入邏輯 OK |
| 6. 後端返回 | Network Response Body | 看到 `{code, msg, data:{token}}` 說明後端完活 |
| 7. 前端攔截器 | 在 `response.use` 成功分支加 `console.log` | 成功分支沒進 → 響應結構對不上 `ApiResponse` 類型 |
| 8. Token 存儲 | DevTools → Application → Local Storage | 沒 `hr-token` → `setToken` 沒跑（第 7 步拋錯了） |
| 9. 後續請求 | Network `/getInfo` Request Headers | 沒 Authorization → 攔截器取 token 時點早於 setToken |
| 10. 後端校驗 | 後端日誌 AuthenticationEntryPointImpl | `原因: Full authentication is required` → 就是 Header 沒帶或 token 解析失敗 |

**核心啟示：後端日誌看得到 SQL = 登入邏輯跑完了 = Bug 一定在⑦之後**（前端攔截器、token 存儲、後續請求之間）。

---

## 九、相關文件索引

**前端：**
- `hr-ui/src/views/login/index.vue` — 登入表單
- `hr-ui/src/store/modules/user.ts` — user store，`login / getInfo / logout` actions
- `hr-ui/src/store/modules/permission.ts` — 菜單 + 動態路由
- `hr-ui/src/api/auth.ts` — 4 個認證 API
- `hr-ui/src/api/request.ts` — Axios 實例 + 攔截器
- `hr-ui/src/api/types/auth.d.ts` / `common.d.ts` — 類型定義
- `hr-ui/src/utils/auth.ts` — Token localStorage 工具
- `hr-ui/src/router/permission.ts` — 全局路由守衛
- `hr-ui/src/router/staticRoutes.ts` — 靜態路由表
- `hr-ui/vite.config.ts` — Dev proxy 配置

**後端：**
- `hr-admin/.../controller/AuthController.java` — 4 個認證端點
- `hr-admin/.../service/LoginService.java` — 登入編排
- `hr-framework/.../security/TokenService.java` — JWT 簽發/解析
- `hr-framework/.../security/JwtAuthenticationFilter.java` — 請求認證過濾
- `hr-framework/.../security/handler/AuthenticationEntryPointImpl.java` — 401 統一返回
- `hr-framework/.../security/SecurityUtils.java` — 當前用戶上下文
- `hr-admin/src/main/resources/application.yml` — `context-path: /api`

---

## 十、踩坑記錄：登入後 `/getInfo` 401（2026-04-15 已解決）

**最終根因：** `LoginUser` 的 `getAuthorities()` 等 `UserDetails` 計算型 getter 被 Jackson 誤當成字段序列化進 Redis，但反序列化找不到 setter，`GenericJackson2JsonRedisSerializer` 拋 `setterless property` → 整個 LoginUser 讀回來是 null → SecurityContext 沒設 → 401。

**修復：** `LoginUser` 所有計算型 getter 加 `@JsonIgnore`（`getAuthorities` / `isAccountNonExpired` / `isAccountNonLocked` / `isCredentialsNonExpired` / `isEnabled`）。

**完整排查鏈路與根因分析詳見** `fronted_steps/phase2_infra.md` 末尾「踩坑記錄」章節。

**對本章節「八、宏觀定位 Bug 的檢查清單」的啟示：** 第 10 步（後端認證返回 401）之後應再加一個子項 ——「查後端 Filter 日誌，看 LoginUser 是不是 null；若是，去 TokenService 加詳細 log 分別打印寫入/讀取 Redis 結果」。Redis 序列化問題是隱形殺手，看表象完全像 token 無效。
