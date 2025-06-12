DELIMITER //

CREATE PROCEDURE `sp_init_questionnaire_notice`(
    IN p_record_count INT,          -- 要生成的記錄數量
    IN p_question_id_start BIGINT,  -- 起始問卷ID
    IN p_question_id_end BIGINT     -- 結束問卷ID
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_id BIGINT;
    DECLARE v_question_id BIGINT;
    DECLARE v_trigger_point VARCHAR(16);
    DECLARE v_recipient_type VARCHAR(16);
    DECLARE v_recipient_email VARCHAR(1024);
    DECLARE v_title VARCHAR(128);
    DECLARE v_content VARCHAR(128);
    DECLARE v_create_by VARCHAR(16);
    DECLARE v_update_by VARCHAR(16);
    DECLARE v_time_offset INT;

    -- 錯誤處理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE,
                @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
            SELECT CONCAT('Error ', @errno, ' (', @sqlstate, '): ', @text) AS error_message;
            ROLLBACK;
        END;

    -- 清空表（如需保留數據，請移除這行）
    START TRANSACTION;
    TRUNCATE TABLE `t_questionnaire_notice`;

    -- 生成隨機數據
    WHILE i < p_record_count DO
            -- 生成唯一ID
            SET v_id = (SELECT IFNULL(MAX(id), 0) FROM `t_questionnaire_notice`) + 1 + i;

            -- 隨機選擇問卷ID
            SET v_question_id = FLOOR(p_question_id_start + RAND() * (p_question_id_end - p_question_id_start + 1));

            -- 隨機觸發點
            SET v_trigger_point = ELT(FLOOR(1 + RAND() * 6),
                                      'public', 'answer', 'approved', 'not-approved', 'beginTime', 'endTime');

            -- 隨機接收者類型
            SET v_recipient_type = ELT(FLOOR(1 + RAND() * 2), 'mgr', 'all-answerer');

            -- 根據接收者類型生成郵件列表
            IF v_recipient_type = 'mgr' THEN
                SET v_recipient_email = CONCAT(
                        'manager', FLOOR(1 + RAND() * 5), '@company.com',
                        ',admin', FLOOR(1 + RAND() * 3), '@company.com'
                                        );
            ELSE
                SET v_recipient_email = CONCAT(
                        'user', FLOOR(1 + RAND() * 100), '@example.com',
                        ',user', FLOOR(1 + RAND() * 100), '@example.com',
                        ',user', FLOOR(1 + RAND() * 100), '@example.com'
                                        );
            END IF;

            -- 生成標題和內容
            SET v_title = CONCAT(
                    ELT(FLOOR(1 + RAND() * 5), '問卷通知: ', '重要: ', '提醒: ', '通知: ', '問卷更新: '),
                    '問卷ID ', v_question_id, ' ',
                    ELT(FLOOR(1 + RAND() * 5), '狀態更新', '請及時處理', '即將截止', '已發布', '審核結果')
                          );

            SET v_content = CONCAT(
                    '親愛的',
                    ELT(FLOOR(1 + RAND() * 3), '用戶', '管理員', '團隊'),
                    '，問卷ID ', v_question_id, ' 已',
                    ELT(FLOOR(1 + RAND() * 5), '發布', '提交', '審核通過', '審核拒絕', '關閉'),
                    '，請及時處理。'
                            );

            -- 隨機創建者和更新者
            SET v_create_by = CONCAT('user', FLOOR(1 + RAND() * 10));
            SET v_update_by = CONCAT('user', FLOOR(1 + RAND() * 10));

            -- 隨機時間偏移（過去30天內）
            SET v_time_offset = FLOOR(RAND() * 30);

            -- 插入數據
            INSERT INTO `t_questionnaire_notice` (
                `id`, `question_id`, `trigger_point`, `recipient_type`, `recipient_email`,
                `title`, `content`, `create_by`, `create_time`, `update_by`, `update_time`
            ) VALUES (
                         v_id,
                         v_question_id,
                         v_trigger_point,
                         v_recipient_type,
                         v_recipient_email,
                         v_title,
                         v_content,
                         v_create_by,
                         DATE_SUB(NOW(), INTERVAL v_time_offset DAY),
                         v_update_by,
                         DATE_SUB(NOW(), INTERVAL (v_time_offset - FLOOR(RAND() * 3)) DAY)
                     );

            SET i = i + 1;
        END WHILE;

    COMMIT;

    -- 返回結果
    SELECT CONCAT('成功生成 ', p_record_count, ' 條隨機問卷通知數據') AS result;
END //

DELIMITER ;