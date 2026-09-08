# Olist Business Case — Analysis & Findings
### Brijesh Vaghela

12 findings from the Olist Brazilian E-Commerce dataset. For each finding: the business question, the SQL approach, the results, and the business insight it produces.

---

## Finding 01 — Which sellers dominate each product category?

**The question a category manager actually asks:**
Before renewing seller contracts or adjusting commission tiers,
you want to know — in each category, is revenue spread across
many sellers, or is one seller so dominant that losing them
hurts the whole category?

**Query approach:**
Three-stage CTE. First aggregate revenue per (category, seller).
Then rank sellers within each category using ROW_NUMBER() —
PARTITION BY restarts the rank counter for every category, like
a separate leaderboard per category. Then filter to rank <= 3
in the outer query. Window functions can't go in WHERE because
they're evaluated after WHERE runs — that's the constraint that
forces the CTE wrapper, and it's the #1 thing candidates get
wrong in live SQL screens.

ROW_NUMBER() not RANK() — because the business question asks
for exactly 3 sellers per category. RANK() would return more
than 3 rows on a revenue tie, which is a different answer to
a different question.

**Results:**

| Category | Rank 1 | Rank 2 | Rank 3 | Signal |
|----------|--------|--------|--------|--------|
| watches_gifts | R$201,072 | R$192,093 | R$169,768 | Healthy — top 3 within 16% |
| health_beauty | R$79,285 | R$72,472 | R$65,817 | Healthy — tight competition |
| bed_bath_table | R$165,219 | R$152,308 | R$54,553 | Risk — rank 1 & 2 earn 3× rank 3 |
| computers_accessories | R$53,258 | R$52,198 | R$47,215 | Healthy — within 12% |
| sports_leisure | R$54,056 | R$42,388 | R$42,094 | Moderate — rank 2 and 3 almost level |

**Business insight:**
`bed_bath_table` is the flag. Rank 1 (R$165K) and rank 2 (R$152K)
together earn nearly 3× what rank 3 makes (R$55K) — giving those
two sellers significant negotiating power over Olist's commission
structure. A category manager seeing this would prioritise retention
incentives for those two sellers before contract renewal.

`watches_gifts` is the opposite — rank 1 (R$201K) and rank 3
(R$170K) are within 16% of each other. Healthy competition means
no single seller has platform leverage.

---

## Finding 02 — Which cities drive orders per state?

**The question an ops or growth team asks:**
Where should we prioritise delivery infrastructure, regional
marketing spend, and seller acquisition? City-level order
concentration tells you where demand actually lives.

**Query approach:**
Same three-stage CTE pattern. Aggregate order counts per
(state, city), rank cities within each state by count,
filter to top 3. ROW_NUMBER() with a secondary tiebreaker
on city name ASC ensures deterministic results across runs —
without it, tied cities could swap ranks between executions.

**Results (selected states):**

| State | City | Orders | Rank |
|-------|------|--------|------|
| SP | sao paulo | 15,540 | 1 |
| SP | campinas | 1,444 | 2 |
| SP | guarulhos | 1,189 | 3 |
| RJ | rio de janeiro | 6,882 | 1 |
| RJ | niteroi | 849 | 2 |
| RJ | nova iguacu | 442 | 3 |
| MG | belo horizonte | 2,773 | 1 |
| MG | juiz de fora | 427 | 2 |
| MG | contagem | 426 | 3 |
| BA | salvador | 1,245 | 1 |
| BA | feira de santana | 185 | 2 |
| BA | vitoria da conquista | 92 | 3 |
| DF | brasilia | 2,131 | 1 |
| DF | taguatinga | 4 | 2 |
| DF | guara | 2 | 3 |

**Business insight:**
DF shows extreme concentration — Brasília has 2,131 orders while
rank 2 (Taguatinga) has just 4. A logistics partner in DF only
needs to cover one city to capture virtually all demand in the state.

SP shows the healthiest multi-city distribution: Sao Paulo leads
at 15,540 but Campinas (1,444) and Guarulhos (1,189) absorb
meaningful volume — delivery infrastructure genuinely needs to
cover the full metro spread here.

MG is interesting: Juiz de Fora (427) and Contagem (426) are
nearly identical, suggesting two secondary cities with comparable
demand — unlike most states where rank 2 and 3 drop off sharply.

---

## Finding 03 — What does Olist's revenue trajectory look like?

**The question a growth or finance team actually asks:**
Not "how much did we make this month" — but "where are we in
the cumulative story, and is the underlying trend accelerating
or flattening?"

**Query approach:**
Two-stage CTE. First aggregate to one revenue number per day
(joining order_items to orders for the timestamp, excluding
cancelled orders). Then apply two window functions over the
ordered date sequence — a running total with
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW,
and a 7-day moving average with ROWS BETWEEN 6 PRECEDING
AND CURRENT ROW. The frame slides forward one row at a time,
recalculating both metrics at each date.

The date filter lives in the outer query, not the CTE — so
the running total reflects true cumulative GMV from the first
order ever placed, not an artificially restarted count.

**Results:**

| Milestone | Date | Running Total |
|-----------|------|---------------|
| First order ever | 2016-09-04 | R$72.89 |
| Platform inflection | 2016-10-04 | R$10,221 cumulative |
| End of dataset | 2018-09-03 | R$13,496,408 total GMV |

**Business insight:**
Olist went from a single R$72 order in September 2016 to
R$13.5M in cumulative GMV by mid-2018 — roughly 24 months.
The October 2016 jump (R$441 to R$9,571 in one day) marks
the likely inflection point where the platform opened
meaningfully to sellers or ran its first real acquisition push.
That single week added more revenue than the entire previous
month combined.

The 7-day moving average on the final days drops from 18K to
5.5K — not a business in decline, but a dataset ending.
A real dashboard would flag this as a data-completeness issue
rather than a trend signal.

---

## Finding 04 — How has each category's order volume accumulated?

**The question:**
Which categories show consistent month-on-month growth vs
which had isolated spikes? A running total per category
reveals the accumulation story that monthly snapshots hide.

**Query approach:**
Three-stage CTE. Aggregate order counts per (category, year,
month). Then apply SUM() OVER with PARTITION BY category —
this is the critical detail: the running total restarts
independently for each category, not one global counter.
Filter NULL categories (products with no category assigned)
to keep the analysis clean.

**What to look for in the output:**
A category whose running total climbs steadily every month
is growing organically. A category whose running total jumps
in one month then barely moves has demand concentration in
a single period — worth investigating why.

---

## Finding 05 — Is Olist's revenue growth accelerating or slowing?

**The question a growth team asks every Monday:**
Not "how much did we make" — but "are we growing faster or
slower than last month, and why?"

**Query approach:**
Two-stage CTE. First aggregate revenue per calendar month.
Then use LAG(revenue, 1) OVER (ORDER BY month) to pull the
previous month's revenue onto the same row — no self-join
needed. Growth % is simple arithmetic from there:
(this_month - last_month) / last_month * 100.

The first row returns NULL for previous month — there is no
month before the first. That's correct, not an error.

**Results (key months):**

| Month | Revenue | MoM Growth |
|-------|---------|------------|
| 2017-03 | R$368,341 | +50.4% |
| 2017-05 | R$503,159 | +42.2% |
| 2017-11 | R$1,003,862 | +52.1% — Black Friday Brazil |
| 2017-12 | R$742,183 | -26.1% — post-holiday unwind |
| 2018-04 | R$993,592 | +1.3% |
| 2018-05 | R$992,871 | -0.1% — plateau begins |

**Business insight:**
Three distinct phases are visible. Early 2017 shows explosive
growth (50-100% MoM) as the platform scales from near-zero.
November 2017 is the clear peak — Black Friday Brazil pushed
Olist past R$1M monthly revenue for the first and only time
in the dataset. From April 2018 onward, the business plateaus
around R$850K-R$1M with single-digit growth — a signal that
current market penetration may be saturating.

**Data quality note:**
November 2016 is missing entirely from the data — LAG() treats
December 2016 as "the month after October" which makes the
early growth rates unreliable. Pre-2017 months are best treated
as a beta period and excluded from trend analysis.

---

## Finding 06 — Do Olist customers come back after their first order?

**The question every product team needs answered:**
What percentage of customers acquired in each month return to
place another order? Is the business building a loyal base, or
is every month's revenue dependent on acquiring new buyers?

**Query approach:**
Five-stage CTE — the most complex query in this project.
First identify each customer's cohort (their first order month)
using customer_unique_id, not customer_id — a critical Olist
data trap, since one person can have multiple customer_id values
across orders. Then calculate month offsets using PERIOD_DIFF,
count cohort sizes, count active customers at each offset, and
divide to get retention %.

**Results (selected cohorts):**

**Results (cohort retention pivot — active customers):**

| Cohort | Size | m1 | m2 | m3 | m4 | m5 | m6 |
|--------|------|----|----|----|----|----|-----|
| 2017-01 | 762 | 3 | 2 | 1 | 3 | 1 | 4 |
| 2017-05 | 3,571 | 17 | 18 | 14 | 11 | 12 | 15 |
| 2017-08 | 4,162 | 28 | 14 | 11 | 15 | 22 | 12 |
| 2017-11 | 7,270 | 40 | 28 | 12 | 14 | 13 | 8 |
| 2018-01 | 6,992 | 23 | 26 | 20 | 20 | 11 | 12 |
| 2018-04 | 6,700 | 39 | 21 | 16 | 9 | — | — |

The triangle shape forms naturally — newer cohorts have fewer
months of data. Every cohort shows the same pattern: thousands
acquired at m0, single or double digits by m1. The November
2017 Black Friday cohort acquired 7,270 customers — only 40
returned the following month.

**Business insight:**
Olist's customer base is almost entirely one-time buyers.
Month-1 retention is below 1% across every single cohort —
including the massive November 2017 Black Friday cohort
(7,270 customers acquired, only 40 returned the next month).

This means Olist cannot rely on repeat revenue. Growth depends
entirely on continuously acquiring new customers. Every month's
revenue comes from that month's new buyers, not from a loyal
returning base.

The strategic question this raises: should Olist invest in
reactivation campaigns? At 0.3% retention, the ROI on email
winback or discount offers is likely near zero. The better
play is to accept the one-time buyer model and optimise for
first-order margin and customer acquisition cost.

**Critical data note:**
Using customer_id instead of customer_unique_id would make
every order appear to come from a new customer — producing
near-zero retention that's wrong for the wrong reason.
customer_unique_id is the true person identifier in this
dataset.

---

## Finding 07 — Who are Olist's most loyal customers?

**The question:**
Given that Finding 06 showed sub-1% month-1 retention across
every cohort, are there any customers who genuinely kept coming
back? And if so, how many, and how loyal are they really?

**Query approach:**
Five-stage CTE using the gaps and islands technique. First
deduplicate to one row per customer per active month. Then
assign a row number per customer ordered by month. The key
insight: subtracting the row number from the sequential month
number produces a constant for consecutive months — same
constant means same streak (island), different constant means
a gap. Count rows within each island to get streak length,
then keep each customer's longest streak.

**Results:**

| Customer (hashed) | Streak | Start | End |
|-------------------|--------|-------|-----|
| 8d50f5ea... | 7 months | 2017-05 | 2018-08 |
| 6469f99c... | 5 months | 2017-09 | 2018-06 |
| 1b6c7548... | 4 months | 2017-11 | 2018-02 |
| f0e310a6... | 3 months | 2017-05 | 2018-04 |
| e0c99ffd... | 3 months | 2017-07 | 2017-09 |
| e12f7f1e... | 3 months | 2017-08 | 2017-10 |
| 2ddc001b... | 3 months | 2017-09 | 2018-04 |
| 3e43e610... | 3 months | 2017-09 | 2018-02 |
| ca77025e... | 3 months | 2017-10 | 2018-06 |
| 935b9c5a... | 3 months | 2018-03 | 2018-05 |
| e0836a97... | 3 months | 2018-06 | 2018-08 |

**Business insight:**
Only 11 customers out of 99,441 achieved 3 or more consecutive
months of ordering. That is 0.011% of Olist's customer base.

Combined with Finding 06's sub-1% month-1 retention, these two
findings tell the same story from different angles: Olist is
structurally a one-time-buyer marketplace. People purchase a
specific item — furniture, electronics, home goods — and have
no reason to return the following month. This is not a product
failure or a retention execution problem. It is the fundamental
nature of the category.

The strategic implication: investing in loyalty programs or
reactivation campaigns would have near-zero ROI. The correct
optimisation is first-order margin and customer acquisition
efficiency — how cheaply can you acquire a customer who will
place one good order?

**Technique note:**
The gaps and islands trick (row_number subtraction) is one of
the most elegant patterns in SQL. It works because consecutive
integers minus consecutive row numbers always produce the same
constant — the moment a gap appears, the constant shifts.

---

## Finding 08 — Which sellers outperform their state's average rating?

**The question a marketplace ops team asks:**
Which sellers are delivering consistently better customer
experience than their regional peers? These are the benchmark
sellers — the ones to feature, protect, and learn from.

**Query approach:**
Two-stage CTE using a window function. First aggregate avg
rating and order count per seller, filtering to a minimum of
10 orders for statistical reliability — a seller with one
5-star review is noise, not signal. Then compute the state
average using AVG() OVER (PARTITION BY seller_state), which
calculates each state's average in one pass. Filter where
individual avg exceeds state avg.

A correlated subquery alternative was also tested — it runs
the state average calculation once per seller row rather than
once per state, producing a 3-row discrepancy (694 vs 691)
due to intermediate rounding. The window function result is
used as canonical since ROUND() is applied once at display
time only.

**Results:**
691 sellers (out of those with 10+ orders) outperform their
state average. SP (São Paulo) has the most — expected given
it has the most sellers overall. The `above_avg_by` column
shows how much each seller exceeds their state benchmark —
useful for tiering Top Seller badges (e.g. top 10% by margin).

**Business insight:**
The minimum order threshold (HAVING COUNT >= 10) is a
deliberate analytical choice — without it, sellers with one
lucky 5-star review dominate the list and the finding becomes
meaningless. This is the kind of decision that separates
analytical rigour from naive querying.

---

## Finding 09 — How much does a late delivery hurt review scores?

**The question an ops team asks:**
Delivery SLA compliance is expensive to maintain — faster
logistics, better carrier contracts, more warehouse capacity.
The business case for that investment requires knowing: what
is the actual rating penalty of a late delivery?

**Query approach:**
Two-stage CTE. First classify each delivered order as Late or
On Time by comparing order_delivered_customer_date against
order_estimated_delivery_date using DATEDIFF — positive means
late, negative means early. Join to order_reviews for the
score. Then aggregate by delivery flag, using SUM() OVER ()
with an empty window to calculate the percentage of total
orders without a self-join.

Only orders with status = 'delivered' and non-NULL timestamps
included — cancelled orders and those still in transit have
no delivery date and would break the DATEDIFF calculation.

**Results:**

| Delivery Status | Orders | % of Total | Avg Rating | Avg Days Late |
|----------------|--------|-----------|------------|---------------|
| On Time | 88,653 | 92% | 4.29 stars | -13.7 days |
| Late | 7,700 | 8% | 2.57 stars | +8.8 days |

**Business insight:**
A late delivery costs Olist 1.72 stars on average — dropping
from 4.29 to 2.57 on a 5-point scale. That is not a marginal
impact. It is the difference between a platform customers
recommend and one they warn people about.

The -13.7 average days for on-time orders is a deliberate
strategy: Olist under-promises on delivery estimates and
over-delivers in reality. Customers expecting delivery in
2 weeks receive it in under 1 week — that surprise drives
the 4.29 average rating on on-time orders.

The maximum late delivery was 188 days — someone waited
6 months past their estimated date. The worst late deliveries
are almost certainly concentrated at 1-star ratings.

**Operational implication:**
Every percentage point reduction in late delivery rate
directly improves platform average rating. If Olist reduced
late deliveries from 8% to 4%, and those orders moved from
2.57 to 4.29 average rating, the platform-wide average
would improve by approximately 0.07 stars — meaningful at
marketplace scale where rating differences drive search
ranking and seller acquisition.

---

## Finding 10 — How does payment behaviour vary across Brazilian states?

**The question a finance or growth team asks:**
Which payment methods dominate in each region, and where are
customers most dependent on installment financing? This informs
payment processor negotiations, regional promotion strategy,
and product pricing decisions.

**Query approach:**
Two-stage CTE. First join orders, customers, and payments to
get one row per order with state and payment details. Then
pivot payment types into columns using conditional aggregation
(SUM CASE WHEN payment_type = X THEN 1 ELSE 0 END) and
calculate percentages against total orders.

Note: percentages do not sum to exactly 100% because one order
can have multiple payment rows (split payments — part credit
card, part voucher). This is correct behaviour reflecting the
data model, not a calculation error.

**Results (all states with 40+ orders):**

| State | Orders | Credit Card % | Boleto % | Avg Installments | Avg Order Value |
|-------|--------|--------------|---------|-----------------|----------------|
| SP | 41,418 | 77.1% | 19.7% | 2.6 | R$137 |
| RJ | 12,766 | 80.1% | 16.8% | 3.0 | R$158 |
| MG | 11,571 | 78.0% | 19.8% | 3.0 | R$154 |
| RS | 5,441 | 72.9% | 24.9% | 3.0 | R$156 |
| PR | 5,023 | 75.0% | 22.2% | 2.9 | R$153 |
| SC | 3,618 | 74.6% | 23.2% | 2.9 | R$164 |
| BA | 3,364 | 78.7% | 18.2% | 3.2 | R$170 |
| DF | 2,133 | 79.5% | 18.5% | 2.7 | R$161 |
| GO | 2,007 | 75.3% | 22.3% | 3.0 | R$163 |
| PE | 1,647 | 80.8% | 16.8% | 3.5 | R$188 |
| CE | 1,329 | 82.0% | 15.2% | 3.5 | R$199 |
| MA | 743 | 71.7% | 27.1% | 3.1 | R$199 |
| PB | 534 | 80.0% | 17.4% | 3.8 | R$248 |
| AL | 412 | 82.5% | 16.5% | 3.7 | R$226 |
| TO | 279 | 70.3% | 27.2% | 3.0 | R$204 |
| AP | 68 | 69.1% | 29.4% | 2.6 | R$232 |
| RR | 45 | 71.1% | 28.9% | 2.8 | R$221 |

**Business insights:**

Credit card dominates everywhere (69-84%) but the pattern
across regions is counterintuitive — northern and northeastern
states show higher credit card completion rates than SP. The
likely explanation: in lower-income regions, boleto orders
have higher abandonment (customers initiate but don't pay),
so completed orders skew toward card users who convert.

Boleto usage is highest in Brazil's poorest states — AP
(29.4%), RR (28.9%), TO (27.2%), MA (27.1%). Boleto is the
payment method of the unbanked: no credit card required, pay
at any bank or lottery shop. High boleto % signals a
lower-income, price-sensitive market that Olist reaches
through affordability, not aspiration.

Installment counts and order values move together in the
North/Northeast. PB (Paraíba) averages 3.8 installments on
R$248 orders; SP averages 2.6 installments on R$137 orders.
Higher-value purchases in lower-income regions require more
installments to be affordable — the same product, spread
across more monthly payments.

**Operational implication:**
A payment processor negotiation strategy should differentiate
by region: in SP and RJ, optimise for credit card transaction
fees (highest volume). In MA, TO, and AP, boleto processing
cost matters more. Voucher usage above 8% in BA and TO
signals heavy promotional dependency — worth investigating
whether those orders are margin-positive.

---

## Finding 11 — What does a typical Olist order look like?

**The question a product or pricing team asks:**
Average order value is distorted by outliers. What does a
typical order actually cost? Where does the high-value segment
begin? And how concentrated is revenue across the order
distribution?

**Query approach:**
Two queries using NTILE(). First, NTILE(100) assigns each
order to a percentile bucket ordered by value — the 50th
percentile bucket gives the median without a native MEDIAN()
function. Second, NTILE(10) splits orders into deciles ordered
by value descending, then SUM() OVER () calculates each
decile's share of total revenue in a single pass.

Order value includes both item price and freight — the true
cost to the customer, not just the product price.

**Results — percentile distribution:**

| Percentile | Order Value Range | Avg Value |
|------------|------------------|-----------|
| 10th | R$38 - R$40 | R$39 |
| 25th | R$60 - R$62 | R$61 |
| 50th (median) | R$103 - R$105 | R$104 |
| 75th | R$173 - R$177 | R$175 |
| 90th | R$287 - R$307 | R$297 |
| 99th | R$762 - R$1,056 | R$887 |
| 100th (max) | up to R$13,664 | R$1,665 |

**Results — revenue concentration by decile:**

| Decile | Avg Order Value | Revenue Share |
|--------|----------------|---------------|
| Top 10% | R$611 | 38.1% |
| 11-20% | R$243 | 15.2% |
| 21-30% | R$178 | 11.1% |
| Bottom 10% | R$31 | 2.0% |

**Business insights:**
The median order on Olist is R$104 — a mid-range household
item, not a luxury purchase. Half of all orders fall below
this value, confirming Olist serves a mass-market, everyday
consumer rather than a premium buyer.

The top 10% of orders (above R$307) generate 38.1% of total
revenue. The top 20% generate over 53%. This is classic
Pareto concentration — the business depends heavily on a
small number of high-value orders to sustain GMV.

The maximum single order was R$13,664 — nearly 130x the
median. This kind of outlier inflates average order value
significantly, which is why median is the more honest metric
for communicating typical customer behaviour.

**Pricing and promotion implication:**
Free shipping thresholds, loyalty perks, and upsell prompts
should target the R$100-300 range — where the highest density
of orders sits and where a small nudge (add one more item)
moves customers meaningfully up the value distribution.

---

## Finding 12 — Capstone: The Complete Seller Scorecard

**The question a seller success team asks every week:**
Which sellers are genuinely performing across all dimensions —
revenue, delivery reliability, and customer satisfaction?
And critically: which high-revenue sellers are quietly
destroying platform trust with poor ratings and late deliveries?

**Query approach:**
Four-stage CTE combining five tables. Three parallel CTEs
compute revenue, delivery performance, and review quality
independently per seller. A fourth CTE joins all three,
applies minimum order thresholds, adds RANK() across all
three dimensions simultaneously, NTILE(4) for revenue
quartile, and a CASE WHEN classification into four business
segments. Everything learned in Findings 1-9 is used here.

**Seller segments defined:**
- **Star Seller:** avg rating ≥ 4.0 AND late delivery ≤ 10%
- **High Revenue Risk:** revenue > R$50K AND avg rating < 3.5
- **Quality Risk:** avg rating < 3.0
- **Standard:** all others

**Key findings from top 30 sellers:**

| Insight | Detail |
|---------|--------|
| Rank 1 by revenue | R$229K, 11.6% late, 4.13 stars — Standard, not Star Seller |
| Rank 5 — High Revenue Risk | R$188K revenue, 3.35 stars — volume masking a quality failure |
| Best overall (rank 2) | BA seller, R$223K revenue, 4.0% late, 4.08 stars — Star Seller |
| Geographic concentration | 20 of the top 30 revenue sellers are in SP |

**Business insight:**
The most important finding in the scorecard is rank 5 —
a seller doing R$188K in revenue with a 3.35 average rating.
Without a multi-dimensional view, this seller looks like a
success story. With it, they're a platform risk. High revenue
gives sellers negotiating leverage; poor quality costs the
platform in customer trust and repeat purchase rates.

The BA Star Seller at rank 2 is the counter-example: 358
orders, 4.0% late delivery, 4.08 rating, R$223K revenue. Lower
volume than rank 1 but higher quality — better platform citizen.
A marketplace's seller success strategy needs both: protect the
high-revenue sellers while elevating the high-quality ones.

20 of the top 30 revenue sellers are in SP. Olist's revenue
base is geographically concentrated — a risk if SP market
conditions change or a competitor targets SP sellers
specifically.

**This capstone demonstrates:**
Multi-table joins across 5 tables, three parallel CTEs,
simultaneous ranking across multiple dimensions, NTILE()
for quartile segmentation, conditional business logic via
CASE WHEN, and minimum threshold filtering for analytical
reliability — all in service of a single business decision
framework. Everything from Findings 01–11 feeds into this view.

**Scope caveat:** the three dimension CTEs (revenue, delivery,
reviews) are combined with INNER JOINs, so a seller only appears
in the scorecard if they have revenue, at least one delivered
order, and at least one review. Sellers with only in-transit or
cancelled orders, or no reviews yet, are silently excluded rather
than scored as zero — meaning this view undercounts newer or
slower-moving sellers. Worth stating explicitly rather than
letting a reviewer discover it by testing edge cases.