

> 你帮我看看当前项目的权限控制是如何实现的，先给我总结一个宏观架构实现，如果有详情问题我会后续继续问你 

● 我来帮你分析项目的权限控制实现架构。让我先探索相关的代码。

● Explore(Explore permission control architecture)
  ⎿  Done (41 tool uses · 61.5k tokens · 9m 30s)                                                                   

● 好的,我已经完成了对项目权限控制架构的探索分析。下面给你一个宏观架构总结:

  PAP 权限控制架构总览

  一、整体设计模式

  项目采用 RBAC (基于角色的访问控制) 模型,结合 Spring Security + JWT 实现,具备以下特点:
  - 用户-角色-菜单(权限)的三层关联模型
  - 基于注解的声明式权限控制
  - 多级缓存优化性能
  - 支持数据权限(部门范围)
  - 多租户隔离

  ---
  二、核心组件架构

  ┌─────────────────────────────────────────────────────────────┐
  │                     HTTP Request                             │
  └────────────────────────┬────────────────────────────────────┘
                           │
                           ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  TokenAuthenticationFilter (JWT 令牌验证)                    │
  │  文件位置: pap-framework/.../TokenAuthenticationFilter.java  │
  │  职责: 解析 JWT → 构建 LoginUser → 设置 SecurityContext     │
  └────────────────────────┬────────────────────────────────────┘
                           │
                           ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  Controller Method                                           │
  │  @PreAuthorize("@ss.hasPermission('bpm:category:create')")│
  └────────────────────────┬────────────────────────────────────┘
                           │
                           ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  SecurityFrameworkServiceImpl (@Bean("ss"))                  │
  │  文件位置: pap-framework/.../SecurityFrameworkServiceImpl.java│
  │  核心方法: hasPermission(String permission)                  │
  └────────────────────────┬────────────────────────────────────┘
                           │
                           ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  PermissionServiceImpl (权限校验核心)                        │
  │  文件位置: pap-server/.../PermissionServiceImpl.java         │
  │  流程:                                                       │
  │  1. 获取用户角色列表 (带缓存)                                │
  │  2. 根据权限字符串查询菜单 ID (带缓存)                       │
  │  3. 检查角色是否拥有菜单权限 (带缓存)                        │
  │  4. 超级管理员自动通过                                       │
  └─────────────────────────────────────────────────────────────┘

  ---
  三、数据模型 (RBAC 关系)

  system_users (AdminUserDO)                system_menu (MenuDO)
       │                                          │
       │ 用户ID                                   │ 菜单ID
       │                                          │ permission: "bpm:category:create"
       └────┬─────────────────────┬──────────────┘
            │                     │
            ▼                     ▼
    system_user_role       system_role_menu
    (UserRoleDO)           (RoleMenuDO)
        userId                 roleId
        roleId                 menuId
            │                     │
            └────────┬────────────┘
                     ▼
              system_role (RoleDO)
                 roleId
                 code (角色编码)
                 dataScope (数据权限范围)
                 dataScopeDeptIds (自定义部门范围)

  关键表:
  - system_users: 用户表
  - system_role: 角色表 (含数据权限配置)
  - system_menu: 菜单/权限表 (permission 字段存储权限字符串)
  - system_user_role: 用户-角色关联
  - system_role_menu: 角色-菜单关联

  ---
  四、权限校验流程

  典型请求的权限检查链路:

  1. 请求携带 JWT Token
     ↓
  2. TokenAuthenticationFilter 拦截
     - 验证 token 有效性
     - 从 token 解析出 userId, tenantId
     - 构建 LoginUser 对象
     - 放入 SecurityContextHolder
     ↓
  3. Spring Security 拦截器链
     ↓
  4. 方法级拦截: @PreAuthorize("@ss.hasPermission('bpm:category:create')")
     ↓
  5. SecurityFrameworkServiceImpl.hasPermission()
     - 从 SecurityContext 获取当前用户 ID
     - 调用 PermissionApi.hasAnyPermissions(userId, permissions)
     ↓
  6. PermissionServiceImpl.hasAnyPermissions()
     ├─ 查询用户的角色列表 (Redis 缓存)
     ├─ 检查是否超级管理员 → 是则直接通过
     ├─ 根据 permission 字符串查询对应的 menuIds (Redis 缓存)
     ├─ 检查用户的角色是否拥有这些 menu 的权限 (Redis 缓存)
     └─ 返回 true/false
     ↓
  7. 通过 → 执行业务方法
     拒绝 → 抛出 AccessDeniedException → 返回 403

  ---
  五、缓存策略 (性能优化关键)

  Redis 缓存键设计:

  | 缓存项    | Redis Key                        | 缓存内容            | 失效时机      |
  |--------|----------------------------------|-----------------|-----------|
  | 用户角色   | user_role_ids:{userId}           | 用户的角色 ID 列表     | 用户角色变更/删除 |
  | 菜单角色   | menu_role_ids:{menuId}           | 可访问该菜单的角色 ID 列表 | 角色菜单变更/删除 |
  | 权限菜单映射 | permission_menu_ids:{permission} | 权限字符串对应的菜单 ID   | 菜单增删改     |
  | 角色信息   | role:{roleId}                    | 角色完整信息          | 角色更新      |

  缓存注解:
  - @Cacheable: 自动从 Redis 读取
  - @CacheEvict: 修改时自动失效
  - 使用 Spring Cache 抽象层

  ---
  六、关键实现类及位置

  | 职责          | 类名                                | 文件路径
        |
  |-------------|-----------------------------------|-------------------------------------------------------------|
  | 权限校验入口      | SecurityFrameworkServiceImpl      | pap-framework/.../SecurityFrameworkServiceImpl.java:61
      |
  | 权限业务逻辑      | PermissionServiceImpl             | pap-server/.../PermissionServiceImpl.java:71
      |
  | JWT 过滤器     | TokenAuthenticationFilter         | pap-framework/.../TokenAuthenticationFilter.java:66
   |
  | Security 配置 | YudaoWebSecurityConfigurerAdapter | pap-framework/.../YudaoWebSecurityConfigurerAdapter.java:71
  |
  | 菜单服务        | MenuServiceImpl                   | pap-server/.../MenuServiceImpl.java
    |
  | 角色服务        | RoleServiceImpl                   | pap-server/.../RoleServiceImpl.java
    |
  | 上下文工具       | SecurityFrameworkUtils            | pap-framework/.../SecurityFrameworkUtils.java:23
     |

  ---
  七、特殊功能

  1. 超级管理员绕过: 拥有 super_admin 角色码的用户自动拥有所有权限
  2. 数据权限: 通过 RoleDO.dataScope 控制可见数据范围(全部/本部门/本部门及子部门/仅本人)
  3. 多租户隔离: 跨租户访问时自动跳过权限检查
  4. SAML2 SSO: 支持企业单点登录集成

  ---
  这就是 PAP 项目权限控制的宏观架构。如果你需要了解某个具体模块的实现细节(比如数据权限如何工作、缓存失效机制、或某个
  具体类的代码逻辑),随时告诉我!





