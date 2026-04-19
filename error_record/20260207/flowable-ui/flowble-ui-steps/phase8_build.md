# 階段八：構建 + 部署

## Step 23：環境變量配置

### 23.1 .env.development（開發環境）

**文件路徑**：`flowable-designer-ui/.env.development`

```ini
VITE_APP_TITLE=流程引擎設計器（開發）
VITE_API_BASE_URL=http://localhost:9090/workflow
```

### 23.2 .env.production（生產環境）

**文件路徑**：`flowable-designer-ui/.env.production`

```ini
VITE_APP_TITLE=流程引擎設計器
# 生產環境後端地址（部署到同一服務器時可用相對路徑）
VITE_API_BASE_URL=/workflow
```

### 23.3 vite.config.ts 適配環境變量

更新 `vite.config.ts` 中的 proxy 配置，支持開發環境代理：

```typescript
import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd())

  return {
    plugins: [vue()],
    resolve: {
      alias: { '@': resolve(__dirname, 'src') }
    },
    server: {
      port: 3000,
      proxy: {
        '/workflow': {
          target: env.VITE_API_BASE_URL || 'http://localhost:9090',
          changeOrigin: true
        }
      }
    },
    build: {
      outDir: 'dist',
      chunkSizeWarningLimit: 2000,
      rollupOptions: {
        output: {
          // 分塊策略：bpmn-js 單獨打包（體積較大）
          manualChunks: {
            'bpmn-vendor': ['bpmn-js', 'bpmn-js-properties-panel'],
            'element-plus': ['element-plus'],
            'vue-vendor': ['vue', 'vue-router', 'pinia']
          }
        }
      }
    }
  }
})
```

---

## Step 24：生產構建 + Nginx 部署

### 24.1 生產構建

```bash
cd flowable-designer-ui

# 安裝依賴
npm install

# 構建
npm run build

# dist/ 目錄即為構建產物
```

### 24.2 Nginx 配置

將 `dist/` 上傳到服務器，Nginx 配置如下：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # 前端靜態文件
    root /opt/flowable-designer-ui/dist;
    index index.html;

    # Vue Router history 模式支持
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 代理後端 API（流程引擎服務）
    location /workflow {
        proxy_pass http://localhost:9090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # 靜態資源緩存
    location ~* \.(js|css|png|jpg|gif|ico|svg|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

### 24.3 Docker 化前端（可選）

**文件路徑**：`flowable-designer-ui/Dockerfile`

```dockerfile
# 構建階段
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# 運行階段
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**nginx.conf**（容器內）：

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /workflow {
        # 後端服務地址（docker network 中的服務名）
        proxy_pass http://flowable-engine:9090;
        proxy_set_header Host $host;
    }
}
```

### 24.4 驗收

```bash
# 本地預覽構建結果
npm run preview

# 瀏覽器訪問 http://localhost:4173
# 確認各頁面路由正常，API 請求正常
```

### 注意事項

- bpmn-js 打包後體積較大（約 1-2MB），已通過 `manualChunks` 分離，避免影響首屏加載
- 生產環境確保 Nginx 已開啟 Gzip 壓縮（`gzip on;`）可大幅減小傳輸體積
- `history` 模式路由必須配置 `try_files $uri $uri/ /index.html`，否則刷新頁面會 404
