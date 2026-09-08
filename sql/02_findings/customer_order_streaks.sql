-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Finding: Longest Consecutive Monthly Ordering Streaks
-- Business Question: Which customers ordered in the most
--                    consecutive months without a gap?
--
-- Why this matters: Given <1% month-1 retention across all
-- cohorts, any customer with 3+ consecutive months is an
-- extreme outlier. These are Olist's genuinely loyal buyers —
-- worth understanding for VIP programs and product insight.
--
-- Technique: Gaps & Islands — subtracting row number from
-- month number produces a constant for consecutive months.
-- Same constant = same island (streak). Different constant
-- = gap between streaks.
--
-- Concepts: Gaps & islands, ROW_NUMBER(), DATE_FORMAT,
--           PERIOD_DIFF, conditional grouping
-- Author: Brijesh Vaghela
-- ============================================================
USE olist;

WITH customer_months AS (
    -- Step 1: distinct months each customer was active
    SELECT
        c.customer_unique_id,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        CAST(PERIOD_DIFF(
            DATE_FORMAT(o.order_purchase_timestamp, '%Y%m'),
            '201609'   -- arbitrary fixed reference point (dataset start)
        ) AS SIGNED) AS month_number
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status != 'canceled'
      AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY c.customer_unique_id,
             DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m'),
             CAST(PERIOD_DIFF(
                 DATE_FORMAT(o.order_purchase_timestamp, '%Y%m'),
                 '201609'
             ) AS SIGNED)
),
with_row_num AS (
    -- Step 2: assign row number per customer ordered by month
    SELECT
        customer_unique_id,
        order_month,
        month_number,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY month_number
        ) AS rn
    FROM customer_months
),
islands AS (
    -- Step 3: month_number - rn is constant for consecutive months
    -- same value = same island = same streak
    SELECT
        customer_unique_id,
        order_month,
        month_number,
        rn,
        (month_number - CAST(rn AS SIGNED)) AS island_id
    FROM with_row_num
),
streak_lengths AS (
    -- Step 4: count how many months in each island per customer
    SELECT
        customer_unique_id,
        island_id,
        COUNT(*)              AS streak_length,
        MIN(order_month)      AS streak_start,
        MAX(order_month)      AS streak_end
    FROM islands
    GROUP BY customer_unique_id, island_id
),
best_streak AS (
    -- Step 5: keep only each customer's longest streak
    SELECT
        customer_unique_id,
        MAX(streak_length)    AS longest_streak,
        MIN(streak_start)     AS streak_start,
        MAX(streak_end)       AS streak_end
    FROM streak_lengths
    GROUP BY customer_unique_id
)
SELECT
    customer_unique_id,
    longest_streak,
    streak_start,
    streak_end
FROM best_streak
WHERE longest_streak >= 3          -- filter out one/two-timers
ORDER BY longest_streak DESC, streak_start ASC
LIMIT 20;