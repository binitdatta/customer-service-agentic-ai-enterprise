import os
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

# Safe: env vars exist even before app is created
print("EFFECTIVE DB_NAME (env):", os.getenv("DB_NAME"))
print("EFFECTIVE DB_USER (env):", os.getenv("DB_USER"))
print("EFFECTIVE DB_HOST (env):", os.getenv("DB_HOST"))
