# Benchmark 路由问题分析报告

## 一、问题概述

**现象描述**：
在 benchmark 页面点击 "Private Banking"，修改数据后点击 "Save"，然后在确认对话框中点击 "Confirm" 后，页面路由跳转出现问题，未能正确返回到 benchmark 列表页面。

**核心问题**：
在 `poc-pro-ui/src/views/benchmark/detail/index.vue` 的第 **694 行**，保存成功后试图跳转到 `/business/benchmark` 路由，但该路由在整个路由配置中**并不存在**，导致跳转失败，最终触发 fallback 逻辑跳转到首页 (`/`)。

---

## 二、完整操作流程分析

### 2.1 用户操作流程

```
[Benchmark 列表页]
  → 点击 "Private Banking" 某条记录的名称
  → [判断流程状态]
      ├─ 流程未启动 (response==null) → 进入 Detail 页面 (/benchmark/detail)
      └─ 流程已启动 (response!=null) → 进入 Approval 页面 (/bpm/approval)

[Detail 页面]
  → 修改数据
  → 点击 "Save" 按钮
  → 弹出确认对话框 "Are you sure you want to save the changes?"
  → 点击 "Confirm" 确认
  → 验证数据 (权重总和是否为100%)
  → 调用 API 保存数据
  → 显示成功消息
  → 等待 1 秒
  → ❌ 尝试跳转到 /business/benchmark (路由不存在)
  → ⚠️ 跳转失败，触发 catch 块
  → 🏠 fallback 到首页 (/)
  → 关闭当前标签页
```

---

## 三、关键代码分析

### 3.1 列表页 - 点击名称跳转逻辑

**文件位置**：
- `poc-pro-ui/src/views/benchmark/privateBank/index.vue` (行 118-165)
- `poc-pro-ui/src/views/benchmark/retailBank/index.vue` (行 118-165)

**代码片段**：
```vue
<!-- 行 35-37: 可点击的名称链接 -->
<el-link type="primary" @click="handleViewDetail(scope.row)">
  {{ scope.row.name }}
</el-link>
```

```javascript
// 行 118-165: 点击处理函数
const handleViewDetail = (row) => {
  // 1. 调用 API 检查流程状态
  BenchmarkApi.getProcessKey(row.processInstanceId)
    .then((response) => {
      // 2. 根据流程状态决定跳转目标
      const path = response==null ? '/benchmark/detail' : '/bpm/approval';

      if (path === '/bpm/approval') {
        // 跳转到审批页面
        router.push({
          path,
          query: {
            id: response.processInstanceId,
            taskId: response.taskId,
            activityId: response.activityId,
            businessKey: row.id,
            businessType: 'benchmark',
            name: row.name,
            status: row.status,
            benchmarkType: row.benchmarkType,
            // ... 更多参数
          }
        });
      } else {
        // 跳转到详情页面
        router.push({
          path,
          query: {
            id: row.id,
            name: row.name,
            status: row.status,
            benchmarkType: row.benchmarkType,
            // ... 更多参数
          }
        });
      }
    })
}
```

**判断逻辑**：
- `response == null` → 流程未启动 → 跳转到 `/benchmark/detail`
- `response != null` → 流程已启动 → 跳转到 `/bpm/approval`

---

### 3.2 Detail 页面 - Save 按钮处理

**文件位置**：`poc-pro-ui/src/views/benchmark/detail/index.vue`

#### 3.2.1 Save 按钮定义（行 133-138）

```vue
<el-button
  type="primary"
  @click="submitForm"
  :loading="submitting"
>
  Save
</el-button>
```

#### 3.2.2 提交表单逻辑（行 824-864）

```javascript
const submitForm = async () => {
  if (submitting.value) return

  submitting.value = true
  try {
    // 1. 显示确认对话框
    await ElMessageBox.confirm(
      'Are you sure you want to save the changes?',
      'Save Changes?',
      {
        confirmButtonText: 'Confirm',      // ← 这就是用户点击的 "Confirm" 按钮
        cancelButtonText: 'Cancel',
        type: 'warning'
      }
    )

    await nextTick()

    // 2. 验证权重总和是否为 100%
    if (!validateWeights(Treedata.value)) {
      return
    }

    // 3. 准备并提交数据
    const submitData = prepareSubmitData(Treedata.value)
    await BenchmarkApi.updateBenchmark(submitData)  // API 调用
    ElMessage.success("Save successful")

    // 4. 退出编辑模式并返回
    isEditMode.value = false
    setTimeout(() => {
      goBack()  // ⚠️ 关键：1秒后触发导航
    }, 1000)

  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error("Submit failed, please try again")
    }
  } finally {
    submitting.value = false
  }
}
```

**流程说明**：
1. 用户点击 "Save" → 调用 `submitForm()`
2. 显示确认对话框
3. 用户点击 "Confirm" → `ElMessageBox.confirm()` Promise resolve
4. 验证数据
5. 调用 API 保存
6. 等待 1 秒后调用 `goBack()` 函数

---

### 3.3 返回导航逻辑 - **问题核心所在**

**文件位置**：`poc-pro-ui/src/views/benchmark/detail/index.vue` (行 672-713)

```javascript
const goBack = async () => {
  // 如果在编辑模式，显示确认对话框
  if (isEditMode.value) {
    try {
      await ElMessageBox.confirm(
        'Are you sure you want to leave the edit page?...',
        'Leave Edit',
        { confirmButtonText: 'Confirm', cancelButtonText: 'Cancel', type: 'warning' }
      )
    } catch (error) {
      return  // 用户取消
    }
  }

  // 尝试返回到 benchmark 列表页
  try {
    // ❌ 问题代码：第 694 行
    await router.push('/business/benchmark')  // 这个路由不存在！

    // 关闭当前标签
    await nextTick()
    tagsViewStore.delView(route)

  } catch (error) {
    // ⚠️ Fallback：跳转失败后返回首页
    await router.push('/')
    await nextTick()
    tagsViewStore.delView(route)
    ElMessage.info('Returned to homepage...')
  }
}
```

**问题分析**：
- **第 694 行**：`router.push('/business/benchmark')`
- 该路由在整个路由配置中**不存在**
- 跳转失败后触发 `catch` 块
- 执行 fallback：`router.push('/')` 跳转到首页
- 用户体验：保存成功后被带到首页，而不是 benchmark 列表

---

## 四、路由配置分析

**文件位置**：`poc-pro-ui/src/router/modules/remaining.ts`

### 4.1 Benchmark 相关路由（行 250-272）

```javascript
{
  path: '/benchmark',
  component: Layout,
  name: 'BenchmarkDetail',
  meta: { hidden: true },
  children: [
    {
      path: 'detail',  // ✅ 完整路径: /benchmark/detail
      component: () => import('../../views/benchmark/detail/index.vue'),
      name: 'BenchmarkDetailPage',
      meta: {
        title: 'Benchmark 详情',
        noCache: false,  // 启用缓存
        hidden: true,
        canTo: true,
        icon: 'ep:pie-chart',
        activeMenu: '/benchmark'
      }
    }
  ]
}
```

### 4.2 BPM Approval 路由（行 369-394）

```javascript
{
  path: 'approval',  // ✅ 完整路径: /bpm/approval
  component: () => import('@/views/bpm/approval/index.vue'),
  name: 'BpmApprovalPage',
  meta: {
    title: 'Approval',
    noCache: true,  // 不缓存
    hidden: true,
    canTo: true,
    icon: 'ep:document-checked',
    activeMenu: '/bpm'
  },
  props: (route) => ({ /* 路由参数 */ })
}
```

### 4.3 缺失的路由

在整个路由配置文件中**未找到**以下路由：

```
❌ /business/benchmark          (第 694 行尝试跳转的路由)
⚠️ /benchmark/privateBank        (Private Banking 列表页)
⚠️ /benchmark/retailBank         (Retail Banking 列表页)
```

**注意**：`privateBank` 和 `retailBank` 页面可能通过**动态路由注册**机制加载（基于用户权限），但在静态路由配置中未定义。

---

## 五、路由跳转总览

### 5.1 所有路由跳转代码位置

| 源文件 | 行号 | 跳转目标 | 状态 |
|--------|------|----------|------|
| `privateBank/index.vue` | 126-159 | `/benchmark/detail` 或 `/bpm/approval` | ✅ 正常 |
| `retailBank/index.vue` | 126-159 | `/benchmark/detail` 或 `/bpm/approval` | ✅ 正常 |
| `detail/index.vue` | 694 | `/business/benchmark` | ❌ **不存在** |
| `detail/index.vue` | 704 | `/` (首页 fallback) | ✅ 正常但不符合预期 |

### 5.2 路由流转图

```
┌─────────────────────────────┐
│  Private Banking 列表页      │
│  (动态路由，权限控制)         │
└──────────┬──────────────────┘
           │ 点击名称
           ↓
     ┌─────────────┐
     │ 检查流程状态 │
     └──┬────────┬──┘
        │        │
   null │        │ not null
        ↓        ↓
  ┌──────────┐  ┌──────────┐
  │ Detail   │  │ Approval │
  │ 详情页    │  │ 审批页    │
  └────┬─────┘  └──────────┘
       │
       │ 修改 → Save → Confirm
       ↓
  ┌──────────────────┐
  │ goBack() 函数     │
  └────┬─────────────┘
       │
       │ router.push('/business/benchmark')
       ↓
  ┌──────────┐
  │ ❌ 404   │ 路由不存在
  └────┬─────┘
       │
       │ catch 块
       ↓
  ┌──────────┐
  │ router.  │
  │ push('/') │ Fallback 到首页
  └──────────┘
```

---

## 六、问题影响分析

### 6.1 用户体验影响

- ❌ **预期行为**：保存成功后返回 benchmark 列表页（Private Banking 或 Retail Banking）
- ⚠️ **实际行为**：保存成功后跳转到系统首页
- 💥 **用户困惑**：不知道数据是否保存成功，需要重新导航到 benchmark 模块

### 6.2 数据一致性

- ✅ 数据保存正常（API 调用成功）
- ✅ 业务逻辑无问题
- ❌ 仅路由导航错误

### 6.3 其他潜在问题

1. **缓存配置不一致**：
   - Detail 页面：`noCache: false` (启用缓存)
   - Approval 页面：`noCache: true` (禁用缓存)
   - 可能导致页面状态不同步

2. **动态路由依赖**：
   - Private Banking 和 Retail Banking 列表页未在静态路由中定义
   - 依赖权限系统动态注册路由
   - 可能导致路由路径不确定

---

## 七、修复方案建议

### 方案 1：修正目标路由路径（推荐）

**修改文件**：`poc-pro-ui/src/views/benchmark/detail/index.vue` 第 694 行

**原代码**：
```javascript
await router.push('/business/benchmark')  // ❌ 不存在
```

**修改为**（需确认列表页的实际路由）：

**选项 A**：如果有统一的 benchmark 入口页
```javascript
await router.push('/benchmark')  // 或 '/benchmark/index'
```

**选项 B**：根据来源页面返回
```javascript
// 从 query 参数获取来源类型
const benchmarkType = route.query.benchmarkType
const targetPath = benchmarkType === 1
  ? '/benchmark/privateBank'   // Private Banking
  : '/benchmark/retailBank'     // Retail Banking
await router.push(targetPath)
```

**选项 C**：使用 router.back()
```javascript
router.back()  // 返回上一页
```

---

### 方案 2：使用路由历史记录

**修改代码**：
```javascript
const goBack = async () => {
  if (isEditMode.value) {
    try {
      await ElMessageBox.confirm('Are you sure...', 'Leave Edit', {...})
    } catch (error) {
      return
    }
  }

  // 使用浏览器历史记录返回
  router.back()

  // 延迟关闭标签，确保路由已切换
  setTimeout(() => {
    tagsViewStore.delView(route)
  }, 300)
}
```

**优点**：
- 简单可靠
- 自动返回用户的上一个页面
- 不依赖硬编码的路由路径

**缺点**：
- 如果用户直接访问详情页（如从收藏夹），可能导航到意外页面

---

### 方案 3：在路由配置中注册缺失的路由

**修改文件**：`poc-pro-ui/src/router/modules/remaining.ts`

**添加路由**（需确认实际的列表页组件路径）：
```javascript
{
  path: '/business',
  component: Layout,
  redirect: '/business/benchmark',
  name: 'Business',
  children: [
    {
      path: 'benchmark',
      component: () => import('../../views/benchmark/privateBank/index.vue'), // 或统一的列表页
      name: 'BusinessBenchmark',
      meta: {
        title: 'Benchmark Management',
        icon: 'ep:data-analysis',
        noCache: false
      }
    }
  ]
}
```

**优点**：
- 使路由系统完整
- 符合当前代码的跳转逻辑

**缺点**：
- 需要确认列表页的实际组件位置
- 可能与动态路由系统冲突

---

### 方案 4：动态判断返回路径

**修改代码**：
```javascript
const goBack = async () => {
  if (isEditMode.value) {
    try {
      await ElMessageBox.confirm('Are you sure...', 'Leave Edit', {...})
    } catch (error) {
      return
    }
  }

  // 尝试多个可能的返回路径
  const possiblePaths = [
    '/business/benchmark',
    '/benchmark',
    '/benchmark/privateBank',
    '/benchmark/retailBank'
  ]

  let navigated = false
  for (const path of possiblePaths) {
    try {
      await router.push(path)
      navigated = true
      await nextTick()
      tagsViewStore.delView(route)
      break
    } catch (error) {
      continue  // 尝试下一个路径
    }
  }

  // 如果都失败，使用 router.back()
  if (!navigated) {
    router.back()
    setTimeout(() => {
      tagsViewStore.delView(route)
    }, 300)
  }
}
```

**优点**：
- 容错性强
- 适配多种路由配置情况

**缺点**：
- 代码复杂
- 性能稍差（尝试多次路由跳转）

---

## 八、推荐修复步骤

### Step 1：确认实际的列表页路由

**操作**：
1. 在 Private Banking 列表页，打开浏览器开发者工具
2. 查看当前页面的路由地址（地址栏 URL）
3. 记录完整路径（如 `/benchmark/privateBank` 或 `/business/benchmark/list`）

### Step 2：选择修复方案

**推荐使用「方案 2：router.back()」**，因为：
- ✅ 最简单可靠
- ✅ 不需要硬编码路由路径
- ✅ 自动适配用户来源
- ✅ 最小化代码变动

**如果需要精确控制**，使用「方案 1 选项 B」：
- ✅ 根据 `benchmarkType` 参数返回对应列表页
- ✅ 用户体验最佳
- ⚠️ 需要确认列表页的实际路由路径

### Step 3：修改代码

根据选择的方案修改 `detail/index.vue` 第 672-713 行的 `goBack()` 函数。

### Step 4：测试验证

**测试场景**：
1. ✅ 从 Private Banking 列表进入详情页 → 修改 → Save → Confirm → 应返回 Private Banking 列表
2. ✅ 从 Retail Banking 列表进入详情页 → 修改 → Save → Confirm → 应返回 Retail Banking 列表
3. ✅ 从 Approval 页面进入详情页（如果有此场景）→ 修改 → Save → Confirm → 应返回 Approval 页面
4. ✅ 直接访问详情页（如书签）→ 修改 → Save → Confirm → 返回首页或合理的默认页面

---

## 九、关键代码位置速查表

| 功能 | 文件路径 | 行号 | 说明 |
|------|---------|------|------|
| Private Banking 列表 | `benchmark/privateBank/index.vue` | 全文件 | 列表页主组件 |
| Retail Banking 列表 | `benchmark/retailBank/index.vue` | 全文件 | 列表页主组件 |
| 详情页主组件 | `benchmark/detail/index.vue` | 全文件 | Detail 页主组件 |
| 名称点击处理 | `privateBank/retailBank index.vue` | 118-165 | `handleViewDetail()` |
| Save 按钮 | `detail/index.vue` | 133-138 | 按钮定义 |
| Save 提交逻辑 | `detail/index.vue` | 824-864 | `submitForm()` |
| **返回导航逻辑** | `detail/index.vue` | **672-713** | `goBack()` **问题代码** |
| **错误路由行** | `detail/index.vue` | **694** | `router.push('/business/benchmark')` |
| Fallback 跳转 | `detail/index.vue` | 704 | `router.push('/')` |
| Approval 页面 | `bpm/approval/index.vue` | 全文件 | 审批页组件 |
| Benchmark 路由配置 | `router/modules/remaining.ts` | 250-272 | 路由定义 |
| Approval 路由配置 | `router/modules/remaining.ts` | 369-394 | 路由定义 |
| Benchmark API | `api/benchmark/index.ts` | 全文件 | API 接口定义 |

---

## 十、附录

### A. Private Banking vs Retail Banking 差异

两个页面代码几乎完全相同，唯一区别：

**Private Banking** (第 175 行)：
```javascript
businessType: 1
```

**Retail Banking** (第 174 行)：
```javascript
businessType: 2
```

### B. 相关 API 接口

**文件**：`poc-pro-ui/src/api/benchmark/index.ts`

```typescript
// 获取流程 key
export const getProcessKey = (processInstanceId: string) => {
  return request.get({ url: `/bpm/benchmark/process-key/${processInstanceId}` })
}

// 更新 benchmark
export const updateBenchmark = (data: BenchmarkVO) => {
  return request.put({ url: '/bpm/benchmark/update', data })
}
```

### C. 状态管理

**Tags View Store** (用于管理标签页)：
```javascript
import { useTagsViewStore } from '@/store/modules/tagsView'
const tagsViewStore = useTagsViewStore()

// 关闭当前标签
tagsViewStore.delView(route)
```

---

## 结论

**问题根源**：`detail/index.vue` 第 694 行尝试跳转到不存在的路由 `/business/benchmark`

**影响**：保存成功后用户被导航到首页，而非预期的 benchmark 列表页

**推荐修复**：使用 `router.back()` 替代硬编码的路由路径

**修复工作量**：约 5-10 行代码修改，测试时间约 30 分钟

---

**报告生成时间**：2025-11-10
**分析范围**：`poc-pro-ui/src/views/benchmark/` 及相关路由配置
**问题严重程度**：🟡 中等（影响用户体验，但不影响数据保存）
