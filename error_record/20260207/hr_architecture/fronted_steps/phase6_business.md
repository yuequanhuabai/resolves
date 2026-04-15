## 階段六：業務頁面

### Step 19：用戶管理頁 ⏳

`src/views/system/user/index.vue` + `src/api/system/user.ts`

頁面結構：
- **左**：DeptTree（點擊部門 → 篩選右側表格）
- **右上**：搜索表單（用戶名 / 手機 / 狀態）
- **右中**：操作按鈕（新增 / 匯出，配合 `v-hasPerms`）
- **右下**：用戶表格 + Pagination

彈窗：
- 新增/修改：用戶名、暱稱、密碼、部門(TreeSelect)、崗位(下拉)、角色(多選)、手機、郵箱、性別、狀態
- 重置密碼：單獨彈窗
- 狀態開關：`<el-switch>` 直接 PUT `/changeStatus`

### Step 20：角色管理頁 ⏳

`src/views/system/role/index.vue` + `src/api/system/role.ts`

- 搜索：角色名 / 角色標識 / 狀態
- 表格：角色名、標識、排序、狀態、創建時間、操作（編輯 / 刪除 / 權限分配）
- 新增/修改彈窗
- **權限分配彈窗**：
  - 菜單權限：`<el-tree>` 帶 checkbox，加載完整菜單樹（`/system/menu/list`）
  - 數據權限：下拉選擇 1-5
  - 自定義數據權限（dataScope=2）：部門樹勾選

### Step 21：部門管理頁 ⏳

`src/views/system/dept/index.vue` + `src/api/system/dept.ts`

- 搜索：部門名 / 狀態
- 樹形表格：`<el-table>` + `row-key="deptId"` + `:tree-props="{ children: 'children' }"`
- 操作：新增子部門 / 編輯 / 刪除
- 新增/修改彈窗：上級部門 (TreeSelect) + 部門名、負責人、手機、郵箱、排序、狀態
- 展開/摺疊全部按鈕

### Step 22：崗位管理頁 ⏳

`src/views/system/post/index.vue` + `src/api/system/post.ts`

標準 CRUD：搜索（崗位編碼 / 名稱 / 狀態）+ 表格 + 分頁 + 新增/修改彈窗。

### Step 23：菜單管理頁 ⏳

`src/views/system/menu/index.vue` + `src/api/system/menu.ts`

- 搜索：菜單名 / 狀態
- 樹形表格
- 操作：新增子菜單 / 編輯 / 刪除
- 新增/修改彈窗（**根據菜單類型動態欄位**）：
  - **目錄(M)**：菜單名、圖標(IconSelect)、排序
  - **菜單(C)**：+ 路由地址、組件路徑
  - **按鈕(F)**：+ 權限標識（如 `system:user:add`）
  - 上級菜單：TreeSelect

#### 階段六驗收

5 個模塊全部 CRUD 通；用 admin 能改任意數據；用 zhangsan/lisi 因權限被攔截（前端按鈕隱藏 + 後端 403）。

---
