#!/bin/bash
# ============================================================================
#  模块 02: 文件预处理 - BOM去除、换行符转换、编码检测
#  依赖: 无
# ============================================================================

preprocess_file() {
    local src="$1" dst="$2"

    if file "$src" 2>/dev/null | grep -qi "UTF-16"; then
        echo "  [WARN] 检测到UTF-16编码，自动转换: $(basename "$src")"
        iconv -f UTF-16 -t UTF-8 "$src" > "$dst" 2>/dev/null || {
            echo "  [ERROR] UTF-16转换失败，使用原文件"
            cp "$src" "$dst"
        }
    else
        cp "$src" "$dst"
    fi

    sed -i '1s/^\xEF\xBB\xBF//' "$dst" 2>/dev/null || true
    sed -i 's/\r$//' "$dst" 2>/dev/null || true
}
