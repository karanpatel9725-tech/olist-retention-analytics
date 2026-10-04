USE olist;

SELECT 'orders -> customers' AS check_name, COUNT(*) AS orphan_rows
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT 'order_items -> orders' AS check_name, COUNT(*) AS orphan_rows
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT 'order_items -> products' AS check_name, COUNT(*) AS orphan_rows
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT 'order_items -> sellers' AS check_name, COUNT(*) AS orphan_rows
FROM order_items oi
LEFT JOIN sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

SELECT 'order_payments -> orders' AS check_name, COUNT(*) AS orphan_rows
FROM order_payments op
LEFT JOIN orders o ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT 'order_reviews -> orders' AS check_name, COUNT(*) AS orphan_rows
FROM order_reviews r
LEFT JOIN orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;