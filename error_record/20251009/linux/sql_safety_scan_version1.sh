#!/bin/bash
# ============================================================================
#  SQL Safety Scanner - SQL脚本安全扫描工具
#
#  用途: 扫描指定目录下所有 .sql 文件中的危险操作，生成检查报告
#  用法: bash sql_safety_scan_version1.sh <sql_directory>
#  输出: 在指定目录下生成 sql_safety_check_<timestamp>.txt
# ============================================================================

set -o pipefail

# ============================================================================
# [模块] 全局配置
# ============================================================================

SCAN_DIR=""
REPORT_FILE=""
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TIMESTAMP_FILE=$(date '+%Y%m%d_%H%M%S')

TMP_DIR=$(mktemp -d)
FINDINGS_FILE="${TMP_DIR}/findings.txt"
> "$FINDINGS_FILE"

cleanup() { rm -rf "$TMP_DIR" 2>/dev/null; }
trap cleanup EXIT

# ============================================================================
# [模块] 参数校验
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
# [模块] 工具函数
# ============================================================================

# 记录检测发现
# 参数: 级别 文件名 行号 SQL片段 描述
record_finding() {
    local severity="$1"
    local file="$2"
    local line_no="$3"
    local sql_snippet="$4"
    local description="$5"

    # 截断SQL（最长200字符）
    local display_sql
    display_sql=$(printf '%s' "$sql_snippet" | tr '\n\r' '  ' | sed 's/  */ /g')
    if [ ${#display_sql} -gt 200 ]; then
        display_sql="${display_sql:0:200}..."
    fi

    printf '%s|%s|%s|%s|%s\n' \
        "$severity" "$file" "$line_no" "$display_sql" "$description" \
        >> "$FINDINGS_FILE"
}

# ============================================================================
# [模块] 文件预处理 - BOM去除、换行符转换、编码检测
# ============================================================================

preprocess_file() {
    local src="$1"
    local dst="$2"

    # 编码检测: UTF-16 → UTF-8
    if file "$src" 2>/dev/null | grep -qi "UTF-16"; then
        echo "  [WARN] 检测到UTF-16编码，自动转换: $(basename "$src")"
        iconv -f UTF-16 -t UTF-8 "$src" > "$dst" 2>/dev/null || {
            echo "  [ERROR] UTF-16转换失败，使用原文件"
            cp "$src" "$dst"
        }
    else
        cp "$src" "$dst"
    fi

    # 去除 BOM (EF BB BF)
    sed -i '1s/^\xEF\xBB\xBF//' "$dst" 2>/dev/null || true

    # CRLF → LF
    sed -i 's/\r$//' "$dst" 2>/dev/null || true
}

# ============================================================================
# [模块] 分隔符检测 - 自动识别 GO 或 分号(;)
# ============================================================================

detect_delimiter() {
    local file="$1"
    if grep -iE '^\s*GO\s*$' "$file" >/dev/null 2>&1; then
        echo "GO"
    elif grep -iE '\s+GO\s*$' "$file" >/dev/null 2>&1; then
        echo "GO"
    else
        echo ";"
    fi
}

# ============================================================================
# [模块] 语句解析 - 将SQL文件拆分为独立语句（含行号追踪）
#   输出格式: 起始行号<TAB>语句文本（多行合并为单行）
#   自动跳过注释（单行--/#、块注释/* */）
#   自动去除行内注释（简化处理）
# ============================================================================

parse_statements() {
    local file="$1"
    local delimiter="$2"
    local output="$3"

    > "$output"

    local line_no=0
    local in_block_comment=0
    local current_stmt=""
    local stmt_start=0

    while IFS= read -r line || [ -n "$line" ]; do
        ((line_no++)) || true

        # trim
        local trimmed
        trimmed=$(printf '%s' "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

        # --- 块注释状态 ---
        if [ "$in_block_comment" -eq 1 ]; then
            if [[ "$trimmed" == *'*/'* ]]; then
                in_block_comment=0
                local after_comment="${trimmed#*\*/}"
                after_comment=$(printf '%s' "$after_comment" | sed 's/^[[:space:]]*//')
                if [ -z "$after_comment" ]; then
                    continue
                fi
                trimmed="$after_comment"
                line="$after_comment"
            else
                continue
            fi
        fi

        # 空行跳过
        [ -z "$trimmed" ] && continue

        # 单行注释跳过
        [[ "$trimmed" == --* ]] && continue
        [[ "$trimmed" == \#* ]] && continue

        # 块注释开始
        if [[ "$trimmed" == '/*'* ]]; then
            if [[ "$trimmed" == *'*/'* ]]; then
                continue
            else
                in_block_comment=1
                continue
            fi
        fi

        # 去除行内注释（简化: 去除不在引号内的 " --" 后内容）
        local clean_line="$line"
        if [[ "$line" == *' --'* ]]; then
            clean_line="${line%% --*}"
        fi
        clean_line=$(printf '%s' "$clean_line" | sed 's/[[:space:]]*$//')

        # ---- GO 分隔符模式 ----
        if [ "$delimiter" = "GO" ]; then
            local upper_trimmed
            upper_trimmed=$(printf '%s' "$trimmed" | tr '[:lower:]' '[:upper:]')

            # 纯 GO 行
            if [[ "$upper_trimmed" =~ ^[[:space:]]*GO[[:space:]]*$ ]]; then
                if [ -n "$current_stmt" ]; then
                    printf '%s\t%s\n' "$stmt_start" "$current_stmt" >> "$output"
                    current_stmt=""
                fi
                continue
            fi

            # 行尾 GO（如 ") GO"）
            if [[ "$upper_trimmed" =~ [[:space:]]+GO[[:space:]]*$ ]]; then
                local before_go
                before_go=$(printf '%s' "$clean_line" | sed -E 's/[[:space:]]+[Gg][Oo][[:space:]]*$//')
                if [ -z "$current_stmt" ]; then
                    stmt_start=$line_no
                fi
                if [ -n "$current_stmt" ]; then
                    current_stmt="$current_stmt $before_go"
                else
                    current_stmt="$before_go"
                fi
                printf '%s\t%s\n' "$stmt_start" "$current_stmt" >> "$output"
                current_stmt=""
                continue
            fi

            # 普通行: 累积
            if [ -z "$current_stmt" ]; then
                stmt_start=$line_no
                current_stmt="$clean_line"
            else
                current_stmt="$current_stmt $clean_line"
            fi

        # ---- 分号(;)分隔符模式 ----
        else
            if [ -z "$current_stmt" ]; then
                stmt_start=$line_no
                current_stmt="$clean_line"
            else
                current_stmt="$current_stmt $clean_line"
            fi

            if [[ "$trimmed" == *';' ]]; then
                current_stmt=$(printf '%s' "$current_stmt" | sed 's/;[[:space:]]*$//')
                if [ -n "$current_stmt" ]; then
                    printf '%s\t%s\n' "$stmt_start" "$current_stmt" >> "$output"
                fi
                current_stmt=""
            fi
        fi
    done < "$file"

    # 兜底: 末尾无分隔符的语句
    if [ -n "$current_stmt" ]; then
        printf '%s\t%s\n' "$stmt_start" "$current_stmt" >> "$output"
    fi
}

# ============================================================================
# [模块] 安全检测规则 - 核心扫描逻辑
#
#   每条规则由 [规则 XXX-NNN] 和 [规则 XXX-NNN END] 标注
#   如需移除某条规则，删除两个标注之间的全部内容即可
#
#   参数: $1=语句文本  $2=文件名  $3=行号  $4=下一条语句(用于上下文)
# ============================================================================

scan_statement() {
    local stmt="$1"
    local file="$2"
    local line_no="$3"
    local next_stmt="${4:-}"

    # 转大写用于匹配
    local upper
    upper=$(printf '%s' "$stmt" | tr '[:lower:]' '[:upper:]')

    local next_upper=""
    if [ -n "$next_stmt" ]; then
        next_upper=$(printf '%s' "$next_stmt" | tr '[:lower:]' '[:upper:]')
    fi

    # 截断显示
    local display
    display=$(printf '%s' "$stmt" | tr '\n\r' '  ' | sed 's/  */ /g')
    [ ${#display} -gt 200 ] && display="${display:0:200}..."

    # 检测是否在存储过程/函数/触发器定义体内
    local in_proc_def=0
    local proc_suffix=""
    if printf '%s\n' "$upper" | grep -qE '(CREATE|ALTER)\s+(OR\s+ALTER\s+)?(PROCEDURE|FUNCTION|TRIGGER)'; then
        in_proc_def=1
        proc_suffix="（在存储过程/函数/触发器定义体内，非直接执行）"
    fi


    # ================================================================
    # [规则 DDL-001] DROP DATABASE - 删除数据库
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'DROP\s+DATABASE'; then
        local sev="CRITICAL"
        [ "$in_proc_def" -eq 1 ] && sev="MEDIUM"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "删除数据库操作，极高风险${proc_suffix}"
    fi
    # [规则 DDL-001 END]


    # ================================================================
    # [规则 DDL-002] DROP TABLE - 删除表（含重建表模式降级）
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'DROP\s+TABLE'; then
        # 提取表名（去除 IF EXISTS、schema前缀、方括号）
        local table_name
        table_name=$(printf '%s' "$upper" | \
            sed -E 's/.*DROP\s+TABLE\s+(IF\s+EXISTS\s+)?//' | \
            awk '{print $1}' | tr -d '[]' | sed 's/.*\.//')

        # 检测重建表模式: 下一条语句是否为 CREATE TABLE 同名表
        local is_rebuild=0
        if [ -n "$table_name" ] && [ -n "$next_upper" ]; then
            if printf '%s\n' "$next_upper" | grep -qiE "CREATE\s+TABLE.*${table_name}"; then
                is_rebuild=1
            fi
        fi

        if [ "$is_rebuild" -eq 1 ]; then
            record_finding "INFO" "$file" "$line_no" "$display" \
                "重建表模式（DROP + CREATE ${table_name}），已降级为INFO${proc_suffix}"
        else
            local sev="CRITICAL"
            [ "$in_proc_def" -eq 1 ] && sev="MEDIUM"
            record_finding "$sev" "$file" "$line_no" "$display" \
                "删除表操作${proc_suffix}"
        fi
    fi
    # [规则 DDL-002 END]


    # ================================================================
    # [规则 DDL-003] TRUNCATE TABLE - 清空表
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'TRUNCATE\s+TABLE'; then
        local sev="CRITICAL"
        [ "$in_proc_def" -eq 1 ] && sev="MEDIUM"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "清空表全部数据，不可回滚${proc_suffix}"
    fi
    # [规则 DDL-003 END]


    # ================================================================
    # [规则 DDL-004] DROP SCHEMA - 删除Schema
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'DROP\s+SCHEMA'; then
        local sev="CRITICAL"
        [ "$in_proc_def" -eq 1 ] && sev="MEDIUM"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "删除Schema操作${proc_suffix}"
    fi
    # [规则 DDL-004 END]


    # ================================================================
    # [规则 DDL-005] DROP INDEX - 删除索引
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'DROP\s+INDEX'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "删除索引，可能影响查询性能${proc_suffix}"
    fi
    # [规则 DDL-005 END]


    # ================================================================
    # [规则 DDL-006] DROP VIEW - 删除视图
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'DROP\s+VIEW'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "删除视图${proc_suffix}"
    fi
    # [规则 DDL-006 END]


    # ================================================================
    # [规则 DDL-007] DROP PROCEDURE / DROP FUNCTION - 删除存储过程或函数
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'DROP\s+(PROCEDURE|FUNCTION|PROC)\b'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "删除存储过程/函数${proc_suffix}"
    fi
    # [规则 DDL-007 END]


    # ================================================================
    # [规则 DDL-008] DROP TRIGGER - 删除触发器
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'DROP\s+TRIGGER'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "删除触发器${proc_suffix}"
    fi
    # [规则 DDL-008 END]


    # ================================================================
    # [规则 DDL-009] ALTER TABLE ... DROP COLUMN - 删除列
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'ALTER\s+TABLE.*DROP\s+COLUMN'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "删除表列，数据不可恢复${proc_suffix}"
    fi
    # [规则 DDL-009 END]


    # ================================================================
    # [规则 DDL-010] ALTER TABLE ... ALTER COLUMN - 修改列类型
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'ALTER\s+TABLE.*ALTER\s+COLUMN'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "修改列类型，可能导致数据截断${proc_suffix}"
    fi
    # [规则 DDL-010 END]


    # ================================================================
    # [规则 DDL-011] sp_rename - 重命名对象
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'SP_RENAME'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "重命名数据库对象，可能影响依赖关系${proc_suffix}"
    fi
    # [规则 DDL-011 END]


    # ================================================================
    # [规则 DDL-012] DISABLE/ENABLE TRIGGER - 禁用/启用触发器
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE '(DISABLE|ENABLE)\s+TRIGGER'; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" \
            "禁用/启用触发器${proc_suffix}"
    fi
    # [规则 DDL-012 END]


    # ================================================================
    # [规则 DDL-013] ALTER TABLE ... ADD/DROP CONSTRAINT - 约束变更
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'ALTER\s+TABLE.*DROP\s+CONSTRAINT'; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" \
            "删除表约束${proc_suffix}"
    fi
    # [规则 DDL-013 END]


    # ================================================================
    # [规则 DML-001] DELETE 无 WHERE - 删除全表数据
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'DELETE\s+(FROM\s+)?[A-Z\[_]'; then
        if ! printf '%s\n' "$upper" | grep -qE '\sWHERE\s'; then
            local sev="CRITICAL"
            [ "$in_proc_def" -eq 1 ] && sev="MEDIUM"
            record_finding "$sev" "$file" "$line_no" "$display" \
                "DELETE 无 WHERE 条件，将删除全表数据${proc_suffix}"
        fi
    fi
    # [规则 DML-001 END]


    # ================================================================
    # [规则 DML-002] UPDATE 无 WHERE - 更新全表数据
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'UPDATE\s+[A-Z\[_]'; then
        if ! printf '%s\n' "$upper" | grep -qE '\sWHERE\s'; then
            # 排除 UPDATE STATISTICS 等非DML语句
            if ! printf '%s\n' "$upper" | grep -qE 'UPDATE\s+STATISTICS'; then
                local sev="CRITICAL"
                [ "$in_proc_def" -eq 1 ] && sev="MEDIUM"
                record_finding "$sev" "$file" "$line_no" "$display" \
                    "UPDATE 无 WHERE 条件，将更新全表数据${proc_suffix}"
            fi
        fi
    fi
    # [规则 DML-002 END]


    # ================================================================
    # [规则 DML-003] DELETE/UPDATE 恒真条件 - WHERE 1=1 等
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE '(DELETE|UPDATE)\s'; then
        if printf '%s\n' "$upper" | grep -qE "WHERE\s+(1\s*=\s*1|'1'\s*=\s*'1'|0\s*=\s*0|1\s*<>\s*0)"; then
            local sev="HIGH"
            [ "$in_proc_def" -eq 1 ] && sev="INFO"
            record_finding "$sev" "$file" "$line_no" "$display" \
                "DELETE/UPDATE 使用恒真条件(如 1=1)，等价于无WHERE${proc_suffix}"
        fi
    fi
    # [规则 DML-003 END]


    # ================================================================
    # [规则 DML-004] MERGE - 批量合并操作
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE '^\s*MERGE\s'; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" \
            "MERGE 操作，可能批量增删改${proc_suffix}"
    fi
    # [规则 DML-004 END]


    # ================================================================
    # [规则 DML-005] INSERT INTO ... SELECT - 批量插入
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'INSERT\s+INTO\s+.*SELECT\s'; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" \
            "INSERT INTO ... SELECT 批量插入${proc_suffix}"
    fi
    # [规则 DML-005 END]


    # ================================================================
    # [规则 DML-006] SELECT INTO - 隐式创建表
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'SELECT\s.*\sINTO\s+[A-Z\[#_].*\sFROM\s'; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" \
            "SELECT INTO 隐式创建新表${proc_suffix}"
    fi
    # [规则 DML-006 END]


    # ================================================================
    # [规则 DCL-001] DROP LOGIN / DROP USER - 删除账号
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'DROP\s+(LOGIN|USER)\b'; then
        local sev="CRITICAL"
        [ "$in_proc_def" -eq 1 ] && sev="MEDIUM"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "删除数据库登录/用户${proc_suffix}"
    fi
    # [规则 DCL-001 END]


    # ================================================================
    # [规则 DCL-002] GRANT - 授权
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE '^\s*GRANT\s'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "权限授予操作${proc_suffix}"
    fi
    # [规则 DCL-002 END]


    # ================================================================
    # [规则 DCL-003] REVOKE - 撤权
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE '^\s*REVOKE\s'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "权限撤销操作${proc_suffix}"
    fi
    # [规则 DCL-003 END]


    # ================================================================
    # [规则 DCL-004] DENY - 拒绝权限
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE '^\s*DENY\s'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "权限拒绝操作${proc_suffix}"
    fi
    # [规则 DCL-004 END]


    # ================================================================
    # [规则 DCL-005] CREATE LOGIN / CREATE USER - 创建账号
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'CREATE\s+(LOGIN|USER)\b'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "创建数据库登录/用户${proc_suffix}"
    fi
    # [规则 DCL-005 END]


    # ================================================================
    # [规则 DCL-006] ALTER LOGIN / ALTER USER - 修改账号
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'ALTER\s+(LOGIN|USER)\b'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "修改数据库登录/用户${proc_suffix}"
    fi
    # [规则 DCL-006 END]


    # ================================================================
    # [规则 DCL-007] ALTER ROLE / sp_addrolemember - 角色变更
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE '(ALTER\s+ROLE|SP_ADDROLEMEMBER|SP_DROPROLEMEMBER)'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "数据库角色成员变更${proc_suffix}"
    fi
    # [规则 DCL-007 END]


    # ================================================================
    # [规则 DCL-008] ALTER AUTHORIZATION - 变更所有者
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'ALTER\s+AUTHORIZATION'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "变更对象所有权${proc_suffix}"
    fi
    # [规则 DCL-008 END]


    # ================================================================
    # [规则 SYS-001] xp_cmdshell - 操作系统命令执行
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'XP_CMDSHELL'; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" \
            "调用操作系统命令，极高安全风险${proc_suffix}"
    fi
    # [规则 SYS-001 END]


    # ================================================================
    # [规则 SYS-002] SHUTDOWN - 关闭数据库
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE '^\s*SHUTDOWN'; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" \
            "关闭数据库服务${proc_suffix}"
    fi
    # [规则 SYS-002 END]


    # ================================================================
    # [规则 SYS-003] RESTORE DATABASE - 还原数据库
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'RESTORE\s+DATABASE'; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" \
            "还原数据库，将覆盖现有数据${proc_suffix}"
    fi
    # [规则 SYS-003 END]


    # ================================================================
    # [规则 SYS-004] sp_configure / RECONFIGURE - 服务器配置
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE '(SP_CONFIGURE|^\s*RECONFIGURE)'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "修改服务器级配置${proc_suffix}"
    fi
    # [规则 SYS-004 END]


    # ================================================================
    # [规则 SYS-005] ALTER DATABASE - 修改数据库配置
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'ALTER\s+DATABASE'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "修改数据库级配置${proc_suffix}"
    fi
    # [规则 SYS-005 END]


    # ================================================================
    # [规则 SYS-006] KILL - 终止会话
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE '^\s*KILL\s+[0-9]'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "终止数据库会话${proc_suffix}"
    fi
    # [规则 SYS-006 END]


    # ================================================================
    # [规则 SYS-007] BULK INSERT - 外部文件导入
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'BULK\s+INSERT'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "外部文件批量导入${proc_suffix}"
    fi
    # [规则 SYS-007 END]


    # ================================================================
    # [规则 SYS-008] OPENROWSET / OPENDATASOURCE - 外部数据源
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE '(OPENROWSET|OPENDATASOURCE)'; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "访问外部数据源${proc_suffix}"
    fi
    # [规则 SYS-008 END]


    # ================================================================
    # [规则 SYS-009] 动态SQL - sp_executesql / EXEC(变量或字符串)
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE "(SP_EXECUTESQL|EXEC\s*\(\s*@|EXECUTE\s*\(\s*@|EXEC\s*\(\s*N?')"; then
        local sev="HIGH"
        [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" \
            "动态SQL执行，存在注入风险${proc_suffix}"
    fi
    # [规则 SYS-009 END]


    # ================================================================
    # [规则 SYS-010] xp_* 扩展存储过程（排除已捕获的 xp_cmdshell）
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'XP_[A-Z]'; then
        if ! printf '%s\n' "$upper" | grep -qE 'XP_CMDSHELL'; then
            local sev="HIGH"
            [ "$in_proc_def" -eq 1 ] && sev="INFO"
            record_finding "$sev" "$file" "$line_no" "$display" \
                "调用扩展存储过程${proc_suffix}"
        fi
    fi
    # [规则 SYS-010 END]


    # ================================================================
    # [规则 SYS-011] DBCC - 数据库维护命令
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE '^\s*DBCC\s'; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" \
            "DBCC 数据库维护命令${proc_suffix}"
    fi
    # [规则 SYS-011 END]


    # ================================================================
    # [规则 SYS-012] BACKUP DATABASE / BACKUP LOG - 备份操作
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'BACKUP\s+(DATABASE|LOG)'; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" \
            "备份操作出现在变更脚本中${proc_suffix}"
    fi
    # [规则 SYS-012 END]


    # ================================================================
    # [规则 SYS-013] WAITFOR DELAY - 延时执行
    # ================================================================
    if printf '%s\n' "$upper" | grep -qE 'WAITFOR\s+DELAY'; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" \
            "延时执行语句${proc_suffix}"
    fi
    # [规则 SYS-013 END]
}


# ============================================================================
# [模块] 报告生成
# ============================================================================

generate_report() {
    local report="$1"

    # 统计各级别数量
    local critical_count high_count medium_count info_count total_findings
    critical_count=$(grep -c '^CRITICAL|' "$FINDINGS_FILE" 2>/dev/null || echo 0)
    high_count=$(grep -c '^HIGH|' "$FINDINGS_FILE" 2>/dev/null || echo 0)
    medium_count=$(grep -c '^MEDIUM|' "$FINDINGS_FILE" 2>/dev/null || echo 0)
    info_count=$(grep -c '^INFO|' "$FINDINGS_FILE" 2>/dev/null || echo 0)
    total_findings=$((critical_count + high_count + medium_count + info_count))

    local scanned_count
    scanned_count=$(find "$SCAN_DIR" -maxdepth 1 -name "*.sql" -type f 2>/dev/null | wc -l)

    {
        echo "============================================================"
        echo "  SQL Safety Scanner - 安全扫描报告"
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
            # 按级别分组输出
            for severity in CRITICAL HIGH MEDIUM INFO; do
                local count
                count=$(grep -c "^${severity}|" "$FINDINGS_FILE" 2>/dev/null || echo 0)
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

    # 同时输出到终端
    cat "$report"
    echo ""
    echo "报告已生成: ${report}"
}


# ============================================================================
# [模块] 主流程
# ============================================================================

main() {
    echo "============================================================"
    echo "  SQL Safety Scanner 开始扫描..."
    echo "  目录: ${SCAN_DIR}"
    echo "============================================================"
    echo ""

    # 获取所有 .sql 文件（不递归）
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

    # 逐文件扫描
    for sql_file in "${sql_files[@]}"; do
        local filename
        filename=$(basename "$sql_file")
        echo "扫描: ${filename}"

        # 1. 预处理
        local preprocessed="${TMP_DIR}/${filename}.pre"
        preprocess_file "$sql_file" "$preprocessed"

        # 2. 检测分隔符
        local delimiter
        delimiter=$(detect_delimiter "$preprocessed")
        echo "  分隔符: ${delimiter}"

        # 3. 解析语句
        local stmt_file="${TMP_DIR}/${filename}.stmts"
        parse_statements "$preprocessed" "$delimiter" "$stmt_file"

        local stmt_count
        stmt_count=$(wc -l < "$stmt_file")
        echo "  语句数: ${stmt_count}"

        # 4. 读取所有语句到数组
        local stmt_lines=()
        local stmt_texts=()
        while IFS=$'\t' read -r s_line s_text; do
            stmt_lines+=("$s_line")
            stmt_texts+=("$s_text")
        done < "$stmt_file"

        # 5. 逐语句扫描（带上下文：传入下一条语句用于重建表模式判断）
        local total=${#stmt_texts[@]}
        for ((i=0; i<total; i++)); do
            local next_stmt=""
            if ((i + 1 < total)); then
                next_stmt="${stmt_texts[$((i+1))]}"
            fi
            scan_statement "${stmt_texts[$i]}" "$filename" "${stmt_lines[$i]}" "$next_stmt"
        done

        echo "  完成"
        echo ""
    done

    # 生成报告
    generate_report "$REPORT_FILE"

    # 退出码: 0=安全  1=有CRITICAL  2=有HIGH(无CRITICAL)
    local critical_count high_count
    critical_count=$(grep -c '^CRITICAL|' "$FINDINGS_FILE" 2>/dev/null || echo 0)
    high_count=$(grep -c '^HIGH|' "$FINDINGS_FILE" 2>/dev/null || echo 0)

    if [ "$critical_count" -gt 0 ]; then
        exit 1
    elif [ "$high_count" -gt 0 ]; then
        exit 2
    else
        exit 0
    fi
}

main
