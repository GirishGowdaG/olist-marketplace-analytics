-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Finding: Order Value Percentiles and High-Value Segments
-- Business Question: What is the median order value, how does
--                    spending distribute, and who are the top
--                    10% of spenders?
--
-- Why this matters: Average order value is distorted by
-- outliers. Median and percentile distribution reveal what
-- a typical order actually looks like and where the high-
-- value segment begins — critical for pricing, promotions,
-- and customer segmentation strategy.
--
-- Concepts: NTILE(), percentile buckets, median calculation,
--           revenue concentration analysis
-- Author: Brijesh Vaghela
-- ============================================================
USE olist;

WITH order_totals AS (
    -- Step 1: total value per order (sum across all items)
    SELECT
        o.order_id,
        c.customer_unique_id,
        SUM(oi.price + oi.freight_value)    AS order_value
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN customers c    ON c.customer_id = o.customer_id
    WHERE o.order_status != 'canceled'
    GROUP BY o.order_id, c.customer_unique_id
),
with_percentile AS (
    -- Step 2: assign each order to a percentile bucket (1-100)
    SELECT
        order_id,
        customer_unique_id,
        order_value,
        NTILE(100) OVER (ORDER BY order_value) AS percentile_bucket
    FROM order_totals
),
percentile_summary AS (
    -- Step 3: min/max order value at each percentile boundary
    SELECT
        percentile_bucket,
        COUNT(*)                        AS orders_in_bucket,
        ROUND(MIN(order_value), 2)      AS min_value,
        ROUND(MAX(order_value), 2)      AS max_value,
        ROUND(AVG(order_value), 2)      AS avg_value
    FROM with_percentile
    GROUP BY percentile_bucket
)
-- Key percentile boundaries
SELECT
    percentile_bucket,
    orders_in_bucket,
    min_value,
    max_value,
    avg_value
FROM percentile_summary
WHERE percentile_bucket IN (10, 25, 50, 75, 90, 95, 99, 100)
ORDER BY percentile_bucket;

-- ============================================================
-- Query 2: Revenue concentration by decile
-- What share of total revenue comes from the top 10% of orders?
-- ============================================================
WITH order_totals AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN customers c    ON c.customer_id = o.customer_id
    WHERE o.order_status != 'canceled'
    GROUP BY o.order_id, c.customer_unique_id
),
with_percentile AS (
    SELECT
        order_id,
        customer_unique_id,
        order_value,
        NTILE(10) OVER (ORDER BY order_value DESC) AS decile
    FROM order_totals
)
SELECT
    decile,
    COUNT(*)                            AS orders,
    ROUND(SUM(order_value), 2)          AS total_revenue,
    ROUND(AVG(order_value), 2)          AS avg_order_value,
    ROUND(SUM(order_value) * 100.0 /
        SUM(SUM(order_value)) OVER (), 2) AS revenue_pct
FROM with_percentile
GROUP BY decile
ORDER BY decile;