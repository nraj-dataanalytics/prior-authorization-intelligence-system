# Dashboard Tooltip and Footnote Guide — Prior Authorization Intelligence System
**Phase 4 | Power BI Dashboard Design**
**Generated: 2026-05-31**
**ALL DATA IS SYNTHETIC. Benchmark-calibrated. No PHI.**

---

## Purpose of This Document

This guide specifies two things:

1. **Footnotes** — the eight required integrity statements that must appear on every page of the dashboard, with exact wording, placement, and formatting rules.
2. **Tooltips** — the hover text for every KPI card and visual across all four dashboard pages, with the exact language a recruiter or compliance reviewer should see when they interact with the dashboard.

These are not optional additions. They are the integrity layer of the project. A dashboard that shows 92.7% approval without explaining what `final_outcome` means — versus `decision` — is analytically misleading. These footnotes and tooltips are what separates a portfolio project that looks good from one that demonstrates real payer analytics literacy.

---

## Section 1: Required Footnotes — All Pages

All eight footnotes below must appear on every page of the dashboard. Placement: bottom of the report canvas, 9pt italic, Segoe UI, color #666666. Group FN-1 through FN-3 together (they are the most critical). FN-4 through FN-8 follow on a second line.

---

### FN-1 — Benchmark Metric Source Field (CRITICAL)

**Exact wording:**
> **FN-1:** Approval and denial rate KPI cards use `final_outcome` (final administrative determination after pend resolution and appeal). They do NOT use `decision` (initial routing). Using `decision` would show 86.8% approval — not comparable to published KFF/CMS benchmarks.

**Why this is required:** The two fields produce materially different numbers. Any analyst or auditor reading this dashboard needs to know which field drives the KPIs.

**Formatting:** Bold "FN-1:" label. Monospace font for field names (`final_outcome`, `decision`). Red asterisk on any card that uses these rates.

---

### FN-2 — Field Definitions (CRITICAL)

**Exact wording:**
> **FN-2:** `decision` = initial routing outcome (Approved / Denied / Pended — 3-state, set at first review). `final_outcome` = final administrative determination after pend/appeal resolution (reflects all downstream workflow outcomes).

**Why this is required:** These two fields are confusable by name. Without this footnote, a recruiter building on this dashboard could drag the wrong field onto a benchmark comparison card.

---

### FN-3 — Synthetic Data Disclaimer (CRITICAL)

**Exact wording:**
> **FN-3:** All data is synthetic and benchmark-calibrated. No PHI. No real patient records. No real payer operational data. Synthetic data generated for portfolio analytics purposes using publicly documented MA workflow parameters.

**Why this is required:** Every page of this dashboard must be unambiguously labeled as synthetic. This protects the project and is required by the project rules.

---

### FN-4 — Service-Category Assumption

**Exact wording:**
> **FN-4:** Service-category denial risk values are assumption-based [C01–C10]. CMS public reporting does not provide PA denial rates broken down by service category. Category-level rates are calibrated from clinical complexity assumptions, not measured payer data.

**Applies especially to:** Page 2 (SLA breach by service category), Page 3 (denial rate heatmap by service category).

---

### FN-5 — Year-over-Year Trend Disclaimer

**Exact wording:**
> **FN-5:** Year-over-year trend reflects a synthetic volume distribution calibrated to national MA enrollment growth context (KFF 2023–2024 national data), not a measured payer growth rate. The 47/53 year split reflects proportional volume modeling, not a forecast or actual payer trend.

**Applies especially to:** Page 1 (monthly trend line, YoY volume stacked bar).

---

### FN-6 — Provider Friction Score Disclaimer

**Exact wording:**
> **FN-6:** Provider friction score is an illustrative operational metric computed as: (denial rate × 40%) + (SLA breach rate × 30%) + (documentation failure rate × 30%) × 100. Weights are assumption-based [ASSUMPTION G06]. This is not a real payer score and does not represent any payer's actual provider evaluation methodology.

**Applies especially to:** Page 4 (all provider friction visuals).

---

### FN-7 — CMS-0057-F Reporting Context

**Exact wording:**
> **FN-7:** CMS-0057-F (finalized January 17, 2024) requires Medicare Advantage organizations to publicly report five PA metrics beginning March 31, 2026 for CY2025. The CMS Metrics panel on Page 1 simulates this required public disclosure format. Benchmark comparisons use KFF Medicare Advantage 2024 data (Source S3).

**Applies especially to:** Page 1 (CMS Metrics panel, KPI cards with benchmark deltas).

---

### FN-8 — Decision-Support Scope Disclaimer (CRITICAL)

**Exact wording:**
> **FN-8:** This dashboard is an operational analytics and workflow decision-support tool. It does not approve or deny care. All outputs are intended for workflow prioritization, documentation review, SLA monitoring, and operational improvement — not for clinical determination of coverage.

**Why this is required:** This is a core project rule (verbatim from project instructions). Any payer analytics portfolio tool that surfaces denial rates and documentation outcomes must explicitly disclaim that it is not a clinical decision system. Absence of this footnote creates ambiguity about the purpose of the tool.

**Applies to:** All 4 pages. Especially Page 3 (Denial & Appeal) and Page 4 (Provider Friction) where the outputs most directly relate to case-level outcomes.

---

## Section 2: Footnote Placement Rules

| Rule | Specification |
|------|--------------|
| Position | Bottom of canvas, below all visuals |
| Font | Segoe UI, 9pt, italic |
| Color | #666666 (medium grey — readable but subordinate) |
| Grouping | FN-1, FN-2, FN-3 on line 1 (most critical); FN-4, FN-5, FN-6, FN-7, FN-8 on line 2 |
| Separator | Pipe character ` \| ` between footnotes on same line |
| Monospace fields | `final_outcome`, `decision`, `fact_prior_authorization` — use monospace font within Segoe UI italic |
| Page presence | All 8 footnotes appear on ALL 4 pages without exception |

---

## Section 3: Tooltip Specifications — Page 1 (Executive Overview)

### KPI Card Tooltips

**Card: Final Approval Rate (92.7%)**
> Final administrative approval rate. Includes initial approvals, pend-resolved approvals, and approvals after appeal. Source field: `final_outcome`. KFF Medicare Advantage 2024 benchmark: 92.3%. Delta: +0.4 pp above benchmark.
> Do NOT compare to the 86.8% initial approval rate — that uses `decision` (routing only).

**Card: Final Denial Rate (7.3%)**
> Final administrative denial rate. Includes initial denials and pend-resolved denials. Source field: `final_outcome`. KFF benchmark: 7.7%. Delta: −0.4 pp below benchmark (favorable). [FN-1, FN-2]

**Card: Appeal Overturn Rate (79.4%)**
> Percentage of denied PA requests that were overturned (fully or partially) on appeal. Source table: `fact_appeal`. KFF benchmark: 80.7%. Delta: −1.3 pp below benchmark. CMS-0057-F required metric M3. [FN-3]

**Card: Avg Standard TAT (4.81 days)**
> Average calendar days from submission to decision for Standard (non-urgent) requests. CMS-0057-F SLA limit: 7 calendar days. All-in compliance rate: 79.0%. CMS-0057-F required metric M4a.

**Card: Avg Expedited TAT (1.45 days)**
> Average calendar days from submission to decision for Expedited (urgent) requests. CMS-0057-F SLA limit: 3 calendar days (72 hours). All-in compliance rate: 93.8%. CMS-0057-F required metric M4b.

**Card: SLA Compliance — Overall (~81%)**
> Combined SLA compliance rate across Standard and Expedited requests. Standard weight: ~96% of volume. Expedited weight: ~4% of volume. [ASSUMPTION A10/A11] Not a CMS-required metric — operational management indicator only.

---

### Visual Tooltips — Page 1

**V1.2 — Monthly Trend Line (Requests + Denial Rate)**
> Monthly request volume (left axis) and final denial rate % (right axis), 2023–2024. Denial rate trend uses `final_outcome`. Volume reflects synthetic distribution (47% 2023 / 53% 2024) calibrated to national MA enrollment growth. [FN-5]
> Hover on a data point: Month-Year | Total Requests | Final Denial Rate % | YTD Cumulative Requests

**V1.3 — Donut Chart (Outcome Distribution)**
> Final outcome distribution for all 25,000 PA requests. Categories: Approved (direct) | Pended-Resolved-Approved | Approved-After-Appeal | Pended-Resolved-Denied | Denied (direct).
> Combined Approved slice = sum of first three categories = CMS M1 Final Approval Rate.
> Hover on a slice: Outcome Category | Count | % of Total Requests

**V1.4 — Appeal Funnel**
> PA workflow funnel showing attrition from submission through final determination. Read top to bottom: Total PA Requests → Initial Denials → Appeals Filed → Overturned → Final Denials Remaining.
> Hover on a segment: Stage Name | Count | % of Prior Stage | % of Total PA Requests

**V1.5 — Stacked Bar (Volume by Plan Type × Year)**
> Request volume by plan type (HMO / PPO / SNP / PFFS) for 2023 vs 2024. Plan type sourced from `dim_member[plan_type]`. Use to identify plan-type concentration and year-over-year volume shifts. [FN-5]
> Hover on a segment: Plan Type | Year | Request Count | % of Annual Total

**V1.6 — CMS-0057-F Metrics Table**
> Simulated annual public metrics report per CMS-0057-F requirements (effective March 31, 2026 for CY2025). All five required metrics shown with PAIS value, KFF benchmark, and delta. This format replicates what Medicare Advantage organizations must publicly file. [FN-1, FN-3, FN-7]
> Hover on a row: Metric Name | CMS Rule Reference | PAIS Value | Benchmark Source | Delta | SLA Limit (where applicable)

---

## Section 4: Tooltip Specifications — Page 2 (Delay & SLA Compliance)

### KPI Card Tooltips

**Card: Standard SLA Breach Rate (21.0%)**
> Percentage of Standard (non-urgent) PA requests that exceeded the 7-calendar-day CMS-0057-F SLA limit. Source field: `delayed_flag = TRUE` filtered to Standard requests. A breach here represents a potential CMS compliance finding. [FN-1]

**Card: Expedited SLA Breach Rate (6.2%)**
> Percentage of Expedited (urgent) PA requests that exceeded the 3-calendar-day (72-hour) CMS-0057-F SLA limit. Expedited requests represent ~4% of total volume. [ASSUMPTION A10]

**Card: Avg Standard TAT (4.81 days)**
> Average days to decision for Standard requests. Mean is within SLA, but 21% of requests breach the 7-day limit — the mean alone does not reflect the tail distribution. See histogram for P90/P95 view.

**Card: Avg Expedited TAT (1.45 days)**
> Average days to decision for Expedited requests. 72-hour limit = 3.0 calendar days. Mean of 1.45 indicates strong central tendency, but 6.2% of requests still breach. See histogram.

**Card: P95 TAT — Standard (~12 days)**
> 95th percentile decision time for Standard requests. Represents the worst-case tail — 5% of Standard requests take 12+ days, nearly double the SLA limit. Tail risk indicator for compliance exposure.

**Card: Doc Incomplete Rate (19.4%)**
> Percentage of all PA requests where `documentation_complete = FALSE`. Incomplete documentation is associated with ~40% longer average TAT and significantly higher denial rates. [ASSUMPTION A07]

---

### Visual Tooltips — Page 2

**V2.7a — Standard SLA Gauge (79.0% compliant)**
> Gauge shows Standard SLA compliance rate. Target zone: ≥95% (green). Warning zone: 85–94% (amber). Alert zone: <85% (red). Current: 79.0% (alert). CMS-0057-F 7-day limit applies. [FN-3]
> Hover: Compliance % | Breach Count | Total Standard Requests | SLA Limit

**V2.7b — Expedited SLA Gauge (93.8% compliant)**
> Gauge shows Expedited SLA compliance rate. Target zone: ≥95% (green). Warning: 88–94% (amber). Alert: <88% (red). Current: 93.8% (amber). CMS-0057-F 72-hour limit applies.
> Hover: Compliance % | Breach Count | Total Expedited Requests | SLA Limit

**V2.8 — TAT Distribution Histogram**
> Distribution of `decision_time_days` across all requests. Red vertical reference lines mark the SLA limits: 7 days (Standard) and 3 days (Expedited). The area to the right of each line represents compliance exposure.
> Hover on a bin: Day Range | Request Count | % of Total | Cumulative %

**V2.9 — Avg TAT by Submission Channel**
> Average TAT grouped by how the PA was submitted: Electronic, Fax, Portal, Phone. Channel sourced from `fact_prior_authorization[submission_channel]`. Electronic submission is associated with faster processing due to structured data intake. [ASSUMPTION A08]
> Hover on a bar: Channel | Avg TAT Days | Request Count | % Electronic vs Fax Multiplier

**V2.10 — SLA Breach Rate: Documentation Completeness Impact by Service Category**
> Grouped bar showing SLA breach rate split by documentation completeness, segmented by service category. Incomplete documentation submissions have a materially higher breach rate due to reviewer follow-up and rework cycles. Sort by incomplete-docs breach rate descending to identify highest-risk service categories. [FN-4]
> Hover: Service Category | Doc Status | SLA Breach Rate % | Avg TAT Days | Count
> Note: This visual covers both the "complete vs incomplete" comparison and the "SLA breach by service category" analysis in one cross-tab view.

**V2.11 — SLA Breach Severity Buckets**
> Stacked bar showing the breakdown of SLA breaches by severity: 1 Day Over / 2-3 Days Over / 4-7 Days Over / 8+ Days Over. Calculated column `SLA Breach Severity` in `fact_prior_authorization`. [FN-3]
> Hover: Severity Bucket | Count | % of All Breaches | Avg Days Over SLA

**V2.12 — Monthly SLA Breach Rate Trend**
> Monthly trend of overall SLA breach rate, Jan 2023 through Dec 2024. Use to identify seasonal or operational patterns in breach timing. [FN-5]
> Hover: Month-Year | Breach Rate % | Total Requests | Breach Count

---

## Section 5: Tooltip Specifications — Page 3 (Denial & Appeal Intelligence)

### KPI Card Tooltips

**Card: Initial Denial Rate (6.1%) [ROUTING ONLY]**
> Initial routing denial rate. Source field: `decision = 'Denied'`. This is NOT the benchmark-comparable metric. It represents first-pass routing before pend resolution and appeals. Do not compare to KFF 7.7% benchmark. [FN-1, FN-2]

**Card: Final Denial Rate (7.3%)**
> Final administrative denial rate after all pend resolution. Source field: `final_outcome IN ('Denied', 'Pended-Resolved-Denied')`. This is the CMS-0057-F M2 metric and the correct figure for KFF benchmark comparison. KFF benchmark: 7.7%. [FN-1]

**Card: Top Denial Reason — Documentation Incomplete (34%)**
> The most common denial reason in this dataset. Documentation Incomplete denials are operationally significant because they are preventable — a provider documentation outreach program can directly reduce this category. [ASSUMPTION A07]

**Card: Appeal Rate (11.5%)**
> Percentage of initially denied requests that were appealed. Calculated as: Appeals Filed ÷ Initial Denials. KFF benchmark: 11.5%. Exact match to benchmark. [FN-3]

**Card: Appeal Overturn Rate (79.4%)**
> Percentage of appealed cases where the denial was overturned (fully or partially). KFF benchmark: 80.7%. Delta: −1.3 pp. CMS-0057-F required metric M3. [FN-1]

**Card: Preventable Doc Denials (~520 est.)**
> Estimated count of denials where both `denial_reason = 'Documentation Incomplete'` AND `documentation_complete = FALSE`. These are the highest-priority cases for provider outreach — the denial was caused by a documentation gap that the provider could have corrected before submission. [FN-3, FN-4]

---

### Visual Tooltips — Page 3

**V3.6 — Denial Reason Distribution (Horizontal Bar)**
> Breakdown of all initial denials by reason category: Documentation Incomplete / Medical Necessity Not Met / Out-of-Network / Administrative Error / Duplicate Request. Sorted high to low. Source: `fact_prior_authorization[denial_reason]`.
> Hover: Denial Reason | Count | % of All Denials | Appeal Overturn Rate for this Reason

**V3.8 — Service Category × Denial Reason Heatmap**
> Matrix showing denial count and rate for each service category × denial reason combination. Service-category denial risk is assumption-based [C01–C10]. Use to identify where specific denial reasons concentrate by service type. [FN-4]
> Hover: Service Category | Denial Reason | Count | Denial Rate % for this Category | Assumption Code

**V3.7 — Denial-to-Appeal-to-Overturn Funnel**
> Full administrative workflow funnel: Total PA Requests → Initially Denied → Appealed → Overturned → Final Denials. Shows attrition and recovery at each stage. [FN-1, FN-3]
> Hover: Stage | Count | % of Prior Stage | % of All Requests

**V3.10 — Denial Rate by Reviewer Type**
> Grouped bar showing denial rate by who reviewed the request: Automated / Clinical Staff / Medical Director. Automated denials are typically administrative rejections (wrong format, duplicate). Clinical Staff handles standard complexity reviews. Medical Director handles escalated cases. [ASSUMPTION A09]
> Hover: Reviewer Type | Denial Rate % | Request Count | % of Total Volume

**V3.9 — Denial Rate: Complete vs Incomplete Docs by Service Category**
> Grouped bar showing how documentation completeness affects denial rate within each service category. The gap between Complete and Incomplete bars represents the preventable denial opportunity. [FN-4]
> Hover: Service Category | Doc Status | Denial Rate % | Count

**V3.11 — Appeal Outcome by Denial Reason (Stacked Bar)**
> For each denial reason, shows how appeals resolved: Overturned / Partially Overturned / Upheld. Documentation Incomplete denials have high overturn rates when additional documentation is submitted. [FN-3]
> Hover: Denial Reason | Appeal Outcome | Count | % of Appeals for this Reason | Additional Doc Submitted %

**V3.12 — Top 5 Services by Preventable Documentation Denials (Table)**
> Ranked table of service categories with the highest count of denials that were both Documentation Incomplete reason AND had incomplete documentation at submission. These are the service types where pre-submission documentation checklists would have the most impact. [FN-4]
> Columns: Rank | Service Category | Preventable Doc Denials | Total Denials | Preventable % | Avg TAT for Incomplete Submissions

---

## Section 6: Tooltip Specifications — Page 4 (Provider Friction & Operational Action)

### KPI Card Tooltips

**Card: High-Risk Providers (~200 / 20%)**
> Count of providers with `provider_risk_segment = 'High-Risk'` in `dim_provider`. Risk segment is pre-assigned in the dimension table based on historical submission patterns. 20% of providers generate disproportionate PA workflow friction. [ASSUMPTION G01–G03]

**Card: OON vs In-Network Denial Rate (~1.8×)**
> Out-of-Network providers have approximately 1.8× the denial rate of In-Network providers. Source: `dim_provider[network_status]`. This multiplier reflects network contract compliance and documentation submission differences. [ASSUMPTION G03]

**Card: Avg Doc Incomplete Rate (19.4%)**
> Average documentation incomplete rate across all 1,000 providers. This is the most actionable improvement lever — providers with above-average doc failure rates are prime outreach targets. Source: `dim_provider[avg_incomplete_submission_rate]`.

**Card: Top Friction Provider Type**
> Provider type with the highest average Provider Friction Score across all requests. Sourced from live data — value will vary by filter context. [FN-6]

**Card: Providers Needing Outreach (Top 10)**
> The 10 providers with the highest Provider Friction Score among those with ≥10 PA requests in the selected period. This is the operational action list — not a ranking for display but a prioritized outreach queue. [FN-6]

---

### Visual Tooltips — Page 4

**V4.6 — Provider Friction Scatter Plot**
> Each bubble = one provider. X-axis: Provider Friction Score (0–100). Y-axis: Total PA request volume. Bubble size: Count of denied requests. Color: provider_risk_segment (Low = green / Moderate = amber / High = red). Target quadrant: top-right (high volume + high friction) = highest outreach priority. [FN-6]
> Hover: Provider ID | Provider Type | Friction Score | Total Requests | Denial Count | Doc Incomplete Rate | SLA Breach Rate

**V4.9 — Denial Rate by Provider Type (Horizontal Bar)**
> Average denial rate across all providers of each type (Primary Care / Specialist / Hospital / Imaging / DME / Other). Sorted high to low. Use to identify whether certain provider types systematically generate higher denial rates. [FN-3]
> Hover: Provider Type | Avg Denial Rate % | Provider Count | Avg Friction Score

**V4.7 — In-Network vs Out-of-Network Comparison (Grouped Bar)**
> Three-metric grouped bar comparing In-Network vs Out-of-Network providers: Denial Rate / SLA Breach Rate / Doc Incomplete Rate. OON multipliers are assumption-based [ASSUMPTION G03]. [FN-6]
> Hover: Network Status | Metric | Value % | Count | OON vs INN Multiplier

**V4.11 — Provider Risk Segment × Denial Rate**
> Bar chart showing average denial rate for each provider risk segment (Low / Moderate / High). Demonstrates that risk segment is a useful predictor of denial likelihood. Risk segment pre-assigned in `dim_provider`. [ASSUMPTION G01]
> Hover: Risk Segment | Avg Denial Rate % | Provider Count | Avg Friction Score

**V4.8 — Top 10 Highest-Friction Provider Table**
> Actionable outreach list. Sorted by Provider Friction Score (descending). Minimum 10 requests required for inclusion. Each row = one provider to contact for documentation improvement. The `doc_incomplete_rate` column is the most operationally actionable — it tells you what the outreach call is about. [FN-6]
> Columns: Rank | Provider ID | Provider Type | Network Status | Friction Score | Denial Rate % | SLA Breach Rate % | Doc Incomplete Rate % | Total Requests

**V4.10 — Documentation Failure Rate by Provider Type (Stacked Bar)**
> Shows what proportion of each provider type's submissions have incomplete documentation. DME and specialty categories typically have higher documentation failure rates due to complexity and clinical documentation requirements. [ASSUMPTION C01–C10]
> Hover: Provider Type | Doc Incomplete Rate % | Count | % of Provider Type Submissions

**V4.12 — PA Volume and Denial Rate by Provider Region (Map)**
> Geographic distribution of PA request volume and denial rate by provider region. Bubble size = volume. Color = denial rate (green → red). Use to identify geographic concentration of friction or regional patterns. If geo data is not available for all providers, this visual may show a subset. [FN-3]
> Hover: Region | Total Requests | Denial Rate % | Avg Friction Score | Provider Count in Region

---

## Section 7: Global Slicer and Navigation Tooltips

**Year Slicer (2023 / 2024 / Both)**
> Filter all dashboard pages to a specific calendar year or view the full 2023–2024 synthetic period. [FN-5]

**Plan Type Slicer (HMO / PPO / SNP / PFFS)**
> Filter all pages by Medicare Advantage plan type. Plan type sourced from `dim_member[plan_type]`. HMO and PPO represent the largest volume segments.

**Request Type Slicer (Standard / Expedited)**
> Filter all pages by PA urgency classification. Expedited requests (~4% of volume) are subject to 72-hour SLA vs 7-day for Standard. [ASSUMPTION A10]

**Region Slicer**
> Filter all pages by provider geographic region. Sourced from `dim_provider[region]`.

**Navigation Tabs**
> Tab 1: Executive Overview — Compliance and outcome summary | Tab 2: Delay & SLA — Turnaround time operations | Tab 3: Denial & Appeal — Denial drivers and appeal pipeline | Tab 4: Provider Friction — Provider-level operational action

---

## Section 8: Error State and Empty State Messages

These messages should display when a visual has no data for the current filter selection.

| Situation | Message |
|-----------|---------|
| No appeals in filter | "No appeals recorded for the selected filter. Adjust the Year or Plan Type slicer." |
| No OON providers in filter | "No Out-of-Network providers in current selection. Remove Network Status filter." |
| Provider table < 3 rows | "Insufficient providers meet the minimum request threshold for this filter." |
| No SLA breaches in filter | "No SLA breaches in current selection — all requests met the turnaround requirement." |
| Map: no geo data | "Geographic data not available for all providers in current selection." |

---

## Section 9: Benchmark Reference Card

This panel should appear as a pinned reference box on each page (top-right corner, white background, 9pt text, thin grey border). It provides the benchmark context without requiring the user to hover over each card.

**Exact content:**

> **KFF Medicare Advantage 2024 Benchmarks (Source S3)**
> Approval Rate: 92.3% | Denial Rate: 7.7% | Appeal Rate: 11.5% | Overturn Rate: 80.7%
> **CMS-0057-F SLA Limits**
> Standard: 7 calendar days | Expedited: 72 hours (3 calendar days)
> All benchmark comparisons use `final_outcome`. [FN-1, FN-7]
> This dashboard does not approve or deny care. [FN-8]

---

*Dashboard Tooltip and Footnote Guide — Phase 4. Last updated: 2026-05-31 (revised: FN-8 added; visual numbering reconciled with dashboard_visual_specification.md)*
