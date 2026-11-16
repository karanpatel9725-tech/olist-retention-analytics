USE olist;

WITH valid AS (
    SELECT c.customer_unique_id, o.order_id, o.order_purchase_timestamp
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
numbered AS (
    SELECT customer_unique_id, order_id, order_purchase_timestamp,
           ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp) AS order_number
    FROM valid
)
SELECT COUNT(*) AS orders_kept,
       COUNT(DISTINCT customer_unique_id) AS people,
       SUM(order_number = 1) AS first_orders,
       SUM(order_number > 1) AS repeat_orders
FROM numbered;

-- INSIGHT: 98,207 valid orders belong to 94,990 people, so there are 94,990 first orders
-- and 3,217 repeat orders. This matches the pandas order_number column in notebook 02.

