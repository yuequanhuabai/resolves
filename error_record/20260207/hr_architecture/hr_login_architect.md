# 登录模块宏观架构

## 零、最底层地基：Servlet 过滤器链

在讲 Spring Security 之前，必须先理解它站在什么上面。

### HTTP 请求的必经之路

Java Web 应用运行在 **Servlet 容器**（如 Tomcat）中。容器对每一个 HTTP 请求的处理模型是：

```
HTTP 请求
    │
    ▼
┌─────────────────────────────────────────────┐
│            Servlet 容器（Tomcat）             │
│                                             │
│   Filter1 → Filter2 → Filter3 → ...        │  ← 过滤器链（Filter Chain）
│                                    │        │
│                                    ▼        │
│                            DispatcherServlet │  ← Spring MVC 的唯一 Servlet
│                                    │        │
│                               Controller    │
└─────────────────────────────────────────────┘
```

- **Filter（过滤器）** 是 Servlet 规范定义的接口，比 Servlet 先执行，可以拦截、修改、放行请求
- **每个 Filter 决定是否调用 `chain.doFilter()`**：调用则放行给下一个 Filter，不调用则请求就此终止（如 401 直接返回）
- **DispatcherServlet** 是终点，只有通过所有 Filter 的请求才能到达 Controller

### Spring Security 如何挂载到过滤器链

Spring Security 不是独立运行的，它通过两层桥接嵌入 Servlet 体系：

```
Servlet 容器的原生过滤器链
    │
    ▼
DelegatingFilterProxy           ← Servlet 规范的标准 Filter
（Spring 注册进容器的"代理人"）    只做一件事：把请求委托给 Spring 容器中的 Bean
    │
    ▼
FilterChainProxy                ← Spring Security 的核心 Bean
（Spring Security 的"总调度"）    持有一个或多个 SecurityFilterChain
    │
    ▼
SecurityFilterChain             ← 本项目实际配置的那条安全过滤链
    │
    ├── JwtAuthenticationFilter      （自定义：解析 JWT，建立身份）
    ├── UsernamePasswordAuthFilter   （Spring 内置：表单登录，本项目禁用）
    ├── ExceptionTranslationFilter   （Spring 内置：捕获 401/403，返回 JSON）
    └── AuthorizationFilter          （Spring 内置：最终授权检查）
```

**关键结论：Spring Security 的认证和授权，本质上都是 Filter 里的逻辑。** 请求在进入 Controller 之前，就已经在过滤器链中完成了"你是谁"和"你有没有权限"的判断。

### 本项目中两个关键 Filter 的职责

| Filter | 职责 | 在链中的位置 |
|---|---|---|
| **JwtAuthenticationFilter** | 解析 JWT → 查 Redis → 写入 SecurityContextHolder（认证） | `UsernamePasswordAuthenticationFilter` 之前 |
| **AuthorizationFilter** | 读取 SecurityContextHolder → 对比请求路径所需权限（授权） | 链的末尾，Controller 之前 |

认证（你是谁）先于授权（你能做什么），这是过滤器链的顺序保证的。

---

## 一、地基（核心基础设施）

登录模块建立在以下基础设施之上：

| 层次 | 技术 | 作用 |
|---|---|---|
| **运行底座** | Servlet 过滤器链 | 所有 HTTP 请求的必经之路，Spring Security 挂载于此 |
| **安全框架** | Spring Security（FilterChainProxy） | 在 Servlet 层统一处理认证与授权 |
| **身份令牌** | JWT + Redis 双层架构 | JWT 是轻量引用（只存 UUID），Redis 存真实用户数据 |
| **前端路由守卫** | Vue Router `beforeEach` | 前端所有页面访问的统一入口检查 |

整个系统的认证哲学：**后端过滤器链负责"你是谁 + 有没有权限"，前端路由守卫负责"你能去哪个页面"**。

---

## 二、后端登录架构

### 骨架流程

```
客户端 POST /api/login
    │
    ▼
AuthController          ← 入口，接收 username/password
    │
    ▼
LoginService            ← 驱动整个认证过程
    │
    ├─→ AuthenticationManager (Spring Security)
    │       └─→ UserDetailsServiceImpl  ← 从数据库加载用户 + 权限 + 角色
    │               ↓ 返回 LoginUser（UserDetails 实现）
    │       └─→ BCrypt 校验密码
    │
    └─→ TokenService.createToken(LoginUser)
            ├─ 生成 UUID 作为 tokenKey
            ├─ 将完整 LoginUser 存入 Redis（key: login_token:{tokenKey}, TTL: 30min）
            └─ 签发 JWT（载荷只含 tokenKey）
                        ↓
                    返回 JWT 给客户端
```

### 每次请求的守卫

```
任意请求
    │
    ▼
JwtAuthenticationFilter（Spring Security 过滤链中）
    ├─ 从 Header 取 Bearer Token → 解析 JWT → 得到 tokenKey
    ├─ 用 tokenKey 从 Redis 取 LoginUser
    ├─ 剩余 TTL < 20min → 自动续期至 30min（滑动过期）
    └─ 将 LoginUser 写入 SecurityContextHolder
                        ↓
    后续业务代码通过 @PreAuthorize 做细粒度权限控制
```

### 地基组件

- **SecurityConfig** — Spring Security 6 无状态配置：禁用 Session/CSRF/表单登录，自定义 401/403 JSON 响应，白名单路由放行
- **TokenService** — 双层令牌管理：JWT 做无状态引用，Redis 做有状态存储，logout 只需删 Redis key 即刻失效
- **LoginUser** — 贯穿整个后端的用户上下文载体，包含 userId、deptId、permissions、roles

---

## 三、前端登录架构

### 骨架流程

```
用户填写表单 → views/login/index.vue
    │
    ▼
userStore.login()           ← Pinia store 驱动
    ├─ 调用 authApi.login()（Axios）
    └─ 收到 JWT → 存入 localStorage
                        ↓
router/permission.ts（全局 beforeEach 路由守卫）
    │
    ├─ 无 Token → 重定向 /login
    │
    └─ 有 Token → 路由未初始化？
            ├─ userStore.getInfo()      ← 获取用户信息 + 权限
            ├─ getRouters()             ← 获取后端菜单树
            ├─ generateRoutes(menus)    ← 菜单树 → RouteRecordRaw[]
            └─ router.addRoute()        ← 动态注入路由
                            ↓
                    进入目标页面
```

### 每次请求的守卫

```
任意 Axios 请求
    │
    ▼
request.ts 请求拦截器 → 从 localStorage 取 Token → 附加 Authorization: Bearer {token}

响应拦截器
    ├─ code 200 → 透传业务数据
    └─ code 401 → 清除 Token → 重定向 /login?redirect={原路径}
```

### 地基组件

- **useUserStore** — 用户身份中心：token、userInfo、roles、permissions 的单一数据源
- **usePermissionStore** — 路由权限中心：持有动态路由列表和"是否已生成"标志位（routesGenerated）
- **request.ts** — 全局 Axios 实例：统一注入 Token、统一处理 401

---

## 四、前后端协作地图

```
前端                                    后端
────────────────────────────────────────────────────────
POST /api/login ──────────────────────→ 验证 → 生成 JWT+Redis
                ←────────────────────── 返回 JWT

GET /api/getInfo ─────────────────────→ 从 Redis 取 LoginUser → 返回用户信息
GET /api/getRouters ──────────────────→ 按用户权限查菜单树 → 返回树形结构

每次请求 Authorization: Bearer JWT ──→ Filter 解析 → Redis 查用户 → 鉴权

POST /api/logout ─────────────────────→ 删除 Redis key（JWT 立即失效）
                ←────────────────────── 200 OK
前端清除 localStorage + 重置 Store
```

---

## 五、核心设计决策（地基的哲学）

| 决策 | 选择 | 原因 |
|---|---|---|
| **令牌形态** | JWT 引用 + Redis 数据 | JWT 纯无状态则无法主动注销；纯 Session 则无法水平扩展 |
| **过期策略** | Redis 滑动过期（20min 阈值） | 活跃用户无感续期，闲置用户自动下线 |
| **权限粒度** | 字符串权限码（如 `sys:user:list`） | 细粒度到按钮级，前后端均可用同一套权限码做控制 |
| **路由策略** | 后端下发菜单树，前端动态生成路由 | 菜单/权限集中在后端管理，前端无硬编码路由 |
| **注销机制** | 删 Redis key | 无需等 JWT 自然过期，即刻失效，安全性高 |
