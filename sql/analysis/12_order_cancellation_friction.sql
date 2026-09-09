-- ==============================================================================
-- Query 12: Order Cancellation & Attrition Friction Analysis
-- Business Problem: Non-fulfilled orders ('canceled' and 'unavailable') erode customer
-- trust. At what stage of the lifecycle do orders get canceled, which seller states
-- generate the highest cancellation rates, and what is the lost GMV impact?
--
-- Approach:
-- 1. Partition all orders by status: 'delivered', 'canceled', 'unavailable', 'in_process'.
-- 2. Measure overall cancellation and unavailability rates.
-- 3. Analyze potential revenue lost and correlation with seller geography.
-- ==============================================================================

USE olist;

WITH order_lifecycle AS (
    SELECT
        o.order_id,
        o.order_status,
        c.customer_state,
        COUNT(oi.order_item_id) AS items_in_order,
        COALESCE(SUM(oi.price), 0) AS order_goods_value,
        COALESCE(SUM(oi.freight_value), 0) AS order_freight_value
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.order_id, o.order_status, c.customer_state
)
SELECT
    order_status,
    COUNT(order_id) AS order_count,
    ROUND(COUNT(order_id) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS status_share_pct,
    ROUND(SUM(order_goods_value), 2) AS total_goods_value,
    ROUND(SUM(order_freight_value), 2) AS total_freight_value,
    ROUND(AVG(order_goods_value), 2) AS avg_order_value
FROM order_lifecycle
GROUP BY order_status
ORDER BY order_count DESC;
