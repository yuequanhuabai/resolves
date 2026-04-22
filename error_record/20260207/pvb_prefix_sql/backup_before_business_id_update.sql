-- ============================================================
-- 目的：在执行 business_id 修改前，备份 4 张相关表的当前数据
-- 备份表命名规则：原表名 + _BAK_YYYYMMDD
-- 执行时机：在执行任何 UPDATE 脚本之前运行本脚本
-- 恢复方式：如需回滚，从对应 _BAK 表 SELECT 数据核对或还原
-- ============================================================

-- 1. 备份 ihub_buy_list
SELECT *
INTO ihub_buy_list_bak_20260422
FROM ihub_buy_list
GO

-- 2. 备份 ihub_buy_list_details
SELECT *
INTO ihub_buy_list_details_bak_20260422
FROM ihub_buy_list_details
GO

-- 3. 备份 ihub_house_view_list
SELECT *
INTO ihub_house_view_list_bak_20260422
FROM ihub_house_view_list
GO

-- 4. 备份 ihub_house_view_list_details
SELECT *
INTO ihub_house_view_list_details_bak_20260422
FROM ihub_house_view_list_details
GO

-- ============================================================
-- 备份完成后，验证各备份表行数与原表是否一致
-- ============================================================
SELECT 'ihub_buy_list'                    AS table_name, COUNT(*) AS row_count FROM ihub_buy_list
UNION ALL
SELECT 'ihub_buy_list_bak_20260422'       AS table_name, COUNT(*) AS row_count FROM ihub_buy_list_bak_20260422
UNION ALL
SELECT 'ihub_buy_list_details'            AS table_name, COUNT(*) AS row_count FROM ihub_buy_list_details
UNION ALL
SELECT 'ihub_buy_list_details_bak_20260422' AS table_name, COUNT(*) AS row_count FROM ihub_buy_list_details_bak_20260422
UNION ALL
SELECT 'ihub_house_view_list'             AS table_name, COUNT(*) AS row_count FROM ihub_house_view_list
UNION ALL
SELECT 'ihub_house_view_list_bak_20260422' AS table_name, COUNT(*) AS row_count FROM ihub_house_view_list_bak_20260422
UNION ALL
SELECT 'ihub_house_view_list_details'     AS table_name, COUNT(*) AS row_count FROM ihub_house_view_list_details
UNION ALL
SELECT 'ihub_house_view_list_details_bak_20260422' AS table_name, COUNT(*) AS row_count FROM ihub_house_view_list_details_bak_20260422
GO
