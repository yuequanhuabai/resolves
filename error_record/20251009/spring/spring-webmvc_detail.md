# Spring-WebMVC 模块深度分析文档

## 模块概述

spring-webmvc 是 Spring Framework 的传统同步 Web MVC 框架，基于 Servlet API 提供分层的、模型-视图-控制器架构。它是 Java Web 开发中**最成熟、最广泛使用**的企业级框架，已成为事实上的标准。

**核心特性**：
- DispatcherServlet：中央请求分发器
- HandlerMapping：请求到处理器的映射
- HandlerAdapter：多种处理器的适配器
- ModelAndView：模型与视图的统一返回
- ViewResolver：视图逻辑名到具体视图的解析
- 拦截器链：处理前后的横切关注点
- 异常处理：统一的异常处理策略

---

## 一、时间（When）：MVC 请求处理的生命周期

### 初始化阶段（Initialization）
- **时间点**：Servlet 容器启动时
- **操作**：
  - DispatcherServlet 初始化
  - 扫描 HandlerMapping、HandlerAdapter、ViewResolver 等组件
  - 解析 @RequestMapping 注解，构建映射表

### 单次请求处理阶段（Per-Request）
- **阶段 1：前处理（Pre-handling）**
  - 接收请求，经过拦截器 preHandle()
  - HandlerMapping 查询处理器
  - 拦截器决定是否继续

- **阶段 2：业务处理（Handler invocation）**
  - HandlerAdapter 调用处理方法
  - 方法执行，返回 ModelAndView 或数据

- **阶段 3：后处理（Post-handling）**
  - 经过拦截器 postHandle()
  - ViewResolver 解析视图
  - View 渲染模型

- **阶段 4：完成（Completion）**
  - 经过拦截器 afterCompletion()
  - 响应返回客户端

---

## 二、地点（Where）：核心代码模块分布

### 核心分发层
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.servlet` | `DispatcherServlet` | 中央请求分发器，整个 MVC 流程的协调者 |
| `org.springframework.web.servlet` | `FrameworkServlet` | DispatcherServlet 的基类，Servlet 生命周期管理 |
| `org.springframework.web.servlet` | `ModelAndView` | 模型与视图的统一返回值 |
| `org.springframework.web.servlet` | `View` | 视图接口 |

### 处理器映射层
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.servlet.handler` | `HandlerMapping` | 请求到处理器的映射策略 |
| `org.springframework.web.servlet.handler` | `AbstractHandlerMapping` | HandlerMapping 基类 |
| `org.springframework.web.servlet.handler` | `RequestMappingHandlerMapping` | 映射 @RequestMapping 注解 |
| `org.springframework.web.servlet.handler` | `HandlerExecutionChain` | 处理器执行链（含拦截器）|
| `org.springframework.web.servlet.handler` | `HandlerInterceptor` | 拦截器接口 |

### 处理器适配层
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.servlet` | `HandlerAdapter` | 处理器适配器接口 |
| `org.springframework.web.servlet.mvc.method.annotation` | `RequestMappingHandlerAdapter` | 适配 @RequestMapping 处理方法 |
| `org.springframework.web.servlet.mvc` | `SimpleControllerHandlerAdapter` | 适配 Controller 接口 |
| `org.springframework.web.servlet.mvc` | `HttpRequestHandlerAdapter` | 适配 HttpRequestHandler 接口 |

### 视图解析层
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.servlet` | `ViewResolver` | 视图逻辑名到具体视图的解析 |
| `org.springframework.web.servlet.view` | `InternalResourceViewResolver` | JSP 视图解析器 |
| `org.springframework.web.servlet.view` | `AbstractView` | View 基类 |
| `org.springframework.web.servlet.view` | `InternalResourceView` | JSP 视图实现 |

### 参数解析与返回值处理
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.method.support` | `HandlerMethodArgumentResolver` | 方法参数解析策略 |
| `org.springframework.web.method.support` | `HandlerMethodReturnValueHandler` | 返回值处理策略 |
| `org.springframework.web.bind.support` | `WebDataBinder` | 参数绑定与验证 |

### 异常处理层
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.servlet` | `HandlerExceptionResolver` | 异常处理策略接口 |
| `org.springframework.web.servlet.mvc.method.annotation` | `ExceptionHandlerExceptionResolver` | 处理 @ExceptionHandler |
| `org.springframework.web.servlet.mvc.support` | `DefaultHandlerExceptionResolver` | 默认异常处理 |

### 其他关键模块
| 地点 | 主要类 | 职责 |
|------|--------|------|
| `org.springframework.web.servlet.i18n` | `LocaleResolver` | 国际化语言地区解析 |
| `org.springframework.web.servlet.theme` | `ThemeResolver` | 主题解析 |
| `org.springframework.web.servlet.config` | `EnableWebMvc` | 注解启用 WebMVC |
| `org.springframework.web.servlet.resource` | `ResourceHandler` | 静态资源处理 |
| `org.springframework.web.servlet.function` | `RouterFunction` | 函数式路由（MVC 中的函数式支持）|

---

## 三、人物（Who）：参与角色与职责划分

### 系统参与者

**1. Servlet 容器（Servlet Container）**
- 角色：HTTP 请求的入口与响应的出口
- 职责：
  - 接收 HTTP 请求
  - 创建 ServletRequest、ServletResponse
  - 调用 DispatcherServlet 处理
  - 返回响应给客户端

**2. DispatcherServlet（中央分发器）**
- 角色：MVC 流程的中央协调者
- 职责：
  - 接收 HttpServletRequest 和 HttpServletResponse
  - 组织处理流程：映射 → 适配 → 处理 → 视图 → 响应
  - 管理 HandlerMapping、HandlerAdapter、ViewResolver 等策略
  - 异常捕获与转换

**3. HandlerMapping（处理器映射器）**
- 角色：请求到处理器的映射查询
- 职责：
  - 根据请求 URL、Method 等查找匹配的处理器
  - 返回 HandlerExecutionChain（含拦截器）
  - RequestMappingHandlerMapping：处理 @RequestMapping 注解

**4. HandlerInterceptor（拦截器）**
- 角色：请求处理前后的横切处理
- 职责：
  - preHandle()：处理前（可阻止继续处理）
  - postHandle()：处理后（可修改 ModelAndView）
  - afterCompletion()：请求完成后（资源清理）

**5. HandlerAdapter（处理器适配器）**
- 角色：支持多种处理器类型的适配器
- 职责：
  - 判断是否支持给定处理器
  - 解析方法参数（通过 ArgumentResolver）
  - 调用处理器方法
  - 包装返回值为 ModelAndView

**6. HandlerMethod（处理方法）**
- 角色：被 @RequestMapping 修饰的处理方法的包装
- 职责：
  - 持有方法引用、参数信息
  - 被 HandlerAdapter 调用执行
  - 支持参数自动解析

**7. ArgumentResolver（参数解析器）**
- 角色：方法参数的自动解析
- 职责：
  - 识别参数类型（@RequestParam、@RequestBody 等）
  - 从请求中提取参数值
  - 进行类型转换
  - 数据绑定与验证

**8. WebDataBinder（数据绑定器）**
- 角色：请求参数与对象属性的绑定
- 职责：
  - 将请求参数绑定到对象属性
  - 执行 JSR-303 验证
  - 自定义编辑器支持

**9. ViewResolver（视图解析器）**
- 角色：逻辑视图名到具体视图对象的解析
- 职责：
  - 接收视图逻辑名（如 "user/list"）
  - 解析为 View 对象
  - InternalResourceViewResolver：JSP 视图解析

**10. View（视图）**
- 角色：模型的最终渲染
- 职责：
  - render(model, request, response)
  - 使用 model 中的数据渲染 HTML/JSON/XML 等
  - JSP View、Freemarker View、Thymeleaf View 等

**11. HandlerExceptionResolver（异常处理器）**
- 角色：全局异常捕获与处理
- 职责：
  - 捕获处理链中的异常
  - 转换为 ModelAndView 或响应数据
  - ExceptionHandlerExceptionResolver：处理 @ExceptionHandler

---

## 四、起因（Why）：问题背景与设计动机

### 核心问题

**问题 1：传统 Servlet 编程的重复代码多**
- **现象**：每个 Servlet 都要处理请求解析、参数绑定、响应生成等重复工作
- **代码示例（无 Spring 支持）**：
```java
// 传统 Servlet：每个处理器重复相同逻辑
public class UserServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
        try {
            // 1. 解析参数
            String id = req.getParameter("id");
            if (id == null || id.isEmpty()) {
                resp.sendError(400, "id is required");
                return;
            }

            // 2. 类型转换
            int userId = Integer.parseInt(id);

            // 3. 业务逻辑
            User user = userService.findById(userId);
            if (user == null) {
                resp.sendError(404, "user not found");
                return;
            }

            // 4. 响应生成
            resp.setContentType("application/json");
            ObjectMapper mapper = new ObjectMapper();
            resp.getWriter().write(mapper.writeValueAsString(user));
        } catch (Exception e) {
            resp.sendError(500, e.getMessage());
        }
    }
}
// 每个 URL 都需要一个 Servlet，重复代码 80%
```

**问题 2：多个 URL 到处理器的路由困难**
- **现象**：无内置路由机制，需手工配置 URL 模式，难以维护
- **代码示例（无 Spring 支持）**：
```xml
<!-- web.xml 中冗长配置 -->
<servlet>
    <servlet-name>userGet</servlet-name>
    <servlet-class>com.example.UserGetServlet</servlet-class>
</servlet>
<servlet-mapping>
    <servlet-name>userGet</servlet-name>
    <url-pattern>/users</url-pattern>
</servlet-mapping>

<servlet>
    <servlet-name>userGetById</servlet-name>
    <servlet-class>com.example.UserGetByIdServlet</servlet-class>
</servlet>
<servlet-mapping>
    <servlet-name>userGetById</servlet-name>
    <url-pattern>/users/*</url-pattern>
</servlet-mapping>

<!-- 需要写多个 Servlet，配置也多 -->
```

**问题 3：视图与模型的分离困难**
- **现象**：响应生成逻辑混杂在处理器中，难以重用视图
- **代码示例（无 Spring 支持）**：
```java
// 每个处理器都要负责响应格式化
public void handleUser(HttpServletRequest req, HttpServletResponse resp) {
    User user = userService.findById(userId);

    // HTML 格式
    if (req.getHeader("Accept").contains("text/html")) {
        resp.setContentType("text/html");
        resp.getWriter().println("<html><body>");
        resp.getWriter().println("<h1>" + user.getName() + "</h1>");
        resp.getWriter().println("</body></html>");
    }
    // JSON 格式
    else if (req.getHeader("Accept").contains("application/json")) {
        resp.setContentType("application/json");
        resp.getWriter().println(new ObjectMapper().writeValueAsString(user));
    }
}
// 混杂在一起，难以测试和维护
```

**问题 4：异常处理分散**
- **现象**：每个处理器都要处理异常，容易不一致
- **代码示例（无 Spring 支持）**：
```java
// 每个处理器都重复异常处理
public void handleRequest(HttpServletRequest req, HttpServletResponse resp) {
    try {
        // 业务逻辑
    } catch (IllegalArgumentException e) {
        resp.setStatus(400);
        resp.getWriter().write("{\"error\":\"" + e.getMessage() + "\"}");
    } catch (ResourceNotFoundException e) {
        resp.setStatus(404);
        resp.getWriter().write("{\"error\":\"not found\"}");
    } catch (Exception e) {
        resp.setStatus(500);
        resp.getWriter().write("{\"error\":\"internal error\"}");
    }
}
// 异常处理逻辑重复
```

**问题 5：参数绑定与验证复杂**
- **现象**：参数提取、类型转换、验证都需手工处理
- **代码示例（无 Spring 支持）**：
```java
public void createUser(HttpServletRequest req, HttpServletResponse resp) {
    try {
        // 1. 解析 JSON 请求体
        BufferedReader reader = req.getReader();
        StringBuilder sb = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            sb.append(line);
        }
        String json = sb.toString();

        // 2. 反序列化
        ObjectMapper mapper = new ObjectMapper();
        Map<String, Object> data = mapper.readValue(json, Map.class);

        // 3. 提取字段
        String name = (String) data.get("name");
        Integer age = ((Number) data.get("age")).intValue();
        List<String> tags = (List<String>) data.get("tags");

        // 4. 验证
        if (name == null || name.isEmpty()) {
            throw new Exception("name is required");
        }
        if (age == null || age < 0 || age > 150) {
            throw new Exception("age must be between 0 and 150");
        }

        // 5. 业务逻辑
        User user = new User(name, age, tags);
        userService.save(user);
        // ...
    } catch (Exception e) {
        // 异常处理
    }
}
```

### Spring-WebMVC 解决方案

| 问题 | 解决方案 |
|------|---------|
| 重复代码多 | DispatcherServlet + HandlerAdapter：一个 Servlet 处理所有请求，降低重复代码 |
| 路由困难 | HandlerMapping + @RequestMapping：灵活的路由映射与内置支持 |
| 视图分离困难 | ModelAndView + ViewResolver：模型与视图的清晰分离 |
| 异常处理分散 | HandlerExceptionResolver + @ExceptionHandler：全局异常处理 |
| 参数绑定复杂 | ArgumentResolver + WebDataBinder + 注解：自动参数解析与绑定 |

---

## 五、经过（How）：核心处理流程

### 流程 1：应用启动与处理器扫描

```
Servlet 容器启动
    ↓
加载 web.xml，启动 ContextLoaderListener
    ↓
ContextLoaderListener 初始化根 ApplicationContext
    ↓
DispatcherServlet 初始化（init() 方法）
    ├─ FrameworkServlet.initServletBean()
    ├─ 创建 WebApplicationContext（子容器）
    └─ DispatcherServlet.onRefresh()
    ↓
onRefresh() 初始化 9 个策略组件
    ├─ initHandlerMappings()
    │  └─ 扫描 HandlerMapping Bean
    │  └─ RequestMappingHandlerMapping 扫描 @RequestMapping 注解
    │  └─ 构建 URL → HandlerMethod 的映射表
    ├─ initHandlerAdapters()
    │  └─ RequestMappingHandlerAdapter（适配 @RequestMapping 方法）
    │  └─ SimpleControllerHandlerAdapter（适配 Controller 接口）
    │  └─ HttpRequestHandlerAdapter（适配 HttpRequestHandler）
    ├─ initViewResolvers()
    │  └─ InternalResourceViewResolver（JSP）
    │  └─ 其他自定义 ViewResolver
    ├─ initHandlerExceptionResolvers()
    │  └─ ExceptionHandlerExceptionResolver
    │  └─ ResponseStatusExceptionResolver
    │  └─ DefaultHandlerExceptionResolver
    └─ 其他（LocaleResolver、ThemeResolver 等）
    ↓
扫描 @RestController、@Controller
    ├─ RequestMappingHandlerMapping 扫描 @RequestMapping 方法
    ├─ 为每个方法创建 RequestMappingInfo
    ├─ 构建 URL 模式 → HandlerMethod 的映射
    └─ 存储在 RequestMappingHandlerMapping 中
    ↓
启动完成，应用就绪处理请求
```

**关键类与方法**：
- `DispatcherServlet.init()` ← Servlet 初始化
- `DispatcherServlet.onRefresh()` ← 策略初始化
- `RequestMappingHandlerMapping.afterPropertiesSet()` ← 扫描 @RequestMapping

---

### 流程 2：单次请求的完整处理链

```
HTTP 请求到达
    ↓
Servlet 容器调用 DispatcherServlet.service(request, response)
    ↓
DispatcherServlet.doDispatch(request, response)
    ├─ 获取处理器执行链
    ├─ 执行拦截器 preHandle()
    ├─ 调用处理器
    ├─ 执行拦截器 postHandle()
    ├─ 处理视图
    └─ 执行拦截器 afterCompletion()
    ↓
步骤 1：获取处理器执行链（HandlerExecutionChain）
    └─ DispatcherServlet.getHandler(request)
        ├─ 遍历所有 HandlerMapping
        └─ 调用 mapping.getHandler(request)
            ├─ RequestMappingHandlerMapping 查询 URL 映射表
            ├─ 匹配请求 URL、Method
            ├─ 返回 HandlerMethod
            └─ 包装为 HandlerExecutionChain（含拦截器）
    ↓
步骤 2：执行拦截器 preHandle()
    └─ 遍历 HandlerExecutionChain 中的拦截器
        ├─ 依次调用 interceptor.preHandle(request, response, handler)
        ├─ 返回 false：中断处理链，直接响应
        └─ 返回 true：继续处理
    ↓
步骤 3：调用处理器（HandlerAdapter）
    └─ DispatcherServlet.getHandlerAdapter(handler)
        ├─ 查找支持该处理器的适配器
        ├─ RequestMappingHandlerAdapter（处理 @RequestMapping 方法）
        └─ 调用 adapter.handle(request, response, handler)
    ↓
RequestMappingHandlerAdapter.handle()
    ├─ 创建 InvocableHandlerMethod 包装处理方法
    ├─ 遍历所有 HandlerMethodArgumentResolver
    │  ├─ 识别参数类型（@RequestParam、@RequestBody 等）
    │  ├─ 从请求中提取参数值
    │  ├─ WebDataBinder 进行数据绑定与验证
    │  └─ 构建参数数组
    ├─ method.invoke(target, args...)
    │  └─ 调用处理方法，执行业务逻辑
    ├─ 捕获异常
    │  └─ 转换为 HandlerExceptionResolver 处理
    ├─ 返回值处理
    │  ├─ 如果是 ModelAndView：直接返回
    │  ├─ 如果是其他类型：通过 HandlerMethodReturnValueHandler 转换
    │  └─ 最终返回 ModelAndView
    └─ 返回 ModelAndView
    ↓
步骤 4：执行拦截器 postHandle()
    └─ 遍历拦截器，反向调用 postHandle()
        ├─ 可以修改 ModelAndView
        └─ 处理异常等
    ↓
步骤 5：处理视图（ViewResolver 与 View Rendering）
    ├─ 如果处理器返回了 ModelAndView
    │  ├─ 如果包含视图逻辑名（String）
    │  │  ├─ 遍历 ViewResolver 列表
    │  │  ├─ resolver.resolveViewName(viewName, locale)
    │  │  │  └─ InternalResourceViewResolver 将 "user/list" 解析为 "/ WEB-INF/views/user/list.jsp"
    │  │  └─ 返回 View 对象
    │  └─ 调用 view.render(modelMap, request, response)
    │      ├─ 如果是 JSP View
    │      │  └─ RequestDispatcher.forward() 转发到 JSP
    │      │  └─ JSP 引擎使用 model 数据渲染 HTML
    │      └─ 如果是其他 View（JSON View 等）
    │          └─ 序列化 model 为相应格式写入响应
    └─ 如果处理器返回了 ResponseEntity（RestController）
        ├─ HttpEntityMethodProcessor 处理
        └─ 序列化为 JSON/XML 等写入响应
    ↓
步骤 6：执行拦截器 afterCompletion()
    └─ 遍历拦截器，反向调用 afterCompletion()
        ├─ 资源清理
        ├─ 日志记录
        └─ 会话管理等
    ↓
响应完成，返回给客户端
```

**关键方法**：
- `DispatcherServlet.doDispatch()` ← 流程总协调
- `DispatcherServlet.getHandler()` ← 获取处理器
- `HandlerAdapter.handle()` ← 调用处理器
- `ViewResolver.resolveViewName()` ← 解析视图
- `View.render()` ← 渲染视图

---

### 流程 3：参数解析与数据绑定

```
处理方法签名
    @PostMapping("/users")
    public User createUser(
        @RequestParam String name,
        @RequestBody User user,
        HttpServletRequest request
    ) { ... }
    ↓
RequestMappingHandlerAdapter 开始参数解析
    ↓
参数 1：@RequestParam String name
    ├─ RequestParamMethodArgumentResolver.supportsParameter() → true
    ├─ resolveArgument(parameter, mavContainer, webRequest, binderFactory)
    ├─ 从请求参数中获取 "name"
    ├─ WebDataBinder 进行类型转换（String → String，无转换）
    └─ 返回 "John"
    ↓
参数 2：@RequestBody User user
    ├─ RequestResponseBodyMethodProcessor.supportsParameter() → true
    ├─ resolveArgument()
    ├─ 读取 request body（JSON 格式）
    ├─ 查找合适的 HttpMessageConverter（MappingJackson2HttpMessageConverter）
    ├─ converter.read(User.class, inputMessage)
    │  └─ JSON → User 对象反序列化
    ├─ WebDataBinder binder = binderFactory.createBinder(webRequest, user, "user")
    ├─ binder.bind(bindingResult)
    │  ├─ 绑定属性到 User 对象
    │  └─ 执行 @Valid/@Validated 验证（JSR-303）
    ├─ 如果验证失败
    │  └─ BindingResult 中记录错误
    └─ 返回 User 对象（可能包含验证错误）
    ↓
参数 3：HttpServletRequest request
    ├─ ServletRequestMethodArgumentResolver.supportsParameter() → true
    └─ 直接返回 request 对象
    ↓
所有参数都已解析
    ↓
调用处理方法
    └─ createUser("John", userObject, request)
```

**关键类与方法**：
- `HandlerMethodArgumentResolver` ← 参数解析策略
- `WebDataBinder` ← 数据绑定
- `HttpMessageConverter` ← HTTP 消息转换（JSON、XML 等）
- `Validator` ← JSR-303 验证

---

### 流程 4：异常处理

```
请求处理的任何阶段发生异常
    ├─ 参数解析异常
    ├─ 数据绑定验证异常
    ├─ 业务逻辑异常
    └─ 视图渲染异常
    ↓
DispatcherServlet.doDispatch() 中的 try-catch
    ├─ 捕获异常
    └─ 调用 processDispatchResult(request, response, mappedHandler, Exception)
    ↓
处理异常（HandlerExceptionResolver 链）
    ├─ 遍历所有 HandlerExceptionResolver
    ├─ 第一个能处理该异常的 resolver 处理
    └─ 返回 ModelAndView（包含错误信息）
    ↓
异常解析器 1：ExceptionHandlerExceptionResolver
    ├─ 如果在 @RestController 中定义了 @ExceptionHandler(CustomException.class)
    ├─ 调用该异常处理方法
    ├─ 返回 ResponseEntity 或其他响应
    └─ 转换为 ModelAndView
    ↓
异常解析器 2：ResponseStatusExceptionResolver
    ├─ 如果异常被 @ResponseStatus 修饰
    ├─ 提取 HTTP 状态码
    └─ 返回 ModelAndView（含状态码）
    ↓
异常解析器 3：DefaultHandlerExceptionResolver
    ├─ 处理 Spring 内置异常
    │  ├─ HttpRequestMethodNotSupportedException → 405 Method Not Allowed
    │  ├─ HttpMediaTypeNotAcceptableException → 406 Not Acceptable
    │  └─ 其他异常...
    └─ 返回 ModelAndView
    ↓
异常信息转为响应
    ├─ 如果是 RestController
    │  ├─ 响应 JSON 格式错误信息
    │  └─ 如 {"error":"validation failed","message":"..."}
    └─ 如果是普通 Controller
        ├─ 解析错误视图
        └─ 返回错误页面
    ↓
响应完成
```

**关键类与方法**：
- `HandlerExceptionResolver` ← 异常解析策略
- `ExceptionHandlerExceptionResolver` ← @ExceptionHandler 处理
- `@ExceptionHandler` ← 异常处理注解
- `@ResponseStatus` ← HTTP 状态码注解

---

## 六、结果（Result）：最终状态与架构收益

### 最终状态

#### 代码对比

**无 Spring 支持**（传统 Servlet）：
```java
// 需要为每个 URL 创建一个 Servlet
public class UserListServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
        try {
            List<User> users = userService.listAll();
            resp.setContentType("application/json");
            resp.getWriter().write(new ObjectMapper().writeValueAsString(users));
        } catch (Exception e) {
            resp.sendError(500, e.getMessage());
        }
    }
}

public class UserGetServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
        try {
            String id = req.getParameter("id");
            if (id == null) {
                resp.sendError(400, "id required");
                return;
            }
            User user = userService.findById(Integer.parseInt(id));
            if (user == null) {
                resp.sendError(404, "not found");
                return;
            }
            resp.setContentType("application/json");
            resp.getWriter().write(new ObjectMapper().writeValueAsString(user));
        } catch (Exception e) {
            resp.sendError(500, e.getMessage());
        }
    }
}

// 还要在 web.xml 中配置这两个 Servlet，冗长且重复
```

**使用 Spring WebMVC**：
```java
@RestController
@RequestMapping("/users")
public class UserController {

    @Autowired
    private UserService userService;

    @GetMapping
    public List<User> list() {
        return userService.listAll();
    }

    @GetMapping("/{id}")
    public User get(@PathVariable int id) {
        return userService.findById(id);
    }

    @PostMapping
    public User create(@RequestBody User user) {
        return userService.save(user);
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<String> handleNotFound(ResourceNotFoundException e) {
        return ResponseEntity.notFound().build();
    }
}
// 一个 Controller 处理多个 URL，代码清晰，无配置
```

#### 框架状态

- **URL 映射表**：RequestMappingHandlerMapping 中已构建 URL → HandlerMethod 的完整映射
- **视图缓存**：ViewResolver 可能缓存已解析的视图对象
- **拦截器链**：为每个处理器预先构建好的拦截器链
- **HandlerAdapter 池**：所有支持的适配器已初始化

### 架构收益

| 收益维度 | 具体表现 |
|---------|---------|
| **代码减少** | 减少 70-80% 的样板代码 |
| **可维护性** | 一个 Controller 对应一类资源，逻辑清晰 |
| **代码复用** | 视图、拦截器、异常处理等可复用 |
| **参数绑定** | @RequestParam、@RequestBody 等注解自动处理 |
| **视图分离** | ModelAndView 清晰分离模型与视图逻辑 |
| **异常统一** | @ExceptionHandler 统一异常处理，无需重复 try-catch |
| **国际化支持** | LocaleResolver 内置国际化支持 |
| **主题支持** | ThemeResolver 内置主题管理 |
| **灵活路由** | 支持路径变量、正则表达式、内容协商等 |
| **扩展性** | 可自定义 HandlerMapping、ViewResolver、Interceptor 等 |

---

## 七、核心设计模式

### 1. 策略模式（Strategy）
```
HandlerMapping 策略：RequestMappingHandlerMapping、BeanNameUrlHandlerMapping
HandlerAdapter 策略：RequestMappingHandlerAdapter、SimpleControllerHandlerAdapter
ViewResolver 策略：InternalResourceViewResolver、RedirectViewResolver
HandlerExceptionResolver 策略：ExceptionHandlerExceptionResolver、DefaultHandlerExceptionResolver
```

### 2. 责任链模式（Chain of Responsibility）
```
HandlerInterceptor 链：preHandle → Handle → postHandle → afterCompletion
    ↑ 依次执行，每个拦截器可中断链

HandlerExceptionResolver 链：
    ↑ 遍历所有异常解析器，第一个能处理的接手
```

### 3. 模板方法模式（Template Method）
```
DispatcherServlet.doDispatch() 是整个 MVC 流程的模板
    ├─ 获取处理器
    ├─ 执行前置拦截器
    ├─ 调用处理器
    ├─ 执行后置拦截器
    └─ 处理视图

每个步骤的具体实现由子类或策略提供
```

### 4. 适配器模式（Adapter）
```
HandlerAdapter 适配多种处理器类型
    ├─ @RequestMapping 方法
    ├─ Controller 接口
    ├─ HttpRequestHandler 接口
    └─ 其他自定义处理器

统一的 handle() 接口，屏蔽具体实现差异
```

### 5. 工厂模式（Factory）
```
ViewResolver 作为工厂，创建 View 对象
    ├─ InternalResourceViewResolver → JSP View
    ├─ FreemarkerViewResolver → Freemarker View
    └─ 其他 ViewResolver

通过工厂创建，支持动态切换视图实现
```

---

## 八、关键接口与类详解

### DispatcherServlet
**700+ 行**，MVC 流程的中央协调者：
```java
protected void doDispatch(HttpServletRequest request, HttpServletResponse response)
    ← 单次请求处理的完整流程

protected HandlerExecutionChain getHandler(HttpServletRequest request)
    ← 获取处理器与拦截器链

protected ModelAndView invokeHandlerMethod(HttpServletRequest request, ...)
    ← 调用处理方法，返回 ModelAndView
```

### HandlerMapping
**请求到处理器的映射**：
```java
HandlerExecutionChain getHandler(HttpServletRequest request)
    ← 根据请求查找处理器，返回含拦截器的执行链
```

### HandlerAdapter
**处理器的统一调用接口**：
```java
boolean supports(Object handler);
    ← 判断是否支持该处理器

ModelAndView handle(HttpServletRequest request, HttpServletResponse response, Object handler)
    ← 调用处理器，返回 ModelAndView
```

### ModelAndView
**模型与视图的统一返回值**：
```java
String getViewName();  // 视图逻辑名（如 "user/list"）
View getView();        // 视图对象（如 JSP View、JSON View）
ModelMap getModelMap(); // 模型数据（Map）
```

### ViewResolver
**视图逻辑名到视图对象的解析**：
```java
View resolveViewName(String viewName, Locale locale)
    ← 根据逻辑名解析为 View 对象
```

### View
**视图的渲染接口**：
```java
void render(Map<String, ?> model, HttpServletRequest request, HttpServletResponse response)
    ← 使用 model 数据渲染响应
```

### HandlerInterceptor
**请求处理的拦截器接口**：
```java
boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
    ← 处理前，返回 false 中断链

void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, ModelAndView mav)
    ← 处理后，可修改 ModelAndView

void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex)
    ← 完成后，进行清理
```

---

## 九、文件统计

**spring-webmvc 模块包含 358 个 Java 文件**，主要分布：
- `org.springframework.web.servlet`：核心分发（50 个）
- `org.springframework.web.servlet.mvc`：处理器与适配（80 个）
- `org.springframework.web.servlet.handler`：映射与拦截（40 个）
- `org.springframework.web.servlet.view`：视图解析（50 个）
- `org.springframework.web.servlet.support`：支持类（30 个）
- `org.springframework.web.servlet.config`：配置（20 个）
- 其他（88 个）

---

## 十、与其他模块的关系

### 依赖关系
```
spring-webmvc
├─ spring-web（基础 Web 工具）
├─ spring-core（核心工具）
├─ spring-context（IoC 容器）
├─ spring-aop（AOP 支持）
├─ spring-tx（事务支持）
└─ spring-beans（Bean 管理）
```

### 被依赖关系
```
依赖 spring-webmvc 的模块
├─ spring-webmvc-test（MVC 测试支持）
├─ spring-data-rest（REST 数据服务）
├─ spring-boot-web（Spring Boot Web 自动配置）
└─ 几乎所有传统 Java Web 应用都依赖
```

---

## 总结

**spring-webmvc 的核心价值**：

1. **减少样板代码**：DispatcherServlet + 注解处理，消除 70-80% 重复代码

2. **清晰的 MVC 架构**：
   - Model：@Controller 返回的 ModelAndView
   - View：View 接口与 ViewResolver
   - Controller：@RequestMapping 处理方法

3. **灵活的路由**：@RequestMapping 支持路径变量、正则表达式、内容协商

4. **参数自动解析**：@RequestParam、@RequestBody 等注解 + ArgumentResolver

5. **统一的异常处理**：@ExceptionHandler + HandlerExceptionResolver

6. **拦截器机制**：HandlerInterceptor 支持横切关注点（日志、权限、事务等）

7. **视图解析器**：支持 JSP、Freemarker、Thymeleaf 等多种视图技术

8. **内置国际化与主题支持**：LocaleResolver、ThemeResolver

9. **成熟稳定**：20+ 年积累，被广泛使用，最成熟的 Java Web 框架

10. **与 Spring 深度集成**：IoC、AOP、事务等 Spring 功能无缝整合

这是 Java Web 开发**最成熟、最广泛使用**的框架，虽然新项目可能选择 Spring Boot + WebFlux，但企业中的大多数 Web 应用仍运行在 Spring WebMVC 上。
