# Olist Marketplace Analytics

**End-to-end marketplace intelligence on Brazilian e-commerce — Relational SQL Engine · Portuguese NLP Pipeline · Executive Power BI Application.**

![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.10-3776AB?logo=python&logoColor=white)
![NLP](https://img.shields.io/badge/NLP-pysentimiento%20PT-8A2BE2)
![Power BI](https://img.shields.io/badge/Power%20BI-Executive%20Suite-F2C811?logo=powerbi&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green)
![Dataset](https://img.shields.io/badge/Dataset-Olist%20Kaggle-2EA44F)

> An enterprise product analytics framework built across 99,441 commercial orders and R$13.5M in gross merchandise value (GMV). Combines 12 production SQL analytical queries, a modular Portuguese NLP engine classifying 42,370 free-text reviews with negation handling, and an interactive 5-page Power BI executive suite diagnosing fulfillment friction, customer lifetime behavior, and marketplace seller health.

---

## 🏗️ System Architecture

```
┌─────────────────────────┐   LOAD DATA LOCAL INFILE   ┌──────────────────────────┐
│   Kaggle CSV Datasets   │ ─────────────────────────► │                          │
│   8 Relational Tables   │    python/src/review_      │    MySQL 8.0 Engine      │
│   ~530K Records         │    loader.py (Reviews)     │    olist database        │
└─────────────────────────┘ ─────────────────────────► │                          │
                                                       │  ┌────────────────────┐  │
                                    SQLAlchemy Pool    │  │ orders (spine)     │  │
                                ┌──────────────────────┤  │ order_items        │  │
                                │                      │  │ order_payments     │  │
                                ▼                      │  │ customers          │  │
                     ┌──────────────────────┐          │  │ sellers            │  │
                     │ Python NLP Pipeline  │          │  │ products           │  │
                     │                      │  UPSERT  │  └────────────────────┘  │
                     │ sentiment_engine.py  ├─────────►│  review_sentiment     │
                     │ RoBERTa (BerTweet-PT)│          │  review_reason_summary│
                     │ 42,370 Text Reviews  │          └────────────┬─────────────┘
                     │                      │                       │
                     │ reason_classifier.py │               CREATE VIEW LAYER
                     │ Negation-aware rules │                       │
                     └──────────────────────┘                       ▼
                                                       ┌──────────────────────────┐
                                                       │ SQL Analytical Views     │
                                                       │ • customer_cohort_metrics│
                                                       │ • regional_logistics     │
                                                       │ • seller_operational     │
                                                       │ • category_sentiment     │
                                                       └────────────┬─────────────┘
                                                                    │
                                                                    │ Import Mode
                                                                    ▼
                                                       ┌──────────────────────────┐
                                                       │ Power BI Executive Suite │
                                                       │ 5 Interactive Pages      │
                                                       │ Star Schema · DAX Model  │
                                                       │ Slate Corporate Theme    │
                                                       └──────────────────────────┘
```

---

## 📌 Executive Problem Statement

Operating a nationwide e-commerce marketplace across Brazil introduces distinct operational complexities:
1. **Geographic Logistics Drag**: Sellers are concentrated in the industrial Southeast (SP, RJ, MG), while customer demand spans 27 federal states. Long transit distances to the North and Northeast create heavy freight surcharges and delivery variance.
2. **Customer Acquisition vs. Retention Reality**: Over 96% of marketplace customers purchase only once, challenging traditional retention economics and requiring strict optimization of first-order unit economics.
3. **Seller Operational Bottlenecks**: Aggregate seller star ratings often mask severe dispatch delays. A seller with high sales volume but chronic handling delays damages platform-level NPS.
4. **Voice of the Customer in Context**: Star ratings indicate customer sentiment, but unstructured Brazilian Portuguese text reveals the actual operational root causes behind negative reviews.

---

## 🎯 Core Marketplace KPIs

- **Gross Merchandise Value (GMV)**: R$13,496,408 across 99,441 orders (Sep 2016 – Sep 2018).
- **Freight Burden Index (FBI)**: Ratio of shipping freight to product price (averages **14.2% in the Southeast** vs. **31.6% in the North**).
- **Fulfillment Latency Breakdown**: Average cycle time of **12.5 days** (Seller Dispatch: **2.8 days** | Carrier Transit: **9.7 days**).
- **Repeat Customer Share**: **3.0%** of customers generate **4.0% of total GMV**, spending **+31% higher AOV** (R$178.40 vs. R$136.20).
- **SLA Reliability Rate**: **91.9% of orders arrive before the estimated date**, with an average padding buffer of **11.2 days**.

---

## ❓ Strategic Business Inquiries & SQL Findings

| # | Business Question | SQL Script | Strategic Finding |
|---|---|---|---|
| **01** | How does cross-regional freight burden impact customer ratings across Brazil? | `01_regional_freight_burden.sql` | Northern regions pay a **31.6% freight surcharge**, depressing average ratings to **3.82★** vs **4.16★** in SP. |
| **02** | Is delivery delay caused by merchant dispatch lag or carrier transit latency? | `02_fulfillment_latency_deconstruction.sql` | **86% of delay latency** occurs after carrier acceptance; transit surges from 8.9 to 23.7 days on late orders. |
| **03** | In which categories is marketplace GMV concentrated among top sellers? | `03_seller_concentration_risk.sql` | `bed_bath_table` and `watches_gifts` exhibit over **45% GMV concentration** in the top 3 merchants. |
| **04** | What is the lifetime value and basket size expansion of repeat buyers? | `04_repeat_customer_dynamics.sql` | Repeat customers place **31% higher basket sizes** (R$178.40 AOV) and buy across diverse categories. |
| **05** | How do credit card installments and Boleto Bancário affect checkout conversion? | `05_payment_method_economics.sql` | Credit cards represent **75.2% of GMV** (avg **3.5x installments**); high-ticket items average **6.2x installments**. |
| **06** | How volatile and predictable are Olist's estimated delivery date buffers? | `06_carrier_sla_buffer_reliability.sql` | Average buffer is **11.2 days early**, but buffer standard deviation is **8.4 days** in peripheral states. |
| **07** | Do product verticals suffer from physical transport friction (weight/volume)? | `07_product_vertical_economics.sql` | Heavy goods (> 8 kg) experience **40% longer transit times** and a **14% lower satisfaction rating**. |
| **08** | Has marketplace GMV decentralized from São Paulo into emerging regional hubs? | `08_regional_expansion_trajectory.sql` | São Paulo GMV share moderated from **48.2% to 39.4%**, with Southern states expanding to **16.1%**. |
| **09** | How can Olist segment merchants into operational reliability tiers? | `09_seller_operational_reliability.sql` | Identified **Tier 1 Elite Operators** (22% of sellers generating 41% GMV) vs. **Tier 3 Bottlenecks** (8% of sellers). |
| **10** | How does Portuguese review sentiment distribute across product verticals? | `10_category_sentiment_profile.sql` | `office_furniture` and `telephony` exhibit the highest negative sentiment shares (**28.4% and 22.8% NEG**). |
| **11** | What operational failures do customers cite in free-text feedback? | `11_customer_complaint_taxonomy.sql` | **Late or non-delivery accounts for 33.3%** of negative citations, followed by wrong items (10.1%). |
| **12** | At what lifecycle stage do order cancellations occur and what is the lost GMV? | `12_order_cancellation_friction.sql` | **60%+ of cancellations occur before carrier dispatch**, indicating merchant inventory stockouts. |

---

## 🧠 Natural Language Processing Pipeline

Customer reviews contain numerical 1–5 star ratings and free-text Brazilian Portuguese comments. The NLP pipeline performs deep text classification and multi-label complaint extraction.

- **Pretrained Deep Learning Model**: `pysentimiento/bertweet-pt-sentiment` (RoBERTa architecture fine-tuned on Brazilian Portuguese).
- **Text Coverage**: 42,370 reviews with comment messages scored independently of numerical ratings.
- **Rule-Based Complaint Classifier**: Evaluates normalized text against 8 operational and product failure categories using a 3-token lookback window for negation detection (`não`, `nem`, `nunca`, `jamais`).
- **Resilient Execution**: Batched inference with database upsert checkpointing (`ON DUPLICATE KEY UPDATE`).

---

## 📊 Executive Power BI Suite

A 5-page executive reporting application designed in Power BI Desktop using a clean Corporate Slate theme:
1. **Executive Marketplace Overview**: GMV velocity, order trajectory, macro-category performance, and platform KPIs.
2. **Customer Economics & Repeat Growth**: Repeat buyer penetration, cohort repurchase heatmap, and basket value expansion.
3. **Seller Health & Category Concentration**: Merchant operational tiering, dispatch latency distribution, and category concentration risk.
4. **Logistics & Regional Friction**: Deconstruction of handling vs. carrier transit, regional Freight Burden Index map, and delivery buffer volatility.
5. **Customer Voice & Quality Intelligence**: RoBERTa sentiment distributions, root-cause complaint breakdown, and cross-category quality tracking.

---

## 📁 Repository Structure

```
olist-marketplace-analytics/
├── data/                                 ← Dataset documentation & ingestion guidance
│   └── README.md
├── docs/                                 ← Business documentation & architecture
│   ├── business_case.md                  ← Comprehensive 12-finding business case
│   ├── olist_data_model.svg              ← Relational star/galaxy schema diagram
│   └── README.md
├── powerbi/                              ← Business intelligence application
│   ├── Theme work/                       ← Custom JSON theme definitions
│   │   └── olist_corporate_slate_theme.json
│   ├── olist_marketplace_analytics.pbix  ← Executive Power BI report
│   ├── screenshots/                      ← Dashboard page captures
│   └── README.md
├── python/                               ← Modular Python NLP pipeline
│   ├── src/
│   │   ├── config.py                     ← Environment configuration dataclass
│   │   ├── db.py                         ← SQLAlchemy connection pooling
│   │   ├── review_loader.py              ← Robust multi-line review CSV parser
│   │   ├── sentiment_engine.py           ← Batched BerTweet-PT inference engine
│   │   └── reason_classifier.py          ← Negation-aware Portuguese complaint classifier
│   ├── main.py                           ← Unified CLI entry point
│   ├── requirements.txt                  ← Pipeline dependencies
│   └── README.md
├── sql/                                  ← Relational database engine
│   ├── schema/                           ← DDL, indexes, and bulk ingestion
│   │   ├── 01_create_schema.sql
│   │   └── 02_load_data.sql
│   ├── analysis/                         ← 12 strategic business queries
│   │   ├── 01_regional_freight_burden.sql
│   │   ├── 02_fulfillment_latency_deconstruction.sql
│   │   ├── 03_seller_concentration_risk.sql
│   │   ├── 04_repeat_customer_dynamics.sql
│   │   ├── 05_payment_method_economics.sql
│   │   ├── 06_carrier_sla_buffer_reliability.sql
│   │   ├── 07_product_vertical_economics.sql
│   │   ├── 08_regional_expansion_trajectory.sql
│   │   ├── 09_seller_operational_reliability.sql
│   │   ├── 10_category_sentiment_profile.sql
│   │   ├── 11_customer_complaint_taxonomy.sql
│   │   └── 12_order_cancellation_friction.sql
│   ├── views/                            ← Analytical reporting views
│   │   ├── 01_customer_cohort_metrics.sql
│   │   ├── 02_regional_logistics_performance.sql
│   │   ├── 03_category_sentiment_breakdown.sql
│   │   └── 04_seller_operational_health.sql
│   └── README.md
├── .gitattributes
├── .gitignore
├── LICENSE                               ← MIT License
├── README.md                             ← Project executive summary
└── requirements.txt                      ← Root Python requirements
```

---

## 🔁 Reproduction Steps

```powershell
# 1. Clone repository
git clone https://github.com/GirishGowdaG/olist-marketplace-analytics.git
cd olist-marketplace-analytics

# 2. Download Kaggle dataset into data/
#    https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

# 3. Initialize MySQL Schema & Data
#    Execute sql/schema/01_create_schema.sql and sql/schema/02_load_data.sql in MySQL Workbench

# 4. Deploy Analytical Views
#    Execute sql/views/*.sql scripts in order

# 5. Set up Python Environment & Dependencies
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install torch --index-url https://download.pytorch.org/whl/cpu
pip install -r python/requirements.txt

# 6. Configure MySQL Credentials (PowerShell)
$env:OLIST_DB_USER     = "root"
$env:OLIST_DB_PASSWORD = "your_mysql_password"
$env:OLIST_DB_HOST     = "127.0.0.1"
$env:OLIST_DB_PORT     = "3306"
$env:OLIST_DB_NAME     = "olist"

# 7. Run NLP Pipeline
python -m python.main --task all

# 8. Open Power BI
#    Open powerbi/olist_marketplace_analytics.pbix and trigger data refresh
```

---

## 👤 Author & Attribution

**Girish G Gowda**  
* GitHub: [https://github.com/GirishGowdaG](https://github.com/GirishGowdaG)  

*Dataset Attribution: Brazilian E-Commerce Public Dataset provided by Olist and published on Kaggle under the CC BY-NC-SA 4.0 license.*  
*Model Attribution: `pysentimiento/bertweet-pt-sentiment` developed by Pérez et al., licensed under CC BY-NC 4.0.*
