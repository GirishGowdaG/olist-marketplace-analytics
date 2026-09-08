# sql/02_findings — Business Case Analytical Queries

13 SQL queries, each answering one specific business question a marketplace analytics team would ask. Every file follows the same structure: the business question, why it matters in the real world, the SQL approach with technique explanation, and the results with business interpretation.

**Capstone query:** `seller_scorecard.sql` — joins 5 tables across 4 CTEs and ranks sellers simultaneously across revenue, delivery quality, and customer satisfaction. Read this one first if you're evaluating SQL skill.

---

## Query Index

| File | Business Question | Key SQL Technique | Finding |
|---|---|---|---|
| `top_sellers_by_category.sql` | Which sellers dominate each category — and what does the revenue gap signal? | `ROW_NUMBER() OVER (PARTITION BY category)` | `bed_bath_table` has dangerous 3× concentration risk |
| `top_cities_by_state.sql` | Where does demand actually live? | `ROW_NUMBER()` with tiebreaker for deterministic results | DF: 2,131 orders in Brasília vs 4 in rank-2 city |
| `revenue_running_total.sql` | How did GMV accumulate — and where did growth accelerate or plateau? | `SUM() OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` + 7-day moving avg | Three distinct growth phases; plateau from Apr 2018 |
| `category_orders_running_total.sql` | Which categories show sustained growth vs isolated spikes? | `SUM() OVER (PARTITION BY category ORDER BY month)` | Running total restarts per category via PARTITION BY |
| `monthly_revenue_growth.sql` | Is revenue growing faster or slower than last month? | `LAG(revenue, 1) OVER (ORDER BY month)` | Black Friday 2017: +52.1% MoM — the only month above R$1M |
| `category_mom_order_growth.sql` | Which categories are accelerating, which are flattening? | `LAG()` partitioned by category for independent MoM series | |
| `cohort_retention.sql` | Does Olist have a retention problem or an acquisition problem? | 5-stage CTE · `PERIOD_DIFF` · conditional aggregation pivot | Sub-1% m1 retention across every cohort |
| `customer_order_streaks.sql` | Who are the most loyal customers and how loyal are they really? | Gaps & Islands — `ROW_NUMBER()` subtraction trick | Only 11 of 96,096 customers ordered in 3+ consecutive months |
| `sellers_above_state_avg_rating.sql` | Which sellers outperform their regional peers? | `AVG() OVER (PARTITION BY seller_state)` | 691 sellers beat their state avg — min 10 orders threshold |
| `delivery_sla_review_impact.sql` | What is the exact rating penalty of a late delivery? | `DATEDIFF` + `CASE WHEN` + `SUM() OVER ()` for % | **1.72 star penalty** — 4.29★ on-time vs 2.57★ late |
| `payment_behaviour_by_state.sql` | How do payment preferences and affordability vary by region? | Conditional aggregation pivot across 27 states | Boleto peaks 29% in AP (North) vs 20% in SP |
| `order_value_percentiles.sql` | What does a typical Olist order actually cost? | `NTILE(100)` for percentiles · `NTILE(10)` for decile revenue share | Top 10% of orders generate 38.1% of revenue |
| `seller_scorecard.sql` | Which sellers are performing across ALL dimensions simultaneously? | 4-stage CTE · `RANK()` across 3 dimensions · `NTILE(4)` · `CASE WHEN` segmentation | Rank-5 seller: R$188K revenue at 3.35★ — hidden platform risk |

---

## Techniques Reference

**`ROW_NUMBER()` vs `RANK()` — a choice with real consequences**
`RANK()` returns more rows than requested on tied values. `ROW_NUMBER()` always returns exactly one row per rank. When the business question asks for *exactly* top 3 sellers per category, `ROW_NUMBER()` is correct. Using `RANK()` would give the wrong count — a subtle but meaningful error.

**Why CTE wrappers for window function filters**
Window functions are evaluated *after* the WHERE clause runs. You cannot write `WHERE ROW_NUMBER() = 1` directly — it will fail. The CTE wrapper is not optional syntax; it is the SQL evaluation order forcing you to wrap. This is the most common mistake candidates make in live SQL screens.

**The `customer_unique_id` trap in cohort analysis**
`cohort_retention.sql` uses `customer_unique_id`, not `customer_id`. Olist assigns a new `customer_id` per order, so joining on `customer_id` makes every repeat order appear to come from a new customer — producing near-zero retention that's wrong for the wrong reason. This note is documented inside the query file.

**Gaps & Islands in `customer_order_streaks.sql`**
The technique works by assigning a `ROW_NUMBER()` per customer ordered by month, then subtracting it from the month's sequential integer. Consecutive months produce a *constant* from the subtraction — the moment a gap appears, the constant shifts. Rows sharing the same constant form an island (a streak). Counting rows per island gives streak length.

**Why `SUM() OVER ()` instead of a self-join for percentages**
`delivery_sla_review_impact.sql` calculates the percentage of on-time vs late orders using `SUM(total_orders) OVER ()` — a window function with an empty frame that computes the grand total across all rows. This avoids a self-join on the summary CTE and keeps the logic in a single pass.

---

## Reading Recommendation

**For a SQL interview:** Focus on `seller_scorecard.sql` and `cohort_retention.sql`. Both demonstrate multi-CTE thinking, and both have documented decision rationale (why `ROW_NUMBER()` not `RANK()`, why `customer_unique_id` not `customer_id`) that answers the "explain your approach" follow-up.

**For a product analytics discussion:** Focus on `delivery_sla_review_impact.sql` and `cohort_retention.sql`. Both have findings with direct business recommendations documented in-file.

---

*Author: Brijesh Vaghela | [LinkedIn](https://www.linkedin.com/in/brijesh-vaghela)*
