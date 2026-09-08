-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Finding 02 Practice: Running total of orders per category
--                       by month
-- Business Question: How has each product category's order
--                    volume accumulated over time?
--
-- Why this matters: Category managers use cumulative order
-- trends to spot which categories are growing consistently
-- vs which had one-off spikes. A category with steady
-- month-on-month accumulation is healthier than one whose
-- running total jumps once then flatlines.
--
-- Key concept: PARTITION BY Category_Name restarts the running
-- total independently for each category — without it, you get
-- one global counter meaningless for per-category analysis.
--
-- Concepts: SUM() OVER, PARTITION BY, ROWS BETWEEN window frame
-- Author: Brijesh Vaghela
-- ============================================================
USE olist;

WITH category_monthly AS (
    SELECT
        p.product_category_name           AS category_name,
        YEAR(o.order_purchase_timestamp)  AS order_year,
        MONTH(o.order_purchase_timestamp) AS order_month,
        COUNT(p.product_category_name)    AS num_orders
    FROM orders AS o
    JOIN order_items AS oi ON o.order_id = oi.order_id
    JOIN products AS p     ON oi.product_id = p.product_id
    GROUP BY p.product_category_name,
             YEAR(o.order_purchase_timestamp),
             MONTH(o.order_purchase_timestamp)
),
with_running_total AS (
    SELECT
        category_name,
        order_year,
        order_month,
        num_orders,
        SUM(num_orders) OVER (
            PARTITION BY category_name
            ORDER BY order_year, order_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total
    FROM category_monthly
)
SELECT *
FROM with_running_total
WHERE category_name IS NOT NULL
ORDER BY category_name, order_year, order_month;