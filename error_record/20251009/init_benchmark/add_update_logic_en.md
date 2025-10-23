# Benchmark Details Insert/Update Logic Design

> **Version**: v3.0 (Hybrid Approach)
> **Date**: 2025-10-22
> **Author**: Claude Code
> **Description**: Hybrid approach with pre-generated UUIDs and isTemplate marker (universal template design)

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

### ⚠️ Design Evolution: v2.0 → v3.0

**v2.0 Problem**:
1. Using `id=null` for template data caused confusion
2. Frontend had to generate temporary IDs for display
3. Complex logic to track originalId vs display ID

**v3.0 Solution (Hybrid Approach)**:
1. Use **`componentId`** as business identifier in grouping table (e.g., `FI_GD`, `EQUITY_DM`)
2. Use **`parentComponentId`** to establish hierarchy (independent of UUIDs)
3. **Pre-generate UUIDs** during query, use same UUIDs for insert
4. Use **`isTemplate`** field to distinguish template from real data
5. **Universal template**: Removed `benchmark_type`, all benchmarks use same grouping structure

### 1. Create Grouping Table

**Table Name**: `benchmark_grouping`

**Purpose**: Store universal grouping template structure (used by all benchmark types)

```sql
-- benchmark_grouping table (v3.0 - Universal Template)
CREATE TABLE benchmark_grouping (
    id nvarchar(64) NOT NULL PRIMARY KEY,           -- Auto-generated primary key (UUID)
    componentId nvarchar(64) NOT NULL,              -- Component ID (business identifier, e.g., FI_GD, EQUITY_DM)
    parentComponentId nvarchar(64) DEFAULT NULL,    -- Parent Component ID (NULL for root nodes)
    componentName nvarchar(64) DEFAULT NULL,        -- Component Name (display name)
    description nvarchar(128) NOT NULL,             -- Description (asset classification name)
    asset_level tinyint NOT NULL,                   -- Asset Level (1,2,3...)
    sort_order int DEFAULT 0 NULL,                  -- Sort Order
    CONSTRAINT UK_componentId UNIQUE (componentId)  -- Unique component ID
)
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Primary Key ID (auto-generated UUID)',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_grouping',
    'COLUMN', N'id'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Component ID (business identifier, e.g., FI, FI_GD, FI_GD_EUR)',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_grouping',
    'COLUMN', N'componentId'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Parent Component ID (NULL for root nodes)',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_grouping',
    'COLUMN', N'parentComponentId'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Component Name (display name)',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_grouping',
    'COLUMN', N'componentName'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Description (asset classification description)',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_grouping',
    'COLUMN', N'description'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Asset Level (1,2,3...)',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_grouping',
    'COLUMN', N'asset_level'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Sort Order',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_grouping',
    'COLUMN', N'sort_order'
GO

EXEC sp_addextendedproperty
    'MS_Description', N'Benchmark grouping table (universal template for all benchmarks)',
    'SCHEMA', N'dbo',
    'TABLE', N'benchmark_grouping'
GO
```

### 2. Component ID Naming Convention (v3.0)

**Format**: `{Category}_{SubCategory}_{Detail}` (without type prefix, universal for all benchmarks)

**Examples**:
- **Level 1**:
  - `FI` (Fixed Income)
  - `EQUITY` (Equity)
  - `ALT` (Alternatives)

- **Level 2**:
  - `FI_GD` (Fixed Income > Government Debt)
  - `FI_CD` (Fixed Income > Corporate Debt)
  - `EQUITY_DM` (Equity > Developed Markets)
  - `EQUITY_EM` (Equity > Emerging Markets)

- **Level 3**:
  - `FI_GD_EUR` (Fixed Income > Government Debt > EUR Bonds)
  - `FI_GD_NEUR` (Fixed Income > Government Debt > Non-EUR Bonds)
  - `EQUITY_DM_EU` (Equity > Developed Markets > Europe)

**Benefits**:
- Human-readable and concise
- Universal template works for all benchmark types
- Easy to maintain and debug
- No type prefix needed (simplified from v2.0)

### 3. Insert Template Data (v3.0 - Universal Template)

**Note**: ID is auto-generated UUID, hierarchy is established by parentComponentId

```sql
-- ====================================================================
-- Insert benchmark_grouping data (v3.0 - Universal Template)
-- Mixed 2-level and 3-level hierarchy
-- ====================================================================

-- Level 1: Fixed Income
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'FI', NULL, N'Fixed Income', N'Fixed Income', 1, 1);

    -- Level 2: Government Debt (has level 3 children)
    INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
    VALUES (NEWID(), N'FI_GD', N'FI', N'Government Debt', N'Government Debt', 2, 1);

        -- Level 3: EUR Government Bonds
        INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
        VALUES (NEWID(), N'FI_GD_EUR', N'FI_GD', N'EUR Bonds', N'EUR Government Bonds', 3, 1);

        -- Level 3: Non-EUR Government Bonds
        INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
        VALUES (NEWID(), N'FI_GD_NEUR', N'FI_GD', N'Non-EUR Bonds', N'Non-EUR Government Bonds', 3, 2);

    -- Level 2: Corporate Debt (leaf node, no level 3 children)
    INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
    VALUES (NEWID(), N'FI_CD', N'FI', N'Corporate Debt', N'Corporate Debt', 2, 2);

-- Level 1: Equity
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'EQUITY', NULL, N'Equity', N'Equity', 1, 2);

    -- Level 2: Developed Markets (has level 3 children)
    INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
    VALUES (NEWID(), N'EQUITY_DM', N'EQUITY', N'Developed Markets', N'Developed Markets', 2, 1);

        -- Level 3: Europe Equity
        INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
        VALUES (NEWID(), N'EQUITY_DM_EU', N'EQUITY_DM', N'Europe', N'Europe Equity', 3, 1);

        -- Level 3: North America Equity
        INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
        VALUES (NEWID(), N'EQUITY_DM_NA', N'EQUITY_DM', N'North America', N'North America Equity', 3, 2);

    -- Level 2: Emerging Markets (leaf node, no level 3 children)
    INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
    VALUES (NEWID(), N'EQUITY_EM', N'EQUITY', N'Emerging Markets', N'Emerging Markets', 2, 2);

-- Level 1: Alternatives
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'ALT', NULL, N'Alternatives', N'Alternatives', 1, 3);

    -- Level 2: Hedge Funds (leaf node, no level 3 children)
    INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
    VALUES (NEWID(), N'ALT_HF', N'ALT', N'Hedge Funds', N'Hedge Funds', 2, 1);
```

### 4. Template Data Tree Structure (v3.0 - Universal Template)

**All Benchmarks (Universal Structure)**:
```
FI (Fixed Income)
├─ FI_GD (Government Debt) [has children]
│  ├─ FI_GD_EUR (EUR Government Bonds)
│  └─ FI_GD_NEUR (Non-EUR Government Bonds)
└─ FI_CD (Corporate Debt) [leaf]

EQUITY (Equity)
├─ EQUITY_DM (Developed Markets) [has children]
│  ├─ EQUITY_DM_EU (Europe Equity)
│  └─ EQUITY_DM_NA (North America Equity)
└─ EQUITY_EM (Emerging Markets) [leaf]

ALT (Alternatives)
└─ ALT_HF (Hedge Funds) [leaf]
```

**Note**: In v3.0, all benchmarks use the same universal template structure. Users can customize by setting weights to 0 for unused categories.

---

## Backend Implementation

### 1. Create Template Table Entity and Mapper

#### 1.1 BenchmarkGroupingDO.java

**Path**: `pap-server/src/main/java/cn/bochk/pap/server/business/dal/BenchmarkGroupingDO.java`

```java
package cn.bochk.pap.server.business.dal;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * benchmark_grouping table entity (v3.0)
 * Store grouping template structure (universal template for all benchmark types)
 */
@Data
@TableName("benchmark_grouping")
public class BenchmarkGroupingDO {

    /**
     * Primary Key ID (auto-generated UUID)
     */
    private String id;

    /**
     * Component ID (business identifier, e.g., FI, FI_GD, FI_GD_EUR)
     */
    private String componentId;

    /**
     * Parent Component ID (NULL means root node)
     */
    private String parentComponentId;

    /**
     * Component Name (display name)
     */
    private String componentName;

    /**
     * Description (asset classification description)
     */
    private String description;

    /**
     * Asset Level (1,2,3...)
     */
    private Integer assetLevel;

    /**
     * Sort Order
     */
    private Integer sortOrder;
}
```

#### 1.2 BenchmarkGroupingMapper.java

**Path**: `pap-server/src/main/java/cn/bochk/pap/server/business/mapper/BenchmarkGroupingMapper.java`

```java
package cn.bochk.pap.server.business.mapper;

import cn.bochk.pap.server.business.dal.BenchmarkGroupingDO;
import cn.bochk.pap.framework.common.mybatis.mybatis.core.mapper.BaseMapperX;
import cn.bochk.pap.framework.common.mybatis.mybatis.core.query.LambdaQueryWrapperX;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * benchmark_grouping Mapper (v3.0)
 */
@Mapper
public interface BenchmarkGroupingMapper extends BaseMapperX<BenchmarkGroupingDO> {

    /**
     * Query all grouping templates
     * Ordered by sort_order
     *
     * @return template list
     */
    default List<BenchmarkGroupingDO> selectList() {
        return selectList(new LambdaQueryWrapperX<BenchmarkGroupingDO>()
                .orderByAsc(BenchmarkGroupingDO::getSortOrder));
    }
}
```

### 2. Modify VO Classes

#### 2.1 Modify BenchmarkDetailsRespVo

**Path**: `pap-server/src/main/java/cn/bochk/pap/server/business/controller/vo/response/BenchmarkDetailsRespVo.java`

```java
/**
 * Benchmark details response VO (v3.0 - Hybrid Approach)
 * Support both template data (with pre-generated UUID) and real data
 */
@Data
public class BenchmarkDetailsRespVo {
    private String id;  // Pre-generated UUID for template data, real UUID for saved data
    private String assetsClassification;
    private String weight;
    private String processInstanceId;
    private String recordVersion;

    // NEW: Mark if this is template data
    private Boolean isTemplate;  // true = template data, false/null = real saved data

    private List<BenchmarkDetailsRespVo> children;  // ← Hierarchy maintained here
}
```

#### 2.2 Modify BenchmarkDetailsReqVo

**Path**: `pap-server/src/main/java/cn/bochk/pap/server/business/controller/vo/request/BenchmarkDetailsReqVo.java`

```java
/**
 * Benchmark details request VO (v4.0 - Query-based Approach)
 * Backend determines initialization by querying benchmark_details table
 */
@Data
public class BenchmarkDetailsReqVo {
    private String id;
    private String benchmarkId;  // Benchmark main table ID (required for query)
    private String assetClassification;
    private String weight;
    private String recordVersion;

    private List<BenchmarkDetailsReqVo> children;  // ← Hierarchy maintained here
}
```

### 3. Modify BenchmarkServiceImpl.java

**Path**: `pap-server/src/main/java/cn/bochk/pap/server/business/service/Impl/BenchmarkServiceImpl.java`

#### 3.1 Add Dependency Injection

```java
import cn.bochk.pap.server.business.dal.BenchmarkGroupingDO;
import cn.bochk.pap.server.business.mapper.BenchmarkGroupingMapper;
import cn.hutool.core.util.IdUtil;

@Service
@Slf4j
public class BenchmarkServiceImpl implements BenchmarkService {

    @Autowired
    private BenchmarkMapper benchmarkMapper;

    @Autowired
    private BenchmarkDetailsMapper benchmarkDetailsMapper;

    // NEW: Inject grouping table Mapper (v3.0)
    @Autowired
    private BenchmarkGroupingMapper benchmarkGroupingMapper;

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
 * Get default template data (called when benchmark_details is empty) (v3.0)
 * Query from benchmark_grouping table and pre-generate UUIDs
 *
 * @param benchmarkDO benchmark main table data
 * @return tree structure of template data with pre-generated UUIDs
 */
private List<BenchmarkDetailsRespVo> getDefaultTemplateData(BenchmarkDO benchmarkDO) {
    // 1. Query all grouping templates
    List<BenchmarkGroupingDO> templates = benchmarkGroupingMapper.selectList();

    if (templates == null || templates.isEmpty()) {
        log.warn("No grouping templates found in benchmark_grouping table");
        return new ArrayList<>();
    }

    log.info("Loaded {} template records from benchmark_grouping", templates.size());

    // 2. Convert template data to tree structure with pre-generated UUIDs
    return buildTreeFromTemplate(templates, benchmarkDO);
}
```

#### 3.4 Add buildTreeFromTemplate() Method

```java
/**
 * Build tree structure from template data (v3.0 - Hybrid Approach)
 * Use componentId and parentComponentId to establish hierarchy
 * Pre-generate UUIDs for all nodes
 *
 * @param templates template data list
 * @param benchmarkDO benchmark main table data
 * @return tree structure list
 */
private List<BenchmarkDetailsRespVo> buildTreeFromTemplate(
        List<BenchmarkGroupingDO> templates,
        BenchmarkDO benchmarkDO) {

    List<BenchmarkDetailsRespVo> result = new ArrayList<>();

    // Create Map to store componentId -> UUID mapping
    Map<String, String> componentIdToUuidMap = new HashMap<>();

    // 1. Group by parentComponentId (Map<parentComponentId, List<children>>)
    Map<String, List<BenchmarkGroupingDO>> parentChildMap = templates.stream()
        .filter(t -> t.getParentComponentId() != null)  // Exclude root nodes
        .collect(Collectors.groupingBy(BenchmarkGroupingDO::getParentComponentId));

    // 2. Find all root nodes (parentComponentId == null)
    List<BenchmarkGroupingDO> rootNodes = templates.stream()
        .filter(t -> t.getParentComponentId() == null)
        .sorted(Comparator.comparing(BenchmarkGroupingDO::getSortOrder))
        .collect(Collectors.toList());

    log.info("Found {} root nodes in template", rootNodes.size());

    // 3. Recursively build each root node and its subtree
    for (BenchmarkGroupingDO rootNode : rootNodes) {
        BenchmarkDetailsRespVo rootVo = buildTemplateNodeRecursive(
            rootNode,
            parentChildMap,
            componentIdToUuidMap,
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
 * Recursively build template node (v3.0 - Hybrid Approach with pre-generated UUID)
 * Pre-generate UUID and establish id/parent_id relationships
 *
 * @param template current template node
 * @param parentChildMap parent-child relationship map (key=componentId)
 * @param componentIdToUuidMap Map storing componentId -> pre-generated UUID
 * @param benchmarkDO benchmark main table data
 * @return built response VO
 */
private BenchmarkDetailsRespVo buildTemplateNodeRecursive(
        BenchmarkGroupingDO template,
        Map<String, List<BenchmarkGroupingDO>> parentChildMap,
        Map<String, String> componentIdToUuidMap,
        BenchmarkDO benchmarkDO) {

    // 1. Build current node
    BenchmarkDetailsRespVo vo = new BenchmarkDetailsRespVo();

    // IMPORTANT: Pre-generate UUID for template data
    String generatedId = IdUtil.fastSimpleUUID();
    vo.setId(generatedId);

    // Store mapping: componentId -> UUID (for building parent_id relationships)
    componentIdToUuidMap.put(template.getComponentId(), generatedId);

    vo.setAssetsClassification(template.getDescription());

    // IMPORTANT: Default weight is 0, filled by user in frontend
    vo.setWeight("0.00");

    vo.setProcessInstanceId(benchmarkDO.getProcessInstanceId());
    vo.setRecordVersion("0");

    // IMPORTANT: Mark this as template data
    vo.setIsTemplate(true);

    // 2. Recursively process child nodes (find children by current componentId)
    List<BenchmarkGroupingDO> childTemplates = parentChildMap.get(template.getComponentId());
    if (childTemplates != null && !childTemplates.isEmpty()) {
        List<BenchmarkDetailsRespVo> children = new ArrayList<>();

        // Sort by sort_order
        childTemplates.sort(Comparator.comparing(BenchmarkGroupingDO::getSortOrder));

        for (BenchmarkGroupingDO childTemplate : childTemplates) {
            BenchmarkDetailsRespVo childVo = buildTemplateNodeRecursive(
                childTemplate,
                parentChildMap,
                componentIdToUuidMap,
                benchmarkDO
            );
            children.add(childVo);
        }

        vo.setChildren(children);
    }

    return vo;
}
```

#### 3.6 Modify updateBenchmark() Method (v4.0 - Query-based)

```java
/**
 * Update benchmark and its details data
 * Determines initialization by querying benchmark_details table
 *
 * @param updateReqVO update request VO
 */
@Override
@Transactional(rollbackFor = Exception.class)
public void updateBenchmark(List<BenchmarkDetailsReqVo> updateReqVO) {
    if (updateReqVO == null || CollUtil.isEmpty(updateReqVO)) {
        throw new ServerException(400, "updateRequestion is null");
    }

    try {
        // 1. Validate root weights sum to 100
        validateRootWeights(updateReqVO);

        // 2. Get benchmarkId
        String benchmarkId = updateReqVO.get(0).getBenchmarkId();
        if (benchmarkId == null || benchmarkId.isEmpty()) {
            throw new ServerException(400, "benchmarkId cannot be null");
        }

        // 3. Query detail table to determine if this is initialization
        List<BenchmarkDetailsDo> existingDetails = benchmarkDetailsMapper.selectList(
            new LambdaQueryWrapperX<BenchmarkDetailsDo>()
                .eq(BenchmarkDetailsDo::getBenchmarkId, benchmarkId)
        );

        if (existingDetails == null || existingDetails.isEmpty()) {
            // Case 1: Initialization
            log.info("Initialization save, benchmarkId: {}", benchmarkId);
            handleFirstSave(benchmarkId, updateReqVO);
        } else {
            // Case 2: Non-initialization save
            log.info("Non-initialization save, benchmarkId: {}", benchmarkId);
            handleSubsequentSave(benchmarkId, updateReqVO);
        }

    } catch (Exception e) {
        log.error("Update Benchmark error: ", e);
        throw new ServerException(500, "Update Benchmark failed: " + e.getMessage());
    }
}
```

#### 3.7 Add validateRootWeights() Method

```java
/**
 * Validate root node weights sum to 100
 */
private void validateRootWeights(List<BenchmarkDetailsReqVo> updateReqVO) {
    double totalWeight = updateReqVO.stream()
        .filter(vo -> vo.getWeight() != null && !vo.getWeight().isEmpty())
        .mapToDouble(vo -> new BigDecimal(vo.getWeight())
            .setScale(2, RoundingMode.HALF_UP)
            .doubleValue())
        .sum();

    if (Math.abs(totalWeight - 100.0) > 0.01) {  // Allow 0.01 error margin
        throw new ServerException(400, "Root weights must sum to 100");
    }
}
```

#### 3.8 Add handleFirstSave() Method (Initialization)

```java
/**
 * Handle first save (initialization)
 *
 * @param benchmarkId benchmark ID
 * @param updateReqVO request data
 */
private void handleFirstSave(String benchmarkId, List<BenchmarkDetailsReqVo> updateReqVO) {
    // 1. Get benchmark record
    BenchmarkDO benchmarkDO = benchmarkMapper.selectById(benchmarkId);
    if (benchmarkDO == null) {
        throw new ServerException(400, "Benchmark does not exist: " + benchmarkId);
    }

    // 2. UPDATE benchmark table to initial state
    benchmarkDO.setRecordVersion(0);  // Force set to 0
    benchmarkDO.setDelFlag(0);
    benchmarkDO.setMaker(getLoginUserNickname());
    benchmarkDO.setMakerDatetime(LocalDateTime.now());
    benchmarkMapper.updateById(benchmarkDO);

    // 3. Recursively INSERT all details (record_version=0)
    insertBenchmarkDetailsRecursive(updateReqVO, benchmarkDO, null, 1);

    // 4. Start BPM process
    Map<String, Object> processInstanceVariables = new HashMap<>();
    startProcess(benchmarkId, processInstanceVariables);

    // 5. Send notification
    sendNotification();
}
```

#### 3.9 Add handleSubsequentSave() Method (Non-initialization)

```java
/**
 * Handle subsequent save (non-initialization)
 *
 * @param benchmarkId benchmark ID
 * @param updateReqVO request data
 */
private void handleSubsequentSave(String benchmarkId, List<BenchmarkDetailsReqVo> updateReqVO) {
    // 1. Get old benchmark record
    BenchmarkDO oldBenchmark = benchmarkMapper.selectById(benchmarkId);
    if (oldBenchmark == null) {
        throw new ServerException(400, "Benchmark does not exist: " + benchmarkId);
    }

    // 2. Validate version
    validateRecordVersion(updateReqVO.get(0), oldBenchmark);

    // 3. Version management: mark old record + INSERT new record
    BenchmarkDO newBenchmark = createNewBenchmarkVersion(oldBenchmark);

    // 4. Recursively INSERT new version details (old data remains unchanged)
    insertBenchmarkDetailsRecursive(updateReqVO, newBenchmark, null, 1);

    // 5. Start BPM process
    Map<String, Object> processInstanceVariables = new HashMap<>();
    startProcess(newBenchmark.getId(), processInstanceVariables);

    // 6. Send notification
    sendNotification();
}
```

#### 3.10 Add insertBenchmarkDetailsRecursive() Method

```java
/**
 * Recursively insert benchmark_details (v3.0 - Version Management)
 * IMPORTANT: Always INSERT, never UPDATE (creates new version each time)
 * For first save: Use pre-generated UUID from template
 * For Nth save: Generate new UUID for new version
 *
 * @param reqVos request VO list
 * @param newBenchmark new version of benchmark main table
 * @param parentId parent node ID (pass null for root level nodes)
 * @param currentLevel current level (starts from 1)
 */
private void insertBenchmarkDetailsRecursive(
        List<BenchmarkDetailsReqVo> reqVos,
        BenchmarkDO newBenchmark,
        String parentId,
        int currentLevel) {

    List<BenchmarkDetailsDo> insertDetails = new ArrayList<>();

    for (BenchmarkDetailsReqVo reqVo : reqVos) {
        // 1. Create current node
        BenchmarkDetailsDo detail = new BenchmarkDetailsDo();

        // Generate new UUID for new version
        // (First save uses template UUID, Nth save uses new UUID)
        detail.setId(IdUtils.getUUID());

        detail.setBusinessId(newBenchmark.getBusinessId());
        detail.setBenchmarkId(newBenchmark.getId());  // ← New version benchmark ID
        detail.setParentId(parentId);
        detail.setAssetClassification(reqVo.getAssetClassification());
        detail.setAssetLevel(currentLevel);
        detail.setWeight(new BigDecimal(reqVo.getWeight()));
        detail.setRecordVersion(newBenchmark.getRecordVersion());

        insertDetails.add(detail);

        // 2. Recursively process child nodes
        if (reqVo.getChildren() != null && !reqVo.getChildren().isEmpty()) {
            insertBenchmarkDetailsRecursive(
                reqVo.getChildren(),
                newBenchmark,
                detail.getId(),  // ← Use current node ID as parentId for children
                currentLevel + 1
            );
        }
    }

    // 3. Batch insert current level nodes
    if (!insertDetails.isEmpty()) {
        benchmarkDetailsMapper.insertBatch(insertDetails);
    }
}
```

#### 3.11 Add createNewBenchmarkVersion() Method

```java
/**
 * Create new version benchmark (version management)
 *
 * @param oldBenchmark old version of benchmark
 * @return new version of benchmark
 */
private BenchmarkDO createNewBenchmarkVersion(BenchmarkDO oldBenchmark) {
    // 1. UPDATE old record: mark as deleted
    oldBenchmark.setDelFlag(1);
    oldBenchmark.setValidEndDatetime(LocalDateTime.now());
    benchmarkMapper.updateById(oldBenchmark);

    // 2. INSERT new record
    BenchmarkDO newBenchmark = new BenchmarkDO();
    BeanUtils.copyProperties(oldBenchmark, newBenchmark);
    newBenchmark.setId(IdUtils.getUUID());  // New UUID
    newBenchmark.setDelFlag(0);
    newBenchmark.setRecordVersion(oldBenchmark.getRecordVersion() + 1);  // Version + 1
    newBenchmark.setValidStartDatetime(LocalDateTime.now());
    newBenchmark.setValidEndDatetime(null);
    newBenchmark.setMaker(getLoginUserNickname());
    newBenchmark.setMakerDatetime(LocalDateTime.now());
    benchmarkMapper.insert(newBenchmark);

    return newBenchmark;
}
```

---

## Frontend Implementation

### 1. Modify Data Processing Logic (detail/index.vue)

**Location**: `poc-pro-ui/src/views/benchmark/detail/index.vue`

#### 1.1 Process Template Data (v3.0 - Hybrid Approach with isTemplate)

```javascript
/**
 * Process tree data returned from backend (v3.0 - Hybrid Approach)
 * Supports template data (isTemplate=true with pre-generated UUID) and real data (isTemplate=false)
 * Note: Hierarchy is maintained by children array
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
    // IMPORTANT: Use isTemplate field from backend (not checking id)
    const isTemplate = node.isTemplate === true

    const treeNode = {
      id: node.id,                     // Pre-generated UUID (template) or real UUID (saved)
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
  const hasTemplate = detailsList.some(d => d.isTemplate === true)
  if (hasTemplate) {
    console.log('[Benchmark] Loaded template data, please fill in weights and save')
  }
}
```

#### 1.2 Modify Save Data Building Logic (v3.0 - Version Management)

```javascript
/**
 * Build save data (v3.0 - Version Management)
 * Include benchmarkId and isTemplate to avoid backend NPE
 * Note: Backend uses children array structure to establish parent-child relationships
 */
const buildSaveData = (nodes, benchmarkId) => {
  return nodes.map(node => {
    const data = {
      id: node.id,
      benchmarkId: benchmarkId,         // ✅ Add: needed for first save
      assetClassification: node.label,
      weight: node.weight.toString(),
      recordVersion: node.recordVersion || '0',
      isTemplate: node.isTemplate || false,  // ✅ Add: helps backend avoid NPE
      children: []
    }

    // Recursively process child nodes
    if (node.children && node.children.length > 0) {
      data.children = buildSaveData(node.children, benchmarkId)
    }

    return data
  })
}
```

#### 1.3 Modify Save Method

```javascript
/**
 * Save benchmark data (v3.0 - Version Management)
 * Backend uses version management: always creates new version
 */
const saveBenchmark = async () => {
  submitting.value = true

  try {
    // 1. Build save data (pass benchmarkId)
    const saveData = buildSaveData(
      Treedata.value[0].children,
      currentBenchmarkId.value  // Pass current benchmark ID
    )

    console.log('[Benchmark] Saving data:', saveData)

    // 2. Call save API
    await BenchmarkApi.updateBenchmark(saveData)

    ElMessage.success('Save successful')

    // 3. Reload data after save
    // Note: Backend creates new version, new IDs will be returned
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

### 4.1 First Visit Flow (Initialization) - v3.0 Version Management

```
User Action            Backend Processing                     Data State
──────────────────     ──────────────────────────────────     ─────────────────
1. Visit detail page
   GET /benchmark/{id}
                    →  Query benchmark main table             benchmark v0 exists
                    →  Query benchmark_details table          X table is empty (no v0 details)
                    →  Call getDefaultTemplateData()
                    →  Query from benchmark_grouping table
                    →  Build tree structure
                         - Pre-generate UUID
                         - id = "uuid-001"
                         - isTemplate = true
                         - weight = "0.00"
                    →  Return template data
   ←
2. Frontend displays tree
   (id is pre-generated UUID)
                                                               Frontend shows template + isTemplate=true
3. User fills weights
   (edit leaf nodes)
                                                               User fills: 50.00, 30.00...
4. Click Save button
   POST /benchmark/update
   body: [{
     id: "uuid-001",
     benchmarkId: "benchmark-v0",  ← Current benchmark ID
     weight: "50.00",
     isTemplate: true,             ← Tell backend this is first save
     children: [...]
   }]
                    →  isTemplate=true → Get benchmarkDO from benchmarkId
                    →  UPDATE benchmark v0 to v1 (recordVersion 0→1)
                    →  Recursively INSERT all details (to v1)
                    →  Start BPM process                      √ Insert success
   ←  Return success

5. Frontend reload
   GET /benchmark/{id}
                    →  Query benchmark_details table          √ v1 details exist
                    →  Build tree structure
                         - id = "new-uuid-xxx"  (new version IDs)
                         - isTemplate = false
                    →  Return real data
   ←
6. Frontend display
   (id is new UUID for v1)
                                                               Show v1 data + isTemplate=false
```

### 4.2 Second Visit Flow (Modify Existing Data) - v3.0 Version Management

```
User Action            Backend Processing                     Data State
──────────────────     ──────────────────────────────────     ─────────────────
1. Visit detail page
   GET /benchmark/{id}
                    →  Query benchmark_details table          √ v1 details exist
                    →  Call buildDynamicTree()
                    →  Return real data
                         - id = "uuid-v1-001"
                         - weight = "50.00"
                         - isTemplate = false
                         - recordVersion = "1"
   ←
2. Frontend display
   (with v1 UUID and weight)
                                                               Show v1 data + isTemplate=false
3. User modifies weight
   (50.00 → 55.00)
                                                               User modifies weight
4. Click Save button
   POST /benchmark/update
   body: [{
     id: "uuid-v1-001",
     benchmarkId: "benchmark-v1",  ← Current benchmark ID
     weight: "55.00",               ← Modified weight
     recordVersion: "1",
     isTemplate: false,             ← Tell backend this is modify
     children: [...]
   }]
                    →  isTemplate=false → Query detail to get benchmarkId
                    →  Validate recordVersion
                    →  Mark old details as deleted (v1 details)
                    →  Mark benchmark v1 as deleted + INSERT benchmark v2
                    →  Recursively INSERT all details (to v2, new UUIDs)
                    →  Start BPM process                      √ Insert v2 success
   ←  Return success

5. Frontend reload
   GET /benchmark/{id}
                    →  Query benchmark_details table          √ v2 details exist
                    →  Return v2 data
                         - id = "uuid-v2-001"  (new UUIDs for v2)
                         - weight = "55.00"
                         - recordVersion = "2"
   ←
6. Frontend display
   (id is new v2 UUID)
                                                               Show v2 data
```

---

## Key Points

### 5.1 Hybrid Approach Mechanism (⭐ Core Design - v3.0)

**Problem**: How to distinguish template data from real saved data when both have UUIDs?

**Solution**: Pre-generate UUIDs for template data + use `isTemplate` field to mark template data.

| Field | Grouping Table (DO) | Query Response (VO) | Frontend Display | Save Request (VO) | Real Data (After Save) |
|-------|---------------------|---------------------|------------------|-------------------|------------------------|
| `id` | Auto-generated UUID | Pre-generated UUID | Pre-generated UUID | Pre-generated UUID | New UUID (version management) |
| `benchmarkId` | ❌ Not in table | ❌ Not included | ❌ Not needed | ✅ **Required** | Stored in details table |
| `componentId` | Business code (e.g., `FI_GD`) | ❌ Not included | ❌ Not needed | ❌ Not needed | ❌ Not needed |
| `parentComponentId` | Parent's code | ❌ Not included | ❌ Not needed | ❌ Not needed | ❌ Not needed |
| `isTemplate` | ❌ Not in table | ✅ `true`/`false` | ✅ Used to identify | ❌ **Not needed** (v4.0) | ❌ Not in table |
| `children` | ❌ Not in table | ✅ Included | ✅ Used for hierarchy | ✅ Used for save | ❌ Not in table |
| `parent_id` | ❌ Not in template | ❌ Not in response | ❌ Not needed | ❌ Not needed | ✅ Generated from recursion |

**Save Logic Based on Query (v4.0)**:
1. **Query Template**: Backend uses `parentComponentId` to build `children` array, pre-generates UUIDs, returns VO with `id=UUID, isTemplate=true, children=[...]`
2. **Frontend Display**: Frontend uses pre-generated UUIDs directly, checks `isTemplate` field to distinguish template from real data
3. **Determine Operation**: Backend queries `benchmark_details` table by `benchmarkId`
   - If table is **empty** → Initialization (first save)
   - If table has **data** → Non-initialization save
4. **First Save (details empty)**: Frontend sends `{id, benchmarkId, children}`, backend **UPDATE benchmark (recordVersion=0, delFlag=0)** and recursively **INSERT all details**
5. **Nth Save (details exist)**: Frontend sends `{id, benchmarkId, children}`, backend **marks old benchmark as deleted + INSERT new benchmark**, and recursively **INSERT new details** (old details remain unchanged)
6. **Key Point**: Backend determines operation by **querying database**, not by frontend flag

### 5.2 Template Data vs Real Data (v3.0 Version Management)

| Field | Template Data (First Query) | Real Data (After Save) |
|-------|---------------------------|----------------------|
| `id` | Pre-generated UUID (e.g., `uuid-001`) | New UUID for each version (e.g., `uuid-v1-001`, `uuid-v2-001`) |
| `isTemplate` | `true` | `false` |
| `weight` | `"0.00"` | User-filled value (e.g., `"50.00"`) |
| `recordVersion` | `"0"` | Incremented version (e.g., `"1"`, `"2"`, `"3"`) |
| `benchmarkId` | Not in RespVo | Stored in database |
| `children` | Array (may be empty) | Array (may be empty) |

**Key Difference**: Each save creates NEW records with NEW UUIDs (not updating existing ones)

### 5.3 Insert/Update Decision Logic (v4.0 - Query-based)

**Backend logic**:
```java
// 1. Get benchmarkId from request
String benchmarkId = updateReqVO.get(0).getBenchmarkId();

// 2. Query benchmark_details table to determine operation type
List<BenchmarkDetailsDo> existingDetails = benchmarkDetailsMapper.selectList(
    new LambdaQueryWrapperX<>().eq(BenchmarkDetailsDo::getBenchmarkId, benchmarkId)
);

if (existingDetails == null || existingDetails.isEmpty()) {
    // ====== Initialization: UPDATE benchmark + INSERT details ======
    // 1. Get benchmarkDO from benchmarkId
    // 2. UPDATE benchmark (recordVersion=0, delFlag=0)
    // 3. Recursively INSERT all details
    handleFirstSave(benchmarkId, updateReqVO);
} else {
    // ====== Non-initialization: INSERT new benchmark + INSERT new details ======
    // 1. Get old benchmarkDO
    // 2. Validate version
    // 3. Mark old benchmark as deleted + INSERT new benchmark
    // 4. Recursively INSERT new details (old details remain unchanged)
    handleSubsequentSave(benchmarkId, updateReqVO);
}
```

**Decision basis**: Query `benchmark_details` table by `benchmarkId`
- **Details table empty** → Initialization (UPDATE benchmark, INSERT details)
- **Details table has data** → Non-initialization (INSERT new version)

### 5.4 Frontend Data Processing Key Points (v3.0)

**Handle template data (v3.0 - Use isTemplate field)**:
```javascript
const isTemplate = node.isTemplate === true  // Check explicit field

const treeNode = {
  id: node.id,                // Pre-generated UUID (both template and real data)
  children: [],               // Hierarchy maintained here
  isTemplate: isTemplate      // Mark template data
}
```

**Use pre-generated UUID when saving (v4.0)**:
```javascript
const data = {
  id: node.id,                          // Use pre-generated UUID directly
  benchmarkId: benchmarkId,             // Pass benchmark ID (required)
  weight: node.weight.toString(),
  recordVersion: node.recordVersion || '0',
  // Note: No isTemplate field - backend determines by querying database
  children: buildSaveData(node.children, benchmarkId)  // Backend uses this for hierarchy
}
```

### 5.5 ID Generation Timing (v3.0)

| Timing | ID Source | Value | isTemplate |
|--------|-----------|-------|------------|
| Query template data | Backend pre-generates | `a1b2c3d4-5678-...` | `true` |
| Frontend display template | Use backend UUID | Same UUID | `true` |
| First save | Use pre-generated UUID | Same UUID | `true` |
| After save (reload) | Database ID | Same UUID | `false` |
| Subsequent saves | Use existing ID | Unchanged | `false` |

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

**SQL Validation Scripts (v3.0)**:
```sql
-- 1. Check grouping table data
SELECT * FROM benchmark_grouping ORDER BY sort_order;

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

-- 5. Verify grouping hierarchy
SELECT
    g1.componentId AS level1_component,
    g1.description AS level1_desc,
    g2.componentId AS level2_component,
    g2.description AS level2_desc,
    g3.componentId AS level3_component,
    g3.description AS level3_desc
FROM benchmark_grouping g1
LEFT JOIN benchmark_grouping g2 ON g2.parentComponentId = g1.componentId
LEFT JOIN benchmark_grouping g3 ON g3.parentComponentId = g2.componentId
WHERE g1.parentComponentId IS NULL
ORDER BY g1.sort_order, g2.sort_order, g3.sort_order;
```

---

## FAQ

### Q1: Why use componentId instead of fixed UUID in grouping table? (v3.0)
**A**: The grouping table uses `componentId` as a business identifier to establish template hierarchy. This provides:
- Human-readable identifiers (e.g., `FI_GD`, `EQUITY_DM`)
- Simplified universal template (no need for multi-type support)
- Easy to maintain and understand
- Dynamic UUID generation in backend avoids conflicts

The actual UUID is pre-generated during query time, not stored in the grouping table.

### Q2: How does parent-child relationship work without parent_id? (v3.0)
**A**: Two stages:

**Grouping Table (Build tree)**:
```sql
-- Use parentComponentId to build children array
componentId: 'FI_GD'
parentComponentId: 'FI'  -- Links to parent
```

**During Save (Establish real parent_id)**:
```java
// Recursive method passes parentId parameter
insertRecursive(reqVos, benchmarkDO, currentNodeId, level) {
    detail.setId(reqVo.getId());         // Use pre-generated UUID
    detail.setParentId(currentNodeId);   // Use parameter directly
    insert(detail);

    // Recurse with current UUID as parent
    insertRecursive(reqVo.getChildren(), benchmarkDO, reqVo.getId(), level+1);
}
```

### Q3: Why pre-generate UUIDs when querying template? (v3.0)
**A**: Pre-generating UUIDs provides several benefits:
- **Simplified save logic**: Backend can directly use the UUID without generating new ones
- **Consistent IDs**: Same UUID used from template load to database insert
- **Clear distinction**: Use `isTemplate` field to mark template vs real data
- **Better UX**: Frontend doesn't need to manage temp IDs

### Q4: How does frontend distinguish template data from real data? (v3.0)
**A**: By checking the `isTemplate` field:
- `isTemplate === true` → Template data (not yet saved to database)
- `isTemplate === false` or omitted → Real data (saved to database)

The `id` field is a pre-generated UUID in both cases.

### Q5: Why does BenchmarkDetailsReqVo need isTemplate and benchmarkId fields? (v3.0)
**A**: These fields help backend determine the correct operation and avoid NPE (NullPointerException).

**Data flow**:
```
Frontend sends:
{
  id: "uuid-123",
  benchmarkId: "benchmark-v0",
  weight: "15.00",
  isTemplate: true  // ← Required!
}

Backend logic (based on isTemplate):
if (isTemplate === true) {
  // First save: UPDATE benchmark + INSERT details
  benchmarkDO = benchmarkMapper.selectById(benchmarkId);  // ← Use benchmarkId directly
  updateBenchmarkForFirstSave(benchmarkDO);  // UPDATE v0 → v1
  insertBenchmarkDetailsRecursive(...);       // INSERT details
} else {
  // Nth save: INSERT new benchmark + INSERT new details
  detailDO = benchmarkDetailsMapper.selectById(id);
  benchmarkDO = benchmarkMapper.selectById(detailDO.getBenchmarkId());
  markOldDetailsAsDeleted(benchmarkId);
  updateMainBenchmark(benchmarkDO);           // INSERT new version
  insertBenchmarkDetailsRecursive(...);       // INSERT new details
}
```

**Benefits**:
- **Avoid NPE**: On first save, detail table is empty, so we can't query by detail ID
- **Performance**: No need to query detail table on first save
- **Clear logic**: Explicitly tells backend whether it's first save or Nth save

### Q6: What happens if user leaves without saving?
**A**: No impact, data not inserted to database, `benchmark_details` table remains empty, next visit still shows template data.

### Q7: How to update template structure? (v3.0)
**A**: Directly modify `benchmark_grouping` table data:
```sql
-- Add new template node
INSERT INTO benchmark_grouping
  (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES
  (NEWID(), N'FI_NEW', N'FI', N'New Asset', N'New Asset Class', 2, 10);

-- Modify description
UPDATE benchmark_grouping SET description = N'Updated Description' WHERE componentId = 'FI_GD';

-- Modify sort order
UPDATE benchmark_grouping SET sort_order = 10 WHERE componentId = 'EQUITY';
```

Note: In v3.0, we use a universal template (no `benchmark_type` field), so all benchmarks share the same grouping structure.

### Q8: What if I need different structures for different benchmark types? (v3.0)
**A**: In v3.0, we simplified to use a **universal template** that works for all benchmark types. If you absolutely need type-specific structures:

**Option 1 (Recommended)**: Use the universal template and let users customize weights based on their needs. Nodes with 0 weight can be considered unused.

**Option 2**: Revert to v2.0 design with `benchmark_type` field in the template table. This adds complexity but provides type-specific templates.

### Q9: How to handle concurrent saves?
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

### Implementation Points (v3.0 - Hybrid Approach)
1. ⭐ **Hybrid Approach**: Pre-generate UUIDs for template data + use `isTemplate` field to mark template vs real data
2. **Component ID Design**: Use `componentId` + `parentComponentId` in `benchmark_grouping` table (universal template)
3. **Universal Template**: Simplified from multi-type to single universal template (all benchmarks use same structure)
4. **Children Array**: Use `children` array to maintain tree hierarchy (no need for componentId in VO)
5. **Simplified Recursion**: Pass `parentId` parameter through recursion, use pre-generated UUIDs
6. **Auto-detect Query**: Return template with pre-generated UUIDs if `benchmark_details` is empty
7. **Auto-detect Save**: First save = INSERT (using pre-generated UUIDs), subsequent saves = UPDATE
8. **Simplified Frontend**: Frontend uses pre-generated UUIDs directly, checks `isTemplate` field

### Advantages
- **Simplified Logic**: No need to generate temp IDs in frontend or new UUIDs in backend insert
- **Consistent IDs**: Same UUID used from template load to database insert
- **Clear Distinction**: `isTemplate` field explicitly marks template vs real data
- **User-friendly**: Auto-initialize structure with pre-generated IDs, users only fill weights
- **Smart**: Auto-detect INSERT/UPDATE, users don't need to care
- **Scalable**: Supports arbitrary levels of tree structure
- **Maintainable**: Component IDs are human-readable (e.g., `FI_GD_EUR`, `EQUITY_DM`)
- **Simplified Design**: Universal template instead of type-specific templates

### Key Differences from v2.0
| Aspect | v2.0 (Template Code) | v3.0 (Hybrid Approach) |
|--------|----------------------|------------------------|
| Template ID in Query | `null` | Pre-generated UUID |
| Template Marker | Check `id === null` | Check `isTemplate === true` |
| Frontend Temp ID | Frontend generates | Not needed (use pre-generated) |
| Insert UUID | Backend generates new | Backend uses pre-generated |
| Multi-Type Support | ✅ Yes (via `benchmark_type`) | ❌ No (universal template) |
| Table Name | `benchmark_details_template` | `benchmark_grouping` |
| Business Identifier | `template_code` | `componentId` |
| Complexity | Medium | ✅ Low (simplified) |

---

**Document Version**: v3.0
**Last Updated**: 2025-10-22
**Maintainer**: Claude Code
