## 階段四：公共組件

### Step 12：分頁組件 ✅（完成於 2026-04-15）

#### 產物清單

| 檔案 | 職責 |
|---|---|
| `src/components/Pagination/index.vue` | 封裝 el-pagination，統一 page/limit/total 協議 |
| `vite.config.ts`（修改） | Components 插件加 `dirs: ['src/components']`，全局自動註冊 |

#### 關鍵決策

- **v-model 雙綁 `page` + `limit`**：改動自動同步父組件 query 狀態
- **單一 `@pagination` 事件**：封裝了 `current-change` / `size-change`，父組件只綁一個
- **默認 `autoScroll`**：翻頁後自動滾回內容頂
- **空數據自動隱藏**：`total <= 0` 不渲染
- **全局自動註冊**：Components 插件 `dirs` 掃描，`<Pagination />` 任何頁面直接可用

驗證將在 Step 19 用戶管理頁實際落地。

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
