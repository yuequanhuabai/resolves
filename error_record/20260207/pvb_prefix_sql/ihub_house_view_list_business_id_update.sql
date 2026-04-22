-- ============================================================
-- 目的：为已投产的 ihub_house_view_list 及 ihub_house_view_list_details 表中
--       Private Banking 记录的 business_id 按新命名规则修正
-- 映射关系（仅 business_type = 1）：
--   LIST_BND_ELG  -->  PVBLIST_ELG_BND
--   LIST_EQ_ELG   -->  PVBLIST_ELG_EQ
--   LIST_FND_ELG  -->  PVBLIST_ELG_FND
-- Retail Banking（business_type = 2）待确认，本次不修改
-- 注意：两种 business_type 的 business_id 原始值相同，
--       必须严格通过 business_type = 1 过滤，切勿遗漏此条件
-- 说明：ihub_house_view_list_details.business_id 是主表 business_id 的冗余字段，
--       需与主表保持同步
-- 执行前请先运行下方 SELECT 验证语句确认影响行数，再执行 UPDATE
-- ============================================================

-- *** 执行前验证：确认待更新的主表记录 ***
SELECT id, business_id, business_type
FROM ihub_house_view_list
WHERE business_type = 1
  AND business_id IN ('LIST_BND_ELG', 'LIST_EQ_ELG', 'LIST_FND_ELG')

-- *** 执行前验证：确认待更新的明细表记录 ***
SELECT id, house_view_list_id, business_id
FROM ihub_house_view_list_details
WHERE business_id IN ('LIST_BND_ELG', 'LIST_EQ_ELG', 'LIST_FND_ELG')
  AND house_view_list_id IN (
      SELECT id FROM ihub_house_view_list WHERE business_type = 1
  )

-- ============================================================
-- 确认以上 SELECT 结果符合预期后，再执行以下 UPDATE
-- ============================================================
BEGIN TRANSACTION
GO

-- 1. 更新主表
UPDATE ihub_house_view_list
SET business_id = CASE business_id
    WHEN 'LIST_BND_ELG' THEN 'PVBLIST_ELG_BND'
    WHEN 'LIST_EQ_ELG'  THEN 'PVBLIST_ELG_EQ'
    WHEN 'LIST_FND_ELG' THEN 'PVBLIST_ELG_FND'
END
WHERE business_type = 1
  AND business_id IN ('LIST_BND_ELG', 'LIST_EQ_ELG', 'LIST_FND_ELG')
GO

-- 2. 同步更新明细表
UPDATE ihub_house_view_list_details
SET business_id = CASE business_id
    WHEN 'LIST_BND_ELG' THEN 'PVBLIST_ELG_BND'
    WHEN 'LIST_EQ_ELG'  THEN 'PVBLIST_ELG_EQ'
    WHEN 'LIST_FND_ELG' THEN 'PVBLIST_ELG_FND'
END
WHERE business_id IN ('LIST_BND_ELG', 'LIST_EQ_ELG', 'LIST_FND_ELG')
  AND house_view_list_id IN (
      SELECT id FROM ihub_house_view_list WHERE business_type = 1
  )
GO

COMMIT
GO
