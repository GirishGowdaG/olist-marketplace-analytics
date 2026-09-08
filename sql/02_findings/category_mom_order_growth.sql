-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Finding 3 Practice: MoM order count growth per category
-- Business Question: For the top 5 categories by revenue,
--                    how is order volume growing month over month?
--
-- Why this matters: Revenue growth could come from higher prices
-- OR more orders. This isolates the volume signal — is demand
-- actually increasing, or is revenue growth masking flat volume
-- with price inflation?
--
-- Concepts: LAG() with PARTITION BY, MoM growth %, top-N filter CTE
-- Author: Brijesh Vaghela
-- ============================================================

USE olist;

WITH category_monthly AS (
    SELECT
        ct.product_category_name_english     AS category,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        COUNT(DISTINCT o.order_id)           AS order_count
    FROM order_items oi
    JOIN orders o   ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN category_translation ct ON p.product_category_name = ct.product_category_name
    WHERE o.order_status != 'canceled'
      AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY ct.product_category_name_english,
             DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
),
top5 AS (
    SELECT category
    FROM category_monthly
    GROUP BY category
    ORDER BY SUM(order_count) DESC
    LIMIT 5
),
with_lag AS (
    SELECT
        cm.category,
        cm.order_month,
        cm.order_count,
        LAG(cm.order_count, 1) OVER (
            PARTITION BY cm.category
            ORDER BY cm.order_month
        ) AS prev_month_orders,
        ROUND(
            (cm.order_count - LAG(cm.order_count, 1) OVER (
                PARTITION BY cm.category
                ORDER BY cm.order_month
            )) / LAG(cm.order_count, 1) OVER (
                PARTITION BY cm.category
                ORDER BY cm.order_month
            ) * 100
        , 1) AS mom_growth_pct
    FROM category_monthly cm
    JOIN top5 t ON t.category = cm.category
)
SELECT *
FROM with_lag
ORDER BY category, order_month;