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

# ---- 磁盘空间预估参数 ----
# 压缩比取样字节数：从当次最大的源文件取头部样本实测压缩比。
# 日志内容同质，头部样本足以代表整体，成本上限即此值。
SAMPLE_BYTES=10485760
# 取样失败时的兜底压缩比（放大 100 倍的整数，300 = 3:1，保守值）
RATIO_DEFAULT=300
# 压缩比上限（2000 = 20:1）。实测再高也不采信，避免门槛被压得过低
RATIO_MAX=2000
# 压缩比下限（100 = 1:1）
RATIO_MIN=100
# 安全余量百分比（150 = 在估算值上再留 50%）
SPACE_SAFETY_PCT=150
# 最低可用空间保护，单位 KB（10MB）。
# 不要设太大：它是加在估算值之上的，设成几十 MB 会让小批量归档的
# 门槛反而高于"按未压缩体积判断"，失去本次修正的意义。
SPACE_FLOOR_KB=10240

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

# 清理上次异常中断残留的临时包（仅限本机前缀，且超过 1 天）
find "$ARCHIVE_DIR" -maxdepth 1 -type f -name ".${HOSTNAME}.${MODULE}.applog.*.tmp.*" -mtime +1 -delete 2>/dev/null || true

# 昨天日期（支持传入参数模拟"今天"，用法：./pap-log-archive_v5.sh 2026-03-27）
if [ -n "$1" ]; then
    date -d "$1" +%Y-%m-%d >/dev/null 2>&1 || { echo "invalid date: $1"; exit 1; }
    YESTERDAY=$(date -d "$1 -1 day" +%Y-%m-%d)
    YESTERDAY_SHORT=$(date -d "$1 -1 day" +%Y%m%d)
else
    YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
    YESTERDAY_SHORT=$(date -d "yesterday" +%Y%m%d)
fi

# ============================================================
# 把放大 100 倍的整数比格式化成可读形式，如 1240 -> 12.4:1
# ============================================================
fmt_ratio() {
    local r=${1:-100}
    echo "$(( r / 100 )).$(( r % 100 / 10 )):1"
}

# ============================================================
# 压缩比取样：从给定文件取头部样本，实测 gzip 压缩比
# 输出放大 100 倍的整数比（raw*100/comp），便于纯整数运算
# ============================================================
sample_ratio() {
    local f="$1" raw comp r
    [ -n "$f" ] && [ -f "$f" ] || { echo "$RATIO_DEFAULT"; return; }

    raw=$(head -c "$SAMPLE_BYTES" "$f" 2>/dev/null | wc -c)
    raw=${raw:-0}
    # 样本太小不足以代表整体，用兜底值
    if [ "$raw" -lt 65536 ]; then
        echo "$RATIO_DEFAULT"; return
    fi

    comp=$(head -c "$SAMPLE_BYTES" "$f" 2>/dev/null | gzip -c 2>/dev/null | wc -c)
    comp=${comp:-0}
    if [ "$comp" -le 0 ]; then
        echo "$RATIO_DEFAULT"; return
    fi

    r=$(( raw * 100 / comp ))
    [ "$r" -lt "$RATIO_MIN" ] && r=$RATIO_MIN
    [ "$r" -gt "$RATIO_MAX" ] && r=$RATIO_MAX
    echo "$r"
}

# ============================================================
# 第一步：收集所有需要归档的日期（<= 昨天）
# 来源1：LOG_DIR/archive/ 下文件名中的日期
# 来源2：CONVERT_LOG_DIR/ 下的日期子目录
# 注意：不以"tar 包已存在"跳过日期。只要磁盘上还有该日期的
# 日志文件就纳入处理，迟到的文件会打进补充包（.suppN.tar.gz）。
# ============================================================
DATES_TO_ARCHIVE=()

# 来源1：扫描 archive/ 下文件名中的日期
if [ -d "$LOG_DIR/archive" ]; then
    ALL_DATES=$(find "$LOG_DIR/archive" -maxdepth 1 -type f -name "*.log" -size +0c -printf '%f\n' 2>/dev/null \
        | grep -oP '\d{4}-\d{2}-\d{2}' \
        | sort -u || true)

    for d in $ALL_DATES; do
        if [[ "$d" < "$YESTERDAY" || "$d" == "$YESTERDAY" ]]; then
            date -d "$d" +%Y%m%d >/dev/null 2>&1 || continue
            DATES_TO_ARCHIVE+=("$d")
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
            # 去重：已在列表中则跳过
            already=false
            for existing in "${DATES_TO_ARCHIVE[@]}"; do
                if [ "$existing" = "$d" ]; then already=true; break; fi
            done
            if [ "$already" = false ]; then
                DATES_TO_ARCHIVE+=("$d")
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

if [ "$YESTERDAY_IN_LIST" = false ]; then
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

    # 文件级幂等：主包不存在则打主包；主包已存在说明这些是
    # 迟到的文件（logback 懒滚动/日切晚于本脚本），打补充包，
    # 序号递增，绝不覆盖已有归档。
    TARGET_NAME="${ARCHIVE_NAME}.tar.gz"
    if [ -f "$ARCHIVE_DIR/$TARGET_NAME" ]; then
        N=1
        while [ -f "$ARCHIVE_DIR/${ARCHIVE_NAME}.supp${N}.tar.gz" ]; do
            N=$((N+1))
        done
        TARGET_NAME="${ARCHIVE_NAME}.supp${N}.tar.gz"
    fi

    # ------------------------------------------------------------
    # 磁盘空间检查
    # TOTAL_SIZE 是"未压缩"的源文件总量，但 tar 是 -czf 带 gzip 压缩的。
    # 直接拿它当门槛会虚高一个数量级（文本日志压缩比常在 8:1~20:1），
    # 造成"空间明明够却拒绝归档"的误杀。这里先实测压缩比，
    # 再按估算的压缩后体积 + 安全余量来判断。
    # ------------------------------------------------------------
    TOTAL_SIZE=0
    if [ ${#ARCHIVE_SOURCE_FILES[@]} -gt 0 ]; then
        S=$(du -sk "${ARCHIVE_SOURCE_FILES[@]}" 2>/dev/null | awk '{sum+=$1} END{print sum+0}')
        TOTAL_SIZE=$((TOTAL_SIZE + ${S:-0}))
    fi
    if [ ${#CONVERT_SOURCE_FILES[@]} -gt 0 ]; then
        S=$(du -sk "${CONVERT_SOURCE_FILES[@]}" 2>/dev/null | awk '{sum+=$1} END{print sum+0}')
        TOTAL_SIZE=$((TOTAL_SIZE + ${S:-0}))
    fi
    if [ "$DATE" = "$YESTERDAY" ]; then
        for LOG_NAME in server_start.log server_stop.log; do
            if [ -f "$LOG_DIR/$LOG_NAME" ] && [ -s "$LOG_DIR/$LOG_NAME" ]; then
                S=$(du -sk "$LOG_DIR/$LOG_NAME" 2>/dev/null | awk '{print $1+0}')
                TOTAL_SIZE=$((TOTAL_SIZE + ${S:-0}))
            fi
        done
    fi

    RATIO=$RATIO_DEFAULT
    NEED_KB=0
    if [ "$TOTAL_SIZE" -gt 0 ]; then
        # 取当次最大的源文件做压缩比取样
        SAMPLE_SRC=""
        if [ ${#ARCHIVE_SOURCE_FILES[@]} -gt 0 ]; then
            SAMPLE_SRC=$(ls -S "${ARCHIVE_SOURCE_FILES[@]}" 2>/dev/null | head -1)
        elif [ ${#CONVERT_SOURCE_FILES[@]} -gt 0 ]; then
            SAMPLE_SRC=$(ls -S "${CONVERT_SOURCE_FILES[@]}" 2>/dev/null | head -1)
        fi
        RATIO=$(sample_ratio "$SAMPLE_SRC")

        # 估算压缩后体积 + 安全余量 + 最低可用空间保护
        NEED_KB=$(( TOTAL_SIZE * SPACE_SAFETY_PCT / RATIO + SPACE_FLOOR_KB ))
        # 封顶：gzip 最坏情况也就是未压缩体积，再高没有意义
        MAX_NEED_KB=$(( TOTAL_SIZE + SPACE_FLOOR_KB ))
        [ "$NEED_KB" -gt "$MAX_NEED_KB" ] && NEED_KB=$MAX_NEED_KB

        # df -kP 强制 POSIX 单行输出，避免长设备名折行导致取错列
        ARCHIVE_AVAIL=$(df -kP "$ARCHIVE_DIR" 2>/dev/null | awk 'NR==2{print $4+0}')
        ARCHIVE_AVAIL=${ARCHIVE_AVAIL:-0}
        if [ "$ARCHIVE_AVAIL" -le 0 ]; then
            echo "$(date) - [${MODULE}] WARN: cannot determine free space on $ARCHIVE_DIR, skip space check for ${DATE}" >> "$ERROR_LOG"
        elif [ "$ARCHIVE_AVAIL" -lt "$NEED_KB" ]; then
            log_error "insufficient disk space on $ARCHIVE_DIR for ${DATE}: raw ${TOTAL_SIZE}KB, ratio $(fmt_ratio $RATIO), need ${NEED_KB}KB, available ${ARCHIVE_AVAIL}KB"
        fi
    fi

    # ------------------------------------------------------------
    # 打包压缩（原子写入）
    # 先写临时文件，gzip -t 校验通过后再 mv 到最终名。
    # 中途失败一律清掉临时文件，绝不留下半个 tar 包
    # （残包会让该日期在后续运行中被当成"已归档"而永久跳过）。
    # LOG_TAR_LIST 以 LOG_DIR 为基准，CONVERT_TAR_LIST 以 LOGS_BASE_DIR 为基准
    # ------------------------------------------------------------
    TAR_ARGS=()
    if [ ${#LOG_TAR_LIST[@]} -gt 0 ]; then
        TAR_ARGS+=(-C "$LOG_DIR" "${LOG_TAR_LIST[@]}")
    fi
    if [ ${#CONVERT_TAR_LIST[@]} -gt 0 ]; then
        TAR_ARGS+=(-C "$LOGS_BASE_DIR" "${CONVERT_TAR_LIST[@]}")
    fi

    TMP_TAR="$ARCHIVE_DIR/.${TARGET_NAME}.tmp.$$"
    rm -f "$TMP_TAR"
    if ! tar -czf "$TMP_TAR" "${TAR_ARGS[@]}"; then
        rm -f "$TMP_TAR"
        log_error "failed to create tar archive $TARGET_NAME"
    fi
    if ! gzip -t "$TMP_TAR" 2>/dev/null; then
        rm -f "$TMP_TAR"
        log_error "tar archive $TARGET_NAME failed integrity check (gzip -t)"
    fi
    if ! mv -f "$TMP_TAR" "$ARCHIVE_DIR/$TARGET_NAME"; then
        rm -f "$TMP_TAR"
        log_error "failed to finalize tar archive $TARGET_NAME"
    fi

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
    OUT_KB=$(du -sk "$ARCHIVE_DIR/$TARGET_NAME" 2>/dev/null | awk '{print $1+0}')
    echo "$(date) - archived $TARGET_NAME (files: ${TOTAL_FILES}, raw: ${TOTAL_SIZE}KB, out: ${OUT_KB:-0}KB, est_need: ${NEED_KB}KB, ratio: $(fmt_ratio $RATIO))" >> "$ARCHIVE_DIR/archive.log"
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
