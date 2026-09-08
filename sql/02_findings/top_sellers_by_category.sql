-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Finding 01: Top-N Per Group (Window Functions — Ranking)
-- Business Question: Top 3 sellers by revenue in each of
--                    Olist's top 5 product categories
--
-- Why this matters: Category managers use this to identify
-- which sellers get premium placement, better commission
-- terms, or co-marketing budget. The revenue gap between
-- rank 1 and rank 3 reveals category concentration risk.
--
-- Key finding: watches_gifts shows healthy competition
-- (201K / 192K / 169K). bed_bath_table is concentrated —
-- rank 1 and 2 earn 3x rank 3, giving them outsized
-- negotiating power over Olist's commission structure.
--
-- Concepts: ROW_NUMBER(), PARTITION BY, 3-stage CTE pattern
-- Author: Brijesh Vaghela
-- ============================================================
USE olist;

WITH category_seller_rev AS (
    SELECT
        ct.product_category_name_english AS category,
        oi.seller_id,
        SUM(oi.price)                    AS seller_revenue
    FROM order_items oi
    JOIN products p
        ON p.product_id = oi.product_id
    JOIN category_translation ct
        ON ct.product_category_name = p.product_category_name
    GROUP BY ct.product_category_name_english, oi.seller_id
),
ranked AS (
    SELECT
        category,
        seller_id,
        seller_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY seller_revenue DESC, seller_id ASC
        ) AS rev_rank
    FROM category_seller_rev
),
top_categories AS (
    SELECT category
    FROM category_seller_rev
    GROUP BY category
    ORDER BY SUM(seller_revenue) DESC
    LIMIT 5
)
SELECT
    r.category,
    r.seller_id,
    r.seller_revenue,
    r.rev_rank
FROM ranked r
JOIN top_categories tc ON tc.category = r.category
WHERE r.rev_rank <= 3
ORDER BY r.category, r.rev_rank;