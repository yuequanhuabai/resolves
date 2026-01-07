CREATE TABLE ASSET_TYPE
(
    ID               varchar(64)  primary key,
    ASSET_TYPE       varchar(32)                                      DEFAULT NULL ,
    SYSTEM_CODE      varchar(32)                                      DEFAULT NULL ,
    BUY_LIST         char(1)                                          DEFAULT NULL ,
    HOUSE_VIEW_LIST  char(1)                                          DEFAULT NULL ,
    CONDITION_SQL    nvarchar(512)                                    DEFAULT NULL,
    FIELD            varchar(32)                                      DEFAULT NULL
);




INSERT INTO testflow.dbo.ASSET_TYPE
(ID, ASSET_TYPE, SYSTEM_CODE, FIELD, CONDITION_SQL, BUY_LIST, HOUSE_VIEW_LIST)
VALUES (newid(), N'Bond', N'BND', N'ISIN', NULL,N'Y', NULL);

INSERT INTO testflow.dbo.ASSET_TYPE
(ID, ASSET_TYPE, SYSTEM_CODE, FIELD, CONDITION_SQL, BUY_LIST, HOUSE_VIEW_LIST)
VALUES (newid(), N'Certificate of Deposits', N'BND', N'ISIN', NULL,N'Y', NULL);

INSERT INTO testflow.dbo.ASSET_TYPE
(ID, ASSET_TYPE, SYSTEM_CODE, FIELD, CONDITION_SQL, BUY_LIST, HOUSE_VIEW_LIST)
VALUES (newid(), N'Equities', N'SMS', N'TICKER', N'and CLIENT_SEC_TYPE = ''Equities'' and CLIENT_SEC_TYPE2 in (''Stocks'',''Debt Security'',''Synthetic ETF'',''Trust (Non-Synthetic ETF)'',''US Equities'',''US ETF'',''Warrant'',''Rights'')',N'Y', NULL);

INSERT INTO testflow.dbo.ASSET_TYPE
(ID, ASSET_TYPE, SYSTEM_CODE, FIELD, CONDITION_SQL, BUY_LIST, HOUSE_VIEW_LIST)
VALUES (newid(), N'Equities', N'PVB', N'TICKER', N'and CLIENT_SEC_TYPE = ''Equities'' and CLIENT_SET_TYPE2 IN (''JP Equities'',''SG Equities'',''SG ETF'')',N'Y', NULL);


INSERT INTO testflow.dbo.ASSET_TYPE
(ID, ASSET_TYPE, SYSTEM_CODE, FIELD, CONDITION_SQL, BUY_LIST, HOUSE_VIEW_LIST)
VALUES (newid(), N'Fund', N'FMS', N'ISIN', NULL,N'Y', NULL);


INSERT INTO testflow.dbo.ASSET_TYPE
(ID, ASSET_TYPE, SYSTEM_CODE, FIELD, CONDITION_SQL, BUY_LIST, HOUSE_VIEW_LIST)
VALUES (newid(), N'Structured Investment', N'MTC', N'Product Code', NULL,N'Y', NULL);
