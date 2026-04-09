# 後端架構文檔 — Spring Boot

## 一、項目結構

### 1.1 Maven 多模塊結構

```
hr-backend/
├── pom.xml                              # 父 POM
│
├── hr-common/                           # 公共模塊
│   ├── pom.xml
│   └── src/main/java/com/hr/common/
│       ├── core/
│       │   ├── domain/
│       │   │   └── BaseEntity.java          # 基礎實體 (id, createBy, createTime, updateBy, updateTime, deleted)
│       │   ├── result/
│       │   │   ├── R.java                   # 統一響應體 R<T>
│       │   │   └── PageResult.java          # 分頁響應體
│       │   ├── page/
│       │   │   └── PageQuery.java           # 分頁請求參數
│       │   └── exception/
│       │       ├── BusinessException.java   # 業務異常
│       │       └── GlobalExceptionHandler.java
│       ├── constant/
│       │   ├── HttpStatus.java              # HTTP 狀態碼常量
│       │   └── Constants.java               # 系統常量
│       ├── enums/
│       │   ├── StatusEnum.java              # 啟用/停用
│       │   ├── GenderEnum.java              # 性別
│       │   ├── MenuTypeEnum.java            # 菜單類型 (M/C/F)
│       │   └── DataScopeEnum.java           # 數據權限範圍
│       ├── utils/
│       │   ├── StringUtils.java
│       │   ├── DateUtils.java
│       │   ├── TreeUtils.java               # 樹形結構構建工具
│       │   └── SecurityUtils.java           # 獲取當前登入用戶
│       └── annotation/
│           ├── DataScope.java               # 數據權限註解
│           └── Log.java                     # 操作日誌註解
│
├── hr-framework/                        # 框架模塊
│   ├── pom.xml
│   └── src/main/java/com/hr/framework/
│       ├── security/
│       │   ├── config/
│       │   │   └── SecurityConfig.java      # Spring Security 配置
│       │   ├── filter/
│       │   │   └── JwtAuthenticationFilter.java  # JWT 過濾器
│       │   ├── handler/
│       │   │   ├── AuthenticationEntryPointImpl.java   # 401 處理
│       │   │   └── AccessDeniedHandlerImpl.java        # 403 處理
│       │   ├── service/
│       │   │   ├── TokenService.java        # Token 生成/解析/刷新
│       │   │   ├── LoginService.java        # 登入邏輯
│       │   │   ├── PermissionService.java   # 權限校驗 (@perm.hasPerms)
│       │   │   └── UserDetailsServiceImpl.java  # 用戶認證加載
│       │   └── model/
│       │       └── LoginUser.java           # 登入用戶信息 (含權限集合)
│       ├── interceptor/
│       │   └── DataScopeInterceptor.java    # MyBatis 數據權限攔截器
│       ├── aspect/
│       │   └── LogAspect.java               # 操作日誌切面
│       ├── config/
│       │   ├── MybatisPlusConfig.java       # MP 配置 (分頁插件等)
│       │   ├── RedisConfig.java             # Redis 序列化配置
│       │   └── CorsConfig.java              # 跨域配置
│       └── redis/
│           └── RedisCache.java              # Redis 操作封裝
│
├── hr-system/                           # 業務模塊
│   ├── pom.xml
│   └── src/main/java/com/hr/system/
│       ├── domain/                          # 實體
│       │   ├── SysUser.java
│       │   ├── SysRole.java
│       │   ├── SysDept.java
│       │   ├── SysPost.java
│       │   ├── SysMenu.java
│       │   ├── SysUserRole.java             # 用戶-角色關聯
│       │   ├── SysRoleMenu.java             # 角色-菜單關聯
│       │   └── SysRoleDept.java             # 角色-部門關聯
│       ├── mapper/                          # Mapper 接口
│       │   ├── SysUserMapper.java
│       │   ├── SysRoleMapper.java
│       │   ├── SysDeptMapper.java
│       │   ├── SysPostMapper.java
│       │   ├── SysMenuMapper.java
│       │   ├── SysUserRoleMapper.java
│       │   ├── SysRoleMenuMapper.java
│       │   └── SysRoleDeptMapper.java
│       ├── service/                         # 業務接口
│       │   ├── ISysUserService.java
│       │   ├── ISysRoleService.java
│       │   ├── ISysDeptService.java
│       │   ├── ISysPostService.java
│       │   └── ISysMenuService.java
│       ├── service/impl/                    # 業務實現
│       │   ├── SysUserServiceImpl.java
│       │   ├── SysRoleServiceImpl.java
│       │   ├── SysDeptServiceImpl.java
│       │   ├── SysPostServiceImpl.java
│       │   └── SysMenuServiceImpl.java
│       └── dto/                             # 數據傳輸對象
│           ├── SysUserDTO.java              # 用戶新增/修改
│           ├── SysUserQuery.java            # 用戶查詢條件
│           ├── SysRoleDTO.java
│           └── SysUserInfoVO.java           # 用戶詳情 (含角色、崗位)
│
└── hr-admin/                            # 啟動模塊
    ├── pom.xml
    └── src/
        ├── main/
        │   ├── java/com/hr/admin/
        │   │   ├── HrApplication.java       # 啟動類
        │   │   └── controller/
        │   │       ├── auth/
        │   │       │   └── AuthController.java      # 登入/登出/用戶信息
        │   │       ├── system/
        │   │       │   ├── SysUserController.java
        │   │       │   ├── SysRoleController.java
        │   │       │   ├── SysDeptController.java
        │   │       │   ├── SysPostController.java
        │   │       │   └── SysMenuController.java
        │   │       └── internal/
        │   │           └── InternalApiController.java  # 內部接口 (供未來微服務調用)
        │   └── resources/
        │       ├── application.yml
        │       ├── application-dev.yml      # 開發環境配置
        │       ├── application-prod.yml     # 生產環境配置
        │       └── mapper/                  # MyBatis XML
        │           ├── SysUserMapper.xml
        │           ├── SysRoleMapper.xml
        │           ├── SysDeptMapper.xml
        │           ├── SysPostMapper.xml
        │           └── SysMenuMapper.xml
        └── test/
            └── java/com/hr/admin/           # 測試類

```

### 1.2 模塊依賴關係

```
hr-admin
  └── hr-system
        └── hr-framework
              └── hr-common
```

### 1.3 包名規範

```
基礎包名: com.hr
公共模塊: com.hr.common.*
框架模塊: com.hr.framework.*
業務模塊: com.hr.system.*
啟動模塊: com.hr.admin.*
```

---

## 二、數據庫設計 (SQL Server)

### 2.1 用戶表 sys_user

```sql
CREATE TABLE sys_user (
    user_id       BIGINT        IDENTITY(1,1) PRIMARY KEY,
    dept_id       BIGINT        NULL,
    post_id       BIGINT        NULL,
    username      NVARCHAR(50)  NOT NULL,
    password      NVARCHAR(200) NOT NULL,
    nickname      NVARCHAR(50)  NOT NULL,
    email         NVARCHAR(100) NULL,
    phone         NVARCHAR(20)  NULL,
    gender        TINYINT       DEFAULT 0,        -- 0未知 1男 2女
    avatar        NVARCHAR(500) NULL,
    status        TINYINT       DEFAULT 0,        -- 0正常 1停用
    login_ip      NVARCHAR(50)  NULL,
    login_time    DATETIME2     NULL,
    remark        NVARCHAR(500) NULL,
    create_by     NVARCHAR(50)  NULL,
    create_time   DATETIME2     DEFAULT GETDATE(),
    update_by     NVARCHAR(50)  NULL,
    update_time   DATETIME2     NULL,
    deleted       TINYINT       DEFAULT 0,        -- 0未刪 1已刪

    CONSTRAINT uk_username UNIQUE (username)
);
```

### 2.2 部門表 sys_dept

```sql
CREATE TABLE sys_dept (
    dept_id       BIGINT        IDENTITY(1,1) PRIMARY KEY,
    parent_id     BIGINT        DEFAULT 0,        -- 0 表示頂級
    dept_name     NVARCHAR(100) NOT NULL,
    ancestors     NVARCHAR(500) NULL,              -- 祖級列表 "0,1,5"
    leader        NVARCHAR(50)  NULL,
    phone         NVARCHAR(20)  NULL,
    email         NVARCHAR(100) NULL,
    order_num     INT           DEFAULT 0,
    status        TINYINT       DEFAULT 0,
    create_by     NVARCHAR(50)  NULL,
    create_time   DATETIME2     DEFAULT GETDATE(),
    update_by     NVARCHAR(50)  NULL,
    update_time   DATETIME2     NULL,
    deleted       TINYINT       DEFAULT 0
);
```

### 2.3 崗位表 sys_post

```sql
CREATE TABLE sys_post (
    post_id       BIGINT        IDENTITY(1,1) PRIMARY KEY,
    post_code     NVARCHAR(50)  NOT NULL,
    post_name     NVARCHAR(100) NOT NULL,
    order_num     INT           DEFAULT 0,
    status        TINYINT       DEFAULT 0,
    remark        NVARCHAR(500) NULL,
    create_by     NVARCHAR(50)  NULL,
    create_time   DATETIME2     DEFAULT GETDATE(),
    update_by     NVARCHAR(50)  NULL,
    update_time   DATETIME2     NULL,
    deleted       TINYINT       DEFAULT 0,

    CONSTRAINT uk_post_code UNIQUE (post_code)
);
```

### 2.4 角色表 sys_role

```sql
CREATE TABLE sys_role (
    role_id       BIGINT        IDENTITY(1,1) PRIMARY KEY,
    role_key      NVARCHAR(50)  NOT NULL,          -- 角色標識 如 "admin"
    role_name     NVARCHAR(100) NOT NULL,
    data_scope    TINYINT       DEFAULT 1,         -- 1全部 2自定義 3本部門 4本部門及以下 5僅本人
    order_num     INT           DEFAULT 0,
    status        TINYINT       DEFAULT 0,
    remark        NVARCHAR(500) NULL,
    create_by     NVARCHAR(50)  NULL,
    create_time   DATETIME2     DEFAULT GETDATE(),
    update_by     NVARCHAR(50)  NULL,
    update_time   DATETIME2     NULL,
    deleted       TINYINT       DEFAULT 0,

    CONSTRAINT uk_role_key UNIQUE (role_key)
);
```

### 2.5 菜單/權限表 sys_menu

```sql
CREATE TABLE sys_menu (
    menu_id       BIGINT        IDENTITY(1,1) PRIMARY KEY,
    parent_id     BIGINT        DEFAULT 0,
    menu_name     NVARCHAR(100) NOT NULL,
    menu_type     CHAR(1)       NOT NULL,          -- M目錄 C菜單 F按鈕
    path          NVARCHAR(200) NULL,              -- 路由地址
    component     NVARCHAR(200) NULL,              -- 前端組件路徑
    perms         NVARCHAR(100) NULL,              -- 權限標識 如 "sys:user:list"
    icon          NVARCHAR(100) NULL,
    order_num     INT           DEFAULT 0,
    visible       TINYINT       DEFAULT 0,         -- 0顯示 1隱藏
    status        TINYINT       DEFAULT 0,
    create_by     NVARCHAR(50)  NULL,
    create_time   DATETIME2     DEFAULT GETDATE(),
    update_by     NVARCHAR(50)  NULL,
    update_time   DATETIME2     NULL
);
```

### 2.6 關聯表

```sql
-- 用戶-角色關聯
CREATE TABLE sys_user_role (
    user_id       BIGINT NOT NULL,
    role_id       BIGINT NOT NULL,
    PRIMARY KEY (user_id, role_id)
);

-- 角色-菜單關聯
CREATE TABLE sys_role_menu (
    role_id       BIGINT NOT NULL,
    menu_id       BIGINT NOT NULL,
    PRIMARY KEY (role_id, menu_id)
);

-- 角色-部門關聯 (數據權限)
CREATE TABLE sys_role_dept (
    role_id       BIGINT NOT NULL,
    dept_id       BIGINT NOT NULL,
    PRIMARY KEY (role_id, dept_id)
);
```

### 2.7 操作日誌表

```sql
CREATE TABLE sys_oper_log (
    oper_id       BIGINT        IDENTITY(1,1) PRIMARY KEY,
    title         NVARCHAR(100) NULL,              -- 模塊標題
    method        NVARCHAR(200) NULL,              -- 方法名
    request_method NVARCHAR(10) NULL,              -- GET/POST/PUT/DELETE
    oper_url      NVARCHAR(500) NULL,
    oper_ip       NVARCHAR(50)  NULL,
    oper_param    NVARCHAR(MAX) NULL,              -- 請求參數
    json_result   NVARCHAR(MAX) NULL,              -- 返回結果
    status        TINYINT       DEFAULT 0,         -- 0成功 1失敗
    error_msg     NVARCHAR(MAX) NULL,
    oper_name     NVARCHAR(50)  NULL,
    oper_time     DATETIME2     DEFAULT GETDATE()
);
```

### 2.8 索引設計

```sql
CREATE INDEX idx_user_dept ON sys_user(dept_id);
CREATE INDEX idx_user_post ON sys_user(post_id);
CREATE INDEX idx_user_status ON sys_user(status, deleted);
CREATE INDEX idx_dept_parent ON sys_dept(parent_id);
CREATE INDEX idx_menu_parent ON sys_menu(parent_id);
CREATE INDEX idx_oper_log_time ON sys_oper_log(oper_time);
```

---

## 三、認證授權設計

### 3.1 JWT Token 方案

```
Token 結構:
  Header: { "alg": "HS256" }
  Payload: { "sub": "uuid", "iat": 時間戳, "exp": 過期時間 }

存儲方案:
  Redis Key:   login_token:{uuid}
  Redis Value: LoginUser 對象 (含 userId, username, deptId, permissions)
  過期時間:    30 分鐘 (每次請求自動刷新)
```

### 3.2 Security 配置要點

```java
// 放行路徑
- POST /api/auth/login          (登入)
- GET  /api/auth/captcha         (驗證碼，可選)
- GET  /doc.html                 (API 文檔)
- /swagger-resources/**

// 需認證路徑
- /api/** (除上述放行路徑外)

// 禁用
- CSRF (前後端分離不需要)
- Session (JWT 無狀態)
```

### 3.3 數據權限攔截器

```
觸發方式: Service 方法加 @DataScope(deptAlias = "d", userAlias = "u") 註解
攔截時機: MyBatis 執行 SQL 前
攔截邏輯:
  1. 獲取當前用戶角色列表
  2. 遍歷角色，取最大數據權限範圍
  3. 根據 data_scope 拼接 SQL WHERE 條件
  4. 注入到原始 SQL
```

---

## 四、分層設計規範

### 4.1 Controller 層

```
職責: 參數校驗、調用 Service、返回統一響應
規範:
  - 使用 @Validated 做參數校驗
  - 使用 @PreAuthorize 做權限校驗
  - 使用 @Log 記錄操作日誌
  - 不包含業務邏輯
  - 統一返回 R<T>
```

### 4.2 Service 層

```
職責: 業務邏輯、事務控制
規範:
  - 接口定義在 hr-system 的 service 包
  - 實現類在 service/impl 包
  - 使用 @Transactional 管理事務
  - 使用 @DataScope 控制數據權限
  - 跨模塊調用通過接口，不直接依賴實現 (為微服務升級預留)
```

### 4.3 Mapper 層

```
職責: 數據訪問
規範:
  - 簡單 CRUD 使用 MyBatis-Plus 內置方法
  - 複雜查詢 (多表關聯、樹形查詢) 寫 XML
  - 不在 Mapper 中寫業務邏輯
```

---

## 五、接口設計

### 5.1 認證接口

| 方法 | 路徑 | 權限 | 說明 |
|------|------|------|------|
| POST | /api/auth/login | 匿名 | 登入，返回 Token |
| POST | /api/auth/logout | 認證 | 登出，清除 Redis |
| GET | /api/auth/info | 認證 | 當前用戶信息 + 角色 + 權限集合 |
| GET | /api/auth/routers | 認證 | 當前用戶動態菜單路由 |

### 5.2 用戶管理

| 方法 | 路徑 | 權限標識 | 說明 |
|------|------|---------|------|
| GET | /api/system/user | sys:user:list | 分頁查詢 |
| GET | /api/system/user/{id} | sys:user:query | 用戶詳情 |
| POST | /api/system/user | sys:user:add | 新增 |
| PUT | /api/system/user | sys:user:edit | 修改 |
| DELETE | /api/system/user/{id} | sys:user:remove | 刪除 |
| PUT | /api/system/user/resetPwd | sys:user:resetPwd | 重置密碼 |
| PUT | /api/system/user/status | sys:user:edit | 修改狀態 |

### 5.3 角色管理

| 方法 | 路徑 | 權限標識 | 說明 |
|------|------|---------|------|
| GET | /api/system/role | sys:role:list | 分頁查詢 |
| GET | /api/system/role/{id} | sys:role:query | 角色詳情 |
| POST | /api/system/role | sys:role:add | 新增 |
| PUT | /api/system/role | sys:role:edit | 修改 |
| DELETE | /api/system/role/{id} | sys:role:remove | 刪除 |
| PUT | /api/system/role/dataScope | sys:role:edit | 修改數據權限 |
| GET | /api/system/role/{id}/users | sys:role:list | 查詢角色下用戶 |

### 5.4 部門管理

| 方法 | 路徑 | 權限標識 | 說明 |
|------|------|---------|------|
| GET | /api/system/dept/tree | sys:dept:list | 部門樹 |
| GET | /api/system/dept/{id} | sys:dept:query | 部門詳情 |
| POST | /api/system/dept | sys:dept:add | 新增 |
| PUT | /api/system/dept | sys:dept:edit | 修改 |
| DELETE | /api/system/dept/{id} | sys:dept:remove | 刪除 |

### 5.5 崗位管理

| 方法 | 路徑 | 權限標識 | 說明 |
|------|------|---------|------|
| GET | /api/system/post | sys:post:list | 分頁查詢 |
| GET | /api/system/post/{id} | sys:post:query | 崗位詳情 |
| POST | /api/system/post | sys:post:add | 新增 |
| PUT | /api/system/post | sys:post:edit | 修改 |
| DELETE | /api/system/post/{id} | sys:post:remove | 刪除 |

### 5.6 菜單管理

| 方法 | 路徑 | 權限標識 | 說明 |
|------|------|---------|------|
| GET | /api/system/menu/tree | sys:menu:list | 菜單樹 |
| GET | /api/system/menu/{id} | sys:menu:query | 菜單詳情 |
| POST | /api/system/menu | sys:menu:add | 新增 |
| PUT | /api/system/menu | sys:menu:edit | 修改 |
| DELETE | /api/system/menu/{id} | sys:menu:remove | 刪除 |
| GET | /api/system/menu/roleTree/{roleId} | sys:menu:list | 角色已選菜單樹 |

### 5.7 內部接口 (為流程引擎預留)

| 方法 | 路徑 | 說明 |
|------|------|------|
| GET | /api/internal/user/{id} | 查詢用戶基本信息 |
| GET | /api/internal/user/dept/{deptId} | 查詢部門下所有用戶 |
| GET | /api/internal/dept/{id} | 查詢部門信息 |
| GET | /api/internal/dept/{id}/leader | 查詢部門負責人 |
| GET | /api/internal/role/{roleKey}/users | 查詢角色下用戶 |

> 當前通過 Controller 暴露，後期升級微服務時抽取為 Feign Client。

---

## 六、配置文件結構

### application.yml

```yaml
server:
  port: 8080
  servlet:
    context-path: /api

spring:
  profiles:
    active: dev

mybatis-plus:
  mapper-locations: classpath:mapper/**/*.xml
  configuration:
    map-underscore-to-camel-case: true
  global-config:
    db-config:
      logic-delete-field: deleted
      logic-delete-value: 1
      logic-not-delete-value: 0
      id-type: auto
```

### application-dev.yml

```yaml
spring:
  datasource:
    driver-class-name: com.microsoft.sqlserver.jdbc.SQLServerDriver
    url: jdbc:sqlserver://localhost:1433;databaseName=hr_db;encrypt=true;trustServerCertificate=true
    username: sa
    password: ${DB_PASSWORD}

  data:
    redis:
      host: localhost
      port: 6379
      password: ${REDIS_PASSWORD:}

# JWT 配置
jwt:
  secret: ${JWT_SECRET}
  expiration: 1800              # Token 過期時間 (秒)

# 日誌級別
logging:
  level:
    com.hr: debug
    com.hr.system.mapper: debug  # 打印 SQL
```

---

## 七、關鍵設計模式

### 7.1 統一響應體

```java
public class R<T> {
    private int code;
    private String msg;
    private T data;

    public static <T> R<T> ok(T data);
    public static <T> R<T> fail(String msg);
    public static <T> R<T> fail(int code, String msg);
}
```

### 7.2 全局異常處理

```
BusinessException       → 400 + 業務錯誤信息
MethodArgumentNotValid  → 400 + 參數校驗錯誤
AccessDeniedException   → 403 + "無權訪問"
Exception               → 500 + "系統內部錯誤"
```

### 7.3 操作日誌 AOP

```
@Log(title = "用戶管理", businessType = BusinessType.INSERT)
@PostMapping
public R<Void> add(@RequestBody SysUserDTO dto) { ... }

→ 切面自動記錄: 操作人、IP、請求參數、返回結果、耗時
→ 寫入 sys_oper_log 表
```
