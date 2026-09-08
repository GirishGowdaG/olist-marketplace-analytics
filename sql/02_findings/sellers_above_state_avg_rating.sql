-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Finding: Sellers Outperforming Their State's Average Rating
-- Business Question: Which sellers consistently deliver above-
--                    average customer experience vs other
--                    sellers in their state?
--
-- Why this matters: These sellers are candidates for Top Seller
-- badges, search ranking boosts, and seller coaching benchmarks.
-- Comparing within state makes it fair — SP sellers vs SP
-- sellers, not against low-volume sellers in remote states.
--
-- Approach: Window function (AVG OVER PARTITION BY) chosen over
-- correlated subquery — computes state average in one pass
-- rather than once per row. At Olist's scale both work; at
-- 100M+ rows the window approach is significantly faster.
--
-- Note: A correlated subquery alternative was tested and
-- produced 694 results vs 691 from the window approach —
-- a 3-row difference caused by floating point rounding in
-- intermediate ROUND() calls. Window function result used
-- as the canonical answer since rounding happens once at
-- display time only.
--
-- Concepts: AVG() OVER PARTITION BY, correlated subquery,
--           HAVING for minimum order threshold
-- Author: Brijesh Vaghela
-- ============================================================
USE olist;

WITH seller_stats AS (
    SELECT
        oi.seller_id,
        s.seller_state,
        AVG(r.review_score)           AS avg_rating,
        COUNT(DISTINCT oi.order_id)   AS total_orders
    FROM order_items oi
    JOIN orders o        ON o.order_id = oi.order_id
    JOIN order_reviews r ON r.order_id = oi.order_id
    JOIN sellers s       ON s.seller_id = oi.seller_id
    WHERE o.order_status != 'canceled'
    GROUP BY oi.seller_id, s.seller_state
    HAVING COUNT(DISTINCT oi.order_id) >= 10
),
with_state_avg AS (
    SELECT
        seller_id,
        seller_state,
        avg_rating,
        total_orders,
        AVG(avg_rating) OVER (
            PARTITION BY seller_state
        ) AS state_avg_rating
    FROM seller_stats
)
SELECT
    seller_id,
    seller_state,
    ROUND(avg_rating, 2)        AS avg_rating,
    total_orders,
    ROUND(state_avg_rating, 2)  AS state_avg_rating,
    ROUND(avg_rating - state_avg_rating, 2) AS above_avg_by
FROM with_state_avg
WHERE avg_rating > state_avg_rating
ORDER BY seller_state, above_avg_by DESC;