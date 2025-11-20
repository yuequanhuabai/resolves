● 完美！現在讓我給你一份完整的對比和詳細講解：

  ? 完整的權限控制系統對比講解

  第一部分：菜單/權限控制 vs 數據權限控制

  ┌─────────────────────────────────────────────────────────────────────┐
  │                        權限控制的兩個維度                             │
  ├─────────────────────────────────────────────────────────────────────┤
  │                                                                       │
  │  【菜單/功能權限控制】         vs      【數據權限控制】              │
  │  ━━━━━━━━━━━━━━━━━━━          ━━━━━━━━━━━━━━━━━━━                │
  │                                                                       │
  │  問題：用戶能不能訪問？        問題：用戶能看什麼數據？             │
  │  控制層級：API端點/按鈕層      控制層級：數據行層                    │
  │                                                                       │
  │  核心表：system_menu           核心字段：role.dataScope              │
  │         system_role_menu        role.dataScopeDeptIds               │
  │                                                                       │
  │  檢查方式：                      檢查方式：                           │
  │  @PreAuthorize                  SQL Where條件過濾                    │
  │  ("@ss.hasPermission             (user.dept_id IN (...))           │
  │   ('system:user:add'")                                              │
  │                                                                       │
  │  例子：                         例子：                               │
  │  是否有「添加用戶」按鈕？       查詢用戶列表時，只返回               │
  │  是否有「訪問BPM模塊」的權限？  我部門及子部門的用戶                 │
  │                                                                       │
  └─────────────────────────────────────────────────────────────────────┘

  ---
  第二部分：關鍵實體和表的完整關係圖

  【用戶維度】
      AdminUserDO (system_users)
      ├─ id (用戶ID)
      ├─ username (用戶名)
      ├─ deptId ──────────────────────┐
      └─ postIds (岗位集合)            │
                                      │
      ┌──────────────────────────────┘
      │
      ├─→ system_user_role ←─────────┐
      │       ├─ userId              │
      │       └─ roleId ┐            │
      │                 │            │
      │        [菜單/功能權限]        │    [數據權限]
      │                 │            │
      │   ┌─────────────┘            │
      │   ▼                          │
      │  RoleDO (system_role)        │
      │   ├─ id (角色ID)             │
      │   ├─ code (角色編碼)         │
      │   ├─ dataScope ?─────────────┘
      │   │  (數據權限範圍：ALL/DEPT_CUSTOM/DEPT_ONLY/DEPT_AND_CHILD/SELF)
      │   │
      │   ├─ dataScopeDeptIds
      │   │  (當dataScope=DEPT_CUSTOM時，指定的部門IDs)
      │   │
      │   └─→ system_role_menu
      │       ├─ roleId
      │       └─ menuId ──→ MenuDO (system_menu)
      │                   ├─ id (菜單ID)
      │                   ├─ permission (如:"system:user:add")
      │                   ├─ parentId (樹形結構)
      │                   └─ type (菜單/目錄/按鈕)
      │
      └──→ DeptDO (system_dept) ?─── 通過 deptId 關聯
          ├─ id (部門ID)
          ├─ parentId (父部門ID，支持樹形)
          ├─ name (部門名稱)
          └─ leaderUserId (負責人ID)

  【岗位維度】
      PostDO (system_post)
      ├─ id (岗位ID)
      ├─ code (岗位編碼)
      └─ name (岗位名稱)

      註：用戶通過 AdminUserDO.postIds 關聯多個岗位

  ---
  第三部分：數據權限詳細計算邏輯 (PermissionServiceImpl.java:277-330)

  核心方法：getDeptDataPermission(userId)

  public DeptDataPermissionRespDTO getDeptDataPermission(Long userId) {
      // 第1步：獲取用戶的所有啟用角色
      List<RoleDO> roles = getEnableUserRoleListByUserIdFromCache(userId);

      // 如果用戶沒有角色，只能查看自己的數據
      if (roles.isEmpty()) {
          return new DeptDataPermissionRespDTO(self=true);
      }

      DeptDataPermissionRespDTO result = new DeptDataPermissionRespDTO();

      // 第2步：獲取用戶所在部門ID（使用Guava的Suppliers進行懶惰求值）
      // 只有在真正需要時才查詢數據庫
      Supplier<Long> userDeptId = Suppliers.memoize(
          () -> userService.getUser(userId).getDeptId()
      );

      // 第3步：遍歷用戶的每個角色，聚合數據權限
      for (RoleDO role : roles) {
          Integer dataScope = role.getDataScope();

          // 情況1：ALL - 全部數據權限
          if (dataScope == 1) {
              result.setAll(true);  // 無限制，可訪問所有數據
              continue;
          }

          // 情況2：DEPT_CUSTOM - 指定部門數據權限
          if (dataScope == 2) {
              // 添加角色指定的部門IDs
              result.getDeptIds().addAll(role.getDataScopeDeptIds());
              // 重要：自動添加用戶所在的部門
              // 防止用戶被自己的部門過濾掉（例如登錄查詢時）
              result.getDeptIds().add(userDeptId.get());
              continue;
          }

          // 情況3：DEPT_ONLY - 本部門數據權限
          if (dataScope == 3) {
              // 只能看自己所在部門的數據
              result.getDeptIds().add(userDeptId.get());
              continue;
          }

          // 情況4：DEPT_AND_CHILD - 本部門及子部門數據權限
          if (dataScope == 4) {
              // 獲取用戶部門的所有子部門IDs（帶緩存）
              Set<Long> childDepts = deptService.getChildDeptIdListFromCache(
                  userDeptId.get()
              );
              result.getDeptIds().addAll(childDepts);
              // 添加本身部門
              result.getDeptIds().add(userDeptId.get());
              continue;
          }

          // 情況5：SELF - 僅本人數據權限
          if (dataScope == 5) {
              // 只能看自己創建的數據
              result.setSelf(true);
              continue;
          }
      }

      return result;
  }

  ---
  第四部分：完整示例

  場景1：用戶登錄並獲取數據權限

  用戶：張三 (userId=100, deptId=10, username="zhangsan")

  步驟1：查詢用戶角色
  SQL: SELECT * FROM system_user_role WHERE userId=100
  結果：
    - roleId=1 (超級管理員)
    - roleId=2 (部門經理)

  步驟2：查詢這些角色的dataScope
  SQL: SELECT * FROM system_role WHERE id IN (1, 2)
  結果：
    Role1 {
      id: 1,
      code: "super_admin",
      dataScope: 1,              // ALL - 全部數據
      dataScopeDeptIds: null
    }
    Role2 {
      id: 2,
      code: "dept_manager",
      dataScope: 3,              // DEPT_ONLY - 本部門
      dataScopeDeptIds: null
    }

  步驟3：聚合計算
    遍歷Role1: dataScope=1(ALL) → result.all = true
    遍歷Role2: dataScope=3(DEPT_ONLY) → result.deptIds.add(10)

  步驟4：最終權限結果
  DeptDataPermissionRespDTO {
    all: true,              // 超級管理員權限覆蓋一切
    self: false,
    deptIds: [10]
  }

  業務層使用：由於 all=true，查詢時不進行任何部門過濾

  場景2：指定部門的審批員

  用戶：李四 (userId=101, deptId=20)

  步驟1：查詢用戶角色
  結果：roleId=3

  步驟2：查詢角色詳情
  Role3 {
    id: 3,
    code: "cross_dept_approver",
    dataScope: 2,                    // DEPT_CUSTOM - 指定部門
    dataScopeDeptIds: [20, 30, 40]   // 只能審批這三個部門
  }

  步驟3：聚合計算
    遍歷Role3:
      dataScope=2(DEPT_CUSTOM)
      → result.deptIds.addAll([20, 30, 40])
      → 自動添加用戶部門(20)，防止被過濾

  步驟4：最終權限結果
  DeptDataPermissionRespDTO {
    all: false,
    self: false,
    deptIds: [20, 30, 40]
  }

  業務層使用：查詢工單時，WHERE user.deptId IN (20, 30, 40)

  場景3：本部門及子部門經理

  用戶：王五 (userId=102, deptId=50)

  部門樹結構：
    50 (研發部)
    ├─ 51 (後端組)
    ├─ 52 (前端組)
    └─ 53 (測試組)

  步驟1：查詢用戶角色
  結果：roleId=4

  步驟2：查詢角色詳情
  Role4 {
    id: 4,
    code: "dept_and_child_manager",
    dataScope: 4,              // DEPT_AND_CHILD - 本部門及子部門
    dataScopeDeptIds: null
  }

  步驟3：聚合計算
    遍歷Role4:
      dataScope=4(DEPT_AND_CHILD)
      → 獲取部門50的所有子部門IDs
      → result.deptIds.addAll([51, 52, 53, 50])
      → 再添加本身部門(50)

  步驟4：最終權限結果
  DeptDataPermissionRespDTO {
    all: false,
    self: false,
    deptIds: [50, 51, 52, 53]
  }

  業務層使用：查詢員工時，WHERE deptId IN (50, 51, 52, 53)

  ---
  第五部分：崗位和部門的實際用途

  1. 部門（DeptDO）的用途

  system_dept 表：
  id  | parentId | name     | leaderUserId
  ----|----------|----------|-------------
  10  | 0        | 公司總部 | 1
  20  | 10       | 研發部   | 100
  21  | 20       | 後端組   | 101
  22  | 20       | 前端組   | 102
  30  | 10       | 市場部   | 103
  31  | 30       | 廣告組   | 104

  用途：
  1. 組織結構：描述公司的組織層級
  2. 數據權限：通過role.dataScope控制用戶能訪問哪些部門的數據
  3. 部門領導：leaderUserId字段記錄部門負責人
  4. 樹形查詢：parentId支持遞歸查詢父/子部門

  2. 崗位（PostDO）的用途

  system_post 表：
  id | code         | name      | status
  ---|--------------|-----------|-------
  1  | cto          | CTO       | 0
  2  | dev_manager  | 開發經理  | 0
  3  | dev          | 開發人員  | 0
  4  | tester       | 測試      | 0

  AdminUserDO.postIds = [3, 4]  // JSON序列化

  用途：
  1. 員工崗位標簽：一個員工可以有多個崗位（如同時是開發和測試）
  2. 業務規則：某些業務邏輯可能需要判斷用戶的崗位
  3. 組織管理：岗位管理和薪資等與業務邏輯的關聯

  注意：PostDO 本身不直接控制權限！
        它是一個組織屬性，業務層可以利用它進行業務判斷

  ---
  第六部分：數據權限在實際業務中的應用

  例子：查詢員工列表 API

  @GetMapping("/list")
  @PreAuthorize("@ss.hasPermission('system:user:list')")
  public CommonResult<List<UserVO>> list() {
      // 第1步：檢查功能權限（通過 @PreAuthorize）
      // ? 檢查成功，用戶有 system:user:list 權限

      // 第2步：獲取用戶的數據權限
      Long userId = SecurityFrameworkUtils.getLoginUserId();
      DeptDataPermissionRespDTO dataPerm =
          permissionService.getDeptDataPermission(userId);

      // 第3步：構建查詢條件
      LambdaQueryWrapper<AdminUserDO> query = new LambdaQueryWrapper<>();

      // 應用數據權限過濾
      if (!dataPerm.getAll()) {  // 如果不是全部數據權限
          if (dataPerm.getSelf()) {
              // SELF 權限：只看自己
              query.eq(AdminUserDO::getId, userId);
          } else if (!dataPerm.getDeptIds().isEmpty()) {
              // 有特定部門限制
              query.in(AdminUserDO::getDeptId, dataPerm.getDeptIds());
          }
      }
      // 如果 all=true，不添加任何過濾條件

      // 第4步：執行查詢
      List<AdminUserDO> users = adminUserMapper.selectList(query);

      // 返回結果
      return success(BeanUtils.toBean(users, UserVO.class));
  }

  運行結果示例：
  ┌─ 超級管理員訪問 ─────────────────────┐
  │ dataPerm.all = true                  │
  │ SQL: SELECT * FROM system_users      │
  │ 返回：所有用戶(1000+條)              │
  └──────────────────────────────────────┘

  ┌─ 部門經理訪問 ────────────────────────────┐
  │ dataPerm.deptIds = [20, 21, 22]         │
  │ SQL: SELECT * FROM system_users        │
  │      WHERE dept_id IN (20, 21, 22)     │
  │ 返回：這三個部門的用戶(50條)           │
  └────────────────────────────────────────────┘

  ┌─ 普通員工訪問 ──────────────────────┐
  │ dataPerm.self = true                │
  │ SQL: SELECT * FROM system_users     │
  │      WHERE id = 102                 │
  │ 返回：只有自己(1條)                 │
  └──────────────────────────────────────┘

  ---
  第七部分：三層權限檢查總結

  用戶發起 API 請求
          ↓
  【第1層：認證】
      TokenAuthenticationFilter
      - 驗證 JWT Token 有效性
      - 從 Token 提取 userId, tenantId
      - 設置 SecurityContext
      - 不合格 → 返回 401 Unauthorized
          ↓
  【第2層：菜單/功能權限檢查】
      @PreAuthorize("@ss.hasPermission('system:user:list')")
      SecurityFrameworkServiceImpl.hasPermission()
      PermissionServiceImpl.hasAnyPermissions()
      - 查詢用戶角色 (Redis 緩存)
      - 查詢權限對應的 menuIds (Redis 緩存)
      - 檢查用戶角色是否包含該 menuId (Redis 緩存)
      - 超級管理員自動通過
      - 不合格 → 返回 403 Forbidden
          ↓
  【第3層：數據權限過濾】
      SQL Where 條件
      - 獲取用戶的部門數據權限
      - 根據 dataScope 計算可訪問的部門 IDs
      - 過濾 SQL 查詢結果
      - 合格 → 返回經過過濾的數據

  ---
  第八部分：關鍵設計巧妙之處

  1. 多角色聚合
     一個用戶有多個角色時，取並集（最寬鬆）
     例：[ALL, DEPT_ONLY] → ALL

  2. 自動添加用戶部門
     DEPT_CUSTOM 時自動添加用戶所在部門
     防止登錄查詢時被過濾掉

  3. 懶惰求值（Lazy Evaluation）
     Suppliers.memoize(() -> userService.getUser(userId))
     只在首次使用時查詢數據庫，結果緩存在內存

  4. 多級緩存
     Redis 緩存用戶角色、菜單、部門樹
     降低數據庫查詢頻率

  5. 遞歸部門樹
     getChildDeptIdListFromCache(deptId)
     支持深層組織結構的權限控制

  ---
  這就是完整的RBAC + 數據權限的實現！現在你應該對**菜單權限(What can I do)和數據權限(What data can I
  see)**有清晰的理解了。有任何疑問都可以繼續問我！