#!/bin/bash
# ============================================================================
#  模块 04: 语句解析 - 将SQL文件拆分为独立语句（含行号追踪）
#  依赖: 无
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
