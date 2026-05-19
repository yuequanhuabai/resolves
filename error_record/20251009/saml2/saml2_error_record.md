# SAML2 搭建错误记录

> 日期：2026-05-19
> 项目：mylogin saml2 分支
> 技术栈：Spring Boot 3.5 + Spring Security SAML2 + Keycloak + Vue 3

---

## 错误一：Maven 依赖无法解析

### 现象

```
Unresolved dependency: 'org.opensaml:opensaml-saml-api:jar:4.3.2'
```

### 原因

`spring-security-saml2-service-provider` 依赖的 OpenSAML 库不托管在 Maven Central，
而是在 Shibboleth 私有仓库，Maven 默认找不到。

### 解决方案

在 `pom.xml` 中添加 Shibboleth 仓库：

```xml
<repositories>
    <repository>
        <id>shibboleth</id>
        <url>https://build.shibboleth.net/nexus/content/repositories/releases/</url>
    </repository>
</repositories>
```

---

## 错误二：SP 无法生成签名凭证

### 现象

```
WARN: Unable to resolve signing credential
ERROR: Failed to resolve any signing credential
Saml2Exception: java.lang.IllegalArgumentException: Failed to resolve any signing credential
```

### 原因

Keycloak 的 IdP 元数据中声明了 `WantAuthnRequestsSigned="true"`，
Spring Security 读到后尝试对 AuthnRequest 进行签名，
但 SP 未配置任何签名密钥，导致无法完成签名。

### 解决方案

将本地保存的 `keycloak-metadata.xml` 中的签名要求改为 `false`：

```xml
<!-- 修改前 -->
WantAuthnRequestsSigned="true"

<!-- 修改后 -->
WantAuthnRequestsSigned="false"
```

> **说明**：Keycloak 客户端的 `Client Signature Required` 默认为 OFF，
> 实际并不强制验证 SP 签名，元数据中的该字段改为 false 与实际行为一致。

---

## 错误三：Keycloak 要求 HTTPS

### 现象

浏览器跳转到 Keycloak 后显示：

```
We are sorry...
HTTPS required
```

Keycloak 日志：

```
error="ssl_required"
```

### 原因

Keycloak 新建 Realm 默认开启 SSL 要求，
而开发环境使用的是 HTTP，不满足条件被拒绝。

### 解决方案

在 Keycloak 管理控制台关闭 SSL 限制：

```
mylogin Realm → Realm settings → General → Require SSL → 改为 None → Save
```

---

## 错误四：Keycloak 报 Invalid Signature

### 现象

页面显示：

```
We are sorry...
Invalid requester
```

Keycloak 日志：

```
ERROR: request validation failed: VerificationException: Invalid signature on document
error="invalid_signature", clientId="null"
```

### 原因

Keycloak 客户端的 **Keys** 标签下 `Client Signature Required` 为 **ON**，
要求 SP 对所有 AuthnRequest 进行签名并提交公钥供验证。
由于 SP 未注册任何公钥，Keycloak 无法验证签名，请求被拒绝。

> 注意：`clientId="null"` 是因为 Keycloak 先做签名验证，
> 验证失败后才查 Client，所以 clientId 还未被识别。

### 解决方案

在 Keycloak 管理控制台关闭签名要求：

```
mylogin Realm → Clients → 选中客户端 → Keys 标签 → Client Signature Required → 改为 OFF → Save
```

---

## 错误五：SAML 断言回传被 CORS 拦截

### 现象

Keycloak 认证成功后，浏览器被重定向到后端 ACS 端点，页面显示：

```
Invalid CORS request
```

URL：`http://localhost:8888/login/saml2/sso/keycloak`

### 原因

SAML HTTP-POST Binding 的工作方式是：
Keycloak 返回一个含有隐藏表单的 HTML 页面，浏览器自动 POST 断言到 SP 的 ACS 端点。
该 POST 请求携带 `Origin: http://36.151.149.59:8180`（Keycloak 的地址），
而后端 CORS 配置只允许了 `http://localhost:5173`，导致请求被 Spring 的 CorsFilter 拒绝。

### 解决方案

为 SAML ACS 端点单独配置宽松的 CORS 规则，与 API 端点隔离：

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();

    // API 端点：只允许前端访问，携带 Cookie
    CorsConfiguration apiConfig = new CorsConfiguration();
    apiConfig.setAllowedOrigins(List.of("http://localhost:5173"));
    apiConfig.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE"));
    apiConfig.setAllowedHeaders(List.of("*"));
    apiConfig.setAllowCredentials(true);
    source.registerCorsConfiguration("/api/**", apiConfig);

    // SAML ACS 端点：允许 Keycloak POST 断言，不需要 credentials
    CorsConfiguration samlConfig = new CorsConfiguration();
    samlConfig.setAllowedOriginPatterns(List.of("*"));
    samlConfig.setAllowedMethods(List.of("POST", "GET"));
    samlConfig.setAllowedHeaders(List.of("*"));
    source.registerCorsConfiguration("/login/saml2/**", samlConfig);

    return source;
}
```

> **说明**：SAML ACS 端点的安全性由断言签名保证，而非 CORS，
> 因此对该端点放开 Origin 限制是安全的。

---

## 错误总览

| # | 错误信息 | 出错位置 | 根本原因 |
|---|---|---|---|
| 1 | `Unresolved dependency: opensaml-saml-api` | Maven 构建 | OpenSAML 不在 Maven Central |
| 2 | `Failed to resolve any signing credential` | Spring Boot 启动/运行 | SP 无签名密钥但元数据要求签名 |
| 3 | `HTTPS required` | Keycloak | Realm 强制 SSL，开发环境用 HTTP |
| 4 | `Invalid signature / Invalid requester` | Keycloak | Client Signature Required 为 ON |
| 5 | `Invalid CORS request` | Spring Boot | SAML ACS 端点未允许 Keycloak Origin |

---

## 最终可用配置关键点

- Keycloak Realm → Require SSL → **None**
- Keycloak Client → Keys → Client Signature Required → **OFF**
- `keycloak-metadata.xml` → `WantAuthnRequestsSigned="false"`
- `pom.xml` → 添加 Shibboleth 仓库
- `SecurityConfig` → SAML ACS 端点单独配置 CORS
