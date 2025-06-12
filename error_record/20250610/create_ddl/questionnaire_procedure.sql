DELIMITER //

CREATE PROCEDURE sp_insert_test_questionnaire(IN record_count INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE base_time DATETIME DEFAULT NOW();
    DECLARE random_id BIGINT;
    DECLARE random_duration INT;
    DECLARE random_type INT;
    DECLARE random_days INT;
    DECLARE random_approve INT;
    DECLARE random_re_edit INT;
    DECLARE random_answer_limit INT;
    DECLARE random_cycle_type INT;
    DECLARE random_cycle_day INT;
    DECLARE random_share INT;
    DECLARE random_status INT;

    -- 確保 record_count 大於 0
    IF record_count <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'record_count must be greater than 0';
    END IF;

    WHILE i <= record_count DO
            -- 生成範圍內的隨機 ID (模擬雪花 ID，範圍 1 到 9223372036854775807)
            SET random_id = FLOOR(1 + RAND() * 9223372036854775807);
            -- 隨機 duration (10-60 分鐘)
            SET random_duration = FLOOR(10 + RAND() * 51);
            -- 隨機 question_type (1, 2, 3)
            SET random_type = FLOOR(1 + RAND() * 3);
            -- 隨機 valid_days (1-30 天)
            SET random_days = FLOOR(1 + RAND() * 30);
            -- 隨機 need_approve (0, 1)
            SET random_approve = FLOOR(RAND() * 2);
            -- 隨機 re_edit (0, 1)
            SET random_re_edit = FLOOR(RAND() * 2);
            -- 隨機 answer_limit (1-5)
            SET random_answer_limit = FLOOR(1 + RAND() * 5);
            -- 隨機 cycle_copy_type (0-4)
            SET random_cycle_type = FLOOR(RAND() * 5);
            -- 隨機 cycle_copy_day (1-28)
            SET random_cycle_day = FLOOR(1 + RAND() * 28);
            -- 隨機 answer_share (0, 1)
            SET random_share = FLOOR(RAND() * 2);
            -- 隨機 status (0, 1)
            SET random_status = FLOOR(RAND() * 2);

            INSERT INTO t_questionnaire (
                id, code, cn_name, hk_name, en_name,
                cn_conclusion, hk_conclusion, en_conclusion,
                cn_description, hk_description, en_description,
                duration, question_type, subject,
                start_time, end_time, valid_days,
                need_approve, re_edit, answer_limit,
                cycle_copy_type, cycle_copy_day, answer_share,
                data_list_show_subject_id, version, status,
                create_by, creator_name, create_time,
                update_by, update_name, update_time, delete_flag
            ) VALUES (
                         random_id,
                         CONCAT('QST', LPAD(i, 3, '0')),
                         CONCAT('問卷名稱', i),
                         CONCAT('問卷名稱HK', i),
                         CONCAT('Questionnaire Name', i),
                         CONCAT('結論', i),
                         CONCAT('結論HK', i),
                         CONCAT('Conclusion', i),
                         CONCAT('描述', i),
                         CONCAT('描述HK', i),
                         CONCAT('Description', i),
                         random_duration,
                         random_type,
                         JSON_OBJECT('question_id', i, 'title', CONCAT('Question ', i)),
                         DATE_ADD(base_time, INTERVAL FLOOR(RAND() * 10) DAY),
                         DATE_ADD(base_time, INTERVAL FLOOR(10 + RAND() * 20) DAY),
                         random_days,
                         random_approve,
                         random_re_edit,
                         random_answer_limit,
                         random_cycle_type,
                         random_cycle_day,
                         random_share,
                         CONCAT('SUB', i),
                         1,
                         random_status,
                         'user001',
                         '測試用戶',
                         base_time,
                         'user001',
                         '測試用戶',
                         base_time,
                         0
                     );

            SET i = i + 1;
        END WHILE;

    SELECT CONCAT('Inserted ', record_count, ' test records into t_questionnaire') AS result;
END //

DELIMITER ;