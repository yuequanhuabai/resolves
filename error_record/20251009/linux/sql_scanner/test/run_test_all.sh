#!/bin/bash
# ============================================================================
#  一键运行全部模块测试
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOTAL_PASS=0
TOTAL_FAIL=0

echo "============================================================"
echo "  SQL Scanner 模块化测试 - 全部运行"
echo "============================================================"
echo ""

for test_script in "$SCRIPT_DIR"/run_test_0[0-6].sh; do
    if [ -f "$test_script" ]; then
        bash "$test_script"
        exit_code=$?
        if [ "$exit_code" -eq 0 ]; then
            ((TOTAL_PASS++))
        else
            ((TOTAL_FAIL++))
        fi
        echo ""
    fi
done

echo "============================================================"
echo "  总结: ${TOTAL_PASS} 个模块全部通过, ${TOTAL_FAIL} 个模块存在失败"
echo "============================================================"

if [ "$TOTAL_FAIL" -eq 0 ]; then
    echo ""
    echo "  所有模块测试通过! 可以放心使用 main.sh 运行完整扫描。"
    echo ""
fi

exit "$TOTAL_FAIL"
