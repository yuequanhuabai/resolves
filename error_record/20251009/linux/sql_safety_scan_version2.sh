#!/bin/bash
# ============================================================================
#  SQL Safety Scanner - SQL脚本安全扫描工具
#
#  用途: 扫描指定目录下所有 .sql 文件中的危险操作，生成检查报告
#  用法: bash sql_safety_scan_version2.sh <sql_directory>
#  输出: 在指定目录下生成 sql_safety_check_<timestamp>.txt
#
#  退出码: 0=安全  1=有CRITICAL  2=有HIGH(无CRITICAL)
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

# bash 原生 trim（无子进程）
trim() {
    local var="$1"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

# 记录检测发现
record_finding() {
    local severity="$1" file="$2" line_no="$3" sql_snippet="$4" description="$5"
    local display_sql="${sql_snippet//$'\n'/ }"
    display_sql="${display_sql//$'\r'/ }"
    # 压缩连续空格
    while [[ "$display_sql" == *"  "* ]]; do
        display_sql="${display_sql//  / }"
    done
    if [ ${#display_sql} -gt 200 ]; then
        display_sql="${display_sql:0:200}..."
    fi
    printf '%s|%s|%s|%s|%s\n' "$severity" "$file" "$line_no" "$display_sql" "$description" >> "$FINDINGS_FILE"
}

# ============================================================================
# [模块] 文件预处理 - BOM去除、换行符转换、编码检测
# ============================================================================

preprocess_file() {
    local src="$1" dst="$2"

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
    if grep -qiE '^\s*GO\s*$' "$file" 2>/dev/null; then
        echo "GO"
    elif grep -qiE '\s+GO\s*$' "$file" 2>/dev/null; then
        echo "GO"
    else
        echo ";"
    fi
}

# ============================================================================
# [模块] 语句解析 - 将SQL文件拆分为独立语句（含行号追踪）
#   输出格式: 起始行号<TAB>语句文本（多行合并为单行）
#   自动跳过注释、去除行内注释
# ============================================================================

parse_statements() {
    local file="$1" delimiter="$2" output="$3"
    > "$output"

    local line_no=0 in_block_comment=0 current_stmt="" stmt_start=0

    while IFS= read -r line || [ -n "$line" ]; do
        ((line_no++)) || true

        # bash 原生 trim（避免 sed 子进程）
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

        # --- 块注释状态 ---
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

        # 块注释开始
        if [[ "$trimmed" == '/*'* ]]; then
            [[ "$trimmed" != *'*/'* ]] && in_block_comment=1
            continue
        fi

        # 去除行内注释
        local clean_line="$line"
        [[ "$line" == *' --'* ]] && clean_line="${line%% --*}"
        clean_line="${clean_line%"${clean_line##*[![:space:]]}"}"

        # ---- GO 分隔符模式 ----
        if [ "$delimiter" = "GO" ]; then
            local upper_trimmed="${trimmed^^}"

            # 纯 GO 行
            if [[ "$upper_trimmed" =~ ^[[:space:]]*GO[[:space:]]*$ ]]; then
                if [ -n "$current_stmt" ]; then
                    printf '%s\t%s\n' "$stmt_start" "$current_stmt" >> "$output"
                    current_stmt=""
                fi
                continue
            fi

            # 行尾 GO
            if [[ "$upper_trimmed" =~ [[:space:]]+GO[[:space:]]*$ ]]; then
                local before_go
                before_go=$(printf '%s' "$clean_line" | sed -E 's/[[:space:]]+[Gg][Oo][[:space:]]*$//')
                [ -z "$current_stmt" ] && stmt_start=$line_no
                current_stmt="${current_stmt:+$current_stmt }${before_go}"
                printf '%s\t%s\n' "$stmt_start" "$current_stmt" >> "$output"
                current_stmt=""
                continue
            fi

            # 普通行累积
            [ -z "$current_stmt" ] && stmt_start=$line_no
            current_stmt="${current_stmt:+$current_stmt }${clean_line}"

        # ---- 分号(;) 分隔符模式 ----
        else
            [ -z "$current_stmt" ] && stmt_start=$line_no
            current_stmt="${current_stmt:+$current_stmt }${clean_line}"

            if [[ "$trimmed" == *';' ]]; then
                # 去除末尾分号
                current_stmt="${current_stmt%%;}"
                current_stmt="${current_stmt%"${current_stmt##*[![:space:]]}"}"
                [ -n "$current_stmt" ] && printf '%s\t%s\n' "$stmt_start" "$current_stmt" >> "$output"
                current_stmt=""
            fi
        fi
    done < "$file"

    # 兜底
    [ -n "$current_stmt" ] && printf '%s\t%s\n' "$stmt_start" "$current_stmt" >> "$output"
}

# ============================================================================
# [模块] 安全检测规则 - 核心扫描逻辑
#
#   每条规则由 [规则 XXX-NNN] 和 [规则 XXX-NNN END] 标注
#   如需移除某条规则，删除两个标注之间的全部内容即可
#
#   参数: $1=语句文本  $2=文件名  $3=行号  $4=下一条语句(用于上下文)
#
#   性能说明: 全部使用 bash 内置 [[ =~ ]] 匹配，无子进程开销
# ============================================================================

scan_statement() {
    local stmt="$1" file="$2" line_no="$3" next_stmt="${4:-}"

    # bash 内置转大写（无子进程）
    local upper="${stmt^^}"
    local next_upper="${next_stmt^^}"

    # 截断显示
    local display="${stmt//$'\n'/ }"
    display="${display//$'\r'/ }"
    [ ${#display} -gt 200 ] && display="${display:0:200}..."

    # 检测是否在存储过程/函数/触发器定义体内
    local in_proc_def=0 proc_suffix=""
    local _p_proc='(CREATE|ALTER)[[:space:]]+(OR[[:space:]]+ALTER[[:space:]]+)?(PROCEDURE|FUNCTION|TRIGGER)'
    if [[ "$upper" =~ $_p_proc ]]; then
        in_proc_def=1
        proc_suffix="（在存储过程/函数/触发器定义体内，非直接执行）"
    fi


    # ================================================================
    # [规则 DDL-001] DROP DATABASE - 删除数据库
    # ================================================================
    if [[ "$upper" =~ DROP[[:space:]]+DATABASE ]]; then
        local sev="CRITICAL"; [ "$in_proc_def" -eq 1 ] && sev="MEDIUM"
        record_finding "$sev" "$file" "$line_no" "$display" "删除数据库操作，极高风险${proc_suffix}"
    fi
    # [规则 DDL-001 END]


    # ================================================================
    # [规则 DDL-002] DROP TABLE - 删除表（含重建表模式降级）
    # ================================================================
    if [[ "$upper" =~ DROP[[:space:]]+TABLE ]]; then
        # 提取表名
        local table_name=""
        local _tmp="${upper#*DROP TABLE }"
        _tmp="${_tmp#IF EXISTS }"
        _tmp="${_tmp#IF EXISTS}"
        table_name="${_tmp%% *}"
        table_name="${table_name//[\[\]]/}"
        table_name="${table_name##*.}"

        # 检测重建表模式
        local is_rebuild=0
        if [ -n "$table_name" ] && [ -n "$next_upper" ]; then
            [[ "$next_upper" =~ CREATE[[:space:]]+TABLE ]] && \
            [[ "$next_upper" == *"$table_name"* ]] && is_rebuild=1
        fi

        if [ "$is_rebuild" -eq 1 ]; then
            record_finding "INFO" "$file" "$line_no" "$display" \
                "重建表模式（DROP + CREATE ${table_name}），已降级为INFO${proc_suffix}"
        else
            local sev="CRITICAL"; [ "$in_proc_def" -eq 1 ] && sev="MEDIUM"
            record_finding "$sev" "$file" "$line_no" "$display" "删除表操作${proc_suffix}"
        fi
    fi
    # [规则 DDL-002 END]


    # ================================================================
    # [规则 DDL-003] TRUNCATE TABLE - 清空表
    # ================================================================
    if [[ "$upper" =~ TRUNCATE[[:space:]]+TABLE ]]; then
        local sev="CRITICAL"; [ "$in_proc_def" -eq 1 ] && sev="MEDIUM"
        record_finding "$sev" "$file" "$line_no" "$display" "清空表全部数据，不可回滚${proc_suffix}"
    fi
    # [规则 DDL-003 END]


    # ================================================================
    # [规则 DDL-004] DROP SCHEMA - 删除Schema
    # ================================================================
    if [[ "$upper" =~ DROP[[:space:]]+SCHEMA ]]; then
        local sev="CRITICAL"; [ "$in_proc_def" -eq 1 ] && sev="MEDIUM"
        record_finding "$sev" "$file" "$line_no" "$display" "删除Schema操作${proc_suffix}"
    fi
    # [规则 DDL-004 END]


    # ================================================================
    # [规则 DDL-005] DROP INDEX - 删除索引
    # ================================================================
    if [[ "$upper" =~ DROP[[:space:]]+INDEX ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "删除索引，可能影响查询性能${proc_suffix}"
    fi
    # [规则 DDL-005 END]


    # ================================================================
    # [规则 DDL-006] DROP VIEW - 删除视图
    # ================================================================
    if [[ "$upper" =~ DROP[[:space:]]+VIEW ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "删除视图${proc_suffix}"
    fi
    # [规则 DDL-006 END]


    # ================================================================
    # [规则 DDL-007] DROP PROCEDURE / DROP FUNCTION - 删除存储过程或函数
    # ================================================================
    local _p_drop_proc='DROP[[:space:]]+(PROCEDURE|FUNCTION|PROC)[[:space:]]'
    if [[ "$upper" =~ $_p_drop_proc ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "删除存储过程/函数${proc_suffix}"
    fi
    # [规则 DDL-007 END]


    # ================================================================
    # [规则 DDL-008] DROP TRIGGER - 删除触发器
    # ================================================================
    if [[ "$upper" =~ DROP[[:space:]]+TRIGGER ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "删除触发器${proc_suffix}"
    fi
    # [规则 DDL-008 END]


    # ================================================================
    # [规则 DDL-009] ALTER TABLE ... DROP COLUMN - 删除列
    # ================================================================
    if [[ "$upper" =~ ALTER[[:space:]]+TABLE ]] && [[ "$upper" =~ DROP[[:space:]]+COLUMN ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "删除表列，数据不可恢复${proc_suffix}"
    fi
    # [规则 DDL-009 END]


    # ================================================================
    # [规则 DDL-010] ALTER TABLE ... ALTER COLUMN - 修改列类型
    # ================================================================
    if [[ "$upper" =~ ALTER[[:space:]]+TABLE ]] && [[ "$upper" =~ ALTER[[:space:]]+COLUMN ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "修改列类型，可能导致数据截断${proc_suffix}"
    fi
    # [规则 DDL-010 END]


    # ================================================================
    # [规则 DDL-011] sp_rename - 重命名对象
    # ================================================================
    if [[ "$upper" == *"SP_RENAME"* ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "重命名数据库对象，可能影响依赖关系${proc_suffix}"
    fi
    # [规则 DDL-011 END]


    # ================================================================
    # [规则 DDL-012] DISABLE/ENABLE TRIGGER - 禁用/启用触发器
    # ================================================================
    local _p_trigger='(DISABLE|ENABLE)[[:space:]]+TRIGGER'
    if [[ "$upper" =~ $_p_trigger ]]; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" "禁用/启用触发器${proc_suffix}"
    fi
    # [规则 DDL-012 END]


    # ================================================================
    # [规则 DDL-013] ALTER TABLE ... DROP CONSTRAINT - 约束变更
    # ================================================================
    if [[ "$upper" =~ ALTER[[:space:]]+TABLE ]] && [[ "$upper" =~ DROP[[:space:]]+CONSTRAINT ]]; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" "删除表约束${proc_suffix}"
    fi
    # [规则 DDL-013 END]


    # ================================================================
    # [规则 DML-001] DELETE 无 WHERE - 删除全表数据
    #   排除 ON DELETE CASCADE 等 DDL 外键定义中的 DELETE 关键字
    # ================================================================
    if [[ "$upper" =~ DELETE[[:space:]] ]] && \
       [[ "$upper" != *" WHERE "* ]] && \
       [[ "$upper" != *"ON DELETE"* ]]; then
        local sev="CRITICAL"; [ "$in_proc_def" -eq 1 ] && sev="MEDIUM"
        record_finding "$sev" "$file" "$line_no" "$display" "DELETE 无 WHERE 条件，将删除全表数据${proc_suffix}"
    fi
    # [规则 DML-001 END]


    # ================================================================
    # [规则 DML-002] UPDATE 无 WHERE - 更新全表数据
    #   排除 ON UPDATE CASCADE 等 DDL 外键定义中的 UPDATE 关键字
    #   排除 UPDATE STATISTICS 等非DML语句
    # ================================================================
    if [[ "$upper" =~ UPDATE[[:space:]]+[A-Z\[_] ]] && \
       [[ "$upper" != *" WHERE "* ]] && \
       [[ "$upper" != *"ON UPDATE"* ]] && \
       [[ "$upper" != *"UPDATE STATISTICS"* ]]; then
        local sev="CRITICAL"; [ "$in_proc_def" -eq 1 ] && sev="MEDIUM"
        record_finding "$sev" "$file" "$line_no" "$display" "UPDATE 无 WHERE 条件，将更新全表数据${proc_suffix}"
    fi
    # [规则 DML-002 END]


    # ================================================================
    # [规则 DML-003] DELETE/UPDATE 恒真条件 - WHERE 1=1 等
    # ================================================================
    local _p_tautology='WHERE[[:space:]]+(1[[:space:]]*=[[:space:]]*1|0[[:space:]]*=[[:space:]]*0)'
    if [[ "$upper" =~ (DELETE|UPDATE)[[:space:]] ]] && [[ "$upper" =~ $_p_tautology ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "DELETE/UPDATE 使用恒真条件(如 1=1)，等价于无WHERE${proc_suffix}"
    fi
    # [规则 DML-003 END]


    # ================================================================
    # [规则 DML-004] MERGE - 批量合并操作
    # ================================================================
    if [[ "$upper" =~ ^[[:space:]]*MERGE[[:space:]] ]]; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" "MERGE 操作，可能批量增删改${proc_suffix}"
    fi
    # [规则 DML-004 END]


    # ================================================================
    # [规则 DML-005] INSERT INTO ... SELECT - 批量插入
    # ================================================================
    if [[ "$upper" =~ INSERT[[:space:]]+INTO ]] && [[ "$upper" =~ [[:space:]]SELECT[[:space:]] ]]; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" "INSERT INTO ... SELECT 批量插入${proc_suffix}"
    fi
    # [规则 DML-005 END]


    # ================================================================
    # [规则 DML-006] SELECT INTO - 隐式创建表
    # ================================================================
    if [[ "$upper" =~ SELECT.*[[:space:]]INTO[[:space:]] ]] && [[ "$upper" =~ [[:space:]]FROM[[:space:]] ]]; then
        # 排除 INSERT INTO ... SELECT ... FROM （已被 DML-005 覆盖）
        if [[ "$upper" != *"INSERT"* ]]; then
            record_finding "MEDIUM" "$file" "$line_no" "$display" "SELECT INTO 隐式创建新表${proc_suffix}"
        fi
    fi
    # [规则 DML-006 END]


    # ================================================================
    # [规则 DCL-001] DROP LOGIN / DROP USER - 删除账号
    # ================================================================
    local _p_drop_user='DROP[[:space:]]+(LOGIN|USER)[[:space:]]'
    if [[ "$upper" =~ $_p_drop_user ]]; then
        local sev="CRITICAL"; [ "$in_proc_def" -eq 1 ] && sev="MEDIUM"
        record_finding "$sev" "$file" "$line_no" "$display" "删除数据库登录/用户${proc_suffix}"
    fi
    # [规则 DCL-001 END]


    # ================================================================
    # [规则 DCL-002] GRANT - 授权
    # ================================================================
    if [[ "$upper" =~ ^[[:space:]]*GRANT[[:space:]] ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "权限授予操作${proc_suffix}"
    fi
    # [规则 DCL-002 END]


    # ================================================================
    # [规则 DCL-003] REVOKE - 撤权
    # ================================================================
    if [[ "$upper" =~ ^[[:space:]]*REVOKE[[:space:]] ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "权限撤销操作${proc_suffix}"
    fi
    # [规则 DCL-003 END]


    # ================================================================
    # [规则 DCL-004] DENY - 拒绝权限
    # ================================================================
    if [[ "$upper" =~ ^[[:space:]]*DENY[[:space:]] ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "权限拒绝操作${proc_suffix}"
    fi
    # [规则 DCL-004 END]


    # ================================================================
    # [规则 DCL-005] CREATE LOGIN / CREATE USER - 创建账号
    # ================================================================
    local _p_create_user='CREATE[[:space:]]+(LOGIN|USER)[[:space:]]'
    if [[ "$upper" =~ $_p_create_user ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "创建数据库登录/用户${proc_suffix}"
    fi
    # [规则 DCL-005 END]


    # ================================================================
    # [规则 DCL-006] ALTER LOGIN / ALTER USER - 修改账号
    # ================================================================
    local _p_alter_user='ALTER[[:space:]]+(LOGIN|USER)[[:space:]]'
    if [[ "$upper" =~ $_p_alter_user ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "修改数据库登录/用户${proc_suffix}"
    fi
    # [规则 DCL-006 END]


    # ================================================================
    # [规则 DCL-007] ALTER ROLE / sp_addrolemember - 角色变更
    # ================================================================
    if [[ "$upper" =~ ALTER[[:space:]]+ROLE ]] || \
       [[ "$upper" == *"SP_ADDROLEMEMBER"* ]] || \
       [[ "$upper" == *"SP_DROPROLEMEMBER"* ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "数据库角色成员变更${proc_suffix}"
    fi
    # [规则 DCL-007 END]


    # ================================================================
    # [规则 DCL-008] ALTER AUTHORIZATION - 变更所有者
    # ================================================================
    if [[ "$upper" =~ ALTER[[:space:]]+AUTHORIZATION ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "变更对象所有权${proc_suffix}"
    fi
    # [规则 DCL-008 END]


    # ================================================================
    # [规则 SYS-001] xp_cmdshell - 操作系统命令执行
    # ================================================================
    if [[ "$upper" == *"XP_CMDSHELL"* ]]; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" "调用操作系统命令，极高安全风险${proc_suffix}"
    fi
    # [规则 SYS-001 END]


    # ================================================================
    # [规则 SYS-002] SHUTDOWN - 关闭数据库
    # ================================================================
    if [[ "$upper" =~ ^[[:space:]]*SHUTDOWN ]]; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" "关闭数据库服务${proc_suffix}"
    fi
    # [规则 SYS-002 END]


    # ================================================================
    # [规则 SYS-003] RESTORE DATABASE - 还原数据库
    # ================================================================
    if [[ "$upper" =~ RESTORE[[:space:]]+DATABASE ]]; then
        record_finding "CRITICAL" "$file" "$line_no" "$display" "还原数据库，将覆盖现有数据${proc_suffix}"
    fi
    # [规则 SYS-003 END]


    # ================================================================
    # [规则 SYS-004] sp_configure / RECONFIGURE - 服务器配置
    # ================================================================
    if [[ "$upper" == *"SP_CONFIGURE"* ]] || [[ "$upper" =~ ^[[:space:]]*RECONFIGURE ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "修改服务器级配置${proc_suffix}"
    fi
    # [规则 SYS-004 END]


    # ================================================================
    # [规则 SYS-005] ALTER DATABASE - 修改数据库配置
    # ================================================================
    if [[ "$upper" =~ ALTER[[:space:]]+DATABASE ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "修改数据库级配置${proc_suffix}"
    fi
    # [规则 SYS-005 END]


    # ================================================================
    # [规则 SYS-006] KILL - 终止会话
    # ================================================================
    if [[ "$upper" =~ ^[[:space:]]*KILL[[:space:]]+[0-9] ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "终止数据库会话${proc_suffix}"
    fi
    # [规则 SYS-006 END]


    # ================================================================
    # [规则 SYS-007] BULK INSERT - 外部文件导入
    # ================================================================
    if [[ "$upper" =~ BULK[[:space:]]+INSERT ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "外部文件批量导入${proc_suffix}"
    fi
    # [规则 SYS-007 END]


    # ================================================================
    # [规则 SYS-008] OPENROWSET / OPENDATASOURCE - 外部数据源
    # ================================================================
    if [[ "$upper" == *"OPENROWSET"* ]] || [[ "$upper" == *"OPENDATASOURCE"* ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "访问外部数据源${proc_suffix}"
    fi
    # [规则 SYS-008 END]


    # ================================================================
    # [规则 SYS-009] 动态SQL - sp_executesql / EXEC(变量或字符串)
    # ================================================================
    if [[ "$upper" == *"SP_EXECUTESQL"* ]] || \
       [[ "$upper" =~ EXEC[[:space:]]*\([[:space:]]*@ ]] || \
       [[ "$upper" =~ EXECUTE[[:space:]]*\([[:space:]]*@ ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "动态SQL执行，存在注入风险${proc_suffix}"
    fi
    # [规则 SYS-009 END]


    # ================================================================
    # [规则 SYS-010] xp_* 扩展存储过程（排除已捕获的 xp_cmdshell）
    # ================================================================
    if [[ "$upper" =~ XP_[A-Z] ]] && [[ "$upper" != *"XP_CMDSHELL"* ]]; then
        local sev="HIGH"; [ "$in_proc_def" -eq 1 ] && sev="INFO"
        record_finding "$sev" "$file" "$line_no" "$display" "调用扩展存储过程${proc_suffix}"
    fi
    # [规则 SYS-010 END]


    # ================================================================
    # [规则 SYS-011] DBCC - 数据库维护命令
    # ================================================================
    if [[ "$upper" =~ ^[[:space:]]*DBCC[[:space:]] ]]; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" "DBCC 数据库维护命令${proc_suffix}"
    fi
    # [规则 SYS-011 END]


    # ================================================================
    # [规则 SYS-012] BACKUP DATABASE / BACKUP LOG - 备份操作
    # ================================================================
    local _p_backup='BACKUP[[:space:]]+(DATABASE|LOG)'
    if [[ "$upper" =~ $_p_backup ]]; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" "备份操作出现在变更脚本中${proc_suffix}"
    fi
    # [规则 SYS-012 END]


    # ================================================================
    # [规则 SYS-013] WAITFOR DELAY - 延时执行
    # ================================================================
    if [[ "$upper" =~ WAITFOR[[:space:]]+DELAY ]]; then
        record_finding "MEDIUM" "$file" "$line_no" "$display" "延时执行语句${proc_suffix}"
    fi
    # [规则 SYS-013 END]
}


# ============================================================================
# [模块] 报告生成
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


# ============================================================================
# [模块] 主流程
# ============================================================================

main() {
    echo "============================================================"
    echo "  SQL Safety Scanner 开始扫描..."
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

        # 4. 带上下文的逐语句扫描（前一条 + 当前 + 下一条）
        local prev_stmt="" prev_line="" cur_stmt="" cur_line=""
        local first=1
        while IFS=$'\t' read -r s_line s_text; do
            if [ "$first" -eq 1 ]; then
                cur_stmt="$s_text"
                cur_line="$s_line"
                first=0
                continue
            fi
            # 扫描上一条（next_stmt = 当前读入的）
            scan_statement "$cur_stmt" "$filename" "$cur_line" "$s_text"
            cur_stmt="$s_text"
            cur_line="$s_line"
        done < "$stmt_file"
        # 扫描最后一条（无下一条）
        if [ -n "$cur_stmt" ]; then
            scan_statement "$cur_stmt" "$filename" "$cur_line" ""
        fi

        echo "  完成"
        echo ""
    done

    generate_report "$REPORT_FILE"

    # 退出码
    local cc hc
    cc=$(grep -c '^CRITICAL|' "$FINDINGS_FILE" 2>/dev/null || true)
    hc=$(grep -c '^HIGH|' "$FINDINGS_FILE" 2>/dev/null || true)
    : "${cc:=0}" "${hc:=0}"
    [ "$cc" -gt 0 ] && exit 1
    [ "$hc" -gt 0 ] && exit 2
    exit 0
}

main
