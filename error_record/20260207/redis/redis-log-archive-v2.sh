#!/bin/bash

# Redis 日志路径
LOG="/var/log/redis.log"
# 归档目录
ARCHIVE_DIR="/LOG"
# 保留天数
KEEP_DAYS=30

# 权限检查：日志文件是否可读
if [ ! -r "$LOG" ]; then
    echo "ERROR: no read permission on $LOG" >&2
    exit 1
fi

# 权限检查：日志文件是否可写（用于移动）
if [ ! -w "$LOG" ]; then
    echo "ERROR: no write permission on $LOG" >&2
    exit 1
fi

# 确保归档目录存在
mkdir -p "$ARCHIVE_DIR" 2>/dev/null
if [ ! -d "$ARCHIVE_DIR" ]; then
    echo "ERROR: cannot create archive dir $ARCHIVE_DIR, try: sudo mkdir -p $ARCHIVE_DIR && sudo chown \$(whoami) $ARCHIVE_DIR" >&2
    exit 1
fi

# 权限检查：归档目录是否可写
if [ ! -w "$ARCHIVE_DIR" ]; then
    echo "ERROR: no write permission on $ARCHIVE_DIR, try: sudo chown \$(whoami) $ARCHIVE_DIR" >&2
    exit 1
fi

# 主机名
HOSTNAME=$(hostname)
# 当前时间戳
TIMESTAMP=$(date +%Y%m%d%H%M)
# 归档文件名
ARCHIVE_NAME="${HOSTNAME}.ihub.pap_redis_log_${TIMESTAMP}"

# 日志文件为空则跳过
if [ ! -s "$LOG" ]; then
    echo "$(date) - log file is empty, skip." >> "$ARCHIVE_DIR/archive.log"
    exit 0
fi

# 移动日志到归档目录（不会丢失任何日志）
mv "$LOG" "$ARCHIVE_DIR/$ARCHIVE_NAME"

# 通知 Redis 重新打开日志文件
redis-cli DEBUG RELOAD-LOG 2>/dev/null || kill -HUP $(pidof redis-server)

# 压缩归档文件
tar -zcf "$ARCHIVE_DIR/$ARCHIVE_NAME.tar.gz" -C "$ARCHIVE_DIR" "$ARCHIVE_NAME"

# 删除压缩前的临时文件
rm -f "$ARCHIVE_DIR/$ARCHIVE_NAME"

# 删除超过保留天数的旧归档（已屏蔽）
# find "$ARCHIVE_DIR" -name "*.ihub.pap_redis_log_*.tar.gz" -mtime +$KEEP_DAYS -delete

echo "$(date) - archived to $ARCHIVE_NAME.tar.gz" >> "$ARCHIVE_DIR/archive.log"
