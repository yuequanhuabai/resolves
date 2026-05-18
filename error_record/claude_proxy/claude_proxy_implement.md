# Claude API 中转平台 实现方案

## 一、项目概述

面向受网络限制地区的用户，提供 Claude API 的中转代理服务。
用户通过平台账号购买额度，即可在本地直接调用前沿 AI 能力。

---

## 二、技术选型

### 前端

**推荐：Vue 3 + Vite + Element Plus**

理由：
- 与当前已有项目（mylogin-front）技术栈一致，无需重新学习
- 国内主流 AI 代理项目（one-api、new-api）均采用 Vue + Element，社区参考资源丰富
- Element Plus 自带完整的表单、表格、对话框组件，适合快速搭建管理后台

> Next.js 在全球 AI 代理项目中占比更高（约 40%），但其优势在于全栈一体化，
> 本项目后端已选定 Spring Boot，Next.js 的 API Routes 优势不成立，不作首选。

### 后端

**Spring Boot 3.x + Java 17**（复用现有 mylogin-back 基础）

| 能力         | 技术                        |
|--------------|-----------------------------|
| 认证         | JWT（已实现）               |
| 流式代理     | SseEmitter + WebClient      |
| 限流         | Redis + 令牌桶算法           |
| 持久化       | Spring Data JPA + SQL Server |
| 缓存         | Redis                        |
| HTTP 客户端  | Spring WebClient（非阻塞）   |

---

## 三、整体架构

```
┌─────────────────────────────────────────┐
│              用户浏览器                  │
│   Vue 3 Chat UI  /  用户控制台           │
└────────────────┬────────────────────────┘
                 │ HTTPS + SSE
                 ▼
┌─────────────────────────────────────────┐
│         中转服务器（境外 VPS）            │
│                                         │
│  ┌─────────────┐   ┌─────────────────┐  │
│  │  Spring Boot │   │      Redis       │  │
│  │             │   │  - 限流计数      │  │
│  │  - 认证模块  │   │  - Token 缓存   │  │
│  │  - 代理模块  │   └─────────────────┘  │
│  │  - 计费模块  │                        │
│  │  - 管理模块  │   ┌─────────────────┐  │
│  └──────┬──────┘   │   SQL Server     │  │
│         │          │  - 用户表        │  │
│         │          │  - 账单表        │  │
│         │          │  - 请求日志表    │  │
│         │          └─────────────────┘  │
└─────────┼───────────────────────────────┘
          │ HTTPS
          ▼
┌─────────────────────────────────────────┐
│         api.anthropic.com               │
│         Claude API                      │
└─────────────────────────────────────────┘
```

---

## 四、核心模块设计

### 4.1 认证模块（复用现有）

- 用户注册 / 登录 / JWT 签发
- 在现有 mylogin-back 基础上扩展用户角色：`USER` / `ADMIN`

### 4.2 代理模块（核心）

负责接收用户请求 → 转发 Claude API → 流式回传。

**关键技术：SseEmitter + WebClient**

```
用户请求 (POST /api/chat)
    ↓
校验 JWT + 校验余额
    ↓
创建 SseEmitter（返回给浏览器，连接建立）
    ↓
WebClient 异步调用 Claude API（流式）
    ↓
每收到一个 chunk → emitter.send(chunk)
    ↓
Claude 返回完毕 → 统计本次 Token 消耗 → 扣减余额 → emitter.complete()
```

**为什么用 WebClient 而不是 RestTemplate：**
WebClient 是非阻塞的，调用 Claude API 等待响应期间不占用线程，
配合 SseEmitter 可以在单个线程上同时处理大量流式连接。

### 4.3 计费模块

- 余额单位：`积分`（与 Claude Token 消耗按比例换算）
- 每次请求完成后，根据实际 input/output token 数扣减
- 余额不足时拒绝请求，返回 402

### 4.4 限流模块

- 基于 Redis 令牌桶：每个用户每分钟最多 N 次请求
- 全局限流：保护出口带宽和 Claude API 配额

### 4.5 管理模块（Admin）

- 用户管理：查询、封禁、手动充值
- 请求日志：每次调用记录（用户、模型、Token 数、费用、时间）
- 用量统计：日/月报表

---

## 五、数据库设计

### 用户表 sys_user（扩展现有）

```sql
ALTER TABLE sys_user ADD
    role         VARCHAR(20)  DEFAULT 'USER',   -- USER / ADMIN
    credits      BIGINT       DEFAULT 0,         -- 剩余积分
    total_used   BIGINT       DEFAULT 0;         -- 累计消耗积分
```

### 请求日志表 request_log

```sql
CREATE TABLE request_log (
    id           BIGINT PRIMARY KEY IDENTITY,
    user_id      BIGINT        NOT NULL,
    model        VARCHAR(50),                    -- claude-opus-4-7 等
    input_tokens INT,
    output_tokens INT,
    credits_used BIGINT,
    status       VARCHAR(20),                    -- SUCCESS / FAILED / ABORTED
    created_at   DATETIME2     DEFAULT GETDATE()
);
```

### 充值记录表 recharge_log

```sql
CREATE TABLE recharge_log (
    id           BIGINT PRIMARY KEY IDENTITY,
    user_id      BIGINT        NOT NULL,
    credits      BIGINT        NOT NULL,
    remark       VARCHAR(200),
    created_at   DATETIME2     DEFAULT GETDATE()
);
```

---

## 六、API 设计

### 用户侧

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/auth/login | 登录 |
| POST | /api/auth/register | 注册 |
| GET  | /api/user/me | 当前用户信息 + 余额 |
| POST | /api/chat | 发起对话（SSE 流式返回） |
| GET  | /api/user/logs | 本人请求历史 |

### 管理侧（需 ADMIN 角色）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET  | /api/admin/users | 用户列表 |
| POST | /api/admin/users/{id}/recharge | 手动充值 |
| POST | /api/admin/users/{id}/ban | 封禁用户 |
| GET  | /api/admin/logs | 全量请求日志 |
| GET  | /api/admin/stats | 用量统计报表 |

---

## 七、核心流程：流式代理

```
POST /api/chat
Body: { model, messages[], max_tokens }

1. JwtAuthFilter 验证 Token
2. 查询用户余额，余额 <= 0 → 返回 402
3. Redis 限流检查，超限 → 返回 429
4. 创建 SseEmitter，返回响应头（连接建立）
5. 异步线程启动：
   a. WebClient POST → api.anthropic.com/v1/messages（stream: true）
   b. 逐块接收 Claude 的 SSE 响应
   c. 每块 → emitter.send(data)，前端实时显示
   d. 收到 [DONE] 事件：
      - 汇总 input/output token 数
      - 按价格计算积分消耗
      - 写入 request_log
      - 扣减 sys_user.credits
      - emitter.complete()
6. 异常情况：
   - 用户断开连接 → emitter.onCompletion 回调中记录 ABORTED
   - Claude API 报错 → emitter.completeWithError，记录 FAILED
```

---

## 八、安全设计

| 风险 | 措施 |
|------|------|
| JWT 泄露 | 7天过期，敏感操作二次验证 |
| Claude API Key 泄露 | Key 仅存服务器环境变量，不入库不入日志 |
| 用户滥用 | Redis 限流 + 余额前置校验 |
| 余额超支 | 请求前校验余额，流式过程中若实时估算超出则中断 |
| 越权访问 | Admin 接口 RBAC 校验，普通用户只能访问自己数据 |

---

## 九、部署架构

```
境外 VPS（能访问 api.anthropic.com）
├── Docker Compose
│   ├── spring-boot-app   (Port 8888)
│   ├── redis             (Port 6379, 仅内网)
│   └── nginx             (Port 443, SSL 终止，反向代理到 8888)
│
└── SQL Server（可复用现有 106.55.7.17 或迁移至 VPS）

域名：申请一个域名，配置 HTTPS（Let's Encrypt 免费证书）
```

---

## 十、实施阶段建议

| 阶段 | 内容 | 优先级 |
|------|------|--------|
| P0 | 扩展用户表 + 积分字段；实现 /api/chat 流式代理接口 | 核心 |
| P0 | 前端 Chat UI（对话框 + SSE 接收） | 核心 |
| P1 | 计费扣减 + 请求日志记录 | 重要 |
| P1 | Redis 限流 | 重要 |
| P2 | 管理后台（充值、用户管理、日志查询） | 完善 |
| P3 | 报表统计、多模型支持、邀请码系统 | 扩展 |
