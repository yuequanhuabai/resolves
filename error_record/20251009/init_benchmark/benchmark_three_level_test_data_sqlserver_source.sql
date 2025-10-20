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
-- benchmark_id: a1b2c3d4-5678-90ab-cdef-000000000001
-- business_id: BM-MIXED-2025102001
INSERT INTO benchmark (id, business_id, process_instance_id, name, status, business_type, benchmark_type, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES (N'a1b2c3d4-5678-90ab-cdef-000000000001', N'BM-MIXED-2025102001', NULL, N'Test Mixed-Level Tree Benchmark', 0, 1, 1, N'admin', N'2025-10-20 10:00:00', NULL, NULL, NULL, NULL, 0, N'2025-10-20 10:00:00', NULL, 0, 0);

-- ====================================================================
-- 2. 插入 benchmark_details 详情数据（混合层级树结构）
-- ====================================================================

-- Level 1: Fixed Income (一级节点 - 固定收益)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'a1b2c3d4-5678-90ab-cdef-100000000001', N'BM-MIXED-2025102001', N'a1b2c3d4-5678-90ab-cdef-000000000001', NULL, N'Fixed Income', 1, 40.00, 0);

-- Level 2: Government Debt (二级节点 - 政府债券，属于 Fixed Income，有三级子节点)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'a1b2c3d4-5678-90ab-cdef-200000000001', N'BM-MIXED-2025102001', N'a1b2c3d4-5678-90ab-cdef-000000000001', N'a1b2c3d4-5678-90ab-cdef-100000000001', N'Government Debt', 2, 25.00, 0);

-- Level 3: EUR Government Bonds (三级节点，属于 Government Debt)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'a1b2c3d4-5678-90ab-cdef-300000000001', N'BM-MIXED-2025102001', N'a1b2c3d4-5678-90ab-cdef-000000000001', N'a1b2c3d4-5678-90ab-cdef-200000000001', N'EUR Government Bonds', 3, 15.00, 0);

-- Level 3: Non-EUR Government Bonds (三级节点，属于 Government Debt)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'a1b2c3d4-5678-90ab-cdef-300000000002', N'BM-MIXED-2025102001', N'a1b2c3d4-5678-90ab-cdef-000000000001', N'a1b2c3d4-5678-90ab-cdef-200000000001', N'Non-EUR Government Bonds', 3, 10.00, 0);

-- Level 2: Corporate Debt (二级叶子节点 - 企业债券，属于 Fixed Income，⭐无三级子节点)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'a1b2c3d4-5678-90ab-cdef-200000000002', N'BM-MIXED-2025102001', N'a1b2c3d4-5678-90ab-cdef-000000000001', N'a1b2c3d4-5678-90ab-cdef-100000000001', N'Corporate Debt', 2, 15.00, 0);

-- Level 1: Equity (一级节点 - 股票)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'a1b2c3d4-5678-90ab-cdef-100000000002', N'BM-MIXED-2025102001', N'a1b2c3d4-5678-90ab-cdef-000000000001', NULL, N'Equity', 1, 60.00, 0);

-- Level 2: Developed Markets (二级节点 - 发达市场，属于 Equity，有三级子节点)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'a1b2c3d4-5678-90ab-cdef-200000000003', N'BM-MIXED-2025102001', N'a1b2c3d4-5678-90ab-cdef-000000000001', N'a1b2c3d4-5678-90ab-cdef-100000000002', N'Developed Markets', 2, 40.00, 0);

-- Level 3: Europe Equity (三级节点，属于 Developed Markets)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'a1b2c3d4-5678-90ab-cdef-300000000003', N'BM-MIXED-2025102001', N'a1b2c3d4-5678-90ab-cdef-000000000001', N'a1b2c3d4-5678-90ab-cdef-200000000003', N'Europe Equity', 3, 20.00, 0);

-- Level 3: North America Equity (三级节点，属于 Developed Markets)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'a1b2c3d4-5678-90ab-cdef-300000000004', N'BM-MIXED-2025102001', N'a1b2c3d4-5678-90ab-cdef-000000000001', N'a1b2c3d4-5678-90ab-cdef-200000000003', N'North America Equity', 3, 20.00, 0);

-- Level 2: Emerging Markets (二级叶子节点 - 新兴市场，属于 Equity，⭐无三级子节点)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'a1b2c3d4-5678-90ab-cdef-200000000004', N'BM-MIXED-2025102001', N'a1b2c3d4-5678-90ab-cdef-000000000001', N'a1b2c3d4-5678-90ab-cdef-100000000002', N'Emerging Markets', 2, 20.00, 0);

-- Level 1: Alternatives (一级节点 - 另类投资，⭐下面只有二级叶子节点)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'a1b2c3d4-5678-90ab-cdef-100000000003', N'BM-MIXED-2025102001', N'a1b2c3d4-5678-90ab-cdef-000000000001', NULL, N'Alternatives', 1, 0.00, 0);

-- Level 2: Hedge Funds (二级叶子节点 - 对冲基金，属于 Alternatives，⭐无三级子节点)
INSERT INTO benchmark_details (id, business_id, benchmark_id, parent_id, asset_classification, asset_level, weight, record_version)
VALUES (N'a1b2c3d4-5678-90ab-cdef-200000000005', N'BM-MIXED-2025102001', N'a1b2c3d4-5678-90ab-cdef-000000000001', N'a1b2c3d4-5678-90ab-cdef-100000000003', N'Hedge Funds', 2, 0.00, 0);

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
-- 2. 执行后，可在前端通过 benchmark_id = 'a1b2c3d4-5678-90ab-cdef-000000000001' 查询
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

-- ====================================================================
-- 📝 ID 修改规则说明（重要！）
-- ====================================================================
-- 如果您需要修改 ID 以避免重复，请按照以下规则修改：
--
-- 一、ID 格式规范
-- ----------------
-- 1. benchmark 主表 ID 格式：
--    - 使用 UUID 格式：xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
--    - 示例：a1b2c3d4-5678-90ab-cdef-000000000001
--
-- 2. business_id 格式：
--    - 格式：BM-前缀-日期序号
--    - 示例：BM-MIXED-2025102001（表示2025年10月20日的第1个）
--    - 修改建议：修改日期或序号，如 BM-MIXED-2025102002
--
-- 二、benchmark_details ID 命名规则（重要！）
-- ------------------------------------------------
-- 为了便于识别层级关系，建议使用以下规则：
--
-- 1. UUID 基础格式：
--    前缀部分：a1b2c3d4-5678-90ab-cdef-（保持一致）
--    后缀部分：XYYYYYYYYYYZ（根据层级和序号变化）
--
-- 2. 后缀编号规则（12位数字）：
--    - 第1位：表示层级
--      * 0 = benchmark 主表
--      * 1 = Level 1（一级节点）
--      * 2 = Level 2（二级节点）
--      * 3 = Level 3（三级节点）
--    - 第2-11位：保留位（填0）
--    - 第12位：该层级内的序号（从1开始）
--
-- 3. 实际示例：
--    benchmark 主表：
--      a1b2c3d4-5678-90ab-cdef-000000000001  （0开头，序号1）
--
--    Level 1 节点：
--      a1b2c3d4-5678-90ab-cdef-100000000001  （1开头，第1个一级节点：Fixed Income）
--      a1b2c3d4-5678-90ab-cdef-100000000002  （1开头，第2个一级节点：Equity）
--      a1b2c3d4-5678-90ab-cdef-100000000003  （1开头，第3个一级节点：Alternatives）
--
--    Level 2 节点：
--      a1b2c3d4-5678-90ab-cdef-200000000001  （2开头，第1个二级节点：Government Debt）
--      a1b2c3d4-5678-90ab-cdef-200000000002  （2开头，第2个二级节点：Corporate Debt）
--      a1b2c3d4-5678-90ab-cdef-200000000003  （2开头，第3个二级节点：Developed Markets）
--      a1b2c3d4-5678-90ab-cdef-200000000004  （2开头，第4个二级节点：Emerging Markets）
--      a1b2c3d4-5678-90ab-cdef-200000000005  （2开头，第5个二级节点：Hedge Funds）
--
--    Level 3 节点：
--      a1b2c3d4-5678-90ab-cdef-300000000001  （3开头，第1个三级节点：EUR Government Bonds）
--      a1b2c3d4-5678-90ab-cdef-300000000002  （3开头，第2个三级节点：Non-EUR Government Bonds）
--      a1b2c3d4-5678-90ab-cdef-300000000003  （3开头，第3个三级节点：Europe Equity）
--      a1b2c3d4-5678-90ab-cdef-300000000004  （3开头，第4个三级节点：North America Equity）
--
-- 三、如何修改 ID（防止重复）
-- ------------------------------------------------
-- 方法1：修改 UUID 前缀（推荐）
--   将 a1b2c3d4-5678-90ab-cdef 改为其他值，例如：
--   - b2c3d4e5-6789-01bc-def0-（批量替换前缀）
--   - c3d4e5f6-7890-12cd-ef01-（批量替换前缀）
--
--   步骤：
--   1. 使用文本编辑器打开此脚本
--   2. 全局搜索：a1b2c3d4-5678-90ab-cdef
--   3. 全局替换为：b2c3d4e5-6789-01bc-def0（或其他随机UUID前缀）
--   4. 保存文件
--
-- 方法2：修改 business_id
--   将 BM-MIXED-2025102001 改为：
--   - BM-MIXED-2025102002（修改序号）
--   - BM-MIXED-2025102101（修改日期）
--   - BM-TEST-2025102001（修改前缀）
--
--   步骤：
--   1. 使用文本编辑器打开此脚本
--   2. 全局搜索：BM-MIXED-2025102001
--   3. 全局替换为：BM-MIXED-2025102002
--   4. 保存文件
--
-- 方法3：同时修改两者（最安全）
--   同时执行方法1和方法2的步骤
--
-- 四、修改检查清单
-- ------------------------------------------------
-- 修改完成后，请检查以下内容：
-- ☑ benchmark 主表的 id 是否唯一
-- ☑ benchmark 主表的 business_id 是否唯一
-- ☑ 所有 benchmark_details 的 id 是否唯一
-- ☑ 所有 benchmark_details 的 business_id 是否一致
-- ☑ 所有 benchmark_details 的 benchmark_id 是否指向 benchmark 主表的 id
-- ☑ 所有 Level 2/3 节点的 parent_id 是否正确指向父节点的 id
--
-- 五、快速生成新 UUID 前缀的方法
-- ------------------------------------------------
-- 在线生成：https://www.uuidgenerator.net/
-- 或使用以下格式手动编写（8-4-4-4-12位）：
--   xxxxxxxx-xxxx-xxxx-xxxx-
--   示例：
--   - a1b2c3d4-5678-90ab-cdef-
--   - b2c3d4e5-6789-01bc-def0-
--   - c3d4e5f6-7890-12cd-ef01-
--   - d4e5f6a7-8901-23de-f012-
--
-- 六、parent_id 关系对照表（重要！）
-- ------------------------------------------------
-- 如果修改了 ID，请确保 parent_id 关系正确：
--
-- Level 1 节点（parent_id = NULL）：
--   - Fixed Income:    a1b2c3d4-5678-90ab-cdef-100000000001
--   - Equity:          a1b2c3d4-5678-90ab-cdef-100000000002
--   - Alternatives:    a1b2c3d4-5678-90ab-cdef-100000000003
--
-- Level 2 节点（parent_id 指向 Level 1）：
--   - Government Debt:     parent_id = a1b2c3d4-5678-90ab-cdef-100000000001  (Fixed Income)
--   - Corporate Debt:      parent_id = a1b2c3d4-5678-90ab-cdef-100000000001  (Fixed Income)
--   - Developed Markets:   parent_id = a1b2c3d4-5678-90ab-cdef-100000000002  (Equity)
--   - Emerging Markets:    parent_id = a1b2c3d4-5678-90ab-cdef-100000000002  (Equity)
--   - Hedge Funds:         parent_id = a1b2c3d4-5678-90ab-cdef-100000000003  (Alternatives)
--
-- Level 3 节点（parent_id 指向 Level 2）：
--   - EUR Government Bonds:      parent_id = a1b2c3d4-5678-90ab-cdef-200000000001  (Government Debt)
--   - Non-EUR Government Bonds:  parent_id = a1b2c3d4-5678-90ab-cdef-200000000001  (Government Debt)
--   - Europe Equity:             parent_id = a1b2c3d4-5678-90ab-cdef-200000000003  (Developed Markets)
--   - North America Equity:      parent_id = a1b2c3d4-5678-90ab-cdef-200000000003  (Developed Markets)
--
-- 七、示例：完整修改流程
-- ------------------------------------------------
-- 假设要创建第二套测试数据，步骤如下：
--
-- 1. 复制本文件，命名为 benchmark_three_level_test_data_sqlserver_v2.sql
-- 2. 打开编辑器，执行以下替换：
--    搜索：a1b2c3d4-5678-90ab-cdef
--    替换：b2c3d4e5-6789-01bc-def0
--
-- 3. 执行第二次替换：
--    搜索：BM-MIXED-2025102001
--    替换：BM-MIXED-2025102002
--
-- 4. 修改 benchmark 名称（可选）：
--    搜索：Test Mixed-Level Tree Benchmark
--    替换：Test Mixed-Level Tree Benchmark V2
--
-- 5. 检查所有 parent_id 关系是否正确（应该自动更新）
-- 6. 保存文件并执行
--
-- ====================================================================
-- 结束
-- ====================================================================
