import os
import base64
import re
import pandas as pd
# import sqlparse
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
from sqlalchemy import create_engine,text

PROPERTIES_BASE=os.path.expanduser('/opt/project/PAP/jupyterhub/properties')


ALLOWED_USERS={
  'jay123666':{'role':'admin','allowed':true}
}

DB_CONFIGS={
    'DEV'={
        'host':'10.33.213.100',
        'port':10138,
        'user':'papusr',
        'database':'PAPDB',
        'properties':'EUPSYAE28gIFDK8HHmAIVA==',
        'hex_key': '076CD005914A4F2FD1DE7AB280E37FC8'


    }
}

def decrypt_password(cipher_b64: str, hex_key: str) -> str:
    """ AES/ECB/PKCSSPadding 解密 （与java端一致） """
    key_bytes =bytes.fromhex(hex_key)
    cipher_bytes = base64.b64decode(cipher_b64)
    cipher = AES.new(key_bytes,AES.MODE_ECB)
    return unpad(cipher.decypt(cipher_bytes),AES.block_size).decode('utf-8')

def get_engine(env: str):
    """  根据环境名称，读取properties，解密密码，建立SQLAlchemy Engine """
    env = env.