# Spring Aspects 模块详细分析

> 基于记叙文6要素：时间、地点、人物、起因、经过、结果

---

## 模块概述

**模块定位**: AspectJ 原生织入实现，提供比 spring-aop 更强大的 AOP 能力
**核心本质**: 使用 AspectJ 编译器在编译时或类加载时直接修改字节码，而非运行时创建代理
**关键区别**: spring-aop 是代理模式，spring-aspects 是字节码织入
**适用场景**: 需要增强非 Spring Bean、私有方法、或追求极致性能的场景

---

## 一、AspectJ 织入机制

### 【时间】何时织入
- **编译时织入（CTW）**: 在 Java 编译阶段，使用 AspectJ 编译器（ajc）
- **加载时织入（LTW）**: 在类加载到 JVM 时，通过 Java Agent 拦截

### 【地点】在哪里织入
- **CTW 位置**: 构建过程中，通过 Gradle/Maven 的 AspectJ 插件
- **LTW 位置**: JVM 启动时，通过 `-javaagent:spring-instrument.jar` 参数

### 【人物】研究对象
- **源文件**: `.aj` 文件（AspectJ 原生语法）而非 `.java` 文件
- **核心切面类**:
  - `AnnotationTransactionAspect.aj` - 事务切面
  - `AnnotationBeanConfigurerAspect.aj` - 依赖注入切面
  - `AnnotationCacheAspect.aj` - 缓存切面
  - `AnnotationAsyncExecutionAspect.aj` - 异步执行切面

### 【起因】为什么需要 AspectJ 织入
- **代理局限性**: Spring AOP 代理无法拦截内部方法调用（this 调用）
- **可见性限制**: 代理模式只能增强 public 方法
- **对象限制**: 代理模式只能增强 Spring 管理的 Bean
- **性能需求**: 代理模式有运行时开销，字节码织入性能更优

### 【经过】处理步骤（精炼）

**编译时织入（CTW）流程**:

**步骤1: 配置 AspectJ 编译器**
- **操作主体**: 构建工具（Gradle/Maven）
- **核心动作**: 使用 AspectJ 编译器替代 javac
- **配置示例**:
  ```gradle
  apply plugin: "io.freefair.aspectj"
  aspectj.version = "1.9.5"
  ```

**步骤2: 编译源文件**
- **操作主体**: AspectJ 编译器（ajc）
- **核心动作**: 同时编译 `.java` 和 `.aj` 文件
- **关键产物**: 包含织入逻辑的 `.class` 字节码

**步骤3: 织入切面逻辑**
- **操作主体**: AspectJ 织入器
- **核心动作**: 在编译期将切面逻辑织入目标类的字节码
- **织入位置**: 符合 pointcut 表达式的所有连接点

**加载时织入（LTW）流程**:

**步骤1: 配置 Java Agent**
- **操作主体**: JVM 启动参数
- **核心动作**: 添加 `-javaagent:spring-instrument.jar`
- **作用**: 拦截类加载过程

**步骤2: 配置织入规则**
- **操作主体**: `META-INF/aop.xml` 配置文件
- **核心动作**: 声明需要应用的切面
- **配置示例**:
  ```xml
  <aspectj>
      <aspects>
          <aspect name="org.springframework.transaction.aspectj.AnnotationTransactionAspect"/>
          <aspect name="org.springframework.beans.factory.aspectj.AnnotationBeanConfigurerAspect"/>
      </aspects>
  </aspectj>
  ```

**步骤3: 类加载拦截**
- **操作主体**: Spring Instrument Agent
- **核心动作**: 拦截类加载器的 `loadClass()` 方法
- **时机**: 在类被加载到 JVM 之前

**步骤4: 字节码织入**
- **操作主体**: AspectJ Weaver
- **核心动作**: 读取 `aop.xml`，将切面逻辑织入字节码
- **结果**: 修改后的字节码加载到 JVM

### 【结果】最终状态
- **字节码层面**: 目标类的字节码已被修改，包含切面逻辑
- **运行时状态**: 方法执行时直接执行织入的逻辑，无需代理
- **对象状态**: 原始对象本身就包含增强逻辑，无代理包装

---

## 二、@Configurable 依赖注入

### 【时间】何时注入
- **对象创建时**: 在构造器执行后立即注入（默认）
- **构造器执行前**: 配置 `@Configurable(preConstruction=true)` 时
- **对象反序列化时**: 从流中恢复对象后触发注入

### 【地点】在哪里注入
- **字节码位置**: 构造器的字节码后插入注入逻辑
- **运行环境**: 任何创建对象的地方（包括 `new` 关键字）
- **Spring 容器**: 通过 `AnnotationBeanConfigurerAspect` 连接到容器

### 【人物】研究对象
- **核心切面**: `AnnotationBeanConfigurerAspect.aj`
- **目标对象**: 标注 `@Configurable` 的任何类（包括非 Spring Bean）
- **配置类**: `SpringConfiguredConfiguration` 注册切面实例

### 【起因】为什么需要 @Configurable
- **领域驱动设计**: 领域对象通常用 `new` 创建，不经过 Spring 容器
- **依赖需求**: 这些对象仍需要注入 Service、Repository 等依赖
- **代理不可行**: 代理模式只能增强容器管理的 Bean
- **解决方案**: 通过 AspectJ 织入，在对象创建时自动注入依赖

### 【经过】处理步骤（精炼）

**步骤1: 声明切面类型**
- **操作主体**: AspectJ 编译器
- **核心动作**: 使用 `declare parents` 语法
- **关键代码**:
  ```aspectj
  declare parents: @Configurable * implements ConfigurableObject;
  ```
- **效果**: 所有 `@Configurable` 类自动实现 `ConfigurableObject` 接口

**步骤2: 定义切点**
- **操作主体**: `AnnotationBeanConfigurerAspect`
- **核心切点**:
  ```aspectj
  // 匹配所有 @Configurable 对象
  public pointcut inConfigurableBean() : @this(Configurable);

  // 匹配构造器执行后
  public pointcut beanConstruction(Object bean) :
      initialization(ConfigurableObject+.new(..)) && this(bean);

  // 匹配反序列化
  public pointcut beanDeserialization(Object bean) :
      execution(Object ConfigurableDeserializationSupport+.readResolve()) && this(bean);
  ```

**步骤3: 织入通知**
- **操作主体**: AspectJ Weaver
- **核心动作**: 在构造器字节码后插入 `after() returning` 通知
- **通知代码**:
  ```aspectj
  after(Object bean) returning :
      beanConstruction(bean) && inConfigurableBean() {
      configureBean(bean);
  }
  ```

**步骤4: 执行依赖注入**
- **操作主体**: `BeanConfigurerSupport`
- **核心动作**: 查找 Bean 定义并注入
- **关键步骤**:
  1. 从 `@Configurable` 注解获取 beanName
  2. 从 Spring 容器查找对应的 BeanDefinition
  3. 应用属性注入（`populateBean` 逻辑）
  4. 调用初始化方法

**步骤5: 反序列化支持**
- **操作主体**: AspectJ 编译器
- **核心动作**: 为可序列化对象引入 `readResolve()` 方法
- **关键代码**:
  ```aspectj
  declare parents: ConfigurableObject+ && Serializable+
      implements ConfigurableDeserializationSupport;

  public Object ConfigurableDeserializationSupport.readResolve() {
      return this;
  }
  ```
- **效果**: 反序列化后触发通知，重新注入依赖

### 【结果】最终状态
- **对象创建**: 使用 `new` 创建的对象自动拥有依赖
- **字节码**: 构造器后包含 `configureBean()` 调用
- **依赖状态**: 字段、属性已被 Spring 容器注入
- **生命周期**: 对象不归 Spring 容器管理，但拥有容器注入的依赖

---

## 三、AspectJ 事务切面

### 【时间】何时执行事务
- **方法调用时**: 执行标注 `@Transactional` 的方法时
- **内部调用**: 同一类内部方法调用也会触发（区别于代理）
- **任何可见性**: 支持 private、protected、package 方法（区别于代理）

### 【地点】在哪里执行
- **字节码层面**: 方法执行的字节码被 `around()` 通知包围
- **运行上下文**: 与代理模式共享 `TransactionAspectSupport` 基类
- **事务管理器**: 使用相同的 `PlatformTransactionManager`

### 【人物】研究对象
- **核心切面**: `AnnotationTransactionAspect.aj`
- **父切面**: `AbstractTransactionAspect.aj`
- **共享基类**: `TransactionAspectSupport`（与 spring-tx 共享）
- **配置类**: `AspectJTransactionManagementConfiguration`

### 【起因】为什么需要 AspectJ 事务
- **this 调用问题**: 代理无法拦截内部方法调用
  ```java
  public void methodA() {
      this.methodB(); // 代理拦截不到，AspectJ 可以
  }

  @Transactional
  public void methodB() {
      // 业务逻辑
  }
  ```
- **私有方法**: 代理只能增强 public 方法，AspectJ 支持任何可见性
- **性能优化**: 字节码织入比代理调用更快
- **非 Spring Bean**: AspectJ 可以为任何对象添加事务

### 【经过】处理步骤（精炼）

**步骤1: 定义切点**
- **操作主体**: `AnnotationTransactionAspect`
- **核心切点**:
  ```aspectj
  // 匹配类级别 @Transactional 的所有 public 方法
  private pointcut executionOfAnyPublicMethodInAtTransactionalType() :
      execution(public * ((@Transactional *)+).*(..)) && within(@Transactional *);

  // 匹配方法级别 @Transactional
  private pointcut executionOfTransactionalMethod() :
      execution(@Transactional * *(..));

  // 组合切点
  protected pointcut transactionalMethodExecution(Object txObject) :
      (executionOfAnyPublicMethodInAtTransactionalType()
       || executionOfTransactionalMethod()) && this(txObject);
  ```

**步骤2: 织入环绕通知**
- **操作主体**: `AbstractTransactionAspect`
- **核心通知**:
  ```aspectj
  Object around(final Object txObject): transactionalMethodExecution(txObject) {
      MethodSignature methodSignature = (MethodSignature) thisJoinPoint.getSignature();

      return invokeWithinTransaction(
          methodSignature.getMethod(),
          txObject.getClass(),
          new InvocationCallback() {
              public Object proceedWithInvocation() throws Throwable {
                  return proceed(txObject); // 执行原方法
              }
          });
  }
  ```

**步骤3: 共享事务逻辑**
- **操作主体**: `TransactionAspectSupport.invokeWithinTransaction()`
- **核心动作**: 与代理模式使用相同的事务管理逻辑
- **关键步骤**:
  1. 获取 `TransactionAttribute`（事务配置）
  2. 确定 `PlatformTransactionManager`
  3. 创建或加入事务
  4. 执行 `callback.proceedWithInvocation()`
  5. 提交或回滚事务

**步骤4: 注册切面实例**
- **操作主体**: `AspectJTransactionManagementConfiguration`
- **核心动作**: 通过 `aspectOf()` 获取切面单例
- **关键代码**:
  ```java
  @Bean(name = TRANSACTION_ASPECT_BEAN_NAME)
  @Role(BeanDefinition.ROLE_INFRASTRUCTURE)
  public AnnotationTransactionAspect transactionAspect() {
      AnnotationTransactionAspect txAspect = AnnotationTransactionAspect.aspectOf();
      if (this.txManager != null) {
          txAspect.setTransactionManager(this.txManager);
      }
      return txAspect;
  }
  ```
- **说明**: `aspectOf()` 是 AspectJ 为单例切面生成的方法

### 【结果】最终状态
- **字节码**: 方法执行被事务逻辑包围
- **内部调用**: this 调用也会触发事务（代理做不到）
- **可见性**: 私有方法也可以有事务（代理做不到）
- **性能**: 直接字节码执行，无代理开销

---

## 四、核心对比：spring-aspects vs spring-aop

### 对比矩阵

| 维度 | spring-aop (代理) | spring-aspects (织入) |
|------|------------------|---------------------|
| **【人物】实现方式** | JDK 动态代理 / CGLIB | AspectJ 字节码织入 |
| **【时间】处理时机** | 运行时创建代理 | 编译时或加载时织入 |
| **【地点】处理位置** | BeanPostProcessor | AspectJ 编译器/Weaver |
| **【起因】适用场景** | Spring Bean 增强 | 任何对象增强 |
| **【经过】文件类型** | .java + @Aspect 注解 | .aj 原生 AspectJ |
| **【结果】对象状态** | 代理包装原对象 | 字节码直接修改 |
| **连接点支持** | 仅方法执行 | 所有 AspectJ 连接点 |
| **内部调用** | 不支持（this 调用） | 支持 |
| **方法可见性** | public（接口代理） | 任何可见性 |
| **性能** | 有代理开销 | 无代理开销（更快） |
| **配置复杂度** | 简单（注解驱动） | 复杂（需要 AspectJ 工具） |

---

## 五、典型场景执行时序

### 场景1: @Configurable 对象创建

```
时间点1: 编译阶段
  └─ 操作主体: AspectJ 编译器（ajc）
  └─ 动作: 编译 AnnotationBeanConfigurerAspect.aj
  └─ 结果: 生成切面字节码

时间点2: 编译目标类
  └─ 操作主体: AspectJ 编译器
  └─ 动作: 编译 @Configurable 标注的类
  └─ 织入: declare parents 使其实现 ConfigurableObject
  └─ 结果: 构造器后插入 configureBean() 调用

时间点3: 应用启动
  └─ 操作主体: Spring 容器
  └─ 动作: 注册 AnnotationBeanConfigurerAspect 实例
  └─ 设置: 切面持有 BeanFactory 引用
  └─ 结果: 切面准备就绪

时间点4: 用户代码创建对象
  └─ 操作主体: 应用代码
  └─ 动作: new MyConfigurableObject()
  └─ 上下文: 使用 new 关键字，非 Spring 容器创建

时间点5: 构造器执行
  └─ 操作主体: JVM
  └─ 动作: 执行构造器字节码
  └─ 状态: 对象实例化，字段为默认值

时间点6: 切面通知触发（织入的代码）
  └─ 操作主体: AnnotationBeanConfigurerAspect
  └─ 动作: after() returning 通知执行
  └─ 调用: configureBean(newObject)

时间点7: 依赖注入
  └─ 操作主体: BeanConfigurerSupport
  └─ 动作:
      1. 读取 @Configurable(value="beanName")
      2. 从容器查找 BeanDefinition
      3. 应用属性注入
      4. 调用初始化方法
  └─ 结果: 对象拥有注入的依赖

时间点8: 返回到用户代码
  └─ 操作主体: 应用代码
  └─ 动作: 获得完全初始化的对象
  └─ 状态: 对象包含 Spring 注入的依赖
  └─ 关键: 对象不在 Spring 容器中，但拥有容器注入的依赖
```

### 场景2: AspectJ 事务方法执行（包含内部调用）

```
时间点1: LTW 配置
  └─ 操作主体: META-INF/aop.xml
  └─ 动作: 声明 AnnotationTransactionAspect
  └─ 结果: AspectJ Weaver 知道要应用事务切面

时间点2: 类加载
  └─ 操作主体: Spring Instrument Agent
  └─ 动作: 拦截 Service 类加载
  └─ 织入: AspectJ Weaver 修改字节码
  └─ 结果: @Transactional 方法被 around() 通知包围

时间点3: 外部方法调用
  └─ 操作主体: 用户代码
  └─ 动作: service.methodA()
  └─ 上下文: methodA 无 @Transactional

时间点4: 内部方法调用（关键）
  └─ 操作主体: methodA 内部
  └─ 动作: this.methodB()
  └─ 上下文: methodB 有 @Transactional
  └─ 关键: 代理模式拦截不到，AspectJ 可以

时间点5: 切面拦截（织入的代码）
  └─ 操作主体: AnnotationTransactionAspect
  └─ 动作: around() 通知执行
  └─ 上下文: 拦截 methodB 执行

时间点6: 开启事务
  └─ 操作主体: TransactionAspectSupport
  └─ 动作: invokeWithinTransaction()
  └─ 步骤:
      1. 获取 TransactionManager
      2. 创建新事务
      3. 绑定连接到线程

时间点7: 执行业务逻辑
  └─ 操作主体: proceed(txObject)
  └─ 动作: 执行 methodB 的原始代码
  └─ 上下文: 在事务中执行

时间点8: 提交事务
  └─ 操作主体: TransactionAspectSupport
  └─ 动作:
      IF (无异常) → 提交事务
      ELSE → 回滚事务
  └─ 结果: 事务完成

时间点9: 返回结果
  └─ 操作主体: methodB
  └─ 动作: 返回到 methodA
  └─ 关键: 内部调用成功触发事务（代理做不到）
```

---

## 六、关键配置示例

### 1. 启用 Load-Time Weaving

**Java Config**:
```java
@Configuration
@EnableLoadTimeWeaving(aspectjWeaving = EnableLoadTimeWeaving.AspectJWeaving.ENABLED)
@EnableTransactionManagement(mode = AdviceMode.ASPECTJ)
@EnableSpringConfigured  // 启用 @Configurable 支持
public class AppConfig {

    @Bean
    public PlatformTransactionManager transactionManager(DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }
}
```

**JVM 参数**:
```bash
java -javaagent:spring-instrument.jar -jar myapp.jar
```

**META-INF/aop.xml**:
```xml
<!DOCTYPE aspectj PUBLIC "-//AspectJ//DTD//EN" "http://www.eclipse.org/aspectj/dtd/aspectj.dtd">
<aspectj>
    <weaver options="-verbose -showWeaveInfo">
        <include within="com.example..*"/>
    </weaver>

    <aspects>
        <aspect name="org.springframework.transaction.aspectj.AnnotationTransactionAspect"/>
        <aspect name="org.springframework.beans.factory.aspectj.AnnotationBeanConfigurerAspect"/>
        <aspect name="org.springframework.cache.aspectj.AnnotationCacheAspect"/>
    </aspects>
</aspectj>
```

### 2. 使用 @Configurable

**领域对象**:
```java
@Configurable("userEntityConfigurer")
public class User {

    @Autowired
    private transient UserRepository repository;  // 注意：transient 避免序列化

    public void save() {
        repository.save(this);  // 使用注入的依赖
    }
}
```

**Spring 配置**:
```java
@Bean
public BeanDefinition userEntityConfigurer() {
    BeanDefinition bd = new RootBeanDefinition();
    bd.setScope("prototype");
    bd.setAutowireMode(AbstractBeanDefinition.AUTOWIRE_BY_TYPE);
    return bd;
}
```

**使用示例**:
```java
User user = new User();  // 使用 new 创建
user.setName("张三");
user.save();  // repository 已被自动注入
```

---

## 七、性能与限制

### 性能优势
1. **无代理开销**: 直接字节码执行，比代理快 10-30%
2. **无反射调用**: 方法调用不经过反射
3. **编译时优化**: CTW 可以进行更多编译时优化

### 使用限制
1. **构建复杂**: 需要配置 AspectJ 编译器或 LTW Agent
2. **调试困难**: 字节码被修改，调试时看不到织入的代码
3. **学习曲线**: 需要理解 AspectJ 语法和织入机制
4. **IDE 支持**: 需要安装 AJDT (AspectJ Development Tools) 插件

### 选择建议
- **优先使用 spring-aop**: 满足 90% 的场景，配置简单
- **特殊场景使用 spring-aspects**:
  - 需要拦截内部调用
  - 需要增强私有方法
  - 需要为非 Spring Bean 注入依赖
  - 性能极度敏感的场景

---

## 八、关键设计模式

### 1. 织入模式 (Weaving Pattern)
- **应用**: AspectJ 编译器和 Weaver
- **目的**: 在不修改源代码的情况下修改字节码
- **实现**: 编译时或加载时修改 .class 文件

### 2. 模板方法模式 (Template Method)
- **应用**: `AbstractTransactionAspect` 和 `AbstractDependencyInjectionAspect`
- **目的**: 定义算法骨架，子类实现具体切点
- **实现**: 抽象切面定义通知，具体切面定义 pointcut

### 3. 回调模式 (Callback Pattern)
- **应用**: `InvocationCallback` 在事务切面中
- **目的**: 将方法执行逻辑委托给回调
- **实现**: `proceed(txObject)` 包装为 `proceedWithInvocation()`

### 4. 单例模式 (Singleton Pattern)
- **应用**: AspectJ 切面实例
- **目的**: 每个切面类型只有一个实例
- **实现**: `aspectOf()` 方法返回单例实例

---

## 九、常见问题

### Q1: @Aspect 注解和 .aj 文件有什么区别？
**答**:
- `@Aspect` 注解：Spring AOP 使用，运行时代理
- `.aj` 文件：AspectJ 原生语法，编译时/加载时织入
- spring-aspects 模块使用 `.aj` 文件，不使用 `@Aspect` 注解

### Q2: 为什么 @Transactional 要标注在实现类而非接口？
**答**:
- AspectJ 遵循 Java 规则：接口上的注解不被继承
- 织入需要具体类的字节码
- 代理模式可以用接口注解（因为代理实现接口）

### Q3: @Configurable 的性能开销大吗？
**答**:
- 每次 `new` 对象都会触发 Spring 容器查找和注入
- 建议只在真正需要依赖注入的领域对象上使用
- 可以考虑使用工厂模式或构造器注入替代

### Q4: 如何验证 LTW 是否生效？
**答**:
- 启用 AspectJ Weaver 日志：`-Daj.weaving.verbose=true`
- 查看控制台输出：`[AppClassLoader@xxx] weaveinfo Join point 'method-execution...'`
- 使用 `@EnableLoadTimeWeaving` 的 `aspectjWeaving` 属性

---

## 十、核心源码位置

| 组件 | 文件路径 |
|------|---------|
| **事务切面** | `spring-aspects/src/main/java/org/springframework/transaction/aspectj/AnnotationTransactionAspect.aj` |
| **依赖注入切面** | `spring-aspects/src/main/java/org/springframework/beans/factory/aspectj/AnnotationBeanConfigurerAspect.aj` |
| **缓存切面** | `spring-aspects/src/main/java/org/springframework/cache/aspectj/AnnotationCacheAspect.aj` |
| **异步切面** | `spring-aspects/src/main/java/org/springframework/scheduling/aspectj/AnnotationAsyncExecutionAspect.aj` |
| **事务配置** | `spring-aspects/src/main/java/org/springframework/transaction/aspectj/AspectJTransactionManagementConfiguration.java` |
| **LTW 配置** | `spring-aspects/src/main/resources/META-INF/aop.xml` |
| **构建配置** | `spring-aspects/spring-aspects.gradle` |

---

## 总结

### 核心本质
Spring Aspects 的核心本质是：**通过 AspectJ 字节码织入技术，在编译时或类加载时直接修改字节码，实现比代理模式更强大、更灵活的 AOP 能力**

### 关键要素
1. **【时间】何时**: 编译时（CTW）或类加载时（LTW）织入，运行时直接执行
2. **【地点】何地**: AspectJ 编译器或 JVM Agent 中，字节码层面修改
3. **【人物】何人**: .aj 切面文件（非 @Aspect 注解），AspectJ Weaver
4. **【起因】为何**: 解决代理局限（内部调用、私有方法、非 Spring Bean）
5. **【经过】如何**: 编译/加载时读取切面定义，修改目标类字节码，织入增强逻辑
6. **【结果】结果**: 字节码直接包含增强逻辑，无代理包装，性能更优

### 与 spring-aop 的本质区别
- **spring-aop**: 运行时代理，适合 Spring Bean 的方法级增强
- **spring-aspects**: 字节码织入，适合任何对象的全方位增强

### 适用场景
- 需要拦截 this 内部调用
- 需要增强私有/保护方法
- 需要为非 Spring 对象注入依赖（@Configurable）
- 追求极致性能
- 需要 AspectJ 的高级特性（字段访问、构造器拦截等）

---

**文档生成时间**: 2025-11-25
**Spring Framework 版本**: 5.2.3.RELEASE
**分析深度**: 精炼核心，聚焦本质
