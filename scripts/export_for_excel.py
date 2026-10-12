"""Run four business queries and save the results as CSV files in data/processed/.

The CSVs feed the Excel summary. They are git-ignored; this script recreates them.
"""

import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

load_dotenv()

OUT_DIR = Path(__file__).resolve().parents[1] / "data" / "processed"

QUERIES = {
    "01_monthly_revenue.csv": """
        SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
               COUNT(DISTINCT o.order_id) AS orders,
               ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.order_status = 'delivered'
        GROUP BY order_month
        ORDER BY order_month
    """,
    "02_top_categories.csv": """
        SELECT t.product_category_name_english AS category,
               ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue,
               ROUND(100 * SUM(oi.price + oi.freight_value)
                     / SUM(SUM(oi.price + oi.freight_value)) OVER (), 1) AS pct_of_total
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.product_id = p.product_id
        LEFT JOIN product_category_translation t ON p.product_category_name = t.product_category_name
        WHERE o.order_status = 'delivered'
        GROUP BY t.product_category_name_english
        ORDER BY revenue DESC
        LIMIT 10
    """,
    "03_review_by_lateness.csv": """
        WITH latest_review AS (
            SELECT order_id, review_score,
                   ROW_NUMBER() OVER (PARTITION BY order_id
                                      ORDER BY review_creation_date DESC,
                                               review_answer_timestamp DESC) AS rn
            FROM order_reviews
        )
        SELECT CASE
                 WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN '1_on_time'
                 WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) <= 3 THEN '2_late_up_to_3_days'
                 WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) <= 7 THEN '3_late_4_to_7_days'
                 ELSE '4_late_over_7_days'
               END AS lateness,
               COUNT(*) AS orders,
               ROUND(AVG(r.review_score), 2) AS avg_review_score
        FROM orders o
        JOIN latest_review r ON o.order_id = r.order_id AND r.rn = 1
        WHERE o.order_status = 'delivered'
          AND o.order_delivered_customer_date IS NOT NULL
        GROUP BY lateness
        ORDER BY lateness
    """,
    "04_repeat_by_category.csv": """
        WITH person_orders AS (
            SELECT c.customer_unique_id, o.order_id,
                   ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id
                                      ORDER BY o.order_purchase_timestamp) AS order_number,
                   COUNT(*) OVER (PARTITION BY c.customer_unique_id) AS total_orders
            FROM orders o
            JOIN customers c ON o.customer_id = c.customer_id
            WHERE o.order_status NOT IN ('canceled', 'unavailable')
        )
        SELECT t.product_category_name_english AS category,
               COUNT(*) AS customers,
               ROUND(100 * AVG(po.total_orders > 1), 2) AS pct_repeat
        FROM person_orders po
        JOIN order_items oi ON po.order_id = oi.order_id AND oi.order_item_id = 1
        JOIN products p ON oi.product_id = p.product_id
        LEFT JOIN product_category_translation t ON p.product_category_name = t.product_category_name
        WHERE po.order_number = 1
        GROUP BY t.product_category_name_english
        HAVING COUNT(*) >= 1000
        ORDER BY pct_repeat DESC
    """,
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

OUT_DIR.mkdir(parents=True, exist_ok=True)
with engine.connect() as conn:
    for filename, query in QUERIES.items():
        df = pd.read_sql(text(query), conn)
        df.to_csv(OUT_DIR / filename, index=False)
        print(f"{filename:28} rows: {len(df)}")
