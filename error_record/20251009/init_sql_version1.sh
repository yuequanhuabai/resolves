#!/bin/bash

#===============================================================================
# SQL 初始化脚本
# 用于在应用启动前执行数据库初始化 SQL
#
# 用法:
#   ./init_sql.sh -p <profile> -s <sql_files>
#
# 参数:
#   -p, --profile    环境配置 (必填): dev, sit, prd 等
#   -s, --sql        SQL文件路径 (必填): 多个文件用英文逗号分隔
#   -h, --help       显示帮助信息
#
# 示例:
#   ./init_sql.sh -p dev -s "/root/sql/create.sql"
#   ./init_sql.sh -p prd -s "/root/sql/a.sql,/root/sql/b.sql,/root/sql/c.sql"
#   ./init_sql.sh --profile=sit --sql="/opt/sql/init.sql,/opt/sql/data.sql"
#===============================================================================

set -e  # 遇错退出

# ==================== 固定配置区 ====================
# 应用的 JAR 包名
JAVA_APP_NAME="application.jar"

# 应用 JAR 包在 Linux 里面的目录
JAVA_APP_DIR="/opt/project/PAP/IHUB/back-end/"

# 执行初始化 SQL 时错误日志生成的目录
LOG_DIR="/opt/project/PAP/IHUB/back-end/init_sql_log/"

# ==================== 参数变量 ====================
PROFILE=""
SQL_FILES=""

# ==================== 函数定义 ====================

# 显示帮助信息
show_help() {
    echo "用法: $0 -p <profile> -s <sql_files>"
    echo ""
    echo "参数:"
    echo "  -p, --profile    环境配置 (必填): dev, sit, prd 等"
    echo "  -s, --sql        SQL文件路径 (必填): 多个文件用英文逗号分隔"
    echo "  -h, --help       显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -p dev -s \"/root/sql/create.sql\""
    echo "  $0 -p prd -s \"/root/sql/a.sql,/root/sql/b.sql\""
    echo "  $0 --profile=sit --sql=\"/opt/sql/init.sql,/opt/sql/data.sql\""
    exit 0
}

# 校验 SQL 文件路径格式（多个文件用英文逗号分隔）
validate_sql_paths() {
    local sql_paths="$1"

    # 检查是否为空
    if [ -z "$sql_paths" ]; then
        echo "[ERROR] SQL 文件路径不能为空"
        return 1
    fi

    # 检查是否包含中文逗号
    if [[ "$sql_paths" == *"，"* ]]; then
        echo "[ERROR] SQL 文件路径分隔符必须是英文逗号，检测到中文逗号"
        return 1
    fi

    # 检查是否有连续逗号
    if [[ "$sql_paths" == *",,"* ]]; then
        echo "[ERROR] SQL 文件路径格式错误: 存在连续逗号"
        return 1
    fi

    # 检查是否以逗号开头或结尾
    if [[ "$sql_paths" == ,* ]] || [[ "$sql_paths" == *, ]]; then
        echo "[ERROR] SQL 文件路径格式错误: 不能以逗号开头或结尾"
        return 1
    fi

    return 0
}

# 校验每个 SQL 文件是否存在
validate_sql_files_exist() {
    local sql_paths="$1"
    local missing=0

    # 按逗号分割并检查每个文件
    IFS=',' read -ra files <<< "$sql_paths"
    for file in "${files[@]}"; do
        # 去除首尾空格
        file=$(echo "$file" | xargs)
        if [ ! -f "$file" ]; then
            echo "[ERROR] SQL 文件不存在: $file"
            missing=1
        fi
    done

    return $missing
}

# ==================== 参数解析 ====================
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--profile)
            PROFILE="$2"
            shift 2
            ;;
        --profile=*)
            PROFILE="${1#*=}"
            shift
            ;;
        -s|--sql)
            SQL_FILES="$2"
            shift 2
            ;;
        --sql=*)
            SQL_FILES="${1#*=}"
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "[ERROR] 未知参数: $1"
            echo "使用 -h 或 --help 查看帮助"
            exit 1
            ;;
    esac
done

# ==================== 参数校验 ====================
echo "=========================================="
echo "  SQL 初始化脚本"
echo "=========================================="
echo ""

# 校验必填参数
if [ -z "$PROFILE" ]; then
    echo "[ERROR] 缺少必填参数: -p/--profile (环境配置)"
    echo "使用 -h 或 --help 查看帮助"
    exit 1
fi

if [ -z "$SQL_FILES" ]; then
    echo "[ERROR] 缺少必填参数: -s/--sql (SQL文件路径)"
    echo "使用 -h 或 --help 查看帮助"
    exit 1
fi

# 校验 profile 值
case $PROFILE in
    dev|sit|prd|uat|local)
        echo "[OK] Profile: $PROFILE"
        ;;
    *)
        echo "[WARN] Profile '$PROFILE' 不在常用列表 (dev/sit/prd/uat/local) 中，请确认是否正确"
        ;;
esac

# 校验 SQL 文件路径格式
if ! validate_sql_paths "$SQL_FILES"; then
    exit 1
fi
echo "[OK] SQL 路径格式校验通过"

# ==================== 前置检查 ====================

# 检查 Java
if ! command -v java &> /dev/null; then
    echo "[ERROR] Java 未安装或不在 PATH 中"
    exit 1
fi
echo "[OK] Java: $(java -version 2>&1 | head -1)"

# 构建 JAR 包完整路径
JAR_PATH="${JAVA_APP_DIR%/}/${JAVA_APP_NAME}"

# 检查 JAR 包
if [ ! -f "$JAR_PATH" ]; then
    echo "[ERROR] JAR 包不存在: $JAR_PATH"
    exit 1
fi
echo "[OK] JAR: $JAR_PATH"

# 校验 SQL 文件是否存在
if ! validate_sql_files_exist "$SQL_FILES"; then
    echo ""
    echo "请检查 SQL 文件路径后重试"
    exit 1
fi

# 统计 SQL 文件数量
IFS=',' read -ra sql_array <<< "$SQL_FILES"
SQL_COUNT=${#sql_array[@]}
echo "[OK] SQL 文件检查通过 (${SQL_COUNT} 个文件)"

# 确保错误日志目录存在
if [ ! -d "$LOG_DIR" ]; then
    echo "[INFO] 创建错误日志目录: $LOG_DIR"
    mkdir -p "$LOG_DIR"
fi
echo "[OK] 错误日志目录: $LOG_DIR"

# ==================== 执行 ====================
echo ""
echo "=========================================="
echo "  开始执行 SQL 初始化"
echo "=========================================="
echo "Profile:    $PROFILE"
echo "JAR:        $JAR_PATH"
echo "SQL 文件:   ${SQL_COUNT} 个"
echo "错误日志:   $LOG_DIR"
echo ""

# 列出要执行的 SQL 文件
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
    --error-log="$LOG_DIR"

EXIT_CODE=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# ==================== 结果处理 ====================
echo ""
echo "=========================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "  执行成功!"
    echo "  耗时: ${DURATION}s"
else
    echo "  执行失败!"
    echo "  退出码: $EXIT_CODE"
    echo "  请检查错误日志: $LOG_DIR"
fi
echo "=========================================="

exit $EXIT_CODE
