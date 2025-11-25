# Spring Beans 模块详细分析

> 基于记叙文6要素：时间、地点、人物、起因、经过、结果

---

## 模块概述

**模块定位**: Spring IoC 容器的核心实现
**核心本质**: 管理 Bean 的完整生命周期，从定义到实例化到依赖注入到销毁
**关键能力**: 依赖注入、循环依赖解决、扩展点机制
**设计精髓**: 模板方法模式 + 策略模式 + 责任链模式

---

## 一、Bean 完整生命周期

### 【时间】何时创建 Bean
- **容器启动时**: 所有非懒加载的单例 Bean
- **首次请求时**: 懒加载的单例 Bean 和原型 Bean
- **依赖注入时**: 作为其他 Bean 的依赖被触发创建

### 【地点】在哪里创建 Bean
- **入口位置**: `AbstractBeanFactory.getBean()` → `doGetBean()`
- **创建位置**: `AbstractAutowireCapableBeanFactory.createBean()` → `doCreateBean()`
- **容器类型**: `DefaultListableBeanFactory`（核心容器实现）

### 【人物】研究对象
- **核心对象**: Bean 实例（从 BeanDefinition 到完整对象的转变）
- **操作主体**: `AbstractAutowireCapableBeanFactory`（Bean 创建工厂）
- **参与者**: BeanDefinition、BeanWrapper、BeanPostProcessor、InstantiationStrategy
- **状态转换**: 元数据 → 原始实例 → 注入依赖 → 初始化完成 → 可用对象

### 【起因】为什么需要生命周期管理
- **依赖注入**: 需要先创建 Bean 实例才能注入依赖
- **初始化回调**: 需要在依赖注入后执行初始化逻辑
- **扩展点**: 提供多个阶段让开发者介入和定制
- **代理创建**: AOP 需要在初始化后创建代理对象

### 【经过】处理步骤（精炼）

#### 阶段1: Bean 检索入口
- **操作主体**: `AbstractBeanFactory.doGetBean()`
- **目标对象**: Bean 名称（String）
- **核心步骤**:
  1. 转换 Bean 名称（处理别名、FactoryBean 前缀）
  2. 检查单例缓存（三级缓存机制）
  3. 未找到则标记为"正在创建"
  4. 获取合并后的 BeanDefinition
  5. 初始化 depends-on 依赖的 Bean
  6. 根据作用域创建 Bean

#### 阶段2: 单例缓存检查（三级缓存）
- **操作主体**: `DefaultSingletonBeanRegistry.getSingleton()`
- **目标对象**: Bean 名称
- **三级缓存逻辑**:
  ```
  Level 1: singletonObjects (完全初始化的 Bean)
      ↓ 未找到 AND Bean 正在创建中
  Level 2: earlySingletonObjects (早期引用)
      ↓ 未找到 AND 允许早期引用
  Level 3: singletonFactories (ObjectFactory)
      ↓ 调用 factory.getObject()
  返回早期引用，并从 Level 3 移至 Level 2
  ```

#### 阶段3: Bean 创建入口
- **操作主体**: `AbstractAutowireCapableBeanFactory.createBean()`
- **目标对象**: BeanDefinition + 构造参数
- **核心步骤**:
  1. 解析 Bean 的 Class 对象
  2. 准备方法覆盖（lookup-method、replace-method）
  3. **关键点**: 调用 `postProcessBeforeInstantiation()`
     - 给 BeanPostProcessor 返回代理的机会
     - 如果返回非 null，短路整个创建流程
  4. 调用 `doCreateBean()` 执行实际创建

#### 阶段4: 实际 Bean 创建（核心流程）
- **操作主体**: `AbstractAutowireCapableBeanFactory.doCreateBean()`
- **目标对象**: BeanDefinition
- **详细步骤**:

**步骤 4.1 - 实例化**:
- **方法**: `createBeanInstance()`
- **策略选择**:
  - Supplier 回调
  - 工厂方法（factory-method）
  - 构造器自动装配（@Autowired 构造器）
  - 默认无参构造器
- **实例化策略**: `CglibSubclassingInstantiationStrategy`（默认）
- **结果**: `BeanWrapper` 包装的原始 Bean 实例

**步骤 4.2 - 处理合并 BeanDefinition**:
- **方法**: `applyMergedBeanDefinitionPostProcessors()`
- **时机**: 实例化后，属性注入前
- **作用**: `MergedBeanDefinitionPostProcessor` 缓存注入元数据
- **例子**: `AutowiredAnnotationBeanPostProcessor` 扫描并缓存 @Autowired 字段

**步骤 4.3 - 早期单例暴露（循环依赖）**:
- **条件**: 单例 + 允许循环引用 + 正在创建中
- **方法**: `addSingletonFactory(beanName, ObjectFactory)`
- **作用**: 将 ObjectFactory 添加到三级缓存
- **ObjectFactory 逻辑**: 调用 `getEarlyBeanReference()` 返回早期引用

**步骤 4.4 - 属性填充（依赖注入）**:
- **方法**: `populateBean()`
- **详细流程**: 见"二、依赖注入流程"

**步骤 4.5 - 初始化**:
- **方法**: `initializeBean()`
- **详细流程**: 见下文

**步骤 4.6 - 循环依赖检查**:
- **检查**: 获取早期单例引用
- **逻辑**: 如果早期引用被使用，用早期引用替换当前对象

**步骤 4.7 - 注册销毁回调**:
- **方法**: `registerDisposableBeanIfNecessary()`
- **作用**: 注册 DisposableBean 或 destroy-method

#### 阶段5: Bean 初始化详细步骤
- **操作主体**: `AbstractAutowireCapableBeanFactory.initializeBean()`
- **目标对象**: 已注入依赖的 Bean 实例
- **详细步骤**:

**步骤 5.1 - 调用 Aware 接口**:
- **方法**: `invokeAwareMethods()`
- **执行顺序**:
  1. `BeanNameAware.setBeanName()`
  2. `BeanClassLoaderAware.setBeanClassLoader()`
  3. `BeanFactoryAware.setBeanFactory()`

**步骤 5.2 - 初始化前处理**:
- **方法**: `applyBeanPostProcessorsBeforeInitialization()`
- **调用**: 所有 `BeanPostProcessor.postProcessBeforeInitialization()`
- **用途**:
  - `ApplicationContextAwareProcessor` 注入 ApplicationContext
  - `CommonAnnotationBeanPostProcessor` 执行 @PostConstruct

**步骤 5.3 - 初始化回调**:
- **方法**: `invokeInitMethods()`
- **执行顺序**:
  1. `InitializingBean.afterPropertiesSet()`（如果实现）
  2. 自定义 init-method（XML 或 @Bean(initMethod)）

**步骤 5.4 - 初始化后处理（关键）**:
- **方法**: `applyBeanPostProcessorsAfterInitialization()`
- **调用**: 所有 `BeanPostProcessor.postProcessAfterInitialization()`
- **关键用途**: **AOP 代理创建**
  - `AbstractAutoProxyCreator` 在此创建代理对象
  - 可以用代理对象替换原始 Bean

### 【结果】最终状态
- **单例 Bean**: 添加到 `singletonObjects`（一级缓存）
- **容器注册**: Bean 可通过 `getBean()` 或依赖注入获取
- **状态**: 完全初始化，依赖已注入，初始化回调已执行
- **可能状态**: 原始对象或代理对象（取决于是否有 AOP）

---

## 二、依赖注入流程

### 【时间】何时注入依赖
- **生命周期阶段**: 实例化后，初始化前
- **具体时机**: `doCreateBean()` 中的 `populateBean()` 阶段
- **注入时机差异**:
  - 构造器注入：实例化时
  - Setter/Field 注入：属性填充时

### 【地点】在哪里注入依赖
- **属性注入入口**: `AbstractAutowireCapableBeanFactory.populateBean()`
- **构造器注入**: `AbstractAutowireCapableBeanFactory.autowireConstructor()`
- **注解注入**: `AutowiredAnnotationBeanPostProcessor.postProcessProperties()`

### 【人物】研究对象
- **核心对象**: 待注入依赖的 Bean 实例
- **操作主体**: `AbstractAutowireCapableBeanFactory`、`AutowiredAnnotationBeanPostProcessor`
- **目标对象**: 依赖的 Bean（需要被注入的对象）
- **媒介**: `BeanWrapper`（属性访问）、`DependencyDescriptor`（依赖描述）

### 【起因】为什么需要依赖注入
- **控制反转**: 对象不负责创建依赖，由容器管理
- **松耦合**: 依赖接口而非具体实现
- **可测试性**: 便于 Mock 和单元测试
- **配置外部化**: 依赖关系在配置中声明

### 【经过】处理步骤（精炼）

#### 注入方式1: 构造器注入
- **操作主体**: `ConstructorResolver`
- **目标对象**: Bean 的构造器
- **核心步骤**:
  1. **确定候选构造器**:
     - 调用 `SmartInstantiationAwareBeanPostProcessor.determineCandidateConstructors()`
     - `AutowiredAnnotationBeanPostProcessor` 检测 @Autowired 构造器
  2. **解析构造器参数**:
     - 遍历每个参数类型
     - 调用 `resolveDependency()` 解析依赖
  3. **调用构造器**:
     - 通过 `InstantiationStrategy` 调用构造器
     - 返回实例化的对象

#### 注入方式2: Setter 注入（byName）
- **操作主体**: `AbstractAutowireCapableBeanFactory.autowireByName()`
- **目标对象**: Bean 的属性
- **核心步骤**:
  1. 获取未满足的非简单属性列表
  2. 遍历每个属性名称
  3. 调用 `getBean(propertyName)` 获取依赖 Bean
  4. 添加到 PropertyValues
  5. 注册依赖关系

#### 注入方式3: Setter 注入（byType）
- **操作主体**: `AbstractAutowireCapableBeanFactory.autowireByType()`
- **目标对象**: Bean 的属性
- **核心步骤**:
  1. 获取未满足的非简单属性列表
  2. 遍历每个属性，获取属性类型
  3. 创建 `DependencyDescriptor`
  4. 调用 `resolveDependency()` 按类型解析
  5. 添加到 PropertyValues

#### 注入方式4: 字段注入（@Autowired）
- **操作主体**: `AutowiredAnnotationBeanPostProcessor`
- **目标对象**: @Autowired 标注的字段
- **核心步骤**:
  1. **缓存阶段**（`postProcessMergedBeanDefinition()`）:
     - 扫描类中的 @Autowired 字段和方法
     - 构建 `InjectionMetadata` 并缓存
  2. **注入阶段**（`postProcessProperties()`）:
     - 获取缓存的注入元数据
     - 遍历每个注入点
     - 创建 `DependencyDescriptor`
     - 调用 `beanFactory.resolveDependency()`
     - 通过反射注入：`Field.set(bean, value)`

#### 依赖解析核心逻辑
- **方法**: `DefaultListableBeanFactory.resolveDependency()`
- **目标**: 根据类型和限定符查找匹配的 Bean
- **步骤**:
  1. 处理 Optional、ObjectFactory、Provider 等特殊类型
  2. 按类型查找候选 Bean（`getBeanNamesForType()`）
  3. 过滤候选 Bean（泛型匹配、@Qualifier）
  4. 确定主要候选：
     - @Primary 标注的 Bean
     - @Priority 优先级最高的
     - 名称匹配的
  5. 调用 `getBean()` 获取 Bean 实例

### 【结果】最终状态
- **属性状态**: Bean 的所有依赖字段/属性已被赋值
- **依赖关系**: 容器记录了 Bean 之间的依赖关系
- **依赖类型**: 可能是原始 Bean 或代理对象
- **后续阶段**: 进入初始化阶段

---

## 三、BeanPostProcessor 扩展机制

### 【时间】BeanPostProcessor 执行时机

**完整时间线**:
```
1. [实例化前]   postProcessBeforeInstantiation()    ← 可短路
2. [实例化]     Bean 实例创建
3. [合并定义]   postProcessMergedBeanDefinition()    ← 缓存元数据
4. [早期暴露]   ObjectFactory.getObject()
                 └→ getEarlyBeanReference()          ← 早期代理
5. [实例化后]   postProcessAfterInstantiation()     ← 可跳过属性填充
6. [属性处理]   postProcessProperties()              ← @Autowired 注入
7. [属性填充]   设置属性值
8. [初始化前]   postProcessBeforeInitialization()   ← @PostConstruct
9. [初始化]     afterPropertiesSet() + init-method
10. [初始化后]  postProcessAfterInitialization()    ← AOP 代理创建
11. [就绪]      Bean 可用
```

### 【地点】在哪里调用
- **实例化相关**: `AbstractAutowireCapableBeanFactory.createBean()` 及子方法
- **属性相关**: `AbstractAutowireCapableBeanFactory.populateBean()`
- **初始化相关**: `AbstractAutowireCapableBeanFactory.initializeBean()`

### 【人物】研究对象
- **核心对象**: BeanPostProcessor 实现类
- **目标对象**: 正在创建的 Bean 实例
- **关键实现**:
  - `AutowiredAnnotationBeanPostProcessor` - @Autowired 处理
  - `CommonAnnotationBeanPostProcessor` - @Resource, @PostConstruct 处理
  - `AbstractAutoProxyCreator` - AOP 代理创建
  - `ApplicationContextAwareProcessor` - Aware 接口注入

### 【起因】为什么需要 BeanPostProcessor
- **扩展点**: 提供介入 Bean 生命周期的机会
- **功能增强**: 在不修改 Bean 代码的情况下增强功能
- **注解处理**: 处理各种注解（@Autowired、@PostConstruct 等）
- **代理创建**: AOP 代理、事务代理等

### 【经过】关键扩展点（精炼）

#### 扩展点1: postProcessBeforeInstantiation（短路点）
- **接口**: `InstantiationAwareBeanPostProcessor`
- **时机**: Bean 实例化**之前**
- **操作主体**: 实现类（如 `AbstractAutoProxyCreator`）
- **目标对象**: Bean 的 Class 对象（尚未实例化）
- **特殊性**: 如果返回非 null，**短路整个 Bean 创建流程**
- **用途**:
  - 返回自定义的代理对象
  - 对象池化
  - 懒加载代理

#### 扩展点2: postProcessMergedBeanDefinition
- **接口**: `MergedBeanDefinitionPostProcessor`
- **时机**: 实例化后，属性填充前
- **目标对象**: 合并后的 BeanDefinition
- **用途**: **缓存注入元数据以提升性能**
- **示例**: `AutowiredAnnotationBeanPostProcessor` 扫描 @Autowired 字段

#### 扩展点3: getEarlyBeanReference（循环依赖）
- **接口**: `SmartInstantiationAwareBeanPostProcessor`
- **时机**: ObjectFactory 被调用时（循环依赖场景）
- **目标对象**: 刚实例化的原始 Bean
- **用途**: **提供早期代理引用**
- **关键**: AOP 代理可以在此阶段创建（而非初始化后）

#### 扩展点4: postProcessAfterInstantiation
- **接口**: `InstantiationAwareBeanPostProcessor`
- **时机**: 实例化后，属性填充前
- **目标对象**: 刚实例化的 Bean
- **返回值**: false 可跳过属性填充
- **用途**: 自定义字段注入

#### 扩展点5: postProcessProperties（注解注入）
- **接口**: `InstantiationAwareBeanPostProcessor`
- **时机**: 属性填充阶段
- **目标对象**: Bean 实例 + PropertyValues
- **用途**: **@Autowired、@Resource、@Inject 注入**
- **关键**: 这是注解驱动依赖注入的核心

#### 扩展点6: postProcessBeforeInitialization
- **接口**: `BeanPostProcessor`
- **时机**: 初始化回调**之前**
- **目标对象**: 已注入依赖的 Bean
- **用途**:
  - `ApplicationContextAwareProcessor` 注入容器相关接口
  - `CommonAnnotationBeanPostProcessor` 执行 **@PostConstruct**

#### 扩展点7: postProcessAfterInitialization（AOP 关键）
- **接口**: `BeanPostProcessor`
- **时机**: 初始化回调**之后**
- **目标对象**: 完全初始化的 Bean
- **用途**: **AOP 代理创建的核心位置**
- **关键实现**: `AbstractAutoProxyCreator`
- **说明**: 可以用代理对象替换原始 Bean

### 【结果】最终效果
- **Bean 增强**: 原始 Bean 被增强或替换为代理
- **注解处理**: 所有相关注解已被处理
- **扩展执行**: 所有注册的扩展逻辑已执行
- **灵活性**: 无需修改 Bean 代码即可增强功能

---

## 四、循环依赖解决方案

### 【时间】何时处理循环依赖
- **检测时机**: Bean 创建过程中请求另一个 Bean
- **暴露时机**: 实例化后立即暴露（通过三级缓存）
- **解决时机**: 依赖注入阶段获取早期引用

### 【地点】在哪里处理
- **缓存管理**: `DefaultSingletonBeanRegistry`
- **早期暴露**: `AbstractAutowireCapableBeanFactory.doCreateBean()`
- **获取引用**: `DefaultSingletonBeanRegistry.getSingleton()`

### 【人物】研究对象
- **核心对象**: 互相依赖的 Bean（A → B → A）
- **操作主体**: `DefaultSingletonBeanRegistry`
- **关键组件**:
  - `singletonObjects` - 一级缓存（完整 Bean）
  - `earlySingletonObjects` - 二级缓存（早期引用）
  - `singletonFactories` - 三级缓存（ObjectFactory）

### 【起因】为什么会有循环依赖
- **业务场景**: Service A 依赖 Service B，Service B 依赖 Service A
- **常见情况**: 双向关联的领域对象
- **设计问题**: 有时反映了设计上的耦合问题

### 【经过】解决步骤（精炼）

#### 三级缓存机制

**缓存定义**:
```java
// 一级缓存：完全初始化的单例 Bean
Map<String, Object> singletonObjects = new ConcurrentHashMap<>(256);

// 二级缓存：早期单例对象（尚未完全初始化）
Map<String, Object> earlySingletonObjects = new HashMap<>(16);

// 三级缓存：单例工厂（用于创建早期引用）
Map<String, ObjectFactory<?>> singletonFactories = new HashMap<>(16);
```

#### 循环依赖解决流程

**场景**: Bean A 依赖 Bean B，Bean B 依赖 Bean A

**时间点T1: 创建 Bean A**
```
步骤1: 标记 A 为"正在创建"
步骤2: 实例化 A（原始对象）
步骤3: 将 A 的 ObjectFactory 放入三级缓存
       ObjectFactory 逻辑: () -> getEarlyBeanReference(A)
步骤4: 开始填充 A 的属性
步骤5: 发现依赖 Bean B
步骤6: 调用 getBean(B)
```

**时间点T2: 创建 Bean B（A 创建中）**
```
步骤1: 标记 B 为"正在创建"
步骤2: 实例化 B（原始对象）
步骤3: 将 B 的 ObjectFactory 放入三级缓存
步骤4: 开始填充 B 的属性
步骤5: 发现依赖 Bean A
步骤6: 调用 getBean(A)
```

**时间点T3: 获取 Bean A（B 创建中）**
```
步骤1: 检查一级缓存 singletonObjects → null
步骤2: 检查 A 是否正在创建 → 是
步骤3: 检查二级缓存 earlySingletonObjects → null
步骤4: 检查三级缓存 singletonFactories → 找到 A 的 ObjectFactory
步骤5: 调用 factory.getObject() → 执行 getEarlyBeanReference(A)
       - 可能返回原始 A，也可能返回早期代理
步骤6: 将早期引用移至二级缓存
步骤7: 从三级缓存移除
步骤8: 返回 A 的早期引用给 B
```

**时间点T4: B 完成创建**
```
步骤1: B 使用 A 的早期引用完成属性填充
步骤2: B 执行初始化回调
步骤3: B 执行 postProcessAfterInitialization（可能被代理）
步骤4: B 被添加到一级缓存 singletonObjects
步骤5: B 从二级、三级缓存移除
步骤6: 返回完全初始化的 B
```

**时间点T5: A 完成创建**
```
步骤1: A 接收到完全初始化的 B
步骤2: A 完成属性填充
步骤3: A 执行初始化回调
步骤4: A 执行 postProcessAfterInitialization
步骤5: 检查是否使用了早期引用：
       - 从二级缓存获取 earlySingletonReference
       - 如果存在，使用早期引用替换当前对象
步骤6: A 被添加到一级缓存 singletonObjects
步骤7: A 从二级、三级缓存移除
步骤8: 返回完全初始化的 A
```

#### 为什么需要三级缓存？

**只用两级缓存的问题**:
- 如果 Bean 需要被代理（AOP），何时创建代理？
- 如果在早期暴露时就创建代理，**所有 Bean 都会被提前代理**（浪费）
- 如果在初始化后才创建代理，**循环依赖时注入的是原始对象**（错误）

**三级缓存的优势**:
- 三级缓存存储 ObjectFactory（惰性求值）
- 只有在**循环依赖发生时**才调用 factory.getObject()
- 只有**需要早期引用的 Bean** 才会提前创建代理
- 没有循环依赖的 Bean 在初始化后才创建代理（正常流程）

### 【结果】支持与限制

**支持的场景**:
- ✅ 单例 + Setter 注入
- ✅ 单例 + 字段注入（@Autowired）

**不支持的场景**:
- ❌ 原型作用域 + 任何注入方式
  - 原因：原型 Bean 不缓存，无法获取早期引用
  - 异常：`BeanCurrentlyInCreationException`
- ❌ 单例 + 构造器注入（大多数情况）
  - 原因：构造器注入在实例化时就需要依赖，无法暴露早期引用
  - 解决：使用 Setter 或 Field 注入

**配置开关**:
```java
// AbstractAutowireCapableBeanFactory
private boolean allowCircularReferences = true; // 可禁用
```

---

## 五、关键类职责矩阵

| 类名 | 操作时间 | 核心职责 | 关键方法 | 结果产出 |
|------|---------|---------|---------|---------|
| **BeanDefinition** | 容器初始化 | Bean 元数据容器 | 存储 class、scope、懒加载、依赖等信息 | Bean 的配置描述 |
| **DefaultListableBeanFactory** | 整个生命周期 | 核心容器实现 | getBean()、registerBeanDefinition()、<br>getBeanNamesForType() | Bean 实例、类型查找 |
| **AbstractBeanFactory** | Bean 检索时 | Bean 检索和缓存 | doGetBean()、getMergedBeanDefinition() | Bean 实例或缓存 |
| **AbstractAutowireCapableBeanFactory** | Bean 创建时 | Bean 创建和装配 | createBean()、doCreateBean()、<br>autowireByName/Type()、populateBean()、<br>initializeBean() | 完整 Bean 实例 |
| **DefaultSingletonBeanRegistry** | 单例管理 | 单例缓存和循环依赖 | getSingleton()、addSingleton()、<br>addSingletonFactory()、<br>beforeSingletonCreation() | 单例 Bean 实例 |
| **BeanWrapper** | 属性填充时 | 属性访问和转换 | setPropertyValue()、<br>getPropertyValue() | 属性已设置的 Bean |
| **InstantiationStrategy** | 实例化时 | 对象实例化策略 | instantiate() | 原始 Bean 实例 |
| **ConstructorResolver** | 构造器注入时 | 构造器参数解析 | autowireConstructor()、<br>resolveConstructorArguments() | 通过构造器创建的实例 |
| **DependencyDescriptor** | 依赖解析时 | 依赖描述符 | 描述依赖的类型、必需性、<br>泛型信息等 | 依赖元数据 |
| **AutowiredAnnotationBeanPostProcessor** | 属性填充时 | @Autowired 处理 | postProcessMergedBeanDefinition()、<br>postProcessProperties() | 注入完成的 Bean |
| **CommonAnnotationBeanPostProcessor** | 初始化前/属性填充 | @Resource, @PostConstruct | postProcessProperties()、<br>postProcessBeforeInitialization() | 注入和初始化完成 |
| **BeanPostProcessor** | Bean 生命周期各阶段 | Bean 扩展点 | postProcessBeforeInitialization()、<br>postProcessAfterInitialization() | 增强后的 Bean |

---

## 六、典型场景执行时序

### 场景1: 普通单例 Bean 创建（无循环依赖）

```
时间点1: 应用代码调用
  └─ 操作主体: 应用代码
  └─ 动作: applicationContext.getBean("userService")
  └─ 目标: 获取 UserService Bean

时间点2: Bean 检索入口
  └─ 操作主体: AbstractBeanFactory
  └─ 动作: doGetBean("userService")
  └─ 步骤:
      1. 转换 Bean 名称
      2. 检查单例缓存 → 未找到
      3. 标记为"正在创建"
      4. 获取合并 BeanDefinition
  └─ 决策: 需要创建 Bean

时间点3: 实例化阶段
  └─ 操作主体: AbstractAutowireCapableBeanFactory
  └─ 动作: createBeanInstance()
  └─ 步骤:
      1. 确定构造器（无 @Autowired，使用默认）
      2. 使用 CglibSubclassingInstantiationStrategy
      3. 调用无参构造器
  └─ 结果: BeanWrapper 包装的原始实例

时间点4: 早期暴露
  └─ 操作主体: AbstractAutowireCapableBeanFactory
  └─ 动作: addSingletonFactory()
  └─ 条件: 单例 + 允许循环引用 + 正在创建
  └─ 结果: ObjectFactory 添加到三级缓存

时间点5: 属性填充
  └─ 操作主体: AbstractAutowireCapableBeanFactory
  └─ 动作: populateBean()
  └─ 步骤:
      1. postProcessAfterInstantiation() → true（继续）
      2. postProcessProperties() → @Autowired 字段注入
         - 注入 userRepository
         - 调用 getBean("userRepository")
      3. applyPropertyValues() → 设置属性
  └─ 结果: 依赖已注入的 Bean

时间点6: 初始化阶段
  └─ 操作主体: AbstractAutowireCapableBeanFactory
  └─ 动作: initializeBean()
  └─ 步骤:
      1. invokeAwareMethods()
         - setBeanName("userService")
         - setBeanFactory(factory)
      2. postProcessBeforeInitialization()
         - ApplicationContextAwareProcessor 注入 context
         - 执行 @PostConstruct 方法
      3. invokeInitMethods()
         - 调用 afterPropertiesSet()（如果实现）
         - 调用 init-method（如果配置）
      4. postProcessAfterInitialization()
         - AbstractAutoProxyCreator 创建 AOP 代理
  └─ 结果: 完全初始化的 Bean（可能是代理）

时间点7: 添加到缓存
  └─ 操作主体: DefaultSingletonBeanRegistry
  └─ 动作: addSingleton("userService", bean)
  └─ 步骤:
      1. 添加到 singletonObjects（一级缓存）
      2. 从 singletonFactories 移除（三级缓存）
      3. 从 earlySingletonObjects 移除（二级缓存）
  └─ 结果: Bean 可被后续请求直接获取

时间点8: 返回给调用方
  └─ 操作主体: AbstractBeanFactory
  └─ 动作: 返回 Bean 实例
  └─ 结果: 应用代码获得可用的 UserService
```

---

### 场景2: 循环依赖 Bean 创建

```
背景: ServiceA 依赖 ServiceB，ServiceB 依赖 ServiceA

时间点1: 创建 ServiceA
  └─ 动作: getBean("serviceA")
  └─ 步骤:
      1. 实例化 ServiceA（原始对象）
      2. addSingletonFactory(A, () -> getEarlyBeanReference(A))
      3. 开始 populateBean(A)
      4. 发现依赖 ServiceB
      5. 调用 getBean("serviceB")

时间点2: 创建 ServiceB（A 创建中）
  └─ 动作: getBean("serviceB")
  └─ 步骤:
      1. 实例化 ServiceB（原始对象）
      2. addSingletonFactory(B, () -> getEarlyBeanReference(B))
      3. 开始 populateBean(B)
      4. 发现依赖 ServiceA
      5. 调用 getBean("serviceA") → **循环依赖发生**

时间点3: 获取 ServiceA 早期引用（B 创建中）
  └─ 动作: doGetBean("serviceA")
  └─ 步骤:
      1. 检查 singletonObjects → null
      2. 检查正在创建标记 → true
      3. 检查 earlySingletonObjects → null
      4. 检查 singletonFactories → 找到 A 的 factory
      5. 调用 factory.getObject()
         └─ 执行 getEarlyBeanReference(A)
         └─ SmartInstantiationAwareBeanPostProcessor 可能创建早期代理
      6. 将早期引用放入 earlySingletonObjects
      7. 从 singletonFactories 移除
  └─ 结果: B 获得 A 的早期引用（可能是代理）

时间点4: ServiceB 完成创建
  └─ 步骤:
      1. B 使用 A 的早期引用完成属性填充
      2. initializeBean(B)
         - 执行 Aware、@PostConstruct、init-method
         - postProcessAfterInitialization() 可能创建 B 的代理
      3. addSingleton("serviceB", B)
  └─ 结果: B 完全初始化，添加到一级缓存

时间点5: ServiceA 完成创建
  └─ 步骤:
      1. A 接收完全初始化的 B
      2. A 完成属性填充
      3. initializeBean(A)
      4. 检查早期引用:
         - 从 earlySingletonObjects 获取
         - 如果存在且未被修改，使用早期引用
      5. addSingleton("serviceA", A)
  └─ 结果: A 完全初始化，添加到一级缓存

时间点6: 返回结果
  └─ 结果:
      - ServiceA 和 ServiceB 都完全初始化
      - 互相持有对方的引用
      - 如果有 AOP，持有的是代理对象
```

---

## 七、核心设计模式

### 1. 工厂模式 (Factory Pattern)
- **应用**: `BeanFactory` 接口层次
- **实现**: `DefaultListableBeanFactory`
- **目的**: 统一 Bean 创建接口

### 2. 模板方法模式 (Template Method)
- **应用**: `AbstractBeanFactory`、`AbstractAutowireCapableBeanFactory`
- **体现**: 定义算法骨架，子类实现具体步骤
- **示例**: `doGetBean()` 定义检索流程，子类实现 `createBean()`

### 3. 策略模式 (Strategy Pattern)
- **应用**: `InstantiationStrategy`
- **实现**: `SimpleInstantiationStrategy`、`CglibSubclassingInstantiationStrategy`
- **目的**: 可插拔的实例化策略

### 4. 单例模式 (Singleton Pattern)
- **应用**: 单例 Bean 管理
- **实现**: `DefaultSingletonBeanRegistry` 的三级缓存
- **保证**: 容器范围内的单例

### 5. 适配器模式 (Adapter Pattern)
- **应用**: `BeanWrapper`
- **目的**: 统一不同 Bean 的属性访问方式

### 6. 责任链模式 (Chain of Responsibility)
- **应用**: `BeanPostProcessor` 链式调用
- **实现**: 遍历所有 BeanPostProcessor 依次处理
- **示例**: `applyBeanPostProcessorsBeforeInitialization()`

### 7. 观察者模式 (Observer Pattern)
- **应用**: Bean 生命周期回调
- **实现**: `BeanPostProcessor`、Aware 接口
- **目的**: 解耦 Bean 创建和扩展逻辑

---

## 八、性能优化要点

### 1. 元数据缓存
- **位置**: `MergedBeanDefinitionPostProcessor`
- **缓存内容**: @Autowired 字段、@PostConstruct 方法
- **效果**: 避免每次创建 Bean 都反射扫描

### 2. 单例缓存
- **位置**: `DefaultSingletonBeanRegistry`
- **缓存内容**: 完全初始化的单例 Bean
- **效果**: 单例 Bean 只创建一次

### 3. 类型查找缓存
- **位置**: `DefaultListableBeanFactory`
- **缓存内容**: 类型到 Bean 名称的映射
- **效果**: 加速 `getBeanNamesForType()` 查询

### 4. BeanWrapper 缓存
- **位置**: `CachedIntrospectionResults`
- **缓存内容**: Bean 的 PropertyDescriptor
- **效果**: 避免重复内省

---

## 九、常见问题

### Q1: 为什么构造器循环依赖无法解决？
**答**: 构造器注入在实例化时就需要依赖，而早期暴露发生在实例化后。无法在实例化前暴露早期引用。

### Q2: 三级缓存能简化为两级吗？
**答**: 不建议。两级缓存会导致所有 Bean 在早期暴露时就创建代理，影响性能。三级缓存通过 ObjectFactory 实现惰性代理创建。

### Q3: 为什么 @Autowired 比 XML autowire 常用？
**答**:
- @Autowired 更灵活（字段、方法、构造器）
- 支持 required=false
- 支持 @Qualifier 限定
- 代码即文档

### Q4: BeanPostProcessor 的执行顺序如何控制？
**答**: 实现 `Ordered` 或 `PriorityOrdered` 接口，通过 `getOrder()` 返回优先级。

---

## 十、关键源码位置

| 功能 | 核心类 | 关键方法 |
|------|--------|---------|
| Bean 检索入口 | AbstractBeanFactory | doGetBean() |
| Bean 创建 | AbstractAutowireCapableBeanFactory | createBean(), doCreateBean() |
| 实例化 | AbstractAutowireCapableBeanFactory | createBeanInstance() |
| 属性填充 | AbstractAutowireCapableBeanFactory | populateBean() |
| 初始化 | AbstractAutowireCapableBeanFactory | initializeBean() |
| 单例缓存 | DefaultSingletonBeanRegistry | getSingleton(), addSingleton() |
| 循环依赖 | DefaultSingletonBeanRegistry | addSingletonFactory() |
| 依赖解析 | DefaultListableBeanFactory | resolveDependency() |
| @Autowired 处理 | AutowiredAnnotationBeanPostProcessor | postProcessProperties() |
| 构造器解析 | ConstructorResolver | autowireConstructor() |

---

## 总结

### 核心本质
Spring Beans 模块的核心本质是：**通过 IoC 容器管理 Bean 的完整生命周期，实现依赖注入和控制反转，提供灵活的扩展点机制**

### 关键要素
1. **【时间】何时**: 容器启动或首次请求时创建，整个生命周期贯穿多个阶段
2. **【地点】何地**: AbstractBeanFactory（检索）→ AbstractAutowireCapableBeanFactory（创建）→ DefaultSingletonBeanRegistry（缓存）
3. **【人物】何人**: BeanFactory 体系（容器）、BeanPostProcessor（扩展）、Bean 实例（管理对象）
4. **【起因】为何**: 实现控制反转、解耦依赖、提供统一的对象生命周期管理
5. **【经过】如何**: 定义 → 实例化 → 属性注入 → 初始化 → 使用 → 销毁
6. **【结果】结果**: 完全初始化的 Bean（可能是代理），依赖已注入，可在容器中使用

### 设计精髓
- **模板方法**: 定义清晰的生命周期阶段
- **扩展点**: BeanPostProcessor 提供灵活的介入时机
- **三级缓存**: 优雅解决循环依赖问题
- **策略模式**: 可插拔的实例化和注入策略
- **职责分离**: 创建、缓存、依赖解析各司其职

---

**文档生成时间**: 2025-11-25
**Spring Framework 版本**: 5.2.3.RELEASE
**分析深度**: 精炼核心，聚焦本质
