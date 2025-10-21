# Benchmark Details Insert/Update Logic Design

> **Version**: v2.0
> **Date**: 2025-10-21
> **Author**: Claude Code
> **Description**: Template-based initialization with template_code approach (supports multiple benchmark types)

---

## Business Requirements

### Scenario

1. **Initialization Phase**:
   - System only initializes `benchmark` main table data
   - `benchmark_details` table is empty
   - Need to fetch fixed detail structure from **dictionary/template table**
   - Template data does not include weights, users maintain and fill weights in frontend

2. **First Save**:
   - User fills in weights and clicks save
   - Backend checks `benchmark_details` table is empty
   - Execute **INSERT operation**
   - Generate real IDs and insert into database

3. **Second and Subsequent Saves**:
   - `benchmark_details` table already has data
   - Execute **UPDATE operation**
   - Update weights and version numbers

---

## Database Design

### ⚠️ Design Problem and Solution

**Problem**:
1. Template table cannot use fixed `id` and `parent_id` - conflicts when supporting multiple benchmark types (Private Bank, Retail Bank)
2. Cannot establish hierarchy using `parent_id` when IDs don't exist yet

**Solution**:
1. Use **`template_code`** as business identifier instead of fixed UUID
2. Use **`parent_template_code`** to establish hierarchy (not dependent on real IDs)
3. Use **`benchmark_type`** to support multiple types (1=Private Bank, 2=Retail Bank)
4. **Dynamically generate UUIDs** during save operation using Map<template_code, generated_uuid>

### 1. Create Template Table

**Table Name**: `benchmark_details_template`

**Purpose**: Store template structure for different benchmark types using template codes

```sql
-- benchmark_details_template template table (v2.0)
CREATE TABLE benchmark_details_template (
    id nvarchar(64) NOT NULL PRIMARY KEY,  -- Auto-generated primary key (UUID)
    template_code nvarchar(64) NOT NULL,   -- Template code (business identifier, unique per type)
    parent_template_code nvarchar(64) DEFAULT NULL NULL,  -- Parent template code (for hierarchy)
    benchmark_type tinyint NOT NULL,       -- Benchmark type: 1=Private Bank, 2=Retail Bank
    asset_classification nvarchar(64) NOT NULL,
    asset_level tinyint NOT NULL,
    sort_order int DEFAULT 0 NULL,
    is_active bit DEFAULT 1 NULL,
    CONSTRAINT UK_template_code_type UNIQUE (template_code, benchmark_type)  -- Unique per type
)
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Primary Key ID (auto-generated UUID)',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_details_template',
    'COLUMN', N'id'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Template Code (e.g., PB_FI, RB_EQUITY)',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_details_template',
    'COLUMN', N'template_code'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Parent Template Code (NULL for root nodes)',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_details_template',
    'COLUMN', N'parent_template_code'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Benchmark Type: 1=Private Bank, 2=Retail Bank',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_details_template',
    'COLUMN', N'benchmark_type'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Asset Classification Name',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_details_template',
    'COLUMN', N'asset_classification'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Asset Level (1,2,3...)',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_details_template',
    'COLUMN', N'asset_level'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Sort Order',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_details_template',
    'COLUMN', N'sort_order'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Is Active (1=active, 0=inactive)',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_details_template',
    'COLUMN', N'is_active'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Benchmark details template table (supports multiple types)',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_details_template'
GO
```

### 2. Template Code Naming Convention

**Format**: `{Type}_{Category}_{SubCategory}_{Detail}`

**Examples**:
- **Private Bank**:
  - `PB_FI` (Level 1: Fixed Income)
  - `PB_FI_GD` (Level 2: Government Debt)
  - `PB_FI_GD_EUR` (Level 3: EUR Government Bonds)
  - `PB_EQUITY` (Level 1: Equity)
  - `PB_EQUITY_DM` (Level 2: Developed Markets)

- **Retail Bank**:
  - `RB_FI` (Level 1: Fixed Income)
  - `RB_FI_GD` (Level 2: Government Debt)
  - `RB_FI_GD_EUR` (Level 3: EUR Government Bonds)

**Benefits**:
- Human-readable
- No UUID conflicts across types
- Easy to maintain and debug

### 3. Insert Template Data (Private Bank Example)

**Note**: ID is auto-generated UUID, hierarchy is established by template_code

```sql
-- ====================================================================
-- Insert benchmark_details_template for Private Bank (benchmark_type = 1)
-- Mixed 2-level and 3-level hierarchy
-- ====================================================================

-- Level 1: Fixed Income
INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
VALUES (NEWID(), N'PB_FI', NULL, 1, N'Fixed Income', 1, 1, 1);

    -- Level 2: Government Debt (has level 3 children)
    INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
    VALUES (NEWID(), N'PB_FI_GD', N'PB_FI', 1, N'Government Debt', 2, 1, 1);

        -- Level 3: EUR Government Bonds
        INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
        VALUES (NEWID(), N'PB_FI_GD_EUR', N'PB_FI_GD', 1, N'EUR Government Bonds', 3, 1, 1);

        -- Level 3: Non-EUR Government Bonds
        INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
        VALUES (NEWID(), N'PB_FI_GD_NEUR', N'PB_FI_GD', 1, N'Non-EUR Government Bonds', 3, 2, 1);

    -- Level 2: Corporate Debt (leaf node, no level 3 children)
    INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
    VALUES (NEWID(), N'PB_FI_CD', N'PB_FI', 1, N'Corporate Debt', 2, 2, 1);

-- Level 1: Equity
INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
VALUES (NEWID(), N'PB_EQUITY', NULL, 1, N'Equity', 1, 2, 1);

    -- Level 2: Developed Markets (has level 3 children)
    INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
    VALUES (NEWID(), N'PB_EQUITY_DM', N'PB_EQUITY', 1, N'Developed Markets', 2, 1, 1);

        -- Level 3: Europe Equity
        INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
        VALUES (NEWID(), N'PB_EQUITY_DM_EU', N'PB_EQUITY_DM', 1, N'Europe Equity', 3, 1, 1);

        -- Level 3: North America Equity
        INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
        VALUES (NEWID(), N'PB_EQUITY_DM_NA', N'PB_EQUITY_DM', 1, N'North America Equity', 3, 2, 1);

    -- Level 2: Emerging Markets (leaf node, no level 3 children)
    INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
    VALUES (NEWID(), N'PB_EQUITY_EM', N'PB_EQUITY', 1, N'Emerging Markets', 2, 2, 1);

-- Level 1: Alternatives
INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
VALUES (NEWID(), N'PB_ALT', NULL, 1, N'Alternatives', 1, 3, 1);

    -- Level 2: Hedge Funds (leaf node, no level 3 children)
    INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
    VALUES (NEWID(), N'PB_ALT_HF', N'PB_ALT', 1, N'Hedge Funds', 2, 1, 1);
```

### 4. Insert Template Data (Retail Bank Example)

```sql
-- ====================================================================
-- Insert benchmark_details_template for Retail Bank (benchmark_type = 2)
-- ====================================================================

-- Level 1: Fixed Income
INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
VALUES (NEWID(), N'RB_FI', NULL, 2, N'Fixed Income', 1, 1, 1);

    -- Level 2: Government Debt
    INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
    VALUES (NEWID(), N'RB_FI_GD', N'RB_FI', 2, N'Government Debt', 2, 1, 1);

    -- Level 2: Corporate Debt
    INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
    VALUES (NEWID(), N'RB_FI_CD', N'RB_FI', 2, N'Corporate Debt', 2, 2, 1);

-- Level 1: Equity
INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
VALUES (NEWID(), N'RB_EQUITY', NULL, 2, N'Equity', 1, 2, 1);

    -- Level 2: Domestic Equity
    INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
    VALUES (NEWID(), N'RB_EQUITY_DOM', N'RB_EQUITY', 2, N'Domestic Equity', 2, 1, 1);

    -- Level 2: International Equity
    INSERT INTO benchmark_details_template (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
    VALUES (NEWID(), N'RB_EQUITY_INTL', N'RB_EQUITY', 2, N'International Equity', 2, 2, 1);
```

**Template Data Tree Structure**:

**Private Bank (benchmark_type = 1)**:
```
PB_FI (Fixed Income)
├─ PB_FI_GD (Government Debt) [has children]
│  ├─ PB_FI_GD_EUR (EUR Government Bonds)
│  └─ PB_FI_GD_NEUR (Non-EUR Government Bonds)
└─ PB_FI_CD (Corporate Debt) [leaf]

PB_EQUITY (Equity)
├─ PB_EQUITY_DM (Developed Markets) [has children]
│  ├─ PB_EQUITY_DM_EU (Europe Equity)
│  └─ PB_EQUITY_DM_NA (North America Equity)
└─ PB_EQUITY_EM (Emerging Markets) [leaf]

PB_ALT (Alternatives)
└─ PB_ALT_HF (Hedge Funds) [leaf]
```

**Retail Bank (benchmark_type = 2)**:
```
RB_FI (Fixed Income)
├─ RB_FI_GD (Government Debt)
└─ RB_FI_CD (Corporate Debt)

RB_EQUITY (Equity)
├─ RB_EQUITY_DOM (Domestic Equity)
└─ RB_EQUITY_INTL (International Equity)
```

---

## Backend Implementation

### 1. Create Template Table Entity and Mapper

#### 1.1 BenchmarkDetailsTemplateDO.java

**Path**: `pap-server/src/main/java/cn/bochk/pap/server/business/dal/dataobject/BenchmarkDetailsTemplateDO.java`

```java
package cn.bochk.pap.server.business.dal.dataobject;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * benchmark_details_template template table entity (v2.0)
 * Store template structure using template codes (supports multiple benchmark types)
 */
@Data
@TableName("benchmark_details_template")
public class BenchmarkDetailsTemplateDO {

    /**
     * Primary Key ID (auto-generated UUID)
     */
    private String id;

    /**
     * Template Code (business identifier, e.g., PB_FI, RB_EQUITY)
     */
    private String templateCode;

    /**
     * Parent Template Code (NULL means root node)
     */
    private String parentTemplateCode;

    /**
     * Benchmark Type: 1=Private Bank, 2=Retail Bank
     */
    private Integer benchmarkType;

    /**
     * Asset Classification Name
     */
    private String assetClassification;

    /**
     * Asset Level (1,2,3...)
     */
    private Integer assetLevel;

    /**
     * Sort Order
     */
    private Integer sortOrder;

    /**
     * Is Active (true=active, false=inactive)
     */
    private Boolean isActive;
}
```

#### 1.2 BenchmarkDetailsTemplateMapper.java

**Path**: `pap-server/src/main/java/cn/bochk/pap/server/business/dal/mysql/BenchmarkDetailsTemplateMapper.java`

```java
package cn.bochk.pap.server.business.dal.mysql;

import cn.bochk.pap.server.business.dal.dataobject.BenchmarkDetailsTemplateDO;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * benchmark_details_template Mapper (v2.0)
 */
@Mapper
public interface BenchmarkDetailsTemplateMapper extends BaseMapper<BenchmarkDetailsTemplateDO> {

    /**
     * Query active template data by benchmark type
     * Ordered by sort_order
     *
     * @param benchmarkType benchmark type (1=Private Bank, 2=Retail Bank)
     * @return template list
     */
    @Select("SELECT * FROM benchmark_details_template " +
            "WHERE is_active = 1 AND benchmark_type = #{benchmarkType} " +
            "ORDER BY sort_order ASC")
    List<BenchmarkDetailsTemplateDO> selectActiveTemplatesByType(@Param("benchmarkType") Integer benchmarkType);
}
```

### 2. VO Classes (No modifications needed)

#### 2.1 BenchmarkDetailsRespVo (No changes needed)

**Path**: `pap-server/src/main/java/cn/bochk/pap/server/business/controller/vo/response/BenchmarkDetailsRespVo.java`

```java
/**
 * Benchmark details response VO
 * Note: No need to add templateCode field
 * The hierarchy is maintained by children array
 */
@Data
public class BenchmarkDetailsRespVo {
    private String id;
    private String assetsClassification;
    private String weight;
    private Integer assetLevel;
    private String processInstanceId;
    private String recordVersion;
    private List<BenchmarkDetailsRespVo> children;  // ← Hierarchy maintained here
}
```

#### 2.2 BenchmarkDetailsReqVo (No changes needed)

**Path**: `pap-server/src/main/java/cn/bochk/pap/server/business/controller/vo/request/BenchmarkDetailsReqVo.java`

```java
/**
 * Benchmark details request VO
 * Note: No need to add templateCode field
 * The hierarchy is maintained by children array
 */
@Data
public class BenchmarkDetailsReqVo {
    private String id;
    private String assetsClassification;
    private String weight;
    private Integer assetLevel;
    private String recordVersion;
    private List<BenchmarkDetailsReqVo> children;  // ← Hierarchy maintained here
}
```

### 3. Modify BenchmarkServiceImpl.java

**Path**: `pap-server/src/main/java/cn/bochk/pap/server/business/service/Impl/BenchmarkServiceImpl.java`

#### 3.1 Add Dependency Injection

```java
import cn.bochk.pap.server.business.dal.dataobject.BenchmarkDetailsTemplateDO;
import cn.bochk.pap.server.business.dal.mysql.BenchmarkDetailsTemplateMapper;
import cn.hutool.core.util.IdUtil;

@Service
@Slf4j
public class BenchmarkServiceImpl implements BenchmarkService {

    @Autowired
    private BenchmarkMapper benchmarkMapper;

    @Autowired
    private BenchmarkDetailsMapper benchmarkDetailsMapper;

    // NEW: Inject template table Mapper
    @Autowired
    private BenchmarkDetailsTemplateMapper templateMapper;

    // ... other code
}
```

#### 3.2 Modify getBenchmark() Method (Query Logic)

```java
/**
 * Query benchmark details
 * If benchmark_details is empty, fetch data from template table
 *
 * @param id benchmark primary key ID
 * @return tree structure detail data
 */
@Override
public List<BenchmarkDetailsRespVo> getBenchmark(String id) {
    // 1. Query benchmark main table
    BenchmarkDO benchmarkDO = benchmarkMapper.selectById(id);
    if (benchmarkDO == null) {
        throw new BusinessException("Benchmark not found: " + id);
    }

    // 2. Query benchmark_details table
    List<BenchmarkDetailsDo> detailsDos = benchmarkDetailsMapper.selectList(
        new LambdaQueryWrapper<BenchmarkDetailsDo>()
            .eq(BenchmarkDetailsDo::getBenchmarkId, id)
    );

    // 3. If details table is empty, get default data from template
    if (detailsDos == null || detailsDos.isEmpty()) {
        log.info("Benchmark details is empty, loading from template for benchmark: {}", id);
        return getDefaultTemplateData(benchmarkDO);
    }

    // 4. Otherwise build tree structure from existing data
    log.info("Benchmark details found, building tree for benchmark: {}", id);
    return buildDynamicTree(detailsDos, benchmarkDO);
}
```

#### 3.3 Add getDefaultTemplateData() Method

```java
/**
 * Get default template data (called when benchmark_details is empty)
 *
 * @param benchmarkDO benchmark main table data
 * @return tree structure of template data
 */
private List<BenchmarkDetailsRespVo> getDefaultTemplateData(BenchmarkDO benchmarkDO) {
    // 1. Get benchmark_type from benchmarkDO
    Integer benchmarkType = benchmarkDO.getBenchmarkType();
    if (benchmarkType == null) {
        throw new BusinessException("Benchmark type cannot be null");
    }

    // 2. Query template data by benchmark_type
    List<BenchmarkDetailsTemplateDO> templates = templateMapper.selectActiveTemplatesByType(benchmarkType);

    if (templates == null || templates.isEmpty()) {
        log.warn("No active templates found for benchmark_type: {}", benchmarkType);
        return new ArrayList<>();
    }

    log.info("Loaded {} template records for benchmark_type: {}", templates.size(), benchmarkType);

    // 3. Convert template data to tree structure
    return buildTreeFromTemplate(templates, benchmarkDO);
}
```

#### 3.4 Add buildTreeFromTemplate() Method

```java
/**
 * Build tree structure from template data (v2.0)
 * Use template_code and parent_template_code to establish hierarchy
 *
 * @param templates template data list
 * @param benchmarkDO benchmark main table data
 * @return tree structure list
 */
private List<BenchmarkDetailsRespVo> buildTreeFromTemplate(
        List<BenchmarkDetailsTemplateDO> templates,
        BenchmarkDO benchmarkDO) {

    List<BenchmarkDetailsRespVo> result = new ArrayList<>();

    // 1. Group by parent_template_code (Map<parent_template_code, List<children>>)
    Map<String, List<BenchmarkDetailsTemplateDO>> parentChildMap = templates.stream()
        .filter(t -> t.getParentTemplateCode() != null)  // Exclude root nodes
        .collect(Collectors.groupingBy(BenchmarkDetailsTemplateDO::getParentTemplateCode));

    // 2. Find all root nodes (parent_template_code == null)
    List<BenchmarkDetailsTemplateDO> rootNodes = templates.stream()
        .filter(t -> t.getParentTemplateCode() == null)
        .sorted(Comparator.comparing(BenchmarkDetailsTemplateDO::getSortOrder))
        .collect(Collectors.toList());

    log.info("Found {} root nodes in template for benchmark_type: {}",
        rootNodes.size(), benchmarkDO.getBenchmarkType());

    // 3. Recursively build each root node and its subtree
    for (BenchmarkDetailsTemplateDO rootNode : rootNodes) {
        BenchmarkDetailsRespVo rootVo = buildTemplateNodeRecursive(
            rootNode,
            parentChildMap,
            benchmarkDO
        );
        result.add(rootVo);
    }

    return result;
}
```

#### 3.5 Add buildTemplateNodeRecursive() Method

```java
/**
 * Recursively build template node (v2.0 - Simplified)
 * Use template_code to find children, but don't pass it to VO
 *
 * @param template current template node
 * @param parentChildMap parent-child relationship map (key=parent_template_code)
 * @param benchmarkDO benchmark main table data
 * @return built response VO
 */
private BenchmarkDetailsRespVo buildTemplateNodeRecursive(
        BenchmarkDetailsTemplateDO template,
        Map<String, List<BenchmarkDetailsTemplateDO>> parentChildMap,
        BenchmarkDO benchmarkDO) {

    // 1. Build current node
    BenchmarkDetailsRespVo vo = new BenchmarkDetailsRespVo();

    // IMPORTANT: Template data does not set id, backend generates on save
    vo.setId(null);

    vo.setAssetsClassification(template.getAssetClassification());

    // IMPORTANT: Default weight is 0, filled by user in frontend
    vo.setWeight("0.00");

    vo.setAssetLevel(template.getAssetLevel());
    vo.setProcessInstanceId(benchmarkDO.getProcessInstanceId());
    vo.setRecordVersion("0");

    // 2. Recursively process child nodes (find children by current template_code)
    List<BenchmarkDetailsTemplateDO> childTemplates = parentChildMap.get(template.getTemplateCode());
    if (childTemplates != null && !childTemplates.isEmpty()) {
        List<BenchmarkDetailsRespVo> children = new ArrayList<>();

        // Sort by sort_order
        childTemplates.sort(Comparator.comparing(BenchmarkDetailsTemplateDO::getSortOrder));

        for (BenchmarkDetailsTemplateDO childTemplate : childTemplates) {
            BenchmarkDetailsRespVo childVo = buildTemplateNodeRecursive(
                childTemplate,
                parentChildMap,
                benchmarkDO
            );
            children.add(childVo);
        }

        vo.setChildren(children);
    }

    return vo;
}
```

#### 3.6 Modify updateBenchmark() Method (Auto-detect Insert/Update)

```java
/**
 * Update benchmark and its details data
 * Automatically determines whether to insert or update
 *
 * @param updateReqVO update request VO
 */
@Override
@Transactional(rollbackFor = Exception.class)
public void updateBenchmark(BenchmarkUpdateReqVo updateReqVO) {
    String benchmarkId = updateReqVO.getId();

    // 1. Update benchmark main table
    BenchmarkDO benchmarkDO = benchmarkMapper.selectById(benchmarkId);
    if (benchmarkDO == null) {
        throw new BusinessException("Benchmark not found: " + benchmarkId);
    }

    // Update main table fields (based on actual business needs)
    // benchmarkDO.setXxx(updateReqVO.getXxx());
    benchmarkMapper.updateById(benchmarkDO);

    // 2. Query existing benchmark_details data
    List<BenchmarkDetailsDo> existingDetails = benchmarkDetailsMapper.selectList(
        new LambdaQueryWrapper<BenchmarkDetailsDo>()
            .eq(BenchmarkDetailsDo::getBenchmarkId, benchmarkId)
    );

    // 3. Determine whether to insert or update
    if (existingDetails == null || existingDetails.isEmpty()) {
        // First save - perform INSERT operation
        log.info("First time save - performing INSERT operation for benchmark: {}", benchmarkId);
        insertBenchmarkDetailsFromTemplate(updateReqVO.getChildren(), benchmarkDO);
    } else {
        // Subsequent save - perform UPDATE operation
        log.info("Subsequent save - performing UPDATE operation for benchmark: {}", benchmarkId);
        updateBenchmarkDetails(updateReqVO.getChildren(), benchmarkDO, existingDetails);
    }

    log.info("Benchmark updated successfully: {}", benchmarkId);
}
```

#### 3.7 Add insertBenchmarkDetailsFromTemplate() Method

```java
/**
 * First save - insert benchmark_details from template data (v2.0 - Simplified)
 * Key: Use recursive parentId parameter to establish parent-child relationships
 *
 * @param reqVos frontend submitted data (including user-filled weights)
 * @param benchmarkDO benchmark main table data
 */
private void insertBenchmarkDetailsFromTemplate(
        List<BenchmarkDetailsReqVo> reqVos,
        BenchmarkDO benchmarkDO) {

    if (reqVos == null || reqVos.isEmpty()) {
        log.warn("No details to insert for benchmark: {}", benchmarkDO.getId());
        return;
    }

    log.info("Inserting {} detail records for benchmark: {}", reqVos.size(), benchmarkDO.getId());

    // Use recursive insert (supports multi-level tree)
    // parentId is null for root level nodes
    insertBenchmarkDetailsRecursive(reqVos, benchmarkDO, null, 1);
}
```

#### 3.8 Add insertBenchmarkDetailsRecursive() Method

```java
/**
 * Recursively insert benchmark_details (v2.0 - Simplified INSERT operation)
 * Key: Directly pass parentId through recursion, no Map needed
 *
 * @param reqVos request VO list
 * @param benchmarkDO benchmark main table
 * @param parentId parent node ID (pass null for root level nodes)
 * @param currentLevel current level (starts from 1)
 */
private void insertBenchmarkDetailsRecursive(
        List<BenchmarkDetailsReqVo> reqVos,
        BenchmarkDO benchmarkDO,
        String parentId,
        int currentLevel) {

    for (BenchmarkDetailsReqVo reqVo : reqVos) {
        // 1. Create current node
        BenchmarkDetailsDo detail = new BenchmarkDetailsDo();

        // Generate new UUID as ID
        String generatedId = IdUtil.fastSimpleUUID();
        detail.setId(generatedId);

        detail.setBusinessId(benchmarkDO.getBusinessId());
        detail.setBenchmarkId(benchmarkDO.getId());
        detail.setParentId(parentId);  // ← Directly use the parentId parameter
        detail.setAssetClassification(reqVo.getAssetsClassification());
        detail.setAssetLevel(currentLevel);

        // Get user-filled weight from frontend
        detail.setWeight(new BigDecimal(reqVo.getWeight()));

        detail.setRecordVersion(0);

        // 2. Insert to database
        benchmarkDetailsMapper.insert(detail);

        log.debug("Inserted detail: id={}, parent_id={}, classification={}, level={}, weight={}",
            detail.getId(),
            detail.getParentId(),
            detail.getAssetClassification(),
            detail.getAssetLevel(),
            detail.getWeight()
        );

        // 3. Recursively process child nodes
        if (reqVo.getChildren() != null && !reqVo.getChildren().isEmpty()) {
            insertBenchmarkDetailsRecursive(
                reqVo.getChildren(),
                benchmarkDO,
                generatedId,  // ← Pass current node's ID as parentId for children
                currentLevel + 1  // Increment level
            );
        }
    }
}
```

#### 3.9 Add updateBenchmarkDetails() Method

```java
/**
 * Subsequent save - update benchmark_details
 *
 * @param reqVos frontend submitted data
 * @param benchmarkDO benchmark main table data
 * @param existingDetails existing detail data
 */
private void updateBenchmarkDetails(
        List<BenchmarkDetailsReqVo> reqVos,
        BenchmarkDO benchmarkDO,
        List<BenchmarkDetailsDo> existingDetails) {

    if (reqVos == null || reqVos.isEmpty()) {
        log.warn("No details to update for benchmark: {}", benchmarkDO.getId());
        return;
    }

    log.info("Updating {} detail records for benchmark: {}", reqVos.size(), benchmarkDO.getId());

    // Build ID -> DetailsDO map (for quick lookup)
    Map<String, BenchmarkDetailsDo> existingMap = existingDetails.stream()
        .collect(Collectors.toMap(BenchmarkDetailsDo::getId, d -> d));

    // Recursively update
    updateBenchmarkDetailsRecursive(reqVos, benchmarkDO, existingMap);
}
```

#### 3.10 Add updateBenchmarkDetailsRecursive() Method

```java
/**
 * Recursively update benchmark_details
 *
 * @param reqVos request VO list
 * @param benchmarkDO benchmark main table
 * @param existingMap existing data map (key=id, value=DetailsDO)
 */
private void updateBenchmarkDetailsRecursive(
        List<BenchmarkDetailsReqVo> reqVos,
        BenchmarkDO benchmarkDO,
        Map<String, BenchmarkDetailsDo> existingMap) {

    for (BenchmarkDetailsReqVo reqVo : reqVos) {
        // 1. Find existing record by id
        BenchmarkDetailsDo existingDetail = existingMap.get(reqVo.getId());

        if (existingDetail != null) {
            // Exists, update it
            existingDetail.setWeight(new BigDecimal(reqVo.getWeight()));
            existingDetail.setRecordVersion(existingDetail.getRecordVersion() + 1);

            benchmarkDetailsMapper.updateById(existingDetail);

            log.debug("Updated detail: id={}, classification={}, weight={}, version={}",
                existingDetail.getId(),
                existingDetail.getAssetClassification(),
                existingDetail.getWeight(),
                existingDetail.getRecordVersion()
            );
        } else {
            // Does not exist, skip or throw error (should not happen normally)
            log.warn("Detail not found for update: id={}, classification={}",
                reqVo.getId(),
                reqVo.getAssetsClassification()
            );
        }

        // 2. Recursively process child nodes
        if (reqVo.getChildren() != null && !reqVo.getChildren().isEmpty()) {
            updateBenchmarkDetailsRecursive(reqVo.getChildren(), benchmarkDO, existingMap);
        }
    }
}
```

---

## Frontend Implementation

### 1. Modify Data Processing Logic (detail/index.vue)

**Location**: `poc-pro-ui/src/views/benchmark/detail/index.vue`

#### 1.1 Process Template Data (v2.0 - Simplified)

```javascript
/**
 * Process tree data returned from backend (v2.0 - Simplified)
 * Supports template data (id is null) and real data (id has value)
 * Note: Hierarchy is maintained by children array, no need for templateCode
 */
const processTreeData = (detailsList) => {
  if (!detailsList || detailsList.length === 0) {
    Treedata.value = []
    return
  }

  const rootNode = {
    id: 'root',
    label: 'All Assets',
    weight: 100.00,
    children: [],
    isRoot: true,
    level: 0
  }

  /**
   * Recursively process node
   * @param {Object} node - node data
   * @param {Number} level - level (starts from 1)
   * @returns {Object} processed tree node
   */
  const processNode = (node, level) => {
    // If id is empty or null, it's template data, generate temp ID
    const isTemplate = !node.id
    const tempId = node.id || `temp-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`

    const treeNode = {
      id: tempId,                      // Temp ID or real ID (for display only)
      originalId: node.id,             // Save original ID (may be null)
      label: node.assetsClassification,
      weight: parseFloat(node.weight || 0),
      recordVersion: node.recordVersion || '0',
      assetLevel: node.assetLevel,
      children: [],                    // ← Hierarchy maintained here
      level: level,
      isTemplate: isTemplate           // Mark if it's template data
    }

    // Recursively process child nodes
    if (node.children && node.children.length > 0) {
      node.children.forEach(child => {
        treeNode.children.push(processNode(child, level + 1))
      })
    }

    return treeNode
  }

  // Process all level 1 nodes
  detailsList.forEach(detail => {
    rootNode.children.push(processNode(detail, 1))
  })

  Treedata.value = [rootNode]

  // If template data, notify user
  const hasTemplate = detailsList.some(d => !d.id)
  if (hasTemplate) {
    console.log('[Benchmark] Loaded template data, please fill in weights and save')
  }
}
```

#### 1.2 Modify Save Data Building Logic (v2.0 - Simplified)

```javascript
/**
 * Build save data (v2.0 - Simplified)
 * Handle template data (originalId is null) and real data
 * Note: No need for templateCode, backend uses children array structure
 */
const buildSaveData = (nodes) => {
  return nodes.map(node => {
    const data = {
      // Use originalId (template data is null, real data has value)
      id: node.originalId || null,
      assetsClassification: node.label,
      weight: node.weight.toString(),
      recordVersion: node.recordVersion || '0',
      assetLevel: node.assetLevel
    }

    // Recursively process child nodes
    // Backend will use children array structure to establish parent-child relationships
    if (node.children && node.children.length > 0) {
      data.children = buildSaveData(node.children)
    }

    return data
  })
}
```

#### 1.3 Modify Save Method

```javascript
/**
 * Save benchmark data
 * First save will insert detail data, subsequent saves will update
 */
const saveBenchmark = async () => {
  submitting.value = true

  try {
    // 1. Build save data
    const saveData = {
      id: benchmarkId.value,
      children: buildSaveData(Treedata.value[0].children)
    }

    console.log('[Benchmark] Saving data:', saveData)

    // 2. Call save API
    await BenchmarkApi.updateBenchmark(saveData)

    ElMessage.success('Save successful')

    // 3. Reload data after save (get backend-generated real IDs)
    await loadBenchmarkData()

    console.log('[Benchmark] Data reloaded after save')

  } catch (error) {
    console.error('[Benchmark] Save failed:', error)
    ElMessage.error('Save failed: ' + (error.message || 'Unknown error'))
  } finally {
    submitting.value = false
  }
}
```

---

## Complete Process Flow

### 4.1 First Visit Flow (Initialization)

```
User Action            Backend Processing                     Data State
──────────────────     ──────────────────────────────────     ─────────────────
1. Visit detail page
   GET /benchmark/{id}
                    →  Query benchmark main table             benchmark table has data
                    →  Query benchmark_details table          X table is empty
                    →  Call getDefaultTemplateData()
                    →  Query template from template table
                    →  Build tree structure
                         - id = null
                         - weight = "0.00"
                    →  Return template data
   ←
2. Frontend displays tree
   (id is temp ID)
                                                               Frontend shows template structure
3. User fills weights
   (edit leaf nodes)
                                                               User fills: 15.00, 10.00...
4. Click Save button
   POST /benchmark/update
   body: {
     id: "xxx",
     children: [{
       id: null,          ← Template data, id is null
       weight: "15.00",   ← User-filled weight
       ...
     }]
   }
                    →  Query existingDetails
                    →  Found empty → Execute INSERT
                    →  Call insertBenchmarkDetailsRecursive()
                    →  Generate real UUID
                    →  Insert to database                     √ Insert success
   ←  Return success

5. Frontend reload
   GET /benchmark/{id}
                    →  Query benchmark_details table          √ table has data
                    →  Build tree structure (with real IDs)
                    →  Return real data
   ←
6. Frontend display
   (id is real UUID)
                                                               Show real data and IDs
```

### 4.2 Second Visit Flow (Update)

```
User Action            Backend Processing                     Data State
──────────────────     ──────────────────────────────────     ─────────────────
1. Visit detail page
   GET /benchmark/{id}
                    →  Query benchmark_details table          √ table has data
                    →  Call buildDynamicTree()
                    →  Return real data
   ←
2. Frontend display
   (with real ID and weight)
                                                               Show saved data
3. User modifies weight
   (15.00 → 18.00)
                                                               User modifies weight
4. Click Save button
   POST /benchmark/update
   body: {
     id: "xxx",
     children: [{
       id: "real-uuid-001",  ← Real ID
       weight: "18.00",      ← Modified weight
       recordVersion: "0",
       ...
     }]
   }
                    →  Query existingDetails
                    →  Found data → Execute UPDATE
                    →  Call updateBenchmarkDetailsRecursive()
                    →  Find record by id
                    →  Update weight and recordVersion        √ Update success
   ←  Return success

5. Frontend reload
   (optional, already has latest data)
                                                               Show updated data
```

---

## Key Points

### 5.1 Template Code Mechanism (⭐ Core Design - Simplified)

**Problem**: Template table cannot use fixed UUID because multiple benchmark types (Private Bank, Retail Bank) would conflict.

**Solution**: Use `template_code` as business identifier in template table **only**. VO classes don't need it.

| Field | Template Table (DO) | Query Response (VO) | Frontend Display | Save Request (VO) | Real Data (After Save) |
|-------|---------------------|---------------------|------------------|-------------------|------------------------|
| `id` | Auto-generated UUID | `null` | Temp ID | `null` | Generated UUID |
| `template_code` | Business code (e.g., `PB_FI`) | ❌ Not included | ❌ Not needed | ❌ Not needed | ❌ Not needed |
| `parent_template_code` | Parent's code | ❌ Not included | ❌ Not needed | ❌ Not needed | ❌ Not needed |
| `children` | ❌ Not in table | ✅ Included | ✅ Used for hierarchy | ✅ Used for save | ❌ Not in table |
| `parent_id` | ❌ Not in template | ❌ Not in response | ❌ Not needed | ❌ Not needed | ✅ Generated UUID |

**Simplified Workflow**:
1. **Query Template**: Backend uses `parent_template_code` to build `children` array, returns VO with `id=null, children=[...]`
2. **Frontend Display**: Frontend generates temp IDs for display, uses `children` array for hierarchy
3. **First Save**: Frontend sends `id=null, children=[...]`, backend recursively processes children
4. **Parent Relationship**: Backend passes `parentId` parameter through recursion: `insert(child, currentNodeId)`
5. **Second Save**: Use real UUIDs with children array

### 5.2 Template Data Characteristics

| Field | Template Data | Real Data |
|-------|--------------|-----------|
| `id` | `null` | Real UUID (e.g., `a1b2c3d4-5678-...`) |
| `weight` | `"0.00"` | User-filled value (e.g., `"15.00"`) |
| `recordVersion` | `"0"` | Incremented version (e.g., `"0"`, `"1"`, `"2"`) |
| `children` | Array (may be empty) | Array (may be empty) |

### 5.3 Insert/Update Decision Logic

**Backend logic**:
```java
// Query existing data
List<BenchmarkDetailsDo> existingDetails = benchmarkDetailsMapper.selectList(...);

if (existingDetails == null || existingDetails.isEmpty()) {
    // INSERT operation
    insertBenchmarkDetailsFromTemplate(...);
} else {
    // UPDATE operation
    updateBenchmarkDetails(...);
}
```

**Decision basis**: Query `benchmark_details` table, if empty then INSERT, otherwise UPDATE

### 5.4 Frontend Data Processing Key Points

**Handle template data (v2.0 - Simplified, id is null)**:
```javascript
const isTemplate = !node.id
const tempId = node.id || `temp-${Date.now()}-${Math.random()}`

const treeNode = {
  id: tempId,                 // ID for frontend display (temp or real)
  originalId: node.id,        // ID to pass to backend on save (null or real UUID)
  children: [],               // Hierarchy maintained here
  isTemplate: isTemplate
}
```

**Use originalId and children when saving**:
```javascript
const data = {
  id: node.originalId || null,       // Use originalId, not temp ID
  weight: node.weight.toString(),
  children: buildSaveData(node.children)  // Backend uses this for hierarchy
}
```

### 5.5 ID Generation Timing

| Timing | ID Source | Value |
|--------|-----------|-------|
| Query template data | Backend does not set | `null` |
| Frontend display template | Frontend generates temp ID | `temp-1729412345-abc123` |
| First save | Backend generates real UUID | `a1b2c3d4-5678-90ab-cdef-...` |
| Subsequent saves | Use existing ID | Unchanged |

---

## Testing Suggestions

### 6.1 Test Scenarios

#### Scenario 1: First Visit (Template Data)
1. Create a new benchmark (only main table data)
2. Visit detail page
3. **Expected**: Show template tree structure, weight is 0.00
4. Fill weights and save
5. **Expected**: Save success, refresh shows real IDs and weights

#### Scenario 2: Second Visit (Real Data)
1. Visit previously saved benchmark
2. **Expected**: Show real data (including IDs and weights)
3. Modify weights and save
4. **Expected**: Update success, version number increments

#### Scenario 3: Mixed Level Tree
1. Visit data with mixed 2-level and 3-level structure
2. **Expected**: Correctly display mixed levels
3. Only leaf nodes can edit weights
4. Non-leaf node weights auto-calculated

### 6.2 Data Validation

**SQL Validation Scripts**:
```sql
-- 1. Check template table data
SELECT * FROM benchmark_details_template WHERE is_active = 1 ORDER BY sort_order;

-- 2. Check benchmark table
SELECT id, business_id, name, status FROM benchmark WHERE id = 'xxx';

-- 3. Check benchmark_details table (empty before first save)
SELECT * FROM benchmark_details WHERE benchmark_id = 'xxx';

-- 4. Check tree structure relationships
SELECT
    d1.id AS level1_id,
    d1.asset_classification AS level1_name,
    d2.id AS level2_id,
    d2.asset_classification AS level2_name,
    d3.id AS level3_id,
    d3.asset_classification AS level3_name
FROM benchmark_details d1
LEFT JOIN benchmark_details d2 ON d2.parent_id = d1.id
LEFT JOIN benchmark_details d3 ON d3.parent_id = d2.id
WHERE d1.benchmark_id = 'xxx' AND d1.parent_id IS NULL
ORDER BY d1.asset_level, d2.asset_level, d3.asset_level;
```

---

## FAQ

### Q1: Why use template_code instead of fixed UUID in template table?
**A**: Because the system supports multiple benchmark types (Private Bank, Retail Bank). If using fixed UUIDs:
- `PB_FI` and `RB_FI` would need different UUIDs even though they represent same category
- Cannot reuse template structure across types
- Hard to maintain

Using `template_code` + `benchmark_type`:
- Same code can exist for different types (e.g., `PB_FI` and `RB_FI`)
- Easy to maintain and understand
- Dynamic UUID generation avoids conflicts

### Q2: How does parent-child relationship work without parent_id?
**A**: Two stages:

**Template Table (Build tree)**:
```sql
-- Use parent_template_code to build children array
template_code: 'PB_FI_GD'
parent_template_code: 'PB_FI'  -- Links to parent
```

**During Save (Establish real parent_id)**:
```java
// Recursive method passes parentId parameter
insertRecursive(children, benchmarkDO, currentNodeId, level) {
    String generatedId = generateUUID();
    detail.setParentId(currentNodeId);  // Use parameter directly
    insert(detail);

    // Recurse with current ID as parent
    insertRecursive(child.getChildren(), benchmarkDO, generatedId, level+1);
}
```

### Q3: Why not return real ID when querying?
**A**: Because on first visit `benchmark_details` table is empty, cannot return real ID. Template data is just a structure template, not a real record.

### Q4: How does frontend distinguish template data from real data?
**A**: By checking the `id` field:
- `id === null` → Template data
- `id !== null` → Real data (saved)

### Q5: What happens if user leaves without saving?
**A**: No impact, data not inserted to database, `benchmark_details` table remains empty, next visit still shows template data.

### Q6: How to update template structure?
**A**: Directly modify `benchmark_details_template` table data:
```sql
-- Add new template node for Private Bank
INSERT INTO benchmark_details_template
  (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
VALUES
  (NEWID(), N'PB_NEW_ASSET', N'PB_FI', 1, N'New Asset Class', 2, 10, 1);

-- Disable a template node
UPDATE benchmark_details_template SET is_active = 0 WHERE template_code = 'PB_ALT_HF';

-- Modify sort order
UPDATE benchmark_details_template SET sort_order = 10 WHERE template_code = 'PB_EQUITY';
```

### Q7: How to add a new benchmark type (e.g., Corporate Bank)?
**A**:
1. Define new `benchmark_type` value (e.g., `3` for Corporate Bank)
2. Insert template data with new type:
```sql
INSERT INTO benchmark_details_template
  (id, template_code, parent_template_code, benchmark_type, asset_classification, asset_level, sort_order, is_active)
VALUES
  (NEWID(), N'CB_FI', NULL, 3, N'Fixed Income', 1, 1, 1),
  (NEWID(), N'CB_FI_BOND', N'CB_FI', 3, N'Bonds', 2, 1, 1);
```

### Q8: How to handle concurrent saves?
**A**: Use optimistic locking (`record_version`):
```java
// Check version when updating
int rows = benchmarkDetailsMapper.update(
    detail,
    new LambdaUpdateWrapper<BenchmarkDetailsDo>()
        .eq(BenchmarkDetailsDo::getId, detail.getId())
        .eq(BenchmarkDetailsDo::getRecordVersion, oldVersion)
);

if (rows == 0) {
    throw new BusinessException("Data has been modified by another user");
}
```

---

## Summary

### Implementation Points (v2.0 - Simplified)
1. ⭐ **Template Code Design**: Use `template_code` + `parent_template_code` in template table **only**
2. **Multi-Type Support**: Support multiple benchmark types (Private Bank, Retail Bank) with `benchmark_type` field
3. **Children Array**: Use `children` array to maintain tree hierarchy (no need for templateCode in VO)
4. **Simplified Recursion**: Pass `parentId` parameter through recursion (no Map needed)
5. **Auto-detect Query**: Return template if `benchmark_details` is empty
6. **Auto-detect Save**: First save = INSERT, subsequent saves = UPDATE
7. **Dynamic UUID Generation**: Generate UUIDs during save, pass to children
8. **Frontend Handling**: Correctly process template data (`id=null`, use `children` for hierarchy)

### Advantages
- **Flexibility**: Template structure can be configured dynamically, no code changes needed
- **Multi-Type Support**: Same template code can exist for different benchmark types
- **No Conflicts**: Dynamic UUID generation prevents ID conflicts
- **User-friendly**: Auto-initialize structure, users only fill weights
- **Smart**: Auto-detect INSERT/UPDATE, users don't need to care
- **Scalable**: Supports arbitrary levels of tree structure
- **Maintainable**: Template codes are human-readable (e.g., `PB_FI_GD_EUR`)

### Key Differences from v1.0
| Aspect | v1.0 (Fixed UUID) | v2.0 (Template Code) |
|--------|------------------|----------------------|
| Template ID | Fixed UUID | Auto-generated UUID |
| Hierarchy | `parent_id` | `parent_template_code` |
| Multi-Type Support | ❌ No | ✅ Yes (via `benchmark_type`) |
| Parent Relationship | Direct UUID reference | Map-based dynamic lookup |
| Conflict Risk | ⚠️ High (UUID conflicts) | ✅ Low (template codes) |

---

**Document Version**: v2.0
**Last Updated**: 2025-10-21
**Maintainer**: Claude Code
