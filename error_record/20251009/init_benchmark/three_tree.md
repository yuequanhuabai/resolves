# Benchmark 动态层级树改造方案（完全替换方案）

> **版本**: v2.1（完全替换版本）
> **日期**: 2025-10-20
> **作者**: Claude Code
> **说明**: 根据实际数据动态展示二级或三级树，不固定层级结构
>
> ⚠️ **重要提示**: 本方案为**完全替换方案**，将彻底替换原有的二级树实现，前后端需要同步修改！

---

## ⚠️ 重要说明

### 方案特点
- ✅ **完全替换**：不保留旧代码，彻底使用新的动态层级实现
- ✅ **不向下兼容**：VO类字段名从 `benchmarkDetailsLevel` 改为 `children`
- ✅ **前后端同步**：前后端必须同时部署，不能单独部署
- ✅ **支持混合层级**：同一棵树中可以有二级和三级分支同时存在
- ✅ **数据库无需迁移**：现有数据完全兼容，无需修改

### 不兼容性说明
| 改动项 | 旧实现 | 新实现 | 影响 |
|--------|--------|--------|------|
| 响应VO字段 | `List<BenchmarkDetailsDo> benchmarkDetailsLevel` | `List<BenchmarkDetailsRespVo> children` | 🔴 API响应格式变化 |
| 请求VO字段 | `List<BenchmarkDetailsDo> benchmarkDetailsLevel` | `List<BenchmarkDetailsReqVo> children` | 🔴 API请求格式变化 |
| 插入逻辑 | 固定两层循环 | 递归插入任意层级 | 🔴 逻辑完全重写 |
| 查询逻辑 | 过滤+关联 | 递归构建 | 🔴 逻辑完全重写 |
| 前端字段名 | `detail.benchmarkDetailsLevel` | `nodeData.children` | 🔴 数据处理逻辑变化 |

---

## 目录
1. [现有二级树实现原理](#1-现有二级树实现原理)
2. [动态层级树设计方案](#2-动态层级树设计方案)
3. [**⚠️ 对原有代码的影响分析**](#3-对原有代码的影响分析)
4. [数据库改动](#4-数据库改动)
5. [后端代码改造](#5-后端代码改造)
6. [前端代码改造](#6-前端代码改造)
7. [实现步骤](#7-实现步骤)
8. [测试方案](#8-测试方案)
9. [常见问题处理](#9-常见问题处理)

---

## 1. 现有二级树实现原理

### 1.1 数据库结构

#### benchmark 主表
```sql
CREATE TABLE `benchmark` (
  `id` varchar(64) NOT NULL COMMENT '主键id',
  `business_id` varchar(64) NOT NULL COMMENT '业务id',
  `name` varchar(64) COMMENT 'benchmark名称',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '状态:0-草稿;1-pending;2-approval通过',
  `business_type` tinyint COMMENT '1-private banking;2-retail banking',
  `benchmark_type` tinyint COMMENT '1:BENCHMARK,2:COMPOSITE',
  `maker` varchar(32) COMMENT '制单人',
  `record_version` int DEFAULT '0' COMMENT '数据版本号',
  PRIMARY KEY (`id`)
) COMMENT='benchmark主表';
```

#### benchmark_details 详情表（核心结构）
```sql
CREATE TABLE `benchmark_details` (
  `id` varchar(64) NOT NULL COMMENT '主键id',
  `business_id` varchar(64) COMMENT '业务ID',
  `benchmark_id` varchar(64) COMMENT 'benchmark表的主键id',
  `parent_id` varchar(64) COMMENT '父节点主键id,根节点则为空',
  `asset_classification` varchar(64) COMMENT '资产分类名称',
  `asset_level` tinyint COMMENT '资产分类级别: 1,2',
  `weight` decimal(20,2) COMMENT '权重',
  `record_version` int DEFAULT '0' COMMENT '数据版本号',
  PRIMARY KEY (`id`)
) COMMENT='benchmark详情表';
```

**关键字段说明:**
- `asset_level`: 资产层级，当前支持 `1`（一级节点）和 `2`（二级节点）
- `parent_id`: 父节点ID，`asset_level=2` 的记录通过此字段关联到 `asset_level=1` 的父节点
- `asset_classification`: 资产分类名称，如 "Fixed Income"、"Developed EUR Government Debt"

**现有数据示例:**
```sql
-- Level 1: Fixed Income (根节点)
INSERT INTO benchmark_details (id, parent_id, asset_classification, asset_level, weight)
VALUES ('42aa-xxx', NULL, 'Fixed Income', 1, 18.00);

-- Level 2: Developed EUR Government Debt (子节点，属于 Fixed Income)
INSERT INTO benchmark_details (id, parent_id, asset_classification, asset_level, weight)
VALUES ('44e8-xxx', '42aa-xxx', 'Developed EUR Government Debt', 2, 3.00);
```

### 1.2 后端实现

#### 1.2.1 数据查询逻辑 (BenchmarkServiceImpl.java:92-118)

**核心方法**: `getBenchmark(String id)`

```java
@Override
public List<BenchmarkDetailsRespVo> getBenchmark(String id) {
    List<BenchmarkDetailsRespVo> result = new ArrayList<>();
    BenchmarkDO benchmarkDO = benchmarkMapper.selectById(id);

    // 1. 查询所有详情数据
    List<BenchmarkDetailsDo> detailsDos = benchmarkDetailsMapper.selectList(id);

    // 2. 过滤出 level=2 的子节点
    List<BenchmarkDetailsDo> childrenDetail = detailsDos.stream()
        .filter(x -> x.getAssetLevel() == 2)
        .toList();

    // 3. 遍历 level=1 的根节点
    detailsDos.forEach(vo -> {
        if (vo.getAssetLevel().equals(1)) {
            BenchmarkDetailsRespVo respVo = new BenchmarkDetailsRespVo();
            respVo.setId(vo.getId());
            respVo.setWeight(String.valueOf(vo.getWeight()));
            respVo.setAssetsClassification(vo.getAssetClassification());
            respVo.setRecordVersion(String.valueOf(vo.getRecordVersion()));
            respVo.setProcessInstanceId(benchmarkDO.getProcessInstanceId());
            result.add(respVo);
        }
    });

    // 4. 为每个根节点关联子节点（通过 parent_id）
    result.forEach(vo -> {
        List<BenchmarkDetailsDo> benchmarkDetailsDo = new ArrayList<>();
        childrenDetail.forEach(children -> {
            if (vo.getId().equals(children.getParentId())) {
                benchmarkDetailsDo.add(children);
            }
        });
        vo.setBenchmarkDetailsLevel(benchmarkDetailsDo);
    });

    return result;
}
```

**实现原理:**
1. 从数据库查询所有 `benchmark_details` 记录
2. 按 `asset_level` 分离一级节点（level=1）和二级节点（level=2）
3. 通过 `parent_id` 将二级节点关联到对应的一级节点
4. 返回嵌套结构：`List<Level1(包含List<Level2>)>`

#### 1.2.2 响应VO类 (BenchmarkDetailsRespVo.java)

```java
@Data
public class BenchmarkDetailsRespVo {
    private String id;
    private String assetsClassification;
    private String weight;
    private String recordVersion;
    private String processInstanceId;

    // 当前存储二级子节点
    List<BenchmarkDetailsDo> benchmarkDetailsLevel;
}
```

**问题**: `benchmarkDetailsLevel` 使用的是 `BenchmarkDetailsDo` 类型，无法支持多级嵌套。

### 1.3 前端实现

#### 1.3.1 数据处理 (detail/index.vue:524-560)

**核心方法**: `processTreeData(detailsList)`

```javascript
const processTreeData = (detailsList) => {
  if (!detailsList || detailsList.length === 0) {
    treeData.value = [];
    return;
  }

  const rootNode = {
    id: 'root',
    label: 'All Assets',
    weight: '100.00',
    children: [],
    isRoot: true,
    level: 0
  };

  // 处理一级节点
  detailsList.forEach(detail => {
    const level1Node = {
      id: detail.id,
      label: detail.assetsClassification,
      weight: detail.weight || '0.00',
      recordVersion: detail.recordVersion,
      children: [],
      level: 1
    };

    // 处理二级节点
    if (detail.benchmarkDetailsLevel && detail.benchmarkDetailsLevel.length > 0) {
      detail.benchmarkDetailsLevel.forEach(level2 => {
        level1Node.children.push({
          id: level2.id,
          label: level2.assetClassification,
          weight: level2.weight ? level2.weight.toString() : '0.00',
          parentId: detail.id,
          level: 2,
          children: []  // 二级节点目前无子节点
        });
      });
    }

    rootNode.children.push(level1Node);
  });

  treeData.value = [rootNode];
};
```

**实现原理:**
1. 创建虚拟根节点 "All Assets"（level=0）
2. 遍历后端返回的数据，构建一级节点（level=1）
3. 为每个一级节点添加二级子节点（level=2）
4. 赋值给 `treeData` 用于 el-tree 渲染

#### 1.3.2 树形展示 (detail/index.vue:98-119)

```vue
<el-tree
  ref="treeRef"
  :data="treeData"
  node-key="id"
  :props="{ children: 'children', label: 'label' }"
  :expand-on-click-node="false"
  default-expand-all
>
  <template #default="{ node, data }">
    <div class="custom-tree-node">
      <span class="node-label">{{ data.label }}</span>

      <!-- 权重编辑：仅在 level=2 时可编辑 -->
      <el-input
        v-if="isEditMode && node.level === 2"
        v-model="data.weight"
        size="small"
        @change="handleWeightChange(data)"
        style="width: 100px"
      />
      <span v-else class="node-weight">{{ data.weight }}%</span>
    </div>
  </template>
</el-tree>
```

**关键点:**
- `node.level === 2` 时允许编辑权重
- 一级节点（level=1）的权重为只读，由子节点权重之和计算得出
- 根节点（level=0）权重固定为 100%

---

## 2. 动态层级树设计方案

### 2.1 核心设计思想

**关键改变**: 不固定树的层级数量，根据数据库中 `asset_level` 的最大值动态构建树形结构。

**设计原则:**
1. **数据驱动**: 根据 `benchmark_details` 表中的 `asset_level` 字段动态判断层级
2. **递归构建**: 使用递归方法构建任意层级的树形结构
3. **叶子节点编辑**: 始终在最后一级（叶子节点）进行权重编辑
4. **向上聚合**: 父节点权重自动计算为所有子节点权重之和

### 2.2 业务场景示例

#### 场景1: 二级树结构
```
Root (100%)
├─ Fixed Income (40%)
│  ├─ Government Debt (25%)
│  └─ Corporate Debt (15%)
└─ Equity (60%)
   ├─ Developed Markets (40%)
   └─ Emerging Markets (20%)
```

#### 场景2: 三级树结构
```
Root (100%)
├─ Fixed Income (40%)
│  ├─ Government Debt (25%)
│  │  ├─ EUR Government (15%)
│  │  └─ Non-EUR Government (10%)
│  └─ Corporate Debt (15%)
│     ├─ EUR Corporate (8%)
│     └─ High Yield (7%)
└─ Equity (60%)
   ├─ Developed Markets (40%)
   │  ├─ Europe (20%)
   │  └─ North America (20%)
   └─ Emerging Markets (20%)
```

### 2.3 技术实现策略

#### 2.3.1 后端策略
1. **递归构建树**: 通过 `buildTreeRecursive()` 方法递归处理所有层级
2. **自动计算父节点权重**: 遍历时累加子节点权重
3. **VO类改造**: 将 `List<BenchmarkDetailsDo>` 改为 `List<BenchmarkDetailsRespVo>` 支持无限嵌套

#### 2.3.2 前端策略
1. **递归渲染**: el-tree 原生支持递归渲染 `children` 属性
2. **动态判断叶子节点**: 通过 `!data.children || data.children.length === 0` 判断
3. **仅叶子节点可编辑**: 在模板中使用 `v-if` 判断是否为叶子节点

---

## 3. ⚠️ 对原有代码的影响分析

### 3.1 影响概述

本方案采用**完全替换**策略，将对现有代码产生以下影响：

| 模块 | 影响文件 | 改动类型 | 影响程度 | 是否需要测试 |
|------|---------|---------|---------|------------|
| 后端VO类 | `BenchmarkDetailsRespVo.java` | 字段名修改 | 🔴 高 | ✅ 是 |
| 后端VO类 | `BenchmarkDetailsReqVo.java` | 字段名修改 | 🔴 高 | ✅ 是 |
| 后端Service | `BenchmarkServiceImpl.java` | 方法重写 | 🔴 高 | ✅ 是 |
| 前端数据处理 | `detail/index.vue` | processTreeData() | 🔴 高 | ✅ 是 |
| 前端保存逻辑 | `detail/index.vue` | saveBenchmark() | 🔴 高 | ✅ 是 |
| 前端模板 | `detail/index.vue` | el-tree 模板 | 🟡 中 | ✅ 是 |
| 数据库 | `benchmark_details` 表 | 无需修改 | 🟢 无 | ❌ 否 |

### 3.2 后端影响详解

#### 3.2.1 VO类字段名变化

**影响位置**: `BenchmarkDetailsRespVo.java` 和 `BenchmarkDetailsReqVo.java`

**原代码**:
```java
@Data
public class BenchmarkDetailsRespVo {
    private String id;
    private String assetsClassification;
    private String weight;
    private String recordVersion;
    private String processInstanceId;

    // ⚠️ 旧字段名
    List<BenchmarkDetailsDo> benchmarkDetailsLevel;
}
```

**新代码**:
```java
@Data
public class BenchmarkDetailsRespVo {
    private String id;
    private String assetsClassification;
    private String weight;
    private String recordVersion;
    private String processInstanceId;
    private Integer assetLevel;  // 新增

    // ✅ 新字段名，支持递归嵌套
    private List<BenchmarkDetailsRespVo> children;
}
```

**影响说明**:
- 🔴 API响应格式发生变化，前端必须同步修改
- 🔴 字段类型从 `List<BenchmarkDetailsDo>` 改为 `List<BenchmarkDetailsRespVo>`，支持无限嵌套
- 🔴 所有使用 `getBenchmarkDetailsLevel()` 的代码需要改为 `getChildren()`

#### 3.2.2 查询逻辑完全重写

**影响位置**: `BenchmarkServiceImpl.java` - `getBenchmark()` 方法 (line 92-118)

**原代码逻辑**:
```java
// 1. 查询所有数据
List<BenchmarkDetailsDo> detailsDos = benchmarkDetailsMapper.selectList(id);

// 2. 过滤 level=2 的节点
List<BenchmarkDetailsDo> childrenDetail = detailsDos.stream()
    .filter(x -> x.getAssetLevel() == 2)
    .toList();

// 3. 遍历 level=1，手动关联 level=2
detailsDos.forEach(vo -> {
    if (vo.getAssetLevel().equals(1)) {
        // ... 构建一级节点
        childrenDetail.forEach(children -> {
            if (vo.getId().equals(children.getParentId())) {
                // ... 添加子节点
            }
        });
    }
});
```

**新代码逻辑**:
```java
// 1. 查询所有数据
List<BenchmarkDetailsDo> detailsDos = benchmarkDetailsMapper.selectList(id);

// 2. 动态构建树（递归）
return buildDynamicTree(detailsDos, benchmarkDO);

// buildDynamicTree 内部使用 Map 和递归构建任意层级
```

**影响说明**:
- 🔴 逻辑完全重写，不再使用过滤+双重循环
- 🔴 使用递归方法构建树，支持任意层级
- ✅ 性能优化：使用 Map 预处理父子关系，避免 O(n²) 复杂度

#### 3.2.3 插入逻辑完全重写

**影响位置**: `BenchmarkServiceImpl.java` - `insertBenchmarkDetails()` 方法 (line 267-284)

**原代码逻辑**:
```java
private void insertBenchmarkDetails(List<BenchmarkDetailsReqVo> updateReqVO, BenchmarkDO newBenchmark) {
    updateReqVO.forEach(reqVO -> {
        // 1. 插入一级节点
        BenchmarkDetailsDo rootDetail = createRootDetail(reqVO, newBenchmark);
        insertDetails.add(rootDetail);

        // 2. 插入二级节点
        List<BenchmarkDetailsDo> childDetails = reqVO.getBenchmarkDetailsLevel();
        childDetails.forEach(childDetail -> {
            BenchmarkDetailsDo detail = createChildDetail(childDetail, newBenchmark, rootDetail.getId());
            insertDetails.add(detail);
        });
        // ⚠️ 没有处理三级及以上，无法支持多层级
    });
}
```

**新代码逻辑**:
```java
private void insertBenchmarkDetailsRecursive(
        List<BenchmarkDetailsReqVo> reqVos,
        BenchmarkDO newBenchmark,
        String parentId,
        int currentLevel) {

    for (BenchmarkDetailsReqVo reqVo : reqVos) {
        // 1. 创建当前层级节点
        BenchmarkDetailsDo detail = new BenchmarkDetailsDo();
        detail.setAssetLevel(currentLevel);
        detail.setParentId(parentId);
        // ...

        // 2. 递归处理子节点
        if (reqVo.getChildren() != null && !reqVo.getChildren().isEmpty()) {
            insertBenchmarkDetailsRecursive(
                reqVo.getChildren(),
                newBenchmark,
                detail.getId(),  // 当前节点ID作为子节点的parent_id
                currentLevel + 1  // 层级+1
            );
        }
    }
}
```

**影响说明**:
- 🔴 方法签名完全改变，增加了 `parentId` 和 `currentLevel` 参数
- 🔴 使用递归逻辑，支持任意层级数据插入
- 🔴 需要修改 `updateBenchmark()` 方法中的调用

#### 3.2.4 删除的方法

以下方法将被**删除**，不再使用：

```java
// ❌ 删除
private BenchmarkDetailsDo createRootDetail(BenchmarkDetailsReqVo reqVO, BenchmarkDO newBenchmark)

// ❌ 删除
private BenchmarkDetailsDo createChildDetail(BenchmarkDetailsDo newDetails, BenchmarkDO newBenchmark, String parentId)

// ❌ 删除
private void insertBenchmarkDetails(List<BenchmarkDetailsReqVo> updateReqVO, BenchmarkDO newBenchmark)
```

#### 3.2.5 新增的方法

```java
// ✅ 新增：动态构建树的入口方法
private List<BenchmarkDetailsRespVo> buildDynamicTree(
    List<BenchmarkDetailsDo> detailsDos,
    BenchmarkDO benchmarkDO)

// ✅ 新增：递归构建每个节点
private BenchmarkDetailsRespVo buildNodeRecursive(
    BenchmarkDetailsDo currentNode,
    Map<String, List<BenchmarkDetailsDo>> parentChildMap,
    BenchmarkDO benchmarkDO)

// ✅ 新增：递归插入详情数据
private void insertBenchmarkDetailsRecursive(
    List<BenchmarkDetailsReqVo> reqVos,
    BenchmarkDO newBenchmark,
    String parentId,
    int currentLevel)

// ✅ 新增：空数据时返回默认模板
private List<BenchmarkDetailsRespVo> getDefaultTemplateData(BenchmarkDO benchmarkDO)

// ✅ 新增：创建默认节点辅助方法
private BenchmarkDetailsRespVo createDefaultNode(
    String id, String classification, String weight,
    Integer level, BenchmarkDO benchmarkDO)

// ✅ 新增：验证一级节点权重总和
private void validateRootWeights(List<BenchmarkDetailsReqVo> updateReqVO)
```

### 3.3 前端影响详解

#### 3.3.1 数据处理逻辑变化

**影响位置**: `detail/index.vue` - `processTreeData()` 方法 (约 line 524-560)

**原代码**:
```javascript
const processTreeData = (detailsList) => {
  detailsList.forEach(detail => {
    const level1Node = { /* ... */ };

    // ⚠️ 使用旧字段名
    if (detail.benchmarkDetailsLevel && detail.benchmarkDetailsLevel.length > 0) {
      detail.benchmarkDetailsLevel.forEach(level2 => {
        level1Node.children.push({
          // ... 二级节点
          children: []  // 二级节点无子节点
        });
      });
    }
  });
};
```

**新代码**:
```javascript
const processTreeData = (detailsList) => {
  // 递归处理节点
  const buildNode = (nodeData, parentLevel) => {
    const node = { /* ... */ };

    // ✅ 使用新字段名，支持递归
    if (nodeData.children && nodeData.children.length > 0) {
      node.children = nodeData.children.map(child =>
        buildNode(child, parentLevel + 1)  // 递归调用
      );
    }

    return node;
  };

  // 处理所有一级节点
  detailsList.forEach(detail => {
    const level1Node = buildNode(detail, 0);
    rootNode.children.push(level1Node);
  });
};
```

**影响说明**:
- 🔴 字段名从 `benchmarkDetailsLevel` 改为 `children`
- 🔴 使用递归方法处理，支持任意层级
- 🔴 权重计算逻辑改为递归向上聚合

#### 3.3.2 编辑权限判断变化

**影响位置**: `detail/index.vue` - el-tree 模板 (约 line 98-119)

**原代码**:
```vue
<el-input
  v-if="isEditMode && node.level === 2"
  v-model="data.weight"
/>
```

**新代码**:
```vue
<el-input
  v-if="isEditMode && (!data.children || data.children.length === 0)"
  v-model="data.weight"
/>
```

**影响说明**:
- 🔴 判断条件从固定层级 `node.level === 2` 改为动态判断叶子节点
- ✅ 支持不同分支有不同深度
- ✅ 自动适配二级、三级或混合层级

#### 3.3.3 保存数据格式变化

**影响位置**: `detail/index.vue` - `saveBenchmark()` 方法

**原代码**:
```javascript
// 构建请求数据（只支持两层）
const requestData = root.children.map(level1 => ({
  id: level1.id,
  assetClassification: level1.label,
  weight: level1.weight,
  benchmarkDetailsLevel: level1.children.map(level2 => ({
    // ... 二级节点
    // ⚠️ 没有处理三级
  }))
}));
```

**新代码**:
```javascript
// 递归转换数据格式
const formatNodeData = (node) => {
  const data = {
    id: node.id,
    assetClassification: node.label,
    weight: node.weight
  };

  // ✅ 递归处理子节点
  if (node.children && node.children.length > 0) {
    data.children = node.children.map(child => formatNodeData(child));
  }

  return data;
};

const requestData = root.children.map(child => formatNodeData(child));
```

**影响说明**:
- 🔴 字段名从 `benchmarkDetailsLevel` 改为 `children`
- 🔴 使用递归方法构建请求数据
- ✅ 支持任意层级数据保存

### 3.4 API 接口变化

#### 查询接口响应格式变化

**接口**: `GET /api/benchmark/detail?id={benchmarkId}`

**原响应格式**:
```json
[
  {
    "id": "level1-001",
    "assetsClassification": "Fixed Income",
    "weight": "40.00",
    "recordVersion": "1",
    "benchmarkDetailsLevel": [
      {
        "id": "level2-001",
        "assetClassification": "Government Debt",
        "weight": "25.00"
      }
    ]
  }
]
```

**新响应格式**:
```json
[
  {
    "id": "level1-001",
    "assetsClassification": "Fixed Income",
    "weight": "40.00",
    "recordVersion": "1",
    "assetLevel": 1,
    "children": [
      {
        "id": "level2-001",
        "assetsClassification": "Corporate Debt",
        "weight": "15.00",
        "assetLevel": 2,
        "children": [
          {
            "id": "level3-001",
            "assetsClassification": "EUR Corporate",
            "weight": "8.00",
            "assetLevel": 3,
            "children": []
          }
        ]
      }
    ]
  }
]
```

**变化说明**:
- 🔴 字段名: `benchmarkDetailsLevel` → `children`
- 🔴 字段类型: `List<BenchmarkDetailsDo>` → `List<BenchmarkDetailsRespVo>`
- ✅ 新增: `assetLevel` 字段
- ✅ 支持: 递归嵌套，任意层级

#### 保存接口请求格式变化

**接口**: `POST /api/benchmark/update`

**原请求格式**:
```json
[
  {
    "id": "level1-001",
    "assetClassification": "Fixed Income",
    "weight": "40.00",
    "recordVersion": "1",
    "benchmarkDetailsLevel": [
      {
        "id": "level2-001",
        "assetClassification": "Government Debt",
        "weight": "25.00"
      }
    ]
  }
]
```

**新请求格式**:
```json
[
  {
    "id": "level1-001",
    "assetClassification": "Fixed Income",
    "weight": "40.00",
    "recordVersion": "1",
    "children": [
      {
        "id": "level2-001",
        "assetClassification": "Corporate Debt",
        "weight": "15.00",
        "children": [
          {
            "id": "level3-001",
            "assetClassification": "EUR Corporate",
            "weight": "8.00",
            "children": []
          }
        ]
      }
    ]
  }
]
```

**变化说明**:
- 🔴 字段名: `benchmarkDetailsLevel` → `children`
- ✅ 支持递归嵌套，任意层级

### 3.5 数据库影响

**好消息**: 数据库**无需任何迁移**！

| 表 | 是否需要修改 | 说明 |
|----|------------|------|
| `benchmark` | ❌ 否 | 无需修改 |
| `benchmark_details` | 🟡 可选 | 仅建议更新字段注释 |

**可选的数据库改动**:
```sql
-- 仅更新注释，说明支持多级
ALTER TABLE `benchmark_details`
MODIFY COLUMN `asset_level` tinyint COMMENT '资产分类级别: 1,2,3,...（支持多级）';
```

**现有数据兼容性**:
- ✅ 现有二级树数据完全兼容，无需修改
- ✅ 可以直接添加三级数据，系统自动识别
- ✅ 新旧数据可以并存

### 3.6 影响总结

#### 必须修改的文件

| 文件路径 | 修改内容 | 行数变化 | 难度 |
|---------|---------|---------|------|
| `BenchmarkDetailsRespVo.java` | 字段名修改+新增字段 | +3 -1 | 🟢 简单 |
| `BenchmarkDetailsReqVo.java` | 字段名修改 | +1 -1 | 🟢 简单 |
| `BenchmarkServiceImpl.java` | 新增6个方法，删除3个方法 | +200 -50 | 🔴 复杂 |
| `detail/index.vue` | 修改5个方法+模板 | +100 -80 | 🟡 中等 |

#### 不需要修改的文件

| 文件 | 原因 |
|------|------|
| `BenchmarkDO.java` | 主表实体类无需修改 |
| `BenchmarkDetailsDo.java` | 详情表实体类无需修改 |
| `BenchmarkMapper.java` | Mapper接口无需修改 |
| `BenchmarkDetailsMapper.java` | Mapper接口无需修改 |
| 数据库表结构 | 完全兼容，无需修改 |

#### 风险评估

| 风险项 | 风险等级 | 风险描述 | 缓解措施 |
|--------|---------|---------|---------|
| API不兼容 | 🔴 高 | 前后端API格式变化 | 前后端必须同时部署 |
| 数据丢失 | 🟢 低 | 数据库无需修改 | 无风险 |
| 功能回归 | 🟡 中 | 逻辑完全重写 | 充分测试二级树功能 |
| 性能下降 | 🟢 低 | 递归可能有性能影响 | 使用Map优化，添加深度限制 |
| 并发冲突 | 🟢 低 | 事务逻辑未变 | 无额外风险 |

#### 部署要求

⚠️ **关键要求**: 前后端**必须同时部署**，不能单独部署！

**部署顺序**:
1. ✅ 先部署后端（包含新的API响应格式）
2. ✅ 立即部署前端（包含新的字段名处理）
3. ❌ 不能只部署后端或只部署前端

**回滚方案**:
- 如果出现问题，前后端同时回滚到旧版本
- 数据库无需回滚（因为未修改）

---

## 4. 数据库改动

### 4.1 表结构调整

**benchmark_details 表改动（最小化改动）**

```sql
-- 修改 asset_level 字段注释，支持更多层级
ALTER TABLE `benchmark_details`
MODIFY COLUMN `asset_level` tinyint COMMENT '资产分类级别: 1,2,3,...（支持多级）';
```

**说明:**
- 无需修改字段类型（tinyint 可支持 1-255）
- 仅更新注释说明支持多级结构
- 现有二级数据无需迁移，完全兼容

### 4.2 数据示例

#### 4.2.1 二级数据示例（现有数据兼容）
```sql
-- Level 1
INSERT INTO benchmark_details (id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES ('level1-001', 'benchmark-001', NULL, 'Fixed Income', 1, 40.00, 1);

-- Level 2 (parent_id 指向 level1-001)
INSERT INTO benchmark_details (id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES ('level2-001', 'benchmark-001', 'level1-001', 'Government Debt', 2, 25.00, 1);
```

#### 3.2.2 三级数据示例（新增支持）
```sql
-- Level 1
INSERT INTO benchmark_details (id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES ('level1-001', 'benchmark-001', NULL, 'Fixed Income', 1, 40.00, 1);

-- Level 2
INSERT INTO benchmark_details (id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES ('level2-001', 'benchmark-001', 'level1-001', 'Government Debt', 2, 25.00, 1);

-- Level 3 (parent_id 指向 level2-001)
INSERT INTO benchmark_details (id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES ('level3-001', 'benchmark-001', 'level2-001', 'EUR Government', 3, 15.00, 1);

INSERT INTO benchmark_details (id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES ('level3-002', 'benchmark-001', 'level2-001', 'Non-EUR Government', 3, 10.00, 1);
```

**数据关系:**
```
Fixed Income (level1-001, level=1, weight=40.00)
  └─ Government Debt (level2-001, level=2, parent_id=level1-001, weight=25.00)
      ├─ EUR Government (level3-001, level=3, parent_id=level2-001, weight=15.00)
      └─ Non-EUR Government (level3-002, level=3, parent_id=level2-001, weight=10.00)
```

---

## 5. 后端代码改造

### 5.1 修改 BenchmarkDetailsRespVo.java

**位置**: `pocpro/pap-server/src/main/java/cn/bochk/pap/server/business/vo/resp/BenchmarkDetailsRespVo.java`

**改动说明**: 将子节点类型从 `List<BenchmarkDetailsDo>` 改为 `List<BenchmarkDetailsRespVo>` 以支持递归嵌套。

```java
package cn.bochk.pap.server.business.vo.resp;

import lombok.Data;
import java.util.List;

@Data
public class BenchmarkDetailsRespVo {
    private String id;
    private String assetsClassification;
    private String weight;
    private String recordVersion;
    private String processInstanceId;
    private Integer assetLevel;  // 新增：记录层级信息（可选）

    /**
     * 子节点列表（支持递归嵌套）
     * 原字段名: benchmarkDetailsLevel (List<BenchmarkDetailsDo>)
     * 新字段名: children (List<BenchmarkDetailsRespVo>)
     */
    private List<BenchmarkDetailsRespVo> children;
}
```

**关键改动:**
- `List<BenchmarkDetailsDo> benchmarkDetailsLevel` → `List<BenchmarkDetailsRespVo> children`
- 新增 `assetLevel` 字段（可选，便于前端判断层级）

### 4.2 修改 BenchmarkServiceImpl.java

**位置**: `pocpro/pap-server/src/main/java/cn/bochk/pap/server/business/service/Impl/BenchmarkServiceImpl.java`

#### 4.2.1 修改 getBenchmark() 方法

```java
@Override
public List<BenchmarkDetailsRespVo> getBenchmark(String id) {
    BenchmarkDO benchmarkDO = benchmarkMapper.selectById(id);
    List<BenchmarkDetailsDo> detailsDos = benchmarkDetailsMapper.selectList(id);

    // 如果没有数据，返回默认模板
    if (detailsDos == null || detailsDos.isEmpty()) {
        return getDefaultTemplateData(benchmarkDO);
    }

    // 动态构建树形结构
    return buildDynamicTree(detailsDos, benchmarkDO);
}
```

#### 4.2.2 新增 buildDynamicTree() 方法（核心逻辑）

```java
/**
 * 动态构建树形结构（根据数据层级自动适配）
 *
 * @param detailsDos 所有详情数据
 * @param benchmarkDO benchmark主表数据
 * @return 树形结构列表（根节点列表）
 */
private List<BenchmarkDetailsRespVo> buildDynamicTree(
        List<BenchmarkDetailsDo> detailsDos,
        BenchmarkDO benchmarkDO) {

    List<BenchmarkDetailsRespVo> result = new ArrayList<>();

    // 1. 按 parent_id 分组（Map<parent_id, List<子节点>>）
    Map<String, List<BenchmarkDetailsDo>> parentChildMap = detailsDos.stream()
        .filter(d -> d.getParentId() != null)  // 排除根节点
        .collect(Collectors.groupingBy(BenchmarkDetailsDo::getParentId));

    // 2. 找出所有根节点（parent_id == null）
    List<BenchmarkDetailsDo> rootNodes = detailsDos.stream()
        .filter(d -> d.getParentId() == null)
        .sorted(Comparator.comparing(BenchmarkDetailsDo::getAssetLevel))
        .collect(Collectors.toList());

    // 3. 递归构建每个根节点及其子树
    for (BenchmarkDetailsDo rootNode : rootNodes) {
        BenchmarkDetailsRespVo rootVo = buildNodeRecursive(rootNode, parentChildMap, benchmarkDO);
        result.add(rootVo);
    }

    return result;
}
```

#### 4.2.3 新增 buildNodeRecursive() 递归方法

```java
/**
 * 递归构建节点及其所有子节点
 *
 * @param currentNode 当前节点
 * @param parentChildMap 父子关系映射
 * @param benchmarkDO benchmark主表数据
 * @return 构建完成的响应VO
 */
private BenchmarkDetailsRespVo buildNodeRecursive(
        BenchmarkDetailsDo currentNode,
        Map<String, List<BenchmarkDetailsDo>> parentChildMap,
        BenchmarkDO benchmarkDO) {

    // 1. 构建当前节点
    BenchmarkDetailsRespVo nodeVo = new BenchmarkDetailsRespVo();
    nodeVo.setId(currentNode.getId());
    nodeVo.setAssetsClassification(currentNode.getAssetClassification());
    nodeVo.setWeight(currentNode.getWeight() != null ?
        currentNode.getWeight().toString() : "0.00");
    nodeVo.setRecordVersion(String.valueOf(currentNode.getRecordVersion()));
    nodeVo.setProcessInstanceId(benchmarkDO.getProcessInstanceId());
    nodeVo.setAssetLevel(currentNode.getAssetLevel());

    // 2. 查找当前节点的子节点
    List<BenchmarkDetailsDo> childNodes = parentChildMap.get(currentNode.getId());

    if (childNodes != null && !childNodes.isEmpty()) {
        // 3. 递归构建所有子节点
        List<BenchmarkDetailsRespVo> childVos = new ArrayList<>();

        for (BenchmarkDetailsDo childNode : childNodes) {
            BenchmarkDetailsRespVo childVo = buildNodeRecursive(
                childNode, parentChildMap, benchmarkDO);
            childVos.add(childVo);
        }

        nodeVo.setChildren(childVos);

        // 4. 计算父节点权重（所有子节点权重之和）
        BigDecimal totalWeight = childVos.stream()
            .map(child -> new BigDecimal(child.getWeight()))
            .reduce(BigDecimal.ZERO, BigDecimal::add);
        nodeVo.setWeight(totalWeight.setScale(2, RoundingMode.HALF_UP).toString());
    }

    return nodeVo;
}
```

#### 4.2.4 新增 getDefaultTemplateData() 方法

```java
/**
 * 获取默认模板数据（首次加载无数据时使用）
 * 注意：这里返回的是二级结构模板，如果需要三级，可根据业务需求调整
 */
private List<BenchmarkDetailsRespVo> getDefaultTemplateData(BenchmarkDO benchmarkDO) {
    List<BenchmarkDetailsRespVo> result = new ArrayList<>();

    // 创建默认的二级树模板
    // Level 1: Fixed Income
    BenchmarkDetailsRespVo fixedIncome = createDefaultNode(
        "default-fixed-income", "Fixed Income", "0.00", 1, benchmarkDO);
    fixedIncome.setChildren(Arrays.asList(
        createDefaultNode("default-gov-debt", "Government Debt", "0.00", 2, benchmarkDO),
        createDefaultNode("default-corp-debt", "Corporate Debt", "0.00", 2, benchmarkDO)
    ));

    // Level 1: Equity
    BenchmarkDetailsRespVo equity = createDefaultNode(
        "default-equity", "Equity", "0.00", 1, benchmarkDO);
    equity.setChildren(Arrays.asList(
        createDefaultNode("default-developed", "Developed Markets", "0.00", 2, benchmarkDO),
        createDefaultNode("default-emerging", "Emerging Markets", "0.00", 2, benchmarkDO)
    ));

    // Level 1: Alternatives
    BenchmarkDetailsRespVo alternatives = createDefaultNode(
        "default-alternatives", "Alternatives", "0.00", 1, benchmarkDO);
    alternatives.setChildren(Arrays.asList(
        createDefaultNode("default-hedge-funds", "Hedge Funds", "0.00", 2, benchmarkDO),
        createDefaultNode("default-real-estate", "Real Estate", "0.00", 2, benchmarkDO)
    ));

    result.add(fixedIncome);
    result.add(equity);
    result.add(alternatives);

    return result;
}

/**
 * 创建默认节点辅助方法
 */
private BenchmarkDetailsRespVo createDefaultNode(
        String id, String classification, String weight,
        Integer level, BenchmarkDO benchmarkDO) {
    BenchmarkDetailsRespVo node = new BenchmarkDetailsRespVo();
    node.setId(id);
    node.setAssetsClassification(classification);
    node.setWeight(weight);
    node.setAssetLevel(level);
    node.setRecordVersion("0");
    node.setProcessInstanceId(benchmarkDO != null ?
        benchmarkDO.getProcessInstanceId() : null);
    return node;
}
```

#### 4.2.5 修改 updateBenchmark() 方法（处理动态层级保存）

```java
@Override
@Transactional(rollbackFor = Exception.class)
public void updateBenchmark(List<BenchmarkDetailsReqVo> updateReqVO) {
    if (updateReqVO == null || CollUtil.isEmpty(updateReqVO)) {
        throw new ServerException(400, "updateRequestion is null");
    }

    try {
        // 1. 校验权重总和（仅校验一级节点）
        validateRootWeights(updateReqVO);

        // 2. 获取原有数据
        BenchmarkDetailsDo benchmarkDetailsDo = benchmarkDetailsMapper
            .selectById(updateReqVO.get(0).getId());
        BenchmarkDO benchmarkDO = benchmarkMapper
            .selectById(benchmarkDetailsDo.getBenchmarkId());

        // 3. 验证版本号
        validateRecordVersion(updateReqVO.get(0), benchmarkDO);

        // 4. 更新主表数据
        BenchmarkDO newBenchmark = updateMainBenchmark(benchmarkDO);

        // 5. 递归插入详情数据（支持多级）
        insertBenchmarkDetailsRecursive(updateReqVO, newBenchmark, null, 1);

        // 6. 发起 BPM 流程
        Map<String, Object> processInstanceVariables = new HashMap<>();
        startProcess(String.valueOf(newBenchmark.getId()), processInstanceVariables);

        // 7. 推送消息至消息通知
        sendNotification();

    } catch (Exception e) {
        log.error("更新Benchmark异常: ", e);
        throw new ServerException(500, "更新Benchmark失败: " + e.getMessage());
    }
}

/**
 * 递归插入详情数据（支持任意层级）
 */
private void insertBenchmarkDetailsRecursive(
        List<BenchmarkDetailsReqVo> reqVos,
        BenchmarkDO newBenchmark,
        String parentId,
        int currentLevel) {

    List<BenchmarkDetailsDo> insertDetails = new ArrayList<>();

    for (BenchmarkDetailsReqVo reqVo : reqVos) {
        // 创建当前层级节点
        BenchmarkDetailsDo detail = new BenchmarkDetailsDo();
        detail.setId(IdUtils.getUUID());
        detail.setBusinessId(newBenchmark.getBusinessId());
        detail.setBenchmarkId(newBenchmark.getId());
        detail.setParentId(parentId);
        detail.setAssetClassification(reqVo.getAssetClassification());
        detail.setAssetLevel(currentLevel);
        detail.setWeight(new BigDecimal(reqVo.getWeight()));
        detail.setRecordVersion(newBenchmark.getRecordVersion());

        insertDetails.add(detail);

        // 递归处理子节点
        if (reqVo.getChildren() != null && !reqVo.getChildren().isEmpty()) {
            insertBenchmarkDetailsRecursive(
                reqVo.getChildren(),
                newBenchmark,
                detail.getId(),  // 当前节点ID作为子节点的parent_id
                currentLevel + 1  // 层级+1
            );
        }
    }

    // 批量插入当前层级的所有节点
    if (!insertDetails.isEmpty()) {
        benchmarkDetailsMapper.insertBatch(insertDetails);
    }
}

/**
 * 验证一级节点权重总和
 */
private void validateRootWeights(List<BenchmarkDetailsReqVo> updateReqVO) {
    double totalWeight = updateReqVO.stream()
        .filter(vo -> vo.getWeight() != null && !vo.getWeight().isEmpty())
        .mapToDouble(vo -> new BigDecimal(vo.getWeight())
            .setScale(2, RoundingMode.HALF_UP)
            .doubleValue())
        .sum();

    if (Math.abs(totalWeight - 100.0) > 0.01) {  // 允许0.01的误差
        throw new ServerException(400, "一级节点权重总和不等于100，请调整为100");
    }
}
```

### 4.3 修改 BenchmarkDetailsReqVo.java（请求VO）

**位置**: `pocpro/pap-server/src/main/java/cn/bochk/pap/server/business/vo/req/BenchmarkDetailsReqVo.java`

```java
package cn.bochk.pap.server.business.vo.req;

import lombok.Data;
import java.util.List;

@Data
public class BenchmarkDetailsReqVo {
    private String id;
    private String assetClassification;
    private String weight;
    private String recordVersion;

    /**
     * 子节点列表（支持递归嵌套）
     */
    private List<BenchmarkDetailsReqVo> children;
}
```

### 4.4 需要引入的依赖

```java
import java.util.stream.Collectors;
import java.util.Comparator;
import java.util.Arrays;
import java.math.RoundingMode;
```

---

## 5. 前端代码改造

### 5.1 修改 detail/index.vue

**位置**: `poc-pro-ui/src/views/benchmark/detail/index.vue`

#### 5.1.1 修改 processTreeData() 方法

**原方法位置**: 约 line 524-560

**新方法**:
```javascript
/**
 * 处理树形数据（动态层级版本）
 * 根据后端返回的数据自动构建任意层级的树
 */
const processTreeData = (detailsList) => {
  if (!detailsList || detailsList.length === 0) {
    treeData.value = [];
    return;
  }

  // 创建虚拟根节点
  const rootNode = {
    id: 'root',
    label: 'All Assets',
    weight: '100.00',
    children: [],
    isRoot: true,
    level: 0
  };

  // 递归处理节点
  const buildNode = (nodeData, parentLevel) => {
    const node = {
      id: nodeData.id,
      label: nodeData.assetsClassification,
      weight: nodeData.weight || '0.00',
      recordVersion: nodeData.recordVersion,
      assetLevel: nodeData.assetLevel,
      level: parentLevel + 1,
      children: []
    };

    // 递归处理子节点
    if (nodeData.children && nodeData.children.length > 0) {
      node.children = nodeData.children.map(child =>
        buildNode(child, parentLevel + 1)
      );

      // 计算父节点权重（子节点权重之和）
      const totalWeight = node.children.reduce((sum, child) => {
        return sum + parseFloat(child.weight || 0);
      }, 0);
      node.weight = totalWeight.toFixed(2);
    }

    return node;
  };

  // 处理所有一级节点
  detailsList.forEach(detail => {
    const level1Node = buildNode(detail, 0);
    rootNode.children.push(level1Node);
  });

  // 计算根节点权重
  const totalRootWeight = rootNode.children.reduce((sum, child) => {
    return sum + parseFloat(child.weight || 0);
  }, 0);
  rootNode.weight = totalRootWeight.toFixed(2);

  treeData.value = [rootNode];
};
```

#### 5.1.2 修改 el-tree 模板（动态判断叶子节点）

**原模板位置**: 约 line 98-119

**修改后的模板**:
```vue
<el-tree
  ref="treeRef"
  :data="treeData"
  node-key="id"
  :props="{ children: 'children', label: 'label' }"
  :expand-on-click-node="false"
  default-expand-all
  class="benchmark-tree"
>
  <template #default="{ node, data }">
    <div class="custom-tree-node">
      <span class="node-label">{{ data.label }}</span>

      <!-- 权重显示/编辑 -->
      <div class="node-weight-container">
        <!-- 仅在叶子节点（无children或children为空）且处于编辑模式时可编辑 -->
        <el-input
          v-if="isEditMode && (!data.children || data.children.length === 0)"
          v-model="data.weight"
          size="small"
          @input="handleWeightChange(data)"
          @blur="validateWeight(data)"
          style="width: 100px"
          class="weight-input"
        >
          <template #suffix>%</template>
        </el-input>

        <!-- 非叶子节点或非编辑模式下只读显示 -->
        <span v-else class="node-weight">
          {{ data.weight }}%
          <el-tag
            v-if="data.children && data.children.length > 0"
            size="small"
            type="info"
            class="auto-calc-tag"
          >
            自动计算
          </el-tag>
        </span>
      </div>
    </div>
  </template>
</el-tree>
```

#### 5.1.3 修改权重变化处理逻辑

```javascript
/**
 * 处理权重变化（动态层级版本）
 * 叶子节点权重改变后，需要递归向上更新父节点权重
 */
const handleWeightChange = (nodeData) => {
  // 确保输入的是有效数字
  const weight = parseFloat(nodeData.weight);
  if (isNaN(weight) || weight < 0) {
    nodeData.weight = '0.00';
    return;
  }

  // 格式化为两位小数
  nodeData.weight = weight.toFixed(2);

  // 向上递归更新父节点权重
  updateParentWeights();
};

/**
 * 递归更新所有父节点的权重
 */
const updateParentWeights = () => {
  const updateNodeWeight = (node) => {
    // 如果有子节点，计算子节点权重之和
    if (node.children && node.children.length > 0) {
      // 先递归更新所有子节点
      node.children.forEach(child => updateNodeWeight(child));

      // 然后计算当前节点权重
      const totalWeight = node.children.reduce((sum, child) => {
        return sum + parseFloat(child.weight || 0);
      }, 0);
      node.weight = totalWeight.toFixed(2);
    }
  };

  // 从根节点开始更新
  if (treeData.value && treeData.value.length > 0) {
    treeData.value.forEach(root => updateNodeWeight(root));
  }
};

/**
 * 验证权重输入
 */
const validateWeight = (nodeData) => {
  const weight = parseFloat(nodeData.weight);

  // 验证范围
  if (weight < 0 || weight > 100) {
    ElMessage.warning('权重必须在 0-100 之间');
    nodeData.weight = '0.00';
    return;
  }

  // 更新父节点权重
  updateParentWeights();

  // 验证根节点权重总和
  validateRootWeightSum();
};

/**
 * 验证一级节点权重总和是否为 100%
 */
const validateRootWeightSum = () => {
  if (!treeData.value || treeData.value.length === 0) return;

  const root = treeData.value[0];
  if (!root.children || root.children.length === 0) return;

  const totalWeight = root.children.reduce((sum, child) => {
    return sum + parseFloat(child.weight || 0);
  }, 0);

  // 允许 0.01 的误差
  if (Math.abs(totalWeight - 100) > 0.01) {
    ElMessage.warning(`一级节点权重总和为 ${totalWeight.toFixed(2)}%，应该为 100%`);
    return false;
  }

  return true;
};
```

#### 5.1.4 修改保存方法

```javascript
/**
 * 保存 Benchmark 数据（动态层级版本）
 */
const saveBenchmark = async () => {
  // 1. 验证权重总和
  if (!validateRootWeightSum()) {
    ElMessage.error('权重总和必须为 100%，请调整后再提交');
    return;
  }

  // 2. 确认保存
  try {
    await ElMessageBox.confirm(
      '确认要保存当前的 Benchmark 配置吗？',
      '确认保存',
      {
        confirmButtonText: '确认',
        cancelButtonText: '取消',
        type: 'warning'
      }
    );
  } catch {
    return; // 用户取消
  }

  // 3. 转换数据格式（递归处理）
  const formatNodeData = (node, includeChildren = true) => {
    const data = {
      id: node.id,
      assetClassification: node.label,
      weight: node.weight,
      recordVersion: node.recordVersion || formData.value.recordVersion
    };

    // 递归处理子节点
    if (includeChildren && node.children && node.children.length > 0) {
      data.children = node.children.map(child => formatNodeData(child, true));
    }

    return data;
  };

  // 4. 构建请求数据（从根节点的children开始，即一级节点）
  const root = treeData.value[0];
  const requestData = root.children.map(child => formatNodeData(child, true));

  // 5. 调用API保存
  try {
    loading.value = true;
    await BenchmarkApi.updateBenchmark(requestData);
    ElMessage.success('保存成功');

    // 重新加载数据
    await loadBenchmarkDetail();

    // 退出编辑模式
    isEditMode.value = false;
  } catch (error) {
    console.error('保存失败:', error);
    ElMessage.error('保存失败: ' + (error.message || '未知错误'));
  } finally {
    loading.value = false;
  }
};
```

#### 5.1.5 添加样式

```vue
<style lang="scss" scoped>
.benchmark-tree {
  margin-top: 20px;

  .custom-tree-node {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    padding: 4px 0;

    .node-label {
      flex: 1;
      font-size: 14px;
      color: #303133;
    }

    .node-weight-container {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-left: 20px;

      .node-weight {
        font-size: 14px;
        font-weight: 500;
        color: #409EFF;
        display: flex;
        align-items: center;
        gap: 6px;

        .auto-calc-tag {
          margin-left: 4px;
        }
      }

      .weight-input {
        :deep(.el-input__inner) {
          text-align: right;
          padding-right: 25px;
        }
      }
    }
  }
}

/* 不同层级的样式区分 */
:deep(.el-tree-node__content) {
  height: 36px;

  /* 一级节点 */
  &[aria-level="2"] {
    background-color: #f5f7fa;
    font-weight: 600;
  }

  /* 二级节点 */
  &[aria-level="3"] {
    background-color: #fafafa;
  }

  /* 三级及以上节点 */
  &[aria-level="4"],
  &[aria-level="5"] {
    background-color: #ffffff;
  }
}

/* hover 效果 */
:deep(.el-tree-node__content:hover) {
  background-color: #f0f9ff;
}
</style>
```

---

## 6. 实现步骤

### 6.1 开发环境准备

```bash
# 1. 切换到开发分支
git checkout -b feature/dynamic-tree-levels

# 2. 确保后端环境正常
cd pocpro
mvn clean install -DskipTests

# 3. 确保前端环境正常
cd ../poc-pro-ui
npm install
```

### 6.2 后端实现步骤

#### Step 1: 修改数据库（可选）
```sql
-- 更新字段注释
ALTER TABLE `benchmark_details`
MODIFY COLUMN `asset_level` tinyint COMMENT '资产分类级别: 1,2,3,...（支持多级）';
```

#### Step 2: 修改 VO 类
1. 修改 `BenchmarkDetailsRespVo.java`
2. 修改 `BenchmarkDetailsReqVo.java`

#### Step 3: 修改 Service 类
1. 修改 `BenchmarkServiceImpl.java`
   - 修改 `getBenchmark()` 方法
   - 新增 `buildDynamicTree()` 方法
   - 新增 `buildNodeRecursive()` 方法
   - 新增 `getDefaultTemplateData()` 方法
   - 修改 `updateBenchmark()` 方法
   - 新增 `insertBenchmarkDetailsRecursive()` 方法

#### Step 4: 后端单元测试
```java
// 在 BenchmarkServiceImplTest.java 中添加测试用例

@Test
public void testGetBenchmark_TwoLevels() {
    // 测试二级树数据查询
    String benchmarkId = "test-benchmark-id";
    List<BenchmarkDetailsRespVo> result = benchmarkService.getBenchmark(benchmarkId);

    // 验证数据结构
    assertNotNull(result);
    assertTrue(result.size() > 0);

    // 验证一级节点有子节点
    BenchmarkDetailsRespVo level1 = result.get(0);
    assertNotNull(level1.getChildren());

    // 验证二级节点没有子节点（二级树情况）
    if (level1.getChildren().size() > 0) {
        BenchmarkDetailsRespVo level2 = level1.getChildren().get(0);
        assertTrue(level2.getChildren() == null || level2.getChildren().isEmpty());
    }
}

@Test
public void testGetBenchmark_ThreeLevels() {
    // 测试三级树数据查询
    String benchmarkId = "test-benchmark-3level-id";
    List<BenchmarkDetailsRespVo> result = benchmarkService.getBenchmark(benchmarkId);

    // 验证三级结构
    BenchmarkDetailsRespVo level1 = result.get(0);
    assertNotNull(level1.getChildren());

    BenchmarkDetailsRespVo level2 = level1.getChildren().get(0);
    assertNotNull(level2.getChildren());

    BenchmarkDetailsRespVo level3 = level2.getChildren().get(0);
    assertTrue(level3.getChildren() == null || level3.getChildren().isEmpty());
}

@Test
public void testGetBenchmark_EmptyData() {
    // 测试空数据返回默认模板
    String benchmarkId = "empty-benchmark-id";
    List<BenchmarkDetailsRespVo> result = benchmarkService.getBenchmark(benchmarkId);

    // 验证返回默认模板
    assertNotNull(result);
    assertTrue(result.size() > 0);
    assertEquals("Fixed Income", result.get(0).getAssetsClassification());
}
```

### 6.3 前端实现步骤

#### Step 1: 备份原文件
```bash
cp src/views/benchmark/detail/index.vue src/views/benchmark/detail/index.vue.backup
```

#### Step 2: 修改 index.vue
1. 修改 `processTreeData()` 方法
2. 修改 el-tree 模板
3. 修改 `handleWeightChange()` 方法
4. 新增 `updateParentWeights()` 方法
5. 新增 `validateWeight()` 方法
6. 新增 `validateRootWeightSum()` 方法
7. 修改 `saveBenchmark()` 方法
8. 添加新样式

#### Step 3: 前端测试

**测试场景 1: 二级树数据**
1. 在数据库中准备二级树数据
2. 访问 Benchmark 详情页
3. 验证显示二级树结构
4. 验证只有二级节点可编辑
5. 修改权重后验证一级节点自动计算

**测试场景 2: 三级树数据**
1. 在数据库中准备三级树数据
2. 访问 Benchmark 详情页
3. 验证显示三级树结构
4. 验证只有三级节点（叶子节点）可编辑
5. 修改权重后验证二级、一级节点自动计算

**测试场景 3: 空数据默认模板**
1. 清空 benchmark_details 表数据
2. 访问 Benchmark 详情页
3. 验证显示默认模板
4. 验证可以编辑叶子节点权重

### 6.4 集成测试

#### 测试用例 1: 二级树完整流程
```
1. 创建二级树数据
2. 查询并展示
3. 编辑权重
4. 保存数据
5. 验证数据库中的数据正确
6. 重新查询验证
```

#### 测试用例 2: 三级树完整流程
```
1. 创建三级树数据
2. 查询并展示
3. 编辑权重（仅三级节点）
4. 验证二级、一级节点自动计算
5. 保存数据
6. 验证数据库中的数据正确
7. 重新查询验证
```

#### 测试用例 3: 二级转三级流程
```
1. 初始数据为二级树
2. 手动在数据库添加三级节点
3. 刷新页面
4. 验证自动展示为三级树
5. 验证编辑权限从二级节点转移到三级节点
```

---

## 7. 测试方案

### 7.1 后端 API 测试

#### 7.1.1 测试数据准备

**二级树测试数据:**
```sql
-- Benchmark 主表
INSERT INTO benchmark (id, business_id, name, status, record_version)
VALUES ('bench-2level', 'business-001', 'Test 2-Level Tree', 0, 1);

-- 一级节点
INSERT INTO benchmark_details (id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES
('l1-fixed', 'bench-2level', NULL, 'Fixed Income', 1, 40.00, 1),
('l1-equity', 'bench-2level', NULL, 'Equity', 1, 60.00, 1);

-- 二级节点
INSERT INTO benchmark_details (id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES
('l2-gov', 'bench-2level', 'l1-fixed', 'Government Debt', 2, 25.00, 1),
('l2-corp', 'bench-2level', 'l1-fixed', 'Corporate Debt', 2, 15.00, 1),
('l2-dev', 'bench-2level', 'l1-equity', 'Developed Markets', 2, 40.00, 1),
('l2-em', 'bench-2level', 'l1-equity', 'Emerging Markets', 2, 20.00, 1);
```

**三级树测试数据:**
```sql
-- Benchmark 主表
INSERT INTO benchmark (id, business_id, name, status, record_version)
VALUES ('bench-3level', 'business-002', 'Test 3-Level Tree', 0, 1);

-- 一级节点
INSERT INTO benchmark_details (id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES ('l1-fixed-3', 'bench-3level', NULL, 'Fixed Income', 1, 40.00, 1);

-- 二级节点
INSERT INTO benchmark_details (id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES ('l2-gov-3', 'bench-3level', 'l1-fixed-3', 'Government Debt', 2, 25.00, 1);

-- 三级节点
INSERT INTO benchmark_details (id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES
('l3-eur', 'bench-3level', 'l2-gov-3', 'EUR Government', 3, 15.00, 1),
('l3-non-eur', 'bench-3level', 'l2-gov-3', 'Non-EUR Government', 3, 10.00, 1);
```

#### 7.1.2 Postman 测试

**测试 1: 查询二级树**
```http
GET /api/benchmark/detail?id=bench-2level
```

**预期响应:**
```json
[
  {
    "id": "l1-fixed",
    "assetsClassification": "Fixed Income",
    "weight": "40.00",
    "recordVersion": "1",
    "assetLevel": 1,
    "children": [
      {
        "id": "l2-gov",
        "assetsClassification": "Government Debt",
        "weight": "25.00",
        "assetLevel": 2,
        "children": []
      },
      {
        "id": "l2-corp",
        "assetsClassification": "Corporate Debt",
        "weight": "15.00",
        "assetLevel": 2,
        "children": []
      }
    ]
  },
  {
    "id": "l1-equity",
    "assetsClassification": "Equity",
    "weight": "60.00",
    "assetLevel": 1,
    "children": [...]
  }
]
```

**测试 2: 查询三级树**
```http
GET /api/benchmark/detail?id=bench-3level
```

**预期响应:**
```json
[
  {
    "id": "l1-fixed-3",
    "assetsClassification": "Fixed Income",
    "weight": "40.00",
    "assetLevel": 1,
    "children": [
      {
        "id": "l2-gov-3",
        "assetsClassification": "Government Debt",
        "weight": "25.00",
        "assetLevel": 2,
        "children": [
          {
            "id": "l3-eur",
            "assetsClassification": "EUR Government",
            "weight": "15.00",
            "assetLevel": 3,
            "children": []
          },
          {
            "id": "l3-non-eur",
            "assetsClassification": "Non-EUR Government",
            "weight": "10.00",
            "assetLevel": 3,
            "children": []
          }
        ]
      }
    ]
  }
]
```

### 7.2 前端功能测试

#### 测试检查清单

| 测试项 | 二级树 | 三级树 | 验证点 |
|--------|--------|--------|--------|
| 数据加载 | ✓ | ✓ | 树形结构正确展示 |
| 层级显示 | ✓ | ✓ | 不同层级样式区分 |
| 权重显示 | ✓ | ✓ | 格式为 X.XX% |
| 编辑权限 | 仅二级可编辑 | 仅三级可编辑 | 叶子节点可编辑 |
| 自动计算 | 一级自动计算 | 二级、一级自动计算 | 父节点=子节点之和 |
| 权重验证 | ✓ | ✓ | 0-100范围验证 |
| 总和验证 | ✓ | ✓ | 一级节点总和=100% |
| 数据保存 | ✓ | ✓ | 保存后数据正确 |
| 空数据处理 | ✓ | ✓ | 显示默认模板 |

#### 手动测试步骤

**测试 1: 二级树编辑**
```
1. 访问 /benchmark/detail?id=bench-2level
2. 点击"编辑"按钮
3. 观察二级节点有输入框，一级节点只读
4. 修改二级节点权重（如 25 改为 30）
5. 观察一级节点权重自动更新（40 变为 45）
6. 点击"保存"
7. 验证保存成功提示
8. 刷新页面验证数据持久化
```

**测试 2: 三级树编辑**
```
1. 访问 /benchmark/detail?id=bench-3level
2. 点击"编辑"按钮
3. 观察三级节点有输入框，二级、一级节点只读
4. 修改三级节点权重（如 15 改为 18）
5. 观察二级节点权重自动更新（25 变为 28）
6. 观察一级节点权重自动更新（40 变为 43）
7. 调整其他节点使总和为 100%
8. 点击"保存"
9. 验证保存成功
```

**测试 3: 权重验证**
```
1. 编辑模式下，输入无效权重（如 -10）
2. 验证显示警告提示
3. 输入超过 100 的权重（如 150）
4. 验证显示警告提示
5. 修改权重使一级节点总和不等于 100
6. 点击保存
7. 验证显示"权重总和必须为 100%"错误
```

### 7.3 性能测试

#### 7.3.1 后端性能测试

**测试场景**: 查询包含 1000 个节点的三级树

```java
@Test
public void testPerformance_LargeTree() {
    // 准备 1000 个节点的数据
    String benchmarkId = "large-tree-benchmark";

    long startTime = System.currentTimeMillis();
    List<BenchmarkDetailsRespVo> result = benchmarkService.getBenchmark(benchmarkId);
    long endTime = System.currentTimeMillis();

    long duration = endTime - startTime;
    System.out.println("查询耗时: " + duration + "ms");

    // 验证性能要求：查询时间应小于 2 秒
    assertTrue(duration < 2000, "查询时间过长: " + duration + "ms");
}
```

#### 7.3.2 前端性能测试

**测试场景**: 渲染包含 500 个节点的树

```javascript
// 在浏览器 Console 中执行
console.time('Tree Rendering');

// 触发数据加载
await loadBenchmarkDetail();

console.timeEnd('Tree Rendering');

// 验证渲染时间应小于 1 秒
```

---

## 8. 常见问题处理

### 8.1 后端问题

#### 问题 1: 递归深度过大导致栈溢出

**现象:**
```
java.lang.StackOverflowError
    at cn.bochk.pap.server.business.service.Impl.BenchmarkServiceImpl.buildNodeRecursive
```

**原因:** 数据存在循环引用（parent_id 指向错误）

**解决方案:**
```java
// 在 buildNodeRecursive 方法中添加深度限制
private BenchmarkDetailsRespVo buildNodeRecursive(
        BenchmarkDetailsDo currentNode,
        Map<String, List<BenchmarkDetailsDo>> parentChildMap,
        BenchmarkDO benchmarkDO,
        int depth) {  // 新增深度参数

    // 防止递归过深
    if (depth > 10) {
        log.warn("递归深度超过10层，可能存在数据问题: {}", currentNode.getId());
        return createBasicNode(currentNode, benchmarkDO);
    }

    // ... 原有逻辑

    // 递归调用时传递 depth + 1
    BenchmarkDetailsRespVo childVo = buildNodeRecursive(
        childNode, parentChildMap, benchmarkDO, depth + 1);
}
```

#### 问题 2: 权重计算精度问题

**现象:** 子节点权重之和为 99.99% 或 100.01%

**原因:** BigDecimal 精度问题

**解决方案:**
```java
// 统一使用 setScale 设置精度
BigDecimal totalWeight = childVos.stream()
    .map(child -> new BigDecimal(child.getWeight()))
    .reduce(BigDecimal.ZERO, BigDecimal::add)
    .setScale(2, RoundingMode.HALF_UP);  // 统一四舍五入

nodeVo.setWeight(totalWeight.toString());
```

#### 问题 3: 空数据时返回 null

**现象:** 前端收到 null 导致页面报错

**解决方案:**
```java
@Override
public List<BenchmarkDetailsRespVo> getBenchmark(String id) {
    BenchmarkDO benchmarkDO = benchmarkMapper.selectById(id);

    // 确保 benchmarkDO 不为 null
    if (benchmarkDO == null) {
        log.warn("未找到 benchmark 记录: {}", id);
        return Collections.emptyList();  // 返回空列表而不是 null
    }

    List<BenchmarkDetailsDo> detailsDos = benchmarkDetailsMapper.selectList(id);

    // 确保详情列表不为 null
    if (detailsDos == null || detailsDos.isEmpty()) {
        return getDefaultTemplateData(benchmarkDO);
    }

    return buildDynamicTree(detailsDos, benchmarkDO);
}
```

### 8.2 前端问题

#### 问题 1: 权重输入框无法输入小数点

**现象:** 输入 "10." 后自动变成 "10.00"

**原因:** `@input` 事件中立即格式化数字

**解决方案:**
```javascript
// 将格式化逻辑从 @input 移到 @blur
<el-input
  v-model="data.weight"
  @input="handleWeightInput(data)"     // 仅做基本验证
  @blur="handleWeightBlur(data)"       // 失焦时格式化
/>

const handleWeightInput = (nodeData) => {
  // 允许输入数字和小数点
  nodeData.weight = nodeData.weight.replace(/[^\d.]/g, '');
};

const handleWeightBlur = (nodeData) => {
  // 失焦时格式化为两位小数
  const weight = parseFloat(nodeData.weight);
  if (!isNaN(weight)) {
    nodeData.weight = weight.toFixed(2);
    updateParentWeights();
  } else {
    nodeData.weight = '0.00';
  }
};
```

#### 问题 2: 树节点展开/折叠状态丢失

**现象:** 编辑权重后树自动折叠

**原因:** `treeData.value` 重新赋值导致重新渲染

**解决方案:**
```javascript
// 保存展开状态
const saveExpandedKeys = () => {
  if (treeRef.value) {
    expandedKeys.value = treeRef.value.store.nodesMap;
  }
};

// 恢复展开状态
const restoreExpandedKeys = () => {
  nextTick(() => {
    if (treeRef.value && expandedKeys.value) {
      Object.keys(expandedKeys.value).forEach(key => {
        const node = treeRef.value.getNode(key);
        if (node && !node.isLeaf) {
          node.expanded = true;
        }
      });
    }
  });
};

// 在权重更新前后调用
const handleWeightChange = (nodeData) => {
  saveExpandedKeys();

  // ... 更新权重逻辑

  restoreExpandedKeys();
};
```

#### 问题 3: 父节点权重显示"NaN%"

**现象:** 子节点为空或权重为空字符串时，父节点显示 NaN%

**原因:** parseFloat('') 返回 NaN

**解决方案:**
```javascript
const updateParentWeights = () => {
  const updateNodeWeight = (node) => {
    if (node.children && node.children.length > 0) {
      node.children.forEach(child => updateNodeWeight(child));

      const totalWeight = node.children.reduce((sum, child) => {
        // 安全解析权重，默认为 0
        const weight = parseFloat(child.weight);
        return sum + (isNaN(weight) ? 0 : weight);
      }, 0);

      node.weight = totalWeight.toFixed(2);
    } else if (!node.weight || node.weight === '') {
      // 叶子节点权重为空时默认为 0
      node.weight = '0.00';
    }
  };

  if (treeData.value && treeData.value.length > 0) {
    treeData.value.forEach(root => updateNodeWeight(root));
  }
};
```

### 8.3 数据一致性问题

#### 问题: 前端编辑后保存，数据库中的 parent_id 关系错误

**现象:** 保存成功，但重新查询时树结构错乱

**原因:** 递归保存时 parent_id 未正确传递

**解决方案:**
```java
// 确保递归保存时正确传递 parent_id
private void insertBenchmarkDetailsRecursive(
        List<BenchmarkDetailsReqVo> reqVos,
        BenchmarkDO newBenchmark,
        String parentId,  // 当前层级的父节点ID
        int currentLevel) {

    List<BenchmarkDetailsDo> insertDetails = new ArrayList<>();

    for (BenchmarkDetailsReqVo reqVo : reqVos) {
        BenchmarkDetailsDo detail = new BenchmarkDetailsDo();
        String newId = IdUtils.getUUID();

        detail.setId(newId);
        detail.setParentId(parentId);  // 设置父节点ID
        detail.setAssetLevel(currentLevel);
        // ... 其他字段

        insertDetails.add(detail);

        // 递归处理子节点，传递当前节点ID作为子节点的parent_id
        if (reqVo.getChildren() != null && !reqVo.getChildren().isEmpty()) {
            insertBenchmarkDetailsRecursive(
                reqVo.getChildren(),
                newBenchmark,
                newId,  // 传递当前节点ID
                currentLevel + 1
            );
        }
    }

    if (!insertDetails.isEmpty()) {
        benchmarkDetailsMapper.insertBatch(insertDetails);
    }
}
```

---

## 9. 总结

### 9.1 方案优势

1. **灵活性**: 根据数据动态展示二级或三级树，不固定层级
2. **可扩展性**: 理论上支持任意层级（通过递归实现）
3. **向后兼容**: 完全兼容现有二级树数据，无需数据迁移
4. **用户体验**: 仅叶子节点可编辑，父节点自动计算，逻辑清晰
5. **性能优化**: 使用 Map 预处理父子关系，避免多次循环查询

### 9.2 关键技术点

- **后端递归构建**: `buildNodeRecursive()` 方法实现动态层级构建
- **前端递归渲染**: el-tree 原生支持 children 递归渲染
- **权重自动计算**: 子节点权重变化时递归向上更新父节点
- **叶子节点判断**: `!data.children || data.children.length === 0`
- **数据结构统一**: VO类使用相同类型的 children 支持无限嵌套

### 9.3 后续优化建议

1. **性能优化**:
   - 大数据量时考虑分页加载或虚拟滚动
   - 使用缓存减少数据库查询

2. **功能增强**:
   - 支持拖拽调整节点顺序
   - 支持动态添加/删除节点
   - 支持节点复制/粘贴功能

3. **数据安全**:
   - 添加乐观锁防止并发修改冲突
   - 添加数据变更审计日志

4. **用户体验**:
   - 添加撤销/重做功能
   - 添加数据验证提示（实时显示权重总和）
   - 添加快捷键支持（如 Ctrl+S 保存）

---

## 10. 附录

### 10.1 完整文件清单

#### 后端文件
```
pocpro/pap-server/src/main/java/cn/bochk/pap/server/business/
├── vo/
│   ├── resp/BenchmarkDetailsRespVo.java (修改)
│   └── req/BenchmarkDetailsReqVo.java (修改)
├── service/
│   └── Impl/BenchmarkServiceImpl.java (修改)
└── mapper/
    └── BenchmarkDetailsMapper.java (无需修改)
```

#### 前端文件
```
poc-pro-ui/src/views/benchmark/
└── detail/
    └── index.vue (修改)
```

#### 数据库文件
```
pocpro/sql/mysql/benchmark/
└── table.sql (可选修改：更新注释)
```

### 10.2 Git 提交建议

```bash
# 提交 1: 后端 VO 类修改
git add **/BenchmarkDetailsRespVo.java **/BenchmarkDetailsReqVo.java
git commit -m "feat: 修改 Benchmark VO 类支持动态层级嵌套

- BenchmarkDetailsRespVo: benchmarkDetailsLevel → children
- BenchmarkDetailsReqVo: 新增 children 字段
- 支持递归嵌套结构"

# 提交 2: 后端 Service 类修改
git add **/BenchmarkServiceImpl.java
git commit -m "feat: 实现 Benchmark 动态层级树构建

- 新增 buildDynamicTree() 方法：根据数据动态构建树
- 新增 buildNodeRecursive() 方法：递归构建节点
- 新增 getDefaultTemplateData() 方法：空数据默认模板
- 修改 updateBenchmark()：支持递归保存多级数据
- 兼容二级和三级树结构"

# 提交 3: 前端代码修改
git add **/benchmark/detail/index.vue
git commit -m "feat: 前端支持 Benchmark 动态层级展示

- 修改 processTreeData()：递归处理任意层级
- 修改 el-tree 模板：动态判断叶子节点
- 新增 updateParentWeights()：递归更新父节点权重
- 新增 validateRootWeightSum()：验证权重总和
- 修改 saveBenchmark()：支持递归数据保存
- 优化样式：不同层级视觉区分"

# 提交 4: 文档和测试
git add three_tree.md
git commit -m "docs: 添加动态层级树改造方案文档

- 详细实现方案
- 完整代码示例
- 测试方案和用例
- 常见问题处理"
```

### 10.3 部署检查清单

#### 部署前检查
- [ ] 后端单元测试全部通过
- [ ] 前端 ESLint 检查通过
- [ ] 数据库脚本已审核
- [ ] 代码已通过 Code Review
- [ ] 已在测试环境验证功能

#### 部署步骤
1. [ ] 备份生产数据库
2. [ ] 执行数据库变更脚本（如有）
3. [ ] 部署后端代码
4. [ ] 部署前端代码
5. [ ] 执行烟雾测试
6. [ ] 监控系统日志和错误

#### 部署后验证
- [ ] 二级树功能正常
- [ ] 三级树功能正常
- [ ] 空数据显示默认模板
- [ ] 权重编辑和保存正常
- [ ] 无报错日志

---

**文档版本**: v2.0（动态层级版本）
**最后更新**: 2025-10-20
**作者**: Claude Code
**状态**: 待实现
