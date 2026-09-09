-- ==============================================================================
-- Olist Marketplace Analytics — Relational Database Schema
-- Database: MySQL 8.0+
-- Author: Girish G Gowda
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS olist
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE olist;

-- 1. Customers Dimension
CREATE TABLE IF NOT EXISTS customers (
    customer_id              VARCHAR(32)  NOT NULL,
    customer_unique_id       VARCHAR(32)  NOT NULL,
    customer_zip_code_prefix INT          NOT NULL,
    customer_city            VARCHAR(64)  NOT NULL,
    customer_state           CHAR(2)      NOT NULL,
    PRIMARY KEY (customer_id),
    INDEX idx_cust_unique (customer_unique_id),
    INDEX idx_cust_state (customer_state)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Sellers Dimension
CREATE TABLE IF NOT EXISTS sellers (
    seller_id              VARCHAR(32)  NOT NULL,
    seller_zip_code_prefix INT          NOT NULL,
    seller_city            VARCHAR(64)  NOT NULL,
    seller_state           CHAR(2)      NOT NULL,
    PRIMARY KEY (seller_id),
    INDEX idx_seller_state (seller_state)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Product Categories Translation Dimension
CREATE TABLE IF NOT EXISTS category_translation (
    product_category_name         VARCHAR(64) NOT NULL,
    product_category_name_english VARCHAR(64) NOT NULL,
    PRIMARY KEY (product_category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Products Dimension
CREATE TABLE IF NOT EXISTS products (
    product_id                 VARCHAR(32) NOT NULL,
    product_category_name      VARCHAR(64),
    product_name_lenght        INT,
    product_description_lenght INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT,
    PRIMARY KEY (product_id),
    INDEX idx_prod_category (product_category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Orders Spine (Fact Table)
CREATE TABLE IF NOT EXISTS orders (
    order_id                      VARCHAR(32) NOT NULL,
    customer_id                   VARCHAR(32) NOT NULL,
    order_status                  VARCHAR(20) NOT NULL,
    order_purchase_timestamp      DATETIME    NOT NULL,
    order_approved_at             DATETIME,
    order_delivered_carrier_date  DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME    NOT NULL,
    PRIMARY KEY (order_id),
    INDEX idx_orders_customer (customer_id),
    INDEX idx_orders_status (order_status),
    INDEX idx_orders_purchase (order_purchase_timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Order Line Items (Fact Table)
CREATE TABLE IF NOT EXISTS order_items (
    order_id            VARCHAR(32)    NOT NULL,
    order_item_id       INT            NOT NULL,
    product_id          VARCHAR(32)    NOT NULL,
    seller_id           VARCHAR(32)    NOT NULL,
    shipping_limit_date DATETIME       NOT NULL,
    price               DECIMAL(10, 2) NOT NULL,
    freight_value       DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id),
    INDEX idx_items_product (product_id),
    INDEX idx_items_seller (seller_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Order Payments (Fact Table)
CREATE TABLE IF NOT EXISTS order_payments (
    order_id             VARCHAR(32)    NOT NULL,
    payment_sequential   INT            NOT NULL,
    payment_type         VARCHAR(20)    NOT NULL,
    payment_installments INT            NOT NULL,
    payment_value        DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential),
    INDEX idx_pay_type (payment_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Customer Order Reviews (Fact Table)
CREATE TABLE IF NOT EXISTS order_reviews (
    review_id               VARCHAR(32) NOT NULL,
    order_id                VARCHAR(32) NOT NULL,
    review_score            TINYINT     NOT NULL,
    review_comment_title    VARCHAR(255),
    review_comment_message  TEXT,
    review_creation_date    DATETIME    NOT NULL,
    review_answer_timestamp DATETIME    NOT NULL,
    PRIMARY KEY (review_id, order_id),
    INDEX idx_reviews_order (order_id),
    INDEX idx_reviews_score (review_score)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. NLP Sentiment Model Output Table
CREATE TABLE IF NOT EXISTS review_sentiment (
    review_id          VARCHAR(32)    NOT NULL,
    sentiment_label    VARCHAR(10)    NOT NULL,
    sentiment_score    DECIMAL(5, 4)  NOT NULL,
    processed_at       TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (review_id),
    INDEX idx_sent_label (sentiment_label)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Review Reason Classification Summary Table
CREATE TABLE IF NOT EXISTS review_reason_summary (
    sentiment_label    VARCHAR(10)    NOT NULL,
    reason             VARCHAR(64)    NOT NULL,
    review_count       INT            NOT NULL,
    pct_of_sentiment   DECIMAL(5, 1)  NOT NULL,
    PRIMARY KEY (sentiment_label, reason)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
