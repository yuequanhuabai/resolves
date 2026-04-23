 ▐▛███▜▌   Claude Code v2.1.118
▝▜█████▛▘  Sonnet 4.6 · Claude Pro
  ▘▘ ▝▝    D:\software\develop_tools\git\gitee\pap_new

> /init                                                                         

  Searched for 5 patterns, read 11 files, listed 14 directories (ctrl+o to expand)

● Now I have enough context to draft the CLAUDE.md.

● Write(CLAUDE.md)
  ⎿  Wrote 95 lines to CLAUDE.md
       2 # CLAUDE.md
       3 This file provides guidance to Claude Code (claude.ai/code) when
       4  working with code in this repository.
       5 ## Repository layout
       6 
         po; each side has its own `.git`):king directory (no root git re
       8 
          ruoyi-vue-pro / yudao).oot 3.4.5 / Java 17 backend (forked from
      10 - `pap-front/` — Vue 3 + Vite 5 + Element Plus + TypeScript admi
         n UI (forked from yudao-ui-admin-vue3).
     … +159 lines (ctrl+o to expand)

● Created CLAUDE.md at the repo root
  (D:/software/develop_tools/git/gitee/pap_new/CLAUDE.md).

  It covers:
  - Layout — two siblings (pap-back/pap-front), each with its own git root, no
  wrapping repo.
  - Backend — Maven multi-module (pap-dependencies BOM, pap-framework shared
  infra, pap-server main app), the dual-package scan (cn.bochk.pap.server +
  cn.bochk.pap.module), key server subpackages (aladdin, bpm, business, system,
  init).
  - Commands — Maven build/run variants, the skipTests=true default gotcha, and
  the --init-sql bootstrap mode on PapServerApplication with all its flags.
  - Config — profile files, port 9600, SQL Server as the local master DB,
  mandatory Redis/Spring-Session for SAML2, Flowable database-schema-update: 
  false, SAML2 SP endpoint pattern.
  - Frontend — stack, mode-based env files, the npm run dev vs dev-server split,
   build per env, lint/type-check scripts, VITE_API_URL=/admin-api.
  - Cross-cutting — manual SQL migrations in sql/sqlserver/ (MySQL dir is
  legacy), script/shell/deploy.sh as the deploy recipe, and a note that the
  upstream pap-back/README.md is marketing copy not ground truth.

✻ Cogitated for 3m 11s

> 幫我分析一下等前項目的認證和授權模塊                                          

  Searched for 6 patterns, read 25 files, listed 7 directories (ctrl+o to expand)

● 下面是對這個項目認證 / 授權模塊的完整分析。項目是基於 yudao / ruoyi-vue-pro
  魔改的，保留了原本的 OAuth2 Token + RBAC 模型，同時在外層嫁接了 ADFS 的 SAML2
  單點登錄。

  ---
  一、整體架構

  兩條認證通道，最終落點都是同一個內部 OAuth2 Access Token：

                      ┌──────────────────────────────────┐
                      │  後端本地帳密 (system/auth/login)  │──┐
                      └──────────────────────────────────┘  │
                                                            ▼
     ADFS IdP ──SAML2──► /login/saml2/sso/{PAP}  ──►  OAuth2AccessTokenDO
                            (successHandler)                ▲
                                                            │  Bearer <token>
                                                            │
                      ┌──────────────────────────────────┐  │
                      │ 所有後續 HTTP 請求               │──┘
                      │ TokenAuthenticationFilter        │
                      └──────────────────────────────────┘

  - 認證 (Authentication)：發 token 可以走 SAML2 或本地帳密，驗 token 統一用
  TokenAuthenticationFilter。
  - 授權 (Authorization)：方法級 @PreAuthorize("@ss.hasPermission(...)") +
  前端菜單/按鈕級別指令，RBAC 存在 SQL Server（user_role / role_menu / menu）。
  - Session：業務本身是無狀態 Token，但 SAML2 流程依賴 HttpSession（AuthnRequest
   的 InResponseTo/RelayState），所以用 Spring Session + Redis
  共享，多實例才不會丟。

  ---
  二、後端：Spring Security 骨架

  核心配置集中在 pap-framework 的 security 子包：

  檔案: YudaoSecurityAutoConfiguration
  職責: 註冊 AuthenticationEntryPoint / AccessDeniedHandler / PasswordEncoder 
    (BCrypt) / TokenAuthenticationFilter / 名為 ss 的 SecurityFrameworkService
    Bean / 把 SecurityContextHolder 切換成 TransmittableThreadLocal
    策略（支援線程池/異步傳遞）
  ────────────────────────────────────────
  檔案: YudaoWebSecurityConfigurerAdapter
  職責: 定義 SecurityFilterChain：CSRF 關閉、Session IF_REQUIRED、@PreAuthorize
    開啟（@EnableMethodSecurity(securedEnabled=true)）
  ────────────────────────────────────────
  檔案: SecurityProperties (yudao.security.*)
  職責: token header / parameter 名、mock 開關、全域 permit-all URL、BCrypt
    strength

  2.1 免登錄白名單構造

  filterChain(HttpSecurity) 把以下三類合併成 permitAll：

  1. 靜態資源 + /admin-api/api/health/**
  2. @PermitAll 註解掃描：getPermitAllUrlsFromAnnotations() 反射
  RequestMappingHandlerMapping，把標註的 Controller 方法按 HTTP
  方法歸類註冊。AuthController 的
  /login、/logout、/refresh-token、/register、/reset-password 都靠這個。
  3. 硬編碼白名單：/saml2/**、/login/saml2/**、/system/auth/saml2/**、/admin-api
  /pvb1/**、/admin-api/Audit/**、/admin-api/{benchmark,modelPortfolio,buyList}/e
  xport-**、Swagger / Druid / Actuator。⚠️
  這一塊直接寫死在框架類裡，修改需要改源碼、重啟。
  4. 其餘 anyRequest().authenticated()。

  2.2 Token 認證過濾器

  TokenAuthenticationFilter.doFilterInternal()（pap-framework）的邏輯：

  1. SecurityFrameworkUtils.obtainAuthorization() 從 Authorization header 取
  token（相容 Bearer  前綴），若缺失再從 ?token= query param 取（主要給
  WebSocket 用）。
  2. oauth2TokenApi.checkAccessToken(token) → Redis 先查，沒有回源 MySQL/SQL
  Server。
  3. 校驗 userType 是否匹配（/admin-api = ADMIN，/app-api = MEMBER；WebSocket
  等不強制）。
  4. 組裝 LoginUser → SecurityContextHolder + request.setAttribute（供後續
  ApiAccessLogFilter 記錄日誌用）。
  5. Mock 模式（yudao.security.mock-enable=true，dev profile 下開啟）：token 以
  mockSecret（預設 test）開頭，後綴直接當 userId 用，方便本地調試。⚠️
  上線必須關閉，現在 application-dev.yaml 裡是 mock-enable: true。

  2.3 SAML2 單點登錄

  IdP 是香港中銀的 ums01.bochk.com（ADFS），SP 端配置位於
  pap.security.ums.saml2.*：

  - entityId / registrationId = PAP
  - loginProcessingUrl = /login/saml2/sso/{registrationId} （必須含
  {registrationId}，否則 Spring Security 解不出注冊 ID）
  - assertionUrl = https://pap-dev.bcggroup.com/login/saml2/sso/PAP
  - idpMetadata = classpath:saml2/federationmetadata.xml（支援 classpath:/
  file:/ http(s)://）

  ⚠️ 重要發現：YudaoWebSecurityConfigurerAdapter 裡的
  saml2Login()、saml2Metadata()、saml2Logout()，以及
  RelyingPartyRegistrationRepository 這個 Bean 目前全部被註釋掉了（第
  227–242、270 行）。意味着：
  - /login/saml2/sso/PAP 依賴 Spring Security 自動配置的 SAML2 支持（會從
  spring.security.saml2.* 或自動發現的 RelyingPartyRegistration
  走），這裡沒有顯式註冊，需要確認現在跑的 profile 下到底是靠什麼完成 SAML
  回調。
  - successHandler() 方法還在，但沒掛到 filter chain 上——現在成功後如何觸發生成
  token → 重定向需要再核對一次。

  成功後的路徑（successHandler，目前未接線）：
  1. SAMLUserDetailsServiceImpl.loadUserBySamlPrincipal() 從 SAML 斷言屬性
  (http://ums01.bochk.com/name、nameId、deptcode、authorisation 等) 取資訊。
  2. 若 adminUser 表不存在且 autoCreateUser=true → createUserFromSaml()
  自動建部門 + 建用戶 + 分配角色（取 authorisation 末 5 位當角色名去查
  RoleDO）。
  3. oauth2TokenService.createAccessToken() 生成內部 token。
  4. response.sendRedirect(redirectUrl + "?token=" + urlEncoded) 把 token
  拼回前端首頁 URL。

  ⚠️ SAMLUserDetailsServiceImpl 有幾個明顯的遺留問題：
  - createUserFromSaml 裡 UserPostDO.setUserId(deptNewId) 明顯是 bug（應該是
  userId 不是 deptNewId）。
  - 自動創建用戶預設密碼是硬編碼 "123456"。
  - getDefaultRoleIds() 後半段是硬編碼 admin=1 / user=2 / 
  common=3，註解寫「不推薦用於生產」但現在就在那裡。
  - getUserPermissions() 整段也是硬編碼 HashMap 兜底，未接真實權限服務。

  2.4 OAuth2 Token 體系（system/service/oauth2）

  雖然掛着 OAuth2 的名字，但這裡不是完整 OAuth2 授權伺服器，只是 token 管理器：

  ┌──────────────────────┬───────────────────────────────────────────────────┐
  │         類別         │                       儲存                        │
  ├──────────────────────┼───────────────────────────────────────────────────┤
  │ OAuth2AccessTokenDO  │ OAuth2AccessTokenMapper (DB) +                    │
  │                      │ OAuth2AccessTokenRedisDAO (Redis 快取)            │
  ├──────────────────────┼───────────────────────────────────────────────────┤
  │ OAuth2RefreshTokenDO │ 只有 DB                                           │
  ├──────────────────────┼───────────────────────────────────────────────────┤
  │ Token 值             │ IdUtil.fastSimpleUUID() — 非                      │
  │                      │ JWT，不自包含，完全依賴後端查詢驗證               │
  ├──────────────────────┼───────────────────────────────────────────────────┤
  │                      │ pap.security.ums.saml2.token-expire-hours（名字寫 │
  │ 過期                 │  hours，實際被當 seconds                          │
  │                      │ 用——plusSeconds(tokenValiditySeconds)，dev 裡配的 │
  │                      │  5400 結果是 90 分鐘而不是 5400 小時）            │
  └──────────────────────┴───────────────────────────────────────────────────┘

  關鍵方法：
  - createAccessToken(userId, userType, clientId, scopes)：先建 refresh，再建
  access，綁在一起。
  - checkAccessToken()：查不到/過期拋 UNAUTHORIZED。
  - refreshAccessToken()：用 refresh token 換新的 access，刪掉舊 access。
  - removeAccessToken()：登出時調用，DB + Redis 雙清。

  ⚠️ OAuth2ClientService 整塊被註釋掉了 (validOAuthClientFromCache)，現在所有
  token 都硬用常量 OAuth2ClientConstants.CLIENT_ID_DEFAULT，沒做 client 校驗。

  2.5 授權（權限校驗）

  所有業務 Controller 用 Spring EL 方法級授權：

  @PreAuthorize("@ss.hasPermission('buy:list:update')")

  @ss 就是 SecurityFrameworkServiceImpl（YudaoSecurityAutoConfiguration 註冊
  Bean 名 "ss"）。實現在 PermissionServiceImpl：

  - hasAnyPermissions(userId, perms...)：
    a. 取用戶啟用中的角色（Redis 快取，USER_ROLE_ID_LIST）
    b. menuService.getMenuIdListByPermissionFromCache(permission) 把 permission
  字串倒查到 menu id
    c. getMenuRoleIdListByMenuIdFromCache(menuId) 取擁有該 menu 的 role id
    d. 用戶角色 ∩ 菜單角色 非空 → 放行
    e. 超管（roleService.hasAnySuperAdmin）繞過
  - hasAnyRoles()：直接比 role code
  - hasScope()：比 token 裡的 scopes（OAuth2 作用域）

  三份數據由 @Cacheable + @CacheEvict 全部打在 Redis 上，配
  spring.cache.redis.time-to-live: 1h。權限變更（assignRoleMenu / assignUserRole
   / processRoleDeleted）有 allEntries=true 的清快取動作。

  另外還有一個 skipPermissionCheck() 後門：只要 LoginUser.visitTenantId != 
  tenantId（跨租戶訪問）就直接放行所有權限和數據權限。這個語義要記住，改權限時不
  要被它絆倒。

  2.6 異常回應

  - 未登錄（AuthenticationException）→ AuthenticationEntryPointImpl → 回 HTTP
  200 + CommonResult.error(UNAUTHORIZED)（401 業務碼）
  - 權限不足（AccessDeniedException）→ AccessDeniedHandlerImpl →
  CommonResult.error(FORBIDDEN)（403）

  前端就是按 code === 401 做 refresh token / 重新登錄判斷。

  ---
  三、前端：兩段式流程

  3.1 Token 儲存

  src/utils/auth.ts：wsCache (web-storage-cache) 放在 localStorage：
  - ACCESS_TOKEN / REFRESH_TOKEN
  - setSamlToken(token)：SAML 回調只帶一個 token 時，access 和 refresh
  存同一個值（所以 SAML 用戶其實沒有真正的 refresh token，refresh 一定會失敗 →
  直接登出）
  - formatToken() = 'Bearer ' + token

  3.2 入口判斷（src/views/Login/Login.vue + src/permission.ts）

  - VITE_SSO_ONLY=true：強制跳 VITE_SSO_URL（/saml2/authenticate/adfs）
  - VITE_SSO_ONLY=false：顯示帳密登錄表單（用 /system/auth/login）
  - /login?forceLocal=1：後門，即使 SSO only 模式也可以走本地登錄
  - SAML 回調：後端 302 帶 ?token=xxx 回前端，router.beforeEach 捕獲
  to.query.token → setSamlToken() → 放行到首頁

  3.3 路由守衛（src/permission.ts）

  進入任意路由
   ├── 檢查 VITE_SYSTEM_MAINTENANCE / VITE_COMING_SOON → /coming-soon
   ├── URL 帶 token → setSamlToken
   ├── 已有 accessToken
   │    ├── 去 /login → 重定向 /
   │    └── 否則 → setUserInfoAction() + generateRoutes() + addRoute()
   └── 無 token
        ├── 在白名單 → 放行
        └── 否則 → /login?redirect=...

  setUserInfoAction 打 GET /system/auth/get-permission-info，後端返回 {user, 
  roles[], permissions[], menus[]}。permissions 存進 Pinia
  useUserStore.permissions: Set<string>，menus 存
  wsCache.ROLE_ROUTERS，usePermissionStore.generateRoutes()
  基於後端菜單動態組裝前端路由。

  3.4 Axios 攔截 + 自動刷新（src/config/axios/service.ts）

  - 請求：非白名單路徑自動加 Authorization: Bearer <token> 和
  tenant-id、visit-tenant-id
  - 響應 code === 401：
    a. 第一個 401 觸發 refreshToken()（POST
  /system/auth/refresh-token?refreshToken=...）
    b. 刷新期間其他請求排隊，成功後重放，失敗則 handleAuthorized() 彈窗 → 清
  token → 回登錄頁
    c. SAML 用戶 refresh 會失敗（因為 access==refresh），會走登出流程

  3.5 按鈕級授權（src/directives/permission/hasPermi.ts）

  <el-button v-hasPermi="['buy:list:update']">...</el-button>

  邏輯：userStore.permissions.has('*:*:*') 或 permission 陣列任一命中 →
  保留元素；否則 el.parentNode.removeChild(el)。另有 v-hasRole 姐妹指令。

  3.6 登出

  useUserStore.loginOut()：
  - SSO Only 模式：構造一個隱藏表單 POST 到
  /admin-api/system/auth/saml2/logout（後端返回自動提交 HTML 再 POST 到
  /logout/saml2/slo/PAP，觸發 IdP 級別 SLO）
  - 本地模式：POST /system/auth/logout → 後端刪 Redis + DB 的 token → 本地清
  token

  ---
  四、重點風險 / 可疑點

  按嚴重性排：

  1. AdminAuthServiceImpl.authenticate() 的密碼校驗整塊被註釋掉（第 77–80
  行），現在本地登錄只要用戶存在就放行。/system/auth/loginSso 更誇張，直接
  @GetMapping 接 ?userName=xxx 也能換 token。兩者在生產 profile
  下都絕對不能開放。
  2. SAML2 的 saml2Login() 
  全塊註釋掉，successHandler、RelyingPartyRegistrationRepository 也沒裝——目前
  SAML 回調怎麼實際走通需要核實，很可能依賴 Spring Security
  的自動配置，但那樣就不會走自定義的
  SAMLUserDetailsServiceImpl.getToken()，token 無法下發。
  3. Mock 登錄後門 yudao.security.mock-enable=true 在 dev profile 開着，密鑰預設
   "test"。任何知道這個的人可以用 Authorization: Bearer test123 直接變成
  userId=123。
  4. token-expire-hours 配成 5400 但實際被 plusSeconds 用 → 真實有效期 90
  分鐘，和配置名誤導不符。
  5. SAML 自動建用戶密碼硬編碼 "123456"，且 createUserFromSaml 裡
  UserPostDO.setUserId(deptNewId) 是 bug。
  6. permitAllUrls 硬編碼到框架類（/api/pvb1/**、/admin-api/Audit/**、多個
  export 接口都免認證），這些是真正「對外裸奔」的業務接口，改需要動
  pap-framework 源碼。
  7. Token 不是 JWT，每次請求都要命中 Redis（或 
  DB），高併發下是瓶頸；好處是可以單純刪庫下線 token。
  8. 超管 + skipPermissionCheck 兩個繞過點要記住，做審計時別忽略。

  ---
  需要我再深入某一塊（例如把 SAML
  實際能跑通的路徑摸清楚，或把權限緩存的一致性邏輯畫出來），告訴我就行。

✻ Worked for 5m 41s