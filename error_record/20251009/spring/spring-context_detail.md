# Spring-Context 模块：六要素详细分析

## 概述
本文档采用记叙文"六要素"（时间、地点、人物、起因、经过、结果）来分析 spring-context 模块的代码运作流程，力求精炼本质、去除冗余细节。

---

## 一级主题：ApplicationContext 生命周期管理

### 1. Bean 容器初始化流程

#### 时间
**编程时**：开发者创建 ApplicationContext（如 `new AnnotationConfigApplicationContext(Config.class)`）

#### 地点
核心类：`AbstractApplicationContext`（1433行）
- 位置：`org.springframework.context.support`
- 入口方法：`refresh()`

#### 人物
**操作主体**：AbstractApplicationContext 容器
**操作目标对象**：
- BeanFactory（DefaultListableBeanFactory）
- BeanDefinition 注册表
- Bean 实例集合
- 事件多播器
- 消息源

#### 起因
应用启动需要初始化 Spring 容器，自动创建和注册所有 Bean，准备运行环境。

#### 经过（12 步核心步骤）
1. **prepareRefresh()** - 标记容器刷新状态，初始化属性源
2. **obtainFreshBeanFactory()** - 创建或刷新 BeanFactory
3. **prepareBeanFactory()** - 配置 BeanFactory（注册系统 Bean、设置类加载器）
4. **postProcessBeanFactory()** - 子类后处理（可覆盖扩展）
5. **invokeBeanFactoryPostProcessors()** - 调用所有 BeanFactoryPostProcessor，**关键：ConfigurationClassPostProcessor 处理 @Configuration 类**
6. **registerBeanPostProcessors()** - 注册所有 BeanPostProcessor（处理 Bean 初始化回调）
7. **initMessageSource()** - 初始化国际化消息源
8. **initApplicationEventMulticaster()** - 初始化事件多播器
9. **onRefresh()** - 子类刷新钩子
10. **registerListeners()** - 注册 ApplicationListener，关联事件多播器
11. **finishBeanFactoryInitialization()** - **实例化非延迟单例 Bean**
12. **finishRefresh()** - 完成刷新，启动 Lifecycle Bean，**发布 ContextRefreshedEvent 事件**

#### 结果
ApplicationContext 完全初始化，所有 Bean 已创建、依赖已注入、所有监听器已注册。容器进入就绪状态，可接收请求和事件。

---

### 2. 配置类处理流程（@Configuration 与 @Bean）

#### 时间
**refresh() 的第 5 步**：invokeBeanFactoryPostProcessors 阶段

#### 地点
关键类：`ConfigurationClassPostProcessor`
- 包：`org.springframework.context.annotation`
- 职责：BeanFactoryPostProcessor + BeanDefinitionRegistryPostProcessor

#### 人物
**操作主体**：ConfigurationClassPostProcessor
**操作目标对象**：
- @Configuration 标注的配置类
- @Bean 标注的工厂方法
- @ComponentScan 扫描指令
- @Import 导入指令
- BeanDefinitionRegistry（注册新的 BeanDefinition）

#### 起因
Spring 容器需要理解基于注解的配置，并将其转化为 BeanDefinition，才能进行 Bean 创建。

#### 经过（5 个处理步骤）
1. **扫描 @Configuration 类** - 查找所有标注 @Configuration 的类
2. **解析配置类** - ConfigurationClassParser 递归解析：
   - 处理 @ComponentScan（触发组件扫描）
   - 处理 @Import（导入其他配置）
   - 处理 @Bean 方法（提取为 BeanMethod）
3. **处理 @ComponentScan** - ClassPathBeanDefinitionScanner 扫描 classpath，查找 @Component 及衍生注解（@Service、@Controller、@Repository）
4. **读取 Bean 定义** - ConfigurationClassBeanDefinitionReader 将 @Bean 方法转化为 BeanDefinition，添加到注册表
5. **CGLIB 增强** - ConfigurationClassEnhancer 使用 CGLIB 代理 @Configuration 类，确保 @Bean 方法间的调用能返回单例 Bean（而非每次创建新实例）

#### 结果
所有配置类中的 @Bean 方法、@ComponentScan 扫描的组件都转化为 BeanDefinition，注册到 BeanFactory。后续 Bean 创建阶段基于这些定义。

---

### 3. Bean 实例化与依赖注入

#### 时间
**refresh() 的第 11 步**：finishBeanFactoryInitialization 阶段

#### 地点
核心类：`DefaultListableBeanFactory`（spring-beans 模块，被 context 依赖）
- 方法：getBean() → createBean()

#### 人物
**操作主体**：BeanFactory（DefaultListableBeanFactory）
**操作目标对象**：
- BeanDefinition（Bean 的元数据）
- Bean 实例
- 依赖对象（其他 Bean）
- 构造器、Setter 方法、字段

#### 起因
容器需要根据 BeanDefinition 创建实际可用的 Bean 对象，并将所有依赖注入。

#### 经过（6 个处理步骤）
1. **获取 BeanDefinition** - 根据 Bean 名称查找其定义信息
2. **解析依赖** - 分析构造器或 Setter 参数，确定所需的其他 Bean
3. **递归获取依赖 Bean** - 对每个依赖调用 getBean()，确保依赖先被创建
4. **选择实例化策略** - 使用构造器（Constructor）、工厂方法（FactoryMethod）或工厂 Bean（FactoryBean）创建实例
5. **执行依赖注入** - 通过构造器参数、Setter 方法、字段注入将依赖设置到 Bean
6. **执行初始化回调** - 调用 @PostConstruct、init-method、InitializingBean.afterPropertiesSet()

#### 结果
所有 Bean 实例已创建，依赖关系完整，初始化逻辑已执行。Bean 进入就绪状态。

---

### 4. ApplicationListener 事件监听机制

#### 时间
**refresh() 的第 10 步**：registerListeners 阶段（以及运行时事件发布时刻）

#### 地点
核心类：
- `SimpleApplicationEventMulticaster`（事件多播器）
- `ApplicationListenerMethodAdapter`（适配 @EventListener 方法）
- 包：`org.springframework.context.event`

#### 人物
**操作主体**：SimpleApplicationEventMulticaster（事件分发器）
**操作目标对象**：
- 实现 ApplicationListener 接口的 Bean
- 标注 @EventListener 的方法
- ApplicationEvent 事件对象

#### 起因
Spring 需要支持发布-订阅模式，允许应用在特定事件发生时执行自定义逻辑（如 Bean 创建完成、容器启动/关闭）。

#### 经过（4 个处理步骤）
1. **扫描监听器** - ApplicationListenerDetector（BeanPostProcessor）检测所有 ApplicationListener 实现或 @EventListener 方法
2. **转换为统一形式** - 将 @EventListener 方法适配为 GenericApplicationListener（支持泛型和条件过滤）
3. **注册到多播器** - 所有监听器注册到 SimpleApplicationEventMulticaster
4. **事件发布时分发** - publishEvent(event) 被调用时，多播器遍历所有监听器，**按优先级和条件过滤**，逐一执行（同步或异步）

#### 结果
事件发布者可通过 publishEvent() 向所有感兴趣的监听器广播事件，监听器可响应并执行对应业务逻辑。支持同步和异步两种模式。

---

## 二级主题：注解与组件扫描

### 5. 组件扫描与自动注册

#### 时间
**ConfigurationClassPostProcessor 的解析阶段**（refresh() 第 5 步内部）

#### 地点
核心类：`ClassPathBeanDefinitionScanner`
- 包：`org.springframework.context.annotation`

#### 人物
**操作主体**：ClassPathBeanDefinitionScanner
**操作目标对象**：
- Classpath 中的 .class 文件
- @Component、@Service、@Controller、@Repository 等注解
- BeanDefinitionRegistry（注册发现的 Bean）

#### 起因
应用中可能有数百个 Bean 类，手动逐个定义效率低。需要自动扫描并发现被特定注解标注的类。

#### 经过（4 个处理步骤）
1. **指定扫描路径** - @ComponentScan(basePackages="com.example") 告知扫描范围
2. **扫描类资源** - 使用 ResourcePatternResolver 遍历指定包下所有 .class 文件
3. **过滤候选类** - ClassPathScanningCandidateComponentProvider 检查每个类是否有目标注解和其他过滤条件
4. **生成 BeanDefinition** - 为每个匹配的类生成 BeanDefinition，通过 AnnotationBeanNameGenerator 生成 Bean 名称，注册到 BeanFactory

#### 结果
所有被 @Component（及其衍生注解）标注的类自动转化为 BeanDefinition，无需手动配置。

---

### 6. @Autowired 和 @Resource 依赖注入

#### 时间
**Bean 实例化的第 5 步**：执行依赖注入时

#### 地点
核心类：`CommonAnnotationBeanPostProcessor`
- 包：`org.springframework.context.annotation`
- 实现：BeanPostProcessor 接口

#### 人物
**操作主体**：CommonAnnotationBeanPostProcessor（Bean 后处理器）
**操作目标对象**：
- 标注 @Autowired、@Resource、@Inject 的字段
- 标注 @Autowired 的构造器和 Setter 方法
- 需要被注入的 Bean

#### 起因
容器需要识别 @Autowired 和 @Resource 注解，自动从容器中查找并注入对应的 Bean。

#### 经过（3 个处理步骤）
1. **扫描注解** - BeanPostProcessor.postProcessProperties() 遍历 Bean 的所有字段和方法，找出标注 @Autowired/@Resource 的部分
2. **解析类型** - 根据字段类型、@Qualifier 或名称查找匹配的 Bean
3. **执行注入** - 通过反射设置字段值或调用 Setter 方法，将 Bean 注入

#### 结果
@Autowired 和 @Resource 注解被解析，对应的 Bean 自动注入到字段。

---

## 三级主题：高级特性

### 7. 缓存抽象与 @Cacheable

#### 时间
**方法执行时**（运行时）

#### 地点
核心类：`CacheInterceptor`（AOP 拦截器）
- 包：`org.springframework.cache.annotation`

#### 人物
**操作主体**：CacheInterceptor（AOP 拦截器）
**操作目标对象**：
- 标注 @Cacheable、@CachePut、@CacheEvict 的方法
- CacheManager 和 Cache 实例
- 方法的返回值

#### 起因
应用需要缓存某些高耗时方法的返回值，减少重复计算，提升性能。

#### 经过（4 个处理步骤）
1. **方法拦截** - AOP 拦截所有标注 @Cacheable 的方法调用
2. **计算缓存键** - 根据方法参数、@Cacheable 的 key 属性生成缓存键
3. **缓存查询** - 从 CacheManager 获取指定 Cache，检查键是否存在
4. **条件返回或执行** - 若缓存命中则直接返回；否则执行原方法，将返回值放入缓存，再返回

#### 结果
方法返回值被缓存，相同参数的后续调用直接返回缓存值，无需重复执行。@CacheEvict 则在执行后清除缓存，@CachePut 强制更新缓存。

---

### 8. 定时任务与 @Scheduled

#### 时间
**应用启动时**（容器初始化）以及**定时触发时**

#### 地点
核心类：`ScheduledAnnotationBeanPostProcessor`
- 包：`org.springframework.scheduling.annotation`

#### 人物
**操作主体**：ScheduledAnnotationBeanPostProcessor + TaskScheduler
**操作目标对象**：
- 标注 @Scheduled 的方法
- TaskScheduler（任务调度器）
- 线程池（ExecutorService）

#### 起因
应用需要定期执行某些任务（如定时同步数据、清理过期数据），需要声明式的任务调度方案。

#### 经过（4 个处理步骤）
1. **扫描 @Scheduled 方法** - ScheduledAnnotationBeanPostProcessor 在 Bean 初始化后处理，找出所有标注 @Scheduled 的方法
2. **解析调度参数** - 从 @Scheduled 注解提取 cron 表达式、固定延迟(fixedDelay)、固定速率(fixedRate) 等
3. **创建触发器** - CronTrigger(cron 表达式)或 PeriodicTrigger(延迟/速率)
4. **注册到 TaskScheduler** - 将方法包装为 Runnable，注册到 TaskScheduler，由它按触发器时间表执行

#### 结果
应用启动后，TaskScheduler 接管所有 @Scheduled 方法的定期执行，无需手动创建线程和时间轮询。

---

### 9. 异步执行与 @Async

#### 时间
**方法调用时**（运行时）

#### 地点
核心类：`AsyncAnnotationBeanPostProcessor`
- 包：`org.springframework.scheduling.annotation`

#### 人物
**操作主体**：AsyncAnnotationBeanPostProcessor（AOP）
**操作目标对象**：
- 标注 @Async 的方法
- TaskExecutor（任务执行器线程池）
- 方法返回值 (Future 或 void)

#### 起因
某些耗时操作不需要立即返回结果，应该异步执行，避免阻塞调用线程。

#### 经过（3 个处理步骤）
1. **AOP 拦截** - AsyncAnnotationBeanPostProcessor 为标注 @Async 的方法创建 AOP 代理
2. **提交任务** - 拦截器将方法执行包装为 Runnable/Callable，提交给 TaskExecutor（线程池）
3. **返回 Future** - 拦截器立即返回 Future（如果方法返回类型是 Future）或 void；实际方法在线程池中异步执行

#### 结果
@Async 方法调用不再阻塞调用者，方法在后台线程池中执行，提升应用响应性。

---

### 10. 数据验证与 Bean Validation

#### 时间
**Bean 初始化或方法调用前**

#### 地点
核心类：`LocalValidatorFactoryBean`、`MethodValidationPostProcessor`
- 包：`org.springframework.validation.beanvalidation`

#### 人物
**操作主体**：LocalValidatorFactoryBean（Bean 验证工厂）
**操作目标对象**：
- 标注 JSR-303/380 验证注解的 Bean（@NotNull、@Min、@Max 等）
- Validator 实例
- 方法参数和返回值

#### 起因
应用需要验证输入数据是否符合业务规则，防止无效数据进入处理流程。

#### 经过（3 个处理步骤）
1. **初始化验证器** - LocalValidatorFactoryBean 创建 JSR-303 ValidatorFactory 和 Validator
2. **触发验证** - 在 Bean 初始化或方法执行前，MethodValidationPostProcessor 拦截并调用 Validator.validate()
3. **收集违规** - Validator 检查所有标注的约束注解，生成 ConstraintViolation 集合，返回给调用者

#### 结果
无效数据被拒绝，应用只处理合法数据。验证逻辑集中在注解中，声明式定义，易于维护。

---

### 11. 国际化与消息源

#### 时间
**应用启动时**（initMessageSource）和**运行时消息查询**

#### 地点
核心类：`ResourceBundleMessageSource`、`ReloadableResourceBundleMessageSource`
- 包：`org.springframework.context.support`

#### 人物
**操作主体**：MessageSource（消息源，通常是 ResourceBundleMessageSource）
**操作目标对象**：
- .properties 属性文件（多语言资源包）
- 消息键（message key）
- 语言环境（Locale）

#### 起因
应用需要支持多语言，同一个消息需要在不同语言环境下显示不同文本。

#### 经过（3 个处理步骤）
1. **加载资源** - 应用启动时，MessageSource 加载 messages.properties、messages_zh_CN.properties 等资源文件
2. **缓存消息** - 将消息键和文本缓存在内存中
3. **查询翻译** - getMessage(code, args, locale) 被调用时，根据 Locale 查找对应的消息文本

#### 结果
应用可通过 MessageSource 获取多语言文本，用户界面根据其语言环境显示对应语言。

---

## 四级主题：扩展点与生命周期

### 12. BeanPostProcessor 扩展机制

#### 时间
**Bean 初始化的前后阶段**（refresh() 第 6 步后、第 11 步中）

#### 地点
核心接口：`BeanPostProcessor`
- 方法：postProcessBeforeInitialization() 和 postProcessAfterInitialization()
- 所有 BeanPostProcessor 实现类被注册为 Bean 后处理器链

#### 人物
**操作主体**：BeanFactory（执行链）
**操作目标对象**：
- 每个被创建的 Bean 实例
- 所有注册的 BeanPostProcessor

#### 起因
容器需要提供扩展点，允许开发者在 Bean 初始化前后进行自定义处理（如代理、增强、验证）。

#### 经过（3 个处理步骤）
1. **收集处理器** - BeanFactory 在启动时收集所有实现 BeanPostProcessor 的 Bean
2. **初始化前调用** - 对于每个 Bean，依次调用所有 postProcessBeforeInitialization()
3. **初始化后调用** - 执行 @PostConstruct、init-method 等初始化，再依次调用 postProcessAfterInitialization()

#### 结果
开发者可实现自定义 BeanPostProcessor，对任意 Bean 进行增强（如注解处理、AOP 代理、字段赋值）。Spring 的 @Autowired、@PostConstruct、AOP 代理等内部机制都基于此扩展点。

---

### 13. ApplicationContextInitializer 启动初始化

#### 时间
**容器创建之初**（refresh() 执行前）

#### 地点
接口：`ApplicationContextInitializer`
- 包：`org.springframework.context`

#### 人物
**操作主体**：ApplicationContextInitializer（应用上下文初始化器）
**操作目标对象**：
- ConfigurableApplicationContext（可配置的容器）
- 容器的 BeanDefinitionRegistry、PropertySource 等

#### 起因
在容器完全初始化前，某些自定义配置（如动态添加 PropertySource、预注册 Bean）需要执行。

#### 经过（2 个处理步骤）
1. **发现初始化器** - Spring Boot 或应用代码通过 META-INF/spring.factories 或显式指定注册 ApplicationContextInitializer
2. **按顺序执行** - 容器 refresh() 前，依次调用所有初始化器的 initialize(context) 方法

#### 结果
初始化器可在容器启动前进行定制配置，如添加环境变量、自定义 Bean 定义等。

---

## 五级主题：事件与生命周期

### 14. Lifecycle 和 SmartLifecycle 管理

#### 时间
**容器启动时**（finishRefresh）和**容器关闭时**（close）

#### 地点
核心类：`DefaultLifecycleProcessor`
- 包：`org.springframework.context.support`

#### 人物
**操作主体**：DefaultLifecycleProcessor
**操作目标对象**：
- 实现 Lifecycle 或 SmartLifecycle 接口的 Bean
- start() / stop() 方法

#### 起因
某些 Bean（如数据库连接池、消息队列消费者）需要在容器启动时初始化，在容器关闭时优雅地释放资源。

#### 经过（3 个处理步骤）
1. **收集 Lifecycle Bean** - finishRefresh() 中，查找所有实现 Lifecycle 接口的 Bean
2. **启动阶段** - 调用 start() 按优先级启动 Bean（SmartLifecycle.getPhase() 定义顺序）
3. **停止阶段** - 容器 close() 时，按反序调用 stop()

#### 结果
Bean 的 start/stop 生命周期与容器的启动/关闭同步，无需手动管理资源的创建和释放。

---

### 15. ContextRefreshedEvent 和 ContextClosedEvent 事件

#### 时间
**refresh() 完成时**（ContextRefreshedEvent）和**close() 执行时**（ContextClosedEvent）

#### 地点
事件类：
- `ContextRefreshedEvent`
- `ContextClosedEvent`
- 包：`org.springframework.context.event`

#### 人物
**操作主体**：AbstractApplicationContext
**操作目标对象**：
- 所有注册的 ApplicationListener
- @EventListener 方法

#### 起因
应用需要在容器完全准备就绪或即将关闭时执行某些初始化或清理逻辑。

#### 经过（2 个处理步骤）
1. **发布事件** - finishRefresh() 调用 publishEvent(new ContextRefreshedEvent())；close() 发布 ContextClosedEvent
2. **通知监听器** - SimpleApplicationEventMulticaster 将事件发送给所有监听器

#### 结果
应用可通过 @EventListener(ContextRefreshedEvent.class) 实现容器启动完成的自定义逻辑，如初始化缓存、启动定时任务等。

---

## 六级主题：表达式与动态值

### 16. SpEL 表达式与 @Value

#### 时间
**Bean 属性值解析时**（依赖注入阶段）

#### 地点
核心类：`StandardBeanExpressionResolver`
- 包：`org.springframework.context.expression`

#### 人物
**操作主体**：StandardBeanExpressionResolver（表达式解析器）
**操作目标对象**：
- @Value 注解的属性值（如 `@Value("#{systemProperties['user.home']}")`）
- SpEL 表达式字符串
- Bean 属性的最终值

#### 起因
应用需要在配置中使用动态值（如调用方法、访问 Bean 属性、系统属性），而不仅仅是静态字符串。

#### 经过（3 个处理步骤）
1. **识别表达式** - 当 @Value 包含 "#{...}" 或 "${...}" 时，容器识别为表达式或属性占位符
2. **解析表达式** - SpEL Parser 解析表达式字符串，生成 AST（抽象语法树）
3. **求值** - Expression.getValue(context) 在 Bean 的上下文中求值，返回最终值

#### 结果
@Value("#{T(java.lang.Math).random()}") 等动态表达式可在 Bean 初始化时执行，为属性赋予动态值。

---

## 七级主题：AOP 织入与代理

### 17. 加载时织入 (Load-Time Weaving, LTW)

#### 时间
**类加载时**（JVM 加载字节码）

#### 地点
核心类：`LoadTimeWeaverAwareProcessor`
- 包：`org.springframework.context.weaving`

#### 人物
**操作主体**：LoadTimeWeaverAwareProcessor（LTW 处理器）
**操作目标对象**：
- 实现 LoadTimeWeaverAware 接口的 Bean
- Instrumentation（Java Agent）
- AspectJ 织入器

#### 起因
某些 AOP 场景（如 AspectJ）需要在类加载阶段织入代码，而不是运行时创建代理。

#### 经过（2 个处理步骤）
1. **提供 LoadTimeWeaver** - LoadTimeWeaverAwareProcessor 注入 LoadTimeWeaver 到感知 Bean
2. **织入织入器** - 织入器通过 Instrumentation 在类加载时修改字节码

#### 结果
AspectJ 切面可在类加载时织入，支持对私有方法、构造器、静态初始化块的增强。

---

## 总结表：关键类与职责

| 模块 | 关键类 | 职责 |
|------|--------|------|
| **容器初始化** | AbstractApplicationContext | 12 步刷新流程，容器生命周期 |
| **配置处理** | ConfigurationClassPostProcessor | @Configuration 解析，@Bean 注册 |
| **组件扫描** | ClassPathBeanDefinitionScanner | @Component 自动发现和注册 |
| **Bean 创建** | DefaultListableBeanFactory | Bean 实例化、依赖注入、生命周期 |
| **依赖注入** | CommonAnnotationBeanPostProcessor | @Autowired、@Resource 解析 |
| **事件发布** | SimpleApplicationEventMulticaster | 事件多播、监听器分发 |
| **缓存** | CacheInterceptor | @Cacheable 拦截、缓存管理 |
| **任务调度** | ScheduledAnnotationBeanPostProcessor | @Scheduled 触发器注册 |
| **异步执行** | AsyncAnnotationBeanPostProcessor | @Async 方法异步代理 |
| **验证** | LocalValidatorFactoryBean | JSR-303/380 验证 |
| **消息源** | ResourceBundleMessageSource | 多语言文本加载 |
| **生命周期** | DefaultLifecycleProcessor | Lifecycle.start/stop 调用 |
| **表达式** | StandardBeanExpressionResolver | SpEL 表达式求值 |
| **AOP 织入** | LoadTimeWeaverAwareProcessor | LTW 字节码增强 |

---

## 核心流程视图

```
应用启动
  ↓
new AnnotationConfigApplicationContext(Config.class)
  ↓
AbstractApplicationContext.refresh() [12 步]
  ├─ 第 5 步: ConfigurationClassPostProcessor 处理 @Configuration
  │   └─ ClassPathBeanDefinitionScanner 扫描 @Component
  │   └─ BeanDefinition 注册到 BeanFactory
  │
  ├─ 第 11 步: finishBeanFactoryInitialization() 创建 Bean
  │   └─ DefaultListableBeanFactory.getBean() 逐一创建
  │   └─ CommonAnnotationBeanPostProcessor 处理 @Autowired
  │   └─ 执行 BeanPostProcessor 链（包括 AOP 代理、缓存、异步等）
  │   └─ 调用 @PostConstruct、init-method
  │
  ├─ 第 12 步: finishRefresh() 完成刷新
  │   └─ startLifecycleBeans() 调用 Lifecycle.start()
  │   └─ publishEvent(ContextRefreshedEvent) 发布事件
  │
  ↓
容器就绪
  ├─ @EventListener 监听事件
  ├─ @Scheduled 定时执行
  ├─ @Async 异步方法
  ├─ @Cacheable 缓存方法
  └─ ...

  ↓
应用关闭
  ↓
AbstractApplicationContext.close()
  ├─ stopLifecycleBeans() 调用 Lifecycle.stop()
  ├─ publishEvent(ContextClosedEvent)
  ├─ 清理资源
  ↓
结束
```

---

## 设计模式应用总结

| 模式 | 应用场景 |
|------|--------|
| **Template Method** | AbstractApplicationContext.refresh() 定义骨架，子类可覆盖 postProcessBeanFactory() 等 |
| **Observer** | ApplicationEventPublisher/Listener 事件发布-订阅 |
| **Chain of Responsibility** | BeanPostProcessor 链、BeanFactoryPostProcessor 链 |
| **Adapter** | ApplicationListenerMethodAdapter 适配 @EventListener 方法 |
| **Strategy** | Condition、ImportSelector、BeanNameGenerator 等策略接口 |
| **Decorator** | LoadTimeWeaverAwareProcessor 装饰 LoadTimeWeaver |
| **Proxy** | ConfigurationClassEnhancer 使用 CGLIB 代理 @Configuration 类 |
| **Factory** | BeanFactory、FactoryBean、ApplicationContextFactory |
| **Composite** | CompositeCacheManager 聚合多个 CacheManager |

---

**文档生成时间**：2025-11-25
**分析范围**：spring-context 模块核心功能
**文档风格**：精炼本质、去除冗余、六要素结构化
