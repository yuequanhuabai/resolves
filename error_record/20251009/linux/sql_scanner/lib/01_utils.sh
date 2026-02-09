#!/bin/bash
# ============================================================================
#  模块 01: 工具函数
#  依赖: 00_config.sh (FINDINGS_FILE)
# ============================================================================

record_finding() {
    local severity="$1" file="$2" line_no="$3" sql_snippet="$4" description="$5"
    local display_sql="${sql_snippet//$'\n'/ }"
    display_sql="${display_sql//$'\r'/ }"
    while [[ "$display_sql" == *"  "* ]]; do
        display_sql="${display_sql//  / }"
    done
    if [ ${#display_sql} -gt 200 ]; then
        display_sql="${display_sql:0:200}..."
    fi
    printf '%s|%s|%s|%s|%s\n' "$severity" "$file" "$line_no" "$display_sql" "$description" >> "$FINDINGS_FILE"
}
