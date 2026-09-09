# python — Production NLP & Sentiment Pipeline

## Overview

The `python/` directory contains an end-to-end natural language processing pipeline designed to ingest, score, and categorize 42,370 free-text Brazilian Portuguese customer reviews from the Olist marketplace dataset.

Refactored into a modular architecture under `python/src/`, the pipeline separates configuration, database connectivity, model inference, and rule-based reason classification into distinct, testable components.

```
python/
├── src/
│   ├── config.py              ← Environment variables & configuration dataclasses
│   ├── db.py                  ← SQLAlchemy connection pooling & manager
│   ├── review_loader.py       ← Multi-line quoted CSV ingestion into MySQL
│   ├── sentiment_engine.py    ← Batched BerTweet-PT sentiment scoring & upsert
│   └── reason_classifier.py   ← Negation-aware Portuguese complaint classifier
├── main.py                    ← Unified CLI entry point
└── requirements.txt           ← Pinned pipeline dependencies
```

---

## Architecture & Components

### 1. Robust Review Ingestion (`review_loader.py`)
- **The Problem**: Standard SQL `LOAD DATA INFILE` statements fail on row 77,917 of `olist_order_reviews_dataset.csv` due to embedded newlines and unescaped double quotes in customer feedback text.
- **The Solution**: Python's `pandas` engine reads quoted text blocks accurately, handles timestamp conversions, deduplicates composite primary keys `(review_id, order_id)`, and streams clean records into MySQL using chunked inserts.

### 2. Deep Learning Sentiment Engine (`sentiment_engine.py`)
- **Model**: `pysentimiento/bertweet-pt-sentiment` — a RoBERTa language model pretrained on Brazilian Portuguese text.
- **Coverage**: Evaluates all 42,370 reviews containing written commentary.
- **Design Rationale**:
  - Scores text independently of the numerical 1–5 star rating, allowing the platform to identify diverging reviews (e.g., 5-star ratings where the written text expresses frustration, or 1-star ratings where the complaint is purely carrier-related).
  - Uses batched inference (64 records per pass) with checkpointing and idempotent SQL `ON DUPLICATE KEY UPDATE` upserts to ensure crash resilience during execution.

### 3. Multi-Label Reason Classifier (`reason_classifier.py`)
- **The Problem**: Pretrained sentiment models indicate *how* a customer feels (positive, neutral, negative), but do not identify *what* operational issue occurred.
- **The Solution**: A rule-based pattern matcher that maps normalized Brazilian Portuguese text to specific business root causes:
  - `Late or Delayed Delivery`
  - `Damaged or Defective Item`
  - `Wrong or Incomplete Product`
  - `Poor Quality / Not as Described`
  - `Refund or Order Cancellation`
  - `Fast & Early Delivery`
  - `Satisfied / As Described`
  - `Delighted / Strong Recommendation`
- **Negation Handling**: A 3-token backward lookback window detects Portuguese negators (`não`, `nem`, `nunca`, `jamais`). For example, praise terms following a negator (*"não recomendo"*) are prevented from triggering false positive praise tags.

---

## Execution Guide

### 1. Installation

```powershell
# Step 1: Install PyTorch CPU build (hosted outside PyPI)
pip install torch --index-url https://download.pytorch.org/whl/cpu

# Step 2: Install remaining dependencies
pip install -r python/requirements.txt
```

### 2. Environment Variables

```powershell
$env:OLIST_DB_USER     = "root"
$env:OLIST_DB_PASSWORD = "your_password"
$env:OLIST_DB_HOST     = "127.0.0.1"
$env:OLIST_DB_PORT     = "3306"
$env:OLIST_DB_NAME     = "olist"
```

### 3. Running the Pipeline

```powershell
# Run the complete pipeline
python -m python.main --task all

# Or run individual stages:
python -m python.main --task load_reviews
python -m python.main --task sentiment
python -m python.main --task reason
```

---

*Author: Girish G Gowda | [GitHub](https://github.com/GirishGowdaG)*
