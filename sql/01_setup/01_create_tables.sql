-- ============================================================
-- Olist Advanced SQL Business Case Study
-- 01_create_tables.sql  — schema + foreign keys + indexes (8 tables)
--
-- Design decisions documented here:
-- 1. customer_unique_id is NOT the PK of customers — Olist assigns a new
--    customer_id per order, so one real person can have many customer_id
--    values. customer_unique_id is the true person identifier. Cohort and
--    retention queries MUST join on customer_unique_id, not customer_id.
-- 2. order_reviews has no FK to orders. The Olist dataset contains review
--    rows for cancelled orders that have no matching delivered order — a
--    known data characteristic. Enforcing an FK would reject those rows
--    silently. The composite PK (review_id, order_id) is sufficient.
-- 3. Performance indexes are added below each table. Without these, the
--    cohort retention and seller scorecard queries perform full table scans
--    on order_items (112K rows) and orders (99K rows) — acceptable for
--    a 530K-row dataset but poor practice for production schema design.
-- ============================================================

CREATE DATABASE IF NOT EXISTS olist;
USE olist;

-- Drop in reverse-dependency order so FKs don't block
DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS category_translation;

-- ================================================================
-- DIMENSION / LOOKUP TABLES
-- ================================================================

CREATE TABLE customers (
    customer_id              VARCHAR(50) PRIMARY KEY,
    customer_unique_id       VARCHAR(50) NOT NULL,   -- true person ID
    customer_zip_code_prefix VARCHAR(10),
    customer_city            VARCHAR(60),
    customer_state           CHAR(2)
);

-- Cohort retention queries group by customer_unique_id — this index
-- turns a full scan into a ref lookup on every cohort CTE
CREATE INDEX idx_customers_unique_id ON customers(customer_unique_id);
CREATE INDEX idx_customers_state     ON customers(customer_state);


CREATE TABLE sellers (
    seller_id              VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city            VARCHAR(60),
    seller_state           CHAR(2)
);

CREATE INDEX idx_sellers_state ON sellers(seller_state);


CREATE TABLE category_translation (
    product_category_name         VARCHAR(80) PRIMARY KEY,
    product_category_name_english VARCHAR(80)
);


CREATE TABLE products (
    product_id                 VARCHAR(50) PRIMARY KEY,
    product_category_name      VARCHAR(80),
    product_name_lenght        INT,       -- column name preserved from source CSV
    product_description_lenght INT,       -- column name preserved from source CSV
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT
);

-- Category joins appear in nearly every analytical query
CREATE INDEX idx_products_category ON products(product_category_name);


-- ================================================================
-- FACT TABLES
-- ================================================================

CREATE TABLE orders (
    order_id                      VARCHAR(50) PRIMARY KEY,
    customer_id                   VARCHAR(50),
    order_status                  VARCHAR(20),
    order_purchase_timestamp      DATETIME,
    order_approved_at             DATETIME NULL,
    order_delivered_carrier_date  DATETIME NULL,
    order_delivered_customer_date DATETIME NULL,
    order_estimated_delivery_date DATETIME NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- purchase_timestamp drives every time-series, cohort, and MoM query
CREATE INDEX idx_orders_purchase_ts  ON orders(order_purchase_timestamp);
-- status filter appears in almost every WHERE clause
CREATE INDEX idx_orders_status       ON orders(order_status);
-- customer_id join is the spine of all customer-level analysis
CREATE INDEX idx_orders_customer_id  ON orders(customer_id);


CREATE TABLE order_items (
    order_id            VARCHAR(50),
    order_item_id       INT,
    product_id          VARCHAR(50),
    seller_id           VARCHAR(50),
    shipping_limit_date DATETIME NULL,
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id)  REFERENCES sellers(seller_id)
);

-- seller_id joins drive the entire seller scorecard and performance analysis
CREATE INDEX idx_order_items_seller_id  ON order_items(seller_id);
-- product_id joins drive category-level aggregations
CREATE INDEX idx_order_items_product_id ON order_items(product_id);


CREATE TABLE order_payments (
    order_id             VARCHAR(50),
    payment_sequential   INT,
    payment_type         VARCHAR(20),
    payment_installments INT,
    payment_value        DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- payment_type filter used in the payments-by-state pivot
CREATE INDEX idx_payments_type ON order_payments(payment_type);


CREATE TABLE order_reviews (
    review_id               VARCHAR(50),
    order_id                VARCHAR(50),
    review_score            TINYINT,
    review_comment_title    VARCHAR(150),
    review_comment_message  TEXT,
    review_creation_date    DATETIME NULL,
    review_answer_timestamp DATETIME NULL,
    PRIMARY KEY (review_id, order_id)
    -- No FK to orders: the dataset contains review rows for cancelled orders
    -- that would violate an FK constraint. See design decision note at top.
);

-- order_id lookup is the join path from delivery analysis to review scores
CREATE INDEX idx_reviews_order_id    ON order_reviews(order_id);
-- review_score filter used in divergence analysis and sentiment comparison
CREATE INDEX idx_reviews_score       ON order_reviews(review_score);
