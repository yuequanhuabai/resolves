-- ====================================================================
-- Benchmark 混合层级树结构测试数据 - SQL Server 版本
-- 创建日期: 2025-10-20
-- 说明: 包含 1 条 benchmark 主表记录 + 混合层级树结构的详情数据
-- 特点: 同时包含二级树和三级树，测试动态层级渲染
-- 字段完全匹配 SQL Server 表结构：
--   - benchmark: 18个字段（无 tenant_id）
--   - benchmark_details: 8个字段（无 tenant_id）
-- ====================================================================

-- ====================================================================
-- 1. 插入 benchmark 主表数据（入口）- 完整18个字段
-- ====================================================================
BEGIN TRANSACTION
GO

INSERT INTO benchmark (
    id,
    business_id,
    process_instance_id,
    name,
    status,
    business_type,
    benchmark_type,
    maker,
    maker_datetime,
    maker_business_date,
    checker,
    checker_datetime,
    checker_business_date,
    record_version,
    valid_start_datetime,
    valid_end_datetime,
    del_flag,
    system_version
) VALUES (
    N'benchmark-mixed-level-20251020',      -- id: 主键ID（全新ID）
    N'B-MIXED-LEVEL-20251020',              -- business_id: 业务ID（全新ID）
    NULL,                                    -- process_instance_id: 流程ID（草稿状态为空）
    N'Test Mixed-Level Tree Benchmark',     -- name: benchmark名称（混合层级）
    0,                                       -- status: 0-待提交（草稿，可编辑）
    1,                                       -- business_type: 1-private banking
    1,                                       -- benchmark_type: 1-BENCHMARK
    N'admin',                                -- maker: 制单人
    N'2025-10-20 10:00:00',                 -- maker_datetime: 提交日期
    NULL,                                    -- maker_business_date: 提交人业务日期
    NULL,                                    -- checker: 审核人
    NULL,                                    -- checker_datetime: 审核日期
    NULL,                                    -- checker_business_date: 审核人业务日期
    0,                                       -- record_version: 数据版本号
    N'2025-10-20 10:00:00',                 -- valid_start_datetime: 数据记录日期
    NULL,                                    -- valid_end_datetime: 数据版本更新日期
    0,                                       -- del_flag: 0-未删除
    0                                        -- system_version: 乐观锁版本号
)
GO

COMMIT
GO

-- ====================================================================
-- 2. 插入 benchmark_details 详情数据（三级树结构）
-- ====================================================================

BEGIN TRANSACTION
GO

-- --------------------------------------------------------------------
-- Level 1: Fixed Income (一级节点 - 固定收益)
-- --------------------------------------------------------------------
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
) VALUES (
    N'mixed-level1-fixed-income',            -- id
    N'B-MIXED-LEVEL-20251020',               -- business_id
    N'benchmark-mixed-level-20251020',       -- benchmark_id: 关联主表
    NULL,                                     -- parent_id: NULL 表示一级节点
    N'Fixed Income',                         -- asset_classification: 资产分类名称
    1,                                        -- asset_level: 1 表示一级
    40.00,                                    -- weight: 权重为所有子节点之和
    0                                         -- record_version: 数据版本号
)
GO

    -- ----------------------------------------------------------------
    -- Level 2: Government Debt (二级节点 - 政府债券，属于 Fixed Income)
    -- ----------------------------------------------------------------
    INSERT INTO benchmark_details (
        id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version
    ) VALUES (
        N'mixed-level2-government-debt',      -- id
        N'B-MIXED-LEVEL-20251020',            -- business_id
        N'benchmark-mixed-level-20251020',    -- benchmark_id
        N'mixed-level1-fixed-income',         -- parent_id: 指向父节点 Fixed Income
        N'Government Debt',                   -- asset_classification
        2,                                    -- asset_level: 2 表示二级
        25.00,                                -- weight: 子节点权重之和 (15 + 10)
        0                                     -- record_version
    )
    GO

        -- ------------------------------------------------------------
        -- Level 3: EUR Government Bonds (三级节点，属于 Government Debt)
        -- ------------------------------------------------------------
        INSERT INTO benchmark_details (
            id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version
        ) VALUES (
            N'mixed-level3-eur-gov-bonds',    -- id
            N'B-MIXED-LEVEL-20251020',        -- business_id
            N'benchmark-mixed-level-20251020', -- benchmark_id
            N'mixed-level2-government-debt',  -- parent_id: 指向父节点 Government Debt
            N'EUR Government Bonds',          -- asset_classification
            3,                                -- asset_level: 3 表示三级（叶子节点）
            15.00,                            -- weight: 叶子节点可编辑
            0                                 -- record_version
        )
        GO

        -- ------------------------------------------------------------
        -- Level 3: Non-EUR Government Bonds (三级节点，属于 Government Debt)
        -- ------------------------------------------------------------
        INSERT INTO benchmark_details (
            id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version
        ) VALUES (
            N'mixed-level3-non-eur-gov-bonds', -- id
            N'B-MIXED-LEVEL-20251020',        -- business_id
            N'benchmark-mixed-level-20251020', -- benchmark_id
            N'mixed-level2-government-debt',  -- parent_id: 指向父节点 Government Debt
            N'Non-EUR Government Bonds',      -- asset_classification
            3,                                -- asset_level: 3 表示三级（叶子节点）
            10.00,                            -- weight: 叶子节点可编辑
            0                                 -- record_version
        )
        GO

    -- ----------------------------------------------------------------
    -- Level 2: Corporate Debt (二级节点 - 企业债券，属于 Fixed Income)
    -- ⭐ 注意：这是二级叶子节点，没有三级子节点！
    -- ----------------------------------------------------------------
    INSERT INTO benchmark_details (
        id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version
    ) VALUES (
        N'mixed-level2-corporate-debt',       -- id
        N'B-MIXED-LEVEL-20251020',            -- business_id
        N'benchmark-mixed-level-20251020',    -- benchmark_id
        N'mixed-level1-fixed-income',         -- parent_id: 指向父节点 Fixed Income
        N'Corporate Debt',                    -- asset_classification
        2,                                    -- asset_level: 2 表示二级（叶子节点，可编辑）
        15.00,                                -- weight: 二级叶子节点，可编辑
        0                                     -- record_version
    )
    GO

-- --------------------------------------------------------------------
-- Level 1: Equity (一级节点 - 股票)
-- --------------------------------------------------------------------
INSERT INTO benchmark_details (
    id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version
) VALUES (
    N'mixed-level1-equity',                   -- id
    N'B-MIXED-LEVEL-20251020',                -- business_id
    N'benchmark-mixed-level-20251020',        -- benchmark_id
    NULL,                                      -- parent_id: NULL 表示一级节点
    N'Equity',                                -- asset_classification
    1,                                         -- asset_level: 1 表示一级
    60.00,                                     -- weight: 子节点权重之和 (40 + 20)
    0                                          -- record_version
)
GO

    -- ----------------------------------------------------------------
    -- Level 2: Developed Markets (二级节点 - 发达市场，属于 Equity)
    -- ----------------------------------------------------------------
    INSERT INTO benchmark_details (
        id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version
    ) VALUES (
        N'mixed-level2-developed-markets',    -- id
        N'B-MIXED-LEVEL-20251020',            -- business_id
        N'benchmark-mixed-level-20251020',    -- benchmark_id
        N'mixed-level1-equity',               -- parent_id: 指向父节点 Equity
        N'Developed Markets',                 -- asset_classification
        2,                                    -- asset_level: 2 表示二级
        40.00,                                -- weight: 子节点权重之和 (20 + 20)
        0                                     -- record_version
    )
    GO

        -- ------------------------------------------------------------
        -- Level 3: Europe Equity (三级节点，属于 Developed Markets)
        -- ------------------------------------------------------------
        INSERT INTO benchmark_details (
            id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version
        ) VALUES (
            N'mixed-level3-europe-equity',    -- id
            N'B-MIXED-LEVEL-20251020',        -- business_id
            N'benchmark-mixed-level-20251020', -- benchmark_id
            N'mixed-level2-developed-markets', -- parent_id: 指向父节点 Developed Markets
            N'Europe Equity',                 -- asset_classification
            3,                                -- asset_level: 3 表示三级（叶子节点）
            20.00,                            -- weight: 叶子节点可编辑
            0                                 -- record_version
        )
        GO

        -- ------------------------------------------------------------
        -- Level 3: North America Equity (三级节点，属于 Developed Markets)
        -- ------------------------------------------------------------
        INSERT INTO benchmark_details (
            id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version
        ) VALUES (
            N'mixed-level3-north-america-equity', -- id
            N'B-MIXED-LEVEL-20251020',        -- business_id
            N'benchmark-mixed-level-20251020', -- benchmark_id
            N'mixed-level2-developed-markets', -- parent_id: 指向父节点 Developed Markets
            N'North America Equity',          -- asset_classification
            3,                                -- asset_level: 3 表示三级（叶子节点）
            20.00,                            -- weight: 叶子节点可编辑
            0                                 -- record_version
        )
        GO

    -- ----------------------------------------------------------------
    -- Level 2: Emerging Markets (二级节点 - 新兴市场，属于 Equity)
    -- ⭐ 注意：这是二级叶子节点，没有三级子节点！
    -- ----------------------------------------------------------------
    INSERT INTO benchmark_details (
        id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version
    ) VALUES (
        N'mixed-level2-emerging-markets',     -- id
        N'B-MIXED-LEVEL-20251020',            -- business_id
        N'benchmark-mixed-level-20251020',    -- benchmark_id
        N'mixed-level1-equity',               -- parent_id: 指向父节点 Equity
        N'Emerging Markets',                  -- asset_classification
        2,                                    -- asset_level: 2 表示二级（叶子节点，可编辑）
        20.00,                                -- weight: 二级叶子节点，可编辑
        0                                     -- record_version
    )
    GO

-- --------------------------------------------------------------------
-- Level 1: Alternatives (一级节点 - 另类投资)
-- ⭐ 注意：这个一级节点下只有二级节点，全部是叶子节点
-- --------------------------------------------------------------------
INSERT INTO benchmark_details (
    id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version
) VALUES (
    N'mixed-level1-alternatives',             -- id
    N'B-MIXED-LEVEL-20251020',                -- business_id
    N'benchmark-mixed-level-20251020',        -- benchmark_id
    NULL,                                      -- parent_id: NULL 表示一级节点
    N'Alternatives',                          -- asset_classification
    1,                                         -- asset_level: 1 表示一级
    0.00,                                      -- weight: 子节点权重之和
    0                                          -- record_version
)
GO

    -- ----------------------------------------------------------------
    -- Level 2: Hedge Funds (二级节点 - 对冲基金，属于 Alternatives)
    -- ⭐ 注意：这是二级叶子节点，没有三级子节点！
    -- ----------------------------------------------------------------
    INSERT INTO benchmark_details (
        id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version
    ) VALUES (
        N'mixed-level2-hedge-funds',          -- id
        N'B-MIXED-LEVEL-20251020',            -- business_id
        N'benchmark-mixed-level-20251020',    -- benchmark_id
        N'mixed-level1-alternatives',         -- parent_id: 指向父节点 Alternatives
        N'Hedge Funds',                       -- asset_classification
        2,                                    -- asset_level: 2 表示二级（叶子节点，可编辑）
        0.00,                                 -- weight: 二级叶子节点，可编辑
        0                                     -- record_version
    )
    GO

COMMIT
GO

-- ====================================================================
-- 数据结构说明（混合层级）
-- ====================================================================
-- 树形结构如下（包含二级树和三级树）：
--
-- Root (100%)
-- ├─ Fixed Income (40%)                      [Level 1]
-- │  ├─ Government Debt (25%)                [Level 2] ⭐ 有三级子节点
-- │  │  ├─ EUR Government Bonds (15%)        [Level 3 - 叶子节点，可编辑]
-- │  │  └─ Non-EUR Government Bonds (10%)    [Level 3 - 叶子节点，可编辑]
-- │  └─ Corporate Debt (15%)                 [Level 2 - 叶子节点，可编辑] ⭐ 二级叶子节点
-- │
-- ├─ Equity (60%)                            [Level 1]
-- │  ├─ Developed Markets (40%)              [Level 2] ⭐ 有三级子节点
-- │  │  ├─ Europe Equity (20%)               [Level 3 - 叶子节点，可编辑]
-- │  │  └─ North America Equity (20%)        [Level 3 - 叶子节点，可编辑]
-- │  └─ Emerging Markets (20%)               [Level 2 - 叶子节点，可编辑] ⭐ 二级叶子节点
-- │
-- └─ Alternatives (0%)                       [Level 1]
--    └─ Hedge Funds (0%)                     [Level 2 - 叶子节点，可编辑] ⭐ 二级叶子节点
--
-- ⭐ 关键特点：
-- 1. Government Debt 和 Developed Markets 是三级树分支（Level 2 -> Level 3）
-- 2. Corporate Debt、Emerging Markets、Hedge Funds 是二级叶子节点（Level 2，无子节点）
-- 3. 同一棵树中混合了二级和三级结构
-- 4. 前端应该只允许叶子节点可编辑（无论是 Level 2 还是 Level 3）
--
-- ====================================================================
-- 表结构说明（SQL Server 版本）
-- ====================================================================
-- benchmark 表字段（18个字段）：
--   id, business_id, process_instance_id, name, status, business_type,
--   benchmark_type, maker, maker_datetime, maker_business_date, checker,
--   checker_datetime, checker_business_date, record_version,
--   valid_start_datetime, valid_end_datetime, del_flag, system_version
--
-- benchmark_details 表字段（8个字段）：
--   id, business_id, benchmark_id, parent_id, asset_classification,
--   asset_level, weight, record_version
--
-- ====================================================================
-- 使用说明
-- ====================================================================
-- 1. 在 SQL Server Management Studio 中执行本脚本
-- 2. 执行后，可在前端通过 benchmark_id = 'benchmark-mixed-level-20251020' 查询
-- 3. 前端应该展示为混合层级树结构（既有二级也有三级）
-- 4. 只有叶子节点可以编辑权重（无论是 Level 2 还是 Level 3）
-- 5. 非叶子节点的权重自动计算为子节点之和
-- 6. 测试重点：
--    - Government Debt 展开后应显示 2 个三级子节点
--    - Corporate Debt 不能展开（二级叶子节点）
--    - Developed Markets 展开后应显示 2 个三级子节点
--    - Emerging Markets 不能展开（二级叶子节点）
--    - Hedge Funds 不能展开（二级叶子节点）
-- ====================================================================
