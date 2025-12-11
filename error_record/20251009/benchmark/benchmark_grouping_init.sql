INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'FI', NULL, N'Fixed Income', N'Fixed Income', 1, 1);

-- Level 2: Government Debt (has level 3 children)
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'FI_GD', N'FI', N'Government Debt', N'Government Debt', 2, 1);

-- Level 3: EUR Government Bonds
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'FI_GD_EUR', N'FI_GD', N'EUR Bonds', N'EUR Government Bonds', 3, 1);

-- Level 3: Non-EUR Government Bonds
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'FI_GD_NEUR', N'FI_GD', N'Non-EUR Bonds', N'Non-EUR Government Bonds', 3, 2);

-- Level 2: Corporate Debt (leaf node, no level 3 children)
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'FI_CD', N'FI', N'Corporate Debt', N'Corporate Debt', 2, 2);

-- Level 1: Equity
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'EQUITY', NULL, N'Equity', N'Equity', 1, 2);

-- Level 2: Developed Markets (has level 3 children)
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'EQUITY_DM', N'EQUITY', N'Developed Markets', N'Developed Markets', 2, 1);

-- Level 3: Europe Equity
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'EQUITY_DM_EU', N'EQUITY_DM', N'Europe', N'Europe Equity', 3, 1);

-- Level 3: North America Equity
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'EQUITY_DM_NA', N'EQUITY_DM', N'North America', N'North America Equity', 3, 2);

-- Level 2: Emerging Markets (leaf node, no level 3 children)
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'EQUITY_EM', N'EQUITY', N'Emerging Markets', N'Emerging Markets', 2, 2);

-- Level 1: Alternatives
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'ALT', NULL, N'Alternatives', N'Alternatives', 1, 3);

-- Level 2: Hedge Funds (leaf node, no level 3 children)
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'ALT_HF', N'ALT', N'Hedge Funds', N'Hedge Funds', 2, 1);

-- Level 1: Alternatives
INSERT INTO benchmark_grouping (id, componentId, parentComponentId, componentName, description, asset_level, sort_order)
VALUES (NEWID(), N'ALT2', NULL, N'Alte22', N'Alte222', 1, 4);