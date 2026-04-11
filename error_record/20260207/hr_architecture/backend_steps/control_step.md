# 後端實施步驟 · 總控

本文件是後端實施的**索引入口**，僅列階段、Step 標題與進度。
每個階段的詳細內容在對應的 `pN.md` 檔案中，修改時只讀取所需階段檔即可。

---

## 整體進度

```
階段一 (Step 1-3)   項目骨架 + 數據庫          ██████████  ✅ 已完成    Day 1-2
階段二 (Step 4-6)   公共模塊                   █████████░  🔄 進行中    Day 2-3
階段三 (Step 7-11)  框架模塊 (安全/認證/攔截)    ██████████  ✅ 已完成    Day 3-5
階段四 (Step 12-18) 業務模塊 (核心 CRUD)        ███░░░░░░░  🔄 進行中    Day 5-9
階段五 (Step 19-20) 認證 + 內部接口             ░░░░░░░░░░  ⏳ 待開始    Day 9-10
階段六 (Step 21-22) 文檔 + 測試                ░░░░░░░░░░  ⏳ 待開始    Day 10-11
階段七 (Step 23)    初始化數據                  ░░░░░░░░░░  ⏳ 待開始    Day 11
```

圖例：✅ 已完成　🔄 進行中　⏳ 待開始　⏸️ 暫停

---

## 階段 ↔ 檔案對照

| 階段 | 檔案 | Step 範圍 |
|---|---|---|
| 階段一 項目初始化 | [phase1_skeleton_db.md](./phase1_skeleton_db.md) | Step 1 ~ 3 |
| 階段二 公共模塊 | [phase2_common.md](./phase2_common.md) | Step 4 ~ 6 |
| 階段三 框架模塊 | [phase3_framework.md](./phase3_framework.md) | Step 7 ~ 11 |
| 階段四 業務模塊 | [phase4_business.md](./phase4_business.md) | Step 12 ~ 18 |
| 階段五 認證接口 | [phase5_auth_internal.md](./phase5_auth_internal.md) | Step 19 ~ 20 |
| 階段六 文檔測試 | [phase6_docs_test.md](./phase6_docs_test.md) | Step 21 ~ 22 |
| 階段七 初始化數據 | [phase7_init_data.md](./phase7_init_data.md) | Step 23 |

---

## Step 清單與進度

### 階段一：項目初始化 → [phase1_skeleton_db.md](./phase1_skeleton_db.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 1 | 創建 Maven 多模塊項目 | ✅ |
| 2 | 配置 hr-admin 啟動模塊 | ✅ |
| 3 | 創建 SQL Server 數據庫 | ✅ |

### 階段二：公共模塊 (hr-common) → [phase2_common.md](./phase2_common.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 4 | 基礎設施 (BaseEntity / R / PageResult / PageQuery / Constants / 枚舉) | ✅ |
| 5 | 異常處理 (BusinessException / GlobalExceptionHandler) | ✅ |
| 6 | 工具類 (TreeUtils) ※ SecurityUtils 移至 Step 8 | 🔄 |

### 階段三：框架模塊 (hr-framework) → [phase3_framework.md](./phase3_framework.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 7 | Redis 配置 | ✅ |
| 8 | MyBatis-Plus 配置 | ✅ |
| 9 | Spring Security + JWT | ✅ |
| 10 | 跨域配置 | ✅ |
| 11 | 操作日誌 | ✅ |

### 階段四：業務模塊 (hr-system) → [phase4_business.md](./phase4_business.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 12 | 實體類 | ✅ |
| 13 | 部門管理 | ✅ |
| 14 | 崗位管理 | ⏳ |
| 15 | 菜單管理 | ⏳ |
| 16 | 角色管理 | ⏳ |
| 17 | 用戶管理 | ⏳ |
| 18 | 數據權限攔截器 | ⏳ |

### 階段五：認證接口 (hr-admin) → [phase5_auth_internal.md](./phase5_auth_internal.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 19 | 登入/登出 | ⏳ |
| 20 | 內部接口 (為流程引擎預留) | ⏳ |

### 階段六：API 文檔 + 測試 → [phase6_docs_test.md](./phase6_docs_test.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 21 | Knife4j 集成 | ⏳ |
| 22 | 接口測試 | ⏳ |

### 階段七：初始化數據腳本 → [phase7_init_data.md](./phase7_init_data.md)

| Step | 標題 | 狀態 |
|---|---|---|
| 23 | 編寫初始化 SQL | ⏳ |

---

## 關鍵里程碑

| 里程碑 | 驗收標準 |
|---|---|
| M1: 項目能跑 | Spring Boot 啟動成功，連接 SQL Server + Redis |
| M2: 能登入 | 帳號密碼登入 → 返回 Token → Token 訪問受保護接口 |
| M3: CRUD 通 | 用戶/角色/部門/崗位/菜單 全部 CRUD 接口可用 |
| M4: 權限生效 | 角色權限分配 + 數據權限過濾 正常工作 |
| M5: 後端完成 | API 文檔完整，初始化數據就緒，可交付前端對接 |

---

## 使用約定

- **未來對話開頭**：僅載入本文件 `control_step.md` 了解全局
- **修改某階段**：只讀取對應的 `pN.md`，不載入其他階段檔
- **原始備份**：根目錄 `backend_steps.md` 保留不動（用戶自行處理）
