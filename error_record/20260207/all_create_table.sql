-- testflow.dbo.ACT_EVT_LOG definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_EVT_LOG;

CREATE TABLE testflow.dbo.ACT_EVT_LOG (
                                          LOG_NR_ numeric(19,0) IDENTITY(1,1) NOT NULL,
                                          TYPE_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          TASK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          TIME_STAMP_ datetime NOT NULL,
                                          USER_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          DATA_ varbinary(MAX) NULL,
                                          LOCK_OWNER_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          LOCK_TIME_ datetime NULL,
                                          IS_PROCESSED_ tinyint DEFAULT 0 NULL,
                                          CONSTRAINT PK__ACT_EVT___DE8852D862B75F8D PRIMARY KEY (LOG_NR_)
);


-- testflow.dbo.ACT_GE_PROPERTY definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_GE_PROPERTY;

CREATE TABLE testflow.dbo.ACT_GE_PROPERTY (
                                              NAME_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                              VALUE_ nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              REV_ int NULL,
                                              CONSTRAINT PK__ACT_GE_P__A7BE44DE55CAE128 PRIMARY KEY (NAME_)
);


-- testflow.dbo.ACT_HI_ACTINST definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_HI_ACTINST;

CREATE TABLE testflow.dbo.ACT_HI_ACTINST (
                                             ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             REV_ int DEFAULT 1 NULL,
                                             PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             ACT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             TASK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             CALL_PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             ACT_NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             ACT_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             ASSIGNEE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             START_TIME_ datetime NOT NULL,
                                             END_TIME_ datetime NULL,
                                             TRANSACTION_ORDER_ int NULL,
                                             DURATION_ numeric(19,0) NULL,
                                             DELETE_REASON_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                             CONSTRAINT PK__ACT_HI_A__C4971C0F1AC1784A PRIMARY KEY (ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_HI_ACT_INST_END ON dbo.ACT_HI_ACTINST (  END_TIME_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_ACT_INST_EXEC ON dbo.ACT_HI_ACTINST (  EXECUTION_ID_ ASC  , ACT_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_ACT_INST_PROCINST ON dbo.ACT_HI_ACTINST (  PROC_INST_ID_ ASC  , ACT_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_ACT_INST_START ON dbo.ACT_HI_ACTINST (  START_TIME_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_HI_ATTACHMENT definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_HI_ATTACHMENT;

CREATE TABLE testflow.dbo.ACT_HI_ATTACHMENT (
                                                ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                REV_ int NULL,
                                                USER_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                DESCRIPTION_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                TASK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                URL_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                CONTENT_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                TIME_ datetime NULL,
                                                CONSTRAINT PK__ACT_HI_A__C4971C0F5D5A6CB6 PRIMARY KEY (ID_)
);


-- testflow.dbo.ACT_HI_COMMENT definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_HI_COMMENT;

CREATE TABLE testflow.dbo.ACT_HI_COMMENT (
                                             ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             TIME_ datetime NOT NULL,
                                             USER_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             TASK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             ACTION_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             MESSAGE_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             FULL_MSG_ varbinary(MAX) NULL,
                                             CONSTRAINT PK__ACT_HI_C__C4971C0FF5F26909 PRIMARY KEY (ID_)
);


-- testflow.dbo.ACT_HI_DETAIL definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_HI_DETAIL;

CREATE TABLE testflow.dbo.ACT_HI_DETAIL (
                                            ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                            TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                            PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            TASK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            ACT_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                            VAR_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            REV_ int NULL,
                                            TIME_ datetime NOT NULL,
                                            BYTEARRAY_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            DOUBLE_ float NULL,
                                            LONG_ numeric(19,0) NULL,
                                            TEXT_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            TEXT2_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            CONSTRAINT PK__ACT_HI_D__C4971C0F28D0D315 PRIMARY KEY (ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_HI_DETAIL_ACT_INST ON dbo.ACT_HI_DETAIL (  ACT_INST_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_DETAIL_NAME ON dbo.ACT_HI_DETAIL (  NAME_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_DETAIL_PROC_INST ON dbo.ACT_HI_DETAIL (  PROC_INST_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_DETAIL_TASK_ID ON dbo.ACT_HI_DETAIL (  TASK_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_DETAIL_TIME ON dbo.ACT_HI_DETAIL (  TIME_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_HI_ENTITYLINK definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_HI_ENTITYLINK;

CREATE TABLE testflow.dbo.ACT_HI_ENTITYLINK (
                                                ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                LINK_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                CREATE_TIME_ datetime NULL,
                                                SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                SUB_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                SCOPE_DEFINITION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                PARENT_ELEMENT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                REF_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                REF_SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                REF_SCOPE_DEFINITION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                ROOT_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                ROOT_SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                HIERARCHY_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                CONSTRAINT PK__ACT_HI_E__C4971C0FC089A054 PRIMARY KEY (ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_HI_ENT_LNK_REF_SCOPE ON dbo.ACT_HI_ENTITYLINK (  REF_SCOPE_ID_ ASC  , REF_SCOPE_TYPE_ ASC  , LINK_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_ENT_LNK_ROOT_SCOPE ON dbo.ACT_HI_ENTITYLINK (  ROOT_SCOPE_ID_ ASC  , ROOT_SCOPE_TYPE_ ASC  , LINK_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_ENT_LNK_SCOPE ON dbo.ACT_HI_ENTITYLINK (  SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  , LINK_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_ENT_LNK_SCOPE_DEF ON dbo.ACT_HI_ENTITYLINK (  SCOPE_DEFINITION_ID_ ASC  , SCOPE_TYPE_ ASC  , LINK_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_HI_IDENTITYLINK definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_HI_IDENTITYLINK;

CREATE TABLE testflow.dbo.ACT_HI_IDENTITYLINK (
                                                  ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  GROUP_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  USER_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  TASK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  CREATE_TIME_ datetime NULL,
                                                  PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SUB_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SCOPE_DEFINITION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  CONSTRAINT PK__ACT_HI_I__C4971C0FE2BFC0CD PRIMARY KEY (ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_HI_IDENT_LNK_SCOPE ON dbo.ACT_HI_IDENTITYLINK (  SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_IDENT_LNK_SCOPE_DEF ON dbo.ACT_HI_IDENTITYLINK (  SCOPE_DEFINITION_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_IDENT_LNK_SUB_SCOPE ON dbo.ACT_HI_IDENTITYLINK (  SUB_SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_IDENT_LNK_USER ON dbo.ACT_HI_IDENTITYLINK (  USER_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_HI_PROCINST definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_HI_PROCINST;

CREATE TABLE testflow.dbo.ACT_HI_PROCINST (
                                              ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                              REV_ int DEFAULT 1 NULL,
                                              PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                              BUSINESS_KEY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                              START_TIME_ datetime NOT NULL,
                                              END_TIME_ datetime NULL,
                                              DURATION_ numeric(19,0) NULL,
                                              START_USER_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              START_ACT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              END_ACT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              SUPER_PROCESS_INSTANCE_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              DELETE_REASON_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                              NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              CALLBACK_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              CALLBACK_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              REFERENCE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              REFERENCE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              PROPAGATED_STAGE_INST_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              BUSINESS_STATUS_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              CONSTRAINT PK__ACT_HI_P__C4971C0F9EA89CC0 PRIMARY KEY (ID_),
                                              CONSTRAINT UQ__ACT_HI_P__C034157271462E77 UNIQUE (PROC_INST_ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_HI_PRO_INST_END ON dbo.ACT_HI_PROCINST (  END_TIME_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_PRO_I_BUSKEY ON dbo.ACT_HI_PROCINST (  BUSINESS_KEY_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_PRO_SUPER_PROCINST ON dbo.ACT_HI_PROCINST (  SUPER_PROCESS_INSTANCE_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_HI_TASKINST definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_HI_TASKINST;

CREATE TABLE testflow.dbo.ACT_HI_TASKINST (
                                              ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                              REV_ int DEFAULT 1 NULL,
                                              PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              TASK_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              TASK_DEF_KEY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              SUB_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              SCOPE_DEFINITION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              PROPAGATED_STAGE_INST_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              STATE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              PARENT_TASK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              DESCRIPTION_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              OWNER_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              ASSIGNEE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              START_TIME_ datetime NOT NULL,
                                              IN_PROGRESS_TIME_ datetime NULL,
                                              IN_PROGRESS_STARTED_BY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              CLAIM_TIME_ datetime NULL,
                                              CLAIMED_BY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              SUSPENDED_TIME_ datetime NULL,
                                              SUSPENDED_BY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              END_TIME_ datetime NULL,
                                              COMPLETED_BY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              DURATION_ numeric(19,0) NULL,
                                              DELETE_REASON_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              PRIORITY_ int NULL,
                                              IN_PROGRESS_DUE_DATE_ datetime NULL,
                                              DUE_DATE_ datetime NULL,
                                              FORM_KEY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              CATEGORY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                              LAST_UPDATED_TIME_ datetime2 NULL,
                                              CONSTRAINT PK__ACT_HI_T__C4971C0FAE05C589 PRIMARY KEY (ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_HI_TASK_SCOPE ON dbo.ACT_HI_TASKINST (  SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_TASK_SCOPE_DEF ON dbo.ACT_HI_TASKINST (  SCOPE_DEFINITION_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_TASK_SUB_SCOPE ON dbo.ACT_HI_TASKINST (  SUB_SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_HI_TSK_LOG definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_HI_TSK_LOG;

CREATE TABLE testflow.dbo.ACT_HI_TSK_LOG (
                                             ID_ numeric(19,0) IDENTITY(1,1) NOT NULL,
                                             TYPE_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             TASK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             TIME_STAMP_ datetime NOT NULL,
                                             USER_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             DATA_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             SCOPE_DEFINITION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             SUB_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                             CONSTRAINT PK__ACT_HI_T__C4971C0F3C73D011 PRIMARY KEY (ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_ACT_HI_TSK_LOG_TASK ON dbo.ACT_HI_TSK_LOG (  TASK_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_HI_VARINST definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_HI_VARINST;

CREATE TABLE testflow.dbo.ACT_HI_VARINST (
                                             ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             REV_ int DEFAULT 1 NULL,
                                             PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             TASK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             VAR_TYPE_ nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             SUB_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             BYTEARRAY_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             DOUBLE_ float NULL,
                                             LONG_ numeric(19,0) NULL,
                                             TEXT_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             TEXT2_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             META_INFO_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             CREATE_TIME_ datetime NULL,
                                             LAST_UPDATED_TIME_ datetime2 NULL,
                                             CONSTRAINT PK__ACT_HI_V__C4971C0F5213D5DF PRIMARY KEY (ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_HI_PROCVAR_NAME_TYPE ON dbo.ACT_HI_VARINST (  NAME_ ASC  , VAR_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_VAR_SCOPE_ID_TYPE ON dbo.ACT_HI_VARINST (  SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_HI_VAR_SUB_ID_TYPE ON dbo.ACT_HI_VARINST (  SUB_SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_ID_BYTEARRAY definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_ID_BYTEARRAY;

CREATE TABLE testflow.dbo.ACT_ID_BYTEARRAY (
                                               ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                               REV_ int NULL,
                                               NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               BYTES_ varbinary(MAX) NULL,
                                               CONSTRAINT PK__ACT_ID_B__C4971C0F70263D5D PRIMARY KEY (ID_)
);


-- testflow.dbo.ACT_ID_GROUP definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_ID_GROUP;

CREATE TABLE testflow.dbo.ACT_ID_GROUP (
                                           ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                           REV_ int NULL,
                                           NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           CONSTRAINT PK__ACT_ID_G__C4971C0FCD414305 PRIMARY KEY (ID_)
);


-- testflow.dbo.ACT_ID_INFO definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_ID_INFO;

CREATE TABLE testflow.dbo.ACT_ID_INFO (
                                          ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                          REV_ int NULL,
                                          USER_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          TYPE_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          KEY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          VALUE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          PASSWORD_ varbinary(MAX) NULL,
                                          PARENT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          CONSTRAINT PK__ACT_ID_I__C4971C0FDA8812CA PRIMARY KEY (ID_)
);


-- testflow.dbo.ACT_ID_PRIV definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_ID_PRIV;

CREATE TABLE testflow.dbo.ACT_ID_PRIV (
                                          ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                          NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                          CONSTRAINT ACT_UNIQ_PRIV_NAME UNIQUE (NAME_),
                                          CONSTRAINT PK__ACT_ID_P__C4971C0F285A255D PRIMARY KEY (ID_)
);


-- testflow.dbo.ACT_ID_PROPERTY definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_ID_PROPERTY;

CREATE TABLE testflow.dbo.ACT_ID_PROPERTY (
                                              NAME_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                              VALUE_ nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              REV_ int NULL,
                                              CONSTRAINT PK__ACT_ID_P__A7BE44DEFE4AE270 PRIMARY KEY (NAME_)
);


-- testflow.dbo.ACT_ID_TOKEN definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_ID_TOKEN;

CREATE TABLE testflow.dbo.ACT_ID_TOKEN (
                                           ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                           REV_ int NULL,
                                           TOKEN_VALUE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           TOKEN_DATE_ datetime NULL,
                                           IP_ADDRESS_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           USER_AGENT_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           USER_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           TOKEN_DATA_ nvarchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           CONSTRAINT PK__ACT_ID_T__C4971C0FDD44F3C5 PRIMARY KEY (ID_)
);


-- testflow.dbo.ACT_ID_USER definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_ID_USER;

CREATE TABLE testflow.dbo.ACT_ID_USER (
                                          ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                          REV_ int NULL,
                                          FIRST_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          LAST_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          DISPLAY_NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          EMAIL_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          PWD_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          PICTURE_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                          CONSTRAINT PK__ACT_ID_U__C4971C0FC59B5C40 PRIMARY KEY (ID_)
);


-- testflow.dbo.ACT_RE_DEPLOYMENT definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RE_DEPLOYMENT;

CREATE TABLE testflow.dbo.ACT_RE_DEPLOYMENT (
                                                ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                CATEGORY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                KEY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                DEPLOY_TIME_ datetime NULL,
                                                DERIVED_FROM_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                DERIVED_FROM_ROOT_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                PARENT_DEPLOYMENT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                ENGINE_VERSION_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                CONSTRAINT PK__ACT_RE_D__C4971C0F8BE06FB3 PRIMARY KEY (ID_)
);


-- testflow.dbo.ACT_RE_PROCDEF definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RE_PROCDEF;

CREATE TABLE testflow.dbo.ACT_RE_PROCDEF (
                                             ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             REV_ int NULL,
                                             CATEGORY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             KEY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             VERSION_ int NOT NULL,
                                             DEPLOYMENT_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             RESOURCE_NAME_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             DGRM_RESOURCE_NAME_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             DESCRIPTION_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             HAS_START_FORM_KEY_ tinyint NULL,
                                             HAS_GRAPHICAL_NOTATION_ tinyint NULL,
                                             SUSPENSION_STATE_ tinyint NULL,
                                             TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                             DERIVED_FROM_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             DERIVED_FROM_ROOT_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             DERIVED_VERSION_ int DEFAULT 0 NOT NULL,
                                             ENGINE_VERSION_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             CONSTRAINT ACT_UNIQ_PROCDEF UNIQUE (KEY_,VERSION_,DERIVED_VERSION_,TENANT_ID_),
                                             CONSTRAINT PK__ACT_RE_P__C4971C0F0C59BCC8 PRIMARY KEY (ID_)
);


-- testflow.dbo.ACT_RU_ACTINST definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RU_ACTINST;

CREATE TABLE testflow.dbo.ACT_RU_ACTINST (
                                             ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             REV_ int DEFAULT 1 NULL,
                                             PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             ACT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             TASK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             CALL_PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             ACT_NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             ACT_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             ASSIGNEE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             START_TIME_ datetime NOT NULL,
                                             END_TIME_ datetime NULL,
                                             DURATION_ numeric(19,0) NULL,
                                             TRANSACTION_ORDER_ int NULL,
                                             DELETE_REASON_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                             CONSTRAINT PK__ACT_RU_A__C4971C0F071CCB4D PRIMARY KEY (ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_RU_ACTI_END ON dbo.ACT_RU_ACTINST (  END_TIME_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_RU_ACTI_EXEC ON dbo.ACT_RU_ACTINST (  EXECUTION_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_RU_ACTI_EXEC_ACT ON dbo.ACT_RU_ACTINST (  EXECUTION_ID_ ASC  , ACT_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_RU_ACTI_PROC ON dbo.ACT_RU_ACTINST (  PROC_INST_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_RU_ACTI_PROC_ACT ON dbo.ACT_RU_ACTINST (  PROC_INST_ID_ ASC  , ACT_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_RU_ACTI_START ON dbo.ACT_RU_ACTINST (  START_TIME_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_RU_ACTI_TASK ON dbo.ACT_RU_ACTINST (  TASK_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_RU_ENTITYLINK definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RU_ENTITYLINK;

CREATE TABLE testflow.dbo.ACT_RU_ENTITYLINK (
                                                ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                REV_ int NULL,
                                                CREATE_TIME_ datetime NULL,
                                                LINK_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                SUB_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                SCOPE_DEFINITION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                PARENT_ELEMENT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                REF_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                REF_SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                REF_SCOPE_DEFINITION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                ROOT_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                ROOT_SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                HIERARCHY_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                CONSTRAINT PK__ACT_RU_E__C4971C0F1EAA984B PRIMARY KEY (ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_ENT_LNK_REF_SCOPE ON dbo.ACT_RU_ENTITYLINK (  REF_SCOPE_ID_ ASC  , REF_SCOPE_TYPE_ ASC  , LINK_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_ENT_LNK_ROOT_SCOPE ON dbo.ACT_RU_ENTITYLINK (  ROOT_SCOPE_ID_ ASC  , ROOT_SCOPE_TYPE_ ASC  , LINK_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_ENT_LNK_SCOPE ON dbo.ACT_RU_ENTITYLINK (  SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  , LINK_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_ENT_LNK_SCOPE_DEF ON dbo.ACT_RU_ENTITYLINK (  SCOPE_DEFINITION_ID_ ASC  , SCOPE_TYPE_ ASC  , LINK_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_RU_HISTORY_JOB definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RU_HISTORY_JOB;

CREATE TABLE testflow.dbo.ACT_RU_HISTORY_JOB (
                                                 ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                 REV_ int NULL,
                                                 LOCK_EXP_TIME_ datetime NULL,
                                                 LOCK_OWNER_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                 RETRIES_ int NULL,
                                                 EXCEPTION_STACK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                 EXCEPTION_MSG_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                 HANDLER_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                 HANDLER_CFG_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                 CUSTOM_VALUES_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                 ADV_HANDLER_CFG_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                 CREATE_TIME_ datetime2 NULL,
                                                 SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                 TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                 CONSTRAINT PK__ACT_RU_H__C4971C0F2CF79161 PRIMARY KEY (ID_)
);


-- testflow.dbo.ASSET_CLASSIFICATION definition

-- Drop table

-- DROP TABLE testflow.dbo.ASSET_CLASSIFICATION;

CREATE TABLE testflow.dbo.ASSET_CLASSIFICATION (
                                                   ASSET_CLASSIFICATION_OID bigint NOT NULL,
                                                   ATTR_NAME varchar(80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   LEVEL_1 varchar(80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   LEVEL_2 varchar(80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   LEVEL_3 varchar(80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   CONSTRAINT ASSET_CLASSIFICATION_PK PRIMARY KEY (ASSET_CLASSIFICATION_OID)
);


-- testflow.dbo.BANK definition

-- Drop table

-- DROP TABLE testflow.dbo.BANK;

CREATE TABLE testflow.dbo.BANK (
                                   BANK_OID decimal(25,0) NOT NULL,
                                   BANK_CODE_1 varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                   BANK_CODE_2 varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                   DESCPT_LANG0 varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                   DESCPT_LANG1 varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                   PREV_BUSSINESS_DATE date NULL,
                                   BUSINESS_DATE date NULL,
                                   NEXT_BUSINESS_DATE date NULL,
                                   LAST_MOD_DATETIME datetime NULL,
                                   LAST_MOD_USER varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                   DEFAULT_BRANCH_CODE varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                   CONSTRAINT BANK_PK PRIMARY KEY (BANK_OID)
);


-- testflow.dbo.BATCH_BUSINESS_DATE_RESULT definition

-- Drop table

-- DROP TABLE testflow.dbo.BATCH_BUSINESS_DATE_RESULT;

CREATE TABLE testflow.dbo.BATCH_BUSINESS_DATE_RESULT (
                                                         BATCH_BUSINESS_DATE_RESULT_OID decimal(25,0) NOT NULL,
    [TYPE] varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    STATUS varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PREV_BUSINESS_DATE date NOT NULL,
    CREATE_BUSINESS_DATE date NOT NULL,
    SYSTEM_DATE date NOT NULL,
    CONSTRAINT BATCH_BUSINESS_DATE_RESULT_PK PRIMARY KEY (BATCH_BUSINESS_DATE_RESULT_OID)
    );


-- testflow.dbo.BPM_CATEGORY definition

-- Drop table

-- DROP TABLE testflow.dbo.BPM_CATEGORY;

CREATE TABLE testflow.dbo.BPM_CATEGORY (
                                           ID bigint IDENTITY(1,1) NOT NULL,
                                           NAME nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                           CODE nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                           DESCRIPTION nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                           STATUS tinyint DEFAULT NULL NULL,
                                           SORT int DEFAULT NULL NULL,
                                           CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                           CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                           UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                           UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                           DELETED bit DEFAULT 0 NOT NULL,
                                           TENANT_ID bigint DEFAULT 0 NOT NULL,
                                           CONSTRAINT PK__BPM_CATE__3214EC2759EC8901 PRIMARY KEY (ID)
);


-- testflow.dbo.BPM_PROCESS_DEFINITION_INFO definition

-- Drop table

-- DROP TABLE testflow.dbo.BPM_PROCESS_DEFINITION_INFO;

CREATE TABLE testflow.dbo.BPM_PROCESS_DEFINITION_INFO (
                                                          ID bigint IDENTITY(1,1) NOT NULL,
                                                          PROCESS_DEFINITION_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                          MODEL_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                          MODEL_TYPE tinyint DEFAULT 10 NOT NULL,
                                                          CATEGORY nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                          ICON nvarchar(512) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          DESCRIPTION nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          FORM_TYPE tinyint NOT NULL,
                                                          FORM_ID bigint DEFAULT NULL NULL,
                                                          FORM_CONF nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          FORM_FIELDS nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          FORM_CUSTOM_CREATE_PATH nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          FORM_CUSTOM_VIEW_PATH nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          SIMPLE_MODEL nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                          SORT bigint DEFAULT 0 NULL,
                                                          VISIBLE varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '1' NOT NULL,
                                                          START_USER_IDS nvarchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          START_DEPT_IDS nvarchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          MANAGER_USER_IDS nvarchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          ALLOW_CANCEL_RUNNING_PROCESS varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '1' NOT NULL,
                                                          PROCESS_ID_RULE nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          AUTO_APPROVAL_TYPE tinyint DEFAULT 0 NOT NULL,
                                                          TITLE_SETTING nvarchar(512) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          SUMMARY_SETTING nvarchar(512) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          PROCESS_BEFORE_TRIGGER_SETTING nvarchar(1024) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          PROCESS_AFTER_TRIGGER_SETTING nvarchar(1024) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          TASK_BEFORE_TRIGGER_SETTING nvarchar(1024) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          TASK_AFTER_TRIGGER_SETTING nvarchar(1024) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                          CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                          UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                          UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                          DELETED bit DEFAULT 0 NOT NULL,
                                                          TENANT_ID bigint DEFAULT 0 NOT NULL,
                                                          CONSTRAINT PK__BPM_PROC__3214EC277CED2397 PRIMARY KEY (ID)
);


-- testflow.dbo.BR_BENCHMARK_MODEL_INFO definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_BENCHMARK_MODEL_INFO;

CREATE TABLE testflow.dbo.BR_BENCHMARK_MODEL_INFO (
                                                      ID int IDENTITY(1,1) NOT NULL,
                                                      CREATE_TIME datetime NOT NULL,
                                                      BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [TYPE] nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CURRENCY nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PROVIDER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MODEL_FAMILY nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    VENDOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK__BR_BENCH__3214EC279375BEF8 PRIMARY KEY (ID)
    );


-- testflow.dbo.BR_BENCHMARK_MODEL_INFO_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_BENCHMARK_MODEL_INFO_1;

CREATE TABLE testflow.dbo.BR_BENCHMARK_MODEL_INFO_1 (
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


-- testflow.dbo.BR_BENCHMARK_MODEL_INFO_2 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_BENCHMARK_MODEL_INFO_2;

CREATE TABLE testflow.dbo.BR_BENCHMARK_MODEL_INFO_2 (
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


-- testflow.dbo.BR_COMPOSITE_WEIGHTS definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_COMPOSITE_WEIGHTS;

CREATE TABLE testflow.dbo.BR_COMPOSITE_WEIGHTS (
                                                   ID int IDENTITY(1,1) NOT NULL,
                                                   CREATE_TIME datetime NOT NULL,
    [DATE] datetime NULL,
                                                   BENCHMARK_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   COMPONENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   WEIGHT numeric(20,2) NULL,
                                                   CONSTRAINT PK__BR_COMPO__3214EC27CE9731C8 PRIMARY KEY (ID)
);


-- testflow.dbo.BR_COMPOSITE_WEIGHTS_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_COMPOSITE_WEIGHTS_1;

CREATE TABLE testflow.dbo.BR_COMPOSITE_WEIGHTS_1 (
                                                     ID int IDENTITY(1,1) NOT NULL,
                                                     CREATE_TIME datetime NOT NULL,
    [DATE] datetime NULL,
                                                     BENCHMARK_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     COMPONENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     WEIGHT decimal(20,2) NULL,
                                                     CONSTRAINT PK__BR_COMPO__3214EC27DA41D97D PRIMARY KEY (ID)
);


-- testflow.dbo.BR_COMPOSITE_WEIGHTS_2 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_COMPOSITE_WEIGHTS_2;

CREATE TABLE testflow.dbo.BR_COMPOSITE_WEIGHTS_2 (
                                                     ID int IDENTITY(1,1) NOT NULL,
                                                     CREATE_TIME datetime NOT NULL,
    [DATE] datetime NULL,
                                                     BENCHMARK_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     COMPONENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     WEIGHT decimal(20,2) NULL,
                                                     CONSTRAINT PK__BR_COMPO__3214EC27DA41D97D_copy1 PRIMARY KEY (ID)
);


-- testflow.dbo.BR_MODEL_INFO definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_MODEL_INFO;

CREATE TABLE testflow.dbo.BR_MODEL_INFO (
                                            ID int IDENTITY(1,1) NOT NULL,
                                            CREATE_TIME datetime NOT NULL,
                                            BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            CURRENCY nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [TYPE] nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MODEL_VIEW nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK__BR_MODEL__3214EC27830A3EC0 PRIMARY KEY (ID)
    );


-- testflow.dbo.BR_MODEL_INFO_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_MODEL_INFO_1;

CREATE TABLE testflow.dbo.BR_MODEL_INFO_1 (
                                              ID int IDENTITY(1,1) NOT NULL,
                                              CREATE_TIME datetime NOT NULL,
                                              BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              CURRENCY nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [TYPE] nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MODEL_VIEW nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK__BR_MODEL__3214EC2735F2B328 PRIMARY KEY (ID)
    );


-- testflow.dbo.BR_MODEL_INFO_2 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_MODEL_INFO_2;

CREATE TABLE testflow.dbo.BR_MODEL_INFO_2 (
                                              ID int NULL,
                                              CREATE_TIME datetime NULL,
                                              BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              CURRENCY nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [TYPE] nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    MODEL_VIEW nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    );


-- testflow.dbo.BR_MODEL_POSITION_DATA definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_MODEL_POSITION_DATA;

CREATE TABLE testflow.dbo.BR_MODEL_POSITION_DATA (
                                                     ID int IDENTITY(1,1) NOT NULL,
                                                     CREATE_TIME datetime NOT NULL,
                                                     POS_DATE datetime NULL,
                                                     PORTFOLIO_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     WEIGHT numeric(20,2) NULL,
                                                     CONSTRAINT PK__BR_MODEL__3214EC27167884F7 PRIMARY KEY (ID)
);


-- testflow.dbo.BR_MODEL_POSITION_DATA_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_MODEL_POSITION_DATA_1;

CREATE TABLE testflow.dbo.BR_MODEL_POSITION_DATA_1 (
                                                       ID int IDENTITY(1,1) NOT NULL,
                                                       CREATE_TIME datetime NOT NULL,
                                                       POS_DATE datetime NULL,
                                                       PORTFOLIO_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       WEIGHT numeric(20,2) NULL,
                                                       CONSTRAINT PK__BR_MODEL__3214EC2745B8B125 PRIMARY KEY (ID)
);


-- testflow.dbo.BR_MODEL_POSITION_DATA_2 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_MODEL_POSITION_DATA_2;

CREATE TABLE testflow.dbo.BR_MODEL_POSITION_DATA_2 (
                                                       ID int NULL,
                                                       CREATE_TIME datetime NULL,
                                                       POS_DATE datetime NULL,
                                                       PORTFOLIO_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       WEIGHT numeric(20,2) NULL
);


-- testflow.dbo.BR_SECURITY_LIST definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_LIST;

CREATE TABLE testflow.dbo.BR_SECURITY_LIST (
                                               ID int IDENTITY(1,1) NOT NULL,
                                               CREATE_TIME datetime NOT NULL,
                                               CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               LIST_TAG nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               LIST_VALUE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               CONSTRAINT PK__BR_SECUR__3214EC273673E6B1 PRIMARY KEY (ID)
);


-- testflow.dbo.BR_SECURITY_LISTS_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_LISTS_1;

CREATE TABLE testflow.dbo.BR_SECURITY_LISTS_1 (
                                                  ID int IDENTITY(1,1) NOT NULL,
                                                  CREATE_TIME datetime NOT NULL,
                                                  CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  LIST_TAG nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  LIST_VALUE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  DATA_SOURCE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  CONSTRAINT PK__BR_SECUR__3214EC2705D2AF23 PRIMARY KEY (ID)
);


-- testflow.dbo.BR_SECURITY_LISTS_2 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_LISTS_2;

CREATE TABLE testflow.dbo.BR_SECURITY_LISTS_2 (
                                                  ID int IDENTITY(1,1) NOT NULL,
                                                  CREATE_TIME datetime NOT NULL,
                                                  CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  LIST_TAG nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  LIST_VALUE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  DATA_SOURCE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  CONSTRAINT PK__BR_SECUR__3214EC2705D2AF23_copy2 PRIMARY KEY (ID)
);


-- testflow.dbo.BR_SECURITY_MASTER_BND_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_BND_1;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_BND_1 (
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


-- testflow.dbo.BR_SECURITY_MASTER_BND_2 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_BND_2;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_BND_2 (
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


-- testflow.dbo.BR_SECURITY_MASTER_CBL_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_CBL_1;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_CBL_1 (
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


-- testflow.dbo.BR_SECURITY_MASTER_COS_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_COS_1;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_COS_1 (
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


-- testflow.dbo.BR_SECURITY_MASTER_COS_2 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_COS_2;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_COS_2 (
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


-- testflow.dbo.BR_SECURITY_MASTER_FMS_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_FMS_1;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_FMS_1 (
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


-- testflow.dbo.BR_SECURITY_MASTER_FMS_2 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_FMS_2;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_FMS_2 (
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


-- testflow.dbo.BR_SECURITY_MASTER_MRG_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_MRG_1;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_MRG_1 (
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


-- testflow.dbo.BR_SECURITY_MASTER_MRG_2 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_MRG_2;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_MRG_2 (
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


-- testflow.dbo.BR_SECURITY_MASTER_MTC_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_MTC_1;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_MTC_1 (
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


-- testflow.dbo.BR_SECURITY_MASTER_MTC_2 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_MTC_2;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_MTC_2 (
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


-- testflow.dbo.BR_SECURITY_MASTER_PDS_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_PDS_1;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_PDS_1 (
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


-- testflow.dbo.BR_SECURITY_MASTER_PDS_2 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_PDS_2;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_PDS_2 (
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


-- testflow.dbo.BR_SECURITY_MASTER_PVB_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_PVB_1;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_PVB_1 (
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


-- testflow.dbo.BR_SECURITY_MASTER_PVB_2 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_PVB_2;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_PVB_2 (
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


-- testflow.dbo.BR_SECURITY_MASTER_SMS_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_SMS_1;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_SMS_1 (
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


-- testflow.dbo.BR_SECURITY_MASTER_SMS_2 definition

-- Drop table

-- DROP TABLE testflow.dbo.BR_SECURITY_MASTER_SMS_2;

CREATE TABLE testflow.dbo.BR_SECURITY_MASTER_SMS_2 (
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


-- testflow.dbo.FLW_CHANNEL_DEFINITION definition

-- Drop table

-- DROP TABLE testflow.dbo.FLW_CHANNEL_DEFINITION;

CREATE TABLE testflow.dbo.FLW_CHANNEL_DEFINITION (
                                                     ID_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                     NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     VERSION_ int NULL,
                                                     KEY_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     CATEGORY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     DEPLOYMENT_ID_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     CREATE_TIME_ datetime NULL,
                                                     TENANT_ID_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     RESOURCE_NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     DESCRIPTION_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     TYPE_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     IMPLEMENTATION_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                     CONSTRAINT PK_FLW_CHANNEL_DEFINITION PRIMARY KEY (ID_)
);
CREATE  UNIQUE NONCLUSTERED INDEX ACT_IDX_CHANNEL_DEF_UNIQ ON dbo.FLW_CHANNEL_DEFINITION (  KEY_ ASC  , VERSION_ ASC  , TENANT_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.FLW_EVENT_DEFINITION definition

-- Drop table

-- DROP TABLE testflow.dbo.FLW_EVENT_DEFINITION;

CREATE TABLE testflow.dbo.FLW_EVENT_DEFINITION (
                                                   ID_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   VERSION_ int NULL,
                                                   KEY_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   CATEGORY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   DEPLOYMENT_ID_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   TENANT_ID_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   RESOURCE_NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   DESCRIPTION_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   CONSTRAINT PK_FLW_EVENT_DEFINITION PRIMARY KEY (ID_)
);
CREATE  UNIQUE NONCLUSTERED INDEX ACT_IDX_EVENT_DEF_UNIQ ON dbo.FLW_EVENT_DEFINITION (  KEY_ ASC  , VERSION_ ASC  , TENANT_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.FLW_EVENT_DEPLOYMENT definition

-- Drop table

-- DROP TABLE testflow.dbo.FLW_EVENT_DEPLOYMENT;

CREATE TABLE testflow.dbo.FLW_EVENT_DEPLOYMENT (
                                                   ID_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   CATEGORY_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   DEPLOY_TIME_ datetime NULL,
                                                   TENANT_ID_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   PARENT_DEPLOYMENT_ID_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   CONSTRAINT PK_FLW_EVENT_DEPLOYMENT PRIMARY KEY (ID_)
);


-- testflow.dbo.FLW_EVENT_RESOURCE definition

-- Drop table

-- DROP TABLE testflow.dbo.FLW_EVENT_RESOURCE;

CREATE TABLE testflow.dbo.FLW_EVENT_RESOURCE (
                                                 ID_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                 NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                 DEPLOYMENT_ID_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                 RESOURCE_BYTES_ varbinary(MAX) NULL,
                                                 CONSTRAINT PK_FLW_EVENT_RESOURCE PRIMARY KEY (ID_)
);


-- testflow.dbo.FLW_EV_DATABASECHANGELOG definition

-- Drop table

-- DROP TABLE testflow.dbo.FLW_EV_DATABASECHANGELOG;

CREATE TABLE testflow.dbo.FLW_EV_DATABASECHANGELOG (
                                                       ID nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                       AUTHOR nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                       FILENAME nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                       DATEEXECUTED datetime2(3) NOT NULL,
                                                       ORDEREXECUTED int NOT NULL,
                                                       EXECTYPE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                       MD5SUM nvarchar(35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       DESCRIPTION nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       COMMENTS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       TAG nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       LIQUIBASE nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       CONTEXTS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       LABELS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                       DEPLOYMENT_ID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
);


-- testflow.dbo.FLW_EV_DATABASECHANGELOGLOCK definition

-- Drop table

-- DROP TABLE testflow.dbo.FLW_EV_DATABASECHANGELOGLOCK;

CREATE TABLE testflow.dbo.FLW_EV_DATABASECHANGELOGLOCK (
                                                           ID int NOT NULL,
                                                           LOCKED bit NOT NULL,
                                                           LOCKGRANTED datetime2(3) NULL,
                                                           LOCKEDBY nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                           CONSTRAINT PK_FLW_EV_DATABASECHANGELOGLOCK PRIMARY KEY (ID)
);


-- testflow.dbo.FLW_RU_BATCH definition

-- Drop table

-- DROP TABLE testflow.dbo.FLW_RU_BATCH;

CREATE TABLE testflow.dbo.FLW_RU_BATCH (
                                           ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                           REV_ int NULL,
                                           TYPE_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                           SEARCH_KEY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           SEARCH_KEY2_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           CREATE_TIME_ datetime NOT NULL,
                                           COMPLETE_TIME_ datetime NULL,
                                           STATUS_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           BATCH_DOC_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                           CONSTRAINT PK__FLW_RU_B__C4971C0F813D1503 PRIMARY KEY (ID_)
);


-- testflow.dbo.IHUB_ALTERNATIVES_MTA definition

-- Drop table

-- DROP TABLE testflow.dbo.IHUB_ALTERNATIVES_MTA;

CREATE TABLE testflow.dbo.IHUB_ALTERNATIVES_MTA (
                                                    ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                    HISTORY_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    PROCESS_INSTANCE_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                    ASSET_TYPE nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    PRODUCT_CODE nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    ISIN nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    TICKER nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    ATTR_NAME nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    PROXY_ASSET_CLASS nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    APPROVAL_STATUS char(1) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '2' NOT NULL,
                                                    BIZ_STATUS char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    MAKER nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                    MAKER_DATETIME datetime DEFAULT NULL NULL,
                                                    MAKER_BUSINESS_DATE datetime NULL,
                                                    CHECKER nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                    CHECKER_DATETIME datetime DEFAULT NULL NULL,
                                                    CHECKER_BUSINESS_DATE datetime DEFAULT NULL NULL,
                                                    VERSION int DEFAULT 0 NULL,
                                                    VALID_START_DATETIME datetime DEFAULT NULL NULL,
                                                    VALID_END_DATETIME datetime DEFAULT NULL NULL,
                                                    DEL_FLAG tinyint DEFAULT 0 NULL,
                                                    EDIT_FLAG tinyint DEFAULT 0 NULL,
                                                    CLIENT_ID nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    CONSTRAINT PK__IHUB_ALT__3214EC2754728E63 PRIMARY KEY (ID)
);


-- testflow.dbo.IHUB_ASSET_CLASSIFICATION_MTA definition

-- Drop table

-- DROP TABLE testflow.dbo.IHUB_ASSET_CLASSIFICATION_MTA;

CREATE TABLE testflow.dbo.IHUB_ASSET_CLASSIFICATION_MTA (
                                                            ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                            PROCESS_INSTANCE_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                            ASSET_TYPE nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            BUSINESS_TYPE tinyint NULL,
                                                            PRODUCT_CODE nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            ISIN nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            TICKER nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            ATTR_NAME nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            ISSUER nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            CLASSIFICATION_LEVEL1 nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            CLASSIFICATION_LEVEL2 nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            CLASSIFICATION_LEVEL3 nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            APPROVAL_STATUS char(1) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '2' NOT NULL,
                                                            BIZ_STATUS char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            MAKER nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                            MAKER_DATETIME datetime DEFAULT NULL NULL,
                                                            MAKER_BUSINESS_DATE datetime NULL,
                                                            CHECKER nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                            CHECKER_DATETIME datetime DEFAULT NULL NULL,
                                                            CHECKER_BUSINESS_DATE datetime DEFAULT NULL NULL,
                                                            VERSION int DEFAULT 0 NULL,
                                                            VALID_START_DATETIME datetime DEFAULT NULL NULL,
                                                            VALID_END_DATETIME datetime DEFAULT NULL NULL,
                                                            DEL_FLAG tinyint DEFAULT 0 NULL,
                                                            EDIT_FLAG tinyint DEFAULT 0 NULL,
                                                            HISTORY_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            NEW_CLASSIFICATION_LEVEL1 nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            NEW_CLASSIFICATION_LEVEL2 nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            NEW_CLASSIFICATION_LEVEL3 nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            CLIENT_ID nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                            CONSTRAINT PK__IHUB_ASS__3214EC276DA6AC52 PRIMARY KEY (ID)
);


-- testflow.dbo.IHUB_ASSET_TYPE definition

-- Drop table

-- DROP TABLE testflow.dbo.IHUB_ASSET_TYPE;

CREATE TABLE testflow.dbo.IHUB_ASSET_TYPE (
                                              ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                              ASSET_TYPE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                              SYSTEM_CODE nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                              BUY_LIST char(1) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                              HOUSE_VIEW_LIST char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              CONDITION_SQL nvarchar(512) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                              FIELD nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                              CUSTOMER_TIER_ID char(1) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                              ASSETCLASSIFICATION char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              CONSTRAINT PK__IHUB_ASS__3214EC276835C609 PRIMARY KEY (ID)
);


-- testflow.dbo.IHUB_BENCHMARK definition

-- Drop table

-- DROP TABLE testflow.dbo.IHUB_BENCHMARK;

CREATE TABLE testflow.dbo.IHUB_BENCHMARK (
                                             ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                             PROCESS_INSTANCE_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                             NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                             APPROVAL_STATUS tinyint DEFAULT 2 NOT NULL,
                                             BUSINESS_TYPE tinyint DEFAULT NULL NULL,
                                             BENCHMARK_TYPE tinyint DEFAULT NULL NULL,
                                             MAKER nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                             MAKER_DATETIME datetime DEFAULT getdate() NULL,
                                             MAKER_BUSINESS_DATE datetime DEFAULT NULL NULL,
                                             CHECKER nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                             CHECKER_DATETIME datetime DEFAULT NULL NULL,
                                             CHECKER_BUSINESS_DATE datetime DEFAULT NULL NULL,
                                             RECORD_VERSION int DEFAULT 0 NULL,
                                             VALID_START_DATETIME datetime DEFAULT getdate() NULL,
                                             VALID_END_DATETIME datetime DEFAULT NULL NULL,
                                             DEL_FLAG tinyint DEFAULT 0 NULL,
                                             BIZ_STATUS tinyint NULL,
                                             HISTORY_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                             EDIT_FLAG tinyint DEFAULT 0 NULL,
                                             CONSTRAINT PK__IHUB_BEN__3214EC27EA9CE9EE PRIMARY KEY (ID)
);


-- testflow.dbo.IHUB_BENCHMARK_DETAILS definition

-- Drop table

-- DROP TABLE testflow.dbo.IHUB_BENCHMARK_DETAILS;

CREATE TABLE testflow.dbo.IHUB_BENCHMARK_DETAILS (
                                                     ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                     BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                     BENCHMARK_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                     PARENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                     ASSET_CLASSIFICATION nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                     ASSET_LEVEL tinyint DEFAULT NULL NULL,
                                                     WEIGHT numeric(20,2) DEFAULT NULL NULL,
                                                     RECORD_VERSION int DEFAULT 0 NULL,
                                                     SORT_ORDER int DEFAULT 0 NULL,
                                                     CONSTRAINT PK__IHUB_BEN__3214EC272A550848 PRIMARY KEY (ID)
);


-- testflow.dbo.IHUB_BENCHMARK_GROUPING definition

-- Drop table

-- DROP TABLE testflow.dbo.IHUB_BENCHMARK_GROUPING;

CREATE TABLE testflow.dbo.IHUB_BENCHMARK_GROUPING (
                                                      ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                      COMPONENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                      PARENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                      COMPONENT_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                      DESCRIPTION nvarchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                      ASSET_LEVEL tinyint NOT NULL,
                                                      SORT_ORDER int DEFAULT 0 NULL,
                                                      CONSTRAINT PK__IHUB_BEN__3214EC27AAA80327 PRIMARY KEY (ID),
                                                      CONSTRAINT UK_component_id UNIQUE (COMPONENT_ID)
);


-- testflow.dbo.IHUB_BUY_LIST definition

-- Drop table

-- DROP TABLE testflow.dbo.IHUB_BUY_LIST;

CREATE TABLE testflow.dbo.IHUB_BUY_LIST (
                                            ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                            BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                            NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                            BUSINESS_TYPE tinyint DEFAULT NULL NULL,
                                            PROCESS_INSTANCE_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                            APPROVAL_STATUS tinyint DEFAULT 2 NOT NULL,
                                            MAKER nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                            MAKER_DATETIME datetime DEFAULT NULL NULL,
                                            MAKER_BUSINESS_DATE datetime DEFAULT NULL NULL,
                                            CHECKER nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                            CHECKER_DATETIME datetime DEFAULT NULL NULL,
                                            CHECKER_BUSINESS_DATE datetime DEFAULT NULL NULL,
                                            RECORD_VERSION int DEFAULT 0 NULL,
                                            VALID_START_DATETIME datetime DEFAULT getdate() NOT NULL,
                                            VALID_END_DATETIME datetime DEFAULT NULL NULL,
                                            DEL_FLAG tinyint DEFAULT 0 NULL,
                                            BIZ_STATUS tinyint DEFAULT 0 NULL,
                                            HISTORY_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                            EDIT_FLAG tinyint DEFAULT 0 NULL,
                                            CONSTRAINT PK__IHUB_BUY__3214EC279E20DC18 PRIMARY KEY (ID)
);


-- testflow.dbo.IHUB_BUY_LIST_DETAILS definition

-- Drop table

-- DROP TABLE testflow.dbo.IHUB_BUY_LIST_DETAILS;

CREATE TABLE testflow.dbo.IHUB_BUY_LIST_DETAILS (
                                                    ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                    BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                    BUY_LIST_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                    RECORD_VERSION int DEFAULT 0 NULL,
                                                    ASSET_TYPE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                    PRODUCT_CODE nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                    CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                    CONSTRAINT PK__IHUB_BUY__3214EC272C1F6C67 PRIMARY KEY (ID)
);


-- testflow.dbo.IHUB_HOUSE_VIEW_LIST definition

-- Drop table

-- DROP TABLE testflow.dbo.IHUB_HOUSE_VIEW_LIST;

CREATE TABLE testflow.dbo.IHUB_HOUSE_VIEW_LIST (
                                                   ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                   BUSINESS_TYPE tinyint DEFAULT NULL NULL,
                                                   PROCESS_INSTANCE_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                   APPROVAL_STATUS tinyint DEFAULT 2 NOT NULL,
                                                   MAKER nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                   MAKER_DATETIME datetime DEFAULT NULL NULL,
                                                   MAKER_BUSINESS_DATE datetime DEFAULT NULL NULL,
                                                   CHECKER nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                   CHECKER_DATETIME datetime DEFAULT NULL NULL,
                                                   CHECKER_BUSINESS_DATE datetime DEFAULT NULL NULL,
                                                   RECORD_VERSION int DEFAULT 0 NULL,
                                                   VALID_START_DATETIME datetime DEFAULT NULL NULL,
                                                   VALID_END_DATETIME datetime DEFAULT NULL NULL,
                                                   DEL_FLAG tinyint DEFAULT 0 NULL,
                                                   BIZ_STATUS tinyint DEFAULT 0 NULL,
                                                   HISTORY_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                   EDIT_FLAG tinyint DEFAULT 0 NULL,
                                                   CONSTRAINT PK__IHUB_HOU__3214EC27536602A0 PRIMARY KEY (ID)
);


-- testflow.dbo.IHUB_HOUSE_VIEW_LIST_DETAILS definition

-- Drop table

-- DROP TABLE testflow.dbo.IHUB_HOUSE_VIEW_LIST_DETAILS;

CREATE TABLE testflow.dbo.IHUB_HOUSE_VIEW_LIST_DETAILS (
                                                           ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                           BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                           HOUSE_VIEW_LIST_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                           RECORD_VERSION int DEFAULT 0 NULL,
                                                           ASSET_TYPE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                           PRODUCT_CODE nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                           CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                           VALUE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                           CONSTRAINT PK__IHUB_HOU__3214EC27CFA1B1DD PRIMARY KEY (ID)
);


-- testflow.dbo.IHUB_MODEL_PORTFOLIO definition

-- Drop table

-- DROP TABLE testflow.dbo.IHUB_MODEL_PORTFOLIO;

CREATE TABLE testflow.dbo.IHUB_MODEL_PORTFOLIO (
                                                   ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   PROCESS_INSTANCE_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                   NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                   APPROVAL_STATUS tinyint DEFAULT 2 NOT NULL,
                                                   BUSINESS_TYPE tinyint DEFAULT NULL NULL,
                                                   MAKER nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                   MAKER_DATETIME datetime DEFAULT getdate() NULL,
                                                   MAKER_BUSINESS_DATE datetime DEFAULT NULL NULL,
                                                   CHECKER nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                   CHECKER_DATETIME datetime DEFAULT NULL NULL,
                                                   CHECKER_BUSINESS_DATE datetime DEFAULT NULL NULL,
                                                   RECORD_VERSION int DEFAULT 0 NULL,
                                                   VALID_START_DATETIME datetime DEFAULT getdate() NOT NULL,
                                                   VALID_END_DATETIME datetime DEFAULT NULL NULL,
                                                   DEL_FLAG tinyint DEFAULT 0 NULL,
                                                   BIZ_STATUS tinyint DEFAULT NULL NULL,
                                                   HISTORY_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                   EDIT_FLAG tinyint DEFAULT NULL NULL,
                                                   CONSTRAINT PK__IHUB_MOD__3214EC27C5A8430A PRIMARY KEY (ID)
);


-- testflow.dbo.IHUB_MODEL_PORTFOLIO_DETAILS definition

-- Drop table

-- DROP TABLE testflow.dbo.IHUB_MODEL_PORTFOLIO_DETAILS;

CREATE TABLE testflow.dbo.IHUB_MODEL_PORTFOLIO_DETAILS (
                                                           ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                           BUSINESS_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                           MODEL_PORTFOLIO_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                           ASSET_TYPE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                           PRODUCT_CODE nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                           ASSET_WEIGHT numeric(20,2) DEFAULT NULL NULL,
                                                           PRODUCT_WEIGHT numeric(20,2) DEFAULT NULL NULL,
                                                           RECORD_VERSION int DEFAULT 0 NULL,
                                                           CLIENT_ID nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                           CONSTRAINT PK__IHUB_MOD__3214EC27F7063ECE PRIMARY KEY (ID)
);


-- testflow.dbo.INFRA_API_ACCESS_LOG definition

-- Drop table

-- DROP TABLE testflow.dbo.INFRA_API_ACCESS_LOG;

CREATE TABLE testflow.dbo.INFRA_API_ACCESS_LOG (
                                                   ID bigint IDENTITY(1,1) NOT NULL,
                                                   TRACE_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                                   USER_ID bigint DEFAULT '0' NOT NULL,
                                                   USER_TYPE tinyint DEFAULT '0' NOT NULL,
                                                   APPLICATION_NAME nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   REQUEST_METHOD nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                                   REQUEST_URL nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                                   REQUEST_PARAMS nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   RESPONSE_BODY nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   USER_IP nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   USER_AGENT nvarchar(512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   OPERATE_MODULE nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                   OPERATE_NAME nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                   OPERATE_TYPE tinyint DEFAULT '0' NULL,
                                                   BEGIN_TIME datetime2 NOT NULL,
                                                   END_TIME datetime2 NOT NULL,
                                                   DURATION int NOT NULL,
                                                   RESULT_CODE int DEFAULT '0' NOT NULL,
                                                   RESULT_MSG nvarchar(512) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                   CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                   CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                   UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                   UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                   DELETED bit DEFAULT 0 NOT NULL,
                                                   CONSTRAINT PK__INFRA_AP__3214EC276925EA57 PRIMARY KEY (ID)
);
CREATE NONCLUSTERED INDEX IDX_INFRA_API_ACCESS_LOG_01 ON dbo.INFRA_API_ACCESS_LOG (  CREATE_TIME ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.INFRA_API_ERROR_LOG definition

-- Drop table

-- DROP TABLE testflow.dbo.INFRA_API_ERROR_LOG;

CREATE TABLE testflow.dbo.INFRA_API_ERROR_LOG (
                                                  ID bigint IDENTITY(1,1) NOT NULL,
                                                  TRACE_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  USER_ID bigint DEFAULT '0' NOT NULL,
                                                  USER_TYPE tinyint DEFAULT '0' NOT NULL,
                                                  APPLICATION_NAME nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  REQUEST_METHOD nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  REQUEST_URL nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  REQUEST_PARAMS nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  USER_IP nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  USER_AGENT nvarchar(512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  EXCEPTION_TIME datetime2 NOT NULL,
                                                  EXCEPTION_NAME nvarchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                                  EXCEPTION_MESSAGE nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  EXCEPTION_ROOT_CAUSE_MESSAGE nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  EXCEPTION_STACK_TRACE nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  EXCEPTION_CLASS_NAME nvarchar(512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  EXCEPTION_FILE_NAME nvarchar(512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  EXCEPTION_METHOD_NAME nvarchar(512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  EXCEPTION_LINE_NUMBER int NOT NULL,
                                                  PROCESS_STATUS tinyint NOT NULL,
                                                  PROCESS_TIME datetime2 DEFAULT NULL NULL,
                                                  PROCESS_USER_ID int DEFAULT '0' NULL,
                                                  CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                  CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                  UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                  UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                  DELETED bit DEFAULT 0 NOT NULL,
                                                  CONSTRAINT PK__INFRA_AP__3214EC27A7FCB397 PRIMARY KEY (ID)
);


-- testflow.dbo.INFRA_CODEGEN_COLUMN definition

-- Drop table

-- DROP TABLE testflow.dbo.INFRA_CODEGEN_COLUMN;

CREATE TABLE testflow.dbo.INFRA_CODEGEN_COLUMN (
                                                   ID bigint IDENTITY(1,1) NOT NULL,
                                                   TABLE_ID bigint NOT NULL,
                                                   COLUMN_NAME nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   DATA_TYPE nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   COLUMN_COMMENT nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   NULLABLE varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   PRIMARY_KEY varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   ORDINAL_POSITION int NOT NULL,
                                                   JAVA_TYPE nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   JAVA_FIELD nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   DICT_TYPE nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                   EXAMPLE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                   CREATE_OPERATION varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   UPDATE_OPERATION varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   LIST_OPERATION varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   LIST_OPERATION_CONDITION nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '=' NOT NULL,
                                                   LIST_OPERATION_RESULT varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   HTML_TYPE nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                   CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                   UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                   UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                   DELETED bit DEFAULT 0 NOT NULL,
                                                   CONSTRAINT PK__INFRA_CO__3214EC27C658D317 PRIMARY KEY (ID)
);


-- testflow.dbo.INFRA_CODEGEN_TABLE definition

-- Drop table

-- DROP TABLE testflow.dbo.INFRA_CODEGEN_TABLE;

CREATE TABLE testflow.dbo.INFRA_CODEGEN_TABLE (
                                                  ID bigint IDENTITY(1,1) NOT NULL,
                                                  DATA_SOURCE_CONFIG_ID bigint NOT NULL,
                                                  SCENE tinyint DEFAULT '1' NOT NULL,
                                                  TABLE_NAME nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                                  TABLE_COMMENT nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                                  REMARK nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                  MODULE_NAME nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  BUSINESS_NAME nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  CLASS_NAME nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                                  CLASS_COMMENT nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  AUTHOR nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  TEMPLATE_TYPE tinyint DEFAULT '1' NOT NULL,
                                                  FRONT_TYPE tinyint NOT NULL,
                                                  PARENT_MENU_ID bigint DEFAULT NULL NULL,
                                                  MASTER_TABLE_ID bigint DEFAULT NULL NULL,
                                                  SUB_JOIN_COLUMN_ID bigint DEFAULT NULL NULL,
                                                  SUB_JOIN_MANY varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                  TREE_PARENT_COLUMN_ID bigint DEFAULT NULL NULL,
                                                  TREE_NAME_COLUMN_ID bigint DEFAULT NULL NULL,
                                                  CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                  CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                  UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                  UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                  DELETED bit DEFAULT 0 NOT NULL,
                                                  CONSTRAINT PK__INFRA_CO__3214EC274BA89B65 PRIMARY KEY (ID)
);


-- testflow.dbo.INFRA_CONFIG definition

-- Drop table

-- DROP TABLE testflow.dbo.INFRA_CONFIG;

CREATE TABLE testflow.dbo.INFRA_CONFIG (
                                           ID bigint IDENTITY(1,1) NOT NULL,
                                           CATEGORY nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TYPE] tinyint NOT NULL,
                                           NAME nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                           CONFIG_KEY nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                           VALUE nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                           VISIBLE varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                           REMARK nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                           CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                           CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                           UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                           UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                           DELETED bit DEFAULT 0 NOT NULL,
                                           CONSTRAINT PK__INFRA_CO__3214EC2713D4F076 PRIMARY KEY (ID)
);


-- testflow.dbo.INFRA_DATA_SOURCE_CONFIG definition

-- Drop table

-- DROP TABLE testflow.dbo.INFRA_DATA_SOURCE_CONFIG;

CREATE TABLE testflow.dbo.INFRA_DATA_SOURCE_CONFIG (
                                                       ID bigint IDENTITY(1,1) NOT NULL,
                                                       NAME nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                                       URL nvarchar(1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                       USERNAME nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                       PASSWORD nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                                       CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                       CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                       UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                       UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                       DELETED bit DEFAULT 0 NOT NULL,
                                                       CONSTRAINT PK__INFRA_DA__3214EC271EBC2FEB PRIMARY KEY (ID)
);


-- testflow.dbo.INFRA_JOB definition

-- Drop table

-- DROP TABLE testflow.dbo.INFRA_JOB;

CREATE TABLE testflow.dbo.INFRA_JOB (
                                        ID bigint IDENTITY(1,1) NOT NULL,
                                        NAME nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                        STATUS tinyint NOT NULL,
                                        HANDLER_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                        HANDLER_PARAM nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                        CRON_EXPRESSION nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                        RETRY_COUNT int DEFAULT '0' NOT NULL,
                                        RETRY_INTERVAL int DEFAULT '0' NOT NULL,
                                        MONITOR_TIMEOUT int DEFAULT '0' NOT NULL,
                                        CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                        CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                        UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                        UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                        DELETED bit DEFAULT 0 NOT NULL,
                                        CONSTRAINT PK__INFRA_JO__3214EC276CB48C12 PRIMARY KEY (ID)
);


-- testflow.dbo.INFRA_JOB_LOG definition

-- Drop table

-- DROP TABLE testflow.dbo.INFRA_JOB_LOG;

CREATE TABLE testflow.dbo.INFRA_JOB_LOG (
                                            ID bigint IDENTITY(1,1) NOT NULL,
                                            JOB_ID bigint NOT NULL,
                                            HANDLER_NAME nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                            HANDLER_PARAM nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                            EXECUTE_INDEX tinyint DEFAULT '1' NOT NULL,
                                            BEGIN_TIME datetime2 NOT NULL,
                                            END_TIME datetime2 DEFAULT NULL NULL,
                                            DURATION int DEFAULT NULL NULL,
                                            STATUS tinyint NOT NULL,
    [RESULT] nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
    CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
    CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
    UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
    UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
    DELETED bit DEFAULT 0 NOT NULL,
    CONSTRAINT PK__INFRA_JO__3214EC27B7856B16 PRIMARY KEY (ID)
    );


-- testflow.dbo.SYSTEM_DEPT definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_DEPT;

CREATE TABLE testflow.dbo.SYSTEM_DEPT (
                                          ID bigint IDENTITY(1,1) NOT NULL,
                                          NAME nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                          PARENT_ID bigint DEFAULT '0' NOT NULL,
                                          SORT int DEFAULT '0' NOT NULL,
                                          LEADER_USER_ID bigint DEFAULT NULL NULL,
                                          PHONE nvarchar(11) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                          EMAIL nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                          STATUS tinyint NOT NULL,
                                          CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                          CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                          UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                          UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                          DELETED bit DEFAULT 0 NOT NULL,
                                          CONSTRAINT PK__SYSTEM_D__3214EC27B0255D06 PRIMARY KEY (ID)
);


-- testflow.dbo.SYSTEM_DICT_DATA definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_DICT_DATA;

CREATE TABLE testflow.dbo.SYSTEM_DICT_DATA (
                                               ID bigint IDENTITY(1,1) NOT NULL,
                                               SORT int DEFAULT '0' NOT NULL,
                                               LABEL nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                               VALUE nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                               DICT_TYPE nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                               STATUS tinyint DEFAULT '0' NOT NULL,
                                               COLOR_TYPE nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                               CSS_CLASS nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                               REMARK nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                               CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                               CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                               UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                               UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                               DELETED bit DEFAULT 0 NOT NULL,
                                               CONSTRAINT PK__SYSTEM_D__3214EC2765673859 PRIMARY KEY (ID)
);


-- testflow.dbo.SYSTEM_DICT_TYPE definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_DICT_TYPE;

CREATE TABLE testflow.dbo.SYSTEM_DICT_TYPE (
                                               ID bigint IDENTITY(1,1) NOT NULL,
                                               NAME nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
    [TYPE] nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
    STATUS tinyint DEFAULT '0' NOT NULL,
    REMARK nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
    CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
    CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
    UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
    UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
    DELETED bit DEFAULT 0 NOT NULL,
    DELETED_TIME datetime2 DEFAULT NULL NULL,
    CONSTRAINT PK__SYSTEM_D__3214EC278F7FB922 PRIMARY KEY (ID)
    );


-- testflow.dbo.SYSTEM_LOGIN_LOG definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_LOGIN_LOG;

CREATE TABLE testflow.dbo.SYSTEM_LOGIN_LOG (
                                               ID bigint IDENTITY(1,1) NOT NULL,
                                               LOG_TYPE bigint NOT NULL,
                                               TRACE_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                               USER_ID bigint DEFAULT '0' NOT NULL,
                                               USER_TYPE tinyint DEFAULT '0' NOT NULL,
                                               USERNAME nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
    [RESULT] tinyint NOT NULL,
                                               USER_IP nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                               USER_AGENT nvarchar(512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                               CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                               CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                               UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                               UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                               DELETED bit DEFAULT 0 NOT NULL,
                                               TENANT_ID bigint DEFAULT '0' NOT NULL,
                                               CONSTRAINT PK__SYSTEM_L__3214EC27BEAE7BBB PRIMARY KEY (ID)
);


-- testflow.dbo.SYSTEM_MENU definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_MENU;

CREATE TABLE testflow.dbo.SYSTEM_MENU (
                                          ID bigint IDENTITY(1,1) NOT NULL,
                                          NAME nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                          PERMISSION nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
    [TYPE] tinyint NOT NULL,
                                          SORT int DEFAULT '0' NOT NULL,
                                          PARENT_ID bigint DEFAULT '0' NOT NULL,
    [PATH] nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
    ICON nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '#' NULL,
    COMPONENT nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
    COMPONENT_NAME nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
    STATUS tinyint DEFAULT '0' NOT NULL,
    VISIBLE varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '1' NOT NULL,
    KEEP_ALIVE varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '1' NOT NULL,
    ALWAYS_SHOW varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '1' NOT NULL,
    CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
    CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
    UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
    UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
    DELETED bit DEFAULT 0 NOT NULL,
    CONSTRAINT PK__SYSTEM_M__3214EC270DBE989A PRIMARY KEY (ID)
    );


-- testflow.dbo.SYSTEM_NOTIFY_MESSAGE definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_NOTIFY_MESSAGE;

CREATE TABLE testflow.dbo.SYSTEM_NOTIFY_MESSAGE (
                                                    ID bigint IDENTITY(1,1) NOT NULL,
                                                    USER_ID bigint NOT NULL,
                                                    USER_TYPE tinyint NOT NULL,
                                                    TEMPLATE_ID bigint NOT NULL,
                                                    TEMPLATE_CODE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                    TEMPLATE_NICKNAME nvarchar(63) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                    TEMPLATE_CONTENT nvarchar(1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                    TEMPLATE_TYPE int NOT NULL,
                                                    TEMPLATE_PARAMS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                    READ_STATUS varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                    READ_TIME datetime2 DEFAULT NULL NULL,
                                                    CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                    CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                    UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                    UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                    DELETED bit DEFAULT 0 NOT NULL,
                                                    TENANT_ID bigint DEFAULT 0 NOT NULL,
                                                    CONSTRAINT PK__SYSTEM_N__3214EC279F33CA9B PRIMARY KEY (ID)
);


-- testflow.dbo.SYSTEM_NOTIFY_TEMPLATE definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_NOTIFY_TEMPLATE;

CREATE TABLE testflow.dbo.SYSTEM_NOTIFY_TEMPLATE (
                                                     ID bigint IDENTITY(1,1) NOT NULL,
                                                     NAME nvarchar(63) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                     CODE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                     NICKNAME nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                     CONTENT nvarchar(1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TYPE] tinyint NOT NULL,
                                                     PARAMS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                     STATUS tinyint NOT NULL,
                                                     REMARK nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                     CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                     CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                     UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                     UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                     DELETED bit DEFAULT 0 NOT NULL,
                                                     CONSTRAINT PK__SYSTEM_N__3214EC27012289EE PRIMARY KEY (ID)
);


-- testflow.dbo.SYSTEM_OAUTH2_ACCESS_TOKEN definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_OAUTH2_ACCESS_TOKEN;

CREATE TABLE testflow.dbo.SYSTEM_OAUTH2_ACCESS_TOKEN (
                                                         ID bigint IDENTITY(1,1) NOT NULL,
                                                         USER_ID bigint NOT NULL,
                                                         USER_TYPE tinyint NOT NULL,
                                                         USER_INFO nvarchar(512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                         ACCESS_TOKEN nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                         REFRESH_TOKEN nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                         CLIENT_ID nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                         SCOPES nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                         EXPIRES_TIME datetime2 NOT NULL,
                                                         CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                         CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                         UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                         UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                         DELETED bit DEFAULT 0 NOT NULL,
                                                         CONSTRAINT PK__SYSTEM_O__3214EC27A84F1770 PRIMARY KEY (ID)
);
CREATE NONCLUSTERED INDEX IDX_SYSTEM_OAUTH2_ACCESS_TOKEN_01 ON dbo.SYSTEM_OAUTH2_ACCESS_TOKEN (  ACCESS_TOKEN ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IDX_SYSTEM_OAUTH2_ACCESS_TOKEN_02 ON dbo.SYSTEM_OAUTH2_ACCESS_TOKEN (  REFRESH_TOKEN ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.SYSTEM_OAUTH2_REFRESH_TOKEN definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_OAUTH2_REFRESH_TOKEN;

CREATE TABLE testflow.dbo.SYSTEM_OAUTH2_REFRESH_TOKEN (
                                                          ID bigint IDENTITY(1,1) NOT NULL,
                                                          USER_ID bigint NOT NULL,
                                                          REFRESH_TOKEN nvarchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                          USER_TYPE tinyint NOT NULL,
                                                          CLIENT_ID nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                          SCOPES nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                                          EXPIRES_TIME datetime2 NOT NULL,
                                                          CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                          CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                          UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                          UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                                          DELETED bit DEFAULT 0 NOT NULL,
                                                          CONSTRAINT PK__SYSTEM_O__3214EC2763D7526B PRIMARY KEY (ID)
);


-- testflow.dbo.SYSTEM_OPERATE_LOG definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_OPERATE_LOG;

CREATE TABLE testflow.dbo.SYSTEM_OPERATE_LOG (
                                                 ID bigint IDENTITY(1,1) NOT NULL,
                                                 TRACE_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                                 USER_ID bigint NOT NULL,
                                                 USER_TYPE tinyint DEFAULT '0' NOT NULL,
    [TYPE] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    SUB_TYPE nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    BIZ_ID bigint NOT NULL,
    [ACTION] nvarchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
    SUCCESS varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '1' NOT NULL,
    EXTRA nvarchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
    REQUEST_METHOD nvarchar(16) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
    REQUEST_URL nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
    USER_IP nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
    USER_AGENT nvarchar(512) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
    CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
    CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
    UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
    UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
    DELETED bit DEFAULT 0 NOT NULL,
    CONSTRAINT PK__SYSTEM_O__3214EC270BBC26FA PRIMARY KEY (ID)
    );


-- testflow.dbo.SYSTEM_POST definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_POST;

CREATE TABLE testflow.dbo.SYSTEM_POST (
                                          ID bigint IDENTITY(1,1) NOT NULL,
                                          CODE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                          NAME nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                          SORT int NOT NULL,
                                          STATUS tinyint NOT NULL,
                                          REMARK nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                          CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                          CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                          UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                          UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                          DELETED bit DEFAULT 0 NOT NULL,
                                          CONSTRAINT PK__SYSTEM_P__3214EC27B2EAA15F PRIMARY KEY (ID)
);


-- testflow.dbo.SYSTEM_ROLE definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_ROLE;

CREATE TABLE testflow.dbo.SYSTEM_ROLE (
                                          ID bigint IDENTITY(1,1) NOT NULL,
                                          NAME nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                          CODE nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                          SORT int NOT NULL,
                                          DATA_SCOPE tinyint DEFAULT '1' NOT NULL,
                                          DATA_SCOPE_DEPT_IDS nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                          STATUS tinyint NOT NULL,
    [TYPE] tinyint NOT NULL,
                                          REMARK nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                          CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                          CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                          UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                          UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                          DELETED bit DEFAULT 0 NOT NULL,
                                          CONSTRAINT PK__SYSTEM_R__3214EC27AFD87DC3 PRIMARY KEY (ID)
);


-- testflow.dbo.SYSTEM_ROLE_MENU definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_ROLE_MENU;

CREATE TABLE testflow.dbo.SYSTEM_ROLE_MENU (
                                               ID bigint IDENTITY(1,1) NOT NULL,
                                               ROLE_ID bigint NOT NULL,
                                               MENU_ID bigint NOT NULL,
                                               CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                               CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                               UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                               UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                               DELETED bit DEFAULT 0 NOT NULL,
                                               CONSTRAINT PK__SYSTEM_R__3214EC27465380ED PRIMARY KEY (ID)
);


-- testflow.dbo.SYSTEM_USERS definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_USERS;

CREATE TABLE testflow.dbo.SYSTEM_USERS (
                                           ID bigint IDENTITY(1,1) NOT NULL,
                                           USERNAME nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                           PASSWORD nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NOT NULL,
                                           NICKNAME nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                           REMARK nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                           DEPT_ID bigint DEFAULT NULL NULL,
                                           POST_IDS nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
                                           EMAIL nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                           MOBILE nvarchar(11) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                           SEX tinyint DEFAULT '0' NULL,
                                           AVATAR nvarchar(512) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                           STATUS tinyint DEFAULT '0' NOT NULL,
                                           LOGIN_IP nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                           LOGIN_DATE datetime2 DEFAULT NULL NULL,
                                           CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                           CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                           UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                           UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                           DELETED bit DEFAULT 0 NOT NULL,
                                           CONSTRAINT PK__SYSTEM_U__3214EC27E666AFF9 PRIMARY KEY (ID)
);


-- testflow.dbo.SYSTEM_USER_POST definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_USER_POST;

CREATE TABLE testflow.dbo.SYSTEM_USER_POST (
                                               ID bigint IDENTITY(1,1) NOT NULL,
                                               USER_ID bigint DEFAULT '0' NOT NULL,
                                               POST_ID bigint DEFAULT '0' NOT NULL,
                                               CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                               CREATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                               UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                               UPDATE_TIME datetime2 DEFAULT getdate() NOT NULL,
                                               DELETED bit DEFAULT 0 NOT NULL,
                                               CONSTRAINT PK__SYSTEM_U__3214EC275046DF4D PRIMARY KEY (ID)
);


-- testflow.dbo.SYSTEM_USER_ROLE definition

-- Drop table

-- DROP TABLE testflow.dbo.SYSTEM_USER_ROLE;

CREATE TABLE testflow.dbo.SYSTEM_USER_ROLE (
                                               ID bigint IDENTITY(1,1) NOT NULL,
                                               USER_ID bigint NOT NULL,
                                               ROLE_ID bigint NOT NULL,
                                               CREATOR nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                               CREATE_TIME datetime2 DEFAULT getdate() NULL,
                                               UPDATER nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                               UPDATE_TIME datetime2 DEFAULT getdate() NULL,
                                               DELETED bit DEFAULT 0 NOT NULL,
                                               CONSTRAINT PK__SYSTEM_U__3214EC274A517C14 PRIMARY KEY (ID)
);


-- testflow.dbo.TABLE_SWITCH_LOG definition

-- Drop table

-- DROP TABLE testflow.dbo.TABLE_SWITCH_LOG;

CREATE TABLE testflow.dbo.TABLE_SWITCH_LOG (
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


-- testflow.dbo.TMP_SECURITY_LISTS_1 definition

-- Drop table

-- DROP TABLE testflow.dbo.TMP_SECURITY_LISTS_1;

CREATE TABLE testflow.dbo.TMP_SECURITY_LISTS_1 (
                                                   ID int IDENTITY(1,1) NOT NULL,
                                                   CREATE_TIME datetime NOT NULL,
                                                   CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   LIST_TAG nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   LIST_VALUE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   DATA_SOURCE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   CONSTRAINT PK__BR_SECUR__3214EC2705D2AF23_copy1 PRIMARY KEY (ID)
);


-- testflow.dbo.TMP_SECURITY_LISTS_2 definition

-- Drop table

-- DROP TABLE testflow.dbo.TMP_SECURITY_LISTS_2;

CREATE TABLE testflow.dbo.TMP_SECURITY_LISTS_2 (
                                                   ID int IDENTITY(1,1) NOT NULL,
                                                   CREATE_TIME datetime NOT NULL,
                                                   CLIENT_ID nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   LIST_TAG nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   LIST_VALUE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   DATA_SOURCE nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   CONSTRAINT PK__BR_SECUR__3214EC2705D2AF23_copy1_copy1 PRIMARY KEY (ID)
);


-- testflow.dbo.ACT_GE_BYTEARRAY definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_GE_BYTEARRAY;

CREATE TABLE testflow.dbo.ACT_GE_BYTEARRAY (
                                               ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                               REV_ int NULL,
                                               NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               DEPLOYMENT_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               BYTES_ varbinary(MAX) NULL,
                                               GENERATED_ tinyint NULL,
                                               CONSTRAINT PK__ACT_GE_B__C4971C0F03D82376 PRIMARY KEY (ID_),
                                               CONSTRAINT ACT_FK_BYTEARR_DEPL FOREIGN KEY (DEPLOYMENT_ID_) REFERENCES testflow.dbo.ACT_RE_DEPLOYMENT(ID_)
);


-- testflow.dbo.ACT_ID_MEMBERSHIP definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_ID_MEMBERSHIP;

CREATE TABLE testflow.dbo.ACT_ID_MEMBERSHIP (
                                                USER_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                GROUP_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                CONSTRAINT PK__ACT_ID_M__C2371B0F1A6D94E7 PRIMARY KEY (USER_ID_,GROUP_ID_),
                                                CONSTRAINT ACT_FK_MEMB_GROUP FOREIGN KEY (GROUP_ID_) REFERENCES testflow.dbo.ACT_ID_GROUP(ID_),
                                                CONSTRAINT ACT_FK_MEMB_USER FOREIGN KEY (USER_ID_) REFERENCES testflow.dbo.ACT_ID_USER(ID_)
);


-- testflow.dbo.ACT_ID_PRIV_MAPPING definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_ID_PRIV_MAPPING;

CREATE TABLE testflow.dbo.ACT_ID_PRIV_MAPPING (
                                                  ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  PRIV_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  USER_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  GROUP_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  CONSTRAINT PK__ACT_ID_P__C4971C0F9D06B174 PRIMARY KEY (ID_),
                                                  CONSTRAINT ACT_FK_PRIV_MAPPING FOREIGN KEY (PRIV_ID_) REFERENCES testflow.dbo.ACT_ID_PRIV(ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_PRIV_GROUP ON dbo.ACT_ID_PRIV_MAPPING (  GROUP_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_PRIV_USER ON dbo.ACT_ID_PRIV_MAPPING (  USER_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_PROCDEF_INFO definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_PROCDEF_INFO;

CREATE TABLE testflow.dbo.ACT_PROCDEF_INFO (
                                               ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                               PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                               REV_ int NULL,
                                               INFO_JSON_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               CONSTRAINT ACT_UNIQ_INFO_PROCDEF UNIQUE (PROC_DEF_ID_),
                                               CONSTRAINT PK__ACT_PROC__C4971C0F227ABE3E PRIMARY KEY (ID_),
                                               CONSTRAINT ACT_FK_INFO_JSON_BA FOREIGN KEY (INFO_JSON_ID_) REFERENCES testflow.dbo.ACT_GE_BYTEARRAY(ID_),
                                               CONSTRAINT ACT_FK_INFO_PROCDEF FOREIGN KEY (PROC_DEF_ID_) REFERENCES testflow.dbo.ACT_RE_PROCDEF(ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_INFO_PROCDEF ON dbo.ACT_PROCDEF_INFO (  PROC_DEF_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_RE_MODEL definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RE_MODEL;

CREATE TABLE testflow.dbo.ACT_RE_MODEL (
                                           ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                           REV_ int NULL,
                                           NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           KEY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           CATEGORY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           CREATE_TIME_ datetime NULL,
                                           LAST_UPDATE_TIME_ datetime NULL,
                                           VERSION_ int NULL,
                                           META_INFO_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           DEPLOYMENT_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           EDITOR_SOURCE_VALUE_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           EDITOR_SOURCE_EXTRA_VALUE_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                           TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                           CONSTRAINT PK__ACT_RE_M__C4971C0FCC65FB79 PRIMARY KEY (ID_),
                                           CONSTRAINT ACT_FK_MODEL_DEPLOYMENT FOREIGN KEY (DEPLOYMENT_ID_) REFERENCES testflow.dbo.ACT_RE_DEPLOYMENT(ID_),
                                           CONSTRAINT ACT_FK_MODEL_SOURCE FOREIGN KEY (EDITOR_SOURCE_VALUE_ID_) REFERENCES testflow.dbo.ACT_GE_BYTEARRAY(ID_),
                                           CONSTRAINT ACT_FK_MODEL_SOURCE_EXTRA FOREIGN KEY (EDITOR_SOURCE_EXTRA_VALUE_ID_) REFERENCES testflow.dbo.ACT_GE_BYTEARRAY(ID_)
);


-- testflow.dbo.ACT_RU_EXECUTION definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RU_EXECUTION;

CREATE TABLE testflow.dbo.ACT_RU_EXECUTION (
                                               ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                               REV_ int NULL,
                                               PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               BUSINESS_KEY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               PARENT_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               SUPER_EXEC_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               ROOT_PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               ACT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               IS_ACTIVE_ tinyint NULL,
                                               IS_CONCURRENT_ tinyint NULL,
                                               IS_SCOPE_ tinyint NULL,
                                               IS_EVENT_SCOPE_ tinyint NULL,
                                               IS_MI_ROOT_ tinyint NULL,
                                               SUSPENSION_STATE_ tinyint NULL,
                                               CACHED_ENT_STATE_ int NULL,
                                               TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                               NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               START_ACT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               START_TIME_ datetime NULL,
                                               START_USER_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               LOCK_TIME_ datetime NULL,
                                               LOCK_OWNER_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               IS_COUNT_ENABLED_ tinyint NULL,
                                               EVT_SUBSCR_COUNT_ int NULL,
                                               TASK_COUNT_ int NULL,
                                               JOB_COUNT_ int NULL,
                                               TIMER_JOB_COUNT_ int NULL,
                                               SUSP_JOB_COUNT_ int NULL,
                                               DEADLETTER_JOB_COUNT_ int NULL,
                                               EXTERNAL_WORKER_JOB_COUNT_ int NULL,
                                               VAR_COUNT_ int NULL,
                                               ID_LINK_COUNT_ int NULL,
                                               CALLBACK_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               CALLBACK_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               REFERENCE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               REFERENCE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               PROPAGATED_STAGE_INST_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               BUSINESS_STATUS_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               CONSTRAINT PK__ACT_RU_E__C4971C0F4B75ED53 PRIMARY KEY (ID_),
                                               CONSTRAINT ACT_FK_EXE_PARENT FOREIGN KEY (PARENT_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_),
                                               CONSTRAINT ACT_FK_EXE_PROCDEF FOREIGN KEY (PROC_DEF_ID_) REFERENCES testflow.dbo.ACT_RE_PROCDEF(ID_),
                                               CONSTRAINT ACT_FK_EXE_SUPER FOREIGN KEY (SUPER_EXEC_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_EXECUTION_IDANDREV ON dbo.ACT_RU_EXECUTION (  ID_ ASC  , REV_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EXECUTION_PARENT ON dbo.ACT_RU_EXECUTION (  PARENT_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EXECUTION_PROC ON dbo.ACT_RU_EXECUTION (  PROC_DEF_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EXECUTION_SUPER ON dbo.ACT_RU_EXECUTION (  SUPER_EXEC_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EXEC_BUSKEY ON dbo.ACT_RU_EXECUTION (  BUSINESS_KEY_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EXEC_PROC_INST_ID ON dbo.ACT_RU_EXECUTION (  PROC_INST_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EXEC_REF_ID_ ON dbo.ACT_RU_EXECUTION (  REFERENCE_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EXEC_ROOT ON dbo.ACT_RU_EXECUTION (  ROOT_PROC_INST_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_RU_EXTERNAL_JOB definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RU_EXTERNAL_JOB;

CREATE TABLE testflow.dbo.ACT_RU_EXTERNAL_JOB (
                                                  ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  REV_ int NULL,
                                                  CATEGORY_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  LOCK_EXP_TIME_ datetime NULL,
                                                  LOCK_OWNER_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  EXCLUSIVE_ bit NULL,
                                                  EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  PROCESS_INSTANCE_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  ELEMENT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  ELEMENT_NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SUB_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SCOPE_DEFINITION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  CORRELATION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  RETRIES_ int NULL,
                                                  EXCEPTION_STACK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  EXCEPTION_MSG_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  DUEDATE_ datetime NULL,
                                                  REPEAT_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  HANDLER_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  HANDLER_CFG_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  CUSTOM_VALUES_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  CREATE_TIME_ datetime2 NULL,
                                                  TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                  CONSTRAINT PK__ACT_RU_E__C4971C0FC8F6A48D PRIMARY KEY (ID_),
                                                  CONSTRAINT ACT_FK_EXTERNAL_JOB_CUSTOM_VALUES FOREIGN KEY (CUSTOM_VALUES_ID_) REFERENCES testflow.dbo.ACT_GE_BYTEARRAY(ID_),
                                                  CONSTRAINT ACT_FK_EXTERNAL_JOB_EXCEPTION FOREIGN KEY (EXCEPTION_STACK_ID_) REFERENCES testflow.dbo.ACT_GE_BYTEARRAY(ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_EJOB_SCOPE ON dbo.ACT_RU_EXTERNAL_JOB (  SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EJOB_SCOPE_DEF ON dbo.ACT_RU_EXTERNAL_JOB (  SCOPE_DEFINITION_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EJOB_SUB_SCOPE ON dbo.ACT_RU_EXTERNAL_JOB (  SUB_SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EXTERNAL_JOB_CORRELATION_ID ON dbo.ACT_RU_EXTERNAL_JOB (  CORRELATION_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EXTERNAL_JOB_CUSTOM_VALUES_ID ON dbo.ACT_RU_EXTERNAL_JOB (  CUSTOM_VALUES_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EXTERNAL_JOB_EXCEPTION_STACK_ID ON dbo.ACT_RU_EXTERNAL_JOB (  EXCEPTION_STACK_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_RU_JOB definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RU_JOB;

CREATE TABLE testflow.dbo.ACT_RU_JOB (
                                         ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                         REV_ int NULL,
                                         CATEGORY_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                         LOCK_EXP_TIME_ datetime NULL,
                                         LOCK_OWNER_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         EXCLUSIVE_ bit NULL,
                                         EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         PROCESS_INSTANCE_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         ELEMENT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         ELEMENT_NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         SUB_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         SCOPE_DEFINITION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         CORRELATION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         RETRIES_ int NULL,
                                         EXCEPTION_STACK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         EXCEPTION_MSG_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         DUEDATE_ datetime NULL,
                                         REPEAT_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         HANDLER_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         HANDLER_CFG_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         CUSTOM_VALUES_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                         CREATE_TIME_ datetime2 NULL,
                                         TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                         CONSTRAINT PK__ACT_RU_J__C4971C0FEC382E29 PRIMARY KEY (ID_),
                                         CONSTRAINT ACT_FK_JOB_CUSTOM_VALUES FOREIGN KEY (CUSTOM_VALUES_ID_) REFERENCES testflow.dbo.ACT_GE_BYTEARRAY(ID_),
                                         CONSTRAINT ACT_FK_JOB_EXCEPTION FOREIGN KEY (EXCEPTION_STACK_ID_) REFERENCES testflow.dbo.ACT_GE_BYTEARRAY(ID_),
                                         CONSTRAINT ACT_FK_JOB_EXECUTION FOREIGN KEY (EXECUTION_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_),
                                         CONSTRAINT ACT_FK_JOB_PROCESS_INSTANCE FOREIGN KEY (PROCESS_INSTANCE_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_),
                                         CONSTRAINT ACT_FK_JOB_PROC_DEF FOREIGN KEY (PROC_DEF_ID_) REFERENCES testflow.dbo.ACT_RE_PROCDEF(ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_JOB_CORRELATION_ID ON dbo.ACT_RU_JOB (  CORRELATION_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_JOB_CUSTOM_VALUES_ID ON dbo.ACT_RU_JOB (  CUSTOM_VALUES_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_JOB_EXCEPTION_STACK_ID ON dbo.ACT_RU_JOB (  EXCEPTION_STACK_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_JOB_EXECUTION_ID ON dbo.ACT_RU_JOB (  EXECUTION_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_JOB_PROCESS_INSTANCE_ID ON dbo.ACT_RU_JOB (  PROCESS_INSTANCE_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_JOB_PROC_DEF_ID ON dbo.ACT_RU_JOB (  PROC_DEF_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_JOB_SCOPE ON dbo.ACT_RU_JOB (  SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_JOB_SCOPE_DEF ON dbo.ACT_RU_JOB (  SCOPE_DEFINITION_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_JOB_SUB_SCOPE ON dbo.ACT_RU_JOB (  SUB_SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_RU_SUSPENDED_JOB definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RU_SUSPENDED_JOB;

CREATE TABLE testflow.dbo.ACT_RU_SUSPENDED_JOB (
                                                   ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   REV_ int NULL,
                                                   CATEGORY_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                   EXCLUSIVE_ bit NULL,
                                                   EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   PROCESS_INSTANCE_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   ELEMENT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   ELEMENT_NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   SUB_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   SCOPE_DEFINITION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   CORRELATION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   RETRIES_ int NULL,
                                                   EXCEPTION_STACK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   EXCEPTION_MSG_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   DUEDATE_ datetime NULL,
                                                   REPEAT_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   HANDLER_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   HANDLER_CFG_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   CUSTOM_VALUES_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                   CREATE_TIME_ datetime2 NULL,
                                                   TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                   CONSTRAINT PK__ACT_RU_S__C4971C0F073298F0 PRIMARY KEY (ID_),
                                                   CONSTRAINT ACT_FK_SUSPENDED_JOB_CUSTOM_VALUES FOREIGN KEY (CUSTOM_VALUES_ID_) REFERENCES testflow.dbo.ACT_GE_BYTEARRAY(ID_),
                                                   CONSTRAINT ACT_FK_SUSPENDED_JOB_EXCEPTION FOREIGN KEY (EXCEPTION_STACK_ID_) REFERENCES testflow.dbo.ACT_GE_BYTEARRAY(ID_),
                                                   CONSTRAINT ACT_FK_SUSPENDED_JOB_EXECUTION FOREIGN KEY (EXECUTION_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_),
                                                   CONSTRAINT ACT_FK_SUSPENDED_JOB_PROCESS_INSTANCE FOREIGN KEY (PROCESS_INSTANCE_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_),
                                                   CONSTRAINT ACT_FK_SUSPENDED_JOB_PROC_DEF FOREIGN KEY (PROC_DEF_ID_) REFERENCES testflow.dbo.ACT_RE_PROCDEF(ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_SJOB_SCOPE ON dbo.ACT_RU_SUSPENDED_JOB (  SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_SJOB_SCOPE_DEF ON dbo.ACT_RU_SUSPENDED_JOB (  SCOPE_DEFINITION_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_SJOB_SUB_SCOPE ON dbo.ACT_RU_SUSPENDED_JOB (  SUB_SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_SUSPENDED_JOB_CORRELATION_ID ON dbo.ACT_RU_SUSPENDED_JOB (  CORRELATION_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_SUSPENDED_JOB_CUSTOM_VALUES_ID ON dbo.ACT_RU_SUSPENDED_JOB (  CUSTOM_VALUES_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_SUSPENDED_JOB_EXCEPTION_STACK_ID ON dbo.ACT_RU_SUSPENDED_JOB (  EXCEPTION_STACK_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_SUSPENDED_JOB_EXECUTION_ID ON dbo.ACT_RU_SUSPENDED_JOB (  EXECUTION_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_SUSPENDED_JOB_PROCESS_INSTANCE_ID ON dbo.ACT_RU_SUSPENDED_JOB (  PROCESS_INSTANCE_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_SUSPENDED_JOB_PROC_DEF_ID ON dbo.ACT_RU_SUSPENDED_JOB (  PROC_DEF_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_RU_TASK definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RU_TASK;

CREATE TABLE testflow.dbo.ACT_RU_TASK (
                                          ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                          REV_ int NULL,
                                          EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          TASK_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          SUB_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          SCOPE_DEFINITION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          PROPAGATED_STAGE_INST_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          STATE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          PARENT_TASK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          DESCRIPTION_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          TASK_DEF_KEY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          OWNER_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          ASSIGNEE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          DELEGATION_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          PRIORITY_ int NULL,
                                          CREATE_TIME_ datetime NULL,
                                          IN_PROGRESS_TIME_ datetime NULL,
                                          IN_PROGRESS_STARTED_BY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          CLAIM_TIME_ datetime NULL,
                                          CLAIMED_BY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          SUSPENDED_TIME_ datetime NULL,
                                          SUSPENDED_BY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          IN_PROGRESS_DUE_DATE_ datetime NULL,
                                          DUE_DATE_ datetime NULL,
                                          CATEGORY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          SUSPENSION_STATE_ int NULL,
                                          TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                          FORM_KEY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                          IS_COUNT_ENABLED_ tinyint NULL,
                                          VAR_COUNT_ int NULL,
                                          ID_LINK_COUNT_ int NULL,
                                          SUB_TASK_COUNT_ int NULL,
                                          CONSTRAINT PK__ACT_RU_T__C4971C0FEAA0E7C6 PRIMARY KEY (ID_),
                                          CONSTRAINT ACT_FK_TASK_EXE FOREIGN KEY (EXECUTION_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_),
                                          CONSTRAINT ACT_FK_TASK_PROCDEF FOREIGN KEY (PROC_DEF_ID_) REFERENCES testflow.dbo.ACT_RE_PROCDEF(ID_),
                                          CONSTRAINT ACT_FK_TASK_PROCINST FOREIGN KEY (PROC_INST_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_TASK_CREATE ON dbo.ACT_RU_TASK (  CREATE_TIME_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TASK_EXEC ON dbo.ACT_RU_TASK (  EXECUTION_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TASK_PROCINST ON dbo.ACT_RU_TASK (  PROC_INST_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TASK_PROC_DEF_ID ON dbo.ACT_RU_TASK (  PROC_DEF_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TASK_SCOPE ON dbo.ACT_RU_TASK (  SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TASK_SCOPE_DEF ON dbo.ACT_RU_TASK (  SCOPE_DEFINITION_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TASK_SUB_SCOPE ON dbo.ACT_RU_TASK (  SUB_SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_RU_TIMER_JOB definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RU_TIMER_JOB;

CREATE TABLE testflow.dbo.ACT_RU_TIMER_JOB (
                                               ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                               REV_ int NULL,
                                               CATEGORY_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                               LOCK_EXP_TIME_ datetime NULL,
                                               LOCK_OWNER_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               EXCLUSIVE_ bit NULL,
                                               EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               PROCESS_INSTANCE_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               ELEMENT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               ELEMENT_NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               SUB_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               SCOPE_DEFINITION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               CORRELATION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               RETRIES_ int NULL,
                                               EXCEPTION_STACK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               EXCEPTION_MSG_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               DUEDATE_ datetime NULL,
                                               REPEAT_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               HANDLER_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               HANDLER_CFG_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               CUSTOM_VALUES_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                               CREATE_TIME_ datetime2 NULL,
                                               TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                               CONSTRAINT PK__ACT_RU_T__C4971C0F7DFA4BF5 PRIMARY KEY (ID_),
                                               CONSTRAINT ACT_FK_TIMER_JOB_CUSTOM_VALUES FOREIGN KEY (CUSTOM_VALUES_ID_) REFERENCES testflow.dbo.ACT_GE_BYTEARRAY(ID_),
                                               CONSTRAINT ACT_FK_TIMER_JOB_EXCEPTION FOREIGN KEY (EXCEPTION_STACK_ID_) REFERENCES testflow.dbo.ACT_GE_BYTEARRAY(ID_),
                                               CONSTRAINT ACT_FK_TIMER_JOB_EXECUTION FOREIGN KEY (EXECUTION_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_),
                                               CONSTRAINT ACT_FK_TIMER_JOB_PROCESS_INSTANCE FOREIGN KEY (PROCESS_INSTANCE_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_),
                                               CONSTRAINT ACT_FK_TIMER_JOB_PROC_DEF FOREIGN KEY (PROC_DEF_ID_) REFERENCES testflow.dbo.ACT_RE_PROCDEF(ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_TIMER_JOB_CORRELATION_ID ON dbo.ACT_RU_TIMER_JOB (  CORRELATION_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TIMER_JOB_CUSTOM_VALUES_ID ON dbo.ACT_RU_TIMER_JOB (  CUSTOM_VALUES_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TIMER_JOB_DUEDATE ON dbo.ACT_RU_TIMER_JOB (  DUEDATE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TIMER_JOB_EXCEPTION_STACK_ID ON dbo.ACT_RU_TIMER_JOB (  EXCEPTION_STACK_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TIMER_JOB_EXECUTION_ID ON dbo.ACT_RU_TIMER_JOB (  EXECUTION_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TIMER_JOB_PROCESS_INSTANCE_ID ON dbo.ACT_RU_TIMER_JOB (  PROCESS_INSTANCE_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TIMER_JOB_PROC_DEF_ID ON dbo.ACT_RU_TIMER_JOB (  PROC_DEF_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TJOB_SCOPE ON dbo.ACT_RU_TIMER_JOB (  SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TJOB_SCOPE_DEF ON dbo.ACT_RU_TIMER_JOB (  SCOPE_DEFINITION_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_TJOB_SUB_SCOPE ON dbo.ACT_RU_TIMER_JOB (  SUB_SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_RU_VARIABLE definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RU_VARIABLE;

CREATE TABLE testflow.dbo.ACT_RU_VARIABLE (
                                              ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                              REV_ int NULL,
                                              TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                              NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                              EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              TASK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              SUB_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              BYTEARRAY_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              DOUBLE_ float NULL,
                                              LONG_ numeric(19,0) NULL,
                                              TEXT_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              TEXT2_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              META_INFO_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                              CONSTRAINT PK__ACT_RU_V__C4971C0FC948F8AF PRIMARY KEY (ID_),
                                              CONSTRAINT ACT_FK_VAR_BYTEARRAY FOREIGN KEY (BYTEARRAY_ID_) REFERENCES testflow.dbo.ACT_GE_BYTEARRAY(ID_),
                                              CONSTRAINT ACT_FK_VAR_EXE FOREIGN KEY (EXECUTION_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_),
                                              CONSTRAINT ACT_FK_VAR_PROCINST FOREIGN KEY (PROC_INST_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_RU_VAR_SCOPE_ID_TYPE ON dbo.ACT_RU_VARIABLE (  SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_RU_VAR_SUB_ID_TYPE ON dbo.ACT_RU_VARIABLE (  SUB_SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_VARIABLE_BA ON dbo.ACT_RU_VARIABLE (  BYTEARRAY_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_VARIABLE_EXEC ON dbo.ACT_RU_VARIABLE (  EXECUTION_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_VARIABLE_PROCINST ON dbo.ACT_RU_VARIABLE (  PROC_INST_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_VARIABLE_TASK_ID ON dbo.ACT_RU_VARIABLE (  TASK_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.FLW_RU_BATCH_PART definition

-- Drop table

-- DROP TABLE testflow.dbo.FLW_RU_BATCH_PART;

CREATE TABLE testflow.dbo.FLW_RU_BATCH_PART (
                                                ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                REV_ int NULL,
                                                BATCH_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                TYPE_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                SCOPE_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                SUB_SCOPE_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                SCOPE_TYPE_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                SEARCH_KEY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                SEARCH_KEY2_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                CREATE_TIME_ datetime NOT NULL,
                                                COMPLETE_TIME_ datetime NULL,
                                                STATUS_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                RESULT_DOC_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                CONSTRAINT PK__FLW_RU_B__C4971C0FFD4703D2 PRIMARY KEY (ID_),
                                                CONSTRAINT FLW_FK_BATCH_PART_PARENT FOREIGN KEY (BATCH_ID_) REFERENCES testflow.dbo.FLW_RU_BATCH(ID_)
);
CREATE NONCLUSTERED INDEX FLW_IDX_BATCH_PART ON dbo.FLW_RU_BATCH_PART (  BATCH_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_RU_DEADLETTER_JOB definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RU_DEADLETTER_JOB;

CREATE TABLE testflow.dbo.ACT_RU_DEADLETTER_JOB (
                                                    ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                    REV_ int NULL,
                                                    CATEGORY_ varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                    EXCLUSIVE_ bit NULL,
                                                    EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    PROCESS_INSTANCE_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    ELEMENT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    ELEMENT_NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    SUB_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    SCOPE_DEFINITION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    CORRELATION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    EXCEPTION_STACK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    EXCEPTION_MSG_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    DUEDATE_ datetime NULL,
                                                    REPEAT_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    HANDLER_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    HANDLER_CFG_ nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    CUSTOM_VALUES_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                    CREATE_TIME_ datetime2 NULL,
                                                    TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                    CONSTRAINT PK__ACT_RU_D__C4971C0F17DA135D PRIMARY KEY (ID_),
                                                    CONSTRAINT ACT_FK_DEADLETTER_JOB_CUSTOM_VALUES FOREIGN KEY (CUSTOM_VALUES_ID_) REFERENCES testflow.dbo.ACT_GE_BYTEARRAY(ID_),
                                                    CONSTRAINT ACT_FK_DEADLETTER_JOB_EXCEPTION FOREIGN KEY (EXCEPTION_STACK_ID_) REFERENCES testflow.dbo.ACT_GE_BYTEARRAY(ID_),
                                                    CONSTRAINT ACT_FK_DEADLETTER_JOB_EXECUTION FOREIGN KEY (EXECUTION_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_),
                                                    CONSTRAINT ACT_FK_DEADLETTER_JOB_PROCESS_INSTANCE FOREIGN KEY (PROCESS_INSTANCE_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_),
                                                    CONSTRAINT ACT_FK_DEADLETTER_JOB_PROC_DEF FOREIGN KEY (PROC_DEF_ID_) REFERENCES testflow.dbo.ACT_RE_PROCDEF(ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_DEADLETTER_JOB_CORRELATION_ID ON dbo.ACT_RU_DEADLETTER_JOB (  CORRELATION_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_DEADLETTER_JOB_CUSTOM_VALUES_ID ON dbo.ACT_RU_DEADLETTER_JOB (  CUSTOM_VALUES_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_DEADLETTER_JOB_EXCEPTION_STACK_ID ON dbo.ACT_RU_DEADLETTER_JOB (  EXCEPTION_STACK_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_DEADLETTER_JOB_EXECUTION_ID ON dbo.ACT_RU_DEADLETTER_JOB (  EXECUTION_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_DEADLETTER_JOB_PROCESS_INSTANCE_ID ON dbo.ACT_RU_DEADLETTER_JOB (  PROCESS_INSTANCE_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_DEADLETTER_JOB_PROC_DEF_ID ON dbo.ACT_RU_DEADLETTER_JOB (  PROC_DEF_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_DJOB_SCOPE ON dbo.ACT_RU_DEADLETTER_JOB (  SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_DJOB_SCOPE_DEF ON dbo.ACT_RU_DEADLETTER_JOB (  SCOPE_DEFINITION_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_DJOB_SUB_SCOPE ON dbo.ACT_RU_DEADLETTER_JOB (  SUB_SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_RU_EVENT_SUBSCR definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RU_EVENT_SUBSCR;

CREATE TABLE testflow.dbo.ACT_RU_EVENT_SUBSCR (
                                                  ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  REV_ int NULL,
                                                  EVENT_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  EVENT_NAME_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  EXECUTION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  ACTIVITY_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  CONFIGURATION_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  CREATED_ datetime NOT NULL,
                                                  PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SUB_SCOPE_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SCOPE_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SCOPE_DEFINITION_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SCOPE_DEFINITION_KEY_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SCOPE_TYPE_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  LOCK_TIME_ datetime NULL,
                                                  LOCK_OWNER_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  TENANT_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '' NULL,
                                                  CONSTRAINT PK__ACT_RU_E__C4971C0F7F95021C PRIMARY KEY (ID_),
                                                  CONSTRAINT ACT_FK_EVENT_EXEC FOREIGN KEY (EXECUTION_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_EVENT_SUBSCR_CONFIG_ ON dbo.ACT_RU_EVENT_SUBSCR (  CONFIGURATION_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EVENT_SUBSCR_EXEC_ID ON dbo.ACT_RU_EVENT_SUBSCR (  EXECUTION_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EVENT_SUBSCR_PROC_ID ON dbo.ACT_RU_EVENT_SUBSCR (  PROC_INST_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_EVENT_SUBSCR_SCOPEREF_ ON dbo.ACT_RU_EVENT_SUBSCR (  SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- testflow.dbo.ACT_RU_IDENTITYLINK definition

-- Drop table

-- DROP TABLE testflow.dbo.ACT_RU_IDENTITYLINK;

CREATE TABLE testflow.dbo.ACT_RU_IDENTITYLINK (
                                                  ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                                  REV_ int NULL,
                                                  GROUP_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  USER_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  TASK_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  PROC_INST_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  PROC_DEF_ID_ nvarchar(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SUB_SCOPE_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SCOPE_TYPE_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  SCOPE_DEFINITION_ID_ nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                                  CONSTRAINT PK__ACT_RU_I__C4971C0FA2C60F30 PRIMARY KEY (ID_),
                                                  CONSTRAINT ACT_FK_ATHRZ_PROCEDEF FOREIGN KEY (PROC_DEF_ID_) REFERENCES testflow.dbo.ACT_RE_PROCDEF(ID_),
                                                  CONSTRAINT ACT_FK_IDL_PROCINST FOREIGN KEY (PROC_INST_ID_) REFERENCES testflow.dbo.ACT_RU_EXECUTION(ID_),
                                                  CONSTRAINT ACT_FK_TSKASS_TASK FOREIGN KEY (TASK_ID_) REFERENCES testflow.dbo.ACT_RU_TASK(ID_)
);
CREATE NONCLUSTERED INDEX ACT_IDX_ATHRZ_PROCEDEF ON dbo.ACT_RU_IDENTITYLINK (  PROC_DEF_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_IDENT_LNK_GROUP ON dbo.ACT_RU_IDENTITYLINK (  GROUP_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_IDENT_LNK_PROCINST ON dbo.ACT_RU_IDENTITYLINK (  PROC_INST_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_IDENT_LNK_SCOPE ON dbo.ACT_RU_IDENTITYLINK (  SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_IDENT_LNK_SCOPE_DEF ON dbo.ACT_RU_IDENTITYLINK (  SCOPE_DEFINITION_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_IDENT_LNK_SUB_SCOPE ON dbo.ACT_RU_IDENTITYLINK (  SUB_SCOPE_ID_ ASC  , SCOPE_TYPE_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_IDENT_LNK_TASK ON dbo.ACT_RU_IDENTITYLINK (  TASK_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ACT_IDX_IDENT_LNK_USER ON dbo.ACT_RU_IDENTITYLINK (  USER_ID_ ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;