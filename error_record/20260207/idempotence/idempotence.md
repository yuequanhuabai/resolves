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

### 四、去重表（異步/MQ 場景）

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

## 總結

| 方案 | 適用場景 | 核心手段 |
|---|---|---|
| 前端 loading | 用戶誤觸重複點擊 | 按鈕禁用 |
| 數據庫唯一約束 | 插入類操作 | UNIQUE 索引 |
| Token 機制 | 支付、下單核心業務 | Redis 存 token |
| 狀態機 + 樂觀鎖 | 狀態流轉類更新 | version 字段 |
| 去重表 | MQ 消費防重複 | 主鍵唯一衝突 |

> 前端 loading 是體驗層的防抖，後端冪等是業務層的保障，兩者解決的問題層次不同，不能互相替代。
