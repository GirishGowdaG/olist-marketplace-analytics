-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Finding: Month-over-Month Revenue Growth
-- Business Question: What is Olist's MoM revenue growth, and
--                    which months showed biggest acceleration
--                    or decline?
--
-- Why this matters: The single most-reported metric in growth
-- and product teams. "We grew 15% MoM" or "Revenue dipped 8%
-- vs last month" — this is how those numbers get calculated.
--
-- Key finding: November 2017 saw the largest growth spike —
-- driven by Black Friday Brazil (Novembro Negro). January 2018
-- saw the sharpest decline as the holiday surge unwound.
--
-- Concepts: LAG(), MoM growth calculation, NULL handling
-- Author: Brijesh Vaghela
-- ============================================================
USE olist;

WITH monthly_rev AS (
    -- Step 1: total revenue per calendar month
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        ROUND(SUM(oi.price), 2)                          AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status != 'canceled'
      AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
),
with_lag AS (
    -- Step 2: bring previous month's revenue onto the same row
    SELECT
        order_month,
        revenue,
        LAG(revenue, 1) OVER (ORDER BY order_month) AS prev_month_rev,
        ROUND(
            (revenue - LAG(revenue, 1) OVER (ORDER BY order_month))
            / LAG(revenue, 1) OVER (ORDER BY order_month) * 100
        , 1) AS mom_growth_pct
    FROM monthly_rev
)
SELECT *
FROM with_lag
ORDER BY order_month;