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
-- benchmark_id: b1b2c3d4-5678-90ab-cdef-000000000001
-- business_id: BM-MIXED-2025102002
INSERT INTO benchmark (id, business_id, process_instance_id, name, status, business_type, benchmark_type, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES (N'b1b2c3d4-5678-90ab-cdef-000000000001', N'BM-MIXED-2025102002', NULL, N'', 0, 1, 1, N'', N'2025-10-20 15:00:00', NULL, NULL, NULL, NULL, 0, N'2025-10-20 15:00:00', NULL, 0, 0);

-- ====================================================================
-- 2. 插入 benchmark_details 详情数据（混合层级树结构）
-- ====================================================================

-- Level 1: Fixed Income (一级节点 - 固定收益)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'b1b2c3d4-5678-90ab-cdef-100000000001', N'BM-MIXED-2025102002', N'b1b2c3d4-5678-90ab-cdef-000000000001', NULL, N'Fixed Income', 1, 40.00, 0);

-- Level 2: Government Debt (二级节点 - 政府债券，属于 Fixed Income，有三级子节点)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'b1b2c3d4-5678-90ab-cdef-200000000001', N'BM-MIXED-2025102002', N'b1b2c3d4-5678-90ab-cdef-000000000001', N'b1b2c3d4-5678-90ab-cdef-100000000001', N'Government Debt', 2, 25.00, 0);

-- Level 3: EUR Government Bonds (三级节点，属于 Government Debt)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'b1b2c3d4-5678-90ab-cdef-300000000001', N'BM-MIXED-2025102002', N'b1b2c3d4-5678-90ab-cdef-000000000001', N'b1b2c3d4-5678-90ab-cdef-200000000001', N'EUR Government Bonds', 3, 15.00, 0);

-- Level 3: Non-EUR Government Bonds (三级节点，属于 Government Debt)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'b1b2c3d4-5678-90ab-cdef-300000000002', N'BM-MIXED-2025102002', N'b1b2c3d4-5678-90ab-cdef-000000000001', N'b1b2c3d4-5678-90ab-cdef-200000000001', N'Non-EUR Government Bonds', 3, 10.00, 0);

-- Level 2: Corporate Debt (二级叶子节点 - 企业债券，属于 Fixed Income，⭐无三级子节点)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'b1b2c3d4-5678-90ab-cdef-200000000002', N'BM-MIXED-2025102002', N'b1b2c3d4-5678-90ab-cdef-000000000001', N'b1b2c3d4-5678-90ab-cdef-100000000001', N'Corporate Debt', 2, 15.00, 0);

-- Level 1: Equity (一级节点 - 股票)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'b1b2c3d4-5678-90ab-cdef-100000000002', N'BM-MIXED-2025102002', N'b1b2c3d4-5678-90ab-cdef-000000000001', NULL, N'Equity', 1, 60.00, 0);

-- Level 2: Developed Markets (二级节点 - 发达市场，属于 Equity，有三级子节点)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'b1b2c3d4-5678-90ab-cdef-200000000003', N'BM-MIXED-2025102002', N'b1b2c3d4-5678-90ab-cdef-000000000001', N'b1b2c3d4-5678-90ab-cdef-100000000002', N'Developed Markets', 2, 40.00, 0);

-- Level 3: Europe Equity (三级节点，属于 Developed Markets)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'b1b2c3d4-5678-90ab-cdef-300000000003', N'BM-MIXED-2025102002', N'b1b2c3d4-5678-90ab-cdef-000000000001', N'b1b2c3d4-5678-90ab-cdef-200000000003', N'Europe Equity', 3, 20.00, 0);

-- Level 3: North America Equity (三级节点，属于 Developed Markets)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'b1b2c3d4-5678-90ab-cdef-300000000004', N'BM-MIXED-2025102002', N'b1b2c3d4-5678-90ab-cdef-000000000001', N'b1b2c3d4-5678-90ab-cdef-200000000003', N'North America Equity', 3, 20.00, 0);

-- Level 2: Emerging Markets (二级叶子节点 - 新兴市场，属于 Equity，⭐无三级子节点)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'b1b2c3d4-5678-90ab-cdef-200000000004', N'BM-MIXED-2025102002', N'b1b2c3d4-5678-90ab-cdef-000000000001', N'b1b2c3d4-5678-90ab-cdef-100000000002', N'Emerging Markets', 2, 20.00, 0);

-- Level 1: Alternatives (一级节点 - 另类投资，⭐下面只有二级叶子节点)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'b1b2c3d4-5678-90ab-cdef-100000000003', N'BM-MIXED-2025102002', N'b1b2c3d4-5678-90ab-cdef-000000000001', NULL, N'Alternatives', 1, 0.00, 0);

-- Level 2: Hedge Funds (二级叶子节点 - 对冲基金，属于 Alternatives，⭐无三级子节点)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'b1b2c3d4-5678-90ab-cdef-200000000005', N'BM-MIXED-2025102002', N'b1b2c3d4-5678-90ab-cdef-000000000001', N'b1b2c3d4-5678-90ab-cdef-100000000003', N'Hedge Funds', 2, 0.00, 0);


