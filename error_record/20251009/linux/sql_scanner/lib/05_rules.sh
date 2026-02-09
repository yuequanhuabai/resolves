#!/bin/bash
# ============================================================================
#  模块 05: 安全检测规则（7条）
#  依赖: 01_utils.sh (record_finding)
# ============================================================================

scan_statement() {
    local stmt="$1" file="$2" line_no="$3" next_stmt="${4:-}"

    local upper="${stmt^^}"
    local next_upper="${next_stmt^^}"

    local display="${stmt//$'\n'/ }"
    display="${display//$'\r'/ }"
    [ ${#display} -gt 200 ] && display="${display:0:200}..."


    # ================================================================
    # [规则 DDL-001] DROP DATABASE - 删除数据库
    # ================================================================
    if [[ "$upper" =~ DROP[[:space:]]+DATABASE ]]; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" "删除数据库操作，极高风险"
    fi
    # [规则 DDL-001 END]


    # ================================================================
    # [规则 DDL-002] DROP TABLE - 删除表（含重建表模式降级）
    # ================================================================
    if [[ "$upper" =~ DROP[[:space:]]+TABLE ]]; then
        local table_name=""
        local _tmp="${upper#*DROP TABLE }"
        _tmp="${_tmp#IF EXISTS }"
        _tmp="${_tmp#IF EXISTS}"
        table_name="${_tmp%% *}"
        table_name="${table_name//[\[\]]/}"
        table_name="${table_name##*.}"

        local is_rebuild=0
        if [ -n "$table_name" ] && [ -n "$next_upper" ]; then
            [[ "$next_upper" =~ CREATE[[:space:]]+TABLE ]] && \
            [[ "$next_upper" == *"$table_name"* ]] && is_rebuild=1
        fi

        if [ "$is_rebuild" -eq 1 ]; then
            record_finding "INFO" "$file" "$line_no" "$display" \
                "重建表模式（DROP + CREATE ${table_name}），已降级为INFO"
        else
            record_finding "CRITICAL" "$file" "$line_no" "$display" "删除表操作"
        fi
    fi
    # [规则 DDL-002 END]


    # ================================================================
    # [规则 DDL-003] TRUNCATE TABLE - 清空表
    # ================================================================
    if [[ "$upper" =~ TRUNCATE[[:space:]]+TABLE ]]; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" "清空表全部数据，不可回滚"
    fi
    # [规则 DDL-003 END]


    # ================================================================
    # [规则 DML-001] DELETE 无 WHERE - 删除全表数据
    # ================================================================
    if [[ "$upper" =~ DELETE[[:space:]] ]] && \
       [[ "$upper" != *" WHERE "* ]] && \
       [[ "$upper" != *"ON DELETE"* ]]; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" "DELETE 无 WHERE 条件，将删除全表数据"
    fi
    # [规则 DML-001 END]


    # ================================================================
    # [规则 DML-002] UPDATE 无 WHERE - 更新全表数据
    # ================================================================
    if [[ "$upper" =~ UPDATE[[:space:]]+[A-Z\[_] ]] && \
       [[ "$upper" != *" WHERE "* ]] && \
       [[ "$upper" != *"ON UPDATE"* ]] && \
       [[ "$upper" != *"UPDATE STATISTICS"* ]]; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" "UPDATE 无 WHERE 条件，将更新全表数据"
    fi
    # [规则 DML-002 END]


    # ================================================================
    # [规则 DML-003] DELETE/UPDATE 恒真条件 - WHERE 1=1 等
    # ================================================================
    local _p_tautology='WHERE[[:space:]]+(1[[:space:]]*=[[:space:]]*1|0[[:space:]]*=[[:space:]]*0)'
    if [[ "$upper" =~ (DELETE|UPDATE)[[:space:]] ]] && [[ "$upper" =~ $_p_tautology ]]; then
        record_finding "HIGH" "$file" "$line_no" "$display" "DELETE/UPDATE 使用恒真条件(如 1=1)，等价于无WHERE"
    fi
    # [规则 DML-003 END]


    # ================================================================
    # [规则 SYS-014] sp_msforeachtable / sp_msforeachdb
    # ================================================================
    if [[ "$upper" == *"SP_MSFOREACHTABLE"* ]] || [[ "$upper" == *"SP_MSFOREACHDB"* ]]; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" \
            "批量遍历操作（sp_msforeachtable/sp_msforeachdb），将对所有表或所有库执行命令，极高风险"
    fi
    # [规则 SYS-014 END]
}
