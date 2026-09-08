-- ============================================================
-- View: payments_by_state
-- Purpose: Per-state payment behaviour — boleto vs credit card share,
--          average installments, and average order value.
--          boleto_pct / credit_card_pct stored as ratios (0.286 = 28.6%)
--          so Power BI's native % format displays them correctly.
-- Feeds:   Power BI "Payments & Regional Affordability" page
-- ============================================================

CREATE OR REPLACE VIEW payments_by_state AS
SELECT 
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(CASE WHEN p.payment_type = 'boleto' THEN 1 ELSE 0 END) / COUNT(*) AS boleto_pct,
    SUM(CASE WHEN p.payment_type = 'credit_card' THEN 1 ELSE 0 END) / COUNT(*) AS credit_card_pct,
    ROUND(AVG(p.payment_installments), 1) AS avg_installments,
    ROUND(AVG(p.payment_value), 2) AS avg_order_value
FROM order_payments p
JOIN orders o ON o.order_id = p.order_id
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY boleto_pct DESC;