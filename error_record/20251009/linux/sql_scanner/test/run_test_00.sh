#!/bin/bash
# ============================================================================
#  测试 00_config.sh - 全局配置
#  验证: TMP_DIR 创建、FINDINGS_FILE 存在、cleanup 函数定义
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/lib/00_config.sh"

PASS=0
FAIL=0

echo "========== 测试模块 00_config =========="

# 测试1: TMP_DIR 是否存在
if [ -d "$TMP_DIR" ]; then
    echo "[PASS] TMP_DIR 目录已创建: $TMP_DIR"
    ((PASS++))
else
    echo "[FAIL] TMP_DIR 目录未创建"
    ((FAIL++))
fi

# 测试2: FINDINGS_FILE 是否存在
if [ -f "$FINDINGS_FILE" ]; then
    echo "[PASS] FINDINGS_FILE 文件已创建: $FINDINGS_FILE"
    ((PASS++))
else
    echo "[FAIL] FINDINGS_FILE 文件未创建"
    ((FAIL++))
fi

# 测试3: TIMESTAMP 是否非空
if [ -n "$TIMESTAMP" ]; then
    echo "[PASS] TIMESTAMP 已设置: $TIMESTAMP"
    ((PASS++))
else
    echo "[FAIL] TIMESTAMP 为空"
    ((FAIL++))
fi

# 测试4: cleanup 函数是否存在
if declare -f cleanup > /dev/null 2>&1; then
    echo "[PASS] cleanup 函数已定义"
    ((PASS++))
else
    echo "[FAIL] cleanup 函数未定义"
    ((FAIL++))
fi

echo ""
echo "结果: ${PASS} 通过, ${FAIL} 失败"
[ "$FAIL" -eq 0 ] && echo ">> 模块 00_config 测试全部通过!" || echo ">> 模块 00_config 存在失败项!"
exit "$FAIL"
