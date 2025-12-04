Benchmark状态优化方案                                                                                     │
│                                                                                                           │
│ 核心诉求                                                                                                  │
│                                                                                                           │
│ 将初始 approvalStatus 从 0 改为 2 (APPROVED)，通过 bizStatus=0(system) 和 bizStatus=4(restart)            │
│ 区分"新建"和"再次编辑"。                                                                                  │
│                                                                                                           │
│ ---                                                                                                       │
│ 方案本质                                                                                                  │
│                                                                                                           │
│ 现状问题                                                                                                  │
│                                                                                                           │
│ - 新建记录初始状态 approvalStatus=0，需要特殊逻辑判断是否可编辑                                           │
│ - approvalStatus 同时承担"流程状态"和"是否可编辑"两个职责                                                 │
│                                                                                                           │
│ 优化方向                                                                                                  │
│                                                                                                           │
│ - 职责分离：approvalStatus 只表达审批状态，bizStatus 表达业务阶段                                         │
│ - 语义明确：approvalStatus=2 默认可编辑，bizStatus=0 表示新建未提交                                       │
│                                                                                                           │
│ ---                                                                                                       │
│ 状态流转对比                                                                                              │
│                                                                                                           │
│ 当前机制                                                                                                  │
│                                                                                                           │
│ 初始: approval=0, biz=0 (特殊判断可编辑)                                                                  │
│   ↓ 提交                                                                                                  │
│ 待审: approval=1, biz=1                                                                                   │
│   ↓ 审批通过                                                                                              │
│ 生效: approval=2, biz=2                                                                                   │
│   ↓ 再编辑提交                                                                                            │
│ 再审: approval=1, biz=4                                                                                   │
│                                                                                                           │
│ 优化后机制                                                                                                │
│                                                                                                           │
│ 初始: approval=2, biz=0 ← 核心改动：默认可编辑                                                            │
│   ↓ 提交                                                                                                  │
│ 待审: approval=1, biz=1                                                                                   │
│   ↓ 审批通过                                                                                              │
│ 生效: approval=2, biz=2                                                                                   │
│   ↓ 再编辑提交                                                                                            │
│ 再审: approval=1, biz=4                                                                                   │
│                                                                                                           │
│ 关键差异：                                                                                                │
│ - approval=2, biz=0：新建未提交                                                                           │
│ - approval=2, biz=2：已审批通过                                                                           │
│                                                                                                           │
│ ---                                                                                                       │
│ 实施要点                                                                                                  │
│                                                                                                           │
│ 1. 数据层                                                                                                 │
│                                                                                                           │
│ - 修改数据库 status 字段默认值：0 → 2                                                                     │
│ - 数据迁移：将已存在的 status=0 记录更新为 2                                                              │
│                                                                                                           │
│ 2. 业务层                                                                                                 │
│                                                                                                           │
│ - 核心逻辑验证：确认 createUpdateBenchmark 和 createInsertBenchmark 中对 bizStatus=0 的处理是否兼容新方案 │
│ - 关键判断点：首次提交时，从 (approval=2, biz=0) 正确转换为 (approval=1, biz=1)                           │
│                                                                                                           │
│ 3. 展示层                                                                                                 │
│                                                                                                           │
│ - 编辑权限：基于 approval=2 && editFlag=0 判断可编辑                                                      │
│ - 状态显示：字典映射自动适配，无需调整                                                                    │
│                                                                                                           │
│ ---                                                                                                       │
│ 影响范围                                                                                                  │
│                                                                                                           │
│ 需要修改                                                                                                  │
│                                                                                                           │
│ 1. 数据库表结构：默认值调整                                                                               │
│ 2. 数据迁移SQL：历史数据处理                                                                              │
│ 3. 后端验证：确认版本管理逻辑兼容性                                                                       │
│                                                                                                           │
│ 无需修改                                                                                                  │
│                                                                                                           │
│ - BPM监听器（只关注 approvalStatus 流转）                                                                 │
│ - 查询Mapper（不依赖特定 approvalStatus 值）                                                              │
│ - 前端列表页（字典渲染自动适配）                                                                          │
│                                                                                                           │
│ ---                                                                                                       │
│ 核心优势                                                                                                  │
│                                                                                                           │
│ 1. 语义清晰：approval=2 明确表达"可编辑"，biz=0 明确表达"新建"                                            │
│ 2. 逻辑简化：消除对初始状态的特殊判断                                                                     │
│ 3. 职责分离：审批流程与业务阶段解耦                                                                       │
│ 4. 低侵入性：主要调整数据库默认值，业务逻辑改动极小                                                       │
│                                                                                                           │
│ ---                                                                                                       │
│ 测试验证                                                                                                  │
│                                                                                                           │
│ 关键场景：                                                                                                │
│ 1. 新建 → 提交 → 通过 ✓                                                                                   │
│ 2. 新建 → 提交 → 驳回 → 再提交 ✓                                                                          │
│ 3. 已通过 → 再编辑 → 再提交 ✓                                                                             │
│ 4. 版本管理正确性验证（historyId, recordVersion, delFlag）✓