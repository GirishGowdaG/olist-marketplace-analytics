-- ==============================================================================
-- View 04: Seller Reliability & Operational Health View
-- Powers: Seller & Product Performance Dashboard Page
-- Analyzes merchant dispatch discipline, order volume, return/cancellation exposure,
-- and customer ratings to support seller tiering.
-- ==============================================================================

USE olist;

CREATE OR REPLACE VIEW view_seller_operational_health AS
SELECT
    s.seller_id,
    s.seller_state,
    s.seller_city,
    COUNT(DISTINCT o.order_id) AS total_orders_fulfilled,
    COUNT(oi.order_item_id) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS total_seller_gmv,
    ROUND(AVG(oi.price), 2) AS avg_item_price,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight_value,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, o.order_approved_at, o.order_delivered_carrier_date)), 1) AS avg_dispatch_hours,
    ROUND(SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(DISTINCT o.order_id), 0), 1) AS late_delivery_pct,
    ROUND(AVG(r.review_score), 2) AS avg_seller_rating
FROM sellers s
JOIN order_items oi ON oi.seller_id = s.seller_id
JOIN orders o ON o.order_id = oi.order_id
LEFT JOIN order_reviews r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_approved_at IS NOT NULL
  AND o.order_delivered_carrier_date IS NOT NULL
GROUP BY s.seller_id, s.seller_state, s.seller_city;
