# BuyList 導入功能修復 - 行動計劃

## 📋 待執行任務

### 1️⃣ 在生產數據庫中執行 SQL（必須）

**優先級**: 🔴 **必須完成**
**預計時間**: 2 分鐘

#### SQL 語句

在你的 MySQL 數據庫中執行：

```sql
-- 1. 添加導入權限定義到 system_menu 表
INSERT INTO `system_menu` (id, name, permission, `type`, sort, parent_id, `path`, icon, component, component_name, status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
VALUES (5098, '業務导入', 'buy:list:import', 3, 6, 5015, '', '', '', NULL, 0, 1, 1, 1, '', '2025-11-13 00:00:00', '', '2025-11-13 00:00:00', 0);

-- 2. 為普通角色 (role_id = 2) 授予導入權限
INSERT INTO `system_role_menu` (id, role_id, menu_id, creator, create_time, updater, update_time, deleted)
VALUES (1844, 2, 5098, '1', '2025-11-13 00:00:00', '1', '2025-11-13 00:00:00', 0);

-- 3. 為租戶管理員角色 (role_id = 109) 授予導入權限
INSERT INTO `system_role_menu` (id, role_id, menu_id, creator, create_time, updater, update_time, deleted)
VALUES (1845, 109, 5098, '1', '2025-11-13 00:00:00', '1', '2025-11-13 00:00:00', 0);
```

#### 驗證執行成功

```sql
-- 檢查權限是否存在
SELECT * FROM system_menu WHERE id = 5098;

-- 檢查角色關聯是否存在
SELECT * FROM system_role_menu WHERE menu_id = 5098;
```

---

### 2️⃣ 部署前端代碼修改（必須）

**優先級**: 🔴 **必須完成**
**預計時間**: 5 分鐘

#### 已修改的文件

✅ 已完成修改：
- `poc-pro-ui/src/api/buylist/index.ts` - 第 67 行
- `poc-pro-ui/src/views/buylist/detail/index.vue` - 第 745-766 行

#### 部署方式

```bash
# 方式 1: 重新構建前端應用
cd poc-pro-ui
npm run i  # 或 pnpm install
npm run build:local  # 或相應環境的構建命令

# 方式 2: 直接使用已修改的文件
# 將修改後的文件複製到你的 npm 構建目錄
# 重新構建並部署

# 方式 3: 使用 Git 更新
git pull  # 從倉庫拉取最新修改
npm run build:local
```

#### 確認修改已應用

在瀏覽器開發者工具的 Network 標籤中：
- 檢查 `parse-file` 請求的 `Content-Type` 是否為 `multipart/form-data`
- 檢查瀏覽器控制台是否有 `console.log('文件解析結果:', parseResult)` 的輸出

---

### 3️⃣ 更新 SQL 初始化文件（推薦）

**優先級**: 🟡 **強烈推薦**
**預計時間**: 5 分鐘

#### 為什麼要做？
確保新部署時自動創建權限配置。

#### 需要修改的文件

**文件**: `pocpro/sql/mysql/new.sql`

#### 修改 1：添加權限定義（第 1225 行）

在第 1224 行（買單導出權限）後添加：

```sql
INSERT INTO `system_menu` (id, name, permission, `type`, sort, parent_id, `path`, icon, component, component_name, status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted) VALUES (5098, '業務导入', 'buy:list:import', 3, 6, 5015, '', '', '', NULL, 0, 1, 1, 1, '', '2025-11-13 00:00:00', '', '2025-11-13 00:00:00', 0);
```

#### 修改 2：添加角色權限關聯（第 1442-1443 行）

在第 1441 行（最後一條 system_role_menu 記錄）後、第 1442 行（COMMIT）前添加：

```sql
INSERT INTO `system_role_menu` (id, role_id, menu_id, creator, create_time, updater, update_time, deleted) VALUES (1844, 2, 5098, '1', '2025-11-13 00:00:00', '1', '2025-11-13 00:00:00', 0);
INSERT INTO `system_role_menu` (id, role_id, menu_id, creator, create_time, updater, update_time, deleted) VALUES (1845, 109, 5098, '1', '2025-11-13 00:00:00', '1', '2025-11-13 00:00:00', 0);
```

---

### 4️⃣ 重啟後端應用（必須）

**優先級**: 🔴 **必須完成**
**預計時間**: 5 分鐘

#### 停止舊應用

```bash
# 查找 Java 進程
ps aux | grep java

# 停止應用（根據進程 ID）
kill -9 <process_id>

# 或使用你的應用管理工具
systemctl stop pap-server
```

#### 啟動新應用

```bash
# 本地開發模式
cd pocpro/pap-server
mvn spring-boot:run

# 生產環境（使用 JAR 包）
java -jar pap-server.jar

# 或使用你的應用管理工具
systemctl start pap-server
```

---

### 5️⃣ 驗證修復（必須）

**優先級**: 🔴 **必須完成**
**預計時間**: 10 分鐘

#### 步驟 1: 用戶重新登錄

- 清除瀏覽器 Cookie 或使用無痕模式
- 重新登錄系統

#### 步驟 2: 進行完整的導入流程測試

1. 進入 BuyList 列表頁
2. 點擊要編輯的 BuyList 進入詳情頁
3. 點擊「Edit」進入編輯模式
4. 點擊「Upload」打開上傳對話框
5. 下載 CSV 模板或準備好的 CSV 文件
6. 選擇文件並點擊「Confirm Upload」
7. **預期結果**: ✅ 顯示「成功導入 X 條數據」

#### 步驟 3: 驗證數據導入

- 表格應顯示導入的數據
- 點擊「Save」保存（應觸發版本控制）

#### 步驟 4: 測試錯誤場景

上傳有問題的 CSV 文件（如缺少必填字段），驗證：
- ✅ 顯示詳細的錯誤提示
- ✅ 對話框保持打開，允許重新上傳

#### 步驟 5: 檢查瀏覽器控制台

打開開發者工具 (F12)：
- Console 標籤中應有 `console.log('文件解析結果:', parseResult)` 的輸出
- 應有成功的 API 調用日誌

---

## 📊 完成檢查清單

### 準備階段
- [ ] 備份當前數據庫（推薦）
- [ ] 備份當前應用代碼

### 執行階段
- [ ] ✅ 前端代碼已修改（自動完成）
- [ ] 執行 SQL 語句添加權限
- [ ] 驗證 SQL 執行成功
- [ ] 更新 SQL 初始化文件（可選但推薦）
- [ ] 部署前端代碼
- [ ] 重啟後端應用
- [ ] 應用正常啟動（無錯誤）

### 驗證階段
- [ ] 用戶能登錄系統
- [ ] 能進入 BuyList 詳情頁
- [ ] 能成功上傳 CSV 文件
- [ ] 能看到導入的數據
- [ ] 能保存已導入的數據
- [ ] 錯誤場景驗證通過

### 完成
- [ ] 所有檢查項都已完成
- [ ] 用戶報告功能正常

---

## 🆘 如果出現問題

### 權限錯誤仍然出現

```bash
# 1. 驗證 SQL 是否執行成功
mysql -h your_host -u user -p database_name
SELECT * FROM system_menu WHERE id = 5098;
SELECT * FROM system_role_menu WHERE menu_id = 5098;

# 2. 檢查用戶的角色
SELECT r.id, r.name FROM system_user u
JOIN system_user_role ur ON u.id = ur.user_id
JOIN system_role r ON ur.role_id = r.id
WHERE u.username = 'your_username';

# 3. 如果用戶的角色不是 2 或 109，為該角色添加權限
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted)
VALUES (next_id, your_role_id, 5098, '1', NOW(), '1', NOW(), 0);

# 4. 重啟應用
```

### 前端文件修改未生效

```bash
# 1. 確認前端代碼已更新
git status  # 檢查是否有未提交的修改

# 2. 清除緩存並重新構建
npm run clean  # 清除 node_modules
npm run clean:cache  # 清除構建緩存
npm run i  # 重新安裝依賴
npm run build:local  # 重新構建

# 3. 清除瀏覽器緩存
# 在瀏覽器中：Ctrl+Shift+Delete（清除瀏覽數據）

# 4. 使用無痕窗口訪問
```

### API 調用超時

```bash
# 1. 檢查後端應用是否正常運行
ps aux | grep java

# 2. 檢查應用日誌
tail -f logs/application.log

# 3. 檢查網絡連接
curl http://localhost:8080/admin-api/buyList/parse-file

# 4. 檢查文件大小（如果是大文件）
# 限制：最大 10MB
ls -lh your_csv_file.csv
```

---

## 📞 聯繫支持

如遇到無法解決的問題：

1. 參考相關文檔：
   - `QUICK_FIX_GUIDE.md` - 快速修復指南
   - `PERMISSION_FIX.md` - 詳細權限說明
   - `BUYLIST_IMPORT_FIX.md` - API 修復說明

2. 提供以下信息：
   - 錯誤信息（完整的截圖或文本）
   - 瀏覽器控制台的錯誤信息
   - 後端應用日誌
   - 數據庫查詢結果
   - 用戶角色信息

---

## 📝 時間估計

| 任務 | 預計時間 | 狀態 |
|------|---------|------|
| 執行 SQL | 2 分鐘 | ⏳ 待完成 |
| 部署前端 | 5 分鐘 | ⏳ 待完成 |
| 更新 SQL 文件 | 5 分鐘 | 🟡 可選 |
| 重啟應用 | 5 分鐘 | ⏳ 待完成 |
| 驗證測試 | 10 分鐘 | ⏳ 待完成 |
| **總計** | **17-27 分鐘** | |

---

## ✅ 完成確認

當所有任務完成後，用戶應該能夠：

✅ 進入 BuyList 詳情頁
✅ 點擊 Edit 進入編輯模式
✅ 點擊 Upload 打開上傳對話框
✅ 選擇 CSV 文件
✅ 點擊 Confirm Upload
✅ **成功導入數據**（而不是權限錯誤）
✅ 查看導入的數據
✅ 保存已導入的數據

---

**最後修改**: 2025-11-13
**狀態**: 待執行
**優先級**: 🔴 高
