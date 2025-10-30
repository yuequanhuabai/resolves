#!/bin/bash
# ====================================================================
# Benchmark 混合层级树结构测试数据生成脚本 - Bash Shell 版本
# 创建日期: 2025-10-30
# 说明: 生成静态 SQL INSERT 语句到 example.sql 文件
# 用途: 可在 Linux 环境中执行，生成可预览的 SQL 文件
# ====================================================================

# ====================================================================
# 配置参数：修改这里设置要生成的 benchmark 记录数
# ====================================================================
RecordCount=2  # 👈 修改这里：要生成多少条 benchmark 记录

# ====================================================================
# 脚本配置
# ====================================================================
OUTPUT_FILE="example.sql"
CURRENT_DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ====================================================================
# UUID 生成函数（兼容多种环境）
# ====================================================================
generate_uuid() {
    # 方法1: 使用 uuidgen（如果可用）
    if command -v uuidgen &> /dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
        return
    fi

    # 方法2: 使用 /proc/sys/kernel/random/uuid（Linux）
    if [ -f /proc/sys/kernel/random/uuid ]; then
        cat /proc/sys/kernel/random/uuid
        return
    fi

    # 方法3: 使用 Python（如果可用）
    if command -v python3 &> /dev/null; then
        python3 -c "import uuid; print(str(uuid.uuid4()))"
        return
    fi

    if command -v python &> /dev/null; then
        python -c "import uuid; print(str(uuid.uuid4()))"
        return
    fi

    # 方法4: 手动生成（格式兼容但非真随机）
    local hex_chars="0123456789abcdef"
    local uuid=""
    for i in {1..32}; do
        uuid+="${hex_chars:$((RANDOM % 16)):1}"
    done
    echo "${uuid:0:8}-${uuid:8:4}-4${uuid:13:3}-${hex_chars:$((8 + RANDOM % 4)):1}${uuid:17:3}-${uuid:20:12}"
}

# ====================================================================
# 初始化输出文件
# ====================================================================
cd "$SCRIPT_DIR"
cat > "$OUTPUT_FILE" << 'EOF'
-- ====================================================================
-- Benchmark 测试数据 SQL 脚本 - 自动生成
-- 生成日期: 由 generate_benchmark_sql.sh 脚本生成
-- 说明: 包含 benchmark 主表记录 + 混合层级树结构的详情数据
-- 用途: 可预览 SQL 语句，确认无误后再执行
-- ====================================================================

EOF

# ====================================================================
# 开始生成数据
# ====================================================================
echo "========================================"
echo "开始生成批量测试数据..."
echo "预计生成: ${RecordCount} 条 benchmark 记录"
echo "预计生成: $((RecordCount * 12)) 条 benchmark_details 记录"
echo "输出文件: ${OUTPUT_FILE}"
echo "========================================"
echo ""

# ====================================================================
# 循环生成每条 benchmark 及其 details
# ====================================================================
for ((counter=1; counter<=RecordCount; counter++)); do
    echo "正在生成第 ${counter} 条记录..."

    # 生成 UUID
    BENCHMARK_ID=$(generate_uuid)
    BUSINESS_ID="BS-MIXED-20251029-${counter}"

    # 生成一级节点 UUID
    L1_FIXED_INCOME=$(generate_uuid)
    L1_EQUITY=$(generate_uuid)
    L1_ALTERNATIVES=$(generate_uuid)

    # 生成二级节点 UUID
    L2_GOV_DEBT=$(generate_uuid)
    L2_CORP_DEBT=$(generate_uuid)
    L2_DEV_MARKETS=$(generate_uuid)
    L2_EMG_MARKETS=$(generate_uuid)
    L2_HEDGE_FUNDS=$(generate_uuid)

    # 生成三级节点 UUID
    L3_EUR_GOV=$(generate_uuid)
    L3_NON_EUR_GOV=$(generate_uuid)
    L3_EUROPE_EQ=$(generate_uuid)
    L3_NA_EQ=$(generate_uuid)

    echo "  Benchmark ID: ${BENCHMARK_ID}"
    echo "  Business ID: ${BUSINESS_ID}"

    # ====================================================================
    # 写入分组注释
    # ====================================================================
    cat >> "$OUTPUT_FILE" << EOF
-- ====================================================================
-- 第 ${counter} 组数据：Benchmark + 12 条 Details
-- ====================================================================

EOF

    # ====================================================================
    # 插入 benchmark 主表数据
    # ====================================================================
    cat >> "$OUTPUT_FILE" << EOF
-- Benchmark: ${BUSINESS_ID}
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
    '${BENCHMARK_ID}',
    '${BUSINESS_ID}',
    NULL,
    N'Test-${BUSINESS_ID}',
    0,
    1,
    1,
    N'admin',
    '${CURRENT_DATETIME}',
    NULL,
    NULL,
    NULL,
    NULL,
    0,
    '${CURRENT_DATETIME}',
    NULL,
    0,
    0
);

EOF

    # ====================================================================
    # 插入 benchmark_details 详情数据（12条记录）
    # ====================================================================
    cat >> "$OUTPUT_FILE" << EOF
-- ====================================================================
-- Benchmark ${BUSINESS_ID} Details (12 条详情记录 - 混合三级树结构)
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
    '${L1_FIXED_INCOME}',
    '${BUSINESS_ID}',
    '${BENCHMARK_ID}',
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
    '${L2_GOV_DEBT}',
    '${BUSINESS_ID}',
    '${BENCHMARK_ID}',
    '${L1_FIXED_INCOME}',
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
    '${L3_EUR_GOV}',
    '${BUSINESS_ID}',
    '${BENCHMARK_ID}',
    '${L2_GOV_DEBT}',
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
    '${L3_NON_EUR_GOV}',
    '${BUSINESS_ID}',
    '${BENCHMARK_ID}',
    '${L2_GOV_DEBT}',
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
    '${L2_CORP_DEBT}',
    '${BUSINESS_ID}',
    '${BENCHMARK_ID}',
    '${L1_FIXED_INCOME}',
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
    '${L1_EQUITY}',
    '${BUSINESS_ID}',
    '${BENCHMARK_ID}',
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
    '${L2_DEV_MARKETS}',
    '${BUSINESS_ID}',
    '${BENCHMARK_ID}',
    '${L1_EQUITY}',
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
    '${L3_EUROPE_EQ}',
    '${BUSINESS_ID}',
    '${BENCHMARK_ID}',
    '${L2_DEV_MARKETS}',
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
    '${L3_NA_EQ}',
    '${BUSINESS_ID}',
    '${BENCHMARK_ID}',
    '${L2_DEV_MARKETS}',
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
    '${L2_EMG_MARKETS}',
    '${BUSINESS_ID}',
    '${BENCHMARK_ID}',
    '${L1_EQUITY}',
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
    '${L1_ALTERNATIVES}',
    '${BUSINESS_ID}',
    '${BENCHMARK_ID}',
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
    '${L2_HEDGE_FUNDS}',
    '${BUSINESS_ID}',
    '${BENCHMARK_ID}',
    '${L1_ALTERNATIVES}',
    N'Hedge Funds',
    2,
    0.00,
    0
);

EOF

    echo "  ✓ 已生成 1 条 benchmark + 12 条 benchmark_details"
    echo ""
done

# ====================================================================
# 写入文件尾部注释
# ====================================================================
cat >> "$OUTPUT_FILE" << EOF
-- ====================================================================
-- 数据验证查询（可选）
-- ====================================================================
-- 查看生成的 benchmark 记录
-- SELECT * FROM benchmark WHERE business_id LIKE 'BS-MIXED-20251029-%';

-- 查看生成的 benchmark_details 记录
-- SELECT * FROM benchmark_details WHERE business_id LIKE 'BS-MIXED-20251029-%' ORDER BY business_id, asset_level, asset_classification;

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
EOF

# ====================================================================
# 完成提示
# ====================================================================
echo "========================================"
echo "批量数据生成完成！"
echo "实际生成: ${RecordCount} 条 benchmark 记录"
echo "实际生成: $((RecordCount * 12)) 条 benchmark_details 记录"
echo "总计: $((RecordCount * 13)) 条 INSERT 语句"
echo "输出文件: ${SCRIPT_DIR}/${OUTPUT_FILE}"
echo "========================================"
echo ""
echo "使用提示："
echo "1. 打开 ${OUTPUT_FILE} 文件预览生成的 SQL 语句"
echo "2. 确认无误后在 SQL Server 中执行"
echo "3. 若需修改生成数量，编辑本脚本第 11 行的 RecordCount 变量"
echo ""
