create table t_answer(
    `id` bigint primary key  comment 'Primary key',
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


)