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


-- Query 2: days between a person's consecutive orders (repeat orders only)
WITH valid AS (
    SELECT c.customer_unique_id, o.order_id, o.order_purchase_timestamp
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
gaps AS (
    SELECT customer_unique_id, order_id, order_purchase_timestamp,
           LAG(order_purchase_timestamp) OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp) AS prev_order
    FROM valid
)
SELECT COUNT(*) AS repeat_orders,
       COUNT(DISTINCT customer_unique_id) AS people,
       ROUND(AVG(DATEDIFF(order_purchase_timestamp, prev_order)), 1) AS avg_days_between,
       SUM(DATEDIFF(order_purchase_timestamp, prev_order) = 0) AS same_day,
       SUM(DATEDIFF(order_purchase_timestamp, prev_order) BETWEEN 1 AND 30) AS days_1_to_30,
       SUM(DATEDIFF(order_purchase_timestamp, prev_order) > 30) AS over_30_days
FROM gaps
WHERE prev_order IS NOT NULL;

-- INSIGHT: 2,888 repeat buyers placed 3,217 repeat orders. 930 (28.9%) came on the same calendar
-- date as the previous order, 696 (21.6%) within 1 to 30 days, and 1,591 (49.5%) after more than
-- 30 days. The average gap is 78.9 days, but it is pulled up by long gaps, so the buckets describe
-- the pattern better. Together with the cohort result, about half of repeat orders happen within a
-- month of the previous order, so the first weeks after a purchase are the best window to reach customers.
-- CAUTION: same date can mean one shopping session split into two orders, not a real return visit.

