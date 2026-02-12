#!/bin/bash
# ============================================================================
#  Simple SQL Safety Scanner v2 - SQL脚本安全扫描工具（精简版）
#
#  用途: 扫描指定目录下所有 .sql 文件中的危险操作，生成检查报告
#  用法: bash sql_safety_scan_version4.sh [-r] <sql_directory>
#        -r  递归扫描子目录
#  输出: 在指定目录下生成 sql_safety_check_<timestamp>.txt
#
#  检测规则: 6条（DDL-001~003, DML-001~002, SYS-014）
#  退出码: 0=安全  1=有CRITICAL  2=有HIGH(无CRITICAL)
# ============================================================================

set -o pipefail

# ============================================================================
# [模块] 全局配置
# ============================================================================

SCAN_DIR=""
REPORT_FILE=""
RECURSIVE=0
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TIMESTAMP_FILE=$(date '+%Y%m%d_%H%M%S')

# [Fix-8] 字段分隔符：使用 SOH（\x01）避免与 SQL 内容中的 | 冲突
SEP=$'\x01'

TMP_DIR=$(mktemp -d)
FINDINGS_FILE="${TMP_DIR}/findings.txt"
> "$FINDINGS_FILE"

cleanup() { rm -rf "$TMP_DIR" 2>/dev/null; }
trap cleanup EXIT

# ============================================================================
# [模块] 参数校验  [Fix-2] 支持 -r 递归扫描选项
# ============================================================================

while getopts "r" opt; do
    case "$opt" in
        r) RECURSIVE=1 ;;
        *)
            echo "用法: bash $0 [-r] <sql_directory>"
            echo "  -r  递归扫描子目录"
            echo "示例: bash $0 /opt/sql/release"
            echo "      bash $0 -r /opt/sql/release"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -lt 1 ]; then
    echo "用法: bash $0 [-r] <sql_directory>"
    echo "  -r  递归扫描子目录"
    echo "示例: bash $0 /opt/sql/release"
    echo "      bash $0 -r /opt/sql/release"
    exit 1
fi

SCAN_DIR="${1%/}"

if [ ! -d "$SCAN_DIR" ]; then
    echo "[ERROR] 目录不存在: $SCAN_DIR"
    exit 1
fi

REPORT_FILE="${SCAN_DIR}/sql_safety_check_${TIMESTAMP_FILE}.txt"

# ============================================================================
# [模块] 工具函数
# ============================================================================

# [Fix-2] 查找 SQL 文件（根据 RECURSIVE 标志决定是否递归）
find_sql_files() {
    local dir="$1"
    if [ "$RECURSIVE" -eq 1 ]; then
        find "$dir" -name "*.sql" -type f 2>/dev/null | sort
    else
        find "$dir" -maxdepth 1 -name "*.sql" -type f 2>/dev/null | sort
    fi
}

# [Fix-8] 使用 SEP（\x01）作为字段分隔符，替代 |
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
    printf '%s%s%s%s%s%s%s%s%s\n' \
        "$severity" "$SEP" "$file" "$SEP" "$line_no" "$SEP" "$display_sql" "$SEP" "$description" \
        >> "$FINDINGS_FILE"
}

# [Fix-5] 剥离单引号字符串内容和行内块注释，用于规则匹配
#   - 'xxx' -> ''  (保留引号作为占位，清除内容，避免字符串内关键字误报)
#   - /* xxx */ -> 空格
strip_strings_and_comments() {
    local input="$1"
    local result="$input"

    # Step 1: 移除行内块注释 /* ... */
    while [[ "$result" == *'/*'*'*/'* ]]; do
        local before="${result%%/\**}"
        local after="${result#*\*/}"
        result="${before} ${after}"
    done

    # Step 2: 处理单引号字符串
    #   先将转义的 '' 替换掉，再移除 '...' 内容
    result=$(printf '%s' "$result" | sed "s/''//g; s/'[^']*'/''/g")
    echo "$result"
}

# ============================================================================
# [模块] 文件预处理 - BOM去除、换行符转换、编码检测
# [Fix-6] 使用临时文件替代 sed -i，兼容 macOS 和 Linux
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

    # [Fix-6] 使用临时文件方式替代 sed -i，避免 macOS 兼容问题
    local tmp_sed="${dst}.sedtmp"
    sed '1s/^\xEF\xBB\xBF//' "$dst" > "$tmp_sed" 2>/dev/null && mv "$tmp_sed" "$dst" || true
    sed 's/\r$//' "$dst" > "$tmp_sed" 2>/dev/null && mv "$tmp_sed" "$dst" || true
    rm -f "$tmp_sed" 2>/dev/null
}

# ============================================================================
# [模块] 分隔符检测 - 自动识别 GO 或 分号(;)
# [Fix-7] 先过滤注释行，避免注释中的 GO 导致误判
# ============================================================================

detect_delimiter() {
    local file="$1"

    # 过滤单行注释（-- 和 #）及单行块注释后再检测
    local stripped
    stripped=$(sed -E '
        /^[[:space:]]*--/d
        /^[[:space:]]*#/d
        s|/\*[^*]*\*/||g
    ' "$file" 2>/dev/null)

    if echo "$stripped" | grep -qiE '^\s*GO\s*$' 2>/dev/null; then
        echo "GO"
    elif echo "$stripped" | grep -qiE '\s+GO\s*$' 2>/dev/null; then
        echo "GO"
    else
        echo ";"
    fi
}

# ============================================================================
# [模块] 语句解析 - 将SQL文件拆分为独立语句（含行号追踪）
# ============================================================================

parse_statements() {
    local file="$1" delimiter="$2" output="$3"
    > "$output"

    local line_no=0 in_block_comment=0 current_stmt="" stmt_start=0

    while IFS= read -r line || [ -n "$line" ]; do
        ((line_no++)) || true

        local trimmed="${line#"${line%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

        if [ "$in_block_comment" -eq 1 ]; then
            if [[ "$trimmed" == *'*/'* ]]; then
                in_block_comment=0
                local after_comment="${trimmed#*\*/}"
                after_comment="${after_comment#"${after_comment%%[![:space:]]*}"}"
                [ -z "$after_comment" ] && continue
                trimmed="$after_comment"
                line="$after_comment"
            else
                continue
            fi
        fi

        [ -z "$trimmed" ] && continue
        [[ "$trimmed" == --* ]] && continue
        [[ "$trimmed" == \#* ]] && continue

        if [[ "$trimmed" == '/*'* ]]; then
            [[ "$trimmed" != *'*/'* ]] && in_block_comment=1
            continue
        fi

        local clean_line="$line"
        [[ "$line" == *' --'* ]] && clean_line="${line%% --*}"
        clean_line="${clean_line%"${clean_line##*[![:space:]]}"}"

        if [ "$delimiter" = "GO" ]; then
            local upper_trimmed="${trimmed^^}"

            if [[ "$upper_trimmed" =~ ^[[:space:]]*GO[[:space:]]*$ ]]; then
                if [ -n "$current_stmt" ]; then
                    printf '%s\t%s\n' "$stmt_start" "$current_stmt" >> "$output"
                    current_stmt=""
                fi
                continue
            fi

            if [[ "$upper_trimmed" =~ [[:space:]]+GO[[:space:]]*$ ]]; then
                local before_go
                before_go=$(printf '%s' "$clean_line" | sed -E 's/[[:space:]]+[Gg][Oo][[:space:]]*$//')
                [ -z "$current_stmt" ] && stmt_start=$line_no
                current_stmt="${current_stmt:+$current_stmt }${before_go}"
                printf '%s\t%s\n' "$stmt_start" "$current_stmt" >> "$output"
                current_stmt=""
                continue
            fi

            [ -z "$current_stmt" ] && stmt_start=$line_no
            current_stmt="${current_stmt:+$current_stmt }${clean_line}"
        else
            [ -z "$current_stmt" ] && stmt_start=$line_no
            current_stmt="${current_stmt:+$current_stmt }${clean_line}"

            if [[ "$trimmed" == *';' ]]; then
                current_stmt="${current_stmt%%;}"
                current_stmt="${current_stmt%"${current_stmt##*[![:space:]]}"}"
                [ -n "$current_stmt" ] && printf '%s\t%s\n' "$stmt_start" "$current_stmt" >> "$output"
                current_stmt=""
            fi
        fi
    done < "$file"

    [ -n "$current_stmt" ] && printf '%s\t%s\n' "$stmt_start" "$current_stmt" >> "$output"
}

# ============================================================================
# [模块] 安全检测规则（6条）
#
#   [Fix-1] 修正规则数量: 实际为6条（DDL-001~003, DML-001~002, SYS-014）
#   每条规则由 [规则 XXX-NNN] 和 [规则 XXX-NNN END] 标注
#   如需移除某条规则，删除两个标注之间的全部内容即可
# ============================================================================

scan_statement() {
    local stmt="$1" file="$2" line_no="$3" next_stmt="${4:-}"

    local upper="${stmt^^}"
    local next_upper="${next_stmt^^}"

    # [Fix-5] 剥离字符串字面量和行内块注释后的内容，用于规则匹配
    local clean_upper
    clean_upper=$(strip_strings_and_comments "$upper")

    local display="${stmt//$'\n'/ }"
    display="${display//$'\r'/ }"
    [ ${#display} -gt 200 ] && display="${display:0:200}..."

    # [Fix-4] 检测是否为存储过程/函数/触发器定义体
    #   这类语句内部的 DELETE/UPDATE 有自身逻辑控制，不应直接报警
    local is_proc_body=0
    if [[ "$clean_upper" =~ ^[[:space:]]*(CREATE|ALTER)[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?(PROCEDURE|FUNCTION|TRIGGER|PROC)[[:space:]] ]]; then
        is_proc_body=1
    fi


    # ================================================================
    # [规则 DDL-001] DROP DATABASE - 删除数据库
    # ================================================================
    if [[ "$clean_upper" =~ DROP[[:space:]]+DATABASE ]]; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" "删除数据库操作，极高风险"
    fi
    # [规则 DDL-001 END]


    # ================================================================
    # [规则 DDL-002] DROP TABLE - 删除表（含重建表模式降级）
    # [Fix-3] 使用精确表名匹配，避免子串误判（如 user 匹配 user_log）
    # ================================================================
    if [[ "$clean_upper" =~ DROP[[:space:]]+TABLE ]]; then
        local table_name=""
        local _tmp="${clean_upper#*DROP TABLE }"
        _tmp="${_tmp#IF EXISTS }"
        _tmp="${_tmp#IF EXISTS}"
        table_name="${_tmp%% *}"
        # [Fix-3] 同时清除反引号
        table_name="${table_name//[\[\]\`]/}"
        table_name="${table_name##*.}"

        local is_rebuild=0
        if [ -n "$table_name" ] && [ -n "$next_upper" ]; then
            # [Fix-3][Fix-5] 对下一条语句也做 strip 处理
            local clean_next
            clean_next=$(strip_strings_and_comments "$next_upper")

            if [[ "$clean_next" =~ CREATE[[:space:]]+TABLE ]]; then
                # [Fix-3] 从 CREATE TABLE 语句中精确提取表名进行比较
                local next_after_create="${clean_next#*CREATE TABLE }"
                next_after_create="${next_after_create#IF NOT EXISTS }"
                next_after_create="${next_after_create#IF NOT EXISTS}"
                local next_table="${next_after_create%% *}"
                next_table="${next_table//[\[\]\`]/}"
                next_table="${next_table##*.}"
                # 精确匹配表名，而非子串匹配
                [[ "$next_table" == "$table_name" ]] && is_rebuild=1
            fi
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
    if [[ "$clean_upper" =~ TRUNCATE[[:space:]]+TABLE ]]; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" "清空表全部数据，不可回滚"
    fi
    # [规则 DDL-003 END]


    # ================================================================
    # [规则 DML-001] DELETE 无 WHERE - 删除全表数据
    #   排除 ON DELETE CASCADE 等 DDL 外键定义中的 DELETE 关键字
    # [Fix-4] 排除存储过程/函数/触发器定义体
    # [Fix-5] 在剥离字符串后的内容上匹配
    # ================================================================
    if [ "$is_proc_body" -eq 0 ] && \
       [[ "$clean_upper" =~ DELETE[[:space:]] ]] && \
       [[ "$clean_upper" != *" WHERE "* ]] && \
       [[ "$clean_upper" != *"ON DELETE"* ]]; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" "DELETE 无 WHERE 条件，将删除全表数据"
    fi
    # [规则 DML-001 END]


    # ================================================================
    # [规则 DML-002] UPDATE 无 WHERE - 更新全表数据
    #   排除 ON UPDATE CASCADE 等 DDL 外键定义中的 UPDATE 关键字
    #   排除 UPDATE STATISTICS 等非DML语句
    # [Fix-4] 排除存储过程/函数/触发器定义体；支持反引号表名
    # [Fix-5] 在剥离字符串后的内容上匹配
    # ================================================================
    if [ "$is_proc_body" -eq 0 ] && \
       [[ "$clean_upper" =~ UPDATE[[:space:]]+[A-Z\[\`_] ]] && \
       [[ "$clean_upper" != *" WHERE "* ]] && \
       [[ "$clean_upper" != *"ON UPDATE"* ]] && \
       [[ "$clean_upper" != *"UPDATE STATISTICS"* ]]; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" "UPDATE 无 WHERE 条件，将更新全表数据"
    fi
    # [规则 DML-002 END]


    # ================================================================
    # [规则 SYS-014] sp_msforeachtable / sp_msforeachdb - 批量遍历操作
    #   sp_msforeachtable 对库内所有表执行命令
    #   sp_msforeachdb    对所有数据库执行命令
    # ================================================================
    if [[ "$clean_upper" == *"SP_MSFOREACHTABLE"* ]] || [[ "$clean_upper" == *"SP_MSFOREACHDB"* ]]; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" \
            "批量遍历操作（sp_msforeachtable/sp_msforeachdb），将对所有表或所有库执行命令，极高风险"
    fi
    # [规则 SYS-014 END]
}

# ============================================================================
# [模块] 报告生成
# [Fix-8] 使用 SEP 分隔符替代 |
# ============================================================================

generate_report() {
    local report="$1"
    local critical_count high_count medium_count info_count total_findings

    # [Fix-8] grep 匹配时也使用 SEP
    critical_count=$(grep -c "^CRITICAL${SEP}" "$FINDINGS_FILE" 2>/dev/null || true)
    high_count=$(grep -c "^HIGH${SEP}" "$FINDINGS_FILE" 2>/dev/null || true)
    medium_count=$(grep -c "^MEDIUM${SEP}" "$FINDINGS_FILE" 2>/dev/null || true)
    info_count=$(grep -c "^INFO${SEP}" "$FINDINGS_FILE" 2>/dev/null || true)
    : "${critical_count:=0}" "${high_count:=0}" "${medium_count:=0}" "${info_count:=0}"
    total_findings=$((critical_count + high_count + medium_count + info_count))

    # [Fix-2] 使用 find_sql_files 统一查找逻辑
    local scanned_count
    scanned_count=$(find_sql_files "$SCAN_DIR" | wc -l)

    {
        echo "============================================================"
        echo "  SQL Safety Scanner v2 - 安全扫描报告"
        echo "============================================================"
        echo "  扫描时间 : ${TIMESTAMP}"
        echo "  扫描目录 : ${SCAN_DIR}"
        echo "  递归扫描 : $([ "$RECURSIVE" -eq 1 ] && echo '是' || echo '否')"
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
                count=$(grep -c "^${severity}${SEP}" "$FINDINGS_FILE" 2>/dev/null || true)
                : "${count:=0}"
                if [ "$count" -gt 0 ]; then
                    echo "------------------------------------------------------------"
                    echo "  ${severity} (${count})"
                    echo "------------------------------------------------------------"
                    echo ""
                    # [Fix-8] 使用 SEP 作为 IFS
                    while IFS="$SEP" read -r sev f_name f_line f_sql f_desc; do
                        echo "  [${sev}] ${f_name}:${f_line}"
                        echo "    ${f_sql}"
                        echo "    >> ${f_desc}"
                        echo ""
                    done < <(grep "^${severity}${SEP}" "$FINDINGS_FILE")
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

# ============================================================================
# [模块] 主流程
# ============================================================================

main() {
    echo "============================================================"
    echo "  SQL Safety Scanner v2 开始扫描..."
    echo "  目录: ${SCAN_DIR}"
    echo "  递归: $([ "$RECURSIVE" -eq 1 ] && echo '是' || echo '否')"
    echo "============================================================"
    echo ""

    # [Fix-2] 使用 find_sql_files 统一查找逻辑
    local sql_files=()
    while IFS= read -r f; do
        sql_files+=("$f")
    done < <(find_sql_files "$SCAN_DIR")

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

        # [Fix-2] 递归模式下显示相对路径，方便区分同名文件
        local display_name="$filename"
        if [ "$RECURSIVE" -eq 1 ]; then
            display_name="${sql_file#"${SCAN_DIR}/"}"
        fi
        echo "扫描: ${display_name}"

        # 使用安全文件名避免特殊字符问题
        local safe_name
        safe_name=$(echo "$filename" | sed 's/[^a-zA-Z0-9._-]/_/g')
        local preprocessed="${TMP_DIR}/${safe_name}.pre"
        preprocess_file "$sql_file" "$preprocessed"

        local delimiter
        delimiter=$(detect_delimiter "$preprocessed")
        echo "  分隔符: ${delimiter}"

        local stmt_file="${TMP_DIR}/${safe_name}.stmts"
        parse_statements "$preprocessed" "$delimiter" "$stmt_file"

        local stmt_count
        stmt_count=$(wc -l < "$stmt_file")
        echo "  语句数: ${stmt_count}"

        local cur_stmt="" cur_line="" first=1
        while IFS=$'\t' read -r s_line s_text; do
            if [ "$first" -eq 1 ]; then
                cur_stmt="$s_text"; cur_line="$s_line"; first=0; continue
            fi
            scan_statement "$cur_stmt" "$display_name" "$cur_line" "$s_text"
            cur_stmt="$s_text"; cur_line="$s_line"
        done < "$stmt_file"
        [ -n "$cur_stmt" ] && scan_statement "$cur_stmt" "$display_name" "$cur_line" ""

        echo "  完成"
        echo ""
    done

    generate_report "$REPORT_FILE"

    local cc hc
    cc=$(grep -c "^CRITICAL${SEP}" "$FINDINGS_FILE" 2>/dev/null || true)
    hc=$(grep -c "^HIGH${SEP}" "$FINDINGS_FILE" 2>/dev/null || true)
    : "${cc:=0}" "${hc:=0}"
    [ "$cc" -gt 0 ] && exit 1
    [ "$hc" -gt 0 ] && exit 2
    exit 0
}

main
