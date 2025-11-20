先不説詳情，如果是前後端分離，前端是react的spa，後端用java17的springboot實現，是不是要client和server都需要一個前端和一個後端，總共四個倉庫

● 不是四個倉庫，實際上的架構是這樣的：

架構圖

┌─────────────────────────────────────────────────────────┐
│                   你的 OAuth 2.0 系統                     │
└─────────────────────────────────────────────────────────┘

┌──────────────────────┐          ┌──────────────────────┐
│   Authorization      │          │   Resource Client    │
│   Server (AS)        │          │   (你的應用)          │
├──────────────────────┤          ├──────────────────────┤
│ 後端: SpringBoot     │          │ 後端: SpringBoot     │
│ - /authorize         │          │ - /login             │
│ - /token             │          │ - /callback          │
│ - /userinfo          │          │ - /api/*             │
│ - 用户數據庫         │          │ - 業務邏輯           │
├──────────────────────┤          ├──────────────────────┤
│ 前端: React SPA      │          │ 前端: React SPA      │
│ - 登錄界面           │          │ - 業務頁面           │
│ - 授權確認屏幕       │          │ - 主應用程序         │
└──────────────────────┘          └──────────────────────┘

倉庫劃分（3 個倉庫）

1. Authorization Server 倉庫
   oauth2-server/
   ├── backend/          (SpringBoot)
   │   ├── /authorize
   │   ├── /token
   │   ├── /userinfo
   │   └── 用户認證
   └── frontend/         (React SPA)
   ├── 登錄頁面
   └── 授權確認屏幕

2. Resource Client 倉庫（你的應用）
   my-app/
   ├── backend/          (SpringBoot)
   │   ├── /login
   │   ├── /callback
   │   ├── 業務 API
   │   └── Token 存儲
   └── frontend/         (React SPA)
   ├── 登錄入口
   ├── 業務頁面
   └── Token 管理

3. 共享庫（可選）
   oauth2-common/       (Java 工具類)
   ├── JWT 驗證
   ├── Token 工具
   └── 常量定義

流程中的角色分配

用户操作                前端                後端              Authorization Server
│
├─ 點擊登錄  ──>  MyApp Frontend
│                     │
│              重定向到 AS frontend
│              (展示登錄頁)
│                     ├────────────────>  AS Frontend
│
│              用户在 AS 登錄
│                     │<─────────────────  AS Frontend
│
├─ 授權確認   ──>  AS Frontend
│                     │
│                     └──────────────────> AS Backend
│                     │  (驗證身份)
│                     │
│              生成授權碼並重定向
│              回到 MyApp 的 /callback
│                     │<─────────────────  AS Backend
│
│  (回到 MyApp)      │
│  /callback?code=xxx
│                     │
│                     └──────────────────> MyApp Backend
│                     │  (調用 /token)
│                     │
│                     └──────────────────> AS Backend
│                     │  (/token)
│                     │
│              獲得 access_token
│                     │<─────────────────  AS Backend
│
│              存儲 token，設置 session
│                     │<─────────────────  MyApp Backend
│
└─ 登錄完成，進入應用 ──>  MyApp Frontend

核心要點

| 組件                      | 責任            | 倉庫                     |
  |-------------------------|---------------|------------------------|
| Authorization Server 後端 | 用户認證、發放 token | oauth2-server/backend  |
| Authorization Server 前端 | 登錄/授權 UI      | oauth2-server/frontend |
| Client 後端               | token 交換、業務邏輯 | my-app/backend         |
| Client 前端               | 用户界面、業務展示     | my-app/frontend        |

關鍵的交互點：
- AS 後端 <-> Client 後端：在後端進行（POST /token），涉及 client_secret
- AS 前端 <-> Client 前端：通過瀏覽器重定向
- User <-> 瀏覽器：所有用户交互都在瀏覽器中

建議的開發順序

1. 先開發 Authorization Server 的後端和前端
2. 再開發 Client 應用 的後端和前端
3. 測試整個流程

所以答案是：3 個倉庫（或 4 個，如果有共享庫的話）

你準備按照這個架構來實現嗎？

Todos
[ ] 實現基礎 OAuth 2.0 Authorization Code Flow
[ ] 添加 ID Token 生成（JWT）
[ ] 添加 nonce 驗證
[ ] 實現 Discovery 端點
[ ] 實現 JWKS 端點
[ ] 添加 UserInfo 端點