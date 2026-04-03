#!/bin/bash

#===============================================================================
# SQL 初始化脚本
#
# 用法:
#   ./init_sql.sh --profile=dev --sql="/opt/sql/a.sql,/opt/sql/b.sql"
#   ./init_sql.sh --profile=dev --sql="/opt/sql/a.sql" --error-log="/opt/logs/"
#===============================================================================

# ==================== 固定配置 ====================
# 应用的 JAR 包名
JAVA_APP_NAME="application.jar"

# 应用 JAR 包在 Linux 里面的目录
JAVA_APP_DIR="/opt/project/PAP/IHUB/back-end/"

# ==================== 参数变量 ====================
PROFILE=""
SQL_FILES=""
ERROR_LOG_DIR=""

# ==================== 解析参数 ====================
for arg in "$@"; do
    case $arg in
        --profile=*)
            PROFILE="${arg#*=}"
            ;;
        --sql=*)
            SQL_FILES="${arg#*=}"
            ;;
        --error-log=*)
            ERROR_LOG_DIR="${arg#*=}"
            ;;
    esac
done

# ==================== 开始 ====================
echo "=========================================="
echo "  SQL 初始化脚本"
echo "=========================================="
echo ""

# ==================== 校验参数 ====================
# 校验 profile
if [ -z "$PROFILE" ]; then
    echo "[ERROR] 缺少参数: --profile"
    echo "用法: $0 --profile=dev --sql=\"/opt/sql/a.sql,/opt/sql/b.sql\""
    exit 1
fi
echo "[OK] Profile: $PROFILE"

# 校验 sql
if [ -z "$SQL_FILES" ]; then
    echo "[ERROR] 缺少参数: --sql"
    echo "用法: $0 --profile=dev --sql=\"/opt/sql/a.sql,/opt/sql/b.sql\""
    exit 1
fi

# 校验 SQL 路径格式
if [[ "$SQL_FILES" == *"，"* ]]; then
    echo "[ERROR] SQL 文件分隔符必须是英文逗号，检测到中文逗号"
    exit 1
fi

if [[ "$SQL_FILES" == *",,"* ]]; then
    echo "[ERROR] SQL 文件路径格式错误: 存在连续逗号"
    exit 1
fi

if [[ "$SQL_FILES" == ,* ]] || [[ "$SQL_FILES" == *, ]]; then
    echo "[ERROR] SQL 文件路径格式错误: 不能以逗号开头或结尾"
    exit 1
fi
echo "[OK] SQL 路径格式校验通过"

# 错误日志目录，没传则用脚本所在目录
if [ -z "$ERROR_LOG_DIR" ]; then
    ERROR_LOG_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# ==================== 前置检查 ====================
# 检查 Java
if ! command -v java &> /dev/null; then
    echo "[ERROR] Java 未安装或不在 PATH 中"
    exit 1
fi
echo "[OK] Java: $(java -version 2>&1 | head -1)"

# JAR 包完整路径
JAR_PATH="${JAVA_APP_DIR%/}/${JAVA_APP_NAME}"

# 检查 JAR 包
if [ ! -f "$JAR_PATH" ]; then
    echo "[ERROR] JAR 包不存在: $JAR_PATH"
    exit 1
fi
echo "[OK] JAR: $JAR_PATH"

# 检查每个 SQL 文件是否存在
IFS=',' read -ra sql_array <<< "$SQL_FILES"
for file in "${sql_array[@]}"; do
    file=$(echo "$file" | xargs)
    if [ ! -f "$file" ]; then
        echo "[ERROR] SQL 文件不存在: $file"
        exit 1
    fi
done
echo "[OK] SQL 文件检查通过 (${#sql_array[@]} 个文件)"

# 创建错误日志目录
if [ ! -d "$ERROR_LOG_DIR" ]; then
    echo "[INFO] 创建错误日志目录: $ERROR_LOG_DIR"
    mkdir -p "$ERROR_LOG_DIR"
fi
echo "[OK] 错误日志目录: $ERROR_LOG_DIR"

# ==================== 执行 ====================
echo ""
echo "=========================================="
echo "  开始执行"
echo "=========================================="
echo "SQL 文件列表:"
index=1
for file in "${sql_array[@]}"; do
    file=$(echo "$file" | xargs)
    echo "  ${index}. ${file}"
    ((index++))
done
echo ""

START_TIME=$(date +%s)

java -jar "$JAR_PATH" \
    --spring.profiles.active="$PROFILE" \
    --init-sql="$SQL_FILES" \
    --no-transaction \
    --continue-on-error \
    --error-log="$ERROR_LOG_DIR"

EXIT_CODE=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# ==================== 结果 ====================
echo ""
echo "=========================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "  执行成功! 耗时: ${DURATION}s"
else
    echo "  执行失败! 退出码: $EXIT_CODE"
    echo "  错误日志: $ERROR_LOG_DIR"
fi
echo "=========================================="

exit $EXIT_CODE
