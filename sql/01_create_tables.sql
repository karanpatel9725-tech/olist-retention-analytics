-- 01_create_tables.sql
-- Purpose: define the 9 Olist tables with proper types and primary keys.
-- Foreign keys are added after loading, in 02_add_foreign_keys.sql.

USE olist;

CREATE TABLE IF NOT EXISTS customers (
    customer_id              VARCHAR(32) NOT NULL,
    customer_unique_id       VARCHAR(32) NOT NULL,
    customer_zip_code_prefix INT,
    customer_city            VARCHAR(100),
    customer_state           CHAR(2),
    PRIMARY KEY (customer_id),
    INDEX idx_customers_unique_id (customer_unique_id)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id                      VARCHAR(32) NOT NULL,
    customer_id                   VARCHAR(32) NOT NULL,
    order_status                  VARCHAR(20),
    order_purchase_timestamp      DATETIME,
    order_approved_at             DATETIME,
    order_delivered_carrier_date  DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    PRIMARY KEY (order_id),
    INDEX idx_orders_customer_id (customer_id)
);

CREATE TABLE IF NOT EXISTS order_items (
    order_id            VARCHAR(32) NOT NULL,
    order_item_id       INT NOT NULL,
    product_id          VARCHAR(32) NOT NULL,
    seller_id           VARCHAR(32) NOT NULL,
    shipping_limit_date DATETIME,
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    INDEX idx_items_product_id (product_id),
    INDEX idx_items_seller_id (seller_id)
);

CREATE TABLE IF NOT EXISTS order_payments (
    order_id             VARCHAR(32) NOT NULL,
    payment_sequential   INT NOT NULL,
    payment_type         VARCHAR(20),
    payment_installments INT,
    payment_value        DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- No primary key on purpose: review_id may repeat in this dataset.
-- We will check this in the profiling step before deciding on a key.
CREATE TABLE IF NOT EXISTS order_reviews (
    review_id               VARCHAR(32) NOT NULL,
    order_id                VARCHAR(32) NOT NULL,
    review_score            TINYINT,
    review_comment_title    VARCHAR(255),
    review_comment_message  TEXT,
    review_creation_date    DATETIME,
    review_answer_timestamp DATETIME,
    INDEX idx_reviews_review_id (review_id),
    INDEX idx_reviews_order_id (order_id)
);

CREATE TABLE IF NOT EXISTS products (
    product_id                 VARCHAR(32) NOT NULL,
    product_category_name      VARCHAR(100),
    product_name_length        INT,
    product_description_length INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT,
    PRIMARY KEY (product_id)
);

CREATE TABLE IF NOT EXISTS sellers (
    seller_id              VARCHAR(32) NOT NULL,
    seller_zip_code_prefix INT,
    seller_city            VARCHAR(100),
    seller_state           CHAR(2),
    PRIMARY KEY (seller_id)
);

CREATE TABLE IF NOT EXISTS geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat             DECIMAL(12,9),
    geolocation_lng             DECIMAL(12,9),
    geolocation_city            VARCHAR(100),
    geolocation_state           CHAR(2),
    INDEX idx_geo_zip (geolocation_zip_code_prefix)
);

CREATE TABLE IF NOT EXISTS product_category_translation (
    product_category_name         VARCHAR(100) NOT NULL,
    product_category_name_english VARCHAR(100),
    PRIMARY KEY (product_category_name)
);