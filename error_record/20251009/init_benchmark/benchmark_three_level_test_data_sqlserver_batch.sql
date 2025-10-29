-- ====================================================================
-- Benchmark 混合层级树结构批量测试数据生成脚本 - SQL Server 版本
-- 创建日期: 2025-10-29
-- 说明: 支持批量生成 N 条 benchmark 主表记录 + 每条对应 12 条混合层级树结构的详情数据
-- 特点:
--   1. 可配置生成的记录数（修改 @RecordCount 变量）
--   2. 同时包含二级树和三级树，测试动态层级渲染
--   3. 自动生成 UUID，business_id 使用序号后缀
-- 字段完全匹配 SQL Server 表结构：
--   - benchmark: 18个字段（无 tenant_id）
--   - benchmark_details: 12个字段，包含三级树（3个一级 + 5个二级 + 4个三级）
-- ====================================================================

-- ====================================================================
-- 配置参数：修改这里设置要生成的 benchmark 记录数
-- ====================================================================
DECLARE @RecordCount INT = 10;  -- 👈 修改这里：要生成多少条 benchmark 记录

-- ====================================================================
-- 循环变量声明
-- ====================================================================
DECLARE @Counter INT = 1;
DECLARE @BenchmarkId NVARCHAR(36);
DECLARE @BusinessId NVARCHAR(50);
DECLARE @CurrentDateTime NVARCHAR(20) = FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss');

-- 一级节点 ID 变量
DECLARE @L1_FixedIncome NVARCHAR(36);
DECLARE @L1_Equity NVARCHAR(36);
DECLARE @L1_Alternatives NVARCHAR(36);

-- 二级节点 ID 变量
DECLARE @L2_GovDebt NVARCHAR(36);
DECLARE @L2_CorpDebt NVARCHAR(36);
DECLARE @L2_DevMarkets NVARCHAR(36);
DECLARE @L2_EmgMarkets NVARCHAR(36);
DECLARE @L2_HedgeFunds NVARCHAR(36);

-- ====================================================================
-- 开始循环生成数据
-- ====================================================================
PRINT '========================================';
PRINT '开始生成批量测试数据...';
PRINT '预计生成: ' + CAST(@RecordCount AS NVARCHAR) + ' 条 benchmark 记录';
PRINT '预计生成: ' + CAST(@RecordCount * 12 AS NVARCHAR) + ' 条 benchmark_details 记录';
PRINT '========================================';
PRINT '';

WHILE @Counter <= @RecordCount
BEGIN
    -- 1. 生成当前 benchmark 的 UUID 和 business_id
    SET @BenchmarkId = LOWER(NEWID());
    SET @BusinessId = 'BS-MIXED-20251029-' + CAST(@Counter AS NVARCHAR);

    PRINT '正在插入第 ' + CAST(@Counter AS NVARCHAR) + ' 条记录...';
    PRINT '  Benchmark ID: ' + @BenchmarkId;
    PRINT '  Business ID: ' + @BusinessId;

    -- ====================================================================
    -- 2. 插入 benchmark 主表数据
    -- ====================================================================
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
        @BenchmarkId,
        @BusinessId,
        NULL,
        N'Test-' + @BusinessId,
        0,
        1,
        1,
        N'admin',
        @CurrentDateTime,
        NULL,
        NULL,
        NULL,
        NULL,
        0,
        @CurrentDateTime,
        NULL,
        0,
        0
    );

    -- ====================================================================
    -- 3. 插入 benchmark_details 详情数据（混合层级树结构 - 12条记录）
    -- ====================================================================

    -- ------------------------------------------------------------------
    -- Level 1: Fixed Income (一级节点 - 固定收益)
    -- ------------------------------------------------------------------
    SET @L1_FixedIncome = LOWER(NEWID());
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
        @L1_FixedIncome,
        @BusinessId,
        @BenchmarkId,
        NULL,
        N'Fixed Income',
        1,
        40.00,
        0
    );

    -- ------------------------------------------------------------------
    -- Level 2: Government Debt (二级节点 - 政府债券，属于 Fixed Income)
    -- ------------------------------------------------------------------
    SET @L2_GovDebt = LOWER(NEWID());
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
        @L2_GovDebt,
        @BusinessId,
        @BenchmarkId,
        @L1_FixedIncome,
        N'Government Debt',
        2,
        25.00,
        0
    );

    -- ------------------------------------------------------------------
    -- Level 3: EUR Government Bonds (三级节点，属于 Government Debt)
    -- ------------------------------------------------------------------
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
        LOWER(NEWID()),
        @BusinessId,
        @BenchmarkId,
        @L2_GovDebt,
        N'EUR Government Bonds',
        3,
        15.00,
        0
    );

    -- ------------------------------------------------------------------
    -- Level 3: Non-EUR Government Bonds (三级节点，属于 Government Debt)
    -- ------------------------------------------------------------------
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
        LOWER(NEWID()),
        @BusinessId,
        @BenchmarkId,
        @L2_GovDebt,
        N'Non-EUR Government Bonds',
        3,
        10.00,
        0
    );

    -- ------------------------------------------------------------------
    -- Level 2: Corporate Debt (二级叶子节点 - 企业债券，属于 Fixed Income)
    -- ------------------------------------------------------------------
    SET @L2_CorpDebt = LOWER(NEWID());
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
        @L2_CorpDebt,
        @BusinessId,
        @BenchmarkId,
        @L1_FixedIncome,
        N'Corporate Debt',
        2,
        15.00,
        0
    );

    -- ------------------------------------------------------------------
    -- Level 1: Equity (一级节点 - 股票)
    -- ------------------------------------------------------------------
    SET @L1_Equity = LOWER(NEWID());
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
        @L1_Equity,
        @BusinessId,
        @BenchmarkId,
        NULL,
        N'Equity',
        1,
        60.00,
        0
    );

    -- ------------------------------------------------------------------
    -- Level 2: Developed Markets (二级节点 - 发达市场，属于 Equity)
    -- ------------------------------------------------------------------
    SET @L2_DevMarkets = LOWER(NEWID());
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
        @L2_DevMarkets,
        @BusinessId,
        @BenchmarkId,
        @L1_Equity,
        N'Developed Markets',
        2,
        40.00,
        0
    );

    -- ------------------------------------------------------------------
    -- Level 3: Europe Equity (三级节点，属于 Developed Markets)
    -- ------------------------------------------------------------------
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
        LOWER(NEWID()),
        @BusinessId,
        @BenchmarkId,
        @L2_DevMarkets,
        N'Europe Equity',
        3,
        20.00,
        0
    );

    -- ------------------------------------------------------------------
    -- Level 3: North America Equity (三级节点，属于 Developed Markets)
    -- ------------------------------------------------------------------
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
        LOWER(NEWID()),
        @BusinessId,
        @BenchmarkId,
        @L2_DevMarkets,
        N'North America Equity',
        3,
        20.00,
        0
    );

    -- ------------------------------------------------------------------
    -- Level 2: Emerging Markets (二级叶子节点 - 新兴市场，属于 Equity)
    -- ------------------------------------------------------------------
    SET @L2_EmgMarkets = LOWER(NEWID());
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
        @L2_EmgMarkets,
        @BusinessId,
        @BenchmarkId,
        @L1_Equity,
        N'Emerging Markets',
        2,
        20.00,
        0
    );

    -- ------------------------------------------------------------------
    -- Level 1: Alternatives (一级节点 - 另类投资)
    -- ------------------------------------------------------------------
    SET @L1_Alternatives = LOWER(NEWID());
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
        @L1_Alternatives,
        @BusinessId,
        @BenchmarkId,
        NULL,
        N'Alternatives',
        1,
        0.00,
        0
    );

    -- ------------------------------------------------------------------
    -- Level 2: Hedge Funds (二级叶子节点 - 对冲基金，属于 Alternatives)
    -- ------------------------------------------------------------------
    SET @L2_HedgeFunds = LOWER(NEWID());
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
        @L2_HedgeFunds,
        @BusinessId,
        @BenchmarkId,
        @L1_Alternatives,
        N'Hedge Funds',
        2,
        0.00,
        0
    );

    PRINT '  ✓ 已插入 1 条 benchmark + 12 条 benchmark_details';
    PRINT '';

    -- 计数器递增
    SET @Counter = @Counter + 1;
END

-- ====================================================================
-- 完成提示
-- ====================================================================
PRINT '========================================';
PRINT '批量数据生成完成！';
PRINT '实际生成: ' + CAST(@RecordCount AS NVARCHAR) + ' 条 benchmark 记录';
PRINT '实际生成: ' + CAST(@RecordCount * 12 AS NVARCHAR) + ' 条 benchmark_details 记录';
PRINT '========================================';

-- ====================================================================
-- 数据验证查询（可选）
-- ====================================================================
-- 查看生成的 benchmark 记录
-- SELECT COUNT(*) AS benchmark_count FROM benchmark WHERE business_id LIKE 'BS-MIXED-20251029-%';

-- 查看生成的 benchmark_details 记录
-- SELECT COUNT(*) AS details_count FROM benchmark_details WHERE business_id LIKE 'BS-MIXED-20251029-%';

-- 查看树形结构示例（第一条记录）
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
