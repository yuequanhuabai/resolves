# 人事管理系統 — 核心總體架構文檔

## 一、系統定位

人事管理系統是微服務體系中的**基礎服務模塊**，承擔三大職責：

- **統一認證中心**：所有子系統的登入、Token 簽發、身份校驗
- **統一權限管理**：用戶、角色、菜單權限、數據權限的集中維護
- **組織架構服務**：部門、崗位數據，供其它微服務（如流程引擎）調用

當前以 Spring Boot 單體交付，模塊邊界按微服務標準劃分，後期可平滑升級至 Spring Cloud。

---

## 二、技術棧總覽

| 層級 | 技術選型 | 版本 |
|------|---------|------|
| 後端框架 | Spring Boot | 3.2+ |
| JDK | OpenJDK | 17 |
| ORM | MyBatis-Plus | 3.5+ |
| 認證授權 | Spring Security + JWT | - |
| 數據庫 | SQL Server | 2019+ |
| 緩存 | Redis | 7+ |
| 構建工具 | Maven (多模塊) | 3.9+ |
| API 文檔 | Knife4j (Swagger 增強) | 4.x |
| 前端框架 | Vue 3 + Element Plus | 3.4+ / 2.x |
| 前端構建 | Vite | 5.x |
| 前端狀態 | Pinia | 2.x |
| 前端路由 | Vue Router | 4.x |
| HTTP 請求 | Axios | 1.x |

---

## 三、核心實體關係

```
┌───────────┐      N:N       ┌───────────┐      N:N       ┌───────────┐
│  sys_user │───────────────▶│ sys_role   │───────────────▶│ sys_menu  │
│  (用戶)   │  sys_user_role │  (角色)    │  sys_role_menu │ (菜單/權限)│
└─────┬─────┘                └─────┬─────┘                └───────────┘
      │ N:1                        │ N:N
      ▼                            ▼
┌───────────┐                ┌───────────┐
│ sys_dept  │                │sys_role_dept│
│  (部門)   │◀───────────────│(角色數據權限)│
└─────┬─────┘                └───────────┘
      │ 自引用 (parent_id)
      ▼
   [樹形結構]

┌───────────┐      N:1       ┌───────────┐
│  sys_user │───────────────▶│ sys_post   │
│  (用戶)   │                │  (崗位)    │
└───────────┘                └───────────┘
```

### 關係說明

| 關係 | 類型 | 中間表 | 說明 |
|------|------|--------|------|
| 用戶 ↔ 角色 | N:N | sys_user_role | 一個用戶可擁有多個角色 |
| 角色 ↔ 菜單 | N:N | sys_role_menu | 一個角色可關聯多個菜單/按鈕權限 |
| 角色 ↔ 部門 | N:N | sys_role_dept | 自定義數據權限範圍 |
| 用戶 → 部門 | N:1 | - | 一個用戶隸屬一個部門 |
| 用戶 → 崗位 | N:1 | - | 一個用戶擔任一個崗位 |
| 部門 → 部門 | 自引用 | - | parent_id 構成樹形結構 |
| 菜單 → 菜單 | 自引用 | - | parent_id 構成樹形結構 |

---

## 四、系統模塊劃分

```
human-resource/
│
├── hr-backend/                          # 後端 (Maven 父工程)
│   ├── pom.xml                          # 父 POM，統一依賴版本
│   │
│   ├── hr-common/                       # 公共模塊
│   │   ├── 通用工具類 (日期、字符串、樹形構建)
│   │   ├── 統一響應體 (R<T>)
│   │   ├── 通用異常 + 全局異常處理器
│   │   ├── 基礎實體 (BaseEntity: createTime, updateTime, deleted)
│   │   └── 常量定義
│   │
│   ├── hr-framework/                    # 框架模塊
│   │   ├── Spring Security 配置
│   │   ├── JWT Token 工具
│   │   ├── 數據權限攔截器 (MyBatis Interceptor)
│   │   ├── 操作日誌 AOP
│   │   ├── Redis 配置
│   │   └── 跨域配置
│   │
│   ├── hr-system/                       # 業務模塊 (核心)
│   │   ├── domain/                      # 實體類
│   │   ├── mapper/                      # MyBatis Mapper
│   │   ├── service/                     # 業務接口
│   │   ├── service/impl/               # 業務實現
│   │   └── dto/                         # 數據傳輸對象
│   │
│   └── hr-admin/                        # 啟動模塊
│       ├── HrApplication.java           # 啟動類
│       ├── controller/                  # 控制器層
│       │   ├── system/                  # 系統管理接口
│       │   │   ├── SysUserController
│       │   │   ├── SysRoleController
│       │   │   ├── SysDeptController
│       │   │   ├── SysPostController
│       │   │   └── SysMenuController
│       │   └── auth/                    # 認證接口
│       │       └── AuthController
│       └── application.yml              # 配置文件
│
└── hr-ui/                               # 前端 (Vue 3 獨立 SPA)
    ├── src/
    │   ├── api/                         # 接口請求
    │   ├── views/                       # 頁面
    │   ├── components/                  # 公共組件
    │   ├── router/                      # 路由 (含動態路由)
    │   ├── store/                       # Pinia 狀態管理
    │   ├── utils/                       # 工具函數
    │   ├── directive/                   # 自定義指令 (權限按鈕)
    │   └── layout/                      # 佈局框架
    └── vite.config.ts                   # 構建配置
```

### 模塊依賴關係

```
hr-admin → hr-system → hr-framework → hr-common
   ↑            ↑            ↑            ↑
 啟動+API     業務邏輯     框架能力      基礎工具
```

每個模塊職責單一，後期升級 Spring Cloud 時：
- `hr-admin` + `hr-system` → 人事微服務
- `hr-framework` → 抽取為公共安全 Starter
- 新增 Gateway 模塊 + Nacos 配置

---

## 五、認證授權架構

### 5.1 認證流程

```
[用戶登入] → AuthController.login()
    │
    ├── 1. 校驗帳號密碼 (Spring Security AuthenticationManager)
    ├── 2. 查詢用戶角色 + 權限列表
    ├── 3. 生成 JWT Token (含 userId, username)
    ├── 4. 用戶信息 + 權限緩存至 Redis (key: login_token:{uuid})
    └── 5. 返回 Token 給前端

[後續請求] → JwtAuthenticationFilter
    │
    ├── 1. 從 Header 提取 Token
    ├── 2. 解析 Token 獲取 uuid
    ├── 3. 從 Redis 獲取用戶信息 + 權限
    ├── 4. 設入 SecurityContextHolder
    └── 5. 放行至 Controller
```

### 5.2 權限控制

```
接口級：@PreAuthorize("@perm.hasPerms('sys:user:list')")
按鈕級：前端 v-hasPerms="['sys:user:add']" 自定義指令
數據級：MyBatis 攔截器自動拼接 WHERE 條件
```

### 5.3 數據權限範圍

| data_scope 值 | 含義 | SQL 拼接邏輯 |
|---------------|------|-------------|
| 1 | 全部數據 | 無過濾 |
| 2 | 自定義數據 | `dept_id IN (sys_role_dept 中配置)` |
| 3 | 本部門數據 | `dept_id = 當前用戶.dept_id` |
| 4 | 本部門及以下 | `dept_id IN (ancestors LIKE '當前部門%')` |
| 5 | 僅本人數據 | `user_id = 當前用戶.user_id` |

---

## 六、前後端交互

### 6.1 開發環境

```
Vue Dev Server (5173) ──proxy──▶ Spring Boot (8080)
         │                              │
       瀏覽器                        SQL Server + Redis
```

### 6.2 生產環境

```
瀏覽器 ──▶ Nginx
              ├── /           → Vue 靜態文件
              └── /api/**     → 反向代理 → Spring Boot (8080)
                                              │
                                        SQL Server + Redis
```

### 6.3 API 規範

```
統一響應格式：
{
  "code": 200,        // 200 成功，401 未認證，403 無權限，500 錯誤
  "msg": "操作成功",
  "data": { ... }
}

接口命名規範：
GET    /api/system/user          # 分頁查詢用戶列表
GET    /api/system/user/{id}     # 查詢用戶詳情
POST   /api/system/user          # 新增用戶
PUT    /api/system/user          # 修改用戶
DELETE /api/system/user/{id}     # 刪除用戶

認證接口：
POST   /api/auth/login           # 登入
POST   /api/auth/logout          # 登出
GET    /api/auth/info            # 獲取當前用戶信息 + 權限
GET    /api/auth/routers         # 獲取當前用戶動態路由
```

---

## 七、未來 Spring Cloud 升級路徑

### 當前 (Spring Boot 單體)

```
[Nginx] → [hr-admin (內含所有模塊)] → [SQL Server] + [Redis]
```

### 未來 (Spring Cloud 微服務)

```
[Nginx] → [Gateway 網關]
               │
      ┌────────┼────────┐
      ▼        ▼        ▼
  [人事服務] [流程引擎] [其它服務]
      │        │        │
      └────────┼────────┘
               ▼
          [Nacos 註冊/配置中心]
               │
      ┌────────┼────────┐
      ▼        ▼        ▼
  [SQL Server] [Redis]  [MQ]
```

### 升級改動點

| 改動項 | 具體操作 |
|--------|---------|
| 新增 Gateway | 新建模塊，路由轉發 + 統一鑒權 |
| 新增 Nacos | 引入依賴，application.yml 遷移至 Nacos |
| 服務間調用 | Service 接口調用 → OpenFeign 遠程調用 |
| 數據庫 | 共享實例 → 按服務拆分 Schema 或實例 |
| hr-framework | 抽取為公共 Starter，各服務依賴 |
| 流程引擎 | 新建獨立微服務，Feign 調用人事服務獲取用戶/部門數據 |

---

## 八、為流程引擎預留的集成點

人事服務需對外暴露以下內部接口（當前為本地調用，後期升級為 Feign 接口）：

| 接口 | 用途 | 調用方 |
|------|------|--------|
| `GET /api/internal/user/{id}` | 查詢用戶基本信息 | 流程引擎 (審批人) |
| `GET /api/internal/user/dept/{deptId}` | 查詢部門下所有用戶 | 流程引擎 (部門審批) |
| `GET /api/internal/dept/{id}` | 查詢部門信息 | 流程引擎 (部門流轉) |
| `GET /api/internal/dept/{id}/leader` | 查詢部門負責人 | 流程引擎 (上級審批) |
| `GET /api/internal/role/{roleKey}/users` | 查詢角色下所有用戶 | 流程引擎 (角色審批) |

這些接口在當前單體中以 Controller 形式存在，升級微服務後抽取為 Feign Client 接口。
