-- ==============================================================================
-- Bulk Data Ingestion Script for Olist Tables
-- Run after 01_create_schema.sql.
-- Note: order_reviews is ingested via python/src/review_loader.py to safely
-- handle embedded newlines and unescaped quotes in Brazilian Portuguese reviews.
-- ==============================================================================

USE olist;

SET GLOBAL local_infile = 1;

-- 1. Customers
LOAD DATA LOCAL INFILE 'data/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 2. Sellers
LOAD DATA LOCAL INFILE 'data/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 3. Category Translation
LOAD DATA LOCAL INFILE 'data/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Sanitize Windows CRLF carriage returns on English category translation
UPDATE category_translation
SET product_category_name_english = REPLACE(product_category_name_english, '\r', '');

-- 4. Products
LOAD DATA LOCAL INFILE 'data/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_category_name, 
 @name_len, @desc_len, @photos, @weight, @len, @height, @width)
SET
    product_name_lenght        = NULLIF(@name_len, ''),
    product_description_lenght = NULLIF(@desc_len, ''),
    product_photos_qty         = NULLIF(@photos, ''),
    product_weight_g           = NULLIF(@weight, ''),
    product_length_cm          = NULLIF(@len, ''),
    product_height_cm          = NULLIF(@height, ''),
    product_width_cm           = NULLIF(@width, '');

-- 5. Orders
LOAD DATA LOCAL INFILE 'data/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, 
 order_purchase_timestamp, @approved, @carrier, @delivered, order_estimated_delivery_date)
SET
    order_approved_at             = NULLIF(@approved, ''),
    order_delivered_carrier_date  = NULLIF(@carrier, ''),
    order_delivered_customer_date = NULLIF(@delivered, '');

-- 6. Order Items
LOAD DATA LOCAL INFILE 'data/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 7. Order Payments
LOAD DATA LOCAL INFILE 'data/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
