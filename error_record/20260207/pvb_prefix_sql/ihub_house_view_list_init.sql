BEGIN TRANSACTION
GO
-- private banking
INSERT INTO ihub_house_view_list (id, business_id, name, business_type, process_instance_id, approval_status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag) VALUES (newid(),N'PVBLIST_ELG_BND', N'Pvb Eligible Bond', 1, NULL, 2, N'', NULL, NULL, NULL, NULL, NULL, 0, GETDATE(), NULL, 0)
GO
INSERT INTO ihub_house_view_list (id, business_id, name, business_type, process_instance_id, approval_status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag) VALUES (newid(),N'PVBLIST_ELG_EQ', N'Pvb Eligible Equity', 1, NULL, 2, N'', NULL, NULL, NULL, NULL, NULL, 0, GETDATE(), NULL, 0)
GO
INSERT INTO ihub_house_view_list (id, business_id, name, business_type, process_instance_id, approval_status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag) VALUES (newid(),N'PVBLIST_ELG_FND', N'Pvb Eligible Fund', 1, NULL, 2, N'', NULL, NULL, NULL, NULL, NULL, 0, GETDATE(), NULL, 0)
GO
-- retail banking (pending confirmation, no changes)
INSERT INTO ihub_house_view_list (id, business_id, name, business_type, process_instance_id, approval_status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag) VALUES (newid(),N'LIST_BND_ELG', N'Pvb Eligible Bond', 2, NULL, 2, N'', NULL, NULL, NULL, NULL, NULL, 0, GETDATE(), NULL, 0)
GO
INSERT INTO ihub_house_view_list (id, business_id, name, business_type, process_instance_id, approval_status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag) VALUES (newid(),N'LIST_EQ_ELG', N'Pvb Eligible Equity', 2, NULL, 2, N'', NULL, NULL, NULL, NULL, NULL, 0, GETDATE(), NULL, 0)
GO
INSERT INTO ihub_house_view_list (id, business_id, name, business_type, process_instance_id, approval_status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag) VALUES (newid(),N'LIST_FND_ELG', N'Pvb Eligible Fund', 2, NULL, 2, N'', NULL, NULL, NULL, NULL, NULL, 0, GETDATE(), NULL, 0)
GO
COMMIT
GO
