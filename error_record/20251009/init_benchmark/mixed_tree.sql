-- ============================================================================
-- Mixed Tree Structure SQL Script
-- ============================================================================
-- 说明：此脚本包含三种不同的树形结构场景：
-- 场景1：只有一级树（无子节点）
-- 场景2：一级和二级叶子结构
-- 场景3：一级、二级目录和三级叶子结构
-- ============================================================================

-- ============================================================================
-- 1. 插入benchmark主表记录
-- ============================================================================
INSERT INTO benchmark
(id, business_id, name, status, business_type, benchmark_type, maker, maker_datetime, maker_business_date,
 checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime,
 del_flag, system_version, tenant_id, instance_id)
VALUES
('MIXED-TREE-2025-0001', 'B-MIXED-001', 'Mixed Tree Structure Test', 0, 1, 1, 'admin',
 NOW(), NULL, NULL, NULL, NULL, 0, NOW(), NULL, 0, 0, 1, NULL);

-- ============================================================================
-- 2. 场景1：只有一级树（无子节点）
-- ============================================================================
-- 说明：这是一个一级节点，parent_id=NULL，且没有任何子节点
-- 用于测试：一级菜单无子结构时应该可编辑

-- 场景1：Cash - 一级节点（无子节点）
INSERT INTO benchmark_details
(id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version, tenant_id)
VALUES
('DETAIL-LEVEL1-ONLY-001', 'B-MIXED-001', 'MIXED-TREE-2025-0001', NULL, 'Cash', 1, 10.00, 0, 1);

-- ============================================================================
-- 3. 场景2：一级和二级叶子结构
-- ============================================================================
-- 说明：一级节点 + 二级叶子节点
-- 树形结构：
-- Bonds (一级，parent_id=NULL, 有子节点，权重自动计算)
--   ├── Government Bonds (二级叶子，parent_id=一级节点id)
--   ├── Corporate Bonds (二级叶子，parent_id=一级节点id)
--   └── Municipal Bonds (二级叶子，parent_id=一级节点id)

-- 场景2：Bonds - 一级节点（有二级子节点）
INSERT INTO benchmark_details
(id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version, tenant_id)
VALUES
('DETAIL-LEVEL1-WITH-L2-001', 'B-MIXED-001', 'MIXED-TREE-2025-0001', NULL, 'Bonds', 1, 30.00, 0, 1);

-- 场景2：二级叶子节点（parent_id指向一级节点）
INSERT INTO benchmark_details
(id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version, tenant_id)
VALUES
('DETAIL-LEVEL2-LEAF-001', 'B-MIXED-001', 'MIXED-TREE-2025-0001', 'DETAIL-LEVEL1-WITH-L2-001',
 'Government Bonds', 2, 15.00, 0, 1);

INSERT INTO benchmark_details
(id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version, tenant_id)
VALUES
('DETAIL-LEVEL2-LEAF-002', 'B-MIXED-001', 'MIXED-TREE-2025-0001', 'DETAIL-LEVEL1-WITH-L2-001',
 'Corporate Bonds', 2, 10.00, 0, 1);

INSERT INTO benchmark_details
(id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version, tenant_id)
VALUES
('DETAIL-LEVEL2-LEAF-003', 'B-MIXED-001', 'MIXED-TREE-2025-0001', 'DETAIL-LEVEL1-WITH-L2-001',
 'Municipal Bonds', 2, 5.00, 0, 1);

-- ============================================================================
-- 4. 场景3：一级、二级目录和三级叶子结构
-- ============================================================================
-- 说明：一级节点 + 二级目录节点 + 三级叶子节点
-- 树形结构：
-- Equity (一级，parent_id=NULL, 有子节点，权重自动计算)
--   ├── Developed Markets (二级目录，parent_id=一级节点id, 有子节点，权重自动计算)
--   │   ├── US Stocks (三级叶子，parent_id=二级节点id)
--   │   ├── European Stocks (三级叶子，parent_id=二级节点id)
--   │   └── Asia Pacific Stocks (三级叶子，parent_id=二级节点id)
--   └── Emerging Markets (二级目录，parent_id=一级节点id, 有子节点，权重自动计算)
--       ├── China Stocks (三级叶子，parent_id=二级节点id)
--       ├── India Stocks (三级叶子，parent_id=二级节点id)
--       └── Brazil Stocks (三级叶子，parent_id=二级节点id)

-- 场景3：Equity - 一级节点（有二级目录子节点）
INSERT INTO benchmark_details
(id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version, tenant_id)
VALUES
('DETAIL-LEVEL1-WITH-L3-001', 'B-MIXED-001', 'MIXED-TREE-2025-0001', NULL, 'Equity', 1, 60.00, 0, 1);

-- 场景3：Developed Markets - 二级目录节点（有三级叶子节点）
INSERT INTO benchmark_details
(id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version, tenant_id)
VALUES
('DETAIL-LEVEL2-DIR-001', 'B-MIXED-001', 'MIXED-TREE-2025-0001', 'DETAIL-LEVEL1-WITH-L3-001',
 'Developed Markets', 2, 40.00, 0, 1);

-- 场景3：Developed Markets下的三级叶子节点
INSERT INTO benchmark_details
(id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version, tenant_id)
VALUES
('DETAIL-LEVEL3-LEAF-001', 'B-MIXED-001', 'MIXED-TREE-2025-0001', 'DETAIL-LEVEL2-DIR-001',
 'US Stocks', 3, 20.00, 0, 1);

INSERT INTO benchmark_details
(id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version, tenant_id)
VALUES
('DETAIL-LEVEL3-LEAF-002', 'B-MIXED-001', 'MIXED-TREE-2025-0001', 'DETAIL-LEVEL2-DIR-001',
 'European Stocks', 3, 12.00, 0, 1);

INSERT INTO benchmark_details
(id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version, tenant_id)
VALUES
('DETAIL-LEVEL3-LEAF-003', 'B-MIXED-001', 'MIXED-TREE-2025-0001', 'DETAIL-LEVEL2-DIR-001',
 'Asia Pacific Stocks', 3, 8.00, 0, 1);

-- 场景3：Emerging Markets - 二级目录节点（有三级叶子节点）
INSERT INTO benchmark_details
(id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version, tenant_id)
VALUES
('DETAIL-LEVEL2-DIR-002', 'B-MIXED-001', 'MIXED-TREE-2025-0001', 'DETAIL-LEVEL1-WITH-L3-001',
 'Emerging Markets', 2, 20.00, 0, 1);

-- 场景3：Emerging Markets下的三级叶子节点
INSERT INTO benchmark_details
(id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version, tenant_id)
VALUES
('DETAIL-LEVEL3-LEAF-004', 'B-MIXED-001', 'MIXED-TREE-2025-0001', 'DETAIL-LEVEL2-DIR-002',
 'China Stocks', 3, 8.00, 0, 1);

INSERT INTO benchmark_details
(id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version, tenant_id)
VALUES
('DETAIL-LEVEL3-LEAF-005', 'B-MIXED-001', 'MIXED-TREE-2025-0001', 'DETAIL-LEVEL2-DIR-002',
 'India Stocks', 3, 7.00, 0, 1);

INSERT INTO benchmark_details
(id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version, tenant_id)
VALUES
('DETAIL-LEVEL3-LEAF-006', 'B-MIXED-001', 'MIXED-TREE-2025-0001', 'DETAIL-LEVEL2-DIR-002',
 'Brazil Stocks', 3, 5.00, 0, 1);

-- ============================================================================
-- 5. 数据验证查询
-- ============================================================================

-- 查询benchmark主表记录
SELECT * FROM benchmark WHERE id = 'MIXED-TREE-2025-0001';

-- 查询所有details记录（按asset_level和parent_id排序）
SELECT
    id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    CASE
        WHEN parent_id IS NULL THEN '一级节点'
        WHEN asset_level = 2 THEN '二级节点'
        WHEN asset_level = 3 THEN '三级节点'
        ELSE '其他'
    END AS node_type
FROM benchmark_details
WHERE benchmark_id = 'MIXED-TREE-2025-0001'
ORDER BY asset_level, parent_id, id;

-- ============================================================================
-- 6. 树形结构展示
-- ============================================================================
/*
预期的树形结构：

MIXED-TREE-2025-0001: Mixed Tree Structure Test
├── Cash (10.00%)                           【场景1：一级节点，无子节点】
├── Bonds (30.00%)                          【场景2：一级节点，有二级叶子】
│   ├── Government Bonds (15.00%)           【二级叶子】
│   ├── Corporate Bonds (10.00%)            【二级叶子】
│   └── Municipal Bonds (5.00%)             【二级叶子】
└── Equity (60.00%)                         【场景3：一级节点，有二级目录和三级叶子】
    ├── Developed Markets (40.00%)          【二级目录】
    │   ├── US Stocks (20.00%)              【三级叶子】
    │   ├── European Stocks (12.00%)        【三级叶子】
    │   └── Asia Pacific Stocks (8.00%)     【三级叶子】
    └── Emerging Markets (20.00%)           【二级目录】
        ├── China Stocks (8.00%)            【三级叶子】
        ├── India Stocks (7.00%)            【三级叶子】
        └── Brazil Stocks (5.00%)           【三级叶子】

总权重验证：10 + 30 + 60 = 100.00%
*/

-- ============================================================================
-- 7. 权重验证查询
-- ============================================================================

-- 验证一级节点权重总和（应该等于100）
SELECT
    '一级节点权重总和' AS description,
    SUM(weight) AS total_weight,
    CASE
        WHEN SUM(weight) = 100.00 THEN '✓ 正确'
        ELSE '✗ 错误'
    END AS validation
FROM benchmark_details
WHERE benchmark_id = 'MIXED-TREE-2025-0001'
  AND parent_id IS NULL;

-- 验证Bonds的二级子节点权重总和（应该等于30.00）
SELECT
    'Bonds二级子节点权重总和' AS description,
    SUM(weight) AS total_weight,
    CASE
        WHEN SUM(weight) = 30.00 THEN '✓ 正确'
        ELSE '✗ 错误'
    END AS validation
FROM benchmark_details
WHERE benchmark_id = 'MIXED-TREE-2025-0001'
  AND parent_id = 'DETAIL-LEVEL1-WITH-L2-001';

-- 验证Developed Markets的三级子节点权重总和（应该等于40.00）
SELECT
    'Developed Markets三级子节点权重总和' AS description,
    SUM(weight) AS total_weight,
    CASE
        WHEN SUM(weight) = 40.00 THEN '✓ 正确'
        ELSE '✗ 错误'
    END AS validation
FROM benchmark_details
WHERE benchmark_id = 'MIXED-TREE-2025-0001'
  AND parent_id = 'DETAIL-LEVEL2-DIR-001';

-- 验证Emerging Markets的三级子节点权重总和（应该等于20.00）
SELECT
    'Emerging Markets三级子节点权重总和' AS description,
    SUM(weight) AS total_weight,
    CASE
        WHEN SUM(weight) = 20.00 THEN '✓ 正确'
        ELSE '✗ 错误'
    END AS validation
FROM benchmark_details
WHERE benchmark_id = 'MIXED-TREE-2025-0001'
  AND parent_id = 'DETAIL-LEVEL2-DIR-002';

-- ============================================================================
-- 8. 测试场景说明
-- ============================================================================
/*
测试场景1：一级节点无子结构可编辑
- 节点：Cash
- 验证：在编辑模式下，Cash节点应该显示可编辑的权重输入框
- 预期：前端判断 (!data.children || data.children.length === 0) 为true

测试场景2：一级节点有二级叶子
- 节点：Bonds
- 验证：Bonds节点应该显示"自动计算"标签，不可编辑
- 验证：Government Bonds, Corporate Bonds, Municipal Bonds应该可编辑
- 预期：修改任一二级叶子节点权重后，Bonds权重自动更新

测试场景3：一级、二级目录和三级叶子
- 节点：Equity -> Developed Markets -> US Stocks
- 验证：Equity和Developed Markets显示"自动计算"，不可编辑
- 验证：US Stocks, European Stocks, Asia Pacific Stocks应该可编辑
- 预期：修改任一三级叶子节点权重后，Developed Markets和Equity权重自动更新

测试场景4：混合编辑
- 同时修改Cash（一级叶子）、Government Bonds（二级叶子）、US Stocks（三级叶子）
- 验证：权重变化能正确反映到父节点
- 验证：保存后能正确提交所有数据到后端
*/

-- ============================================================================
-- 9. 清理脚本（可选，用于重置数据）
-- ============================================================================
/*
-- 取消注释以下语句可以删除测试数据
DELETE FROM benchmark_details WHERE benchmark_id = 'MIXED-TREE-2025-0001';
DELETE FROM benchmark WHERE id = 'MIXED-TREE-2025-0001';
*/
