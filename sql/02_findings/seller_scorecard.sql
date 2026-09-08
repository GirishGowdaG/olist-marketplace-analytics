-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Finding 10 (Capstone): Complete Seller Scorecard
-- Business Question: Which sellers are Olist's best overall
--                    performers across revenue, delivery, and
--                    review quality — and which are high-
--                    revenue but low-quality risks?
--
-- Why this matters: A marketplace can't optimise on revenue
-- alone. A seller doing R$200K but delivering late 40% of
-- the time and averaging 2.5 stars is destroying platform
-- trust. This scorecard surfaces both stars and risks in
-- one view — the kind of table a seller success team uses
-- weekly to prioritise outreach.
--
-- Techniques used: Multi-table joins, CTEs, window functions,
-- RANK(), conditional aggregation, CASE WHEN classification,
-- NTILE() for revenue percentile, correlated logic
-- Author: Brijesh Vaghela
-- ============================================================
USE olist;

WITH seller_revenue AS (
    -- Revenue and order volume per seller
    SELECT
        oi.seller_id,
        COUNT(DISTINCT oi.order_id)      AS total_orders,
        ROUND(SUM(oi.price), 2)          AS total_revenue
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status != 'canceled'
    GROUP BY oi.seller_id
),
seller_delivery AS (
    -- Delivery performance per seller
    SELECT
        oi.seller_id,
        COUNT(DISTINCT oi.order_id)      AS delivered_orders,
        ROUND(AVG(CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END) * 100, 1)                   AS late_delivery_pct,
        ROUND(AVG(DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        )), 1)                           AS avg_days_vs_estimate
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY oi.seller_id
),
seller_reviews AS (
    -- Review quality per seller
    SELECT
        oi.seller_id,
        ROUND(AVG(r.review_score), 2)    AS avg_review_score,
        COUNT(r.review_id)               AS total_reviews
    FROM order_items oi
    JOIN orders o        ON o.order_id = oi.order_id
    JOIN order_reviews r ON r.order_id = oi.order_id
    WHERE o.order_status != 'canceled'
    GROUP BY oi.seller_id
),
combined AS (
    -- Join all three dimensions, filter to sellers with enough data
    --
    -- CAVEAT: these are INNER JOINs, so a seller only appears in the
    -- final scorecard if they have (a) revenue, (b) at least one
    -- order with status='delivered' and non-NULL timestamps, AND
    -- (c) at least one review. A seller with only in-transit or
    -- cancelled orders, or zero reviews so far, is silently excluded
    -- entirely -- not scored as zero, just absent. This is a
    -- deliberate scope limitation (you can't rank delivery/quality
    -- for a seller with no delivery/review data yet), but it means
    -- this scorecard undercounts newer or slower-moving sellers.
    -- A production version would LEFT JOIN and surface these sellers
    -- with an explicit "insufficient data" flag rather than dropping
    -- them.
    SELECT
        sr.seller_id,
        s.seller_state,
        sr.total_orders,
        sr.total_revenue,
        sd.late_delivery_pct,
        sd.avg_days_vs_estimate,
        sv.avg_review_score,
        sv.total_reviews
    FROM seller_revenue sr
    JOIN seller_delivery sd ON sd.seller_id = sr.seller_id
    JOIN seller_reviews sv  ON sv.seller_id = sr.seller_id
    JOIN sellers s          ON s.seller_id  = sr.seller_id
    WHERE sr.total_orders >= 10          -- minimum threshold for reliability
),
scored AS (
    -- Add rankings and revenue percentile
    SELECT
        seller_id,
        seller_state,
        total_orders,
        total_revenue,
        late_delivery_pct,
        avg_days_vs_estimate,
        avg_review_score,
        RANK() OVER (ORDER BY total_revenue DESC)     AS revenue_rank,
        RANK() OVER (ORDER BY avg_review_score DESC)  AS quality_rank,
        RANK() OVER (ORDER BY late_delivery_pct ASC)  AS delivery_rank,
        NTILE(4) OVER (ORDER BY total_revenue DESC)   AS revenue_quartile,
        -- Classify sellers into performance segments
        CASE
            WHEN avg_review_score >= 4.0
             AND late_delivery_pct <= 10
            THEN 'Star Seller'
            WHEN total_revenue > 50000
             AND avg_review_score < 3.5
            THEN 'High Revenue Risk'
            WHEN avg_review_score < 3.0
            THEN 'Quality Risk'
            ELSE 'Standard'
        END                                           AS seller_segment
    FROM combined
)
SELECT
    seller_id,
    seller_state,
    total_orders,
    total_revenue,
    late_delivery_pct,
    avg_review_score,
    revenue_rank,
    quality_rank,
    delivery_rank,
    seller_segment
FROM scored
ORDER BY revenue_rank
LIMIT 30;