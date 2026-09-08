# powerbi — Executive Dashboard

A 9-page executive report built in Power BI Desktop. Custom dark design system, page-level navigation, star/galaxy schema, and a storytelling structure that builds toward a single headline finding: **delivery is Olist's biggest controllable lever**.

The trickiest part of this dashboard was the filter context — `fact_order_items` and `fact_reviews` have a many-to-many relationship that Power BI's engine couldn't resolve cleanly. The Technical Challenges section below documents exactly what broke and how it was fixed.

---

## Files

| File / Folder | Contents |
|---|---|
| `olist_marketplace_analytics.pbix` | The full Power BI report — open in Power BI Desktop and refresh against your local MySQL |
| `screenshots/` | PNG export of all 9 pages — use these if you can't open the .pbix |
| `Banners/` | Custom page header banner images (one per dashboard page) |
| `Icons/` | KPI card icon set used across the dashboard |
| `Theme work/` | JSON theme files — `olist_dark_premium_theme.json` is the active theme |

---

## Dashboard Pages

| Page | File | Headline |
|---|---|---|
| 00 Home | `00_home.png` | Landing page with navigation cards to all 8 content pages |
| 01 Executive Overview | `01_executive_overview.png` | GMV trajectory annotated with Black Friday peak · KPI cards |
| 02 Seller Performance & Risk | `02_seller_performance.png` | 4-segment seller scorecard · category concentration risk · geographic map |
| 03 Customer Retention | `03_customer_retention.png` | Cohort heatmap — sub-1% retention visible across every cohort |
| 04 Delivery & Operations | `04_delivery_operations.png` | The 1.72★ late-delivery penalty · 13.7-day under-promise insight |
| 05 Sentiment Analysis | `05_sentiment_analysis.png` | Star vs text divergence · 435 cases where they disagree |
| 06 Sentiment Trends | `06_sentiment_trends.png` | Sentiment over time · sentiment by top 10 categories |
| 07 Voice of Customer | `07_voice_of_customer.png` | Reason breakdown — why reviews are negative / neutral / positive |
| 08 Payments & Affordability | `08_payments_affordability.png` | Boleto usage map · installment-vs-order-value scatter |

---

## Data Model

The report uses a **star/galaxy schema** (two fact tables sharing dimension tables):

```
                    dim_customers ──────────────────────────────────┐
                    dim_sellers  ──────────────────────┐            │
                    dim_products ──────────────┐        │            │
                    dim_category ──────┐        │        │            │
                                       ▼        ▼        ▼            ▼
                                  fact_order_items ──── fact_orders ──── fact_reviews
                                  (grain: order line)  (grain: order)  (grain: review)
                                                                ▲
                                                                │
                                                   fact_payments (grain: payment)
                                                   review_sentiment
                                                   review_reason_summary
```

**Import Mode** is used throughout. For a dataset of this size (530K rows), Import Mode provides faster query performance in Power BI than DirectQuery, and the refresh is fast enough (< 2 minutes) that live connectivity is not needed.

---

## Design System

**Theme:** Custom dark theme (`olist_dark_premium_theme.json`) — dark backgrounds with high-contrast accent colours. Not the default Power BI dark theme — the JSON file defines specific hex values, font sizes, and visual defaults for consistency across all pages.

**Navigation:** Every page has a return-to-Home icon in the same screen position. The Home page has 8 navigation cards — one per content page. This mirrors how executive dashboards are designed in production: a landing page the audience uses as the menu, never asking "how do I get back?"

**Page banners:** Custom-designed PNG banners with the page title and icon, placed at the top of every content page. Gives the report a branded, consistent appearance — the kind of polish that distinguishes a production dashboard from an ad-hoc report.

**KPI cards:** Each uses a custom icon from the `/Icons/` set (delivery truck, shopping cart, star, person, shop, dollar bag) alongside the headline metric. Icons are imported as PNG images linked to a measure, not native Power BI card visuals — this gives full control over sizing and positioning.

---

## Technical Challenges Solved

**1. Many-to-many filter leakage between `fact_order_items` and `fact_reviews`**

The natural relationship between these tables is many-to-many: one order can have multiple line items and multiple reviews. Power BI's relationship engine cannot safely resolve this without filter leakage — clicking a seller bar was contaminating review-score measures for unrelated sellers.

Resolution: Explicit `TREATAS()` joins on collected ID sets for measures that need to cross this bridge, and `Edit Interactions` set to None for visuals where even `TREATAS()` wasn't sufficient. This is the correct DAX pattern when the underlying relationship graph can't be trusted.

**2. Cross-filter contamination inflating percentage measures past 100%**

A sentiment trend measure (% positive reviews over time) was inflating past 100% when a category filter was applied. The root cause: the `ALL()` modifier was applied at the wrong `CALCULATE()` step, so the filter context leaked from the category slicer into the denominator calculation.

Resolution: The cohort retention matrix and payments-by-state aggregations were moved into precomputed SQL views (`sql/04_views/`). When a DAX fix requires more debugging than the insight it supports is worth, precomputing in SQL is the correct architectural decision — not a workaround.

**3. Duplicate `review_id` rows in the order-items join**

Joining `fact_reviews` through `fact_order_items` produces 437 duplicated divergence cases (a review can technically join to multiple line items). Deduplicating on `review_id` in Power Query during load corrects this to the true figure of **435**.

---

## Viewing the Dashboard

**No setup required — all 9 pages are exported as PNGs in [`powerbi/screenshots/`](screenshots/).**

Open any screenshot directly in your browser. The full narrative flows from page 00 (Home) through to page 08 (Payments & Affordability).

| Quick links | |
|---|---|
| Executive Overview | [`01_executive_overview.png`](screenshots/01_executive_overview.png) |
| Delivery penalty finding | [`04_delivery_operations.png`](screenshots/04_delivery_operations.png) |
| Voice of Customer | [`07_voice_of_customer.png`](screenshots/07_voice_of_customer.png) |

---

## Running the .pbix Locally (optional — requires MySQL)

If you want to connect the live report to your own database:

1. Complete the full setup in the root [`README.md`](../README.md#-reproduce-from-scratch) first
2. Open `olist_marketplace_analytics.pbix` in Power BI Desktop
3. Home → Transform data → Data source settings → change server to `127.0.0.1`, database to `olist`
4. Enter your MySQL credentials → Close & Apply → Refresh

The SQL analytical views (`cohort_retention_matrix`, `payments_by_state`) must exist before refreshing — run `sql/04_views/` scripts first.

---

*Author: Brijesh Vaghela | [LinkedIn](https://www.linkedin.com/in/brijesh-vaghela)*
