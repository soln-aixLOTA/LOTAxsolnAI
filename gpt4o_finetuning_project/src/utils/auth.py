# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
from fastapi import HTTPException, Header
from jose import JWTError, jwt
from typing import Optional
import os
import hvac

# Initialize Vault client
vault_url = os.getenv("VAULT_URL", "http://localhost:8200")
vault_token = os.getenv("VAULT_TOKEN")
if not vault_token:
    raise ValueError("VAULT_TOKEN is not set in environment variables.")

vault_client = hvac.Client(url=vault_url, token=vault_token)
if not vault_client.is_authenticated():
    raise ValueError("Vault authentication failed.")

# Retrieve JWT secret
try:
    secrets = vault_client.secrets.kv.v2.read_secret_version(path='gpt4o_finetuning_project')
    SECRET_KEY = secrets['data']['data']['JWT_SECRET']
except Exception as e:
    raise ValueError(f"Failed to retrieve JWT_SECRET from Vault: {e}")

ALGORITHM = "HS256"

def get_current_user(authorization: Optional[str] = Header(None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header missing")
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header format")
    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Token payload invalid")
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
