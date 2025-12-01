# Spring-Web 模块深度分析文档

## 模块概述

spring-web 是 Spring Framework 的基础 Web 模块，提供通用的 Web 功能抽象和工具支持。它独立于任何特定的 Web 框架（Servlet/WebFlux），为 spring-webmvc、spring-webflux 等上层模块提供基础设施。

**核心职责**：
- Web 请求上下文绑定（RequestContextHolder）
- HTTP 请求处理通用接口（HttpRequestHandler）
- 方法参数与返回值解析策略
- 过滤器与拦截器基础框架
- CORS 跨域资源共享处理
- 文件上传（MultiPart）解析
- 绑定数据验证（WebDataBinder）
- Servlet 容器初始化（Servlet 3.0+）

---

## 一、时间（When）：请求处理的生命周期阶段

### 服务器启动阶段（Server Startup）
- **时间点**：Servlet 容器启动时
- **触发机制**：
  - 传统方式：web.xml 配置 ContextLoaderListener
  - 新方式：Servlet 3.0+ SpringServletContainerInitializer 自动检测 WebApplicationInitializer
- **操作内容**：
  - ContextLoader 初始化根 ApplicationContext
  - 加载 web.xml 或 JavaConfig 配置
  - 注册 DispatcherServlet、Filter、Listener

### 单次请求处理阶段（Per-Request Processing）
```
1. 请求进入（Request Arrival）
   ↓ Servlet 容器调用 Filter.doFilter()

2. 过滤链传播（Filter Chain）
   ↓ 经过 RequestContextFilter、CorsFilter 等

3. DispatcherServlet 处理（Dispatch）
   ↓ 处理请求分发、参数解析、响应生成

4. 请求完成（Request Completion）
   ↓ RequestContextHolder 清理、资源释放
```

### 请求上下文绑定时机（Request Context Binding）
- **绑定时间**：请求进入 Filter 或 DispatcherServlet 时
- **绑定位置**：RequestContextHolder 中的 ThreadLocal
- **解绑时间**：请求完成后（finally 块）

---

## 二、地点（Where）：关键代码位置与模块分布

### 核心顶层模块
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web` | `HttpRequestHandler` | HTTP 请求处理顶层接口 |
| `org.springframework.web` | `WebApplicationInitializer` | Servlet 3.0+ 编程式初始化 SPI |
| `org.springframework.web` | `SpringServletContainerInitializer` | Servlet 容器启动时自动加载 |

### Web 上下文模块
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.context` | `ContextLoader` | 根 ApplicationContext 初始化器 |
| `org.springframework.web.context` | `ContextLoaderListener` | Servlet 生命周期监听器 |
| `org.springframework.web.context.request` | `RequestContextHolder` | ThreadLocal 请求上下文持有者 |
| `org.springframework.web.context.request` | `RequestAttributes` | 请求属性访问接口 |
| `org.springframework.web.context.support` | `WebApplicationContextUtils` | Web 应用上下文工具类 |

### 绑定与验证模块
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.bind` | `WebDataBinder` | 绑定、验证、类型转换 |
| `org.springframework.web.bind.annotation` | `@RequestMapping`、`@RequestParam` | 请求映射与参数注解 |
| `org.springframework.web.bind.support` | `WebDataBinderFactory` | WebDataBinder 工厂 |

### 方法处理模块
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.method` | `HandlerMethod` | 请求处理方法的包装 |
| `org.springframework.web.method.support` | `HandlerMethodArgumentResolver` | 方法参数解析策略 |
| `org.springframework.web.method.support` | `HandlerMethodReturnValueHandler` | 返回值处理策略 |

### 过滤器与拦截器模块
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.filter` | `OncePerRequestFilter` | 每请求一次过滤执行基类 |
| `org.springframework.web.filter` | `RequestContextFilter` | 绑定 RequestContextHolder 的过滤器 |
| `org.springframework.web.filter` | `CorsFilter` | CORS 跨域处理过滤器 |

### 跨域资源共享模块
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.cors` | `CorsConfiguration` | CORS 配置信息 |
| `org.springframework.web.cors` | `CorsProcessor` | CORS 请求处理策略 |
| `org.springframework.web.cors` | `DefaultCorsProcessor` | CORS 处理实现 |

### 文件上传模块
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.multipart` | `MultipartResolver` | 文件上传解析器接口 |
| `org.springframework.web.multipart` | `MultipartFile` | 上传文件访问接口 |
| `org.springframework.web.multipart.commons` | `CommonsMultipartResolver` | Apache Commons FileUpload 实现 |

### 内容协商模块
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.accept` | `ContentNegotiationStrategy` | 内容类型协商策略 |
| `org.springframework.web.accept` | `ContentNegotiationManager` | 内容协商管理器 |

### 工具模块
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.util` | `WebUtils` | Web 工具方法集合 |
| `org.springframework.web.util` | `UriComponents` | URL 组件解析 |
| `org.springframework.web.util.pattern` | `PathPattern` | 路径匹配模式 |

---

## 三、人物（Who）：参与角色与职责划分

### 系统参与者

**1. Servlet 容器（Servlet Container）**
- 角色：Web 应用宿主
- 职责：
  - 启动时调用 ServletContainerInitializer
  - 为每个请求创建 ServletRequest/ServletResponse
  - 管理 Filter、Servlet 的生命周期

**2. SpringServletContainerInitializer（自动启动器）**
- 角色：Spring 在 Servlet 容器中的启动点
- 职责：
  - 实现 ServletContainerInitializer 接口
  - 扫描并检测所有 WebApplicationInitializer 实现
  - 调用 WebApplicationInitializer.onStartup()

**3. WebApplicationInitializer（应用配置者）**
- 角色：应用开发者提供的初始化器
- 职责：
  - 实现 onStartup(ServletContext) 方法
  - 注册 DispatcherServlet、Filter、Listener
  - 配置 ApplicationContext
- 代码示例：
```java
public class MyWebAppInitializer implements WebApplicationInitializer {
    public void onStartup(ServletContext container) {
        XmlWebApplicationContext ctx = new XmlWebApplicationContext();
        ctx.setConfigLocation("/WEB-INF/spring/config.xml");

        ServletRegistration.Dynamic servlet =
            container.addServlet("dispatcher", new DispatcherServlet(ctx));
        servlet.addMapping("/");
        servlet.setLoadOnStartup(1);
    }
}
```

**4. ContextLoader（上下文加载器）**
- 角色：根 ApplicationContext 的创建者
- 职责：
  - 读取 web.xml 中 contextConfigLocation 参数
  - 实例化 WebApplicationContext
  - 调用 ApplicationContextInitializer 进行初始化
  - 将 context 存储到 ServletContext

**5. RequestContextHolder（请求上下文持有者）**
- 角色：ThreadLocal 请求上下文管理器
- 职责：
  - 绑定 RequestAttributes 到当前线程
  - 提供静态方法 getRequestAttributes() 访问
  - 支持可继承 ThreadLocal 传递给子线程

**6. RequestContextFilter（请求上下文过滤器）**
- 角色：请求生命周期的边界管理者
- 职责：
  - 在请求开始时调用 RequestContextHolder.setRequestAttributes()
  - 在请求结束时（finally）调用 resetRequestAttributes()
  - 确保 ThreadLocal 正确清理

**7. CorsProcessor（跨域处理器）**
- 角色：CORS 请求验证和响应头处理者
- 职责：
  - 检查请求的 Origin 是否在允许列表
  - 验证请求方法和请求头
  - 添加 CORS 响应头（Access-Control-*）

**8. MultipartResolver（文件上传解析器）**
- 角色：多部分请求的解析者
- 职责：
  - 检查是否为 multipart/form-data 请求
  - 将上传数据解析为 MultipartFile 对象
  - 管理临时文件的生命周期

**9. WebDataBinder（数据绑定器）**
- 角色：请求参数到 Java 对象的转换器
- 职责：
  - 将 HTTP 请求参数绑定到对象属性
  - 执行类型转换
  - 触发 JSR-303 验证

**10. HandlerMethodArgumentResolver（参数解析器）**
- 角色：方法参数来源的策略解析者
- 职责：
  - 识别参数类型（@RequestParam、@PathVariable 等）
  - 从请求中提取参数值
  - 进行类型转换和数据绑定

---

## 四、起因（Why）：问题背景与设计动机

### 核心问题

**问题 1：Servlet API 过于底层且版本差异大**
- **现象**：直接使用 Servlet API 需处理 ServletRequest/ServletResponse 的复杂 API，不同 Servlet 版本差异大
- **示例（无 Spring 支持）**：
```java
// 传统 Servlet 做法
public class MyServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // 手动获取参数
        String id = req.getParameter("id");
        String[] tags = req.getParameterValues("tags");

        // 手动进行类型转换
        int idInt = Integer.parseInt(id);

        // 手动设置响应
        resp.setContentType("text/html;charset=UTF-8");
        resp.getWriter().println("<h1>Result</h1>");
    }
}
```

**问题 2：请求上下文在多线程环境下难以访问**
- **现象**：业务逻辑可能需要访问当前请求对象，但在异步处理或线程池中无法直接获取
- **代码示例（无 Spring 支持）**：
```java
// 线程池异步处理时，如何获取请求对象？
public void handleRequest(HttpServletRequest request) {
    executor.execute(() -> {
        // 此时已在另一个线程，request 对象无法访问
        String userId = request.getAttribute("userId"); // 错误！
    });
}
```

**问题 3：跨域请求的繁琐处理**
- **现象**：CORS 预检请求需要手动验证和添加响应头
- **代码示例（无 Spring 支持）**：
```java
public void doGet(HttpServletRequest req, HttpServletResponse resp) {
    String origin = req.getHeader("Origin");

    // 手动验证 origin
    if (allowedOrigins.contains(origin)) {
        resp.setHeader("Access-Control-Allow-Origin", origin);
        resp.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers", "Content-Type");
        resp.setHeader("Access-Control-Allow-Credentials", "true");
        resp.setHeader("Access-Control-Max-Age", "3600");
    }
}
```

**问题 4：文件上传解析的复杂性**
- **现象**：multipart/form-data 解析涉及文件流管理、临时文件处理、参数混合解析等复杂逻辑
- **代码示例（无 Spring 支持）**：
```java
public void handleFileUpload(HttpServletRequest req) throws Exception {
    // 手动检查 content-type
    if (!ServletFileUpload.isMultipartContent(req)) {
        throw new Exception("Not multipart request");
    }

    // 手动处理上传
    ServletFileUpload upload = new ServletFileUpload(new DiskFileItemFactory());
    List<FileItem> items = upload.parseRequest(req);

    for (FileItem item : items) {
        if (item.isFormField()) {
            String fieldValue = item.getString();
        } else {
            // 手动保存文件
            String fileName = new File(item.getName()).getName();
            item.write(new File(uploadDir, fileName));
        }
    }
}
```

**问题 5：Servlet 容器初始化的 web.xml 繁琐性**
- **现象**：需要手写 XML 配置注册 Servlet、Filter、Listener
- **示例（无 Spring 支持）**：
```xml
<!-- web.xml 方式，代码量大且易出错 -->
<listener>
    <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
</listener>

<context-param>
    <param-name>contextConfigLocation</param-name>
    <param-value>/WEB-INF/spring/applicationContext.xml</param-value>
</context-param>

<servlet>
    <servlet-name>dispatcher</servlet-name>
    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
</servlet>
```

**问题 6：参数解析与数据绑定的重复代码**
- **现象**：每个请求都要手动解析参数、验证、转换类型
- **代码示例（无 Spring 支持）**：
```java
public void updateUser(HttpServletRequest req) throws Exception {
    String name = req.getParameter("name");
    String age = req.getParameter("age");
    String[] tags = req.getParameterValues("tags");

    // 手动验证
    if (name == null || name.isEmpty()) {
        throw new Exception("name required");
    }

    // 手动类型转换
    int ageInt = Integer.parseInt(age);
    if (ageInt < 0 || ageInt > 150) {
        throw new Exception("age invalid");
    }

    // 手动装配对象
    User user = new User();
    user.setName(name);
    user.setAge(ageInt);
    user.setTags(Arrays.asList(tags));
}
```

### Spring-Web 解决方案

| 问题 | Spring-Web 解决方案 |
|------|-------------------|
| Servlet API 底层复杂 | HttpRequestHandler 接口简化，屏蔽 Servlet 细节 |
| 请求上下文多线程访问困难 | RequestContextHolder + ThreadLocal，线程级上下文绑定 |
| CORS 处理繁琐 | CorsProcessor 统一处理，@CrossOrigin 注解支持 |
| 文件上传解析复杂 | MultipartResolver 统一解析，MultipartFile 接口简化使用 |
| web.xml 配置繁琐 | WebApplicationInitializer SPI + Servlet 3.0 自动检测 |
| 参数解析重复代码多 | @RequestParam、@PathVariable 等注解自动解析，WebDataBinder 自动绑定验证 |

---

## 五、经过（How）：核心处理流程

### 流程 1：Servlet 容器启动与 Spring 初始化

```
Servlet 容器启动
    ↓
查找 classpath 中所有 ServletContainerInitializer 实现
    ↓ SpringServletContainerInitializer 被发现
    ↓
调用 SpringServletContainerInitializer.onStartup(Set<Class<?>> classes, ServletContext sc)
    ├─ 扫描 classpath 中所有 WebApplicationInitializer 实现
    ├─ 排序（按 @Order 或 Ordered 接口）
    └─ 逐一调用 initializer.onStartup(sc)
    ↓
用户实现 WebApplicationInitializer.onStartup(ServletContext)
    ├─ 创建 AnnotationConfigWebApplicationContext 或 XmlWebApplicationContext
    ├─ 调用 context.register(Config.class) 或 setConfigLocation()
    ├─ ContextLoader.initWebApplicationContext() 初始化根 context
    └─ 根 context 存储到 sc.setAttribute("org.springframework.web.context.WebApplicationContext.ROOT")
    ↓
注册 DispatcherServlet
    ├─ ServletRegistration.Dynamic servlet = sc.addServlet("dispatcher", new DispatcherServlet(rootContext))
    ├─ servlet.addMapping("/")
    ├─ servlet.setLoadOnStartup(1)
    └─ DispatcherServlet 创建自己的子 ApplicationContext
    ↓
注册 Filter（如 RequestContextFilter、CorsFilter 等）
    ├─ FilterRegistration.Dynamic filter = sc.addFilter("requestContextFilter", new RequestContextFilter())
    ├─ filter.addMappingForUrlPatterns(null, false, "/*")
    └─ filter 初始化
    ↓
启动完成，应用就绪处理请求
```

**关键类与方法**：
- `SpringServletContainerInitializer.onStartup()` ← 自动启动入口
- `WebApplicationInitializer.onStartup()` ← 应用配置入口
- `ContextLoader.initWebApplicationContext()` ← 根 context 初始化

---

### 流程 2：单次 HTTP 请求处理的上下文绑定

```
HTTP 请求到达
    ↓
Servlet 容器创建 ServletRequest/ServletResponse
    ↓
Filter 链开始执行（RequestContextFilter 通常在链头）
    ↓
RequestContextFilter.doFilterInternal(request, response, filterChain)
    ├─ 创建 ServletRequestAttributes attributes = new ServletRequestAttributes(request)
    ├─ 调用 RequestContextHolder.setRequestAttributes(attributes)
    │  └─ attributes 被存入 ThreadLocal<RequestAttributes> requestAttributesHolder
    ├─ 调用 filterChain.doFilter(request, response) 继续链
    └─ finally 块
        └─ RequestContextHolder.resetRequestAttributes()
           └─ requestAttributesHolder.remove() 清理 ThreadLocal
    ↓
后续 Filter 与 DispatcherServlet
    ├─ CorsFilter → 验证 CORS，添加响应头
    ├─ 其他 Filter
    └─ DispatcherServlet
    ↓
业务代码中任何地方都可访问请求上下文
    ├─ RequestContextHolder.getRequestAttributes()
    ├─ 获取 HttpServletRequest
    └─ 获取 HttpServletResponse
    ↓
响应返回，请求完成
    ↓
RequestContextFilter finally 块执行
    └─ RequestContextHolder.resetRequestAttributes()
```

**关键类与方法**：
- `RequestContextFilter.doFilterInternal()` ← 绑定入口
- `RequestContextHolder.setRequestAttributes()` ← ThreadLocal 绑定
- `RequestContextHolder.resetRequestAttributes()` ← ThreadLocal 清理

---

### 流程 3：CORS 预检请求处理

```
浏览器发送 OPTIONS 预检请求
    ↓
请求头包含：
    Origin: https://example.com
    Access-Control-Request-Method: POST
    Access-Control-Request-Headers: Content-Type
    ↓
CorsFilter 或 HandlerMapping 的 CorsProcessor 接收
    ↓
CorsProcessor.processRequest(configuration, request, response)
    ├─ 检查 Origin 是否在 allowedOrigins 列表中
    ├─ 检查请求方法是否在 allowedMethods 中
    ├─ 检查请求头是否在 allowedHeaders 中
    ├─ 验证失败 → 返回 false，请求被拒绝
    └─ 验证成功 → 添加响应头
        ├─ Access-Control-Allow-Origin: https://example.com
        ├─ Access-Control-Allow-Methods: GET, POST, PUT, DELETE
        ├─ Access-Control-Allow-Headers: Content-Type, Authorization
        ├─ Access-Control-Allow-Credentials: true（如果允许）
        ├─ Access-Control-Max-Age: 3600（缓存预检结果时间）
        └─ 返回 200 OK，不再传递给 DispatcherServlet
    ↓
浏览器收到响应，验证通过
    ↓
浏览器发送真实请求（POST/PUT 等）
    ↓
CorsProcessor 再次检查并添加响应头
    ↓
业务逻辑处理请求
```

**关键类与方法**：
- `CorsFilter` ← CORS 处理过滤器
- `DefaultCorsProcessor.processRequest()` ← CORS 处理逻辑
- `CorsConfiguration` ← CORS 配置

---

### 流程 4：文件上传（MultiPart）处理

```
浏览器上传文件，Content-Type: multipart/form-data
    ↓
DispatcherServlet 接收请求
    ↓
检查是否需要解析 MultiPart
    ├─ MultipartResolver.isMultipart(request)
    └─ 检查 content-type 是否为 multipart/form-data
    ↓
是 → 调用 MultipartResolver.resolveMultipart(request)
    ├─ CommonsMultipartResolver（基于 Apache Commons FileUpload）或其他实现
    ├─ 解析 request 中的 multipart 数据
    ├─ 创建 MultipartHttpServletRequest wrapper
    │  └─ 内部维持 Map<String, MultipartFile[]> fileMap
    │  └─ 内部维持 Map<String, String[]> parameterMap
    ├─ 临时文件存储到配置的目录
    └─ 返回 wrapped request
    ↓
DispatcherServlet 继续处理，使用 MultipartHttpServletRequest
    ├─ 可通过 request.getFile("uploadFile") 获取 MultipartFile
    ├─ 可通过 request.getParameter("fieldName") 获取普通表单字段
    ├─ 可通过 request.getFileNames("uploadFiles") 获取多个文件
    └─ HandlerMethodArgumentResolver 自动转换为方法参数
    ↓
业务代码处理文件
    ├─ MultipartFile file = ...
    ├─ InputStream is = file.getInputStream()
    ├─ byte[] bytes = file.getBytes()
    └─ file.transferTo(new File(...))
    ↓
请求完成
    ↓
MultipartResolver 清理
    ├─ 删除临时文件
    └─ cleanupMultipart(request)
```

**关键类与方法**：
- `MultipartResolver.resolveMultipart()` ← 解析入口
- `CommonsMultipartResolver` ← Commons FileUpload 实现
- `MultipartFile` ← 上传文件访问接口

---

### 流程 5：参数解析与数据绑定

```
DispatcherServlet 找到对应的 Controller 方法
    ↓
方法签名示例：@PostMapping("/users")
    public void createUser(@RequestParam String name,
                          @RequestParam int age,
                          @RequestBody User user,
                          HttpServletRequest request) { ... }
    ↓
HandlerMethodArgumentResolver 链开始遍历
    ├─ 对每个方法参数执行 resolver.supportsParameter(methodParameter)
    └─ 找到支持该参数的 resolver
    ↓
参数 1：@RequestParam String name
    ├─ RequestParamMethodArgumentResolver.supportsParameter() → true
    ├─ resolveArgument(parameter, mavContainer, webRequest, binderFactory)
    ├─ 从请求参数中获取 "name" 的值
    ├─ 类型已是 String，无需转换
    └─ 返回 "John"
    ↓
参数 2：@RequestParam int age
    ├─ RequestParamMethodArgumentResolver 处理
    ├─ 从请求参数中获取 "age" 的值 → "30"
    ├─ 需要转换 String → int
    ├─ 创建 WebDataBinder binder = binderFactory.createBinder(webRequest, null, "age")
    ├─ binder.convertIfNecessary("30", int.class)
    │  └─ 委托给 ConversionService 进行类型转换
    └─ 返回 30
    ↓
参数 3：@RequestBody User user
    ├─ RequestResponseBodyMethodProcessor.supportsParameter() → true
    ├─ resolveArgument(parameter, ...)
    ├─ 读取 request body（JSON）
    ├─ 使用 HttpMessageConverter（如 MappingJackson2HttpMessageConverter）反序列化
    │  └─ JSON → User 对象
    ├─ 创建 WebDataBinder binder = binderFactory.createBinder(webRequest, user, "user")
    ├─ binder.bind(bindingResult)
    │  └─ 执行 JSR-303 验证（@Valid、@Validated）
    ├─ 验证失败 → BindingResult 中记录错误
    └─ 返回 User 对象
    ↓
参数 4：HttpServletRequest request
    ├─ ServletRequestMethodArgumentResolver.supportsParameter() → true
    ├─ 直接返回 webRequest.getNativeRequest(HttpServletRequest.class)
    └─ 返回 request 对象
    ↓
所有参数都已解析
    ↓
DispatcherServlet 调用 Controller 方法
    └─ createUser("John", 30, userObject, request)
```

**关键类与方法**：
- `HandlerMethodArgumentResolver` ← 参数解析策略接口
- 多个具体实现：RequestParamMethodArgumentResolver、RequestResponseBodyMethodProcessor 等
- `WebDataBinder` ← 数据绑定与验证
- `ConversionService` ← 类型转换

---

### 流程 6：RequestContextHolder 使用（异步处理示例）

```
同步请求处理
    ↓
RequestContextFilter 将 ServletRequestAttributes 绑定到 ThreadLocal
    ↓
Controller 方法中
    └─ asyncTaskExecutor.execute(() -> {
            // 异步任务在线程池中执行
            RequestAttributes attrs = RequestContextHolder.getRequestAttributes();
            HttpServletRequest request = (HttpServletRequest) attrs.resolveReference(RequestAttributes.REFERENCE_REQUEST);
            String userId = (String) request.getAttribute("userId");
            // 业务逻辑处理
        })
    ↓
异步任务完成
    ↓
主线程返回响应
    ↓
RequestContextFilter 的 finally 块执行
    └─ RequestContextHolder.resetRequestAttributes()
```

**关键用途**：
- 在 Service 层或工具类中无需传递 request 对象
- 支持异步处理时访问请求上下文
- 支持继承 ThreadLocal（InheritableThreadLocal），传递给子线程

---

## 六、结果（Result）：最终状态与架构收益

### 最终状态

#### 应用代码的简化
**使用前**（手写 Servlet）：
```java
public class UserServlet extends HttpServlet {
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            // 手动解析参数
            String name = req.getParameter("name");
            int age = Integer.parseInt(req.getParameter("age"));

            // 手动验证
            if (name == null || name.isEmpty()) {
                throw new Exception("name required");
            }
            if (age < 0) {
                throw new Exception("age must >= 0");
            }

            // 手动处理 CORS
            String origin = req.getHeader("Origin");
            if (allowedOrigins.contains(origin)) {
                resp.setHeader("Access-Control-Allow-Origin", origin);
            }

            // 业务逻辑
            User user = new User(name, age);
            userService.createUser(user);

            // 手动设置响应
            resp.setStatus(200);
            resp.setContentType("application/json;charset=UTF-8");
            resp.getWriter().println("{\"success\":true}");
        } catch (Exception e) {
            resp.setStatus(400);
            resp.getWriter().println("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }
}

<!-- web.xml -->
<servlet>
    <servlet-name>userServlet</servlet-name>
    <servlet-class>com.example.UserServlet</servlet-class>
</servlet>
<servlet-mapping>
    <servlet-name>userServlet</servlet-name>
    <url-pattern>/users</url-pattern>
</servlet-mapping>
```

**使用后**（Spring-Web + Spring-MVC）：
```java
@RestController
@RequestMapping("/users")
@CrossOrigin(allowedOrigins = "https://example.com")
public class UserController {

    @Autowired
    private UserService userService;

    @PostMapping
    public ResponseEntity<?> createUser(
            @RequestParam String name,
            @RequestParam @Min(0) @Max(150) int age) {
        User user = new User(name, age);
        userService.createUser(user);
        return ResponseEntity.ok().body("{\"success\":true}");
    }
}

// 无需 web.xml，Spring-Web 自动初始化
```

#### 框架状态
- **ThreadLocal 状态**：RequestContextHolder 中已绑定 ServletRequestAttributes
- **Servlet 注册状态**：DispatcherServlet、Filter 已全部注册到 ServletContext
- **ApplicationContext 状态**：根 context（Root ApplicationContext）已创建，子 context（Servlet WebApplicationContext）已初始化
- **资源清理状态**：请求完成后，ThreadLocal 已清空，临时文件已删除

### 架构收益

| 收益维度 | 具体表现 |
|---------|---------|
| **API 简化** | 从 ServletRequest/Response 手工操作 → 注解参数注入自动处理 |
| **代码减少** | 消除 80% 的 Servlet 样板代码（参数解析、验证、CORS、上传等） |
| **多框架支持** | HttpRequestHandler 屏蔽 Servlet 细节，支持 Servlet 和 WebFlux 双栈 |
| **线程安全** | ThreadLocal 线程隔离，RequestContextHolder 提供统一访问口径 |
| **配置灵活** | 支持 web.xml（传统）和 WebApplicationInitializer（现代）两种初始化方式 |
| **文件处理** | MultipartResolver 自动管理上传文件的临时存储与清理 |
| **跨域支持** | CorsProcessor 内置 CORS 处理，@CrossOrigin 注解简化配置 |
| **参数绑定** | WebDataBinder 支持类型转换、JSR-303 验证、自定义编辑器 |
| **异步兼容** | 支持 async/await（Servlet 3.0+）、InheritableThreadLocal 子线程继承 |
| **扩展性** | HandlerMethodArgumentResolver、CorsProcessor 等提供 SPI，易于扩展 |

---

## 七、核心设计模式

### 1. 策略模式（Strategy）
**位置**：参数解析和返回值处理
```
HandlerMethodArgumentResolver 接口 ← 策略接口
    ├─ RequestParamMethodArgumentResolver ← 策略 1
    ├─ RequestResponseBodyMethodProcessor ← 策略 2
    ├─ PathVariableMethodArgumentResolver ← 策略 3
    └─ 多个其他解析器 ← 其他策略
```

### 2. 责任链模式（Chain of Responsibility）
**位置**：Filter 链与 ArgumentResolver 链
```
RequestContextFilter → CorsFilter → OtherFilter → DispatcherServlet
    ↑ 链式处理，每个 Filter 可决定是否继续传递

HandlerMethodArgumentResolver Chain
    ↑ 遍历所有 resolver，找到支持该参数的第一个
```

### 3. 装饰器模式（Decorator）
**位置**：MultipartHttpServletRequest
```
MultipartHttpServletRequest wraps HttpServletRequest
    ├─ 增加 getFile(name) 方法
    ├─ 增加 getFileNames() 方法
    ├─ 增加 getFilePart(name) 方法
    └─ 委托 getParameter() 等方法到内部的原始 request
```

### 4. ThreadLocal 模式（Thread Local Storage）
**位置**：RequestContextHolder
```
ThreadLocal<RequestAttributes> requestAttributesHolder
    ├─ 每个线程一份独立副本
    ├─ 请求开始时 set()
    ├─ 请求中随处可 get()
    └─ 请求结束时 remove()
```

### 5. 模板方法模式（Template Method）
**位置**：OncePerRequestFilter
```
doFilter(request, response, filterChain) {
    if (already filtered) return;

    try {
        doFilterInternal(request, response, filterChain); ← 抽象方法
    } finally {
        mark as filtered;
        remove "already filtered" attribute;
    }
}
```

### 6. 工厂模式（Factory）
**位置**：WebDataBinderFactory、ContentNegotiationManager
```
WebDataBinderFactory 创建 WebDataBinder 实例
ContentNegotiationManager 创建内容协商策略组合
```

---

## 八、关键接口与类详解

### HttpRequestHandler（HTTP 请求处理接口）
**最小化接口**，仅一个方法：
```java
void handleRequest(HttpServletRequest request, HttpServletResponse response)
    throws ServletException, IOException;
```
**用途**：实现简单的 HTTP 请求处理，如 RPC 导出、资源服务等

### RequestContextHolder（请求上下文持有者）
**核心方法**：
```java
static RequestAttributes getRequestAttributes(); // 获取当前线程的请求属性
static void setRequestAttributes(RequestAttributes attributes); // 绑定
static void resetRequestAttributes(); // 清理
```

### WebDataBinder（数据绑定器）
**职责**：
- 绑定：将请求参数绑定到对象属性
- 验证：执行 JSR-303 注解验证
- 转换：String → 其他类型的自动转换

### HandlerMethodArgumentResolver（方法参数解析策略）
**核心方法**：
```java
boolean supportsParameter(MethodParameter parameter); // 判断是否支持该参数
Object resolveArgument(MethodParameter parameter, ModelAndViewContainer mavContainer,
                      NativeWebRequest webRequest, WebDataBinderFactory binderFactory)
    throws Exception; // 解析参数
```

### MultipartResolver（文件上传解析器）
**核心方法**：
```java
boolean isMultipart(HttpServletRequest request); // 检查是否为 multipart 请求
MultipartHttpServletRequest resolveMultipart(HttpServletRequest request)
    throws MultipartException; // 解析
void cleanupMultipart(MultipartHttpServletRequest request); // 清理
```

### CorsProcessor（CORS 处理器）
**核心方法**：
```java
boolean processRequest(@Nullable CorsConfiguration configuration,
                       HttpServletRequest request,
                       HttpServletResponse response) throws IOException;
```

---

## 九、文件统计

**spring-web 模块包含 628 个 Java 文件**，主要分布：
- `org.springframework.web`：核心接口（20 个）
- `org.springframework.web.context`：Web 应用上下文（30 个）
- `org.springframework.web.bind`：数据绑定（45 个）
- `org.springframework.web.filter`：过滤器（25 个）
- `org.springframework.web.method`：方法处理（70 个）
- `org.springframework.web.cors`：跨域处理（15 个）
- `org.springframework.web.multipart`：文件上传（35 个）
- `org.springframework.web.client`：HTTP 客户端（60 个）
- `org.springframework.web.util`：工具类（50 个）
- 其他包（283 个）

---

## 十、与其他模块的关系

### 依赖关系
```
spring-web
├─ spring-core（Assert、ClassUtils、NamedThreadLocal）
├─ spring-beans（PropertyEditor、ConversionService）
├─ spring-context（ApplicationContext、Environment）
├─ spring-aop（AOP 基础设施）
└─ commons-io、commons-fileupload（文件上传支持）
```

### 被依赖关系
```
依赖于 spring-web 的模块
├─ spring-webmvc（Servlet MVC 框架）
├─ spring-webflux（响应式 Web 框架）
├─ spring-ws（Web Services）
├─ spring-restdocs（REST 文档）
└─ 所有 Web 应用都直接依赖
```

---

## 总结

**spring-web 模块的核心价值**：

1. **屏蔽 Servlet API 复杂性**：提供简化的 HttpRequestHandler 接口，隐藏 Servlet 细节

2. **线程级上下文管理**：RequestContextHolder + ThreadLocal 解决多线程环境下的请求访问

3. **参数解析自动化**：HandlerMethodArgumentResolver 链 + WebDataBinder 自动处理参数绑定、类型转换、验证

4. **CORS 内置支持**：CorsProcessor 与 CorsConfiguration 简化跨域处理

5. **文件上传透明化**：MultipartResolver 与 MultipartFile 统一 multipart 处理

6. **Servlet 3.0+ 编程式初始化**：WebApplicationInitializer 消除 web.xml 繁琐性

7. **多框架兼容**：通过统一的 HTTP 请求处理抽象，同时支持 Servlet MVC 与 WebFlux 响应式框架

8. **可扩展的 SPI**：HandlerMethodArgumentResolver、CorsProcessor 等提供扩展点

这是 Spring Web 生态的**基础枢纽**，Spring MVC 和 Spring WebFlux 都构建在其之上。
