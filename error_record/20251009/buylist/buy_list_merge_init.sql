-- ========================================
-- Merged Buy List Initialization Script
-- ========================================
-- This script initializes both buy_list and buy_list_details tables
-- buy_list_details.buy_list_id is dynamically populated via subquery based on business_id
-- ========================================

-- ========================================
-- Step 1: Insert buy_list records
-- ========================================

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(),N'PVBLIST_BND_THM_1', N'Pvb BondList-Thematic1', 1, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(),N'PVBLIST_BND_THM_2', N'Pvb BondList-Thematic2', 1, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(),N'PVBLIST_BND_THM_3',  N'Pvb BondList-Thematic3', 1, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(),N'PVBLIST_BND_TOP',  N'Pvb Bond Top Focus List', 1, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(),N'PVBLIST_EQ_THM_1',  N'Pvb Equity Thematic1', 1, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(),N'PVBLIST_EQ_THM_2',  N'Pvb Equity Thematic2', 1, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(),N'PVBLIST_EQ_THM_3', N'Pvb Equity Thematic3', 1, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(),N'PVBLIST_FND_THM_1', N'Pvb Fund Thematic1', 1, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(),N'PVBLIST_FND_THM_2',  N'Pvb Fund Thematic2', 1, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(),N'PVBLIST_FND_THM_3', N'Pvb Fund Thematic3', 1, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(),N'PVBLIST_FND_FOCUS',  N'Pvb Fund Top Focus List', 1, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);


-- ========================================
-- Step 2: Insert buy_list_details records
-- ========================================
-- buy_list_id is dynamically retrieved via subquery based on business_id

-- Bond
INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), N'PVBLIST_BND_THM_1', (SELECT id FROM buy_list WHERE business_id = N'PVBLIST_BND_THM_1'), 0, N'Bond', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), N'PVBLIST_BND_THM_2', (SELECT id FROM buy_list WHERE business_id = N'PVBLIST_BND_THM_2'), 0, N'Bond', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), N'PVBLIST_BND_THM_3', (SELECT id FROM buy_list WHERE business_id = N'PVBLIST_BND_THM_3'), 0, N'Bond', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), N'PVBLIST_BND_TOP', (SELECT id FROM buy_list WHERE business_id = N'PVBLIST_BND_TOP'), 0, N'Bond', NULL, NULL);

-- Equities
INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), N'PVBLIST_EQ_THM_1', (SELECT id FROM buy_list WHERE business_id = N'PVBLIST_EQ_THM_1'), 0, N'Equities', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), N'PVBLIST_EQ_THM_2', (SELECT id FROM buy_list WHERE business_id = N'PVBLIST_EQ_THM_2'), 0, N'Equities', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), N'PVBLIST_EQ_THM_3', (SELECT id FROM buy_list WHERE business_id = N'PVBLIST_EQ_THM_3'), 0, N'Equities', NULL, NULL);

-- Fund
INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), N'PVBLIST_FND_THM_1', (SELECT id FROM buy_list WHERE business_id = N'PVBLIST_FND_THM_1'), 0, N'Fund', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), N'PVBLIST_FND_THM_2', (SELECT id FROM buy_list WHERE business_id = N'PVBLIST_FND_THM_2'), 0, N'Fund', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), N'PVBLIST_FND_THM_3', (SELECT id FROM buy_list WHERE business_id = N'PVBLIST_FND_THM_3'), 0, N'Fund', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), N'PVBLIST_FND_FOCUS', (SELECT id FROM buy_list WHERE business_id = N'PVBLIST_FND_FOCUS'), 0, N'Fund', NULL, NULL);

-- ========================================
-- End of script
-- ========================================
