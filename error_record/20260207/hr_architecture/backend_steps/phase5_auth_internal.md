## 階段五：認證接口 (hr-admin)

### Step 19：登入/登出 ✅

認證流程串聯了 Spring Security、JWT、Redis、以及階段四建好的用戶/菜單/角色 Service。所有檔案放在 `hr-admin` 模組（它依賴所有其他模組，無循環依賴問題）。

#### 產物清單

| 檔案 | 所屬包 | 職責 |
|---|---|---|
| `UserDetailsServiceImpl.java` | `hr-admin/service/` | 實作 `UserDetailsService`，載入用戶 + 權限 + 角色 |
| `LoginService.java` | `hr-admin/service/` | 登入認證 + 登出 |
| `LoginBody.java` | `hr-admin/controller/` | 登入請求 DTO（username + password） |
| `AuthController.java` | `hr-admin/controller/` | 4 個認證端點 |

#### 1. UserDetailsServiceImpl

Spring Security 的 `AuthenticationManager.authenticate()` 會自動找到這個 `@Service` 並調用 `loadUserByUsername`：

```
loadUserByUsername(username)
  → ISysUserService.selectByUsername()       // 從 DB 查用戶
  → 校驗 status ≠ DISABLED                   // 停用用戶拒絕登入
  → ISysMenuService.selectPermsByUserId()    // 查權限標識集合
  → ISysRoleService.selectRoleKeysByUserId() // 查角色編碼集合
  → new LoginUser(userId, deptId, username, password, nickname, permissions, roles)
```

> **為什麼放 hr-admin 而不是 hr-framework**：它依賴 `ISysUserService`、`ISysMenuService`、`ISysRoleService`（均在 hr-system），而 hr-framework 不依賴 hr-system。放 hr-admin 是最頂層模組，無循環依賴。

#### 2. LoginService

```java
public String login(String username, String password) {
    // 1. Spring Security 認證（內部調用 UserDetailsServiceImpl + BCrypt 比對）
    Authentication auth = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(username, password));
    // 2. 取出 LoginUser
    LoginUser loginUser = (LoginUser) auth.getPrincipal();
    // 3. 記錄登入資訊（IP、時間）
    userService.updateLoginInfo(loginUser.getUserId(), null);
    // 4. 生成 JWT（UUID tokenKey → Redis 存 LoginUser → JWT 簽發）
    return tokenService.createToken(loginUser);
}

public void logout() {
    // 從 SecurityContext 取當前用戶 → 刪除 Redis key
    LoginUser loginUser = SecurityUtils.getLoginUserOrNull();
    if (loginUser != null) tokenService.delLoginUser(loginUser.getToken());
}
```

#### 3. AuthController

| Method | Path | 認證 | 說明 |
|---|---|---|---|
| POST | `/login` | 放行（SecurityConfig permitAll） | 帳號密碼登入，返回 `{ token }` |
| POST | `/logout` | 放行 | 清除 Redis token，返回成功 |
| GET | `/getInfo` | 需認證 | 返回 `{ userId, username, nickname, deptId, roles, permissions }` |
| GET | `/getRouters` | 需認證 | 返回當前用戶的動態菜單樹（`selectMenuTreeByUserId`） |

#### 完整認證流程

```
前端 POST /login { username, password }
  → AuthController.login()
    → LoginService.login()
      → AuthenticationManager.authenticate()
        → UserDetailsServiceImpl.loadUserByUsername()  ← 查 DB
        → DaoAuthenticationProvider.additionalAuthenticationChecks()  ← BCrypt 比對
      → TokenService.createToken(loginUser)
        → UUID tokenKey → Redis SET login_token:{key} = LoginUser (TTL=30min)
        → Jwts.builder().claim("login_token", key).signWith(secretKey).compact()
      → 返回 JWT
  ← R.ok({ "token": "eyJhbG..." })

後續請求 Header: Authorization: Bearer eyJhbG...
  → JwtAuthenticationFilter.doFilterInternal()
    → TokenService.getLoginUser(request)  ← 解析 JWT → Redis GET
    → TokenService.verifyToken(loginUser) ← 滑動過期檢查
    → SecurityContextHolder 設入 Authentication
  → 到達 Controller（@PreAuthorize 校驗權限）
```

#### 驗收

- `mvn compile -q`（全模組）✅ 通過

### Step 20：內部接口 (為流程引擎預留) ✅

為未來的流程引擎（如 Flowable/Camunda）預留的內部查詢接口。當前直接調用 Service，後期微服務化時抽取為 Feign 接口。

#### 產物清單

| 操作 | 檔案 | 說明 |
|---|---|---|
| 新增 | `hr-admin/controller/InternalApiController.java` | 5 個內部端點 |
| 修改 | `hr-framework/config/SecurityConfig.java` | `/internal/**` 加入 permitAll |

#### 1. SecurityConfig 放行

```java
.requestMatchers("/internal/**").permitAll()
```

> 內部接口不走 JWT 認證。後期微服務化時改為 Feign 調用 + 內部鑒權 Token（如共享 Secret Header）。

#### 2. InternalApiController

| Method | Path | 說明 | 用途場景 |
|---|---|---|---|
| GET | `/internal/user/{userId}` | 用戶資訊 | 流程引擎查發起人資料 |
| GET | `/internal/user/dept/{deptId}` | 部門下用戶列表（正常狀態） | 流程引擎查某部門的審批候選人 |
| GET | `/internal/dept/{deptId}` | 部門資訊 | 流程引擎查部門層級 |
| GET | `/internal/dept/{deptId}/leader` | 部門負責人（leader 欄位） | 流程引擎自動指派上級審批 |
| GET | `/internal/role/{roleKey}/users` | 角色下用戶列表 | 流程引擎按角色分配任務 |

> **SQL 注入防護**：`/role/{roleKey}/users` 端點先用 MP 參數化查詢 `eq("role_key", roleKey)` 取得角色 ID（Long），再用 `role.getRoleId()` 拼子查詢，避免字串拼接注入。

#### 驗收

- `mvn compile -q`（全模組）✅ 通過

---

### 階段五總驗收

| Step | 模組 | 狀態 |
|---|---|---|
| 19 | 登入/登出（認證流程串聯） | ✅ |
| 20 | 內部接口（流程引擎預留） | ✅ |

全模組編譯通過，階段五完成。

---
