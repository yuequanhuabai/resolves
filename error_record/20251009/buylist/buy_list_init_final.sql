INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, approval_status , maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag)
VALUES
    (newid(),N'PVBLIST_BND_THM_1', N'Pvb BondList-Thematic1', 1, NULL, 2, N'', NULL, NULL, NULL, NULL, NULL, 0, current_timestamp, NULL, 0);