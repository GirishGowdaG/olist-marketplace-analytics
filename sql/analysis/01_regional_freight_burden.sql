-- ==============================================================================
-- Query 01: Inter-State Freight Burden Index (FBI)
-- Business Problem: In a continental marketplace like Brazil, cross-regional
-- freight can create significant purchase friction. What is the ratio of
-- freight cost to item price across customer destination regions, and does
-- a higher freight ratio suppress customer review scores?
--
-- Approach:
-- 1. Map 27 Brazilian states into 5 macro-regions (Southeast, South, Northeast,
--    Central-West, North).
-- 2. Aggregate gross product revenue, total freight value, and compute the
--    Freight Burden Index (Freight / Item Price).
-- 3. Calculate average review score per region to evaluate customer sentiment impact.
-- ==============================================================================

USE olist;

WITH regional_orders AS (
    SELECT
        c.customer_state,
        CASE
            WHEN c.customer_state IN ('SP', 'RJ', 'MG', 'ES') THEN 'Southeast'
            WHEN c.customer_state IN ('PR', 'SC', 'RS') THEN 'South'
            WHEN c.customer_state IN ('DF', 'GO', 'MT', 'MS') THEN 'Central-West'
            WHEN c.customer_state IN ('BA', 'PE', 'CE', 'MA', 'PB', 'RN', 'AL', 'SE', 'PI') THEN 'Northeast'
            WHEN c.customer_state IN ('AM', 'PA', 'RO', 'AC', 'TO', 'AP', 'RR') THEN 'North'
            ELSE 'Other'
        END AS destination_region,
        oi.price,
        oi.freight_value,
        r.review_score
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    LEFT JOIN order_reviews r ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
)
SELECT
    destination_region,
    COUNT(DISTINCT customer_state) AS states_in_region,
    COUNT(*) AS total_items_shipped,
    ROUND(SUM(price), 2) AS total_item_value,
    ROUND(SUM(freight_value), 2) AS total_freight_value,
    ROUND(AVG(price), 2) AS avg_item_price,
    ROUND(AVG(freight_value), 2) AS avg_freight_cost,
    -- Freight Burden Index: freight cost as percentage of item price
    ROUND((SUM(freight_value) / NULLIF(SUM(price), 0)) * 100, 2) AS freight_burden_pct,
    ROUND(AVG(review_score), 2) AS avg_customer_rating
FROM regional_orders
GROUP BY destination_region
ORDER BY freight_burden_pct DESC;
