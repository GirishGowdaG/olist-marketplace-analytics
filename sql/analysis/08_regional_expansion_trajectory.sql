-- ==============================================================================
-- Query 08: Regional Marketplace GMV Trajectory & Expansion
-- Business Problem: How did Olist evolve geographically from 2016 through 2018?
-- Did marketplace growth remain concentrated in São Paulo (SP) and the Southeast,
-- or did inter-state expansion successfully capture share across peripheral states?
--
-- Approach:
-- 1. Truncate order purchase timestamp to quarterly cohorts.
-- 2. Partition revenue into São Paulo (State origin/dominant hub), Rest of Southeast,
--    and Regional Expansion States (South, Northeast, Central-West, North).
-- 3. Calculate quarterly GMV growth and regional mix evolution.
-- ==============================================================================

USE olist;

WITH quarterly_regional_sales AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-Q%q') AS purchase_quarter,
        CASE
            WHEN c.customer_state = 'SP' THEN '1. São Paulo (Core Hub)'
            WHEN c.customer_state IN ('RJ', 'MG', 'ES') THEN '2. Other Southeast'
            WHEN c.customer_state IN ('PR', 'SC', 'RS') THEN '3. South'
            WHEN c.customer_state IN ('BA', 'PE', 'CE', 'MA', 'PB', 'RN', 'AL', 'SE', 'PI') THEN '4. Northeast'
            ELSE '5. Central-West & North'
        END AS geographic_zone,
        oi.price
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
)
SELECT
    purchase_quarter,
    COUNT(*) AS total_items_sold,
    ROUND(SUM(price), 2) AS total_quarterly_gmv,
    ROUND(SUM(CASE WHEN geographic_zone = '1. São Paulo (Core Hub)' THEN price ELSE 0 END), 2) AS sp_gmv,
    ROUND(SUM(CASE WHEN geographic_zone = '1. São Paulo (Core Hub)' THEN price ELSE 0 END) * 100.0 / SUM(price), 1) AS sp_share_pct,
    ROUND(SUM(CASE WHEN geographic_zone = '2. Other Southeast' THEN price ELSE 0 END) * 100.0 / SUM(price), 1) AS other_southeast_share_pct,
    ROUND(SUM(CASE WHEN geographic_zone = '3. South' THEN price ELSE 0 END) * 100.0 / SUM(price), 1) AS south_share_pct,
    ROUND(SUM(CASE WHEN geographic_zone = '4. Northeast' THEN price ELSE 0 END) * 100.0 / SUM(price), 1) AS northeast_share_pct,
    ROUND(SUM(CASE WHEN geographic_zone = '5. Central-West & North' THEN price ELSE 0 END) * 100.0 / SUM(price), 1) AS cw_north_share_pct
FROM quarterly_regional_sales
GROUP BY purchase_quarter
ORDER BY purchase_quarter;
