# docs — Architecture & Case Study Documentation

## Overview

The `docs/` directory contains strategic business documentation, analytical write-ups, and architectural assets detailing the multi-tier analytical platform built on the Olist Brazilian E-Commerce dataset.

```
docs/
├── business_case.md            ← Complete strategic analysis across 12 business findings
├── interview_defensibility.md  ← Comprehensive interview guide and technical rationale
└── olist_data_model.svg        ← Relational star/galaxy schema data model diagram
```

---

## Documents Summary

### 1. `business_case.md`
A comprehensive business analysis written from the perspective of an analytics lead presenting to marketplace executive leadership. The case study structures findings into four strategic pillars:
- **Pillar 1: Cross-Regional Economics & Freight Drag**: Evaluating how Brazilian geography impacts consumer pricing, delivery promises, and review satisfaction.
- **Pillar 2: Order Fulfillment Latency Deconstruction**: Separating merchant dispatch handling from carrier transit network delays to isolate operational bottlenecks.
- **Pillar 3: Seller Discipline & Category Concentration**: Quantifying platform dependency on dominant sellers and modeling multi-variable merchant reliability tiers.
- **Pillar 4: Customer Voice & Repurchase Dynamics**: Analyzing repeat buyer basket size expansions and classifying root-cause dissatisfaction in Portuguese review text.

### 2. `interview_defensibility.md`
A deep technical preparation guide documenting every design decision, metric formulation, SQL CTE flow, Python NLP architecture, Power BI modeling technique, and limitations of the Olist dataset. Designed to ensure full transparency and credible, authentic interview articulation.

### 3. `olist_data_model.svg`
A scalable vector diagram illustrating the relational star/galaxy schema powering the project:
- **Central Spine Fact**: `orders`
- **Line Item Fact**: `order_items`
- **Transaction Fact**: `order_payments`
- **Customer Feedback Fact**: `order_reviews`
- **Core Dimensions**: `customers`, `sellers`, `products`, `category_translation`
- **Analytical Reporting Views**: Materialized view layer providing pre-aggregated KPIs to Power BI.

---

*Author: Girish G Gowda | [GitHub](https://github.com/GirishGowdaG)*
