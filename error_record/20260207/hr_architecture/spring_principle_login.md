# Spring Security 認證授權核心對象

---

## 一、認證（Authentication）流程

### 1. `SecurityContextHolder`
整個安全體系的**核心容器**，保存當前線程的安全上下文。

```
SecurityContextHolder
    └── SecurityContext
            └── Authentication（當前登錄用戶信息）
```

- 默認用 `ThreadLocal` 存儲，每個請求線程隔離
- 請求結束後自動清除

---

### 2. `Authentication`
**認證信息的載體**，貫穿整個認證流程。

```java
Authentication {
    getPrincipal()    // 認證前：username字符串；認證後：UserDetails對象
    getCredentials()  // 密碼（認證成功後會被清除）
    getAuthorities()  // 權限列表
    isAuthenticated() // 是否已認證
}
```

常用實現：`UsernamePasswordAuthenticationToken`

---

### 3. `AuthenticationManager`
**認證的入口**，只有一個方法：

```java
Authentication authenticate(Authentication authentication)
```

- 本身不做認證，**委託給** `AuthenticationProvider` 列表逐一嘗試
- 默認實現：`ProviderManager`

---

### 4. `AuthenticationProvider`
**真正執行認證邏輯**的地方。

```java
Authentication authenticate(Authentication authentication) // 執行認證
boolean supports(Class<?> authentication)                 // 判斷是否支持此類型
```

- `DaoAuthenticationProvider`：處理用戶名密碼認證
  - 調用 `UserDetailsService` 加載用戶
  - 調用 `PasswordEncoder` 驗證密碼

---

### 5. `UserDetailsService`
**加載用戶數據**的接口，你需要實現它：

```java
UserDetails loadUserByUsername(String username)
```

- 從數據庫查用戶，返回 `UserDetails` 對象
- 找不到拋 `UsernameNotFoundException`

---

### 6. `UserDetails`
**用戶信息的標準模型**：

```java
UserDetails {
    getUsername()
    getPassword()       // 數據庫中的加密密碼
    getAuthorities()    // 角色/權限列表
    isEnabled()         // 帳號是否啟用
    isAccountNonLocked()
    isCredentialsNonExpired()
    isAccountNonExpired()
}
```

---

### 7. `PasswordEncoder`
**密碼加密與驗證**：

```java
String encode(CharSequence rawPassword)               // 加密
boolean matches(CharSequence raw, String encoded)     // 驗證
```

- 項目用 `spring-security-crypto` 提供的 `BCryptPasswordEncoder`

---

## 二、過濾器鏈（Filter Chain）

所有請求都經過 `SecurityFilterChain`，關鍵過濾器：

```
請求進入
    │
    ├── UsernamePasswordAuthenticationFilter  ← 攔截 /login，提取帳密，發起認證
    │
    ├── (自定義) JwtAuthenticationFilter      ← 攔截所有請求，解析JWT，設置Authentication
    │
    ├── ExceptionTranslationFilter            ← 捕獲認證/授權異常，轉為HTTP響應
    │
    └── FilterSecurityInterceptor             ← 執行授權決策
```

---

## 三、授權（Authorization）流程

### 8. `GrantedAuthority`
**權限的最小單元**：

```java
String getAuthority() // 返回如 "ROLE_ADMIN" 或 "user:list"
```

---

### 9. `AccessDecisionManager` / `AuthorizationManager`（6.x新）
**授權決策者**，判斷當前用戶是否有權訪問資源。

- Spring Security 6.x 推薦用 `AuthorizationManager<RequestAuthorizationContext>`
- 結合 `@PreAuthorize("hasRole('ADMIN')")` 等註解使用

---

## 四、整體流程圖

```
POST /login
    │
    ▼
UsernamePasswordAuthenticationFilter
    │ 構造 UsernamePasswordAuthenticationToken(username, password)
    ▼
AuthenticationManager (ProviderManager)
    │ 委託
    ▼
DaoAuthenticationProvider
    │ loadUserByUsername()          → UserDetailsService → 數據庫
    │ passwordEncoder.matches()     → BCryptPasswordEncoder
    │ 認證成功，填充 authorities
    ▼
Authentication（已認證）
    │ 生成 JWT Token 返回前端
    ▼
─────────────────────────────────────────
後續請求帶 Authorization: Bearer <token>
    │
    ▼
JwtAuthenticationFilter（自定義）
    │ 解析Token → 獲取username和authorities
    │ 構造已認證的 UsernamePasswordAuthenticationToken
    ▼
SecurityContextHolder.getContext().setAuthentication(...)
    │
    ▼
FilterSecurityInterceptor / @PreAuthorize
    │ 檢查 authorities 是否滿足資源要求
    ▼
放行 or 拋出 AccessDeniedException
```

---

## 五、總結對照表

| 對象 | 角色定位 |
|------|---------|
| `SecurityContextHolder` | 安全上下文的全局倉庫 |
| `Authentication` | 認證信息的數據載體 |
| `AuthenticationManager` | 認證流程的入口調度者 |
| `AuthenticationProvider` | 認證邏輯的具體執行者 |
| `UserDetailsService` | 用戶數據的加載接口 |
| `UserDetails` | 用戶信息的標準模型 |
| `PasswordEncoder` | 密碼的加密與校驗工具 |
| `GrantedAuthority` | 權限的最小表示單元 |
| `SecurityFilterChain` | 請求的安全攔截管道 |
| `AuthorizationManager` | 授權決策的執行者 |
