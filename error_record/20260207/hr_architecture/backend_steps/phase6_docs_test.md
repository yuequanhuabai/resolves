## 階段六：API 文檔 + 測試

### Step 21：Knife4j 集成

1. 引入 knife4j-openapi3-jakarta-spring-boot-starter
2. 配置 Swagger 分組 (認證接口、系統管理、內部接口)
3. Controller 添加 @Tag、@Operation 註解
4. 驗證: 訪問 /doc.html 查看文檔

### Step 22：接口測試

1. 測試登入接口，獲取 Token
2. 使用 Token 測試各模塊 CRUD
3. 測試權限控制：
   - 未登入訪問 → 401
   - 無權限訪問 → 403
   - 數據權限過濾是否生效
4. 測試邊界情況：
   - 刪除有子部門的部門 → 提示錯誤
   - 刪除有用戶的角色 → 提示錯誤
   - 用戶名重複 → 提示錯誤

---
