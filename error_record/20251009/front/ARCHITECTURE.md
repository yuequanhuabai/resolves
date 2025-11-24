# React 项目架构：视图与逻辑分离

## 三种分离模式对比

### 方案 1：自定义 Hook 模式 ⭐ 推荐

**优点**：
- ✅ 逻辑复用性强（Hook 可在多个组件中使用）
- ✅ 组件代码简洁
- ✅ 符合 React Hooks 设计理念
- ✅ 易于测试（Hook 可以单独测试）

**缺点**：
- ⚠️ 需要理解 Hooks 规则

**适用场景**：大部分场景，现代 React 项目首选

**目录结构**：
```
src/
├── pages/              # 页面组件（视图）
│   └── User.js         # 使用 Hook
├── hooks/              # 自定义 Hook（业务逻辑）
│   └── useUser.js      # 封装所有用户相关逻辑
└── services/           # API 服务（可选）
    └── userService.js
```

**代码示例**：
```javascript
// hooks/useUser.js - 业务逻辑
export function useUser() {
  const [data, setData] = useState(null);
  // ... 所有逻辑
  return { data, loading, error, refetch };
}

// pages/User.js - 视图
function User() {
  const { data, loading, error } = useUser();
  return <div>{data?.username}</div>;
}
```

---

### 方案 2：容器/展示组件模式

**优点**：
- ✅ 职责分离明确
- ✅ 展示组件可复用
- ✅ 易于理解（经典 MVC 思想）

**缺点**：
- ⚠️ 文件数量多（每个功能至少 2 个文件）
- ⚠️ Props 传递可能繁琐

**适用场景**：展示组件需要在多处复用的场景

**目录结构**：
```
src/
├── containers/          # 容器组件（逻辑）
│   └── UserContainer.js # 处理数据和业务逻辑
└── components/          # 展示组件（视图）
    └── UserView.js      # 只负责渲染 UI
```

**代码示例**：
```javascript
// containers/UserContainer.js - 逻辑
function UserContainer() {
  const [data, setData] = useState(null);
  // ... 所有逻辑
  return <UserView data={data} onAction={handleAction} />;
}

// components/UserView.js - 视图
function UserView({ data, onAction }) {
  return <div onClick={onAction}>{data?.username}</div>;
}
```

---

### 方案 3：多层架构（企业级）⭐ 大型项目推荐

**优点**：
- ✅ 最清晰的职责分离
- ✅ API 层可单独管理
- ✅ 易于维护和扩展
- ✅ 易于单元测试

**缺点**：
- ⚠️ 文件结构复杂
- ⚠️ 小项目过度设计

**适用场景**：大型项目、团队协作、需要严格分层

**目录结构**：
```
src/
├── pages/              # 页面入口
│   └── User.js         # 组装 Hook 和 View
├── components/         # UI 组件（纯展示）
│   └── UserView.js     # 纯 UI，无逻辑
├── hooks/              # 业务逻辑
│   └── useUserData.js  # 状态管理、数据处理
├── services/           # API 服务
│   └── userService.js  # HTTP 请求封装
└── utils/              # 工具函数
    └── validators.js
```

**代码示例**：
```javascript
// services/userService.js - API 层
export const userService = {
  async getUser(signal) {
    const res = await fetch('/api/user', { signal });
    return res.json();
  }
};

// hooks/useUserData.js - 业务逻辑层
export function useUserData() {
  const [data, setData] = useState(null);
  useEffect(() => {
    const controller = new AbortController();
    userService.getUser(controller.signal)
      .then(setData);
    return () => controller.abort();
  }, []);
  return { data, loading, error };
}

// components/UserView.js - 视图层
function UserView({ user, onLogout }) {
  return (
    <div>
      <h1>{user.name}</h1>
      <button onClick={onLogout}>登出</button>
    </div>
  );
}

// pages/User.js - 组装层
function User() {
  const { data, loading } = useUserData();
  const handleLogout = () => { /* ... */ };
  return <UserView user={data} onLogout={handleLogout} />;
}
```

---

## 推荐的项目结构（方案 3 完整版）

```
oauth2-client-ui/
├── public/
├── src/
│   ├── pages/              # 页面组件（路由级别）
│   │   ├── Home.js
│   │   ├── Callback.js
│   │   └── User.js
│   │
│   ├── components/         # 可复用的 UI 组件
│   │   ├── common/         # 通用组件
│   │   │   ├── Button.js
│   │   │   ├── Loading.js
│   │   │   └── ErrorMessage.js
│   │   └── user/           # 用户相关组件
│   │       └── UserProfile.js
│   │
│   ├── hooks/              # 自定义 Hook（业务逻辑）
│   │   ├── useUser.js      # 用户逻辑
│   │   ├── useAuth.js      # 认证逻辑
│   │   └── useCallback.js  # 回调处理逻辑
│   │
│   ├── services/           # API 服务层
│   │   ├── api.js          # 基础 API 配置
│   │   ├── userService.js  # 用户相关 API
│   │   └── authService.js  # 认证相关 API
│   │
│   ├── utils/              # 工具函数
│   │   ├── validators.js   # 验证函数
│   │   └── formatters.js   # 格式化函数
│   │
│   ├── constants/          # 常量
│   │   └── endpoints.js    # API 端点常量
│   │
│   ├── App.js              # 应用入口
│   └── index.js            # React 入口
│
├── package.json
└── README.md
```

---

## 实际应用示例

### 使用方案 1（推荐用于当前项目）

#### 1. 创建 Service 层（可选但推荐）

```javascript
// src/services/userService.js
const API_BASE = 'http://localhost:9091/api';

export const userService = {
  async getUser(signal) {
    const res = await fetch(`${API_BASE}/user`, {
      credentials: 'include',
      signal
    });
    if (!res.ok) throw new Error('Failed to fetch user');
    return res.json();
  },

  async logout() {
    const res = await fetch(`${API_BASE}/logout`, {
      method: 'POST',
      credentials: 'include',
    });
    if (!res.ok) throw new Error('Failed to logout');
    return res.json();
  }
};
```

#### 2. 创建自定义 Hook

```javascript
// src/hooks/useUser.js
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { userService } from '../services/userService';

export function useUser() {
  const [userInfo, setUserInfo] = useState(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const controller = new AbortController();

    userService.getUser(controller.signal)
      .then(setUserInfo)
      .catch((err) => {
        if (err.name !== 'AbortError') {
          navigate('/');
        }
      })
      .finally(() => setLoading(false));

    return () => controller.abort();
  }, [navigate]);

  const logout = async () => {
    try {
      await userService.logout();
      navigate('/');
    } catch (error) {
      alert('登出失败');
    }
  };

  return { userInfo, loading, logout };
}
```

#### 3. 使用 Hook（页面组件）

```javascript
// src/pages/User.js
import { useUser } from '../hooks/useUser';

function User() {
  const { userInfo, loading, logout } = useUser();

  if (loading) return <div>加载中...</div>;

  return (
    <div>
      <h1>用户信息</h1>
      <p>用户名: {userInfo?.username}</p>
      <button onClick={logout}>登出</button>
    </div>
  );
}
```

---

## 为什么要分离？

### 问题：所有代码写在一起

```javascript
// ❌ 混乱的代码
function User() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showModal, setShowModal] = useState(false);
  const navigate = useNavigate();

  useEffect(() => { /* 50 行代码 */ }, []);

  const handleSubmit = async () => { /* 30 行代码 */ };
  const validateForm = () => { /* 20 行代码 */ };
  const formatData = () => { /* 15 行代码 */ };

  return (
    <div>
      {/* 100 行 JSX */}
    </div>
  );
}
// 总共 200+ 行代码在一个文件中！
```

### 解决：分层后

```javascript
// ✅ 清晰的代码

// services/userService.js - 15 行
// hooks/useUser.js - 30 行
// components/UserView.js - 40 行（纯 UI）
// pages/User.js - 10 行（组装）

// 职责清晰，易于维护和测试
```

---

## 测试优势

### 分离前：难以测试

```javascript
// ❌ 无法单独测试业务逻辑
test('user logic', () => {
  // 必须渲染整个组件
  render(<User />);
  // 难以模拟不同状态
});
```

### 分离后：易于测试

```javascript
// ✅ 可以单独测试每一层

// 测试 Service
test('userService.getUser', async () => {
  const data = await userService.getUser();
  expect(data).toHaveProperty('username');
});

// 测试 Hook
test('useUser hook', () => {
  const { result } = renderHook(() => useUser());
  expect(result.current.loading).toBe(true);
});

// 测试 UI
test('UserView renders', () => {
  const mockUser = { username: 'test' };
  render(<UserView user={mockUser} />);
  expect(screen.getByText('test')).toBeInTheDocument();
});
```

---

## 总结

| 场景 | 推荐方案 |
|------|---------|
| 小型项目（< 10 页面） | 方案 1：自定义 Hook |
| 中型项目（10-50 页面） | 方案 1 + Service 层 |
| 大型项目（> 50 页面） | 方案 3：完整多层架构 |
| 需要复用 UI 组件 | 方案 2：容器/展示组件 |
| 团队协作、严格规范 | 方案 3：完整多层架构 |

**当前 OAuth2 项目推荐**：方案 1（自定义 Hook + Service）

---

## 下一步行动

如果你想重构现有代码，我可以帮你：

1. ✅ 将 `User.js` 重构为 Hook + View 模式
2. ✅ 将 `Callback.js` 重构为 Hook + View 模式
3. ✅ 将 `Home.js` 重构为 Hook + View 模式
4. ✅ 创建统一的 `services/` 层
5. ✅ 添加错误处理和加载状态的通用组件

只需告诉我你想重构哪些文件！
