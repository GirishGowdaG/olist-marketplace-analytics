-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Finding: Monthly Cohort Retention (Pivot Table)
-- Business Question: What percentage of customers return to
--                    order again after their first purchase?
--
-- Why this matters: Retention is the single most important
-- metric for any marketplace. Acquiring customers costs money —
-- if they buy once and never return, that cost is never
-- recovered. This is the table product and growth teams
-- review weekly.
--
-- Critical data note: customer_unique_id (not customer_id) is
-- the true person identifier in Olist. Using customer_id makes
-- every order look like a new customer — a data trap that
-- produces completely wrong retention numbers.
--
-- Key finding: Month-1 retention is below 1% across every
-- cohort. Olist is a one-time-buyer marketplace — growth
-- depends entirely on continuous new customer acquisition.
--
-- Concepts: Multi-stage CTE, PERIOD_DIFF, conditional aggregation pivot
-- Author: Brijesh Vaghela
-- ============================================================
USE olist;

WITH first_order AS (
    SELECT
        c.customer_unique_id,
        MIN(DATE(o.order_purchase_timestamp))                  AS first_order_date,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m')  AS cohort_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status != 'canceled'
    GROUP BY c.customer_unique_id
),
order_activity AS (
    SELECT
        c.customer_unique_id,
        f.cohort_month,
        PERIOD_DIFF(
            DATE_FORMAT(o.order_purchase_timestamp, '%Y%m'),
            DATE_FORMAT(f.first_order_date, '%Y%m')
        ) AS month_number
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN first_order f ON c.customer_unique_id = f.customer_unique_id
    WHERE o.order_status != 'canceled'
),
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_unique_id) AS cohort_customers
    FROM first_order
    GROUP BY cohort_month
),
monthly_retention AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM order_activity
    GROUP BY cohort_month, month_number
)
SELECT
    mr.cohort_month,
    cs.cohort_customers                                                         AS m0,
    SUM(CASE WHEN mr.month_number = 1  THEN mr.active_customers END)            AS m1,
    SUM(CASE WHEN mr.month_number = 2  THEN mr.active_customers END)            AS m2,
    SUM(CASE WHEN mr.month_number = 3  THEN mr.active_customers END)            AS m3,
    SUM(CASE WHEN mr.month_number = 4  THEN mr.active_customers END)            AS m4,
    SUM(CASE WHEN mr.month_number = 5  THEN mr.active_customers END)            AS m5,
    SUM(CASE WHEN mr.month_number = 6  THEN mr.active_customers END)            AS m6,
    SUM(CASE WHEN mr.month_number = 7  THEN mr.active_customers END)            AS m7,
    SUM(CASE WHEN mr.month_number = 8  THEN mr.active_customers END)            AS m8,
    SUM(CASE WHEN mr.month_number = 9  THEN mr.active_customers END)            AS m9,
    SUM(CASE WHEN mr.month_number = 10 THEN mr.active_customers END)            AS m10,
    SUM(CASE WHEN mr.month_number = 11 THEN mr.active_customers END)            AS m11,
    SUM(CASE WHEN mr.month_number = 12 THEN mr.active_customers END)            AS m12
FROM monthly_retention mr
JOIN cohort_size cs ON cs.cohort_month = mr.cohort_month
GROUP BY mr.cohort_month, cs.cohort_customers
ORDER BY mr.cohort_month;