# data — Dataset

The raw CSV files are not tracked in this repository (they exceed GitHub's file size recommendations and are freely available from Kaggle). This folder exists locally but is gitignored.

---

## How to Get the Data

1. Go to: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
2. Click **Download** (requires a free Kaggle account)
3. Extract the ZIP into this `data/` folder

You should end up with these files:

```
data/
├── olist_customers_dataset.csv
├── olist_geolocation_dataset.csv
├── olist_order_items_dataset.csv
├── olist_order_payments_dataset.csv
├── olist_order_reviews_dataset.csv       ← loaded by python/load_reviews.py
├── olist_orders_dataset.csv
├── olist_products_dataset.csv
├── olist_sellers_dataset.csv
└── product_category_name_translation.csv
```

---

## Dataset Overview

| Table Loaded From | Rows | Key Columns |
|---|---|---|
| `olist_orders_dataset.csv` | 99,441 | order_id, customer_id, order_status, 5 timestamps |
| `olist_order_items_dataset.csv` | 112,650 | order_id, seller_id, product_id, price, freight_value |
| `olist_order_payments_dataset.csv` | 103,886 | order_id, payment_type, payment_installments, payment_value |
| `olist_order_reviews_dataset.csv` | 99,224 | review_id, order_id, review_score, review_comment_message |
| `olist_customers_dataset.csv` | 99,441 | customer_id, customer_unique_id, customer_city, customer_state |
| `olist_products_dataset.csv` | 32,951 | product_id, product_category_name, physical dimensions |
| `olist_sellers_dataset.csv` | 3,095 | seller_id, seller_city, seller_state |
| `product_category_name_translation.csv` | 71 | Portuguese → English category names |
| `olist_geolocation_dataset.csv` | 1M+ | Zip code → lat/lng (not used in this project) |

**Total loaded:** ~530,000 rows across 8 tables (geolocation excluded)
**Time period:** September 2016 – September 2018
**Geography:** 27 Brazilian states

---

## Known Data Quality Issues

These are documented fully in the main `README.md` but summarised here for reference:

1. **`olist_order_reviews_dataset.csv`** — contains embedded newlines in review text. `LOAD DATA INFILE` fails at row 77,917. This file must be loaded using `python/load_reviews.py` (pandas).
2. **`product_category_name_translation.csv`** — Windows CRLF line endings leave `\r` on every English category name, silently breaking all JOINs on that column. Fixed with `UPDATE ... SET ... = REPLACE(column, '\r', '')` after loading.
3. **`customer_unique_id` vs `customer_id`** — Olist assigns a new `customer_id` per order. One real customer can appear with multiple IDs. Always use `customer_unique_id` for person-level analysis (cohorts, retention, streaks).

---

*Author: Brijesh Vaghela | [LinkedIn](https://www.linkedin.com/in/brijesh-vaghela)*
