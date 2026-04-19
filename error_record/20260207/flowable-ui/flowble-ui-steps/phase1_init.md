# 階段一：項目初始化

## Step 1：創建項目 + 安裝依賴

### 1.1 創建 Vue 3 + Vite + TypeScript 項目

```bash
cd D:\software\develop_tools\git\gitee\flowable-micro-server

# 使用 npm 創建（注意中間的 -- 是必須的，用於將參數傳遞給 vite 而非 npm）
npm create vite@latest flowable-designer-ui -- --template vue-ts

cd flowable-designer-ui
```

### 1.2 安裝核心依賴

```bash
# UI 框架
npm install element-plus @element-plus/icons-vue

# 狀態管理 + 路由
npm install pinia vue-router@4

# HTTP 請求
npm install axios

# bpmn-js 設計器核心依賴
npm install bpmn-js

# SCSS 支持
npm install -D sass

# 類型支持
npm install -D @types/node
```

### 1.3 安裝開發工具（可選）

```bash
# ESLint + Prettier
npm install -D eslint @typescript-eslint/eslint-plugin @typescript-eslint/parser
npm install -D prettier eslint-config-prettier eslint-plugin-vue
```

---

## Step 2：配置 vite.config.ts + tsconfig.json

### 2.1 vite.config.ts

**文件路徑**：`flowable-designer-ui/vite.config.ts`

```typescript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src')
    }
  },
  server: {
    port: 3000,
    proxy: {
      // 代理到後端流程引擎服務
      '/workflow': {
        target: 'http://localhost:9090',
        changeOrigin: true
      }
    }
  },
  build: {
    outDir: 'dist',
    chunkSizeWarningLimit: 2000
  }
})
```

### 2.2 tsconfig.json

**文件路徑**：`flowable-designer-ui/tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "module": "ESNext",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "preserve",
    "strict": true,
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": ["src/**/*.ts", "src/**/*.d.ts", "src/**/*.tsx", "src/**/*.vue"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

### 2.3 main.ts — 引入 Element Plus

**文件路徑**：`src/main.ts`

```typescript
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import zhCn from 'element-plus/es/locale/lang/zh-cn'
import App from './App.vue'
import router from './router'
import '@/styles/index.scss'

// bpmn-js 必需樣式（否則 palette 圖標全是方框、選中外框消失）
import 'bpmn-js/dist/assets/diagram-js.css'
import 'bpmn-js/dist/assets/bpmn-font/css/bpmn.css'
import 'bpmn-js/dist/assets/bpmn-js.css'

const app = createApp(App)

// 全局注冊 Element Plus 圖標
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

app.use(createPinia())
app.use(router)
app.use(ElementPlus, { locale: zhCn })
app.mount('#app')
```

### 驗收

```bash
npm run dev
# 瀏覽器訪問 http://localhost:3000，頁面正常展示
```
