# 前後端冪等方案

## 前端：loading 防重複提交

```html
<el-button :loading="loading">登录</el-button>
```

```js
async function handleLogin() {
  loading.value = true   // 按鈕禁用、顯示轉圈
  try {
    await authStore.login(form.value)
  } finally {
    loading.value = false  // 無論成功失敗，恢復按鈕
  }
}
```

**本質**：UI 層防抖，只能攔截同一用戶在同一瀏覽器快速重複點擊。  
攔不住：多 Tab、Postman 直調、網絡自動重試。

---

## 後端冪等方案

### 一、數據庫唯一約束（最簡單）

```sql
ALTER TABLE orders ADD UNIQUE (order_no);
```

重複插入觸發唯一鍵衝突，捕獲異常返回"已存在"。

- 適合：插入類操作
- 缺點：只能攔插入，更新場景無效

---

### 二、Token 機制（最通用）

```
① 客戶端請求前，先 GET /api/idempotency-token，拿到唯一 token
② 請求頭攜帶：Idempotency-Token: abc-123
③ 服務端：
     token 不存在 → 執行業務，token 存 Redis（設過期時間）
     token 已存在 → 直接返回上次結果，不重複執行
```

- 適合：支付、下單等核心業務（Stripe API 採用此方案）
- 注意：只解決「同一請求重試」，攔不住用戶主動發起的兩次不同請求

---

### 三、狀態機 + 樂觀鎖（更新類操作）

```sql
UPDATE orders SET status = 'paid', version = version + 1
WHERE id = 1 AND version = 5
```

```java
// JPA
@Version
private Integer version;
```

重複請求因 version 已變更，WHERE 條件匹配不上，更新行數為 0，業務不重複執行。

- 適合：訂單狀態流轉（待支付 → 已支付只能執行一次）

---

### 四、分佈式鎖（並發場景）

Token 機制攔不住兩個請求「幾乎同時」到達的情況（都是第一次，token 檢查都通過，同時執行）。

```
請求A ──→ 查 token-A 不存在 ──→ 準備扣款
請求B ──→ 查 token-B 不存在 ──→ 準備扣款
                                  ↓
                            兩個都扣了（出事）
```

用 Redis 分佈式鎖，同一時刻只有一個請求能執行：

```java
String lockKey = "transfer:lock:" + accountId;

// 嘗試加鎖，10 秒自動過期（防止宕機死鎖）
Boolean locked = redis.setIfAbsent(lockKey, "1", 10, TimeUnit.SECONDS);

if (!locked) {
    throw new RuntimeException("操作太频繁，请稍后重试");
}

try {
    doTransfer();
} finally {
    redis.delete(lockKey);  // 執行完釋放鎖
}
```

```
請求A ──→ 搶鎖成功 ──→ 執行扣款 ──→ 釋放鎖
請求B ──→ 搶鎖失敗 ──→ 返回"請稍後重試"
```

- 適合：高並發下同一資源的並發寫操作（轉賬、搶購）
- 缺點：Redis 單點故障會影響業務；鎖粒度設計不當會成性能瓶頸

---

### 五、去重表（異步/MQ 場景）

```sql
CREATE TABLE request_dedup (
    request_id VARCHAR(64) PRIMARY KEY,
    created_at DATETIME
);
```

```
收到消息 → INSERT request_id
  成功（第一次）→ 執行業務
  衝突（重複）  → 丟棄，直接返回
```

- 適合：MQ 消費防重複，消息隊列無法保證 exactly-once 時兜底

---

## 完整防重複方案全景

```
用戶操作
   │
   ▼
【第一層：前端】
  - loading 禁用按鈕
  - 確認彈窗（轉賬、刪除等高危操作）
   │
   ▼
【第二層：網關】
  - 限流：同一用戶 N 秒內最多請求 M 次（令牌桶/滑動窗口）
  - 重複請求檢測：相同請求頭 + 相同 body hash，N 秒內視為重複
   │
   ▼
【第三層：應用層】
  - Token 機制（解決網絡重試）
  - 分佈式鎖（解決並發）
   │
   ▼
【第四層：數據庫層】
  - 唯一約束
  - 樂觀鎖（version）
  - 悲觀鎖（SELECT FOR UPDATE）
   │
   ▼
【第五層：業務層】
  - 狀態機（已完成的操作不可重複）
  - 業務時間窗口去重
```

### 各方案對照表

| 層次 | 方案 | 解決什麼問題 | 攔不住什麼 |
|---|---|---|---|
| 前端 | loading + 確認彈窗 | 誤觸、手抖 | 惡意請求、多端 |
| 網關 | 限流 | 高頻刷接口 | 低頻的重複業務操作 |
| 應用 | Token 機制 | 網絡超時重試 | 用戶主動發兩次 |
| 應用 | 分佈式鎖 | 並發同時到達 | 時序上不重疊的請求 |
| 數據庫 | 唯一約束 | 插入重複數據 | 更新類操作 |
| 數據庫 | 樂觀鎖 | 並發更新衝突 | 非版本控制的場景 |
| 業務 | 狀態機 | 已終態的操作重複 | 未到終態前的重複 |
| 業務 | 時間窗口去重 | 短時間內相同業務操作 | 時間窗口之外的重複 |

### 按業務風險選擇組合

```
普通查詢    → 不需要任何冪等處理
普通表單提交 → 前端 loading + 數據庫唯一約束
支付/轉賬   → 前端確認 + Token + 分佈式鎖 + 樂觀鎖 + 狀態機
```

> 前端 loading 是體驗層的防抖，後端冪等是業務層的保障，兩者解決的問題層次不同，不能互相替代。
