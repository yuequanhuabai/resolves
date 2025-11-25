# Spring-Expression 模块：六要素详细分析

## 概述
本文档采用记叙文"六要素"（时间、地点、人物、起因、经过、结果）来分析 spring-expression 模块的代码运作流程，力求精炼本质、去除冗余细节。

**核心定位**：Spring Expression Language (SpEL) 实现，为应用提供强大的动态表达式解析和求值能力。

**模块规模**：118 Java 文件，6 个主要功能域

---

## 一级主题：模块全景

### 1. 模块属性与职责定位

#### 时间维度
- **解析期**：应用开发时或运行时解析表达式字符串
- **编译期**：首次执行或手动触发时编译为字节码
- **运行期**：频繁执行表达式求值

#### 空间维度

**代码组织**（118 个文件）：
```
org.springframework.expression.
├── 【顶层接口】(22 个)
│   ├── Expression             (表达式接口)
│   ├── ExpressionParser       (解析器接口)
│   ├── EvaluationContext      (求值上下文)
│   ├── PropertyAccessor       (属性访问)
│   ├── MethodResolver         (方法解析)
│   ├── TypeConverter          (类型转换)
│   └── ...
├── common/                    (6 个通用类)
│   ├── TemplateAwareExpressionParser
│   ├── CompositeStringExpression
│   └── LiteralExpression
└── spel/                      (90+ 个 SpEL 实现)
    ├── SpelExpression         (核心实现)
    ├── ExpressionState        (求值状态)
    ├── ast/                   (60+ 个 AST 节点)
    ├── standard/              (解析器)
    └── support/               (标准实现)
```

#### 人物（操作主体与对象）

| 阶段 | 操作主体 | 处理对象 | 目标产物 |
|------|--------|--------|--------|
| **解析** | SpelExpressionParser | 表达式字符串 | SpelExpression (含 AST) |
| **编译** | SpelCompiler | AST 节点树 | 字节码 CompiledExpression |
| **求值** | SpelExpression | EvaluationContext | 求值结果 |
| **访问** | PropertyAccessor / MethodResolver | 对象属性/方法 | 值或执行结果 |

---

## 二级主题：表达式解析流程

### 2. 表达式解析流程（字符串 → AST）

#### 时间
应用调用 `parseExpression()` 时

#### 地点
关键类：`SpelExpressionParser`、`InternalSpelExpressionParser`、`Tokenizer`
- 包：`org.springframework.expression.spel.standard`

#### 人物

**操作主体**：SpelExpressionParser（解析器入口）

**操作目标对象**：
- 表达式字符串
- Token 流
- AST 节点

#### 起因

应用需要将字符串形式的动态表达式转化为可执行的程序结构（AST），以便多次高效地求值。

#### 经过（5 个处理步骤）

**步骤 1：词法分析（字符 → Token）**
```
Tokenizer.process(expression)
  ├─ 逐字符扫描表达式
  ├─ 识别关键字、运算符、字面量、标识符等
  ├─ 记录每个 Token 的位置和数据
  └─ 生成 Token 流: [Token, Token, Token, ...]

例：expression = "person.age > 18"
    Token 流：[IDENTIFIER(person), DOT(.), IDENTIFIER(age), GT(>), INT(18)]
```

**步骤 2：语法分析（Token 流 → AST，使用递归下降解析）**
```
InternalSpelExpressionParser.doParseExpression()
  ├─ eatExpression()              - 解析完整表达式
  ├─ eatLogicalOrExpression()     - 解析 || (优先级最低)
  ├─ eatLogicalAndExpression()    - 解析 &&
  ├─ eatEqualityExpression()      - 解析 ==, !=
  ├─ eatRelationalExpression()    - 解析 <, >, <=, >=, instanceof
  ├─ eatAdditiveExpression()      - 解析 +, -
  ├─ eatMultiplicativeExpression()- 解析 *, /, %
  ├─ eatUnaryExpression()         - 解析 !, -, +
  ├─ eatPower()                   - 解析 ^
  ├─ eatPostfixExpression()       - 解析后缀 (++, --, [], ())
  └─ eatPrimary()                 - 解析主表达式 (字面量、引用等)
```

**步骤 3：构建 AST 节点**
```
根据语法分析结果创建相应的 AST 节点：

字面量节点：
  └─ IntLiteral, LongLiteral, StringLiteral, BooleanLiteral, NullLiteral

引用节点：
  ├─ PropertyOrFieldReference  (属性/字段)
  ├─ MethodReference           (方法)
  ├─ VariableReference         (#变量)
  ├─ FunctionReference         (#函数)
  ├─ BeanReference             (@bean)
  ├─ TypeReference             (T(type))
  └─ Identifier

运算符节点：
  ├─ OpPlus, OpMinus, OpMultiply, OpDivide, OpModulus (算术)
  ├─ OpEQ, OpNE, OpLT, OpLE, OpGT, OpGE (比较)
  ├─ OpAnd, OpOr, OperatorNot (逻辑)
  ├─ OperatorInstanceof, OperatorMatches, OperatorBetween (特殊)
  └─ OpInc, OpDec (递增/递减)

复合节点：
  ├─ CompoundExpression     (链式调用)
  ├─ Ternary               (三元运算符)
  ├─ Elvis                 (Elvis 运算符 ?:)
  ├─ Assign                (赋值)
  └─ Indexer               (索引)

集合操作节点：
  ├─ Selection             (选择 ?[])
  ├─ Projection            (投影 !{})
  ├─ InlineList            (列表字面量 {})
  └─ InlineMap             (Map 字面量)
```

**步骤 4：优先级处理**
```
通过递归下降的方法，高优先级的操作在低优先级之前被处理。
例：1 + 2 * 3
  ├─ AdditiveExpression
  │  ├─ MultiplicativeExpression (2 * 3 被先处理)
  │  └─ Literal(1)

二元运算符树的构建是左结合的：
例：1 + 2 + 3
  └─ OpPlus
     ├─ OpPlus
     │  ├─ Literal(1)
     │  └─ Literal(2)
     └─ Literal(3)
```

**步骤 5：优化和缓存**
```
- 短路运算符 (&&, ||) 标记为短路计算
- 记录节点在原表达式中的位置（用于错误报告）
- 为常见操作（属性访问、方法调用）预留缓存空间
- 返回 SpelExpression 对象，内部包含 AST 根节点
```

#### 结果

表达式字符串已解析为 `SpelExpression` 对象，内部包含完整的 AST 树，可重复执行求值。

---

### 3. 表达式编译与缓存

#### 时间
表达式被执行 100+ 次时（MIXED 模式）

#### 地点
关键类：`SpelExpression`、`SpelCompiler`
- 包：`org.springframework.expression.spel.standard`

#### 人物

**操作主体**：SpelCompiler（编译器）

**操作目标对象**：
- AST 节点树
- 字节码生成工具（ASM）
- ClassLoader

#### 起因

重复执行的表达式通过解释执行会有性能开销。编译为字节码可提升性能 10-50 倍。

#### 经过（5 个处理步骤）

**步骤 1：触发条件检查**
```
SpelExpression.getValue() 执行时：
  ├─ 检查 compiledAst 是否已存在
  │  └─ 若存在，直接使用编译版本
  │
  ├─ 检查编译模式
  │  ├─ OFF 模式: 不尝试编译
  │  ├─ IMMEDIATE 模式: 首次执行时编译
  │  └─ MIXED 模式: 执行 100+ 次后编译
  │
  └─ 累计执行计数器
     ├─ interpretedCount++
     └─ 当 interpretedCount > 100 时，尝试编译
```

**步骤 2：编译尝试**
```
SpelCompiler.compile(rootNode)
  ├─ 生成 AST 遍历计划
  ├─ 使用 ASM 生成字节码
  │  ├─ 定义类（类名：Expression_N）
  │  ├─ 定义 getValue() 方法
  │  ├─ 生成方法体字节码指令
  │  └─ 调用对象方法、属性访问等转为字节码
  │
  ├─ 编译失败处理
  │  ├─ 捕获编译异常
  │  ├─ failedAttempts++
  │  ├─ 若 failedAttempts >= 100，放弃编译
  │  └─ 继续解释执行
  │
  └─ 编译成功
     ├─ 加载字节码到 ClassLoader
     ├─ 创建 CompiledExpression 实例
     └─ 缓存到 compiledAst
```

**步骤 3：编译选择**
```
不是所有 AST 节点都可编译：
  ├─ 可编译: 字面量、简单属性访问、基本运算符、方法调用
  └─ 不可编译: 动态代理对象、自定义 PropertyAccessor 等
     └─ 若遇到不可编译的节点，放弃编译，继续解释执行
```

**步骤 4：缓存管理**
```
compiledAst 字段：
  ├─ 类型: volatile CompiledExpression
  ├─ 线程安全: 使用 volatile 和双重检查
  └─ 一旦缓存，后续执行直接使用
```

**步骤 5：性能差异**
```
编译 vs 解释执行性能对比：
  - 首次调用: 编译版本稍慢（编译开销）
  - 100+ 次调用后: 编译版本快 10-50 倍
  - 应用场景: 配置加载时使用频繁的表达式
```

#### 结果

表达式被编译为字节码并缓存，后续执行直接调用编译版本，性能大幅提升。

---

## 三级主题：表达式求值流程

### 4. 表达式求值核心流程

#### 时间
调用 `expression.getValue()` 时

#### 地点
关键类：`SpelExpression`、`ExpressionState`、SpelNode 实现类
- 包：`org.springframework.expression.spel`

#### 人物

**操作主体**：SpelExpression（执行控制器）

**操作目标对象**：
- EvaluationContext（求值上下文）
- 根对象（root object）
- AST 节点

#### 起因

应用需要执行已解析的表达式，获得求值结果。

#### 经过（6 个处理步骤）

**步骤 1：准备求值状态**
```
Expression.getValue(EvaluationContext context, Object rootObject)
  ├─ 创建 ExpressionState 对象
  │  ├─ rootObject 被包装为 TypedValue
  │  ├─ 初始化变量作用域
  │  └─ 初始化上下文对象栈
  │
  └─ ExpressionState 字段
     ├─ relatedContext: EvaluationContext 引用
     ├─ rootObject: TypedValue
     ├─ contextObjects: Deque<TypedValue> (对象栈)
     ├─ variableScopes: Deque<VariableScope> (作用域栈)
     └─ scopeRootObjects: ArrayDeque<TypedValue>
```

**步骤 2：选择执行路径**
```
if (compiledAst != null) {
    // 使用编译版本
    return compiledAst.getValue(context, rootObject);
} else if (useCompilation) {
    // 尝试编译（见前面的编译流程）
    return compiledAst.getValue(...);
} else {
    // 解释执行
    return ast.getValue(state);
}
```

**步骤 3：递归求值 AST（解释执行）**
```
rootNode.getValue(state)
  ├─ 根据节点类型分派到不同的求值逻辑：
  │
  ├─ 【字面量节点】
  │  └─ return literalValue  (直接返回)
  │
  ├─ 【属性引用节点】PropertyOrFieldReference
  │  ├─ 评估前缀表达式 (如果存在)
  │  ├─ 从 state 获取当前对象
  │  ├─ 遍历 context.getPropertyAccessors()
  │  ├─ 调用 accessor.canRead() 检查
  │  ├─ 调用 accessor.read() 读取属性
  │  ├─ 缓存该 accessor 用于下次优化
  │  └─ return 读取的值
  │
  ├─ 【方法引用节点】MethodReference
  │  ├─ 递归评估所有参数表达式
  │  ├─ 从 state 获取方法执行器
  │  ├─ 遍历 context.getMethodResolvers()
  │  ├─ 进行方法匹配和选择
  │  │  ├─ 检查参数个数
  │  │  ├─ 检查参数类型兼容性
  │  │  ├─ 必要时调用 TypeConverter 转换参数
  │  │  └─ 使用距离计算选择最佳匹配
  │  ├─ 缓存选中的 MethodExecutor
  │  ├─ 执行方法 executor.execute(context, target, args)
  │  └─ return 方法返回值
  │
  ├─ 【变量引用节点】VariableReference
  │  └─ return context.lookupVariable(name)
  │
  ├─ 【运算符节点】Operator
  │  ├─ 递归评估左操作数 (必需)
  │  ├─ 若是短路运算符 (&&, ||)
  │  │  └─ 根据左值决定是否评估右操作数
  │  ├─ 递归评估右操作数
  │  ├─ 调用 state.operate(operator, leftValue, rightValue)
  │  ├─ 进行类型转换和类型提升 (如需要)
  │  └─ return 运算结果
  │
  ├─ 【索引节点】Indexer
  │  ├─ 评估对象表达式
  │  ├─ 评估索引表达式
  │  ├─ 根据对象类型分别处理
  │  │  ├─ Array: ArrayIndexOf()
  │  │  ├─ List: List.get(index)
  │  │  ├─ Map: Map.get(key)
  │  │  ├─ String: String.charAt(index)
  │  │  └─ 支持范围切片: [start:end]
  │  └─ return 索引的元素
  │
  ├─ 【集合选择节点】Selection
  │  ├─ 评估集合表达式
  │  ├─ 遍历集合元素
  │  ├─ 对每个元素
  │  │  ├─ 创建新的变量作用域
  │  │  ├─ 设置 #this 引用当前元素
  │  │  ├─ 评估选择条件表达式
  │  │  ├─ 若条件为真，保留该元素
  │  │  └─ 弹出作用域
  │  └─ return 筛选后的集合
  │
  ├─ 【集合投影节点】Projection
  │  ├─ 评估集合表达式
  │  ├─ 遍历集合元素
  │  ├─ 对每个元素
  │  │  ├─ 创建新的变量作用域
  │  │  ├─ 设置 #this 引用当前元素
  │  │  ├─ 评估投影表达式
  │  │  ├─ 收集转换后的值
  │  │  └─ 弹出作用域
  │  └─ return 投影后的集合
  │
  └─ 【三元和 Elvis 节点】
     ├─ Ternary: 评估条件，返回真/假分支结果
     └─ Elvis: 评估左操作数，为 null 时返回右操作数
```

**步骤 4：类型转换（如果需要）**
```
若 getValue() 请求了特定返回类型 T：
  ├─ 若结果已是 T 类型，直接返回
  └─ 否则调用 context.getTypeConverter().convertValue()
     ├─ StandardTypeConverter 委托给 Spring 的 ConversionService
     ├─ 进行类型转换
     └─ return 转换后的值
```

**步骤 5：异常处理**
```
若求值过程中发生异常：
  ├─ 捕获反射异常、类型转换异常等
  ├─ 转换为 SpelEvaluationException
  ├─ 包含原始表达式和错误位置信息
  └─ throw 给调用者
```

**步骤 6：返回结果**
```
return result  (可能需要类型转换后)
```

#### 结果

表达式被求值，返回结果。若多次执行，后续可能使用编译版本以加速。

---

### 5. 属性访问与方法调用

#### 时间
求值过程中访问对象属性或调用方法时

#### 地点
关键类：`ReflectivePropertyAccessor`、`ReflectiveMethodResolver`、`ReflectiveMethodExecutor`
- 包：`org.springframework.expression.spel.support`

#### 人物

**操作主体**：PropertyAccessor / MethodResolver（反射代理）

**操作目标对象**：
- 目标对象
- 属性名称 / 方法名称
- 参数列表

#### 起因

表达式中的属性访问和方法调用需要通过反射来执行。需要缓存机制以减少反射开销。

#### 经过（5 个处理步骤）

**步骤 1：属性访问流程**
```
PropertyAccessor.read(context, target, propertyName)
  ├─ 检查缓存
  │  ├─ PropertyCacheKey = (target.class, propertyName)
  │  ├─ 若缓存存在，使用缓存的 InvokerPair
  │  └─ 若缓存未命中，继续
  │
  ├─ 尝试 getter 方法
  │  ├─ 查找 getProperty() 或 isProperty()
  │  ├─ 若找到，调用 method.invoke(target)
  │  └─ 缓存该方法
  │
  ├─ 若无 getter，尝试 public 字段
  │  ├─ 查找 public 字段
  │  ├─ 若找到，调用 field.get(target)
  │  └─ 缓存该字段
  │
  └─ return 属性值
```

**步骤 2：方法解析和匹配**
```
MethodResolver.resolve(context, target, methodName, argumentTypes)
  ├─ 检查缓存
  │  ├─ MethodCacheKey = (target.class, methodName, argumentTypes)
  │  ├─ 若缓存存在，返回缓存的 MethodExecutor
  │  └─ 若缓存未命中，继续
  │
  ├─ 查找候选方法
  │  ├─ 获取 target.class 的所有方法
  │  ├─ 按名称过滤 (methodName 匹配)
  │  └─ 得到候选方法列表
  │
  ├─ 进行方法选择（考虑参数兼容性）
  │  ├─ 参数个数必须匹配
  │  ├─ 参数类型检查
  │  │  ├─ 精确匹配 (type == argumentType)
  │  │  ├─ 自动装箱/拆箱 (int ↔ Integer)
  │  │  ├─ 子类匹配 (subclass → superclass)
  │  │  └─ 使用 TypeConverter 进行转换
  │  │
  │  ├─ 使用距离计算选择最佳匹配
  │  │  ├─ 精确匹配距离 = 0
  │  │  ├─ 自动装箱距离 = 1
  │  │  ├─ 继承链距离 = 深度
  │  │  └─ 选择距离最小的方法
  │  │
  │  └─ 若有多个同样距离的方法，抛异常
  │
  ├─ 创建 MethodExecutor
  │  └─ ReflectiveMethodExecutor(method, varargsPosition)
  │
  ├─ 缓存 MethodExecutor
  │  └─ methodCache.put(key, executor)
  │
  └─ return MethodExecutor
```

**步骤 3：参数转换**
```
若参数类型不完全匹配，需要类型转换：
  ├─ 对每个参数
  │  ├─ 获取参数的实际类型
  │  ├─ 与方法期望的参数类型比较
  │  ├─ 若不匹配，调用 TypeConverter.convertValue()
  │  └─ 转换参数
  │
  └─ 使用转换后的参数调用方法
```

**步骤 4：方法执行**
```
MethodExecutor.execute(context, target, arguments)
  └─ ReflectiveMethodExecutor.execute()
     ├─ 处理可变参数 (varargs)
     │  └─ 若是可变参数方法，将尾部参数转为数组
     │
     ├─ 调用 method.invoke(target, arguments)
     │  └─ 必要时设置访问权限 (setAccessible(true))
     │
     ├─ 处理返回值
     │  ├─ 包装为 TypedValue (含类型信息)
     │  └─ 若返回值为 null，TypedValue 包含 null 类型
     │
     └─ return TypedValue
```

**步骤 5：缓存优化**
```
三层缓存加速性能：
  1. PropertyAccessor 缓存 (类, 属性名) → (getter/field)
  2. MethodResolver 缓存 (类, 方法名, 参数类型) → Method
  3. TypeDescriptor 缓存 (类, 属性名) → 属性类型描述

缓存命中率通常 > 95%，后续访问相同属性/方法时避免反射开销
```

#### 结果

属性被读取或方法被执行，返回结果（可能需要类型转换）。

---

## 四级主题：运算符和操作

### 6. 运算符求值

#### 时间
表达式包含运算符时

#### 地点
关键类：Operator 抽象类及其 21 个子类实现
- 包：`org.springframework.expression.spel.ast`

#### 人物

**操作主体**：各个 Operator 实现（运算逻辑执行者）

**操作目标对象**：
- 左操作数
- 右操作数

#### 起因

表达式需要支持各种运算符计算（算术、比较、逻辑等）。

#### 经过（4 个处理步骤）

**步骤 1：操作数评估**
```
对于二元运算符 (BinaryOperator):
  ├─ 递归评估左操作数
  ├─ 对于短路运算符 (&&, ||)
  │  └─ 根据左值决定是否评估右操作数
  └─ 递归评估右操作数
```

**步骤 2：类型提升与转换**
```
对于算术运算符 (+, -, *, /, %):
  ├─ 分析左右操作数的类型
  ├─ 进行类型提升 (如 int + double → double)
  ├─ 对于 + 运算符，支持字符串拼接
  └─ 必要时调用 TypeConverter 转换

对于比较运算符 (<, >, <=, >=, ==, !=):
  ├─ 使用 StandardTypeComparator 进行比较
  ├─ 支持数字、字符串、Comparable 等比较
  ├─ 对于 == 和 !=，支持 null 值比较
  └─ return boolean 结果

对于逻辑运算符 (&&, ||, !):
  ├─ 评估操作数为 boolean
  └─ 执行逻辑运算
```

**步骤 3：运算符重载**
```
对于特殊运算符 (instanceof, matches, between):
  ├─ instanceof: 检查对象是否为指定类型
  ├─ matches: 对字符串执行正则表达式匹配
  └─ between: 检查值是否在范围内

对于自定义运算符重载:
  └─ OperatorOverloader.operatorSupported()
```

**步骤 4：返回结果**
```
return 运算结果 (类型对应运算符)
  ├─ 算术运算: 数字类型
  ├─ 比较运算: boolean
  ├─ 逻辑运算: boolean
  └─ 其他: 取决于运算符实现
```

#### 结果

两个操作数被运算，返回结果。

---

### 7. 集合操作（选择和投影）

#### 时间
表达式包含集合操作时

#### 地点
关键类：`Selection`（选择）、`Projection`（投影）
- 包：`org.springframework.expression.spel.ast`

#### 人物

**操作主体**：Selection / Projection 节点

**操作目标对象**：
- 集合对象
- 每个元素
- 选择条件 / 投影表达式

#### 起因

应用需要对集合进行过滤（选择）或变换（投影）。

#### 经过（5 个处理步骤）

**步骤 1：集合选择（Selection, ?[]）**
```
Expression: list.?[age > 18]

Selection.getValue(state)
  ├─ 评估 list 集合表达式
  ├─ 创建结果集合 (与原集合类型相同)
  ├─ 遍历每个元素
  │  ├─ 创建新的变量作用域
  │  │  └─ push(VariableScope) 将新作用域压入栈
  │  │
  │  ├─ 设置 #this 变量
  │  │  └─ context.setVariable("#this", element)
  │  │
  │  ├─ 评估选择条件表达式 (age > 18)
  │  │  └─ 该表达式中的 #this 引用当前元素
  │  │
  │  ├─ 若条件为真，添加到结果集合
  │  │  └─ result.add(element)
  │  │
  │  └─ 弹出作用域
  │     └─ pop(VariableScope)
  │
  └─ return 结果集合
```

**步骤 2：集合投影（Projection, !{}）**
```
Expression: list.!{name}

Projection.getValue(state)
  ├─ 评估 list 集合表达式
  ├─ 创建结果集合
  ├─ 遍历每个元素
  │  ├─ 创建新的变量作用域
  │  ├─ 设置 #this 变量
  │  ├─ 评估投影表达式 (name)
  │  │  └─ 该表达式中的 #this.name 被评估
  │  ├─ 将结果值添加到结果集合
  │  └─ 弹出作用域
  │
  └─ return 转换后的集合
```

**步骤 3：作用域隔离**
```
作用域栈管理:
  ├─ 每次进入选择/投影时，push 新作用域
  ├─ #this 仅在当前作用域有效
  ├─ 外层变量仍可访问（向上查询）
  └─ 离开选择/投影时，pop 作用域

例：
  #list.?[#condition(#this)]
  - 外层可访问 #list, #condition
  - 选择内部可访问 #this (当前元素)
  - 选择完成后，#this 不再有效
```

**步骤 4：特殊选择变体**
```
Selection 支持三种变体：
  └─ 根据前缀判断
     ├─ ?[] - Selection.FIRST_MANY (所有匹配)
     ├─ ^[] - Selection.FIRST_ONE (第一个匹配)
     └─ $[] - Selection.LAST_ONE (最后一个匹配)
```

**步骤 5：性能优化**
```
- 缓存投影结果集合类型（ArrayList, HashSet 等）
- 预分配集合容量（如果可知大小）
- 避免重复的作用域创建
```

#### 结果

集合被过滤（选择）或转换（投影），返回新集合。

---

## 五级主题：求值上下文与环境

### 8. 求值上下文管理

#### 时间
创建和使用表达式求值上下文时

#### 地点
关键类：`StandardEvaluationContext`、`SimpleEvaluationContext`、`ExpressionState`
- 包：`org.springframework.expression.spel.support`

#### 人物

**操作主体**：EvaluationContext（上下文管理器）

**操作目标对象**：
- 根对象
- 属性访问器列表
- 方法解析器列表
- 变量存储
- 类型系统

#### 起因

表达式求值需要一个完整的运行环境，包含对象、变量、类型转换等信息。

#### 经过（5 个处理步骤）

**步骤 1：创建求值上下文**
```
StandardEvaluationContext context = new StandardEvaluationContext(rootObject);

初始化默认组件：
  ├─ PropertyAccessor: [ReflectivePropertyAccessor]
  ├─ ConstructorResolver: [ReflectiveConstructorResolver]
  ├─ MethodResolver: [ReflectiveMethodResolver]
  ├─ TypeConverter: StandardTypeConverter (委托 ConversionService)
  ├─ TypeComparator: StandardTypeComparator
  ├─ OperatorOverloader: StandardOperatorOverloader
  ├─ TypeLocator: StandardTypeLocator
  ├─ BeanResolver: null (可选)
  └─ 变量存储: ConcurrentHashMap<String, Object>
```

**步骤 2：设置变量**
```
context.setVariable("minAge", 18)
context.setVariable("status", "ACTIVE")

变量存储：
  ├─ HashMap 存储变量名 → 值
  ├─ 支持任意 Object 值
  ├─ 线程安全 (ConcurrentHashMap)
  └─ 表达式中用 #变量名 引用
```

**步骤 3：自定义访问器和解析器**
```
// 注册自定义属性访问器
context.addPropertyAccessor(customAccessor);

// 注册自定义方法解析器
context.addMethodResolver(customResolver);

// 注册自定义构造器解析器
context.addConstructorResolver(customConstructorResolver);

// 注册 Bean 解析器
context.setBeanResolver(customBeanResolver);

// 设置自定义类型转换器
context.setTypeConverter(customTypeConverter);
```

**步骤 4：访问器优先级**
```
PropertyAccessor 优先级 (按注册顺序)：
  ├─ 第一个: 自定义访问器 (如果注册)
  ├─ ...
  ├─ 最后一个: ReflectivePropertyAccessor (默认反射)

调用时遍历列表：
  └─ 找到第一个 canRead() 返回 true 的访问器，使用它
```

**步骤 5：SimpleEvaluationContext（轻量级）**
```
SimpleEvaluationContext simpleContext =
    SimpleEvaluationContext.forReadOnlyDataBinding()
        .build();

特点：
  ├─ 无 Bean 引用
  ├─ 无构造器调用
  ├─ 无函数定义
  ├─ 仅允许属性读取
  ├─ 更安全（用户输入）
  └─ 性能更好
```

#### 结果

求值上下文配置完成，可用于表达式求值。

---

## 六级主题：类型系统

### 9. 类型转换与比较

#### 时间
类型不匹配时、需要比较不同类型时

#### 地点
关键类：`StandardTypeConverter`、`StandardTypeComparator`、`TypeDescriptor`
- 包：`org.springframework.expression.spel.support`

#### 人物

**操作主体**：TypeConverter / TypeComparator

**操作目标对象**：
- 源值和目标类型
- 两个待比较的值

#### 起因

表达式求值时经常需要类型转换（String → Integer）或类型比较（2 > "1"）。

#### 经过（4 个处理步骤）

**步骤 1：类型转换流程**
```
StandardTypeConverter.convertValue(value, sourceType, targetType)
  ├─ 检查源值和目标类型
  ├─ 若 value 已是目标类型，直接返回
  ├─ 委托给 Spring ConversionService
  │  └─ ConversionService.convert(value, targetType)
  │
  ├─ ConversionService 执行转换
  │  ├─ 查询已注册的转换器
  │  ├─ 调用转换器进行转换
  │  └─ return 转换后的值
  │
  ├─ 若转换失败，抛异常
  └─ return 转换后的值
```

**步骤 2：常见转换**
```
Spring 默认支持的转换：
  ├─ String ↔ 数字 (Integer, Long, Double, BigDecimal 等)
  ├─ String ↔ Boolean
  ├─ String ↔ Enum
  ├─ Array ↔ Collection
  ├─ String ↔ URL/URI
  ├─ String ↔ Locale
  ├─ Date ↔ Long
  ├─ Calendar ↔ Long
  └─ 自定义转换器 (用户可扩展)
```

**步骤 3：类型比较流程**
```
StandardTypeComparator.compare(left, right)
  ├─ 检查是否支持比较
  │  └─ canCompare(left.class, right.class)
  │
  ├─ 若类型相同，直接比较
  │  └─ ((Comparable) left).compareTo(right)
  │
  ├─ 若类型不同，尝试类型提升
  │  ├─ 数字类型比较：转换为共同类型后比较
  │  │  ├─ 若都是数字，转换为 BigDecimal (精确比较)
  │  │  ├─ 比较数值
  │  │  └─ return 比较结果
  │  │
  │  ├─ 字符串比较
  │  │  └─ 调用 String.compareTo()
  │  │
  │  └─ 若无法比较，抛 SpelEvaluationException
  │
  └─ return 比较结果 (-1, 0, 1)
```

**步骤 4：运算过程中的类型提升**
```
例：3 + 2.5
  ├─ 分析: int + double
  ├─ 类型提升: 提升为 double
  ├─ 转换: 3 → 3.0
  ├─ 执行: 3.0 + 2.5
  └─ return 5.5 (double)

例："hello" + 5
  ├─ 分析: String + int
  ├─ 特殊处理: + 支持字符串拼接
  ├─ 转换: 5 → "5"
  └─ return "hello5" (String)
```

#### 结果

值被成功转换或比较，返回结果。

---

## 核心设计模式

| 模式 | 应用 | 示例 |
|------|------|------|
| **Visitor** | AST 遍历求值 | SpelNode 子类实现 getValue() |
| **Strategy** | 多种访问/解析策略 | PropertyAccessor、MethodResolver |
| **Factory** | 创建表达式 | SpelExpressionParser |
| **Decorator** | 增强求值能力 | ExpressionState 包装 EvaluationContext |
| **Cache** | 性能优化 | 属性、方法、编译表达式的缓存 |
| **Template Method** | 解析流程 | 递归下降解析的模板结构 |
| **Compiler** | 字节码生成 | SpelCompiler 使用 ASM 生成字节码 |

---

## 完整的表达式执行流程图

```
应用代码
  ↓
SpelExpressionParser.parseExpression("person.age > 18")
  ├─ Tokenizer.process() → Token 流
  ├─ InternalSpelExpressionParser.doParseExpression() → AST
  └─ 返回 SpelExpression (包含 AST)

  ↓
StandardEvaluationContext context = new StandardEvaluationContext(person)
context.setVariable("minAge", 18)

  ↓
expression.getValue(context)
  ├─ ExpressionState state = new ExpressionState(context, person)
  ├─ 检查编译缓存
  │  ├─ 若存在 compiledAst，使用编译版本
  │  └─ 否则执行 AST.getValue(state)
  │
  ├─ OpGT.getValue(state)
  │  ├─ PropertyOrFieldReference("age").getValue(state)
  │  │  ├─ PropertyOrFieldReference("person").getValue(state)
  │  │  │  └─ return person 对象
  │  │  ├─ ReflectivePropertyAccessor.read(person, "age")
  │  │  └─ return 25
  │  │
  │  ├─ IntLiteral(18).getValue(state)
  │  │  └─ return 18
  │  │
  │  ├─ compare(25, 18) using StandardTypeComparator
  │  └─ return true
  │
  ├─ 可选：类型转换 (已是 boolean，无需转换)
  └─ return true

  ↓
应用继续处理结果
```

---

## 支持的表达式示例

```
// 字面量
123, 45L, 3.14, 1.4f, true, null, "hello"

// 属性和字段访问
person.name
person.getAge()
person?.address?.street   // 空安全

// 方法调用
person.getName()
"hello".length()
Math.max(1, 2)

// 运算符
1 + 2 * 3                  // 算术
person.age > 18 && person.active  // 逻辑
"hello" + " " + "world"   // 字符串拼接
value instanceof String    // instanceof
"test123".matches("test\\d+")  // 正则

// 三元和 Elvis
person.name == null ? "Unknown" : person.name
person.name ?: "Unknown"

// 赋值
person.age = 25

// 集合
new int[]{1, 2, 3}         // 数组字面量
{1, 2, 3}                  // List 字面量
{key1: 'value1', key2: 'value2'}  // Map 字面量

// 索引和切片
list[0]
map['key']
string[1:4]
array[*]                   // 所有元素

// 集合操作
list.?[age > 18]           // 选择
list.!{name}               // 投影
list.^[age > 18]           // 第一个匹配
list.$[age > 18]           // 最后一个匹配

// 变量和引用
#variable
#function(args)
@beanName
T(java.lang.String)
```

---

## 性能特性

| 特性 | 效果 |
|------|------|
| **解释执行** | 首次快速解析和执行 |
| **编译执行** | 100+ 次执行后编译，性能提升 10-50 倍 |
| **属性缓存** | (类, 属性) → 方法/字段，避免重复反射 |
| **方法缓存** | (类, 方法, 参数) → Method，提升调用速度 |
| **类型描述缓存** | 属性类型信息缓存 |
| **短路求值** | &&, \|\| 避免不必要的右操作数求值 |

---

## 最佳实践

### 安全性
- ✅ 使用 SimpleEvaluationContext 处理用户输入
- ✅ 通过 PropertyAccessor 白名单限制访问范围
- ❌ 避免在 StandardEvaluationContext 中执行不信任的表达式

### 性能
- ✅ 重用 Expression 对象（解析一次，多次执行）
- ✅ 使用编译模式处理频繁执行的表达式
- ✅ 缓存 EvaluationContext（避免重复初始化）
- ❌ 避免在循环中重复解析表达式

### 可读性
- ✅ 使用空安全导航 (`?.`) 处理 null
- ✅ 使用 Elvis 运算符 (`?:`) 提供默认值
- ✅ 对复杂表达式添加注释

---

**文档生成时间**：2025-11-25
**分析范围**：spring-expression 模块的所有主要功能域
**文档风格**：精炼本质、去除冗余、六要素结构化
