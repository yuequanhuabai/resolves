## 階段四：業務模塊 (hr-system)

### Step 12：實體類 ✅

按 `backend_architecture.md` 數據庫設計，於 `hr-system/domain/` 建立 8 個實體：

| 檔案 | 繼承 | 關鍵點 |
|---|---|---|
| `SysUser.java` | BaseEntity | `@TableLogic` 由父類接管；`@JsonIgnore password`；`@TableField(exist=false) Long[] roleIds` |
| `SysDept.java` | BaseEntity, `TreeNode<SysDept>` | 含 `ancestors` 祖先鏈；`children` 非 DB 欄位 |
| `SysPost.java` | BaseEntity | 簡單字典表 |
| `SysRole.java` | BaseEntity | `dataScope` 控制數據範圍；`menuIds / deptIds` 非 DB 欄位 |
| `SysMenu.java` | **不繼承** BaseEntity（`sys_menu` 無 deleted 欄位），實作 `TreeNode<SysMenu>` | 自行宣告 4 個審計欄位 + `@TableField` fill |
| `SysUserRole.java` | 純 POJO | userId / roleId |
| `SysRoleMenu.java` | 純 POJO | roleId / menuId |
| `SysRoleDept.java` | 純 POJO | roleId / deptId（數據權限用） |

**踩坑記錄：**
`sys_menu` 表沒有 `deleted` 欄位，若盲目繼承 `BaseEntity` 會導致 MP 自動拼 `deleted = 0` 條件，查詢報 SQL Server「無效的列名 'deleted'」。解決：`SysMenu` 獨立宣告 `createBy / createTime / updateBy / updateTime`，以 `@TableField(fill=INSERT / INSERT_UPDATE)` 由 `MyMetaObjectHandler` 自動填值。

---

### Step 13：部門管理 ✅

部門是樹形結構，也是數據權限的最小單位，故先於用戶實作。

#### 產物清單

| 層 | 檔案 | 職責 |
|---|---|---|
| Mapper | `hr-system/mapper/SysDeptMapper.java` | 基礎 CRUD + 自訂 SQL |
| Service | `hr-system/service/ISysDeptService.java` | 介面 |
| Service Impl | `hr-system/service/impl/SysDeptServiceImpl.java` | 業務邏輯 |
| Controller | `hr-system/controller/SysDeptController.java` | REST API |

#### 1. SysDeptMapper

繼承 `BaseMapper<SysDept>` 獲得 MP 基礎 CRUD，額外提供 4 個自訂查詢（均用 `@Select / @Update` 註解式，避免建 XML）：

```java
@Select("SELECT COUNT(1) FROM sys_dept WHERE parent_id = #{deptId} AND deleted = 0")
int countChildByDeptId(@Param("deptId") Long deptId);

@Select("SELECT COUNT(1) FROM sys_user WHERE dept_id = #{deptId} AND deleted = 0")
int countUserByDeptId(@Param("deptId") Long deptId);

@Select("SELECT dept_id FROM sys_role_dept WHERE role_id = #{roleId}")
List<Long> selectDeptIdsByRoleId(@Param("roleId") Long roleId);

@Update("UPDATE sys_dept SET ancestors = REPLACE(ancestors, #{oldPath}, #{newPath}) " +
        "WHERE deleted = 0 AND (ancestors = #{oldPath} OR ancestors LIKE #{oldPath} + ',%')")
int updateDeptChildrenAncestors(@Param("oldPath") String oldPath,
                                @Param("newPath") String newPath);
```

> **SQL Server 字串拼接用 `+`**，不是 MySQL 的 `CONCAT`。`LIKE #{oldPath} + ',%'` 表示「舊路徑是前綴，且後面緊跟一個逗號」，精準匹配後代節點。

#### 2. ISysDeptService / SysDeptServiceImpl

介面繼承 `IService<SysDept>`，實作類繼承 `ServiceImpl<SysDeptMapper, SysDept>`，白嫖所有 MP 基礎方法。自訂業務邏輯集中在三個寫入方法：

**`insertDept`：自動計算 ancestors**

```java
if (parentId == null || TOP_PARENT_ID.equals(parentId)) {
    dept.setParentId(TOP_PARENT_ID);
    dept.setAncestors("0");  // 頂級部門 ancestors = "0"
} else {
    SysDept parent = getById(parentId);
    if (parent == null)                               throw ...;  // 父不存在
    if (!NORMAL.equals(parent.getStatus()))           throw ...;  // 父已停用
    dept.setAncestors(parent.getAncestors() + "," + parent.getDeptId());
}
```

**`updateDept`：級聯更新子部門 ancestors**（最複雜的部分）

情境：部門 5 從 parent=1 搬到 parent=3。
- 舊路徑 `oldFullPath = oldDept.ancestors + "," + deptId`，例如 `"0,1,5"`
- 新路徑 `newFullPath = newParent.ancestors + "," + newParent.deptId + "," + deptId`，例如 `"0,2,3,5"`
- 呼叫 `updateDeptChildrenAncestors(oldFullPath, newFullPath)` 用 `REPLACE` 批次改所有後代：
  - dept 10 ancestors：`"0,1,5"` → `"0,2,3,5"`
  - dept 20 ancestors：`"0,1,5,10"` → `"0,2,3,5,10"`

**環路防護**：若 `newParent.ancestors` 等於 `oldFullPath` 或以 `oldFullPath + ","` 開頭，代表把父部門設為自己的後代，拋例外。

**`deleteDeptById`：刪除前校驗**
- `hasChildByDeptId` → 有子部門拒絕
- `checkDeptExistUser` → 有關聯用戶拒絕

#### 3. SysDeptController

6 個 REST 端點，全部掛 `@PreAuthorize("@perm.hasPerms('...')")`，寫入類額外掛 `@Log`：

| Method | Path | 權限 | 日誌 |
|---|---|---|---|
| GET | `/system/dept/list` | `system:dept:list` | - |
| GET | `/system/dept/tree` | `system:dept:list` | - |
| GET | `/system/dept/{deptId}` | `system:dept:query` | - |
| POST | `/system/dept` | `system:dept:add` | `INSERT` |
| PUT | `/system/dept` | `system:dept:edit` | `UPDATE` |
| DELETE | `/system/dept/{deptId}` | `system:dept:remove` | `DELETE` |

#### 驗收

- `mvn -pl hr-system -am compile -q` ✅ 通過
- `TreeUtils.build()` 拿到扁平列表 → 樹形結構，供前端 `el-tree` / `a-tree` 直接渲染
- 刪除校驗、環路防護、ancestors 級聯全部齊活，可交付後續的用戶管理模組直接複用

### Step 14：崗位管理 ✅

崗位是簡單字典表，無樹形結構，走標準分頁 CRUD 模式。

#### 產物清單

| 層 | 檔案 | 職責 |
|---|---|---|
| Mapper | `hr-system/mapper/SysPostMapper.java` | 基礎 CRUD + `countUserByPostId` |
| Service | `hr-system/service/ISysPostService.java` | 介面 |
| Service Impl | `hr-system/service/impl/SysPostServiceImpl.java` | 業務邏輯 |
| Controller | `hr-system/controller/SysPostController.java` | REST API |

#### 1. SysPostMapper

繼承 `BaseMapper<SysPost>` 獲得所有 MP 基礎方法，僅額外提供一個自訂查詢：

```java
@Select("SELECT COUNT(1) FROM sys_user WHERE post_id = #{postId} AND deleted = 0")
int countUserByPostId(@Param("postId") Long postId);
```

> 刪除崗位前校驗：該崗位下是否有關聯用戶。

#### 2. ISysPostService / SysPostServiceImpl

與部門的差異：
- **分頁查詢**：使用 `PageQuery.buildPage()` → `page(page, wrapper)` → `PageResult.of(result)` 三步式分頁，前端傳 `pageNum / pageSize`
- **全量下拉**：`selectPostAll()` 只返回 `status = 0`（正常）的崗位，供新增/編輯用戶時的下拉選項
- **雙重唯一性**：新增/修改前同時校驗 `postCode` 和 `postName`，排除自身 ID
- **批量刪除**：`deletePostByIds(Long[])` 逐一校驗用戶關聯，任一崗位有用戶即拒絕整批刪除

#### 3. SysPostController

7 個 REST 端點：

| Method | Path | 權限 | 日誌 | 說明 |
|---|---|---|---|---|
| GET | `/system/post/list` | `system:post:list` | - | 分頁列表 |
| GET | `/system/post/all` | `system:post:list` | - | 全量下拉選項 |
| GET | `/system/post/{postId}` | `system:post:query` | - | 詳情 |
| POST | `/system/post` | `system:post:add` | `INSERT` | 新增 |
| PUT | `/system/post` | `system:post:edit` | `UPDATE` | 修改 |
| DELETE | `/system/post/{postIds}` | `system:post:remove` | `DELETE` | 批量刪除 |

> 批量刪除路徑 `/{postIds}` 接收逗號分隔的 ID，Spring 自動切割為 `Long[]`，例如 `DELETE /system/post/1,2,3`。

#### 驗收

- `mvn -pl hr-system -am compile -q` ✅ 通過

### Step 15：菜單管理 ✅

菜單是樹形結構，同時承載**權限標識**（perms）和**前端路由**兩個職責。與部門的關鍵差異：物理刪除（無 `deleted` 欄位）、多表 JOIN 查詢權限。

#### 產物清單

| 層 | 檔案 | 職責 |
|---|---|---|
| Mapper | `hr-system/mapper/SysMenuMapper.java` | 基礎 CRUD + 4 個自訂 SQL |
| Service | `hr-system/service/ISysMenuService.java` | 介面（10 個方法） |
| Service Impl | `hr-system/service/impl/SysMenuServiceImpl.java` | 業務邏輯 |
| Controller | `hr-system/controller/SysMenuController.java` | REST API（7 個端點） |

#### 1. SysMenuMapper

繼承 `BaseMapper<SysMenu>`，額外 4 個 `@Select / @Update` 註解式查詢（無 XML）：

| 方法 | SQL 要點 | 用途 |
|---|---|---|
| `selectPermsByUserId` | 四表 JOIN：`sys_menu → sys_role_menu → sys_user_role → sys_role`，取 DISTINCT perms | 登入時載入用戶權限集合 |
| `selectMenusByUserId` | 同上四表 JOIN，只取 `menu_type IN ('M','C')`（不含按鈕） | 構建前端側邊欄路由 |
| `selectMenuIdsByRoleId` | `SELECT menu_id FROM sys_role_menu WHERE role_id = ?` | 角色菜單分配頁面回顯 |
| `countChildByMenuId` | `SELECT COUNT(1) FROM sys_menu WHERE parent_id = ?` | 刪除前校驗子菜單 |

> **注意**：`sys_menu` 無 `deleted` 欄位，上述查詢不帶 `deleted = 0` 條件；而 JOIN 到 `sys_role` 時仍需 `r.deleted = 0 AND r.status = 0`。

#### 2. ISysMenuService / SysMenuServiceImpl

核心邏輯：

- **`selectPermsByUserId`**：超級管理員（`userId = 1`）直接返回 `Set.of("*:*:*")`，不走 DB
- **`selectMenuTreeByUserId`**：超級管理員查全量目錄+菜單；普通用戶走四表 JOIN → `TreeUtils.build` 構建樹
- **`validateMenuType`** 私有校驗方法：
  - 目錄（M）：必須填 `path`
  - 菜單（C）：必須填 `path` + `component`
  - 按鈕（F）：無限制
- **物理刪除**：`removeById` 直接 DELETE，刪除前校驗 `hasChildByMenuId`
- **名稱唯一性**：同父菜單下不允許重名

#### 3. SysMenuController

| Method | Path | 權限 | 日誌 | 說明 |
|---|---|---|---|---|
| GET | `/system/menu/list` | `system:menu:list` | - | 扁平列表 |
| GET | `/system/menu/tree` | `system:menu:list` | - | 樹形結構 |
| GET | `/system/menu/roleMenuIds/{roleId}` | `system:menu:list` | - | 角色已分配菜單 ID |
| GET | `/system/menu/{menuId}` | `system:menu:query` | - | 詳情 |
| POST | `/system/menu` | `system:menu:add` | `INSERT` | 新增 |
| PUT | `/system/menu` | `system:menu:edit` | `UPDATE` | 修改 |
| DELETE | `/system/menu/{menuId}` | `system:menu:remove` | `DELETE` | 刪除（物理） |

> 菜單總量有限（通常 < 200 筆），全量查回構建樹，不走分頁。

#### 驗收

- `mvn -pl hr-system -am compile -q` ✅ 通過

### Step 16：角色管理 ✅

角色是權限模型的核心——連接用戶、菜單（功能權限）、部門（數據權限）三者。涉及三張關聯表操作。

#### 產物清單

| 層 | 檔案 | 職責 |
|---|---|---|
| Mapper | `hr-system/mapper/SysRoleMenuMapper.java` | 角色-菜單關聯，`deleteByRoleId` |
| Mapper | `hr-system/mapper/SysRoleDeptMapper.java` | 角色-部門關聯（數據權限），`deleteByRoleId` |
| Mapper | `hr-system/mapper/SysRoleMapper.java` | 基礎 CRUD + 3 個自訂 SQL |
| Service | `hr-system/service/ISysRoleService.java` | 介面（12 個方法） |
| Service Impl | `hr-system/service/impl/SysRoleServiceImpl.java` | 業務邏輯 |
| Controller | `hr-system/controller/SysRoleController.java` | REST API（8 個端點） |

#### 1. 關聯表 Mapper

`SysRoleMenuMapper` 和 `SysRoleDeptMapper` 均繼承 `BaseMapper`，各提供一個 `@Delete` 方法：

```java
@Delete("DELETE FROM sys_role_menu WHERE role_id = #{roleId}")
int deleteByRoleId(@Param("roleId") Long roleId);
```

> **先刪後插策略**：修改角色菜單/數據權限時，先 `deleteByRoleId` 清空，再批量 `insert`。比計算 diff（哪些新增、哪些刪除）簡單且不易出錯。

#### 2. SysRoleMapper

| 方法 | SQL 要點 | 用途 |
|---|---|---|
| `selectRolesByUserId` | JOIN `sys_user_role`，取角色全部欄位 | 用戶詳情頁顯示關聯角色 |
| `selectRoleKeysByUserId` | JOIN `sys_user_role`，取 DISTINCT `role_key`，過濾 `status=0` | 登入時載入角色編碼集合 |
| `countUserByRoleId` | `SELECT COUNT(1) FROM sys_user_role WHERE role_id = ?` | 刪除前校驗用戶關聯 |

#### 3. ISysRoleService / SysRoleServiceImpl

核心邏輯：

- **新增角色**：校驗 `roleKey` + `roleName` 唯一 → `save(role)` → `insertRoleMenu`（從 `role.getMenuIds()` 批量插入 `sys_role_menu`）
- **修改角色**：校驗唯一性 → `updateById` → 先刪後插 `sys_role_menu`
- **修改數據權限**：`updateById` 僅更新 `dataScope` → 先刪後插 `sys_role_dept`（從 `role.getDeptIds()`）
- **修改狀態**：獨立端點，只更新 `status` 欄位
- **刪除保護**：
  - `checkRoleAllowed`：禁止操作 `roleId = 1`（超級管理員角色）
  - 刪除前逐一校驗 `countUserByRoleId`
  - 刪除時同時清理 `sys_role_menu` 和 `sys_role_dept`
- **超級管理員**：`selectRoleKeysByUserId(1L)` 直接返回 `Set.of("admin")`，不走 DB

#### 4. SysRoleController

| Method | Path | 權限 | 日誌 | 說明 |
|---|---|---|---|---|
| GET | `/system/role/list` | `system:role:list` | - | 分頁列表 |
| GET | `/system/role/all` | `system:role:list` | - | 全量下拉選項 |
| GET | `/system/role/{roleId}` | `system:role:query` | - | 詳情 |
| POST | `/system/role` | `system:role:add` | `INSERT` | 新增（含菜單分配） |
| PUT | `/system/role` | `system:role:edit` | `UPDATE` | 修改（含菜單分配） |
| PUT | `/system/role/dataScope` | `system:role:edit` | `GRANT` | 修改數據權限 |
| PUT | `/system/role/changeStatus` | `system:role:edit` | `UPDATE` | 啟用/停用 |
| DELETE | `/system/role/{roleIds}` | `system:role:remove` | `DELETE` | 批量刪除 |

> `dataScope` 端點的日誌類型為 `GRANT`（授權），區別於一般的 `UPDATE`。

#### 驗收

- `mvn -pl hr-system -am compile -q` ✅ 通過

### Step 17：用戶管理 ✅

用戶是整個系統的核心實體，關聯部門、崗位、角色。涉及密碼加密、三重唯一性校驗、超管保護。

#### 產物清單

| 層 | 檔案 | 職責 |
|---|---|---|
| Mapper | `hr-system/mapper/SysUserRoleMapper.java` | 用戶-角色關聯，`deleteByUserId` |
| Mapper | `hr-system/mapper/SysUserMapper.java` | 基礎 CRUD + `selectByUsername` + `updateLoginInfo` |
| Service | `hr-system/service/ISysUserService.java` | 介面（12 個方法） |
| Service Impl | `hr-system/service/impl/SysUserServiceImpl.java` | 業務邏輯 |
| Controller | `hr-system/controller/SysUserController.java` | REST API（7 個端點） |

#### 1. SysUserRoleMapper

與角色模組的 `SysRoleMenuMapper` 同模式：

```java
@Delete("DELETE FROM sys_user_role WHERE user_id = #{userId}")
int deleteByUserId(@Param("userId") Long userId);
```

#### 2. SysUserMapper

| 方法 | SQL 要點 | 用途 |
|---|---|---|
| `selectByUsername` | `WHERE username = ? AND deleted = 0` | 登入認證（Step 19 的 `UserDetailsServiceImpl` 會調用） |
| `updateLoginInfo` | `SET login_ip = ?, login_time = GETDATE()` | 登入成功後記錄 IP 和時間 |

> **`GETDATE()`**：SQL Server 取當前時間函數，由資料庫端產生，避免應用伺服器與 DB 時區不一致。

#### 3. ISysUserService / SysUserServiceImpl

核心邏輯：

- **新增用戶**：
  1. 三重唯一性校驗：`username`（必填）、`phone`（選填時才校驗）、`email`（選填時才校驗）
  2. `passwordEncoder.encode(user.getPassword())` → BCrypt 加密
  3. `save(user)` → `insertUserRole`（從 `user.getRoleIds()` 批量插入）
- **修改用戶**：
  1. `user.setPassword(null)` — 防止意外覆蓋密碼，密碼走獨立的重置接口
  2. `updateById` → 先刪後插 `sys_user_role`
- **重置密碼**：獨立接口，只更新 `password` 欄位（BCrypt 加密後）
- **修改狀態**：獨立接口，只更新 `status` 欄位
- **刪除保護**：`checkUserAllowed` 禁止操作 `userId = 1`（超級管理員）
- **分頁查詢**：支持 `username / nickname / phone / status / deptId` 五個篩選條件

#### 4. SysUserController

| Method | Path | 權限 | 日誌 | 說明 |
|---|---|---|---|---|
| GET | `/system/user/list` | `system:user:list` | - | 分頁列表 |
| GET | `/system/user/{userId}` | `system:user:query` | - | 詳情（含關聯角色） |
| POST | `/system/user` | `system:user:add` | `INSERT` | 新增 |
| PUT | `/system/user` | `system:user:edit` | `UPDATE` | 修改 |
| PUT | `/system/user/resetPwd` | `system:user:resetPwd` | `UPDATE` | 重置密碼 |
| PUT | `/system/user/changeStatus` | `system:user:edit` | `UPDATE` | 啟用/停用 |
| DELETE | `/system/user/{userIds}` | `system:user:remove` | `DELETE` | 批量刪除 |

> 查詢詳情接口返回 `{ user, roles }` Map 結構，前端一次請求同時拿到用戶資料和關聯角色列表。

#### 驗收

- `mvn -pl hr-system -am compile -q` ✅ 通過

### Step 18：數據權限攔截器 ✅

透過 AOP + SQL 片段注入，實現行級數據隔離。不同角色的用戶只能看到各自權限範圍內的數據。

#### 產物清單

| 操作 | 檔案 | 所屬模組 | 職責 |
|---|---|---|---|
| 新增 | `framework/aspectj/DataScope.java` | hr-framework | 註解，聲明 `deptAlias` / `userAlias` |
| 新增 | `system/aspectj/DataScopeAspect.java` | hr-system | AOP 切面，生成 SQL 片段 |
| 修改 | `common/core/domain/BaseEntity.java` | hr-common | 新增 `params` Map 欄位 |
| 修改 | `SysDeptController.java` | hr-system | list/tree 加 `@DataScope()` |
| 修改 | `SysDeptServiceImpl.java` | hr-system | 查詢時拼入 `params["dataScope"]` |
| 修改 | `SysUserController.java` | hr-system | list 加 `@DataScope()` |
| 修改 | `SysUserServiceImpl.java` | hr-system | 查詢時拼入 `params["dataScope"]` |

#### 1. @DataScope 註解

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface DataScope {
    String deptAlias() default "";   // 部門表別名，空時不加前綴
    String userAlias() default "";   // 用戶表別名，空時不加前綴
}
```

> 放在 `hr-framework` 層（無外部依賴），Controller/Service 均可引用。

#### 2. DataScopeAspect

**工作原理（三步）**：
1. Controller 方法標 `@DataScope()` → `@Before` 切面攔截
2. 切面查當前用戶角色的 `dataScope`，按 5 種策略生成 SQL WHERE 片段，存入 `entity.getParams().put("dataScope", sql)`
3. Service 的 `buildQueryWrapper` 取出片段，用 `wrapper.apply(sql)` 拼入條件

**5 種數據範圍對應的 SQL**：

| dataScope | 枚舉 | 生成的 SQL 片段 |
|---|---|---|
| 1 | ALL | 不加條件（直接 return） |
| 2 | CUSTOM | `dept_id IN (從 sys_role_dept 查出的 ID 列表)` |
| 3 | DEPT | `dept_id = 當前用戶部門ID` |
| 4 | DEPT_AND_CHILD | `dept_id IN (子查詢：本部門 + ancestors 含本部門的後代)` |
| 5 | SELF | `user_id = 當前用戶ID` |

**多角色合併**：一個用戶可能有多個角色、不同 dataScope。切面用 `OR` 合併所有角色的條件。若任一角色為 `ALL`，立即短路返回。

**超級管理員**：`userId = 1` 直接跳過，不做任何過濾。

**無角色用戶**：注入 `1 = 0`，禁止看到任何數據。

#### 3. BaseEntity 新增 params

```java
@JsonIgnore
@TableField(exist = false)
private Map<String, Object> params;
```

> `@JsonIgnore` 避免 JSON 響應暴露內部 SQL；`@TableField(exist=false)` 避免 MP 拼入 SELECT/WHERE。

#### 4. 使用示範

```java
// Controller
@DataScope()
@GetMapping("/list")
public R<PageResult<SysUser>> list(SysUser user, PageQuery pageQuery) { ... }

// ServiceImpl — buildQueryWrapper 中
String dataScope = (String) query.getParams().get(DataScopeAspect.DATA_SCOPE_KEY);
if (StringUtils.hasText(dataScope)) {
    wrapper.apply(dataScope);
}
```

> 當需要 JOIN 查詢時（如用戶列表關聯部門表），可用 `@DataScope(deptAlias = "d", userAlias = "u")` 指定別名，切面會生成 `d.dept_id IN (...)` 形式的 SQL。

#### 踩坑記錄

`DataScopeAspect` 最初放在 `hr-framework`，但它依賴 `hr-system` 的 `SysRoleMapper` / `SysDeptMapper`，導致循環依賴（`hr-system → hr-framework → hr-system`）。**解決**：切面移到 `hr-system/aspectj/`，`@DataScope` 註解留在 `hr-framework`（無外部依賴）。

#### 驗收

- `mvn compile -q`（全模組）✅ 通過

---

### 階段四總驗收

| Step | 模組 | 狀態 |
|---|---|---|
| 12 | 實體類（8 個） | ✅ |
| 13 | 部門管理（樹形 + ancestors 級聯） | ✅ |
| 14 | 崗位管理（分頁 CRUD） | ✅ |
| 15 | 菜單管理（樹形 + 權限標識 + 物理刪除） | ✅ |
| 16 | 角色管理（三表關聯 + 數據權限分配） | ✅ |
| 17 | 用戶管理（BCrypt + 三重唯一性 + 超管保護） | ✅ |
| 18 | 數據權限攔截器（AOP + SQL 注入） | ✅ |

全模組編譯通過，階段四完成。

---
