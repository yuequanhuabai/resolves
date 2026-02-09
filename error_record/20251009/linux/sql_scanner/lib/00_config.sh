#!/bin/bash
# ============================================================================
#  模块 00: 全局配置
#  依赖: 无
# ============================================================================

set -o pipefail

SCAN_DIR=""
REPORT_FILE=""
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TIMESTAMP_FILE=$(date '+%Y%m%d_%H%M%S')

TMP_DIR=$(mktemp -d)
FINDINGS_FILE="${TMP_DIR}/findings.txt"
> "$FINDINGS_FILE"

cleanup() { rm -rf "$TMP_DIR" 2>/dev/null; }
trap cleanup EXIT
