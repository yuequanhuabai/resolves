#!/bin/bash
# ============================================================================
#  测试 01_utils.sh - record_finding 函数
#  依赖: 00_config.sh
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/lib/00_config.sh"
source "$SCRIPT_DIR/lib/01_utils.sh"

PASS=0
FAIL=0

echo "========== 测试模块 01_utils =========="

# 测试1: record_finding 函数是否存在
if declare -f record_finding > /dev/null 2>&1; then
    echo "[PASS] record_finding 函数已定义"
    ((PASS++))
else
    echo "[FAIL] record_finding 函数未定义"
    ((FAIL++))
    echo "结果: ${PASS} 通过, ${FAIL} 失败"
    exit "$FAIL"
fi

# 测试2: 写入一条记录并检查格式
> "$FINDINGS_FILE"
record_finding "CRITICAL" "test.sql" "10" "DROP TABLE users" "删除表操作"

if grep -q '^CRITICAL|test.sql|10|DROP TABLE users|删除表操作$' "$FINDINGS_FILE"; then
    echo "[PASS] record_finding 输出格式正确"
    ((PASS++))
else
    echo "[FAIL] record_finding 输出格式不正确"
    echo "  实际内容: $(cat "$FINDINGS_FILE")"
    ((FAIL++))
fi

# 测试3: 长SQL自动截断（超过200字符）
> "$FINDINGS_FILE"
long_sql=$(printf 'SELECT %0.sa' {1..250})
record_finding "HIGH" "test.sql" "20" "$long_sql" "测试截断"

actual_sql=$(cut -d'|' -f4 "$FINDINGS_FILE")
if [[ "$actual_sql" == *"..."* ]] && [ ${#actual_sql} -le 204 ]; then
    echo "[PASS] 超长SQL已自动截断"
    ((PASS++))
else
    echo "[FAIL] 超长SQL未正确截断 (长度: ${#actual_sql})"
    ((FAIL++))
fi

# 测试4: 多次写入不覆盖
> "$FINDINGS_FILE"
record_finding "CRITICAL" "a.sql" "1" "DROP DATABASE db1" "描述1"
record_finding "HIGH" "b.sql" "2" "DELETE FROM t" "描述2"
line_count=$(wc -l < "$FINDINGS_FILE")
if [ "$line_count" -eq 2 ]; then
    echo "[PASS] 多次写入正确追加 (${line_count} 行)"
    ((PASS++))
else
    echo "[FAIL] 多次写入行数不对 (期望 2, 实际 ${line_count})"
    ((FAIL++))
fi

echo ""
echo "结果: ${PASS} 通过, ${FAIL} 失败"
[ "$FAIL" -eq 0 ] && echo ">> 模块 01_utils 测试全部通过!" || echo ">> 模块 01_utils 存在失败项!"
exit "$FAIL"
