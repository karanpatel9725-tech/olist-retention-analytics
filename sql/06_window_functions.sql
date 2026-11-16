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



-- Query 3: monthly revenue and running total (price + freight, delivered orders)
WITH monthly AS (
    SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
           COUNT(DISTINCT o.order_id) AS orders,
           SUM(oi.price + oi.freight_value) AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
)
SELECT order_month,
       orders,
       ROUND(monthly_revenue, 2) AS monthly_revenue,
       ROUND(SUM(monthly_revenue) OVER (ORDER BY order_month), 2) AS running_total
FROM monthly
ORDER BY order_month;


-- INSIGHT: Delivered revenue (price + freight) adds up to 15,419,773.75 by 2018-08, matching
-- Query 6 in sql/05. Monthly revenue peaked in 2017-11 at 1,153,364.20 (7,289 orders), dipped
-- to 843,078.29 in 2017-12, and stayed between 966,168.41 and 1,132,878.93 from 2018-01 to
-- 2018-08, so the running total grows by about the same amount each month in 2018.
-- 2016 months are tiny (November 2016 is missing) and should not be read as a trend.