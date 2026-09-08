"""
Olist Review Sentiment - Portuguese NLP pipeline (end-to-end, idempotent).

Reads Brazilian-Portuguese review text from the local MySQL `olist` database,
scores each review with a Portuguese sentiment model, and writes the results
to a new `review_sentiment` table. It is built to surface the most interesting
stories in the data: 5-star ratings written in angry language, and 1-star
ratings written in happy language (sentiment-vs-rating divergence).

MODEL
-----
pysentimiento PT  ->  `pysentimiento/bertweet-pt-sentiment`
A RoBERTa model trained on Brazilian Portuguese. It reads the review TEXT only,
independently of the 1-5 star score -- that independence is exactly what makes
the divergence analysis meaningful (a star-predicting model would be circular).

WHY THIS DESIGN
---------------
* Credentials come from environment variables  -> nothing secret hits GitHub.
* The run is RESUMABLE: already-scored reviews are skipped, so a crash midway
  costs nothing. Writes are an idempotent UPSERT, so a full re-run overwrites
  cleanly instead of creating duplicates.
* Inference is batched with a live tqdm progress bar + ETA (CPU-friendly).

CAVEATS (documented in the README too)
--------------------------------------
* Score-only reviews (no comment text) are EXCLUDED from text sentiment.
* Domain shift: the model learned on tweets; reviews are a different register
  -> the model's confidence is stored so low-certainty labels can be filtered.
* Portuguese nuance: sarcasm and negation ("nao gostei") trip up any model.

USAGE (PowerShell, current session)
-----------------------------------
    $env:OLIST_DB_PASSWORD = "your_password"   # required
    $env:OLIST_DB_USER     = "root"            # optional, defaults to root
    python python/sentiment_analysis.py
"""

import os
import sys
from datetime import datetime
from getpass import getpass
from urllib.parse import quote_plus

import pandas as pd
from sqlalchemy import create_engine, text
from tqdm import tqdm
from pysentimiento import create_analyzer

# print accented Portuguese safely in the Windows console
sys.stdout.reconfigure(encoding="utf-8")

# --- Config ----------------------------------------------------------------
MODEL_NAME = "pysentimiento/bertweet-pt-sentiment"
CHUNK_SIZE = 128          # reviews per progress step / DB commit (tune freely)
LABEL_MAP  = {"POS": "positive", "NEU": "neutral", "NEG": "negative"}
RUN_TS     = datetime.now()   # one timestamp for the whole run

# --- 1. Database connection ------------------------------------------------
#     Password is read from an env var; if missing, you are prompted securely.
DB_USER = os.getenv("OLIST_DB_USER", "root")
DB_PASS = os.getenv("OLIST_DB_PASSWORD") or getpass("MySQL password for 'olist': ")
engine = create_engine(
    f"mysql+pymysql://{DB_USER}:{quote_plus(DB_PASS)}@127.0.0.1:3306/olist"
)

# --- 2. Ensure the target table exists (idempotent) ------------------------
DDL = """
CREATE TABLE IF NOT EXISTS review_sentiment (
    review_id       VARCHAR(50)  NOT NULL PRIMARY KEY,
    order_id        VARCHAR(50)  NOT NULL,
    sentiment_label VARCHAR(10)  NOT NULL,   -- positive / neutral / negative
    sentiment_score DECIMAL(5,4) NOT NULL,   -- model confidence in that label (0-1)
    model_name      VARCHAR(80)  NOT NULL,
    scored_at       DATETIME     NOT NULL,
    INDEX idx_order (order_id),
    INDEX idx_label (sentiment_label)
)
"""
with engine.begin() as conn:
    conn.execute(text(DDL))

# --- 3. Pull reviews and report text coverage ------------------------------
PULL = text("""
    SELECT review_id,
           order_id,
           review_score,
           COALESCE(review_comment_title,   '') AS title,
           COALESCE(review_comment_message, '') AS message
    FROM order_reviews
""")
with engine.connect() as conn:
    reviews = pd.read_sql(PULL, conn)

def combine_text(row):
    """Join title + message, keeping only the parts that actually have text."""
    parts = [p.strip() for p in (row["title"], row["message"]) if p and p.strip()]
    return ". ".join(parts)

reviews["comment_text"] = reviews.apply(combine_text, axis=1)
text_reviews = reviews[reviews["comment_text"].str.len() > 0].copy()

total, with_text = len(reviews), len(text_reviews)
print("-" * 64)
print("OLIST REVIEW TEXT COVERAGE")
print("-" * 64)
print(f"Total reviews ............ {total:,}")
print(f"With comment text ........ {with_text:,}  ({with_text / total * 100:.1f}%)")
print(f"Score-only (no text) ..... {total - with_text:,}  -> excluded from sentiment")
print("-" * 64)

# --- 4. Resumability: skip reviews already scored --------------------------
with engine.connect() as conn:
    done = pd.read_sql(text("SELECT review_id FROM review_sentiment"), conn)
done_ids = set(done["review_id"])

pending = text_reviews[~text_reviews["review_id"].isin(done_ids)]
print(f"Already scored ........... {len(done_ids):,}")
print(f"To score this run ........ {len(pending):,}")

# --- 5. Score pending reviews in batches, upsert per chunk -----------------
#     The `AS new` row alias is MySQL 8.0.19+ syntax for ON DUPLICATE KEY.
UPSERT = text("""
    INSERT INTO review_sentiment
        (review_id, order_id, sentiment_label, sentiment_score, model_name, scored_at)
    VALUES
        (:review_id, :order_id, :sentiment_label, :sentiment_score, :model_name, :scored_at)
        AS new
    ON DUPLICATE KEY UPDATE
        sentiment_label = new.sentiment_label,
        sentiment_score = new.sentiment_score,
        model_name      = new.model_name,
        scored_at       = new.scored_at
""")

if len(pending):
    print(f"\nLoading model: {MODEL_NAME}  (cached after the first download)")
    analyzer = create_analyzer(task="sentiment", lang="pt")

    rows = pending.to_dict("records")
    with engine.connect() as conn:
        with tqdm(total=len(rows), desc="Scoring reviews", unit="rev") as pbar:
            for i in range(0, len(rows), CHUNK_SIZE):
                chunk = rows[i:i + CHUNK_SIZE]

                # batched inference -> list of predictions, one per review
                preds = analyzer.predict([r["comment_text"] for r in chunk])

                records = []
                for r, out in zip(chunk, preds):
                    label = LABEL_MAP.get(str(out.output), str(out.output).lower())
                    conf  = float(max(out.probas.values()))   # prob. of the chosen label
                    records.append({
                        "review_id":       r["review_id"],
                        "order_id":        r["order_id"],
                        "sentiment_label": label,
                        "sentiment_score": round(conf, 4),
                        "model_name":      MODEL_NAME,
                        "scored_at":       RUN_TS,
                    })

                conn.execute(UPSERT, records)
                conn.commit()                 # commit per chunk -> crash-safe / resumable
                pbar.update(len(chunk))
    print("Scoring complete.")
else:
    print("\nNothing to score - every text review is already in review_sentiment.")

# --- 6. Validation summary (the real numbers for your README) --------------
with engine.connect() as conn:
    dist = pd.read_sql(text("""
        SELECT sentiment_label, COUNT(*) AS n
        FROM review_sentiment
        GROUP BY sentiment_label
    """), conn)

    div = conn.execute(text("""
        SELECT
            SUM(r.review_score = 5 AND s.sentiment_label = 'negative') AS five_star_negative,
            SUM(r.review_score = 1 AND s.sentiment_label = 'positive') AS one_star_positive
        FROM review_sentiment s
        JOIN order_reviews r ON r.review_id = s.review_id
    """)).one()

scored_total = int(dist["n"].sum()) if len(dist) else 0

print("\n" + "=" * 64)
print("SENTIMENT DISTRIBUTION")
print("=" * 64)
for _, row in dist.iterrows():
    share = row["n"] / scored_total * 100 if scored_total else 0
    print(f"  {row['sentiment_label']:<9} {int(row['n']):>7,}  ({share:4.1f}%)")
print("-" * 64)
print("DIVERGENCE (the most interesting stories)")
print(f"  5-star rating but NEGATIVE text .... {int(div.five_star_negative or 0):>6,}")
print(f"  1-star rating but POSITIVE text .... {int(div.one_star_positive or 0):>6,}")
print("=" * 64)
print("\nDone. Drop these numbers into the README sentiment section.")