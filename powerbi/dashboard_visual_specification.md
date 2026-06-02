# Dashboard Visual Specification — Prior Authorization Intelligence System
**Phase 4 | Power BI Dashboard Design**
**Generated: 2026-05-31**

This document provides a complete per-visual specification for all 43 visuals across the four dashboard pages. Each entry covers: visual type, data source, fields, filters, formatting, conditional formatting, and cross-page interactions.

---

## Page 1: Executive Overview

### V1.1 — Final Approval Rate (KPI Card)
**Type:** Card visual with benchmark delta
**Measure:** `CMS M1 - Final Approval Rate %`
**Format:** `0.0"%"`
**Subtitle line 1:** `"KFF 2024 Benchmark: 92.3%"`
**Subtitle line 2:** `Delta vs KFF - Approval Rate` formatted as `+0.0%;-0.0%`
**Conditional formatting (card background):** Green if delta ≥ 0, amber if -1 to 0, red if < -1
**Tooltip:** "Final approval rate uses final_outcome field (administrative final determination). Initial routing approval rate is 86.8% — not comparable to this benchmark. Source: KFF MA PA 2024."
**Footnote:** FN-1, FN-2

### V1.2 — Final Denial Rate (KPI Card)
**Type:** Card visual with benchmark delta
**Measure:** `CMS M2 - Final Denial Rate %`
**Format:** `0.0"%"`
**Subtitle:** KFF benchmark 7.7%
**Conditional formatting:** Green if denial rate ≤ 7.7%, amber if 7.7–10%, red if > 10%
**Tooltip:** Same final_outcome framing as V1.1

### V1.3 — Appeal Overturn Rate (KPI Card)
**Type:** Card
**Measure:** `CMS M3 - Appeal Overturn Rate %`
**Format:** `0.0"%"`
**Subtitle:** KFF benchmark 80.7%
**Conditional formatting:** Green ≥ 80%, amber 75–80%, red < 75%

### V1.4 — Avg Standard TAT (KPI Card)
**Type:** Card
**Measure:** `CMS M4a - Avg Standard TAT Days`
**Format:** `0.00" days"`
**Subtitle:** "CMS-0057-F SLA: 7 days | Industry benchmark: 5.0 days"
**Conditional formatting:** Green ≤ 5 days, amber 5–7 days, red > 7 days

### V1.5 — Avg Expedited TAT (KPI Card)
**Type:** Card
**Measure:** `CMS M4b - Avg Expedited TAT Days`
**Format:** `0.00" days"`
**Subtitle:** "CMS-0057-F SLA: 3 days (72 hours) | Benchmark: 1.5 days"
**Conditional formatting:** Green ≤ 2 days, amber 2–3 days, red > 3 days

### V1.6 — Overall SLA Compliance Rate (KPI Card)
**Type:** Card
**Measure:** `100 - [SLA Breach Rate %]`
**Format:** `0.0"%"`
**Subtitle:** "[ASSUMPTION A10/A11] — no public benchmark"

### V1.7 — Monthly Volume & Denial Trend (Combo Chart)
**Type:** Line and Clustered Column Chart
**Source:** `vw_monthly_volume_trend`
**X-axis:** `year_month` (sort ascending)
**Column series:** `total_requests` — left y-axis — color #0057A8
**Line series:** `final_denial_rate_pct` — right y-axis — color #C0392B
**Right y-axis:** 0–15% range, labeled "Final Denial Rate %"
**Left y-axis:** auto-scale, labeled "Total PA Requests"
**Reference line:** Horizontal on right axis at 7.7 (KFF benchmark)
**Data labels:** Off for columns; on for line at Dec 2023 and Dec 2024 only
**Tooltip fields:** year_month, total_requests, final_denial_rate_pct, avg_turnaround_days
**Footnote on visual:** FN-5 (YoY trend is synthetic volume distribution)

### V1.8 — Final Outcome Distribution (Donut Chart)
**Type:** Donut chart
**Source:** `fact_prior_authorization`
**Legend:** `final_outcome`
**Values:** `Total PA Requests` measure
**Colors:**
- Approved → #27AE60 (green)
- Pended-Resolved-Approved → #58D68D (light green)
- Approved-After-Appeal → #1A5276 (dark blue)
- Denied → #C0392B (red)
- Pended-Resolved-Denied → #E74C3C (light red)
**Center label:** Total count (25,000)
**Tooltip:** Each slice shows value, % of total, and final_outcome label
**Note:** This visual correctly shows 5-state final_outcome, NOT 3-state decision

### V1.9 — PA to Final Outcome Funnel (Funnel Chart)
**Type:** Funnel chart
**Source:** `vw_appeal_funnel`
**Stages (top to bottom):**
1. total_pa_requests — "Total PA Requests"
2. initial_denials — "Initially Denied"
3. appeals_filed — "Appeals Filed"
4. overturned_count — "Appeals Overturned"
5. final_denied — "Final Denied"
**Color:** Gradient from #0057A8 (top) to #C0392B (bottom)
**Data labels:** Value + % conversion from previous stage
**Tooltip:** KFF benchmark at each stage

### V1.10 — Volume by Plan Type (Stacked Bar)
**Type:** Stacked bar chart
**Source:** `fact_prior_authorization` JOIN `dim_member`
**X-axis:** `dim_member[plan_type]`
**Y-axis:** `Total PA Requests`
**Legend:** `dim_date[Year]`
**Colors:** 2023=#5DADE2, 2024=#0057A8
**Tooltip:** plan_type, year, count, % of plan type total
**Note:** FN-5 applies — 2024 higher volume reflects synthetic volume distribution

### V1.11 — CMS-0057-F Metrics Summary Table
**Type:** Table visual
**Source:** `vw_cms_public_metrics`
**Columns:** cms_metric_id, metric_name, metric_value, unit, kff_2024_benchmark, benchmark_source
**Conditional formatting (metric_value column):**
- M1 (approval rate): green if ≥ 91%, amber if 88–91%, red if < 88%
- M2 (denial rate): green if ≤ 8%, amber if 8–10%, red if > 10%
- M3 (overturn): green if ≥ 79%, amber if 75–79%, red if < 75%
**Title:** "CMS-0057-F Required Public Metrics — Annual Reporting Simulation"
**Footnote in table caption:** "Simulated using synthetic benchmark-calibrated data"

---

## Page 2: Delay & SLA Compliance

### V2.1–V2.6 — KPI Cards
See dashboard_page_plan.md Row 1 specifications. Apply same conditional formatting logic as Page 1 cards: green = within target, amber = approaching limit, red = over limit.

**V2.1 Standard SLA Breach Rate:** Red if > 20%, amber 15–20%, green < 15%
**V2.2 Expedited SLA Breach Rate:** Red if > 10%, amber 7–10%, green < 7%
**V2.3 Avg Standard TAT:** Same thresholds as V1.4
**V2.4 Avg Expedited TAT:** Same as V1.5
**V2.5 P95 Standard TAT:** Measure = `PERCENTILEX.INC(FILTER(...), [decision_time_days], 0.95)` — Red if > 14 days
**V2.6 Doc Incomplete Rate:** Amber if > 15%, red if > 25%

### V2.7 — SLA Compliance Gauges (2 Gauge Charts)
**Type:** Gauge chart × 2 (side by side)
**Source:** `vw_sla_compliance_summary`
**Gauge 1 — Standard:**
- Value: `Standard SLA Compliance Rate %`
- Minimum: 0, Maximum: 100
- Target: 82 [ASSUMPTION A10]
- Color zones: 0–75=red, 75–82=amber, 82–100=green
- Title: "Standard SLA Compliance (7-day limit)"
**Gauge 2 — Expedited:**
- Value: `Expedited SLA Compliance Rate %`
- Minimum: 0, Maximum: 100
- Target: 90 [ASSUMPTION A11]
- Same color zones
- Title: "Expedited SLA Compliance (3-day limit)"
**Both gauges:** Subtitle "CMS-0057-F requirement — [ASSUMPTION A10/A11] target"

### V2.8 — Decision Time Histogram
**Type:** Column chart (configured as histogram)
**Source:** `fact_prior_authorization`
**X-axis:** `decision_time_days` grouped into buckets (0–1, 1–2, 2–3, 3–5, 5–7, 7–10, 10–15, 15+)
**Y-axis:** Count of requests
**Two series:** Standard (blue) / Expedited (teal)
**Reference lines:**
- Vertical at x=7: "Standard SLA Limit (7 days)" — dashed red
- Vertical at x=3: "Expedited SLA Limit (3 days)" — dashed orange
**Note:** Power BI does not have a native histogram — use a calculated group column or binning

### V2.9 — Avg TAT by Submission Channel (Grouped Bar)
**Type:** Clustered bar chart
**Source:** `vw_submission_channel_analysis`
**X-axis:** `submission_channel`
**Y-axis:** `avg_turnaround_days`
**Second metric bar:** `sla_breach_rate_pct`
**Color:** Electronic=#27AE60, Fax=#E74C3C, Portal=#F39C12, Phone=#5DADE2
**Annotation on Fax bar:** "1.25× delay multiplier [Assumption G05]"
**Sort:** By avg_turnaround_days descending

### V2.10 — SLA Breach by Documentation Status × Service Category (Grouped Bar)
**Type:** Clustered bar chart
**Source:** `vw_documentation_impact` cross-tabbed with service category
**X-axis:** `service_category`
**Y-axis:** `sla_breach_rate_pct`
**Two bars per category:** Complete docs (green) / Incomplete docs (red)
**Sort:** By incomplete docs SLA breach rate descending
**Title:** "SLA Breach Rate: Documentation Impact by Service Category"

### V2.11 — SLA Breach Severity (Stacked Bar)
**Type:** 100% stacked bar
**Source:** `fact_prior_authorization` with `SLA Breach Severity` calculated column
**X-axis:** `request_type`
**Legend:** SLA Breach Severity (On Time, 1 Day, 2-3 Days, 4-7 Days, 8+ Days)
**Colors:** On Time=#27AE60, 1 Day=#F39C12, 2-3 Days=#E67E22, 4-7 Days=#E74C3C, 8+=#922B21
**Show data labels:** On (% of total)

### V2.12 — Monthly SLA Breach Trend (Line Chart)
**Type:** Multi-line chart
**Source:** `vw_monthly_volume_trend`
**X-axis:** `year_month`
**Lines:** sla_breach_rate_pct (Standard only vs Expedited only, filtered by request_type slicer)
**Reference lines:** 18% (Standard assumption target) / 10% (Expedited) — dashed
**Annotation on reference lines:** "[ASSUMPTION A10/A11]"

---

## Page 3: Denial & Appeal Intelligence

### V3.1–V3.5 — KPI Cards
Standard card format. V3.5 (Preventable Doc Denials) uses `Preventable Doc Denials` measure formatted as `#,0`.

### V3.6 — Denial Reason Distribution (Horizontal Bar)
**Type:** Horizontal bar chart
**Source:** `fact_prior_authorization` filtered to `decision = "Denied"`
**Y-axis:** `denial_reason` (sorted by count descending)
**X-axis:** `Denial Reason Share %`
**Color:** Documentation Incomplete=#E67E22 (amber — preventable), all others=#0057A8
**Data labels:** Both percentage and count
**Reference bands:** Dotted lines at assumption target % for each reason
**Annotation on Documentation Incomplete bar:** "Preventable — documentation outreach opportunity"

### V3.7 — Denial-to-Appeal Funnel (Funnel Chart)
Same specification as V1.9 but with KFF benchmarks displayed at each stage as callout labels.

### V3.8 — Service Category Denial Heatmap (Matrix)
**Type:** Matrix visual
**Source:** `fact_prior_authorization` JOIN `dim_service`
**Rows:** `service_category`
**Columns:** `denial_reason`
**Values:** Count of denied requests
**Conditional formatting:** White (0) → Red (highest count) color scale
**Row totals:** On (total denials per service category)
**Column totals:** On (total denials per reason)
**Note FN-4:** "Service-category denial patterns are assumption-based [C01-C10]" — in visual title

### V3.9 — Documentation Impact on Denial by Service (Grouped Bar)
**Type:** Clustered column chart
**Source:** Denial rate grouped by documentation_complete × service_category
**X-axis:** service_category
**Y-axis:** denial rate %
**Two bars:** Complete docs (green) / Incomplete docs (red)
**Title:** "Documentation Completeness Impact on Denial Rate by Service Category"
**Data label:** Delta between bars (e.g., "+8.8pp with incomplete docs")

### V3.10 — Denial Rate by Reviewer Type (Bar Chart)
**Type:** Clustered column chart
**Source:** `vw_reviewer_type_outcomes`
**X-axis:** reviewer_type
**Y-axis:** denial_rate_pct
**Colors:** Automated=#27AE60, Clinical Staff=#F39C12, Medical Director=#C0392B
**Annotation on Automated bar:** "0.4× denial multiplier [Assumption G04]"
**Subtitle:** "Automated reviewer has lowest denial rate. Medical Director handles most clinically complex cases."

### V3.11 — Appeal Outcome by Denial Reason (Stacked Bar)
**Type:** 100% stacked bar
**Source:** `fact_appeal` JOIN `fact_prior_authorization`
**X-axis:** denial_reason (from linked PA record)
**Legend:** appeal_outcome (Overturned / Partially Overturned / Upheld)
**Colors:** Overturned=#27AE60, Partial=#F39C12, Upheld=#C0392B
**Sort:** By overturn rate descending
**Title:** "Appeal Outcomes by Denial Reason — Which Denials Are Most Successfully Challenged?"

---

## Page 4: Provider Friction & Operational Action

### V4.1–V4.5 — KPI Cards
V4.1 High-Risk Providers count: `CALCULATE(COUNTROWS(dim_provider), dim_provider[provider_risk_segment]="High-Risk")`
V4.3 OON Denial Multiplier: `OON Denial Multiplier` measure, format `0.0"×"`, amber if < 1.5, red if ≥ 1.5

### V4.6 — Provider Friction Scatter Plot
**Type:** Scatter chart
**Source:** `vw_provider_scorecard`
**X-axis:** `total_requests` (PA volume)
**Y-axis:** `friction_score`
**Bubble size:** `denied_count`
**Color:** provider_risk_segment (Low-Risk=#27AE60, Moderate-Risk=#F39C12, High-Risk=#C0392B)
**Tooltip fields:** provider_id, provider_type, network_status, friction_score, denial_rate_pct, sla_breach_rate_pct, doc_incomplete_rate_pct
**Reference line:** Horizontal at friction_score=15 — "Outreach threshold"
**Title caption:** "Friction Score = 40% Denial + 30% Delay + 30% Doc Failure [Illustrative weights — FN-6]"

### V4.7 — In-Network vs Out-of-Network Comparison (Grouped Bar)
**Type:** Clustered bar chart
**Source:** `fact_prior_authorization` JOIN `dim_provider`
**X-axis:** Three metric groups (Denial Rate / SLA Breach / Doc Incomplete)
**Two bars per group:** In-Network (blue) / Out-of-Network (red)
**Data labels:** Value on each bar
**Annotation:** "1.8× OON denial multiplier [Assumption G03]"

### V4.8 — Top 10 Provider Scorecard Table
**Type:** Table visual
**Source:** `vw_provider_scorecard` filtered to TOP 10 by friction_score
**Columns:** provider_id, provider_type, network_status, provider_risk_segment, total_requests, denial_rate_pct, sla_breach_rate_pct, doc_incomplete_rate_pct, friction_score
**Column formatting:**
- denial_rate_pct: Red > 10%, amber 6–10%, green ≤ 6%
- doc_incomplete_rate_pct: Red > 25%, amber 15–25%, green ≤ 15%
- friction_score: Color gradient bar, red > 20, amber 10–20, green < 10
**Sort default:** friction_score descending
**Table title:** "Provider Outreach Priority List — Top 10 Highest-Friction Providers"
**Caption:** "FN-6: Friction score is an illustrative operational metric, not a real payer score"

### V4.9 — Denial Rate by Provider Type (Horizontal Bar)
**Type:** Horizontal bar chart
**Source:** `vw_provider_scorecard` aggregated by provider_type
**Y-axis:** provider_type sorted by denial rate
**X-axis:** avg denial_rate_pct
**Color:** By avg provider_risk_segment (majority segment per type)

### V4.10 — Documentation Failure Rate by Provider Type (Grouped Bar)
**Type:** Clustered column chart
**Source:** P6 query results from `07_provider_friction_queries.sql`
**X-axis:** provider_type
**Y-axis:** doc_incomplete_rate_pct
**Second series:** denial_rate_among_incomplete_pct
**Title:** "Provider Type Documentation Failure Rate — and Resulting Denial Rate"

### V3.12 — Top 5 Preventable Documentation Denials (Table)
**Type:** Table visual
**Source:** `fact_prior_authorization` filtered to `decision = "Denied"` AND `documentation_complete = FALSE` AND `denial_reason = "Documentation Incomplete"`, aggregated by `dim_service[service_category]`
**Columns:**
- Rank (by preventable denial count)
- service_category
- Preventable Doc Denials count (`Preventable Doc Denials` measure scoped to category)
- total_denials (all denials for category)
- preventable_pct (preventable ÷ total denials %)
- avg_tat_incomplete (avg decision_time_days where documentation_complete = FALSE for this category)
**Sort default:** Preventable Doc Denials descending
**Conditional formatting:** preventable_pct column — red > 40%, amber 25–40%, green ≤ 25%
**Title:** "Top 5 Service Categories — Preventable Documentation Denials"
**Caption:** "FN-4: Denials where denial_reason = 'Documentation Incomplete' AND documentation_complete = FALSE. These are the highest-priority service categories for pre-submission checklist programs."
**Footnote:** FN-4, FN-8

---

## Page 4: Provider Friction & Operational Action (additions)

### V4.11 — Provider Risk Segment × Denial Rate (Bar Chart)
**Type:** Clustered column chart
**Source:** `dim_provider` GROUP BY `provider_risk_segment` joined to `fact_prior_authorization` aggregations
**X-axis:** provider_risk_segment (Low-Risk / Moderate-Risk / High-Risk)
**Y-axis:** avg denial_rate_pct (average denial rate across all providers in each segment)
**Second bar (optional):** avg sla_breach_rate_pct
**Colors:** Low-Risk=#27AE60, Moderate-Risk=#F39C12, High-Risk=#C0392B
**Data labels:** Value on each bar
**Title:** "Denial Rate by Provider Risk Segment — Does Risk Classification Predict Outcomes?"
**Caption:** "Provider risk segment pre-assigned in dim_provider [ASSUMPTION G01]. High-Risk providers have 20% higher avg denial rates than Low-Risk."
**Footnote:** FN-3, FN-6

### V4.12 — PA Volume and Denial Rate by Provider Region (Map)
**Type:** Filled map or bubble map (Power BI ArcGIS or standard map visual)
**Source:** `fact_prior_authorization` JOIN `dim_provider` grouped by `dim_provider[region]`
**Location field:** `dim_provider[region]` (text region name — use as category if exact geo coordinates unavailable)
**Bubble size:** Count of PA requests per region
**Color saturation:** avg denial rate % per region (green = low, red = high)
**Tooltip fields:** region, total_requests, avg_denial_rate_pct, avg_friction_score, provider_count
**Note:** If geo data is not available for all providers, display as a horizontal bar chart sorted by region instead. The map visual is conditional on `dim_provider[region]` containing parseable location data.
**Title:** "PA Volume and Denial Rate by Provider Region"
**Caption:** "FN-3: Synthetic data. Regional patterns reflect random variation, not real geographic denial trends."
**Footnote:** FN-3, FN-6

---

## Cross-Visual Interactions

| Source Visual | Target Visual | Interaction Type |
|--------------|--------------|-----------------|
| V1.8 Donut (outcome) | V1.7 Trend line | Cross-highlight |
| V1.10 Plan type bar | All Page 1 visuals | Cross-filter |
| V2.8 Histogram (TAT bucket) | V2.9 Channel bar | Cross-highlight |
| V3.8 Heatmap (service × reason) | V3.9 Doc impact bar | Cross-filter |
| V4.6 Scatter plot (provider) | V4.8 Scorecard table | Cross-filter (click selects provider) |
| Global Year slicer | All pages, all visuals | Filter |

**Disable cross-filtering between:** Page 1 CMS table (V1.11) ← this should always show totals, never be filtered by other visuals. Set "Edit interactions" → None for this visual.

---

*Dashboard Visual Specification — Phase 4. Last updated: 2026-05-31*
