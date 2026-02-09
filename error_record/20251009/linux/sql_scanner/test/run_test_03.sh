#!/bin/bash
# ============================================================================
#  测试 03_delimiter.sh - 分隔符检测
#  依赖: 无（独立模块）
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/lib/03_delimiter.sh"

PASS=0
FAIL=0
TEST_TMP=$(mktemp -d)
trap "rm -rf $TEST_TMP" EXIT

echo "========== 测试模块 03_delimiter =========="

# 测试1: detect_delimiter 函数是否存在
if declare -f detect_delimiter > /dev/null 2>&1; then
    echo "[PASS] detect_delimiter 函数已定义"
    ((PASS++))
else
    echo "[FAIL] detect_delimiter 函数未定义"
    ((FAIL++))
    echo "结果: ${PASS} 通过, ${FAIL} 失败"
    exit "$FAIL"
fi

# 测试2: 含 GO 的文件应返回 "GO"
go_file="${TEST_TMP}/go_test.sql"
cat > "$go_file" <<'EOF'
SELECT * FROM users
GO
DELETE FROM logs
GO
EOF
result=$(detect_delimiter "$go_file")
if [ "$result" = "GO" ]; then
    echo "[PASS] GO 分隔符正确检测 (返回: $result)"
    ((PASS++))
else
    echo "[FAIL] GO 分隔符检测失败 (期望: GO, 实际: $result)"
    ((FAIL++))
fi

# 测试3: 含分号的文件应返回 ";"
semi_file="${TEST_TMP}/semi_test.sql"
cat > "$semi_file" <<'EOF'
SELECT * FROM users;
DELETE FROM logs WHERE id = 1;
EOF
result=$(detect_delimiter "$semi_file")
if [ "$result" = ";" ]; then
    echo "[PASS] 分号分隔符正确检测 (返回: $result)"
    ((PASS++))
else
    echo "[FAIL] 分号分隔符检测失败 (期望: ;, 实际: $result)"
    ((FAIL++))
fi

# 测试4: 行尾 GO（前面有内容）也应检测为 GO
inline_go_file="${TEST_TMP}/inline_go.sql"
cat > "$inline_go_file" <<'EOF'
SELECT 1
PRINT 'done' GO
EOF
result=$(detect_delimiter "$inline_go_file")
if [ "$result" = "GO" ]; then
    echo "[PASS] 行尾 GO 正确检测 (返回: $result)"
    ((PASS++))
else
    echo "[FAIL] 行尾 GO 检测失败 (期望: GO, 实际: $result)"
    ((FAIL++))
fi

echo ""
echo "结果: ${PASS} 通过, ${FAIL} 失败"
[ "$FAIL" -eq 0 ] && echo ">> 模块 03_delimiter 测试全部通过!" || echo ">> 模块 03_delimiter 存在失败项!"
exit "$FAIL"
