"""
Robust CSV parser for Olist customer reviews.
Overcomes MySQL bulk-load parsing errors caused by embedded newlines and quotes.
"""

import logging
from pathlib import Path
import pandas as pd
from sqlalchemy import text
from python.src.db import DatabaseManager

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


def load_order_reviews(csv_path: str = "data/olist_order_reviews_dataset.csv"):
    path = Path(csv_path)
    if not path.exists():
        logger.error("Reviews CSV not found at: %s", path.resolve())
        return

    logger.info("Reading reviews CSV from %s...", path)
    df = pd.read_csv(
        path,
        dtype={
            "review_id": "string",
            "order_id": "string",
            "review_score": "int8",
            "review_comment_title": "string",
            "review_comment_message": "string",
        },
        parse_dates=["review_creation_date", "review_answer_timestamp"],
    )

    logger.info("Parsed %d review rows. Deduplicating composite keys...", len(df))
    df = df.drop_duplicates(subset=["review_id", "order_id"])

    db_mgr = DatabaseManager()
    with db_mgr.connect() as conn:
        logger.info("Truncating order_reviews table...")
        conn.execute(text("TRUNCATE TABLE order_reviews;"))
        conn.commit()

        logger.info("Streaming reviews to database in chunks...")
        df.to_sql(
            "order_reviews",
            con=conn,
            if_exists="append",
            index=False,
            chunksize=5000,
        )
        conn.commit()

    logger.info("Successfully loaded %d reviews into order_reviews.", len(df))


if __name__ == "__main__":
    load_order_reviews()
