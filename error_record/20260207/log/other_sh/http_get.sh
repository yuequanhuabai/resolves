#!/bin/bash

# 请求参数配置
IP="10.41.242.159"
HOSTNAME=$(/bin/hostname)
PORT="8080"
PATTERN="/admin-api/buyList/insert-tsl"


# 拼接完整URL
URL="http://${HOSTNAME}:${PORT}/${PATTERN}"

# 响应日志目录
BASE_LOG_DIR="/opt/project/PAP/IHUB/other_log/per_day_request_log"
if [ ! -d "${BASE_LOG_DIR}" ]; then
    mkdir -p "${BASE_LOG_DIR}"
fi

# 按日期创建子目录
LOG_DIR="${BASE_LOG_DIR}/$(date '+%Y%m%d')"
if [ ! -d "${LOG_DIR}" ]; then
    mkdir -p "${LOG_DIR}"
fi
LOG_FILE="${LOG_DIR}/response_$(date '+%Y%m%d_%H%M%S').log"

# 最大重试次数
MAX_RETRIES=2
attempt=0
success=false

echo "请求URL: ${URL}" >> "${LOG_FILE}"
echo "请求时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "${LOG_FILE}"
echo "========================================" >> "${LOG_FILE}"

while [ $attempt -le $MAX_RETRIES ]; do
    attempt=$((attempt + 1))
    echo "第 ${attempt} 次请求: ${URL}"

    TEMP_FILE=$(mktemp)
    HTTP_CODE=$(curl -s -o "${TEMP_FILE}" -w "%{http_code}" -H "Content-Type: application/json" -X GET "${URL}")
    RESPONSE_BODY=$(cat "${TEMP_FILE}")

    # 提取业务码
    BIZ_CODE=$(echo "${RESPONSE_BODY}" | grep -o '"code":[0-9]*' | head -n 1 | grep -o '[0-9]*')

    # 写入日志文件
    echo "" >> "${LOG_FILE}"
    echo "--- 第 ${attempt} 次请求 ---" >> "${LOG_FILE}"
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "${LOG_FILE}"
    echo "HTTP状态码: ${HTTP_CODE}" >> "${LOG_FILE}"
    echo "业务码: ${BIZ_CODE}" >> "${LOG_FILE}"
    echo "响应体:" >> "${LOG_FILE}"
    echo "${RESPONSE_BODY}" >> "${LOG_FILE}"
    rm -f "${TEMP_FILE}"

    if [ "$HTTP_CODE" -eq 200 ] && [ "$BIZ_CODE" -eq 0 ]; then
        echo "请求成功, HTTP状态码: ${HTTP_CODE}, 业务码: ${BIZ_CODE}"
        success=true
        break
    else
        echo "请求失败, HTTP状态码: ${HTTP_CODE}, 业务码: ${BIZ_CODE}"
        if [ $attempt -lt $((MAX_RETRIES + 1)) ]; then
            echo "等待1秒后重试..."
            sleep 1
        fi
    fi
done

echo "" >> "${LOG_FILE}"
echo "========================================" >> "${LOG_FILE}"
if [ "$success" = true ]; then
    echo "最终结果: 成功, 共请求 ${attempt} 次" >> "${LOG_FILE}"
else
    echo "最终结果: 失败, 共请求 ${attempt} 次" >> "${LOG_FILE}"
fi

echo "响应日志已写入: ${LOG_FILE}"

if [ "$success" = false ]; then
    echo "所有请求均失败, 共尝试 ${attempt} 次"
    exit 1
fi

exit 0
