-- ==============================================================================
-- View 03: Category Sentiment & Quality Intelligence View
-- Powers: Customer Voice & Recommendations Dashboard Page
-- Maps customer sentiment classification and star scores to translated product
-- categories for cross-functional root-cause analysis.
-- ==============================================================================

USE olist;

CREATE OR REPLACE VIEW view_category_sentiment_breakdown AS
SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name, 'Other') AS product_category,
    s.sentiment_label,
    r.review_score,
    COUNT(DISTINCT r.review_id) AS total_reviews,
    ROUND(AVG(s.sentiment_score), 3) AS avg_model_confidence
FROM order_reviews r
JOIN review_sentiment s ON s.review_id = r.review_id
JOIN orders o ON o.order_id = r.order_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
LEFT JOIN category_translation ct ON ct.product_category_name = p.product_category_name
GROUP BY product_category, s.sentiment_label, r.review_score;
