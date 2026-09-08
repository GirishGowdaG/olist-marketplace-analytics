# python — NLP Pipeline

Three scripts that form a sequential NLP pipeline: load review text into MySQL, score it with a Portuguese sentiment model, then classify the *reasons* behind each sentiment using a custom negation-aware rule classifier.

The interesting engineering decisions are in `sentiment_analysis.py` (resumable UPSERT pattern so a 4-hour inference run can survive a crash) and `reason_analysis_v2.py` (why a custom negation-aware classifier beats a pre-trained model for this specific use case).

---

## Scripts

| Script | What It Does | Run Order |
|---|---|---|
| `load_reviews.py` | Loads `olist_order_reviews_dataset.csv` into MySQL using pandas (bypasses `LOAD DATA INFILE` which fails on embedded newlines in review text) | 1st |
| `sentiment_analysis.py` | Scores 42,370 Portuguese review texts using BerTweet-PT (`pysentimiento/bertweet-pt-sentiment`) — batched, resumable, writes to `review_sentiment` via idempotent UPSERT | 2nd |
| `reason_analysis_v2.py` | Multi-label, negation-aware reason classifier — maps each review to concrete business reasons (late delivery, damaged item, fast delivery, etc.) using Portuguese phrase patterns | 3rd |
| `requirements.txt` | Pinned dependencies for the pipeline | Install before running |

---

## Installation

```powershell
# Step 1 — PyTorch CPU build (must be done FIRST, separate URL)
pip install torch --index-url https://download.pytorch.org/whl/cpu

# Step 2 — Everything else
pip install -r python/requirements.txt
```

**Why torch is not in requirements.txt:** PyTorch's CPU build is hosted at `https://download.pytorch.org/whl/cpu`, not on PyPI. Including it in requirements.txt alongside PyPI packages causes pip's dependency resolver to fail the entire install. It must be installed separately.

---

## Environment Variables

All three scripts use the same naming convention:

```powershell
# PowerShell
$env:OLIST_DB_PASSWORD = "your_mysql_password"   # required
$env:OLIST_DB_USER     = "root"                  # optional, defaults to root
$env:OLIST_DB_HOST     = "127.0.0.1"             # optional
$env:OLIST_DB_PORT     = "3306"                  # optional
$env:OLIST_DB_NAME     = "olist"                 # optional
```

```bash
# bash/zsh
export OLIST_DB_PASSWORD="your_mysql_password"
```

Credentials are never hardcoded. Nothing sensitive hits the repository.

---

## Pipeline Walkthrough

### 1. `load_reviews.py`

**The problem:** `LOAD DATA INFILE` (used for the other 7 tables) fails at row 77,917 of the reviews CSV. Brazilian Portuguese review text contains embedded newlines and imperfectly escaped quotation marks — MySQL's line parser treats embedded newlines as row terminators and corrupts every subsequent row.

**The fix:** pandas `read_csv()` handles multi-line quoted fields correctly by default. The script reads the CSV, converts NaN to None (so MySQL stores NULL rather than the string "nan"), and loads in chunks of 5,000 rows via `DataFrame.to_sql()`.

This is the type of data quality issue that doesn't exist in tutorial datasets but appears constantly in production pipelines.

### 2. `sentiment_analysis.py`

**Model:** `pysentimiento/bertweet-pt-sentiment` — a RoBERTa fine-tuned on Brazilian Portuguese. It reads review *text* independently of the star rating, which is what makes the divergence finding meaningful: a model that predicted from stars would be circular.

**Key design features:**

- **Resumable:** On startup the script reads all `review_id` values already in `review_sentiment` and skips them. If a 4-hour inference run crashes after 30,000 reviews, rerunning it costs ~30 minutes, not 4 hours.
- **Idempotent UPSERT:** Writes use `INSERT ... ON DUPLICATE KEY UPDATE` — a full re-run overwrites cleanly instead of creating duplicate rows.
- **Batched inference:** Reviews are scored in chunks of 128 with a tqdm progress bar showing real-time ETA.
- **Confidence stored:** `sentiment_score` stores the model's probability for the predicted class (0.0–1.0). Low-confidence predictions can be filtered downstream.

**Coverage:** 42,370 of 99,224 reviews contain comment text and are scored. 56,854 score-only reviews are correctly excluded.

**Key finding unlocked by this script:** 435 reviews where sentiment and star rating disagree — 328 five-star reviews that read as negative text, 107 one-star reviews that read as positive.

### 3. `reason_analysis_v2.py`

**Why a custom classifier and not a pre-trained model?**
Initial word-frequency analysis on negative reviews surfaced only generic emotion words: "terrible", "horrible", "bad". These have no business value — you can't action "terrible". The goal was actionable business reasons: late delivery, damaged item, refund request, fast delivery, product quality. No pre-trained Portuguese classifier maps to these specific marketplace categories.

**Negation handling — the key accuracy improvement over v1:**
A naive keyword match counts *"não recomendo"* ("I do NOT recommend") as praise because it contains "recomendo" (recommend). v1 had this bug. v2 checks the 3 words *before* any praise trigger for a negator (`não`, `nem`, `nunca`, `jamais`) and discards the match if negated.

Impact of negation handling:
- Caught **326 negated-praise reviews** that v1 miscounted as positive
- Corrected "late delivery in positive reviews" from 5,412 → 454 (the remainder are genuine "arrived a bit late but I loved it" mixed reviews — honest multi-label behaviour)

**Multi-label output:** A review can match multiple reasons. Percentages are "share of that sentiment's reviews mentioning the reason" and can exceed 100% in aggregate.

**Key finding unlocked by this script:** 33.3% of negative reviews cite late or non-delivery — the single largest negative reason category, confirming the delivery finding from the SQL layer and the star-rating penalty from the sentiment model.

---

## Output Tables

| Table | Populated By | Used In |
|---|---|---|
| `order_reviews` | `load_reviews.py` | All SQL findings involving review scores |
| `review_sentiment` | `sentiment_analysis.py` | Sentiment Analysis and Sentiment Trends dashboard pages |
| `review_reason_summary` | `reason_analysis_v2.py` | Voice of Customer dashboard page |

---

## Known Caveats

- **Domain shift:** BerTweet-PT was trained on tweets; product reviews are a different register (longer, more formal, less slang). Low-confidence scores (`sentiment_score < 0.70`) should be treated with caution.
- **Sarcasm:** Portuguese sarcasm (*"que maravilha, chegou destruído"* — "how wonderful, it arrived destroyed") is not reliably detected by the model or the rule classifier.
- **`iterrows()` in `reason_analysis_v2.py`:** The reason classifier uses `df.iterrows()` for row-level text processing. At 42K rows this runs in under a minute — acceptable. In a production pipeline over millions of rows, this would be replaced with `df["msg"].apply()` or vectorised string operations.

---

*Author: Brijesh Vaghela | [LinkedIn](https://www.linkedin.com/in/brijesh-vaghela)*
