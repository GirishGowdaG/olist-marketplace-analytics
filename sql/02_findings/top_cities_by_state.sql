-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Finding 01 Practice: Top 3 cities by order volume per state
-- Business Question: Which cities drive order volume in each
--                    Brazilian state?
--
-- Why this matters: Identifies where Olist's customer base is
-- geographically concentrated — useful for logistics planning,
-- regional marketing spend, and delivery SLA prioritisation.
--
-- Key finding: SP (São Paulo state) is overwhelmingly dominant.
-- DF (Brasília) shows extreme city concentration — 2,131 orders
-- from the capital vs negligible volumes elsewhere in the state.
--
-- Concepts: ROW_NUMBER(), PARTITION BY, deterministic tiebreaker
-- Author: Brijesh Vaghela
-- ============================================================
USE olist;

WITH city_orders AS (
    SELECT
        c.customer_state,
        c.customer_city,
        COUNT(o.order_id) AS ord_counts
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_state, c.customer_city
),
ranked AS (
    SELECT
        customer_state,
        customer_city,
        ord_counts,
        ROW_NUMBER() OVER (
            PARTITION BY customer_state
            ORDER BY ord_counts DESC, customer_city ASC
        ) AS R_orders
    FROM city_orders
)
SELECT *
FROM ranked
WHERE R_orders <= 3
ORDER BY customer_state, R_orders;