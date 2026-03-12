#!/bin/bash
set -e

LOG_DIR="/opt/project/PAP/IHUB/back-end/logs"
ARCHIVE_DIR="/LOG"
MODULE="IHUB-PAP"
LOCK_FILE="/tmp/archive_${MODULE}.lock"
ERROR_LOG="$ARCHIVE_DIR/archive_error.log"

log_error() {
    echo "$(date) - [${MODULE}] ERROR: $1" >> "$ERROR_LOG"
    exit 1
}

exec 200>"$LOCK_FILE"
flock -n 200 || { echo "$(date) - [${MODULE}] another instance is running, skip." >> "$ERROR_LOG"; exit 0; }

[ ! -r "$LOG_DIR" ] && log_error "no read permission on $LOG_DIR"

mkdir -p "$ARCHIVE_DIR" 2>/dev/null
[ ! -d "$ARCHIVE_DIR" ] && log_error "cannot create archive dir $ARCHIVE_DIR"
[ ! -w "$ARCHIVE_DIR" ] && log_error "no write permission on $ARCHIVE_DIR"

HOSTNAME=$(hostname)
DATETIME=$(date +%Y%m%d)
DATE_DASH=$(date +%Y-%m-%d)
ARCHIVE_NAME="${HOSTNAME}.${MODULE}.applog.${DATETIME}"

[ -f "$ARCHIVE_DIR/${ARCHIVE_NAME}.tar.gz" ] && { echo "$(date) - archive ${ARCHIVE_NAME}.tar.gz already exists, skip." >> "$ARCHIVE_DIR/archive.log"; exit 0; }

LOG_FILES=()
while IFS= read -r -d '' f; do
    LOG_FILES+=("$f")
done < <(find "$LOG_DIR" -name "IHUB_*.log" -size +0c -print0 2>/dev/null)

HISTORY_FILES=()
if [ -d "$LOG_DIR/history" ]; then
    while IFS= read -r -d '' f; do
        HISTORY_FILES+=("$f")
    done < <(find "$LOG_DIR/history" -name "IHUB_*.${DATE_DASH}.*.log" -size +0c -print0 2>/dev/null)
fi

[ ${#LOG_FILES[@]} -eq 0 ] && [ ${#HISTORY_FILES[@]} -eq 0 ] && { echo "$(date) - no log files to archive, skip." >> "$ARCHIVE_DIR/archive.log"; exit 0; }

ALL_FILES=("${LOG_FILES[@]}" "${HISTORY_FILES[@]}")
LOG_TOTAL_SIZE=$(du -sk "${ALL_FILES[@]}" 2>/dev/null | awk '{sum+=$1} END{print sum}')
LOG_DIR_AVAIL=$(df -k "$LOG_DIR" | tail -1 | awk '{print $4}')
[ "$LOG_DIR_AVAIL" -lt "$LOG_TOTAL_SIZE" ] && log_error "insufficient disk space on $LOG_DIR: need ${LOG_TOTAL_SIZE}KB, available ${LOG_DIR_AVAIL}KB"
ARCHIVE_DIR_AVAIL=$(df -k "$ARCHIVE_DIR" | tail -1 | awk '{print $4}')
[ "$ARCHIVE_DIR_AVAIL" -lt "$LOG_TOTAL_SIZE" ] && log_error "insufficient disk space on $ARCHIVE_DIR: need ${LOG_TOTAL_SIZE}KB, available ${ARCHIVE_DIR_AVAIL}KB"

for LOG in "${LOG_FILES[@]}"; do
    BASENAME=$(basename "$LOG")
    cp "$LOG" "$LOG_DIR/${BASENAME}-${DATETIME}" || log_error "failed to copy $LOG, original file not truncated"
done

for LOG in "${LOG_FILES[@]}"; do
    > "$LOG"
done

ROTATED_FILES=()
while IFS= read -r -d '' f; do
    ROTATED_FILES+=("$f")
done < <(find "$LOG_DIR" -name "IHUB_*.log-${DATETIME}" -print0 2>/dev/null)

TAR_LIST=()
for f in "${ROTATED_FILES[@]}"; do
    TAR_LIST+=("$(basename "$f")")
done
for f in "${HISTORY_FILES[@]}"; do
    TAR_LIST+=("history/$(basename "$f")")
done

if [ ${#TAR_LIST[@]} -gt 0 ]; then
    tar -czf "$ARCHIVE_DIR/${ARCHIVE_NAME}.tar.gz" -C "$LOG_DIR" "${TAR_LIST[@]}" || log_error "failed to create tar archive ${ARCHIVE_NAME}.tar.gz"

    for f in "${ROTATED_FILES[@]}"; do
        rm -f "$f"
    done
fi

echo "$(date) - archived to ${ARCHIVE_NAME}.tar.gz" >> "$ARCHIVE_DIR/archive.log"
