# docs — Business Documentation

Supporting documents for the Olist Marketplace Analytics project. Designed to be read alongside the SQL queries and dashboard — they explain the business *thinking* behind the technical work.

---

## Files

| File | What It Contains |
|---|---|
| `business_case.md` | Detailed write-up of all 12 analytical findings — business question, SQL approach, results, and business interpretation for each |
| `olist_data_model.svg` | Star schema diagram — the 8-table data model with relationship lines |

---

## `business_case.md`

A 12-finding business case document written from the perspective of an analyst presenting findings to a marketplace leadership team. Each finding follows the same structure:

1. **The question a real team actually asks** — not "show me the data" but the specific decision the analysis is meant to support
2. **SQL approach** — the technique used and *why* that technique was chosen over alternatives
3. **Results** — the actual numbers from the dataset
4. **Business insight** — what the numbers mean for platform strategy, not just what they show

This document is the written equivalent of presenting your work in an analytics interview. Read it if you want to understand the business reasoning behind the technical choices.

**Findings covered:**

| Finding | Question |
|---|---|
| 01 | Which sellers dominate each product category? |
| 02 | Which cities drive orders per state? |
| 03 | What does Olist's revenue trajectory look like? |
| 04 | How has each category's order volume accumulated? |
| 05 | Is Olist's revenue growth accelerating or slowing? |
| 06 | Do Olist customers come back after their first order? |
| 07 | Who are Olist's most loyal customers? |
| 08 | Which sellers outperform their state's average rating? |
| 09 | How much does a late delivery hurt review scores? |
| 10 | How does payment behaviour vary across Brazilian states? |
| 11 | What does a typical Olist order look like? |
| 12 | Capstone: The complete seller scorecard |

---

## `olist_data_model.svg`

A vector diagram of the 8-table star/galaxy schema. Open in any browser or SVG viewer. Useful for understanding table relationships before reading the SQL queries — especially which join paths exist between fact tables and which dimensions are shared.

---

## Where to start

If you're short on time: Finding 06 (retention) and Finding 12 (seller scorecard) in `business_case.md` show the analytical depth. Add Finding 09 (delivery penalty) and the NLP section of the main README for the full narrative.

For a complete picture: read all 12 findings alongside the SQL files in `sql/02_findings/` — each SQL file is documented to match its corresponding finding in the business case.

---

*Author: Brijesh Vaghela | [LinkedIn](https://www.linkedin.com/in/brijesh-vaghela)*
