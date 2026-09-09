# Olist Marketplace Analytics: Interview Defensibility Guide

**Portfolio Project Technical & Strategic Deep Dive**  
*Author: Girish G Gowda | [GitHub](https://github.com/GirishGowdaG)*

---

## 1. Project Objective & Strategic Motivation

### Why this project exists:
This portfolio project was designed to demonstrate real-world product analytics, operations intelligence, and data engineering on a complex multi-party marketplace. Rather than analyzing a generic, sanitized tutorial dataset (e.g., Superstore), this project evaluates Olist — Brazil’s largest e-commerce platform connecting independent merchants to national retail consumers.

### Key Marketplace Dynamics Analyzed:
- **Geographic Fragmentation**: Continental logistics where merchants are concentrated in São Paulo while buyers span 27 federal states.
- **Unit Economics vs. Freight Drag**: The trade-off between product pricing and inter-state shipping surcharges.
- **Fulfillment Latency Attribution**: Disentangling merchant dispatch time from carrier transit network bottlenecks.
- **Customer Lifetime Value (LTV) Reality**: Navigating high acquisition costs in a market where 97% of consumers purchase only once.

---

## 2. Why the Olist Dataset was Selected

1. **Relational Complexity (Star/Galaxy Schema)**: 8 interconnected tables encompassing order spines, item-level lines, payment splits, customer locations, and review feedback.
2. **Authentic Data Quality Challenges**:
   - Customer review text with embedded line breaks and unescaped double quotes that crash native SQL bulk loaders.
   - Distinct `customer_id` (per order) vs. `customer_unique_id` (individual person), which trips naive cohort analyses.
   - Missing carrier delivery timestamps for canceled and in-flight orders requiring explicit NULL and lifecycle handling.
   - Windows CRLF carriage returns in translated category tables that break standard relational joins.
3. **Multimodal Feedback**: Pairs numerical 1–5 star ratings with free-text Brazilian Portuguese customer commentary, enabling deep NLP sentiment analysis and complaint categorization.

---

## 3. Data Cleaning & Engineering Decisions

| Problem Encountered | Engineering Decision | Technical Justification |
|---|---|---|
| **Bulk Loading Reviews (`LOAD DATA INFILE` failure)** | Ingest via pandas script (`python/src/review_loader.py`) | Python’s CSV parser handles quoted multiline strings natively, whereas MySQL's line parser mistakes embedded newlines as row terminators, corrupting records after row 77,917. |
| **Trailing `\r` on English Category Translations** | Ingest with SQL `UPDATE ... SET REPLACE(..., '\r', '')` | Windows CRLF line endings left invisible `\r` on category strings, causing joins on `product_category_name` to fail silently with zero matches. |
| **Customer Identification in Cohort Retention** | Join strictly on `customer_unique_id` | If `customer_id` is used, every repeat order looks like a brand-new customer, artificially reducing retention to 0%. `customer_unique_id` tracks the actual person across time. |
| **Referential Integrity for Canceled Orders** | Retain unconstrained composite PK `(review_id, order_id)` without rigid foreign key rejection | Canceled orders often generate customer reviews before an order reaches 'delivered' status. Enforcing strict foreign keys would silently drop canceled-order complaints. |

---

## 4. Database Schema & Indexing Strategy

The MySQL schema is indexed intentionally based on query access patterns:
- **`orders`**: Indexed on `order_purchase_timestamp` (time-series filtering) and `customer_id` (customer joins).
- **`order_items`**: Composite primary key `(order_id, order_item_id)`, indexed on `product_id` and `seller_id` for fast merchant and category aggregation.
- **`order_reviews`**: Composite primary key `(review_id, order_id)`, indexed on `review_score` for star-rating segmentation.
- **`review_sentiment`**: Primary key `review_id`, indexed on `sentiment_label` for sentiment profile queries.

---

## 5. Why SQL Analytical Views Were Created

Power BI can execute multi-stage CTEs in native queries, but permanent MySQL views were chosen for four key reasons:
1. **Eliminating Many-to-Many DAX Leakage**: Joining `order_items` (grain: item) to `order_reviews` (grain: review) across orders creates relationship ambiguity in Power BI. Precomputing aggregations in SQL provides flat, clean tables.
2. **Performance & Fast Refresh**: Complex cohort matrices (calculating `TIMESTAMPDIFF` offsets across 99K orders) compute in under 2 seconds in MySQL, whereas dynamic DAX virtual tables slow down visual interactions.
3. **Testability & Version Control**: SQL view definitions are committed, reviewed, and testable outside of proprietary BI files.
4. **Separation of Concerns**: SQL handles heavy relational transformations; Power BI focuses on responsive visualization and user interaction.

---

## 6. Python NLP Architecture & Reason Classification

### BerTweet-PT RoBERTa Model
- Uses `pysentimiento/bertweet-pt-sentiment`, fine-tuned natively on Brazilian Portuguese social text.
- Scores text independently of the numerical star rating. This independence makes sentiment divergence meaningful (e.g., detecting cases where a customer gave 5 stars out of habit, but wrote a negative comment describing broken parts).
- Features batched inference with checkpointing via `ON DUPLICATE KEY UPDATE` to support resumability on large datasets.

### Negation-Aware Reason Classifier
- Raw keyword frequency surfaces generic Portuguese sentiment terms (*"ótimo"*, *"péssimo"*), but fails to explain *why* an issue occurred.
- The rule-based classifier identifies 8 concrete business root causes (Late Delivery, Damaged Item, Wrong Product, Poor Quality, Refund Request, Fast Delivery, As Described, Strong Recommendation).
- **Negation Window**: Checks the 3 tokens preceding any praise term for negators (`não`, `nem`, `nunca`, `jamais`). Phrases like *"não recomendo"* or *"não é bom"* are prevented from triggering false positive praise tags.

---

## 7. Power BI Data Modeling & Key DAX Measures

### Star/Galaxy Schema Design
- Dual fact tables (`order_items` for financial GMV, `orders` for cycle time and status) sharing dimension tables (`customers`, `sellers`, `products`, `category_translation`).
- Reporting views (`view_customer_cohort_metrics`, `view_regional_logistics_performance`, `view_seller_operational_health`, `view_category_sentiment_breakdown`) feed specialized executive summary pages.

### Key DAX Measures Explained:
1. **`Total GMV`**:
   `SUM(order_items[price])` — Quantifies core product merchandise revenue excluding shipping freight.
2. **`Freight Burden Ratio %`**:
   `DIVIDE(SUM(order_items[freight_value]), SUM(order_items[price]), 0)` — Measures shipping friction as a percentage of product value.
3. **`Late Delivery Rate %`**:
   Calculates delivered orders where `order_delivered_customer_date > order_estimated_delivery_date` divided by total delivered orders.
4. **`Avg Dispatch Hours`**:
   `AVERAGEX(..., DATEDIFF(orders[order_approved_at], orders[order_delivered_carrier_date], HOUR))` — Isolates seller operational efficiency.
5. **`Repeat Customer Penetration %`**:
   Measures unique customers with `DISTINCTCOUNT(orders[order_id]) > 1` divided by total unique customer IDs.

---

## 8. Summary of Strategic Business Insights

1. **Fulfillment Latency Attribution**:
   86% of delay latency occurs after the carrier accepts the parcel (carrier transit surges from 8.9 to 23.7 days on late orders). Sellers dispatch in ~3 days consistently.
2. **Regional Freight Burden Index**:
   Northern Brazilian states face a 31.6% freight surcharge relative to product value, depressing review ratings from 4.16★ down to 3.82★.
3. **Customer Retention Reality**:
   97.0% of buyers purchase only once. Repeat buyers spend +31% higher basket sizes (R$178 vs R$136 AOV), confirming Olist is an acquisition-driven durable goods marketplace.
4. **Category Concentration Risk**:
   Categories like `bed_bath_table` and `watches_gifts` exhibit over 45% revenue concentration in their top 3 merchants, exposing the platform to severe supplier risk.
5. **Installment Financing**:
   Credit cards drive 75.2% of GMV with an average of 3.5 installments; high-ticket purchases average 6.2 installments, demonstrating financing's role in conversion.

---

## 9. Project Limitations & Nuances

- **Dataset Time Horizon**: Covers September 2016 to September 2018; conclusions reflect marketplace conditions during that period.
- **Geographic Imbalance**: Heavy seller concentration in São Paulo (SP) skews regional logistics analysis toward outbound shipments from the Southeast.
- **Review Coverage**: Comment text is present on 42.7% of reviews; 57.3% of customers provided star ratings without text.
- **External Carrier Data**: Exact carrier routing and tracking checkpoints are abstracted into carrier handover and customer delivery timestamps.

---

## 10. What I Personally Designed and Implemented

1. **Schema & Ingestion Pipeline**: Relational table design, index tuning, and robust Python loader for multi-line reviews.
2. **12 Analytical SQL Queries**: Formulated independent business questions, CTE architectures, window function metrics, and state-level aggregations.
3. **4 Persistent Reporting Views**: Designed and deployed materialized views in MySQL to support Power BI dashboard stability.
4. **Modular Python NLP Package**: Built `python/src/` with dataclass configuration, database connection pooling, BerTweet-PT inference, and a negation-aware Portuguese reason classifier.
5. **Power BI Data Model & Dashboard**: Modeled star/galaxy relationships, authored DAX business measures, and configured a clean corporate reporting interface.
6. **Documentation & Business Case**: Wrote the complete 12-finding business case and technical defensibility documentation from scratch.

---

*Author: Girish G Gowda | [GitHub](https://github.com/GirishGowdaG)*
