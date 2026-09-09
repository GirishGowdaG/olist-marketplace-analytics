-- ==============================================================================
-- Query 02: Order Fulfillment Latency Deconstruction
-- Business Problem: When an order arrives late, who is accountable? Total delivery
-- latency is composite: Seller Handling Time (order approval to carrier dispatch)
-- versus Carrier Transit Time (carrier dispatch to customer delivery).
--
-- Approach:
-- 1. Filter delivered orders with valid timestamps.
-- 2. Decompose cycle time into:
--    - seller_handling_days: TIMESTAMPDIFF(HOUR, order_approved_at, order_delivered_carrier_date) / 24
--    - carrier_transit_days: TIMESTAMPDIFF(HOUR, order_delivered_carrier_date, order_delivered_customer_date) / 24
--    - total_cycle_days: TIMESTAMPDIFF(HOUR, order_purchase_timestamp, order_delivered_customer_date) / 24
-- 3. Segment by SLA performance (Delivered Before/On Estimate vs. Delivered Past Estimate)
--    to isolate which stage causes SLA breaches.
-- ==============================================================================

USE olist;

WITH fulfillment_times AS (
    SELECT
        o.order_id,
        CASE
            WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'Met SLA (On-Time)'
            ELSE 'Breached SLA (Delayed)'
        END AS sla_status,
        ROUND(TIMESTAMPDIFF(HOUR, o.order_approved_at, o.order_delivered_carrier_date) / 24.0, 2) AS seller_handling_days,
        ROUND(TIMESTAMPDIFF(HOUR, o.order_delivered_carrier_date, o.order_delivered_customer_date) / 24.0, 2) AS carrier_transit_days,
        ROUND(TIMESTAMPDIFF(HOUR, o.order_purchase_timestamp, o.order_delivered_customer_date) / 24.0, 2) AS total_fulfillment_days,
        r.review_score
    FROM orders o
    LEFT JOIN order_reviews r ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_approved_at IS NOT NULL
      AND o.order_delivered_carrier_date IS NOT NULL
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_delivered_carrier_date >= o.order_approved_at
      AND o.order_delivered_customer_date >= o.order_delivered_carrier_date
)
SELECT
    sla_status,
    COUNT(order_id) AS total_orders,
    ROUND(AVG(seller_handling_days), 2) AS avg_seller_handling_days,
    ROUND(AVG(carrier_transit_days), 2) AS avg_carrier_transit_days,
    ROUND(AVG(total_fulfillment_days), 2) AS avg_total_fulfillment_days,
    -- Ratio showing what portion of latency is carrier transit vs seller handling
    ROUND(AVG(carrier_transit_days) / NULLIF(AVG(total_fulfillment_days), 0) * 100, 1) AS carrier_transit_share_pct,
    ROUND(AVG(review_score), 2) AS avg_review_rating
FROM fulfillment_times
GROUP BY sla_status;
