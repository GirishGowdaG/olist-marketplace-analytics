-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Finding: Payment Method and Installment Behaviour by State
-- Business Question: How does payment behaviour vary across
--                    Brazilian states, and which regions rely
--                    most heavily on installment payments?
--
-- Why this matters: Payment mix informs which methods to
-- promote per market, where to negotiate processor rates,
-- and which regions are most dependent on credit financing.
-- High installment averages signal price-sensitive markets
-- where affordability drives purchase decisions.
--
-- Concepts: Conditional aggregation, CASE WHEN pivot,
--           percentage calculation, multi-metric ranking
-- Author: Brijesh Vaghela
-- ============================================================
USE olist;

WITH order_payments_detail AS (
    -- Step 1: one row per order with customer state and payment info
    SELECT
        c.customer_state,
        o.order_id,
        op.payment_type,
        op.payment_installments,
        op.payment_value
    FROM orders o
    JOIN customers c        ON c.customer_id = o.customer_id
    JOIN order_payments op  ON op.order_id = o.order_id
    WHERE o.order_status != 'canceled'
),
state_payment_summary AS (
    -- Step 2: pivot payment types into columns per state
    SELECT
        customer_state,
        COUNT(DISTINCT order_id)                        AS total_orders,
        SUM(CASE WHEN payment_type = 'credit_card'
            THEN 1 ELSE 0 END)                          AS credit_card_orders,
        SUM(CASE WHEN payment_type = 'boleto'
            THEN 1 ELSE 0 END)                          AS boleto_orders,
        SUM(CASE WHEN payment_type = 'voucher'
            THEN 1 ELSE 0 END)                          AS voucher_orders,
        SUM(CASE WHEN payment_type = 'debit_card'
            THEN 1 ELSE 0 END)                          AS debit_card_orders,
        ROUND(AVG(payment_installments), 1)             AS avg_installments,
        ROUND(AVG(payment_value), 2)                    AS avg_payment_value
    FROM order_payments_detail
    GROUP BY customer_state
)
SELECT
    customer_state,
    total_orders,
    -- percentage split by payment type
    ROUND(credit_card_orders * 100.0 / total_orders, 1) AS credit_card_pct,
    ROUND(boleto_orders      * 100.0 / total_orders, 1) AS boleto_pct,
    ROUND(voucher_orders     * 100.0 / total_orders, 1) AS voucher_pct,
    ROUND(debit_card_orders  * 100.0 / total_orders, 1) AS debit_card_pct,
    avg_installments,
    avg_payment_value
FROM state_payment_summary
ORDER BY total_orders DESC;