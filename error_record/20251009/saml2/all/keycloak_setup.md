# Keycloak 配置步骤

> 前提：Keycloak 已启动，能通过 `http://<IP>:8180` 访问管理界面。

---

## 第一步：创建 Realm

1. 登录 Keycloak 管理界面（`admin/admin`）
2. 左上角点击 `master` 下拉菜单 → `Create realm`
3. Realm name 填 `saml-demo`
4. 点击 `Create`

> Realm 是 Keycloak 中的租户概念，相当于一个独立的认证域。不要在 master realm 上做业务配置。

---

## 第二步：创建测试用户

1. 左侧菜单 → `Users` → `Create new user`
2. 填写：
   - Username: `testuser`
   - Email: `testuser@example.com`
   - First name: `Test`
   - Last name: `User`
3. 点击 `Create`
4. 切换到 `Credentials` 标签页 → `Set password`
   - Password: `test123`
   - Temporary: 设为 **OFF**（否则首次登录会要求改密码）
5. 点击 `Save`

---

## 第三步：等待 SP 就绪后注册 SP

这一步在 SP（Spring Boot 项目）创建完成后再回来操作。需要做的事：

1. 左侧菜单 → `Clients` → `Create client`
2. Client type 选 **SAML**
3. Client ID 填 SP 的 Entity ID：`http://localhost:8080/saml2/service-provider-metadata/keycloak`
4. 配置 ACS URL：`http://localhost:8080/login/saml2/sso/keycloak`

> 具体细节见 `implement_step.md` 第三步。
