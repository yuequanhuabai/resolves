#!/bin/bash
# pap-log-archive_v4.sh 沙箱测试
# 用法（Linux 机器上）: bash test_pap_archive_v4.sh ./pap-log-archive_v4.sh
# 所有操作都在 /tmp/pap_archive_test 沙箱内进行，不触碰生产目录。
set -u

SRC="${1:-./pap-log-archive_v4.sh}"
TEST_ROOT="/tmp/pap_archive_test"
HOST=$(hostname)
MODULE="IHUB-PAP"

# 固定模拟"今天"为 2026-08-19，与生产现象对齐
TODAY="2026-08-19"
YD="2026-08-18"
YDS="20260818"

LOGD="$TEST_ROOT/LOG"
APPD="$TEST_ROOT/IHUB/log"
CONVD="$TEST_ROOT/IHUB/logs/convert"
SCRIPT="$TEST_ROOT/archive_test.sh"

PASS=0; FAIL=0

ok()  { echo "    PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "    FAIL: $1"; FAIL=$((FAIL+1)); }
# assert "描述" 命令...  （命令成功即 PASS）
assert() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }
tar_has()     { tar -tzf "$1" 2>/dev/null | grep -qF -- "$2"; }
tar_not_has() { ! tar_has "$1" "$2"; }

# 生成沙箱版脚本：替换生产路径
prepare_script() {
    [ -f "$SRC" ] || { echo "找不到源脚本: $SRC"; exit 1; }
    mkdir -p "$TEST_ROOT"
    sed -e "s#/opt/project/PAP/IHUB#$TEST_ROOT/IHUB#g" \
        -e "s#ARCHIVE_DIR=\"/LOG\"#ARCHIVE_DIR=\"$LOGD\"#" \
        "$SRC" > "$SCRIPT"
    chmod +x "$SCRIPT"
}

# 重建干净的沙箱目录结构
reset_env() {
    rm -rf "$APPD" "$CONVD" "$LOGD"
    mkdir -p "$APPD/archive" "$CONVD" "$LOGD"
}

run() { bash "$SCRIPT" "$TODAY"; }

mkf() { echo "dummy log content $RANDOM" > "$1"; }   # 生成非空文件

MAIN="$LOGD/${HOST}.${MODULE}.applog.${YDS}.tar.gz"

prepare_script

# ============================================================
echo "case 1: 基础归档（archive + convert + server 日志，今天的文件不动）"
# ============================================================
reset_env
mkf "$APPD/archive/IHUB_ALL.applog.${YD}.0.log"
mkf "$APPD/archive/IHUB_INFO.applog.${YD}.0.log"
mkf "$APPD/archive/IHUB_ALL.applog.${TODAY}.0.log"      # 今天的，必须原样保留
mkdir -p "$CONVD/${YDS}"
mkf "$CONVD/${YDS}/req1.log"
mkf "$APPD/server_start.log"
mkf "$APPD/server_stop.log"
run
assert "生成主包"                       test -f "$MAIN"
assert "主包含 ALL 日志"                tar_has "$MAIN" "archive/IHUB_ALL.applog.${YD}.0.log"
assert "主包含 convert 日志"            tar_has "$MAIN" "convert/${YDS}/req1.log"
assert "主包含 server_start.log"        tar_has "$MAIN" "server_start.log"
assert "已归档源文件被删除"             test ! -f "$APPD/archive/IHUB_ALL.applog.${YD}.0.log"
assert "convert 空日期目录被删除"       test ! -d "$CONVD/${YDS}"
assert "今天的文件原样保留"             test -f "$APPD/archive/IHUB_ALL.applog.${TODAY}.0.log"
assert "server_start.log 被清空"        test -f "$APPD/server_start.log" -a ! -s "$APPD/server_start.log"
assert "流水账有归档记录"               grep -q "applog.${YDS}.tar.gz" "$LOGD/archive.log"
MAIN_MD5=$(md5sum "$MAIN" | awk '{print $1}')

# ============================================================
echo "case 2: 迟到文件 -> supp1 补充包（核心修复点，接 case 1 现场）"
# ============================================================
mkf "$APPD/archive/IHUB_WARN.applog.${YD}.0.log"        # 模拟懒滚动迟到的 WARN
run
SUPP1="$LOGD/${HOST}.${MODULE}.applog.${YDS}.supp1.tar.gz"
assert "生成 supp1 补充包"              test -f "$SUPP1"
assert "supp1 含迟到的 WARN"            tar_has "$SUPP1" "archive/IHUB_WARN.applog.${YD}.0.log"
assert "supp1 不含 server 日志(已空)"   tar_not_has "$SUPP1" "server_start.log"
assert "迟到源文件被删除"               test ! -f "$APPD/archive/IHUB_WARN.applog.${YD}.0.log"
assert "主包未被覆盖(md5 不变)"         test "$(md5sum "$MAIN" | awk '{print $1}')" = "$MAIN_MD5"

# ============================================================
echo "case 3: 再次迟到 -> supp2 序号递增（接 case 2 现场）"
# ============================================================
mkf "$APPD/archive/IHUB_ERROR.applog.${YD}.0.log"
run
SUPP2="$LOGD/${HOST}.${MODULE}.applog.${YDS}.supp2.tar.gz"
assert "生成 supp2"                     test -f "$SUPP2"
assert "supp2 含迟到的 ERROR"           tar_has "$SUPP2" "archive/IHUB_ERROR.applog.${YD}.0.log"

# ============================================================
echo "case 4: 无新文件重复执行 -> 不产生空包（接 case 3 现场）"
# ============================================================
run
assert "未产生 supp3"                   test ! -f "$LOGD/${HOST}.${MODULE}.applog.${YDS}.supp3.tar.gz"
assert "流水账记录 no log files"        grep -q "no log files to archive" "$LOGD/archive.log"

# ============================================================
echo "case 5: 多日期积压一次补齐 + 文件名变体 + 无日期文件不动"
# ============================================================
reset_env
mkf "$APPD/archive/IHUB_WARN.applog.2026-08-10.0.log"
mkf "$APPD/archive/IHUB_WARN.applog.2026-08-12.0.log"
mkf "$APPD/archive/IHUB_ERROR.applog.2026-08-12.0.log"
mkf "$APPD/archive/IHUB_ALL.2026-08-18.1.log"           # 变体：无 applog 段
mkf "$APPD/archive/nodateshere.log"                     # 无日期，不应被处理
run
T10="$LOGD/${HOST}.${MODULE}.applog.20260810.tar.gz"
T12="$LOGD/${HOST}.${MODULE}.applog.20260812.tar.gz"
assert "生成 20260810 包"               test -f "$T10"
assert "生成 20260812 包"               test -f "$T12"
assert "20260812 含 WARN"               tar_has "$T12" "IHUB_WARN.applog.2026-08-12.0.log"
assert "20260812 含 ERROR"              tar_has "$T12" "IHUB_ERROR.applog.2026-08-12.0.log"
assert "文件名变体也被归档"             tar_has "$MAIN" "archive/IHUB_ALL.2026-08-18.1.log"
assert "无日期文件原样保留"             test -f "$APPD/archive/nodateshere.log"

# ============================================================
echo "case 6: v3 遗留孤儿救援（tar 已存在 + 目录里有孤儿）"
# ============================================================
reset_env
mkdir -p "$TEST_ROOT/placeholder"; touch "$TEST_ROOT/placeholder/old.log"
tar -czf "$LOGD/${HOST}.${MODULE}.applog.20260812.tar.gz" -C "$TEST_ROOT/placeholder" old.log
mkf "$APPD/archive/IHUB_ERROR.applog.2026-08-12.0.log"  # v3 留下的孤儿
OLD12_MD5=$(md5sum "$LOGD/${HOST}.${MODULE}.applog.20260812.tar.gz" | awk '{print $1}')
run
S12="$LOGD/${HOST}.${MODULE}.applog.20260812.supp1.tar.gz"
assert "孤儿被收进 supp1"               tar_has "$S12" "IHUB_ERROR.applog.2026-08-12.0.log"
assert "孤儿源文件被删除"               test ! -f "$APPD/archive/IHUB_ERROR.applog.2026-08-12.0.log"
assert "已有主包未被改动"               test "$(md5sum "$LOGD/${HOST}.${MODULE}.applog.20260812.tar.gz" | awk '{print $1}')" = "$OLD12_MD5"

# ============================================================
echo "case 7: 0 字节文件不归档也不删除"
# ============================================================
reset_env
touch "$APPD/archive/IHUB_WARN.applog.${YD}.0.log"      # 空文件
mkf   "$APPD/archive/IHUB_INFO.applog.${YD}.0.log"
run
assert "包里只有非空的 INFO"            tar_has "$MAIN" "IHUB_INFO.applog.${YD}.0.log"
assert "包里没有空的 WARN"              tar_not_has "$MAIN" "IHUB_WARN.applog.${YD}.0.log"
assert "空文件仍留在磁盘"               test -f "$APPD/archive/IHUB_WARN.applog.${YD}.0.log"

# ============================================================
echo "case 8: convert 目录含非 .log 文件时不删目录"
# ============================================================
reset_env
mkdir -p "$CONVD/${YDS}"
mkf "$CONVD/${YDS}/req1.log"
echo keep > "$CONVD/${YDS}/keep.txt"
run
assert "req1.log 被归档删除"            test ! -f "$CONVD/${YDS}/req1.log"
assert "keep.txt 保留"                  test -f "$CONVD/${YDS}/keep.txt"
assert "非空目录不被删除"               test -d "$CONVD/${YDS}"

# ============================================================
echo "case 9: 只有 server 日志时单独成包"
# ============================================================
reset_env
mkf "$APPD/server_start.log"
run
assert "生成仅含 server 日志的主包"     tar_has "$MAIN" "server_start.log"
assert "server_start.log 被清空"        test -f "$APPD/server_start.log" -a ! -s "$APPD/server_start.log"

# ============================================================
echo "case 10: 并发锁 —— 已有实例持锁时直接跳过"
# ============================================================
reset_env
mkf "$APPD/archive/IHUB_INFO.applog.${YD}.0.log"
exec 9>"$TEST_ROOT/IHUB/archive_${MODULE}.lock"
flock -n 9
run
exec 9>&-   # 释放锁
assert "错误日志记录 another instance"  grep -q "another instance" "$LOGD/archive_error.log"
assert "持锁期间未生成归档包"           test ! -f "$MAIN"

# ============================================================
echo "case 11: 非法日期参数 -> 报错退出"
# ============================================================
reset_env
if bash "$SCRIPT" 2026-13-99 >/dev/null 2>&1; then
    bad "非法日期应以非零退出"
else
    ok "非法日期以非零退出"
fi

# ============================================================
echo ""
echo "================ 结果: PASS=$PASS FAIL=$FAIL ================"
echo "沙箱目录保留在 $TEST_ROOT（保存的是最后一个用例的现场），可手工检查"
[ "$FAIL" -eq 0 ]
