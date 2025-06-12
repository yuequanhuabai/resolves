DELIMITER //

CREATE PROCEDURE `sp_init_answer_data`(
    IN p_record_count INT,          -- 要生成的記錄數量
    IN p_question_id_start BIGINT,  -- 起始問卷ID
    IN p_question_id_end BIGINT,    -- 結束問卷ID
    IN p_user_count INT            -- 用戶數量範圍
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_id BIGINT;
    DECLARE v_question_id BIGINT;
    DECLARE v_question_code VARCHAR(64);
    DECLARE v_user_id VARCHAR(64);
    DECLARE v_user_name VARCHAR(64);
    DECLARE v_content JSON;
    DECLARE v_extend_info JSON;
    DECLARE v_status VARCHAR(16);
    DECLARE v_approver_id VARCHAR(16);
    DECLARE v_approver_name VARCHAR(32);
    DECLARE v_approve_status INT;
    DECLARE v_tag VARCHAR(16);
    DECLARE v_version INT;
    DECLARE v_total_score INT;
    DECLARE v_update_by VARCHAR(16);
    DECLARE v_updater_name VARCHAR(32);
    DECLARE v_create_time DATETIME;
    DECLARE v_update_time DATETIME;
    DECLARE v_days_offset INT;

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
    TRUNCATE TABLE `t_answer`;

    -- 生成隨機數據
    WHILE i < p_record_count DO
            -- 生成唯一ID
            SET v_id = (SELECT IFNULL(MAX(id), 0) FROM `t_answer`) + 1 + i;

            -- 隨機選擇問卷ID
            SET v_question_id = FLOOR(p_question_id_start + RAND() * (p_question_id_end - p_question_id_start + 1));

            -- 生成問卷代碼
            SET v_question_code = CONCAT('Q', LPAD(v_question_id, 4, '0'), '-', FLOOR(RAND() * 1000));

            -- 隨機用戶信息
            SET v_user_id = CONCAT('user', FLOOR(1 + RAND() * p_user_count));

            SET v_user_name = CONCAT(
                    ELT(FLOOR(1 + RAND() * 100) % 10 + 1, '王', '李', '張', '劉', '陳', '楊', '趙', '黃', '周', '吳'),
                    ELT(FLOOR(1 + RAND() * 100) % 10 + 1, '小明', '大華', '小美', '麗麗', '建國', '淑芬', '志強', '美麗', '建軍', '淑惠')
                              );

            -- 生成JSON格式的答案內容
            SET v_content = JSON_OBJECT(
                    'question1', CONCAT('答案', FLOOR(RAND() * 5) + 1),
                    'question2', ELT(FLOOR(1 + RAND() * 4), 'A', 'B', 'C', 'D'),
                    'question3', IF(RAND() > 0.5, 'true', 'false'),
                    'question4', CONCAT('這是用戶的文本回答，生成於', NOW())
                            );

            -- 生成擴展信息
            SET v_extend_info = JSON_OBJECT(
                    'device', ELT(FLOOR(1 + RAND() * 3), 'PC', 'Mobile', 'Tablet'),
                    'browser', ELT(FLOOR(1 + RAND() * 5), 'Chrome', 'Firefox', 'Safari', 'Edge', 'Opera'),
                    'ip', CONCAT(
                            FLOOR(RAND() * 255), '.',
                            FLOOR(RAND() * 255), '.',
                            FLOOR(RAND() * 255), '.',
                            FLOOR(RAND() * 255)
                          ),
                    'timeSpent', FLOOR(RAND() * 600) + 30  -- 30-630秒
                                );

            -- 隨機狀態
            SET v_status = IF(RAND() > 0.3, '1', '0');

            -- 審批相關信息（只有已提交的答案才可能有審批信息）
            IF v_status = '1' THEN
                SET v_approver_id = CONCAT('mgr', FLOOR(1 + RAND() * 5));
                SET v_approver_name = CONCAT('管理員', ELT(FLOOR(1 + RAND() * 5), 'A', 'B', 'C', 'D', 'E'));
                SET v_approve_status = ELT(FLOOR(1 + RAND() * 3), 0, 1, -1);
            ELSE
                SET v_approver_id = NULL;
                SET v_approver_name = NULL;
                SET v_approve_status = NULL;
            END IF;

            -- 隨機標籤
            SET v_tag = ELT(FLOOR(1 + RAND() * 6), NULL, 'urgent', 'important', 'review', 'followup', 'rejected');

            -- 版本號和分數
            SET v_version = FLOOR(RAND() * 3) + 1;
            SET v_total_score = IF(v_status = '1', FLOOR(RAND() * 100), NULL);

            -- 更新者信息
            SET v_update_by = IF(RAND() > 0.7, CONCAT('sys', FLOOR(1 + RAND() * 3)), v_user_id);
            SET v_updater_name = IF(v_update_by = v_user_id, v_user_name, CONCAT('系統', ELT(FLOOR(1 + RAND() * 3), 'A', 'B', 'C')));

            -- 隨機時間（過去30天內）
            SET v_days_offset = FLOOR(RAND() * 30);
            SET v_create_time = DATE_SUB(NOW(), INTERVAL v_days_offset DAY);
            SET v_update_time = DATE_SUB(v_create_time, INTERVAL FLOOR(RAND() * 3) DAY);

            -- 插入數據
            INSERT INTO `t_answer` (
                `id`, `question_id`, `question_code`, `user_id`, `user_name`,
                `content`, `extend_info`, `status`, `approver_id`, `approver_name`,
                `approve_status`, `tag`, `version`, `total_score`, `create_time`,
                `update_by`, `updater_name`, `update_time`, `delete_flag`
            ) VALUES (
                         v_id,
                         v_question_id,
                         v_question_code,
                         v_user_id,
                         v_user_name,
                         v_content,
                         v_extend_info,
                         v_status,
                         v_approver_id,
                         v_approver_name,
                         v_approve_status,
                         v_tag,
                         v_version,
                         v_total_score,
                         v_create_time,
                         v_update_by,
                         v_updater_name,
                         v_update_time,
                         0  -- 默認未刪除
                     );

            SET i = i + 1;
        END WHILE;

    COMMIT;

    -- 返回結果
    SELECT CONCAT('成功生成 ', p_record_count, ' 條隨機答案數據') AS result;
END //

DELIMITER ;