-- ============================================================================
-- review_sentiment : Portuguese sentiment labels for Olist reviews with text.
--
-- Populated by python/sentiment_analysis.py using the pysentimiento PT model
-- (pysentimiento/bertweet-pt-sentiment). One row per review that contains
-- comment text; score-only reviews are intentionally absent.
--
-- review_id is the PRIMARY KEY, so the loader's INSERT ... ON DUPLICATE KEY
-- UPDATE makes re-runs idempotent -- no duplicates, safe to re-run.
-- Run this once, or just run the Python script (it self-creates the table).
-- ============================================================================

CREATE TABLE IF NOT EXISTS review_sentiment (
    review_id       VARCHAR(50)  NOT NULL PRIMARY KEY,
    order_id        VARCHAR(50)  NOT NULL,
    sentiment_label VARCHAR(10)  NOT NULL,   -- positive / neutral / negative
    sentiment_score DECIMAL(5,4) NOT NULL,   -- model confidence in the label (0-1)
    model_name      VARCHAR(80)  NOT NULL,   -- provenance: which model produced this
    scored_at       DATETIME     NOT NULL,   -- when this run scored the review
    INDEX idx_order (order_id),
    INDEX idx_label (sentiment_label)
);