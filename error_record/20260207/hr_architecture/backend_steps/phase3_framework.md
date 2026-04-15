## 階段三：框架模塊 (hr-framework)

### Step 7：Redis 配置 ✅ 已完成

#### 概覽

| 子步驟 | 內容 | 涉及檔案 |
|---|---|---|
| 7.1 | RedisConfig 序列化配置 | `framework/config/RedisConfig.java` |
| 7.2 | 移除啟動類 RedisAutoConfiguration 排除 + 啟動驗證 | 修改 `HrApplication.java` |
| 7.3 | RedisCache 工具類 | `framework/cache/RedisCache.java` |

#### 包結構新增

```
hr-framework/src/main/java/com/hr/framework/
  ├── config/
  │   └── RedisConfig.java         # Redis 序列化配置
  └── cache/
      └── RedisCache.java          # Redis 操作工具類
```

---

#### 7.1 RedisConfig 序列化配置

**核心問題**：Spring Boot 預設 `RedisTemplate` 用 JDK 序列化，存進 Redis 的資料是二進位亂碼：
- 不可讀（RedisInsight、redis-cli 看不懂）
- 跨語言不兼容（Python/Go/Node 無法解析）
- 體積大（比 JSON 大 30~50%）
- 版本敏感（類結構改一下就反序列化失敗）

**解決方案**：自訂 `RedisTemplate<String, Object>`：
- Key / HashKey → `StringRedisSerializer`（純字串）
- Value / HashValue → `GenericJackson2JsonRedisSerializer`（Jackson JSON）

**為什麼是 `GenericJackson2JsonRedisSerializer` 而非 `Jackson2JsonRedisSerializer`？**

| 對比 | Jackson2JsonRedisSerializer | GenericJackson2JsonRedisSerializer |
|---|---|---|
| 需指定類型 | 是（構造時傳 class） | 否 |
| 支援多類型 | 否，一 template 只能存一種 | 是 |
| 存入 `@class` 欄位 | 否 | **是**（用於反序列化） |

HR 系統會存各種物件（LoginUser、權限集合、驗證碼等），必須用 Generic 版本。

**ObjectMapper 配置要點**：

1. **啟用多態類型（@class 欄位）**：`activateDefaultTyping(validator, NON_FINAL, PROPERTY)`
   - `NON_FINAL`：非 final 類才加 `@class`，String/Integer 這種 final 的不加，省空間
   - `PROPERTY`：`@class` 作為 JSON 屬性，而非包裝成 Array

2. **PolymorphicTypeValidator 白名單**：防範 Jackson 多態反序列化 CVE
   - `com.hr.*` — 允許業務類
   - `java.util.*` — 允許 ArrayList、HashMap 等
   - `java.lang.*` — 允許基礎類
   - `java.time.*` — 允許 LocalDateTime 等

3. **註冊 JavaTimeModule**：支援 JDK 8 時間類（LocalDateTime、LocalDate）
   - 未註冊會報 "Java 8 date/time type not supported by default"

4. **設置 visibility ALL/ANY**：讓 Jackson 直接讀寫 private 欄位，不依賴 getter/setter
   - 某些 DTO 只有 `@Getter` 沒 `@Setter`，需要這個才能反序列化

5. **FAIL_ON_UNKNOWN_PROPERTIES = false**：前向兼容
   - 類加欄位後，舊資料反序列化缺失欄位為 null 而非報錯
   - 類去欄位後，舊資料多餘欄位被忽略

**為什麼不配 ConnectionFactory？**
Spring Boot `RedisAutoConfiguration` 會根據 `application-dev.yml` 的 `spring.data.redis.host/port` 自動創建 `LettuceConnectionFactory`，透過 Bean 方法參數注入即可。

---

#### 7.2 啟動類調整 + 啟動驗證

**調整**：註釋掉 `HrApplication` 的 `RedisAutoConfiguration.class` 排除：
```java
@SpringBootApplication(
    scanBasePackages = "com.hr",
    exclude = {
//        RedisAutoConfiguration.class,   ← Step 7 註釋
        DataSourceAutoConfiguration.class
    }
)
```

**驗證結果**：
- 啟動日誌出現 "Bootstrapping Spring Data Redis repositories in DEFAULT mode"
- "Finished Spring Data repository scanning" — Redis 連接工廠創建成功
- `RedisConfig` 的 `redisTemplate` Bean 成功注入到容器（若失敗會在 context 初始化階段 fail）

**已知問題**：本機 port 8080 被其他程式佔用，由用戶自行解決。

---

#### 7.3 RedisCache 工具類

**目的**：把對 RedisTemplate 的常用操作封裝成統一 API，業務代碼不直接碰 `opsForValue().set(...)` 這類冗長寫法。

**封裝的好處**：
1. 統一入口 — 將來要加統一前綴、監控、日誌切面只改一處
2. 語意清晰 — `setCacheList` 比 `opsForList().rightPushAll` 直觀
3. 泛型友好 — `<T> T getCacheObject(key)` 比強轉優雅
4. 解耦 — 業務代碼依賴 RedisCache，將來換 Caffeine 也容易

**公開方法（16 個）**：

| 類別 | 方法 | 說明 |
|---|---|---|
| **通用** | `setCacheObject(k, v)` | 存值（無 TTL） |
| | `setCacheObject(k, v, timeout, unit)` | 存值 + TTL |
| | `getCacheObject(k)` | 取值（泛型） |
| | `deleteObject(String)` | 刪單個 → boolean |
| | `deleteObject(Collection)` | 批量刪 → long（刪除數量） |
| | `expire(k, timeout, unit)` | 設 TTL |
| | `getExpire(k)` | 查剩餘秒數（-2 不存在 / -1 永久） |
| | `hasKey(k)` | 判斷存在 |
| | `keys(pattern)` | **⚠️ O(n) 阻塞**，僅開發用 |
| | `scanKeys(pattern)` | ✅ 基於 SCAN 非阻塞，生產推薦 |
| **List** | `setCacheList` / `getCacheList` | 列表 |
| **Set** | `setCacheSet` / `getCacheSet` | 集合 |
| **Hash** | `setCacheMap` / `getCacheMap` | 整個 Map |
| | `setCacheMapValue` / `getCacheMapValue` / `deleteCacheMapValue` | 單欄位 |

**設計細節**：

1. **構造器注入 + final 欄位**
   ```java
   private final RedisTemplate<String, Object> redisTemplate;
   public RedisCache(RedisTemplate<String, Object> redisTemplate) { ... }
   ```
   - Spring 官方推薦寫法，final 保證不可變、便於測試、循環依賴編譯期暴露

2. **`@SuppressWarnings("unchecked")` 加在類頂部**
   - 多個方法有 `(List<T>) (List<?>)` 雙重強轉
   - 泛型擦除下無法運行期校驗，業務語境下安全
   - 統一壓制，避免每個方法單獨加

3. **雙重強轉的繞法**：`return (List<T>) (List<?>) opsForList().range(...)`
   - 直接 `(List<T>)` 會 unchecked 警告
   - 先轉 `List<?>` 再轉 `List<T>` 是 JDK 源碼常見寫法，等價但警告少一層

4. **`deleteObject` 返回值策略**
   - 單個 → boolean（只需知道成敗）
   - 批量 → long（需知道實際刪了幾個，可能部分 key 不存在）

5. **`getExpire` 返回值約定**
   - `-2` = key 不存在（Redis TTL 命令原生語意）
   - `-1` = key 存在但未設 TTL
   - `>= 0` = 剩餘秒數
   - RedisTemplate 在 null 時兜底成 -2 保持語意一致

6. **`keys()` vs `scanKeys()` 必須分清**
   - `KEYS pattern` → O(n) 阻塞，10 萬 key 可能阻塞 Redis 幾百毫秒
   - `SCAN cursor MATCH pattern` → 遊標分批（每批 1000），不阻塞
   - `keys()` 方法保留用於開發調試，加 JavaDoc 警告
   - 生產代碼應用 `scanKeys()`

7. **`scanKeys` 使用 try-with-resources**
   ```java
   try (Cursor<String> cursor = redisTemplate.scan(options)) { ... }
   ```
   - `Cursor` 持有 Redis 連接，不關閉會洩漏
   - 實現了 `Closeable`，try-with-resources 自動釋放

---

#### 後續引用場景預覽

| 引用方 | 場景 | 步驟 |
|---|---|---|
| `TokenService.createToken()` | `setCacheObject(LOGIN_TOKEN_KEY + userId, user, 30, MINUTES)` | Step 9 |
| `TokenService.getLoginUser()` | `getCacheObject(LOGIN_TOKEN_KEY + userId)` | Step 9 |
| `TokenService.refreshToken()` | `expire(key, 30, MINUTES)` — 滑動過期 | Step 9 |
| `LoginService.logout()` | `deleteObject(LOGIN_TOKEN_KEY + userId)` | Step 19 |
| `CaptchaController` | `setCacheObject(CAPTCHA_KEY + uuid, code, 5, MINUTES)` | Step 19 |

---

#### 驗收檢查

- [x] `RedisConfig` 自訂 RedisTemplate，Jackson JSON 序列化
- [x] PolymorphicTypeValidator 白名單配置（com.hr / java.util / java.lang / java.time）
- [x] 註冊 JavaTimeModule 支援 LocalDateTime
- [x] 啟動類移除 RedisAutoConfiguration 排除
- [x] Spring Boot 啟動成功，Redis Repository 掃描通過
- [x] `RedisCache` 提供 16 個公開方法，涵蓋 String / List / Set / Hash
- [x] 提供 `scanKeys()` 作為 `keys()` 的生產環境替代
- [x] hr-framework 模塊編譯通過（`mvn -pl hr-framework -am compile`）

完成後進入 → **Step 8：MyBatis-Plus 配置**

### Step 8：MyBatis-Plus 配置 ✅ 已完成

#### 概覽

| 子步驟 | 內容 | 涉及檔案 |
|---|---|---|
| 8.1 | MybatisPlusConfig 分頁 + 樂觀鎖攔截器 | `framework/config/MybatisPlusConfig.java` |
| 8.2 | MyMetaObjectHandler 審計欄位自動填充 | `framework/handler/MyMetaObjectHandler.java` |
| 8.3 | 移除啟動類 DataSourceAutoConfiguration 排除 + 啟動驗證 | 修改 `HrApplication.java` |

#### 包結構新增

```
hr-framework/src/main/java/com/hr/framework/
  ├── config/
  │   └── MybatisPlusConfig.java       # MP 攔截器配置 + @MapperScan
  └── handler/
      └── MyMetaObjectHandler.java     # 審計欄位自動填充
```

---

#### 8.1 MybatisPlusConfig 配置

**設計要點**：

1. **`@MapperScan("com.hr.*.mapper")`**
   - 統一掃描所有子模塊的 Mapper 介面
   - 避免每個 Mapper 單獨加 `@Mapper`
   - `com.hr.*` 萬用字元匹配 `com.hr.system.mapper`、`com.hr.admin.mapper` 等

2. **PaginationInnerInterceptor 分頁攔截器**
   - **必須指定方言**：`new PaginationInnerInterceptor(DbType.SQL_SERVER)`
     - 不同 DB 的分頁 SQL 完全不同（MySQL `LIMIT`、SQL Server `OFFSET FETCH`、Oracle `ROWNUM`）
     - SQL Server 2012+ 使用 `OFFSET n ROWS FETCH NEXT m ROWS ONLY`
   - `setMaxLimit(500L)` — 單頁最大 500 條，防惡意撈大量資料
   - `setOverflow(false)` — 溢出頁不回首頁，直接返回空列表

3. **OptimisticLockerInnerInterceptor 樂觀鎖**
   - 配合實體類 `@Version` 欄位使用
   - 適用於併發更新場景（如角色權限分配時防覆蓋）
   - 目前沒有實體用到，但提前裝好避免以後忘了

**多數據源場景說明**（用戶提問）：

如果將來引入 `dynamic-datasource-spring-boot-starter`，每個數據源的方言可能不同：
```java
// 多數據源時改為自動檢測（不傳 DbType）
new PaginationInnerInterceptor()  // MP 會從連接自動推斷方言
```
- **代價**：每次請求都多一次元資料查詢
- **當前方案**：單數據源 SQL Server，保留 `DbType.SQL_SERVER` 顯式指定更高效

---

#### 8.2 MyMetaObjectHandler 審計欄位自動填充

**目的**：接管 `BaseEntity` 中用 `@TableField(fill=...)` 標記的四個欄位，在 INSERT / UPDATE 時自動注入值，業務代碼完全不用手動 set。

**填充規則**：

| 欄位 | INSERT 填充 | UPDATE 填充 |
|---|---|---|
| `createTime` | 當前時間 | — |
| `createBy` | 當前用戶 | — |
| `updateTime` | 當前時間 | 當前時間 |
| `updateBy` | 當前用戶 | 當前用戶 |

**關鍵設計：當前用戶獲取策略**

```java
private String getCurrentUsername() {
    try {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.isAuthenticated()
                && !"anonymousUser".equals(auth.getPrincipal())) {
            return auth.getName();
        }
    } catch (Exception e) {
        log.debug("取當前用戶失敗，回退為 system: {}", e.getMessage());
    }
    return Constants.SYSTEM_USER;  // "system"
}
```

- **Step 9 之前**：SecurityContextHolder 為空，自動回退 `"system"`
- **Step 9 之後**：Spring Security 登入後，`auth.getName()` 就是 `LoginUser.getUsername()`
- **零代碼修改過渡**：這個 Handler 寫好後，後續加 Spring Security 完全不需要動它

**為什麼排除 `"anonymousUser"`**？
Spring Security 對未登入請求會設一個 `AnonymousAuthenticationToken`，`getName()` 返回字串 `"anonymousUser"`，要排除，否則審計欄位會被填成這個值。

**為什麼用 `strictInsertFill` / `strictUpdateFill`**？
- 嚴格模式：只在實體類 `@TableField(fill=...)` 標記的欄位上才填
- 非嚴格的 `setFieldValByName` 會覆蓋用戶手動設的值，不可取

---

#### 8.3 啟動類調整 + 啟動驗證

**調整**：移除 `HrApplication` 的 `DataSourceAutoConfiguration.class` 排除：

```java
@SpringBootApplication(
    scanBasePackages = "com.hr",
    exclude = {
//        RedisAutoConfiguration.class,         ← Step 7 註釋
//        DataSourceAutoConfiguration.class     ← Step 8 移除
    }
)
```

**驗證結果**：
- 啟動日誌出現 `HikariPool-1 - Start completed` — 數據源初始化成功
- MP Banner 顯示版本 3.5.6
- 無 SQL Server 連接錯誤
- 端口佔用問題由用戶自行解決

---

#### 驗收檢查

- [x] `MybatisPlusConfig` 配置分頁 + 樂觀鎖攔截器
- [x] `@MapperScan("com.hr.*.mapper")` 統一掃描
- [x] `MyMetaObjectHandler` 實現 `insertFill` / `updateFill`
- [x] 當前用戶獲取兼容 Step 9 前後狀態
- [x] 啟動類移除 DataSourceAutoConfiguration 排除
- [x] Spring Boot 啟動成功，HikariPool 初始化通過
- [x] hr-framework 模塊編譯通過

完成後進入 → **Step 9：Spring Security + JWT**

---

### Step 9：Spring Security + JWT ✅ 已完成

#### 概覽

| 子步驟 | 內容 | 涉及檔案 | 狀態 |
|---|---|---|---|
| 9.1 | LoginUser 實作 UserDetails | `framework/security/LoginUser.java` | ✅ |
| 9.2 | JwtProperties + TokenService | `framework/config/JwtProperties.java` / `framework/security/TokenService.java` | ✅ |
| 9.3 | JwtAuthenticationFilter | `framework/security/JwtAuthenticationFilter.java` | ✅ |
| 9.4 | 401/403 處理器 | `framework/security/handler/*` | ✅ |
| 9.5 | SecurityConfig 過濾鏈 | `framework/config/SecurityConfig.java` | ✅ |
| 9.6 | PermissionService 權限校驗 | `framework/security/PermissionService.java` | ✅ |
| 9.7 | SecurityUtils 工具類（原 Step 6.2 延後） | `framework/security/SecurityUtils.java` | ✅ |

**⚠️ 延後說明**：`UserDetailsServiceImpl` 依賴 `SysUserMapper`，本步驟不實作，移至 **Step 17 用戶管理** 一併完成。Step 9 只搭安全框架骨架。

---

#### 9.1 LoginUser 實作 UserDetails ✅

**目的**：封裝「一個已認證用戶」的完整資訊，實作 Spring Security 的 `UserDetails` 介面，可直接塞進 `SecurityContext`，也可序列化存 Redis 供後續請求還原。

**欄位設計**：

| 欄位 | 來源 | 用途 |
|---|---|---|
| `userId` | DB | 審計填充、數據權限過濾 |
| `deptId` | DB | 數據權限（按部門過濾） |
| `username` | DB | UserDetails 必須欄位，登入帳號 |
| `password` | DB（BCrypt） | 登入比對用；`@JsonIgnore` 避免 HTTP 響應洩漏 |
| `nickname` | DB | 前端顯示 |
| `token` | 登入時生成 | 登出時精準定位 Redis key |
| `loginTime` | 登入時 | 計算登入時長 |
| `expireTime` | 登入時 | 判斷是否需要續期 |
| `permissions` | 關聯查詢 | 如 `sys:user:list`，供 `@PreAuthorize` 判斷 |
| `roles` | 關聯查詢 | 如 `admin`、`common`，供 `hasRole()` 判斷 |

**設計要點**：

1. **`@JsonIgnore` on password**
   - Redis 序列化走 field 反射（不受 `@JsonIgnore` 影響，會存入 → 重建 SecurityContext 時能比對）
   - HTTP 響應 JSON 序列化會遵守 `@JsonIgnore`（登入介面返回用戶資訊時密碼不外洩）
   - **同一個注解滿足兩個矛盾需求**，關鍵在序列化路徑不同

2. **`@NoArgsConstructor`**
   - Jackson 從 Redis 反序列化必須有無參構造
   - 同時保留帶參構造供登入流程快速組裝

3. **`getAuthorities()` 合併策略**
   ```java
   // permissions 原樣：sys:user:list
   // roles 加 ROLE_ 前綴：ROLE_admin
   ```
   - Spring Security 硬性約定：`hasRole('admin')` 內部實際比對 `ROLE_admin`
   - `hasAuthority('admin')` 才是字面比對
   - 兩套都要支援，所以都加進 GrantedAuthority 集合

4. **四個狀態方法全返回 `true`**
   - `isAccountNonExpired` / `isAccountNonLocked` / `isCredentialsNonExpired` / `isEnabled`
   - 我們系統不做帳號過期/鎖定/密碼有效期
   - 帳號停用檢查放在**登入流程一次性做掉**（查到 `status=1` 直接拋業務異常）
   - 避免每個請求都走一遍這四個 check

**後續引用場景**：

| 使用方 | 場景 |
|---|---|
| `TokenService.createToken` | 登入成功後 new LoginUser → 存 Redis |
| `JwtAuthenticationFilter` | 請求時從 Redis 取 LoginUser → setAuthentication |
| `SecurityUtils.getLoginUser` | 業務層隨時獲取當前用戶 |
| `MyMetaObjectHandler.getCurrentUsername` | 透過 `auth.getName()` 間接取 username |

---

#### 9.2 JwtProperties + TokenService ✅

**核心設計：JWT + Redis 雙層方案**

純 JWT 有致命缺點：簽發後無法撤銷。登出、改密碼、被封禁，已簽發的 JWT 在過期前仍有效。兩種解法：
- A. 維護黑名單（每次請求查黑名單，效能差）
- B. **JWT 只存索引，真資料放 Redis**（本專案選這個）

```
JWT payload: { "login_token": "a1b2c3..." }   ← 只是一個 UUID
                      ↓
Redis: login_token:a1b2c3...  →  LoginUser{userId, perms, roles, ...}
```

**好處**：
1. **可失效**：登出 → `DEL login_token:xxx` → 整個 token 瞬間作廢
2. **可滑動過期**：每次請求重置 Redis TTL，活躍用戶一直有效
3. **JWT 體積小**：不帶敏感業務資訊，只是索引

**`JwtProperties`（配置綁定）**

```java
@Component
@ConfigurationProperties(prefix = "jwt")
public class JwtProperties {
    private String secret;      // HMAC 密鑰（至少 256 bit）
    private long expiration;    // 有效期（秒）
}
```

- `header` / `prefix` 屬於 HTTP 協議標準，放在 `Constants` 而非這裡，避免誤配置
- 生產環境 secret 應透過環境變數覆蓋

**`TokenService` 五大職責**

| 方法 | 用途 |
|---|---|
| `createToken(LoginUser)` | 登入成功後簽發新 token |
| `getLoginUser(HttpServletRequest)` | 從請求還原當前用戶（過濾器用） |
| `verifyToken(LoginUser)` | 檢查並自動續期（滑動過期） |
| `refreshToken(LoginUser)` | 強制重置 Redis TTL |
| `delLoginUser(String)` | 登出時刪除 Redis key |

**關鍵設計**：

1. **SecretKey 啟動時一次性構建**
   ```java
   this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(UTF_8));
   ```
   避免每次簽發/解析重複計算，同時 `hmacShaKeyFor` 會檢查長度 ≥ 256 bit。

2. **JJWT 0.12.x 新 API**（舊版 0.11 的 `parseClaimsJws` / `setSigningKey` 已 deprecated）
   - 簽發：`Jwts.builder().claim(...).signWith(key).compact()`
   - 解析：`Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload()`

3. **刻意不設 JWT `exp`**
   ```java
   Jwts.builder()
       .claim("login_token", tokenKey)
       .signWith(secretKey)
       .compact();
   // 沒有 .expiration(...)
   ```
   真正決定有效性的是 Redis key 存不存在，把「到期判斷」從 JWT 搬到 Redis，換取滑動過期、瞬間失效的靈活性。

4. **滑動過期閾值：20 分鐘**
   ```java
   if (remaining <= 20 * 60 * 1000) refreshToken(...);
   ```
   expiration=1800s（30 分鐘），剩餘 < 20 分鐘才續期 → 一次續期可管 10 分鐘無 Redis 寫入，避免每個請求都寫 Redis。

5. **`getLoginUser` 靜默失敗**
   JWT 解析失敗、Redis 無 key → 返回 null，由上層過濾器決定「放行匿名」還是「返回 401」。不拋異常。

**滑動過期完整生命週期示意**：

```
12:00  登入 createToken              Redis TTL = 1800s (→12:30)
12:05  請求 → 剩 25 分 > 20 分 → 不動   Redis TTL = 1500s (→12:30)
12:11  請求 → 剩 19 分 ≤ 20 分 → 續期   Redis TTL = 1800s (→12:41)
12:25  請求 → 剩 16 分 ≤ 20 分 → 續期   Redis TTL = 1800s (→12:55)
12:26~12:55  無請求                   自然倒數
12:55  Redis 自動刪除 key              不存在
13:00  用戶回來 → getLoginUser 返回 null → 觸發 401
```

---

#### 9.3 JwtAuthenticationFilter ✅

**職責**：在每個請求進入 Controller 前做四件事：

1. 從 Header 取 JWT → `TokenService.getLoginUser()` 還原 `LoginUser`
2. 若成功 → `verifyToken()` 做滑動續期檢查
3. 包成 `UsernamePasswordAuthenticationToken` 塞進 `SecurityContext`
4. **無論是否成功都放行**——「該不該拒絕」交給 Spring Security 後面的授權階段

**為什麼繼承 `OncePerRequestFilter`？**
同一個請求在 forward / error dispatcher 等場景可能進入過濾鏈多次，`OncePerRequestFilter` 透過 request attribute 標記保證每請求只執行一次，避免 Redis 被重複查詢、SecurityContext 被重複設值。

**為什麼取不到 LoginUser 不直接返回 401？**
放行清單（/login、swagger 等）由 SecurityConfig 管理，授權決策由後續 AuthorizationFilter + AuthenticationEntryPoint 負責。過濾器只管「能認出來就設 context」，職責單一。想像一下 `/swagger-ui.html`：它不該登入但現在沒 token——過濾器直接拒絕就永遠打不開了。

**`UsernamePasswordAuthenticationToken` 三參構造器**

```java
new UsernamePasswordAuthenticationToken(
    loginUser,                   // principal → 業務層可 cast 回 LoginUser
    null,                        // credentials → 已認證階段不需要密碼
    loginUser.getAuthorities()); // authorities → 授權決策用
```

- `principal = loginUser`：業務層 `authentication.getPrincipal()` 可 cast 回 LoginUser
- `credentials = null`：已認證狀態下密碼不應留在記憶體
- 三參構造器內部會把 `authenticated` 設為 `true`，這是標記「已認證」的唯一合法方式

**`authentication == null` 雙重保險**
理論上 `OncePerRequestFilter` 已保證單請求一次，但若將來加了 BasicAuth 等別的認證機制，可能先設過 Authentication——這個判斷讓 JWT 過濾器主動讓位避免互相覆蓋。

**`WebAuthenticationDetailsSource` 的作用**
把 `remoteAddr`、`sessionId` 等請求側資訊綁到 Authentication 上。現在看起來沒用，但 Step 11 操作日誌需要記錄「從哪個 IP 來的請求」時，直接從 Authentication 的 `details` 取，不用再拿 HttpServletRequest。

---

#### 9.4 401 / 403 處理器 ✅

**Spring Security 的兩種「拒絕」**

| 情境 | 觸發條件 | 介面 | HTTP |
|---|---|---|---|
| **未認證** | SecurityContext 沒 Authentication 或是 anonymous | `AuthenticationEntryPoint` | 401 |
| **已認證但無權限** | 有登入但缺少所需權限 | `AccessDeniedHandler` | 403 |

**為什麼不讓 GlobalExceptionHandler 接手？**
401/403 觸發點在 **Spring Security 過濾器鏈內**，請求還沒進 DispatcherServlet，`@RestControllerAdvice` 捕不到。這就是 Step 5.2 GlobalExceptionHandler 顯式跳過 Spring Security 異常的原因。

**為什麼手寫 JSON 而不注入 ObjectMapper？**
處理器是過濾器層組件，依賴要少。`new ObjectMapper()` 夠用，序列化 `R` 物件沒有複雜需求。

**`commence` 這個怪名字**
`AuthenticationEntryPoint` 用 `commence` 而非 `handle`，是因為它的原始設計意圖是「**開始**一個認證流程」（如跳轉登入頁）。REST API 不做跳轉直接返回 JSON，但方法名沒法改。

**log.warn 級別選擇**
這兩類失敗是業務預期內的事件（前端沒帶 token、普通用戶點到管理員按鈕），不是系統異常，用 `warn` 而非 `error`。

---

#### 9.5 SecurityConfig 過濾鏈 ✅

Spring Boot 3 / Spring Security 6 的現代寫法：`@Configuration` + `SecurityFilterChain` bean + 函式式 DSL。**不再使用已移除的 `WebSecurityConfigurerAdapter`**。

**過濾鏈最終樣貌**

```
HTTP 請求
  ↓
DisableEncodeUrlFilter / CorsFilter（由 .cors(...) 插入）
  ↓
┌─────────────────────────────────────────┐
│ JwtAuthenticationFilter  ← 本步驟插入    │
│ （從 Redis 還原 LoginUser → SecurityContext）│
└─────────────────────────────────────────┘
  ↓
UsernamePasswordAuthenticationFilter（表單登入已 disable，不跑）
  ↓
... 其他過濾器 ...
  ↓
AuthorizationFilter（查 SecurityContext → 放行 / 401 / 403）
  ↓
DispatcherServlet → Controller
```

**六段配置**

| 段 | 作用 | 不設的後果 |
|---|---|---|
| `csrf.disable` | 關 CSRF 防護 | POST 請求會被攔截 |
| `formLogin.disable` | 關表單登入 | Spring Security 會攔 `/login` 返回 HTML 登入頁 |
| `httpBasic.disable` | 關 HTTP Basic | 瀏覽器會彈原生彈窗 |
| `sessionManagement STATELESS` | 無狀態 | 會創 JSESSIONID，佔記憶體且影響水平擴展 |
| `authorizeHttpRequests` | 路徑規則 | 放行清單漏了就 401 |
| `exceptionHandling` | 接管 401/403 | 會返回 HTML 錯誤頁 |
| `addFilterBefore` | 插入 JWT 過濾器 | 認證流程不跑 |

**放行清單**
- `/login`、`/logout`、`/captchaImage` — 登入相關（Step 19）
- `/doc.html`、`/swagger-ui/**`、`/v3/api-docs/**`、`/webjars/**` — 文檔（Step 21）
- `/error`、`/favicon.ico` — 平台級

**`csrf.disable` 合理嗎？**
CSRF 防護是為 session-based 認證設計的（攻擊者騙瀏覽器帶 cookie 發請求）。我們用 JWT + Authorization header，瀏覽器不會自動把 header 帶上（cookie 才會），所以 CSRF 天然免疫。

**必須手動暴露的兩個 Bean**
- `PasswordEncoder`：`BCryptPasswordEncoder`，Step 19 登入、Step 17 建用戶都會用
- `AuthenticationManager`：Spring Security 6 不再自動提供，必須從 `AuthenticationConfiguration` 取出。Step 19 登入接口會用

**兩個容易踩的坑**

1. **`@EnableMethodSecurity(prePostEnabled = true)`** 必須加在 `@Configuration` 類上，Spring Security 6 預設不開啟 `@PreAuthorize`，不加會**靜默失效**——最難 debug。
2. **`addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)`** 插入位置必須在表單登入過濾器之前，否則 JWT 認證不會先跑。

---

#### 9.6 PermissionService 權限校驗 ✅

**為什麼要自己寫？** Spring Security 內建 `hasAuthority` / `hasRole`，但直接用有三個問題：
1. 沒有「萬能管理員」（`*:*:*`）概念
2. 多權限任一匹配寫起來冗長：`hasAuthority('a') or hasAuthority('b') or hasAuthority('c')`
3. `ROLE_` 前綴約定容易弄錯

**SpEL 引用 Bean：`@beanName.method(...)`**
`@PreAuthorize` 裡的 `@perm` 表示從容器取名為 `perm` 的 bean 呼叫方法。所以 `@Component("perm")` 的名字是**硬合約**，改名全廢。

**四個對外方法**

| 方法 | 用途 | 示例 |
|---|---|---|
| `hasPerms(String)` | 單權限必有 | `@perm.hasPerms('sys:user:list')` |
| `hasAnyPerms(String)` | 多權限任一（逗號分隔） | `@perm.hasAnyPerms('sys:user:list,sys:user:query')` |
| `hasRole(String)` | 單角色必有 | `@perm.hasRole('admin')` |
| `hasAnyRoles(String)` | 多角色任一 | `@perm.hasAnyRoles('admin,hr')` |

**超級管理員約定**（新增到 `Constants`）
- `ALL_PERMISSION = "*:*:*"` — 通過所有 `hasPerms` 檢查
- `SUPER_ADMIN_ROLE = "admin"` — 通過所有 `hasRole` 檢查

**關鍵設計**

1. **集合包含而非萬用字元**：沒有做 `sys:*:*` 匹配所有 `sys:` 開頭的複雜規則。只有「超級管理員」和「精確權限」兩種。
2. **`hasRole('admin')` 便利性**：業務代碼直接寫 `'admin'`，不用關心 Spring Security 的 `ROLE_` 前綴約定。因為我們比對的是 `LoginUser.getRoles()` 而非 `getAuthorities()`，roles 集合裡存的是原始編碼。
3. **空值一律返回 false**：參數為 null、SecurityContext 無認證、LoginUser 無 permissions → 全部 false。**絕不拋異常**——`@PreAuthorize` 返回 false 會觸發 `AccessDeniedException` → 被 `AccessDeniedHandlerImpl` 接到 → 返回 403 JSON。閉環。
4. **`principal instanceof LoginUser` 判斷**：匿名請求時 principal 是字串 `"anonymousUser"`，不檢查類型直接 cast 會炸。

---

#### 9.7 SecurityUtils 工具類 ✅

> 從 Step 6.2 延後至此（彼時 LoginUser 還未定義）。

**定位**：業務層隨時取「當前登入用戶」，把從 `SecurityContextHolder` 取用的五行重複代碼封裝成**一行靜態呼叫**。

**為什麼是靜態方法而非 @Component？**
- 不需要狀態，全從靜態 `SecurityContextHolder` 取
- 呼叫點不用注入 → 任何一行代碼都能用
- `SecurityContextHolder` 本身就是靜態單例，不違和
- 代價是難 mock，但測試用 Spring Security 官方 `@WithMockUser` 就能解決

**八個方法，兩種風格**

| 方法 | 返回 | 找不到時 | 用途 |
|---|---|---|---|
| `getLoginUser()` | LoginUser | 拋 401 | 必須已登入的業務代碼 |
| `getUserId()` | Long | 拋 401 | — |
| `getUsername()` | String | 拋 401 | — |
| `getDeptId()` | Long | 拋 401 | — |
| `getLoginUserOrNull()` | LoginUser | null | 可選場景（切面、審計） |
| `isLogin()` | boolean | false | 判斷是否已登入 |
| `isAdmin(Long)` | boolean | false | 按 userId 判（Step 18 數據權限用） |
| `isAdmin()` | boolean | false | 判當前用戶 |

**三個細節**

1. **`private` 構造器 + `throw UnsupportedOperationException`** — 工具類標配防禦，防反射強行 new
2. **`instanceof LoginUser` 雙重保險** — 匿名請求時 principal 是字串，避免 ClassCastException
3. **`isAdmin` 拆兩個重載**
   - `isAdmin(Long)` — 給 DataScopeInterceptor（Step 18）用，參數是「被查詢的目標用戶 ID」
   - `isAdmin()` — 業務代碼便捷方式，相當於 `isAdmin(getUserId())`

---

#### 驗收檢查（Step 9）

- [x] `LoginUser` 實作 `UserDetails`，合併 permissions + ROLE_ 前綴 roles
- [x] `JwtProperties` 讀取 yml 的 secret / expiration
- [x] `TokenService` 五大方法齊全，JWT 不設 exp，由 Redis TTL 管過期
- [x] 滑動過期閾值 20 分鐘，避免高頻 Redis 寫入
- [x] `JwtAuthenticationFilter` 繼承 OncePerRequestFilter，靜默放行匿名請求
- [x] `AuthenticationEntryPointImpl` / `AccessDeniedHandlerImpl` 返回統一 R 格式 JSON
- [x] `SecurityConfig` 函式式 DSL 配置，CSRF 關閉、無狀態 session
- [x] `@EnableMethodSecurity(prePostEnabled = true)` 開啟 `@PreAuthorize`
- [x] `AuthenticationManager` + `PasswordEncoder` 暴露為 Bean
- [x] `PermissionService` 以 `@Component("perm")` 名稱註冊
- [x] `SecurityUtils` 靜態工具類，嚴格版 + 寬容版兩套方法
- [x] hr-framework 模塊編譯通過

**延後項**：`UserDetailsServiceImpl` 依賴 `SysUserMapper`，移至 **Step 17 用戶管理**。

完成後進入 → **Step 10：跨域配置**

---

### Step 10：跨域配置 ✅ 已完成

#### 概覽

| 子步驟 | 內容 | 涉及檔案 |
|---|---|---|
| 10.1 | CorsConfig 提供 CorsConfigurationSource Bean | `framework/config/CorsConfig.java` |
| 10.2 | SecurityConfig 啟用 CORS | 修改 `framework/config/SecurityConfig.java` |

#### 為什麼需要 CORS

瀏覽器同源策略禁止 `http://localhost:5173`（Vite 前端）直接調用 `http://localhost:8080`（後端）。後端必須透過 `Access-Control-Allow-*` 響應頭明確允許。

#### 核心概念三連

**1. 預檢請求（Preflight）**
瀏覽器在發「非簡單請求」（如帶 `Authorization` header 的 POST）前，會先發一個 `OPTIONS` 請求探路：

```
OPTIONS /api/users
Origin: http://localhost:5173
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Authorization, Content-Type
```

後端返回允許的源/方法/頭 → 瀏覽器才發真正的 POST。`maxAge` 控制預檢結果緩存多久。

**2. `allowCredentials` 與萬用字元的衝突**
W3C 規範硬性規定：**當 `Access-Control-Allow-Credentials: true` 時，`Access-Control-Allow-Origin` 不能是 `*`**。否則任何站點都能帶著用戶 cookie 攻擊你。

Spring 的解法：用 `setAllowedOriginPatterns("*")` 代替 `setAllowedOrigins("*")`。Pattern 版會動態回填實際 Origin 到響應頭，既通配又合規。

**3. Spring Security 必須明確啟用 CORS**
Security 過濾鏈在 CORS 處理**之前**跑，不啟用的話 OPTIONS 會被當未認證直接返回 401。啟用方式：

```java
http.cors(Customizer.withDefaults());
```

它會自動去容器找 `CorsConfigurationSource` bean。

#### 五個配置決策

| 配置 | 值 | 為什麼 |
|---|---|---|
| `allowedOriginPatterns` | `http://localhost:5173` | Vite 預設端口；配合 credentials 必須用 pattern 版 |
| `allowCredentials` | `true` | 允許前端帶 cookie / Authorization |
| `allowedMethods` | `GET/POST/PUT/DELETE/PATCH/OPTIONS/HEAD` | 完整 REST 方法集 |
| `allowedHeaders` | `*` | 簡化配置，放行所有自訂頭 |
| `exposedHeaders` | `Authorization` | 預設瀏覽器只讓 JS 讀 6 個安全頭，自訂頭要明確暴露 |
| `maxAge` | `3600` | 預檢緩存 1 小時，減少 OPTIONS 請求數 |

#### 生產環境注意

**「白名單地址填的是前端地址而非後端」** — CORS 的 Origin 永遠指「誰在發請求」，也就是前端頁面所在的站點。

| 部署場景 | `allowedOriginPatterns` 應該填 |
|---|---|
| 前後端分離，不同域 | 前端公開網址（如 `https://hr.example.com`） |
| 前端多環境 | 列舉或通配（如 `https://hr*.example.com`） |
| Nginx 反向代理同源部署 | **不需要 CORS**（前端和 `/api/*` 同域） |

**最安全的 CORS 就是不需要 CORS**——生產環境推薦 Nginx 同源部署。

#### 驗收檢查

- [x] `CorsConfig` 提供 `CorsConfigurationSource` Bean
- [x] `allowedOriginPatterns` 使用開發前端地址
- [x] `allowCredentials` + pattern 版合法配合
- [x] `exposedHeaders` 暴露 Authorization
- [x] `SecurityConfig` 啟用 `.cors(Customizer.withDefaults())`
- [x] hr-framework 模塊編譯通過

完成後進入 → **Step 11：操作日誌**

---

### Step 11：操作日誌 ✅ 已完成

#### 概覽

| 子步驟 | 內容 | 涉及檔案 |
|---|---|---|
| 11.1 | 業務類型 / 操作人員類型枚舉 | `common/enums/BusinessType.java` / `common/enums/OperatorType.java` |
| 11.2 | `@Log` 註解 | `framework/aspectj/Log.java` |
| 11.3 | OperLogDTO 數據載體 | `framework/aspectj/OperLogDTO.java` |
| 11.4 | OperLogEvent Spring 事件 | `framework/aspectj/OperLogEvent.java` |
| 11.5 | LogAspect AOP 切面 | `framework/aspectj/LogAspect.java` |

#### 架構方案

```
Controller 方法
  @Log(title="用戶管理", businessType=INSERT)
  ↓
LogAspect @AfterReturning / @AfterThrowing
  ├─ 收集：方法名、URL、IP、請求參數、當前用戶
  ├─ 組裝 OperLogDTO
  ├─ applicationEventPublisher.publishEvent(new OperLogEvent(dto))
  └─ log.info(dto)  ← 本步驟的「持久化」
  ↓
[Step 17+] 業務層加 @EventListener(OperLogEvent.class) → 寫 sys_oper_log 表
```

**本步驟只做發佈端，訂閱端留給業務層**。理由：框架層（hr-framework）不能依賴業務層（hr-system）的 Mapper / Service。Spring 事件做發佈-訂閱解耦，Step 17 業務層加一個 `@EventListener` 即可，框架層零修改。

#### 關鍵設計點

**1. `@AfterReturning` + `@AfterThrowing` 雙 advice 而非 `@Around`**
- `@Around` 必須手動 `proceed()`，忘了就整個接口啞掉
- 我們只要「事後記錄」，沒有流程控制需求
- 兩個方法名對應兩種結局，語意比 try/catch 清晰

**2. 事件解耦分層**
框架層完全不認識業務層的 Mapper / Service，**零依賴顛倒**。這是 hr-framework 能作為獨立模組的關鍵。

**3. IP 獲取兼容反向代理**
生產環境前面通常有 Nginx，`request.getRemoteAddr()` 拿到的是 Nginx 的 IP。按優先級查：
```
X-Forwarded-For → X-Real-IP → Proxy-Client-IP → WL-Proxy-Client-IP → remoteAddr
```
`X-Forwarded-For` 可能是 `client, proxy1, proxy2` 鏈，取第一個（最原始客戶端）。

**4. 超長內容截斷（MAX_JSON_LENGTH = 2000）**
請求體可能是上傳的大 JSON，日誌表直接爆。統一截到 2000 字元加 `...[truncated]` 尾巴。

**5. 參數序列化的白名單攔截**
Controller 方法可能直接接收 `HttpServletRequest` / `MultipartFile`，這些類不能被 Jackson 序列化（會無窮遞迴）。`isSerializable()` 簡易白名單過濾，遇到就 `toString()` 代替。

**6. 日誌異常絕不能影響主業務**
整個 `handleLog` 外面包 `try/catch`，任何失敗只 `log.error` **不拋出**。否則會把正常業務搞成異常。

#### `@Log` 註解的五個屬性

| 屬性 | 預設 | 說明 |
|---|---|---|
| `title` | `""` | 模組標題（「用戶管理」） |
| `businessType` | `OTHER` | 業務類型枚舉 |
| `operatorType` | `MANAGE` | 操作人員類型 |
| `saveRequestData` | `true` | 是否保存請求參數（大 body 可設 false） |
| `saveResponseData` | `true` | 是否保存響應結果 |

#### 如何驗證效果（Step 17+ 可見）

現在沒有任何 Controller 有 `@Log`。到 Step 17 用戶管理時會第一次掛上：

```java
@Log(title = "用戶管理", businessType = BusinessType.INSERT)
@PostMapping
public R<Void> add(@RequestBody SysUser user) { ... }
```

啟動 → 調用 → 控制台就會有 `[操作日誌] OperLogDTO(...)` 輸出。

#### 驗收檢查

- [x] `BusinessType` / `OperatorType` 枚舉就位
- [x] `@Log` 註解支援 title / businessType / operatorType / saveRequestData / saveResponseData
- [x] `LogAspect` 使用 `@AfterReturning` + `@AfterThrowing` 雙 advice
- [x] `OperLogEvent` 解耦業務層持久化
- [x] IP 提取兼容反向代理
- [x] 超長內容截斷 + 序列化白名單保護
- [x] `handleLog` 包 try/catch 保證日誌異常不影響主業務
- [x] hr-framework 模塊編譯通過

---

## 階段三總驗收

| Step | 標題 | 狀態 |
|---|---|---|
| 7 | Redis 配置 | ✅ |
| 8 | MyBatis-Plus 配置 | ✅ |
| 9 | Spring Security + JWT | ✅ |
| 10 | 跨域配置 | ✅ |
| 11 | 操作日誌 | ✅ |

**階段三完成後**：框架層全部就位，業務層（Step 12+）可以直接使用 `@PreAuthorize`、`@Log`、`SecurityUtils`、`RedisCache`、MyBatis-Plus 自動填充等所有框架能力。

完成後進入 → **階段四：業務模塊（Step 12 實體類）**

---

## 踩坑記錄：`/logout` 返回「不支援 GET」（2026-04-15）

### 症狀

前端點擊退出按鈕，後端返回「不支援的 HTTP 方法：GET，支援的方法為：POST」。前端明明發的是 POST。

### 根因

`SecurityConfig` 沒禁用 Spring Security 默認的 `LogoutFilter`，它在 Filter 鏈上早於 Controller：

```
前端 POST /logout
  → LogoutFilter 攔截（認為是自己的默認 url）
  → 執行 session.invalidate() + 清 SecurityContext
  → 302 redirect 到 /login?logout
  → 瀏覽器自動發 GET /login
  → AuthController 只有 @PostMapping("/login") → 返回「不支援 GET」
```

前端看到的「GET 錯誤」不是前端發的，是 LogoutFilter 跳轉鏈路的末端。

### 修復

`SecurityConfig.filterChain` 加一行：

```java
.logout(logout -> logout.disable())
```

### 為什麼必須禁用 LogoutFilter

它為傳統 session-based 應用設計：

| LogoutFilter 幹的事 | 我們的情況 |
|---|---|
| 清 HttpSession | STATELESS，根本沒 session |
| 清 SecurityContext | 每請求從 JWT 重建，當前請求結束就沒了 |
| 302 跳 /login?logout | SPA 路由由前端控制 |
| ❌ **不刪 Redis 的 login_token** | **致命漏洞** |

**關鍵**：LogoutFilter 不知道 Redis 裡還存著 LoginUser。用戶以為登出了，但 JWT 在 TTL 過期前（30 分鐘）仍然有效。我們自訂的 `AuthController.logout()` 調 `TokenService.delLoginUser()` 刪 Redis key，token 立即作廢 —— 這才是真正登出。

### 為什麼登出用 POST 而不是 GET

禁了 LogoutFilter 理論上可以寫 `@GetMapping("/logout")`，但業界慣例用 POST：

1. **GET 會被意外觸發** —— 攻擊者放 `<img src="/logout">` 在評論區，用戶加載頁面就被強制登出
2. **REST 語義** —— GET 應冪等無副作用，登出會刪 Redis key 屬於狀態變更
3. **瀏覽器預取** —— 某些瀏覽器預取 `<a href>` 的 GET 鏈接，鼠標劃過都可能觸發
4. **與 login 對稱** —— login POST，logout 也 POST，風格一致

### 經驗教訓

Spring Security 的默認過濾器（FormLogin / HttpBasic / Logout）都為傳統 Web 應用設計，切到 SPA + JWT 架構時**要顯式禁用**，否則在意料之外的地方攔截請求。SecurityConfig 裡一口氣全禁：

```java
.formLogin(form -> form.disable())
.httpBasic(basic -> basic.disable())
.logout(logout -> logout.disable())
```

之後登入/登出全走自訂 Controller + JwtAuthenticationFilter，鏈路清晰。

---
