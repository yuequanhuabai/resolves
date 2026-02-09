#!/bin/bash
# ============================================================================
#  测试 06_report.sh - 报告生成
#  依赖: 00_config.sh
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/lib/00_config.sh"
source "$SCRIPT_DIR/lib/06_report.sh"

PASS=0
FAIL=0
TEST_TMP=$(mktemp -d)
trap "rm -rf $TEST_TMP" EXIT

echo "========== 测试模块 06_report =========="

# 测试1: generate_report 函数是否存在
if declare -f generate_report > /dev/null 2>&1; then
    echo "[PASS] generate_report 函数已定义"
    ((PASS++))
else
    echo "[FAIL] generate_report 函数未定义"
    ((FAIL++))
    echo "结果: ${PASS} 通过, ${FAIL} 失败"
    exit "$FAIL"
fi

# 准备: 设置 SCAN_DIR 为测试目录
SCAN_DIR="$TEST_TMP"
# 创建一个假 sql 文件让 find 能找到
touch "${TEST_TMP}/dummy.sql"

# 测试2: 无发现时 → PASSED
> "$FINDINGS_FILE"
report1="${TEST_TMP}/report_pass.txt"
generate_report "$report1" > /dev/null 2>&1

if [ -f "$report1" ] && grep -q "PASSED" "$report1"; then
    echo "[PASS] 无发现时报告显示 PASSED"
    ((PASS++))
else
    echo "[FAIL] 无发现时报告未显示 PASSED"
    ((FAIL++))
fi

# 测试3: 有 CRITICAL 发现时 → BLOCKED
> "$FINDINGS_FILE"
echo 'CRITICAL|test.sql|1|DROP TABLE users|删除表操作' >> "$FINDINGS_FILE"
report2="${TEST_TMP}/report_blocked.txt"
generate_report "$report2" > /dev/null 2>&1

if grep -q "BLOCKED" "$report2"; then
    echo "[PASS] 有CRITICAL时报告显示 BLOCKED"
    ((PASS++))
else
    echo "[FAIL] 有CRITICAL时报告未显示 BLOCKED"
    ((FAIL++))
fi

# 测试4: 只有 HIGH 发现时 → WARNING
> "$FINDINGS_FILE"
echo 'HIGH|test.sql|5|DELETE FROM t WHERE 1=1|恒真条件' >> "$FINDINGS_FILE"
report3="${TEST_TMP}/report_warning.txt"
generate_report "$report3" > /dev/null 2>&1

if grep -q "WARNING" "$report3"; then
    echo "[PASS] 只有HIGH时报告显示 WARNING"
    ((PASS++))
else
    echo "[FAIL] 只有HIGH时报告未显示 WARNING"
    ((FAIL++))
fi

# 测试5: 报告包含汇总数字
> "$FINDINGS_FILE"
echo 'CRITICAL|a.sql|1|DROP DATABASE db|删除库' >> "$FINDINGS_FILE"
echo 'CRITICAL|b.sql|2|TRUNCATE TABLE t|清空表' >> "$FINDINGS_FILE"
echo 'HIGH|c.sql|3|DELETE WHERE 1=1|恒真' >> "$FINDINGS_FILE"
report4="${TEST_TMP}/report_summary.txt"
generate_report "$report4" > /dev/null 2>&1

if grep -q "CRITICAL : 2" "$report4" && grep -q "HIGH     : 1" "$report4"; then
    echo "[PASS] 报告汇总数字正确 (CRITICAL:2, HIGH:1)"
    ((PASS++))
else
    echo "[FAIL] 报告汇总数字不正确"
    grep -E "(CRITICAL|HIGH)" "$report4" | while read line; do echo "  $line"; done
    ((FAIL++))
fi

echo ""
echo "结果: ${PASS} 通过, ${FAIL} 失败"
[ "$FAIL" -eq 0 ] && echo ">> 模块 06_report 测试全部通过!" || echo ">> 模块 06_report 存在失败项!"
exit "$FAIL"
