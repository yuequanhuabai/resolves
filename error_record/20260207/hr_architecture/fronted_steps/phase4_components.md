## 階段四：公共組件

### Step 12：分頁組件 ⏳

`src/components/Pagination/index.vue`：
- 封裝 `<el-pagination>`
- Props：`total`、`page`、`limit`
- Emit：`@pagination` (傳 `{ pageNum, pageSize }`)

### Step 13：權限指令 ⏳

`src/directive/permission/hasPerms.ts`：

```ts
v-hasPerms="['system:user:add']"
```

邏輯：
- 從 `user` store 取 `permissions`
- 包含 `*:*:*` 直接通過
- 否則檢查是否包含指定權限字串
- 不包含 → `el.parentNode.removeChild(el)`

`main.ts` 中：`app.directive('hasPerms', hasPerms)`。

### Step 14：公共業務組件 ⏳

| 組件 | 路徑 | 用途 |
|---|---|---|
| DeptTree | `components/DeptTree/index.vue` | 部門樹（搜索 + 選中事件），用戶管理頁左側 |
| TreeSelect | `components/TreeSelect/index.vue` | 樹形下拉（基於 `el-tree-select`），上級部門/上級菜單選擇 |
| IconSelect | `components/IconSelect/index.vue` | 圖標選擇器，菜單管理用 |
| RightToolbar | `components/RightToolbar/index.vue` | 表格右側工具欄（刷新 / 列顯示） |

#### 階段四驗收

在隨便一個 view 裡 import 上述組件能正常渲染；`v-hasPerms` 在 admin 下顯示、在無權限模擬下隱藏。

---
