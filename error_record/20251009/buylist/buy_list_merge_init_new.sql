-- ========================================
-- Merged Buy List Initialization Script
-- ========================================
-- This script uses variables for business_id, name, and business_type to make maintenance easier
-- Modify the DECLARE section if you need to change values
-- ========================================
-- Compatible with SQL Server and DBeaver
-- Execute the entire script at once (do not execute line by line)
-- ========================================

BEGIN
    -- ========================================
    -- Variable Declaration
    -- ========================================

    -- Business Type
    DECLARE @pvb_business_type INT = 1;

-- Business IDs
DECLARE @BIZ_BND_THM_1 NVARCHAR(64) = N'PVBLIST_BND_THM_1';
DECLARE @BIZ_BND_THM_2 NVARCHAR(64) = N'PVBLIST_BND_THM_2';
DECLARE @BIZ_BND_THM_3 NVARCHAR(64) = N'PVBLIST_BND_THM_3';
DECLARE @BIZ_BND_TOP NVARCHAR(64) = N'PVBLIST_BND_TOP';
DECLARE @BIZ_EQ_THM_1 NVARCHAR(64) = N'PVBLIST_EQ_THM_1';
DECLARE @BIZ_EQ_THM_2 NVARCHAR(64) = N'PVBLIST_EQ_THM_2';
DECLARE @BIZ_EQ_THM_3 NVARCHAR(64) = N'PVBLIST_EQ_THM_3';
DECLARE @BIZ_FND_THM_1 NVARCHAR(64) = N'PVBLIST_FND_THM_1';
DECLARE @BIZ_FND_THM_2 NVARCHAR(64) = N'PVBLIST_FND_THM_2';
DECLARE @BIZ_FND_THM_3 NVARCHAR(64) = N'PVBLIST_FND_THM_3';
DECLARE @BIZ_FND_FOCUS NVARCHAR(64) = N'PVBLIST_FND_FOCUS';

    -- Names
DECLARE @NAME_BND_THM_1 NVARCHAR(128) = N'Pvb BondList-Thematic1';
DECLARE @NAME_BND_THM_2 NVARCHAR(128) = N'Pvb BondList-Thematic2';
DECLARE @NAME_BND_THM_3 NVARCHAR(128) = N'Pvb BondList-Thematic3';
DECLARE @NAME_BND_TOP NVARCHAR(128) = N'Pvb Bond Top Focus List';
DECLARE @NAME_EQ_THM_1 NVARCHAR(128) = N'Pvb Equity Thematic1';
DECLARE @NAME_EQ_THM_2 NVARCHAR(128) = N'Pvb Equity Thematic2';
DECLARE @NAME_EQ_THM_3 NVARCHAR(128) = N'Pvb Equity Thematic3';
DECLARE @NAME_FND_THM_1 NVARCHAR(128) = N'Pvb Fund Thematic1';
DECLARE @NAME_FND_THM_2 NVARCHAR(128) = N'Pvb Fund Thematic2';
DECLARE @NAME_FND_THM_3 NVARCHAR(128) = N'Pvb Fund Thematic3';
DECLARE @NAME_FND_FOCUS NVARCHAR(128) = N'Pvb Fund Top Focus List';


    -- ========================================
    -- Step 1: Insert buy_list records
    -- ========================================

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(), @BIZ_BND_THM_1, @NAME_BND_THM_1, @pvb_business_type, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(), @BIZ_BND_THM_2, @NAME_BND_THM_2, @pvb_business_type, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(), @BIZ_BND_THM_3, @NAME_BND_THM_3, @pvb_business_type, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(), @BIZ_BND_TOP, @NAME_BND_TOP, @pvb_business_type, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(), @BIZ_EQ_THM_1, @NAME_EQ_THM_1, @pvb_business_type, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(), @BIZ_EQ_THM_2, @NAME_EQ_THM_2, @pvb_business_type, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(), @BIZ_EQ_THM_3, @NAME_EQ_THM_3, @pvb_business_type, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(), @BIZ_FND_THM_1, @NAME_FND_THM_1, @pvb_business_type, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(), @BIZ_FND_THM_2, @NAME_FND_THM_2, @pvb_business_type, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(), @BIZ_FND_THM_3, @NAME_FND_THM_3, @pvb_business_type, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);

INSERT INTO buy_list
(id, business_id, name, business_type, process_instance_id, status, maker, maker_datetime, maker_business_date, checker, checker_datetime, checker_business_date, record_version, valid_start_datetime, valid_end_datetime, del_flag, system_version)
VALUES
    (newid(), @BIZ_FND_FOCUS, @NAME_FND_FOCUS, @pvb_business_type, NULL, 1, N'', current_timestamp, NULL, NULL, NULL, NULL, 0, current_timestamp, current_timestamp, 0, 0);


-- ========================================
-- Step 2: Insert buy_list_details records
-- ========================================
-- buy_list_id is dynamically retrieved via subquery based on business_id variable

-- Bond
INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), @BIZ_BND_THM_1, (SELECT id FROM buy_list WHERE business_id = @BIZ_BND_THM_1), 0, N'Bond', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), @BIZ_BND_THM_2, (SELECT id FROM buy_list WHERE business_id = @BIZ_BND_THM_2), 0, N'Bond', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), @BIZ_BND_THM_3, (SELECT id FROM buy_list WHERE business_id = @BIZ_BND_THM_3), 0, N'Bond', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), @BIZ_BND_TOP, (SELECT id FROM buy_list WHERE business_id = @BIZ_BND_TOP), 0, N'Bond', NULL, NULL);

-- Equities
INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), @BIZ_EQ_THM_1, (SELECT id FROM buy_list WHERE business_id = @BIZ_EQ_THM_1), 0, N'Equities', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), @BIZ_EQ_THM_2, (SELECT id FROM buy_list WHERE business_id = @BIZ_EQ_THM_2), 0, N'Equities', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), @BIZ_EQ_THM_3, (SELECT id FROM buy_list WHERE business_id = @BIZ_EQ_THM_3), 0, N'Equities', NULL, NULL);

-- Fund
INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), @BIZ_FND_THM_1, (SELECT id FROM buy_list WHERE business_id = @BIZ_FND_THM_1), 0, N'Fund', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), @BIZ_FND_THM_2, (SELECT id FROM buy_list WHERE business_id = @BIZ_FND_THM_2), 0, N'Fund', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), @BIZ_FND_THM_3, (SELECT id FROM buy_list WHERE business_id = @BIZ_FND_THM_3), 0, N'Fund', NULL, NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code, client_id)
VALUES (newid(), @BIZ_FND_FOCUS, (SELECT id FROM buy_list WHERE business_id = @BIZ_FND_FOCUS), 0, N'Fund', NULL, NULL);

PRINT 'Script executed successfully!';
PRINT 'Inserted 11 records into buy_list table';
PRINT 'Inserted 11 records into buy_list_details table';
END

-- ========================================
-- End of script
-- ========================================
