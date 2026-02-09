#!/bin/bash
# ============================================================================
#  SQL Safety Scanner (模块化版) - 入口脚本
#
#  用途: 扫描指定目录下所有 .sql 文件中的危险操作，生成检查报告
#  用法: bash main.sh <sql_directory>
#  输出: 在指定目录下生成 sql_safety_check_<timestamp>.txt
#
#  检测规则: 7条（DDL-001~003, DML-001~003, SYS-014）
#  退出码: 0=安全  1=有CRITICAL  2=有HIGH(无CRITICAL)
# ============================================================================

# 定位脚本所在目录
MAIN_DIR="$(cd "$(dirname " ")" && pwd)"

# ============================================================================
# 加载所有模块
# ============================================================================
source "$MAIN_DIR/lib/00_config.sh"
source "$MAIN_DIR/lib/01_utils.sh"
source "$MAIN_DIR/lib/02_preprocess.sh"
source "$MAIN_DIR/lib/03_delimiter.sh"
source "$MAIN_DIR/lib/04_parser.sh"
source "$MAIN_DIR/lib/05_rules.sh"
source "$MAIN_DIR/lib/06_report.sh"

# ============================================================================
# 参数校验
# ============================================================================
if [ $# -lt 1 ]; then
    echo "用法: bash $0 <sql_directory>"
    echo "示例: bash $0 /opt/sql/release"
    exit 1
fi

SCAN_DIR="${1%/}"

if [ ! -d "$SCAN_DIR" ]; then
    echo "[ERROR] 目录不存在: $SCAN_DIR"
    exit 1
fi

REPORT_FILE="${SCAN_DIR}/sql_safety_check_${TIMESTAMP_FILE}.txt"

# ============================================================================
# 主流程
# ============================================================================
main() {
    echo "============================================================"
    echo "  SQL Safety Scanner (Simple) 开始扫描..."
    echo "  目录: ${SCAN_DIR}"
    echo "============================================================"
    echo ""

    local sql_files=()
    while IFS= read -r f; do
        sql_files+=("$f")
    done < <(find "$SCAN_DIR" -maxdepth 1 -name "*.sql" -type f | sort)

    if [ ${#sql_files[@]} -eq 0 ]; then
        echo "[WARN] 未找到 .sql 文件: ${SCAN_DIR}"
        generate_report "$REPORT_FILE"
        exit 0
    fi

    echo "找到 ${#sql_files[@]} 个 SQL 文件"
    echo ""

    for sql_file in "${sql_files[@]}"; do
        local filename
        filename=$(basename "$sql_file")
        echo "扫描: ${filename}"

        local preprocessed="${TMP_DIR}/${filename}.pre"
        preprocess_file "$sql_file" "$preprocessed"

        local delimiter
        delimiter=$(detect_delimiter "$preprocessed")
        echo "  分隔符: ${delimiter}"

        local stmt_file="${TMP_DIR}/${filename}.stmts"
        parse_statements "$preprocessed" "$delimiter" "$stmt_file"

        local stmt_count
        stmt_count=$(wc -l < "$stmt_file")
        echo "  语句数: ${stmt_count}"

        local cur_stmt="" cur_line="" first=1
        while IFS=$'\t' read -r s_line s_text; do
            if [ "$first" -eq 1 ]; then
                cur_stmt="$s_text"; cur_line="$s_line"; first=0; continue
            fi
            scan_statement "$cur_stmt" "$filename" "$cur_line" "$s_text"
            cur_stmt="$s_text"; cur_line="$s_line"
        done < "$stmt_file"
        [ -n "$cur_stmt" ] && scan_statement "$cur_stmt" "$filename" "$cur_line" ""

        echo "  完成"
        echo ""
    done

    generate_report "$REPORT_FILE"

    local cc hc
    cc=$(grep -c '^CRITICAL|' "$FINDINGS_FILE" 2>/dev/null || true)
    hc=$(grep -c '^HIGH|' "$FINDINGS_FILE" 2>/dev/null || true)
    : "${cc:=0}" "${hc:=0}"
    [ "$cc" -gt 0 ] && exit 1
    [ "$hc" -gt 0 ] && exit 2
    exit 0
}

main
