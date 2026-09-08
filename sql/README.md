# SQL — Olist Marketplace Analytics

Four subfolders covering the full SQL lifecycle: schema design and data loading, 13 analytical queries each tied to a specific business question, the NLP output schema, and the views that feed Power BI directly. The queries get progressively more complex — start with `02_findings/seller_scorecard.sql` if you want to see the ceiling.

---

## Folder Structure

```
sql/
├── 01_setup/        ← Schema creation + data loading
├── 02_findings/     ← 13 business-case analytical queries
├── 03_sentiment/    ← NLP output table schema
└── 04_views/        ← Materialised views powering Power BI
```

---

## Subfolders at a Glance

| Folder | What's Inside | Key Skill |
|---|---|---|
| `01_setup/` | Schema + FKs + performance indexes + bulk loader | Schema design, data quality, indexing |
| `02_findings/` | 13 queries — one business question per file | Window functions, CTEs, rankings, cohort logic |
| `03_sentiment/` | NLP output table schema (idempotent `CREATE TABLE IF NOT EXISTS`) | Integration between Python pipeline and SQL layer |
| `04_views/` | 3 analytical views replacing complex DAX with precomputed SQL | Performance engineering, BI integration |

---

## SQL Techniques Across This Folder

| Technique | File(s) |
|---|---|
| `ROW_NUMBER() OVER (PARTITION BY ...)` | `top_sellers_by_category.sql`, `top_cities_by_state.sql` |
| `LAG()` for period-over-period comparison | `monthly_revenue_growth.sql`, `category_mom_order_growth.sql` |
| `SUM() OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` | `revenue_running_total.sql`, `category_orders_running_total.sql` |
| `SUM() OVER (ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)` | `revenue_running_total.sql` — 7-day moving average |
| `PERIOD_DIFF` for month offset | `cohort_retention.sql`, `01_cohort_retention_matrix.sql` |
| 5-stage CTE pipeline | `cohort_retention.sql` |
| Gaps & Islands (row_number subtraction) | `customer_order_streaks.sql` |
| `AVG() OVER (PARTITION BY)` for group benchmark | `sellers_above_state_avg_rating.sql` |
| `NTILE(100)` + `NTILE(10)` | `order_value_percentiles.sql` |
| Conditional aggregation pivot (`SUM CASE WHEN`) | `payment_behaviour_by_state.sql` |
| `RANK()` across multiple dimensions simultaneously | `seller_scorecard.sql` |
| `CASE WHEN` business-logic classification | `seller_scorecard.sql`, `delivery_sla_review_impact.sql` |
| `DATEDIFF` + NULL filtering for SLA compliance | `delivery_sla_review_impact.sql` |
| `CREATE OR REPLACE VIEW` | All files in `04_views/` |
| Performance indexes with design rationale | `01_setup/01_create_tables.sql` |

---

## Where to start

If you're short on time, these five files show the most depth:

1. `01_setup/01_create_tables.sql` — Schema design decisions and why specific indexes were added where they were
2. `02_findings/seller_scorecard.sql` — The capstone: 5 tables, 4 CTEs, 3 ranking dimensions, business-logic segmentation
3. `02_findings/cohort_retention.sql` — 5-stage CTE cohort analysis with the `customer_unique_id` data trap documented inside
4. `02_findings/delivery_sla_review_impact.sql` — How the 1.72★ penalty was quantified
5. `04_views/01_cohort_retention_matrix.sql` — Why this ended up as a SQL view and not a DAX measure

---

## Key Design Decisions

**Why views instead of DAX for complex aggregations?**
When a Power BI measure requires `TREATAS()` joins and `CALCULATE/ALL()` context manipulation just to produce a percentage that doesn't inflate past 100%, the right call is to move the complexity to SQL where it's testable, readable, and version-controlled. The cohort retention heatmap, payments-by-state pivot, and reason summary are all precomputed SQL views for this reason.

**Why `customer_unique_id` and not `customer_id` for cohort analysis?**
The Olist dataset assigns a new `customer_id` per order — meaning one real person can appear with multiple IDs. Using `customer_id` would make every order look like a new customer, producing near-zero retention that's wrong for the wrong reason. All cohort queries in this project join on `customer_unique_id`, the true person identifier.

**Why `ROW_NUMBER()` and not `RANK()` for top-N queries?**
`RANK()` returns more than N rows on a tie. When the business question asks for exactly the top 3 sellers per category, `ROW_NUMBER()` is the correct function because it always returns exactly one rank per row, breaking ties deterministically. Using `RANK()` would be answering a different question.

---

*Author: Brijesh Vaghela | [LinkedIn](https://www.linkedin.com/in/brijesh-vaghela) | [GitHub](https://github.com/Brijesh403)*
