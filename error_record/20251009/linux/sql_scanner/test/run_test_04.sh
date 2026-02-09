#!/bin/bash
# ============================================================================
#  测试 04_parser.sh - 语句解析
#  依赖: 无（独立模块）
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/lib/04_parser.sh"

PASS=0
FAIL=0
TEST_TMP=$(mktemp -d)
trap "rm -rf $TEST_TMP" EXIT

echo "========== 测试模块 04_parser =========="

# 测试1: parse_statements 函数是否存在
if declare -f parse_statements > /dev/null 2>&1; then
    echo "[PASS] parse_statements 函数已定义"
    ((PASS++))
else
    echo "[FAIL] parse_statements 函数未定义"
    ((FAIL++))
    echo "结果: ${PASS} 通过, ${FAIL} 失败"
    exit "$FAIL"
fi

# 测试2: 分号分隔 - 3条语句
sql_file="${TEST_TMP}/semi.sql"
cat > "$sql_file" <<'EOF'
SELECT * FROM users;
DELETE FROM logs WHERE id = 1;
UPDATE config SET val = 'x' WHERE key = 'k';
EOF
output="${TEST_TMP}/semi_out.txt"
parse_statements "$sql_file" ";" "$output"
count=$(wc -l < "$output")
if [ "$count" -eq 3 ]; then
    echo "[PASS] 分号分隔: 正确解析 3 条语句"
    ((PASS++))
else
    echo "[FAIL] 分号分隔: 期望 3 条, 实际 ${count} 条"
    echo "  内容:"
    cat "$output" | while read line; do echo "    $line"; done
    ((FAIL++))
fi

# 测试3: 注释应被跳过
sql_file2="${TEST_TMP}/comment.sql"
cat > "$sql_file2" <<'EOF'
-- 这是注释
SELECT 1;
/* 块注释 */
SELECT 2;
# 井号注释
SELECT 3;
EOF
output2="${TEST_TMP}/comment_out.txt"
parse_statements "$sql_file2" ";" "$output2"
count2=$(wc -l < "$output2")
if [ "$count2" -eq 3 ]; then
    echo "[PASS] 注释过滤: 正确跳过注释，解析出 3 条语句"
    ((PASS++))
else
    echo "[FAIL] 注释过滤: 期望 3 条, 实际 ${count2} 条"
    echo "  内容:"
    cat "$output2" | while read line; do echo "    $line"; done
    ((FAIL++))
fi

# 测试4: GO 分隔
sql_file3="${TEST_TMP}/go.sql"
cat > "$sql_file3" <<'EOF'
SELECT * FROM users
GO
DELETE FROM logs
GO
EOF
output3="${TEST_TMP}/go_out.txt"
parse_statements "$sql_file3" "GO" "$output3"
count3=$(wc -l < "$output3")
if [ "$count3" -eq 2 ]; then
    echo "[PASS] GO 分隔: 正确解析 2 条语句"
    ((PASS++))
else
    echo "[FAIL] GO 分隔: 期望 2 条, 实际 ${count3} 条"
    echo "  内容:"
    cat "$output3" | while read line; do echo "    $line"; done
    ((FAIL++))
fi

# 测试5: 行号追踪正确
first_line=$(head -1 "$output" | cut -f1)
if [ "$first_line" = "1" ]; then
    echo "[PASS] 行号追踪: 第一条语句起始行号为 1"
    ((PASS++))
else
    echo "[FAIL] 行号追踪: 期望起始行号 1, 实际 ${first_line}"
    ((FAIL++))
fi

# 测试6: 多行语句合并
sql_file4="${TEST_TMP}/multiline.sql"
cat > "$sql_file4" <<'EOF'
SELECT *
  FROM users
  WHERE id = 1;
EOF
output4="${TEST_TMP}/multiline_out.txt"
parse_statements "$sql_file4" ";" "$output4"
count4=$(wc -l < "$output4")
stmt_text=$(head -1 "$output4" | cut -f2)
if [ "$count4" -eq 1 ] && [[ "$stmt_text" == *"SELECT"* ]] && [[ "$stmt_text" == *"WHERE"* ]]; then
    echo "[PASS] 多行语句: 正确合并为 1 条完整语句"
    ((PASS++))
else
    echo "[FAIL] 多行语句: 合并有误 (行数: ${count4})"
    echo "  内容: $stmt_text"
    ((FAIL++))
fi

echo ""
echo "结果: ${PASS} 通过, ${FAIL} 失败"
[ "$FAIL" -eq 0 ] && echo ">> 模块 04_parser 测试全部通过!" || echo ">> 模块 04_parser 存在失败项!"
exit "$FAIL"
