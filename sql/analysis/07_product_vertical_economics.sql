-- ==============================================================================
-- Query 07: Product Vertical Economics — Quality vs. Fulfillment Drag
-- Business Problem: Do product categories suffer poor ratings because of intrinsic
-- product dissatisfaction, or because heavy/bulky physical goods suffer shipping
-- damage and prolonged transit?
--
-- Approach:
-- 1. Aggregate top 25 categories by delivered order items.
-- 2. Correlate average product weight and volume with freight costs and transit times.
-- 3. Compare average review score and late delivery percentage to identify categories
--    whose satisfaction is constrained by physical logistics.
-- ==============================================================================

USE olist;

WITH category_logistics AS (
    SELECT
        COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category,
        oi.price,
        oi.freight_value,
        p.product_weight_g,
        (p.product_length_cm * p.product_height_cm * p.product_width_cm) AS product_volume_cm3,
        DATEDIFF(o.order_delivered_customer_date, o.order_delivered_carrier_date) AS transit_days,
        CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END AS is_late,
        r.review_score
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN category_translation ct ON ct.product_category_name = p.product_category_name
    JOIN orders o ON o.order_id = oi.order_id
    LEFT JOIN order_reviews r ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
    category,
    COUNT(*) AS total_units_sold,
    ROUND(SUM(price), 2) AS total_gmv,
    ROUND(AVG(price), 2) AS avg_item_price,
    ROUND(AVG(freight_value), 2) AS avg_freight_value,
    ROUND(AVG(product_weight_g) / 1000.0, 2) AS avg_weight_kg,
    ROUND(AVG(product_volume_cm3) / 1000.0, 1) AS avg_volume_liters,
    ROUND(AVG(transit_days), 1) AS avg_carrier_transit_days,
    ROUND(SUM(is_late) * 100.0 / COUNT(*), 2) AS late_rate_pct,
    ROUND(AVG(review_score), 2) AS avg_customer_score
FROM category_logistics
GROUP BY category
HAVING total_units_sold >= 500
ORDER BY avg_weight_kg DESC;
