-- 04_data_profiling.sql
-- Purpose: understand the data before analysing it.

USE olist;

-- Query 1: first and last order date
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order
FROM orders;
-- INSIGHT (Query 1): Orders run from 2016-09-04 to 2018-10-17, about 2 years and 1 month.
-- This is a short window, so the "one-time buyer" rate is not a lifetime figure.
-- Customers who first bought late in the period had little time to return, which
-- pushes the measured repeat rate down. Note this under Limitations in the README.


SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
       COUNT(*) AS orders
FROM orders
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m');
-- INSIGHT (Query 2): Monthly orders add up to 99,441, matching the orders table.
-- - 2016 is almost empty (2016-09: 4, 2016-10: 324, 2016-12: 1) and 2016-11 is missing.
-- - Real volume starts in 2017-01 (800) and grows to about 4,000+ by mid-2017.
-- - Peak is 2017-11 (7,544). Possibly Black Friday, but not verified in the data.
-- - 2018-01 to 2018-08 is stable at roughly 6,100 to 7,300 orders a month.
-- - 2018-09 (16) and 2018-10 (4) are the end of the dataset, not a real sales drop.
-- DECISION: use 2017-01 to 2018-08 (20 months) as the reliable window for the
-- cohort analysis. Treat 2016 and the last two months as incomplete.

-- Query 3: how many orders per status
SELECT order_status, COUNT(*) AS orders
FROM orders
GROUP BY order_status
ORDER BY orders DESC;
-- INSIGHT (Query 3): 99,441 orders in total. 96,478 (97.0%) are delivered.
-- Not delivered: shipped 1,107; canceled 625; unavailable 609; invoiced 314;
-- processing 301; created 5; approved 2.
-- DECISION: delivery-time and review analysis uses delivered orders only.
-- Canceled and unavailable orders are excluded from revenue. Revenue and
-- retention rules for the in-progress statuses are still to be decided.
-- NOTE: "97% delivered" is NOT the same as the "97% one-time buyers" claim,
-- which is still unverified.


-- Query 4: orders with a missing delivery date, by status
SELECT order_status,
       COUNT(*) AS orders,
       SUM(order_delivered_customer_date IS NULL) AS missing_delivery_date
FROM orders
GROUP BY order_status
ORDER BY orders DESC;
-- INSIGHT (Query 4): 8 of 96,478 delivered orders have no order_delivered_customer_date,
-- leaving 96,470 delivered orders usable for delivery-time analysis.
-- Every shipped, invoiced, processing, created, approved and unavailable order has no
-- delivery date, which is expected. 6 of 625 canceled orders do have one (odd, cause unknown).
-- DECISION: delivery-time analysis uses status = 'delivered' AND
-- order_delivered_customer_date IS NOT NULL.


-- Query 5: are review_id and order_id unique in order_reviews?
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT review_id) AS distinct_review_ids,
       COUNT(DISTINCT order_id) AS distinct_order_ids
FROM order_reviews;
-- INSIGHT (Query 5): order_reviews has 99,224 rows but only 98,410 distinct review_id
-- and 98,673 distinct order_id. So review_id repeats, and some orders have more than
-- one review. 768 orders (99,441 - 98,673) have no review.
-- RISK: a plain JOIN of orders to order_reviews duplicates orders and inflates
-- counts and revenue.
-- DECISION: reduce to one review per order before joining. Rule to be decided.

-- Query 6: orders that have more than one review
SELECT order_id, COUNT(*) AS reviews
FROM order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY reviews DESC
LIMIT 10;
-- INSIGHT (Query 6): Some orders have more than one review. In the top 10 by review
-- count, 4 orders have 3 reviews and the other 6 shown have 2.
-- This query is limited to 10 rows, so the total number of orders with repeated
-- reviews is not yet counted.
-- Earlier (Query 5): 99,224 review rows vs 98,673 distinct orders, so about 551 extra
-- rows come from repeated order_ids.
-- RISK: joining orders to order_reviews as it is would duplicate these orders.
-- NEXT: inspect one repeated order (Query 7) to see how the reviews differ before
-- choosing a rule for keeping one review per order.

-- Query 7: the reviews on one order that has 3
SELECT review_id, order_id, review_score,
       review_creation_date, review_answer_timestamp
FROM order_reviews
WHERE order_id = '03c939fd7fd3b38f8485a0f95798f1f6'
ORDER BY review_creation_date;