# powerbi — Executive Power BI Suite

## Overview

The reporting layer of the Olist Marketplace Analytics project translates complex multi-table SQL joins and Python NLP models into an interactive, 5-page executive analytics application.

Designed using a modern corporate layout (Clean Slate & Navy system), the report avoids dark-mode clutter and pre-rendered graphic banners in favor of native Power BI components, dynamic KPI cards, and responsive cross-filtering.

---

## Architecture & Data Connectivity

- **Storage Mode**: Import Mode (cached in-memory for low latency and complex DAX evaluations).
- **Data Source**: Local MySQL 8.0 instance (`127.0.0.1:3306`, database: `olist`).
- **Star & Galaxy Schema**:
  - `orders` (Spine Fact)
  - `order_items` (Transaction Fact)
  - `order_payments` (Payment Fact)
  - `order_reviews` (Review Fact)
  - `customers` (Dimension)
  - `sellers` (Dimension)
  - `products` (Dimension)
  - `category_translation` (Dimension)
  - Analytical Materialized Views: `view_customer_cohort_metrics`, `view_regional_logistics_performance`, `view_category_sentiment_breakdown`, `view_seller_operational_health`.

---

## Executive Report Pages

| Page | Title | Target Audience | Primary Business Objective |
|---|---|---|---|
| **Page 1** | **Executive Marketplace Overview** | C-Suite / GM | High-level GMV velocity, order volumes, macro-category distribution, and net marketplace take-rate. |
| **Page 2** | **Customer Economics & Repeat Growth** | Growth & Retention Leads | Quantifying repeat order curves, cohort repurchase decay, customer lifespan, and basket expansion. |
| **Page 3** | **Seller Health & Category Concentration** | Merchant Success / BD | Seller dispatch latency tiering, Pareto concentration risk across verticals, and merchant attrition indicators. |
| **Page 4** | **Logistics & Regional Friction** | Supply Chain / Ops VP | Deconstructing seller handling vs. carrier transit latency, regional Freight Burden Index (FBI), and SLA buffers. |
| **Page 5** | **Voice of Customer & Sentiment Intelligence** | CX & Product Quality | Portuguese RoBERTa sentiment scores, root-cause complaint taxonomies, and cross-category defect tracking. |

---

## Key DAX Business Measures

```dax
-- 1. Gross Marketplace Value (GMV)
Total GMV = SUM(order_items[price])

-- 2. Freight Burden Ratio %
Freight Burden Ratio % = 
DIVIDE(
    SUM(order_items[freight_value]),
    SUM(order_items[price]),
    0
)

-- 3. Late Delivery Rate %
Late Delivery Rate % = 
VAR TotalDelivered = COUNTROWS(FILTER(orders, orders[order_status] = "delivered"))
VAR TotalLate = COUNTROWS(FILTER(orders, orders[order_status] = "delivered" && orders[order_delivered_customer_date] > orders[order_estimated_delivery_date]))
RETURN
DIVIDE(TotalLate, TotalDelivered, 0)

-- 4. Average Seller Dispatch Hours
Avg Dispatch Hours = 
AVERAGEX(
    FILTER(orders, NOT(ISBLANK(orders[order_approved_at])) && NOT(ISBLANK(orders[order_delivered_carrier_date]))),
    DATEDIFF(orders[order_approved_at], orders[order_delivered_carrier_date], HOUR)
)

-- 5. Repeat Customer Penetration %
Repeat Customer Penetration % = 
VAR TotalUniqueCustomers = DISTINCTCOUNT(customers[customer_unique_id])
VAR RepeatCustomers = 
    COUNTROWS(
        FILTER(
            VALUES(customers[customer_unique_id]),
            CALCULATE(DISTINCTCOUNT(orders[order_id])) > 1
        )
    )
RETURN
DIVIDE(RepeatCustomers, TotalUniqueCustomers, 0)
```

---

## Reproduction & Local Refresh

1. Ensure the MySQL `olist` database is running and all analytical views in `sql/views/` are deployed.
2. Open `powerbi/olist_marketplace_analytics.pbix` in Power BI Desktop.
3. If connecting to a different host/port:
   - Navigate to **Home** → **Transform Data** → **Data Source Settings**.
   - Change Server to your host (default `127.0.0.1:3306`) and Database to `olist`.
4. Click **Close & Apply** and trigger **Refresh**.

---

*Author: Girish G Gowda | [GitHub](https://github.com/GirishGowdaG)*
