# PAP 系统登录架构

## 整体流程

```
前端 LoginForm ──POST /system/auth/login──> AuthController ──> AdminAuthService
                                                                     │
                                                               authenticate()
                                                            (用户名查库 + 状态校验)
                                                                     │
                                                             OAuth2TokenService
                                                          (生成 accessToken + refreshToken)
                                                                     │
                                                        ┌────────────┴────────────┐
                                                      MySQL                     Redis
                                                  (持久化令牌)              (缓存令牌)
```

## 两种登录方式

| 方式 | 入口 | 说明 |
|------|------|------|
| **账号密码登录** | `POST /system/auth/login` | 前端表单提交 username + password |
| **SAML2 SSO** | Spring Security SAML2 Filter | IdP 认证成功后回调，`SAMLUserDetailsService` 生成 token，重定向前端携带 `?token=xxx` |

## 后端核心链路

### Security Filter Chain

```
请求 → TokenAuthenticationFilter → Spring Security → Controller
         │
         ├─ 从 Header (Authorization: Bearer xxx) 或 Parameter 提取 token
         ├─ oauth2TokenApi.checkAccessToken(token)  // Redis 优先，fallback MySQL
         ├─ 构建 LoginUser 设入 SecurityContext
         └─ @PermitAll 接口跳过认证，其余 anyRequest().authenticated()
```

### 令牌体系

- **AccessToken**: UUID，存 MySQL + Redis（带 TTL）
- **RefreshToken**: UUID，仅存 MySQL
- 过期时间由 `pap.security.sso.saml.token-expire-hours` 配置
- 密码校验：**当前已注释**（`isPasswordMatch` 被注释），仅校验用户名存在 + 未禁用
- 验证码：**当前已关闭**（`captchaEnable=false`，校验逻辑已注释）

### 关键类

| 类 | 位置 | 职责 |
|----|------|------|
| `AuthController` | `server/system/controller/admin/auth/` | 登录/登出/刷新令牌/获取权限 API |
| `AdminAuthServiceImpl` | `server/system/service/auth/` | 认证逻辑、登录日志记录 |
| `OAuth2TokenServiceImpl` | `server/system/service/oauth2/` | 令牌 CRUD (access + refresh) |
| `OAuth2AccessTokenRedisDAO` | `server/system/dal/redis/oauth2/` | Redis 令牌缓存 |
| `TokenAuthenticationFilter` | `framework/common/security/` | 请求级 Token 校验过滤器 |
| `YudaoWebSecurityConfigurerAdapter` | `framework/common/security/` | Security 配置 + SAML2 配置 |
| `SecurityFrameworkUtils` | `framework/common/security/` | Token 提取、LoginUser 上下文操作 |

## 前端核心链路

### 登录流程

```
LoginForm.vue
  │
  ├─ LoginApi.login({ username, password }) ──> POST /system/auth/login
  ├─ authUtil.setToken(res)                 ──> wsCache 存储 ACCESS_TOKEN / REFRESH_TOKEN
  ├─ rememberMe → authUtil.setLoginForm()   ──> 密码加密后存 wsCache (30天)
  └─ router.push(redirect || '/')
```

### 路由守卫 (permission.ts)

```
router.beforeEach
  │
  ├─ URL 含 ?token=xxx → setSamlToken() (SAML SSO 回调场景)
  ├─ 有 accessToken？
  │    ├─ 目标是 /login → 重定向 /
  │    └─ 否则：加载字典 → 加载用户信息(getInfo) → 生成动态路由 → next
  └─ 无 accessToken？
       ├─ 白名单 (/login, /register...) → 放行
       └─ 其他 → 重定向 /login?redirect=xxx
```

### Token 无感刷新 (axios/service.ts)

```
响应 401
  │
  ├─ 有 refreshToken → POST /system/auth/refresh-token
  │    ├─ 成功 → setToken() + 回放请求队列 + 重发当前请求
  │    └─ 失败 → 弹窗提示 → 清除 token → 跳转登录页
  └─ 无 refreshToken → 直接登出

  并发请求期间：后续 401 请求加入队列等待刷新完成
```

### 关键文件

| 文件 | 职责 |
|------|------|
| `views/Login/components/LoginForm.vue` | 登录表单 UI + 登录逻辑 |
| `api/login/index.ts` | 登录相关 API 封装 |
| `utils/auth.ts` | Token 存取 (wsCache)、记住密码 |
| `permission.ts` | 全局路由守卫 |
| `config/axios/service.ts` | Axios 拦截器、401 刷新令牌 |
| `store/modules/user.ts` | 用户信息 Pinia Store |

## 数据存储

| 数据 | 存储位置 | 说明 |
|------|---------|------|
| AccessToken | MySQL `oauth2_access_token` + Redis | Redis 带 TTL 自动过期 |
| RefreshToken | MySQL `oauth2_refresh_token` | 仅数据库持久化 |
| 前端 Token | wsCache (sessionStorage) | ACCESS_TOKEN / REFRESH_TOKEN |
| 记住密码 | wsCache | RSA 加密密码，30天过期 |
| 登录日志 | MySQL | LoginLogService 记录 |
