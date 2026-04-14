## 階段一：項目初始化

### Step 1：創建 Vue 3 項目 + 安裝依賴 + 配置 Vite/TS ✅

#### 目標
在倉庫根目錄下生成 `hr-ui/` 項目，能 `npm run dev` 啟動，瀏覽器看到 Vite + Vue 3 默認頁面，且 Element Plus 按需引入工作正常。

#### 產物清單

| 操作 | 路徑 | 說明 |
|---|---|---|
| 新建目錄 | `hr-ui/` | Vite 腳手架生成 |
| 修改 | `hr-ui/package.json` | 加入 vue-router/pinia/axios/element-plus 等依賴 |
| 修改 | `hr-ui/vite.config.ts` | 路徑別名 + 自動導入 + dev proxy |
| 修改 | `hr-ui/tsconfig.json` | 路徑別名 paths |
| 新增 | `hr-ui/.env.development` | dev 環境變量 |
| 新增 | `hr-ui/.env.production` | prod 環境變量 |
| 新增 | `hr-ui/src/types/auto-imports.d.ts` | 自動生成（unplugin） |
| 新增 | `hr-ui/src/types/components.d.ts` | 自動生成（unplugin） |

#### 1. 創建項目骨架

在倉庫根目錄執行：

```bash
cd D:/software/develop_tools/git/gitee/human_resource
npm create vite@latest hr-ui -- --template vue-ts
```

> 互動式提示一律按 `Enter` / `y` 通過。

#### 2. 安裝核心依賴

```bash
cd hr-ui
npm install vue-router@4 pinia axios element-plus @element-plus/icons-vue
npm install -D sass unplugin-auto-import unplugin-vue-components @types/node
```

**依賴用途速查：**

| 包 | 用途 |
|---|---|
| `vue-router@4` | 路由 |
| `pinia` | 狀態管理 |
| `axios` | HTTP |
| `element-plus` | UI 組件庫 |
| `@element-plus/icons-vue` | 圖標 |
| `sass` | SCSS 預處理 |
| `unplugin-auto-import` | 自動導入 Vue/router/pinia API |
| `unplugin-vue-components` | 自動註冊 Element Plus 組件 |
| `@types/node` | 讓 `vite.config.ts` 能用 `path` 模塊 |

#### 3. 配置 `vite.config.ts`

完整覆蓋 `hr-ui/vite.config.ts`：

```ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import { ElementPlusResolver } from 'unplugin-vue-components/resolvers'
import path from 'path'

export default defineConfig({
  plugins: [
    vue(),
    AutoImport({
      imports: ['vue', 'vue-router', 'pinia'],
      resolvers: [ElementPlusResolver()],
      dts: 'src/types/auto-imports.d.ts'
    }),
    Components({
      resolvers: [ElementPlusResolver()],
      dts: 'src/types/components.d.ts'
    })
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src')
    }
  },
  server: {
    port: 5173,
    open: true,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true
        // 後端 context-path 已是 /api，這裡不做 rewrite
      }
    }
  }
})
```

**關鍵點：**
- `@` → `src/`：`import x from '@/store'` 寫法
- AutoImport：寫 `ref()`、`useRouter()` 不用手動 import
- ElementPlusResolver：用 `<el-button>` 不用手動 import + 樣式
- Proxy `/api`：前端 `axios.get('/api/login')` → 後端 `http://localhost:8080/api/login`

#### 4. 配置 `tsconfig.json`

`hr-ui/tsconfig.json` 中 `compilerOptions` 加 `baseUrl` 和 `paths`：

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  }
}
```

> Vite 創建的模板會把 ts 配置拆成 `tsconfig.app.json`，加在 `compilerOptions` 裡即可。也要在 `tsconfig.node.json` 確保 `vite.config.ts` 能用 `path`。

#### 5. 環境變量

新增 `hr-ui/.env.development`：

```
VITE_APP_TITLE=人事管理系統
VITE_APP_BASE_API=/api
```

新增 `hr-ui/.env.production`：

```
VITE_APP_TITLE=人事管理系統
VITE_APP_BASE_API=/api
```

> 之所以 dev 也用 `/api` 而非完整 URL：走 Vite proxy 規避瀏覽器 CORS。生產用 `/api` 走 Nginx 反代。

#### 6. main.ts 最小可用

`hr-ui/src/main.ts`：

```ts
import { createApp } from 'vue'
import 'element-plus/dist/index.css'
import App from './App.vue'

createApp(App).mount('#app')
```

> Pinia / Router 在階段二接入，這裡先驗證 Element Plus 渲染。

#### 7. 在 App.vue 放一個 el-button 驗證

`hr-ui/src/App.vue`：

```vue
<template>
  <div style="padding: 40px">
    <h1>HR 前端 - Step 1 驗證</h1>
    <el-button type="primary">Element Plus 工作正常</el-button>
  </div>
</template>

<script setup lang="ts"></script>
```

#### 驗收

```bash
cd hr-ui
npm run dev
```

打開 `http://localhost:5173/`，看到藍色 Element Plus 按鈕即通過。

#### 實際安裝結果（完成於 2026-04-14）

| 類別 | 包 | 安裝版本 |
|---|---|---|
| 運行時 | vue | 3.5.32 |
| 運行時 | vue-router | 4.6.4 |
| 運行時 | pinia | 3.0.4 |
| 運行時 | axios | 1.15.0 |
| 運行時 | element-plus | 2.13.7 |
| 運行時 | @element-plus/icons-vue | 2.3.2 |
| 構建時 | vite | 8.0.4 |
| 構建時 | typescript | 6.0.2 |
| 構建時 | vue-tsc | 3.2.6 |
| 構建時 | sass | 1.99.0 |
| 構建時 | unplugin-auto-import | 21.0.0 |
| 構建時 | unplugin-vue-components | 32.0.0 |
| 構建時 | @types/node | 24.12.2 |
| 構建時 | @vitejs/plugin-vue | 6.0.5 |

#### 踩坑與討論記錄

##### ⚠️ 坑 1：並行 `npm install` 會競態覆蓋 `package.json`

**現象：** 同時在兩個 shell 跑 `npm install A` 和 `npm install -D B`，後完成的那個會把先完成的寫入覆蓋掉，導致部分依賴丟失。

**原因：** npm 不是原子寫入，兩個進程都讀舊 package.json → 各自改 → 各自寫回。

**How to apply:** npm 命令必須**串行**執行，不能並行。

##### ⚠️ 坑 2：`import.meta` 不能寫在 Vue 模板表達式裡

**現象：**
```vue
<template>
  <p>{{ import.meta.env.VITE_APP_TITLE }}</p>  <!-- ❌ -->
</template>
```
報錯：`import.meta may appear only with 'sourceType: "module"'`

**原因：** Vue 模板表達式（`{{ }}` 內）走的是輕量 JS 解析器，只接受「表達式」不接受 ES Module 語法。`import.meta` 屬於模塊級語法。

**正解：** 在 `<script setup>` 裡取值賦給變量，模板引用變量。
```vue
<script setup lang="ts">
const title = import.meta.env.VITE_APP_TITLE
</script>
<template>
  <p>{{ title }}</p>  <!-- ✅ -->
</template>
```

##### ⚠️ 坑 3：Chrome 翻譯工具會破壞 Vue 事件綁定

**現象：** 用 Chrome「Translate this page」翻譯頁面後，按鈕點擊無反應；切回原文才能交互。

**原因：** Chrome 翻譯工具直接修改 DOM（替換 TextNode、包 `<font>`），Vue 的虛擬 DOM 認為 DOM 是它控制的，翻譯後 DOM 結構變了 → Vue 下次 patch 對不上真實 DOM → 事件監聽器丟失或報錯。

**決策（2026-04-14）：** 不在 `index.html` 加 `<meta name="google" content="notranslate">` 屏蔽翻譯。
- 用戶立場：翻譯是正常瀏覽器行為，真實用戶會用，禁用是掩蓋問題
- 開發時切回原文即可
- 相關 feedback 已記入記憶系統

#### 用戶提出的概念疑問（對話中解釋了，作索引留存）

| 疑問 | 解釋要點 |
|---|---|
| `npm create vite` 是不是像 Maven archetype？ | 本質一致：下載模板包 → 渲染 → 落盤。npm 生態更靈活，任何 `create-*` 包都是模板 |
| 每個生成的文件/目錄都是幹什麼的？ | index.html（SPA 入口）/ src（源碼）/ public（原樣拷貝資源）/ package.json（≈pom.xml）/ node_modules（依賴實體，不提交）/ 三個 tsconfig（主配 + 瀏覽器端 + Node 端） |
| `<script setup>` vs 選項式 API 區別？ | 選項式按類型分塊（data/methods/watch），組合式按功能組織 + 可抽 `useXxx()` 復用 |

#### 踩坑預判（未實際遇到）

- **Windows 路徑斜槓**：`vite.config.ts` 用 `path.resolve(__dirname, 'src')` 自動處理 `\` vs `/`
- **AutoImport 首次啟動**：dev 啟動時才會生成 `auto-imports.d.ts` / `components.d.ts`，若 IDE 報紅，重啟一次 dev server
- **port 5173 被佔用**：Vite 會自動 +1 嘗試，或在 `vite.config.ts` 改 `server.port`

#### git 狀態

- 倉庫層級：`hr-ui/` 獨立 git repo（與 hr-backend 分倉庫，方案 A）
- 分支：`master`（推 GitHub 前改 `main`）
- 首次 commit 未完成，文件已 staged

---

### Step 2：配置 ESLint + Prettier ✅

#### 目標
統一代碼風格，保存/提交前自動格式化。採用 **ESLint 9+ flat config**（`eslint.config.js`），不再用老版 `.eslintrc.cjs`。

#### 產物清單

| 操作 | 路徑 | 說明 |
|---|---|---|
| 新增 | `hr-ui/eslint.config.js` | ESLint 9 flat config，整合 Vue + TS + Prettier |
| 新增 | `hr-ui/.prettierrc.json` | Prettier 規則（單引號、無分號、2 空格、100 列） |
| 新增 | `hr-ui/.prettierignore` | Prettier 忽略清單 |
| 修改 | `hr-ui/package.json` | scripts 加 `lint` / `format` |

#### 實際安裝包

```bash
npm install -D eslint typescript-eslint eslint-plugin-vue \
  @vue/eslint-config-typescript @vue/eslint-config-prettier prettier
```

| 包 | 版本 | 作用 |
|---|---|---|
| eslint | 10.2.0 | 主引擎 |
| typescript-eslint | 8.58.2 | TS 支持（替代舊 `@typescript-eslint/*` 兩個包） |
| eslint-plugin-vue | 10.8.0 | Vue SFC 規則 |
| @vue/eslint-config-typescript | 14.7.0 | Vue + TS 整合配置 |
| @vue/eslint-config-prettier | 10.2.0 | 關閉與 Prettier 衝突的規則 |
| prettier | 3.8.2 | 格式化 |

> **新老寫法對比：** 舊版需要 `@typescript-eslint/parser` + `@typescript-eslint/eslint-plugin` 兩個包 + `.eslintrc.cjs`；新版 `typescript-eslint` 一個包 + `eslint.config.js` flat config 即可。

#### 關鍵配置決策

**`eslint.config.js`** 採用三段組合：
1. `pluginVue.configs['flat/recommended']`：Vue 官方推薦規則
2. `vueTsEslintConfig()`：TS + Vue 整合
3. `skipFormatting`：關閉所有格式類規則（交給 Prettier）

**自定義調整：**

| 規則 | 設定 | 原因 |
|---|---|---|
| `vue/multi-word-component-names` | off | 允許 `App.vue` 這種單詞名 |
| `vue/no-v-html` | warn | 安全警告但不阻斷 |
| `@typescript-eslint/no-explicit-any` | warn | 允許偶爾用 any，但提醒 |
| `@typescript-eslint/no-unused-vars` | warn + 忽略 `_` 前綴 | 允許 `_unused` 佔位參數 |

**`.prettierrc.json` 風格：**
- 單引號 `'`
- 無分號
- 2 空格縮進
- 最大行寬 100
- `trailingComma: none`（尾隨逗號全關）
- `endOfLine: lf`（Windows 下也用 LF，跨平台一致）

**忽略自動生成的類型檔：**
`src/types/auto-imports.d.ts` 和 `components.d.ts` 由 unplugin 動態生成，不參與 lint/format。

#### npm 腳本

```json
{
  "scripts": {
    "lint": "eslint . --fix",
    "format": "prettier --write \"src/**/*.{ts,vue,scss,json}\""
  }
}
```

> 注意：新版 `eslint .` 不需要 `--ext` 參數，從 `eslint.config.js` 的 `files` 字段讀取。

#### 驗收（完成於 2026-04-15）

```bash
npm run lint     # 零告警通過
npm run format   # App.vue 被規整（el-button 單行化等）
```

#### 後續計劃

- [ ] 配置 Git pre-commit hook（husky + lint-staged），暫緩到階段八前再加
- [ ] IDE 配置：VS Code 裝 ESLint + Prettier 插件，`.vscode/settings.json` 開 saveOnSave

---
