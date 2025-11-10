# 前端项目架构分析

## 一、项目概览

**项目名称**：PAP (Process Application Platform) - 前端项目
**技术栈**：Vue 3 + TypeScript + Element Plus + Vue Router + Pinia
**项目路径**：`poc-pro-ui/`
**架构模式**：SPA (Single Page Application) + 模块化组件设计

---

## 二、核心技术栈

### 2.1 前端框架

```
Vue 3 (Composition API)
├── 响应式系统：基于 Proxy 的响应式
├── 组合式 API：<script setup> 语法
├── 生命周期：onMounted, onBeforeUnmount 等
└── 响应式工具：ref, reactive, computed, watch
```

### 2.2 UI 组件库

```
Element Plus
├── 表单组件：el-form, el-input, el-select
├── 数据展示：el-table, el-tree, el-descriptions
├── 反馈组件：el-message, el-message-box, el-notification
└── 布局组件：el-container, el-header, el-main
```

### 2.3 路由管理

```
Vue Router 4
├── 路由模式：History 模式
├── 路由守卫：全局前置守卫、路由级守卫
├── 动态路由：基于权限的动态路由注册
└── 路由懒加载：import() 动态导入
```

### 2.4 状态管理

```
Pinia
├── Store 模块：user, permission, tagsView, app
├── 响应式状态：state, getters, actions
└── 持久化：本地存储集成
```

---

## 三、项目目录结构

```
poc-pro-ui/
├── src/
│   ├── views/                    # 页面组件（核心业务逻辑）
│   │   ├── benchmark/           # Benchmark 业务模块
│   │   │   ├── privateBank/     # Private Banking 列表页
│   │   │   │   └── index.vue
│   │   │   ├── retailBank/      # Retail Banking 列表页
│   │   │   │   └── index.vue
│   │   │   └── detail/          # 详情/编辑页
│   │   │       └── index.vue
│   │   ├── bpm/                 # 工作流模块
│   │   │   ├── approval/        # 审批页面
│   │   │   └── ...
│   │   ├── business/            # 业务模块
│   │   └── system/              # 系统管理模块
│   │
│   ├── router/                   # 路由配置
│   │   ├── index.ts             # 路由主入口
│   │   └── modules/             # 模块化路由
│   │       ├── remaining.ts     # 剩余路由（包含 benchmark, bpm）
│   │       ├── business.ts      # 业务路由
│   │       └── system.ts        # 系统路由
│   │
│   ├── api/                      # API 接口层
│   │   ├── benchmark/           # Benchmark API
│   │   │   └── index.ts
│   │   ├── bpm/                 # BPM API
│   │   └── request.ts           # Axios 封装
│   │
│   ├── store/                    # 状态管理
│   │   └── modules/
│   │       ├── user.ts          # 用户状态
│   │       ├── permission.ts    # 权限状态
│   │       ├── tagsView.ts      # 标签页状态
│   │       └── app.ts           # 应用状态
│   │
│   ├── components/               # 公共组件
│   │   ├── Layout/              # 布局组件
│   │   ├── ProcessInstance/     # 流程实例组件
│   │   └── ...
│   │
│   ├── utils/                    # 工具函数
│   │   ├── request.ts           # HTTP 请求封装
│   │   ├── auth.ts              # 认证工具
│   │   └── validate.ts          # 验证工具
│   │
│   ├── types/                    # TypeScript 类型定义
│   │   ├── benchmark.d.ts
│   │   └── ...
│   │
│   ├── App.vue                   # 根组件
│   └── main.ts                   # 应用入口
│
├── public/                       # 静态资源
├── package.json                  # 依赖配置
├── vite.config.ts               # Vite 构建配置
└── tsconfig.json                # TypeScript 配置
```

---

## 四、架构层次分析

### 4.1 三层架构设计

```
┌─────────────────────────────────────────────────┐
│              视图层 (View Layer)                 │
│  src/views/ - 页面组件，处理用户交互              │
│  - 表单输入、按钮点击、数据展示                    │
│  - 调用 API 层获取/提交数据                       │
│  - 使用 Router 进行页面导航                      │
└──────────────────┬──────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────┐
│             API 层 (API Layer)                   │
│  src/api/ - HTTP 请求封装，与后端通信              │
│  - 封装 RESTful API 调用                         │
│  - 请求拦截器：添加 token、处理超时                │
│  - 响应拦截器：统一错误处理、数据转换               │
└──────────────────┬──────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────┐
│           后端服务 (Backend Service)              │
│  Spring Boot REST API                           │
│  - 业务逻辑处理                                   │
│  - 数据持久化                                     │
│  - 工作流引擎 (Flowable)                          │
└─────────────────────────────────────────────────┘
```

### 4.2 页面组件结构

```
页面组件 (.vue 文件)
├── <template>                  # 模板结构
│   ├── 布局容器
│   ├── 表单/表格/树形控件
│   └── 操作按钮
│
├── <script setup>              # 组合式 API 逻辑
│   ├── 导入依赖
│   │   ├── Vue 核心 API (ref, reactive, computed)
│   │   ├── Vue Router (useRouter, useRoute)
│   │   ├── API 接口
│   │   └── Store (useStore)
│   │
│   ├── 响应式状态定义
│   │   ├── 表单数据 (reactive)
│   │   ├── 加载状态 (ref)
│   │   └── 列表数据 (ref)
│   │
│   ├── 计算属性 (computed)
│   │
│   ├── 生命周期钩子
│   │   ├── onMounted - 初始化数据
│   │   └── onBeforeUnmount - 清理资源
│   │
│   └── 方法定义
│       ├── 事件处理函数 (handleXxx)
│       ├── API 调用函数 (fetchData, submitForm)
│       └── 工具函数 (validate, format)
│
└── <style scoped>              # 组件样式
    └── SCSS/CSS 样式
```

---

## 五、路由系统架构

### 5.1 路由配置结构

```
Router 系统
├── 静态路由 (Static Routes)
│   ├── 登录页 (/login)
│   ├── 404 页面 (/404)
│   └── 基础布局路由
│
└── 动态路由 (Dynamic Routes)
    ├── 基于权限加载
    ├── 从后端获取用户菜单
    └── 动态注册到 Router
```

### 5.2 路由配置模式

**文件**：`src/router/modules/remaining.ts`

```javascript
// 路由配置示例
{
  path: '/benchmark',              // 路由路径
  component: Layout,               // 布局组件
  name: 'BenchmarkDetail',         // 路由名称
  meta: {                          // 元数据
    hidden: true,                  // 是否在菜单中隐藏
    title: 'Benchmark 详情',       // 页面标题
    icon: 'ep:pie-chart',          // 图标
    noCache: false,                // 是否缓存
    canTo: true,                   // 是否可直接访问
    activeMenu: '/benchmark'       // 激活的菜单项
  },
  children: [                      // 子路由
    {
      path: 'detail',              // 完整路径: /benchmark/detail
      component: () => import('...'),  // 懒加载组件
      name: 'BenchmarkDetailPage',
      meta: { ... }
    }
  ]
}
```

### 5.3 路由导航流程

```
用户操作
  ↓
触发路由导航 (router.push / router.replace / router.back)
  ↓
全局前置守卫 (beforeEach)
  ├── 检查用户登录状态
  ├── 验证权限
  └── 设置页面标题
  ↓
路由组件加载 (异步组件)
  ↓
路由组件渲染
  ↓
全局后置钩子 (afterEach)
  └── 结束加载进度条
```

### 5.4 路由跳转方式

| 方式 | 代码示例 | 说明 | 浏览器历史 |
|------|----------|------|-----------|
| **编程式导航** | `router.push('/path')` | 新增历史记录 | 添加新记录 |
| **编程式导航** | `router.replace('/path')` | 替换当前记录 | 替换当前记录 |
| **编程式导航** | `router.back()` | 返回上一页 | 返回上一条 |
| **编程式导航** | `router.go(-1)` | 前进/后退 n 步 | 移动 n 条 |
| **声明式导航** | `<router-link to="/path">` | 链接导航 | 添加新记录 |

---

## 六、状态管理架构

### 6.1 Pinia Store 结构

```
Pinia Store
├── user Store                    # 用户状态
│   ├── state: userInfo, token
│   ├── getters: isLogin, userName
│   └── actions: login, logout, getUserInfo
│
├── permission Store              # 权限状态
│   ├── state: routes, addRoutes
│   ├── getters: permissionRoutes
│   └── actions: generateRoutes, setRoutes
│
├── tagsView Store               # 标签页状态
│   ├── state: visitedViews, cachedViews
│   ├── getters: visitedViewsCount
│   └── actions: addView, delView, delAllViews
│
└── app Store                    # 应用状态
    ├── state: sidebar, device, theme
    └── actions: toggleSidebar, setDevice
```

### 6.2 Store 使用模式

```javascript
// 在组件中使用 Store
import { useTagsViewStore } from '@/store/modules/tagsView'

const tagsViewStore = useTagsViewStore()

// 读取状态
const views = tagsViewStore.visitedViews

// 调用 action
tagsViewStore.delView(route)
```

---

## 七、API 请求架构

### 7.1 请求封装层次

```
组件调用
  ↓
API 接口模块 (src/api/benchmark/index.ts)
  ├── export const getBenchmarkList = (params) => request.get(...)
  ├── export const updateBenchmark = (data) => request.put(...)
  └── export const deleteBenchmark = (id) => request.delete(...)
  ↓
Request 封装 (src/utils/request.ts)
  ├── 请求拦截器
  │   ├── 添加 Authorization token
  │   ├── 设置 Content-Type
  │   └── 处理请求参数
  ├── Axios 实例
  └── 响应拦截器
      ├── 统一错误处理
      ├── Token 过期处理
      └── 数据解包 (response.data)
  ↓
后端 API (Spring Boot)
```

### 7.2 API 接口模块示例

**文件**：`src/api/benchmark/index.ts`

```typescript
import request from '@/utils/request'

// 获取流程状态
export const getProcessKey = (processInstanceId: string) => {
  return request.get({
    url: `/bpm/benchmark/process-key/${processInstanceId}`
  })
}

// 更新 Benchmark
export const updateBenchmark = (data: BenchmarkVO) => {
  return request.put({
    url: '/bpm/benchmark/update',
    data
  })
}

// 查询列表
export const getBenchmarkPage = (params: BenchmarkPageReqVO) => {
  return request.get({
    url: '/bpm/benchmark/page',
    params
  })
}
```

### 7.3 请求拦截器逻辑

```javascript
// 请求拦截器
request.interceptors.request.use(
  config => {
    // 1. 添加 token
    const token = getToken()
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`
    }

    // 2. 设置租户 ID
    const tenantId = getTenantId()
    if (tenantId) {
      config.headers['tenant-id'] = tenantId
    }

    return config
  },
  error => Promise.reject(error)
)

// 响应拦截器
request.interceptors.response.use(
  response => {
    const res = response.data

    // 1. 业务错误码处理
    if (res.code !== 0) {
      ElMessage.error(res.msg || 'Request failed')
      return Promise.reject(new Error(res.msg))
    }

    // 2. 返回数据
    return res.data
  },
  error => {
    // 3. HTTP 错误处理
    if (error.response?.status === 401) {
      // Token 过期，跳转登录
      router.push('/login')
    }
    return Promise.reject(error)
  }
)
```

---

## 八、组件通信模式

### 8.1 父子组件通信

```vue
<!-- 父组件 -->
<template>
  <ChildComponent
    :prop-data="parentData"
    @child-event="handleChildEvent"
  />
</template>

<script setup>
// 接收子组件事件
const handleChildEvent = (payload) => {
  console.log('Child event:', payload)
}
</script>
```

```vue
<!-- 子组件 -->
<script setup>
// 接收 props
const props = defineProps({
  propData: {
    type: Object,
    required: true
  }
})

// 发射事件
const emit = defineEmits(['child-event'])
const triggerEvent = () => {
  emit('child-event', { data: 'some data' })
}
</script>
```

### 8.2 跨组件通信

```javascript
// 方式 1: Pinia Store
const store = useMyStore()
store.sharedData = 'new value'

// 方式 2: Provide/Inject
// 祖先组件
provide('sharedData', ref('value'))

// 后代组件
const sharedData = inject('sharedData')

// 方式 3: Event Bus (不推荐，Vue 3 已移除)
// 使用第三方库 mitt 或 tiny-emitter
```

---

## 九、页面生命周期

### 9.1 组件生命周期流程

```
用户访问页面 URL
  ↓
路由守卫检查 (beforeEach)
  ↓
组件创建 (setup 函数执行)
  ├── 定义响应式状态
  ├── 定义计算属性
  └── 定义方法
  ↓
组件挂载前 (onBeforeMount)
  ↓
组件挂载 (onMounted)
  ├── DOM 已渲染
  ├── 可以访问 DOM 元素
  └── 【常用】初始化数据、API 请求
  ↓
组件更新 (onUpdated)
  └── 响应式数据变化后触发
  ↓
组件卸载前 (onBeforeUnmount)
  └── 【常用】清理定时器、事件监听
  ↓
组件卸载 (onUnmounted)
```

### 9.2 典型初始化模式

```javascript
<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import BenchmarkApi from '@/api/benchmark'

// 1. 响应式状态
const loading = ref(false)
const tableData = ref([])

// 2. 路由参数
const route = useRoute()
const id = route.query.id

// 3. 初始化数据
const fetchData = async () => {
  loading.value = true
  try {
    const data = await BenchmarkApi.getDetail(id)
    tableData.value = data.list
  } catch (error) {
    ElMessage.error('Failed to load data')
  } finally {
    loading.value = false
  }
}

// 4. 生命周期钩子
onMounted(() => {
  fetchData()
})
</script>
```

---

## 十、核心设计模式

### 10.1 异步数据加载模式

```javascript
// 标准异步加载模式
const loading = ref(false)
const data = ref(null)

const loadData = async () => {
  loading.value = true
  try {
    data.value = await SomeApi.getData()
  } catch (error) {
    ElMessage.error('加载失败')
  } finally {
    loading.value = false
  }
}
```

### 10.2 表单提交模式

```javascript
// 表单提交标准流程
const formRef = ref(null)
const submitting = ref(false)

const submitForm = async () => {
  // 1. 防止重复提交
  if (submitting.value) return

  // 2. 表单验证
  await formRef.value.validate()

  // 3. 确认对话框
  await ElMessageBox.confirm('确认提交?', '提示')

  // 4. 提交数据
  submitting.value = true
  try {
    await SomeApi.submit(formData)
    ElMessage.success('提交成功')
    router.back()  // 返回上一页
  } catch (error) {
    ElMessage.error('提交失败')
  } finally {
    submitting.value = false
  }
}
```

### 10.3 列表查询模式

```javascript
// 分页查询标准模式
const queryParams = reactive({
  pageNo: 1,
  pageSize: 10,
  keyword: ''
})

const tableData = ref([])
const total = ref(0)

const getList = async () => {
  const { list, total: totalCount } = await SomeApi.getPage(queryParams)
  tableData.value = list
  total.value = totalCount
}

// 搜索
const handleQuery = () => {
  queryParams.pageNo = 1
  getList()
}

// 重置
const resetQuery = () => {
  Object.assign(queryParams, {
    pageNo: 1,
    pageSize: 10,
    keyword: ''
  })
  getList()
}

// 分页切换
const handlePageChange = (page) => {
  queryParams.pageNo = page
  getList()
}
```

---

## 十一、关键架构特点

### 11.1 模块化设计

- ✅ **路由模块化**：按业务模块拆分路由配置
- ✅ **API 模块化**：每个业务模块独立的 API 文件
- ✅ **组件模块化**：公共组件提取复用
- ✅ **Store 模块化**：按功能拆分 Pinia Store

### 11.2 权限控制

```
权限控制层次
├── 路由级权限
│   └── 动态路由注册，无权限的路由不加载
│
├── 菜单级权限
│   └── 根据权限过滤菜单显示
│
└── 按钮级权限
    └── v-permission 指令控制按钮显示
```

### 11.3 性能优化

- ✅ **路由懒加载**：按需加载页面组件
- ✅ **组件缓存**：keep-alive 缓存列表页
- ✅ **虚拟滚动**：大列表使用虚拟滚动
- ✅ **请求防抖**：搜索输入防抖处理
- ✅ **图片懒加载**：延迟加载图片资源

### 11.4 错误处理

```
错误处理机制
├── API 层
│   ├── HTTP 错误捕获 (401, 403, 500)
│   └── 业务错误码处理
│
├── 组件层
│   ├── try-catch 包裹异步操作
│   └── ElMessage 显示错误提示
│
└── 全局层
    ├── 全局错误处理器 (app.config.errorHandler)
    └── 路由错误处理 (router.onError)
```

---

## 十二、架构优势与注意事项

### 12.1 架构优势

1. **清晰的分层**：View → API → Backend，职责明确
2. **高度模块化**：业务模块独立，易于维护扩展
3. **组件复用**：公共组件提取，避免重复代码
4. **类型安全**：TypeScript 提供类型检查
5. **性能优化**：懒加载、缓存、防抖等优化手段

### 12.2 开发注意事项

1. **路由命名规范**：使用 kebab-case，与 URL 一致
2. **组件命名规范**：使用 PascalCase
3. **API 错误处理**：统一使用 try-catch 包裹
4. **防止内存泄漏**：在 onBeforeUnmount 中清理定时器、监听器
5. **响应式陷阱**：注意 ref 需要 .value 访问
6. **路由跳转**：优先使用 router.back() 而非硬编码路径

### 12.3 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 路由跳转失败 | 路由不存在 | 检查路由配置，使用 router.back() |
| 数据不更新 | 未使用 ref/reactive | 使用响应式 API 包裹数据 |
| 组件缓存失效 | keep-alive 配置错误 | 检查 meta.noCache 配置 |
| API 请求 401 | Token 过期 | 响应拦截器自动跳转登录 |
| 表单重复提交 | 未加防抖控制 | 使用 loading 状态防止重复点击 |

---

## 十三、总结

这是一个**标准的企业级 Vue 3 项目架构**，具有以下特点：

### 核心架构模式
```
┌────────────────────────────────────────┐
│         Vue 3 SPA 应用                  │
├────────────────────────────────────────┤
│  路由层 (Vue Router)                    │
│  ├─ 静态路由                            │
│  └─ 动态路由 (权限控制)                  │
├────────────────────────────────────────┤
│  视图层 (Views)                         │
│  ├─ 页面组件 (.vue)                     │
│  └─ 公共组件 (Components)               │
├────────────────────────────────────────┤
│  状态层 (Pinia Store)                   │
│  ├─ 用户状态                            │
│  ├─ 权限状态                            │
│  └─ 应用状态                            │
├────────────────────────────────────────┤
│  API 层 (HTTP Request)                 │
│  ├─ 请求拦截器 (Token)                  │
│  ├─ 响应拦截器 (错误处理)                │
│  └─ 接口模块 (按业务划分)                │
├────────────────────────────────────────┤
│  后端服务 (Spring Boot REST API)        │
└────────────────────────────────────────┘
```

### 技术栈总结
- **UI 框架**：Vue 3 (Composition API)
- **UI 组件库**：Element Plus
- **路由**：Vue Router 4
- **状态管理**：Pinia
- **HTTP 客户端**：Axios
- **类型系统**：TypeScript
- **构建工具**：Vite

### 架构评价
- ✅ **结构清晰**：模块化设计，职责分离
- ✅ **可维护性高**：代码组织规范，易于扩展
- ✅ **性能良好**：懒加载、缓存优化
- ✅ **用户体验**：统一的错误处理、加载提示

---

**文档版本**：v1.0
**生成时间**：2025-11-10
**适用范围**：PAP 前端项目 (poc-pro-ui)
