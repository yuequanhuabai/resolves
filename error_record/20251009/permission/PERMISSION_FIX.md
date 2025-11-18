# BuyList 導入權限修復文檔

## 問題描述

用戶在使用 BuyList 導入功能時，點擊「Confirm Upload」後收到以下錯誤信息：

```
沒有權限操作 (或 Access Denied)
```

這是因為後端 `parseFile` 接口要求 `buy:list:import` 權限，但該權限在數據庫中不存在。

---

## 根本原因分析

### 後端權限要求
**文件**: `BuyListController.java` 第 98 行
```java
@PreAuthorize("@ss.hasPermission('buy:list:import')")
public CommonResult<ParseResultVO> parseFile(@RequestParam("file") MultipartFile file)
```

### 數據庫狀態
在 `pocpro/sql/mysql/new.sql` 中，只定義了以下 BuyList 權限：
- `buy:list:query` (ID: 5016) - 查詢
- `buy:list:create` (ID: 5017) - 創建
- `buy:list:update` (ID: 5018) - 更新
- `buy:list:delete` (ID: 5019) - 刪除
- `buy:list:export` (ID: 5020) - 導出

**缺少**: `buy:list:import` - 導入

---

## 修復方案

### 1. 添加導入權限定義

**文件**: `pocpro/sql/mysql/new.sql` 第 1225 行

**SQL 語句**:
```sql
INSERT INTO `system_menu` (id, name, permission, `type`, sort, parent_id, `path`, icon, component, component_name, status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
VALUES (5098, '業務导入', 'buy:list:import', 3, 6, 5015, '', '', '', NULL, 0, 1, 1, 1, '', '2025-11-13 00:00:00', '', '2025-11-13 00:00:00', 0);
```

**字段說明**:
| 字段 | 值 | 說明 |
|------|-----|------|
| id | 5098 | 權限 ID（未使用的下一個 ID） |
| name | '業務导入' | 權限名稱 |
| permission | 'buy:list:import' | 權限標識符（後端代碼中使用） |
| type | 3 | 類型（3 = 按鈕權限） |
| sort | 6 | 排序（在導出之後） |
| parent_id | 5015 | 父權限 ID（BuyList 菜單） |
| status | 0 | 狀態（0 = 啟用） |
| visible | 1 | 可見（1 = 可見） |

### 2. 為角色授予導入權限

**文件**: `pocpro/sql/mysql/new.sql` 第 1442-1443 行

**SQL 語句**:
```sql
-- 為普通角色 (role_id = 2) 授予導入權限
INSERT INTO `system_role_menu` (id, role_id, menu_id, creator, create_time, updater, update_time, deleted)
VALUES (1844, 2, 5098, '1', '2025-11-13 00:00:00', '1', '2025-11-13 00:00:00', 0);

-- 為租戶管理員角色 (role_id = 109) 授予導入權限
INSERT INTO `system_role_menu` (id, role_id, menu_id, creator, create_time, updater, update_time, deleted)
VALUES (1845, 109, 5098, '1', '2025-11-13 00:00:00', '1', '2025-11-13 00:00:00', 0);
```

**字段說明**:
| 字段 | 值 | 說明 |
|------|-----|------|
| id | 1844, 1845 | 角色菜單關聯 ID |
| role_id | 2, 109 | 角色 ID |
| menu_id | 5098 | 權限 ID（即新增的導入權限） |
| creator | '1' | 創建人 |

**授權角色**:
- **role_id = 2**: 普通角色（common role）
- **role_id = 109**: 租戶管理員角色（tenant_admin）

如需為其他角色授予該權限，按照相同格式添加新的 `INSERT` 語句，修改 `role_id` 值。

---

## 應用修復

### 步驟 1：更新數據庫
1. 打開 MySQL 客戶端或管理工具
2. 選擇 PAP 系統使用的數據庫
3. 執行以下 SQL 語句：

```sql
-- 1. 添加導入權限定義
INSERT INTO `system_menu` (id, name, permission, `type`, sort, parent_id, `path`, icon, component, component_name, status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
VALUES (5098, '業務导入', 'buy:list:import', 3, 6, 5015, '', '', '', NULL, 0, 1, 1, 1, '', '2025-11-13 00:00:00', '', '2025-11-13 00:00:00', 0);

-- 2. 為普通角色授予導入權限
INSERT INTO `system_role_menu` (id, role_id, menu_id, creator, create_time, updater, update_time, deleted)
VALUES (1844, 2, 5098, '1', '2025-11-13 00:00:00', '1', '2025-11-13 00:00:00', 0);

-- 3. 為租戶管理員角色授予導入權限
INSERT INTO `system_role_menu` (id, role_id, menu_id, creator, create_time, updater, update_time, deleted)
VALUES (1845, 109, 5098, '1', '2025-11-13 00:00:00', '1', '2025-11-13 00:00:00', 0);
```

### 步驟 2：驗證權限（可選）
```sql
-- 查看是否添加成功
SELECT * FROM system_menu WHERE id = 5098;
SELECT * FROM system_role_menu WHERE menu_id = 5098;
```

### 步驟 3：重啟應用
1. 停止後端應用
2. 等待數據庫中的權限緩存失效（通常自動）或清除緩存
3. 重新啟動後端應用

### 步驟 4：驗證修復
1. 用戶重新登錄（或清除瀏覽器 Cookie）
2. 進入 BuyList 詳情頁
3. 點擊「Edit」進入編輯模式
4. 點擊「Upload」上傳文件
5. 點擊「Confirm Upload」
6. 應該能成功上傳，不再顯示權限錯誤

---

## 其他數據庫適配

如使用其他數據庫（Oracle、PostgreSQL、SQL Server 等），需要在對應的 SQL 文件中進行相同修改：

| 數據庫 | SQL 文件位置 |
|--------|-----------|
| MySQL | `pocpro/sql/mysql/new.sql` ✅ |
| Oracle | `pocpro/sql/oracle/new.sql` |
| PostgreSQL | `pocpro/sql/postgresql/new.sql` |
| SQL Server | `pocpro/sql/sqlserver/converted_sqlserver.sql` |
| KingBase | `pocpro/sql/kingbase/new.sql` |
| DM | `pocpro/sql/dm/new.sql` |
| OpenGauss | `pocpro/sql/opengauss/new.sql` |

**修改方法**：在對應文件中查找 system_menu 和 system_role_menu 相關的 INSERT 語句，按照上述格式添加導入權限的定義和角色關聯。

---

## 權限層級結構

```
BuyList (ID: 5015) - 菜單
├── 業務查詢 (ID: 5016) - buy:list:query
├── 業務创建 (ID: 5017) - buy:list:create
├── 業務更新 (ID: 5018) - buy:list:update
├── 業務删除 (ID: 5019) - buy:list:delete
├── 業務导出 (ID: 5020) - buy:list:export
└── 業務导入 (ID: 5098) - buy:list:import ← 新增
```

---

## 檢查清單

- [x] 後端 Controller 中的 `@PreAuthorize` 注解已確認為 `buy:list:import`
- [x] 權限在 system_menu 表中已添加（ID: 5098）
- [x] 角色菜單關聯在 system_role_menu 表中已添加（普通角色和租戶管理員）
- [ ] 數據庫 SQL 語句已執行
- [ ] 應用已重啟
- [ ] 用戶可以成功使用導入功能

---

## 相關文件修改記錄

| 文件 | 修改位置 | 改動 |
|------|--------|------|
| `pocpro/sql/mysql/new.sql` | 第 1225 行 | 添加導入權限定義 |
| `pocpro/sql/mysql/new.sql` | 第 1442-1443 行 | 為角色添加導入權限 |

---

## 常見問題

### Q: 修改後仍然顯示沒有權限？
**A**:
1. 確認執行了 SQL 語句
2. 重啟後端應用
3. 用戶重新登錄（清除緩存）
4. 檢查用戶是否屬於被授予權限的角色

### Q: 需要為所有用戶授予導入權限嗎？
**A**: 只需為需要使用該功能的角色授予權限。通常授予給：
- 普通用戶角色（role_id = 2）
- 管理員角色
- 業務操作員角色

### Q: 如何為特定用戶授予導入權限？
**A**: 需要為該用戶所屬的角色添加該權限，或者在 system_role_menu 表中為該用戶的主要角色添加記錄。

---

**修復完成時間**: 2025-11-13
**驗證狀態**: 待測試
**相關文檔**: `BUYLIST_IMPORT_FIX.md`, `buylist_import.md`
