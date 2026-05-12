登录时 SecurityContext 的创建与存储全链路

  ---
一、全局时序图

POST /login (username=admin&password=123456)
│
▼
SecurityContextHolderFilter          ← 加载旧 Context（此时只有空/匿名）
│
▼
UsernamePasswordAuthenticationFilter
│
├─① attemptAuthentication()
│       │
│       ▼
│   ProviderManager.authenticate()
│       │
│       ▼
│   DaoAuthenticationProvider
│       ├── UserDetailsServiceImpl.loadUserByUsername()
│       ├── BCrypt.matches(表单密码, DB哈希)
│       └── 返回 已认证的 Authentication 对象
│
├─② sessionStrategy.onAuthentication()   ← Session Fixation 防护
│       换 Session ID，新 JSESSIONID Cookie
│
└─③ successfulAuthentication()           ← SecurityContext 在这里诞生
├── createEmptyContext()          ← 创建空 SecurityContext
├── context.setAuthentication()   ← 把 Authentication 装进去
├── SecurityContextHolder.setContext()  ← 绑定 ThreadLocal
├── securityContextRepository.saveContext()  ← 写入 HttpSession
├── rememberMeServices.loginSuccess()   ← 可选：remember-me Cookie
└── redirect → /dashboard
│
▼
SecurityContextHolderFilter finally块
└── SecurityContextHolder.clearContext()  ← 清空 ThreadLocal

  ---
二、第一棒：过滤器入口时，SecurityContext 在哪里

请求进入 Spring Security 过滤链，第一个处理安全上下文的是 SecurityContextHolderFilter（Spring Security 6.x 的默认实现，替代了旧的
SecurityContextPersistenceFilter）：

// SecurityContextHolderFilter.doFilter()
public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) {

      // 从 SecurityContextRepository（默认是 HttpSessionSecurityContextRepository）加载
      // 对于全新登录：Session 里没有 SPRING_SECURITY_CONTEXT，返回空 Context
      Supplier<SecurityContext> deferredContext =
          securityContextRepository.loadDeferredContext(request);

      try {
          securityContextHolderStrategy.setDeferredContext(deferredContext);
          chain.doFilter(request, response);   // 继续往下走
      } finally {
          // 无论成功失败，请求结束时必须清空 ThreadLocal
          securityContextHolderStrategy.clearContext();
          request.removeAttribute(FILTER_APPLIED);
      }
}

注意两点：
- 这里加载的 Context 是懒加载（Deferred），不会立刻读 Session，等到真正调用 getContext() 才触发
- 对于第一次登录：Session 里没有 SPRING_SECURITY_CONTEXT，加载结果是一个空的 SecurityContextImpl，Authentication 为 null
- finally 块里的 clearContext() 是安全保障线，无论后续发生什么都会执行

  ---
三、第二棒：UsernamePasswordAuthenticationFilter 的认证过程

这个 Filter 的父类是 AbstractAuthenticationProcessingFilter，真正的入口在父类的 doFilter()：

// AbstractAuthenticationProcessingFilter.doFilter()
public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) {

      // 判断当前请求是不是登录 URL（POST /login）
      if (!requiresAuthentication(request, response)) {
          chain.doFilter(request, response);  // 不是登录请求，直接放行
          return;
      }

      try {
          // ① 执行认证
          Authentication authResult = attemptAuthentication(request, response);

          // ② Session Fixation 防护（见第四节）
          this.sessionStrategy.onAuthentication(authResult, request, response);

          // ③ 认证成功处理（SecurityContext 在这里诞生）
          successfulAuthentication(request, response, chain, authResult);

      } catch (AuthenticationException ex) {
          // 认证失败
          unsuccessfulAuthentication(request, response, ex);
      }
}

attemptAuthentication() 是子类 UsernamePasswordAuthenticationFilter 实现的：

public Authentication attemptAuthentication(HttpServletRequest request, HttpServletResponse response) {

      String username = obtainUsername(request);  // 取表单 username 字段
      String password = obtainPassword(request);  // 取表单 password 字段

      // 创建一个【未认证】的 Token，authenticated = false
      UsernamePasswordAuthenticationToken authRequest =
          UsernamePasswordAuthenticationToken.unauthenticated(username, password);

      // 把请求信息附加到 Token 的 details（IP、SessionId 等）
      setDetails(request, authRequest);

      // 交给 AuthenticationManager 去认证
      return this.getAuthenticationManager().authenticate(authRequest);
}

认证链路：ProviderManager → DaoAuthenticationProvider：

// DaoAuthenticationProvider（继承 AbstractUserDetailsAuthenticationProvider）

// 第一步：加载用户
UserDetails user = retrieveUser(username, authentication);
// → UserDetailsServiceImpl.loadUserByUsername()
// → userRepository.findByUsername(username)
// → 从 SQL Server 的 sys_user 表查出来

// 第二步：校验账号状态（未锁定、未禁用、未过期）
preAuthenticationChecks.check(user);

// 第三步：比对密码
additionalAuthenticationChecks(user, authentication);
// → BCryptPasswordEncoder.matches(表单明文, DB哈希)
// → 不匹配则抛 BadCredentialsException

// 第四步：构造【已认证】的 Token 返回
return UsernamePasswordAuthenticationToken.authenticated(
user,                    // principal = UserDetails 对象
authentication.getCredentials(),  // credentials = 密码（马上会被清除）
user.getAuthorities()    // [ROLE_USER]
// authenticated = true（区别于入参的 false）
);

此时返回的 Authentication 对象是已认证的，isAuthenticated() 为 true，但它还只是一个普通 Java 对象，漂浮在内存里，还没有和任何 SecurityContext 或 Session 关联。

  ---
四、第三棒：Session Fixation 防护 —— 换 Session ID

认证通过后，在 SecurityContext 被创建之前，有一个容易被忽视的重要步骤：

// AbstractAuthenticationProcessingFilter.doFilter() 里
this.sessionStrategy.onAuthentication(authResult, request, response);

默认策略是 ChangeSessionIdAuthenticationStrategy（Servlet 3.1+）：

// ChangeSessionIdAuthenticationStrategy.onAuthentication()
public void onAuthentication(Authentication authentication,
HttpServletRequest request, HttpServletResponse response) {

      HttpSession session = request.getSession(false);
      if (session == null) return;   // 没有旧 Session 则跳过

      // 关键：改变 Session ID，但保留 Session 里的所有属性（包括 CSRF token）
      request.changeSessionId();
      // Servlet 容器会：
      //   1. 生成新的 Session ID（SecureRandom）
      //   2. 在 Manager 的 sessions Map 里更换 key
      //   3. 旧 JSESSIONID Cookie 失效
      //   4. 响应里追加 Set-Cookie: JSESSIONID=<新ID>; Path=/; HttpOnly
}

为什么要在这里换 ID？

这是防 Session Fixation 攻击 的标准手段。攻击者可以在用户登录前先设定一个已知的 Session ID，如果登录后 Session ID 不变，攻击者就能用这个已知 ID
冒充登录后的用户。换 ID 切断了这个链条。

  ---
五、第四棒：successfulAuthentication() —— SecurityContext 诞生的精确时刻

这是整条链路最核心的方法：

// AbstractAuthenticationProcessingFilter.successfulAuthentication()
protected void successfulAuthentication(HttpServletRequest request,
HttpServletResponse response, FilterChain chain,
Authentication authResult) throws IOException, ServletException {

      // ① 创建一个全新的空 SecurityContext
      //    SecurityContextHolder.createEmptyContext()
      //    → new SecurityContextImpl()
      //    此时 Authentication 字段为 null
      SecurityContext context = this.securityContextHolderStrategy.createEmptyContext();

      // ② 把刚认证好的 Authentication 装入 SecurityContext
      context.setAuthentication(authResult);
      //    SecurityContextImpl.authentication = UsernamePasswordAuthenticationToken{
      //        principal = UserDetails{username="admin", authorities=[ROLE_USER]},
      //        authenticated = true
      //    }

      // ③ 把 SecurityContext 放入 SecurityContextHolder（绑定到当前线程 ThreadLocal）
      this.securityContextHolderStrategy.setContext(context);
      //    ThreadLocal<SecurityContext>.set(context)
      //    从这一刻起，当前线程任何地方调用
      //    SecurityContextHolder.getContext() 都能拿到这个 context

      // ④ 把 SecurityContext 持久化到 HttpSession（跨请求保存）
      this.securityContextRepository.saveContext(context, request, response);
      //    → HttpSessionSecurityContextRepository.saveContext()（见下节）

      // ⑤ Remember-me 处理（如果用户勾选了"记住我"）
      this.rememberMeServices.loginSuccess(request, response, authResult);
      //    → TokenBasedRememberMeServices：生成签名 Token，Set-Cookie: remember-me=...

      // ⑥ 发布应用事件（供业务代码监听，如记录登录日志）
      if (this.eventPublisher != null) {
          this.eventPublisher.publishEvent(
              new InteractiveAuthenticationSuccessEvent(authResult, this.getClass())
          );
      }

      // ⑦ 重定向到登录成功页
      this.successHandler.onAuthenticationSuccess(request, response, authResult);
      //    → SimpleUrlAuthenticationSuccessHandler → redirect /dashboard
}

  ---
六、第五棒：saveContext() —— 写入 HttpSession

// HttpSessionSecurityContextRepository.saveContext()
public void saveContext(SecurityContext context,
HttpServletRequest request, HttpServletResponse response) {

      Authentication authentication = context.getAuthentication();

      // 如果是匿名身份或未认证，不存 Session
      if (authentication == null || trustResolver.isAnonymous(authentication)) {
          // 如果 Session 里有旧的 Context，清掉
          HttpSession session = request.getSession(false);
          if (session != null) {
              session.removeAttribute(springSecurityContextKey);
          }
          return;
      }

      // 获取或创建 HttpSession
      // （换完 Session ID 之后，request.getSession(true) 拿到的是新 Session）
      HttpSession httpSession = request.getSession(true);

      // 核心：把 SecurityContext 作为属性存入 Session
      httpSession.setAttribute(springSecurityContextKey, context);
      //    springSecurityContextKey = "SPRING_SECURITY_CONTEXT"
      //    即：session.setAttribute("SPRING_SECURITY_CONTEXT", SecurityContextImpl{...})
      //    因为 SecurityContext implements Serializable，可以被序列化
}

完成后，HttpSession 的属性表里多了一条：

Session[新ID] {
"SPRING_SECURITY_CONTEXT" → SecurityContextImpl {
authentication = UsernamePasswordAuthenticationToken {
principal = UserDetails{ username="admin" }
authorities = [ROLE_USER]
authenticated = true
}
}
}

  ---
七、第六棒：finally 清空 ThreadLocal

整个请求结束，回到最外层的 SecurityContextHolderFilter：

// SecurityContextHolderFilter.doFilter() 的 finally 块
finally {
securityContextHolderStrategy.clearContext();
//    ThreadLocal<SecurityContext>.remove()
//    SecurityContext 从线程上摘下来
//    但 HttpSession 里的那份还在，不受影响
}

ThreadLocal 里的 SecurityContext 消失了，HttpSession 里的完好无损。 这就是"一次登录，多次请求都不用重新认证"的原理。

  ---
八、完整接力棒示意图

POST /login
│
▼ SecurityContextHolderFilter
│  加载 Session → 空 Context → 放入 ThreadLocal
│
▼ UsernamePasswordAuthenticationFilter
│  ① 提取 username/password
│  ② 构造 未认证Token → AuthenticationManager
│         → DaoAuthenticationProvider
│               → UserDetailsService（查DB）
│               → BCrypt（比对密码）
│         ← 返回 已认证Token
│  ③ SessionFixation：换 Session ID（新 JSESSIONID Cookie）
│  ④ successfulAuthentication()
│       createEmptyContext()          → SecurityContextImpl（空）
│       context.setAuthentication()   → 装入已认证Token
│       SecurityContextHolder.set()   → 绑定 ThreadLocal ✓
│       securityContextRepository     → HttpSession.setAttribute(
│         .saveContext()                  "SPRING_SECURITY_CONTEXT",
│                                          context)           ✓
│       rememberMeServices            → Set-Cookie: remember-me（可选）
│       redirect /dashboard
│
▼ SecurityContextHolderFilter finally
clearContext()                     → ThreadLocal 清空

浏览器收到：
302 Location: /dashboard
Set-Cookie: JSESSIONID=<新ID>; Path=/; HttpOnly
Set-Cookie: remember-me=<签名Token>（如果勾选了）

  ---
九、一个关键区别：Spring Security 5 vs 6

Column 1: 谁负责保存 Context 到 Session
Spring Security 5（旧）: SecurityContextPersistenceFilter（自动，请求结束时保存）
Spring Security 6（新，你的项目）: AbstractAuthenticationProcessingFilter.successfulAuthentication() 里显式调用 saveContext()
────────────────────────────────────────
Column 1: 普通已登录请求会触发 Session 写入吗
Spring Security 5（旧）: 会（每次请求结束都写）
Spring Security 6（新，你的项目）: 不会（除非代码主动调用 saveContext()）
────────────────────────────────────────
Column 1: 旧过滤器
Spring Security 5（旧）: SecurityContextPersistenceFilter
Spring Security 6（新，你的项目）: SecurityContextHolderFilter

你的项目用 Spring Boot 3.5.14，内置 Spring Security 6.x，走的是新模型 —— SecurityContext 只在认证成功的那一刻由 successfulAuthentication() 显式写入
Session，后续普通请求只读不写。

