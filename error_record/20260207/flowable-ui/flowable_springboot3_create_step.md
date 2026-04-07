# Flowable 7.x + Spring Boot 3 独立流程引擎微服务 — 详细步骤

> 本文档是 [flowable_springboot3_create_core.md](flowable_springboot3_create_core.md) 的配套详细操作指南。
>
> 每个步骤对应主体架构中的一个阶段，包含完整的代码和配置。

---

## 目录

- [步骤 1：初始化项目](#步骤-1初始化项目)
- [步骤 2：引入 Flowable 依赖](#步骤-2引入-flowable-依赖)
- [步骤 3：配置数据源与 Flowable 引擎](#步骤-3配置数据源与-flowable-引擎)
- [步骤 4：编写流程定义 API](#步骤-4编写流程定义-api)
- [步骤 5：编写流程实例 API](#步骤-5编写流程实例-api)
- [步骤 6：编写任务 API](#步骤-6编写任务-api)
- [步骤 7：编写历史记录 API](#步骤-7编写历史记录-api)
- [步骤 8：Docker 打包与部署](#步骤-8docker-打包与部署)

---

## 步骤 1：初始化项目

### 1.1 创建项目目录

```bash
mkdir flowable-engine-server
cd flowable-engine-server
```

### 1.2 创建 pom.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.5</version>
        <relativePath/>
    </parent>

    <groupId>com.example</groupId>
    <artifactId>flowable-engine-server</artifactId>
    <version>1.0.0</version>
    <name>flowable-engine-server</name>
    <description>独立流程引擎微服务</description>

    <properties>
        <java.version>17</java.version>
        <flowable.version>7.1.0</flowable.version>
    </properties>

    <dependencies>
        <!-- 见步骤 2 -->
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

### 1.3 创建启动类

**文件路径**：`src/main/java/com/example/workflow/WorkflowApplication.java`

```java
package com.example.workflow;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class WorkflowApplication {
    public static void main(String[] args) {
        SpringApplication.run(WorkflowApplication.class, args);
    }
}
```

### 1.4 创建目录结构

```bash
mkdir -p src/main/java/com/example/workflow/{config,controller,service,dto/request,dto/response,listener}
mkdir -p src/main/resources/processes
```

---

## 步骤 2：引入 Flowable 依赖

### 2.1 完整 dependencies 配置

在 `pom.xml` 的 `<dependencies>` 中添加：

```xml
<dependencies>
    <!-- Spring Boot Web -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <!-- Flowable 流程引擎 Spring Boot Starter -->
    <dependency>
        <groupId>org.flowable</groupId>
        <artifactId>flowable-spring-boot-starter-process</artifactId>
        <version>${flowable.version}</version>
    </dependency>

    <!-- Flowable REST API（可选，如果想直接暴露 Flowable 原生 REST） -->
    <dependency>
        <groupId>org.flowable</groupId>
        <artifactId>flowable-spring-boot-starter-process-rest</artifactId>
        <version>${flowable.version}</version>
    </dependency>

    <!-- MySQL 驱动 -->
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <scope>runtime</scope>
    </dependency>

    <!-- 连接池 -->
    <dependency>
        <groupId>com.zaxxer</groupId>
        <artifactId>HikariCP</artifactId>
    </dependency>

    <!-- Lombok（简化代码） -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>

    <!-- Knife4j / Swagger（API 文档） -->
    <dependency>
        <groupId>com.github.xiaoymin</groupId>
        <artifactId>knife4j-openapi3-jakarta-spring-boot-starter</artifactId>
        <version>4.5.0</version>
    </dependency>

    <!-- Jackson（JSON 处理，Spring Boot 已自带，显式声明确保版本一致） -->
    <dependency>
        <groupId>com.fasterxml.jackson.core</groupId>
        <artifactId>jackson-databind</artifactId>
    </dependency>

    <!-- 测试 -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### 2.2 依赖说明

| 依赖 | 作用 |
|---|---|
| `flowable-spring-boot-starter-process` | Flowable 流程引擎核心，自动配置引擎、自动建表 |
| `flowable-spring-boot-starter-process-rest` | 暴露 Flowable 原生 REST API（`/process-api/*`） |
| `mysql-connector-j` | MySQL 8.x 驱动 |
| `knife4j-openapi3-jakarta-spring-boot-starter` | Swagger API 文档，访问 `/doc.html` |

### 2.3 注意事项

- Flowable 7.1.0 已适配 `jakarta.*` 命名空间，与 Spring Boot 3 兼容
- 如果不需要 Flowable 原生 REST API，可以去掉 `flowable-spring-boot-starter-process-rest`，只用自己写的 Controller
- 如果遇到依赖冲突，添加以下排除：

```xml
<dependency>
    <groupId>org.flowable</groupId>
    <artifactId>flowable-spring-boot-starter-process</artifactId>
    <version>${flowable.version}</version>
    <exclusions>
        <exclusion>
            <groupId>org.flowable</groupId>
            <artifactId>flowable-spring-boot-starter-security</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

---

## 步骤 3：配置数据源与 Flowable 引擎

### 3.1 application.yml

**文件路径**：`src/main/resources/application.yml`

```yaml
server:
  port: 9090
  servlet:
    context-path: /workflow

spring:
  application:
    name: flowable-engine-server
  profiles:
    active: dev

  # Jackson 配置
  jackson:
    date-format: yyyy-MM-dd HH:mm:ss
    time-zone: Asia/Shanghai
    serialization:
      write-dates-as-timestamps: false

# Flowable 配置
flowable:
  # 自动建表策略：true=启动时自动创建/更新表结构
  database-schema-update: true
  # 启用异步执行器（定时任务、异步服务任务需要）
  async-executor-activate: true
  # 自动部署 resources/processes/ 目录下的流程文件
  check-process-definitions: true
  # 关闭 CMMN/DMN 等不需要的引擎（减少启动时间和表数量）
  cmmn:
    enabled: false
  dmn:
    enabled: false
  app:
    enabled: false
  idm:
    enabled: false
  eventregistry:
    enabled: false

# Knife4j 文档
springdoc:
  swagger-ui:
    path: /swagger-ui.html
  api-docs:
    path: /v3/api-docs
```

### 3.2 application-dev.yml

**文件路径**：`src/main/resources/application-dev.yml`

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/flowable_engine?useUnicode=true&characterEncoding=utf8&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai&nullCatalogMeansCurrent=true
    username: root
    password: root
    hikari:
      minimum-idle: 5
      maximum-pool-size: 20
      idle-timeout: 30000
      max-lifetime: 1800000
      connection-timeout: 30000

# 开发环境打印 SQL
logging:
  level:
    org.flowable: DEBUG
    org.flowable.engine.impl.persistence: DEBUG
```

### 3.3 创建数据库

```sql
-- 在 MySQL 中执行
CREATE DATABASE IF NOT EXISTS flowable_engine
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;
```

> Flowable 启动后会自动创建约 70+ 张表（以 `ACT_` 和 `FLW_` 开头），无需手动建表。

### 3.4 Flowable 引擎配置类

**文件路径**：`src/main/java/com/example/workflow/config/FlowableConfig.java`

```java
package com.example.workflow.config;

import org.flowable.spring.SpringProcessEngineConfiguration;
import org.flowable.spring.boot.EngineConfigurationConfigurer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class FlowableConfig {

    /**
     * Flowable 引擎额外配置
     */
    @Bean
    public EngineConfigurationConfigurer<SpringProcessEngineConfiguration> engineConfigurer() {
        return configuration -> {
            // 设置字体（解决流程图中文乱码）
            configuration.setActivityFontName("宋体");
            configuration.setLabelFontName("宋体");
            configuration.setAnnotationFontName("宋体");
        };
    }
}
```

### 3.5 跨域配置

**文件路径**：`src/main/java/com/example/workflow/config/CorsConfig.java`

```java
package com.example.workflow.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

@Configuration
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowCredentials(true);
        config.addAllowedOriginPattern("*");
        config.addAllowedHeader("*");
        config.addAllowedMethod("*");

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return new CorsFilter(source);
    }
}
```

### 3.6 验证启动

```bash
mvn spring-boot:run
```

启动成功后日志会显示：

```
ProcessEngine default created
Flowable 7.1.0
Started WorkflowApplication in X seconds
```

访问 `http://localhost:9090/workflow/doc.html` 查看 API 文档。

---

## 步骤 4：编写流程定义 API

### 4.1 统一响应类

**文件路径**：`src/main/java/com/example/workflow/dto/response/R.java`

```java
package com.example.workflow.dto.response;

import lombok.Data;

@Data
public class R<T> {
    private int code;
    private String message;
    private T data;

    public static <T> R<T> ok(T data) {
        R<T> r = new R<>();
        r.setCode(200);
        r.setMessage("success");
        r.setData(data);
        return r;
    }

    public static <T> R<T> ok() {
        return ok(null);
    }

    public static <T> R<T> fail(String message) {
        R<T> r = new R<>();
        r.setCode(500);
        r.setMessage(message);
        return r;
    }
}
```

### 4.2 流程定义 VO

**文件路径**：`src/main/java/com/example/workflow/dto/response/ProcessDefinitionVO.java`

```java
package com.example.workflow.dto.response;

import lombok.Data;

@Data
public class ProcessDefinitionVO {
    private String id;
    private String key;
    private String name;
    private int version;
    private String deploymentId;
    private String resourceName;
    private boolean suspended;
}
```

### 4.3 流程定义 Service

**文件路径**：`src/main/java/com/example/workflow/service/ProcessDefinitionService.java`

```java
package com.example.workflow.service;

import com.example.workflow.dto.response.ProcessDefinitionVO;
import lombok.RequiredArgsConstructor;
import org.flowable.engine.RepositoryService;
import org.flowable.engine.repository.Deployment;
import org.flowable.engine.repository.ProcessDefinition;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProcessDefinitionService {

    private final RepositoryService repositoryService;

    /**
     * 部署流程（上传 BPMN 文件）
     */
    public String deploy(String name, MultipartFile file) throws IOException {
        Deployment deployment = repositoryService.createDeployment()
                .name(name)
                .addInputStream(file.getOriginalFilename(), file.getInputStream())
                .deploy();
        return deployment.getId();
    }

    /**
     * 部署流程（传入 BPMN XML 字符串）
     */
    public String deployByXml(String name, String processKey, String bpmnXml) {
        Deployment deployment = repositoryService.createDeployment()
                .name(name)
                .addString(processKey + ".bpmn20.xml", bpmnXml)
                .deploy();
        return deployment.getId();
    }

    /**
     * 查询所有流程定义（每个 Key 只取最新版本）
     */
    public List<ProcessDefinitionVO> list() {
        List<ProcessDefinition> definitions = repositoryService.createProcessDefinitionQuery()
                .latestVersion()
                .orderByProcessDefinitionName()
                .asc()
                .list();

        return definitions.stream().map(this::toVO).collect(Collectors.toList());
    }

    /**
     * 删除部署（级联删除关联的流程实例）
     */
    public void delete(String deploymentId) {
        // true 表示级联删除：同时删除关联的流程实例、任务、历史数据
        repositoryService.deleteDeployment(deploymentId, true);
    }

    /**
     * 获取流程定义的 BPMN XML
     */
    public InputStream getResource(String processDefinitionId) {
        ProcessDefinition definition = repositoryService.createProcessDefinitionQuery()
                .processDefinitionId(processDefinitionId)
                .singleResult();

        return repositoryService.getResourceAsStream(
                definition.getDeploymentId(), definition.getResourceName());
    }

    private ProcessDefinitionVO toVO(ProcessDefinition definition) {
        ProcessDefinitionVO vo = new ProcessDefinitionVO();
        vo.setId(definition.getId());
        vo.setKey(definition.getKey());
        vo.setName(definition.getName());
        vo.setVersion(definition.getVersion());
        vo.setDeploymentId(definition.getDeploymentId());
        vo.setResourceName(definition.getResourceName());
        vo.setSuspended(definition.isSuspended());
        return vo;
    }
}
```

### 4.4 流程定义 Controller

**文件路径**：`src/main/java/com/example/workflow/controller/ProcessDefinitionController.java`

```java
package com.example.workflow.controller;

import com.example.workflow.dto.response.ProcessDefinitionVO;
import com.example.workflow.dto.response.R;
import com.example.workflow.service.ProcessDefinitionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;

@Tag(name = "流程定义", description = "流程部署/查询/删除")
@RestController
@RequestMapping("/api/process")
@RequiredArgsConstructor
public class ProcessDefinitionController {

    private final ProcessDefinitionService processDefinitionService;

    @Operation(summary = "部署流程（上传 BPMN 文件）")
    @PostMapping(value = "/deploy", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public R<String> deploy(
            @RequestParam("name") String name,
            @RequestParam("file") MultipartFile file) throws IOException {
        String deploymentId = processDefinitionService.deploy(name, file);
        return R.ok(deploymentId);
    }

    @Operation(summary = "部署流程（BPMN XML 字符串）")
    @PostMapping("/deploy-xml")
    public R<String> deployByXml(
            @RequestParam("name") String name,
            @RequestParam("processKey") String processKey,
            @RequestBody String bpmnXml) {
        String deploymentId = processDefinitionService.deployByXml(name, processKey, bpmnXml);
        return R.ok(deploymentId);
    }

    @Operation(summary = "查询流程定义列表")
    @GetMapping("/list")
    public R<List<ProcessDefinitionVO>> list() {
        return R.ok(processDefinitionService.list());
    }

    @Operation(summary = "删除部署")
    @DeleteMapping("/delete/{deploymentId}")
    public R<Void> delete(@PathVariable String deploymentId) {
        processDefinitionService.delete(deploymentId);
        return R.ok();
    }

    @Operation(summary = "获取流程定义 XML")
    @GetMapping("/resource/{processDefinitionId}")
    public ResponseEntity<InputStreamResource> getResource(@PathVariable String processDefinitionId) {
        InputStream inputStream = processDefinitionService.getResource(processDefinitionId);
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_XML)
                .body(new InputStreamResource(inputStream));
    }
}
```

---

## 步骤 5：编写流程实例 API

### 5.1 请求 DTO

**文件路径**：`src/main/java/com/example/workflow/dto/request/StartProcessRequest.java`

```java
package com.example.workflow.dto.request;

import lombok.Data;

import java.util.Map;

@Data
public class StartProcessRequest {
    /**
     * 流程定义 Key（对应 BPMN 中的 process id）
     */
    private String processKey;

    /**
     * 业务标识（如订单号、请假单号，用于关联业务数据）
     */
    private String businessKey;

    /**
     * 流程变量（传入审批人、金额、天数等业务数据）
     */
    private Map<String, Object> variables;
}
```

### 5.2 响应 VO

**文件路径**：`src/main/java/com/example/workflow/dto/response/ProcessInstanceVO.java`

```java
package com.example.workflow.dto.response;

import lombok.Data;

import java.util.Date;

@Data
public class ProcessInstanceVO {
    private String instanceId;
    private String processDefinitionId;
    private String processDefinitionKey;
    private String processDefinitionName;
    private String businessKey;
    private String startUserId;
    private Date startTime;
    private boolean suspended;
}
```

### 5.3 流程实例 Service

**文件路径**：`src/main/java/com/example/workflow/service/ProcessInstanceService.java`

```java
package com.example.workflow.service;

import com.example.workflow.dto.request.StartProcessRequest;
import com.example.workflow.dto.response.ProcessInstanceVO;
import lombok.RequiredArgsConstructor;
import org.flowable.engine.RuntimeService;
import org.flowable.engine.runtime.ProcessInstance;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProcessInstanceService {

    private final RuntimeService runtimeService;

    /**
     * 发起流程实例
     */
    public ProcessInstanceVO start(StartProcessRequest request) {
        ProcessInstance instance = runtimeService.createProcessInstanceBuilder()
                .processDefinitionKey(request.getProcessKey())
                .businessKey(request.getBusinessKey())
                .variables(request.getVariables())
                .start();

        return toVO(instance);
    }

    /**
     * 查询运行中的流程实例
     */
    public List<ProcessInstanceVO> listRunning(String processKey) {
        List<ProcessInstance> instances;
        if (processKey != null && !processKey.isEmpty()) {
            instances = runtimeService.createProcessInstanceQuery()
                    .processDefinitionKey(processKey)
                    .orderByProcessInstanceId()
                    .desc()
                    .list();
        } else {
            instances = runtimeService.createProcessInstanceQuery()
                    .orderByProcessInstanceId()
                    .desc()
                    .list();
        }
        return instances.stream().map(this::toVO).collect(Collectors.toList());
    }

    /**
     * 通过 businessKey 查询流程实例
     */
    public ProcessInstanceVO getByBusinessKey(String processKey, String businessKey) {
        ProcessInstance instance = runtimeService.createProcessInstanceQuery()
                .processDefinitionKey(processKey)
                .processInstanceBusinessKey(businessKey)
                .singleResult();
        return instance != null ? toVO(instance) : null;
    }

    /**
     * 挂起流程实例
     */
    public void suspend(String instanceId) {
        runtimeService.suspendProcessInstanceById(instanceId);
    }

    /**
     * 激活流程实例
     */
    public void activate(String instanceId) {
        runtimeService.activateProcessInstanceById(instanceId);
    }

    /**
     * 终止并删除流程实例
     */
    public void delete(String instanceId, String reason) {
        runtimeService.deleteProcessInstance(instanceId, reason);
    }

    private ProcessInstanceVO toVO(ProcessInstance instance) {
        ProcessInstanceVO vo = new ProcessInstanceVO();
        vo.setInstanceId(instance.getProcessInstanceId());
        vo.setProcessDefinitionId(instance.getProcessDefinitionId());
        vo.setProcessDefinitionKey(instance.getProcessDefinitionKey());
        vo.setProcessDefinitionName(instance.getProcessDefinitionName());
        vo.setBusinessKey(instance.getBusinessKey());
        vo.setStartUserId(instance.getStartUserId());
        vo.setStartTime(instance.getStartTime());
        vo.setSuspended(instance.isSuspended());
        return vo;
    }
}
```

### 5.4 流程实例 Controller

**文件路径**：`src/main/java/com/example/workflow/controller/ProcessInstanceController.java`

```java
package com.example.workflow.controller;

import com.example.workflow.dto.request.StartProcessRequest;
import com.example.workflow.dto.response.ProcessInstanceVO;
import com.example.workflow.dto.response.R;
import com.example.workflow.service.ProcessInstanceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "流程实例", description = "发起/查询/挂起/终止流程")
@RestController
@RequestMapping("/api/instance")
@RequiredArgsConstructor
public class ProcessInstanceController {

    private final ProcessInstanceService processInstanceService;

    @Operation(summary = "发起流程实例")
    @PostMapping("/start")
    public R<ProcessInstanceVO> start(@RequestBody StartProcessRequest request) {
        return R.ok(processInstanceService.start(request));
    }

    @Operation(summary = "查询运行中的流程实例")
    @GetMapping("/list")
    public R<List<ProcessInstanceVO>> list(
            @RequestParam(required = false) String processKey) {
        return R.ok(processInstanceService.listRunning(processKey));
    }

    @Operation(summary = "通过 businessKey 查询流程实例")
    @GetMapping("/get-by-business-key")
    public R<ProcessInstanceVO> getByBusinessKey(
            @RequestParam String processKey,
            @RequestParam String businessKey) {
        return R.ok(processInstanceService.getByBusinessKey(processKey, businessKey));
    }

    @Operation(summary = "挂起流程实例")
    @PutMapping("/suspend/{instanceId}")
    public R<Void> suspend(@PathVariable String instanceId) {
        processInstanceService.suspend(instanceId);
        return R.ok();
    }

    @Operation(summary = "激活流程实例")
    @PutMapping("/activate/{instanceId}")
    public R<Void> activate(@PathVariable String instanceId) {
        processInstanceService.activate(instanceId);
        return R.ok();
    }

    @Operation(summary = "终止并删除流程实例")
    @DeleteMapping("/delete/{instanceId}")
    public R<Void> delete(
            @PathVariable String instanceId,
            @RequestParam(defaultValue = "管理员终止") String reason) {
        processInstanceService.delete(instanceId, reason);
        return R.ok();
    }
}
```

---

## 步骤 6：编写任务 API

### 6.1 请求 DTO

**文件路径**：`src/main/java/com/example/workflow/dto/request/CompleteTaskRequest.java`

```java
package com.example.workflow.dto.request;

import lombok.Data;

import java.util.Map;

@Data
public class CompleteTaskRequest {
    /**
     * 任务 ID
     */
    private String taskId;

    /**
     * 审批意见
     */
    private String comment;

    /**
     * 流程变量（可在审批时动态设置变量，如 approved=true）
     */
    private Map<String, Object> variables;
}
```

### 6.2 响应 VO

**文件路径**：`src/main/java/com/example/workflow/dto/response/TaskVO.java`

```java
package com.example.workflow.dto.response;

import lombok.Data;

import java.util.Date;

@Data
public class TaskVO {
    private String taskId;
    private String taskName;
    private String taskDefinitionKey;
    private String assignee;
    private String processInstanceId;
    private String processDefinitionId;
    private String businessKey;
    private Date createTime;
    private boolean suspended;
}
```

### 6.3 任务 Service

**文件路径**：`src/main/java/com/example/workflow/service/FlowableTaskService.java`

```java
package com.example.workflow.service;

import com.example.workflow.dto.request.CompleteTaskRequest;
import com.example.workflow.dto.response.TaskVO;
import lombok.RequiredArgsConstructor;
import org.flowable.engine.RuntimeService;
import org.flowable.engine.TaskService;
import org.flowable.engine.runtime.ProcessInstance;
import org.flowable.task.api.Task;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FlowableTaskService {

    private final TaskService taskService;
    private final RuntimeService runtimeService;

    /**
     * 查询指定用户的待办任务
     */
    public List<TaskVO> getTodoTasks(String assignee) {
        List<Task> tasks = taskService.createTaskQuery()
                .taskAssignee(assignee)
                .orderByTaskCreateTime()
                .desc()
                .list();
        return tasks.stream().map(this::toVO).collect(Collectors.toList());
    }

    /**
     * 查询候选人/候选组的待签收任务
     */
    public List<TaskVO> getCandidateTasks(String userId) {
        List<Task> tasks = taskService.createTaskQuery()
                .taskCandidateUser(userId)
                .orderByTaskCreateTime()
                .desc()
                .list();
        return tasks.stream().map(this::toVO).collect(Collectors.toList());
    }

    /**
     * 签收任务（候选人模式下，先签收再办理）
     */
    public void claim(String taskId, String userId) {
        taskService.claim(taskId, userId);
    }

    /**
     * 完成任务（审批通过）
     */
    public void complete(CompleteTaskRequest request) {
        // 添加审批意见
        if (request.getComment() != null && !request.getComment().isEmpty()) {
            Task task = taskService.createTaskQuery()
                    .taskId(request.getTaskId())
                    .singleResult();
            taskService.addComment(request.getTaskId(),
                    task.getProcessInstanceId(), request.getComment());
        }
        // 完成任务，传入变量
        if (request.getVariables() != null && !request.getVariables().isEmpty()) {
            taskService.complete(request.getTaskId(), request.getVariables());
        } else {
            taskService.complete(request.getTaskId());
        }
    }

    /**
     * 驳回到上一节点
     * 原理：通过 moveActivityIdTo 将当前节点回退到指定节点
     */
    public void reject(String taskId, String comment) {
        Task task = taskService.createTaskQuery()
                .taskId(taskId)
                .singleResult();

        if (comment != null && !comment.isEmpty()) {
            taskService.addComment(taskId, task.getProcessInstanceId(), "驳回：" + comment);
        }

        // 获取上一个用户任务节点（简化处理，实际可根据历史记录查找）
        // 这里使用 Flowable 的 changeActivityState API
        runtimeService.createChangeActivityStateBuilder()
                .processInstanceId(task.getProcessInstanceId())
                .moveActivityIdTo(task.getTaskDefinitionKey(), getStartActivityId(task))
                .changeState();
    }

    /**
     * 转办任务（将任务转交给其他人处理）
     */
    public void delegate(String taskId, String targetUserId) {
        taskService.setAssignee(taskId, targetUserId);
    }

    /**
     * 获取任务详情
     */
    public TaskVO getDetail(String taskId) {
        Task task = taskService.createTaskQuery()
                .taskId(taskId)
                .singleResult();
        return task != null ? toVO(task) : null;
    }

    /**
     * 查询某个流程实例当前的待办任务
     */
    public List<TaskVO> getTasksByInstanceId(String instanceId) {
        List<Task> tasks = taskService.createTaskQuery()
                .processInstanceId(instanceId)
                .orderByTaskCreateTime()
                .asc()
                .list();
        return tasks.stream().map(this::toVO).collect(Collectors.toList());
    }

    /**
     * 获取流程的第一个用户任务节点 ID（用于驳回到发起人）
     * 简化实现：实际项目可根据历史记录精确定位上一节点
     */
    private String getStartActivityId(Task task) {
        // 获取流程实例的历史活动，找到第一个 UserTask
        var activities = org.flowable.engine.ProcessEngines.getDefaultProcessEngine()
                .getHistoryService()
                .createHistoricActivityInstanceQuery()
                .processInstanceId(task.getProcessInstanceId())
                .activityType("userTask")
                .orderByHistoricActivityInstanceStartTime()
                .asc()
                .list();

        if (activities.size() > 1) {
            // 回退到上一个节点
            return activities.get(activities.size() - 2).getActivityId();
        }
        // 如果只有一个节点，回退到自身（重新提交）
        return activities.get(0).getActivityId();
    }

    private TaskVO toVO(Task task) {
        TaskVO vo = new TaskVO();
        vo.setTaskId(task.getId());
        vo.setTaskName(task.getName());
        vo.setTaskDefinitionKey(task.getTaskDefinitionKey());
        vo.setAssignee(task.getAssignee());
        vo.setProcessInstanceId(task.getProcessInstanceId());
        vo.setProcessDefinitionId(task.getProcessDefinitionId());
        vo.setCreateTime(task.getCreateTime());
        vo.setSuspended(task.isSuspended());

        // 查询 businessKey
        ProcessInstance instance = runtimeService.createProcessInstanceQuery()
                .processInstanceId(task.getProcessInstanceId())
                .singleResult();
        if (instance != null) {
            vo.setBusinessKey(instance.getBusinessKey());
        }
        return vo;
    }
}
```

### 6.4 任务 Controller

**文件路径**：`src/main/java/com/example/workflow/controller/TaskController.java`

```java
package com.example.workflow.controller;

import com.example.workflow.dto.request.CompleteTaskRequest;
import com.example.workflow.dto.response.R;
import com.example.workflow.dto.response.TaskVO;
import com.example.workflow.service.FlowableTaskService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "任务管理", description = "待办查询/审批/驳回/转办")
@RestController
@RequestMapping("/api/task")
@RequiredArgsConstructor
public class TaskController {

    private final FlowableTaskService flowableTaskService;

    @Operation(summary = "查询待办任务")
    @GetMapping("/todo")
    public R<List<TaskVO>> getTodoTasks(@RequestParam String assignee) {
        return R.ok(flowableTaskService.getTodoTasks(assignee));
    }

    @Operation(summary = "查询待签收任务（候选人模式）")
    @GetMapping("/candidate")
    public R<List<TaskVO>> getCandidateTasks(@RequestParam String userId) {
        return R.ok(flowableTaskService.getCandidateTasks(userId));
    }

    @Operation(summary = "签收任务")
    @PostMapping("/claim")
    public R<Void> claim(@RequestParam String taskId, @RequestParam String userId) {
        flowableTaskService.claim(taskId, userId);
        return R.ok();
    }

    @Operation(summary = "完成任务（审批通过）")
    @PostMapping("/complete")
    public R<Void> complete(@RequestBody CompleteTaskRequest request) {
        flowableTaskService.complete(request);
        return R.ok();
    }

    @Operation(summary = "驳回任务")
    @PostMapping("/reject")
    public R<Void> reject(
            @RequestParam String taskId,
            @RequestParam(required = false) String comment) {
        flowableTaskService.reject(taskId, comment);
        return R.ok();
    }

    @Operation(summary = "转办任务")
    @PostMapping("/delegate")
    public R<Void> delegate(
            @RequestParam String taskId,
            @RequestParam String targetUserId) {
        flowableTaskService.delegate(taskId, targetUserId);
        return R.ok();
    }

    @Operation(summary = "任务详情")
    @GetMapping("/detail/{taskId}")
    public R<TaskVO> detail(@PathVariable String taskId) {
        return R.ok(flowableTaskService.getDetail(taskId));
    }

    @Operation(summary = "查询流程实例的当前任务")
    @GetMapping("/list-by-instance/{instanceId}")
    public R<List<TaskVO>> listByInstance(@PathVariable String instanceId) {
        return R.ok(flowableTaskService.getTasksByInstanceId(instanceId));
    }
}
```

---

## 步骤 7：编写历史记录 API

### 7.1 历史 Service

**文件路径**：`src/main/java/com/example/workflow/service/FlowableHistoryService.java`

```java
package com.example.workflow.service;

import lombok.RequiredArgsConstructor;
import org.flowable.bpmn.model.BpmnModel;
import org.flowable.engine.HistoryService;
import org.flowable.engine.ProcessEngineConfiguration;
import org.flowable.engine.RepositoryService;
import org.flowable.engine.history.HistoricActivityInstance;
import org.flowable.engine.history.HistoricProcessInstance;
import org.flowable.image.ProcessDiagramGenerator;
import org.flowable.task.api.history.HistoricTaskInstance;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FlowableHistoryService {

    private final HistoryService historyService;
    private final RepositoryService repositoryService;
    private final ProcessEngineConfiguration processEngineConfiguration;

    /**
     * 查询已完成的流程实例
     */
    public List<Map<String, Object>> listFinished(String processKey) {
        var query = historyService.createHistoricProcessInstanceQuery()
                .finished()
                .orderByProcessInstanceEndTime()
                .desc();

        if (processKey != null && !processKey.isEmpty()) {
            query.processDefinitionKey(processKey);
        }

        return query.list().stream().map(instance -> {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("instanceId", instance.getId());
            map.put("processDefinitionId", instance.getProcessDefinitionId());
            map.put("processDefinitionKey", instance.getProcessDefinitionKey());
            map.put("processDefinitionName", instance.getProcessDefinitionName());
            map.put("businessKey", instance.getBusinessKey());
            map.put("startUserId", instance.getStartUserId());
            map.put("startTime", instance.getStartTime());
            map.put("endTime", instance.getEndTime());
            map.put("duration", instance.getDurationInMillis());
            return map;
        }).collect(Collectors.toList());
    }

    /**
     * 查询流程的审批记录（历史活动）
     */
    public List<Map<String, Object>> getActivities(String instanceId) {
        List<HistoricActivityInstance> activities = historyService
                .createHistoricActivityInstanceQuery()
                .processInstanceId(instanceId)
                .orderByHistoricActivityInstanceStartTime()
                .asc()
                .list();

        return activities.stream().map(activity -> {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("activityId", activity.getActivityId());
            map.put("activityName", activity.getActivityName());
            map.put("activityType", activity.getActivityType());
            map.put("assignee", activity.getAssignee());
            map.put("startTime", activity.getStartTime());
            map.put("endTime", activity.getEndTime());
            map.put("duration", activity.getDurationInMillis());
            return map;
        }).collect(Collectors.toList());
    }

    /**
     * 查询流程的审批意见
     */
    public List<Map<String, Object>> getComments(String instanceId) {
        // 查询该流程实例的所有历史任务
        List<HistoricTaskInstance> tasks = historyService.createHistoricTaskInstanceQuery()
                .processInstanceId(instanceId)
                .orderByHistoricTaskInstanceStartTime()
                .asc()
                .list();

        List<Map<String, Object>> result = new ArrayList<>();
        for (HistoricTaskInstance task : tasks) {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("taskId", task.getId());
            map.put("taskName", task.getName());
            map.put("assignee", task.getAssignee());
            map.put("startTime", task.getStartTime());
            map.put("endTime", task.getEndTime());

            // 查询该任务的评论
            var comments = processEngineConfiguration.getTaskService()
                    .getTaskComments(task.getId());
            List<String> commentList = comments.stream()
                    .map(c -> c.getFullMessage())
                    .collect(Collectors.toList());
            map.put("comments", commentList);

            result.add(map);
        }
        return result;
    }

    /**
     * 生成流程图（高亮已执行的节点和连线）
     */
    public InputStream generateDiagram(String instanceId) {
        // 1. 查询历史流程实例
        HistoricProcessInstance historicInstance = historyService
                .createHistoricProcessInstanceQuery()
                .processInstanceId(instanceId)
                .singleResult();

        if (historicInstance == null) {
            throw new RuntimeException("流程实例不存在：" + instanceId);
        }

        // 2. 获取 BPMN 模型
        BpmnModel bpmnModel = repositoryService.getBpmnModel(
                historicInstance.getProcessDefinitionId());

        // 3. 获取已执行的活动节点
        List<HistoricActivityInstance> activities = historyService
                .createHistoricActivityInstanceQuery()
                .processInstanceId(instanceId)
                .list();

        List<String> highLightedActivities = activities.stream()
                .map(HistoricActivityInstance::getActivityId)
                .collect(Collectors.toList());

        // 4. 获取已执行的连线（简化：使用空列表，也可根据活动推算）
        List<String> highLightedFlows = new ArrayList<>();

        // 5. 生成图片
        ProcessDiagramGenerator diagramGenerator =
                processEngineConfiguration.getProcessDiagramGenerator();

        return diagramGenerator.generateDiagram(
                bpmnModel,
                "png",
                highLightedActivities,
                highLightedFlows,
                "宋体", "宋体", "宋体",
                null,
                1.0,
                true);
    }
}
```

### 7.2 历史 Controller

**文件路径**：`src/main/java/com/example/workflow/controller/HistoryController.java`

```java
package com.example.workflow.controller;

import com.example.workflow.dto.response.R;
import com.example.workflow.service.FlowableHistoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.InputStream;
import java.util.List;
import java.util.Map;

@Tag(name = "历史记录", description = "已完成流程/审批记录/流程图")
@RestController
@RequestMapping("/api/history")
@RequiredArgsConstructor
public class HistoryController {

    private final FlowableHistoryService flowableHistoryService;

    @Operation(summary = "查询已完成的流程实例")
    @GetMapping("/instances")
    public R<List<Map<String, Object>>> listFinished(
            @RequestParam(required = false) String processKey) {
        return R.ok(flowableHistoryService.listFinished(processKey));
    }

    @Operation(summary = "查询审批记录（历史活动节点）")
    @GetMapping("/activities/{instanceId}")
    public R<List<Map<String, Object>>> getActivities(@PathVariable String instanceId) {
        return R.ok(flowableHistoryService.getActivities(instanceId));
    }

    @Operation(summary = "查询审批意见")
    @GetMapping("/comments/{instanceId}")
    public R<List<Map<String, Object>>> getComments(@PathVariable String instanceId) {
        return R.ok(flowableHistoryService.getComments(instanceId));
    }

    @Operation(summary = "生成流程图（高亮已执行节点）")
    @GetMapping("/diagram/{instanceId}")
    public ResponseEntity<InputStreamResource> getDiagram(@PathVariable String instanceId) {
        InputStream diagram = flowableHistoryService.generateDiagram(instanceId);
        return ResponseEntity.ok()
                .contentType(MediaType.IMAGE_PNG)
                .body(new InputStreamResource(diagram));
    }
}
```

---

## 步骤 8：Docker 打包与部署

### 8.1 Dockerfile

**文件路径**：项目根目录 `Dockerfile`

```dockerfile
FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="workflow-engine"

# 设置时区
RUN apk add --no-cache tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

# 安装中文字体（流程图中文显示需要）
RUN apk add --no-cache fontconfig ttf-dejavu \
    && fc-cache -fv

WORKDIR /app

COPY target/flowable-engine-server-1.0.0.jar app.jar

EXPOSE 9090

ENTRYPOINT ["java", \
    "-Xms256m", \
    "-Xmx512m", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-jar", \
    "app.jar"]
```

### 8.2 构建镜像

```bash
# 1. 打包
mvn clean package -DskipTests

# 2. 构建 Docker 镜像
docker build -t flowable-engine-server:1.0.0 .
```

### 8.3 运行容器

```bash
docker run -d --name flowable-engine \
  -p 9090:9090 \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://宿主机IP:3306/flowable_engine?useUnicode=true&characterEncoding=utf8&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai&nullCatalogMeansCurrent=true" \
  -e SPRING_DATASOURCE_USERNAME=root \
  -e SPRING_DATASOURCE_PASSWORD=root \
  flowable-engine-server:1.0.0
```

### 8.4 Docker Compose（推荐）

**文件路径**：项目根目录 `docker-compose.yml`

```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: flowable-mysql
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: flowable_engine
      MYSQL_CHARACTER_SET_SERVER: utf8mb4
      MYSQL_COLLATION_SERVER: utf8mb4_general_ci
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
    command: --default-authentication-plugin=mysql_native_password
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  flowable-engine:
    image: flowable-engine-server:1.0.0
    container_name: flowable-engine
    depends_on:
      mysql:
        condition: service_healthy
    ports:
      - "9090:9090"
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/flowable_engine?useUnicode=true&characterEncoding=utf8&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai&nullCatalogMeansCurrent=true
      SPRING_DATASOURCE_USERNAME: root
      SPRING_DATASOURCE_PASSWORD: root

volumes:
  mysql-data:
```

启动：

```bash
docker-compose up -d
```

### 8.5 验证部署

```bash
# 检查容器状态
docker ps

# 查看日志
docker logs -f flowable-engine

# 测试接口
curl http://服务器IP:9090/workflow/api/process/list

# 访问 API 文档
# 浏览器打开：http://服务器IP:9090/workflow/doc.html
```

---

## 附录：完整测试流程

部署成功后，按以下顺序测试：

### A. 准备流程文件

创建一个简单的请假审批 BPMN 文件 `leave-approval.bpmn20.xml`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
             xmlns:flowable="http://flowable.org/bpmn"
             targetNamespace="http://flowable.org/test">

    <process id="leave-approval" name="请假审批" isExecutable="true">

        <startEvent id="start" name="开始"/>

        <sequenceFlow id="flow1" sourceRef="start" targetRef="managerApproval"/>

        <userTask id="managerApproval" name="经理审批"
                  flowable:assignee="${manager}"/>

        <sequenceFlow id="flow2" sourceRef="managerApproval" targetRef="end"/>

        <endEvent id="end" name="结束"/>

    </process>
</definitions>
```

### B. 部署流程

```bash
curl -X POST "http://localhost:9090/workflow/api/process/deploy" \
  -F "name=请假审批" \
  -F "file=@leave-approval.bpmn20.xml"

# 返回：{"code":200,"message":"success","data":"部署ID"}
```

### C. 查询流程定义

```bash
curl "http://localhost:9090/workflow/api/process/list"

# 返回流程定义列表，记下 key = "leave-approval"
```

### D. 发起流程

```bash
curl -X POST "http://localhost:9090/workflow/api/instance/start" \
  -H "Content-Type: application/json" \
  -d '{
    "processKey": "leave-approval",
    "businessKey": "LEAVE-2024001",
    "variables": {
      "applicant": "zhangsan",
      "manager": "lisi",
      "days": 3,
      "reason": "年假"
    }
  }'

# 返回流程实例信息
```

### E. 查询待办

```bash
curl "http://localhost:9090/workflow/api/task/todo?assignee=lisi"

# 返回 lisi 的待办任务，记下 taskId
```

### F. 审批通过

```bash
curl -X POST "http://localhost:9090/workflow/api/task/complete" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "上一步返回的taskId",
    "comment": "同意请假",
    "variables": {"approved": true}
  }'
```

### G. 查看历史

```bash
# 查看已完成流程
curl "http://localhost:9090/workflow/api/history/instances"

# 查看审批记录
curl "http://localhost:9090/workflow/api/history/activities/流程实例ID"

# 查看流程图（浏览器打开）
# http://localhost:9090/workflow/api/history/diagram/流程实例ID
```
