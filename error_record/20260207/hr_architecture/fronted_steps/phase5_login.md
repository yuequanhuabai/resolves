## 階段五：登入功能

### Step 15：登入頁 ⏳

`src/views/login/index.vue`：
- 表單：用戶名 + 密碼 + 記住我
- 校驗：用戶名/密碼不能為空
- 提交：
  ```
  userStore.login({ username, password })
  → 成功：router.push(redirect || '/')
  → 失敗：ElMessage.error
  ```
- 樣式：居中卡片式佈局，背景圖/漸變

### Step 16：API 對接 ⏳

`src/api/auth.ts`：

```ts
login(data: LoginData): Promise<{ token: string }>
logout(): Promise<void>
getInfo(): Promise<UserInfo>
getRouters(): Promise<MenuItem[]>
```

對應後端 4 個端點（均在 `AuthController`）：
- `POST /login`
- `POST /logout`
- `GET /getInfo`
- `GET /getRouters`

`user` store 的 `login / getInfo / logout` action 調用這些 API，並維護 `token / userInfo / roles / permissions`。

### Step 17：動態路由生成 ⏳

`store/modules/permission.ts` 的 `generateRoutes(menus)`：
1. 接收後端菜單樹
2. 遞歸轉 Vue Router 路由配置
3. `component` 字段處理：
   ```ts
   component: () => import(`@/views/${component}.vue`)
   ```
   （Vite 動態 import 限制：路徑前綴需固定）
4. 追加 `404` 兜底：`{ path: '/:pathMatch(.*)*', redirect: '/404' }`

路由守衛中：拿到菜單後 `router.addRoute()` 動態注入。

### Step 18：端到端驗證 ⏳

驗收清單：
- [ ] admin/admin123 能登入 → 跳首頁
- [ ] 側邊欄渲染後端返回的菜單
- [ ] 點擊菜單能跳轉對應頁面（即使頁面是空殼）
- [ ] 退出登入 → 清 Token → 跳 `/login`
- [ ] 直接訪問 `/system/user`（未登入）→ 跳 `/login?redirect=/system/user`
- [ ] 登入後自動跳回 `redirect` 路徑
- [ ] 刷新頁面 token 還在，動態路由重新加載

---
