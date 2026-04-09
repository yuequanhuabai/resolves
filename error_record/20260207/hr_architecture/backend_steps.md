# 後端實施步驟

## 階段一：項目初始化

### Step 1：創建 Maven 多模塊項目

1. 創建父工程 `hr-backend`，packaging 設為 `pom`
2. 定義 `<dependencyManagement>` 統一版本管理：
   - Spring Boot 3.2.x (parent)
   - MyBatis-Plus 3.5.x
   - Knife4j 4.x
   - JWT (jjwt 0.12.x)
   - SQL Server JDBC Driver
3. 創建四個子模塊：
   - `hr-common`
   - `hr-framework`
   - `hr-system`
   - `hr-admin`
4. 配置模塊間依賴關係：
   ```
   hr-admin → hr-system → hr-framework → hr-common
   ```

### Step 2：配置 hr-admin 啟動模塊

1. 創建啟動類 `HrApplication.java`
2. 配置 `application.yml`：
   - 端口 8080
   - context-path: `/api`
   - MyBatis-Plus mapper 掃描路徑
3. 配置 `application-dev.yml`：
   - SQL Server 數據源連接
   - Redis 連接
   - JWT 密鑰
4. 啟動驗證：應用能正常啟動

### Step 3：創建 SQL Server 數據庫

1. 創建數據庫 `hr_db`
2. 執行建表腳本 (參考 backend_architecture.md 第二節)：
   - sys_user
   - sys_dept
   - sys_post
   - sys_role
   - sys_menu
   - sys_user_role
   - sys_role_menu
   - sys_role_dept
   - sys_oper_log
3. 創建索引
4. 插入初始化數據：
   - 超級管理員帳號 (admin / admin123)
   - 頂級部門
   - 基礎崗位
   - 管理員角色
   - 系統菜單 + 按鈕權限

---

## 階段二：公共模塊 (hr-common)

### Step 4：基礎設施

1. 創建 `BaseEntity.java` — 公共欄位 (createBy, createTime, updateBy, updateTime, deleted)
2. 創建 `R<T>` — 統一響應體
3. 創建 `PageResult<T>` — 分頁響應體
4. 創建 `PageQuery` — 分頁請求參數 (pageNum, pageSize)
5. 創建常量類 `Constants.java`、`HttpStatus.java`
6. 創建枚舉類 `StatusEnum`、`GenderEnum`、`MenuTypeEnum`、`DataScopeEnum`

### Step 5：異常處理

1. 創建 `BusinessException.java` — 業務異常
2. 創建 `GlobalExceptionHandler.java` — 全局異常處理器
   - 處理 BusinessException → 400
   - 處理 MethodArgumentNotValidException → 400
   - 處理 AccessDeniedException → 403
   - 處理 Exception → 500

### Step 6：工具類

1. `SecurityUtils.java` — 獲取當前登入用戶 ID、用戶名、部門 ID
2. `TreeUtils.java` — 列表轉樹形結構通用方法
3. 其它工具類按需添加

---

## 階段三：框架模塊 (hr-framework)

### Step 7：Redis 配置

1. 引入 spring-boot-starter-data-redis
2. 創建 `RedisConfig.java` — Jackson 序列化配置
3. 創建 `RedisCache.java` — 封裝常用操作 (set/get/delete/expire)

### Step 8：MyBatis-Plus 配置

1. 創建 `MybatisPlusConfig.java`：
   - 分頁插件 `PaginationInnerInterceptor`
   - 自動填充處理器 (createTime, updateTime)
   - 邏輯刪除配置

### Step 9：Spring Security + JWT

1. 創建 `LoginUser.java` — 實現 UserDetails，包含用戶信息 + 權限集合
2. 創建 `TokenService.java`：
   - `createToken(LoginUser)` — 生成 JWT，用戶信息存 Redis
   - `parseToken(token)` — 解析 Token，從 Redis 取用戶信息
   - `refreshToken(LoginUser)` — 刷新過期時間
3. 創建 `JwtAuthenticationFilter.java`：
   - 繼承 OncePerRequestFilter
   - 從 Header 取 Token → 解析 → 設入 SecurityContext
4. 創建 `UserDetailsServiceImpl.java`：
   - 實現 UserDetailsService
   - 根據 username 查詢用戶 + 角色 + 權限
5. 創建 `SecurityConfig.java`：
   - 放行登入接口、Swagger 文檔
   - 註冊 JWT 過濾器
   - 禁用 CSRF、Session
   - 配置 401/403 處理器
6. 創建 `PermissionService.java`：
   - `hasPerms(String perm)` — 校驗當前用戶是否有指定權限
   - 註冊為 Spring Bean `@Component("perm")`
   - Controller 使用: `@PreAuthorize("@perm.hasPerms('sys:user:list')")`

### Step 10：跨域配置

1. 創建 `CorsConfig.java` — 允許前端開發服務器跨域

### Step 11：操作日誌

1. 創建 `@Log` 註解
2. 創建 `LogAspect.java` — AOP 切面，攔截標註了 @Log 的 Controller 方法
3. 異步寫入 sys_oper_log 表

---

## 階段四：業務模塊 (hr-system)

### Step 12：實體類

按 backend_architecture.md 數據庫設計，創建：
1. `SysUser.java` (含 @TableLogic deleted)
2. `SysDept.java`
3. `SysPost.java`
4. `SysRole.java`
5. `SysMenu.java`
6. `SysUserRole.java`
7. `SysRoleMenu.java`
8. `SysRoleDept.java`

### Step 13：部門管理 (優先，因為用戶依賴部門)

1. `SysDeptMapper.java` + `SysDeptMapper.xml`
   - 查詢部門列表
   - 根據角色 ID 查詢部門 ID 集合 (數據權限)
2. `ISysDeptService.java` + `SysDeptServiceImpl.java`
   - 查詢部門列表 (返回樹形)
   - 新增部門 (自動維護 ancestors)
   - 修改部門 (級聯更新子部門 ancestors)
   - 刪除部門 (校驗是否有子部門或用戶)
3. `SysDeptController.java`

### Step 14：崗位管理

1. `SysPostMapper.java` — 基本 CRUD (MyBatis-Plus 內置即可)
2. `ISysPostService.java` + `SysPostServiceImpl.java`
   - 分頁查詢
   - 新增 (校驗編碼唯一)
   - 修改
   - 刪除 (校驗是否有用戶關聯)
3. `SysPostController.java`

### Step 15：菜單管理

1. `SysMenuMapper.java` + `SysMenuMapper.xml`
   - 查詢所有菜單列表
   - 根據用戶 ID 查詢權限標識集合
   - 根據用戶 ID 查詢菜單樹
   - 根據角色 ID 查詢已選菜單 ID
2. `ISysMenuService.java` + `SysMenuServiceImpl.java`
   - 查詢菜單樹
   - 新增/修改/刪除菜單
   - 構建前端路由所需結構 (RouterVO)
3. `SysMenuController.java`

### Step 16：角色管理

1. `SysRoleMapper.java` + `SysRoleMapper.xml`
   - 分頁查詢角色
   - 根據用戶 ID 查詢角色列表
2. `ISysRoleService.java` + `SysRoleServiceImpl.java`
   - 分頁查詢
   - 新增角色 (同時插入 sys_role_menu)
   - 修改角色 (同時更新 sys_role_menu)
   - 刪除角色 (校驗是否有用戶關聯)
   - 修改數據權限 (更新 data_scope + sys_role_dept)
3. `SysRoleController.java`

### Step 17：用戶管理

1. `SysUserMapper.java` + `SysUserMapper.xml`
   - 分頁查詢用戶 (關聯部門名稱)
   - 根據 username 查詢用戶 (登入用)
   - 數據權限 SQL 預留
2. `ISysUserService.java` + `SysUserServiceImpl.java`
   - 分頁查詢 (支持按部門、用戶名、手機、狀態篩選)
   - 查詢用戶詳情 (含角色列表、崗位信息)
   - 新增用戶 (密碼 BCrypt 加密，插入 sys_user_role)
   - 修改用戶 (更新 sys_user_role)
   - 刪除用戶 (不允許刪除 admin)
   - 重置密碼
   - 修改狀態
3. `SysUserController.java`

### Step 18：數據權限攔截器

1. 創建 `@DataScope` 註解 — 標註在 Service 方法上
2. 創建 `DataScopeInterceptor.java` — MyBatis 攔截器
   - 獲取當前用戶角色的 data_scope
   - 拼接 WHERE 條件
   - 注入到原始 SQL
3. 在 SysUserServiceImpl 的列表查詢方法上添加 `@DataScope`

---

## 階段五：認證接口 (hr-admin)

### Step 19：登入/登出

1. 創建 `AuthController.java`：
   - `POST /auth/login` — 接收帳號密碼，調用 LoginService，返回 Token
   - `POST /auth/logout` — 清除 Redis 中的 Token
   - `GET /auth/info` — 返回當前用戶信息 + 角色標識 + 權限標識集合
   - `GET /auth/routers` — 返回當前用戶的動態菜單路由
2. 創建 `LoginService.java`：
   - 調用 AuthenticationManager 認證
   - 認證成功後生成 Token
   - 記錄登入 IP 和時間

### Step 20：內部接口 (為流程引擎預留)

1. 創建 `InternalApiController.java`：
   - `GET /internal/user/{id}` — 用戶信息
   - `GET /internal/user/dept/{deptId}` — 部門用戶列表
   - `GET /internal/dept/{id}` — 部門信息
   - `GET /internal/dept/{id}/leader` — 部門負責人
   - `GET /internal/role/{roleKey}/users` — 角色用戶列表
2. 當前直接調用 Service，後期抽取為 Feign 接口

---

## 階段六：API 文檔 + 測試

### Step 21：Knife4j 集成

1. 引入 knife4j-openapi3-jakarta-spring-boot-starter
2. 配置 Swagger 分組 (認證接口、系統管理、內部接口)
3. Controller 添加 @Tag、@Operation 註解
4. 驗證: 訪問 /doc.html 查看文檔

### Step 22：接口測試

1. 測試登入接口，獲取 Token
2. 使用 Token 測試各模塊 CRUD
3. 測試權限控制：
   - 未登入訪問 → 401
   - 無權限訪問 → 403
   - 數據權限過濾是否生效
4. 測試邊界情況：
   - 刪除有子部門的部門 → 提示錯誤
   - 刪除有用戶的角色 → 提示錯誤
   - 用戶名重複 → 提示錯誤

---

## 階段七：初始化數據腳本

### Step 23：編寫初始化 SQL

```
插入順序:
  1. sys_dept   — 頂級公司 + 基礎部門
  2. sys_post   — 基礎崗位 (董事長/總經理/普通員工)
  3. sys_menu   — 完整菜單樹 (目錄 + 菜單 + 按鈕)
  4. sys_role   — 超級管理員角色 + 普通角色
  5. sys_user   — admin 用戶 (密碼 BCrypt 加密)
  6. sys_user_role  — admin 綁定管理員角色
  7. sys_role_menu  — 管理員角色綁定所有菜單
```

---

## 實施順序總結

```
階段一 (Step 1-3)   項目骨架 + 數據庫         ██░░░░░░░░  預計 Day 1-2
階段二 (Step 4-6)   公共模塊                  ████░░░░░░  預計 Day 2-3
階段三 (Step 7-11)  框架模塊 (安全/認證/攔截)   ██████░░░░  預計 Day 3-5
階段四 (Step 12-18) 業務模塊 (核心 CRUD)       ████████░░  預計 Day 5-9
階段五 (Step 19-20) 認證 + 內部接口            █████████░  預計 Day 9-10
階段六 (Step 21-22) 文檔 + 測試               ██████████  預計 Day 10-11
階段七 (Step 23)    初始化數據                 ██████████  預計 Day 11
```

### 關鍵里程碑

| 里程碑 | 驗收標準 |
|--------|---------|
| M1: 項目能跑 | Spring Boot 啟動成功，連接 SQL Server + Redis |
| M2: 能登入 | 帳號密碼登入 → 返回 Token → Token 訪問受保護接口 |
| M3: CRUD 通 | 用戶/角色/部門/崗位/菜單 全部 CRUD 接口可用 |
| M4: 權限生效 | 角色權限分配 + 數據權限過濾 正常工作 |
| M5: 後端完成 | API 文檔完整，初始化數據就緒，可交付前端對接 |
