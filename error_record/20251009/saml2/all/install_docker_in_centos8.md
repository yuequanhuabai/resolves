# CentOS 8 安装 Docker

> CentOS 8 已 EOL，官方源已失效，需要先切换镜像源。

---

## 第一步：修复 CentOS 8 的 yum 源（EOL 问题）

```bash
 
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo
```

---

## 第二步：安装 Docker

```bash
# 安装依赖
yum install -y yum-utils

# 添加 Docker 源（官方源，如果网络正常优先用这个）
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 如果官方源报 SSL 错误（国内常见），改用阿里云镜像源
# yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 安装 Docker
yum install -y docker-ce docker-ce-cli containerd.io

# 启动并设置开机自启
systemctl start docker
systemctl enable docker
```

---

## 第三步：验证安装

```bash
docker --version
docker run hello-world
```

看到 `Hello from Docker!` 即表示安装成功。

> **如果拉镜像超时**（国内常见，报 `context deadline exceeded`），需要配置 Docker 镜像加速器：
>
> ```bash
> vi /etc/docker/daemon.json
> ```
>
> 输入以下内容：
>
> ```json
> {
>   "registry-mirrors": [
>     "https://docker.1ms.run",
>     "https://docker.xuanyuan.me"
>   ]
> }
> ```
>
> 保存后重启 Docker：
>
> ```bash
> systemctl daemon-reload
> systemctl restart docker
> ```
>
> 然后重新执行 `docker run hello-world` 验证。

---

## 第四步：启动 Keycloak

```bash
docker run -d -p 8180:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  -e KC_HOSTNAME_STRICT=false \
  -e KC_HOSTNAME_STRICT_HTTPS=false \
  -e KC_HTTP_ENABLED=true \
  --name keycloak \
  quay.io/keycloak/keycloak:latest start-dev
```

---

## 第五步：关闭 Realm 级别的 HTTPS 强制要求

Keycloak 有两层 HTTPS 控制：服务器级别和 Realm 级别。第四步的环境变量只解决了服务器级别，Realm（master）默认仍然要求外部访问走 HTTPS，会报 `HTTPS required` 错误。

通过容器内部的命令行工具修改（从容器内部走 localhost 不受 HTTPS 限制）：

```bash
# 先用 admin 登录，拿到操作令牌
docker exec keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 --realm master --user admin --password admin

# 把 master realm 的 SSL 要求设为 NONE（允许 HTTP 访问）
docker exec keycloak /opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE
```

---

## 第六步：验证 Keycloak

浏览器访问 `http://<你的CentOS IP>:8180`，用 `admin/admin` 登录，看到管理界面即表示成功。
