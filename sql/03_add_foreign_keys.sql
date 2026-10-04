-- 03_add_foreign_keys.sql
-- Purpose: turn the six verified relationships into real foreign keys.
-- Run only after 02_orphan_checks.sql shows 0 orphans everywhere.

USE olist;

ALTER TABLE orders
    ADD CONSTRAINT fk_orders_customers
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id);

ALTER TABLE order_items
    ADD CONSTRAINT fk_items_orders
    FOREIGN KEY (order_id) REFERENCES orders (order_id);

ALTER TABLE order_items
    ADD CONSTRAINT fk_items_products
    FOREIGN KEY (product_id) REFERENCES products (product_id);

ALTER TABLE order_items
    ADD CONSTRAINT fk_items_sellers
    FOREIGN KEY (seller_id) REFERENCES sellers (seller_id);

ALTER TABLE order_payments
    ADD CONSTRAINT fk_payments_orders
    FOREIGN KEY (order_id) REFERENCES orders (order_id);

ALTER TABLE order_reviews
    ADD CONSTRAINT fk_reviews_orders
    FOREIGN KEY (order_id) REFERENCES orders (order_id);