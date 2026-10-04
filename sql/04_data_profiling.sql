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
-- INSIGHT (Query 7): Order 03c939fd... has 3 reviews with 3 different review_ids,
-- scores 3, 3, 4, written on 2018-03-06, 2018-03-20 and 2018-03-29.
-- So a repeated order_id means the customer reviewed the same order again later,
-- at least in this one case. Only one order was inspected.
-- CANDIDATE RULE: keep the most recent review per order (latest review_creation_date).
-- Not final until we check how often scores differ across all repeated orders.
-- OPEN: the 814 repeated review_id values (Query 5) are not yet investigated.


-- Query 8: among orders with more than one review, how many have different scores?
SELECT COUNT(*) AS orders_with_multiple_reviews,
       SUM(min_score <> max_score) AS orders_with_different_scores
FROM (
    SELECT order_id,
           MIN(review_score) AS min_score,
           MAX(review_score) AS max_score
    FROM order_reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS t;
-- INSIGHT (Query 8): 547 orders have more than one review (about 0.55% of 98,673
-- reviewed orders). 202 of them (37%) have differing scores; 345 repeat the same score.
-- The 551 surplus rows = 543 orders with 2 reviews + 4 orders with 3 reviews.
-- DECISION: keep one review per order, the latest by review_creation_date
-- (tie-break on review_answer_timestamp). Impact on average scores is tiny (202 orders),
-- but without this step joins would duplicate 547 orders.


-- Query 9: review_ids that appear more than once
SELECT review_id,
       COUNT(*) AS review_rows,
       COUNT(DISTINCT order_id) AS distinct_orders
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY review_rows DESC
LIMIT 10;
-- INSIGHT (Query 9): Some review_ids are attached to several different orders. In the top 10
-- by row count, every review_id appears 3 times across 3 distinct orders.
-- Only the top 10 were inspected, so the total number of shared review_ids is not yet counted.
-- This is a different problem from Query 8 (one order with several reviews).
-- DECISION: review_id is not a usable key. Deduplicate per order_id (latest review) and
-- join reviews on order_id only.


-- Query 10: the orders sharing one review_id, and their customers
SELECT r.review_id, r.order_id, c.customer_unique_id,
       o.order_purchase_timestamp, r.review_score
FROM order_reviews r
JOIN orders o ON r.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE r.review_id = '08528f70f579f0c830189efc523d2182'
ORDER BY o.order_purchase_timestamp;
-- INSIGHT (Query 10): review_id 08528f70... is attached to 3 orders (2018-07-24, 2018-08-07,
-- 2018-08-17) that all belong to the same customer_unique_id, each with score 1.
-- So at least here, a shared review_id means one person's review recorded on several of
-- their own orders. Cause unknown; only one review_id was inspected.
-- Also: this customer is a repeat buyer (3 orders in under a month).
-- Convention check: customer_unique_id, not customer_id, identifies the person.


-- Query 11: customer rows vs real people
SELECT COUNT(*) AS customer_rows,
       COUNT(DISTINCT customer_id) AS distinct_customer_ids,
       COUNT(DISTINCT customer_unique_id) AS distinct_people
FROM customers;
-- INSIGHT (Query 11): customers has 99,441 rows, 99,441 distinct customer_id and 96,096
-- distinct customer_unique_id. customer_id is created per order, so it is NOT a person.
-- 3,345 rows are repeat appearances of someone already counted.
-- BOUND (not the final figure): at most 3,345 / 96,096 = 3.48% of people can have 2+ orders,
-- so at least about 96.5% have exactly one order. Covers all statuses, not yet filtered.
-- RULE: always count customers with customer_unique_id.


-- Query 12: how many people have 1, 2, 3... orders (all statuses)
SELECT orders_per_person, COUNT(*) AS people
FROM (
    SELECT c.customer_unique_id, COUNT(*) AS orders_per_person
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
) AS t
GROUP BY orders_per_person
ORDER BY orders_per_person;
-- INSIGHT (Query 12): Orders per person (all statuses, 96,096 people, 99,441 orders):
-- 1 order: 93,099 (96.9%) | 2: 2,745 | 3: 203 | 4: 30 | 5: 8 | 6: 6 | 7: 3 | 9: 1 | 17: 1.
-- 2,997 people (3.1%) ordered more than once. The ~97% one-time-buyer claim is CONFIRMED
-- for this definition (all statuses, whole period, ~2 years of data).
-- Totals check: people sum to 96,096 and orders sum to 99,441.
-- CAVEATS: includes canceled/unavailable orders; short window; the person with 17 orders
-- has not been investigated.


-- Query 13: orders per person, excluding orders that never reached a customer
SELECT orders_per_person, COUNT(*) AS people
FROM (
    SELECT c.customer_unique_id, COUNT(*) AS orders_per_person
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
) AS t
GROUP BY orders_per_person
ORDER BY orders_per_person;
-- INSIGHT (Query 13): Excluding canceled and unavailable orders: 94,990 people, 98,207 orders.
-- 1 order: 92,102 (96.96%) | 2: 2,652 | 3: 188 | 4: 29 | 5: 9 | 6: 5 | 7: 3 | 9: 1 | 16: 1.
-- 2,888 people (3.04%) ordered more than once, vs 3.12% in Query 12.
-- The ~97% one-time-buyer claim holds under both definitions (difference under 0.1 point).
-- 1,106 people had only canceled/unavailable orders and drop out.
-- CAVEATS: ~2 year window; the person with 16 orders is not yet investigated.