# CentOS 8 安装 SQL Server 2022 Developer Edition 教程（非 root 用户）

> 服务器配置：2C 2G 3M | 系统：CentOS 8 | 版本：SQL Server 2022 Developer Edition

---

## 一、前置准备（root 用户操作）

以下步骤需要 root 用户完成，后续所有操作交给专用数据库用户。

### 1.1 创建数据库专用用户

```bash
# 创建用户 mssql_admin（用于管理 SQL Server 的操作系统用户）
useradd -m -s /bin/bash mssql_admin

# 设置密码
passwd mssql_admin
Aa+123,.

# 赋予 sudo 权限
usermod -aG wheel mssql_admin
```

### 1.2 配置 sudo 免密（可选，方便操作）

```bash
visudo
```

在文件末尾添加：

```
mssql_admin ALL=(ALL) NOPASSWD: ALL
```

### 1.3 切换到 mssql_admin 用户

```bash
su - mssql_admin
```

> 以下所有操作均在 mssql_admin 用户下执行，需要权限的地方使用 sudo。

---

## 二、系统环境准备

### 2.1 CentOS 8 换源（官方源已停止维护）

CentOS 8 已于 2021 年底 EOL，需要切换到可用的镜像源：

```bash
# 备份原有 repo 文件
sudo mkdir -p /etc/yum.repos.d/backup
sudo mv /etc/yum.repos.d/CentOS-*.repo /etc/yum.repos.d/backup/

# 使用阿里云 CentOS Vault 镜像源
sudo cat > /etc/yum.repos.d/CentOS-Vault.repo << 'EOF'
[BaseOS]
name=CentOS-8 - Base
baseurl=https://mirrors.aliyun.com/centos-vault/centos/8.5.2111/BaseOS/x86_64/os/
gpgcheck=0
enabled=1

[AppStream]
name=CentOS-8 - AppStream
baseurl=https://mirrors.aliyun.com/centos-vault/centos/8.5.2111/AppStream/x86_64/os/
gpgcheck=0
enabled=1
EOF

# 清理并重建缓存
sudo dnf clean all
sudo dnf makecache
```

### 2.2 安装必要依赖

```bash
sudo dnf install -y python3 openssl libcurl
```

### 2.3 2G 内存优化 — 配置 Swap

2G 内存偏小，建议添加 2G swap 防止 OOM：

```bash
# 创建 2G swap 文件
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 设置开机自动挂载
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 验证
free -h
```

---

## 三、安装 SQL Server 2022

### 3.1 添加 SQL Server 仓库

```bash
sudo curl -o /etc/yum.repos.d/mssql-server.repo \
  https://packages.microsoft.com/config/rhel/8/mssql-server-2022.repo
```

### 3.2 安装 SQL Server

```bash
sudo dnf install -y mssql-server
```

### 3.3 配置 SQL Server

```bash
sudo /opt/mssql/bin/mssql-conf setup
```

交互过程：

```
选择版本：输入 2（Developer Edition）
接受许可：输入 Yes
设置 SA 密码：输入一个强密码（至少 8 位，含大小写字母+数字+特殊字符）
例如：MyDev@2024#Sql
```

### 3.4 2G 内存关键设置 — 限制内存使用

```bash
# 限制 SQL Server 最大使用 768MB 内存（给系统和其他进程留空间）
sudo /opt/mssql/bin/mssql-conf set memory.memorylimitmb 768

# 重启服务生效
sudo systemctl restart mssql-server
```

### 3.5 验证服务状态

```bash
sudo systemctl status mssql-server
```

看到 `active (running)` 即表示安装成功。

### 3.6 设置开机自启

```bash
sudo systemctl enable mssql-server
```

---

## 四、安装命令行工具（sqlcmd）

### 4.1 添加工具仓库

```bash
sudo curl -o /etc/yum.repos.d/mssql-tools.repo \
  https://packages.microsoft.com/config/rhel/8/prod.repo
```

### 4.2 安装 sqlcmd 和 bcp

```bash
sudo dnf install -y mssql-tools18 unixODBC-devel
```

安装过程中会提示接受许可协议，输入 `Yes`。

### 4.3 添加环境变量

```bash
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc
```

### 4.4 验证连接

```bash
# -C 参数表示信任自签名证书（开发环境使用）
sqlcmd -S localhost -U SA -P 'MyDev@2024#Sql' -C -Q "SELECT @@VERSION"
```

能看到 SQL Server 版本信息即表示一切正常。

---

## 五、防火墙配置

### 5.1 开放 1433 端口

```bash
sudo firewall-cmd --zone=public --add-port=1433/tcp --permanent
sudo firewall-cmd --reload
```

### 5.2 验证端口

```bash
sudo firewall-cmd --list-ports
```

> 如果服务器在云平台（阿里云/腾讯云等），还需要在**安全组**中放行 1433 端口。

---

## 六、安全加固建议

### 6.1 创建日常使用的数据库账户（不要直接用 SA）

```bash
sqlcmd -S localhost -U SA -P 'MyDev@2024#Sql' -C << 'SQL'
-- 创建登录账户
CREATE LOGIN devuser WITH PASSWORD = 'DevUser@2024#';

-- 创建数据库
CREATE DATABASE mydevdb;
GO

-- 在数据库中创建用户并授权
USE mydevdb;
CREATE USER devuser FOR LOGIN devuser;
ALTER ROLE db_owner ADD MEMBER devuser;
GO

PRINT '创建完成';
GO
SQL
```

### 6.2 验证新用户连接

```bash
sqlcmd -S localhost -U devuser -P 'DevUser@2024#' -d mydevdb -C -Q "SELECT DB_NAME() AS current_db"
```

### 6.3 限制 SA 远程访问（建议）

日常开发使用 devuser，SA 仅在本地管理时使用。可以在应用连接串中始终使用 devuser。

---

## 七、远程连接

使用以下连接信息在本地开发工具中连接：

| 参数 | 值 |
|------|-----|
| 服务器 | `你的服务器公网IP,1433` |
| 用户名 | `devuser` |
| 密码 | `DevUser@2024#` |
| 数据库 | `mydevdb` |
| 加密 | 信任服务器证书（开发环境） |

支持的客户端工具：
- SSMS（SQL Server Management Studio）
- Azure Data Studio
- DBeaver
- Navicat
- JetBrains DataGrip

---

## 八、常用管理命令速查

```bash
# 查看服务状态
sudo systemctl status mssql-server

# 启动 / 停止 / 重启
sudo systemctl start mssql-server
sudo systemctl stop mssql-server
sudo systemctl restart mssql-server

# 查看错误日志
sudo cat /var/opt/mssql/log/errorlog

# 修改 SA 密码
sudo /opt/mssql/bin/mssql-conf set-sa-password

# 查看当前配置
sudo cat /var/opt/mssql/mssql.conf

# 修改内存限制（单位 MB）
sudo /opt/mssql/bin/mssql-conf set memory.memorylimitmb 768

# 修改 TCP 端口
sudo /opt/mssql/bin/mssql-conf set network.tcpport 1434
```

---

## 九、卸载（如需要）

```bash
sudo systemctl stop mssql-server
sudo dnf remove -y mssql-server mssql-tools18
sudo rm -rf /var/opt/mssql
```

---

## 附：安装流程总结

```
1. root 创建 mssql_admin 用户并授予 sudo 权限
2. 切换到 mssql_admin 用户
3. 修复 CentOS 8 软件源
4. 配置 swap（2G 内存必做）
5. 添加微软仓库 → 安装 mssql-server
6. 运行 mssql-conf setup 选择 Developer 版本
7. 限制内存为 768MB
8. 安装 sqlcmd 命令行工具
9. 开放防火墙 1433 端口
10. 创建日常开发用的数据库账户
```
