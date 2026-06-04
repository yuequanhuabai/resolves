 好的，流程 A（登录）来了。我先用六要素给一个宏观全景，再把最关键的「经过」拆成逐步明细。

  ---
  流程 A：登录（密码对比 + 签发 token）

  一、六要素全景

  ┌──────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ 要素 │                                                                   内容                                                                   │
  ├──────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 时间 │ 用户在登录页输入账号密码、点击「登录」按钮的那一刻起，到后端返回 token 为止                                                              │
  ├──────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 地点 │ 前端 LoginView.vue / auth.js / api/index.js；后端 AuthController → AuthenticationManager → UserDetailsServiceImpl →                      │
  │      │ BCryptPasswordEncoder → JwtUtil                                                                                                          │
  ├──────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 人物 │ 用户、Axios 实例、Spring Security 认证体系、JPA、数据库 sys_user 表                                                                      │
  ├──────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 起因 │ 后端是 STATELESS 无状态的，用户想访问受保护资源，必须先用账密换取一张「通行证」(token)                                                   │
  ├──────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 经过 │ 前端提交账密 → 后端查库取出加密密码 → BCrypt 比对 → 比对通过则签发 JWT（详见下方分步）                                                   │
  ├──────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 结果 │ 后端返回 {token, username}，前端存入 localStorage，登录完成；之后凭 token 访问（进入流程 B）                                             │
  └──────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  ---
  二、「经过」分步详解（核心）

  🔹 第 1 步：前端收集账密并发请求

  - 地点：mylogin-front/src/views/LoginView.vue:65 → stores/auth.js:12
  - 经过：点击登录触发 handleLogin()，调用 authStore.login(form.value)，里面执行：
  const res = await api.post('/api/auth/login', { username: uname, password })
  - 注意：此时发送的是明文用户名 + 明文密码（靠 HTTPS 保护传输，本 demo 是 http）。此刻还没有 token。
  - 结果：一个 POST 请求发往 http://localhost:8888/api/auth/login

  ---
  🔹 第 2 步：请求进入后端，穿过安全过滤器链

  - 地点：mylogin-back 的 JwtAuthFilter → SecurityConfig
  - 起因：Spring Security 规定，所有请求都要先过滤器链
  - 经过：
    a. 先经过 JwtAuthFilter（filter/JwtAuthFilter.java:37）。它检查请求头有没有 Authorization: Bearer ...。登录请求没有带 token，所以 if
  条件不成立，过滤器直接放行，什么都不做。
    b. 接着 SecurityConfig.java:40 的规则判定：/api/auth/login 被配置为 permitAll()，无需认证即可访问。
  - 结果：请求顺利到达 AuthController

  ▎ 关键点：登录接口本身是不需要认证的（否则就死锁了——没登录哪来的 token）。

  ---
  🔹 第 3 步：Controller 接手，委托给认证管理器

  - 地点：controller/AuthController.java:27
  - 人物：AuthController + AuthenticationManager
  - 经过：
  Authentication auth = authenticationManager.authenticate(
      new UsernamePasswordAuthenticationToken(request.username(), request.password())
  );
  - Controller 自己不做密码校验，而是把「用户名+密码」包装成一个未认证的 UsernamePasswordAuthenticationToken，丢给 AuthenticationManager 去处理。
  - 结果：认证流程交棒给 Spring Security 内部

  ---
  🔹 第 4 步：去数据库把用户捞出来

  - 地点：AuthenticationManager 内部 → service/UserDetailsServiceImpl.java:19 → repository/UserRepository.java:9
  - 起因：要比对密码，得先知道这个用户**数据库里存的密码（密文）**是什么
  - 经过：
    a. AuthenticationManager 内部的 DaoAuthenticationProvider 调用 UserDetailsServiceImpl.loadUserByUsername(username)
    b. 它通过 JPA 执行 findByUsername → 查 SQL Server 的 sys_user 表
    c. 查到则封装成 UserDetails（含数据库里那串 BCrypt 密文密码和 enabled 状态）；查不到则抛 UsernameNotFoundException
  - 结果：拿到该用户在库里的「标准答案」——加密后的密码

  ---
  🔹 第 5 步：密码对比（流程 A 的灵魂，密码唯一出现的地方）

  - 地点：DaoAuthenticationProvider 内部，使用 SecurityConfig.java:73 注册的 BCryptPasswordEncoder
  - 人物：BCryptPasswordEncoder
  - 经过：
    - 前端传来的是明文密码，数据库存的是 BCrypt 密文（不可逆，无法解密）
    - 所以不是「把密文解密回明文再比」，而是用 BCrypt 算法：encoder.matches(明文, 密文)
    - BCrypt 从密文里取出当初的盐(salt)，对明文重新做一次哈希，再比对结果是否一致
  - 结果：
    - ✅ 一致 → 认证成功，返回一个已认证的 Authentication 对象
    - ❌ 不一致 → 抛 BadCredentialsException（属于 AuthenticationException）

  ---
  🔹 第 6 步：签发 JWT（造通行证）

  - 地点：controller/AuthController.java:32 → util/JwtUtil.java:27
  - 起因：密码已验过，现在要发一张「以后免密」的凭证
  - 经过：
  String token = jwtUtil.generate(auth.getName());
  - JwtUtil.generate 用 JJWT 构建一个 JWT：
    - subject = 用户名
    - issuedAt = 现在
    - expiration = 现在 + 7 天（JwtUtil.java:32）
    - 签名 = 用 application.yml 里的密钥做 HS256 对称签名（JwtUtil.java:33）
  - 结果：得到一串 xxxxx.yyyyy.zzzzz 形式的 token。这串签名是后续流程 B 验证的关键——别人没有密钥就伪造不出合法签名。

  ---
  🔹 第 7 步：返回前端并落地存储

  - 地点：AuthController.java:33 → 前端 stores/auth.js:14
  - 经过：
    - 后端返回 200 OK，body 是 { "token": "...", "username": "..." }
    - 若第 5 步密码错误，则走 catch，返回 401 + {"message":"用户名或密码错误"}（AuthController.java:35）
    - 前端拿到后存入 localStorage：
  localStorage.setItem('token', res.data.token)
  localStorage.setItem('username', res.data.username)
  - 结果：登录完成，token 持久化在浏览器。之后每次请求都会带上它 → 这就接上了流程 B。

  ---
  三、一句话串起整个流程 A

  ▎ 用户交出明文密码 → 后端拿用户名查库取出 BCrypt 密文 → BCrypt 比对明文与密文 → 比对通过则用密钥签发一张 7 天有效的 JWT → 返回前端存进 localStorage。
  ▎
  ▎ 密码对比只在这里发生这一次；token 一旦签发，后续访问就不再碰密码了。

  ---
  要不要我接着讲流程 B（前端带着这张 token 来访问时，后端如何验签解析、识别用户，而全程不碰密码）？
