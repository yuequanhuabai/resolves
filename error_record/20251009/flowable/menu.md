# PAP 项目菜单权限管理详解

> **作者**: Claude Code
> **日期**: 2025-10-24
> **项目**: PAP (Private & Retail Banking Management System)
> **以 Benchmark 为例详细说明**

---

## 📚 目录

1. [概述](#概述)
2. [整体架构](#整体架构)
3. [后端菜单管理](#后端菜单管理)
4. [后端权限验证](#后端权限验证)
5. [前端路由生成](#前端路由生成)
6. [前端权限控制](#前端权限控制)
7. [Benchmark 完整示例](#benchmark-完整示例)
8. [菜单权限流程图](#菜单权限流程图)
9. [常见问题与最佳实践](#常见问题与最佳实践)

---

## 概述

PAP 项目采用 **RBAC（基于角色的访问控制）** 模型，实现了完善的菜单和权限管理体系。核心特点：

- **后端主导**: 菜单数据由后端管理，前端动态加载
- **细粒度控制**: 支持菜单权限和按钮权限
- **动态路由**: 前端根据后端返回的菜单动态生成路由
- **权限指令**: 通过 `v-hasPermi` 指令控制按钮显示

### 核心概念

| 概念 | 说明 | 示例 |
|------|------|------|
| **菜单 (Menu)** | 系统的导航菜单，包括目录、菜单、按钮 | Benchmark 菜单 |
| **权限标识 (Permission)** | 唯一的权限字符串 | `benchmark:benchmark:query` |
| **角色 (Role)** | 用户的角色分组 | 管理员、普通用户 |
| **用户角色关联** | 用户拥有哪些角色 | 用户A → [管理员, 审批员] |
| **角色菜单关联** | 角色拥有哪些菜单 | 管理员 → [所有菜单] |

---

## 整体架构

### 数据流转图

```
┌─────────────────────────────────────────────────────────────┐
│  数据库层                                                    │
│  ├─ system_menu (菜单表)                                    │
│  ├─ system_role (角色表)                                    │
│  ├─ system_user_role (用户-角色关联表)                      │
│  └─ system_role_menu (角色-菜单关联表)                      │
├─────────────────────────────────────────────────────────────┤
│  后端服务层                                                  │
│  ├─ MenuService (菜单管理)                                  │
│  ├─ PermissionService (权限验证)                            │
│  └─ AuthController (登录时返回用户权限)                     │
├─────────────────────────────────────────────────────────────┤
│  HTTP API                                                   │
│  POST /login → { permissions: [...], menus: [...] }        │
├─────────────────────────────────────────────────────────────┤
│  前端应用层                                                  │
│  ├─ UserStore (存储用户权限和菜单)                          │
│  ├─ PermissionStore (生成动态路由)                          │
│  ├─ Router Guard (路由守卫)                                 │
│  └─ v-hasPermi (权限指令)                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 后端菜单管理

### 1. 菜单数据结构

#### MenuDO 实体类

```java
// system/dal/dataobject/permission/MenuDO.java
@TableName("system_menu")
@Data
public class MenuDO extends BaseDO {

    private Long id;              // 菜单ID
    private String name;          // 菜单名称
    private String permission;    // 权限标识（如：benchmark:benchmark:query）
    private Integer type;         // 菜单类型（1-目录 2-菜单 3-按钮）
    private Integer sort;         // 显示顺序
    private Long parentId;        // 父菜单ID
    private String path;          // 路由地址（如：/benchmark/privateBank）
    private String icon;          // 菜单图标
    private String component;     // 组件路径（如：benchmark/privateBank/index）
    private String componentName; // 组件名称（如：BenchmarkPrivateBank）
    private Integer status;       // 菜单状态（0-正常 1-停用）
    private Boolean visible;      // 是否可见
    private Boolean keepAlive;    // 是否缓存
    private Boolean alwaysShow;   // 是否总是显示
}
```

#### 菜单类型说明

| 类型值 | 类型名称 | 说明 | 示例 |
|--------|---------|------|------|
| **1** | 目录 | 不对应具体页面，用于分组 | "业务管理" 目录 |
| **2** | 菜单 | 对应具体页面 | "Benchmark 管理" 菜单 |
| **3** | 按钮 | 页面内的操作按钮 | "查询"、"新增"、"删除" 按钮 |

---

### 2. 菜单管理 API

#### MenuController

```java
// system/controller/admin/permission/MenuController.java
@Tag(name = "管理后台 - 菜单")
@RestController
@RequestMapping("/system/menu")
public class MenuController {

    @Resource
    private MenuService menuService;

    // 创建菜单
    @PostMapping("/create")
    @PreAuthorize("@ss.hasPermission('system:menu:create')")
    public CommonResult<Long> createMenu(@Valid @RequestBody MenuSaveVO createReqVO) {
        Long menuId = menuService.createMenu(createReqVO);
        return success(menuId);
    }

    // 获取菜单列表（用于菜单管理界面）
    @GetMapping("/list")
    @PreAuthorize("@ss.hasPermission('system:menu:query')")
    public CommonResult<List<MenuRespVO>> getMenuList(MenuListReqVO reqVO) {
        List<MenuDO> list = menuService.getMenuList(reqVO);
        list.sort(Comparator.comparing(MenuDO::getSort));
        return success(BeanUtils.toBean(list, MenuRespVO.class));
    }

    // 获取菜单精简信息列表（用于角色分配菜单）
    @GetMapping({"/list-all-simple", "simple-list"})
    public CommonResult<List<MenuSimpleRespVO>> getSimpleMenuList() {
        List<MenuDO> list = menuService.getMenuListByTenant(
            new MenuListReqVO().setStatus(CommonStatusEnum.ENABLE.getStatus())
        );
        list = menuService.filterDisableMenus(list);
        list.sort(Comparator.comparing(MenuDO::getSort));
        return success(BeanUtils.toBean(list, MenuSimpleRespVO.class));
    }
}
```

---

### 3. 权限验证机制

#### PermissionService

```java
// system/service/permission/PermissionServiceImpl.java
@Service
public class PermissionServiceImpl implements PermissionService {

    @Resource
    private RoleMenuMapper roleMenuMapper;
    @Resource
    private UserRoleMapper userRoleMapper;
    @Resource
    private MenuService menuService;

    /**
     * 判断用户是否拥有指定权限
     */
    @Override
    public boolean hasAnyPermissions(Long userId, String... permissions) {
        // 1. 如果为空，说明已经有权限
        if (ArrayUtil.isEmpty(permissions)) {
            return true;
        }

        // 2. 获得当前用户的角色列表
        List<RoleDO> roles = getEnableUserRoleListByUserIdFromCache(userId);
        if (CollUtil.isEmpty(roles)) {
            return false;
        }

        // 3. 遍历判断每个权限
        for (String permission : permissions) {
            if (hasAnyPermission(roles, permission)) {
                return true;
            }
        }

        // 4. 判断是否是超级管理员
        return roleService.hasAnySuperAdmin(convertSet(roles, RoleDO::getId));
    }

    /**
     * 判断指定角色是否拥有该权限
     */
    private boolean hasAnyPermission(List<RoleDO> roles, String permission) {
        // 1. 根据权限标识查找对应的菜单ID列表
        List<Long> menuIds = menuService.getMenuIdListByPermissionFromCache(permission);
        if (CollUtil.isEmpty(menuIds)) {
            return false;
        }

        // 2. 判断角色是否拥有这些菜单
        Set<Long> roleIds = convertSet(roles, RoleDO::getId);
        for (Long menuId : menuIds) {
            // 获得拥有该菜单的角色编号集合
            Set<Long> menuRoleIds = getMenuRoleIdListByMenuIdFromCache(menuId);
            // 如果有交集，说明有权限
            if (CollUtil.containsAny(menuRoleIds, roleIds)) {
                return true;
            }
        }
        return false;
    }
}
```

#### 权限验证流程

```
用户请求接口
    ↓
Spring Security 拦截
    ↓
@PreAuthorize("@ss.hasPermission('benchmark:benchmark:query')")
    ↓
调用 PermissionService.hasAnyPermissions(userId, permissions)
    ↓
1. 查询用户拥有的角色: system_user_role
2. 查询权限对应的菜单: system_menu (where permission = 'benchmark:benchmark:query')
3. 查询角色拥有的菜单: system_role_menu
4. 判断是否有交集
    ↓
返回 true/false
```

---

### 4. Benchmark 后端权限配置

#### BenchmarkController 权限注解

```java
// business/controller/BenchmarkController.java
@RestController
@RequestMapping("/admin-api/benchmark")
public class BenchmarkController {

    @GetMapping("/page")
    @Operation(summary = "获得業務分页")
    @PreAuthorize("@ss.hasPermission('benchmark:benchmark:query')")
    public CommonResult<PageResult<BenchmarkRespVO>> getBenchmarkPage(@Valid BenchmarkReqVO pageReqVO) {
        // 查询分页数据
    }

    @PutMapping("/update")
    @Operation(summary = "更新業務")
    @PreAuthorize("@ss.hasPermission('benchmark:benchmark:update')")
    public CommonResult<Boolean> updateBenchmark(@Valid @RequestBody List<BenchmarkDetailsReqVo> updateReqVO) {
        // 更新业务数据
    }

    @DeleteMapping("/delete-list")
    @Operation(summary = "批量删除業務")
    @PreAuthorize("@ss.hasPermission('benchmark:benchmark:delete')")
    public CommonResult<Boolean> deleteBenchmarkList(@RequestParam("ids") List<String> ids) {
        // 删除数据
    }

    @GetMapping("/export-excel")
    @Operation(summary = "导出業務 Excel")
    @PreAuthorize("@ss.hasPermission('benchmark:benchmark:export')")
    public void exportBenchmarkExcel(@Valid BenchmarkReqVO pageReqVO, HttpServletResponse response) {
        // 导出Excel
    }
}
```

#### Benchmark 权限标识规范

```
格式: 模块:功能:操作
示例:
- benchmark:benchmark:query   (查询权限)
- benchmark:benchmark:create  (新增权限)
- benchmark:benchmark:update  (修改权限)
- benchmark:benchmark:delete  (删除权限)
- benchmark:benchmark:export  (导出权限)
```

---

## 前端路由生成

### 1. 登录时获取菜单数据

#### 用户登录流程

```typescript
// store/modules/user.ts
export const useUserStore = defineStore('admin-user', {
  state: (): UserInfoVO => ({
    permissions: new Set<string>(),  // 权限集合
    roles: [],                       // 角色列表
    user: {},                        // 用户信息
    isSetUser: false
  }),

  actions: {
    // 获取用户信息（登录后调用）
    async setUserInfoAction() {
      // 1. 调用后端接口获取用户信息
      let userInfo = await getInfo()

      // 2. 存储权限和角色
      this.permissions = new Set(userInfo.permissions)
      this.roles = userInfo.roles
      this.user = userInfo.user
      this.isSetUser = true

      // 3. 缓存到本地
      wsCache.set(CACHE_KEY.USER, userInfo)
      wsCache.set(CACHE_KEY.ROLE_ROUTERS, userInfo.menus)  // 菜单数据
    }
  }
})
```

#### 后端返回的数据结构

```json
{
  "code": 0,
  "data": {
    "user": {
      "id": 1,
      "nickname": "管理员",
      "avatar": "https://...",
      "deptId": 100
    },
    "roles": ["super_admin"],
    "permissions": [
      "*:*:*",
      "benchmark:benchmark:query",
      "benchmark:benchmark:update",
      "benchmark:benchmark:delete",
      "benchmark:benchmark:export"
    ],
    "menus": [
      {
        "id": 1,
        "name": "业务管理",
        "path": "/business",
        "component": "Layout",
        "meta": {
          "title": "业务管理",
          "icon": "ep:menu"
        },
        "children": [
          {
            "id": 100,
            "name": "BenchmarkPrivateBank",
            "path": "benchmark/privateBank",
            "component": "benchmark/privateBank/index",
            "meta": {
              "title": "Benchmark - Private Bank",
              "icon": "ep:document"
            }
          }
        ]
      }
    ]
  }
}
```

---

### 2. 动态路由生成

#### PermissionStore

```typescript
// store/modules/permission.ts
export const usePermissionStore = defineStore('permission', {
  state: (): PermissionState => ({
    routers: [],        // 所有路由
    addRouters: [],     // 动态添加的路由
    menuTabRouters: []  // 菜单标签路由
  }),

  actions: {
    async generateRoutes(): Promise<unknown> {
      return new Promise<void>(async (resolve) => {
        // 1. 从缓存中获取菜单列表（登录时已获取）
        let res: AppCustomRouteRecordRaw[] = []
        const roleRouters = wsCache.get(CACHE_KEY.ROLE_ROUTERS)
        if (roleRouters) {
          res = roleRouters as AppCustomRouteRecordRaw[]
        }

        // 2. 生成路由配置
        const routerMap: AppRouteRecordRaw[] = generateRoute(res)

        // 3. 动态路由，404 一定要放到最后面
        this.addRouters = routerMap.concat([
          {
            path: '/:path(.*)*',
            component: () => import('@/views/Error/404.vue'),
            name: '404Page',
            meta: {
              hidden: true,
              breadcrumb: false
            }
          }
        ])

        // 4. 渲染菜单的所有路由
        this.routers = cloneDeep(remainingRouter).concat(routerMap)
        resolve()
      })
    }
  }
})
```

---

### 3. 路由守卫

#### permission.ts 路由守卫

```typescript
// permission.ts
router.beforeEach(async (to, from, next) => {
  start()  // 开始进度条
  loadStart()

  if (getAccessToken()) {
    // 已登录
    if (to.path === '/login') {
      next({ path: '/' })
    } else {
      const dictStore = useDictStoreWithOut()
      const userStore = useUserStoreWithOut()
      const permissionStore = usePermissionStoreWithOut()

      // 1. 加载字典数据
      if (!dictStore.getIsSetDict) {
        await dictStore.setDictMap()
      }

      // 2. 加载用户信息和权限
      if (!userStore.getIsSetUser) {
        isRelogin.show = true
        await userStore.setUserInfoAction()  // 获取用户信息、权限、菜单
        isRelogin.show = false

        // 3. 生成动态路由
        await permissionStore.generateRoutes()

        // 4. 动态添加路由
        permissionStore.getAddRouters.forEach((route) => {
          router.addRoute(route as unknown as RouteRecordRaw)
        })

        // 5. 跳转到目标路由
        const redirectPath = from.query.redirect || to.path
        const redirect = decodeURIComponent(redirectPath as string)
        const { paramsObject: query } = parseURL(redirect)
        const nextData = to.path === redirect
          ? { ...to, replace: true }
          : { path: redirect, query }
        next(nextData)
      } else {
        next()
      }
    }
  } else {
    // 未登录
    if (whiteList.indexOf(to.path) !== -1 || getAccessToken()) {
      next()
    } else {
      next(`/login?redirect=${to.fullPath}`)  // 重定向到登录页
    }
  }
})
```

#### 路由守卫流程图

```
用户访问页面
    ↓
检查是否登录 (getAccessToken())
    ├─ 否 → 跳转登录页
    └─ 是 ↓
检查是否已加载用户信息 (userStore.getIsSetUser)
    ├─ 是 → 直接放行
    └─ 否 ↓
1. 调用 userStore.setUserInfoAction()
   - 获取用户信息
   - 获取权限列表
   - 获取菜单数据
    ↓
2. 调用 permissionStore.generateRoutes()
   - 根据菜单数据生成路由
    ↓
3. 动态添加路由到 router
    ↓
4. 跳转到目标页面
```

---

## 前端权限控制

### 1. 按钮权限指令

#### v-hasPermi 指令实现

```typescript
// directives/permission/hasPermi.ts
import { useUserStore } from '@/store/modules/user'

/** 判断权限的指令 directive */
export function hasPermi(app: App<Element>) {
  app.directive('hasPermi', (el, binding) => {
    const { value } = binding

    if (value && value instanceof Array && value.length > 0) {
      const hasPermissions = hasPermission(value)

      if (!hasPermissions) {
        // 没有权限，移除DOM元素
        el.parentNode && el.parentNode.removeChild(el)
      }
    } else {
      throw new Error('请设置操作权限标签值')
    }
  })
}

/** 判断权限的方法 function */
const userStore = useUserStore()
const all_permission = '*:*:*'  // 超级管理员权限

export const hasPermission = (permission: string[]) => {
  return (
    userStore.permissions.has(all_permission) ||
    permission.some((permission) => userStore.permissions.has(permission))
  )
}
```

---

### 2. 页面中使用权限控制

#### Benchmark 页面权限示例

```vue
<template>
  <div class="app-container">
    <el-form :model="queryParams">
      <!-- 搜索按钮：需要查询权限 -->
      <el-button
        @click="handleQuery"
        v-hasPermi="['benchmark:benchmark:query']">
        <Icon icon="ep:search" /> 搜索
      </el-button>

      <!-- 重置按钮：需要查询权限 -->
      <el-button
        @click="resetQuery"
        v-hasPermi="['benchmark:benchmark:query']">
        <Icon icon="ep:refresh" /> 重置
      </el-button>

      <!-- 新增按钮：需要新增权限 -->
      <el-button
        type="primary"
        @click="handleCreate"
        v-hasPermi="['benchmark:benchmark:create']">
        <Icon icon="ep:plus" /> 新增
      </el-button>

      <!-- 导出按钮：需要导出权限 -->
      <el-button
        @click="handleExport"
        v-hasPermi="['benchmark:benchmark:export']">
        <Icon icon="ep:download" /> 导出
      </el-button>

      <!-- 删除按钮：需要删除权限 -->
      <el-button
        type="danger"
        @click="handleDelete"
        v-hasPermi="['benchmark:benchmark:delete']">
        <Icon icon="ep:delete" /> 删除
      </el-button>
    </el-form>

    <!-- 表格操作列 -->
    <el-table :data="list">
      <el-table-column label="操作" width="200">
        <template #default="scope">
          <!-- 编辑按钮：需要更新权限 -->
          <el-button
            link
            type="primary"
            @click="handleUpdate(scope.row)"
            v-hasPermi="['benchmark:benchmark:update']">
            编辑
          </el-button>

          <!-- 删除按钮：需要删除权限 -->
          <el-button
            link
            type="danger"
            @click="handleDelete(scope.row)"
            v-hasPermi="['benchmark:benchmark:delete']">
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>
```

#### 权限控制效果

| 用户角色 | 拥有权限 | 可见按钮 |
|---------|---------|---------|
| **超级管理员** | `*:*:*` | 所有按钮 |
| **普通用户** | `benchmark:benchmark:query` | 搜索、重置 |
| **审批员** | `benchmark:benchmark:query`<br>`benchmark:benchmark:update` | 搜索、重置、编辑 |
| **管理员** | 所有 benchmark 权限 | 所有按钮 |

---

### 3. 编程式权限判断

#### 在 TypeScript 中判断权限

```typescript
import { checkPermi, checkRole } from '@/utils/permission'

// 方式1: 判断权限标识
if (checkPermi(['benchmark:benchmark:update'])) {
  // 有权限，执行操作
  this.showUpdateDialog = true
}

// 方式2: 判断角色
if (checkRole(['admin', 'manager'])) {
  // 是管理员或经理，执行操作
  this.showAdminPanel = true
}

// 方式3: 直接从 store 获取
import { useUserStore } from '@/store/modules/user'
const userStore = useUserStore()

if (userStore.permissions.has('benchmark:benchmark:delete')) {
  // 有删除权限
}
```

---

## Benchmark 完整示例

### 1. 数据库菜单配置

#### 菜单表数据 (system_menu)

```sql
-- 1. 父菜单：业务管理（目录）
INSERT INTO system_menu (
  id, name, permission, type, sort, parent_id, path, icon,
  component, component_name, status, visible, keep_alive
) VALUES (
  1000, '业务管理', '', 1, 10, 0, '/business', 'ep:menu',
  'Layout', NULL, 0, 1, 1
);

-- 2. 子菜单：Benchmark - Private Bank（菜单）
INSERT INTO system_menu (
  id, name, permission, type, sort, parent_id, path, icon,
  component, component_name, status, visible, keep_alive
) VALUES (
  1100, 'Benchmark - Private Bank', '', 2, 1, 1000,
  'benchmark/privateBank', 'ep:document',
  'benchmark/privateBank/index', 'BenchmarkPrivateBank',
  0, 1, 1
);

-- 3. 按钮：查询
INSERT INTO system_menu (
  id, name, permission, type, sort, parent_id
) VALUES (
  1101, '查询', 'benchmark:benchmark:query', 3, 1, 1100
);

-- 4. 按钮：新增
INSERT INTO system_menu (
  id, name, permission, type, sort, parent_id
) VALUES (
  1102, '新增', 'benchmark:benchmark:create', 3, 2, 1100
);

-- 5. 按钮：修改
INSERT INTO system_menu (
  id, name, permission, type, sort, parent_id
) VALUES (
  1103, '修改', 'benchmark:benchmark:update', 3, 3, 1100
);

-- 6. 按钮：删除
INSERT INTO system_menu (
  id, name, permission, type, sort, parent_id
) VALUES (
  1104, '删除', 'benchmark:benchmark:delete', 3, 4, 1100
);

-- 7. 按钮：导出
INSERT INTO system_menu (
  id, name, permission, type, sort, parent_id
) VALUES (
  1105, '导出', 'benchmark:benchmark:export', 3, 5, 1100
);
```

---

### 2. 角色菜单关联

#### 角色菜单关联表 (system_role_menu)

```sql
-- 假设角色ID为 100（普通用户）
-- 只分配查询权限
INSERT INTO system_role_menu (role_id, menu_id) VALUES
(100, 1000),  -- 业务管理目录
(100, 1100),  -- Benchmark菜单
(100, 1101);  -- 查询按钮

-- 假设角色ID为 101（管理员）
-- 分配所有权限
INSERT INTO system_role_menu (role_id, menu_id) VALUES
(101, 1000),  -- 业务管理目录
(101, 1100),  -- Benchmark菜单
(101, 1101),  -- 查询按钮
(101, 1102),  -- 新增按钮
(101, 1103),  -- 修改按钮
(101, 1104),  -- 删除按钮
(101, 1105);  -- 导出按钮
```

---

### 3. 用户角色关联

#### 用户角色关联表 (system_user_role)

```sql
-- 用户ID为 1 的用户是管理员
INSERT INTO system_user_role (user_id, role_id) VALUES (1, 101);

-- 用户ID为 2 的用户是普通用户
INSERT INTO system_user_role (user_id, role_id) VALUES (2, 100);
```

---

### 4. 完整权限验证流程

#### 场景：用户 A（普通用户）访问 Benchmark 页面

```
1. 用户登录
   POST /login
   用户名: userA
   密码: ******
    ↓
2. 后端验证用户名密码
    ↓
3. 后端查询用户信息
   SELECT * FROM system_user WHERE username = 'userA'
   → user_id = 2
    ↓
4. 后端查询用户角色
   SELECT r.* FROM system_role r
   JOIN system_user_role ur ON r.id = ur.role_id
   WHERE ur.user_id = 2
   → role_id = 100 (普通用户)
    ↓
5. 后端查询角色菜单
   SELECT m.* FROM system_menu m
   JOIN system_role_menu rm ON m.id = rm.menu_id
   WHERE rm.role_id = 100
   → 菜单ID: [1000, 1100, 1101]
    ↓
6. 后端提取权限标识
   SELECT permission FROM system_menu WHERE id IN (1000, 1100, 1101)
   → permissions: ['benchmark:benchmark:query']
    ↓
7. 后端返回登录结果
   {
     "user": { "id": 2, "nickname": "普通用户" },
     "roles": ["user"],
     "permissions": ["benchmark:benchmark:query"],
     "menus": [
       {
         "name": "业务管理",
         "path": "/business",
         "children": [
           {
             "name": "BenchmarkPrivateBank",
             "path": "benchmark/privateBank",
             "component": "benchmark/privateBank/index"
           }
         ]
       }
     ]
   }
    ↓
8. 前端存储权限和菜单
   userStore.permissions = ['benchmark:benchmark:query']
   wsCache.set(CACHE_KEY.ROLE_ROUTERS, menus)
    ↓
9. 前端生成动态路由
   permissionStore.generateRoutes()
    ↓
10. 前端添加路由
    router.addRoute({
      path: '/business',
      component: Layout,
      children: [
        {
          path: 'benchmark/privateBank',
          component: () => import('@/views/benchmark/privateBank/index.vue')
        }
      ]
    })
    ↓
11. 用户访问 /business/benchmark/privateBank
    ↓
12. 页面渲染，权限指令生效
    - 搜索按钮（v-hasPermi="['benchmark:benchmark:query']"）→ 显示 ✓
    - 新增按钮（v-hasPermi="['benchmark:benchmark:create']"）→ 隐藏 ✗
    - 修改按钮（v-hasPermi="['benchmark:benchmark:update']"）→ 隐藏 ✗
    - 删除按钮（v-hasPermi="['benchmark:benchmark:delete']"）→ 隐藏 ✗
    - 导出按钮（v-hasPermi="['benchmark:benchmark:export']"）→ 隐藏 ✗
```

---

## 菜单权限流程图

### 整体流程图

```
┌────────────────────────────────────────────────────────────────┐
│  1. 用户登录                                                    │
│  POST /login { username, password }                           │
└──────────────────────┬─────────────────────────────────────────┘
                       ↓
┌────────────────────────────────────────────────────────────────┐
│  2. 后端验证 & 查询权限                                         │
│  ├─ 验证用户名密码                                              │
│  ├─ 查询用户角色: system_user_role                             │
│  ├─ 查询角色菜单: system_role_menu                             │
│  ├─ 查询菜单详情: system_menu                                  │
│  └─ 提取权限标识: menu.permission                              │
└──────────────────────┬─────────────────────────────────────────┘
                       ↓
┌────────────────────────────────────────────────────────────────┐
│  3. 返回用户信息                                                │
│  {                                                             │
│    user: {...},                                                │
│    roles: ['admin'],                                           │
│    permissions: ['benchmark:benchmark:query', ...],           │
│    menus: [{...}]                                              │
│  }                                                             │
└──────────────────────┬─────────────────────────────────────────┘
                       ↓
┌────────────────────────────────────────────────────────────────┐
│  4. 前端存储数据                                                │
│  ├─ userStore.permissions = new Set(permissions)              │
│  ├─ userStore.roles = roles                                   │
│  ├─ wsCache.set(CACHE_KEY.USER, userInfo)                     │
│  └─ wsCache.set(CACHE_KEY.ROLE_ROUTERS, menus)                │
└──────────────────────┬─────────────────────────────────────────┘
                       ↓
┌────────────────────────────────────────────────────────────────┐
│  5. 生成动态路由                                                │
│  permissionStore.generateRoutes()                             │
│  ├─ 读取菜单数据: wsCache.get(CACHE_KEY.ROLE_ROUTERS)          │
│  ├─ 转换为路由配置: generateRoute(menus)                       │
│  └─ 添加到路由: router.addRoute(route)                         │
└──────────────────────┬─────────────────────────────────────────┘
                       ↓
┌────────────────────────────────────────────────────────────────┐
│  6. 页面权限控制                                                │
│  ├─ 菜单显示: 根据 menus 数据渲染侧边栏                        │
│  ├─ 路由访问: 只能访问已添加的动态路由                         │
│  ├─ 按钮显示: v-hasPermi 指令检查 permissions                  │
│  └─ API调用: 后端 @PreAuthorize 验证权限                       │
└────────────────────────────────────────────────────────────────┘
```

---

## 常见问题与最佳实践

### Q1: 如何新增一个菜单？

**步骤**:

1. **在数据库中新增菜单**
   ```sql
   INSERT INTO system_menu (...) VALUES (...);
   ```

2. **分配给角色**
   ```sql
   INSERT INTO system_role_menu (role_id, menu_id) VALUES (角色ID, 菜单ID);
   ```

3. **前端创建页面组件**
   ```
   src/views/your-module/your-page/index.vue
   ```

4. **后端创建 Controller**
   ```java
   @PreAuthorize("@ss.hasPermission('your-module:your-page:query')")
   public CommonResult<...> yourMethod() { ... }
   ```

5. **用户重新登录**（或清除缓存后刷新页面）

---

### Q2: 权限不生效怎么办？

**排查步骤**:

1. **检查数据库菜单配置**
   ```sql
   SELECT * FROM system_menu WHERE permission = 'benchmark:benchmark:query';
   ```

2. **检查角色菜单关联**
   ```sql
   SELECT * FROM system_role_menu WHERE menu_id = 菜单ID;
   ```

3. **检查用户角色关联**
   ```sql
   SELECT * FROM system_user_role WHERE user_id = 用户ID;
   ```

4. **检查前端权限缓存**
   ```typescript
   console.log(userStore.permissions)
   ```

5. **清除缓存重新登录**

---

### Q3: 按钮权限和菜单权限有什么区别？

| 维度 | 菜单权限 | 按钮权限 |
|------|---------|---------|
| **类型** | type = 2 | type = 3 |
| **作用** | 控制页面是否可访问 | 控制按钮是否显示 |
| **实现** | 动态路由 | v-hasPermi 指令 |
| **必填字段** | path, component | permission |

**注意**: 按钮权限依赖于父菜单权限，用户必须先有菜单权限才能看到页面上的按钮。

---

### Q4: 超级管理员权限是如何实现的？

**实现方式**:

1. **后端**:
   ```java
   // PermissionServiceImpl.java
   public boolean hasAnyPermissions(Long userId, String... permissions) {
       List<RoleDO> roles = getEnableUserRoleListByUserIdFromCache(userId);

       // 判断是否是超级管理员
       return roleService.hasAnySuperAdmin(convertSet(roles, RoleDO::getId));
   }
   ```

2. **前端**:
   ```typescript
   // hasPermi.ts
   const all_permission = '*:*:*'
   export const hasPermission = (permission: string[]) => {
     return (
       userStore.permissions.has(all_permission) ||  // 超级管理员
       permission.some((p) => userStore.permissions.has(p))
     )
   }
   ```

3. **数据库配置**:
   ```sql
   -- 给超级管理员角色添加特殊权限
   INSERT INTO system_menu (name, permission, type)
   VALUES ('超级管理员', '*:*:*', 3);

   INSERT INTO system_role_menu (role_id, menu_id)
   VALUES (超级管理员角色ID, 菜单ID);
   ```

---

### Q5: 如何实现动态权限（不重启系统生效）？

**实现方式**:

1. **后端缓存更新**:
   ```java
   @CacheEvict(value = RedisKeyConstants.MENU_ROLE_ID_LIST, allEntries = true)
   public void assignRoleMenu(Long roleId, Set<Long> menuIds) {
       // 更新角色菜单关联
   }
   ```

2. **前端清除缓存**:
   ```typescript
   // 清除权限缓存
   wsCache.delete(CACHE_KEY.USER)
   wsCache.delete(CACHE_KEY.ROLE_ROUTERS)

   // 重新加载用户信息
   await userStore.setUserInfoAction()
   await permissionStore.generateRoutes()

   // 刷新页面
   location.reload()
   ```

---

### 最佳实践

#### 1. 权限标识命名规范

```
格式: 模块:子模块:操作
示例:
- system:user:query
- system:role:create
- benchmark:benchmark:update
- bpm:process:approve
```

#### 2. 菜单层级规范

```
- 一级菜单（目录）：不配置 path 和 component
- 二级菜单（页面）：配置 path 和 component
- 三级菜单（按钮）：只配置 permission
```

#### 3. 组件命名规范

```
component: 'benchmark/privateBank/index'
componentName: 'BenchmarkPrivateBank'

规则: 模块名 + 子模块名（驼峰命名）
```

#### 4. 权限粒度设计

```
粗粒度: 只控制菜单访问
细粒度: 控制按钮显示 + 后端接口验证

推荐: 细粒度控制（安全性更高）
```

---

## 附录：关键代码位置

| 功能 | 前端文件 | 后端文件 |
|------|---------|---------|
| **菜单API** | `src/api/system/menu/index.ts` | `system/controller/admin/permission/MenuController.java` |
| **权限验证** | `src/utils/permission.ts` | `system/service/permission/PermissionServiceImpl.java` |
| **权限指令** | `src/directives/permission/hasPermi.ts` | - |
| **用户Store** | `src/store/modules/user.ts` | - |
| **权限Store** | `src/store/modules/permission.ts` | - |
| **路由守卫** | `src/permission.ts` | - |
| **路由生成** | `src/utils/routerHelper.ts` | - |
| **Benchmark Controller** | - | `business/controller/BenchmarkController.java` |
| **Benchmark 页面** | `src/views/benchmark/privateBank/index.vue` | - |

---

**文档结束** | 本文档详细讲解了 PAP 项目的菜单权限管理体系，以 Benchmark 为例展示了从数据库配置到前后端实现的完整流程。通过理解这套权限体系，可以快速为新功能添加菜单和权限控制。
