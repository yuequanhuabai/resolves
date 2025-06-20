#################################  t_questionnaire  ###################################################################################################
drop table if exists `t_questionnaire`;
create table t_questionnaire(
    `id` bigint primary key  comment 'Primary key,使用雪花id' ,
    `code` varchar(255)   comment 'union code',
    `cn_name` varchar(255) comment 'questionnaire cn name',
    `hk_name` varchar(255) comment 'questionnaire hk name',
    `en_name` varchar(255) comment 'questionnaire hk name',
    `cn_conclusion` varchar(255) comment 'questionnaire cn conclusion',
    `hk_conclusion` varchar(255) comment 'questionnaire hk conclusion',
    `en_conclusion` varchar(255) comment 'questionnaire en conclusion',
    `cn_description` varchar(255) comment 'questionnaire cn description',
    `hk_description` varchar(255) comment 'questionnaire hk description',
    `en_description` varchar(255) comment 'questionnaire en description',
    `duration` int comment 'questionnaire duration(minute, for questionnaire type: exam)',
    `question_type` int comment 'type of questionnaire(1.event ;2 survey, 3. exam)',
    `subject` json comment 'subject',
    `start_time` datetime comment 'the start time for answering the questionnaire',
    `end_time` datetime comment 'the deadline for completing the questionnaire',
    `valid_days` int  comment '相對有效期，和start_time 和 end_time   二選一',
    `need_approve` int comment '提交後是否需要審批， 0=不需要，1=需要',
    `re_edit` int comment '提交後是否允許再次編輯： 0:允許；1:不允許',
    `answer_limit` int default 1 comment '回答次數限制，默認1此',
    `cycle_copy_type` int default 0 comment '周期性複製類型： 0=不複製，1=周，2=月，3=季度，4=年',
    `cycle_copy_day` int comment '周期複製在周期的第幾天',
    `answer_share` int default 1 comment '共享回答（多個用戶編輯同一個回答）',
    `data_list_show_subject_id` varchar(128) comment '數據列表顯示的題目ID，多個以逗號分隔',
    `version` int  comment 'version no',
    `status` int comment 'status 0=unpublished, 1=publish',
    `create_by` varchar(16) comment 'creator (user ID)',
    `creator_name` varchar(32) comment 'creator username',
    `create_time` datetime comment 'create time',
    `update_by`  varchar(16) comment 'updator (user id)',
    `update_name` varchar(32) comment  'update name',
    `update_time` datetime comment 'update time',
    `delete_flag` int default 0 comment 'flag of logical delete'
);


##################################   t_questionnaire_user   ##################################################################################################
drop table if exists `t_questionnaire_user`;
create table `t_questionnaire_user`(
  `id` bigint primary key ,
  `question_id` bigint comment  'questionId',
  `user_type` int comment '用戶類型： 0-管理員，1=限定回答',
  `user_id` varchar(16) comment '用戶id',
  `user_name` varchar(32) comment '用戶名',
  `email` varchar(32) comment 'email',
    `create_by` varchar(16) comment 'creator (user Id)',
    `create_time` datetime default current_timestamp comment 'create time'
);

##################################   t_questionnaire_favorite   ##################################################################################################
drop table if exists `t_questionnaire_favorite`;
create table `t_questionnaire_favorite` (
    id bigint primary key ,
    question_id bigint ,
    collect int default 0 comment '1為收藏，0為取消收藏',
    user_id varchar(16),
    user_name varchar(32),
    create_time datetime default current_timestamp
);

show create table t_questionnaire_favorite;

##################################   t_questionnaire_notice   ##################################################################################################
drop table if exists `t_questionnaire_notice`;
create table `t_questionnaire_notice`(
    id bigint primary key ,
    question_id bigint,
    trigger_point varchar(16) comment '觸發點：public,answer,approved, not-approved, beginTime,endTime',
    recipient_type varchar(16) comment '接收者類型： mgr,all-answerer',
    recipient_email varchar(1024) comment '自定義接收者email，多個英文逗號分隔',
    `title` varchar(128) comment 'email 標題',
    `content` varchar(128) comment 'email content',
    `create_by` varchar(16) ,
    `create_time` datetime,
    `update_by` varchar(16),
    `update_time` datetime
);


##################################   t_answer  ##################################################################################################
drop table if exists `t_answer`;
create table `t_answer`(
    `id` bigint primary key ,
    `question_id` bigint,
    `question_code` varchar(64),
    `user_id` varchar(64),
    `user_name` varchar(64),
    `content` json comment 'answer content',
    `extend_info` json comment 'extend_info',
    `status` varchar(16) default '0' comment 'status: 0=temp store, 1=submit',
    `approver_id` varchar(16) comment '審批人的userId',
    `approver_name` varchar(32) comment '審批人的人名',
    `approve_status` int comment '審批狀態： 0=待審批，1=通過，-1=不通過',
    `tag` varchar(16) comment '標簽',
    `version` int comment 'version no',
    `total_score` int comment 'score value',
    `create_time` datetime default current_timestamp,
    `update_by` varchar(16),
    `updater_name` varchar(32),
    `update_time` datetime,
    `delete_flag` int default 0 comment 'flag of logical delete'
);


##################################   t_answer_score  ##################################################################################################

drop table if exists `t_answer_socre`;
create table `t_answer_socre`(
    `id` bigint primary key ,
    `answer_id`bigint,
    `answer_user_id` varchar(64),
    `subject_id` bigint,
    `user_id` varchar(100),
    `user_name` varchar(100),
    `favor` int default 0 comment 'like: 0=not like , 1=like',
    `score` int default -1 comment 'score value',
    `comment` varchar(258) comment 'comment',
    `userName` varchar(100) comment 'username of rated user',
    `create_time` datetime default current_timestamp,
    `update_time` datetime default current_timestamp
)











