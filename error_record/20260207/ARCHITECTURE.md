# PAP 项目架构概览

> 本文基于仓库当前真实代码勘探整理，面向「整体架构」层面：模块划分、分层、技术栈、关键基础设施与前后端协作链路。不深入单个业务实现细节。
> 上游血缘：[yudao / ruoyi-vue-pro](https://gitee.com/zhijiantianya/ruoyi-vue-pro) 脚手架，已 rebrand 为 `cn.bochk.pap`（group `cn.bochk.boot`），并叠加了 BlackRock Aladdin 集成与组合投顾（portfolio-advisory）业务域。

---

## 1. 总体形态

```
pap_new/                      （非 Git 仓库；两个子项目各自是独立 Git 仓库）
├── pap-back/                 Spring Boot 3.5 + Java 17 多模块 Maven 后端
└── pap-front/                Vue 3 + Vite 5 + Element Plus + TS 管理后台前端
```

- **架构风格**：前后端分离的单体应用（不是微服务）。后端只有一个可运行进程（`pap-server`），前端是 SPA 管理后台。
- **对接契约**：前端通过 `/admin-api` 前缀调用后端 REST 接口；后端统一返回 `CommonResult<T>`（`{ code, data, msg }`）。
- **外部系统**：后端通过 `aladdin/` 客户端 + 外部代理（NGINX 负载均衡）对接 BlackRock Aladdin。

```
┌────────────┐   /admin-api (Bearer Token, SAML2 SSO)   ┌──────────────┐   OAuth2 client-credentials   ┌──────────────┐
│  pap-front │ ───────────────────────────────────────▶ │  pap-server  │ ────────────────────────────▶ │  Aladdin 代理 │
│ (Vue SPA)  │ ◀─────────── CommonResult<T> ──────────── │ (Spring Boot)│ ◀──────────────────────────── │  (NGINX LB)  │
└────────────┘                                           └──────┬───────┘                               └──────────────┘
                                                                │
                                            ┌───────────────────┼────────────────────┐
                                       SQL Server/MySQL       Redis              Flowable(BPM)
                                    (动态多数据源 master)   (Session/缓存/        (工作流引擎)
                                                            令牌缓存/Quartz)
```

---

## 2. 后端架构（`pap-back/`）

### 2.1 Maven 模块划分

| 模块 | 角色 | 说明 |
|------|------|------|
| `pap-dependencies` | BOM | 统一锁定依赖版本；叶子 POM 只声明 artifact，不写版本号 |
| `pap-framework` | 跨切面基础设施 | 包 `cn.bochk.pap.framework.common.*`，被业务模块依赖 |
| `pap-server` | **唯一可运行的 Spring Boot 应用** | 打包产物 `pap-server/target/application.jar`（`finalName=application`） |

关键版本：Java 17、Spring Boot 3.5.13。

### 2.2 framework 基础设施（`framework.common.*`）

横切能力集中在此模块，业务模块只管调用：

- `mybatis/` — 动态多数据源（`dynamic-datasource`）+ MyBatis-Plus（含 `mybatis-plus-join`）；逻辑删除 `1=删/0=未删`；敏感字段加解密
- `redis/` — Redis 核心配置（**强依赖，非纯缓存**：Spring Session、令牌缓存、operate-log、WebSocket 路由）
- `security/` — 安全与操作日志（`operatelog/`、`security/`）
- `web/` — `apilog`(接口日志)、`jackson`、`swagger`、`xss`、`desensitize`(脱敏)、`external`(外部调用支持)
- `pojo/` — `PageResult` / `CommonResult` / `PageParam` 等统一返回与分页载体
- `exception/` — `ServiceException` + 全局异常处理
- `excel/` — Excel 导入导出（含字典翻译）
- `biz/system`、`biz/infra` — 跨模块 API（业务模块回调系统能力）
- `util/` — 大量工具集（date/json/jwt/http/spring/servlet…）

### 2.3 server 包结构（`cn.bochk.pap.server.*`）

```
server/
├── PapServerApplication      主类，扫描 *.server 与 *.module
├── init/SqlInitializer       ★ 拦截 --init-sql=… 在 Spring 启动前直接执行 SQL（不引导 Spring！）
├── system/                   认证/用户/部门/角色/权限/字典/OAuth2/通知/操作日志
├── bpm/                      Flowable 工作流（流程定义、任务、表单、监听器）
├── business/                 ★ 业务域（本 fork 新增）
└── aladdin/                  BlackRock Aladdin API 客户端
```

#### system 模块分层（标准分层）
```
controller/admin → service → dal/{mysql, redis, dataobject} → convert(MapStruct)
```

#### business 模块分层（与 system 略有差异）
```
controller → service(+Impl) → mapper(接口) + vo/{req, resp}
```
- 用 `mapper/`（**不是** `dal/mysql/`），MyBatis XML 在 `pap-server/src/main/resources/business/*.xml`
  （对应 `mybatis-plus.mapper-locations: classpath*:business/*.xml`）
- 业务实体（截至当前代码）：
  - **ModelPortfolio**（模型组合）、**BuyList**（买入清单）、**HouseViewList**、**Benchmark**（基准）、
    **AssetClassification**（资产分类）、**Alternatives**（另类）、**Pvb3rdPartyPortAc**（第三方组合）、**Audit**（审计）
  - 配套大量映射表：SecurityMaster、ModelInfo、Bank、DayendBatchLog、TableSwitchLog、Tmp/Br* 临时与中间表
- 控制器示例（`ModelPortfolioController`）印证约定：`@RestController` + `@RequestMapping("/admin-api/modelPortfolio")` +
  `@PreAuthorize("@ss.hasPermission('model:portfolio:query')")` 权限注解 + 返回 `CommonResult<PageResult<...RespVO>>`，
  用 `BeanUtils.toBean` 做 DO→VO 转换。

#### aladdin 模块（强制外部出口）
```
aladdin/
├── config/      AladdinProperties、负载均衡(AladdinLoadBalanceConfig)、Web 配置、Lock4j 配置
├── controller/  AladdinController
├── service/     IAladdinApiService / IAladdinTokenService (+Impl)   ← 令牌 OAuth2 client-credentials，缓存于 Redis
├── interceptor/ AladdinHeaderInterceptor（Host 头改写等）
├── dal/redis/   RedisKeyConstants
└── enums/       AladdinApiConstants / AladdinConstants
```
> 约束：所有对 BlackRock 的出站调用**必须经过此模块或 `pap.external-service.*` 代理**，以保证重试/failover/Host 头改写一致，禁止直连。

### 2.4 两种启动模式（重要）

`main()` 不总是引导 Spring：

1. **正常模式**：`java -jar application.jar --spring.profiles.active=dev`（dev 监听 `:9600`）
2. **SQL 初始化模式**：带 `--init-sql=a.sql,b.sql` 时，`SqlInitializer` 用手搓的 Hikari 连接池直接跑 SQL 后退出，**不启动 Spring**。
   附加开关：`--use-spring` / `--no-transaction` / `--continue-on-error` / `--ignore-drop-errors` / `--error-log=<dir>`。
   基线 DDL/DML 在 `pap-back/sql/{mysql, sqlserver}/`。

### 2.5 构建与运行（在 `pap-back/` 下）

```bash
mvn clean package -P dev               # 测试默认跳过（父 POM surefire skipTests=true）；可选 sit/uat/prod
mvn -pl pap-server -am package         # 只构建 server 及其依赖
java -jar pap-server/target/application.jar --spring.profiles.active=dev
mvn -pl pap-server test -DskipTests=false -Dtest=SomeClass#someMethod   # 跑单测需显式开启
```
Profile（dev/sit/uat/prod）在 `pap-server/pom.xml` 声明，经 `@activatedProperties@` 资源过滤注入 `application.yaml`。

### 2.6 数据源、认证、日志

- **数据源**：动态多数据源，`master` 为主库；dev 使用 SQL Server（见 `application-dev.yaml`），其它环境可能是 MySQL/Oracle —— 以对应 `application-*.yaml` 为准。
- **认证**：SAML2 SSO（Spring Security，`pap.security.ums.saml2.*`，IdP 元数据 `classpath:saml2/federationmetadata.xml`）。
  - Cookie 设为 `SameSite=none; Secure=true`，因为 SAML2 HTTP-POST 绑定需要 JSESSIONID 随跨站 POST 一起回传；改 Cookie 配置须同时验证 `server.forward-headers-strategy=framework` 网关路径。
  - dev 另有 mock 认证旁路：`pap.security.mock-enable=true`。
- **配置过滤陷阱**：只有 `application.yaml` 被 Maven `@…@` 过滤；其它 `application-*.yaml` 原样拷贝。
- **日志**：`logback-spring.xml`，输出到 `${user.home}/logs/pap-server.log`；MyBatis SQL 经 SLF4J 进同一文件（非 stdout）。

---

## 3. 前端架构（`pap-front/`）

### 3.1 技术栈

Vue 3.5 + Vite 5 + TypeScript + Element Plus 2.9 + Pinia（持久化）+ Vue Router 4 + Vue-I18n + UnoCSS + ECharts；
集成 BPMN（bpmn-js / camunda-moddle）、form-create 表单设计器、wangEditor、xlsx 等。运行 Node ≥16。

### 3.2 目录组织（`src/`）

```
src/
├── api/        按业务域组织的接口层（modelportolio / buylist / benchmark / bpm / system / infra …）
├── views/      页面，与 api/ 大致一一对应（modelportfolio / buylist / benchmark / blackRock / bpm / system …）
├── store/      Pinia：user / permission / dict / app / locale / lock / tagsView / bpm
├── router/     index.ts + modules（静态路由 + 动态路由）
├── config/     axios 封装（service.ts 拦截器 + index.ts 方法封装 + config / errorCode）
├── components/ 通用组件
├── layout/     布局骨架
├── hooks/、directives/、plugins/、locales/、styles/、utils/、permission.ts、main.ts
```

> 命名映射约定：`views/<feature>` ↔ `api/<feature>` ↔ `store/modules/*` ↔ 后端 `business/{controller,service,mapper,vo}`。
> 新增业务功能时应在这四处并行建目录。

### 3.3 请求层与认证流（`src/config/axios/`）

- `index.ts`：对 `get/post/put/delete/download/upload` 等做薄封装，统一注入 `Content-Type`。
- `service.ts`：核心拦截器
  - **请求拦截**：自动加 `Authorization: Bearer <accessToken>`（白名单 `/login`、`/refresh-token` 除外）；可选租户头 `tenant-id` / `visit-tenant-id`；GET 防缓存头；POST 表单序列化。
  - **响应拦截**：按 `CommonResult.code` 分流——`200` 放行；`401` 触发**无感刷新令牌**（请求排队、刷新成功后回放队列、失败则弹窗登出）；`500/901/其它` 统一提示；blob/arraybuffer（如 Excel 导出）直接返回。
- 权限：`permission.ts` + `store/permission` 基于后端返回的菜单/权限码生成动态路由；按钮级权限对应后端 `@ss.hasPermission(...)`。

### 3.4 环境与构建（在 `pap-front/` 下）

```bash
npm install            # 或 npm run i
npm run dev            # 本地模式 (.env.local)，Vite 端口 9080
npm run dev-server     # dev 模式 (.env.dev)，指向远程 dev API
npm run build:local    # 另有 build:dev / build:sit / build:uat / build:prod
npm run ts:check       # vue-tsc --noEmit
npm run lint:eslint / lint:format / lint:style
```
环境文件：`.env.local / .env.dev / .env.sit / .env.uat(.stage) / .env.prod`。
关键变量：`VITE_BASE_URL`（后端 origin）、`VITE_API_URL`（默认 `/admin-api`）、`VITE_PORT`、SAML2 SSO 端点（`VITE_SSO_URL` / `VITE_SSO_LOGOUT_URL`）。
别名：`@/` → `pap-front/src/`。

---

## 4. 端到端协作链路（新增业务功能的标准路径）

```
1. 建表          pap-back/sql/{mysql,sqlserver}/ 加脚本
2. 后端 DO       business/dal/dataobject
3. 后端 Mapper   business/mapper/*.java + resources/business/*.xml
4. 后端 Service  business/service + Impl
5. 后端 VO       business/vo/{req,resp}
6. 后端 Controller business/controller（@RequestMapping("/admin-api/...") + @PreAuthorize 权限码）
7. 前端 api      src/api/<feature>
8. 前端 view     src/views/<feature>
9. 前端 store    src/store/modules/<feature>（如需）
```
- 出站调用 BlackRock：一律走 `aladdin/` 或 `pap.external-service.*`，不要新建直连 HTTP 客户端。

---

## 5. 关键约束速查（容易踩坑）

| 主题 | 约束 |
|------|------|
| 版本管理 | 版本只在 `pap-dependencies` BOM 锁定，叶子 POM 不写版本 |
| 打包产物名 | `application.jar`（不是 `pap-server.jar`） |
| 启动分叉 | `--init-sql` 存在时短路、不启动 Spring |
| 配置过滤 | 只有 `application.yaml` 被 Maven 过滤；`application-*.yaml` 原样拷贝 |
| Redis | 强依赖，缺失会影响 Session/SAML2 多实例/令牌缓存 |
| Cookie | `SameSite=none; Secure=true` 为 SAML2 POST 绑定所需，勿随意改 |
| business vs system | business 用 `mapper/`+XML，system 用 `dal/mysql/`+MapStruct convert |
| 外部出口 | BlackRock 调用必须经 aladdin/代理 |
| 测试 | Surefire 默认跳过，需 `-DskipTests=false` |
| 子仓库 | pap-back / pap-front 各自独立 Git 仓库，git 命令需进各自目录 |
```
