

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



-- Query 12: delivery time and late deliveries (delivered orders with a delivery date)
SELECT COUNT(*) AS orders,
       ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_days_to_deliver,
       ROUND(AVG(DATEDIFF(order_estimated_delivery_date, order_purchase_timestamp)), 1) AS avg_days_promised,
       ROUND(100 * AVG(order_delivered_customer_date > order_estimated_delivery_date), 1) AS pct_late
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
-- INSIGHT (Query 12): Delivered orders with a delivery date: 96,470.
-- Average time to deliver 12.5 days vs average promised 24.4 days (about 12 days earlier
-- than promised on average). 8.1% of orders arrived after the estimated date
-- (about 7,800 orders, rough). 
-- NOTE: the late test compares full date and time, so same-day arrivals after the promised
-- time count as late; days use DATEDIFF (whole days). Averages hide the spread; the
-- slowest orders have not been examined. Effect of lateness on reviews and repeat
-- purchases is not tested yet.


-- Query 13: delivery time and late share by customer state
SELECT c.customer_state,
       COUNT(*) AS orders,
       ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_days_to_deliver,
       ROUND(100 * AVG(o.order_delivered_customer_date > o.order_estimated_delivery_date), 1) AS pct_late
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY pct_late DESC;
-- INSIGHT (Query 13): Delivery by customer state (delivered orders with a delivery date,
-- 27 states, 96,470 orders). Highest late share: AL 23.9% (397 orders), MA 19.7% (717),
-- PI 16.0% (476), CE 15.3% (1,279), SE 15.2% (335), BA 14.0% (3,256), RJ 13.5% (12,350).
-- SP (40,494 orders) is 5.9% late, 8.7 days on average; MG 5.6%; PR 5.0%.
-- Slowest averages: RR 29.3 days (41 orders), AP 27.2 (67), AM 26.4 (145), AL 24.5.
-- Long average time is not the same as late: AP 4.5% and AM 4.1% late despite 27 and 26 days
-- (possibly more generous promised dates; not checked).
-- Rough late orders (share x orders): SP about 2,390, RJ about 1,670, BA about 460.
-- Small samples (RR, AP, AC, AM) are unreliable. Effect of lateness on reviews and repeat
-- purchases not yet tested, so no recommendation yet.



-- Query 14: average review score, on-time vs late (delivered orders, one review per order)
WITH latest_review AS (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_creation_date DESC,
                                       review_answer_timestamp DESC) AS rn
    FROM order_reviews
)
SELECT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'late' ELSE 'on_time' END AS delivery_status,
       COUNT(*) AS orders,
       ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM orders o
JOIN latest_review r ON o.order_id = r.order_id AND r.rn = 1
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;
-- INSIGHT (Query 14): Average review score by delivery status (delivered orders with a
-- delivery date and a review; one review per order = latest, via ROW_NUMBER in a CTE).
-- on_time: 88,163 orders, average 4.29. late: 7,661 orders, average 2.57.
-- Gap = 1.72 points. 646 delivered orders have no review and are excluded
-- (95,824 reviewed vs 96,470 delivered with a date). Late share among reviewed = 8.0%.
-- CAUTION: this compares two groups; it does not prove lateness caused the lower score
-- (state, seller, product and review content are not controlled for).
-- NEXT: score by how late an order is; repeat purchase by delivery experience;
-- significance test in Phase 3.



-- Query 15: average review score by how late the order was (delivered, one review per order)
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
ORDER BY lateness;
-- INSIGHT (Query 15): Average review score by lateness (delivered, one review per order,
-- 95,824 orders): on time 4.29 (88,163); up to 3 days late 3.59 (3,132);
-- 4 to 7 days late 2.10 (1,748); over 7 days late 1.70 (2,781).
-- The score falls at every step; the biggest drop (1.49) is between the 3-day and 7-day bands.
-- Orders more than 7 days late are 2.9% of reviewed orders and 36.3% of all late orders.
-- Totals match Query 14 (88,163 on time; 7,661 late).
-- CAUTION: association, not proof of cause (very late orders may have other problems too).
-- NEXT: do customers whose first order arrived late come back less often?


-- Query 16: repeat purchase rate by delivery experience of the FIRST order
WITH person_orders AS (
    SELECT c.customer_unique_id,
           o.order_status,
           o.order_delivered_customer_date,
           o.order_estimated_delivery_date,
           ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id
                              ORDER BY o.order_purchase_timestamp) AS order_number,
           COUNT(*) OVER (PARTITION BY c.customer_unique_id) AS total_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
)
SELECT CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'first_order_late' ELSE 'first_order_on_time' END AS first_order_delivery,
       COUNT(*) AS customers,
       ROUND(100 * AVG(total_orders > 1), 2) AS pct_repeat
FROM person_orders
WHERE order_number = 1
  AND order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
GROUP BY first_order_delivery;
-- INSIGHT (Query 16): Repeat purchase rate by delivery experience of the FIRST order
-- (first = earliest non-canceled/unavailable order; repeat = any later such order;
-- customers via customer_unique_id; first order must be delivered with a delivery date).
-- First order on time: 85,697 customers, 3.07% came back. First order late: 7,594 customers,
-- 2.52% came back. Gap = 0.55 points (about 18% fewer returns among late).
-- 93,291 customers included; 1,699 of the 94,990 drop out (first order not delivered/no date).
-- KEY POINT: 96.93% of customers with an on-time first order also never returned, so late
-- delivery is NOT the main driver of the 97% one-time buyers.
-- Rough upper bound: if late customers returned at the on-time rate, about 42 more repeat
-- customers (vs 2,888 repeat in total), assuming lateness is the whole cause (unproven).
-- CAUTION: significance not tested; late-in-period customers had less time to return;
-- late and on-time groups may differ in timing, state and product.



-- Query 17: repeat purchase rate by review score of the FIRST order
WITH latest_review AS (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_creation_date DESC,
                                       review_answer_timestamp DESC) AS rn
    FROM order_reviews
),
person_orders AS (
    SELECT c.customer_unique_id, o.order_id, o.order_status,
           ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id
                              ORDER BY o.order_purchase_timestamp) AS order_number,
           COUNT(*) OVER (PARTITION BY c.customer_unique_id) AS total_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
)
SELECT r.review_score,
       COUNT(*) AS customers,
       ROUND(100 * AVG(po.total_orders > 1), 2) AS pct_repeat
FROM person_orders po
JOIN latest_review r ON po.order_id = r.order_id AND r.rn = 1
WHERE po.order_number = 1
  AND po.order_status = 'delivered'
GROUP BY r.review_score
ORDER BY r.review_score;
-- INSIGHT (Query 17): Repeat purchase rate by review score of the FIRST order (latest review
-- per order; delivered first orders; repeat = any later non-canceled/unavailable order).
-- Score 1: 9,067 customers, 2.92% repeat | 2: 2,832, 2.75% | 3: 7,657, 2.94% |
-- 4: 18,362, 2.78% | 5: 54,765, 3.14%. 92,683 customers in total.
-- Range is only 0.39 points; 1-star customers return almost as often as 5-star (2.92% vs 3.14%).
-- No steady pattern (2-star lowest, 3-star above 4-star); likely noise, not tested.
-- Rough repeat-customer counts: 2-star about 78, 1-star about 265, 5-star about 1,720.
-- KEY POINT: with Query 16, neither late delivery nor a bad first review explains the 97%
-- one-time buyers. Cause not visible in this data; no recommendation from this yet.



-- Query 18: repeat purchase rate by customer state of the FIRST order
WITH person_orders AS (
    SELECT c.customer_unique_id, c.customer_state,
           ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id
                              ORDER BY o.order_purchase_timestamp) AS order_number,
           COUNT(*) OVER (PARTITION BY c.customer_unique_id) AS total_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
)
SELECT customer_state,
       COUNT(*) AS customers,
       ROUND(100 * AVG(total_orders > 1), 2) AS pct_repeat
FROM person_orders
WHERE order_number = 1
GROUP BY customer_state
HAVING COUNT(*) >= 500
ORDER BY pct_repeat DESC;
-- INSIGHT (Query 18): Repeat purchase rate by customer state of the FIRST order
-- (non-canceled/unavailable orders; states with at least 500 first-order customers;
-- 17 states, 92,472 customers; overall rate for reference 3.04%).
-- Highest: RJ 3.37% (12,238 customers), MT 3.33% (871), GO 3.16%, SP 3.14% (39,738), RS 3.13%.
-- Lowest: CE 1.62% (1,300), MA 2.24% (713), PE 2.32% (1,597), PA 2.44%, PB 2.52%.
-- Range 1.75 points. Rough repeat-customer counts: RJ about 412, SP about 1,248,
-- CE about 21, MT about 29, so small-state gaps may be noise.
-- Low-repeat states (CE, MA, PE, PA, PB) tend to have high late shares (Query 13), but RJ has
-- 13.5% late and the highest repeat rate, so delivery does not explain state differences.
-- No test run yet; CE is the clearest candidate. Significance in Phase 3.



-- Query 19: repeat purchase rate by category of the FIRST order's first item
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
ORDER BY pct_repeat DESC;
-- INSIGHT (Query 19): Repeat purchase rate by category of the FIRST order's first item
-- (non-canceled/unavailable orders; categories with at least 1,000 first-order customers;
-- 21 rows incl. one blank category, 84,144 customers; overall rate for reference 3.04%).
-- Highest: fashion_bags_accessories 5.91% (1,726), furniture_decor 4.55% (6,039),
-- bed_bath_table 4.51% (8,847), sports_leisure 3.92% (7,326).
-- Lowest: electronics 1.65% (2,489), consoles_games 1.75% (1,031), cool_stuff 1.87% (3,529),
-- office_furniture 2.02%, auto 2.05%. Blank category (no category/translation): 2.83% (1,377).
-- Range 4.26 points: first-purchase category is linked to repeat rate more strongly than
-- delivery (0.55), review score (0.39) or state (1.75).
-- Top-revenue categories are not the best at retention: health_beauty 2.79% and
-- watches_gifts 2.14% are below average; bed_bath_table and furniture_decor are above.
-- Rough repeat-customer counts: bed_bath_table about 399, furniture_decor about 275,
-- electronics about 41, consoles_games about 18 (small counts, possible noise).
-- CAUTION: uses the first item of the first order only; repeat = any later order, not
-- necessarily the same category; not tested for significance (Phase 3).