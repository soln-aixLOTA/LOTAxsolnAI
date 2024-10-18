# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
from jose import jwt
import os
from datetime import datetime, timedelta
import argparse

# Configuration
SECRET_KEY = os.getenv("JWT_SECRET", "your_jwt_secret")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def main():
    parser = argparse.ArgumentParser(description="Generate JWT Token")
    parser.add_argument("--sub", type=str, required=True, help="Subject (e.g., user ID)")
    parser.add_argument("--expires_minutes", type=int, default=30, help="Token expiration time in minutes")
    args = parser.parse_args()

    data = {"sub": args.sub}
    expires = timedelta(minutes=args.expires_minutes)
    token = create_access_token(data, expires_delta=expires)
    print(f"JWT Token: {token}")

if __name__ == "__main__":
    main()
