#!/bin/bash
# ============================================================================
#  模块 03: 分隔符检测 - 自动识别 GO 或 分号(;)
#  依赖: 无
# ============================================================================

detect_delimiter() {
    local file="$1"
    if grep -qiE '^\s*GO\s*$' "$file" 2>/dev/null; then
        echo "GO"
    elif grep -qiE '\s+GO\s*$' "$file" 2>/dev/null; then
        echo "GO"
    else
        echo ";"
    fi
}
