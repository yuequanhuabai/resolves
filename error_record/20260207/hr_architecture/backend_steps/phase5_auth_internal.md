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
