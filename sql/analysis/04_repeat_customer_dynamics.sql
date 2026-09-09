-- ==============================================================================
-- Query 04: Customer Repeat Purchase Dynamics & Basket Economics
-- Business Problem: Marketplace growth requires understanding the lifetime value
-- difference between one-time buyers and repeat buyers. What proportion of customers
-- make repeated purchases, and how do repeat customers compare in Average Order
-- Value (AOV), items per basket, and freight spend?
--
-- Approach:
-- 1. Identify distinct customers using `customer_unique_id` (not per-order customer_id).
-- 2. Compute order count, total spend, total freight, and days between first and last order.
-- 3. Segment into 'Single-Order Buyers' vs 'Repeat Customers' (2, 3, 4+ orders).
-- 4. Compare customer economic profiles.
-- ==============================================================================

USE olist;

WITH customer_orders_summary AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(oi.order_item_id) AS total_items,
        SUM(oi.price) AS total_product_spend,
        SUM(oi.freight_value) AS total_freight_spend,
        MIN(o.order_purchase_timestamp) AS first_order_date,
        MAX(o.order_purchase_timestamp) AS last_order_date
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_segments AS (
    SELECT
        customer_unique_id,
        total_orders,
        total_items,
        total_product_spend,
        total_freight_spend,
        TIMESTAMPDIFF(DAY, first_order_date, last_order_date) AS lifespan_days,
        CASE
            WHEN total_orders = 1 THEN '1. One-Time Customer'
            WHEN total_orders = 2 THEN '2. Repeat (2 Orders)'
            WHEN total_orders BETWEEN 3 AND 4 THEN '3. Frequent (3-4 Orders)'
            ELSE '4. Power Buyer (5+ Orders)'
        END AS loyalty_cohort
    FROM customer_orders_summary
)
SELECT
    loyalty_cohort,
    COUNT(customer_unique_id) AS customer_count,
    ROUND(COUNT(customer_unique_id) * 100.0 / (SELECT COUNT(*) FROM customer_segments), 2) AS customer_share_pct,
    ROUND(SUM(total_product_spend), 2) AS cohort_gmv,
    ROUND(SUM(total_product_spend) * 100.0 / (SELECT SUM(total_product_spend) FROM customer_segments), 2) AS gmv_share_pct,
    ROUND(AVG(total_product_spend / total_orders), 2) AS avg_basket_value_per_order,
    ROUND(AVG(total_items / total_orders), 2) AS avg_items_per_order,
    ROUND(AVG(total_freight_spend / total_orders), 2) AS avg_freight_per_order,
    ROUND(AVG(lifespan_days), 1) AS avg_lifespan_days
FROM customer_segments
GROUP BY loyalty_cohort
ORDER BY loyalty_cohort;
