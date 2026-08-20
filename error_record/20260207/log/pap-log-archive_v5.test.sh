#!/bin/bash
# ============================================================================
# pap-log-archive_v5.sh 测试套件
#
# 用法：
#   ./pap-log-archive_v5.test.sh            # 跑全部用例
#   ./pap-log-archive_v5.test.sh TC-03      # 只跑指定用例
#
# 每个用例使用独立沙箱目录，互不影响。
# 被测脚本的四个硬编码路径会被 sed 重定向到沙箱；
# flock 在 Git Bash 下不存在，测试时打桩为 true（真机 Linux 无需）。
# ============================================================================

SUT="${SUT:-$(cd "$(dirname "$0")" && pwd)/pap-log-archive_v5.sh}"
BASE="${BASE:-${TMPDIR:-/tmp}/v5test.$$}"
ONLY="${1:-}"

PASS=0; FAIL=0; SKIP=0
FAILED_CASES=""

# ---------- 断言 ----------
ok()   { PASS=$((PASS+1)); printf '    \033[32m✓\033[0m %s\n' "$1"; }
ng()   { FAIL=$((FAIL+1)); printf '    \033[31m✗\033[0m %s\n' "$1"
         printf '        期望: %s\n        实际: %s\n' "$2" "$3"; }
assert_eq()      { [ "$2" = "$3" ] && ok "$1" || ng "$1" "$2" "$3"; }
assert_file()    { [ -f "$2" ] && ok "$1" || ng "$1" "存在 $2" "不存在"; }
assert_nofile()  { [ ! -f "$2" ] && ok "$1" || ng "$1" "不存在 $2" "存在"; }
assert_match()   { echo "$2" | grep -qE "$3" && ok "$1" || ng "$1" "匹配 /$3/" "$2"; }
assert_nomatch() { echo "$2" | grep -qE "$3" && ng "$1" "不匹配 /$3/" "$2" || ok "$1"; }

# ---------- 沙箱 ----------
# $1 = 用例 ID。生成 T（沙箱根）、A（archive 目录）、D（归档产出目录）、SH（被测副本）
setup() {
  T="$BASE/$1"; A="$T/applog/archive"; D="$T/dest"; SH="$T/run.sh"
  rm -rf "$T"; mkdir -p "$A" "$T/applogs/convert" "$D"
  sed -e "s#^LOG_DIR=.*#LOG_DIR=\"$T/applog\"#" \
      -e "s#^CONVERT_LOG_DIR=.*#CONVERT_LOG_DIR=\"$T/applogs/convert\"#" \
      -e "s#^ARCHIVE_DIR=.*#ARCHIVE_DIR=\"$D\"#" \
      -e "s#^LOCK_FILE=.*#LOCK_FILE=\"$T/archive.lock\"#" \
      "$SUT" > "$SH"
  command -v flock >/dev/null 2>&1 || sed -i "s#^flock -n 200 .*#true#" "$SH"
  chmod +x "$SH"
}

# 造一个大小为 $2 字节的可压缩日志文件 $1
mklog() {
  yes "2026-08-10 09:15:22.331|ERROR|http-nio-9600-exec-7|c.b.p.s.b.BuyListServiceImpl|query|188|java.net.SocketTimeoutException: Read timed out" \
    | head -c "$2" > "$1"
}
# 造一个大小为 $2 字节的不可压缩文件（随机数据）$1
mkrand() { head -c "$2" /dev/urandom > "$1"; }

# 运行被测脚本，捕获退出码到 RC、stdout+stderr 到 OUT
run() { OUT=$("$SH" "$@" 2>&1); RC=$?; }

# 列出产出的包名（仅 basename，按名排序）
pkgs() { ls "$D"/*.tar.gz 2>/dev/null | xargs -n1 basename 2>/dev/null | sort | tr '\n' ' '; }
# 产出包个数
npkg() { ls "$D"/*.tar.gz 2>/dev/null | wc -l | tr -d ' '; }
# 沙箱里所有隐藏的临时文件
tmps() { ls -a "$D" 2>/dev/null | grep -c '\.tmp\.' | tr -d ' '; }

hdr() {
  [ -n "$ONLY" ] && [ "$ONLY" != "$1" ] && return 1
  printf '\n\033[1m[%s] %s\033[0m\n' "$1" "$2"; return 0
}

H=$(hostname)
P="$H.IHUB-PAP.applog"          # 包名前缀

# ============================================================================
# TC-01  空目录：无任何日志文件
#        边界：DATES_TO_ARCHIVE 为空数组
# ============================================================================
if hdr TC-01 "空目录 — 不产生任何包，正常退出"; then
  setup TC-01
  run 2026-08-12
  assert_eq "退出码为 0"            "0" "$RC"
  assert_eq "产出包数为 0"          "0" "$(npkg)"
  assert_match "archive.log 记录 skip" "$(cat "$D/archive.log" 2>/dev/null)" "no log files to archive"
fi

# ============================================================================
# TC-02  日期上界：今天 / 未来 的文件不得被归档
#        边界：d <= YESTERDAY 的比较
# ============================================================================
if hdr TC-02 "日期上界 — 昨天归档，今天和未来不归档"; then
  setup TC-02
  mklog "$A/IHUB_ALL.2026-08-11.0.log" 200000   # 昨天  → 应归档
  mklog "$A/IHUB_ALL.2026-08-12.0.log" 200000   # 今天  → 不应归档
  mklog "$A/IHUB_ALL.2026-08-13.0.log" 200000   # 未来  → 不应归档
  run 2026-08-12
  assert_eq "退出码为 0"                "0" "$RC"
  assert_eq "只产出 1 个包"             "1" "$(npkg)"
  assert_file "昨天的包已生成"          "$D/$P.20260811.tar.gz"
  assert_nofile "今天的包未生成"        "$D/$P.20260812.tar.gz"
  assert_nofile "未来的包未生成"        "$D/$P.20260813.tar.gz"
  assert_file "今天的源文件保留"        "$A/IHUB_ALL.2026-08-12.0.log"
  assert_file "未来的源文件保留"        "$A/IHUB_ALL.2026-08-13.0.log"
fi

# ============================================================================
# TC-03  0 字节文件：-size +0c 的边界
#        边界：0 字节不打包也不删除；1 字节要打包
# ============================================================================
if hdr TC-03 "0 字节边界 — 0 字节跳过且保留，1 字节正常归档"; then
  setup TC-03
  : > "$A/IHUB_ALL.2026-08-11.0.log"                     # 0 字节
  printf 'x' > "$A/IHUB_ALL.2026-08-11.1.log"            # 1 字节
  run 2026-08-12
  assert_eq "退出码为 0"            "0" "$RC"
  assert_file "0 字节文件被保留"    "$A/IHUB_ALL.2026-08-11.0.log"
  assert_nofile "1 字节文件被删除"  "$A/IHUB_ALL.2026-08-11.1.log"
  assert_match "包内只有 1 字节那个" "$(tar -tzf "$D/$P.20260811.tar.gz")" "IHUB_ALL\.2026-08-11\.1\.log"
  assert_nomatch "包内没有 0 字节那个" "$(tar -tzf "$D/$P.20260811.tar.gz")" "IHUB_ALL\.2026-08-11\.0\.log"
fi

# ============================================================================
# TC-04  多日期补归档：模拟脚本停跑数天
#        边界：按日期拆包、从早到晚排序
# ============================================================================
if hdr TC-04 "停跑补归档 — 5 个日期各自独立成包"; then
  setup TC-04
  for d in 06 07 08 09 10; do mklog "$A/IHUB_ALL.2026-08-$d.0.log" 300000; done
  run 2026-08-11
  assert_eq "退出码为 0"      "0" "$RC"
  assert_eq "产出 5 个包"     "5" "$(npkg)"
  for d in 06 07 08 09 10; do assert_file "202608$d 包存在" "$D/$P.202608$d.tar.gz"; done
  assert_eq "archive.log 有 5 条" "5" "$(grep -c archived "$D/archive.log")"
  assert_match "处理顺序从早到晚" "$(grep archived "$D/archive.log" | grep -o '2026080[6-9]\|20260810' | tr '\n' ' ')" \
               "20260806 20260807 20260808 20260809 20260810"
fi

# ============================================================================
# TC-05  跨月 / 跨年边界
# ============================================================================
if hdr TC-05 "跨月跨年 — 日期换算与包名正确"; then
  setup TC-05
  mklog "$A/IHUB_ALL.2025-12-31.0.log" 100000
  mklog "$A/IHUB_ALL.2026-01-01.0.log" 100000
  run 2026-01-02
  assert_file "跨年前一天成包" "$D/$P.20251231.tar.gz"
  assert_file "元旦当天成包"   "$D/$P.20260101.tar.gz"
fi

# ============================================================================
# TC-06  幂等与补充包：主包 → supp1 → supp2
#        边界：迟到文件不覆盖已有归档
# ============================================================================
if hdr TC-06 "补充包 — 迟到文件进 suppN，主包不被覆盖"; then
  setup TC-06
  mklog "$A/IHUB_ALL.2026-08-11.0.log" 200000
  run 2026-08-12
  M1=$(md5sum "$D/$P.20260811.tar.gz" | cut -d' ' -f1)
  assert_eq "第一次：1 个主包" "1" "$(npkg)"

  mklog "$A/IHUB_ALL.2026-08-11.1.log" 200000     # 迟到文件
  run 2026-08-12
  assert_file "supp1 生成"       "$D/$P.20260811.supp1.tar.gz"
  assert_eq   "主包未被改动"     "$M1" "$(md5sum "$D/$P.20260811.tar.gz" | cut -d' ' -f1)"
  assert_match "supp1 内是迟到文件" "$(tar -tzf "$D/$P.20260811.supp1.tar.gz")" "IHUB_ALL\.2026-08-11\.1\.log"

  mklog "$A/IHUB_ALL.2026-08-11.2.log" 200000     # 再迟到一个
  run 2026-08-12
  assert_file "supp2 生成"       "$D/$P.20260811.supp2.tar.gz"
  assert_eq   "共 3 个包"        "3" "$(npkg)"
fi

# ============================================================================
# TC-07  空跑幂等：主包已存在且无新文件，不得产生垃圾包
#        边界：这是 v4/v5 相对 v3 最危险的回归点
# ============================================================================
if hdr TC-07 "空跑幂等 — 无新文件时不产生 suppN 垃圾包"; then
  setup TC-07
  mklog "$A/IHUB_ALL.2026-08-11.0.log" 200000
  run 2026-08-12; N1=$(npkg)
  run 2026-08-12; N2=$(npkg)
  run 2026-08-12; N3=$(npkg)
  assert_eq "第 1 次后包数" "1" "$N1"
  assert_eq "第 2 次后包数不变" "1" "$N2"
  assert_eq "第 3 次后包数不变" "1" "$N3"
  assert_nofile "未生成 supp1" "$D/$P.20260811.supp1.tar.gz"
fi

# ============================================================================
# TC-08  supp 序号进位到两位数
#        边界：while 循环找空位，supp9 → supp10
# ============================================================================
if hdr TC-08 "supp 序号进位 — supp1..supp9 存在时取 supp10"; then
  setup TC-08
  : > "$D/$P.20260811.tar.gz"
  for n in 1 2 3 4 5 6 7 8 9; do : > "$D/$P.20260811.supp$n.tar.gz"; done
  mklog "$A/IHUB_ALL.2026-08-11.0.log" 200000
  run 2026-08-12
  assert_eq   "退出码为 0"   "0" "$RC"
  assert_file "生成 supp10"  "$D/$P.20260811.supp10.tar.gz"
fi

# ============================================================================
# TC-09  压缩比修正：高可压缩数据，门槛应远低于未压缩体积
#        这是本次 v5 的核心改动
# ============================================================================
if hdr TC-09 "压缩比修正 — est_need 远小于 raw（v4 会等于 raw）"; then
  setup TC-09
  for i in 0 1 2 3 4; do mklog "$A/IHUB_ALL.2026-08-11.$i.log" 10000000; done   # 约 48MB
  run 2026-08-12
  LINE=$(grep archived "$D/archive.log")
  RAW=$(echo "$LINE"  | grep -oP 'raw: \K[0-9]+')
  NEED=$(echo "$LINE" | grep -oP 'est_need: \K[0-9]+')
  OUTK=$(echo "$LINE" | grep -oP 'out: \K[0-9]+')
  printf '        raw=%sKB  est_need=%sKB  实际输出=%sKB\n' "$RAW" "$NEED" "$OUTK"
  [ "$NEED" -lt "$RAW" ] && ok "门槛 est_need < raw（修正生效）" \
                         || ng "门槛 est_need < raw" "need<$RAW" "need=$NEED"
  [ "$NEED" -gt "$OUTK" ] && ok "门槛 est_need > 实际输出（余量足够）" \
                          || ng "门槛 > 实际输出" ">$OUTK" "$NEED"
  assert_match "压缩比记入日志" "$LINE" "ratio: [0-9]+\.[0-9]+:1"
fi

# ============================================================================
# TC-10  压缩比下限：不可压缩数据，ratio 应被钳到 1.0:1
#        边界：RATIO_MIN=100
# ============================================================================
if hdr TC-10 "压缩比下限 — 随机数据 ratio 钳到 1.0:1，门槛不低于实际"; then
  setup TC-10
  mkrand "$A/IHUB_ALL.2026-08-11.0.log" 3000000
  run 2026-08-12
  LINE=$(grep archived "$D/archive.log")
  printf '        %s\n' "$(echo "$LINE" | grep -oP 'raw:.*')"
  assert_match "ratio 为 1.0:1" "$LINE" "ratio: 1\.0:1"
  RAW=$(echo "$LINE" | grep -oP 'raw: \K[0-9]+'); NEED=$(echo "$LINE" | grep -oP 'est_need: \K[0-9]+')
  [ "$NEED" -ge "$RAW" ] && ok "门槛封顶为 raw+floor，不低于实际需要" \
                         || ng "门槛 >= raw" ">=$RAW" "$NEED"
fi

# ============================================================================
# TC-11  压缩比取样下限：样本 < 64KB 时用兜底值 3.0:1
#        边界：sample_ratio 里的 raw < 65536 分支
# ============================================================================
if hdr TC-11 "取样样本过小 — 回落到兜底压缩比 3.0:1"; then
  setup TC-11
  mklog "$A/IHUB_ALL.2026-08-11.0.log" 30000     # < 64KB
  run 2026-08-12
  assert_match "ratio 为兜底 3.0:1" "$(grep archived "$D/archive.log")" "ratio: 3\.0:1"
fi

# ============================================================================
# TC-12  磁盘空间不足：exit 1 且不留残骸
#        边界：原子写入的核心保障
# ============================================================================
if hdr TC-12 "空间不足 — exit 1，无 tmp 残留，无半包，源文件保留"; then
  setup TC-12
  sed -i 's#^SPACE_FLOOR_KB=.*#SPACE_FLOOR_KB=999999999#' "$SH"
  mklog "$A/IHUB_ALL.2026-08-11.0.log" 3000000
  run 2026-08-12
  assert_eq   "退出码为 1"        "1" "$RC"
  assert_eq   "无 .tmp. 残留"     "0" "$(tmps)"
  assert_eq   "无 tar.gz 产出"    "0" "$(npkg)"
  assert_file "源文件保留"        "$A/IHUB_ALL.2026-08-11.0.log"
  assert_match "错误信息含四要素" "$(cat "$D/archive_error.log")" \
               "insufficient disk space.*raw .*ratio .*need .*available"
fi

# ============================================================================
# TC-13  tar 失败：原子写入回滚
#        边界：注入一个必然失败的 tar，验证不留半包
# ============================================================================
if hdr TC-13 "tar 失败 — 回滚清理 tmp，退出码 1"; then
  setup TC-13
  mkdir -p "$T/fakebin"
  printf '#!/bin/bash\n# 造出半个文件再失败，模拟写到一半 ENOSPC\nfor a in "$@"; do case "$a" in *.tmp.*) head -c 4096 /dev/urandom > "$a";; esac; done\nexit 2\n' > "$T/fakebin/tar"
  chmod +x "$T/fakebin/tar"
  sed -i "2i export PATH=\"$T/fakebin:\$PATH\"" "$SH"
  mklog "$A/IHUB_ALL.2026-08-11.0.log" 200000
  run 2026-08-12
  assert_eq   "退出码为 1"      "1" "$RC"
  assert_eq   "无 .tmp. 残留"   "0" "$(tmps)"
  assert_eq   "无 tar.gz 产出"  "0" "$(npkg)"
  assert_file "源文件保留（未误删）" "$A/IHUB_ALL.2026-08-11.0.log"
  assert_match "错误信息正确"   "$(cat "$D/archive_error.log")" "failed to create tar archive"
fi

# ============================================================================
# TC-14  gzip -t 校验失败：产出损坏包时也要回滚
#        边界：tar 返回 0 但产物损坏
# ============================================================================
if hdr TC-14 "完整性校验 — tar 成功但产物损坏时回滚"; then
  setup TC-14
  mkdir -p "$T/fakebin"
  printf '#!/bin/bash\nfor a in "$@"; do case "$a" in *.tmp.*) printf "NOT-A-GZIP-FILE" > "$a";; esac; done\nexit 0\n' > "$T/fakebin/tar"
  chmod +x "$T/fakebin/tar"
  sed -i "2i export PATH=\"$T/fakebin:\$PATH\"" "$SH"
  mklog "$A/IHUB_ALL.2026-08-11.0.log" 200000
  run 2026-08-12
  assert_eq   "退出码为 1"     "1" "$RC"
  assert_eq   "无 .tmp. 残留"  "0" "$(tmps)"
  assert_eq   "损坏包未落地"   "0" "$(npkg)"
  assert_match "错误信息指明校验失败" "$(cat "$D/archive_error.log")" "failed integrity check"
fi

# ============================================================================
# TC-15  残留 tmp 清理：> 1 天清理，< 1 天保留
#        边界：find -mtime +1
# ============================================================================
if hdr TC-15 "tmp 清理 — 超 1 天的清掉，新的保留"; then
  setup TC-15
  OLD="$D/.$P.20260101.tar.gz.tmp.999"; NEW="$D/.$P.20260102.tar.gz.tmp.998"
  : > "$OLD"; : > "$NEW"
  touch -d "3 days ago" "$OLD"
  run 2026-08-12
  assert_nofile "3 天前的 tmp 被清理" "$OLD"
  assert_file   "刚生成的 tmp 被保留" "$NEW"
fi

# ============================================================================
# TC-16  server 日志：非空进昨天包并清空；空则不进包
#        边界：-s 判断 + 只归到 YESTERDAY
# ============================================================================
if hdr TC-16 "server 日志 — 非空进昨天包并清空，空的不进包"; then
  setup TC-16
  echo "started" > "$T/applog/server_start.log"
  : >            "$T/applog/server_stop.log"      # 空
  mklog "$A/IHUB_ALL.2026-08-10.0.log" 100000     # 前天
  mklog "$A/IHUB_ALL.2026-08-11.0.log" 100000     # 昨天
  run 2026-08-12
  Y=$(tar -tzf "$D/$P.20260811.tar.gz"); B=$(tar -tzf "$D/$P.20260810.tar.gz")
  assert_match   "server_start 进了昨天的包"   "$Y" "server_start\.log"
  assert_nomatch "server_stop（空）未进包"     "$Y" "server_stop\.log"
  assert_nomatch "server_start 未进前天的包"   "$B" "server_start\.log"
  assert_eq "server_start.log 已清空" "0" "$(stat -c%s "$T/applog/server_start.log")"
fi

# ============================================================================
# TC-17  convert 目录：打包后清空并 rmdir；非 .log 文件保留且目录不删
# ============================================================================
if hdr TC-17 "convert 目录 — 全 .log 则删目录，有杂项则保留"; then
  setup TC-17
  mkdir -p "$T/applogs/convert/20260810" "$T/applogs/convert/20260811" "$T/applogs/convert/notadate"
  mklog "$T/applogs/convert/20260810/req-1.log" 50000
  mklog "$T/applogs/convert/20260811/req-1.log" 50000
  echo "x" > "$T/applogs/convert/20260811/manifest.json"      # 非 .log
  run 2026-08-12
  assert_eq "20260810 目录已删除"        "" "$(ls -d "$T/applogs/convert/20260810" 2>/dev/null)"
  assert_eq "20260811 目录保留（有杂项）" "$T/applogs/convert/20260811" "$(ls -d "$T/applogs/convert/20260811" 2>/dev/null)"
  assert_file "非 .log 文件未被删"        "$T/applogs/convert/20260811/manifest.json"
  assert_eq "非日期目录未被处理"          "$T/applogs/convert/notadate" "$(ls -d "$T/applogs/convert/notadate" 2>/dev/null)"
  assert_match "包内 convert 路径正确"    "$(tar -tzf "$D/$P.20260810.tar.gz")" "convert/20260810/req-1\.log"
fi

# ============================================================================
# TC-18  只有 convert 没有 archive：取样源回退到 convert 文件
#        边界：sample_ratio 的 elif 分支
# ============================================================================
if hdr TC-18 "取样源回退 — 只有 convert 文件时仍能实测压缩比"; then
  setup TC-18
  mkdir -p "$T/applogs/convert/20260811"
  mklog "$T/applogs/convert/20260811/req-1.log" 2000000
  run 2026-08-12
  assert_eq "退出码为 0" "0" "$RC"
  assert_file "包已生成" "$D/$P.20260811.tar.gz"
  assert_nomatch "ratio 不是兜底值（说明取样成功）" "$(grep archived "$D/archive.log")" "ratio: 3\.0:1"
fi

# ============================================================================
# TC-19  非法日期参数
# ============================================================================
if hdr TC-19 "参数校验 — 非法日期立即退出，不做任何事"; then
  setup TC-19
  mklog "$A/IHUB_ALL.2026-08-11.0.log" 100000
  run "2026-13-45"
  assert_eq "退出码为 1"    "1" "$RC"
  assert_match "提示非法日期" "$OUT" "invalid date"
  assert_eq "未产出任何包"  "0" "$(npkg)"
  assert_file "源文件未动"  "$A/IHUB_ALL.2026-08-11.0.log"
fi

# ============================================================================
# TC-20  文件名不匹配收集模式：日期能被识别但文件收不到
#        已知缺陷验证（v3/v4/v5 共有），预期为"空转、不产包、文件滞留"
# ============================================================================
if hdr TC-20 "已知缺陷 — 日期前非点分隔的文件名会空转"; then
  setup TC-20
  mklog "$A/app-2026-08-11.log" 100000     # 识别得到日期，但 *.DATE.*.log 匹配不上
  run 2026-08-12
  assert_eq "退出码为 0（静默空转）" "0" "$RC"
  assert_eq "未产出任何包"           "0" "$(npkg)"
  assert_file "文件滞留在 archive/"  "$A/app-2026-08-11.log"
  printf '        \033[33m注：这是 v3/v4/v5 共有的已知缺陷，本用例锁定当前行为\033[0m\n'
fi

# ============================================================================
# TC-21  并发锁：第二个实例应直接跳过
#        仅在有真实 flock 的环境（Linux）执行
# ============================================================================
if hdr TC-21 "并发锁 — 锁被占用时跳过且退出码 0"; then
  if ! command -v flock >/dev/null 2>&1; then
    SKIP=$((SKIP+1)); printf '    \033[33m－ 跳过：当前环境无 flock（Git Bash），请在 Linux 上执行\033[0m\n'
  else
    setup TC-21
    mklog "$A/IHUB_ALL.2026-08-11.0.log" 100000
    ( flock -n 200 || exit 1; sleep 5 ) 200>"$T/archive.lock" &
    HOLDER=$!; sleep 1
    run 2026-08-12
    assert_eq "退出码为 0"   "0" "$RC"
    assert_eq "未产出任何包" "0" "$(npkg)"
    assert_match "记录了跳过原因" "$(cat "$D/archive_error.log")" "another instance is running"
    wait $HOLDER 2>/dev/null
  fi
fi

# ============================================================================
# TC-22  归档目录不可写
#        边界：权限校验分支（root 下 chmod 无效，故 root 时跳过）
# ============================================================================
if hdr TC-22 "权限 — 归档目录不可写时报错退出"; then
  if [ "$(id -u)" = "0" ] || [ "$(uname -o 2>/dev/null)" = "Msys" ]; then
    SKIP=$((SKIP+1)); printf '    \033[33m－ 跳过：root 或 Windows 下 chmod 不生效，请在 Linux 普通用户下执行\033[0m\n'
  else
    setup TC-22
    mklog "$A/IHUB_ALL.2026-08-11.0.log" 100000
    chmod 500 "$D"
    run 2026-08-12
    assert_eq "退出码为 1" "1" "$RC"
    chmod 700 "$D"
  fi
fi

# ============================================================================
# 汇总
# ============================================================================
printf '\n\033[1m════════════════════════════════════════\033[0m\n'
printf '  通过 \033[32m%d\033[0m   失败 \033[31m%d\033[0m   跳过 \033[33m%d\033[0m\n' "$PASS" "$FAIL" "$SKIP"
printf '  沙箱：%s\n' "$BASE"
printf '\033[1m════════════════════════════════════════\033[0m\n'
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
