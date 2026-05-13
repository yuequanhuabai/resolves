PersistentTokenBasedRememberMeServices方案:

● 核心设计：两个值，而不是一个

PersistentTokenBasedRememberMeServices 在数据库里维护一张表：

persistent_logins
─────────────────────────────────────────
username   → 用户名
series     → 随机字符串，标识"这台设备/这次登录"，不变
token      → 随机字符串，每次使用后更换
last_used  → 最后使用时间

发给浏览器的 Cookie 内容是：series:token（Base64 编码）

  ---
第一阶段：勾选 Remember Me 登录成功

生成随机 series = "ABC"
生成随机 token  = "111"

存入数据库：(alice, series=ABC, token=111, last_used=now)
发给浏览器：Set-Cookie: remember-me=BASE64(ABC:111); Max-Age=604800

  ---
第二阶段：关闭浏览器，重新访问（自动登录）

浏览器带着 remember-me=BASE64(ABC:111) 来访问：

① 解码 Cookie → series=ABC, token=111
② 用 series=ABC 查数据库 → 找到记录
③ 比对 token：111 == 111？→ 匹配 ✅

④ 生成新 token = "222"（旧 token 111 立刻作废）
⑤ 更新数据库：(alice, series=ABC, token=222, last_used=now)
⑥ 发给浏览器新 Cookie：Set-Cookie: remember-me=BASE64(ABC:222)

⑦ 重建 SecurityContext，用户自动登录成功

你的理解完全正确：用一次，换一个。旧 token 用完即废。

  ---
第三阶段：盗用检测——最精妙的设计

假设攻击者在第一次自动登录之后，盗到了旧 Cookie (ABC:111)：

正常用户已经用 111 换到了 222，数据库里是 token=222

攻击者拿着 (ABC:111) 来访问：
→ 用 series=ABC 查数据库 → 找到记录
→ 比对 token：111 ≠ 222 → 不匹配！

→ 系统判断：这个 series 对应的 token 已经被用过了
还有人拿着旧 token 来，说明 Cookie 被盗了

→ 立刻删除数据库里 series=ABC 的所有记录
→ 正常用户和攻击者的 remember-me 全部失效
→ 双方都被强制跳转到登录页

  ---
时序图

正常轮换流程：

    访问1  Cookie: ABC:111  →  DB查到111 ✅ → 换成222 → Cookie: ABC:222
    访问2  Cookie: ABC:222  →  DB查到222 ✅ → 换成333 → Cookie: ABC:333
    访问3  Cookie: ABC:333  →  DB查到333 ✅ → 换成444 → Cookie: ABC:444

盗用检测流程：

    正常用户  Cookie: ABC:111  → DB查到111 ✅ → 换成222 → Cookie: ABC:222
                                                             ↓
    攻击者    Cookie: ABC:111  → DB查到222 ≠ 111 ❌
                                → 删除 series=ABC 所有记录
                                → 正常用户和攻击者全部失效

  ---
登出时：立刻撤销

用户点击登出
→ 用 series 从数据库删除对应记录
→ Cookie 立刻无效，不需要等过期

这是 TokenBasedRememberMeServices 做不到的——无状态的 token 根本没法主动撤销。

  ---
两种实现对比

TokenBasedRememberMeServices
→ 无状态，服务器不存任何东西
→ token 可反复使用直到过期
→ 无法主动撤销，无法检测盗用
→ 适合：安全要求不高的场景

PersistentTokenBasedRememberMeServices
→ 有状态，数据库存 series + token
→ token 一次性，用完即换
→ 可主动撤销，可检测盗用
→ 适合：安全要求较高的场景

  ---

▎ 一句话总结：PersistentTokenBasedRememberMeServices 的核心是"series 固定标识设备，token 每次使用后轮换"——用完即废保证了 token
▎ 不可重用，数据库比对保证了盗用可检测，登出删记录保证了随时可撤销。
