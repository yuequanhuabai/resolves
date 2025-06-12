DELIMITER //

CREATE PROCEDURE `sp_init_questionnaire_user_random`(
    IN p_record_count INT,  -- 要生成的記錄數量
    IN p_question_id_start BIGINT,  -- 起始問卷ID
    IN p_question_id_end BIGINT,    -- 結束問卷ID
    IN p_admin_ratio DECIMAL(3,2)   -- 管理員比例 (0.00-1.00)
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_id BIGINT;
    DECLARE v_question_id BIGINT;
    DECLARE v_user_type INT;
    DECLARE v_user_id VARCHAR(16);
    DECLARE v_user_name VARCHAR(32);
    DECLARE v_email VARCHAR(32);
    DECLARE v_create_by VARCHAR(16);
    DECLARE v_base_id BIGINT;

    -- 錯誤處理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE,
                @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
            SELECT CONCAT('Error ', @errno, ' (', @sqlstate, '): ', @text) AS error_message;
            ROLLBACK;
        END;

    -- 清空表
    START TRANSACTION;
    TRUNCATE TABLE `t_questionnaire_user`;

    -- 獲取當前最大ID作為基礎
    SELECT IFNULL(MAX(id), 0) + 1 INTO v_base_id FROM `t_questionnaire_user`;

    -- 生成隨機數據
    WHILE i < p_record_count DO
            -- 改進的ID生成方式，確保唯一性
            SET v_id = v_base_id + i;

            -- 隨機選擇問卷ID
            SET v_question_id = FLOOR(p_question_id_start + RAND() * (p_question_id_end - p_question_id_start + 1));

            -- 根據比例決定用戶類型
            IF RAND() < p_admin_ratio THEN
                SET v_user_type = 0;  -- 管理員
            ELSE
                SET v_user_type = 1;  -- 限定回答用戶
            END IF;

            -- 生成隨機用戶ID
            SET v_user_id = CONCAT('user', FLOOR(RAND() * 90000) + 10000);

            -- 生成隨機中文名
            SET v_user_name = CONCAT(
                    ELT(FLOOR(1 + RAND() * 100) % 10 + 1, '王', '李', '張', '劉', '陳', '楊', '趙', '黃', '周', '吳'),
                    ELT(FLOOR(1 + RAND() * 100) % 10 + 1, '強', '偉', '芳', '秀英', '娜', '敏', '靜', '麗', '軍', '傑')
                              );

            -- 生成隨機郵箱
            SET v_email = CONCAT(
                    SUBSTRING(MD5(RAND()), 1, 8),
                    '@',
                    ELT(FLOOR(1 + RAND() * 5), 'example.com', 'test.com', 'demo.com', 'sample.com', 'mail.com')
                          );

            -- 隨機創建者
            SET v_create_by = ELT(FLOOR(1 + RAND() * 3), 'system', 'admin', 'auto');

            -- 動態插入數據
            SET @sql = CONCAT('
            INSERT INTO `t_questionnaire_user`
            (`id`, `question_id`, `user_type`, `user_id`, `user_name`, `email`, `create_by`, `create_time`)
            VALUES (',
                              v_id, ', ',
                              v_question_id, ', ',
                              v_user_type, ', ',
                              QUOTE(v_user_id), ', ',
                              QUOTE(v_user_name), ', ',
                              QUOTE(v_email), ', ',
                              QUOTE(v_create_by), ', ',
                              'NOW()',
                              ')');

            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;

            SET i = i + 1;
        END WHILE;

    COMMIT;

    -- 返回結果
    SELECT CONCAT('成功生成 ', p_record_count, ' 條隨機問卷用戶數據') AS result;
END //

DELIMITER ;