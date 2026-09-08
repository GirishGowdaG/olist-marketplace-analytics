-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Finding 03: Window Frames — Running Total & 7-Day Moving Avg
-- Business Question: What does Olist's daily revenue look like
--                    as a running total and 7-day moving average?
--
-- Why this matters: Growth and finance teams use running totals
-- to track cumulative revenue vs targets. Moving averages
-- smooth daily noise to reveal the real underlying trend —
-- removing weekend dips and one-off spikes from the picture.
--
-- Concepts: SUM() OVER, AVG() OVER, ROWS BETWEEN window frames
-- Author: Brijesh Vaghela
-- ============================================================
USE olist;

WITH daily_revenue AS (
    -- Step 1: aggregate to one revenue number per day
    -- order_items holds price; join orders for the purchase date
    SELECT
        DATE(o.order_purchase_timestamp) AS order_date,
        SUM(oi.price)                    AS daily_rev
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status != 'canceled'        -- exclude cancelled orders
      AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY DATE(o.order_purchase_timestamp)
),
rolling AS (
    -- Step 2: add running total and 7-day moving average
    SELECT
        order_date,
        daily_rev,
        ROUND(
            SUM(daily_rev) OVER (
                ORDER BY order_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ), 2
        ) AS running_total,
        ROUND(
            AVG(daily_rev) OVER (
                ORDER BY order_date
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ), 2
        ) AS moving_avg_7d
    FROM daily_revenue
)
SELECT *
FROM rolling
WHERE order_date BETWEEN '2017-01-01' AND '2018-12-31'
ORDER BY order_date;