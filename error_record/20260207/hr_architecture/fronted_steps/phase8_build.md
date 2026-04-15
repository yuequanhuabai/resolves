## 階段八：優化 + 構建

### Step 27：體驗優化 ⏳

| 點 | 實現 |
|---|---|
| 頁面加載 loading | NProgress 路由切換進度條 |
| 表格 loading | `v-loading` 綁定 `loading` ref |
| 按鈕防重複 | 提交按鈕 `:loading="submitting"` |
| 表格空狀態 | `<el-empty>` 配合 `v-if="!list.length"` |
| 刪除二次確認 | `ElMessageBox.confirm` 統一 |
| 全局錯誤捕獲 | `app.config.errorHandler` |

### Step 28：生產構建 ⏳

#### vite.config.ts 生產優化

```ts
build: {
  rollupOptions: {
    output: {
      manualChunks: {
        vue: ['vue', 'vue-router', 'pinia'],
        elementPlus: ['element-plus', '@element-plus/icons-vue']
      }
    }
  },
  terserOptions: {
    compress: { drop_console: true, drop_debugger: true }
  }
}
```

可選：`vite-plugin-compression` 產出 `.gz`。

#### 構建 + 部署

```bash
npm run build    # 產出 dist/
```

Nginx 配置：

```nginx
server {
  listen 80;
  server_name hr.example.com;

  location / {
    root /usr/share/nginx/html;
    try_files $uri $uri/ /index.html;
  }

  location /api/ {
    proxy_pass http://localhost:8080/api/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
```

#### 階段八驗收

- `npm run build` 無報錯，`dist/` 大小合理（vendor chunk 分離）
- Nginx 部署後刷新任意子路由不 404（依賴 `try_files`）
- API 請求正確走代理

---
