# Olist Marketplace Analytics: Business Case & Strategic Insights

**Marketplace Growth Dynamics, Customer Lifetime Value & Operational Friction**  
*Author: Girish G Gowda | [GitHub](https://github.com/GirishGowdaG)*

---

## Executive Summary

Operating a nationwide e-commerce marketplace across Brazil requires balancing multi-party incentives: acquiring buyers across 27 distinct federal states, maintaining healthy seller margins, and mitigating volatile cross-regional logistics bottlenecks.

This business case evaluates 99,441 orders on the Olist marketplace (2016–2018), analyzing R$13.5M in gross merchandise value (GMV). By combining relational database analytics in MySQL, natural language processing on 42,370 Brazilian Portuguese reviews, and executive visualization in Power BI, this study deconstructs the operational levers driving customer repeat behavior, seller retention, and platform margin.

---

## 12 Strategic Business Findings

### Finding 01: The Regional Freight Burden Index (FBI)
* **Problem**: In a continental market where most manufacturing is concentrated in the Southeast (SP, RJ, MG), how does inter-state shipping cost affect order economics?
* **Analysis**: Aggregated gross product revenue and shipping freight across Brazil's 5 macro-regions (`sql/analysis/01_regional_freight_burden.sql`).
* **Result**:
  - **Southeast (Core)**: Freight averages **R$17.16** (14.2% Freight Burden Ratio). Average rating: **4.16★**.
  - **North & Northeast (Peripheral)**: Freight averages **R$38.85 – R$42.10** (28.4% – 31.6% Freight Burden Ratio). Average rating drops to **3.82★ – 3.91★**.
* **Strategic Takeaway**: Cross-regional logistics imposes a 30%+ price surcharge on non-Southeast consumers, directly eroding customer review scores. Olist must incentivize regional seller onboarding in the North and Northeast to reduce inter-state transit distances.

---

### Finding 02: Deconstructing Fulfillment Latency (Seller vs. Carrier)
* **Problem**: When customers experience late deliveries, is the bottleneck merchant dispatch latency or carrier transit delay?
* **Analysis**: Partitioned total delivery cycle time into Seller Handling Time (order approval to carrier handover) and Carrier Transit Time (carrier handover to customer delivery) (`sql/analysis/02_fulfillment_latency_deconstruction.sql`).
* **Result**:
  - **On-Time Orders (91.9%)**: Average seller dispatch is **2.8 days**; carrier transit is **8.9 days** (Total: **12.1 days**).
  - **Late Orders (8.1%)**: Average seller dispatch increases to **3.4 days**, but carrier transit surges to **23.7 days** (Total: **27.6 days**).
* **Strategic Takeaway**: **86% of delay latency occurs after the carrier accepts the parcel.** While sellers maintain relatively consistent dispatch discipline, carrier transit network volatility is the primary failure mode.

---

### Finding 03: Category Seller Concentration & Platform Risk
* **Problem**: Is platform category revenue diversified or concentrated among a few dominant sellers?
* **Analysis**: Measured GMV share controlled by the Top 1 and Top 3 merchants across mature product verticals (`sql/analysis/03_seller_concentration_risk.sql`).
* **Result**:
  - Categories like `bed_bath_table` and `watches_gifts` exhibit over **45% revenue concentration** within the top 3 sellers.
  - In `bed_bath_table`, the top 2 sellers generate nearly 3× the revenue of the third-ranked seller.
* **Strategic Takeaway**: Excessive merchant concentration creates severe platform risk. If a top seller leaves or experiences supply disruptions, category revenue collapses. Olist should establish seller diversification incentives in high-risk categories.

---

### Finding 04: Customer Repeat Purchase Dynamics & Basket Economics
* **Problem**: What proportion of customers return to make a second purchase, and what is their economic value?
* **Analysis**: Grouped customers by `customer_unique_id` to evaluate order frequency, basket value, and customer lifespan (`sql/analysis/04_repeat_customer_dynamics.sql`).
* **Result**:
  - **97.0%** of buyers make exactly one purchase.
  - **3.0%** of buyers return for 2 or more orders.
  - Repeat customers spend **R$178.40 per order** compared to **R$136.20** for first-time buyers (+31% higher AOV).
* **Strategic Takeaway**: Olist is functionally an acquisition-driven marketplace for durable/infrequent goods (furniture, electronics). Rather than expensive loyalty programs that fight structural product buying cycles, Olist should optimize first-order margins and acquisition efficiency.

---

### Finding 05: Payment Financing & Installment Leverage
* **Problem**: How do consumer financing mechanisms (installments) affect purchasing power?
* **Analysis**: Evaluated payment method mix, installment distributions, and order completion rates (`sql/analysis/05_payment_method_economics.sql`).
* **Result**:
  - **Credit Card** accounts for **75.2%** of volume, with an average installment count of **3.5x**.
  - **High-ticket orders (> R$300)** average **6.2 installments**.
  - **Boleto Bancário** represents **19.4%** of transactions and serves unbanked or credit-constrained populations with 100% upfront settlement.
* **Strategic Takeaway**: Installment financing is essential for marketplace conversion in Brazil. Olist must maintain strong acquirer relationships to keep installment merchant discount rates (MDR) competitive.

---

### Finding 06: Carrier SLA Error Distribution & Buffer Predictability
* **Problem**: How accurate are Olist’s promised delivery dates across destination states?
* **Analysis**: Calculated delivery buffer variance (estimated delivery date minus actual delivery date) by state (`sql/analysis/06_carrier_sla_buffer_reliability.sql`).
* **Result**:
  - Overall, orders arrive an average of **11.2 days before the estimated date**.
  - However, the standard deviation of this buffer is **8.4 days**, with extreme volatility in peripheral states (AL, MA, PA).
* **Strategic Takeaway**: Olist heavily pads its delivery promises to preserve on-time statistics. While this creates a pleasant surprise for urban customers, wide buffer variance in peripheral states indicates unpredictable logistics scheduling. Dynamic, route-specific estimation models are needed.

---

### Finding 07: Product Physicality & Transport Friction
* **Problem**: Do product categories with lower satisfaction suffer from product quality issues or freight challenges?
* **Analysis**: Correlated product weight, dimensional volume, freight spend, transit days, and review ratings (`sql/analysis/07_product_vertical_economics.sql`).
* **Result**:
  - Bulky categories (e.g., `furniture_decor`, `office_furniture`) average **8.5 kg – 14.2 kg** per item.
  - Freight costs for heavy goods represent **25% – 35% of product price**, and transit times are **40% longer**.
  - Customer review scores for bulky items average **3.78★ – 3.92★**, compared to **4.25★** for lightweight categories (`health_beauty`, `fashion`).
* **Strategic Takeaway**: Heavy items suffer from freight friction, carrier mishandling, and transit delays that depress review ratings independently of product quality. Specialized bulky-item logistics partners should be contracted.

---

### Finding 08: Geographic GMV Trajectory & Expansion
* **Problem**: Has marketplace revenue expanded outside the industrial core of São Paulo?
* **Analysis**: Truncated quarterly GMV from 2016-Q4 through 2018-Q3 by destination macro-region (`sql/analysis/08_regional_expansion_trajectory.sql`).
* **Result**:
  - In 2016-Q4, São Paulo accounted for **48.2%** of total marketplace GMV.
  - By 2018-Q3, São Paulo's share moderated to **39.4%**, with Southern states expanding to **16.1%** and the Northeast growing to **15.2%**.
* **Strategic Takeaway**: Marketplace demand is steadily decentralizing toward emerging regional hubs across the South and Northeast, creating urgent need for decentralized fulfillment centers.

---

### Finding 09: Seller Operational Reliability Matrix
* **Problem**: How can Olist segment its 3,000+ merchants into actionable operational tiers?
* **Analysis**: Categorized sellers with >= 30 orders based on dispatch speed, SLA compliance, and customer ratings (`sql/analysis/09_seller_operational_reliability.sql`).
* **Result**:
  - **Tier 1 (Elite Operators)**: Dispatch <= 48 hrs, Rating >= 4.2★, Late <= 5% (Represent **22%** of sellers, generating **41%** of GMV).
  - **Tier 2 (Fast Dispatch / Product Quality Risk)**: Dispatch <= 48 hrs, Rating < 4.0★ (Represent **9%** of GMV; fast fulfillment cannot mask defective merchandise).
  - **Tier 3 (Dispatch Bottlenecks)**: Dispatch > 72 hrs, Late > 15% (Represent **8%** of sellers, causing disproportionate platform NPS damage).
  - **Tier 4 (Standard Merchants)**: Remaining marketplace sellers.
* **Strategic Takeaway**: Olist should implement tier-based merchant benefits: preferential search placement and fee rebates for Tier 1, and mandatory operational review or delisting for chronic Tier 3 bottlenecks.

---

### Finding 10: Portuguese Review Sentiment across Categories
* **Problem**: Which product verticals generate the highest proportion of negative sentiment in customer reviews?
* **Analysis**: Scored 42,370 free-text reviews using BerTweet-PT and joined with product categories (`sql/analysis/10_category_sentiment_profile.sql`).
* **Result**:
  - Categories with the highest negative sentiment share include `office_furniture` (**28.4% NEG**), `audio` (**24.2% NEG**), and `telephony` (**22.8% NEG**).
  - Highly satisfied categories include `books_general_interest` (**68.1% POS**) and `health_beauty` (**61.4% POS**).
* **Strategic Takeaway**: High-negativity categories require vendor quality audits, clearer sizing/specification documentation on product pages, and improved transit packaging standards.

---

### Finding 11: Voice of Customer Root-Cause Complaint Taxonomy
* **Problem**: What specific operational and product failures do customers report in negative reviews?
* **Analysis**: Applied a negation-aware rule-based text classifier to extract complaint drivers (`sql/analysis/11_customer_complaint_taxonomy.sql`).
* **Result**:
  - **Late or Non-Delivery**: Represents **33.3%** of all negative feedback citations.
  - **Wrong or Incomplete Product**: **10.1%** of negative citations.
  - **Refund / Cancellation Requests**: **10.0%** of negative citations.
  - **Damaged or Defective Goods**: **8.0%** of negative citations.
* **Strategic Takeaway**: Over one-third of customer dissatisfaction stems directly from fulfillment timing. Eliminating fulfillment delays would resolve the single largest driver of brand detraction.

---

### Finding 12: Order Cancellation & Attrition Friction
* **Problem**: At what stage do order cancellations occur and what is the lost revenue impact?
* **Analysis**: Evaluated order statuses across customer locations and order item values (`sql/analysis/12_order_cancellation_friction.sql`).
* **Result**:
  - **0.63%** of orders are canceled (625 orders) and **0.61%** are marked unavailable (609 orders).
  - Together, these represent approximately **R$210,000 in lost GMV** and customer dissatisfaction.
  - Over **60% of cancellations occur prior to carrier dispatch**, pointing to inventory inaccuracy and seller stockouts as the primary drivers.
* **Strategic Takeaway**: Real-time inventory synchronization between seller ERPs and Olist's catalog is critical to eliminate unfulfillable orders.

---

*Author: Girish G Gowda | [GitHub](https://github.com/GirishGowdaG)*