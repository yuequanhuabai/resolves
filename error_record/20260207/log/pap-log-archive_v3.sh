#!/bin/bash
set -e

# PAP 应用日志目录
LOG_DIR="/opt/project/PAP/IHUB/log"
# convert 请求日志目录
CONVERT_LOG_DIR="/opt/project/PAP/IHUB/logs/convert"
# 归档目录
ARCHIVE_DIR="/LOG"
# 模块名
MODULE="IHUB-PAP"
# 锁文件
LOCK_FILE="/opt/project/PAP/IHUB/archive_${MODULE}.lock"
# 错误日志文件
ERROR_LOG="$ARCHIVE_DIR/archive_error.log"

# 错误处理函数
log_error() {
    echo "$(date) - [${MODULE}] ERROR: $1" >> "$ERROR_LOG"
    exit 1
}

# 加锁，防止重复执行
exec 200>"$LOCK_FILE"
flock -n 200 || { echo "$(date) - [${MODULE}] another instance is running, skip." >> "$ERROR_LOG"; exit 0; }

# 权限检查：日志目录是否可读
if [ ! -r "$LOG_DIR" ]; then
    log_error "no read permission on $LOG_DIR"
fi

# 确保归档目录存在
mkdir -p "$ARCHIVE_DIR" 2>/dev/null
if [ ! -d "$ARCHIVE_DIR" ]; then
    log_error "cannot create archive dir $ARCHIVE_DIR, try: sudo mkdir -p $ARCHIVE_DIR && sudo chown $(whoami) $ARCHIVE_DIR"
fi

# 权限检查：归档目录是否可写
if [ ! -w "$ARCHIVE_DIR" ]; then
    log_error "no write permission on $ARCHIVE_DIR, try: sudo chown $(whoami) $ARCHIVE_DIR"
fi

# 主机名
HOSTNAME=$(hostname)
# 昨天日期（支持传入参数模拟"今天"，用法：./pap-log-archive.sh 2026-03-27）
if [ -n "$1" ]; then
    date -d "$1" +%Y-%m-%d >/dev/null 2>&1 || { echo "invalid date: $1"; exit 1; }
    YESTERDAY=$(date -d "$1 -1 day" +%Y-%m-%d)
    YESTERDAY_SHORT=$(date -d "$1 -1 day" +%Y%m%d)
else
    YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
    YESTERDAY_SHORT=$(date -d "yesterday" +%Y%m%d)
fi

# ============================================================
# 第一步：收集所有需要归档的日期（<= 昨天）
# 来源1：LOG_DIR/archive/ 下文件名中的日期
# 来源2：CONVERT_LOG_DIR/ 下的日期子目录
# ============================================================
DATES_TO_ARCHIVE=()

# 来源1：扫描 archive/ 下文件名中的日期
if [ -d "$LOG_DIR/archive" ]; then
    ALL_DATES=$(find "$LOG_DIR/archive" -maxdepth 1 -type f -name "*.log" -size +0c -printf '%f\n' 2>/dev/null \
        | grep -oP '\d{4}-\d{2}-\d{2}' \
        | sort -u || true)

    for d in $ALL_DATES; do
        if [[ "$d" < "$YESTERDAY" || "$d" == "$YESTERDAY" ]]; then
            DATE_SHORT_TMP=$(date -d "$d" +%Y%m%d 2>/dev/null) || continue
            ARCHIVE_NAME="${HOSTNAME}.${MODULE}.applog.${DATE_SHORT_TMP}"
            if [ ! -f "$ARCHIVE_DIR/${ARCHIVE_NAME}.tar.gz" ]; then
                DATES_TO_ARCHIVE+=("$d")
            fi
        fi
    done
fi

# 来源2：扫描 CONVERT_LOG_DIR/ 下的日期子目录（格式 YYYYMMDD）
if [ -d "$CONVERT_LOG_DIR" ]; then
    CONVERT_DATES=$(find "$CONVERT_LOG_DIR" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2>/dev/null \
        | grep -P '^\d{8}$' | sort -u || true)

    for ds in $CONVERT_DATES; do
        d=$(date -d "$ds" +%Y-%m-%d 2>/dev/null) || continue
        if [[ "$d" < "$YESTERDAY" || "$d" == "$YESTERDAY" ]]; then
            ARCHIVE_NAME="${HOSTNAME}.${MODULE}.applog.${ds}"
            if [ ! -f "$ARCHIVE_DIR/${ARCHIVE_NAME}.tar.gz" ]; then
                # 去重：已在列表中则跳过
                already=false
                for existing in "${DATES_TO_ARCHIVE[@]}"; do
                    if [ "$existing" = "$d" ]; then already=true; break; fi
                done
                if [ "$already" = false ]; then
                    DATES_TO_ARCHIVE+=("$d")
                fi
            fi
        fi
    done
fi

# 如果昨天不在列表中，检查 server 日志是否需要归档
YESTERDAY_IN_LIST=false
for d in "${DATES_TO_ARCHIVE[@]}"; do
    if [ "$d" = "$YESTERDAY" ]; then
        YESTERDAY_IN_LIST=true
        break
    fi
done

if [ "$YESTERDAY_IN_LIST" = false ] && [ ! -f "$ARCHIVE_DIR/${HOSTNAME}.${MODULE}.applog.${YESTERDAY_SHORT}.tar.gz" ]; then
    for LOG_NAME in server_start.log server_stop.log; do
        if [ -f "$LOG_DIR/$LOG_NAME" ] && [ -s "$LOG_DIR/$LOG_NAME" ]; then
            DATES_TO_ARCHIVE+=("$YESTERDAY")
            break
        fi
    done
fi

# 没有任何日期需要归档
if [ ${#DATES_TO_ARCHIVE[@]} -eq 0 ]; then
    echo "$(date) - no log files to archive, skip." >> "$ARCHIVE_DIR/archive.log"
    exit 0
fi

# 对日期排序（从早到晚）
IFS=$'\n' DATES_TO_ARCHIVE=($(sort <<<"${DATES_TO_ARCHIVE[*]}")); unset IFS

# ============================================================
# 第二步：按日期逐个打包归档
# ============================================================
SERVER_LOGS_ARCHIVED=false

for DATE in "${DATES_TO_ARCHIVE[@]}"; do
    DATE_SHORT=$(date -d "$DATE" +%Y%m%d)
    ARCHIVE_NAME="${HOSTNAME}.${MODULE}.applog.${DATE_SHORT}"

    # 幂等检查
    if [ -f "$ARCHIVE_DIR/${ARCHIVE_NAME}.tar.gz" ]; then
        continue
    fi

    # LOG_TAR_LIST：相对 LOG_DIR 的文件（archive/ 文件 + server 日志）
    # CONVERT_TAR_LIST：相对 LOGS_BASE_DIR 的文件（logs/convert/YYYYMMDD/ 文件）
    LOG_TAR_LIST=()
    ARCHIVE_SOURCE_FILES=()
    CONVERT_TAR_LIST=()
    CONVERT_SOURCE_FILES=()
    LOGS_BASE_DIR=$(dirname "$CONVERT_LOG_DIR")

    # 收集该日期的 archive 目录文件
    if [ -d "$LOG_DIR/archive" ]; then
        while IFS= read -r -d '' f; do
            LOG_TAR_LIST+=("archive/$(basename "$f")")
            ARCHIVE_SOURCE_FILES+=("$f")
        done < <(find "$LOG_DIR/archive" -maxdepth 1 -type f \( -name "*.${DATE}.*.log" -o -name "*.${DATE}.log" \) -size +0c -print0 2>/dev/null)
    fi

    # 收集该日期的 convert 请求日志文件
    CONVERT_DATE_DIR="$CONVERT_LOG_DIR/${DATE_SHORT}"
    if [ -d "$CONVERT_DATE_DIR" ]; then
        while IFS= read -r -d '' f; do
            CONVERT_TAR_LIST+=("convert/${DATE_SHORT}/$(basename "$f")")
            CONVERT_SOURCE_FILES+=("$f")
        done < <(find "$CONVERT_DATE_DIR" -maxdepth 1 -type f -name "*.log" -print0 2>/dev/null)
    fi

    # 昨天的归档加入 server 日志（存在且非空才加入）
    if [ "$DATE" = "$YESTERDAY" ]; then
        for LOG_NAME in server_start.log server_stop.log; do
            if [ -f "$LOG_DIR/$LOG_NAME" ] && [ -s "$LOG_DIR/$LOG_NAME" ]; then
                LOG_TAR_LIST+=("$LOG_NAME")
            fi
        done
    fi

    # 该日期没有文件需要归档
    if [ ${#LOG_TAR_LIST[@]} -eq 0 ] && [ ${#CONVERT_TAR_LIST[@]} -eq 0 ]; then
        continue
    fi

    # 磁盘空间检查
    TOTAL_SIZE=0
    if [ ${#ARCHIVE_SOURCE_FILES[@]} -gt 0 ]; then
        TOTAL_SIZE=$(du -sk "${ARCHIVE_SOURCE_FILES[@]}" 2>/dev/null | awk '{sum+=$1} END{print sum}')
    fi
    if [ ${#CONVERT_SOURCE_FILES[@]} -gt 0 ]; then
        S=$(du -sk "${CONVERT_SOURCE_FILES[@]}" 2>/dev/null | awk '{sum+=$1} END{print sum}')
        TOTAL_SIZE=$((TOTAL_SIZE + S))
    fi
    if [ "$DATE" = "$YESTERDAY" ]; then
        for LOG_NAME in server_start.log server_stop.log; do
            if [ -f "$LOG_DIR/$LOG_NAME" ] && [ -s "$LOG_DIR/$LOG_NAME" ]; then
                S=$(du -sk "$LOG_DIR/$LOG_NAME" 2>/dev/null | awk '{print $1}')
                TOTAL_SIZE=$((TOTAL_SIZE + S))
            fi
        done
    fi
    if [ "$TOTAL_SIZE" -gt 0 ]; then
        ARCHIVE_AVAIL=$(df -k "$ARCHIVE_DIR" | tail -1 | awk '{print $4}')
        if [ "$ARCHIVE_AVAIL" -lt "$TOTAL_SIZE" ]; then
            log_error "insufficient disk space on $ARCHIVE_DIR: need ${TOTAL_SIZE}KB, available ${ARCHIVE_AVAIL}KB"
        fi
    fi

    # 打包压缩
    # LOG_TAR_LIST 以 LOG_DIR 为基准，CONVERT_TAR_LIST 以 LOGS_BASE_DIR 为基准
    TAR_ARGS=()
    if [ ${#LOG_TAR_LIST[@]} -gt 0 ]; then
        TAR_ARGS+=(-C "$LOG_DIR" "${LOG_TAR_LIST[@]}")
    fi
    if [ ${#CONVERT_TAR_LIST[@]} -gt 0 ]; then
        TAR_ARGS+=(-C "$LOGS_BASE_DIR" "${CONVERT_TAR_LIST[@]}")
    fi
    tar -czf "$ARCHIVE_DIR/${ARCHIVE_NAME}.tar.gz" "${TAR_ARGS[@]}" \
        || log_error "failed to create tar archive ${ARCHIVE_NAME}.tar.gz"

    # 删除 archive 目录下已归档的源文件
    for f in "${ARCHIVE_SOURCE_FILES[@]}"; do
        rm -f "$f"
    done

    # 删除 convert 日期子目录下已归档的源文件，子目录为空则删除
    for f in "${CONVERT_SOURCE_FILES[@]}"; do
        rm -f "$f"
    done
    if [ -d "$CONVERT_DATE_DIR" ] && [ -z "$(ls -A "$CONVERT_DATE_DIR" 2>/dev/null)" ]; then
        rmdir "$CONVERT_DATE_DIR"
    fi

    # 标记 server 日志已归档
    if [ "$DATE" = "$YESTERDAY" ]; then
        SERVER_LOGS_ARCHIVED=true
    fi

    TOTAL_FILES=$(( ${#LOG_TAR_LIST[@]} + ${#CONVERT_TAR_LIST[@]} ))
    echo "$(date) - archived ${ARCHIVE_NAME}.tar.gz (files: ${TOTAL_FILES})" >> "$ARCHIVE_DIR/archive.log"
done

# ============================================================
# 第三步：清空 server 日志（全部归档完成后）
# ============================================================
if [ "$SERVER_LOGS_ARCHIVED" = true ]; then
    for LOG_NAME in server_start.log server_stop.log; do
        if [ -f "$LOG_DIR/$LOG_NAME" ]; then
            > "$LOG_DIR/$LOG_NAME"
        fi
    done
fi
