## 階段二：公共模塊 (hr-common)

### Step 4：基礎設施 ✅ 已完成

#### 概覽

| 子步驟 | 內容 | 涉及檔案 |
|---|---|---|
| 4.1 | BaseEntity 實體基類 | `core/domain/BaseEntity.java` |
| 4.2 | R<T> 統一響應體 | `core/domain/R.java` |
| 4.3 | PageResult<T> 分頁響應體 | `core/domain/PageResult.java` |
| 4.4 | PageQuery 分頁請求參數 | `core/domain/PageQuery.java` |
| 4.5 | HttpStatus + Constants 常量類 | `constant/HttpStatus.java`、`constant/Constants.java` |
| 4.6 | 4 個業務枚舉 | `enums/StatusEnum.java`、`GenderEnum.java`、`MenuTypeEnum.java`、`DataScopeEnum.java` |

#### 包結構

```
hr-common/src/main/java/com/hr/common/
  ├── core/domain/
  │   ├── BaseEntity.java          # 實體基類（審計欄位 + 邏輯刪除）
  │   ├── R.java                   # 統一響應體
  │   ├── PageResult.java          # 分頁響應體
  │   └── PageQuery.java           # 分頁請求參數
  ├── constant/
  │   ├── HttpStatus.java          # HTTP/業務狀態碼
  │   └── Constants.java           # 通用常量、Redis Key 前綴等
  ├── enums/
  │   ├── StatusEnum.java          # 0正常 / 1停用
  │   ├── GenderEnum.java          # 0未知 / 1男 / 2女
  │   ├── MenuTypeEnum.java        # M目錄 / C菜單 / F按鈕
  │   └── DataScopeEnum.java       # 1全部 / 2自訂 / 3本部門 / 4本部門及以下 / 5僅本人
  └── package-info.java
```

---

#### 4.1 BaseEntity 實體基類

**目的**：所有資料庫表都有 `create_by / create_time / update_by / update_time / deleted` 5 個共有欄位，抽到父類避免重複。

**關鍵點**：
- `@TableField(fill = FieldFill.INSERT)` — 插入時自動填充（用於 createBy、createTime）
- `@TableField(fill = FieldFill.INSERT_UPDATE)` — 插入和更新都填充（用於 updateBy、updateTime）
- `@TableLogic` — 邏輯刪除欄位，搭配 application.yml 的 `logic-delete-field: deleted` 生效
- `@JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")` — 時間 JSON 序列化格式
- `implements Serializable` + `serialVersionUID = 1L` — 為 Redis 緩存、深拷貝等場景做準備
- 用 `@Getter @Setter` 而非 `@Data`，避免父類覆蓋子類的 `toString/equals`

**待後續配套**：
- MetaObjectHandler（Step 7 hr-framework）— 真正執行 createBy/createTime 自動填充
- 子實體類（Step 9+）— SysUser、SysDept 等 extends BaseEntity

---

#### 4.2 R<T> 統一響應體

**目的**：所有 Controller 返回值統一包裝為 `{ code, msg, data }` 結構，前端只需處理一種格式。

**欄位**：
- `code` — 狀態碼（int，避免 NPE）
- `msg` — 提示訊息
- `data` — 業務數據（泛型 T）

**靜態工廠方法**：
- 成功：`R.ok()` / `R.ok(data)` / `R.ok(msg, data)` / `R.ok(msg)`
- 失敗：`R.fail()` / `R.fail(msg)` / `R.fail(code, msg)`
- 工具：`isSuccess()`

**設計細節**：
- 用 `@Data`（=`@Getter @Setter @ToString @EqualsAndHashCode`），響應體日誌打印需要 toString
- 靜態方法寫 `<T>` 是方法級別的泛型聲明，呼叫端可推斷 T
- 內建 `SUCCESS=200`、`FAIL=500`，後續會改為引用 `HttpStatus.SUCCESS / ERROR`

**典型使用**：
```java
return R.ok(user);
return R.fail("用戶名已存在");
return R.fail(HttpStatus.UNAUTHORIZED, "未授權");
```

---

#### 4.3 PageResult<T> 分頁響應體

**目的**：分頁查詢有固定 4 個資訊（total / rows / pageNum / pageSize），單獨封裝便於前端 `el-table` + `el-pagination` 解析。

**欄位**：`total`、`rows`、`pageNum`、`pageSize`（均為 long，跟著 MyBatis-Plus IPage 類型走）

**靜態工廠方法**：
- `PageResult.of(IPage<T>)` — 從 MyBatis-Plus 的 IPage 一行轉換
- `PageResult.empty()` — 空結果（`Collections.emptyList()`，零分配）

**為什麼不直接返回 IPage？**
IPage 欄位名是 `records / current / size`，不夠直觀；封裝後欄位語意化，且未來換 ORM 不影響 Controller。

**典型使用**：
```java
@GetMapping("/list")
public R<PageResult<SysUser>> list(SysUserQuery query) {
    IPage<SysUser> page = userService.selectPage(query);
    return R.ok(PageResult.of(page));
}
```

---

#### 4.4 PageQuery 分頁請求參數

**目的**：所有分頁查詢的請求 DTO 繼承此類，自動具備分頁與排序欄位。

**欄位**：
- `pageNum` / `pageSize`（Long，可為 null）
- `orderByColumn` — 排序欄位名
- `isAsc` — 排序方向（"asc" / "desc"，跟 RuoYi 風格一致）

**常量**：
- `DEFAULT_PAGE_NUM = 1`
- `DEFAULT_PAGE_SIZE = 10`
- `MAX_PAGE_SIZE = 500`（防止前端傳過大值拖垮 DB）

**核心方法**：
- `<T> Page<T> buildPage()` — 構造 MyBatis-Plus 的 Page 對象（方法級泛型，T 由呼叫方決定）
- `getSafePageNum()` / `getSafePageSize()` — 校驗合法性（非法時返回默認值或上限），保留原始值便於日誌排查

**⚠️ 安全提醒**：`orderByColumn` 是 SQL 注入高危點，後續 Service 實作時要做白名單校驗。

**典型使用**：
```java
public class SysUserQuery extends PageQuery {
    private String username;
    private Integer status;
}
// Service 層
Page<SysUser> page = query.buildPage();
return userMapper.selectPage(page, wrapper);
```

---

#### 4.5 HttpStatus + Constants 常量類

**HttpStatus.java** — 集中管理 HTTP/業務狀態碼：
- 2xx：SUCCESS(200)、CREATED(201)、ACCEPTED(202)、NO_CONTENT(204)
- 3xx：MOVED_PERM(301)、SEE_OTHER(303)、NOT_MODIFIED(304)
- 4xx：BAD_REQUEST(400)、UNAUTHORIZED(401)、FORBIDDEN(403)、NOT_FOUND(404)、BAD_METHOD(405)、CONFLICT(409)、UNSUPPORTED_TYPE(415)
- 5xx：ERROR(500)、NOT_IMPLEMENTED(501)、SERVICE_UNAVAILABLE(503)
- 業務碼：WARN(601)（前端顯示黃色警告框，與 500 紅色錯誤區分）

**Constants.java** — 通用常量：
- 字符編碼：UTF8、GBK
- 通用標誌：SUCCESS("0")、FAIL("1")、YES("Y")、NO("N")、TRUE、FALSE
- 用戶相關：SYSTEM_USER、ANONYMOUS、ADMIN_USERNAME、ADMIN_USER_ID(1L)、ADMIN_ROLE_ID(1L)
- 樹狀結構：TOP_PARENT_ID(0L)、ANCESTORS_SEPARATOR(",")
- HTTP：HTTP、HTTPS
- Token / 認證：TOKEN_HEADER("Authorization")、TOKEN_PREFIX("Bearer ")、JWT_USER_ID、JWT_USERNAME
- Redis Key 前綴：LOGIN_TOKEN_KEY、USER_PERMS_KEY、USER_ROLES_KEY、CAPTCHA_KEY、RATE_LIMIT_KEY

**設計原則**：
- 兩個類都用 `final class` + 私有構造器，禁止實例化和繼承
- Redis Key 用 `:` 分隔（Redis 慣例，配合 RedisInsight 工具樹狀展示）
- Key 前綴以冒號結尾，方便拼接：`LOGIN_TOKEN_KEY + userId` → `login_token:1`

---

#### 4.6 4 個業務枚舉

| 枚舉 | code 類型 | 取值 | 對應欄位 |
|---|---|---|---|
| StatusEnum | Integer | NORMAL(0) / DISABLED(1) | sys_user.status 等 |
| GenderEnum | Integer | UNKNOWN(0) / MALE(1) / FEMALE(2) | sys_user.gender |
| MenuTypeEnum | String | DIR("M") / MENU("C") / BUTTON("F") | sys_menu.menu_type |
| DataScopeEnum | Integer | ALL(1) / CUSTOM(2) / DEPT(3) / DEPT_AND_CHILD(4) / SELF(5) | sys_role.data_scope |

**統一結構**：每個枚舉都包含
- `code`（資料庫值）+ `desc`（中文描述）
- `@Getter` 自動生成 getter
- `getByCode(code)` — 從資料庫值反查枚舉，找不到返回 null
- `isValid(code)` — 校驗值合法性

**設計細節**：
- 為什麼用枚舉而非常量類？這 4 組值都是「有限互斥 + 編碼-描述成對 + 可迭代」場景
- 為什麼 MenuTypeEnum 的 code 是 String？因為 init.sql 裡 menu_type 是 CHAR(1)，存的就是 'M'/'C'/'F' 字面字母
- 為什麼 code 用 Integer 而非 int？方法參數可能為 null（前端 JSON / DB 查詢結果），用 Integer 才能判空提前返回
- 為什麼 Entity 不直接用枚舉欄位？目前 Entity 仍用 Integer，業務層再用 `StatusEnum.getByCode(...)` 轉換，更靈活、容錯性更好（將來 DB 加新狀態時不會反序列化失敗）
- 為什麼不抽 BaseEnum 接口？避免過度設計，4 個枚舉各 30 行還在可接受範圍

---

#### 驗收檢查

- [x] hr-common 模塊編譯通過（`mvn -pl hr-common -am compile`）
- [x] 包結構符合架構規範（core/domain、constant、enums）
- [x] 所有 POJO 實現 Serializable 並聲明 serialVersionUID
- [x] 所有靜態工廠方法/常量類使用 final class + 私有構造器
- [x] 4 個枚舉均提供 getByCode() 與 isValid() 工具方法

完成後進入 → **Step 5：異常處理**

### Step 5：異常處理 ✅ 已完成

#### 概覽

| 子步驟 | 內容 | 涉及檔案 |
|---|---|---|
| 5.1 | BusinessException 業務異常 | `core/exception/BusinessException.java` |
| 5.2 | GlobalExceptionHandler 全局異常處理器 | `core/exception/GlobalExceptionHandler.java` |

#### 包結構新增

```
hr-common/src/main/java/com/hr/common/
  └── core/exception/
      ├── BusinessException.java        # 業務異常
      └── GlobalExceptionHandler.java   # 全局異常處理器
```

---

#### 5.1 BusinessException 業務異常

**目的**：把**業務異常**和**系統異常**分開。
- 業務異常（用戶名已存在、密碼錯誤、庫存不足）→ 預期內，msg 可原樣返回前端
- 系統異常（NPE、SQL、磁碟滿）→ 預期外，記日誌 + 返回兜底訊息

**為什麼繼承 RuntimeException 而非 Exception？**
- 不強制 try-catch / throws，業務代碼乾淨
- 與 Spring 全家桶（DataAccessException、TransactionException）保持一致風格

**欄位**：
- `code`（int，final）— 錯誤碼，預設 `HttpStatus.ERROR (500)`
- `message`（繼承自 RuntimeException）

**4 個構造器**：
| 構造器 | 場景 |
|---|---|
| `BusinessException(msg)` | 最常見，預設 code=500 |
| `BusinessException(code, msg)` | 自訂狀態碼（401/403/409 等） |
| `BusinessException(msg, cause)` | 包裝其他異常但仍當業務異常處理 |
| `BusinessException(code, msg, cause)` | 完整版 |

**設計細節**：
- `code` 用 `final` 強制不可變，與 RuntimeException.message 保持一致
- 用 `@Getter` 而非 `@Data`：code 是 final 沒 setter，異常物件不應該用 equals 比較
- **不在構造器寫日誌**：業務異常頻繁觸發，由 GlobalExceptionHandler 統一決定日誌級別
- `serialVersionUID = 1L`（RuntimeException 已實現 Serializable）

**典型使用**：
```java
throw new BusinessException("用戶名已存在");
throw new BusinessException(HttpStatus.FORBIDDEN, "帳號已停用");
throw new BusinessException("外部服務不可用", ioException);
```

---

#### 5.2 GlobalExceptionHandler 全局異常處理器

**目的**：統一捕獲所有 Controller 拋出的異常，包裝成標準 `R<?>` 響應返回前端。

**核心註解**：
- `@RestControllerAdvice` = `@ControllerAdvice` + `@ResponseBody`，全局攔截 + 自動 JSON
- `@Slf4j` — Lombok 自動生成 log 物件
- `@ExceptionHandler(XxxException.class)` — 標記某方法處理某種異常

**處理的 9 種異常**：

| # | 異常類型 | HTTP 碼 | 日誌級別 | 觸發場景 |
|---|---|---|---|---|
| 1 | BusinessException | 自訂（默認 500） | WARN | 業務代碼主動拋出 |
| 2 | MethodArgumentNotValidException | 400 | WARN | `@RequestBody @Valid` 校驗失敗 |
| 3 | BindException | 400 | WARN | `@ModelAttribute @Valid` 校驗失敗（form/query） |
| 4 | ConstraintViolationException | 400 | WARN | Controller 上 `@Validated` + 單參數校驗 |
| 5 | MissingServletRequestParameterException | 400 | WARN | 必填參數缺失 |
| 6 | HttpMessageNotReadableException | 400 | WARN | JSON 解析失敗 |
| 7 | HttpRequestMethodNotSupportedException | 405 | WARN | HTTP 方法不允許 |
| 8 | NoHandlerFoundException | 404 | WARN | 路徑不存在 |
| 9 | Exception（兜底） | 500 | **ERROR**（含完整堆疊） | 預期外的系統異常 |

**設計細節**：

1. **業務異常 vs 系統異常的日誌級別差異**
   - WARN：用戶可自行處理、不需告警；ERROR：觸發監控告警
   - 如果業務異常用 ERROR，會把告警系統淹沒，半夜把開發叫起來

2. **系統異常絕不返回原始 message**
   - `e.getMessage()` 可能含表名、欄位名、IP、token 等敏感資訊
   - 統一返回「系統繁忙，請稍後重試」，技術細節只進日誌

3. **`log.error("...", e.getMessage(), e)` 最後的 e 是關鍵**
   - SLF4J 約定：最後一個 Throwable 參數會打印完整堆疊，前面的 `{}` 不會消費它
   - 線上問題排查必須要有完整 stack trace

4. **Spring Security 異常不在此處理**
   - `AccessDeniedException` / `AuthenticationException` 由 Step 8 配置的 `AuthenticationEntryPoint` 和 `AccessDeniedHandler` 統一處理（這是 Security 的標準做法）
   - 這樣 hr-common 不用引入 spring-security 依賴，保持模組職責清晰

5. **`formatFieldError` 私有工具方法**
   - 3 個校驗異常處理器共用，把 FieldError 轉成 `"username: 不能為空"` 字串
   - 抽取出來避免重複，將來改格式只改一處

6. **`@RestControllerAdvice` 跨模組生效原理**
   - 它本身是 `@Component`，會被 Spring 掃描
   - 啟動類 `HrApplication` 配置了 `scanBasePackages = "com.hr"`，自動發現 hr-common 下的 advice

**待後續配套**：
- `NoHandlerFoundException` 需要在 `application.yml` 加配置才會觸發（Step 7 補上）：
  ```yaml
  spring:
    mvc:
      throw-exception-if-no-handler-found: true
    web:
      resources:
        add-mappings: false
  ```

---

#### 驗收檢查

- [x] hr-common 模塊編譯通過（`mvn -pl hr-common -am compile`）
- [x] BusinessException 繼承 RuntimeException、code 為 final
- [x] GlobalExceptionHandler 處理 9 種異常，業務 WARN / 系統 ERROR
- [x] 系統異常不暴露原始 message，記錄完整堆疊
- [x] hr-common 未引入 spring-security 依賴

完成後進入 → **Step 6：工具類**

### Step 6：工具類 🔄 進行中

#### 概覽

| 子步驟 | 內容 | 狀態 | 涉及檔案 |
|---|---|---|---|
| 6.1 | TreeNode + TreeUtils 樹結構工具 | ✅ | `core/tree/TreeNode.java`、`core/tree/TreeUtils.java` |
| 6.2 | SecurityUtils 認證工具 | ⏸️ **移至 Step 8** | （與 Spring Security 配置一起做） |

#### ⚠️ 順序調整說明

原計畫先寫 SecurityUtils，但它需要從 `SecurityContextHolder` 取 `LoginUser` 物件，
而 `LoginUser` 要在 Step 8 配置 Spring Security 時才能定義（依賴 `UserDetails` 接口）。
若此時硬寫一個簡化版，到 Step 8 還要回頭重寫，違反「不寫過渡代碼」原則。

**決策**：SecurityUtils 移到 Step 8，與 Spring Security 配置一起做。Step 6 只做 TreeUtils。

#### 包結構新增

```
hr-common/src/main/java/com/hr/common/
  └── core/tree/
      ├── TreeNode.java        # 樹節點契約接口
      └── TreeUtils.java       # 樹構建/展平工具
```

---

#### 6.1 TreeNode + TreeUtils 樹結構工具

**目的**：把扁平列表轉換成樹形結構返回前端。HR 系統至少 3 處要用：
1. 部門樹（sys_dept）— 公司 → 部門 → 子部門
2. 菜單樹（sys_menu）— 目錄 → 菜單 → 按鈕
3. 角色-部門權限樹（前端勾選用）

**核心問題**：不同實體欄位名不同（`deptId` vs `menuId`），如何複用？

| 方案 | 做法 | 取捨 |
|---|---|---|
| A. 反射 | 運行時取 id / parentId / children | 慢、不安全、難除錯 |
| B. 接口契約（✅ 採用） | 定義 TreeNode 接口，實體類實作它 | 類型安全、編譯期校驗、零反射 |

---

**TreeNode 接口**（`core/tree/TreeNode.java`）

```java
public interface TreeNode<T extends TreeNode<T>> {
    Long getId();
    Long getParentId();
    List<T> getChildren();
    void setChildren(List<T> children);
}
```

**遞迴泛型 `<T extends TreeNode<T>>` 的意義**：
確保 `getChildren()` 返回的列表元素是同類型 —— 例如 `SysDept implements TreeNode<SysDept>` 時，`getChildren()` 必定返回 `List<SysDept>` 而不是 `List<SysMenu>`，編譯期就能校驗，調用方無需強轉。

---

**TreeUtils 工具類**（`core/tree/TreeUtils.java`）

提供 3 個方法：

| 方法 | 簽名 | 用途 |
|---|---|---|
| `build(list)` | `static <T extends TreeNode<T>> List<T> build(List<T>)` | 從預設頂級節點（`Constants.TOP_PARENT_ID = 0`）構建樹 |
| `build(list, rootId)` | `static <T extends TreeNode<T>> List<T> build(List<T>, Long)` | 從指定父節點構建子樹 |
| `flatten(tree)` | `static <T extends TreeNode<T>> List<T> flatten(List<T>)` | 把樹再展平回列表（深度優先遍歷） |

**核心算法**（O(n)，兩次線性掃描）：

```java
// 第一遍：按 parentId 分組建 Map 索引
Map<Long, List<T>> childrenMap = new HashMap<>();
for (T node : list) {
    childrenMap.computeIfAbsent(node.getParentId(), k -> new ArrayList<>()).add(node);
}
// 第二遍：給每個節點掛上自己的子節點
for (T node : list) {
    List<T> children = childrenMap.get(node.getId());
    node.setChildren(children == null ? new ArrayList<>() : children);
}
// 返回所有以 rootId 為父的節點（即頂層）
return childrenMap.getOrDefault(rootId, Collections.emptyList());
```

**為什麼不用樸素遞迴 O(n²)？**
樸素做法每個節點都遍歷整個列表找子節點：100 個節點 1 萬次、1000 個節點 100 萬次。
Map 索引做法兩次線性掃描搞定，複雜度降一個數量級，代碼也不複雜。

**為什麼兩遍而不是一遍？**
一遍掃描時，當前節點的子節點可能還沒被掃到（取決於 DB 返回順序）。
兩遍掃描**不依賴節點順序**：第一遍把所有節點按 parentId 分組進 Map，第二遍直接從 Map 查。

---

#### 設計細節補充

**1. `computeIfAbsent` 的優勢**
```java
childrenMap.computeIfAbsent(parentId, k -> new ArrayList<>()).add(node);
```
JDK 8+ 原子操作，只做一次哈希查找。等價於 `containsKey` + `get/put` + `add`，但性能更好、代碼更短。

**2. `flatten()` 反向方法的價值**
實際業務常用：
```java
// 根據父部門 ID 找所有後代部門 ID（含本身）
List<SysDept> tree = TreeUtils.build(allDepts, parentId);
List<Long> allDescendantIds = TreeUtils.flatten(tree).stream()
    .map(SysDept::getId)
    .toList();
```
這在 `DataScopeEnum.DEPT_AND_CHILD`（本部門及下級）數據權限過濾時必用。

**3. 不會死遞迴**
每個節點的 `children` 從 Map 取的是引用，Map 裡的列表只在第一遍 add 過一次。
第二遍只是掛引用，不再添加，不會循環。

**4. 為什麼 `rootId` 用 Long 參數而不是寫死 0？**
- 支援構建子樹（從某個部門節點開始）
- 處理特殊根 ID（某些舊系統用 -1 或 null）

**5. 空列表返回 `Collections.emptyList()`**
不可變單例空列表，零分配，性能更好，調用方只讀不會 add 元素。

---

#### 後續引用場景預覽

| 引用方 | 場景 | 步驟 |
|---|---|---|
| `SysDept` | `implements TreeNode<SysDept>`，children 用 `@TableField(exist=false)` | Step 12 |
| `SysMenu` | `implements TreeNode<SysMenu>`，children 用 `@TableField(exist=false)` | Step 12 |
| `SysDeptService.getDeptTree()` | `TreeUtils.build(deptMapper.selectList(null))` | Step 13 |
| `SysMenuService.buildMenuTreeByUserId()` | 過濾按鈕後構建菜單樹 | Step 15 |
| `DataScopeAspect` | `TreeUtils.flatten(...)` 取所有下級部門 ID | Step 18 |

---

#### 驗收檢查

- [x] `com.hr.common.core.tree.TreeNode` 接口建立（遞迴泛型）
- [x] `com.hr.common.core.tree.TreeUtils` 工具類建立（`final class` + 私有構造器）
- [x] 提供 `build(list)` / `build(list, rootId)` / `flatten(tree)` 三個方法
- [x] 算法時間複雜度 O(n)，不依賴節點順序
- [x] hr-common 模塊編譯通過（`mvn -pl hr-common -am compile`）
- [ ] SecurityUtils — **推遲到 Step 8 執行**

完成後進入 → **Step 7：Redis 配置**

---
