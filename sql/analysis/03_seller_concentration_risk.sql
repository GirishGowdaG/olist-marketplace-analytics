-- ==============================================================================
-- Query 03: Seller Concentration and Category Market Risk
-- Business Problem: In which product categories is platform revenue heavily
-- reliant on a small handful of dominant sellers? High concentration exposes Olist
-- to seller attrition, sudden stockouts, and reduced commission bargaining power.
--
-- Approach:
-- 1. Join order items, products, sellers, and translated categories.
-- 2. Aggregate gross sales per (category, seller).
-- 3. Calculate category total revenue and compute the revenue share of the
--    Top 1, Top 3, and Top 5 sellers using cumulative window functions.
-- 4. Filter to mature categories (> R$100,000 GMV) to surface genuine risks.
-- ==============================================================================

USE olist;

WITH seller_category_sales AS (
    SELECT
        COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category,
        oi.seller_id,
        SUM(oi.price) AS seller_category_revenue,
        COUNT(DISTINCT oi.order_id) AS seller_orders
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN category_translation ct ON ct.product_category_name = p.product_category_name
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY category, oi.seller_id
),
ranked_sellers AS (
    SELECT
        category,
        seller_id,
        seller_category_revenue,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY seller_category_revenue DESC) AS seller_rank,
        SUM(seller_category_revenue) OVER (PARTITION BY category) AS total_category_revenue,
        COUNT(seller_id) OVER (PARTITION BY category) AS total_sellers_in_category
    FROM seller_category_sales
)
SELECT
    category,
    total_sellers_in_category,
    ROUND(total_category_revenue, 2) AS category_gmv,
    ROUND(SUM(CASE WHEN seller_rank = 1 THEN seller_category_revenue ELSE 0 END), 2) AS top_1_seller_revenue,
    ROUND(SUM(CASE WHEN seller_rank <= 3 THEN seller_category_revenue ELSE 0 END), 2) AS top_3_sellers_revenue,
    ROUND(SUM(CASE WHEN seller_rank = 1 THEN seller_category_revenue ELSE 0 END) / total_category_revenue * 100, 2) AS top_1_share_pct,
    ROUND(SUM(CASE WHEN seller_rank <= 3 THEN seller_category_revenue ELSE 0 END) / total_category_revenue * 100, 2) AS top_3_share_pct,
    CASE
        WHEN (SUM(CASE WHEN seller_rank <= 3 THEN seller_category_revenue ELSE 0 END) / total_category_revenue) >= 0.50 THEN 'High Concentration Risk'
        WHEN (SUM(CASE WHEN seller_rank <= 3 THEN seller_category_revenue ELSE 0 END) / total_category_revenue) >= 0.30 THEN 'Moderate Concentration'
        ELSE 'Diversified / Healthy'
    END AS risk_tier
FROM ranked_sellers
GROUP BY category, total_category_revenue, total_sellers_in_category
HAVING total_category_revenue >= 100000
ORDER BY top_3_share_pct DESC;
