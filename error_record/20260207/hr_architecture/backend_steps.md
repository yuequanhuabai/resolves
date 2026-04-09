# 後端實施步驟

## 階段一：項目初始化

### Step 1：創建 Maven 多模塊項目 ✅ 已完成

#### 1.1 IDEA 操作步驟

1. **File → New → Project**，選擇 **Maven Archetype**
   - Name: `hr-backend`，GroupId: `com.hr`，ArtifactId: `hr-backend`
   - Archetype: `maven-archetype-quickstart`，JDK: 17
2. 創建後**刪除 `src` 目錄**（父工程不需要代碼）
3. **右鍵 `hr-backend` → New → Module**，依次創建 4 個子模塊：
   - `hr-common`、`hr-framework`、`hr-system`、`hr-admin`
   - 每個模塊都選 Maven Archetype + `maven-archetype-quickstart`

#### 1.2 模塊依賴鏈路

```
hr-admin → hr-system → hr-framework → hr-common
   │
   ├── SQL Server 驅動 (runtime)
   ├── Knife4j API 文檔
   └── Spring Boot 打包插件
```

#### 1.3 POM 文件（已配置完成）

**版本統一管理（父 POM properties）：**

| 依賴 | 版本 |
|------|------|
| Spring Boot (parent) | 3.2.5 |
| MyBatis-Plus | 3.5.6 |
| Knife4j | 4.4.0 |
| JJWT | 0.12.5 |
| SQL Server JDBC | 12.6.1.jre11 |
| Fastjson2 | 2.0.49 |
| Lombok | 由 Spring Boot 管理 |

**各子模塊依賴分配：**

| 模塊 | 自身依賴 |
|------|---------|
| hr-common | spring-boot-starter-web, starter-validation, mybatis-plus, fastjson2, commons-lang3 |
| hr-framework | **hr-common**, spring-boot-starter-security, starter-data-redis, jjwt, starter-aop |
| hr-system | **hr-framework** |
| hr-admin | **hr-system**, mssql-jdbc, knife4j, starter-test, spring-boot-maven-plugin |

#### 1.4 知識補充：父 POM 的定位

##### 父 POM 是什麼？

可以把它理解為**一個家庭的「家規」**：

```
hr-backend (父 POM) ← 定規矩的人，自己不寫代碼
├── hr-common        ← 孩子，遵守家規
├── hr-framework     ← 孩子，遵守家規
├── hr-system        ← 孩子，遵守家規
└── hr-admin         ← 孩子，遵守家規
```

父工程**沒有 src 目錄**，它不產生任何代碼，它的 `packaging` 是 `pom`（不是 `jar`）。它只做三件事：

##### 第一件：聲明「我有哪些孩子」

```xml
<modules>
    <module>hr-common</module>
    <module>hr-framework</module>
    <module>hr-system</module>
    <module>hr-admin</module>
</modules>
```

**目的**：當你在父工程執行 `mvn clean compile` 時，Maven 會自動按順序編譯所有子模塊。不用一個一個去編譯。

##### 第二件：統一管理依賴版本（最重要）

這就是 `<dependencyManagement>` 的作用。

**問題場景**：假設你有 4 個子模塊都要用 MyBatis-Plus，如果每個子模塊各自寫版本號：

```xml
<!-- hr-common 裡寫 -->
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-spring-boot3-starter</artifactId>
    <version>3.5.6</version>   ← 版本寫在這
</dependency>

<!-- hr-framework 裡也寫 -->
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-spring-boot3-starter</artifactId>
    <version>3.5.5</version>   ← 哎，手抖寫了不同版本
</dependency>
```

**災難**：版本不一致，運行時可能出現詭異的兼容性問題，而且升級時要改好幾個地方。

**解法**：在父 POM 用 `<dependencyManagement>` 統一聲明版本：

```xml
<!-- 父 POM：只「聲明」版本，不「引入」依賴 -->
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.baomidou</groupId>
            <artifactId>mybatis-plus-spring-boot3-starter</artifactId>
            <version>3.5.6</version>   ← 版本只在這裡定義一次
        </dependency>
    </dependencies>
</dependencyManagement>
```

然後子模塊引用時**不寫版本號**，自動繼承父 POM 的版本：

```xml
<!-- hr-common 子模塊：只寫 groupId + artifactId，不寫 version -->
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-spring-boot3-starter</artifactId>
    <!-- 不寫 version，自動用父 POM 定義的 3.5.6 -->
</dependency>
```

**關鍵區別：**

| 標籤 | 作用 |
|------|------|
| `<dependencyManagement>` | **只聲明版本**，子模塊不會自動獲得這個依賴，需要自己手動引用（但不用寫版本） |
| `<dependencies>` | **真正引入依賴**，寫在父 POM 的 `<dependencies>` 裡，所有子模塊都會自動獲得 |

所以父 POM 裡：

```xml
<!-- dependencyManagement：聲明版本，子模塊按需引用 -->
<dependencyManagement>
    <dependencies>
        <dependency>mybatis-plus ... 3.5.6</dependency>
        <dependency>knife4j ... 4.4.0</dependency>
        <dependency>jjwt ... 0.12.5</dependency>
        ...
    </dependencies>
</dependencyManagement>

<!-- dependencies：所有子模塊都自動獲得 Lombok -->
<dependencies>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
    </dependency>
</dependencies>
```

Lombok 放在 `<dependencies>` 裡，因為每個模塊都需要它。其它依賴放在 `<dependencyManagement>` 裡，讓子模塊按需選用。

##### 第三件：繼承 Spring Boot Parent

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.2.5</version>
</parent>
```

**這行的作用巨大**。Spring Boot Parent 自帶了幾百個常用庫的版本管理。所以子模塊裡寫：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <!-- 不用寫版本！Spring Boot Parent 已經管好了 -->
</dependency>
```

**繼承鏈**：

```
Spring Boot Parent (管了幾百個常用庫版本)
  └── hr-backend 父 POM (管了我們自己選的庫版本)
        ├── hr-common (繼承以上全部)
        ├── hr-framework
        ├── hr-system
        └── hr-admin
```

##### 父 POM 修改前後對比

| 項目 | IDEA 自動生成的 | 修改後的 |
|------|----------------|---------|
| parent | 無 | **Spring Boot 3.2.5** |
| packaging | pom ✓ | pom ✓（已正確） |
| properties | 只有 encoding + compiler | 加了**所有第三方庫版本號** |
| dependencyManagement | 只有 JUnit | 加了 **MyBatis-Plus、Knife4j、JJWT、SQL Server、子模塊自身**的版本管理 |
| dependencies | JUnit | 改為 **Lombok**（全模塊公用） |
| pluginManagement | 一堆 Maven 默認插件 | **刪掉了**（Spring Boot Parent 已管理） |

##### 一句話總結

> **父 POM = 不寫代碼，只管版本和規矩。** 改版本只改一個地方，所有子模塊自動生效。

#### 1.5 知識補充：四個子模塊 POM 的修改詳解

##### 統一做的事：清理 IDEA 自動生成的垃圾

IDEA 自動生成的每個子模塊都帶有重複內容（以 hr-common 為例）：

```xml
<!-- IDEA 自動生成的，全是重複的 -->
<properties>                          ← 刪掉，繼承父 POM
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <maven.compiler.release>17</maven.compiler.release>
</properties>

<dependencyManagement>                ← 刪掉，繼承父 POM
    <dependencies>
        <dependency>junit-bom...</dependency>
    </dependencies>
</dependencyManagement>

<dependencies>                        ← 刪掉 JUnit，換成模塊真正需要的依賴
    <dependency>junit-jupiter-api</dependency>
    <dependency>junit-jupiter-params</dependency>
</dependencies>

<build>
    <pluginManagement>                ← 刪掉，繼承父 POM → Spring Boot Parent
        <plugins>10 個 Maven 默認插件...</plugins>
    </pluginManagement>
</build>

<url>http://www.example.com</url>     ← 刪掉，無用
<!-- FIXME change it to the project's website --> ← 刪掉
```

清理完後，每個子模塊的 POM 只剩下真正有意義的東西：**parent 引用 + artifactId + 自己需要的依賴**。

##### hr-common（公共模塊）

```xml
<dependencies>
    <!-- ① --> <dependency>spring-boot-starter-web</dependency>
    <!-- ② --> <dependency>spring-boot-starter-validation</dependency>
    <!-- ③ --> <dependency>mybatis-plus-spring-boot3-starter</dependency>
    <!-- ④ --> <dependency>fastjson2</dependency>
    <!-- ⑤ --> <dependency>commons-lang3</dependency>
</dependencies>
```

**為什麼需要這些？**

| # | 依賴 | 原因 |
|---|------|------|
| ① | starter-web | 這個模塊要寫 `GlobalExceptionHandler`（全局異常處理器），它用到 `@RestControllerAdvice`，這個註解來自 Spring Web |
| ② | starter-validation | 這個模塊要定義 DTO 的校驗規則，比如 `@NotBlank`、`@Email`，這些註解來自 validation |
| ③ | mybatis-plus | 這個模塊要寫 `BaseEntity`（基礎實體），裡面要用 `@TableId`、`@TableLogic`、`@TableField` 等 MyBatis-Plus 註解 |
| ④ | fastjson2 | JSON 工具，工具類中用於序列化/反序列化 |
| ⑤ | commons-lang3 | Apache 的字符串工具，比如 `StringUtils.isBlank()`，比自己寫更可靠 |

**定位**：hr-common 是**最底層**的模塊，所有其它模塊都直接或間接依賴它。所以放在這裡的依賴，上層模塊都能用到。

##### hr-framework（框架模塊）

```xml
<dependencies>
    <!-- ① --> <dependency>hr-common</dependency>
    <!-- ② --> <dependency>spring-boot-starter-security</dependency>
    <!-- ③ --> <dependency>spring-boot-starter-data-redis</dependency>
    <!-- ④ --> <dependency>jjwt-api</dependency>
                <dependency>jjwt-impl (runtime)</dependency>
                <dependency>jjwt-jackson (runtime)</dependency>
    <!-- ⑤ --> <dependency>spring-boot-starter-aop</dependency>
</dependencies>
```

**為什麼需要這些？**

| # | 依賴 | 原因 |
|---|------|------|
| ① | hr-common | 框架模塊要用公共模塊的工具類、異常類、基礎實體。**這就是模塊間的依賴關係** |
| ② | starter-security | 這個模塊要配置 Spring Security — 登入認證、權限校驗、401/403 處理器 |
| ③ | starter-data-redis | 這個模塊要把用戶登入信息（Token → 用戶權限）緩存到 Redis |
| ④ | jjwt (3 個包) | JWT Token 的生成和解析。拆成 3 個包是 JJWT 官方的設計：api 是接口、impl 是實現、jackson 是序列化。impl 和 jackson 標記為 `runtime`，因為代碼裡只調用 api 的接口，運行時才需要實現 |
| ⑤ | starter-aop | 這個模塊要寫操作日誌切面 `@Log`，AOP 切面需要這個依賴 |

**定位**：hr-framework 是**技術基礎設施層**，不包含任何業務邏輯，只提供安全、緩存、日誌等通用能力。

##### hr-system（業務模塊）

```xml
<dependencies>
    <!-- 只有一個 -->
    <dependency>hr-framework</dependency>
</dependencies>
```

**就這麼簡單？是的。** 原因是 **Maven 依賴傳遞**：

```
hr-system 依賴 hr-framework
    → hr-framework 依賴 hr-common
        → hr-common 依賴 starter-web, mybatis-plus, ...
```

所以 hr-system 只寫了一個 `hr-framework`，但實際上它能用到整條鏈上所有的依賴：

```
hr-system 能用的依賴：
├── hr-framework 帶來的：Security, Redis, JWT, AOP
├── hr-common 帶來的：starter-web, validation, mybatis-plus, fastjson2, commons-lang3
└── 父 POM 帶來的：Lombok
```

**定位**：hr-system 是**純業務層**，裡面放用戶、角色、部門、崗位的 Entity、Mapper、Service。它不需要直接引入任何第三方庫，因為底層模塊已經全帶上來了。

##### hr-admin（啟動模塊）

```xml
<dependencies>
    <!-- ① --> <dependency>hr-system</dependency>
    <!-- ② --> <dependency>mssql-jdbc (runtime)</dependency>
    <!-- ③ --> <dependency>knife4j-openapi3-jakarta-spring-boot-starter</dependency>
    <!-- ④ --> <dependency>spring-boot-starter-test (test)</dependency>
</dependencies>

<build>
    <plugins>
        <!-- ⑤ --> <plugin>spring-boot-maven-plugin</plugin>
    </plugins>
</build>
```

**為什麼需要這些？**

| # | 依賴 | 原因 |
|---|------|------|
| ① | hr-system | 傳遞依賴拿到整條鏈：system → framework → common |
| ② | mssql-jdbc | SQL Server 數據庫驅動。標記為 `runtime` 是因為代碼裡不直接 `import` 它，只有運行時 JDBC 才需要加載驅動類。**驅動放在啟動模塊而不是 common**，是因為只有最終啟動的應用才需要知道用什麼數據庫，底層模塊不該關心 |
| ③ | knife4j | API 文檔界面。放在啟動模塊，因為只有啟動模塊對外暴露 HTTP 接口 |
| ④ | starter-test | 單元測試。`scope=test` 表示只在跑測試時有效，打包時不包含 |
| ⑤ | spring-boot-maven-plugin | **只在這個模塊配置**。這個插件把項目打成可執行的 fat jar（包含所有依賴）。只有啟動模塊需要打成可執行 jar，其它模塊是普通的 library jar |

**定位**：hr-admin 是**最頂層**的模塊，是唯一能啟動的模塊。它包含啟動類、Controller、配置文件。

##### 四個模塊全局視圖

```
                 依賴方向 →

hr-admin          hr-system          hr-framework        hr-common
(啟動+API)         (業務邏輯)          (技術能力)           (基礎工具)
┌──────────┐     ┌──────────┐      ┌──────────┐       ┌──────────┐
│ 啟動類    │     │ Entity   │      │ Security │       │ BaseEntity│
│ Controller│────▶│ Mapper   │─────▶│ JWT      │──────▶│ R<T>     │
│ 配置文件  │     │ Service  │      │ Redis    │       │ 異常處理  │
│          │     │ DTO      │      │ AOP 日誌  │       │ 工具類   │
├──────────┤     └──────────┘      └──────────┘       └──────────┘
│ 獨有依賴：│
│ SQL Server│
│ Knife4j  │
│ 打包插件  │
└──────────┘
```

**一句話原則**：每個模塊只引入自己「職責範圍內」需要的依賴，通過依賴傳遞獲得下層的能力。這樣後期拆微服務時，每個模塊的邊界是清晰的。

#### 1.6 驗收

- [ ] IDEA Maven 面板能看到 4 個子模塊
- [ ] `mvn clean compile` 無報錯
- [ ] 依賴全部下載成功（無紅線）

---

### Step 2：配置 hr-admin 啟動模塊 ✅ 已完成

> **前置條件**：Step 1 完成，依賴下載成功

#### 2.1 清理 IDEA 自動生成的模板代碼 ✅

每個子模塊的 `src/main/java` 和 `src/test/java` 下有 IDEA 自動生成的 `App.java` 和 `AppTest.java`，全部刪除。

**刪除的文件清單（共 8 個）：**

| 模塊 | 刪除的文件 | 位置 |
|------|-----------|------|
| hr-common | `App.java` | `src/main/java/com/hr/` |
| hr-common | `AppTest.java` | `src/test/java/com/hr/` |
| hr-framework | `App.java` | `src/main/java/com/hr/` |
| hr-framework | `AppTest.java` | `src/test/java/com/hr/` |
| hr-system | `App.java` | `src/main/java/com/hr/` |
| hr-system | `AppTest.java` | `src/test/java/com/hr/` |
| hr-admin | `App.java` | `src/main/java/com/hr/` |
| hr-admin | `AppTest.java` | `src/test/java/com/hr/` |

**為什麼要刪？**

- 這些是 Maven archetype (`maven-archetype-quickstart`) 自動生成的佔位代碼，內容就是 `System.out.println("Hello World!")`
- 它們的包名是 `com.hr`，但我們實際的包結構是 `com.hr.common`、`com.hr.framework` 等，不在同一個包下
- 如果不刪，後面會跟我們自己寫的類混在一起，造成包結構混亂
- 特別是 4 個模塊都有 `com.hr.App`，**類名完全相同會導致衝突**

#### 2.2 創建包結構 ✅

在每個模塊的 `src/main/java/` 下創建獨立的基礎包，並放入 `package-info.java` 佔位文件：

| 模塊 | 創建的包 | 文件 |
|------|---------|------|
| hr-common | `com.hr.common` | `package-info.java` |
| hr-framework | `com.hr.framework` | `package-info.java` |
| hr-system | `com.hr.system` | `package-info.java` |
| hr-admin | `com.hr.admin` | `package-info.java` |

**為什麼包名不同？**

之前 IDEA 生成的 `App.java` 都在 `com.hr` 包下，4 個模塊共用同一個包名。我們改成每個模塊有獨立的子包：

```
com.hr
├── common      ← hr-common 模塊的代碼都在這裡
├── framework   ← hr-framework 模塊的代碼都在這裡
├── system      ← hr-system 模塊的代碼都在這裡
└── admin       ← hr-admin 模塊的代碼都在這裡
```

這樣每個模塊的代碼邊界清晰，不會互相侵入。

**什麼是 `package-info.java`？**

它是 Java 官方規範中的**包級文檔文件**，作用：
- 讓空目錄被 IDEA 和 Git 識別（空目錄會被忽略）
- 為這個包提供 Javadoc 說明
- 後續這個包裡有了真正的類之後，這個文件可以保留也可以刪除，不影響功能

**後續代碼會放在哪？**

```
com.hr.common       → BaseEntity, R<T>, 異常類, 工具類
com.hr.framework    → SecurityConfig, TokenService, RedisCache
com.hr.system       → SysUser, SysUserMapper, SysUserService
com.hr.admin        → HrApplication, Controller 層
```

#### 2.3 啟動類 HrApplication.java ✅

文件路徑：`hr-admin/src/main/java/com/hr/admin/HrApplication.java`

```java
package com.hr.admin;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;

@SpringBootApplication(
    scanBasePackages = "com.hr",
    exclude = {
        RedisAutoConfiguration.class,
        DataSourceAutoConfiguration.class
    }
)
public class HrApplication {

    public static void main(String[] args) {
        SpringApplication.run(HrApplication.class, args);
        System.out.println("========== 人事管理系統啟動成功 ==========");
    }
}
```

**逐行解釋：**

**① `@SpringBootApplication`**

這是 Spring Boot 的核心註解，它其實等於 3 個註解的組合：

```
@SpringBootApplication
  = @SpringBootConfiguration   → 標記這是一個配置類
  + @EnableAutoConfiguration   → 開啟自動配置（Spring Boot 的魔法）
  + @ComponentScan             → 掃描 Bean（默認掃描當前包及子包）
```

**② `scanBasePackages = "com.hr"`**

這是重點。默認情況下 `@ComponentScan` 只掃描啟動類所在包及其子包，也就是 `com.hr.admin`。但我們的代碼分散在 4 個模塊：

```
com.hr.admin       ← 默認只掃描這裡
com.hr.common      ← 掃不到！
com.hr.framework   ← 掃不到！
com.hr.system      ← 掃不到！
```

設成 `com.hr` 後，4 個模塊的 Bean 全部都能被掃到：

```
com.hr             ← 從這裡開始掃描
├── admin          ✓
├── common         ✓
├── framework      ✓
└── system         ✓
```

**③ `exclude = { RedisAutoConfiguration.class, DataSourceAutoConfiguration.class }`**

這是**臨時措施**。Spring Boot 的自動配置檢測到你引入了 Redis 和 JDBC 的依賴，會自動嘗試連接 Redis 和數據庫。但現在：

- 還沒裝 Redis / 還沒配 Redis 連接信息 → 啟動報錯
- 還沒建數據庫 / 還沒配數據源 → 啟動報錯

所以先排除這兩個自動配置，讓項目能跑起來。後面 Step 3 配好數據庫、Step 7 配好 Redis 後，會把這兩行 exclude 移除。

> ⚠️ 這是臨時措施，Step 3 配好數據庫、Step 7 配好 Redis 後移除 exclude。

**④ `SpringApplication.run(HrApplication.class, args)`**

啟動 Spring Boot 應用。這一行做了非常多事情：
- 創建 Spring 容器
- 掃描所有 Bean
- 執行自動配置
- 啟動內嵌的 Tomcat 服務器

**⑤ `System.out.println("========== 人事管理系統啟動成功 ==========")`**

純粹是為了在控制台看到一個明確的成功標誌，方便確認啟動完成。

#### 2.4 配置文件 ✅

在 `hr-admin/src/main/resources/` 下創建 3 個配置文件：

```
resources/
├── application.yml          ← 主配置（所有環境共用）
├── application-dev.yml      ← 開發環境配置
└── application-prod.yml     ← 生產環境配置
```

##### 為什麼要拆成 3 個文件？

開發和生產環境的數據庫地址、密碼、Redis 地址都不一樣。Spring Boot 的 **Profile 機制**讓你可以按環境拆分配置：

```
application.yml         → 公共配置，永遠加載
application-dev.yml     → 只在 dev 環境加載
application-prod.yml    → 只在 prod 環境加載
```

主配置裡的 `spring.profiles.active: dev` 決定了當前激活哪個環境。部署生產時改成 `prod`（或啟動時加參數 `--spring.profiles.active=prod`）。

三個文件的加載關係：

```
啟動時:
  1. 先加載 application.yml (公共配置)
  2. 讀到 spring.profiles.active: dev
  3. 再加載 application-dev.yml (覆蓋/補充公共配置)
```

如果 dev 和主配置有相同的 key，**dev 的值會覆蓋主配置**。

##### application.yml（主配置）

```yaml
server:
  port: 8080
  servlet:
    context-path: /api

spring:
  profiles:
    active: dev
  servlet:
    multipart:
      max-file-size: 10MB
      max-request-size: 20MB

# MyBatis-Plus
mybatis-plus:
  mapper-locations: classpath*:mapper/**/*.xml
  type-aliases-package: com.hr.system.domain
  configuration:
    map-underscore-to-camel-case: true
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl
  global-config:
    db-config:
      logic-delete-field: deleted
      logic-delete-value: 1
      logic-not-delete-value: 0
      id-type: auto

# Knife4j
knife4j:
  enable: true
  openapi:
    title: 人事管理系統 API
    version: 1.0.0
```

**逐項解釋：**

**① server 配置**

```yaml
server:
  port: 8080                    # 應用端口
  servlet:
    context-path: /api          # 所有接口加 /api 前綴
```

設了 `context-path: /api` 後，所有接口的 URL 都會自動加上 `/api` 前綴：

```
Controller 裡寫的:  /system/user
實際訪問地址:       http://localhost:8080/api/system/user
```

這樣前端代理和 Nginx 反向代理時更清晰，一眼能區分 API 請求和靜態資源。

**② spring.profiles.active**

```yaml
spring:
  profiles:
    active: dev                 # 激活開發環境配置
```

告訴 Spring Boot 去加載 `application-dev.yml`。

**③ multipart 文件上傳限制**

```yaml
spring:
  servlet:
    multipart:
      max-file-size: 10MB      # 單個文件最大 10MB
      max-request-size: 20MB   # 整個請求最大 20MB
```

預留給後續頭像上傳等功能。Spring Boot 默認只允許 1MB，太小了。

**④ MyBatis-Plus 配置**

| 配置 | 作用 |
|------|------|
| `mapper-locations` | 告訴 MyBatis 去哪找 XML 映射文件。`classpath*` 表示搜索所有模塊的 classpath |
| `type-aliases-package` | 配了這個後，XML 裡寫 `resultType="SysUser"` 就行，不用寫全路徑 `com.hr.system.domain.SysUser` |
| `map-underscore-to-camel-case` | 數據庫欄位 `create_time` 自動映射到 Java 的 `createTime`，不用手動一個個配 |
| `log-impl` | 開發時在控制台打印執行的 SQL 語句，方便調試。生產環境要關掉 |
| `logic-delete` | 配了之後，調用 MyBatis-Plus 的 `deleteById()` 不會真的 DELETE，而是 `UPDATE SET deleted=1` |
| `id-type: auto` | 主鍵用數據庫自增（SQL Server 的 IDENTITY） |

**⑤ Knife4j 配置**

```yaml
knife4j:
  enable: true                          # 開啟 API 文檔
  openapi:
    title: 人事管理系統 API              # 文檔標題
    version: 1.0.0                      # 版本號
```

開啟後，啟動應用訪問 `/api/doc.html` 就能看到交互式 API 文檔。

##### application-dev.yml（開發環境）

```yaml
spring:
  datasource:
    driver-class-name: com.microsoft.sqlserver.jdbc.SQLServerDriver
    url: jdbc:sqlserver://localhost:1433;databaseName=hr_db;encrypt=true;trustServerCertificate=true
    username: sa
    password: your_password_here        # ⚠️ 需改成自己的密碼

  data:
    redis:
      host: localhost
      port: 6379
      password:
      database: 0

# JWT
jwt:
  secret: HrSystemSecretKey2024ForJwtTokenGenerationAndValidation
  expiration: 1800
```

**逐項解釋：**

**① SQL Server 數據源**

| 參數 | 含義 |
|------|------|
| `localhost:1433` | SQL Server 默認端口 |
| `databaseName=hr_db` | 數據庫名（Step 3 會創建） |
| `encrypt=true;trustServerCertificate=true` | SQL Server JDBC 新版要求加密連接，`trustServerCertificate=true` 表示信任自簽證書（開發環境用） |

**② Redis**

```yaml
  data:
    redis:
      host: localhost
      port: 6379
      password:                         # 空表示無密碼
      database: 0                       # 使用 0 號庫
```

**③ JWT**

```yaml
jwt:
  secret: HrSystemSecretKey2024ForJwtTokenGenerationAndValidation
  expiration: 1800                      # Token 過期時間，1800 秒 = 30 分鐘
```

這是自定義配置，不是 Spring Boot 內建的。後面 Step 9 寫 `TokenService` 時會用 `@Value("${jwt.secret}")` 讀取這些值。

##### application-prod.yml（生產環境，佔位）

```yaml
spring:
  datasource:
    driver-class-name: com.microsoft.sqlserver.jdbc.SQLServerDriver
    url: jdbc:sqlserver://prod-server:1433;databaseName=hr_db;encrypt=true;trustServerCertificate=true
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}

  data:
    redis:
      host: ${REDIS_HOST}
      port: 6379
      password: ${REDIS_PASSWORD}
      database: 0

jwt:
  secret: ${JWT_SECRET}
  expiration: 1800
```

和 dev 結構一樣，但密碼全部用**環境變量佔位符**：

```yaml
username: ${DB_USERNAME}       # 從環境變量讀取
password: ${DB_PASSWORD}
```

**為什麼？** 生產環境的密碼不能明文寫在代碼裡（會被提交到 Git），通過環境變量注入更安全。部署時設置環境變量即可：

```bash
export DB_USERNAME=sa
export DB_PASSWORD=實際密碼
java -jar hr-admin.jar --spring.profiles.active=prod
```

#### 2.5 啟動驗證 ✅

##### 驗證過程

1. 先執行 `mvn install -DskipTests` 安裝所有模塊到本地 Maven 倉庫（模塊間依賴需要先安裝才能找到）
2. 執行 `mvn spring-boot:run` 啟動應用
3. 訪問 `http://localhost:8080/api/` 驗證

##### 驗證結果

啟動成功，關鍵日誌：

```
Tomcat started on port 8080 (http) with context path '/api'
Started HrApplication in 1.863 seconds
========== 人事管理系統啟動成功 ==========
```

訪問 `http://localhost:8080/api/` 返回 **401**（正確 — Spring Security 默認攔截所有未認證請求）。

##### 注意事項

- 如果 8080 端口被其它程式佔用，可以修改 `application.yml` 中的 `server.port` 為其它空閒端口（如 8081）
- 目前 `Using generated security password: xxx` 的 WARN 是正常的，Step 9 配置 Spring Security 後會消失
- 目前排除了 DataSource 和 Redis 自動配置，後續步驟配好後會移除 exclude

#### 2.6 驗收清單

- [x] 模板代碼（8 個 App/AppTest 文件）已刪除
- [x] 4 個模塊基礎包結構已創建
- [x] 啟動類 HrApplication.java 已創建
- [x] 3 個配置文件已創建（application.yml / dev / prod）
- [x] 應用能正常啟動，控制台輸出「人事管理系統啟動成功」
- [x] HTTP 請求返回 401（Spring Security 攔截，正常）

完成後進入 → **Step 3：創建 SQL Server 數據庫**

### Step 3：創建 SQL Server 數據庫

1. 創建數據庫 `hr_db`
2. 執行建表腳本 (參考 backend_architecture.md 第二節)：
   - sys_user
   - sys_dept
   - sys_post
   - sys_role
   - sys_menu
   - sys_user_role
   - sys_role_menu
   - sys_role_dept
   - sys_oper_log
3. 創建索引
4. 插入初始化數據：
   - 超級管理員帳號 (admin / admin123)
   - 頂級部門
   - 基礎崗位
   - 管理員角色
   - 系統菜單 + 按鈕權限

---

## 階段二：公共模塊 (hr-common)

### Step 4：基礎設施

1. 創建 `BaseEntity.java` — 公共欄位 (createBy, createTime, updateBy, updateTime, deleted)
2. 創建 `R<T>` — 統一響應體
3. 創建 `PageResult<T>` — 分頁響應體
4. 創建 `PageQuery` — 分頁請求參數 (pageNum, pageSize)
5. 創建常量類 `Constants.java`、`HttpStatus.java`
6. 創建枚舉類 `StatusEnum`、`GenderEnum`、`MenuTypeEnum`、`DataScopeEnum`

### Step 5：異常處理

1. 創建 `BusinessException.java` — 業務異常
2. 創建 `GlobalExceptionHandler.java` — 全局異常處理器
   - 處理 BusinessException → 400
   - 處理 MethodArgumentNotValidException → 400
   - 處理 AccessDeniedException → 403
   - 處理 Exception → 500

### Step 6：工具類

1. `SecurityUtils.java` — 獲取當前登入用戶 ID、用戶名、部門 ID
2. `TreeUtils.java` — 列表轉樹形結構通用方法
3. 其它工具類按需添加

---

## 階段三：框架模塊 (hr-framework)

### Step 7：Redis 配置

1. 引入 spring-boot-starter-data-redis
2. 創建 `RedisConfig.java` — Jackson 序列化配置
3. 創建 `RedisCache.java` — 封裝常用操作 (set/get/delete/expire)

### Step 8：MyBatis-Plus 配置

1. 創建 `MybatisPlusConfig.java`：
   - 分頁插件 `PaginationInnerInterceptor`
   - 自動填充處理器 (createTime, updateTime)
   - 邏輯刪除配置

### Step 9：Spring Security + JWT

1. 創建 `LoginUser.java` — 實現 UserDetails，包含用戶信息 + 權限集合
2. 創建 `TokenService.java`：
   - `createToken(LoginUser)` — 生成 JWT，用戶信息存 Redis
   - `parseToken(token)` — 解析 Token，從 Redis 取用戶信息
   - `refreshToken(LoginUser)` — 刷新過期時間
3. 創建 `JwtAuthenticationFilter.java`：
   - 繼承 OncePerRequestFilter
   - 從 Header 取 Token → 解析 → 設入 SecurityContext
4. 創建 `UserDetailsServiceImpl.java`：
   - 實現 UserDetailsService
   - 根據 username 查詢用戶 + 角色 + 權限
5. 創建 `SecurityConfig.java`：
   - 放行登入接口、Swagger 文檔
   - 註冊 JWT 過濾器
   - 禁用 CSRF、Session
   - 配置 401/403 處理器
6. 創建 `PermissionService.java`：
   - `hasPerms(String perm)` — 校驗當前用戶是否有指定權限
   - 註冊為 Spring Bean `@Component("perm")`
   - Controller 使用: `@PreAuthorize("@perm.hasPerms('sys:user:list')")`

### Step 10：跨域配置

1. 創建 `CorsConfig.java` — 允許前端開發服務器跨域

### Step 11：操作日誌

1. 創建 `@Log` 註解
2. 創建 `LogAspect.java` — AOP 切面，攔截標註了 @Log 的 Controller 方法
3. 異步寫入 sys_oper_log 表

---

## 階段四：業務模塊 (hr-system)

### Step 12：實體類

按 backend_architecture.md 數據庫設計，創建：
1. `SysUser.java` (含 @TableLogic deleted)
2. `SysDept.java`
3. `SysPost.java`
4. `SysRole.java`
5. `SysMenu.java`
6. `SysUserRole.java`
7. `SysRoleMenu.java`
8. `SysRoleDept.java`

### Step 13：部門管理 (優先，因為用戶依賴部門)

1. `SysDeptMapper.java` + `SysDeptMapper.xml`
   - 查詢部門列表
   - 根據角色 ID 查詢部門 ID 集合 (數據權限)
2. `ISysDeptService.java` + `SysDeptServiceImpl.java`
   - 查詢部門列表 (返回樹形)
   - 新增部門 (自動維護 ancestors)
   - 修改部門 (級聯更新子部門 ancestors)
   - 刪除部門 (校驗是否有子部門或用戶)
3. `SysDeptController.java`

### Step 14：崗位管理

1. `SysPostMapper.java` — 基本 CRUD (MyBatis-Plus 內置即可)
2. `ISysPostService.java` + `SysPostServiceImpl.java`
   - 分頁查詢
   - 新增 (校驗編碼唯一)
   - 修改
   - 刪除 (校驗是否有用戶關聯)
3. `SysPostController.java`

### Step 15：菜單管理

1. `SysMenuMapper.java` + `SysMenuMapper.xml`
   - 查詢所有菜單列表
   - 根據用戶 ID 查詢權限標識集合
   - 根據用戶 ID 查詢菜單樹
   - 根據角色 ID 查詢已選菜單 ID
2. `ISysMenuService.java` + `SysMenuServiceImpl.java`
   - 查詢菜單樹
   - 新增/修改/刪除菜單
   - 構建前端路由所需結構 (RouterVO)
3. `SysMenuController.java`

### Step 16：角色管理

1. `SysRoleMapper.java` + `SysRoleMapper.xml`
   - 分頁查詢角色
   - 根據用戶 ID 查詢角色列表
2. `ISysRoleService.java` + `SysRoleServiceImpl.java`
   - 分頁查詢
   - 新增角色 (同時插入 sys_role_menu)
   - 修改角色 (同時更新 sys_role_menu)
   - 刪除角色 (校驗是否有用戶關聯)
   - 修改數據權限 (更新 data_scope + sys_role_dept)
3. `SysRoleController.java`

### Step 17：用戶管理

1. `SysUserMapper.java` + `SysUserMapper.xml`
   - 分頁查詢用戶 (關聯部門名稱)
   - 根據 username 查詢用戶 (登入用)
   - 數據權限 SQL 預留
2. `ISysUserService.java` + `SysUserServiceImpl.java`
   - 分頁查詢 (支持按部門、用戶名、手機、狀態篩選)
   - 查詢用戶詳情 (含角色列表、崗位信息)
   - 新增用戶 (密碼 BCrypt 加密，插入 sys_user_role)
   - 修改用戶 (更新 sys_user_role)
   - 刪除用戶 (不允許刪除 admin)
   - 重置密碼
   - 修改狀態
3. `SysUserController.java`

### Step 18：數據權限攔截器

1. 創建 `@DataScope` 註解 — 標註在 Service 方法上
2. 創建 `DataScopeInterceptor.java` — MyBatis 攔截器
   - 獲取當前用戶角色的 data_scope
   - 拼接 WHERE 條件
   - 注入到原始 SQL
3. 在 SysUserServiceImpl 的列表查詢方法上添加 `@DataScope`

---

## 階段五：認證接口 (hr-admin)

### Step 19：登入/登出

1. 創建 `AuthController.java`：
   - `POST /auth/login` — 接收帳號密碼，調用 LoginService，返回 Token
   - `POST /auth/logout` — 清除 Redis 中的 Token
   - `GET /auth/info` — 返回當前用戶信息 + 角色標識 + 權限標識集合
   - `GET /auth/routers` — 返回當前用戶的動態菜單路由
2. 創建 `LoginService.java`：
   - 調用 AuthenticationManager 認證
   - 認證成功後生成 Token
   - 記錄登入 IP 和時間

### Step 20：內部接口 (為流程引擎預留)

1. 創建 `InternalApiController.java`：
   - `GET /internal/user/{id}` — 用戶信息
   - `GET /internal/user/dept/{deptId}` — 部門用戶列表
   - `GET /internal/dept/{id}` — 部門信息
   - `GET /internal/dept/{id}/leader` — 部門負責人
   - `GET /internal/role/{roleKey}/users` — 角色用戶列表
2. 當前直接調用 Service，後期抽取為 Feign 接口

---

## 階段六：API 文檔 + 測試

### Step 21：Knife4j 集成

1. 引入 knife4j-openapi3-jakarta-spring-boot-starter
2. 配置 Swagger 分組 (認證接口、系統管理、內部接口)
3. Controller 添加 @Tag、@Operation 註解
4. 驗證: 訪問 /doc.html 查看文檔

### Step 22：接口測試

1. 測試登入接口，獲取 Token
2. 使用 Token 測試各模塊 CRUD
3. 測試權限控制：
   - 未登入訪問 → 401
   - 無權限訪問 → 403
   - 數據權限過濾是否生效
4. 測試邊界情況：
   - 刪除有子部門的部門 → 提示錯誤
   - 刪除有用戶的角色 → 提示錯誤
   - 用戶名重複 → 提示錯誤

---

## 階段七：初始化數據腳本

### Step 23：編寫初始化 SQL

```
插入順序:
  1. sys_dept   — 頂級公司 + 基礎部門
  2. sys_post   — 基礎崗位 (董事長/總經理/普通員工)
  3. sys_menu   — 完整菜單樹 (目錄 + 菜單 + 按鈕)
  4. sys_role   — 超級管理員角色 + 普通角色
  5. sys_user   — admin 用戶 (密碼 BCrypt 加密)
  6. sys_user_role  — admin 綁定管理員角色
  7. sys_role_menu  — 管理員角色綁定所有菜單
```

---

## 實施順序總結

```
階段一 (Step 1-3)   項目骨架 + 數據庫         ██░░░░░░░░  預計 Day 1-2
階段二 (Step 4-6)   公共模塊                  ████░░░░░░  預計 Day 2-3
階段三 (Step 7-11)  框架模塊 (安全/認證/攔截)   ██████░░░░  預計 Day 3-5
階段四 (Step 12-18) 業務模塊 (核心 CRUD)       ████████░░  預計 Day 5-9
階段五 (Step 19-20) 認證 + 內部接口            █████████░  預計 Day 9-10
階段六 (Step 21-22) 文檔 + 測試               ██████████  預計 Day 10-11
階段七 (Step 23)    初始化數據                 ██████████  預計 Day 11
```

### 關鍵里程碑

| 里程碑 | 驗收標準 |
|--------|---------|
| M1: 項目能跑 | Spring Boot 啟動成功，連接 SQL Server + Redis |
| M2: 能登入 | 帳號密碼登入 → 返回 Token → Token 訪問受保護接口 |
| M3: CRUD 通 | 用戶/角色/部門/崗位/菜單 全部 CRUD 接口可用 |
| M4: 權限生效 | 角色權限分配 + 數據權限過濾 正常工作 |
| M5: 後端完成 | API 文檔完整，初始化數據就緒，可交付前端對接 |
