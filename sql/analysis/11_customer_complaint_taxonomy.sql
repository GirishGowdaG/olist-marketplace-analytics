-- ==============================================================================
-- Query 11: Voice of Customer Reason Taxonomy Breakdown
-- Business Problem: Beyond broad positive/negative sentiment, what specific issues
-- do customers mention in free-text Brazilian Portuguese reviews?
--
-- Approach:
-- 1. Read from the classification summary table populated by our NLP rule engine.
-- 2. Analyze the distribution of specific customer feedback drivers across
--    negative, neutral, and positive reviews.
-- 3. Calculate the relative share of each reason within its sentiment class.
-- ==============================================================================

USE olist;

SELECT
    sentiment_label,
    reason AS customer_feedback_reason,
    review_count,
    pct_of_sentiment AS relative_share_pct
FROM review_reason_summary
ORDER BY
    CASE sentiment_label
        WHEN 'NEG' THEN 1
        WHEN 'NEU' THEN 2
        WHEN 'POS' THEN 3
        ELSE 4
    END,
    review_count DESC;
