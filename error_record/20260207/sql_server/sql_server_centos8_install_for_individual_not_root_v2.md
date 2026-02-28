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
sudo tee /etc/yum.repos.d/CentOS-Vault.repo > /dev/null << 'EOF'
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

### 2.2 检查磁盘空间

SQL Server 安装需要至少 **6GB** 可用磁盘空间，建议预留 **10GB+**（含数据文件和日志）：

```bash
df -h
```

确认根分区或 `/var` 分区有足够空间。如果空间不足，需要先扩容或挂载额外磁盘。

### 2.3 处理 SELinux

CentOS 8 默认开启 SELinux，可能会阻止 SQL Server 正常运行：

```bash
# 查看当前 SELinux 状态
getenforce
```

如果返回 `Enforcing`，建议改为宽松模式：

```bash
# 临时关闭（重启后失效）
sudo setenforce 0

# 永久改为宽松模式
sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
```

> 如果你对 SELinux 比较熟悉，也可以不关闭，而是为 SQL Server 添加策略：
> `sudo setsebool -P mssql_port_t on` 等，但配置较复杂，开发环境建议直接设为 permissive。

### 2.4 安装必要依赖

```bash
sudo dnf install -y python3 openssl libcurl
```

### 2.5 2G 内存优化 — 配置 Swap

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

### 3.3 配置排序规则（Collation）

如果你的项目涉及中文数据，建议在安装前先设置排序规则：

```bash
# 查看可用的中文排序规则
/opt/mssql/bin/mssql-conf set-collation | grep -i chinese
```

常用中文排序规则：

| 排序规则 | 说明 |
|---------|------|
| `Chinese_PRC_CI_AS` | 简体中文，不区分大小写，区分重音（最常用） |
| `Chinese_PRC_CS_AS` | 简体中文，区分大小写，区分重音 |
| `Chinese_Taiwan_Stroke_CI_AS` | 繁体中文（笔画排序） |

> 如果不设置，默认为 `SQL_Latin1_General_CP1_CI_AS`（英文排序），对中文数据不影响存储，但排序和比较行为可能不符合中文习惯。个人开发不敏感的话可以跳过此步。

### 3.4 配置 SQL Server

```bash
# 如需指定中文排序规则，先设置再 setup
sudo /opt/mssql/bin/mssql-conf set-collation Chinese_PRC_CI_AS

# 运行安装配置
sudo /opt/mssql/bin/mssql-conf setup
```

交互过程：

```
选择版本：输入 2（Developer Edition）
接受许可：输入 Yes
设置 SA 密码：输入一个强密码（至少 8 位，含大小写字母+数字+特殊字符）
例如：MyDev@2024#Sql
```

### 3.5 2G 内存关键设置 — 限制内存使用

```bash
# 限制 SQL Server 最大使用 768MB 内存（给系统和其他进程留空间）
sudo /opt/mssql/bin/mssql-conf set memory.memorylimitmb 768

# 重启服务生效
sudo systemctl restart mssql-server
```

### 3.6 数据目录与权限说明

SQL Server 默认数据存储路径：

| 目录 | 用途 |
|------|------|
| `/var/opt/mssql/data/` | 数据库文件（.mdf、.ndf、.ldf） |
| `/var/opt/mssql/log/` | 错误日志 |
| `/var/opt/mssql/secrets/` | 密钥文件 |

这些目录由安装程序自动创建，归 `mssql` 系统用户所有。如需修改默认数据目录：

```bash
# 自定义数据目录（例如挂载了额外磁盘）
sudo mkdir -p /data/mssql
sudo chown mssql:mssql /data/mssql

sudo /opt/mssql/bin/mssql-conf set filelocation.defaultdatadir /data/mssql
sudo /opt/mssql/bin/mssql-conf set filelocation.defaultlogdir /data/mssql
sudo systemctl restart mssql-server
```

> 注意：这里的 `mssql` 用户是 SQL Server 安装时自动创建的服务运行用户，和我们创建的 `mssql_admin` 管理用户不同。

### 3.7 验证服务状态

```bash
sudo systemctl status mssql-server
```

看到 `active (running)` 即表示安装成功。

### 3.8 设置开机自启

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

## 九、数据库备份与还原

即使是个人开发环境，也建议定期备份，避免误操作导致数据丢失。

### 9.1 手动备份

```bash
sqlcmd -S localhost -U SA -P 'MyDev@2024#Sql' -C -Q "
BACKUP DATABASE mydevdb
TO DISK = '/var/opt/mssql/data/mydevdb_backup.bak'
WITH FORMAT, COMPRESSION, NAME = 'mydevdb 手动备份';
"
```

### 9.2 还原备份

```bash
sqlcmd -S localhost -U SA -P 'MyDev@2024#Sql' -C -Q "
RESTORE DATABASE mydevdb
FROM DISK = '/var/opt/mssql/data/mydevdb_backup.bak'
WITH REPLACE;
"
```

### 9.3 定时自动备份（使用 crontab 代替 SQL Agent）

Developer 版虽然有 SQL Agent，但在 Linux 上用 crontab 更简单：

```bash
# 创建备份脚本
mkdir -p ~/backup_scripts

cat > ~/backup_scripts/backup_mssql.sh << 'SCRIPT'
#!/bin/bash
BACKUP_DIR="/var/opt/mssql/data/backups"
DATE=$(date +%Y%m%d_%H%M%S)
sudo mkdir -p $BACKUP_DIR

/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'MyDev@2024#Sql' -C -Q "
BACKUP DATABASE mydevdb
TO DISK = '${BACKUP_DIR}/mydevdb_${DATE}.bak'
WITH FORMAT, COMPRESSION;
"

# 删除 7 天前的旧备份
find $BACKUP_DIR -name "*.bak" -mtime +7 -delete
SCRIPT

chmod +x ~/backup_scripts/backup_mssql.sh
```

```bash
# 添加定时任务：每天凌晨 3 点自动备份
crontab -e
```

添加以下行：

```
0 3 * * * /home/mssql_admin/backup_scripts/backup_mssql.sh >> /home/mssql_admin/backup_scripts/backup.log 2>&1
```

---

## 十、常见问题排错

### 10.1 安装失败或服务启动失败

```bash
# 查看详细错误日志
sudo cat /var/opt/mssql/log/errorlog

# 查看 systemd 服务日志
sudo journalctl -u mssql-server --no-pager -n 50
```

### 10.2 常见错误及解决方法

| 错误 | 原因 | 解决方法 |
|------|------|----------|
| `sqlservr: This program requires a machine with at least 2000 megabytes of memory` | 内存不足 2GB | SQL Server 2019+ 要求最低 2GB，确认 `free -h` 总内存（含 swap）>= 2GB |
| `Connection refused` | 服务未启动或端口未开放 | 检查 `systemctl status mssql-server` 和防火墙 |
| `Login failed for user 'SA'` | 密码错误或密码不符合复杂度要求 | 重置密码：`sudo /opt/mssql/bin/mssql-conf set-sa-password` |
| `SELinux is preventing ...` | SELinux 阻止 | 执行 `sudo setenforce 0` |
| `No space left on device` | 磁盘空间不足 | `df -h` 检查空间，清理或扩容 |
| `Out of memory` | 内存溢出 | 降低内存限制或增加 swap |

### 10.3 服务启动但无法连接

逐步排查：

```bash
# 1. 确认服务在运行
sudo systemctl status mssql-server

# 2. 确认端口在监听
sudo ss -tlnp | grep 1433

# 3. 本地能否连接
sqlcmd -S localhost -U SA -P 'MyDev@2024#Sql' -C -Q "SELECT 1"

# 4. 确认防火墙已放行
sudo firewall-cmd --list-ports

# 5. 从远程测试端口连通性（在本地机器上执行）
# telnet 你的服务器IP 1433
```

### 10.4 内存不足导致被系统杀掉（OOM Killer）

2G 内存机器容易出现此问题：

```bash
# 检查是否被 OOM 杀掉
sudo dmesg | grep -i "oom\|killed"

# 解决方案：降低内存限制
sudo /opt/mssql/bin/mssql-conf set memory.memorylimitmb 512
sudo systemctl restart mssql-server
```

---

## 十一、卸载（如需要）

```bash
sudo systemctl stop mssql-server
sudo dnf remove -y mssql-server mssql-tools18
sudo rm -rf /var/opt/mssql
```

---

## 附：安装流程总结

```
1.  root 创建 mssql_admin 用户并授予 sudo 权限
2.  切换到 mssql_admin 用户
3.  修复 CentOS 8 软件源
4.  检查磁盘空间（>= 6GB）
5.  处理 SELinux（设为 permissive）
6.  配置 swap（2G 内存必做）
7.  添加微软仓库 → 安装 mssql-server
8.  设置排序规则（中文项目用 Chinese_PRC_CI_AS）
9.  运行 mssql-conf setup 选择 Developer 版本
10. 了解数据目录位置与权限
11. 限制内存为 768MB
12. 安装 sqlcmd 命令行工具
13. 开放防火墙 1433 端口
14. 创建日常开发用的数据库账户
15. 配置定时备份
```
