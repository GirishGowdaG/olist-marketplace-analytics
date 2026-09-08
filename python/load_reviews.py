"""
load_reviews.py
---------------
Loads olist_order_reviews_dataset.csv into the MySQL `order_reviews` table.

Why not LOAD DATA INFILE?
The review_comment_message field contains embedded newlines and imperfectly
escaped quotes. MySQL's line parser fails at row 77,917. pandas handles
multi-line quoted fields natively, so we use it as the loader here.

Usage (PowerShell):
    $env:OLIST_DB_PASSWORD = "your_password"   # required
    $env:OLIST_DB_USER     = "root"            # optional, defaults to root
    python python/load_reviews.py

Usage (bash/zsh):
    export OLIST_DB_PASSWORD="your_password"
    python python/load_reviews.py

Note: env var names are consistent across all three scripts in this project
(load_reviews.py, sentiment_analysis.py, reason_analysis_v2.py).
"""

import os
from urllib.parse import quote_plus
import pandas as pd
from sqlalchemy import create_engine
from pathlib import Path

# --- DB connection — credentials from environment variables ---
# Naming convention: OLIST_DB_* matches sentiment_analysis.py and reason_analysis_v2.py
DB_USER = os.environ.get("OLIST_DB_USER", "root")
DB_PASS = os.environ.get("OLIST_DB_PASSWORD", "")
DB_HOST = os.environ.get("OLIST_DB_HOST", "127.0.0.1")
DB_PORT = os.environ.get("OLIST_DB_PORT", "3306")
DB_NAME = os.environ.get("OLIST_DB_NAME", "olist")

engine = create_engine(
    f"mysql+pymysql://{DB_USER}:{quote_plus(DB_PASS)}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# --- locate CSV relative to this script ---
BASE_DIR = Path(__file__).resolve().parent.parent
CSV = BASE_DIR / "data" / "olist_order_reviews_dataset.csv"

# --- load ---
df = pd.read_csv(CSV)

# Validate before touching the database. Note this can't be a raw
# newline count against the source file -- the whole reason this
# script exists is that review text contains embedded newlines, so a
# naive line count would overcount rows and always "fail". Instead,
# validate against the documented dataset size (see data/README.md):
# 99,224 reviews. A large gap here means the CSV changed or pandas
# silently dropped malformed rows -- either way, worth stopping for.
EXPECTED_ROWS = 99_224
pct_diff = abs(len(df) - EXPECTED_ROWS) / EXPECTED_ROWS * 100
assert pct_diff < 1, (
    f"Row count mismatch: pandas parsed {len(df):,} rows, expected "
    f"~{EXPECTED_ROWS:,} (±1%) per data/README.md. Off by {pct_diff:.1f}% "
    f"-- stopping, since every sentiment/reason finding depends on this table."
)

# empty strings / NaN -> None so MySQL stores NULL
df = df.where(pd.notnull(df), None)

# append into the existing (empty) table; if_exists="append" does not recreate it
df.to_sql("order_reviews", engine, if_exists="append", index=False, chunksize=5000)

print(f"Loaded {len(df):,} review rows into `order_reviews` "
      f"(validated against expected ~{EXPECTED_ROWS:,})")