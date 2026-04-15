## 階段六：API 文檔 + 測試

### Step 21：Knife4j 集成 ✅

Knife4j 4.4.0（基於 SpringDoc OpenAPI 3）提供 API 文檔 UI，按業務分組、全局 JWT 認證。

#### 產物清單

| 操作 | 檔案 | 說明 |
|---|---|---|
| 新增 | `hr-admin/config/OpenApiConfig.java` | OpenAPI 全局配置 + 3 個分組 + JWT Bearer 認證 |
| 修改 | `hr-common/pom.xml` | 新增 `swagger-annotations-jakarta:2.2.19`（與 Knife4j 版本對齊） |
| 修改 | `application.yml` | `knife4j.setting.language: zh_cn` + springdoc 啟用 |
| 修改 | 7 個 Controller | 加 `@Tag` 註解；AuthController 額外加 `@Operation` |

#### 1. OpenApiConfig

```java
@Bean public OpenAPI openAPI() {
    // 全局 Info + JWT Bearer SecurityScheme
}

@Bean public GroupedOpenApi authGroup()     { pathsToMatch("/login", "/logout", ...); }
@Bean public GroupedOpenApi systemGroup()   { pathsToMatch("/system/**"); }
@Bean public GroupedOpenApi internalGroup() { pathsToMatch("/internal/**"); }
```

**三個分組**：

| 分組 | 路徑匹配 | 包含內容 |
|---|---|---|
| 1-認證接口 | `/login, /logout, /getInfo, /getRouters` | 登入登出 + 用戶資訊 + 動態路由 |
| 2-系統管理 | `/system/**` | 用戶/角色/部門/崗位/菜單 CRUD |
| 3-內部接口 | `/internal/**` | 流程引擎預留端點 |

**JWT 認證**：配置 `SecurityScheme(type=HTTP, scheme=bearer, bearerFormat=JWT)`，doc.html 頁面頂部「Authorize」按鈕輸入 token 後，所有端點自動帶上 `Authorization: Bearer xxx`。

#### 2. Controller @Tag 註解

| Controller | @Tag name |
|---|---|
| `AuthController` | 認證管理 |
| `SysUserController` | 用戶管理 |
| `SysRoleController` | 角色管理 |
| `SysDeptController` | 部門管理 |
| `SysPostController` | 崗位管理 |
| `SysMenuController` | 菜單管理 |
| `InternalApiController` | 內部接口（流程引擎預留） |

> `AuthController` 的 4 個方法額外加了 `@Operation(summary = "...")` 描述。

#### 3. swagger-annotations 依賴

hr-system 的 Controller 需要 `@Tag` 註解，但 hr-system 不依賴 Knife4j。解決：在 `hr-common/pom.xml` 加入僅註解的 `swagger-annotations-jakarta:2.2.19`（< 50KB，無運行時依賴）。

#### 踩坑記錄

- 阿里雲鏡像 `_remote.repositories` 標記了 `swagger-annotations-jakarta:2.2.19` 為「未解析」（JAR 存在但標記缺失），導致離線也找不到。解決：`mvn install:install-file` 重新安裝到本地倉庫。

#### 訪問地址

- 文檔 UI：`http://localhost:8080/api/doc.html`
- OpenAPI JSON：`http://localhost:8080/api/v3/api-docs`

#### 驗收

- `mvn compile -q`（全模組）✅ 通過

### Step 22：接口測試 ⏸️ 暫緩

**決策（2026-04-14）**：手動 doc.html 點測暫緩，後續改用 **Java 編程式測試** 一次到位，同時覆蓋功能 + 併發 + 壓測。

#### 後續方案（待實施）

1. **功能測試層**：JUnit 5 + Spring Boot Test + MockMvc / TestRestTemplate
   - 認證流程（login/logout/getInfo/getRouters）
   - 各模塊 CRUD（dept/post/menu/role/user）
   - 權限校驗（401/403）
   - 邊界場景（刪除約束、唯一性、admin 保護）
2. **併發測試層**：JUnit + `CountDownLatch` / `CompletableFuture`
   - 同一用戶並發登入是否覆蓋 token
   - 並發新增同名用戶（測唯一性鎖）
   - 並發刪除-讀取競態
3. **壓測層**：JMeter 或 Gatling（Scala/Java DSL）
   - 登入接口 QPS
   - 列表查詢 QPS（含數據權限 SQL 注入後的性能影響）
   - Redis 快取命中率觀察

#### 前置修復記錄

- **2026-04-14**：發現 init.sql 權限前綴 `sys:` 與 Controller `system:` 不一致，已用 `sql/fix_perms_prefix.sql` 修復數據庫，admin 不受影響但普通用戶之前會全部 403。

---
