# SQL — Analytical Engine & Database Views

## Overview

The SQL directory contains the complete analytical foundation of the Olist Marketplace Analytics project. Structured cleanly into schema definition, analytical query suites, and persistent reporting views, it supports both ad-hoc business exploration and automated BI reporting.

```
sql/
├── schema/     ← Table DDL, constraints, indexing, and bulk ingestion
├── analysis/   ← 12 independent business analysis queries
└── views/      ← Materialized analytical views powering Power BI
```

---

## Directory Breakdown

### 1. `sql/schema/`
- `01_create_schema.sql`: Production DDL defining 8 core relational tables, indexing strategies, primary/foreign keys, and character set configuration (`utf8mb4`).
- `02_load_data.sql`: Fast bulk loading scripts utilizing `LOAD DATA LOCAL INFILE` with NULL sanitization and Windows CRLF carriage return fixes.

### 2. `sql/analysis/` (12 Strategic Queries)

| File | Core Business Question | Key Techniques |
|---|---|---|
| `01_regional_freight_burden.sql` | What is the Freight Burden Index (FBI) across Brazil's 5 macro-regions? | CASE macro-regions, conditional aggregates, cost ratios |
| `02_fulfillment_latency_deconstruction.sql` | Is delivery delay caused by seller handling time or carrier transit latency? | TIMESTAMPDIFF, SLA segmentation, latency share ratios |
| `03_seller_concentration_risk.sql` | In which product categories is GMV concentrated among the top 1–3 sellers? | ROW_NUMBER(), cumulative window aggregates, risk tiers |
| `04_repeat_customer_dynamics.sql` | What proportion of buyers return and how do repeat baskets compare in AOV? | Multi-stage CTE, customer_unique_id grouping, basket metrics |
| `05_payment_method_economics.sql` | How does installment financing expand purchasing power and affect cancellation? | Multi-tier installment grouping, payment completion rates |
| `06_carrier_sla_buffer_reliability.sql` | What is the variance and predictability of Olist's estimated delivery dates? | DATEDIFF buffer calculation, STDDEV volatility analysis |
| `07_product_vertical_economics.sql` | Do product verticals suffer from physical transport friction (weight/volume)? | Physical dimensions aggregation, freight ratio correlation |
| `08_regional_expansion_trajectory.sql` | Has marketplace GMV expanded beyond the industrial hub of São Paulo? | Quarterly cohort grouping, cross-regional mix percentages |
| `09_seller_operational_reliability.sql` | How can Olist segment sellers into operational tiers based on dispatch & SLA? | Multi-variable seller scorecard, tier classification |
| `10_category_sentiment_profile.sql` | How does RoBERTa NLP sentiment distribute across major product verticals? | Multi-table joins, sentiment distribution ratios |
| `11_customer_complaint_taxonomy.sql` | What specific operational and product failures do customers cite in reviews? | Multi-label reason extraction summary, percentage weighting |
| `12_order_cancellation_friction.sql` | What is the revenue loss and geographical concentration of canceled orders? | Lifecycle stage breakdown, lost GMV aggregation |

---

### 3. `sql/views/` (Reporting Layer Views)

| View Name | Source File | Power BI Target | Purpose |
|---|---|---|---|
| `view_customer_cohort_metrics` | `01_customer_cohort_metrics.sql` | Page 2: Customer Economics | Month-by-month cohort retention curves and repurchase GMV |
| `view_regional_logistics_performance` | `02_regional_logistics_performance.sql` | Page 4: Logistics Friction | State-by-state freight ratios, transit days, and SLA compliance |
| `view_category_sentiment_breakdown` | `03_category_sentiment_breakdown.sql` | Page 5: Voice of Customer | Category-level sentiment distribution and confidence scores |
| `view_seller_operational_health` | `04_seller_operational_health.sql` | Page 3: Seller Health | Merchant dispatch hours, order volume, and rating performance |

---

## Design Rationale: SQL Views vs. Complex DAX

To prevent filter-context leakage and eliminate complex runtime recalculations in Power BI, multi-table aggregations (such as cohort repurchase offsets and state-level conditional pivots) are precomputed in persistent SQL views. This ensures clean separation of concerns: SQL handles heavy transformation, while Power BI focuses on responsive executive exploration.

---

*Author: Girish G Gowda | [GitHub](https://github.com/GirishGowdaG)*
