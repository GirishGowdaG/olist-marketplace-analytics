"""
Sentiment scoring pipeline using BerTweet-PT (RoBERTa for Brazilian Portuguese).
Batched, idempotent upsert into MySQL table review_sentiment.
"""

import logging
from typing import List, Tuple
import pandas as pd
from sqlalchemy import text
from tqdm import tqdm
from pysentimiento import create_analyzer

from python.src.config import ModelConfig
from python.src.db import DatabaseManager

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


class SentimentAnalysisEngine:
    def __init__(self, config: ModelConfig = None):
        self.config = config or ModelConfig()
        logger.info("Initializing BerTweet-PT sentiment analyzer on %s...", self.config.device)
        self.analyzer = create_analyzer(task="sentiment", lang="pt")

    def analyze_batch(self, texts: List[str]) -> List[Tuple[str, float]]:
        # Map pysentimiento output to compact sentiment codes
        label_map = {"POS": "POS", "NEU": "NEU", "NEG": "NEG"}
        results = self.analyzer.predict(texts)
        if not isinstance(results, list):
            results = [results]

        output = []
        for res in results:
            lbl = label_map.get(res.output, "NEU")
            score = float(res.probas.get(res.output, 0.0))
            output.append((lbl, score))
        return output

    def run_pipeline(self, limit: int = None):
        db_mgr = DatabaseManager()
        query = """
            SELECT r.review_id, r.review_comment_message
            FROM order_reviews r
            LEFT JOIN review_sentiment s ON s.review_id = r.review_id
            WHERE r.review_comment_message IS NOT NULL
              AND TRIM(r.review_comment_message) != ''
              AND s.review_id IS NULL
        """
        if limit:
            query += f" LIMIT {limit}"

        logger.info("Querying un-scored customer reviews...")
        with db_mgr.connect() as conn:
            pending_df = pd.read_sql(query, conn)

        total_pending = len(pending_df)
        if total_pending == 0:
            logger.info("All reviews with comment text are already scored. Pipeline up to date.")
            return

        logger.info("Found %d pending reviews to score. Running batched inference...", total_pending)
        batch_size = self.config.batch_size

        upsert_sql = text("""
            INSERT INTO review_sentiment (review_id, sentiment_label, sentiment_score)
            VALUES (:review_id, :sentiment_label, :sentiment_score)
            ON DUPLICATE KEY UPDATE
                sentiment_label = VALUES(sentiment_label),
                sentiment_score = VALUES(sentiment_score);
        """)

        for i in tqdm(range(0, total_pending, batch_size), desc="Sentiment Scoring"):
            chunk = pending_df.iloc[i : i + batch_size]
            review_ids = chunk["review_id"].tolist()
            texts_list = chunk["review_comment_message"].astype(str).tolist()

            preds = self.analyze_batch(texts_list)
            records = [
                {
                    "review_id": r_id,
                    "sentiment_label": p[0],
                    "sentiment_score": round(p[1], 4),
                }
                for r_id, p in zip(review_ids, preds)
            ]

            with db_mgr.connect() as conn:
                conn.execute(upsert_sql, records)
                conn.commit()

        logger.info("Sentiment pipeline execution complete.")


if __name__ == "__main__":
    engine = SentimentAnalysisEngine()
    engine.run_pipeline()
