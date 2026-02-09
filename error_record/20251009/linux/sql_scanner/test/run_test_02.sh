#!/bin/bash
# ============================================================================
#  测试 02_preprocess.sh - 文件预处理
#  依赖: 无（独立模块）
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/lib/02_preprocess.sh"

PASS=0
FAIL=0
TEST_TMP=$(mktemp -d)
trap "rm -rf $TEST_TMP" EXIT

echo "========== 测试模块 02_preprocess =========="

# 测试1: preprocess_file 函数是否存在
if declare -f preprocess_file > /dev/null 2>&1; then
    echo "[PASS] preprocess_file 函数已定义"
    ((PASS++))
else
    echo "[FAIL] preprocess_file 函数未定义"
    ((FAIL++))
    echo "结果: ${PASS} 通过, ${FAIL} 失败"
    exit "$FAIL"
fi

# 测试2: CRLF 换行符转换
src_file="${TEST_TMP}/crlf_test.sql"
dst_file="${TEST_TMP}/crlf_test_out.sql"
printf 'SELECT 1;\r\nSELECT 2;\r\n' > "$src_file"
preprocess_file "$src_file" "$dst_file"

if grep -qP '\r' "$dst_file" 2>/dev/null; then
    echo "[FAIL] CRLF 未被去除"
    ((FAIL++))
else
    echo "[PASS] CRLF 已正确去除"
    ((PASS++))
fi

# 测试3: 普通文件正常拷贝
src_file2="${TEST_TMP}/normal.sql"
dst_file2="${TEST_TMP}/normal_out.sql"
echo "SELECT * FROM users;" > "$src_file2"
preprocess_file "$src_file2" "$dst_file2"

if [ -f "$dst_file2" ] && grep -q "SELECT \* FROM users" "$dst_file2"; then
    echo "[PASS] 普通文件正确拷贝"
    ((PASS++))
else
    echo "[FAIL] 普通文件拷贝失败"
    ((FAIL++))
fi

# 测试4: BOM 去除
src_file3="${TEST_TMP}/bom_test.sql"
dst_file3="${TEST_TMP}/bom_test_out.sql"
printf '\xEF\xBB\xBFSELECT 1;' > "$src_file3"
preprocess_file "$src_file3" "$dst_file3"

first_bytes=$(xxd -l 3 "$dst_file3" 2>/dev/null | head -1)
if [[ "$first_bytes" != *"efbb bf"* ]]; then
    echo "[PASS] BOM 已去除"
    ((PASS++))
else
    echo "[FAIL] BOM 未被去除"
    ((FAIL++))
fi

echo ""
echo "结果: ${PASS} 通过, ${FAIL} 失败"
[ "$FAIL" -eq 0 ] && echo ">> 模块 02_preprocess 测试全部通过!" || echo ">> 模块 02_preprocess 存在失败项!"
exit "$FAIL"
