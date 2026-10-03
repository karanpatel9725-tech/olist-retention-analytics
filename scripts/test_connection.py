"""Test the MySQL connection using credentials from .env."""

import os

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

load_dotenv()  # finds .env by searching upward from this file

required = ["DB_USER", "DB_PASSWORD", "DB_HOST", "DB_NAME"]
missing = [name for name in required if not os.getenv(name)]
if missing:
    raise SystemExit(f"Missing in .env: {missing}")

# URL.create handles special characters in the password safely
url = URL.create(
    drivername="mysql+pymysql",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    port=int(os.getenv("DB_PORT", "3306")),
    database=os.getenv("DB_NAME"),
)

engine = create_engine(url)
with engine.connect() as conn:
    db, version = conn.execute(text("SELECT DATABASE(), VERSION()")).fetchone()
    print(f"Connected to database: {db} | MySQL version: {version}")
