# Spring-JDBC 模块详细分析

## 模块概述

`spring-jdbc`是Spring Framework的数据库访问模块，提供JDBC操作的高级抽象。采用**记叙文6要素**方式记录其核心设计和执行机制。

---

## 一、时间（When）

- **起源时间**：Spring Framework初期（2001年5月，Rod Johnson开发）
- **核心演进**：持续优化，支持命名参数、对象化操作、存储过程调用等
- **当前版本**：Spring 5.2.3.RELEASE及以后版本
- **执行时间**：应用运行时，数据库操作发生时

---

## 二、地点（Where）

### 代码位置
```
spring-jdbc/
├── src/main/java/org/springframework/jdbc/
│   ├── core/                          # 核心JDBC模板和回调
│   │   ├── JdbcTemplate.java          # 中心模板类
│   │   ├── JdbcOperations.java        # 接口规范
│   │   ├── RowMapper.java             # 行映射接口
│   │   ├── ResultSetExtractor.java    # 结果集提取接口
│   │   ├── PreparedStatementCreator.java # SQL创建回调
│   │   ├── metadata/                  # 数据库元数据支持
│   │   ├── namedparam/                # 命名参数支持
│   │   └── simple/                    # 简化操作类
│   ├── datasource/                    # 数据源管理
│   │   ├── DataSourceUtils.java       # 连接工具
│   │   ├── DataSourceTransactionManager.java
│   │   └── embedded/                  # 嵌入式数据库
│   ├── support/                       # 支持工具
│   │   ├── JdbcAccessor.java          # 基础访问类
│   │   ├── SQLExceptionTranslator.java # 异常翻译器
│   │   ├── KeyHolder.java             # 主键持有者
│   │   └── rowset/                    # SQL行集合
│   ├── object/                        # 对象化操作
│   │   ├── SqlQuery.java
│   │   ├── SqlUpdate.java
│   │   └── StoredProcedure.java
│   └── config/                        # XML配置支持
│       ├── JdbcNamespaceHandler.java
│       └── DatabasePopulator*.java
```

### 运行时位置
- 应用启动时由Spring容器初始化
- JdbcTemplate存储在容器中作为bean
- 连接在事务管理器控制下获取和释放

---

## 三、人物（Who）

### 主要角色及职责

| 角色 | 具体类 | 职责 |
|------|--------|------|
| **模板** | JdbcTemplate | 协调整个JDBC流程，管理异常和连接 |
| **规范制定者** | JdbcOperations | 定义标准JDBC操作接口 |
| **连接管理者** | DataSourceUtils | 获取/释放连接，处理事务同步 |
| **基础访问者** | JdbcAccessor | 提供DataSource和异常翻译器 |
| **回调实现者** | 用户代码 | 实现PreparedStatementCreator、RowMapper等 |
| **结果处理者** | RowMapper / ResultSetExtractor | 将ResultSet转换为对象 |
| **异常翻译者** | SQLExceptionTranslator | 将SQLException转为DataAccessException |
| **元数据提供者** | CallMetaDataProvider等 | 提供数据库特定的元数据解析 |

---

## 四、起因（Why）

### 问题背景

在Spring出现之前，JDBC操作存在四个核心问题：

1. **冗余的样板代码**
   ```
   connection → statement → preparedstatement → 参数设置 → 执行 → 结果处理
   → 异常处理 → 关闭资源
   ```
   每次都需要重复编写

2. **异常处理混乱**
   - SQLException是checked exception，强制捕获
   - SQL错误代码数据库特定，难以统一处理
   - 无法区分约束违反、死锁等语义不同的错误

3. **资源管理困难**
   - 连接、语句、结果集都需要显式关闭
   - 事务管理分散在业务代码中
   - 线程本地连接复用困难

4. **操作重复性高**
   - 查询操作重复（单行、多行、聚合）
   - 更新操作重复（单条、批量）
   - 存储过程调用复杂

### 解决策略

Spring采用**模板方法模式+回调**的方式：
- JdbcTemplate负责连接、异常、资源管理
- 开发者只需提供业务逻辑回调
- 统一的异常层次

---

## 五、经过（How）

### 5.1 核心执行流程

#### 流程总览

```
应用代码调用
  ↓
JdbcTemplate.query/update/execute(...)
  ↓
DataSourceUtils.getConnection(dataSource)
  ↓
连接获取（支持事务同步）
  ↓
创建Statement/PreparedStatement
  ↓
用户回调：设置参数/处理结果
  ↓
SQL异常转为DataAccessException
  ↓
资源清理、连接释放
  ↓
返回结果或抛出异常
```

#### 详细步骤分解

### 5.2 关键处理步骤

#### A. 连接获取与事务同步（DataSourceUtils）

```
doGetConnection(dataSource)
  │
  ├─ 检查ThreadLocal中是否有现存Connection
  │  └─ 如果存在 → 复用（事务内复用同一连接）
  │
  ├─ 获取新连接 → fetchConnection(dataSource)
  │  └─ 若DataSource.getConnection()返回null → 抛IllegalStateException
  │
  └─ 事务同步注册
     ├─ 如果TransactionSynchronizationManager.isSynchronizationActive()
     │  ├─ 创建ConnectionHolder包装连接
     │  ├─ 注册ConnectionSynchronization监听器
     │  └─ 绑定到ThreadLocal（transaction context）
     └─ 返回连接

目的：
  • 同一事务内多次操作使用同一连接（事务一致性）
  • 自动释放不需要显式代码
  • 支持传播级别（REQUIRES_NEW等）
```

#### B. SQL语句执行策略（JdbcTemplate）

```
针对PreparedStatement的三类操作：

1. 查询操作（query）
   应用代码提供 PreparedStatementCreator
     ↓
   JdbcTemplate创建 PreparedStatement
     ↓
   用户回调 preparedStatement → execute() → ResultSet rs
     ↓
   提供给 RowMapper 或 ResultSetExtractor
     ↓
   返回List<T> 或 单个对象

2. 更新操作（update）
   应用代码提供 SQL + 参数 或 PreparedStatementCreator
     ↓
   JdbcTemplate创建 PreparedStatement
     ↓
   用户回调设置参数 PreparedStatementSetter
     ↓
   执行 executeUpdate()
     ↓
   返回受影响行数

   特殊：KeyHolder用于获取生成的主键

3. 批操作（batchUpdate）
   遍历集合 → 逐行调用 BatchPreparedStatementSetter
     ↓
   addBatch() 累积
     ↓
   executeBatch() 一次性执行
     ↓
   返回 int[] 数组（每行影响数）
```

#### C. 异常翻译（SQLExceptionTranslator）

```
原始异常：java.sql.SQLException
         ├─ 属性：errorCode(数据库特定)、SQLState(标准)
         └─ message: "ORA-00001: unique constraint violated"

翻译过程：
  SQLExceptionTranslator.translate(task, sql, SQLException)
    │
    ├─ 尝试 SQLErrorCodeSQLExceptionTranslator（优先）
    │  ├─ 根据数据库产品名(Oracle/MySQL等)
    │  ├─ 查找 sql-error-codes.xml 中的映射表
    │  ├─ 将错误码映射到Spring异常
    │  └─ 例：ORA-00001 → DataIntegrityViolationException
    │
    └─ 后备 SQLStateSQLExceptionTranslator
       └─ 使用标准SQL状态码(23505等) → 通用DataAccessException

转换结果：
  DataAccessException 子类
    ├─ DataIntegrityViolationException     # 约束违反
    ├─ DeadlockLoserDataAccessException    # 死锁
    ├─ PermissionDeniedDataAccessException # 权限不足
    ├─ BadSqlGrammarException              # SQL语法错误
    ├─ OptimisticLockingFailureException   # 乐观锁失败
    └─ UncategorizedSQLException           # 无法分类

特点：
  • Unchecked Exception（RuntimeException）
  • 包含原始SQLException作为rootCause
  • 带有task(任务描述)和sql(失败的SQL)
```

#### D. 结果集映射（RowMapper vs ResultSetExtractor）

```
RowMapper（逐行映射）：
  查询 → ResultSet rs
  ├─ while(rs.next())
  │  └─ T row = rowMapper.mapRow(rs, rowNum)
  │     └─ 将当前行转换为一个T对象
  └─ 返回 List<T>

  适用：大量相同结构的行
  实现简单，无需管理迭代

ResultSetExtractor（整体提取）：
  查询 → ResultSet rs
  ├─ T result = extractor.extractData(rs)
  │  └─ 在此方法内完全控制rs的遍历和处理
  │     可返回复杂结果（嵌套集合、Map等）
  └─ 返回 T（通常是List或Map）

  适用：复杂结果构建、需要自定义迭代逻辑
  功能强大，实现复杂

示例对比：
  // RowMapper
  List<User> users = jdbcTemplate.query(
    "SELECT id, name FROM users",
    (rs, rowNum) -> new User(rs.getInt("id"), rs.getString("name"))
  );

  // ResultSetExtractor
  Map<Integer, List<Order>> result = jdbcTemplate.query(
    "SELECT u.id, u.name, o.order_id FROM users u LEFT JOIN orders o",
    rs -> {
      Map<Integer, List<Order>> map = new HashMap<>();
      while(rs.next()) {
        // 自定义嵌套逻辑
      }
      return map;
    }
  );
```

#### E. 命名参数支持（NamedParameterJdbcTemplate）

```
传统SQL: SELECT * FROM users WHERE id = ? AND status = ?
需要记住参数顺序

命名参数SQL: SELECT * FROM users WHERE id = :id AND status = :status
参数有名称，顺序无关

执行流程：
  SQL with :name placeholders
    ↓
  NamedParameterJdbcTemplate.query(sql, paramSource, rowMapper)
    ↓
  SqlParameterSource（提供参数值）
    ├─ MapSqlParameterSource: Map<String, ?>
    ├─ BeanPropertySqlParameterSource: 从bean属性获取
    └─ 用户自定义: AbstractSqlParameterSource
    ↓
  内部将命名参数转换为 ? 占位符
    ↓
  调用底层 JdbcTemplate
```

#### F. 存储过程调用（CallableStatement）

```
特殊处理流程（相比普通SQL）：

1. 元数据解析
   CallMetaDataProvider（数据库特定实现）
     ├─ OracleCallMetaDataProvider
     ├─ PostgresCallMetaDataProvider
     ├─ MySQLCallMetaDataProvider
     └─ GenericCallMetaDataProvider（后备）

   作用：
     • 获取存储过程参数信息
     • 参数类型（IN/OUT/INOUT）
     • 数据类型映射

2. 参数映射
   申明参数 SqlParameter → 执行时映射关系
     ├─ SqlInParameter：输入参数
     ├─ SqlOutParameter：输出参数
     └─ SqlReturnResultSet：结果集参数

3. 执行与返回
   CallableStatement.execute()
     ↓
   提取输出参数值
     └─ registerOutParameter() + getXxx()
     └─ 结果返回为 Map<String, Object>
```

#### G. 资源清理（finally块自动处理）

```
获取的资源：
  ├─ Connection
  ├─ Statement/PreparedStatement/CallableStatement
  └─ ResultSet

清理链条：
  1. 用户回调抛异常
     ↓
  2. JdbcTemplate catch异常
     ↓
  3. 关闭ResultSet
     ↓
  4. 关闭Statement
     ↓
  5. 释放Connection
     └─ 若非事务，直接close()
     └─ 若在事务中，由TransactionManager管理
     ↓
  6. 异常翻译后重新抛出

优点：
  • 即使抛异常也能清理资源
  • 开发者无需显式try-finally
```

### 5.3 模板方法的具体流程

```java
// 伪代码展示流程
public <T> T execute(PreparedStatementCreator psc,
                     PreparedStatementCallback<T> action) {
    // 1. 连接获取
    Connection con = DataSourceUtils.getConnection(getDataSource());

    // 2. 语句创建
    PreparedStatement ps = psc.createPreparedStatement(con);

    try {
        // 3. 用户逻辑回调
        T result = action.doInPreparedStatement(ps);

        // 4. SQL警告处理
        handleWarnings(ps.getWarnings());

        return result;
    }
    catch (SQLException ex) {
        // 5. 异常翻译
        throw getExceptionTranslator()
            .translate("executing prepared statement",
                       psc.getSql(), ex);
    }
    finally {
        // 6. 资源清理
        JdbcUtils.closeStatement(ps);
        DataSourceUtils.releaseConnection(con, getDataSource());
    }
}
```

---

## 六、结果（Result）

### 最终状态转变

```
输入状态：
  ├─ 原始JDBC API（低级、繁琐）
  ├─ 异常处理混乱（checked/database-specific）
  ├─ 资源管理复杂（try-catch-finally嵌套）
  └─ 代码重复性高（样板代码80%）

处理后状态：
  ├─ 高级模板化操作（40行代码缩至4行）
  ├─ 统一异常体系（DataAccessException）
  ├─ 自动资源管理（透明处理）
  ├─ 支持事务一致性（线程本地连接复用）
  └─ 多数据库兼容（元数据适配）
```

### 6.1 核心成果总结

| 方面 | 成果 | 示例 |
|------|------|------|
| **代码量** | 减少80% | 手写JDBC 40行 → JdbcTemplate 4行 |
| **异常处理** | 统一转换 | SQLException → DataAccessException |
| **连接管理** | 自动化 | 无需显式close()调用 |
| **事务支持** | 线程透明 | 同事务内自动复用连接 |
| **类型安全** | 泛型支持 | query()返回List<T>，无强转 |
| **数据库适配** | 自动映射 | 错误码、元数据、方言自适配 |
| **参数化** | 多种方式 | 位置参数、命名参数、对象参数 |

### 6.2 操作示例对比

#### 传统JDBC（无Spring）
```java
Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;
try {
    conn = dataSource.getConnection();
    ps = conn.prepareStatement("SELECT * FROM users WHERE id = ?");
    ps.setInt(1, userId);
    rs = ps.executeQuery();

    List<User> users = new ArrayList<>();
    while(rs.next()) {
        users.add(new User(rs.getInt("id"), rs.getString("name")));
    }
    return users;
}
catch(SQLException ex) {
    // 如何处理？不知道原因
    throw new RuntimeException(ex);
}
finally {
    try { if(rs != null) rs.close(); } catch(Exception e) {}
    try { if(ps != null) ps.close(); } catch(Exception e) {}
    try { if(conn != null) conn.close(); } catch(Exception e) {}
}
```

#### 使用Spring-JDBC（一行代码）
```java
List<User> users = jdbcTemplate.query(
    "SELECT * FROM users WHERE id = ?",
    new Object[]{userId},
    (rs, rowNum) -> new User(rs.getInt("id"), rs.getString("name"))
);
```

### 6.3 系统在Spring生态中的位置

```
应用代码
  │
  ├─ 业务Service
  │  └─ @Transactional annotation
  │
  ▼
Spring-JDBC (本模块)
  ├─ JdbcTemplate
  ├─ DataSourceUtils (连接管理)
  ├─ SQLExceptionTranslator (异常转换)
  └─ RowMapper/ResultSetExtractor (结果映射)

  │
  ├─ spring-tx (事务管理)
  │  └─ DataSourceTransactionManager
  │     └─ 与spring-jdbc配合管理连接
  │
  ├─ spring-context (依赖注入)
  │  └─ JdbcTemplate作为bean注入
  │
  └─ spring-core (基础工具)
     └─ 反射、日志等

  │
  ▼
JDBC API (java.sql.*)
  │
  ▼
DataSource
  │
  ▼
JDBC Driver
  │
  ▼
数据库服务器
```

### 6.4 关键类关系图

```
JdbcOperations (接口)
    │
    ▼ implements
JdbcTemplate (核心类)
    │
    ├─ extends
    │  └─ JdbcAccessor
    │     ├─ holds: DataSource
    │     ├─ holds: SQLExceptionTranslator
    │     └─ implements: InitializingBean
    │
    ├─ uses
    │  ├─ DataSourceUtils (获取Connection)
    │  ├─ JdbcUtils (工具方法)
    │  ├─ SQLExceptionTranslator (异常转换)
    │  └─ StatementCallback/PreparedStatementCallback/... (用户回调)
    │
    └─ supports
       ├─ RowMapper<T> (逐行映射)
       ├─ ResultSetExtractor<T> (整体提取)
       ├─ RowCallbackHandler (行回调)
       ├─ PreparedStatementCreator (SQL创建)
       ├─ PreparedStatementSetter (参数设置)
       └─ KeyHolder (主键获取)

NamedParameterJdbcTemplate (高级模板)
    │
    ├─ wraps: JdbcTemplate
    └─ uses: SqlParameterSource
       ├─ MapSqlParameterSource
       ├─ BeanPropertySqlParameterSource
       └─ ...
```

---

## 核心设计模式总结

| 模式 | 应用 | 好处 |
|------|------|------|
| **模板方法** | JdbcTemplate的execute系列 | 框架负责连接、异常、资源；用户专注业务 |
| **策略模式** | PreparedStatementCreator/RowMapper等 | 灵活定制SQL创建和结果处理 |
| **回调模式** | 用户实现各种Callback接口 | 控制反转，框架调用用户代码 |
| **数据访问对象** | DAO继承JdbcDaoSupport | 提供基础设施 |
| **装饰器** | NamedParameterJdbcTemplate | 增强功能而不修改原类 |
| **工厂** | DataSourceUtils | 统一连接获取入口 |
| **适配器** | 多个CallMetaDataProvider实现 | 适配不同数据库的元数据API |

---

## 扩展性与应用范围

### 支持的操作类型

1. ✅ 单条查询 → query()返回List
2. ✅ 批量查询 → queryForList()
3. ✅ 聚合查询 → queryForObject()
4. ✅ 单条插入 → update()返回受影响行数
5. ✅ 批量插入 → batchUpdate()
6. ✅ 获取自增主键 → update() + KeyHolder
7. ✅ 存储过程调用 → call()
8. ✅ 原生SQL执行 → execute()
9. ✅ 命名参数 → NamedParameterJdbcTemplate
10. ✅ 对象化操作 → SqlQuery/SqlUpdate类

### 约束与局限

1. ⚠️ 仅支持JDBC数据源（不支持特殊池如Druid扩展配置）
2. ⚠️ 不支持动态SQL（需Mybatis等补充）
3. ⚠️ 不支持ORM功能（需Hibernate等补充）
4. ⚠️ 复杂业务逻辑需自己写SQL

---

## 总结

`spring-jdbc`通过**模板方法+回调**，将复杂的JDBC操作流程简化为直观的、链式的、异常统一的API。它处理了连接管理、异常转换、资源清理等基础设施，让开发者只需关注SQL和业务逻辑。配合Spring事务管理，提供了企业级数据库访问的坚实基础。

其设计在2001年提出至今仍被广泛使用，甚至其思想被后续的Mybatis、QueryDSL等框架借鉴。对于简单到中等复杂度的CRUD操作，spring-jdbc仍然是最轻量级、最高效的选择。
