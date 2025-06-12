DELIMITER //

CREATE PROCEDURE `sp_init_questionnaire_favorite`(
    IN p_record_count INT,          -- 要生成的記錄數量
    IN p_question_id_start BIGINT,  -- 起始問卷ID
    IN p_question_id_end BIGINT,    -- 結束問卷ID
    IN p_user_count INT            -- 用戶數量範圍
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_id BIGINT;
    DECLARE v_question_id BIGINT;
    DECLARE v_user_id VARCHAR(16);
    DECLARE v_user_name VARCHAR(32);
    DECLARE v_base_id BIGINT;

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
    TRUNCATE TABLE `t_questionnaire_favorite`;

    -- 獲取當前最大ID作為基礎
    SELECT IFNULL(MAX(id), 0) + 1 INTO v_base_id FROM `t_questionnaire_favorite`;

    -- 生成隨機數據
    WHILE i < p_record_count DO
            -- 生成唯一ID
            SET v_id = v_base_id + i;

            -- 隨機選擇問卷ID
            SET v_question_id = FLOOR(p_question_id_start + RAND() * (p_question_id_end - p_question_id_start + 1));

            -- 生成隨機用戶ID和姓名
            SET v_user_id = CONCAT('user', FLOOR(1 + RAND() * p_user_count));

            SET v_user_name = CONCAT(
                    ELT(FLOOR(1 + RAND() * 100) % 10 + 1, '王', '李', '張', '劉', '陳', '楊', '趙', '黃', '周', '吳'),
                    ELT(FLOOR(1 + RAND() * 100) % 10 + 1, '小明', '大華', '小美', '麗麗', '建國', '淑芬', '志強', '美麗', '建軍', '淑惠')
                              );

            -- 動態插入數據
            INSERT INTO `t_questionnaire_favorite`
            (`id`, `question_id`, `user_id`, `user_name`, `create_time`)
            VALUES (
                       v_id,
                       v_question_id,
                       v_user_id,
                       v_user_name,
                       DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY)  -- 隨機創建時間（過去一年內）
                   );

            SET i = i + 1;
        END WHILE;

    COMMIT;

    -- 返回結果
    SELECT CONCAT('成功生成 ', p_record_count, ' 條隨機問卷收藏數據') AS result;
END //

DELIMITER ;