SELECT business_id,id  from buy_list order by business_id  ;



-- Bond
INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code,client_id)
VALUES (newid(), N'PVBLIST_BND_THM_1', N'5BDE9E3B-E62E-4649-BB6E-6EB2B9255FD3', 0, N'Bond', NULL,NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code,client_id)
VALUES (newid(), N'PVBLIST_BND_THM_2', N'070DCBEA-FC90-4A78-92DD-CAA4359B1B62', 0, N'Bond', NULL,NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code,client_id)
VALUES (newid(), N'PVBLIST_BND_THM_3', N'D76FD9DA-7EB7-407F-B98A-E1E2F17844CD', 0, N'Bond', NULL,NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code,client_id)
VALUES (newid(), N'PVBLIST_BND_TOP', N'070DCBEA-FC90-4A78-92DD-CAA4359B1B62', 0, N'Bond', NULL,NULL);

--Equities
INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code,client_id)
VALUES (newid(), N'PVBLIST_EQ_THM_1', N'A2811AD0-434D-4928-B22D-318AA6C48C28', 0, N'Equities', NULL,NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code,client_id)
VALUES (newid(), N'PVBLIST_EQ_THM_2', N'B349F52D-AD60-479D-B8EF-E18D6C4C5085', 0, N'Equities', NULL,NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code,client_id)
VALUES (newid(), N'PVBLIST_EQ_THM_3', N'9FF789B6-7E30-4113-AEAA-338AC6BA0940', 0, N'Equities', NULL,NULL);

--Fund
INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code,client_id)
VALUES (newid(), N'PVBLIST_FND_THM_1', N'E5F0A2D5-F85A-49F6-AA02-C3D6C2729006', 0, N'Fund', NULL,NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code,client_id)
VALUES (newid(), N'PVBLIST_FND_THM_2', N'B349F52D-AD60-479D-B8EF-E18D6C4C5085', 0, N'Fund', NULL,NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code,client_id)
VALUES (newid(), N'PVBLIST_FND_THM_3', N'3ECCD123-ABB8-45A0-ABBD-BEDEA27D858A', 0, N'Fund', NULL,NULL);

INSERT INTO buy_list_details
(id, business_id, buy_list_id, record_version, asset_type, product_code,client_id)
VALUES (newid(), N'PVBLIST_FND_FOCUS', N'8E3D8682-8ECB-4008-917E-3E56C7FE43AF', 0, N'Fund', NULL,NULL);
