"""Load the 9 raw Olist CSVs from data/raw/ into the MySQL database defined in .env.

Run sql/01_create_tables.sql first. Safe to re-run: each table is emptied before loading.
"""

import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

load_dotenv()

RAW_DIR = Path(__file__).resolve().parents[1] / "data" / "raw"

# table name -> (csv file, date columns)
TABLES = {
    "customers": ("olist_customers_dataset.csv", []),
    "orders": (
        "olist_orders_dataset.csv",
        [
            "order_purchase_timestamp",
            "order_approved_at",
            "order_delivered_carrier_date",
            "order_delivered_customer_date",
            "order_estimated_delivery_date",
        ],
    ),
    "order_items": ("olist_order_items_dataset.csv", ["shipping_limit_date"]),
    "order_payments": ("olist_order_payments_dataset.csv", []),
    "order_reviews": (
        "olist_order_reviews_dataset.csv",
        ["review_creation_date", "review_answer_timestamp"],
    ),
    "products": ("olist_products_dataset.csv", []),
    "sellers": ("olist_sellers_dataset.csv", []),
    "geolocation": ("olist_geolocation_dataset.csv", []),
    "product_category_translation": ("product_category_name_translation.csv", []),
}

# Fix the misspelled column names from the source files
RENAMES = {
    "product_name_lenght": "product_name_length",
    "product_description_lenght": "product_description_length",
}

url = URL.create(
    drivername="mysql+pymysql",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    port=int(os.getenv("DB_PORT", "3306")),
    database=os.getenv("DB_NAME"),
)
engine = create_engine(url)

for table, (filename, date_cols) in TABLES.items():
    df = pd.read_csv(RAW_DIR / filename).rename(columns=RENAMES)
    for col in date_cols:
        df[col] = pd.to_datetime(df[col])  # empty values become NULL

    with engine.begin() as conn:
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 0"))
        conn.execute(text(f"TRUNCATE TABLE {table}"))
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 1"))

    df.to_sql(
        table, engine, if_exists="append", index=False, chunksize=2000, method="multi"
    )

    with engine.connect() as conn:
        in_db = conn.execute(text(f"SELECT COUNT(*) FROM {table}")).scalar()
    status = "OK" if in_db == len(df) else "MISMATCH"
    print(f"{table:32} csv rows: {len(df):>9,} | db rows: {in_db:>9,} | {status}")
