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
