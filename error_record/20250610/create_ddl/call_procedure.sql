
# t_questionnaire表存儲過程;

select * from t_questionnaire;

select count(*) from t_questionnaire;

truncate table t_questionnaire;

CALL sp_insert_test_questionnaire(100);

DROP PROCEDURE IF EXISTS `sp_insert_test_questionnaire`;



## t_questionnaire_user 存儲過程
select * from t_questionnaire_user;
select count(*) from t_questionnaire_user;

CALL sp_init_questionnaire_user_random(100, 1001, 1005, 0.1);

## 刪除存儲過程：
DROP PROCEDURE IF EXISTS `sp_init_questionnaire_user_random`;


##t_questionnaire_favorite

    select * from t_questionnaire_favorite;

select count(*) from t_questionnaire_favorite;
-- 示例：生成100條記錄，問卷ID範圍1001-1005，用戶數量50個
CALL sp_init_questionnaire_favorite(100, 1001, 1005, 50);


##t_questionnaire_notice

    select * from t_questionnaire_notice;

select count(*) from t_questionnaire_notice;

-- 示例：生成50條記錄，問卷ID範圍1001-1005
CALL sp_init_questionnaire_notice(50, 1001, 1005);



#### t_answer表

    select * from t_answer;

select count(*) from t_answer;

-- 示例：生成200條記錄，問卷ID範圍1001-1005，用戶數量50個
CALL sp_init_answer_data(200, 1001, 1005, 50);


#### t_answer_score 表

    select * from t_answer_socre;

select count(*) from t_answer_socre;

-- 示例：生成500条记录，答案ID范围1-1000，用户数量50个，题目数量20个
CALL sp_init_answer_score_data(500, 1, 1000, 50, 20);
