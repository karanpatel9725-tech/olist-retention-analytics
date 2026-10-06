

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


-- Query 7: revenue and orders per month (delivered orders only)
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;
-- INSIGHT (Query 7): Delivered orders and revenue (price + freight) per month, 23 months.
-- Orders sum to 96,478 and revenue to 15,419,773.75, matching Query 6.
-- Revenue grows from 127,482.37 (2017-01) to a peak of 1,153,364.20 (2017-11, 7,289 orders),
-- possibly Black Friday (not verified), then 843,078.29 in 2017-12.
-- 2018-01 to 2018-08 is flat: revenue 966,168.41 to 1,132,878.93, orders 6,099 to 7,069.
-- Growth slowed after 2017; reason not known. Revenue per order stays about 147 to 167.
-- 2016 is about 0.3% of revenue; 2018-09 and 2018-10 have no delivered orders.


-- Query 8: top 10 product categories by revenue (delivered orders only)
SELECT t.product_category_name_english AS category,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY t.product_category_name_english
ORDER BY revenue DESC
LIMIT 10;
-- INSIGHT (Query 8): Top 10 categories by revenue (delivered, price + freight):
-- health_beauty 1,412,089.53; watches_gifts 1,264,333.12; bed_bath_table 1,225,209.26;
-- sports_leisure 1,118,256.91; computers_accessories 1,032,723.77; furniture_decor 880,329.92;
-- housewares 758,392.25; cool_stuff 691,680.89; auto 669,454.75; garden_tools 567,145.68.
-- The top 10 total 9,619,616.08, about 62.4% of the 15,419,773.75 total. The top category
-- is about 9.2%, so no single category dominates.
-- Ranking by orders differs from ranking by revenue: bed_bath_table has the most orders
-- (9,272) but is 3rd by revenue; watches_gifts has 5,495 orders but is 2nd, so it earns
-- roughly 230 per order against about 132 for bed_bath_table.
-- NOTE: the orders column cannot be summed (an order with items from two categories counts
-- in both). No NULL category appears in the top 10; the share of revenue without a category
-- is not yet measured.


-- Query 9: share of total revenue per category (top 10, delivered orders only)
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
LIMIT 10;
-- INSIGHT (Query 9): Share of total revenue (delivered, price + freight) for the top 10
-- categories: health_beauty 9.2%; watches_gifts 8.2%; bed_bath_table 7.9%; sports_leisure 7.3%;
-- computers_accessories 6.7%; furniture_decor 5.7%; housewares 4.9%; cool_stuff 4.5%;
-- auto 4.3%; garden_tools 3.7%. Together 62.4%, so 37.6% comes from other categories.
-- Revenue is spread across many categories; no single category dominates.
-- Shares are of the full 15,419,773.75 total (window function SUM(SUM()) OVER ()).


-- Query 10: revenue by payment type (delivered orders only, from order_payments)
SELECT p.payment_type,
       COUNT(DISTINCT p.order_id) AS orders,
       ROUND(SUM(p.payment_value), 2) AS paid,
       ROUND(100 * SUM(p.payment_value)
             / SUM(SUM(p.payment_value)) OVER (), 1) AS pct_of_total
FROM order_payments p
JOIN orders o ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.payment_type
ORDER BY paid DESC;
-- INSIGHT (Query 10): Payments on delivered orders by payment type (from order_payments):
-- credit_card 12,101,094.88 (78.5%, 74,304 orders); boleto 2,769,932.58 (18.0%, 19,191);
-- voucher 343,013.19 (2.2%, 3,679); debit_card 208,421.12 (1.4%, 1,485).
-- Paid adds up to 15,422,461.77, matching Query 2a.
-- The orders column adds up to 98,659 vs 96,477 delivered orders with payments, so some
-- orders used more than one payment type (combinations not checked).
-- Rough paid per order: voucher about 93, debit_card about 140, boleto about 144,
-- credit_card about 163.   



-- Query 11: top 10 states by revenue (delivered orders, price + freight)
SELECT c.customer_state,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue,
       ROUND(100 * SUM(oi.price + oi.freight_value)
             / SUM(SUM(oi.price + oi.freight_value)) OVER (), 1) AS pct_of_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC
LIMIT 10;
-- INSIGHT (Query 11): Top 10 customer states by revenue (delivered, price + freight):
-- SP 5,769,703.15 (37.4%, 40,501 orders); RJ 2,055,401.57 (13.3%, 12,350); MG 1,818,891.67
-- (11.8%, 11,354); RS 861,472.79 (5.6%); PR 781,708.80 (5.1%); SC 595,127.78 (3.9%);
-- BA 591,137.81 (3.8%); DF 346,123.35 (2.2%); GO 334,212.35 (2.2%); ES 317,657.93 (2.1%).
-- SP + RJ + MG = 62.5% of revenue; the top 10 = 87.4% of revenue and 90.5% of delivered orders.
-- Revenue per order is lowest in SP (about 142.5) and highest in BA (about 181.6); cause not known.
-- State = customer location, not seller location.