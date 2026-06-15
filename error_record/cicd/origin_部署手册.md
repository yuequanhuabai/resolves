# mylogin CI/CD 裸机部署操作手册

> 目标:`git push` 到 `main` → GitHub Actions 自动 `test → build → deploy` → 上线。
> 形态:裸机(后端 jar + systemd,前端 dist + nginx),自签证书 + 公网 IP,CentOS。

---

## 0. 宏观逻辑(先看懂全局再动手)

### 0.1 三台主机的分工

```
                          用户浏览器
                              │ HTTPS(自签证书)
                              ▼
        ┌───────────────────────────────────────────┐
        │  主机A  <HOST_A_IP>   —— 唯一对外入口        │
        │   nginx                                     │
        │    ├─ 443: 托管前端 dist 静态资源(SPA)       │
        │    └─ /api/ 反向代理 ──────────┐            │
        └───────────────────────────────│────────────┘
                                         │ HTTPS(内网调用,自签)
                                         ▼
        ┌───────────────────────────────────────────┐
        │  主机B  <HOST_B_IP>                         │
        │   Spring Boot jar (systemd 托管, 8888)      │
        └───────────────────────────────│────────────┘
                                         │ JDBC
                                         ▼
        ┌───────────────────────────────────────────┐
        │  DB节点  106.55.7.17   SQL Server(保持不动) │
        └───────────────────────────────────────────┘
```

**关键设计点(为什么这么分):**

1. **nginx 是唯一入口**:浏览器只认主机 A 一个源 `https://<HOST_A_IP>`。前端静态资源和 `/api` 后端请求都从这一个源走 —— 于是**浏览器视角下是同源,跨域(CORS)问题直接消失**,refresh_token 那个 HttpOnly Cookie 也走得很顺。
2. **HTTPS 在 nginx 终结**:自签证书放主机 A。主机 B 的后端虽然也开着 HTTPS(它本来就有 p12),但只在 A↔B 内网调用,不直接对浏览器。
3. **后端不对公网暴露**:主机 B 的 8888 用防火墙只放行主机 A,等于把后端藏在内网。

### 0.2 流水线数据流

```
你:git push 到 main
   │
   ▼
GitHub Actions(云端 ubuntu runner,两个仓库各一条)
   │
   ├─ 后端仓库:mvn clean package(先跑单测!不过就红、不部署)
   │         └→ 产出 jar ──SSH/scp──▶ 主机B:/opt/mylogin ──systemctl restart
   │
   └─ 前端仓库:npm ci && npm run build
             └→ 产出 dist ──SSH/scp──▶ 主机A:/var/www/mylogin(nginx 直接生效)
```

**"测试是门禁"** 就体现在 `mvn clean package` 这一步:它会先跑我们之前加的 10 个单测,任一失败 → 整个 job 红 → 后面的部署步骤根本不执行。这就是企业级流水线"测试不过不上线"的本质。

### 0.3 凭据放哪(重要的安全分层)

| 凭据 | 存放位置 | 原因 |
|------|----------|------|
| 主机 IP、SSH 部署私钥 | **GitHub Secrets** | CI 需要它来连服务器 |
| DB 密码、JWT secret | **主机 B 上的环境变量文件**(一次性手动配) | 应用运行时密钥,不让它流经 CI,攻击面最小 |

> 这是一个很正的企业实践:**"怎么连服务器" 交给 CI,"应用自己的密钥" 留在服务器本地**。两类密钥都绝不进 Git 仓库。

---

## 1. 准备清单(动手前先备齐)

- [ ] 主机 A 公网 IP:`<HOST_A_IP>`(填进下文所有占位符)
- [ ] 主机 B 公网 IP:`<HOST_B_IP>`
- [ ] 两台主机的 root 或 sudo 账号(用于一次性准备)
- [ ] 两个 GitHub 仓库(后端、前端各一个,代码已能 push)
- [ ] 本机装了 `ssh` / `ssh-keygen`(Windows 可用 Git Bash 或 PowerShell 自带的 OpenSSH)

> 全文凡是 `<HOST_A_IP>` `<HOST_B_IP>` 的地方,都替换成你的真实 IP。

---

## 2. 第一部分:必要的代码改动(共 4 处)

> 这几处改完后,本地照样能跑;它们是上线的前提。改完先在本地确认能编译/构建,再进入第 3 部分。

### 2.1 后端:外置 DB 密码和 JWT secret

**文件 `src/main/resources/application.yml`**,把明文改成环境变量占位:

```yaml
spring:
  datasource:
    url: jdbc:sqlserver://106.55.7.17:1433;databaseName=mylogin;encrypt=true;trustServerCertificate=true
    username: sa
    password: ${DB_PASSWORD}          # ← 原来的明文删掉,改成环境变量
    driver-class-name: com.microsoft.sqlserver.jdbc.SQLServerDriver
  # ...其余不变...

jwt:
  secret: ${JWT_SECRET}               # ← 同样改成环境变量
  access-expiration-minutes: 1
  refresh-expiration-days: 7

# 新增:CORS 允许的源,默认本地 dev,生产由环境变量覆盖
cors:
  allowed-origin: ${CORS_ALLOWED_ORIGIN:https://localhost:5173}
```

> 注意:改成 `${DB_PASSWORD}` 后,**本地 IDE 运行也要提供这两个环境变量**了(在 IDEA 的 Run Configuration → Environment variables 里加 `DB_PASSWORD=...;JWT_SECRET=...`)。这样仓库里就不再有任何明文密钥。

### 2.2 后端:CORS 源改成可配置

**文件 `src/main/java/com/t/d/mylogin/config/SecurityConfig.java`**,让 CORS 读上面的配置项:

```java
// 在类里新增一个字段(配合 import org.springframework.beans.factory.annotation.Value)
@Value("${cors.allowed-origin}")
private String allowedOrigin;

// 把 corsConfigurationSource() 里这一行:
//   config.setAllowedOrigins(List.of("https://localhost:5173"));
// 改成:
config.setAllowedOrigins(List.of(allowedOrigin));
```

> 生产环境我们会通过环境变量把它设为 `https://<HOST_A_IP>`。其实同源后浏览器不再发 CORS 预检,但配对了更稳妥。

### 2.3 前端:接口走 nginx 同源,不再直连 8888

**文件 `src/api/index.js`**,改 axios 的 baseURL:

```js
const api = axios.create({
  baseURL: '/',           // ← 原来是 'https://localhost:8888';现在走同源相对路径,由 nginx 反代到后端
  withCredentials: true,  // 这行保持不变(Cookie 跨标签页/带凭据必须)
})
```

> 改完后,前端发的请求是 `/api/auth/login` 这种相对路径,落到当前页面的源(主机 A),nginx 再转给主机 B。本地开发时需要本机也起 nginx,或临时把 baseURL 切回 `https://localhost:8888` 调试 —— 上线用 `/`。

### 2.4 前端:vite 构建时不要读本地证书(否则 CI 必崩)

**文件 `vite.config.js`** 现在**无条件**读 `./certs/*.pem`,而 CI 上没有这些证书,`npm run build` 会直接报错。改成只在本地 dev 时读:

```js
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import * as fs from 'node:fs'

export default defineConfig(({ command }) => ({
  plugins: [vue()],
  // 仅本地 dev(command==='serve')启用 HTTPS 自签证书;
  // build(CI)不读取证书,避免流水线因缺少 certs 而失败。
  ...(command === 'serve' && {
    server: {
      port: 5173,
      https: {
        cert: fs.readFileSync('./certs/localhost.pem'),
        key: fs.readFileSync('./certs/localhost-key.pem'),
      },
    },
  }),
}))
```

> 验证:本地跑 `npm run build`,应在无证书依赖下成功产出 `dist/`。

---

## 3. 第二部分:服务器一次性准备(只做一次)

### 3.1 生成专用部署密钥(在你本机执行)

```bash
ssh-keygen -t ed25519 -C "github-deploy" -f ./mylogin_deploy -N ""
```

产出两个文件:
- `mylogin_deploy`(私钥)→ 稍后填进 GitHub Secrets
- `mylogin_deploy.pub`(公钥)→ 稍后放到两台主机

查看内容备用:

```bash
cat ./mylogin_deploy        # 私钥
cat ./mylogin_deploy.pub    # 公钥
```

---

### 3.2 主机 B 准备(后端:JDK + systemd + 防火墙)

SSH 登录主机 B(用你的 sudo 账号),依次执行:

**(1) 安装 JDK 17**

```bash
sudo yum install -y java-17-openjdk-headless
java -version          # 确认输出 17.x
```

> 若 yum 源里没有 java-17(老 CentOS 7 可能没有),改用 Adoptium:
> `sudo rpm --import https://packages.adoptium.net/artifactory/api/gpg/key/public`,配置其 yum 源后 `sudo yum install -y temurin-17-jdk`。

**(2) 建目录和运行用户**

```bash
sudo useradd -r -s /sbin/nologin mylogin       # 应用运行用户(无登录权限,更安全)
sudo mkdir -p /opt/mylogin/incoming            # incoming 用于接收 CI 上传的 jar
sudo mkdir -p /etc/mylogin
```

**(3) 写运行时密钥文件**(就是 0.3 里说的"留在服务器的密钥")

```bash
sudo tee /etc/mylogin/backend.env >/dev/null <<'EOF'
DB_PASSWORD=MyDev@2024#Sql
JWT_SECRET=bXlsb2dpbi1qd3Qtc2VjcmV0LWtleS0yMDI0LWRlbW8=
CORS_ALLOWED_ORIGIN=https://<HOST_A_IP>
EOF
sudo chmod 600 /etc/mylogin/backend.env       # 只有 root 可读
```

> 记得把 `<HOST_A_IP>` 换成主机 A 真实 IP。生产请换成新的强随机 JWT_SECRET。

**(4) 创建 systemd 服务**

```bash
sudo tee /etc/systemd/system/mylogin-back.service >/dev/null <<'EOF'
[Unit]
Description=mylogin backend
After=network.target

[Service]
User=mylogin
WorkingDirectory=/opt/mylogin
EnvironmentFile=/etc/mylogin/backend.env
ExecStart=/usr/bin/java -jar /opt/mylogin/app.jar
SuccessExitStatus=143
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mylogin-back            # 开机自启(此刻还没 jar,先不 start)
```

**(5) 创建部署用户 deploy,装上公钥**

```bash
sudo useradd -m deploy
sudo mkdir -p /home/deploy/.ssh
# 把 3.1 生成的 mylogin_deploy.pub 内容粘到下面引号里:
echo "ssh-ed25519 AAAA....github-deploy" | sudo tee /home/deploy/.ssh/authorized_keys
sudo chmod 700 /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys
sudo chown -R deploy:deploy /home/deploy/.ssh
```

**(6) 授权 deploy 用户写 jar 目录 + 重启服务**

```bash
sudo chown -R deploy:deploy /opt/mylogin       # deploy 能放 jar
# 只允许 deploy 免密执行这两条 systemctl(最小授权)
echo 'deploy ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart mylogin-back, /usr/bin/systemctl status mylogin-back' | sudo tee /etc/sudoers.d/deploy
sudo chmod 440 /etc/sudoers.d/deploy
```

**(7) 防火墙:8888 只放行主机 A,SSH(22)保持开放**

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="<HOST_A_IP>/32" port port="8888" protocol="tcp" accept'
sudo firewall-cmd --reload
```

> 22 端口通常默认开放(GitHub runner 的出口 IP 不固定,无法收窄到具体段,保持 22 公网可达即可,靠密钥认证保证安全)。
> **云厂商安全组**:别忘了在腾讯云/阿里云控制台的安全组里同样放行 22(全网)和 8888(仅主机 A)。

---

### 3.3 主机 A 准备(nginx + 自签证书 + 站点)

SSH 登录主机 A:

**(1) 安装 nginx**

```bash
sudo yum install -y nginx
```

**(2) 生成自签证书**

```bash
sudo mkdir -p /etc/nginx/certs
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /etc/nginx/certs/mylogin.key \
  -out    /etc/nginx/certs/mylogin.crt \
  -subj "/CN=<HOST_A_IP>"
```

**(3) 建前端站点目录**

```bash
sudo mkdir -p /var/www/mylogin
```

**(4) 写 nginx 站点配置**

```bash
sudo tee /etc/nginx/conf.d/mylogin.conf >/dev/null <<'EOF'
# HTTP 全部跳转 HTTPS
server {
    listen 80;
    server_name <HOST_A_IP>;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name <HOST_A_IP>;

    ssl_certificate     /etc/nginx/certs/mylogin.crt;
    ssl_certificate_key /etc/nginx/certs/mylogin.key;

    root  /var/www/mylogin;
    index index.html;

    # 前端是 SPA(vue-router history 模式):找不到的路径回退到 index.html,
    # 否则刷新 /dashboard 这类深链接会 404。
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 后端反向代理:/api/* → 主机B 的 8888(后端是自签 HTTPS,故 verify off)
    location /api/ {
        proxy_pass https://<HOST_B_IP>:8888;
        proxy_ssl_verify off;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```

> 默认的 `/etc/nginx/nginx.conf` 里可能自带一个监听 80 的 `server {}`,若冲突就把它删掉/注释掉,只留我们这份。

**(5) SELinux 放行(CentOS 必做,否则 nginx 反代会 502、读 /var/www 会 403)**

```bash
# 允许 nginx 发起到后端的网络连接(反向代理需要)
sudo setsebool -P httpd_can_network_connect 1

# 让 /var/www/mylogin 拥有 nginx 可读的安全上下文(并持久化)
sudo yum install -y policycoreutils-python-utils
sudo semanage fcontext -a -t httpd_sys_content_t "/var/www/mylogin(/.*)?"
sudo restorecon -Rv /var/www/mylogin
```

**(6) 创建部署用户 deploy,装公钥,授权写站点目录**

```bash
sudo useradd -m deploy
sudo mkdir -p /home/deploy/.ssh
echo "ssh-ed25519 AAAA....github-deploy" | sudo tee /home/deploy/.ssh/authorized_keys
sudo chmod 700 /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys
sudo chown -R deploy:deploy /home/deploy/.ssh

sudo chown -R deploy:deploy /var/www/mylogin   # deploy 能写前端文件
```

**(7) 启动 nginx + 防火墙放行 80/443**

```bash
sudo systemctl enable --now nginx
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

> 同样别忘了云厂商安全组放行 80、443。

---

## 4. 第三部分:GitHub 配置

### 4.1 配置 Secrets(两个仓库都要配同样这几个)

进入仓库 → **Settings → Secrets and variables → Actions → New repository secret**,逐个添加:

| Secret 名 | 值 |
|-----------|-----|
| `HOST_A_IP` | 主机 A 公网 IP |
| `HOST_B_IP` | 主机 B 公网 IP |
| `DEPLOY_USER` | `deploy` |
| `DEPLOY_SSH_KEY` | `mylogin_deploy` **私钥**全文(含 `-----BEGIN...END-----`) |

> 注意:DB 密码、JWT secret **不进 GitHub** —— 它们已在主机 B 的 `/etc/mylogin/backend.env` 里(见 0.3)。

### 4.2 后端仓库工作流

在**后端仓库**新建文件 `.github/workflows/deploy.yml`:

```yaml
name: CI-CD Backend
on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
          cache: maven

      # 先跑单测再打包:测试失败这步就红,后面的部署根本不会执行(测试门禁)
      - name: Build & Test
        run: mvn -B clean package

      # 把 jar 传到主机B 的 incoming 目录
      - name: Upload jar to Host B
        uses: appleboy/scp-action@v0.1.7
        with:
          host: ${{ secrets.HOST_B_IP }}
          username: ${{ secrets.DEPLOY_USER }}
          key: ${{ secrets.DEPLOY_SSH_KEY }}
          source: "target/*.jar"
          target: "/opt/mylogin/incoming"
          strip_components: 1     # 去掉 target/ 前缀,文件直接落到 incoming/

      # 激活新 jar 并重启(保留上一版本用于回滚)
      - name: Activate & Restart
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.HOST_B_IP }}
          username: ${{ secrets.DEPLOY_USER }}
          key: ${{ secrets.DEPLOY_SSH_KEY }}
          script: |
            set -e
            cp /opt/mylogin/app.jar /opt/mylogin/app.jar.bak 2>/dev/null || true
            mv /opt/mylogin/incoming/*.jar /opt/mylogin/app.jar
            sudo systemctl restart mylogin-back
            sleep 3
            sudo systemctl --no-pager status mylogin-back
```

### 4.3 前端仓库工作流

在**前端仓库**新建文件 `.github/workflows/deploy.yml`:

```yaml
name: CI-CD Frontend
on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: npm

      - name: Install & Build
        run: |
          npm ci
          npm run build

      # 先清空旧静态文件,避免残留
      - name: Clean remote web root
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.HOST_A_IP }}
          username: ${{ secrets.DEPLOY_USER }}
          key: ${{ secrets.DEPLOY_SSH_KEY }}
          script: rm -rf /var/www/mylogin/*

      # 上传新 dist
      - name: Upload dist to Host A
        uses: appleboy/scp-action@v0.1.7
        with:
          host: ${{ secrets.HOST_A_IP }}
          username: ${{ secrets.DEPLOY_USER }}
          key: ${{ secrets.DEPLOY_SSH_KEY }}
          source: "dist/*"
          target: "/var/www/mylogin"
          strip_components: 1     # 去掉 dist/ 前缀
```

> `appleboy/*-action` 的版本号可能更新,若报版本不存在,去其 GitHub 页面换成最新 tag 即可。

---

## 5. 第四部分:首次跑通与验证

> 建议**先后端、再前端**,逐个验证,出问题好定位。

### 5.1 后端首次部署

1. 把第 2 部分的后端代码改动提交,push 到 `main`。
2. 打开仓库 **Actions** 标签,看 `CI-CD Backend` 这条 run:
   - `Build & Test` 绿 = 单测通过、jar 打好;
   - `Activate & Restart` 末尾会打印 `active (running)` = 服务起来了。
3. 在主机 B 上自查:

```bash
sudo systemctl status mylogin-back          # active (running)
sudo journalctl -u mylogin-back -n 50        # 看启动日志,确认连上了 DB
curl -k https://localhost:8888/api/auth/login -X POST \
     -H 'Content-Type: application/json' -d '{}'   # 通了会返回 401/400(而非连接拒绝)
```

### 5.2 前端首次部署

1. 把第 2 部分的前端代码改动提交,push 到 `main`。
2. Actions 里看 `CI-CD Frontend` 跑绿。
3. 浏览器打开 `https://<HOST_A_IP>`:
   - 自签证书会有安全警告 → 选择"继续前往"(这是自签证书的正常现象);
   - 进入登录页 → 用你 DB 里的账号登录;
   - F12 → Network,确认请求打到 `https://<HOST_A_IP>/api/auth/login` 且返回 200;
   - 登录后刷新页面仍保持登录(说明 refresh_token Cookie + 静默刷新链路通了)。

### 5.3 端到端联调成功的标志

- 登录成功、能看到用户列表;
- 刷新页面不掉登录;
- 多开一个标签页,一个登出另一个跟着登出(BroadcastChannel 同步);
- 整个过程 Network 里没有 CORS 报错。

---

## 6. 第五部分:日常使用与排错

### 6.1 日常发版

以后改完代码,只需:

```bash
git push origin main
```

剩下的 test → build → deploy 全自动。Actions 红了就点进去看哪一步失败。

### 6.2 回滚后端到上一版本

CI 已自动保留上一版 jar 为 `app.jar.bak`。SSH 到主机 B:

```bash
sudo -u deploy bash -c 'cp /opt/mylogin/app.jar.bak /opt/mylogin/app.jar'
sudo systemctl restart mylogin-back
```

### 6.3 常见故障速查

| 现象 | 多半原因 | 处理 |
|------|----------|------|
| 浏览器访问 `/api` 返回 **502** | nginx 连不上主机 B | 检查主机 B 服务是否 running、防火墙/安全组是否放行 8888 给主机 A、SELinux 是否执行了 `httpd_can_network_connect` |
| 访问首页 **403** | SELinux 没给 /var/www 上下文 | 重跑 3.3 (5) 的 `semanage`+`restorecon` |
| 刷新深链接(如 /users)**404** | nginx 少了 SPA 回退 | 确认 `try_files ... /index.html` 在位 |
| Actions 部署步骤 **Permission denied** | 公钥没装对 / deploy 无权限 | 核对两台主机的 `authorized_keys`、`/opt/mylogin` 与 `/var/www/mylogin` 的属主是 deploy |
| 后端起不来,日志报 **password/secret 为空** | env 文件没配或路径不对 | 检查 `/etc/mylogin/backend.env`、systemd 的 `EnvironmentFile` |
| `npm run build` 在 CI **报找不到 certs** | 没做 2.4 的改动 | 按 2.4 改 vite.config.js |

---

## 7. 附录:后续升级 Docker 时的切换点(先了解,暂不做)

等你要升级到容器化时,只需替换这几处,主体不变:

- **后端**:加 `Dockerfile`(`FROM eclipse-temurin:17` + 拷 jar),CI 改为 `docker build` + 推镜像/或直接 `docker save | ssh docker load`,主机 B 把 systemd 换成 `docker run`/compose。env 文件改成 compose 的 `env_file`。
- **前端**:加 `Dockerfile`(`FROM nginx` + 拷 dist + 站点配置),主机 A 换成跑 nginx 容器。
- **流水线骨架、Secrets、反代逻辑、同源策略** 全部沿用,不用重设计。

---

*手册结束。占位符 `<HOST_A_IP>` / `<HOST_B_IP>` 全部替换后即可逐条执行。*
