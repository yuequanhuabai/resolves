流程 B：带 token 访问（验签 + 识别用户，不碰密码）

一、六要素全景

┌──────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 要素 │                                                           内容                                                           │
├──────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 时间 │ 登录成功之后，用户每一次访问受保护资源（看用户列表、刷新页面、异步请求……）的那一刻                                       │
├──────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 地点 │ 前端 api/index.js（请求拦截器）；后端 JwtAuthFilter → JwtUtil → UserDetailsServiceImpl → SecurityContext → 各 Controller │
├──────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 人物 │ Axios 拦截器、JwtAuthFilter、JwtUtil、SecurityContextHolder、目标 Controller                                             │
├──────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 起因 │ 后端是 STATELESS 无状态的，它不记得你登录过；所以每次请求你都得自己出示 token 证明身份                                   │
├──────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 经过 │ 前端自动带上 token → 过滤器取出并用密钥验签 → 解析出用户名 → 查库加载权限 → 写入安全上下文 → 放行到 Controller           │
├──────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 结果 │ 后端「认出」你是谁，正常返回数据；若 token 无效/过期，则返回 401，前端自动踢回登录页                                     │
└──────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  ---
二、「经过」分步详解（核心）

🔹 第 1 步：前端自动给请求贴上 token

- 地点：mylogin-front/src/api/index.js:8-14（请求拦截器）
- 起因：token 存在 localStorage，浏览器不会自动发送，必须手动注入
- 经过：任何一次 api.xxx() 请求发出前，拦截器从 localStorage 取出 token，塞进请求头：
  config.headers.Authorization = `Bearer ${token}`
- 结果：请求头带上 Authorization: Bearer xxxxx.yyyyy.zzzzz 发往后端。注意：这次发的是 token，没有密码。

  ---
🔹 第 2 步：请求进入过滤器，取出 token

- 地点：filter/JwtAuthFilter.java:37-40
- 人物：JwtAuthFilter（每个请求都过一次的 OncePerRequestFilter）
- 经过：
  String header = request.getHeader("Authorization");
  if (header != null && header.startsWith("Bearer ")) {
  String token = header.substring(7);   // 去掉 "Bearer " 前缀，拿到纯 token
- 结果：拿到纯 token 字符串，准备验签

  ---
🔹 第 3 步：⭐ 用密钥验签（流程 B 的灵魂，对应你前面问的密钥）

- 地点：JwtAuthFilter.java:41 → util/JwtUtil.java:41-56
- 起因：要确认这张 token 是后端自己签发的、没被篡改、还没过期
- 经过：
  if (jwtUtil.isValid(token)) { ... }
- isValid 内部调用 claims(token)：
  Jwts.parser()
  .verifyWith(key())          // ← 用你配置的那把密钥验签
  .build()
  .parseSignedClaims(token)   // 验签 + 验过期，任一失败就抛异常
- 这一步同时检查两件事：
  a. 签名：用密钥重新算一遍签名，和 token 里带的签名比对 → 防伪造、防篡改
  b. 过期时间：当前时间是否超过 token 里的 expiration（7 天）

任一不通过就抛 JwtException，被 catch 住返回 false。
- 结果：
    - ✅ 验签通过 → 继续往下
    - ❌ 失败（伪造/篡改/过期）→ 过滤器什么都不做直接放行，但安全上下文是空的（后果见第 7 步）

▎ 🔑 划重点：这里只验签名和过期，不查数据库密码、不做任何密码对比。token 本身就是「我登录过」的证明。这就是和流程 A 最本质的区别。

  ---
🔹 第 4 步：从 token 里解析出「你是谁」

- 地点：JwtAuthFilter.java:42 → JwtUtil.java:37-39
- 经过：
  String username = jwtUtil.extractUsername(token);  // 取 JWT 的 subject
- 还记得流程 A 第 6 步签发时把用户名写进了 subject 吗？这里就是把它取回来。
- 结果：得到用户名，比如 admin

  ---
🔹 第 5 步：查库加载用户权限（注意：这是为了拿权限，不是验密码）

- 地点：JwtAuthFilter.java:43-44 → UserDetailsServiceImpl.java:19
- 起因：光知道用户名还不够，Spring Security 需要这个用户的权限/角色信息才能做后续鉴权
- 经过：
  if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
  UserDetails userDetails = userDetailsService.loadUserByUsername(username);
- 又去查了一次 sys_user 表。但这次只取出用户和它的角色（roles("USER")），完全没用到密码字段做比对。
- 结果：拿到带权限的 UserDetails

▎ 💡 这一步会查库，是这套实现的取舍：好处是用户被禁用/删除能及时反映；代价是每个请求多一次 DB 查询（很多生产方案会把角色直接放进 JWT 里以免查库）。

  ---
🔹 第 6 步：把身份写进「安全上下文」

- 地点：JwtAuthFilter.java:45-48
- 经过：
  UsernamePasswordAuthenticationToken auth =
  new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
  //                                                       ↑ credentials 传 null，因为不需要密码
  auth.setDetails(...);
  SecurityContextHolder.getContext().setAuthentication(auth);
- 构造一个已认证的 Authentication 对象，注意第二个参数（密码/凭证）直接传 null——再次印证流程 B 不需要密码。然后存入 SecurityContextHolder。
- 结果：从这一刻起，本次请求在 Spring Security 眼里就是「已认证的 admin」

  ---
🔹 第 7 步：过滤器放行，安全规则做最终裁决

- 地点：JwtAuthFilter.java:53 → SecurityConfig.java:41
- 经过：
  chain.doFilter(request, response);  // 继续后续过滤器链
- 请求走到 SecurityConfig 的规则 anyRequest().authenticated()：
    - 上下文里有认证对象 → ✅ 放行到 Controller
    - 上下文是空的（第 3 步没过/没带 token）→ ❌ 触发 authenticationEntryPoint（SecurityConfig.java:45），返回 401 {"error":"Unauthorized"}
- 结果：合法请求进入业务层；非法请求当场被拦下返回 401

  ---
🔹 第 8 步：Controller 拿到身份，处理业务

- 地点：各 Controller，如 AuthController.java:46、AsyncController.java:19
- 经过：业务代码可直接拿到当前用户，无需再解析 token：
  // 方式一：注解注入
  public ResponseEntity<...> me(@AuthenticationPrincipal UserDetails userDetails) { ... }
  // 方式二：从上下文取
  Authentication auth = SecurityContextHolder.getContext().getAuthentication();
- 结果：返回该用户对应的数据（用户名、用户列表等）

▎ 🧵 异步细节：AsyncController 返回 Callable（异步线程执行）。JwtAuthFilter.java:29 重写了
▎ shouldNotFilterAsyncDispatch()=false，让异步派发时过滤器再走一遍，保证异步线程里 SecurityContextHolder
▎ 仍能拿到身份——这正是你最新那个提交「异步线程重走Filter」解决的问题。

  ---
🔹 第 9 步（失败回路）：401 后前端自动登出

- 地点：api/index.js:17-27（响应拦截器）
- 经过：若后端返回 401（token 过期/无效），前端拦截器捕获：
  if (error.response?.status === 401) {
  localStorage.removeItem('token')
  localStorage.removeItem('username')
  window.location.href = '/login'
  }
- 结果：清掉本地失效 token，自动跳回登录页 → 用户重新走流程 A。闭环完成。

  ---
三、一句话串起整个流程 B

▎ 前端自动把 token 贴进请求头 → JwtAuthFilter 取出 token → 用密钥验签名 + 验过期 → 解析出用户名 → 查库加载权限（不验密码）→ 写入安全上下文 → 放行到
▎ Controller。
▎
▎ 全程不碰密码；token 的签名就是身份证明。验不过就 401，前端自动踢回登录页。

  ---
四、流程 A vs 流程 B 对照（帮你彻底分清）

┌────────────┬──────────────────────┬─────────────────────────┐
│            │    流程 A（登录）    │ 流程 B（带 token 访问） │
├────────────┼──────────────────────┼─────────────────────────┤
│ 前端发什么 │ 用户名 + 密码        │ token                   │
├────────────┼──────────────────────┼─────────────────────────┤
│ 发生地点   │ AuthController.login │ JwtAuthFilter           │
├────────────┼──────────────────────┼─────────────────────────┤
│ 密钥干嘛用 │ 签发 token           │ 验签 token              │
├────────────┼──────────────────────┼─────────────────────────┤
│ 查数据库   │ 取密码做比对         │ 取权限（不比密码）      │
├────────────┼──────────────────────┼─────────────────────────┤
│ 密码对比   │ ✅ BCrypt 比对一次   │ ❌ 完全不碰             │
├────────────┼──────────────────────┼─────────────────────────┤
│ 产出       │ 一张 token           │ 一个「已认证」身份      │
├────────────┼──────────────────────┼─────────────────────────┤
│ 触发频率   │ 仅登录时一次         │ 几乎每个请求            │
└────────────┴──────────────────────┴─────────────────────────┘

这下流程 A、B 就完整拼起来了。需要我把这两个流程画成一张时序图，或者对比 jwt 和 jwt-2token（双 token）分支的差异吗？
