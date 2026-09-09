-- ==============================================================================
-- Query 09: Seller Operational Reliability Matrix
-- Business Problem: Seller rating is often evaluated in aggregate, obscuring
-- operational performance. A merchant might sell high-quality goods but consistently
-- miss carrier handover deadlines. How can Olist segment sellers by operational
-- discipline (handling speed, SLA breach rate) alongside customer satisfaction?
--
-- Approach:
-- 1. Compute for each seller with >= 30 orders:
--    - Gross sales (GMV)
--    - Average handling time (hours from order approval to carrier dispatch)
--    - On-time delivery compliance %
--    - Average review rating
-- 2. Construct an independent 4-tier matrix:
--    - 'Elite Operator' (Handling <= 48 hrs, Rating >= 4.2, Late Rate <= 5%)
--    - 'Fast But Quality Risk' (Handling <= 48 hrs, Rating < 4.0)
--    - 'Dispatch Bottleneck' (Handling > 72 hrs, Late Rate > 15%)
--    - 'Standard Seller' (Remaining active merchants)
-- ==============================================================================

USE olist;

WITH seller_metrics AS (
    SELECT
        oi.seller_id,
        s.seller_state,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(oi.price), 2) AS total_seller_gmv,
        ROUND(AVG(TIMESTAMPDIFF(HOUR, o.order_approved_at, o.order_delivered_carrier_date)), 1) AS avg_handling_hours,
        ROUND(SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT o.order_id), 1) AS late_order_pct,
        ROUND(AVG(r.review_score), 2) AS avg_seller_rating
    FROM order_items oi
    JOIN sellers s ON s.seller_id = oi.seller_id
    JOIN orders o ON o.order_id = oi.order_id
    LEFT JOIN order_reviews r ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_approved_at IS NOT NULL
      AND o.order_delivered_carrier_date IS NOT NULL
    GROUP BY oi.seller_id, s.seller_state
    HAVING total_orders >= 30
),
seller_classification AS (
    SELECT
        seller_id,
        seller_state,
        total_orders,
        total_seller_gmv,
        avg_handling_hours,
        late_order_pct,
        avg_seller_rating,
        CASE
            WHEN avg_handling_hours <= 48 AND avg_seller_rating >= 4.20 AND late_order_pct <= 5.0 THEN 'Tier 1: Elite Operator'
            WHEN avg_handling_hours <= 48 AND avg_seller_rating < 4.00 THEN 'Tier 2: Fast Dispatch / Product Quality Risk'
            WHEN avg_handling_hours > 72 AND late_order_pct > 15.0 THEN 'Tier 3: Dispatch Bottleneck'
            ELSE 'Tier 4: Standard Merchant'
        END AS operational_tier
    FROM seller_metrics
)
SELECT
    operational_tier,
    COUNT(*) AS merchant_count,
    ROUND(SUM(total_seller_gmv), 2) AS tier_gmv,
    ROUND(SUM(total_seller_gmv) * 100.0 / (SELECT SUM(total_seller_gmv) FROM seller_classification), 1) AS gmv_share_pct,
    ROUND(AVG(avg_handling_hours), 1) AS tier_avg_handling_hours,
    ROUND(AVG(late_order_pct), 1) AS tier_avg_late_pct,
    ROUND(AVG(avg_seller_rating), 2) AS tier_avg_rating
FROM seller_classification
GROUP BY operational_tier
ORDER BY tier_gmv DESC;
