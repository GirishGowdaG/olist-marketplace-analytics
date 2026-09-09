# data — Olist Brazilian E-Commerce Dataset

## Overview

This project utilizes the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), released under the CC BY-NC-SA 4.0 license.

The dataset encompasses 99,441 actual commercial orders made at Olist between September 2016 and September 2018 across all 27 Brazilian states.

> [!NOTE]
> Raw CSV files and downloaded archives are excluded from Git tracking via `.gitignore` to maintain repository performance and avoid duplicating publicly accessible data files.

---

## Dataset Schema & Contents

| CSV Filename | Database Table | Row Count | Description |
|---|---|---|---|
| `olist_orders_dataset.csv` | `orders` | 99,441 | Order spine: status and timestamps (purchase, approved, carrier, delivered, estimated). |
| `olist_order_items_dataset.csv` | `order_items` | 112,650 | Order line items: product ID, seller ID, item price, and freight value. |
| `olist_order_payments_dataset.csv` | `order_payments` | 103,886 | Transaction records: payment type (credit card, boleto, voucher, debit), installments, and value. |
| `olist_order_reviews_dataset.csv` | `order_reviews` | 99,224 | Customer feedback: 1–5 star scores and Portuguese comment text (42,370 with text). |
| `olist_customers_dataset.csv` | `customers` | 99,441 | Customer geographic data (city, state, zip prefix) and true unique identifier (`customer_unique_id`). |
| `olist_sellers_dataset.csv` | `sellers` | 3,095 | Seller geographic data (city, state, zip prefix). |
| `olist_products_dataset.csv` | `products` | 32,951 | Product catalog: categories, name/description length, photos, and physical dimensions (weight, dimensions). |
| `product_category_name_translation.csv` | `category_translation` | 71 | Mapping dictionary from Brazilian Portuguese category names to English. |

---

## Data Download & Reproduction Instructions

1. Download the archive from Kaggle:  
   [https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
2. Extract the CSV files directly into the `data/` directory.
3. Verify that the files match the expected names listed above.
4. Execute `sql/schema/01_create_schema.sql` and `sql/schema/02_load_data.sql` in MySQL.
5. Ingest customer reviews via Python using `python -m python.main --task load_reviews`.

---

## Data Quality Highlights

1. **Embedded Newlines in Review Text**: The customer reviews file contains Brazilian Portuguese free text with raw line breaks and quotation characters. A custom CSV ingestion script (`python/src/review_loader.py`) parses multi-line records cleanly.
2. **Carriage Returns in Translations**: Windows CRLF line terminations in `product_category_name_translation.csv` leave trailing `\r` characters on category names. The schema ingestion script strips these characters using `REPLACE(..., '\r', '')` to preserve join integrity.
3. **Unique Customer Identification**: Olist issues a new `customer_id` for every transaction. Evaluating customer repurchase rates and retention requires grouping by `customer_unique_id`, which tracks the actual individual consumer over time.

---

*Author: Girish G Gowda | [GitHub](https://github.com/GirishGowdaG)*
