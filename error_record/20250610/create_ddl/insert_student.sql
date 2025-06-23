DELIMITER //

CREATE PROCEDURE sp_batch_insert_student(IN record_count INT)
BEGIN
    DECLARE i INT DEFAULT 0;

    -- 檢查輸入參數是否有效
    IF record_count <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Record count must be positive';
    END IF;

    -- 開始事務
    START TRANSACTION;

    -- 循環插入記錄
    WHILE i < record_count DO
            INSERT INTO student (id, name)
            VALUES (
                       UUID(),
                       CONCAT('Student_', SUBSTRING(MD5(RAND()), 1, 8))
                   );
            SET i = i + 1;
        END WHILE;

    -- 提交事務
    COMMIT;
END //

DELIMITER ;