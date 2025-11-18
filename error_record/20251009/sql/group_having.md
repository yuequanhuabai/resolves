# GROUP BY 与 HAVING 完全指南

## 目录
- [SQL 的诞生背景](#sql-的诞生背景)
- [GROUP BY 的诞生与发展](#group-by-的诞生与发展)
- [HAVING 的诞生与发展](#having-的诞生与发展)
- [GROUP BY 详解](#group-by-详解)
- [HAVING 详解](#having-详解)
- [GROUP BY vs WHERE vs HAVING](#group-by-vs-where-vs-having)
- [实战应用场景](#实战应用场景)
- [高级用法](#高级用法)
- [性能优化](#性能优化)
- [常见误区与陷阱](#常见误区与陷阱)
- [不同数据库的实现差异](#不同数据库的实现差异)

---

## SQL 的诞生背景

### 关系数据库的革命（1970年代）

**时间线：**
- **1970年**：IBM 研究员 **Edgar F. Codd** 发表论文《A Relational Model of Data for Large Shared Data Banks》
  - 提出了关系数据库理论
  - 数据以"表"（关系）形式存储
  - 引入了关系代数和关系演算的概念

- **1974年**：IBM 开始开发 **System R** 项目
  - 第一个实现关系数据库的原型系统
  - 创建了 **SEQUEL** 语言（Structured English Query Language）
  - SEQUEL 后来改名为 **SQL**（Structured Query Language）

- **1979年**：Relational Software, Inc.（后来的 Oracle）发布第一个商业化的 SQL 数据库

- **1986年**：ANSI（美国国家标准协会）发布 SQL-86 标准
  - 第一个 SQL 标准
  - **GROUP BY 和 HAVING 被纳入标准**

### 为什么需要 SQL？

在 SQL 出现之前，数据库查询需要：
```
// 类似 COBOL 的过程式代码
OPEN CURSOR FOR EMPLOYEE_FILE
LOOP
    READ EMPLOYEE_RECORD
    IF DEPARTMENT = 'SALES' THEN
        SUM_SALARY = SUM_SALARY + SALARY
        COUNT = COUNT + 1
    END IF
END LOOP
AVERAGE = SUM_SALARY / COUNT
```

SQL 的革命性在于**声明式**查询：
```sql
-- 一句话表达查询意图
SELECT AVG(salary)
FROM employees
WHERE department = 'SALES';
```

---

## GROUP BY 的诞生与发展

### 诞生背景：聚合查询的需求

#### 业务需求的演变

**1960-70年代的典型业务场景：**
1. **财务报表**：按部门统计工资总额
2. **销售统计**：按地区统计销售额
3. **库存管理**：按产品类别统计数量

**问题：** 传统的关系代数只能处理单行数据，无法进行分组统计。

### Edgar F. Codd 的理论基础

Codd 的关系代数定义了基本操作：
- **选择（Selection）**：WHERE 子句
- **投影（Projection）**：SELECT 子句
- **连接（Join）**：JOIN 操作
- **聚合（Aggregation）**：**缺失！**

**关键问题：** 如何在关系模型中表达"分组聚合"？

### GROUP BY 的设计理念

**1974年，System R 项目引入 GROUP BY：**

**设计目标：**
1. 将数据按某些列的值分组
2. 对每组应用聚合函数
3. 返回每组一条记录

**示例：**
```sql
-- 原始数据
employees:
| emp_id | department | salary |
|--------|------------|--------|
| 1      | Sales      | 5000   |
| 2      | Sales      | 6000   |
| 3      | IT         | 7000   |
| 4      | IT         | 8000   |

-- GROUP BY 查询
SELECT department, AVG(salary) as avg_salary
FROM employees
GROUP BY department;

-- 结果
| department | avg_salary |
|------------|------------|
| Sales      | 5500       |
| IT         | 7500       |
```

### 发展历程

#### SQL-86（1986年）
- GROUP BY 首次成为 ANSI 标准
- 支持基本聚合函数：COUNT、SUM、AVG、MAX、MIN
- 只能按单列或多列分组

#### SQL-92（1992年）
- 引入 **ROLLUP** 和 **CUBE** 操作符（部分数据库支持）
- 支持更复杂的分组表达式

#### SQL:1999（1999年）
- 引入 **GROUPING SETS**
- 支持分组函数嵌套

#### SQL:2003（2003年）
- 引入窗口函数（Window Functions）
- OVER() 子句提供了更灵活的分组方式

#### SQL:2011 及以后
- 支持多维分析（OLAP）
- 引入 **LISTAGG**、**STRING_AGG** 等新聚合函数

---

## HAVING 的诞生与发展

### 诞生背景：过滤聚合结果的需求

#### GROUP BY 的局限性

有了 GROUP BY 后，新问题出现了：

**业务需求：** "查询平均工资超过 6000 的部门"

**第一次尝试（错误）：**
```sql
SELECT department, AVG(salary)
FROM employees
WHERE AVG(salary) > 6000  -- ❌ 错误！WHERE 不能使用聚合函数
GROUP BY department;
```

**为什么 WHERE 不行？**
- WHERE 在分组**之前**过滤单行数据
- AVG(salary) 是分组**之后**才能计算的
- 时序矛盾！

### HAVING 的设计

**1974年，System R 项目引入 HAVING：**

**设计理念：**
> HAVING 是专门用于过滤分组后结果的子句

**SQL 执行顺序：**
```
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
  1      2         3          4        5         6
```

**正确的查询：**
```sql
SELECT department, AVG(salary) as avg_salary
FROM employees
GROUP BY department
HAVING AVG(salary) > 6000;  -- ✅ 正确！
```

### HAVING 的语法规则

#### 标准定义（SQL-86）

**HAVING 子句的限制：**
1. 只能出现在 GROUP BY 之后
2. 只能包含：
   - 聚合函数（如 COUNT、SUM、AVG）
   - GROUP BY 中的列
   - 常量

**示例：**
```sql
-- ✅ 合法的 HAVING
HAVING COUNT(*) > 10
HAVING AVG(salary) > 5000
HAVING department = 'Sales'  -- department 在 GROUP BY 中

-- ❌ 非法的 HAVING
HAVING salary > 5000  -- salary 不在 GROUP BY 中，且不是聚合函数
```

### 发展历程

#### SQL-86（1986年）
- HAVING 首次成为标准
- 只支持简单的聚合函数过滤

#### SQL-92（1992年）
- 支持子查询在 HAVING 中使用
- 支持复杂的逻辑表达式

```sql
HAVING AVG(salary) > (SELECT AVG(salary) FROM employees)
```

#### SQL:1999（1999年）
- 支持窗口函数与 HAVING 结合
- 引入 FILTER 子句（部分数据库）

```sql
-- SQL:1999 引入的 FILTER
SELECT department,
       COUNT(*) FILTER (WHERE salary > 5000) as high_earners
FROM employees
GROUP BY department;
```

#### 现代数据库的扩展
- **MySQL/PostgreSQL**：支持别名在 HAVING 中使用
- **Oracle**：支持分析函数与 HAVING 结合
- **SQL Server**：支持 CTE 与 HAVING 结合

---

## GROUP BY 详解

### 基本语法

```sql
SELECT
    分组列1,
    分组列2,
    聚合函数(列)
FROM 表名
WHERE 过滤条件
GROUP BY 分组列1, 分组列2
HAVING 分组过滤条件
ORDER BY 排序列;
```

### 工作原理

#### 分组过程图解

**原始数据：**
```
employees:
| id | department | position | salary |
|----|------------|----------|--------|
| 1  | Sales      | Manager  | 8000   |
| 2  | Sales      | Staff    | 5000   |
| 3  | Sales      | Staff    | 5500   |
| 4  | IT         | Manager  | 9000   |
| 5  | IT         | Staff    | 7000   |
| 6  | HR         | Manager  | 7500   |
```

**执行：**
```sql
SELECT department, COUNT(*) as emp_count, AVG(salary) as avg_salary
FROM employees
GROUP BY department;
```

**分组过程：**
```
1. 扫描表，按 department 分组
   ┌─ Sales ─┐
   │ 1, 2, 3 │
   └─────────┘
   ┌─ IT ────┐
   │ 4, 5    │
   └─────────┘
   ┌─ HR ────┐
   │ 6       │
   └─────────┘

2. 对每组应用聚合函数
   Sales: COUNT=3, AVG=(8000+5000+5500)/3=6166.67
   IT:    COUNT=2, AVG=(9000+7000)/2=8000
   HR:    COUNT=1, AVG=7500

3. 返回结果
   | department | emp_count | avg_salary |
   |------------|-----------|------------|
   | Sales      | 3         | 6166.67    |
   | IT         | 2         | 8000       |
   | HR         | 1         | 7500       |
```

### 聚合函数详解

#### 标准聚合函数（SQL-86）

| 函数 | 说明 | 示例 | 返回值 |
|------|------|------|--------|
| **COUNT(*)** | 统计行数（包括 NULL） | `COUNT(*)` | 整数 |
| **COUNT(列)** | 统计非 NULL 值的数量 | `COUNT(email)` | 整数 |
| **SUM(列)** | 求和 | `SUM(salary)` | 数值 |
| **AVG(列)** | 平均值 | `AVG(salary)` | 数值 |
| **MAX(列)** | 最大值 | `MAX(salary)` | 与列类型相同 |
| **MIN(列)** | 最小值 | `MIN(hire_date)` | 与列类型相同 |

#### COUNT(*) vs COUNT(列) 的区别

```sql
-- 示例数据
employees:
| id | name  | email          |
|----|-------|----------------|
| 1  | Alice | alice@test.com |
| 2  | Bob   | NULL           |
| 3  | Carol | carol@test.com |

-- COUNT(*) 统计所有行
SELECT COUNT(*) FROM employees;
-- 结果: 3

-- COUNT(email) 只统计非 NULL 的值
SELECT COUNT(email) FROM employees;
-- 结果: 2

-- COUNT(DISTINCT email) 统计去重后的非 NULL 值
SELECT COUNT(DISTINCT email) FROM employees;
-- 结果: 2
```

#### 现代聚合函数（SQL:1999+）

| 函数 | 说明 | 示例 |
|------|------|------|
| **STRING_AGG** (PostgreSQL) | 字符串聚合 | `STRING_AGG(name, ', ')` |
| **GROUP_CONCAT** (MySQL) | 字符串聚合 | `GROUP_CONCAT(name)` |
| **LISTAGG** (Oracle) | 字符串聚合 | `LISTAGG(name, ', ')` |
| **ARRAY_AGG** | 数组聚合 | `ARRAY_AGG(name)` |
| **JSON_AGG** | JSON 聚合 | `JSON_AGG(name)` |

### 多列分组

```sql
-- 按多列分组
SELECT department, position, COUNT(*) as count, AVG(salary) as avg_salary
FROM employees
GROUP BY department, position;

-- 结果
| department | position | count | avg_salary |
|------------|----------|-------|------------|
| Sales      | Manager  | 1     | 8000       |
| Sales      | Staff    | 2     | 5250       |
| IT         | Manager  | 1     | 9000       |
| IT         | Staff    | 1     | 7000       |
| HR         | Manager  | 1     | 7500       |
```

**分组规则：**
- 多列组合的唯一值作为一组
- (Sales, Manager) 是一组
- (Sales, Staff) 是另一组

### 表达式分组

```sql
-- 按计算列分组
SELECT
    YEAR(hire_date) as hire_year,
    COUNT(*) as hired_count
FROM employees
GROUP BY YEAR(hire_date);

-- 按 CASE 表达式分组
SELECT
    CASE
        WHEN salary < 5000 THEN 'Low'
        WHEN salary < 8000 THEN 'Medium'
        ELSE 'High'
    END as salary_level,
    COUNT(*) as count
FROM employees
GROUP BY
    CASE
        WHEN salary < 5000 THEN 'Low'
        WHEN salary < 8000 THEN 'Medium'
        ELSE 'High'
    END;
```

---

## HAVING 详解

### 基本语法

```sql
SELECT 列名, 聚合函数
FROM 表名
GROUP BY 列名
HAVING 聚合函数 条件;
```

### 工作原理

**执行流程：**
```
1. FROM: 确定数据源
2. WHERE: 过滤单行数据
3. GROUP BY: 分组
4. 聚合函数: 计算每组的聚合值
5. HAVING: 过滤分组结果
6. SELECT: 选择输出列
7. ORDER BY: 排序
```

**示例：**
```sql
SELECT department, AVG(salary) as avg_salary
FROM employees
WHERE position = 'Staff'          -- 步骤2: 只取 Staff
GROUP BY department               -- 步骤3: 按部门分组
HAVING AVG(salary) > 6000         -- 步骤5: 只要平均工资>6000的部门
ORDER BY avg_salary DESC;         -- 步骤7: 按平均工资降序
```

**执行过程：**
```
原始数据: 6 rows
↓ WHERE (position = 'Staff')
过滤后: 3 rows (id: 2, 3, 5)
↓ GROUP BY department
分组:
  - Sales: [2, 3]  → AVG=5250
  - IT: [5]        → AVG=7000
↓ HAVING (AVG(salary) > 6000)
过滤后: 1 group
  - IT: AVG=7000
↓ SELECT
最终结果:
| department | avg_salary |
|------------|------------|
| IT         | 7000       |
```

### HAVING 的使用规则

#### 规则 1：只能包含聚合函数或 GROUP BY 列

```sql
-- ✅ 正确：使用聚合函数
HAVING COUNT(*) > 5
HAVING AVG(salary) > 6000
HAVING SUM(amount) BETWEEN 1000 AND 5000

-- ✅ 正确：使用 GROUP BY 中的列
SELECT department, COUNT(*)
FROM employees
GROUP BY department
HAVING department IN ('Sales', 'IT');

-- ❌ 错误：使用非 GROUP BY 列且非聚合
SELECT department, COUNT(*)
FROM employees
GROUP BY department
HAVING salary > 5000;  -- salary 不在 GROUP BY 中
```

#### 规则 2：HAVING 中可以使用 SELECT 的别名（部分数据库）

```sql
-- MySQL/PostgreSQL 支持
SELECT department, AVG(salary) as avg_salary
FROM employees
GROUP BY department
HAVING avg_salary > 6000;  -- 使用别名

-- Oracle/SQL Server 不支持，需要重复表达式
SELECT department, AVG(salary) as avg_salary
FROM employees
GROUP BY department
HAVING AVG(salary) > 6000;  -- 必须重复 AVG(salary)
```

#### 规则 3：HAVING 可以包含子查询

```sql
-- 查询平均工资高于全公司平均工资的部门
SELECT department, AVG(salary) as avg_salary
FROM employees
GROUP BY department
HAVING AVG(salary) > (SELECT AVG(salary) FROM employees);
```

#### 规则 4：HAVING 可以使用多个条件

```sql
SELECT department,
       COUNT(*) as emp_count,
       AVG(salary) as avg_salary
FROM employees
GROUP BY department
HAVING COUNT(*) > 2           -- 人数超过2
   AND AVG(salary) > 6000     -- 且平均工资超过6000
   AND MAX(salary) < 10000;   -- 且最高工资低于10000
```

---

## GROUP BY vs WHERE vs HAVING

### 三者的区别

| 特性 | WHERE | GROUP BY | HAVING |
|------|-------|----------|--------|
| **执行时机** | 分组前 | 分组 | 分组后 |
| **过滤对象** | 单行数据 | - | 分组结果 |
| **能否使用聚合函数** | ❌ 否 | - | ✅ 是 |
| **能否使用别名** | ❌ 否 | 部分支持 | 部分支持 |
| **必须与 GROUP BY 配合** | ❌ 否 | - | ✅ 是 |
| **性能** | 最优（索引） | - | 较慢 |

### 使用场景对比

#### 场景 1：过滤单行数据 → 用 WHERE

```sql
-- 查询销售部门的员工
SELECT *
FROM employees
WHERE department = 'Sales';  -- ✅ WHERE
```

#### 场景 2：分组统计 → 用 GROUP BY

```sql
-- 统计每个部门的人数
SELECT department, COUNT(*)
FROM employees
GROUP BY department;  -- ✅ GROUP BY
```

#### 场景 3：过滤分组结果 → 用 HAVING

```sql
-- 查询人数超过5的部门
SELECT department, COUNT(*) as count
FROM employees
GROUP BY department
HAVING COUNT(*) > 5;  -- ✅ HAVING
```

#### 场景 4：组合使用

```sql
-- 查询销售部门中，平均工资超过6000的职位
SELECT position, AVG(salary) as avg_salary
FROM employees
WHERE department = 'Sales'    -- 先过滤部门
GROUP BY position             -- 按职位分组
HAVING AVG(salary) > 6000;    -- 再过滤平均工资
```

### 性能对比

```sql
-- ❌ 性能差：在 HAVING 中过滤单行条件
SELECT department, AVG(salary)
FROM employees
GROUP BY department
HAVING department = 'Sales';  -- 先分组所有部门，再过滤

-- ✅ 性能好：在 WHERE 中过滤单行条件
SELECT department, AVG(salary)
FROM employees
WHERE department = 'Sales'    -- 先过滤，只分组 Sales 部门
GROUP BY department;
```

**原则：** 能用 WHERE 的尽量用 WHERE，不要滥用 HAVING。

---

## 实战应用场景

### 场景 1：销售统计

**需求：** 查询 2024 年每个月的销售额，只显示销售额超过 10 万的月份。

```sql
SELECT
    DATE_FORMAT(order_date, '%Y-%m') as month,
    COUNT(*) as order_count,
    SUM(amount) as total_sales,
    AVG(amount) as avg_order_value
FROM orders
WHERE YEAR(order_date) = 2024
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
HAVING SUM(amount) > 100000
ORDER BY month;
```

**结果：**
```
| month   | order_count | total_sales | avg_order_value |
|---------|-------------|-------------|-----------------|
| 2024-01 | 523         | 156780.50   | 299.77          |
| 2024-03 | 612         | 183450.00   | 299.75          |
| 2024-06 | 701         | 210300.00   | 300.00          |
```

### 场景 2：用户行为分析

**需求：** 找出活跃用户（登录次数超过 10 次且最后登录在 30 天内）。

```sql
SELECT
    user_id,
    COUNT(*) as login_count,
    MAX(login_time) as last_login,
    MIN(login_time) as first_login,
    DATEDIFF(MAX(login_time), MIN(login_time)) as active_days
FROM user_login_log
GROUP BY user_id
HAVING COUNT(*) > 10
   AND MAX(login_time) > DATE_SUB(NOW(), INTERVAL 30 DAY)
ORDER BY login_count DESC;
```

### 场景 3：库存预警

**需求：** 查询库存低于安全库存的商品分类（每类至少有 3 个商品库存不足）。

```sql
SELECT
    category_id,
    category_name,
    COUNT(*) as low_stock_count,
    AVG(stock_quantity) as avg_stock
FROM products
WHERE stock_quantity < safety_stock
GROUP BY category_id, category_name
HAVING COUNT(*) >= 3
ORDER BY low_stock_count DESC;
```

### 场景 4：重复数据检测

**需求：** 找出有重复邮箱的用户（同一邮箱注册多次）。

```sql
SELECT
    email,
    COUNT(*) as duplicate_count,
    GROUP_CONCAT(user_id) as user_ids
FROM users
GROUP BY email
HAVING COUNT(*) > 1;
```

**结果：**
```
| email           | duplicate_count | user_ids    |
|-----------------|-----------------|-------------|
| test@email.com  | 3               | 101,205,389 |
| user@email.com  | 2               | 156,290     |
```

### 场景 5：Top N 问题

**需求：** 查询每个部门工资前 3 名的员工。

```sql
-- 方法1：使用窗口函数（SQL:2003）
SELECT department, name, salary
FROM (
    SELECT
        department,
        name,
        salary,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as rank
    FROM employees
) ranked
WHERE rank <= 3;

-- 方法2：使用子查询（传统方法）
SELECT e1.department, e1.name, e1.salary
FROM employees e1
WHERE (
    SELECT COUNT(DISTINCT e2.salary)
    FROM employees e2
    WHERE e2.department = e1.department
      AND e2.salary > e1.salary
) < 3
ORDER BY e1.department, e1.salary DESC;
```

### 场景 6：同比环比分析

**需求：** 计算每个月的销售额及同比增长率。

```sql
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') as month,
        SUM(amount) as total_sales
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    current.month,
    current.total_sales as current_sales,
    previous.total_sales as previous_year_sales,
    ROUND((current.total_sales - previous.total_sales) / previous.total_sales * 100, 2) as yoy_growth_rate
FROM monthly_sales current
LEFT JOIN monthly_sales previous
    ON DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(current.month, '-01'), '%Y-%m-%d'),
                            INTERVAL 1 YEAR), '%Y-%m') = previous.month
HAVING current.total_sales IS NOT NULL
ORDER BY current.month;
```

---

## 高级用法

### ROLLUP：多维度汇总

**SQL:1999 引入**

**需求：** 统计销售额，按地区和产品汇总，并生成小计和总计。

```sql
SELECT
    region,
    product,
    SUM(sales) as total_sales
FROM sales_data
GROUP BY region, product WITH ROLLUP;
```

**结果：**
```
| region | product  | total_sales |
|--------|----------|-------------|
| East   | Product A| 10000       |
| East   | Product B| 15000       |
| East   | NULL     | 25000       | ← 东部小计
| West   | Product A| 12000       |
| West   | Product B| 18000       |
| West   | NULL     | 30000       | ← 西部小计
| NULL   | NULL     | 55000       | ← 总计
```

**ROLLUP 的原理：**
```sql
GROUP BY a, b WITH ROLLUP
等价于：
GROUP BY a, b
UNION ALL
GROUP BY a
UNION ALL
GROUP BY ()  -- 总计
```

### CUBE：所有维度组合

**需求：** 生成所有可能的汇总组合。

```sql
SELECT
    region,
    product,
    SUM(sales) as total_sales
FROM sales_data
GROUP BY region, product WITH CUBE;
```

**结果：**
```
| region | product  | total_sales |
|--------|----------|-------------|
| East   | Product A| 10000       |
| East   | Product B| 15000       |
| East   | NULL     | 25000       | ← 按地区汇总
| West   | Product A| 12000       |
| West   | Product B| 18000       |
| West   | NULL     | 30000       | ← 按地区汇总
| NULL   | Product A| 22000       | ← 按产品汇总
| NULL   | Product B| 33000       | ← 按产品汇总
| NULL   | NULL     | 55000       | ← 总计
```

### GROUPING SETS：自定义汇总

**需求：** 只要特定的汇总组合。

```sql
SELECT
    region,
    product,
    year,
    SUM(sales) as total_sales
FROM sales_data
GROUP BY GROUPING SETS (
    (region, product),  -- 按地区和产品
    (region),           -- 只按地区
    ()                  -- 总计
);
```

### 窗口函数替代 GROUP BY

**需求：** 在不分组的情况下显示聚合值。

```sql
-- 传统 GROUP BY（会丢失明细）
SELECT department, AVG(salary)
FROM employees
GROUP BY department;

-- 窗口函数（保留明细）
SELECT
    name,
    department,
    salary,
    AVG(salary) OVER (PARTITION BY department) as dept_avg_salary,
    salary - AVG(salary) OVER (PARTITION BY department) as diff_from_avg
FROM employees;
```

**结果：**
```
| name  | department | salary | dept_avg_salary | diff_from_avg |
|-------|------------|--------|-----------------|---------------|
| Alice | Sales      | 8000   | 6166.67         | 1833.33       |
| Bob   | Sales      | 5000   | 6166.67         | -1166.67      |
| Carol | Sales      | 5500   | 6166.67         | -666.67       |
| David | IT         | 9000   | 8000            | 1000          |
| Eve   | IT         | 7000   | 8000            | -1000         |
```

---

## 性能优化

### 索引优化

#### 规则 1：为 GROUP BY 列创建索引

```sql
-- 查询
SELECT department, COUNT(*)
FROM employees
GROUP BY department;

-- 创建索引
CREATE INDEX idx_department ON employees(department);
```

**效果：**
- 无索引：全表扫描 + 临时表排序
- 有索引：索引扫描（快 10-100 倍）

#### 规则 2：覆盖索引最优

```sql
-- 查询
SELECT department, position, COUNT(*)
FROM employees
GROUP BY department, position;

-- 创建覆盖索引
CREATE INDEX idx_dept_position ON employees(department, position);
```

**覆盖索引：** 索引包含查询所需的所有列，无需回表。

#### 规则 3：前缀索引顺序

```sql
-- ✅ 正确：索引顺序与 GROUP BY 一致
CREATE INDEX idx_dept_position ON employees(department, position);
SELECT department, position, COUNT(*)
FROM employees
GROUP BY department, position;

-- ❌ 低效：索引顺序不一致
CREATE INDEX idx_position_dept ON employees(position, department);
SELECT department, position, COUNT(*)
FROM employees
GROUP BY department, position;  -- 索引可能无法完全利用
```

### WHERE 与 HAVING 的性能差异

```sql
-- ❌ 慢：在 HAVING 中过滤单行条件
SELECT department, AVG(salary)
FROM employees  -- 1000万行
GROUP BY department
HAVING department IN ('Sales', 'IT');  -- 先分组1000万行，再过滤

-- ✅ 快：在 WHERE 中过滤单行条件
SELECT department, AVG(salary)
FROM employees  -- 1000万行
WHERE department IN ('Sales', 'IT')    -- 先过滤剩10万行
GROUP BY department;                   -- 只分组10万行
```

**性能差异：** 可能相差 10-100 倍！

### 使用 EXPLAIN 分析

```sql
EXPLAIN SELECT department, COUNT(*)
FROM employees
GROUP BY department
HAVING COUNT(*) > 10;
```

**关注的指标：**
- **type**: 至少是 `ref`，最好是 `index`
- **Extra**:
  - `Using index`: ✅ 好（覆盖索引）
  - `Using temporary`: ⚠️ 使用临时表（慢）
  - `Using filesort`: ⚠️ 文件排序（慢）

### 避免复杂表达式

```sql
-- ❌ 慢：复杂表达式无法使用索引
SELECT UPPER(TRIM(department)), COUNT(*)
FROM employees
GROUP BY UPPER(TRIM(department));

-- ✅ 快：预处理或使用计算列
ALTER TABLE employees ADD COLUMN dept_normalized VARCHAR(50)
    AS (UPPER(TRIM(department))) STORED;
CREATE INDEX idx_dept_norm ON employees(dept_normalized);

SELECT dept_normalized, COUNT(*)
FROM employees
GROUP BY dept_normalized;
```

### 分区表优化

```sql
-- 创建分区表
CREATE TABLE sales (
    id INT,
    sale_date DATE,
    amount DECIMAL(10,2)
)
PARTITION BY RANGE (YEAR(sale_date)) (
    PARTITION p2022 VALUES LESS THAN (2023),
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025)
);

-- 查询时自动剪裁分区
SELECT YEAR(sale_date), SUM(amount)
FROM sales
WHERE sale_date >= '2024-01-01'  -- 只扫描 p2024 分区
GROUP BY YEAR(sale_date);
```

---

## 常见误区与陷阱

### 误区 1：SELECT 列必须在 GROUP BY 中？

**传统规则（SQL-86）：** 是的！

```sql
-- ❌ 标准 SQL 报错
SELECT department, name, AVG(salary)
FROM employees
GROUP BY department;  -- name 不在 GROUP BY 中
-- Error: 'name' is not in GROUP BY clause
```

**MySQL 的特殊行为（5.7 之前）：**
```sql
-- MySQL 默认允许（但结果不确定）
SELECT department, name, AVG(salary)
FROM employees
GROUP BY department;  -- name 随机取一个值

-- 结果不确定：
| department | name  | avg_salary |
|------------|-------|------------|
| Sales      | Alice | 6166.67    |  ← name 可能是 Alice、Bob 或 Carol
| IT         | David | 8000       |  ← name 可能是 David 或 Eve
```

**MySQL 5.7+ 默认启用 ONLY_FULL_GROUP_BY：**
```sql
-- 现在会报错
SELECT department, name, AVG(salary)
FROM employees
GROUP BY department;
-- Error: Expression #2 of SELECT list is not in GROUP BY clause
```

**正确做法：**
```sql
-- 方法1：将所有非聚合列加入 GROUP BY
SELECT department, name, AVG(salary)
FROM employees
GROUP BY department, name;

-- 方法2：使用聚合函数
SELECT department,
       MAX(name) as sample_name,  -- 或 MIN、ANY_VALUE
       AVG(salary)
FROM employees
GROUP BY department;

-- 方法3：使用 ANY_VALUE（MySQL 5.7+）
SELECT department,
       ANY_VALUE(name) as name,
       AVG(salary)
FROM employees
GROUP BY department;
```

### 误区 2：GROUP BY 会自动排序？

**早期 MySQL 行为：** GROUP BY 会隐式排序

```sql
-- MySQL 5.x
SELECT department, COUNT(*)
FROM employees
GROUP BY department;
-- 结果自动按 department 排序
```

**现代数据库：** 不保证顺序！

```sql
-- MySQL 8.0+, PostgreSQL, Oracle
SELECT department, COUNT(*)
FROM employees
GROUP BY department;
-- 结果顺序不确定！
```

**正确做法：** 显式使用 ORDER BY

```sql
SELECT department, COUNT(*)
FROM employees
GROUP BY department
ORDER BY department;  -- 明确指定排序
```

### 误区 3：NULL 值的处理

**问题：** NULL 值如何分组？

```sql
-- 示例数据
| id | department |
|----|------------|
| 1  | Sales      |
| 2  | NULL       |
| 3  | NULL       |
| 4  | IT         |

-- GROUP BY 查询
SELECT department, COUNT(*) as count
FROM employees
GROUP BY department;

-- 结果：NULL 被当作一个组
| department | count |
|------------|-------|
| Sales      | 1     |
| IT         | 1     |
| NULL       | 2     |  ← NULL 自成一组
```

**注意事项：**
```sql
-- COUNT(*) 统计包括 NULL
SELECT department, COUNT(*) as total
FROM employees
GROUP BY department;
-- NULL 组的 count 是 2

-- COUNT(列) 不统计 NULL 值
SELECT department, COUNT(department) as non_null_count
FROM employees
GROUP BY department;
-- 结果：
| department | non_null_count |
|------------|----------------|
| Sales      | 1              |
| IT         | 1              |
| NULL       | 0              |  ← COUNT(department) 不统计 NULL
```

### 误区 4：HAVING 可以替代 WHERE？

**错误理解：** HAVING 和 WHERE 可以互换

```sql
-- ❌ 错误：用 HAVING 过滤单行
SELECT department, AVG(salary)
FROM employees
GROUP BY department
HAVING department = 'Sales';  -- 低效！

-- ✅ 正确：用 WHERE 过滤单行
SELECT department, AVG(salary)
FROM employees
WHERE department = 'Sales'
GROUP BY department;
```

**性能差异：**
- HAVING：先分组所有数据，再过滤分组结果
- WHERE：先过滤数据，再分组（更快）

### 误区 5：聚合函数嵌套

```sql
-- ❌ 错误：聚合函数不能嵌套
SELECT department, MAX(AVG(salary))
FROM employees
GROUP BY department;
-- Error: Invalid use of group function

-- ✅ 正确：使用子查询
SELECT MAX(avg_salary)
FROM (
    SELECT department, AVG(salary) as avg_salary
    FROM employees
    GROUP BY department
) dept_avg;
```

### 误区 6：GROUP BY 与 DISTINCT 的混淆

```sql
-- 去重的两种方式
-- 方法1：DISTINCT
SELECT DISTINCT department
FROM employees;

-- 方法2：GROUP BY
SELECT department
FROM employees
GROUP BY department;
```

**区别：**
- DISTINCT：简单去重，无法使用聚合函数
- GROUP BY：分组，支持聚合函数

**性能：**
- 简单去重：DISTINCT 通常更快
- 需要聚合：必须用 GROUP BY

---

## 不同数据库的实现差异

### MySQL

**特点：**
1. **ONLY_FULL_GROUP_BY** 模式（5.7+）
2. 支持 **GROUP_CONCAT** 字符串聚合
3. 支持 **ROLLUP**，不支持 CUBE

```sql
-- GROUP_CONCAT（MySQL 特有）
SELECT department,
       GROUP_CONCAT(name ORDER BY name SEPARATOR ', ') as employees
FROM employees
GROUP BY department;

-- 结果：
| department | employees           |
|------------|---------------------|
| Sales      | Alice, Bob, Carol   |
| IT         | David, Eve          |

-- ROLLUP
SELECT department, position, COUNT(*)
FROM employees
GROUP BY department, position WITH ROLLUP;
```

**配置：**
```sql
-- 查看当前 SQL MODE
SELECT @@sql_mode;

-- 关闭 ONLY_FULL_GROUP_BY
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
```

### PostgreSQL

**特点：**
1. 严格遵循 SQL 标准
2. 支持 **FILTER** 子句
3. 支持 **STRING_AGG**、**ARRAY_AGG**、**JSON_AGG**

```sql
-- FILTER 子句（PostgreSQL 9.4+）
SELECT department,
       COUNT(*) as total,
       COUNT(*) FILTER (WHERE salary > 5000) as high_earners
FROM employees
GROUP BY department;

-- STRING_AGG
SELECT department,
       STRING_AGG(name, ', ' ORDER BY name) as employees
FROM employees
GROUP BY department;

-- ARRAY_AGG
SELECT department,
       ARRAY_AGG(name ORDER BY name) as employees
FROM employees
GROUP BY department;
-- 结果：employees 是数组类型

-- JSON_AGG
SELECT department,
       JSON_AGG(JSON_BUILD_OBJECT('name', name, 'salary', salary)) as employees
FROM employees
GROUP BY department;
```

### Oracle

**特点：**
1. 支持 **LISTAGG** 字符串聚合
2. 支持 **GROUPING SETS**、**ROLLUP**、**CUBE**
3. 支持 **WITHIN GROUP** 排序

```sql
-- LISTAGG
SELECT department,
       LISTAGG(name, ', ') WITHIN GROUP (ORDER BY name) as employees
FROM employees
GROUP BY department;

-- GROUPING SETS
SELECT department, position, COUNT(*)
FROM employees
GROUP BY GROUPING SETS (
    (department, position),
    (department),
    ()
);

-- CUBE
SELECT region, product, SUM(sales)
FROM sales_data
GROUP BY CUBE(region, product);
```

### SQL Server

**特点：**
1. 支持 **STRING_AGG**（SQL Server 2017+）
2. 支持 **GROUPING SETS**、**ROLLUP**、**CUBE**
3. 不支持别名在 HAVING 中使用

```sql
-- STRING_AGG（SQL Server 2017+）
SELECT department,
       STRING_AGG(name, ', ') WITHIN GROUP (ORDER BY name) as employees
FROM employees
GROUP BY department;

-- ROLLUP
SELECT department, position, COUNT(*)
FROM employees
GROUP BY ROLLUP(department, position);

-- ❌ 不支持别名在 HAVING
SELECT department, AVG(salary) as avg_salary
FROM employees
GROUP BY department
HAVING avg_salary > 6000;  -- 错误！

-- ✅ 必须重复表达式
HAVING AVG(salary) > 6000;
```

### SQLite

**特点：**
1. 轻量级，功能有限
2. 不支持 ROLLUP、CUBE
3. 支持 **GROUP_CONCAT**

```sql
-- GROUP_CONCAT
SELECT department,
       GROUP_CONCAT(name, ', ') as employees
FROM employees
GROUP BY department;
```

---

## 总结

### GROUP BY 的本质
- **分组聚合**：将数据按某些列的值分组，对每组应用聚合函数
- **诞生于 1974 年**：IBM System R 项目
- **成为标准于 1986 年**：SQL-86 标准

### HAVING 的本质
- **分组过滤**：过滤 GROUP BY 的分组结果
- **与 WHERE 互补**：WHERE 过滤单行，HAVING 过滤分组
- **执行顺序**：WHERE → GROUP BY → HAVING

### 使用原则

1. **能用 WHERE 就用 WHERE**：性能更好
2. **需要聚合函数时用 HAVING**：HAVING 的专属领域
3. **显式 ORDER BY**：不依赖隐式排序
4. **注意 NULL 值**：NULL 自成一组
5. **索引优化**：为 GROUP BY 列创建索引
6. **遵循标准**：SELECT 列必须在 GROUP BY 中或使用聚合函数

### 发展趋势

- **窗口函数**：部分场景替代 GROUP BY
- **OLAP 函数**：ROLLUP、CUBE、GROUPING SETS
- **新聚合函数**：STRING_AGG、JSON_AGG、ARRAY_AGG
- **性能优化**：并行执行、向量化计算

---

**GROUP BY 和 HAVING 是 SQL 中最强大的工具之一，掌握它们是成为数据库高手的必经之路！**
