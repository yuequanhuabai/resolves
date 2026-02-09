#!/bin/bash
# ============================================================================
#  测试 05_rules.sh - 安全检测规则（7条）
#  依赖: 00_config.sh, 01_utils.sh
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/lib/00_config.sh"
source "$SCRIPT_DIR/lib/01_utils.sh"
source "$SCRIPT_DIR/lib/05_rules.sh"

PASS=0
FAIL=0

echo "========== 测试模块 05_rules =========="

# 测试1: scan_statement 函数是否存在
if declare -f scan_statement > /dev/null 2>&1; then
    echo "[PASS] scan_statement 函数已定义"
    ((PASS++))
else
    echo "[FAIL] scan_statement 函数未定义"
    ((FAIL++))
    echo "结果: ${PASS} 通过, ${FAIL} 失败"
    exit "$FAIL"
fi

# --- 辅助函数 ---
assert_finding() {
    local test_name="$1" expected_severity="$2" stmt="$3" next_stmt="${4:-}"
    > "$FINDINGS_FILE"
    scan_statement "$stmt" "test.sql" "1" "$next_stmt"
    if grep -q "^${expected_severity}|" "$FINDINGS_FILE"; then
        echo "[PASS] ${test_name}"
        ((PASS++))
    else
        echo "[FAIL] ${test_name} (期望 ${expected_severity}, 实际内容: $(cat "$FINDINGS_FILE"))"
        ((FAIL++))
    fi
}

assert_no_finding() {
    local test_name="$1" stmt="$2"
    > "$FINDINGS_FILE"
    scan_statement "$stmt" "test.sql" "1" ""
    local count
    count=$(wc -l < "$FINDINGS_FILE")
    if [ "$count" -eq 0 ]; then
        echo "[PASS] ${test_name}"
        ((PASS++))
    else
        echo "[FAIL] ${test_name} (不应有发现, 但得到: $(cat "$FINDINGS_FILE"))"
        ((FAIL++))
    fi
}

echo ""
echo "--- 正例测试 (应触发规则) ---"

# DDL-001: DROP DATABASE
assert_finding "DDL-001 DROP DATABASE" "CRITICAL" "DROP DATABASE mydb"

# DDL-002: DROP TABLE (无重建)
assert_finding "DDL-002 DROP TABLE" "CRITICAL" "DROP TABLE users"

# DDL-002: DROP TABLE + CREATE TABLE (重建模式 → INFO)
assert_finding "DDL-002 DROP+CREATE 重建" "INFO" \
    "DROP TABLE IF EXISTS USERS" \
    "CREATE TABLE USERS (id INT)"

# DDL-003: TRUNCATE TABLE
assert_finding "DDL-003 TRUNCATE TABLE" "CRITICAL" "TRUNCATE TABLE logs"

# DML-001: DELETE 无 WHERE
assert_finding "DML-001 DELETE 无WHERE" "CRITICAL" "DELETE FROM users"

# DML-002: UPDATE 无 WHERE
assert_finding "DML-002 UPDATE 无WHERE" "CRITICAL" "UPDATE users SET status = 0"

# DML-003: DELETE WHERE 1=1 (恒真)
assert_finding "DML-003 DELETE WHERE 1=1" "HIGH" "DELETE FROM users WHERE 1=1"

# DML-003: UPDATE WHERE 1=1 (恒真)
assert_finding "DML-003 UPDATE WHERE 1=1" "HIGH" "UPDATE users SET x=1 WHERE 1=1"

# SYS-014: sp_msforeachtable
assert_finding "SYS-014 sp_msforeachtable" "CRITICAL" \
    "EXEC sp_msforeachtable 'SELECT count(*) FROM ?'"

# SYS-014: sp_msforeachdb
assert_finding "SYS-014 sp_msforeachdb" "CRITICAL" \
    "EXEC sp_msforeachdb 'USE ? SELECT name FROM sys.tables'"

echo ""
echo "--- 反例测试 (不应触发规则) ---"

# 安全的 DELETE (有 WHERE)
assert_no_finding "安全 DELETE (有WHERE)" "DELETE FROM users WHERE id = 1"

# 安全的 UPDATE (有 WHERE)
assert_no_finding "安全 UPDATE (有WHERE)" "UPDATE users SET name = 'test' WHERE id = 1"

# ON DELETE CASCADE (不是 DML)
assert_no_finding "ON DELETE CASCADE (DDL)" \
    "ALTER TABLE orders ADD CONSTRAINT fk_user FOREIGN KEY (uid) REFERENCES users(id) ON DELETE CASCADE"

# ON UPDATE CASCADE (不是 DML)
assert_no_finding "ON UPDATE CASCADE (DDL)" \
    "ALTER TABLE orders ADD CONSTRAINT fk_user FOREIGN KEY (uid) REFERENCES users(id) ON UPDATE CASCADE"

# UPDATE STATISTICS (不是 DML)
assert_no_finding "UPDATE STATISTICS" "UPDATE STATISTICS users"

# 普通 SELECT
assert_no_finding "普通 SELECT" "SELECT * FROM users WHERE id = 1"

# CREATE TABLE
assert_no_finding "普通 CREATE TABLE" "CREATE TABLE new_table (id INT PRIMARY KEY, name VARCHAR(50))"

echo ""
echo "结果: ${PASS} 通过, ${FAIL} 失败"
[ "$FAIL" -eq 0 ] && echo ">> 模块 05_rules 测试全部通过!" || echo ">> 模块 05_rules 存在失败项!"
exit "$FAIL"
