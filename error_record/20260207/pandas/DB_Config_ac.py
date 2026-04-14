import os
import base64
import re
import pandas as pd
# import sqlparse
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
from sqlalchemy import create_engine, text

# ============================================================
# 基础路径配置
# os.path.expanduser 会将 ~ 展开为当前系统用户的 home 目录
# 此路径用于存放各环境的 .properties 配置文件（当前脚本未实际读取该目录）
# ============================================================
PROPERTIES_BASE = os.path.expanduser('/opt/project/PAP/jupyterhub/properties')


# ============================================================
# 用户权限白名单
# key   : 用户名
# value : role  —— 用户角色（admin / user 等）
#         allowed —— 是否允许访问
# 当前仅作配置声明，未与查询逻辑挂钩
# ============================================================
ALLOWED_USERS = {
    'jay123666': {'role': 'admin', 'allowed': True}
}


# ============================================================
# 数据库连接配置字典
# key   : 环境标识（DEV / SIT / UAT / PROD 等，调用时不区分大小写）
# value :
#   host       —— 数据库服务器 IP
#   port       —— 端口号
#   user       —— 数据库登录用户名
#   database   —— 目标数据库名
#   properties —— AES/ECB 加密后的密码（Base64 编码字符串）
#   hex_key    —— AES 解密用的 16 字节密钥（十六进制字符串，32 个字符 = 128 bit）
# ============================================================
DB_CONFIGS = {
    'DEV': {
        'host': '10.33.213.100',
        'port': 10138,
        'user': 'papusr',
        'database': 'PAPDB',
        'properties': 'EUPSYAE28gIFDK8HHmA1VA==',
        'hex_key': '076CD005914A4F2FD1DE7AB280E37FC8'
    },
    'SIT1': {
            'host': '10.33.213.100',
            'port': 10139,
            'user': 'papusr',
            'database': 'PAPDB',
            'properties': 'EUPSYAE28gIFDK8HHmA1VA==',
            'hex_key': '076CD005914A4F2FD1DE7AB280E37FC8'
        },
    'SIT3': {
                'host': '10.33.213.100',
                'port': 10140,
                'user': 'papusr',
                'database': 'PAPDB',
                'properties': 'EUPSYAE28gIFDK8HHmA1VA==',
                'hex_key': '076CD005914A4F2FD1DE7AB280E37FC8'
            },
            'USMF': {
                    'host': '10.41.104.179',
                    'port': 10139,
                    'user': 'papusr',
                    'database': 'PAPDB',
                    'properties': 'EUPSYAE28gIFDK8HHmA1VA==',
                    'hex_key': '076CD005914A4F2FD1DE7AB280E37FC8'
                },
                'USMK': {
                        'host': '10.41.104.179',
                        'port': 10138,
                        'user': 'papusr',
                        'database': 'PAPDB',
                        'properties': 'EUPSYAE28gIFDK8HHmA1VA==',
                        'hex_key': '076CD005914A4F2FD1DE7AB280E37FC8'
                    },
}


def decrypt_password(cipher_b64: str, hex_key: str) -> str:
    """
    AES/ECB/PKCS7 解密，与 Java 端加密逻辑对称。

    解密流程：
      1. hex_key（十六进制字符串）→ bytes，作为 AES 密钥
      2. cipher_b64（Base64 字符串）→ bytes，作为密文
      3. 使用 AES-ECB 模式初始化解密器
      4. 解密后去除 PKCS7 填充，得到明文字节
      5. 以 UTF-8 解码，返回明文密码字符串

    参数：
      cipher_b64 : 加密密码的 Base64 编码字符串（来自 DB_CONFIGS 的 properties 字段）
      hex_key    : 十六进制格式的 AES 密钥字符串（来自 DB_CONFIGS 的 hex_key 字段）

    返回：
      str —— 解密后的明文密码
    """
    key_bytes = bytes.fromhex(hex_key)           # 十六进制字符串 → 16字节密钥
    cipher_bytes = base64.b64decode(cipher_b64)  # Base64 → 密文字节
    cipher = AES.new(key_bytes, AES.MODE_ECB)    # 初始化 AES-ECB 解密器
    plain_pwd = unpad(cipher.decrypt(cipher_bytes), AES.block_size).decode('utf-8')
    print(f"[decrypt_password] 解密结果: {plain_pwd}")
    return plain_pwd


def get_engine(env: str):
    """
    根据环境标识，解密数据库密码，创建并返回 SQLAlchemy Engine。

    执行流程：
      1. 将 env 统一转为大写，兼容 'dev' / 'DEV' 等写法
      2. 校验 env 是否在 DB_CONFIGS 中，不存在则抛出 ValueError
      3. 从 DB_CONFIGS 取出对应环境的配置
      4. 调用 decrypt_password 解密密码
      5. 拼接 SQLAlchemy 连接 URL（mssql+pymssql 驱动，SQL Server）
      6. 创建 Engine，启用连接保活（pool_pre_ping）和连接回收（pool_recycle=1800s）
      7. 打印连接成功提示，返回 Engine 对象

    参数：
      env : 环境标识字符串，如 'DEV'、'dev'（不区分大小写）

    返回：
      sqlalchemy.engine.Engine —— 可复用的数据库连接引擎
    """
    env = env.upper()  # 统一大写，避免大小写不一致导致 KeyError
    if env not in DB_CONFIGS:
        raise ValueError(f"未知环境: {env},可选：{list(DB_CONFIGS.keys())}")

    cfg = DB_CONFIGS[env]
    encrypted_pwd = cfg['properties']
    password = decrypt_password(encrypted_pwd, cfg['hex_key'])  # 解密密码

    # 拼接连接 URL，格式：mssql+pymssql://user:password@host:port/database?charset=utf8
    url = (
        f"mssql+pymssql://{cfg['user']}:{password}"
        f"@{cfg['host']}:{cfg['port']}/{cfg['database']}?charset=utf8"
    )

    engine = create_engine(
        url,
        pool_pre_ping=True,   # 每次取连接前发送心跳，自动剔除失效连接
        pool_recycle=1800,    # 连接存活超过 1800 秒（30分钟）后强制回收，防止数据库端主动断开
        echo=False            # 不打印 SQL 日志，生产环境保持静默
    )

    print(f"ok [{env}] 连接建立成功 --> {cfg['host']}/{cfg['database']}")
    return engine


def PAPQuery(sql: str, env: str, chunksize: int = 500) -> pd.DataFrame:
    """
    执行 SQL 查询，以脏读（READ UNCOMMITTED）隔离级别读取数据，
    避免对 SQL Server 表加共享锁，返回 pandas DataFrame。

    执行流程：
      1. 调用 get_engine 获取目标环境的数据库引擎
      2. 通过 with 语句获取连接（用完自动释放，无需手动 close）
      3. 设置事务隔离级别为 READ UNCOMMITTED（脏读），不加锁，不阻塞写操作
      4. 若指定了 chunksize：
           分块读取（每块 chunksize 行），最终用 pd.concat 合并为完整 DataFrame
           适合大数据量查询，避免一次性加载撑爆内存
         若 chunksize=0 / None / False：
           一次性读取全部结果，直接返回 DataFrame
      5. 返回查询结果 DataFrame

    参数：
      sql       : 要执行的 SQL 查询语句（字符串）
      env       : 环境标识，如 'DEV'
      chunksize : 分块读取的行数，默认 500；传 0 或 None 则一次性读取

    返回：
      pd.DataFrame —— 查询结果
    """
    env_engine = get_engine(env)  # 获取对应环境的 Engine

    with env_engine.connect() as conn:
        # READ UNCOMMITTED：允许读取未提交的数据，不对表加共享锁
        # 适合报表/分析场景，牺牲强一致性换取并发性能
        conn.execute(text("SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED"))

        if chunksize:
            # pd.read_sql 在指定 chunksize 时返回生成器（iterator），逐块产出 DataFrame
            # pd.concat 将所有块合并为一个完整 DataFrame，ignore_index 重置行索引
            return pd.concat(
                pd.read_sql(text(sql), conn, chunksize=chunksize),
                ignore_index=True
            )
        # 不分块时，直接返回完整 DataFrame
        return pd.read_sql(text(sql), conn)


# ============================================================
# 对外暴露的可用环境列表（字母序排列），方便外部调用者查看支持哪些环境
# ============================================================
AVAILABLE_ENVS = sorted(DB_CONFIGS.keys())


# ============================================================
# 直接执行入口：python DB_Config_ac.py
# 遍历所有环境，打印每个环境的解密密码
# ============================================================
if __name__ == "__main__":
    for env_name, cfg in DB_CONFIGS.items():
        print(f"\n[{env_name}] 正在解密...")
        pwd = decrypt_password(cfg['properties'], cfg['hex_key'])
        print(f"[{env_name}] 明文密码: {pwd}")
