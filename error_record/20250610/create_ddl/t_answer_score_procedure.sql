DELIMITER //

CREATE PROCEDURE `sp_init_answer_score_data`(
    IN p_record_count INT,          -- 要生成的记录数量
    IN p_answer_id_start BIGINT,    -- 起始答案ID
    IN p_answer_id_end BIGINT,      -- 结束答案ID
    IN p_user_count INT,            -- 用户数量范围
    IN p_subject_count INT          -- 题目数量范围
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_id BIGINT;
    DECLARE v_answer_id BIGINT;
    DECLARE v_answer_user_id VARCHAR(64);
    DECLARE v_subject_id BIGINT;
    DECLARE v_user_id VARCHAR(100);
    DECLARE v_user_name VARCHAR(100);
    DECLARE v_favor INT;
    DECLARE v_score INT;
    DECLARE v_comment VARCHAR(258);
    DECLARE v_userName VARCHAR(100);
    DECLARE v_create_time DATETIME;
    DECLARE v_update_time DATETIME;
    DECLARE v_days_offset INT;

    -- 错误处理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE,
                @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
            SELECT CONCAT('Error ', @errno, ' (', @sqlstate, '): ', @text) AS error_message;
            ROLLBACK;
        END;

    -- 清空表（如需保留数据，请移除这行）
    START TRANSACTION;
    TRUNCATE TABLE `t_answer_socre`;

    -- 生成随机数据
    WHILE i < p_record_count DO
            -- 生成唯一ID
            SET v_id = (SELECT IFNULL(MAX(id), 0) FROM `t_answer_socre`) + 1 + i;

            -- 随机选择答案ID
            SET v_answer_id = FLOOR(p_answer_id_start + RAND() * (p_answer_id_end - p_answer_id_start + 1));

            -- 随机生成答案用户ID
            SET v_answer_user_id = CONCAT('user', FLOOR(1 + RAND() * p_user_count));

            -- 随机题目ID
            SET v_subject_id = FLOOR(1 + RAND() * p_subject_count);

            -- 随机评分用户信息
            SET v_user_id = CONCAT('user', FLOOR(1 + RAND() * p_user_count));

            -- 确保评分用户不是答案用户
            WHILE v_user_id = v_answer_user_id DO
                    SET v_user_id = CONCAT('user', FLOOR(1 + RAND() * p_user_count));
                END WHILE;

            SET v_user_name = CONCAT(
                    ELT(FLOOR(1 + RAND() * 100) % 10 + 1, '王', '李', '张', '刘', '陈', '杨', '赵', '黄', '周', '吴'),
                    ELT(FLOOR(1 + RAND() * 100) % 10 + 1, '小明', '大华', '小美', '丽丽', '建国', '淑芬', '志强', '美丽', '建军', '淑惠')
                              );

            -- 随机点赞
            SET v_favor = IF(RAND() > 0.7, 1, 0);

            -- 随机评分（30%概率不评分）
            SET v_score = IF(RAND() > 0.3, FLOOR(RAND() * 5) + 1, -1);

            -- 随机评论（50%概率有评论）
            IF RAND() > 0.5 THEN
                SET v_comment = CONCAT(
                        ELT(FLOOR(1 + RAND() * 5), '这个回答很专业', '观点新颖', '分析到位', '有待改进', '非常有帮助'),
                        ELT(FLOOR(1 + RAND() * 5), '', '！', '。', '，建议补充更多细节', '，值得学习')
                                );
            ELSE
                SET v_comment = NULL;
            END IF;

            -- 被评分用户名
            SET v_userName = CONCAT(
                    ELT(FLOOR(1 + RAND() * 100) % 10 + 1, '王', '李', '张', '刘', '陈', '杨', '赵', '黄', '周', '吴'),
                    ELT(FLOOR(1 + RAND() * 100) % 10 + 1, '小明', '大华', '小美', '丽丽', '建国', '淑芬', '志强', '美丽', '建军', '淑惠')
                             );

            -- 随机时间（过去30天内）
            SET v_days_offset = FLOOR(RAND() * 30);
            SET v_create_time = DATE_SUB(NOW(), INTERVAL v_days_offset DAY);
            SET v_update_time = DATE_SUB(v_create_time, INTERVAL FLOOR(RAND() * 2) DAY);

            -- 插入数据
            INSERT INTO `t_answer_socre` (
                `id`, `answer_id`, `answer_user_id`, `subject_id`, `user_id`,
                `user_name`, `favor`, `score`, `comment`, `userName`,
                `create_time`, `update_time`
            ) VALUES (
                         v_id,
                         v_answer_id,
                         v_answer_user_id,
                         v_subject_id,
                         v_user_id,
                         v_user_name,
                         v_favor,
                         v_score,
                         v_comment,
                         v_userName,
                         v_create_time,
                         v_update_time
                     );

            SET i = i + 1;
        END WHILE;

    COMMIT;

    -- 返回结果
    SELECT CONCAT('成功生成 ', p_record_count, ' 条随机答案评分数据') AS result;
END //

DELIMITER ;