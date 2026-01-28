#!/bin/bash

#===============================================================================
# SQL 初始化脚本
# 用于在应用启动前执行数据库初始化 SQL
#===============================================================================

set -e  # 遇错退出

# ==================== 配置区 ====================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
JAR_PATH="/root/application.jar"
SQL_DIR="/root/sql"
ERROR_LOG_DIR="/root/sql"
PROFILE="dev"

# SQL 文件列表（按顺序执行）
SQL_FILES=(
    "create.sql"
    "create_table_base.sql"
    "create_table_business.sql"
    "Initialization.sql"
    "data_init.sql"
)

# ==================== 前置检查 ====================
echo "=========================================="
echo "  SQL 初始化脚本"
echo "=========================================="
echo ""

# 检查 Java
if ! command -v java &> /dev/null; then
    echo "[ERROR] Java 未安装或不在 PATH 中"
    exit 1
fi
echo "[OK] Java: $(java -version 2>&1 | head -1)"

# 检查 JAR 包
if [ ! -f "$JAR_PATH" ]; then
    echo "[ERROR] JAR 包不存在: $JAR_PATH"
    exit 1
fi
echo "[OK] JAR: $JAR_PATH"

# 检查 SQL 文件
MISSING_FILES=0
for sql_file in "${SQL_FILES[@]}"; do
    full_path="${SQL_DIR}/${sql_file}"
    if [ ! -f "$full_path" ]; then
        echo "[ERROR] SQL 文件不存在: $full_path"
        MISSING_FILES=1
    fi
done

if [ $MISSING_FILES -eq 1 ]; then
    echo ""
    echo "请检查 SQL 文件路径后重试"
    exit 1
fi
echo "[OK] SQL 文件检查通过 (${#SQL_FILES[@]} 个文件)"

# 确保错误日志目录存在
mkdir -p "$ERROR_LOG_DIR"

# ==================== 构建参数 ====================
# 拼接 SQL 文件路径（逗号分隔）
SQL_PATHS=""
for sql_file in "${SQL_FILES[@]}"; do
    if [ -n "$SQL_PATHS" ]; then
        SQL_PATHS="${SQL_PATHS},"
    fi
    SQL_PATHS="${SQL_PATHS}${SQL_DIR}/${sql_file}"
done

# ==================== 执行 ====================
echo ""
echo "开始执行..."
echo "Profile: $PROFILE"
echo "SQL 文件: ${#SQL_FILES[@]} 个"
echo ""

START_TIME=$(date +%s)

java -jar "$JAR_PATH" \
    --spring.profiles.active="$PROFILE" \
    --init-sql="$SQL_PATHS" \
    --no-transaction \
    --continue-on-error \
    --error-log="$ERROR_LOG_DIR"

EXIT_CODE=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# ==================== 结果处理 ====================
echo ""
echo "=========================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "  执行成功！耗时: ${DURATION}s"
else
    echo "  执行失败！退出码: $EXIT_CODE"
    echo "  请检查错误日志: $ERROR_LOG_DIR"
fi
echo "=========================================="

exit $EXIT_CODE
