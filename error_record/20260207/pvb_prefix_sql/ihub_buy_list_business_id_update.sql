-- ============================================================
-- 目的：为已投产的 ihub_buy_list 及 ihub_buy_list_details 表中
--       Private Banking 记录的 business_id 统一加上 PVB 前缀
-- 影响范围：仅 business_type = 1 且 business_id 不以 'PVB' 开头的记录
-- Retail Banking（business_type = 2）不受影响
-- 说明：ihub_buy_list_details.business_id 是主表 business_id 的冗余字段，
--       需与主表保持同步
-- 执行前请先运行下方 SELECT 验证语句确认影响行数，再执行 UPDATE
-- ============================================================

-- *** 执行前验证：确认待更新的主表记录 ***
SELECT id, business_id, business_type
FROM ihub_buy_list
WHERE business_type = 1
  AND business_id NOT LIKE 'PVB%'

-- *** 执行前验证：确认待更新的明细表记录 ***
SELECT id, buy_list_id, business_id
FROM ihub_buy_list_details
WHERE business_id NOT LIKE 'PVB%'
  AND buy_list_id IN (
      SELECT id FROM ihub_buy_list WHERE business_type = 1
  )

-- ============================================================
-- 确认以上 SELECT 结果符合预期后，再执行以下 UPDATE
-- ============================================================
BEGIN TRANSACTION
GO

-- 1. 更新主表
UPDATE ihub_buy_list
SET business_id = 'PVB' + business_id
WHERE business_type = 1
  AND business_id NOT LIKE 'PVB%'
GO

-- 2. 同步更新明细表
UPDATE ihub_buy_list_details
SET business_id = 'PVB' + business_id
WHERE business_id NOT LIKE 'PVB%'
  AND buy_list_id IN (
      SELECT id FROM ihub_buy_list WHERE business_type = 1
  )
GO

COMMIT
GO
