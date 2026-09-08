# sql/01_setup — Schema Design & Data Loading

Two scripts that build and populate the entire `olist` database from scratch. Run these first, in order, before any analytical queries.

---

## Files

| File | What It Does |
|---|---|
| `01_create_tables.sql` | Creates the `olist` database, drops and recreates all 8 tables with primary keys, foreign keys, and performance indexes |
| `02_load_data.sql` | Bulk-loads 7 of the 8 tables using `LOAD DATA INFILE`; the reviews table is loaded separately via `python/load_reviews.py` |

---

## Schema Overview

```
customers ──────────────────────────────────────────────┐
    customer_id (PK)                                     │
    customer_unique_id  ← true person ID for cohorts     │
    customer_state                                        │
                                                         ▼
sellers                          orders ──────── order_items ──────── products
    seller_id (PK)                   order_id (PK)    (PK: order_id,      product_id (PK)
    seller_state                     customer_id (FK) order_item_id)      product_category_name
                                     order_status     seller_id (FK)
                                     5× timestamps    price
                                                      freight_value
                                         │
                             ┌───────────┴───────────┐
                             ▼                       ▼
                     order_payments          order_reviews
                         order_id (FK)           (PK: review_id, order_id)
                         payment_type            review_score
                         payment_value           review_comment_message
                         installments
                                                         ▲
category_translation                                     │
    product_category_name (PK)              No FK — see design note below
    product_category_name_english
```

---

## Design Decisions

**Performance indexes are documented, not just added.**
Every index in `01_create_tables.sql` has an inline comment explaining which query it supports and why. This is standard production practice — indexes without rationale become dead weight that slows writes with no clear owner.

Indexes added:
- `idx_customers_unique_id` — cohort retention CTEs group and join on this column
- `idx_customers_state` — geographic aggregations
- `idx_sellers_state` — state-level seller benchmarks
- `idx_products_category` — appears in every category-level analytical query
- `idx_orders_purchase_ts` — drives all time-series, MoM, and running total queries
- `idx_orders_status` — appears in the WHERE clause of almost every query
- `idx_orders_customer_id` — the join path between orders and customers
- `idx_order_items_seller_id` — seller scorecard and performance queries
- `idx_order_items_product_id` — category-level aggregations via items
- `idx_payments_type` — payment pivot query filter
- `idx_reviews_order_id` — join path from delivery analysis to review scores
- `idx_reviews_score` — divergence analysis and sentiment comparison filters

**Why `order_reviews` has no FK to `orders`.**
The Olist dataset contains review rows for cancelled orders. Enforcing `FOREIGN KEY (order_id) REFERENCES orders(order_id)` would silently reject those rows at load time with no useful error — the type of silent data loss that corrupts analysis. The composite PK `(review_id, order_id)` provides sufficient referential structure for this project.

**Why `customer_unique_id` is NOT the PK of `customers`.**
Olist assigns a new `customer_id` per order — one real person can have multiple IDs across purchases. `customer_unique_id` is the true person identifier and is indexed, not used as a PK, because the orders table joins via `customer_id`. Switching the PK would require restructuring the FK chain across four tables. The current design reflects the source data model faithfully while making the correct join path explicit through the index name.

**Why `LOAD DATA INFILE` for 7 tables but pandas for reviews.**
The `order_reviews` CSV contains embedded newlines inside quoted review text fields. MySQL's `LOAD DATA INFILE` parser fails at row 77,917 because it treats the embedded newline as a row terminator. pandas handles multi-line quoted fields correctly by default. This is a common production data quality issue — not a tutorial dataset artifact.

---

## How to Run

```sql
-- In MySQL Workbench or CLI, run in this exact order:
SOURCE sql/01_setup/01_create_tables.sql;
SOURCE sql/01_setup/02_load_data.sql;

-- Then load reviews separately:
-- python python/load_reviews.py
```

After loading: ~530,000 rows across 8 tables.

---

*Author: Brijesh Vaghela | [LinkedIn](https://www.linkedin.com/in/brijesh-vaghela)*
