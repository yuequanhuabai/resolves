# SAML2 实战调试 - 实施步骤

## 整体架构

```
浏览器  <-->  SP(Spring Boot)  <-->  IdP(Keycloak)
```

---

## 第一步：部署 Keycloak（IdP）

在 Linux 服务器上用 Docker 启动 Keycloak，配置 Realm 和测试用户。

> 详见 `install_docker_in_centos8.md`（Docker 安装）和 `keycloak_setup.md`（Keycloak 配置）。

---

## 第二步：创建 SP（Spring Boot 项目）

技术栈：Spring Boot 3.3.6 + JDK 17 + Spring Security SAML2 + OpenSAML 4.3.2

关键文件：
- `application.yml` — SAML2 配置（entity-id、metadata-uri、签名证书）
- `credentials/sp-key.pem` + `sp-cert.pem` — SP 自签名证书（openssl 生成）

---

## 第三步：互相注册（建立信任）

| 方向 | 方式 |
|------|------|
| SP → Keycloak | `application.yml` 中 `metadata-uri` 指向 Keycloak，自动拉取 IdP 元数据 |
| Keycloak → SP | 在 Keycloak 管理界面注册 SP 的 Client ID 和 ACS URL |

> 详见 `keycloak_setup.md` 第三步。

---

## 第四步：跑通流程

1. 启动 SP（`mvn spring-boot:run`）
2. 浏览器访问 `http://localhost:8080/`
3. 自动跳转到 Keycloak 登录页 → 输入 `testuser / test123`
4. 登录成功，跳回 SP 显示用户信息

用 **SAML-tracer**（Chrome/Firefox 插件）抓包，可以看到两个 SAML 请求：

| 请求 | 方向 | 内容 |
|------|------|------|
| AuthnRequest | SP → IdP | "我是 SP，请帮我认证用户" |
| Response + Assertion | IdP → SP | "用户是 testuser，认证成功，签名担保" |

> 遇到问题？详见 `keycloak_setup.md` 的常见问题排查部分。

---

## 第五步：深入调试

在 SP 端打断点，跟踪认证到创建 Session 的完整过程：

| 顺序 | 类 | 方法 | 作用 |
|------|------|------|------|
| 1 | `Saml2WebSsoAuthenticationFilter` | `attemptAuthentication()` | 接收 IdP POST 回来的 SAMLResponse |
| 2 | `OpenSaml4AuthenticationProvider` | `authenticate()` | 解码 → 解析 XML → 验签 → 提取用户身份 |
| 3 | `HttpSessionSecurityContextRepository` | `saveContext()` | 将认证结果存入 HttpSession，浏览器拿到 JSESSIONID |

> SAML2 只负责认证那一下，后续访问靠 JSESSIONID cookie 维持会话。

---

## 第六步（可选）：接入数据库

登录成功后连接数据库做业务查询，验证 SAML2 认证 + 业务操作的完整链路。

---

## 第七步（可选）：接入 React 前端

前后端分离，React 作为独立 SPA，SP 变为纯 API 后端。

```
React (localhost:5173)  --API请求-->  SP (localhost:8080)  --SAML-->  Keycloak (8180)
```

技术栈：React 18 + React Router + Axios + Vite

SP 端改动：
- Controller 新增 `/api/user`、`/api/users` 返回 JSON
- SecurityConfig 添加 CORS 配置 + SAML 认证成功后重定向到 React

> 详见 `keycloak_setup.md` 第五部分。
