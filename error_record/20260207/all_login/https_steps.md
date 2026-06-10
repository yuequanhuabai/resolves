mkcert 路线，全部步骤如下。每步都标了在哪执行，出错就把报错贴给我。

  ---
Step 0 · 安装 mkcert（Windows）

任选一种（看你装了哪个包管理器）：

winget install FiloSottile.mkcert      # winget
# 或  choco install mkcert
# 或  scoop install mkcert

装完验证：
mkcert -version

▎ 都没有包管理器的话告诉我，我给你直接下 exe 的办法。

  ---
Step 1 · 生成证书

1a. 安装本地 CA（一次性，全机生效）
mkcert -install
这步会把 mkcert 的本地 CA 装进系统/浏览器信任库——这正是"零警告 + XHR 正常"的关键。

1b. 给后端生成 PKCS12（Spring 用）

在 mylogin-back/src/main/resources/ 目录下执行：
cd D:\software\developmentTools\Git\gitee\newpap\login\mylogin-back\src\main\resources
mkcert -pkcs12 -p12-file localhost.p12 localhost 127.0.0.1 ::1

▎ ⚠️ mkcert 生成的 p12 默认密码是 changeit，下一步要用到。

1c. 给前端生成 PEM（Vite/Node 用）

在 mylogin-front/ 下建个 certs 目录并生成：
cd D:\software\developmentTools\Git\gitee\newpap\login\mylogin-front
mkdir certs
cd certs
mkcert -cert-file localhost.pem -key-file localhost-key.pem localhost 127.0.0.1 ::1

1d. 别把私钥提交进 git

分别在两个项目的 .gitignore 末尾追加：
- mylogin-back/.gitignore → 加一行 src/main/resources/*.p12
- mylogin-front/.gitignore → 加一行 certs/

  ---
Step 2 · 后端改动（3 处）

2a. mylogin-back/src/main/resources/application.yml — server: 块改成：
server:
port: 8888
ssl:
enabled: true
key-store: classpath:localhost.p12
key-store-type: PKCS12
key-store-password: changeit

▎ 没写 key-alias是故意的：keystore 里只有一个密钥时 Spring 会自动选中,省去对错别名的麻烦。

2b. AuthController.java:94 — Cookie 打开 secure：
.secure(false)          // 生产环境改为 true（HTTPS）
改为：
.secure(true)           // HTTPS 下 RT Cookie 仅经加密连接传输

2c. SecurityConfig.java:63 — CORS 来源改 https：
config.setAllowedOrigins(List.of("http://localhost:5173"));
改为：
config.setAllowedOrigins(List.of("https://localhost:5173"));

  ---
Step 3 · 前端改动（2 处）

3a. mylogin-front/vite.config.js — 整个文件替换为：
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import fs from 'node:fs'

export default defineConfig({
plugins: [vue()],
server: {
port: 5173,
https: {
cert: fs.readFileSync('./certs/localhost.pem'),
key: fs.readFileSync('./certs/localhost-key.pem'),
},
},
})

3b. mylogin-front/src/api/index.js:5 — baseURL 改 https：
baseURL: 'http://localhost:8888',
改为：
baseURL: 'https://localhost:8888',

  ---
Step 4 · 启动验证

1. 重启后端，启动日志应出现 https / 8888 (https) 字样。
2. 浏览器先单独访问一次 https://localhost:8888/api/auth/me —— 地址栏应是小锁、无证书警告（验证后端证书被信任）。
3. npm run dev 起前端，访问 https://localhost:5173，走一遍登录。
4. 关键检查点：DevTools → Application → Cookies → refresh_token 那一行的 Secure 列应打勾 ✓。这就是这次改造真正的目标——RT 不再明文裸奔。

  ---
要不要我顺手把这次涉及的 5 处代码改动整理成一份核对清单文档放进项目？另外第 4 步那个"单独访问后端 URL
验证证书"的动作建议别跳过——如果后端证书没被信任,前端登录会卡在一堆看不出原因的 XHR
失败上,先单独验证能帮你把"证书问题"和"代码问题"分开排查。先按上面跑,卡住随时贴报错。
