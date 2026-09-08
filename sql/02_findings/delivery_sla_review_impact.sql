-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Finding: Delivery SLA Compliance and Review Score Impact
-- Business Question: What is Olist's late delivery rate, and
--                    how much does a late delivery hurt the
--                    customer's review score?
--
-- Why this matters: Delivery experience is the single biggest
-- driver of review scores in marketplace businesses. Quantifying
-- the exact rating penalty of a late delivery gives the ops
-- team a number to put on SLA investment decisions.
--
-- Key finding: Late deliveries score significantly lower than
-- on-time deliveries — the gap quantifies the business cost
-- of every SLA breach.
--
-- Concepts: CASE WHEN, conditional aggregation, DATEDIFF,
--           NULL handling for undelivered orders
-- Author: Brijesh Vaghela
-- ============================================================
USE olist;

WITH delivery_status AS (
    -- Step 1: classify each order as late or on-time
    SELECT
        o.order_id,
        o.order_status,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        r.review_score,
        DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        )                               AS days_late,
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late'
            ELSE 'On Time'
        END                             AS delivery_flag
    FROM orders o
    JOIN order_reviews r ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),
summary AS (
    -- Step 2: aggregate key metrics by delivery status
    SELECT
        delivery_flag,
        COUNT(*)                        AS total_orders,
        ROUND(AVG(review_score), 2)     AS avg_review_score,
        ROUND(AVG(days_late), 1)        AS avg_days_late,
        ROUND(MIN(days_late), 0)        AS min_days_late,
        ROUND(MAX(days_late), 0)        AS max_days_late
    FROM delivery_status
    GROUP BY delivery_flag
)
SELECT
    s.delivery_flag,
    s.total_orders,
    ROUND(s.total_orders * 100.0 /
        SUM(s.total_orders) OVER (), 1) AS pct_of_orders,
    s.avg_review_score,
    s.avg_days_late,
    s.min_days_late,
    s.max_days_late
FROM summary s
ORDER BY delivery_flag DESC;