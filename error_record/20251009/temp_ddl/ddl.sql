-- oauth2.oauth2_authorization definition

CREATE TABLE `oauth2_authorization` (
                                        `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
                                        `registered_client_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
                                        `principal_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
                                        `authorization_grant_type` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
                                        `authorized_scopes` text COLLATE utf8mb4_unicode_ci,
                                        `attributes` text COLLATE utf8mb4_unicode_ci,
                                        `state` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
                                        `authorization_code_value` text COLLATE utf8mb4_unicode_ci,
                                        `authorization_code_issued_at` timestamp NULL DEFAULT NULL,
                                        `authorization_code_expires_at` timestamp NULL DEFAULT NULL,
                                        `authorization_code_metadata` text COLLATE utf8mb4_unicode_ci,
                                        `access_token_value` text COLLATE utf8mb4_unicode_ci,
                                        `access_token_issued_at` timestamp NULL DEFAULT NULL,
                                        `access_token_expires_at` timestamp NULL DEFAULT NULL,
                                        `access_token_metadata` text COLLATE utf8mb4_unicode_ci,
                                        `access_token_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
                                        `access_token_scopes` text COLLATE utf8mb4_unicode_ci,
                                        `oidc_id_token_value` text COLLATE utf8mb4_unicode_ci,
                                        `oidc_id_token_issued_at` timestamp NULL DEFAULT NULL,
                                        `oidc_id_token_expires_at` timestamp NULL DEFAULT NULL,
                                        `oidc_id_token_metadata` text COLLATE utf8mb4_unicode_ci,
                                        `oidc_id_token_claims` text COLLATE utf8mb4_unicode_ci,
                                        `refresh_token_value` text COLLATE utf8mb4_unicode_ci,
                                        `refresh_token_issued_at` timestamp NULL DEFAULT NULL,
                                        `refresh_token_expires_at` timestamp NULL DEFAULT NULL,
                                        `refresh_token_metadata` text COLLATE utf8mb4_unicode_ci,
                                        `user_code_value` text COLLATE utf8mb4_unicode_ci,
                                        `user_code_issued_at` timestamp NULL DEFAULT NULL,
                                        `user_code_expires_at` timestamp NULL DEFAULT NULL,
                                        `user_code_metadata` text COLLATE utf8mb4_unicode_ci,
                                        `device_code_value` text COLLATE utf8mb4_unicode_ci,
                                        `device_code_issued_at` timestamp NULL DEFAULT NULL,
                                        `device_code_expires_at` timestamp NULL DEFAULT NULL,
                                        `device_code_metadata` text COLLATE utf8mb4_unicode_ci,
                                        `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
                                        `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                        PRIMARY KEY (`id`),
                                        KEY `idx_registered_client_id` (`registered_client_id`),
                                        KEY `idx_principal_name` (`principal_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='OAuth2授权信息表';


-- oauth2.oauth2_authorization_consent definition

CREATE TABLE `oauth2_authorization_consent` (
                                                `registered_client_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
                                                `principal_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
                                                `authorities` text COLLATE utf8mb4_unicode_ci NOT NULL,
                                                `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
                                                `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                                PRIMARY KEY (`registered_client_id`,`principal_name`),
                                                KEY `idx_principal_name` (`principal_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='OAuth2用户授权同意表';


-- oauth2.oauth2_client definition

CREATE TABLE `oauth2_client` (
                                 `id` bigint NOT NULL AUTO_INCREMENT,
                                 `client_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '瀹㈡埛绔?敮涓?爣璇嗙?',
                                 `client_secret` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '瀹㈡埛绔?瘑閽ワ紝BCrypt鍔犲瘑瀛樺偍',
                                 `client_name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '瀹㈡埛绔?簲鐢ㄥ悕绉',
                                 `redirect_uri` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '鎺堟潈鍥炶皟鍦板潃锛岄槻姝㈡巿鏉冨姭鎸',
                                 `scopes` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT 'read' COMMENT '鏉冮檺鑼冨洿锛岄?鍙峰垎闅旓紝闃叉?瓒婃潈璁块棶',
                                 `is_active` tinyint(1) DEFAULT '1' COMMENT '鏄?惁鍚?敤锛屾敮鎸佸揩閫熺?鐢ㄥ?鎴风?',
                                 `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '鍒涘缓鏃堕棿',
                                 `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '鏈?悗鏇存柊鏃堕棿',
                                 PRIMARY KEY (`id`),
                                 UNIQUE KEY `client_id` (`client_id`),
                                 KEY `idx_client_id` (`client_id`),
                                 KEY `idx_client_name` (`client_name`),
                                 KEY `idx_is_active` (`is_active`),
                                 KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='OAuth2瀹㈡埛绔?敞鍐岃〃';


-- oauth2.users definition

CREATE TABLE `users` (
                         `id` bigint NOT NULL AUTO_INCREMENT,
                         `username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户名',
                         `password` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'BCrypt加密存储的密码',
                         `enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT '账户是否启用',
                         `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                         `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
                         PRIMARY KEY (`id`),
                         UNIQUE KEY `username` (`username`),
                         KEY `idx_username` (`username`),
                         KEY `idx_enabled` (`enabled`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表-OAuth2演示用';