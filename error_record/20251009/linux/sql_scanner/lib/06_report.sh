#!/bin/bash
# ============================================================================
#  模块 06: 报告生成
#  依赖: 00_config.sh (FINDINGS_FILE, SCAN_DIR, TIMESTAMP)
# ============================================================================

generate_report() {
    local report="$1"
    local critical_count high_count medium_count info_count total_findings
    critical_count=$(grep -c '^CRITICAL|' "$FINDINGS_FILE" 2>/dev/null || true)
    high_count=$(grep -c '^HIGH|' "$FINDINGS_FILE" 2>/dev/null || true)
    medium_count=$(grep -c '^MEDIUM|' "$FINDINGS_FILE" 2>/dev/null || true)
    info_count=$(grep -c '^INFO|' "$FINDINGS_FILE" 2>/dev/null || true)
    : "${critical_count:=0}" "${high_count:=0}" "${medium_count:=0}" "${info_count:=0}"
    total_findings=$((critical_count + high_count + medium_count + info_count))
    local scanned_count
    scanned_count=$(find "$SCAN_DIR" -maxdepth 1 -name "*.sql" -type f 2>/dev/null | wc -l)

    {
        echo "============================================================"
        echo "  SQL Safety Scanner (Simple) - 安全扫描报告"
        echo "============================================================"
        echo "  扫描时间 : ${TIMESTAMP}"
        echo "  扫描目录 : ${SCAN_DIR}"
        echo "  文件数量 : ${scanned_count}"
        echo "  发现总数 : ${total_findings}"
        echo "============================================================"
        echo ""

        if [ "$total_findings" -eq 0 ]; then
            echo "  PASSED - 未发现风险操作"
            echo ""
            echo "============================================================"
        else
            for severity in CRITICAL HIGH MEDIUM INFO; do
                local count
                count=$(grep -c "^${severity}|" "$FINDINGS_FILE" 2>/dev/null || true)
                : "${count:=0}"
                if [ "$count" -gt 0 ]; then
                    echo "------------------------------------------------------------"
                    echo "  ${severity} (${count})"
                    echo "------------------------------------------------------------"
                    echo ""
                    while IFS='|' read -r sev f_name f_line f_sql f_desc; do
                        echo "  [${sev}] ${f_name}:${f_line}"
                        echo "    ${f_sql}"
                        echo "    >> ${f_desc}"
                        echo ""
                    done < <(grep "^${severity}|" "$FINDINGS_FILE")
                fi
            done

            echo "============================================================"
            echo "  汇总"
            echo "------------------------------------------------------------"
            echo "  CRITICAL : ${critical_count}"
            echo "  HIGH     : ${high_count}"
            echo "  MEDIUM   : ${medium_count}"
            echo "  INFO     : ${info_count}"
            echo "------------------------------------------------------------"
            if [ "$critical_count" -gt 0 ]; then
                echo "  结论: BLOCKED - 存在 CRITICAL 级别风险，必须人工审批"
            elif [ "$high_count" -gt 0 ]; then
                echo "  结论: WARNING - 存在 HIGH 级别风险，建议人工确认"
            else
                echo "  结论: NOTICE - 仅存在中低级别提示，建议复核"
            fi
            echo "============================================================"
        fi
    } > "$report"

    cat "$report"
    echo ""
    echo "报告已生成: ${report}"
}
