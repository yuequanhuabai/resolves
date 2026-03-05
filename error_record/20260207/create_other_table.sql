
-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_BENCHMARK_MODEL_INFO_1;

CREATE TABLE test_exec_sql.dbo.BR_BENCHMARK_MODEL_INFO_1 (
                                                        ID int IDENTITY(1,1) NOT NULL,
                                                        CREATE_TIME datetime NOT NULL,
                                                        BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [TYPE] nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NAME nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROVIDER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MODEL_FAMILY nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    VENDOR_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK__BR_BENCH__3214EC27082E31B0 PRIMARY KEY (ID)
    );


-- test_exec_sql.dbo.BR_BENCHMARK_MODEL_INFO_2 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_BENCHMARK_MODEL_INFO_2;

CREATE TABLE test_exec_sql.dbo.BR_BENCHMARK_MODEL_INFO_2 (
                                                        ID int IDENTITY(1,1) NOT NULL,
                                                        CREATE_TIME datetime NOT NULL,
                                                        BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [TYPE] nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NAME nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROVIDER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MODEL_FAMILY nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    VENDOR_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK__BR_BENCH__3214EC27082E31B0_copy1 PRIMARY KEY (ID)
    );

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_COMPOSITE_WEIGHTS_1;

CREATE TABLE test_exec_sql.dbo.BR_COMPOSITE_WEIGHTS_1 (
                                                     ID int IDENTITY(1,1) NOT NULL,
                                                     CREATE_TIME datetime NOT NULL,
    [DATE] datetime NULL,
                                                     BENCHMARK_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     COMPONENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     WEIGHT decimal(20,2) NULL,
                                                     CONSTRAINT PK__BR_COMPO__3214EC27DA41D97D PRIMARY KEY (ID)
);


-- test_exec_sql.dbo.BR_COMPOSITE_WEIGHTS_2 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_COMPOSITE_WEIGHTS_2;

CREATE TABLE test_exec_sql.dbo.BR_COMPOSITE_WEIGHTS_2 (
                                                     ID int IDENTITY(1,1) NOT NULL,
                                                     CREATE_TIME datetime NOT NULL,
    [DATE] datetime NULL,
                                                     BENCHMARK_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     COMPONENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     WEIGHT decimal(20,2) NULL,
                                                     CONSTRAINT PK__BR_COMPO__3214EC27DA41D97D_copy1 PRIMARY KEY (ID)
);


-- test_exec_sql.dbo.BR_MODEL_INFO definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_MODEL_INFO;

CREATE TABLE test_exec_sql.dbo.BR_MODEL_INFO (
                                            ID int IDENTITY(1,1) NOT NULL,
                                            CREATE_TIME datetime NOT NULL,
                                            BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            CURRENCY nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [TYPE] nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MODEL_VIEW nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK__BR_MODEL__3214EC27830A3EC0 PRIMARY KEY (ID)
    );


-- test_exec_sql.dbo.BR_MODEL_INFO_1 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_MODEL_INFO_1;

CREATE TABLE test_exec_sql.dbo.BR_MODEL_INFO_1 (
                                              ID int IDENTITY(1,1) NOT NULL,
                                              CREATE_TIME datetime NOT NULL,
                                              BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              CURRENCY nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [TYPE] nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MODEL_VIEW nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK__BR_MODEL__3214EC2735F2B328 PRIMARY KEY (ID)
    );


-- test_exec_sql.dbo.BR_MODEL_INFO_2 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_MODEL_INFO_2;

CREATE TABLE test_exec_sql.dbo.BR_MODEL_INFO_2 (
                                              ID int NULL,
                                              CREATE_TIME datetime NULL,
                                              BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              CURRENCY nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [TYPE] nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MODEL_VIEW nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    );


-- test_exec_sql.dbo.BR_MODEL_POSITION_DATA definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_MODEL_POSITION_DATA;

CREATE TABLE test_exec_sql.dbo.BR_MODEL_POSITION_DATA (
                                                     ID int IDENTITY(1,1) NOT NULL,
                                                     CREATE_TIME datetime NOT NULL,
                                                     POS_DATE datetime NULL,
                                                     PORTFOLIO_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     WEIGHT numeric(20,2) NULL,
                                                     CONSTRAINT PK__BR_MODEL__3214EC27167884F7 PRIMARY KEY (ID)
);


-- test_exec_sql.dbo.BR_MODEL_POSITION_DATA_1 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_MODEL_POSITION_DATA_1;

CREATE TABLE test_exec_sql.dbo.BR_MODEL_POSITION_DATA_1 (
                                                       ID int IDENTITY(1,1) NOT NULL,
                                                       CREATE_TIME datetime NOT NULL,
                                                       POS_DATE datetime NULL,
                                                       PORTFOLIO_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       WEIGHT numeric(20,2) NULL,
                                                       CONSTRAINT PK__BR_MODEL__3214EC2745B8B125 PRIMARY KEY (ID)
);


-- test_exec_sql.dbo.BR_MODEL_POSITION_DATA_2 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_MODEL_POSITION_DATA_2;

CREATE TABLE test_exec_sql.dbo.BR_MODEL_POSITION_DATA_2 (
                                                       ID int NULL,
                                                       CREATE_TIME datetime NULL,
                                                       POS_DATE datetime NULL,
                                                       PORTFOLIO_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       WEIGHT numeric(20,2) NULL
);


-- test_exec_sql.dbo.BR_SECURITY_LIST definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_LIST;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_LIST (
                                               ID int IDENTITY(1,1) NOT NULL,
                                               CREATE_TIME datetime NOT NULL,
                                               CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               LIST_TAG nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               LIST_VALUE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               CONSTRAINT PK__BR_SECUR__3214EC273673E6B1 PRIMARY KEY (ID)
);


-- test_exec_sql.dbo.BR_SECURITY_LISTS_1 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_LISTS_1;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_LISTS_1 (
                                                  ID int IDENTITY(1,1) NOT NULL,
                                                  CREATE_TIME datetime NOT NULL,
                                                  CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  LIST_TAG nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  LIST_VALUE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  DATA_SOURCE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  CONSTRAINT PK__BR_SECUR__3214EC2705D2AF23 PRIMARY KEY (ID)
);


-- test_exec_sql.dbo.BR_SECURITY_LISTS_2 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_LISTS_2;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_LISTS_2 (
                                                  ID int IDENTITY(1,1) NOT NULL,
                                                  CREATE_TIME datetime NOT NULL,
                                                  CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  LIST_TAG nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  LIST_VALUE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  DATA_SOURCE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  CONSTRAINT PK__BR_SECUR__3214EC2705D2AF23_copy2 PRIMARY KEY (ID)
);


-- test_exec_sql.dbo.BR_SECURITY_MASTER_BND_1 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_BND_1;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_BND_1 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_BND_2 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_BND_2;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_BND_2 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy1 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_CBL_1 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_CBL_1;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_CBL_1 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy2 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_COS_1 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_COS_1;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_COS_1 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy4 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_COS_2 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_COS_2;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_COS_2 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy5 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_FMS_1 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_FMS_1;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_FMS_1 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy6 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_FMS_2 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_FMS_2;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_FMS_2 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy7 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_MRG_1 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_MRG_1;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_MRG_1 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy8 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_MRG_2 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_MRG_2;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_MRG_2 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy9 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_MTC_1 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_MTC_1;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_MTC_1 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy10 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_MTC_2 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_MTC_2;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_MTC_2 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy11 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_PDS_1 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_PDS_1;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_PDS_1 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy12 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_PDS_2 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_PDS_2;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_PDS_2 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy13 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_PVB_1 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_PVB_1;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_PVB_1 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy14 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_PVB_2 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_PVB_2;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_PVB_2 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy15 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_SMS_1 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_SMS_1;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_SMS_1 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy16 PRIMARY KEY (SECURITY_MASTER_OID)
    );


-- test_exec_sql.dbo.BR_SECURITY_MASTER_SMS_2 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_SMS_2;

CREATE TABLE test_exec_sql.dbo.BR_SECURITY_MASTER_SMS_2 (
                                                       SECURITY_MASTER_OID bigint NOT NULL,
                                                       CLIENT_ID nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CUSIP nvarchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       ISIN nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       SEDOL nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TICKER nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       PRICE decimal(21,9) NULL,
    [DATE] date NULL,
    [SOURCE] nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CLIENT_SEC_TYPE2 nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CD_INSTMT_TYPE nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    DESC_INSTMT_HANS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ISSUE_COUNTRY nvarchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUPON decimal(9,6) NULL,
    COUP_FREQ char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MATURITY date NULL,
    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MUNI_STATE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PUT_CALL nvarchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EXERCISE_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OPTION_STRIKE decimal(10,0) NULL,
    UNDERLYING_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_ID_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_DESCRIPTION nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    UNDERLYING_PRICE decimal(10,0) NULL,
    CONTRACT_SIZE decimal(10,0) NULL,
    RIC nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    OCC nvarchar(21) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FX_TRADE_DATE date NULL,
    FX_TRADE_CURRENCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NDF_TYPE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONTRACT_CODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STANDARD_CONTRACT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ACCRUAL_DT date NULL,
    RED_CODE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    EFFECTIVE_DATE date NULL,
    COUP_FREQ_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    COUP_FREQ_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_PAY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY_RCY nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PAY_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    REC_LEG nvarchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    FIXED_RATE decimal(10,0) NULL,
    UNDERLYING_TERM decimal(10,0) NULL,
    INDEX_NAME_PAY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    INDEX_NAME_RVY nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    TERM decimal(10,0) NULL,
    INDEX_NAME nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    IRS_TYPE nvarchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROXY_SECTOR nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ATTR_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRODUCT_RISK_RATING decimal(1,0) NULL,
    CONSTRAINT PK__SECURITY__DB91FF368B7EDD25_copy17 PRIMARY KEY (SECURITY_MASTER_OID)
    );

-- test_exec_sql.dbo.TABLE_SWITCH_LOG definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.TABLE_SWITCH_LOG;

CREATE TABLE test_exec_sql.dbo.TABLE_SWITCH_LOG (
                                               table_switch_log_oid int IDENTITY(1,1) NOT NULL,
                                               target_table varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               operation_type varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               business_date date NULL,
                                               table_suffix varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               create_datetime datetime NULL,
                                               create_user varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [type] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    is_valid char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    last_mod_datetime datetime NULL,
    last_mod_user varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK__TABLE_SW__BEF806C027F3216E PRIMARY KEY (table_switch_log_oid)
    );


-- test_exec_sql.dbo.TMP_SECURITY_LISTS_1 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.TMP_SECURITY_LISTS_1;

CREATE TABLE test_exec_sql.dbo.TMP_SECURITY_LISTS_1 (
                                                   ID int IDENTITY(1,1) NOT NULL,
                                                   CREATE_TIME datetime NOT NULL,
                                                   CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   LIST_TAG nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   LIST_VALUE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   DATA_SOURCE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   CONSTRAINT PK__BR_SECUR__3214EC2705D2AF23_copy1 PRIMARY KEY (ID)
);


-- test_exec_sql.dbo.TMP_SECURITY_LISTS_2 definition

-- Drop table

-- DROP TABLE test_exec_sql.dbo.TMP_SECURITY_LISTS_2;

CREATE TABLE test_exec_sql.dbo.TMP_SECURITY_LISTS_2 (
                                                   ID int IDENTITY(1,1) NOT NULL,
                                                   CREATE_TIME datetime NOT NULL,
                                                   CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   LIST_TAG nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   LIST_VALUE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   DATA_SOURCE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   CONSTRAINT PK__BR_SECUR__3214EC2705D2AF23_copy1_copy1 PRIMARY KEY (ID)
);