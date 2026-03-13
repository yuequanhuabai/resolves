#!/bin/bash
set -e

# PAP 应用日志目录
LOG_DIR="/opt/project/PAP/IHUB/back-end/logs"
# 归档目录
ARCHIVE_DIR="/LOG"
# 模块名
MODULE="IHUB-PAP"
# 锁文件
LOCK_FILE="/tmp/archive_${MODULE}.lock"
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
# 前一天日期（脚本凌晨执行，归档前一天日志）
DATETIME=$(date -d "yesterday" +%Y%m%d)
# logback archive 目录的日期格式（yyyy-MM-dd），取前一天
DATE_DASH=$(date -d "yesterday" +%Y-%m-%d)
# 归档文件名
ARCHIVE_NAME="${HOSTNAME}.${MODULE}.applog.${DATETIME}"

# 幂等检查：当天归档已存在则跳过
if [ -f "$ARCHIVE_DIR/${ARCHIVE_NAME}.tar.gz" ]; then
    echo "$(date) - archive ${ARCHIVE_NAME}.tar.gz already exists, skip." >> "$ARCHIVE_DIR/archive.log"
    exit 0
fi

# 查找所有非空的 IHUB 活跃日志文件，存入数组
LOG_FILES=()
while IFS= read -r -d '' f; do
    LOG_FILES+=("$f")
done < <(find "$LOG_DIR" -name "IHUB_*.log" -size +0c -print0 2>/dev/null)

# 查找 archive 目录下当天的滚动日志文件
HISTORY_FILES=()
if [ -d "$LOG_DIR/archive" ]; then
    while IFS= read -r -d '' f; do
        HISTORY_FILES+=("$f")
    done < <(find "$LOG_DIR/archive" -name "IHUB_*.${DATE_DASH}.*.log" -size +0c -print0 2>/dev/null)
fi

if [ ${#LOG_FILES[@]} -eq 0 ] && [ ${#HISTORY_FILES[@]} -eq 0 ]; then
    echo "$(date) - no log files to archive, skip." >> "$ARCHIVE_DIR/archive.log"
    exit 0
fi

# 磁盘空间检查（活跃日志 + archive 当天日志）
ALL_FILES=("${LOG_FILES[@]}" "${HISTORY_FILES[@]}")
LOG_TOTAL_SIZE=$(du -sk "${ALL_FILES[@]}" 2>/dev/null | awk '{sum+=$1} END{print sum}')
# 检查日志目录：cp 副本需要与日志等量的空间
LOG_DIR_AVAIL=$(df -k "$LOG_DIR" | tail -1 | awk '{print $4}')
if [ "$LOG_DIR_AVAIL" -lt "$LOG_TOTAL_SIZE" ]; then
    log_error "insufficient disk space on $LOG_DIR: need ${LOG_TOTAL_SIZE}KB, available ${LOG_DIR_AVAIL}KB"
fi
# 检查归档目录：tar.gz 需要空间（预留与日志等量的空间）
ARCHIVE_DIR_AVAIL=$(df -k "$ARCHIVE_DIR" | tail -1 | awk '{print $4}')
if [ "$ARCHIVE_DIR_AVAIL" -lt "$LOG_TOTAL_SIZE" ]; then
    log_error "insufficient disk space on $ARCHIVE_DIR: need ${LOG_TOTAL_SIZE}KB, available ${ARCHIVE_DIR_AVAIL}KB"
fi

# copytruncate：复制日志到日志目录并加日期后缀，然后清空原文件
# 先完成所有复制，确认全部成功后再清空原文件，避免 cp 失败导致日志丢失
for LOG in "${LOG_FILES[@]}"; do
    BASENAME=$(basename "$LOG")
    cp "$LOG" "$LOG_DIR/${BASENAME}-${DATETIME}" || log_error "failed to copy $LOG, original file not truncated"
done

for LOG in "${LOG_FILES[@]}"; do
    > "$LOG"
done

# 查找当天产生的轮转文件，存入数组
ROTATED_FILES=()
while IFS= read -r -d '' f; do
    ROTATED_FILES+=("$f")
done < <(find "$LOG_DIR" -name "IHUB_*.log-${DATETIME}" -print0 2>/dev/null)

# 将轮转文件 + archive 当天文件一起打包归档到 /LOG
TAR_LIST=()
for f in "${ROTATED_FILES[@]}"; do
    TAR_LIST+=("$(basename "$f")")
done
for f in "${HISTORY_FILES[@]}"; do
    TAR_LIST+=("archive/$(basename "$f")")
done

if [ ${#TAR_LIST[@]} -gt 0 ]; then
    tar -czf "$ARCHIVE_DIR/${ARCHIVE_NAME}.tar.gz" -C "$LOG_DIR" "${TAR_LIST[@]}" || log_error "failed to create tar archive ${ARCHIVE_NAME}.tar.gz"

    # 只删除轮转的临时文件，archive 文件由 logback 自行管理
    for f in "${ROTATED_FILES[@]}"; do
        rm -f "$f"
    done
fi

echo "$(date) - archived to ${ARCHIVE_NAME}.tar.gz" >> "$ARCHIVE_DIR/archive.log"
