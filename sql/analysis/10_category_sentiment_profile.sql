-- ==============================================================================
-- Query 10: Portuguese Review Sentiment & Category Satisfaction Profile
-- Business Problem: How does NLP-derived sentiment distribute across product
-- verticals? Are certain categories inherently prone to negative sentiment due
-- to high return friction or complex assembly (e.g., furniture, electronics)?
--
-- Approach:
-- 1. Join review sentiment labels (positive, neutral, negative) from the BerTweet-PT
--    model with order items, products, and translated categories.
-- 2. Aggregate sentiment volume, positive ratio, negative ratio, and average review score.
-- 3. Filter to major categories (> 300 text-reviewed items) to evaluate category health.
-- ==============================================================================

USE olist;

WITH category_review_sentiment AS (
    SELECT
        COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category,
        s.sentiment_label,
        s.sentiment_score,
        r.review_score
    FROM order_reviews r
    JOIN review_sentiment s ON s.review_id = r.review_id
    JOIN orders o ON o.order_id = r.order_id
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN category_translation ct ON ct.product_category_name = p.product_category_name
)
SELECT
    category,
    COUNT(*) AS total_scored_reviews,
    SUM(CASE WHEN sentiment_label = 'POS' THEN 1 ELSE 0 END) AS positive_reviews,
    SUM(CASE WHEN sentiment_label = 'NEU' THEN 1 ELSE 0 END) AS neutral_reviews,
    SUM(CASE WHEN sentiment_label = 'NEG' THEN 1 ELSE 0 END) AS negative_reviews,
    ROUND(SUM(CASE WHEN sentiment_label = 'POS' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS positive_share_pct,
    ROUND(SUM(CASE WHEN sentiment_label = 'NEG' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS negative_share_pct,
    ROUND(AVG(review_score), 2) AS avg_star_score,
    ROUND(AVG(sentiment_score), 3) AS avg_model_confidence
FROM category_review_sentiment
GROUP BY category
HAVING total_scored_reviews >= 300
ORDER BY negative_share_pct DESC;
