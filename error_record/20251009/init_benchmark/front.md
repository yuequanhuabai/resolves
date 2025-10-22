# 前端修改方案（v4.0 - Query-based Approach）

## 一、修改概述

### 核心变化
**后端逻辑变更**：后端不再依赖前端传递的 `isTemplate` 字段来判断是初始化还是非初始化保存，改为通过查询 `benchmark_details` 表来判断。

### 前端影响
- ✅ **保留**：`benchmarkId` 字段（必需）
- ❌ **移除**：`isTemplate` 字段（不再需要）
- ✅ **简化**：前端无需关心初始化逻辑，只需正常提交数据

---

## 二、需要修改的文件

### 文件1：保存数据构建函数（buildSaveData）

**位置**：Vue组件中的数据构建函数

#### 当前代码（v3.0）
```javascript
/**
 * 构建保存数据（v3.0 - 需要传递isTemplate）
 */
const buildSaveData = (nodes, benchmarkId) => {
  return nodes.map(node => {
    const data = {
      id: node.id,
      benchmarkId: benchmarkId,         // ✅ 保留
      weight: node.weight.toString(),
      recordVersion: node.recordVersion || '0',
      isTemplate: node.isTemplate || false,  // ❌ 需要移除
      children: []
    }

    // 递归处理子节点
    if (node.children && node.children.length > 0) {
      data.children = buildSaveData(node.children, benchmarkId)
    }

    return data
  })
}
```

#### 修改后代码（v4.0）
```javascript
/**
 * 构建保存数据（v4.0 - 后端自动判断）
 */
const buildSaveData = (nodes, benchmarkId) => {
  return nodes.map(node => {
    const data = {
      id: node.id,
      benchmarkId: benchmarkId,         // ✅ 必需
      assetClassification: node.assetClassification || node.label,
      weight: node.weight.toString(),
      recordVersion: node.recordVersion || '0',
      // ❌ 移除 isTemplate 字段
      children: []
    }

    // 递归处理子节点
    if (node.children && node.children.length > 0) {
      data.children = buildSaveData(node.children, benchmarkId)
    }

    return data
  })
}
```

**变更说明**：
- 移除 `isTemplate: node.isTemplate || false` 这一行
- 其他保持不变

---

### 文件2：保存方法（handleSave）

**位置**：Vue组件中的保存方法

#### 当前代码（v3.0）
```javascript
/**
 * 保存benchmark数据（v3.0）
 */
const handleSave = async () => {
  try {
    submitting.value = true

    // 1. 验证权重总和
    validateWeights()

    // 2. 获取benchmarkId
    const benchmarkId = route.params.id

    // 3. 构建保存数据
    const saveData = buildSaveData(treeData.value, benchmarkId)

    // 4. 调用保存接口
    await api.updateBenchmark(saveData)

    ElMessage.success('保存成功')

    // 5. 重新加载数据
    await loadBenchmarkData()

  } catch (error) {
    ElMessage.error('保存失败: ' + (error.message || 'Unknown error'))
  } finally {
    submitting.value = false
  }
}
```

#### 修改后代码（v4.0）
```javascript
/**
 * 保存benchmark数据（v4.0 - 无需变更）
 */
const handleSave = async () => {
  try {
    submitting.value = true

    // 1. 验证权重总和
    validateWeights()

    // 2. 获取benchmarkId
    const benchmarkId = route.params.id

    // 3. 构建保存数据（内部已移除isTemplate）
    const saveData = buildSaveData(treeData.value, benchmarkId)

    // 4. 调用保存接口
    await api.updateBenchmark(saveData)

    ElMessage.success('保存成功')

    // 5. 重新加载数据
    await loadBenchmarkData()

  } catch (error) {
    ElMessage.error('保存失败: ' + (error.message || 'Unknown error'))
  } finally {
    submitting.value = false
  }
}
```

**变更说明**：
- 保存方法本身**无需修改**
- 只需确保调用的 `buildSaveData()` 已按上述方式修改

---

### 文件3：数据加载函数（loadBenchmarkData）

**位置**：Vue组件中的数据加载函数

#### 当前代码（v3.0）
```javascript
/**
 * 加载benchmark数据
 */
const loadBenchmarkData = async () => {
  try {
    loading.value = true
    const benchmarkId = route.params.id

    // 调用查询接口
    const response = await api.getBenchmark(benchmarkId)

    // 后端返回的数据中包含 isTemplate 字段
    // isTemplate=true 表示模板数据
    // isTemplate=false 表示已保存的真实数据
    treeData.value = response.data || []

  } catch (error) {
    ElMessage.error('加载数据失败')
  } finally {
    loading.value = false
  }
}
```

#### 修改后代码（v4.0）
```javascript
/**
 * 加载benchmark数据（v4.0 - 无需变更）
 */
const loadBenchmarkData = async () => {
  try {
    loading.value = true
    const benchmarkId = route.params.id

    // 调用查询接口
    const response = await api.getBenchmark(benchmarkId)

    // 后端返回的数据中仍然包含 isTemplate 字段
    // 前端可以继续使用 isTemplate 来区分模板数据和真实数据（用于UI展示）
    // 但保存时不再需要传递此字段给后端
    treeData.value = response.data || []

  } catch (error) {
    ElMessage.error('加载数据失败')
  } finally {
    loading.value = false
  }
}
```

**变更说明**：
- 数据加载函数**无需修改**
- 后端返回的 `BenchmarkDetailsRespVo` 仍然包含 `isTemplate` 字段
- 前端可以继续使用 `isTemplate` 字段做UI展示判断
- 只是保存时不需要传递此字段

---

## 三、TypeScript类型定义（如果使用TS）

### 接口定义修改

#### 当前定义（v3.0）
```typescript
/**
 * Benchmark详情请求VO（v3.0）
 */
interface BenchmarkDetailsReqVo {
  id: string
  benchmarkId: string
  assetClassification?: string
  weight: string
  recordVersion: string
  isTemplate?: boolean  // ❌ 需要移除
  children?: BenchmarkDetailsReqVo[]
}

/**
 * Benchmark详情响应VO（v3.0）
 */
interface BenchmarkDetailsRespVo {
  id: string
  businessId?: string
  assetsClassification: string
  weight: string
  recordVersion: string
  processInstanceId?: string
  assetLevel: number
  isTemplate?: boolean  // ✅ 保留（用于前端展示）
  children?: BenchmarkDetailsRespVo[]
}
```

#### 修改后定义（v4.0）
```typescript
/**
 * Benchmark详情请求VO（v4.0 - 移除isTemplate）
 */
interface BenchmarkDetailsReqVo {
  id: string
  benchmarkId: string                    // ✅ 必需
  assetClassification?: string
  weight: string
  recordVersion: string
  // ❌ 移除 isTemplate 字段
  children?: BenchmarkDetailsReqVo[]
}

/**
 * Benchmark详情响应VO（v4.0 - isTemplate保留）
 */
interface BenchmarkDetailsRespVo {
  id: string
  businessId?: string
  assetsClassification: string
  weight: string
  recordVersion: string
  processInstanceId?: string
  assetLevel: number
  isTemplate?: boolean                   // ✅ 保留（用于前端展示）
  children?: BenchmarkDetailsRespVo[]
}
```

---

## 四、修改清单总结

### 必需修改的地方（仅JS逻辑）
1. ✅ **buildSaveData() 函数** - 移除 `isTemplate` 字段（删除一行代码）

### 无需修改的地方
1. ❌ **handleSave() 方法** - 无需修改
2. ❌ **loadBenchmarkData() 方法** - 无需修改
3. ❌ **Vue模板（template）** - 无需修改
4. ❌ **CSS样式** - 无需修改
5. ❌ **TypeScript响应类型** - 无需修改（RespVo仍包含isTemplate）

### 可选修改的地方
1. **TypeScript请求类型** - 如果使用TS，建议移除 `isTemplate?: boolean`（仅类型定义）

---

## 五、测试验证

### 测试场景1：首次保存（初始化）

**前端操作**：
1. 访问 `/benchmark/detail/{id}`（该benchmark还没有保存过details）
2. 后端返回模板数据（isTemplate=true）
3. 填写权重数据
4. 点击保存

**前端发送数据**：
```json
[
  {
    "id": "uuid-001",
    "benchmarkId": "benchmark-id-123",
    "assetClassification": "Fixed Income",
    "weight": "50.00",
    "recordVersion": "0",
    "children": [...]
  }
]
```

**后端处理**：
- 查询 `benchmark_details` 表，发现为空
- 判断为初始化
- UPDATE benchmark表（recordVersion=0）
- INSERT所有details

**验证点**：
- ✅ 保存成功
- ✅ 刷新页面，数据正确显示
- ✅ isTemplate变为false

---

### 测试场景2：修改保存（非初始化）

**前端操作**：
1. 访问 `/benchmark/detail/{id}`（该benchmark已经保存过details）
2. 后端返回真实数据（isTemplate=false）
3. 修改权重数据
4. 点击保存

**前端发送数据**：
```json
[
  {
    "id": "uuid-v1-001",
    "benchmarkId": "benchmark-id-123",
    "assetClassification": "Fixed Income",
    "weight": "55.00",
    "recordVersion": "1",
    "children": [...]
  }
]
```

**后端处理**：
- 查询 `benchmark_details` 表，发现有数据
- 判断为非初始化
- 标记旧benchmark为deleted + INSERT新benchmark
- INSERT新版本details

**验证点**：
- ✅ 保存成功
- ✅ recordVersion增加（1→2）
- ✅ 旧数据被标记为deleted但仍存在数据库中

---

## 六、风险评估

### 低风险
- ✅ **向后兼容**：即使前端仍然传递isTemplate字段，后端会忽略它
- ✅ **数据安全**：后端通过查询数据库判断，更可靠
- ✅ **修改范围小**：前端只需修改一个函数

### 需要注意
- ⚠️ **benchmarkId必传**：前端必须确保benchmarkId字段存在且正确
- ⚠️ **测试覆盖**：需要测试首次保存和修改保存两种场景

---

## 七、代码对比示例

### 完整的buildSaveData函数对比

#### 修改前（v3.0）
```javascript
const buildSaveData = (nodes, benchmarkId) => {
  return nodes.map(node => {
    const data = {
      id: node.id,
      benchmarkId: benchmarkId,
      assetClassification: node.assetClassification || node.label,
      weight: node.weight.toString(),
      recordVersion: node.recordVersion || '0',
      isTemplate: node.isTemplate || false,  // ❌ 这一行需要删除
      children: []
    }

    if (node.children && node.children.length > 0) {
      data.children = buildSaveData(node.children, benchmarkId)
    }

    return data
  })
}
```

#### 修改后（v4.0）
```javascript
const buildSaveData = (nodes, benchmarkId) => {
  return nodes.map(node => {
    const data = {
      id: node.id,
      benchmarkId: benchmarkId,
      assetClassification: node.assetClassification || node.label,
      weight: node.weight.toString(),
      recordVersion: node.recordVersion || '0',
      // isTemplate 字段已移除
      children: []
    }

    if (node.children && node.children.length > 0) {
      data.children = buildSaveData(node.children, benchmarkId)
    }

    return data
  })
}
```

**差异**：
- 删除 `isTemplate: node.isTemplate || false,` 这一行
- 其他完全相同

---

## 八、FAQ

### Q1：为什么RespVo还保留isTemplate字段？
**A**：RespVo保留isTemplate是为了前端UI展示使用。前端可以根据这个字段来区分是模板数据还是真实数据，从而显示不同的提示信息。但在保存时，前端不需要把这个字段传回给后端。

### Q2：如果前端不小心还是传了isTemplate字段会怎样？
**A**：后端会忽略这个字段。后端现在通过查询 `benchmark_details` 表来判断操作类型，不依赖前端传递的任何标识字段。

### Q3：前端如何获取benchmarkId？
**A**：通常从以下方式获取：
- 路由参数：`route.params.id`
- 查询结果：`response.data.benchmarkId`（如果后端返回）
- 页面状态：`state.currentBenchmarkId`

### Q4：修改后是否需要清除浏览器缓存？
**A**：建议清除缓存后测试，确保使用的是最新的前端代码。

### Q5：是否需要修改API文档？
**A**：是的，需要更新API文档，说明：
- 请求参数不再需要 `isTemplate` 字段
- 响应数据仍包含 `isTemplate` 字段（仅供前端展示使用）

---

## 九、实施步骤建议

1. **第一步**：修改 `buildSaveData()` 函数，移除isTemplate字段
2. **第二步**：如果使用TypeScript，更新请求类型定义
3. **第三步**：在开发环境测试两种场景（首次保存、修改保存）
4. **第四步**：验证数据正确性
5. **第五步**：部署到测试环境
6. **第六步**：通知QA进行完整测试
7. **第七步**：部署到生产环境

---

## 十、回滚方案

如果前端修改后出现问题，可以快速回滚：

### 回滚前端代码
```javascript
// 恢复这一行即可
const data = {
  id: node.id,
  benchmarkId: benchmarkId,
  assetClassification: node.assetClassification || node.label,
  weight: node.weight.toString(),
  recordVersion: node.recordVersion || '0',
  isTemplate: node.isTemplate || false,  // 恢复这一行
  children: []
}
```

### 无需回滚后端
后端新代码向后兼容，即使前端传递isTemplate字段，后端也会忽略它，通过查询数据库来判断。

---

## 总结

✅ **前端修改非常简单**：只需在 `buildSaveData()` 函数中删除一行代码
✅ **向后兼容**：后端会忽略isTemplate字段，不会报错
✅ **测试简单**：两种场景（首次保存、修改保存）都需要测试
✅ **风险可控**：修改范围小，容易回滚

**建议**：在审核通过后，先在开发环境测试，确认无误后再部署生产环境。
