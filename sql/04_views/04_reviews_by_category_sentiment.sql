-- ============================================================
-- View: reviews_by_category_sentiment
-- Purpose: Denormalized review text and sentiment joined with 
--          translated product category name.
-- Feeds:   Power BI "category_reviews" query
-- ============================================================

CREATE OR REPLACE VIEW reviews_by_category_sentiment AS
SELECT 
    ct.product_category_name_english AS category,
    r.review_score,
    r.review_comment_message AS review_text,
    s.sentiment_label
FROM order_reviews r
JOIN review_sentiment s 
    ON s.review_id = r.review_id
JOIN orders o 
    ON o.order_id = r.order_id
JOIN order_items oi 
    ON oi.order_id = o.order_id
JOIN products p 
    ON p.product_id = oi.product_id
JOIN category_translation ct 
    ON ct.product_category_name = p.product_category_name;
