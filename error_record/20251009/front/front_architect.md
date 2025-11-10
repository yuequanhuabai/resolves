# PAP 前端架构文档

## 1. 项目概览

**项目名称**: PAP (Process Application Platform) 前端系统
**技术栈**: Vue 3 + TypeScript + Vite + Element Plus
**原始框架**: 基于芋道 (Yudao) UI Admin Vue3 模板
**代码库**: `poc-pro-ui/`

### 核心技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Vue | 3.5.12 | 渐进式 JavaScript 框架 |
| TypeScript | 5.3.3 | 类型安全的 JavaScript 超集 |
| Vite | 5.4.3 | 现代化前端构建工具 |
| Element Plus | 2.9.1 | Vue 3 UI 组件库 |
| Pinia | 2.1.7 | Vue 3 官方状态管理库 |
| Vue Router | 4.4.5 | Vue 官方路由管理器 |
| Axios | 1.8.2 | HTTP 客户端 |
| ECharts | 5.5.0 | 数据可视化图表库 |
| BPMN.js | 17.9.2 | 工作流设计器 |
| UnoCSS | 0.58.5 | 原子化 CSS 引擎 |

---

## 2. 项目结构

```
poc-pro-ui/
├── build/                      # 构建配置
│   └── vite/                   # Vite 插件配置
├── public/                     # 静态资源（不经过 webpack 处理）
├── src/                        # 源代码目录
│   ├── api/                    # API 接口定义
│   │   ├── benchmark/          # Benchmark 业务接口
│   │   ├── bpm/                # BPM 工作流接口
│   │   ├── buylist/            # Buylist 业务接口
│   │   ├── infra/              # 基础设施接口（代码生成、文件等）
│   │   ├── login/              # 登录认证接口
│   │   ├── modelportolio/      # 模型组合接口
│   │   └── system/             # 系统管理接口（用户、角色、权限等）
│   │
│   ├── assets/                 # 静态资源（经过 webpack 处理）
│   │   ├── ai/                 # AI 相关资源
│   │   ├── audio/              # 音频文件
│   │   ├── imgs/               # 图片资源
│   │   ├── map/                # 地图数据
│   │   └── svgs/               # SVG 图标
│   │
│   ├── components/             # 全局公共组件
│   │   ├── AppLinkInput/       # 应用链接输入组件
│   │   ├── bpmnProcessDesigner/# BPMN 流程设计器
│   │   ├── ContentWrap/        # 内容包装容器
│   │   ├── CountTo/            # 数字滚动组件
│   │   ├── Crontab/            # Cron 表达式组件
│   │   ├── Cropper/            # 图片裁剪组件
│   │   ├── DeptSelectForm/     # 部门选择表单
│   │   ├── Dialog/             # 对话框组件
│   │   ├── DictTag/            # 字典标签组件
│   │   ├── Echart/             # ECharts 图表封装
│   │   ├── Editor/             # 富文本编辑器
│   │   ├── Form/               # 表单组件
│   │   ├── FormCreate/         # 动态表单生成器
│   │   ├── Icon/               # 图标组件
│   │   ├── ImageViewer/        # 图片预览组件
│   │   ├── InputTree/          # 树形输入组件
│   │   ├── Table/              # 表格组件
│   │   ├── TreeSelect/         # 树形选择器
│   │   └── UploadFile/         # 文件上传组件
│   │
│   ├── config/                 # 全局配置
│   │   └── axios/              # Axios 配置（请求拦截、响应拦截）
│   │
│   ├── directives/             # 全局自定义指令
│   │   ├── auth/               # 权限指令 v-auth
│   │   └── mountedFocus/       # 自动聚焦指令
│   │
│   ├── hooks/                  # 组合式 API Hooks
│   │   └── web/                # Web 相关 Hooks
│   │       ├── useTitle        # 页面标题
│   │       ├── useNProgress    # 进度条
│   │       ├── usePageLoading  # 页面加载
│   │       └── ...
│   │
│   ├── layout/                 # 布局组件
│   │   ├── components/         # 布局子组件（导航栏、侧边栏、标签栏等）
│   │   └── Layout.vue          # 主布局容器
│   │
│   ├── locales/                # 国际化语言包
│   │   ├── zh-CN/              # 简体中文
│   │   └── en/                 # 英语
│   │
│   ├── plugins/                # 插件配置
│   │   ├── elementPlus/        # Element Plus 配置
│   │   ├── formCreate/         # Form Create 配置
│   │   ├── svgIcon/            # SVG 图标注册
│   │   ├── unocss/             # UnoCSS 配置
│   │   ├── vueI18n/            # 国际化配置
│   │   └── animate.css         # 动画库
│   │
│   ├── router/                 # 路由配置
│   │   ├── modules/            # 路由模块（按业务模块拆分）
│   │   ├── index.ts            # 路由主入口
│   │   └── types.ts            # 路由类型定义
│   │
│   ├── store/                  # Pinia 状态管理
│   │   ├── modules/            # Store 模块
│   │   │   ├── app.ts          # 应用全局状态（布局、主题、语言）
│   │   │   ├── user.ts         # 用户信息
│   │   │   ├── permission.ts   # 权限路由
│   │   │   ├── dict.ts         # 数据字典
│   │   │   ├── tagsView.ts     # 标签页导航
│   │   │   ├── lock.ts         # 屏幕锁定
│   │   │   └── bpm/            # BPM 相关状态
│   │   └── index.ts            # Store 主入口
│   │
│   ├── styles/                 # 全局样式
│   │   ├── index.scss          # 样式主入口
│   │   ├── variables.scss      # SCSS 变量
│   │   └── ...
│   │
│   ├── types/                  # TypeScript 类型定义
│   │   ├── auto-imports.d.ts   # 自动导入类型声明
│   │   ├── auto-components.d.ts# 自动注册组件类型声明
│   │   └── ...
│   │
│   ├── utils/                  # 工具函数库
│   │   ├── auth.ts             # 认证工具（token 存取）
│   │   ├── dict.ts             # 字典工具
│   │   ├── download.ts         # 文件下载
│   │   ├── formatTime.ts       # 时间格式化
│   │   ├── tree.ts             # 树形数据处理
│   │   ├── permission.ts       # 权限判断
│   │   ├── routerHelper.ts     # 路由辅助函数
│   │   └── index.ts            # 通用工具集合
│   │
│   ├── views/                  # 页面视图组件
│   │   ├── benchmark/          # Benchmark 业务页面
│   │   │   ├── index.vue       # 列表页
│   │   │   └── detail/         # 详情页
│   │   ├── bpm/                # BPM 工作流页面
│   │   │   ├── model/          # 流程模型管理
│   │   │   ├── processInstance/# 流程实例
│   │   │   ├── task/           # 任务管理
│   │   │   └── ...
│   │   ├── buylist/            # Buylist 业务页面
│   │   ├── modelportfolio/     # 模型组合页面
│   │   ├── system/             # 系统管理页面
│   │   │   ├── user/           # 用户管理
│   │   │   ├── role/           # 角色管理
│   │   │   ├── menu/           # 菜单管理
│   │   │   ├── dept/           # 部门管理
│   │   │   └── ...
│   │   ├── infra/              # 基础设施页面
│   │   │   ├── codegen/        # 代码生成
│   │   │   ├── file/           # 文件管理
│   │   │   └── ...
│   │   ├── Login/              # 登录页
│   │   ├── Home/               # 首页
│   │   ├── Profile/            # 个人中心
│   │   ├── Error/              # 错误页（404、403 等）
│   │   └── Redirect/           # 路由重定向
│   │
│   ├── App.vue                 # 根组件
│   ├── main.ts                 # 应用入口
│   └── permission.ts           # 全局权限守卫
│
├── types/                      # 全局类型定义
├── .env                        # 环境变量（公共）
├── .env.local                  # 本地开发环境变量
├── .env.dev                    # 开发环境变量
├── .env.test                   # 测试环境变量
├── .env.stage                  # 预发布环境变量
├── .env.prod                   # 生产环境变量
├── index.html                  # HTML 模板
├── package.json                # 项目依赖配置
├── tsconfig.json               # TypeScript 配置
├── vite.config.ts              # Vite 配置
└── uno.config.ts               # UnoCSS 配置
```

---

## 3. 核心架构设计

### 3.1 应用启动流程

**文件**: `src/main.ts`

```typescript
// 应用初始化顺序
const setupAll = async () => {
  const app = createApp(App)

  await setupI18n(app)         // 1. 初始化国际化
  setupStore(app)              // 2. 初始化状态管理
  setupGlobCom(app)            // 3. 注册全局组件
  setupElementPlus(app)        // 4. 初始化 Element Plus
  setupFormCreate(app)         // 5. 初始化 Form Create
  setupRouter(app)             // 6. 初始化路由
  setupAuth(app)               // 7. 注册权限指令
  setupMountedFocus(app)       // 8. 注册聚焦指令

  await router.isReady()       // 9. 等待路由就绪
  app.use(VueDOMPurifyHTML)    // 10. 注册 HTML 安全组件
  app.mount('#app')            // 11. 挂载应用
}
```

### 3.2 路由系统

#### 路由守卫流程 (`src/permission.ts`)

```
用户访问路由
    ↓
router.beforeEach (全局前置守卫)
    ↓
检查 token 是否存在
    ├─ 无 token
    │   ├─ 在白名单? → 放行
    │   └─ 不在白名单? → 重定向到 /login
    │
    └─ 有 token
        ├─ 访问 /login? → 重定向到首页
        │
        └─  
            │
            └─ 未加载用户信息
                ├─ 1. 加载数据字典
                ├─ 2. 获取用户信息
                ├─ 3. 获取权限路由
                ├─ 4. 动态添加路由
                └─ 5. 重定向到目标页面
```

#### 动态路由加载

- **后端过滤**: 后端根据用户权限返回菜单树
- **前端生成**: `permissionStore.generateRoutes()` 将菜单转换为路由配置
- **动态添加**: `router.addRoute()` 动态注册可访问的路由

### 3.3 状态管理 (Pinia)

#### Store 模块职责

| Store 模块 | 文件 | 职责 |
|-----------|------|------|
| **app** | `store/modules/app.ts` | 应用全局状态：侧边栏展开/收起、设备类型、主题配置、布局模式 |
| **user** | `store/modules/user.ts` | 用户信息：用户资料、登录/登出、Token 管理 |
| **permission** | `store/modules/permission.ts` | 权限路由：动态路由生成、菜单权限控制 |
| **dict** | `store/modules/dict.ts` | 数据字典：字典数据缓存、字典查询工具 |
| **tagsView** | `store/modules/tagsView.ts` | 标签页导航：已访问页面、缓存页面、标签操作 |
| **lock** | `store/modules/lock.ts` | 屏幕锁定：锁屏状态、密码验证 |
| **bpm** | `store/modules/bpm/` | BPM 状态：流程设计器状态、任务状态等 |

#### 状态持久化

使用 `pinia-plugin-persistedstate` 插件实现状态持久化到 `localStorage`。

### 3.4 HTTP 请求架构

#### Axios 配置 (`src/config/axios/`)

**请求拦截器**：
- 添加 `Authorization` 头（Bearer Token）
- 添加租户 ID 头（`tenant-id`）
- 添加时间戳防止缓存

**响应拦截器**：
- 统一处理业务错误码
- Token 过期自动跳转登录
- 显示错误消息（Message 提示）
- 文件下载处理

#### API 层组织

```typescript
// 示例: src/api/benchmark/index.ts
export const BenchmarkApi = {
  // 分页查询
  getBenchmarkPage: (params: BenchmarkPageReqVO) => {
    return request.get({ url: '/business/benchmark/page', params })
  },

  // 获取详情
  getBenchmarkDetail: (id: number) => {
    return request.get({ url: '/business/benchmark/get?id=' + id })
  },

  // 创建
  createBenchmark: (data: BenchmarkSaveReqVO) => {
    return request.post({ url: '/business/benchmark/create', data })
  },

  // 更新
  updateBenchmark: (data: BenchmarkSaveReqVO) => {
    return request.put({ url: '/business/benchmark/update', data })
  },

  // 删除
  deleteBenchmark: (id: number) => {
    return request.delete({ url: '/business/benchmark/delete?id=' + id })
  }
}
```

### 3.5 组件设计规范

#### 全局组件

全局组件在 `src/components/` 下定义，并在 `src/components/index.ts` 中自动注册：

```typescript
// 自动注册所有全局组件
const components = import.meta.glob('./**/*.vue')
export const setupGlobCom = (app: App) => {
  for (const [key, value] of Object.entries(components)) {
    const name = key.split('/')[1]
    app.component(name, defineAsyncComponent(value as any))
  }
}
```

#### 业务组件

业务组件放在对应的 `views/` 子目录下，按功能模块组织。

**命名规范**：
- 页面组件：PascalCase（如 `BenchmarkList.vue`）
- 业务组件：PascalCase（如 `BenchmarkForm.vue`）
- 工具组件：小写 + 连字符（如 `user-select.vue`）

### 3.6 样式架构

#### UnoCSS 原子化 CSS

使用 UnoCSS 作为主要样式方案，支持以下特性：
- 即时按需生成 CSS
- 类似 Tailwind 的工具类语法
- 自定义快捷方式（shortcuts）
- 图标集成 (`@iconify`)

**配置文件**: `uno.config.ts`

#### SCSS 全局变量

**配置**: `vite.config.ts` 中自动注入 SCSS 变量

```scss
// src/styles/variables.scss
$primary-color: #409eff;
$sidebar-width: 210px;
// ... 其他变量
```

所有 `.vue` 文件的 `<style lang="scss">` 都可以直接使用这些变量。

---

## 4. 关键功能实现

### 4.1 权限控制

#### 按钮级权限控制

使用自定义指令 `v-auth`：

```vue
<template>
  <el-button v-auth="'system:user:create'">新增</el-button>
  <el-button v-auth="['system:user:update']">编辑</el-button>
</template>
```

**实现**: `src/directives/auth/index.ts`

#### 菜单权限控制

后端返回用户可访问的菜单树，前端根据菜单动态生成路由。

**流程**:
1. 用户登录后调用 `/system/auth/get-permission-info` 获取权限信息
2. `permissionStore.generateRoutes()` 处理菜单数据
3. 使用 `router.addRoute()` 动态添加路由
4. 侧边栏菜单根据路由配置自动生成

### 4.2 数据字典

#### 字典使用

```vue
<template>
  <!-- 字典标签展示 -->
  <dict-tag :type="'system_user_sex'" :value="form.sex" />

  <!-- 字典选择器 -->
  <el-select v-model="form.sex">
    <el-option
      v-for="dict in getIntDictOptions('system_user_sex')"
      :key="dict.value"
      :label="dict.label"
      :value="dict.value"
    />
  </el-select>
</template>

<script setup lang="ts">
import { getIntDictOptions } from '@/utils/dict'
</script>
```

#### 字典工具函数

- `getIntDictOptions(type)`: 获取整数类型字典选项
- `getStrDictOptions(type)`: 获取字符串类型字典选项
- `getDictLabel(type, value)`: 根据值获取字典标签

**实现**: `src/utils/dict.ts`

### 4.3 国际化 (i18n)

#### 语言切换

```vue
<template>
  <el-dropdown @command="handleSetLanguage">
    <span>{{ currentLang }}</span>
    <template #dropdown>
      <el-dropdown-menu>
        <el-dropdown-item command="zh-CN">简体中文</el-dropdown-item>
        <el-dropdown-item command="en">English</el-dropdown-item>
      </el-dropdown-menu>
    </template>
  </el-dropdown>
</template>

<script setup lang="ts">
import { useLocaleStore } from '@/store/modules/locale'

const localeStore = useLocaleStore()
const handleSetLanguage = (lang: string) => {
  localeStore.setCurrentLocale({ lang })
}
</script>
```

#### 翻译使用

```vue
<template>
  <h1>{{ t('router.login') }}</h1>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
</script>
```

### 4.4 文件上传

#### 上传组件使用

```vue
<template>
  <UploadFile
    v-model="formData.fileUrl"
    :limit="1"
    :file-size="5"
    :file-type="['png', 'jpg', 'jpeg']"
  />
</template>
```

**组件**: `src/components/UploadFile/index.vue`

**后端接口**: `/infra/file/upload`

### 4.5 富文本编辑器

使用 `@wangeditor/editor-for-vue`:

```vue
<template>
  <Editor
    v-model="content"
    :editorConfig="editorConfig"
  />
</template>

<script setup lang="ts">
import { Editor } from '@/components/Editor'

const content = ref('<p>默认内容</p>')
const editorConfig = {
  placeholder: '请输入内容...',
  MENU_CONF: {
    uploadImage: {
      server: '/infra/file/upload',
      fieldName: 'file'
    }
  }
}
</script>
```

### 4.6 ECharts 图表

#### 图表封装

```vue
<template>
  <Echart
    :options="chartOptions"
    :height="400"
  />
</template>

<script setup lang="ts">
import { Echart } from '@/components/Echart'

const chartOptions = computed(() => ({
  title: { text: 'Benchmark 权重分布' },
  tooltip: {},
  xAxis: { data: ['一级', '二级', '三级'] },
  yAxis: {},
  series: [{
    type: 'bar',
    data: [30, 50, 20]
  }]
}))
</script>
```

### 4.7 BPMN 工作流设计器

#### 设计器使用

```vue
<template>
  <bpmn-process-designer
    v-model="processXml"
    :value="processXml"
    @save="handleSave"
  />
</template>

<script setup lang="ts">
import { bpmnProcessDesigner } from '@/components/bpmnProcessDesigner'

const processXml = ref<string>('')
const handleSave = (xml: string) => {
  // 保存流程定义
  BpmModelApi.updateModel({ bpmnXml: xml })
}
</script>
```

**组件**: `src/components/bpmnProcessDesigner/`

---

## 5. 构建与部署

### 5.1 环境变量配置

#### 环境文件

| 文件 | 用途 | 命令 |
|------|------|------|
| `.env` | 公共配置 | 所有环境 |
| `.env.local` | 本地开发 | `npm run dev` |
| `.env.dev` | 开发环境 | `npm run build:dev` |
| `.env.test` | 测试环境 | `npm run build:test` |
| `.env.stage` | 预发布环境 | `npm run build:stage` |
| `.env.prod` | 生产环境 | `npm run build:prod` |

#### 关键变量

```bash
# 应用标题
VITE_APP_TITLE=PAP 管理系统

# 后端接口地址
VITE_BASE_URL=http://localhost:48080

# 基础路径
VITE_BASE_PATH=/

# 开发服务器端口
VITE_PORT=80

# 是否删除 console
VITE_DROP_CONSOLE=false

# 是否删除 debugger
VITE_DROP_DEBUGGER=false

# 是否生成 sourcemap
VITE_SOURCEMAP=false

# 输出目录
VITE_OUT_DIR=dist
```

### 5.2 构建命令

```bash
# 本地开发
npm run dev

# 开发环境构建
npm run build:dev

# 测试环境构建
npm run build:test

# 预发布环境构建
npm run build:stage

# 生产环境构建
npm run build:prod

# 本地预览构建结果
npm run preview
```

### 5.3 构建优化

#### 代码分割 (`vite.config.ts`)

```typescript
build: {
  rollupOptions: {
    output: {
      manualChunks: {
        'echarts': ['echarts'],               // ECharts 单独打包
        'form-create': ['@form-create/element-ui'],
        'form-designer': ['@form-create/designer']
      }
    }
  }
}
```

#### 依赖预构建

**配置**: `build/vite/optimize.ts`

```typescript
// 预构建包含项
export const include = [
  'vue',
  'vue-router',
  'pinia',
  'axios',
  'element-plus/es',
  // ... 其他依赖
]

// 预构建排除项
export const exclude = [
  'vue-demi'
]
```

### 5.4 部署流程

#### 部署到 Nginx

1. **构建项目**：
```bash
npm run build:prod
```

2. **上传 dist 目录** 到服务器

3. **Nginx 配置示例**：
```nginx
server {
    listen 80;
    server_name yourdomain.com;
    root /var/www/pap-ui/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # 代理后端 API
    location /admin-api/ {
        proxy_pass http://localhost:48080/admin-api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### 使用 Docker 部署

**Dockerfile 示例**：
```dockerfile
FROM node:16 as builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install
COPY . .
RUN pnpm run build:prod

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## 6. 开发规范

### 6.1 代码规范

#### ESLint 配置

**文件**: `.eslintrc.js`

主要规则：
- Vue 3 最佳实践
- TypeScript 严格模式
- Prettier 集成

#### 提交前自动格式化

使用 `lint-staged` + `husky` 实现：

```json
// package.json
{
  "lint-staged": {
    "*.{js,ts,vue}": [
      "eslint --fix",
      "prettier --write"
    ]
  }
}
```

### 6.2 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 组件文件 | PascalCase | `BenchmarkList.vue` |
| 工具文件 | camelCase | `formatTime.ts` |
| 常量 | UPPER_SNAKE_CASE | `MAX_FILE_SIZE` |
| 接口/类型 | PascalCase + VO/DTO 后缀 | `BenchmarkPageReqVO` |
| 函数 | camelCase + 动词开头 | `getBenchmarkList()` |
| Vue ref/reactive | camelCase | `const formData = ref({})` |

### 6.3 目录组织规范

#### 页面组件目录结构

```
views/benchmark/
├── index.vue              # 列表页
├── detail/
│   ├── index.vue          # 详情页主文件
│   ├── components/        # 详情页私有组件
│   │   ├── BenchmarkTree.vue
│   │   └── WeightChart.vue
│   └── hooks/             # 详情页私有 hooks
│       └── useBenchmark.ts
└── BenchmarkForm.vue      # 表单组件（可复用）
```

#### API 目录结构

```
api/benchmark/
├── index.ts               # Benchmark API 定义
└── types.ts               # Benchmark 类型定义
```

### 6.4 TypeScript 使用规范

#### 接口定义

```typescript
// 请求 VO
export interface BenchmarkPageReqVO extends PageParam {
  name?: string
  status?: number
  createTime?: Date[]
}

// 响应 VO
export interface BenchmarkRespVO {
  id: number
  name: string
  status: number
  createTime: string
  updateTime: string
}

// 保存 VO
export interface BenchmarkSaveReqVO {
  id?: number
  name: string
  status: number
}
```

#### 类型导入

```typescript
// 优先使用 type 导入
import type { BenchmarkRespVO } from '@/api/benchmark/types'
```

---

## 7. 常见问题与解决方案

### 7.1 跨域问题

**开发环境**：
- Vite 代理配置（目前已注释，后端支持 CORS）
- 后端添加 CORS 头

**生产环境**：
- Nginx 反向代理
- 后端 CORS 配置

### 7.2 路由刷新 404

**原因**: SPA 应用使用 History 模式，刷新时服务器找不到对应路径

**解决方案**: Nginx 配置 `try_files`
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

### 7.3 Token 过期处理

**实现**: `src/config/axios/service.ts`

```typescript
// 响应拦截器
if (code === 401) {
  if (!isRelogin.show) {
    isRelogin.show = true
    ElMessageBox.confirm('登录状态已过期，请重新登录', '提示', {
      confirmButtonText: '重新登录',
      cancelButtonText: '取消',
      type: 'warning'
    }).then(() => {
      const userStore = useUserStoreWithOut()
      userStore.logout().then(() => {
        location.href = '/login'
      })
    })
  }
  return Promise.reject(new Error('token 过期'))
}
```

### 7.4 白屏问题排查

**可能原因**：
1. JavaScript 报错（打开控制台查看）
2. 路由配置错误
3. 后端接口不可用
4. 构建产物路径错误（检查 `VITE_BASE_PATH`）

**排查步骤**：
1. 打开浏览器开发者工具查看 Console 和 Network
2. 检查是否有资源 404
3. 检查是否有 JavaScript 报错
4. 检查后端接口是否正常返回

### 7.5 大文件上传

**前端配置**：
```typescript
// 分片上传
const uploadLargeFile = async (file: File) => {
  const chunkSize = 5 * 1024 * 1024 // 5MB
  const chunks = Math.ceil(file.size / chunkSize)

  for (let i = 0; i < chunks; i++) {
    const chunk = file.slice(i * chunkSize, (i + 1) * chunkSize)
    await FileApi.uploadChunk({
      file: chunk,
      index: i,
      total: chunks
    })
  }
}
```

**后端**: 需要实现分片上传接口

---

## 8. 扩展阅读

### 8.1 技术文档链接

- [Vue 3 官方文档](https://cn.vuejs.org/)
- [Vite 官方文档](https://cn.vitejs.dev/)
- [Element Plus 文档](https://element-plus.org/zh-CN/)
- [Pinia 文档](https://pinia.vuejs.org/zh/)
- [Vue Router 文档](https://router.vuejs.org/zh/)
- [UnoCSS 文档](https://unocss.dev/)
- [TypeScript 文档](https://www.typescriptlang.org/zh/)

### 8.2 项目特定资源

- **芋道源码**: https://gitee.com/yudaocode/yudao-ui-admin-vue3
- **BPMN.js 文档**: https://bpmn.io/toolkit/bpmn-js/
- **ECharts 文档**: https://echarts.apache.org/zh/index.html

---

## 9. 总结

PAP 前端项目基于 Vue 3 生态构建，采用现代化的技术栈和工程化配置：

**核心特点**：
- ✅ **类型安全**: 全面使用 TypeScript
- ✅ **组件化**: 丰富的全局组件库和业务组件
- ✅ **状态管理**: Pinia 实现集中式状态管理
- ✅ **权限控制**: 基于 RBAC 的细粒度权限系统
- ✅ **国际化**: 完善的多语言支持
- ✅ **工作流**: 集成 BPMN.js 流程设计器
- ✅ **响应式**: 移动端友好的响应式布局
- ✅ **性能优化**: 代码分割、懒加载、CDN 加速

**开发体验**：
- ⚡ Vite 极速开发服务器
- 🔥 HMR 热模块替换
- 📦 自动导入（组件、API、组合式函数）
- 🎨 UnoCSS 原子化 CSS
- 🔧 完善的 ESLint + Prettier 配置
- 📝 TypeScript 智能提示

---

**文档版本**: 1.0
**最后更新**: 2025-10-29
**维护者**: PAP 开发团队
