-- ==============================================================================
-- Query 05: Payment Method Economics & Installment Friction
-- Business Problem: Brazil has unique payment mechanisms, notably Boleto Bancário
-- (cash voucher) and high credit-card installment counts (up to 24x).
-- How does installment financing expand purchasing power (AOV), and does payment
-- method selection correlate with fulfillment cancellation rates?
--
-- Approach:
-- 1. Classify payment types across all orders.
-- 2. Measure order volume, GMV, Average Order Value (AOV), and average installment count.
-- 3. Calculate order completion rate vs. cancellation/abandonment rate per payment channel.
-- ==============================================================================

USE olist;

WITH order_payment_summary AS (
    SELECT
        o.order_id,
        o.order_status,
        op.payment_type,
        op.payment_installments,
        op.payment_value
    FROM orders o
    JOIN order_payments op ON op.order_id = o.order_id
)
SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value), 2) AS total_payment_volume,
    ROUND(AVG(payment_value), 2) AS avg_transaction_value,
    ROUND(AVG(payment_installments), 2) AS avg_installments,
    -- Installment tier distribution for credit card / overall
    SUM(CASE WHEN payment_installments = 1 THEN 1 ELSE 0 END) AS single_payment_orders,
    SUM(CASE WHEN payment_installments BETWEEN 2 AND 5 THEN 1 ELSE 0 END) AS short_installments_2_to_5,
    SUM(CASE WHEN payment_installments >= 6 THEN 1 ELSE 0 END) AS long_installments_6_plus,
    -- Completion & Cancellation Rates
    ROUND(SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS delivery_success_rate_pct,
    ROUND(SUM(CASE WHEN order_status IN ('canceled', 'unavailable') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS cancellation_rate_pct
FROM order_payment_summary
WHERE payment_type != 'not_defined'
GROUP BY payment_type
ORDER BY total_payment_volume DESC;
