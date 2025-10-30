-- ====================================================================
-- Benchmark 测试数据 SQL 脚本 - 静态版本
-- 生成日期: 2025-10-30
-- 说明: 包含 2 条 benchmark 主表记录 + 每条对应 12 条混合层级树结构的详情数据
-- 总计: 26 条 INSERT 语句 (2 benchmark + 24 benchmark_details)
-- 用途: 可预览 SQL 语句，确认无误后再执行，降低直接执行风险
-- ====================================================================

-- ====================================================================
-- 第一组数据：Benchmark #1 + 12 条 Details
-- ====================================================================

-- Benchmark #1: BS-MIXED-20251029-1
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
)
VALUES (
    'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    'BS-MIXED-20251029-1',
    NULL,
    N'Test-BS-MIXED-20251029-1',
    0,
    1,
    1,
    N'admin',
    '2025-10-30 10:00:00',
    NULL,
    NULL,
    NULL,
    NULL,
    0,
    '2025-10-30 10:00:00',
    NULL,
    0,
    0
);

-- ====================================================================
-- Benchmark #1 Details (12 条详情记录 - 混合三级树结构)
-- ====================================================================

-- Level 1: Fixed Income (一级节点 - 固定收益)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'b1c2d3e4-f5a6-4b7c-8d9e-0f1a2b3c4d5e',
    'BS-MIXED-20251029-1',
    'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    NULL,
    N'Fixed Income',
    1,
    40.00,
    0
);

-- Level 2: Government Debt (二级节点 - 政府债券，属于 Fixed Income)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'c1d2e3f4-a5b6-4c7d-8e9f-0a1b2c3d4e5f',
    'BS-MIXED-20251029-1',
    'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    'b1c2d3e4-f5a6-4b7c-8d9e-0f1a2b3c4d5e',
    N'Government Debt',
    2,
    25.00,
    0
);

-- Level 3: EUR Government Bonds (三级节点，属于 Government Debt)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'd1e2f3a4-b5c6-4d7e-8f9a-0b1c2d3e4f5a',
    'BS-MIXED-20251029-1',
    'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    'c1d2e3f4-a5b6-4c7d-8e9f-0a1b2c3d4e5f',
    N'EUR Government Bonds',
    3,
    15.00,
    0
);

-- Level 3: Non-EUR Government Bonds (三级节点，属于 Government Debt)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'e1f2a3b4-c5d6-4e7f-8a9b-0c1d2e3f4a5b',
    'BS-MIXED-20251029-1',
    'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    'c1d2e3f4-a5b6-4c7d-8e9f-0a1b2c3d4e5f',
    N'Non-EUR Government Bonds',
    3,
    10.00,
    0
);

-- Level 2: Corporate Debt (二级叶子节点 - 企业债券，属于 Fixed Income)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'f1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c',
    'BS-MIXED-20251029-1',
    'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    'b1c2d3e4-f5a6-4b7c-8d9e-0f1a2b3c4d5e',
    N'Corporate Debt',
    2,
    15.00,
    0
);

-- Level 1: Equity (一级节点 - 股票)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'a2b3c4d5-e6f7-4a8b-9c0d-1e2f3a4b5c6d',
    'BS-MIXED-20251029-1',
    'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    NULL,
    N'Equity',
    1,
    60.00,
    0
);

-- Level 2: Developed Markets (二级节点 - 发达市场，属于 Equity)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e',
    'BS-MIXED-20251029-1',
    'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    'a2b3c4d5-e6f7-4a8b-9c0d-1e2f3a4b5c6d',
    N'Developed Markets',
    2,
    40.00,
    0
);

-- Level 3: Europe Equity (三级节点，属于 Developed Markets)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'c2d3e4f5-a6b7-4c8d-9e0f-1a2b3c4d5e6f',
    'BS-MIXED-20251029-1',
    'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e',
    N'Europe Equity',
    3,
    20.00,
    0
);

-- Level 3: North America Equity (三级节点，属于 Developed Markets)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'd2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a',
    'BS-MIXED-20251029-1',
    'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e',
    N'North America Equity',
    3,
    20.00,
    0
);

-- Level 2: Emerging Markets (二级叶子节点 - 新兴市场，属于 Equity)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'e2f3a4b5-c6d7-4e8f-9a0b-1c2d3e4f5a6b',
    'BS-MIXED-20251029-1',
    'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    'a2b3c4d5-e6f7-4a8b-9c0d-1e2f3a4b5c6d',
    N'Emerging Markets',
    2,
    20.00,
    0
);

-- Level 1: Alternatives (一级节点 - 另类投资)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'f2a3b4c5-d6e7-4f8a-9b0c-1d2e3f4a5b6c',
    'BS-MIXED-20251029-1',
    'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    NULL,
    N'Alternatives',
    1,
    0.00,
    0
);

-- Level 2: Hedge Funds (二级叶子节点 - 对冲基金，属于 Alternatives)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'a3b4c5d6-e7f8-4a9b-0c1d-2e3f4a5b6c7d',
    'BS-MIXED-20251029-1',
    'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    'f2a3b4c5-d6e7-4f8a-9b0c-1d2e3f4a5b6c',
    N'Hedge Funds',
    2,
    0.00,
    0
);

-- ====================================================================
-- 第二组数据：Benchmark #2 + 12 条 Details
-- ====================================================================

-- Benchmark #2: BS-MIXED-20251029-2
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
)
VALUES (
    'b3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e',
    'BS-MIXED-20251029-2',
    NULL,
    N'Test-BS-MIXED-20251029-2',
    0,
    1,
    1,
    N'admin',
    '2025-10-30 10:00:00',
    NULL,
    NULL,
    NULL,
    NULL,
    0,
    '2025-10-30 10:00:00',
    NULL,
    0,
    0
);

-- ====================================================================
-- Benchmark #2 Details (12 条详情记录 - 混合三级树结构)
-- ====================================================================

-- Level 1: Fixed Income (一级节点 - 固定收益)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'c3d4e5f6-a7b8-4c9d-0e1f-2a3b4c5d6e7f',
    'BS-MIXED-20251029-2',
    'b3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e',
    NULL,
    N'Fixed Income',
    1,
    40.00,
    0
);

-- Level 2: Government Debt (二级节点 - 政府债券，属于 Fixed Income)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'd3e4f5a6-b7c8-4d9e-0f1a-2b3c4d5e6f7a',
    'BS-MIXED-20251029-2',
    'b3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e',
    'c3d4e5f6-a7b8-4c9d-0e1f-2a3b4c5d6e7f',
    N'Government Debt',
    2,
    25.00,
    0
);

-- Level 3: EUR Government Bonds (三级节点，属于 Government Debt)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'e3f4a5b6-c7d8-4e9f-0a1b-2c3d4e5f6a7b',
    'BS-MIXED-20251029-2',
    'b3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e',
    'd3e4f5a6-b7c8-4d9e-0f1a-2b3c4d5e6f7a',
    N'EUR Government Bonds',
    3,
    15.00,
    0
);

-- Level 3: Non-EUR Government Bonds (三级节点，属于 Government Debt)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'f3a4b5c6-d7e8-4f9a-0b1c-2d3e4f5a6b7c',
    'BS-MIXED-20251029-2',
    'b3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e',
    'd3e4f5a6-b7c8-4d9e-0f1a-2b3c4d5e6f7a',
    N'Non-EUR Government Bonds',
    3,
    10.00,
    0
);

-- Level 2: Corporate Debt (二级叶子节点 - 企业债券，属于 Fixed Income)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'a4b5c6d7-e8f9-4a0b-1c2d-3e4f5a6b7c8d',
    'BS-MIXED-20251029-2',
    'b3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e',
    'c3d4e5f6-a7b8-4c9d-0e1f-2a3b4c5d6e7f',
    N'Corporate Debt',
    2,
    15.00,
    0
);

-- Level 1: Equity (一级节点 - 股票)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'b4c5d6e7-f8a9-4b0c-1d2e-3f4a5b6c7d8e',
    'BS-MIXED-20251029-2',
    'b3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e',
    NULL,
    N'Equity',
    1,
    60.00,
    0
);

-- Level 2: Developed Markets (二级节点 - 发达市场，属于 Equity)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'c4d5e6f7-a8b9-4c0d-1e2f-3a4b5c6d7e8f',
    'BS-MIXED-20251029-2',
    'b3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e',
    'b4c5d6e7-f8a9-4b0c-1d2e-3f4a5b6c7d8e',
    N'Developed Markets',
    2,
    40.00,
    0
);

-- Level 3: Europe Equity (三级节点，属于 Developed Markets)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'd4e5f6a7-b8c9-4d0e-1f2a-3b4c5d6e7f8a',
    'BS-MIXED-20251029-2',
    'b3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e',
    'c4d5e6f7-a8b9-4c0d-1e2f-3a4b5c6d7e8f',
    N'Europe Equity',
    3,
    20.00,
    0
);

-- Level 3: North America Equity (三级节点，属于 Developed Markets)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'e4f5a6b7-c8d9-4e0f-1a2b-3c4d5e6f7a8b',
    'BS-MIXED-20251029-2',
    'b3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e',
    'c4d5e6f7-a8b9-4c0d-1e2f-3a4b5c6d7e8f',
    N'North America Equity',
    3,
    20.00,
    0
);

-- Level 2: Emerging Markets (二级叶子节点 - 新兴市场，属于 Equity)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'f4a5b6c7-d8e9-4f0a-1b2c-3d4e5f6a7b8c',
    'BS-MIXED-20251029-2',
    'b3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e',
    'b4c5d6e7-f8a9-4b0c-1d2e-3f4a5b6c7d8e',
    N'Emerging Markets',
    2,
    20.00,
    0
);

-- Level 1: Alternatives (一级节点 - 另类投资)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'a5b6c7d8-e9f0-4a1b-2c3d-4e5f6a7b8c9d',
    'BS-MIXED-20251029-2',
    'b3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e',
    NULL,
    N'Alternatives',
    1,
    0.00,
    0
);

-- Level 2: Hedge Funds (二级叶子节点 - 对冲基金，属于 Alternatives)
INSERT INTO benchmark_details (
    id,
    business_id,
    benchmark_id,
    parent_id,
    asset_classification,
    asset_level,
    weight,
    record_version
)
VALUES (
    'b5c6d7e8-f9a0-4b1c-2d3e-4f5a6b7c8d9e',
    'BS-MIXED-20251029-2',
    'b3c4d5e6-f7a8-4b9c-0d1e-2f3a4b5c6d7e',
    'a5b6c7d8-e9f0-4a1b-2c3d-4e5f6a7b8c9d',
    N'Hedge Funds',
    2,
    0.00,
    0
);

-- ====================================================================
-- 数据验证查询（可选）
-- ====================================================================
-- 查看生成的 benchmark 记录
-- SELECT * FROM benchmark WHERE business_id IN ('BS-MIXED-20251029-1', 'BS-MIXED-20251029-2');

-- 查看生成的 benchmark_details 记录
-- SELECT * FROM benchmark_details WHERE business_id IN ('BS-MIXED-20251029-1', 'BS-MIXED-20251029-2') ORDER BY business_id, asset_level, asset_classification;

-- 查看树形结构（第一条记录）
-- SELECT
--     id,
--     business_id,
--     parent_id,
--     asset_classification,
--     asset_level,
--     weight
-- FROM benchmark_details
-- WHERE business_id = 'BS-MIXED-20251029-1'
-- ORDER BY asset_level, asset_classification;
