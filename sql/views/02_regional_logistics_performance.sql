-- ==============================================================================
-- View 02: Regional Logistics & Freight Efficiency View
-- Powers: Operations & Regional Efficiency Dashboard Page
-- Consolidates state-by-state order volumes, average freight ratios, carrier transit
-- days, and delivery SLA compliance percentages.
-- ==============================================================================

USE olist;

CREATE OR REPLACE VIEW view_regional_logistics_performance AS
SELECT
    c.customer_state,
    CASE
        WHEN c.customer_state IN ('SP', 'RJ', 'MG', 'ES') THEN 'Southeast'
        WHEN c.customer_state IN ('PR', 'SC', 'RS') THEN 'South'
        WHEN c.customer_state IN ('DF', 'GO', 'MT', 'MS') THEN 'Central-West'
        WHEN c.customer_state IN ('BA', 'PE', 'CE', 'MA', 'PB', 'RN', 'AL', 'SE', 'PI') THEN 'Northeast'
        ELSE 'North'
    END AS macro_region,
    COUNT(DISTINCT o.order_id) AS total_delivered_orders,
    ROUND(SUM(oi.price), 2) AS total_gmv,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_spent,
    ROUND(SUM(oi.freight_value) * 100.0 / NULLIF(SUM(oi.price), 0), 2) AS freight_burden_ratio_pct,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_delivered_carrier_date)), 1) AS avg_carrier_transit_days,
    ROUND(AVG(DATEDIFF(o.order_delivered_carrier_date, o.order_approved_at)), 1) AS avg_seller_dispatch_days,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_total_cycle_days,
    ROUND(SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT o.order_id), 2) AS late_delivery_rate_pct,
    ROUND(AVG(r.review_score), 2) AS avg_customer_rating
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
LEFT JOIN order_reviews r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state;
