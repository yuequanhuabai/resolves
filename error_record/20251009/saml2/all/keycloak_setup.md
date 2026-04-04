# Keycloak 配置 & 常见问题排查

> 对应 `implement_step.md` 中每个步骤的详细操作和踩坑记录。

---

## 一、部署 Keycloak（对应第一步）

### 1.1 Docker 启动 Keycloak

```bash
docker run -d -p 8180:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  -e KC_HOSTNAME_STRICT=false \
  -e KC_HOSTNAME_STRICT_HTTPS=false \
  -e KC_HTTP_ENABLED=true \
  --name keycloak \
  quay.io/keycloak/keycloak:latest start-dev
```

### 1.2 关闭 master Realm 的 HTTPS 要求

Keycloak 有两层 HTTPS 控制：**服务器级别**和 **Realm 级别**。启动参数只解决了服务器级别，Realm 默认仍要求外部走 HTTPS。

```bash
# 登录命令行工具（容器内部走 localhost，不受 HTTPS 限制）
docker exec keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 --realm master --user admin --password admin

# 关闭 master realm 的 HTTPS 要求
docker exec keycloak /opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE
```

> 第一条输出 `Logging into ...` 即登录成功，第二条无报错即执行成功。

访问 `http://<CentOS IP>:8180`，用 `admin/admin` 登录。

### 1.3 创建 Realm

1. 左上角 `master` 下拉菜单 → `Create realm`
2. Realm name：`saml-demo`
3. 点击 `Create`

> Realm 是 Keycloak 中的租户概念，相当于独立的认证域。不要在 master realm 上做业务配置。

### 1.4 关闭 saml-demo Realm 的 HTTPS 要求

新建的 Realm 默认也要求 HTTPS，需要同样关闭：

```bash
docker exec keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 --realm master --user admin --password admin

docker exec keycloak /opt/keycloak/bin/kcadm.sh update realms/saml-demo -s sslRequired=NONE
```

### 1.5 创建测试用户

1. 确保当前在 `saml-demo` realm 下
2. 左侧菜单 → `Users` → `Create new user`
3. 填写：
   - Username: `testuser`
   - Email: `testuser@example.com`
   - First name: `Test`
   - Last name: `User`
4. 点击 `Create`
5. 切换到 `Credentials` 标签页 → `Set password`
   - Password: `test123`
   - Temporary: 设为 **OFF**（否则首次登录会要求改密码）
6. 点击 `Save`

---

## 二、创建 SP 项目（对应第二步）

### 2.1 依赖

Spring Boot 3.3.6 + JDK 17，核心依赖：
- `spring-boot-starter-web`
- `spring-boot-starter-security`
- `spring-boot-starter-thymeleaf`
- `spring-security-saml2-service-provider`
- `opensaml-core` / `opensaml-saml-api` / `opensaml-saml-impl`（4.3.2）

> **OpenSAML 依赖问题**：Spring Security SAML2 依赖 OpenSAML 解析 XML，但不会自动引入，需要手动添加。
>
> **Maven 下载失败**：报 `was not found in ... during a previous attempt`，执行 `mvn clean install -U` 强制更新。
>
> **阿里云源缺少 OpenSAML**：在 `pom.xml` 中添加 Shibboleth 仓库：
> ```xml
> <repositories>
>     <repository>
>         <id>shibboleth</id>
>         <url>https://build.shibboleth.net/maven/releases/</url>
>     </repository>
> </repositories>
> ```

### 2.2 application.yml 配置

```yaml
server:
  port: 8080

spring:
  security:
    saml2:
      relyingparty:
        registration:
          keycloak:
            entity-id: http://localhost:8080/saml2/service-provider-metadata/keycloak
            assertingparty:
              metadata-uri: http://<CentOS IP>:8180/realms/saml-demo/protocol/saml/descriptor
            signing:
              credentials:
                - private-key-location: classpath:credentials/sp-key.pem
                  certificate-location: classpath:credentials/sp-cert.pem
```

> `entity-id` 不配也行，Spring Security 会按 `{baseUrl}/saml2/service-provider-metadata/{registrationId}` 自动生成。但建议显式配置，一目了然。

### 2.3 生成 SP 自签名证书

```bash
openssl req -x509 -newkey rsa:2048 -keyout sp-key.pem -out sp-cert.pem -days 365 -nodes -subj "/CN=sp"
```

放到 `src/main/resources/credentials/` 下。

---

## 三、注册 SP 到 Keycloak（对应第三步）

### 3.1 操作步骤

在 Keycloak 管理界面，**确保切换到 `saml-demo` realm**。

左侧菜单 → `Clients` → `Create client`

**General Settings 页：**

| 字段 | 填写内容 |
|------|---------|
| Client type | **SAML** |
| Client ID | `http://localhost:8080/saml2/service-provider-metadata/keycloak` |

点击 `Next`。

**Login Settings 页：**

| 字段 | 填写内容 |
|------|---------|
| Master SAML Processing URL | `http://localhost:8080/login/saml2/sso/keycloak` |
| Valid redirect URIs | `http://localhost:8080/*` |

其他字段全部留空，点击 `Save`。

> Master SAML Processing URL 就是 ACS URL，Keycloak 换了个名字。

### 3.2 关闭客户端签名验证

Keycloak 默认要求验证 SP 的 AuthnRequest 签名，但它没有 SP 的证书，会报 `invalid_signature`。

1. 点击刚注册的 SP Client
2. 切换到 **Keys** 标签页
3. 把 **Client signature required** 设为 **OFF**
4. 点击 `Save`

> 开发阶段先关闭，后续可以打开并上传 SP 证书。

### 3.3 踩坑：Client 注册错 Realm

**现象**：Keycloak 日志报 `error="client_not_found", reason="Cannot_match_source_hash"`

**原因**：SP Client 注册在了 `master` realm 下，但 SP 的 `metadata-uri` 指向 `/realms/saml-demo/...`，请求发到 saml-demo realm 找不到 Client。

**解决**：删掉 master 下的 Client，在 `saml-demo` realm 下重新注册。

---

## 四、跑通流程 & 问题排查（对应第四步）

### 4.1 正常流程

1. 启动 SP（`mvn spring-boot:run`）
2. 浏览器访问 `http://localhost:8080/`
3. 自动跳转到 Keycloak 登录页
4. 输入 `testuser / test123`
5. 登录成功，跳回 SP 显示用户信息和属性

### 4.2 SAML-tracer 抓包

SAML-tracer 是 Chrome/Firefox 浏览器扩展，安装后点击图标打开面板，自动捕获 SAML 请求（黄色高亮）。

> **无痕模式下使用**：需先到 `chrome://extensions/` → SAML-tracer → 详情 → 打开"在无痕模式下启用"。

### 4.3 常见报错

#### `HTTPS required`

**原因**：Realm 级别默认要求 HTTPS。

**解决**：见上方 1.2 和 1.4 节，用 `kcadm.sh` 关闭对应 Realm 的 `sslRequired`。

#### `Invalid requester` / `invalid_signature`

**原因**：Keycloak 要求验证 SP 的 AuthnRequest 签名，但没有 SP 的证书。

**解决**：见上方 3.2 节，关闭 Client signature required。

#### `InResponseTo attribute does not match` / `no saved authentication request was found`

**原因**：F12 开发者工具打开时（"Disable cache" 勾选或 SAML-tracer 插件干扰），浏览器重复发送请求，第二个 AuthnRequest 覆盖了第一个，导致 ID 不匹配。

**解决**：关闭 F12 开发者工具后再测试登录流程。如需用 SAML-tracer，确保 DevTools 的 "Disable cache" 未勾选。

#### `LogoutResponseImpl cannot be cast to Response`

**原因**：SP 端未配置 Single Logout (SLO)。Keycloak 把 LogoutResponse 发回 SP 的登录 URL，Spring Security 误将其当作登录 Response 解析。

**影响**：不影响登录流程，属于后续完善内容。

#### 如何重新登录（清除 session）

SP 和 Keycloak 两端都有 session，仅清一端不够。最简单的办法：用**浏览器无痕模式**打开 `http://localhost:8080/`，每次新窗口就是全新 session。

---

## 五、接入 React 前端（对应第七步）

### 5.1 架构

```
React (localhost:5173)  --API请求-->  SP (localhost:8080)  --SAML-->  Keycloak (8180)
```

React 是独立 SPA 项目，SP 变为纯 API 后端。SAML 认证流程仍由 SP 处理，React 不直接参与 SAML，只负责调 API 和展示。

### 5.2 技术栈

| 组件 | 作用 |
|------|------|
| React 18 | UI 框架 |
| React Router | 前端路由（登录页 / 首页） |
| Axios | 调 SP 的 API |
| Vite | 构建工具，端口 5173（在 `vite.config.js` 中显式配置） |

### 5.3 SP 端改动

- `HomeController` 新增 `/api/user` 和 `/api/users` 接口，返回 JSON
- `SecurityConfig` 添加：
  - CORS 配置，允许 React（localhost:5173）跨域访问
  - SAML 认证成功后重定向到 React 页面（`http://localhost:5173/home`）

### 5.4 认证流程

1. 用户在 React 登录页点击登录按钮
2. 浏览器跳转到 SP（`http://localhost:8080/api/user`）
3. SP 发现未登录，重定向到 Keycloak 登录页
4. 用户在 Keycloak 输入账号密码
5. Keycloak POST 回 SP，SP 创建 session
6. SP 重定向到 React 页面（`http://localhost:5173/home`）
7. React 调 `/api/user` 获取用户信息并展示

### 5.5 常见报错

#### `Invalid CORS request`（访问 `/login/saml2/sso/keycloak` 时）

**原因**：CORS 配置范围过大（`/**`），影响了 SAML 端点。Keycloak POST 回 SP 时 Origin 为 `null`（浏览器自动提交的表单），被 CORS 拦截。

**解决**：CORS 只对 API 路径生效，不要覆盖 SAML 端点：

```java
source.registerCorsConfiguration("/api/**", config);  // 只对 /api/** 生效
// 而不是 source.registerCorsConfiguration("/**", config);
```

#### `ERR_CONNECTION_REFUSED`（重定向到 `localhost:3000/home`）

**原因**：Vite 默认端口是 **5173**，不是 3000（3000 是 Create React App 的默认端口）。SecurityConfig 中重定向地址写错了。

**解决**：确保 SP 端 `SecurityConfig` 中的重定向地址和 CORS 配置都使用 `http://localhost:5173`，与 `vite.config.js` 中配置的端口一致。
