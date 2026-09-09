-- ==============================================================================
-- Query 06: Carrier SLA Error Distribution & Buffer Reliability
-- Business Problem: Olist communicates an estimated delivery date to the customer.
-- How accurate is this estimate? What is the variance between actual delivery
-- date and estimated date across states? Where is the logistics buffer too tight
-- (causing breach) or excessively loose (distorting delivery expectations)?
--
-- Approach:
-- 1. Compute delivery buffer days: DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date).
--    - Positive value: Delivered early (under-promised).
--    - Negative value: Delivered late (SLA breached).
-- 2. Group by destination state and calculate SLA breach percentage, mean buffer,
--    and standard deviation of delivery buffer to measure logistics predictability.
-- ==============================================================================

USE olist;

WITH delivery_buffers AS (
    SELECT
        c.customer_state,
        o.order_id,
        DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date) AS buffer_days,
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
            ELSE 0
        END AS is_late,
        r.review_score
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    LEFT JOIN order_reviews r ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)
SELECT
    customer_state,
    COUNT(order_id) AS delivered_orders,
    ROUND(SUM(is_late) * 100.0 / COUNT(order_id), 2) AS sla_breach_rate_pct,
    ROUND(AVG(buffer_days), 1) AS avg_days_delivered_early,
    ROUND(STDDEV(buffer_days), 1) AS buffer_volatility_stddev,
    ROUND(AVG(CASE WHEN is_late = 1 THEN -buffer_days ELSE NULL END), 1) AS avg_days_overdue_when_late,
    ROUND(AVG(review_score), 2) AS state_avg_rating
FROM delivery_buffers
GROUP BY customer_state
HAVING delivered_orders >= 100
ORDER BY sla_breach_rate_pct DESC;
