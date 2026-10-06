

USE olist;

-- Query 1: orders per status, leaving out orders that never reached a customer
SELECT order_status, COUNT(*) AS orders
FROM orders
WHERE order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_status
ORDER BY orders DESC;
-- INSIGHT (Query 1): Excluding canceled and unavailable, 98,207 orders remain:
-- delivered 96,478; shipped 1,107; invoiced 314; processing 301; created 5; approved 2.
-- 1,729 of these are still in progress (not yet delivered) at the end of the data.

-- Query 2a: revenue from payments, delivered orders only
SELECT SUM(p.payment_value) AS revenue_payments
FROM order_payments p
JOIN orders o ON p.order_id = o.order_id
WHERE o.order_status = 'delivered';

-- Query 2b: revenue from items plus freight, delivered orders only
SELECT SUM(oi.price + oi.freight_value) AS revenue_items
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';
-- INSIGHT (Query 2): Revenue on delivered orders, two definitions:
-- payments (sum of payment_value) = 15,422,461.77; items + freight (shipping fee)= 15,419,773.75.
-- Difference = 2,688.02 (about 0.017% of the items total), payments higher.
-- Cause not yet known. Each total comes from its own table (no join between
-- order_items and order_payments) to avoid duplicated rows.
-- DECISION: revenue definition still to be chosen after investigating the gap.


-- Query 3: orders where payments and items + freight differ (delivered only)
SELECT o.order_id,
       pay.paid,
       itm.items_total,
       ROUND(pay.paid - itm.items_total, 2) AS diff
FROM orders o
JOIN (SELECT order_id, SUM(payment_value) AS paid
      FROM order_payments
      GROUP BY order_id) pay ON o.order_id = pay.order_id
JOIN (SELECT order_id, SUM(price + freight_value) AS items_total
      FROM order_items
      GROUP BY order_id) itm ON o.order_id = itm.order_id
WHERE o.order_status = 'delivered'
  AND ABS(pay.paid - itm.items_total) > 0.01
ORDER BY ABS(pay.paid - itm.items_total) DESC
LIMIT 10;
-- INSIGHT (Query 3): Top 10 orders by absolute difference between payments and
-- items + freight (delivered only). Differences run from 182.81 down to 39.44;
-- 9 of 10 have payments higher, 1 has payments lower (-51.62).
-- The top 10 net to 699.99, about 26% of the 2,688.02 gap in Query 2, so the gap
-- is not driven by a few extreme orders. Cause not yet known.
-- Note: this query only covers orders present in both tables.


-- Query 4: how many delivered orders have a payment/items mismatch?
SELECT COUNT(*) AS orders_compared,
       SUM(ABS(pay.paid - itm.items_total) > 0.01) AS orders_that_differ
FROM orders o
JOIN (SELECT order_id, SUM(payment_value) AS paid
      FROM order_payments
      GROUP BY order_id) pay ON o.order_id = pay.order_id
JOIN (SELECT order_id, SUM(price + freight_value) AS items_total
      FROM order_items
      GROUP BY order_id) itm ON o.order_id = itm.order_id
WHERE o.order_status = 'delivered';
-- INSIGHT (Query 4): 96,477 delivered orders have both payments and items.
-- 299 of them (0.31%) differ by more than 0.01 between payments and items + freight;
-- the rest match to the cent. 1 delivered order (96,478 - 96,477) is missing from
-- one of the two tables (checked in Query 5). Cause of the 299 differences not known.
-- DECISION: revenue = SUM(price + freight_value) from order_items, delivered orders.
-- Reason: it comes from the product lines, so it can be split by category, seller and
-- state, and it agrees with payments within 0.02%. The payments table is used only for
-- payment-type questions (payment_type, installments).


-- Query 5: delivered orders missing from order_payments or order_items
SELECT o.order_id,
       pay.order_id AS in_payments,
       itm.order_id AS in_items
FROM orders o
LEFT JOIN (SELECT DISTINCT order_id FROM order_payments) pay ON o.order_id = pay.order_id
LEFT JOIN (SELECT DISTINCT order_id FROM order_items) itm ON o.order_id = itm.order_id
WHERE o.order_status = 'delivered'
  AND (pay.order_id IS NULL OR itm.order_id IS NULL);
-- INSIGHT (Query 5): Exactly 1 delivered order (bfbd0f9bdef84302105ad712db648a6c) has
-- items but no row in order_payments. All other delivered orders appear in both tables.
-- This explains 96,478 delivered vs 96,477 compared in Query 4. Its value is in the items
-- total but not the payments total, so the gap among comparable orders is slightly larger
-- than the 2,688.02 in Query 2 (order value not looked up).
-- Cause of the missing payment not known.


-- Query 6: delivered orders, revenue and average order value
SELECT COUNT(DISTINCT o.order_id) AS delivered_orders,
       SUM(oi.price + oi.freight_value) AS revenue,
       SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';
-- INSIGHT (Query 6): Delivered orders: 96,478. Revenue (price + freight, delivered only):
-- 15,419,773.75, matching Query 2b, so the join does not duplicate rows.
-- Average order value: 159.83 (shipping included).
-- NOTE: AOV is a mean and can be pulled up by a few large orders; the median and the
-- spread have not been checked. Revenue covers the whole period, including the thin
-- months of 2016 and late 2018 (see profiling Query 2).