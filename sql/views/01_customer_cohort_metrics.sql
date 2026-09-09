-- ==============================================================================
-- View 01: Customer Lifetime & Cohort Repurchase View
-- Powers: Executive Overview & Growth / Customer Economics page
-- Aggregates customer cohorts by initial acquisition month and measures
-- repeat order penetration and lifetime gross value.
-- ==============================================================================

USE olist;

CREATE OR REPLACE VIEW view_customer_cohort_metrics AS
WITH customer_first_orders AS (
    SELECT
        c.customer_unique_id,
        MIN(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')) AS cohort_month,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_activity AS (
    SELECT
        c.customer_unique_id,
        f.cohort_month,
        TIMESTAMPDIFF(MONTH, STR_TO_DATE(f.cohort_month, '%Y-%m-%d'), STR_TO_DATE(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01'), '%Y-%m-%d')) AS month_offset,
        oi.price,
        oi.freight_value
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    JOIN customer_first_orders f ON f.customer_unique_id = c.customer_unique_id
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
),
cohort_summary AS (
    SELECT
        cohort_month,
        month_offset,
        COUNT(DISTINCT customer_unique_id) AS active_customers,
        ROUND(SUM(price), 2) AS monthly_cohort_revenue,
        ROUND(SUM(freight_value), 2) AS monthly_cohort_freight
    FROM customer_activity
    GROUP BY cohort_month, month_offset
)
SELECT
    cs.cohort_month,
    cs.month_offset,
    cs.active_customers,
    c0.active_customers AS cohort_size_month_0,
    ROUND(cs.active_customers * 100.0 / NULLIF(c0.active_customers, 0), 2) AS retention_rate_pct,
    cs.monthly_cohort_revenue,
    cs.monthly_cohort_freight
FROM cohort_summary cs
JOIN cohort_summary c0 ON c0.cohort_month = cs.cohort_month AND c0.month_offset = 0;
