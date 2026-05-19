第一步:创建Realm我找到了，
应该是Manage realms的左侧菜单栏，右侧有蓝色的Create realm 按钮;
点击Create realm 按钮
有三个选项：
Resource file:  tips(Drag a file here or browse to upload)
Realm name *
Enabled    默认 On 开启

下面是 Create 按钮和Cancel 按钮;

● 对，就是这个页面。操作很简单：

- Resource file：不用管，留空
- Realm name：填 mylogin
- Enabled：保持默认 On

然后点 Create。

创建成功后页面会自动跳转到 mylogin 这个 Realm 的管理界面，左上角会显示当前 Realm 名称变成了 mylogin，告诉我跳转后你看到的是什么。

✻ Sautéed for 16s

> 创建成功了，左上角显示 mylogin

● 第一步完成。现在做第二步，创建 SAML2 Client。

左侧菜单点 Clients → 右侧点蓝色 Create client 按钮，告诉我你看到的页面内容。

✻ Churned for 6s

> 左侧菜单 Clients → Create client
有这些选项:
左侧是 1 General settings，左侧下面是空白的；
右侧是
Client type：默认下拉是 OpenID Connect
Client ID * ： 空白需要填写;
Name: 空白需要填写;
Description: 空白需要填写;
Always display in UI : 开关，默认是OFF

下面有Back，Next  还有Cancel按钮

● 按以下填写：

- Client type：下拉选 SAML（从默认的 OpenID Connect 改掉）
- Client ID：填
  http://localhost:8888/saml2/service-provider-metadata/keycloak
- Name、Description、Always display in UI：不用管，留默认

然后点 Next，告诉我下一页的内容。

✻ Baked for 10s

> 我点击了Next

左侧是
1 General settings，
2 Login settings(显示蓝色)
左侧下面是空白的；

右侧是
Root URL：空白需要填写;
Home URL ： 空白需要填写;
Valid redirect URIs: 空白需要填写;
Valid post logout redirect URIs: 空白需要填写;
IDP-Initiated SSO URL name: 空白需要填写;
IDP-Initiated SSO Relay State: 空白需要填写;
Master SAML Processing URL: 空白需要填写;

● 只填这三项，其余留空：

- Root URL：
  http://localhost:8888
- Valid redirect URIs：
  http://localhost:8888/*
- Master SAML Processing URL：
  http://localhost:8888/login/saml2/sso/keycloak

其他字段（Home URL、Valid post logout redirect URIs、IDP-Initiated SSO URL name、IDP-Initiated SSO Relay State）全部留空。

填完点 Save，告诉我保存后跳转到什么页面。

✻ Crunched for 48s

> 提示：Client created successfully
http://localhost:8888/saml2/service-provider-metadata/keycloak
有个开关：Enabled  ，右侧有个下拉，默认是Action（有三个选项Download adapter config，Export，Delete）
现在在：Clients > Client details页面：
上面的Tabs有7个，分别是：
Settings，Keys，Roles，Client scopes，Sessions，Advanced，Events
现在默认是Settings:
有很多选项，但是又分类：
General settings，
Access settings,
SAML capabilities,
Signature and Encryption,
Login settings,
Logout settings

General settings的内容有：
Client ID*: http://localhost:8888/saml2/service-provider-metadata/keycloak
Name: 空白
Description：空白
Always display in UI :默认 off

Access settings的内容有：
Root URL: http://localhost:8888
Home URL: 空白
valid redirect URIs: http://localhost:8888/*
Valid post logout redirect URIs: 空白
IDP-Initiated SSO URL name: 空白
IDP Initiated SSO Relay State: 空白
Master SAML Processing URL: http://localhost:8888/login/saml2/sso/keycloak

SAML capabilities的内容有：
Name ID format: username
Force name ID format: 默认Off
Force POST binding： 默认On
Force artifact binding： 默认Off
Include AuthStatement： 默认On
Include OneTimeUse Condition：默认Off
Optimize REDIRECT signing key lookup：默认Off
Allow ECP flow： 默认Off

Signature and Encryption的内容有：
Sign documents： 默认On
Sign assertions： 默认Off
Signature algorithm： 下拉默认:RSA_SHA256
SAML signature key name : none
Canonicalization method: exclusive
Metadata descriptor: 空白
Use metadata descriptor URL: 默认Off

Login settings的内容有：
Login theme： 下拉框base/keycloak/keycloak.v2
Consent required: 默认Off
Display client on screen：默认Off
Consent screen text:

Logout settings的内容有：
Front channel logout: 默认On

● Client 创建成功。现在在这个 Settings 页里改以下几项：

SAML capabilities 部分：
- Force name ID format：改为 On

Signature and Encryption 部分：
- Sign assertions：改为 On
- SAML signature key name：下拉选 CERT_SUBJECT（当前是 none）

其余所有选项保持默认不动。

改完后点页面底部的 Save，告诉我保存结果。

✻ Sautéed for 10s

> 已修改，显示：Client successfully updated
上面的Tabs有7个，分别是：
Settings，Keys，Roles，Client scopes，Sessions，Advanced，Events
现在的改动是SettingsTab页，其它的Tab还需要改吗？

● 其他 Tab 现在都不需要改，Settings 改完就够了。

Keycloak 这边还剩两件事：

  ---
第四步：创建测试用户

左侧菜单点 Users → 右侧点 Create new user：
- Username：填 testuser
- 其他留空

点 Create，成功后点 Credentials 标签：
- 点 Set password
- 填一个密码（比如 Test@1234）
- Temporary 改为 Off（否则第一次登录会强制改密码，影响测试）
- 点 Save → Save password

  ---
第五步：获取 IdP 元数据

用户创建完之后，在浏览器访问这个地址（把 IP 换成你主机的实际 IP）：

http://<主机IP>:8180/realms/mylogin/protocol/saml/descriptor

浏览器会显示一段 XML，把整个页面内容复制下来告诉我，或者直接截图给我看格式是否正确。

✻ Baked for 21s

> 用户创建完成，元数据 XML 内容如下：
<md:EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" entityID="http://36.151.149.59:8180/realms/mylogin">
<md:IDPSSODescriptor WantAuthnRequestsSigned="true" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
<md:KeyDescriptor use="signing">
<ds:KeyInfo>
<ds:KeyName>xQgJxDj1J9I6qq1yduaM1mH4FcYUuM0y4cLQmEoxKt8</ds:KeyName>
<ds:X509Data>
<ds:X509Certificate>MIICnTCCAYUCBgGePvXYezANBgkqhkiG9w0BAQsFADASMRAwDgYDVQQDDAdteWxvZ2luMB4XDTI2MDUxOTA2MzczOVoXDTM2MDUxOTA2MzkxOVowEjEQMA4GA1UEAwwHbXlsb2dpbjCCA
SIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMSwmUhSB35nEgOuLLgSmSR69S21GvFaOArG8i8a2S7M/sHLX6hT6v4UzpoPdi/pecRFjalyAoLeiRr4ki4gIAl7E2Ib070JLTR1qlW7rfm/EPiRO9B/FqjUtc
Jy/bGIXqqnVbCgnEVaPMps4ARNySsq8OZQgr5U8NMCZytApezvu/fZhY2V7kSHyW/R3hmihRPxW0L1cnLi1PvVV5LBAm8aEulD0FkgTVlYapFA6VqzNVEw9JGaYakyxCMoTtpOpv0Bx5ns6bc1fnGxzgcBQmj25MY
KQ+QXA3X1T298OkgWMdP1RGFNvcRkjAe58dNGkv/sSzXZM55h24t24gDy420CAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAbKkptRzWPDzSkkogI/mH2UjXF7JwwKZ2xqXJwyRv2pDD0+3/I07odxGaxmT9wxHdtln5
X/Zn6XPa5oSk6L66avaprgr0g/cZVZestU2Z1VoCJ2kHYNk22ArxApokpeSMcIioP0hejkjxsuC4JL4hmJgb4twzE01N2k26NPRFyYefCjq6fDdre0FSelvZKY9msfofCcHbRJWs6MyxOGaIAOkLEm35n/y8A+iAr
Qm68BvLdd6pMpyjU5YT1zdQjlM/DD2AdSGgi44FkAoL88MhpwFJUC1tznsHOeUBfh2BbI81RJYIj905df/b9RR49TEonVW14F3W4+KXi5aQSeASpg==</ds:X509Certificate>
</ds:X509Data>
</ds:KeyInfo>
</md:KeyDescriptor>
<md:ArtifactResolutionService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://36.151.149.59:8180/realms/mylogin/protocol/saml/resolve"
index="0"/>
<md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="http://36.151.149.59:8180/realms/mylogin/protocol/saml"/>
<md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="http://36.151.149.59:8180/realms/mylogin/protocol/saml"/>
<md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact" Location="http://36.151.149.59:8180/realms/mylogin/protocol/saml"/>
<md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://36.151.149.59:8180/realms/mylogin/protocol/saml"/>
<md:NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</md:NameIDFormat>
<md:NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</md:NameIDFormat>
<md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified</md:NameIDFormat>
<md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
<md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="http://36.151.149.59:8180/realms/mylogin/protocol/saml"/>
<md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="http://36.151.149.59:8180/realms/mylogin/protocol/saml"/>
<md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="http://36.151.149.59:8180/realms/mylogin/protocol/saml"/>
<md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact" Location="http://36.151.149.59:8180/realms/mylogin/protocol/saml"/>
</md:IDPSSODescriptor>
</md:EntityDescriptor>

● 元数据获取成功，内容完整。从中提取到关键信息：

┌─────────────────────────┬────────────────────────────────────────────────────────┐
│          项目           │                           值                           │
├─────────────────────────┼────────────────────────────────────────────────────────┤
│ IdP Entity ID           │ http://36.151.149.59:8180/realms/mylogin               │
├─────────────────────────┼────────────────────────────────────────────────────────┤
│ SSO 地址                │ http://36.151.149.59:8180/realms/mylogin/protocol/saml │
├─────────────────────────┼────────────────────────────────────────────────────────┤
│ 签名证书                │ 已包含                                                 │
├─────────────────────────┼────────────────────────────────────────────────────────┤
│ WantAuthnRequestsSigned │ true                                                   │
└─────────────────────────┴────────────────────────────────────────────────────────┘

有一点需要说明：元数据里 WantAuthnRequestsSigned="true" 表示 Keycloak 希望 SP 对请求签名。我们第一版先让 Spring Security 不签名，Keycloak
默认不会强制校验，跑通后再按需加上。

  ---
Keycloak 这边配置全部完成。现在可以开始改代码了，涉及三个地方：

后端（改动较多）：
1. pom.xml — 加 SAML2 依赖
2. src/main/resources/ — 放入刚才的元数据 XML 文件
3. SecurityConfig.java — 从表单登录改为 SAML2 登录

前端（改动很少）：
- 登录页加一个"SSO 登录"按钮，点击直接跳转到后端 SAML2 发起端点

现在开始改代码吗？
