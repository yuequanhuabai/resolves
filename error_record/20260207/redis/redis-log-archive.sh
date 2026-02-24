#!/bin/bash

# Redis 日志路径
LOG="/var/log/redis.log"
# 归档目录
ARCHIVE_DIR="/log"
# 保留天数
KEEP_DAYS=30

# 确保归档目录存在
mkdir -p "$ARCHIVE_DIR"

# 当前时间戳
TIMESTAMP=$(date +%Y%m%d%H%M)

# 日志文件为空则跳过
if [ ! -s "$LOG" ]; then
    echo "$(date) - log file is empty, skip." >> "$ARCHIVE_DIR/archive.log"
    exit 0
fi

# 复制日志到归档目录
cp "$LOG" "$ARCHIVE_DIR/redis.log-$TIMESTAMP"

# 清空原日志
> "$LOG"

# 压缩归档文件
gzip "$ARCHIVE_DIR/redis.log-$TIMESTAMP"

# 删除超过保留天数的旧归档（已屏蔽）
# find "$ARCHIVE_DIR" -name "redis.log-*.gz" -mtime +$KEEP_DAYS -delete

echo "$(date) - archived to redis.log-$TIMESTAMP.gz" >> "$ARCHIVE_DIR/archive.log"
