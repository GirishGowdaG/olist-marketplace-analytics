-- ============================================================
-- Olist Advanced SQL Business Case Study
-- 02_load_data.sql  — bulk load 8 CSVs via LOAD DATA INFILE
-- ============================================================
USE olist;

SET FOREIGN_KEY_CHECKS = 0;   -- speed + avoids load-order edge cases

-- ---------- 1. category_translation ----------
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_category_name, product_category_name_english);

-- ---------- 2. customers ----------
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state);

-- ---------- 3. sellers ----------
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(seller_id, seller_zip_code_prefix, seller_city, seller_state);

-- ---------- 4. products ----------
-- Note: empty numeric cells must become NULL, not '' (else load errors)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, @category, @name_len, @desc_len, @photos, @weight, @length, @height, @width)
SET
    product_category_name      = NULLIF(@category, ''),
    product_name_lenght        = NULLIF(@name_len, ''),
    product_description_lenght = NULLIF(@desc_len, ''),
    product_photos_qty         = NULLIF(@photos, ''),
    product_weight_g           = NULLIF(@weight, ''),
    product_length_cm          = NULLIF(@length, ''),
    product_height_cm          = NULLIF(@height, ''),
    product_width_cm           = NULLIF(@width, '');

-- ---------- 5. orders ----------
-- Empty timestamps (undelivered orders) -> NULL
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, customer_id, order_status,
 @purchase, @approved, @carrier, @delivered, @estimated)
SET
    order_purchase_timestamp      = NULLIF(@purchase,  ''),
    order_approved_at             = NULLIF(@approved,  ''),
    order_delivered_carrier_date  = NULLIF(@carrier,   ''),
    order_delivered_customer_date = NULLIF(@delivered, ''),
    order_estimated_delivery_date = NULLIF(@estimated, '');

-- ---------- 6. order_items ----------
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, order_item_id, product_id, seller_id, @ship_limit, price, freight_value)
SET shipping_limit_date = NULLIF(@ship_limit, '');

-- ---------- 7. order_payments ----------
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, payment_sequential, payment_type, payment_installments, payment_value);


-- ---------- 8. order_reviews ----------
-- NOTE: order_reviews is NOT loaded here.
-- The review_comment_message field contains embedded newlines and imperfectly
-- escaped quotes that MySQL's LOAD DATA INFILE cannot parse cleanly (fails at
-- row 77917 with a column-shift error). Loaded instead via pandas, which uses
-- a proper CSV parser that handles multi-line quoted fields.
-- Run:  python python/load_reviews.py   (after the 7 tables above are loaded)


SET FOREIGN_KEY_CHECKS = 1;   -- turn checks back on