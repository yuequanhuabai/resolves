# SAML2 实战调试 - 实施步骤

## 整体架构

```
浏览器(React)  <-->  SP(Spring Boot应用)  <-->  IdP(Keycloak)
```

---

## 第一步：启动 Keycloak（IdP）

```bash
docker run -d -p 8180:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak:latest start-dev
```

启动后访问 `http://localhost:8180`，做三件事：
1. 创建一个 Realm（比如叫 `saml-demo`）
2. 在 Realm 里创建一个测试用户（设置用户名和密码）
3. 先放着，等 SP 建好后再来注册 SP

---

## 第二步：创建 SP（Spring Boot 项目）

用 Spring Initializr 创建项目，依赖选：
- Spring Web
- Spring Security
- Thymeleaf（先不用 React，用最简单的方式跑通流程，后面再换）

关键配置 `application.yml`：

```yaml
spring:
  security:
    saml2:
      relyingparty:
        registration:
          keycloak:
            assertingparty:
              metadata-uri: http://localhost:8180/realms/saml-demo/protocol/saml/descriptor
            signing:
              credentials:
                - private-key-location: classpath:credentials/sp-key.pem
                  certificate-location: classpath:credentials/sp-cert.pem
```

生成 SP 的自签名证书：

```bash
openssl req -x509 -newkey rsa:2048 -keyout sp-key.pem -out sp-cert.pem -days 365 -nodes -subj "/CN=sp"
```

放到 `src/main/resources/credentials/` 下。

写一个最简单的 Controller：

```java
@RestController
public class HomeController {
    @GetMapping("/")
    public String home(@AuthenticationPrincipal Saml2AuthenticatedPrincipal principal) {
        return "Hello, " + principal.getFirstAttribute("email");
    }
}
```

---

## 第三步：互相注册（建立信任）

**把 SP 注册到 Keycloak：**
- 回到 Keycloak 管理界面 -> Clients -> Create Client
- Client type 选 SAML
- Client ID 填 SP 的 Entity ID（Spring Security 默认是 `{baseUrl}/saml2/service-provider-metadata/{registrationId}`，即 `http://localhost:8080/saml2/service-provider-metadata/keycloak`）
- 配置 ACS URL：`http://localhost:8080/login/saml2/sso/keycloak`

**Keycloak 的 Metadata SP 已经通过 `metadata-uri` 自动拉取了，不用手动配。**

---

## 第四步：跑通流程

1. 启动 SP（`mvn spring-boot:run`）
2. 浏览器装 **SAML-tracer** 插件
3. 访问 `http://localhost:8080/`
4. 观察整个流程：
   - SP 重定向到 Keycloak 登录页 -> 打开 SAML-tracer 看 **AuthnRequest XML**
   - 在 Keycloak 输入用户名密码
   - Keycloak POST 回 SP -> SAML-tracer 看 **Response + Assertion XML**
   - SP 验签通过，显示用户信息

---

## 第五步：深入调试

在 SP 端打断点，重点看这几个类：
- `Saml2WebSsoAuthenticationFilter` — 接收 IdP 返回的 Response
- `OpenSaml5AuthenticationProvider` — 解析 Assertion、验证签名
- `Saml2AuthenticatedPrincipal` — 最终提取出的用户身份

---

## 第六步（可选）：接入 React 前端

跑通之后，把 Thymeleaf 换成 React：
- React 作为前端，请求 SP 的 API
- 未登录时 SP 返回 302，React 跟随重定向到 Keycloak
- 登录完成后回到 React 页面

---

> **建议：先用最简单的方式（Thymeleaf）跑通第一到第五步，确认你能看到完整的 SAML2 流程，再考虑加 React。**
