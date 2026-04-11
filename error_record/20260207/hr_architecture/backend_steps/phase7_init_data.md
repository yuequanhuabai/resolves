## 階段七：初始化數據腳本

### Step 23：編寫初始化 SQL

```
插入順序:
  1. sys_dept   — 頂級公司 + 基礎部門
  2. sys_post   — 基礎崗位 (董事長/總經理/普通員工)
  3. sys_menu   — 完整菜單樹 (目錄 + 菜單 + 按鈕)
  4. sys_role   — 超級管理員角色 + 普通角色
  5. sys_user   — admin 用戶 (密碼 BCrypt 加密)
  6. sys_user_role  — admin 綁定管理員角色
  7. sys_role_menu  — 管理員角色綁定所有菜單
```

