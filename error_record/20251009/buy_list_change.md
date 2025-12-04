# BuyList改造方案：实现Benchmark循环审批逻辑

## 一、核心目标

将Benchmark的循环审批机制应用到BuyList：
1. `biz_status` 循环：2(approval) ↔ 4(restart)
2. `del_flag` 控制：再次编辑时APPROVED保留(del=0)，审批通过时清理旧APPROVED(del=1)
3. `history_id` 交替：APPROVED ↔ PENDING ↔ APPROVED ↔ PENDING

---

## 二、现状分析

### 当前BuyList的版本管理模式

```
编辑流程（现状）：
1. 标记旧记录 del_flag=1
2. 插入新记录 recordVersion+1
3. 启动BPM流程
4. 状态回调时：直接更新当前记录的status字段
```

**问题**：
- ❌ 审批通过后直接更新status，没有创建新版本
- ❌ 前端只显示1条记录，无法同时看到"生效版本"和"待审批版本"
- ❌ 缺少biz_status状态机，无法区分"首次提交"和"再次发起"
- ❌ 没有history_id链式追溯

### 目标BuyList的循环审批模式

```
编辑流程（目标）：
1. 旧APPROVED记录：del_flag保持0，edit_flag=1（锁定但显示）
2. 新PENDING记录：biz_status=4，history_id指向APPROVED
3. 审批通过时：
   - 旧APPROVED：del_flag=1（清理）
   - 旧PENDING：del_flag=1（清理）
   - 新APPROVED：biz_status=2，history_id指向PENDING
```

**效果**：前端显示2条记录（APPROVED只读 + PENDING可编辑）

---

## 三、实现思路（宏观）

### 核心改造点

```
┌─────────────────────────────────────────────┐
│  改造维度           │  具体操作              │
├─────────────────────────────────────────────┤
│ 1. 状态字段映射     │ status → approval_status │
│                     │ 新增 biz_status 状态机  │
├─────────────────────────────────────────────┤
│ 2. 版本管理逻辑     │ 编辑时：旧APPROVED不删除 │
│                     │ 审批时：创建新版本       │
├─────────────────────────────────────────────┤
│ 3. history_id链     │ APPROVED ↔ PENDING 交替 │
├─────────────────────────────────────────────┤
│ 4. BPM监听器        │ 审批通过：插入新版本    │
│                     │ 而非更新现有记录        │
├─────────────────────────────────────────────┤
│ 5. 前端查询逻辑     │ 过滤 del_flag=0         │
│                     │ 显示2条（如果有PENDING）│
└─────────────────────────────────────────────┘
```

---

## 四、详细实现步骤

### 阶段1：数据层准备

#### 1.1 字段确认
```
已添加字段（确认数据库已执行）：
- biz_status (tinyint)     ← 新增：业务状态
- history_id (varchar64)   ← 新增：版本链
- edit_flag (tinyint)      ← 新增：编辑权限

保持字段：
- status (tinyint)         ← 保持：审批状态（映射为approval_status）
```

#### 1.2 双状态字段说明（⚠️ 关键）

**BuyList使用两个状态字段：**

```
┌─────────────────────────────────────────────────────┐
│ 字段名    │ Java映射         │ 职责           │ 使用者 │
├─────────────────────────────────────────────────────┤
│ status    │ approvalStatus   │ 审批流程状态   │ BPM引擎│
│ biz_status│ bizStatus        │ 业务阶段标识   │ 业务代码│
└─────────────────────────────────────────────────────┘
```

**为什么需要两个状态？**
- `status (approvalStatus)`：工作流引擎关注的状态（1→2/3流转）
- `biz_status (bizStatus)`：业务代码关注的状态（区分首次/再次提交）

**职责分离：**
- BPM监听器：读取和更新 `status` 字段
- 业务代码：根据 `biz_status` 分支处理逻辑
- 前端显示：主要展示 `status`，业务逻辑依赖 `biz_status`

#### 1.3 字段语义

**status (approval_status) - 审批状态：**
```
0 = 待提交（初始）
1 = 审批中（PENDING）
2 = 已通过（APPROVED）
3 = 已驳回（REJECTED）
```

**biz_status - 业务状态：**
```
0 = system（初始，未提交）
1 = submit（首次提交）
2 = approval（已生效）
3 = reject（已驳回）
4 = restart（再次发起）← 关键：区分首次和再次
```

**edit_flag - 编辑权限：**
```
0 = 可编辑
1 = 不可编辑（锁定）
```

**history_id - 版本链：**
```
PENDING记录 → 指向上一个APPROVED的id
APPROVED记录 → 指向上一个PENDING的id
初始记录 → NULL
```

#### 1.4 状态同步规则

**重要：status 和 biz_status 的关系**

```
场景                    │ status │ biz_status │ 说明
─────────────────────────────────────────────────────────
初始状态                │   0    │     0      │ 未提交
首次提交                │   1    │     1      │ 审批中
审批通过（首次）        │   2    │     2      │ 已生效
审批驳回                │   3    │     3      │ 已驳回
再次编辑提交            │   1    │     4      │ 再次审批中（关键！）
审批通过（再次）        │   2    │     2      │ 已生效
```

**关键区别：**
- `status=1, biz_status=1`：首次提交审批中
- `status=1, biz_status=4`：再次发起审批中 ← 通过biz_status区分

#### 1.5 初始化脚本
```sql
-- 将现有记录的biz_status初始化
UPDATE buy_list
SET biz_status = CASE
    WHEN status = 2 THEN 2  -- APPROVED
    WHEN status = 1 THEN 1  -- PENDING
    ELSE 0                   -- 初始状态
END,
edit_flag = 0,              -- 默认可编辑
history_id = NULL           -- 旧数据无历史链
WHERE biz_status IS NULL;
```

---

### 阶段2：Service层改造

#### 2.1 核心方法拆分

**原方法：**
```
updateList(List<BuyListReqVO> updateReqVO)
  ↓
updateMainList() → 标记旧记录del_flag=1，插入新记录
  ↓
startProcess() → 启动流程
```

**改造为（对照Benchmark）：**
```
updateList(List<BuyListReqVO> updateReqVO)
  ↓
createNewVersion()
  ├─ createUpdateBuyList() → 根据biz_status分支处理
  │    ├─ biz_status=0 → 首次提交前准备
  │    ├─ biz_status=2 → 再次编辑（保留del_flag=0）
  │    └─ biz_status=1/4 → 重复提交（标记删除）
  └─ createInsertBuyList() → 根据biz_status设置新记录
       ├─ biz_status=0 → approval_status=1, biz_status=1
       ├─ biz_status=2 → approval_status=1, biz_status=4
       └─ biz_status=1/4 → approval_status=1, biz_status不变
  ↓
startProcess() → 启动流程
```

#### 2.2 关键代码逻辑

**createUpdateBuyList()：**
```java
private BuyListDO createUpdateBuyList(BuyListDO oldBuyList, Integer status) {
    BuyListDO updateObj = new BuyListDO();
    BeanUtils.copyProperties(oldBuyList, updateObj);

    // 分支1：初始状态首次提交
    if (oldBuyList.getBizStatus().equals(0)) {
        updateObj.setValidStartDatetime(LocalDateTime.now());
        updateObj.setMaker(getLoginUserNickname());
        updateObj.setMakerDatetime(LocalDateTime.now());
        updateObj.setDelFlag(0);  // 保留
    }
    // 分支2：已生效记录再次编辑（关键！）
    else if (oldBuyList.getBizStatus().equals(2)) {
        updateObj.setDelFlag(0);  // 保留del_flag=0，不删除
    }
    // 分支3：PENDING状态的处理
    else if (oldBuyList.getBizStatus().equals(1) || oldBuyList.getBizStatus().equals(4)) {
        if (Objects.isNull(status)) {
            // 页面提交：标记删除
            updateObj.setDelFlag(1);
            updateObj.setValidEndDatetime(null);
        } else {
            // BPM回调：标记删除，并清理上一个APPROVED
            updateObj.setDelFlag(1);
            updateObj.setValidEndDatetime(LocalDateTime.now());

            BuyListDO historyBuyList = buyListMapper.selectById(oldBuyList.getHistoryId());
            historyBuyList.setDelFlag(1);
            historyBuyList.setValidEndDatetime(LocalDateTime.now());
            buyListMapper.updateById(historyBuyList);
        }
    }

    // 统一设置：锁定编辑
    updateObj.setEditFlag(1);
    return updateObj;
}
```

**createInsertBuyList()：**
```java
private BuyListDO createInsertBuyList(BuyListDO oldBuyList, Integer status, BuyListDO historyBuyList) {
    BuyListDO insertObj = new BuyListDO();
    BeanUtils.copyProperties(oldBuyList, insertObj);

    // 分支1：重复发起（编辑PENDING记录）
    if (Objects.isNull(status) &&
        (oldBuyList.getBizStatus().equals(1) || oldBuyList.getBizStatus().equals(4))) {
        insertObj.setApprovalStatus(1);
        insertObj.setBizStatus(oldBuyList.getBizStatus());  // 保持1或4
        insertObj.setMaker(getLoginUserNickname());
        insertObj.setMakerDatetime(LocalDateTime.now());
        insertObj.setChecker(null);
        insertObj.setCheckerDatetime(null);
        insertObj.setHistoryId(historyBuyList.getHistoryId());  // 指向更早的APPROVED
    }
    // 分支2：BPM回调（审批通过/驳回）
    else if (oldBuyList.getBizStatus().equals(1) || oldBuyList.getBizStatus().equals(4)) {
        insertObj.setApprovalStatus(status);  // 2或3
        insertObj.setBizStatus(status);       // 2或3
        insertObj.setChecker(getLoginUserNickname());
        insertObj.setCheckerDatetime(LocalDateTime.now());
        insertObj.setHistoryId(oldBuyList.getId());  // APPROVED指向PENDING
    }
    // 分支3：首次提交
    else if (oldBuyList.getBizStatus().equals(0)) {
        insertObj.setApprovalStatus(1);
        insertObj.setBizStatus(1);  // submit
        insertObj.setMaker(getLoginUserNickname());
        insertObj.setMakerDatetime(LocalDateTime.now());
        insertObj.setHistoryId(oldBuyList.getId());  // 指向初始记录
    }
    // 分支4：已生效/已驳回再次发起
    else if (oldBuyList.getBizStatus().equals(2) || oldBuyList.getBizStatus().equals(3)) {
        insertObj.setApprovalStatus(1);
        insertObj.setBizStatus(4);  // restart（关键！）
        insertObj.setMaker(getLoginUserNickname());
        insertObj.setMakerDatetime(LocalDateTime.now());
        insertObj.setChecker(null);
        insertObj.setCheckerDatetime(null);
        insertObj.setHistoryId(oldBuyList.getId());  // PENDING指向APPROVED
    }

    // 统一设置
    insertObj.setId(IdUtils.getUUID());
    insertObj.setDelFlag(0);
    insertObj.setEditFlag(0);  // 新记录可编辑
    insertObj.setValidStartDatetime(LocalDateTime.now());
    insertObj.setValidEndDatetime(null);
    insertObj.setRecordVersion(oldBuyList.getRecordVersion() + 1);

    return insertObj;
}
```

---

### 阶段3：BPM监听器改造

#### 3.1 当前逻辑
```java
// 现状：直接更新status字段
public void updateProcessStatus(String id, Integer status) {
    buyListMapper.updateById(new BuyListDO()
        .setId(id)
        .setStatus(status)
        .setChecker(getLoginUserNickname())
        .setCheckerDatetime(LocalDateTime.now()));
}
```

#### 3.2 改造后逻辑
```java
// 目标：创建新版本（对照Benchmark）
public void updateProcessStatus(String id, Integer status) {
    try {
        // 1. 获取当前PENDING记录
        BuyListDO oldBuyList = buyListMapper.selectById(id);

        // 2. 创建新版本（传入status=2或3）
        BuyListDO newBuyList = createNewVersion(oldBuyList, status);

        // 3. 复制详情数据
        if (status.equals(3)) {
            // 驳回：从历史APPROVED复制
            copyDetails(newBuyList.getId(), oldBuyList.getHistoryId(), newBuyList.getRecordVersion());
        } else {
            // 通过：从当前PENDING复制
            copyDetails(newBuyList.getId(), oldBuyList.getId(), newBuyList.getRecordVersion());
        }

    } catch (Exception e) {
        log.error("更新BuyList状态失败", e);
        throw new ServerException(500, "更新失败");
    }
}

private void copyDetails(String newId, String sourceId, Integer recordVersion) {
    List<BuyListDetailsDo> sourceDetails = detailsMapper.selectList(
        new LambdaQueryWrapperX<BuyListDetailsDo>()
            .eq(BuyListDetailsDo::getBuyListId, sourceId)
    );

    List<BuyListDetailsDo> newDetails = sourceDetails.stream()
        .map(detail -> {
            BuyListDetailsDo newDetail = new BuyListDetailsDo();
            BeanUtils.copyProperties(detail, newDetail);
            newDetail.setId(IdUtils.getUUID());
            newDetail.setBuyListId(newId);
            newDetail.setRecordVersion(recordVersion);
            return newDetail;
        })
        .collect(Collectors.toList());

    detailsMapper.insertBatch(newDetails);
}
```

**核心变化：**
- ❌ 删除：直接更新status字段
- ✅ 新增：调用createNewVersion创建新版本
- ✅ 新增：复制详情数据到新版本

---

### 阶段4：Mapper查询调整

#### 4.1 当前查询
```java
// 现状：过滤del_flag=0
.eqIfPresent(BuyListDO::getDelFlag, 0)
```

**问题**：无问题，继续保持

#### 4.2 前端展示逻辑
```
查询结果：
- 如果只有1条APPROVED记录 → 显示1行（可编辑）
- 如果有1条APPROVED + 1条PENDING → 显示2行
  - APPROVED：edit_flag=1（只读）
  - PENDING：edit_flag=0（可编辑）
```

**前端判断逻辑（Vue）：**
```javascript
// 列表页点击跳转
const handleNameClick = async (row) => {
    // 检查是否有待审批任务
    const response = await ListApi.getProcessKey(row.processInstanceId);

    if (response != null) {
        // 有待审批任务 → 跳转审批页
        router.push({
            path: '/bpm/approval',
            query: { taskId, processInstanceId, ... }
        });
    } else {
        // 无待审批任务 → 跳转详情页
        router.push({
            path: '/buylist/detail',
            query: {
                id: row.id,
                editFlag: row.editFlag,  // 新增：传递编辑权限
                ...
            }
        });
    }
};
```

---

### 阶段5：前端详情页调整

#### 5.1 编辑权限控制
```javascript
// 新增：基于editFlag判断
const isReadOnly = ref(false);

const initPageData = async () => {
    const routeParams = route.query;
    const editFlag = Number(routeParams.editFlag) || 0;

    // 如果editFlag=1，设置为只读
    if (editFlag === 1) {
        isReadOnly.value = true;
    }

    // ...其他初始化
};
```

#### 5.2 编辑按钮显示
```vue
<el-button
  type="primary"
  @click="toggleEditMode"
  v-if="!isReadOnly && checkPermi(['buy:list:update'])"
  :disabled="isEditMode"
>
  Edit
</el-button>
```

---

## 五、思考逻辑（Why）

### 为什么这样改造？

#### 思考1：为什么需要biz_status？
```
问题：只用approval_status（status字段）够吗？
回答：不够。

原因：
- approval_status：工作流引擎关心的状态（1→2/3）
- biz_status：业务代码关心的状态（区分首次/再次）

举例：
- 用户再次编辑已通过的记录
- approval_status：2 → 1（重新进入审批）
- biz_status：2 → 4（标记为"restart"而非"submit"）

作用：通过biz_status=4，代码知道这是"再次发起"，
     可以清空checker信息，保留maker信息。
```

#### 思考2：为什么再次编辑时旧APPROVED不删除？
```
问题：为什么不像首次提交那样，直接标记del_flag=1？
回答：为了让用户同时看到两个版本。

场景：
- 用户编辑已生效的BuyList
- 前端需要显示：
  ├─ 旧版本（APPROVED）：当前生效的数据，只读
  └─ 新版本（PENDING）：待审批的修改，可编辑

实现：
- 旧APPROVED：del_flag=0（保留），edit_flag=1（锁定）
- 新PENDING：del_flag=0（显示），edit_flag=0（可编辑）

查询：WHERE del_flag=0 → 返回2条记录
```

#### 思考3：为什么审批通过时要清理旧APPROVED？
```
问题：审批通过后，为什么要删除旧APPROVED？
回答：业务上只有一个"生效版本"。

流程：
1. 用户编辑：APPROVED(v2) + PENDING(v3)
2. 审批通过：
   - 删除APPROVED(v2) → del_flag=1
   - 删除PENDING(v3) → del_flag=1
   - 创建APPROVED(v4) → 新的生效版本

结果：前端只显示APPROVED(v4)，用户看到最新生效数据。
```

#### 思考4：为什么history_id要交替指向？
```
问题：为什么不让所有记录都指向第一个版本？
回答：为了双向追溯。

设计：
APPROVED(history=NULL)
  ↓
PENDING(history=APPROVED.id)  ← 知道基于哪个版本修改
  ↓
APPROVED(history=PENDING.id)  ← 知道从哪次审批来的
  ↓
PENDING(history=APPROVED.id)
  ↓
...

能力：
- 从PENDING向前追溯：找到上一个APPROVED（基础版本）
- 从APPROVED向前追溯：找到上一个PENDING（审批来源）
```

---

## 六、改造验证清单

### 6.1 单元测试场景
```
场景1：首次提交
- 初始：1条记录（biz_status=0, del_flag=0）
- 提交后：2条记录（旧记录del_flag=0, 新记录biz_status=1）
- 审批通过：1条记录（biz_status=2, del_flag=0）

场景2：再次编辑
- 初始：1条APPROVED（biz_status=2, del_flag=0）
- 提交后：2条记录（APPROVED del_flag=0 edit_flag=1, PENDING biz_status=4）
- 审批通过：1条APPROVED（新版本，旧版本被删除）

场景3：连续编辑
- APPROVED → PENDING1 → 用户再次编辑 → PENDING2
- 预期：PENDING1被标记删除，PENDING2的history_id指向APPROVED
```

### 6.2 前端验证
```
验证点1：列表页显示
- 有PENDING时：显示2条（APPROVED+PENDING）
- 无PENDING时：显示1条（APPROVED）

验证点2：编辑权限
- APPROVED且edit_flag=1：详情页只读
- PENDING且edit_flag=0：详情页可编辑

验证点3：版本链
- 点击名称可查看版本历史（通过history_id追溯）
```

---

## 七、实施步骤总结

```
Step 1: 数据准备
  ├─ 确认字段已添加（biz_status, history_id, edit_flag）
  ├─ 执行初始化SQL
  └─ 数据迁移验证

Step 2: Service层改造
  ├─ 拆分 createUpdateBuyList()
  ├─ 拆分 createInsertBuyList()
  ├─ 改造 updateList() 方法
  └─ 重写 updateProcessStatus() 方法

Step 3: Mapper验证
  └─ 确认查询过滤 del_flag=0

Step 4: 前端调整
  ├─ 详情页：增加 isReadOnly 判断
  ├─ 列表页：支持显示2条记录
  └─ 路由传参：增加 editFlag 参数

Step 5: 测试验证
  ├─ 单元测试（3个场景）
  ├─ 集成测试（BPM回调）
  └─ 前端E2E测试
```

---

## 八、风险点和注意事项

### 8.1 数据一致性
```
风险：旧数据的biz_status可能为NULL
方案：执行初始化SQL，设置默认值
```

### 8.2 并发控制
```
风险：多人同时编辑同一APPROVED记录
方案：依赖现有的乐观锁（system_version）
```

### 8.3 历史数据兼容
```
风险：旧版本记录的history_id为NULL
方案：在代码中判断NULL，兼容旧数据
```

### 8.4 BPM回调异常
```
风险：createNewVersion失败导致审批状态不一致
方案：添加事务控制 + 异常日志 + 补偿机制
```

---

## 九、核心代码对照表

| 功能点 | Benchmark实现 | BuyList改造目标 |
|--------|--------------|---------------|
| 版本管理入口 | `createNewBenchmarkVersion()` | `createNewBuyListVersion()` |
| 旧记录更新 | `createUpdateBenchmark()` | `createUpdateBuyList()` |
| 新记录插入 | `createInsertBenchmark()` | `createInsertBuyList()` |
| BPM回调 | `updateProcessStatus()` | `updateProcessStatus()` |
| 详情复制 | `updateBenchmarkDetails()` | `copyDetails()` |
| 状态判断 | `biz_status` 分支 | `biz_status` 分支 |
| 版本链 | `history_id` 交替 | `history_id` 交替 |

---

## 十、总结

**改造本质**：将"直接更新"改为"版本创建"，通过biz_status状态机 + del_flag精细控制 + history_id链式追溯，实现循环审批能力。

**关键点**：
1. 再次编辑时，旧APPROVED不删除（del_flag=0, edit_flag=1）
2. 审批通过时，创建新版本并清理旧版本（插入+删除）
3. history_id交替指向，形成完整追溯链

**预期效果**：
- 前端：编辑中显示2条，审批后显示1条
- 后端：完整版本链，支持无限循环审批
- 用户：同时看到"当前生效"和"待审批"两个版本