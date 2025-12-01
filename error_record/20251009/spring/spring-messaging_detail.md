# Spring-Messaging 模块详细分析

## 模块概述

`spring-messaging`是Spring Framework的通用消息传递基础设施模块，为上层应用（WebSocket、STOMP、RSocket、JMS等）提供统一的消息、消息通道、消息处理等抽象。采用**记叙文6要素**方式记录其核心设计和执行机制。

---

## 一、时间（When）

- **起源时间**：Spring 4.0版本引入（2013年）
- **主要演进**：4.1添加注解支持，5.0添加RSocket支持，5.1优化reactive支持
- **当前版本**：Spring 5.2.3.RELEASE及以后
- **执行时间**：应用启动时初始化，消息到达时实时处理

---

## 二、地点（Where）

### 代码位置
```
spring-messaging/
├── src/main/java/org/springframework/messaging/
│   ├── Message.java                      # 消息接口
│   ├── MessageChannel.java               # 消息通道接口
│   ├── MessageHeaders.java               # 消息头
│   ├── PollableChannel.java              # 可轮询通道
│   ├── core/                             # 核心模板和操作
│   │   ├── GenericMessagingTemplate.java # 通用消息模板
│   │   ├── AbstractMessagingTemplate.java
│   │   ├── MessageSendingOperations.java
│   │   ├── MessageReceivingOperations.java
│   │   ├── DestinationResolver.java      # 目标地址解析器
│   │   └── DestinationResolvingMessageSendingOperations.java
│   ├── support/                          # 支持工具
│   │   ├── MessageBuilder.java           # 消息构建器
│   │   ├── GenericMessage.java           # 通用消息实现
│   │   ├── ErrorMessage.java             # 错误消息
│   │   ├── MessageHeaderAccessor.java    # 消息头访问器
│   │   └── GenericMessageHeaderAccessor.java
│   ├── converter/                        # 消息转换
│   │   ├── MessageConverter.java         # 转换器接口
│   │   ├── AbstractMessageConverter.java # 基类
│   │   ├── SimpleMessageConverter.java   # 简单实现
│   │   ├── GenericMessageConverter.java  # 泛型实现
│   │   ├── ByteArrayMessageConverter.java
│   │   ├── StringMessageConverter.java
│   │   ├── MappingJackson2MessageConverter.java # JSON转换
│   │   ├── CompositeMessageConverter.java # 组合转换
│   │   ├── SmartMessageConverter.java    # 智能转换
│   │   ├── ContentTypeResolver.java      # 内容类型解析
│   │   └── MarshallingMessageConverter.java
│   ├── handler/                          # 消息处理
│   │   ├── annotation/                   # 注解处理
│   │   │   ├── MessageMapping.java       # 消息映射注解
│   │   │   ├── Payload.java              # 负载注解
│   │   │   ├── Header.java               # 头注解
│   │   │   ├── Headers.java              # 头组注解
│   │   │   ├── DestinationVariable.java
│   │   │   ├── SendTo.java               # 发送到注解
│   │   │   └── support/                  # 支持类
│   │   │       ├── DefaultMessageHandlerMethodFactory.java
│   │   │       ├── PayloadArgumentResolver.java
│   │   │       ├── HeaderMethodArgumentResolver.java
│   │   │       └── ...
│   │   ├── invocation/                   # 处理器调用
│   │   │   ├── HandlerMethodArgumentResolver.java  # 参数解析器
│   │   │   ├── HandlerMethodReturnValueHandler.java # 返回值处理
│   │   │   ├── InvocableHandlerMethod.java # 可调用处理方法
│   │   │   ├── AbstractMethodMessageHandler.java  # 基础消息处理
│   │   │   ├── HandlerMethodArgumentResolverComposite.java
│   │   │   └── HandlerMethodReturnValueHandlerComposite.java
│   │   ├── CompositeMessageCondition.java
│   │   ├── DestinationPatternsMessageCondition.java
│   │   └── HandlerMethod.java
│   ├── simp/                             # STOMP over WebSocket
│   │   ├── SimpMessagingTemplate.java
│   │   ├── SimpMessageType.java
│   │   ├── SimpMessageHeaderAccessor.java
│   │   ├── annotation/                   # STOMP注解
│   │   ├── broker/                       # 消息代理
│   │   ├── stomp/                        # STOMP协议
│   │   ├── user/                         # 用户会话
│   │   └── config/                       # 配置
│   ├── rsocket/                          # RSocket支持
│   │   ├── RSocketRequester.java
│   │   ├── annotation/                   # RSocket注解
│   │   └── annotation/support/           # 支持类
│   └── tcp/                              # TCP通信
│       └── reactor/                      # Reactor TCP实现
```

### 运行时位置
- 应用启动时Spring容器初始化消息通道和转换器
- 消息发送时通过MessageChannel传输
- 消息接收时通过处理器的HandlerMethod调用

---

## 三、人物（Who）

### 主要角色及职责

| 角色 | 具体类 | 职责 |
|------|--------|------|
| **消息** | Message<T> | 定义消息结构（payload + headers） |
| **通道** | MessageChannel | 消息传输通道，send操作 |
| **可轮询通道** | PollableChannel | 支持主动receive操作 |
| **模板** | GenericMessagingTemplate | send/receive/sendAndReceive操作 |
| **地址解析** | DestinationResolver | 将destination name解析为通道 |
| **转换器** | MessageConverter | Object ↔ Message转换 |
| **处理器** | AbstractMethodMessageHandler | 消息路由和处理 |
| **参数解析** | HandlerMethodArgumentResolver | 方法参数从Message中提取 |
| **返回处理** | HandlerMethodReturnValueHandler | 方法返回值转为Message |
| **消息构建** | MessageBuilder | 流式构建Message对象 |
| **头访问** | MessageHeaderAccessor | 安全访问和修改消息头 |

---

## 四、起因（Why）

### 问题背景

不同的消息传输协议存在三个核心问题：

1. **API不统一**
   - JMS：ConnectionFactory → Session → Producer/Consumer
   - WebSocket：WebSocketHandler → send()
   - RSocket：RSocketRequester → route()
   - 各自API差异大，学习成本高

2. **消息处理分散**
   - 消息接收后需手动解析payload
   - 参数提取繁琐（遍历headers）
   - 返回值转消息逻辑重复

3. **协议特定性强**
   - 无法统一表达不同协议的消息
   - JMS Message vs WebSocket Message结构不同
   - 难以切换底层实现

4. **转换逻辑重复**
   - Object → JSON → Message（发送）
   - Message → JSON → Object（接收）
   - 每个协议都要重复实现

### 解决策略

Spring采用**四层抽象**：
- **Message**：统一的消息结构（payload + headers）
- **MessageChannel**：统一的传输通道
- **MessageConverter**：统一的对象转换
- **@MessageMapping**：统一的处理器注解

---

## 五、经过（How）

### 5.1 整体流程概览

```
┌─── 消息发送流程 ──────────────────┐
│                                   │
│ 应用调用 send(destination, msg)   │
│  → GenericMessagingTemplate      │
│  → DestinationResolver            │
│  → MessageChannel.send()          │
│  → 到达下游处理器或其他通道      │
│                                   │
└───────────────────────────────────┘

┌─── 消息接收与处理流程 ────────────┐
│                                   │
│ 消息到达 → @MessageMapping        │
│  → AbstractMethodMessageHandler   │
│  → HandlerMethodArgumentResolver  │
│  → InvocableHandlerMethod         │
│  → 参数注入 → 方法调用            │
│  → HandlerMethodReturnValueHandler│
│  → 返回值处理                     │
│  → 发送回复（可选）              │
│                                   │
└───────────────────────────────────┘

┌─── 对象转换流程 ──────────────────┐
│                                   │
│ 应用对象（POJO）                  │
│  ↕ MessageConverter.toMessage()   │
│ 消息（payload + headers）          │
│  ↕ MessageConverter.fromMessage() │
│ 应用对象（POJO）                  │
│                                   │
└───────────────────────────────────┘
```

### 5.2 关键处理步骤

#### A. 消息发送流程（GenericMessagingTemplate.send()）

```
应用代码：template.convertAndSend(destination, payload)
  │
  ├─ 1. 负载转消息
  │  └─ MessageConverter.toMessage(payload, headers)
  │     └─ 根据payload类型选择合适的转换器
  │        ├─ String → StringMessageConverter
  │        ├─ byte[] → ByteArrayMessageConverter
  │        ├─ Object → MappingJackson2MessageConverter (JSON)
  │        └─ ...
  │
  ├─ 2. 目标地址解析
  │  └─ DestinationResolver.resolveDestination(destinationName)
  │     └─ 根据通道名查找或创建MessageChannel
  │        └─ 可缓存以提高性能（CachingDestinationResolverProxy）
  │
  ├─ 3. 设置超时时间
  │  └─ 从消息头提取sendTimeout（如果有）
  │     └─ 或使用默认值（setSendTimeout()）
  │
  ├─ 4. 发送消息
  │  └─ MessageChannel.send(message, timeout)
  │     ├─ 返回true：消息成功发送
  │     ├─ 返回false：超时或被拒绝
  │     └─ 抛异常：不可恢复错误
  │
  └─ 5. 异常处理
     └─ catch(MessageDeliveryException ex)
        └─ 包装并重新抛出
```

#### B. 消息接收与处理（@MessageMapping）

```
消息到达处理器
  │
  ├─ 1. 消息匹配
  │  └─ DestinationPatternsMessageCondition
  │     └─ 根据destination匹配@MessageMapping的patterns
  │        ├─ "/app/hello" 精确匹配
  │        ├─ "/app/**" 通配符匹配
  │        └─ "/app/{name}" 变量匹配
  │
  ├─ 2. 处理器选择
  │  └─ AbstractMethodMessageHandler.handleMessage(message)
  │     └─ 找到匹配的HandlerMethod
  │
  ├─ 3. 方法参数解析
  │  └─ HandlerMethodArgumentResolverComposite
  │     └─ 按顺序尝试各参数解析器
  │        ├─ @Payload → PayloadArgumentResolver
  │        │  ├─ 提取message.getPayload()
  │        │  └─ 通过MessageConverter转换为方法参数类型
  │        │     └─ 可进行JSR-303验证（@Valid）
  │        │
  │        ├─ @Header("key") → HeaderMethodArgumentResolver
  │        │  ├─ 从message.getHeaders().get("key")提取
  │        │  └─ 转换为方法参数类型
  │        │
  │        ├─ @Headers Map<String, Object> → HeadersMethodArgumentResolver
  │        │  └─ 所有消息头作为Map
  │        │
  │        ├─ @DestinationVariable("{name}") → DestinationVariableMethodArgumentResolver
  │        │  ├─ 从destination提取变量值
  │        │  └─ 如 "/app/hello/alice" 提取 name="alice"
  │        │
  │        ├─ MessageHeaders → 直接提取
  │        │
  │        ├─ Message<T> → 直接提取整个消息
  │        │
  │        ├─ Session → 会话对象（WebSocket等）
  │        │
  │        ├─ Principal → 用户身份（如果有认证）
  │        │
  │        └─ ... 其他
  │
  ├─ 4. 方法调用
  │  └─ InvocableHandlerMethod.invokeForRequest(message, ...)
  │     └─ 通过反射调用目标方法
  │        └─ try-catch 用户异常
  │
  ├─ 5. 异常处理
  │  └─ 用户方法抛异常
  │     ├─ MessageExceptionHandler 处理
  │     └─ 可返回错误消息或默认处理
  │
  ├─ 6. 返回值处理
  │  └─ HandlerMethodReturnValueHandlerComposite
  │     └─ 按顺序尝试各返回值处理器
  │        ├─ void → 无返回
  │        ├─ Message<?> → 直接发送
  │        ├─ 其他类型 → 转换为Message
  │        │  └─ MessageConverter.toMessage(result, ...)
  │        └─ Mono/Flux → 异步处理（reactive）
  │
  └─ 7. 目标地址确定
     ├─ @SendTo("destination") → 发送到指定地址
     ├─ JmsReplyTo / ReplyToDestination头 → 发送到头指定地址
     └─ 无指定 → 不发送回复
```

#### C. 消息转换机制（MessageConverter）

```
转换器选择链：

CompositeMessageConverter （组合转换器）
  │
  ├─ 遍历多个转换器
  │  ├─ 调用supportsContentType(contentType)
  │  └─ 第一个返回true的为目标转换器
  │
  └─ 具体转换器
     │
     ├─ StringMessageConverter
     │  └─ String payload ↔ TextMessage
     │
     ├─ ByteArrayMessageConverter
     │  └─ byte[] payload ↔ BytesMessage
     │
     ├─ MappingJackson2MessageConverter（JSON）
     │  ├─ Object payload → Jackson序列化 → JSON文本
     │  ├─ JSON文本 → Jackson反序列化 → Object payload
     │  └─ 依赖Jackson库
     │
     ├─ GenericMessageConverter（通用）
     │  ├─ 支持任何可转换的类型
     │  └─ 需要Type信息支持泛型
     │
     ├─ MarshallingMessageConverter（XML）
     │  ├─ Object ↔ XML（需Marshaller）
     │  └─ 依赖JAXB等
     │
     └─ SmartMessageConverter （智能）
        └─ 内置支持更多类型（Protobuf等）

ContentType协商：
  │
  ├─ 发送方设置 MessageHeaders.CONTENT_TYPE
  │  └─ 例：application/json
  │
  ├─ 转换器根据CONTENT_TYPE选择算法
  │  └─ 例：JSON → 使用MappingJackson2MessageConverter
  │
  └─ 接收方提供targetClass
     └─ 转换器根据CONTENT_TYPE和targetClass反序列化
```

#### D. 注解处理的完整链路

```
Spring启动时：
  │
  ├─ 扫描@MessageMapping标注的方法
  │  └─ 在类或方法级别
  │
  ├─ 为每个方法创建HandlerMethod
  │  ├─ 方法信息
  │  ├─ 参数信息（通过反射）
  │  └─ 返回值信息
  │
  ├─ 为每个参数创建对应的解析器
  │  └─ 根据参数的注解（@Payload等）确定解析器
  │
  ├─ 为返回值创建处理器
  │  └─ 根据返回类型（void、Message、Object等）确定处理器
  │
  ├─ 创建DestinationPatternsMessageCondition
  │  └─ 根据@MessageMapping的patterns
  │
  └─ 注册到AbstractMethodMessageHandler
     └─ 建立消息destination → HandlerMethod的映射表

消息处理时：
  │
  ├─ 消息到达
  │  └─ destination="/app/hello"
  │
  ├─ DestinationPatternsMessageCondition匹配
  │  └─ 找到对应的HandlerMethod
  │
  ├─ 参数解析链
  │  └─ 按顺序调用各参数解析器
  │     └─ 返回解析后的参数数组
  │
  ├─ 方法调用
  │  └─ method.invoke(handler, args)
  │
  └─ 返回值处理
     └─ 按顺序调用各返回值处理器
        └─ 决定如何处理返回值
```

#### E. 消息头处理（MessageHeaders vs MessageHeaderAccessor）

```
MessageHeaders（只读视图）：
  │
  ├─ immutable Map<String, Object>
  │
  ├─ 包含系统头
  │  ├─ ID
  │  ├─ TIMESTAMP
  │  ├─ CONTENT_TYPE
  │  ├─ ERROR_CHANNEL
  │  └─ ...
  │
  └─ 包含自定义头
     └─ 应用定义的任意key-value

MessageHeaderAccessor（读写访问）：
  │
  ├─ 包装MessageHeaders
  │  └─ 提供便利的getter/setter方法
  │
  ├─ 支持类型转换
  │  ├─ setHeader(String, Object)
  │  └─ getHeader(String, Class<T>)
  │
  ├─ 知道特定头的含义
  │  ├─ getContentType() → ContentType对象
  │  ├─ getErrorChannel() → MessageChannel对象
  │  └─ ...
  │
  └─ 可用于修改消息头
     └─ MessageBuilder.setHeaders(accessor)

协议特定的Accessor：
  │
  ├─ SimpMessageHeaderAccessor
  │  ├─ STOMP消息头
  │  ├─ getSimpDestination()
  │  ├─ getSimpSessionId()
  │  └─ ...
  │
  └─ 其他协议的Accessor
     └─ RSocketMessageHeaderAccessor等
```

### 5.3 核心类交互图

```
Message<T> (消息)
  │
  ├─ Payload: T（消息内容）
  ├─ Headers: MessageHeaders（元数据）
  │  └─ MessageHeaderAccessor 访问
  │
  └─ MessageBuilder 构造

MessageChannel (通道)
  │
  ├─ send(Message) → boolean
  │
  ├─ 实现类
  │  ├─ DirectChannel（同步发送）
  │  ├─ QueueChannel（异步队列）
  │  ├─ PublishSubscribeChannel（发布-订阅）
  │  └─ ...
  │
  └─ DestinationResolver
     └─ 将destination name解析为MessageChannel

GenericMessagingTemplate (模板)
  │
  ├─ 操作
  │  ├─ send(channel, message)
  │  ├─ convertAndSend(channel, payload) → 自动转换
  │  ├─ receive(channel) → Message
  │  ├─ receiveAndConvert(channel) → Object
  │  └─ sendAndReceive(channel, message) → Message（请求-应答）
  │
  ├─ 依赖
  │  ├─ DestinationResolver（地址解析）
  │  └─ MessageConverter（对象转换）
  │
  └─ 超时管理
     ├─ setSendTimeout(long)
     └─ setReceiveTimeout(long)

MessageConverter (转换器)
  │
  ├─ fromMessage(Message, targetClass) → Object
  ├─ toMessage(payload, headers) → Message
  │
  ├─ 实现
  │  ├─ StringMessageConverter
  │  ├─ ByteArrayMessageConverter
  │  ├─ MappingJackson2MessageConverter（JSON）
  │  ├─ CompositeMessageConverter（多个）
  │  └─ ...
  │
  └─ ContentType协商
     └─ MessageHeaders.CONTENT_TYPE

@MessageMapping (处理器注解)
  │
  ├─ destination pattern
  │  ├─ @MessageMapping("/app/hello")
  │  └─ @MessageMapping("/app/**")
  │
  ├─ 参数注解
  │  ├─ @Payload → MessageConverter转换
  │  ├─ @Header("key") → 单个头
  │  ├─ @Headers → 所有头（Map）
  │  ├─ @DestinationVariable("{name}") → 目标变量
  │  └─ Message/MessageHeaders/Session等
  │
  ├─ 返回值
  │  ├─ void → 无返回
  │  ├─ Object → @SendTo或头指定回复地址
  │  └─ Message → 直接发送
  │
  └─ AbstractMethodMessageHandler
     ├─ 路由消息到HandlerMethod
     ├─ 调用参数解析器
     ├─ 调用方法
     └─ 处理返回值
```

---

## 六、结果（Result）

### 最终状态转变

```
输入状态：
  ├─ 协议多样化（JMS、WebSocket、RSocket等）
  ├─ API不统一（各自独立接口）
  ├─ 消息处理分散（重复代码多）
  └─ 转换逻辑重复（每个地方都需实现）

处理后状态：
  ├─ 统一的Message接口
  ├─ 统一的MessageChannel抽象
  ├─ 统一的@MessageMapping注解
  ├─ 统一的参数解析机制
  ├─ 统一的消息转换
  └─ 可切换的底层实现（JMS/WebSocket/RSocket）
```

### 6.1 核心成果总结

| 方面 | 成果 | 效果 |
|------|------|------|
| **消息结构** | Message<T> + MessageHeaders | 统一表示任何消息 |
| **传输通道** | MessageChannel | 抽象底层通道实现 |
| **处理注解** | @MessageMapping | 声明式消息处理 |
| **参数提取** | HandlerMethodArgumentResolver | 自动参数绑定 |
| **对象转换** | MessageConverter | 自动对象转换 |
| **地址解析** | DestinationResolver | 通道名到实例映射 |
| **模板API** | GenericMessagingTemplate | 统一的send/receive API |
| **异常处理** | MessageExceptionHandler | 统一的异常处理 |
| **协议适配** | SIMP、RSocket等继承层 | 多协议支持 |

### 6.2 代码对比

#### 无Spring Messaging（冗长）
```java
// JMS方式
ConnectionFactory factory = new ActiveMQConnectionFactory();
Connection conn = factory.createConnection();
Session session = conn.createSession(false, Session.AUTO_ACKNOWLEDGE);
Queue queue = session.createQueue("order.queue");
MessageProducer producer = session.createProducer(queue);

ObjectMessage msg = session.createObjectMessage(order);
producer.send(msg);
session.close();
conn.close();

// WebSocket方式（代码截然不同）
@WebSocketMessageMapping
public void handleMessage(WebSocketSession session, String payload) throws IOException {
    // 参数提取、转换、发送都要手写
    Order order = objectMapper.readValue(payload, Order.class);
    // ...
}
```

#### 使用Spring Messaging（统一）
```java
// 统一的发送API（适用JMS/WebSocket/RSocket）
@Autowired
private GenericMessagingTemplate messagingTemplate;

public void sendOrder(Order order) {
    messagingTemplate.convertAndSend("order.queue", order);
}

// 统一的接收处理（适用所有协议）
@MessageMapping("/order/create")
public OrderResponse handleOrder(@Payload Order order) {
    // 参数自动转换、注入，返回值自动处理
    return orderService.create(order);
}
```

### 6.3 处理链对比

```
Spring Messaging处理链（自动化）：
Message → @MessageMapping匹配
  → @Payload提取 + MessageConverter转换
  → 方法参数注入
  → 方法调用
  → 返回值处理 + Message转换
  → @SendTo目标发送

传统手工方式（繁琐）：
Message → 手工解析destination
  → 手工提取content
  → 手工反序列化（JSON/XML）
  → 手工类型转换
  → 手工方法调用
  → 手工处理异常
  → 手工序列化返回值
  → 手工发送到目标
```

### 6.4 系统在Spring生态中的位置

```
应用代码（MessageMapping / GenericMessagingTemplate）
  │
  ▼
Spring-Messaging (本模块) - 核心基础
  ├─ Message/MessageChannel/MessageConverter 抽象
  ├─ @MessageMapping 注解处理
  ├─ GenericMessagingTemplate 模板
  └─ 参数解析、返回值处理基础设施

  │
  ├─ spring-websocket
  │  └─ WebSocketMessageBrokerConfigurer
  │     └─ STOMP over WebSocket 实现
  │
  ├─ spring-webflux
  │  └─ RSocket 支持
  │     └─ RSocketMessageHandler
  │
  ├─ spring-jms
  │  └─ JMS消息监听器集成
  │     └─ @JmsListener使用MessageMapping基础
  │
  ├─ spring-tx (事务管理)
  │  └─ @Transactional 与消息处理结合
  │
  └─ spring-core (基础)
     └─ 反射、转换、验证等

  │
  ▼
具体传输实现
  ├─ JMS Provider (ActiveMQ等)
  ├─ WebSocket (Java Servlet/Reactive)
  ├─ RSocket (Reactor Netty)
  └─ TCP等
```

### 6.5 分层架构

```
┌─────────────────────────────────────┐
│      应用代码（业务逻辑）          │
│  send/receive/handleMessage         │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│   Spring-Messaging 抽象层           │  统一API
│  Message/MessageChannel             │  统一注解
│  MessageConverter/HandlerMethod      │  统一处理
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│   协议适配层                       │  多种协议
│  STOMP/RSocket/JMS特定实现         │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│   底层传输                         │  JMS提供者等
│  ActiveMQ/RabbitMQ/WebSocket/...  │
└─────────────────────────────────────┘
```

---

## 核心设计模式总结

| 模式 | 应用 | 好处 |
|------|------|------|
| **抽象工厂** | Message/MessageChannel接口 | 隐藏不同协议的具体实现 |
| **模板方法** | GenericMessagingTemplate | 标准化send/receive流程 |
| **策略** | MessageConverter/DestinationResolver | 灵活选择转换和地址解析策略 |
| **组合** | CompositeMessageConverter | 多个转换器协同工作 |
| **适配器** | AbstractMethodMessageHandler | 适配不同的消息处理器 |
| **建造者** | MessageBuilder | 流式构建Message对象 |
| **装饰器** | MessageHeaderAccessor | 为MessageHeaders增加便利方法 |
| **观察者** | MessageExceptionHandler | 事件驱动异常处理 |

---

## 支持的协议与实现

### 协议列表

| 协议 | 模块支持 | 实现方式 | 典型用途 |
|------|---------|---------|---------|
| **STOMP** | spring-websocket | SimpMessageHandler | 实时Web通信 |
| **RSocket** | spring-webflux | RSocketMessageHandler | 低延迟二进制协议 |
| **JMS** | spring-jms | AbstractMethodMessageHandler | 异步消息队列 |
| **WebSocket** | spring-websocket | 直接和STOMP | 实时双向通信 |

### 消息格式支持

```
MessageConverter支持的格式：
  ├─ Text (String)
  ├─ Binary (byte[])
  ├─ JSON (Object via Jackson)
  ├─ XML (Object via Marshaller)
  ├─ Protobuf (Binary Protocol Buffers)
  ├─ 自定义格式 (实现MessageConverter)
  └─ 复合格式 (CompositeMessageConverter)
```

---

## 扩展性与定制

### 易于扩展的组件

1. ✅ **自定义MessageConverter**
   ```java
   public class CustomMessageConverter implements MessageConverter {
       @Override public Object fromMessage(Message<?> message, Class<?> targetClass) { ... }
       @Override public Message<?> toMessage(Object payload, MessageHeaders headers) { ... }
   }
   ```

2. ✅ **自定义DestinationResolver**
   ```java
   public class CustomDestinationResolver implements DestinationResolver {
       @Override public MessageChannel resolveDestination(String name) { ... }
   }
   ```

3. ✅ **自定义HandlerMethodArgumentResolver**
   ```java
   public class CustomArgumentResolver implements HandlerMethodArgumentResolver {
       @Override public boolean supportsParameter(MethodParameter parameter) { ... }
       @Override public Object resolveArgument(MethodParameter parameter, Message<?> message) { ... }
   }
   ```

### 局限

1. ⚠️ 需手动配置转换器（无自动发现）
2. ⚠️ 协议特定头需Accessor支持（泛型MessageHeaders不够）
3. ⚠️ 地址解析性能取决于DestinationResolver实现

---

## 总结

`spring-messaging`是Spring生态的**通用消息基础设施**，通过三个关键抽象（Message、MessageChannel、@MessageMapping）为所有消息驱动的应用（JMS、WebSocket、RSocket等）提供统一的API。

它解决了传统消息应用中API混乱、代码重复、协议耦合的问题，使开发者能够用5行代码实现消息发送和接收，并在不同协议间无缝切换。作为上层应用（spring-jms、spring-websocket等）的基础，spring-messaging是Spring实现跨协议消息统一的关键设计。
