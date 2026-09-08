-- ============================================================
-- View: cohort_retention_matrix
-- Purpose: Monthly cohort retention — for each acquisition cohort,
--          what % of customers remained active N months later.
-- Feeds:   Power BI "Customer Retention" page (cohort heatmap)
-- ============================================================

CREATE OR REPLACE VIEW cohort_retention_matrix AS
WITH customer_cohort AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id, DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
),
cohort_data AS (
    SELECT 
        cc.cohort_month,
        PERIOD_DIFF(
            EXTRACT(YEAR_MONTH FROM STR_TO_DATE(CONCAT(co.order_month, '-01'), '%Y-%m-%d')),
            EXTRACT(YEAR_MONTH FROM STR_TO_DATE(CONCAT(cc.cohort_month, '-01'), '%Y-%m-%d'))
        ) AS month_offset,
        COUNT(DISTINCT co.customer_unique_id) AS active_customers
    FROM customer_cohort cc
    JOIN customer_orders co ON cc.customer_unique_id = co.customer_unique_id
    GROUP BY cc.cohort_month, month_offset
),
cohort_sizes AS (
    SELECT cohort_month, active_customers AS cohort_size
    FROM cohort_data
    WHERE month_offset = 0
)
SELECT 
    cd.cohort_month,
    cd.month_offset,
    cd.active_customers,
    cs.cohort_size,
    ROUND((cd.active_customers / cs.cohort_size) * 100, 2) AS retention_pct
FROM cohort_data cd
JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
ORDER BY cd.cohort_month, cd.month_offset;