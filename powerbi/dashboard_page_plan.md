# Dashboard Page Plan — Prior Authorization Intelligence System
**Phase 4 | Power BI Dashboard Design**
**Generated: 2026-05-31**
**ALL DATA IS SYNTHETIC. Benchmark-calibrated. No PHI.**

---

## Dashboard Purpose

This dashboard is not a generic healthcare dashboard. It is a payer operations analytics tool built to answer the operational and compliance questions that Medicare Advantage payer teams, utilization management directors, and CMS regulators actually ask about prior authorization workflows.

Every page connects directly to one of three business problems:

1. **Compliance visibility** — Are we meeting CMS-0057-F turnaround requirements? How do our approval and denial rates compare to the KFF MA benchmark?
2. **Operational bottlenecks** — Where are requests getting delayed? What is driving denials — documentation, clinical criteria, or administrative error?
3. **Provider-level action** — Which providers generate the most friction? Where can targeted outreach reduce rework and improve first-pass approval rates?

---

## Required Footnotes (All Pages)

The following footnotes must appear on every page of the dashboard. They are not optional — they are the integrity layer of the entire analytical system.

**FN-1:** Approval and denial rate KPI cards use `final_outcome` (final administrative determination after pend resolution and appeal). They do NOT use `decision` (initial routing). Using `decision` would show 86.8% approval — not comparable to published benchmarks.

**FN-2:** `decision` = initial routing outcome (Approved / Denied / Pended). `final_outcome` = final administrative determination after pend/appeal resolution.

**FN-3:** All data is synthetic and benchmark-calibrated. No PHI. No real patient records. No real payer data. Generated for portfolio analytics purposes.

**FN-4:** Service-category denial risk values are assumption-based [C01-C10]. CMS public reporting does not provide PA denial rates broken down by service type.

**FN-5:** Year-over-year trend reflects synthetic volume distribution calibrated to national MA trend context (KFF 2023–2024), not a measured payer trend. 2023 vs 2024 denial rate differences reflect random variation only.

**FN-6:** Provider friction score is an illustrative operational metric (40% denial weight + 30% delay weight + 30% documentation failure weight). It is not a real payer score.

**FN-7:** CMS-0057-F (finalized January 17, 2024) requires Medicare Advantage organizations to publicly report five PA metrics beginning March 31, 2026 for CY2025. The CMS Metrics panel on Page 1 simulates this required public disclosure format. Benchmark comparisons use KFF Medicare Advantage 2024 data (Source S3).

**FN-8:** This dashboard is an operational analytics and workflow decision-support tool. It does not approve or deny care. All outputs are intended for workflow prioritization, documentation review, SLA monitoring, and operational improvement — not for clinical determination of coverage.

---

## Page 1: Executive Overview

### Business Story
A payer executive or compliance officer opens this page to answer: "How are we performing against CMS-0057-F requirements, and where is our biggest exposure?" This page gives the full picture in under 60 seconds — approval rates against KFF benchmarks, SLA compliance status, denial volume, and the appeal funnel all in one view. Every number on this page is something a payer must report publicly starting March 31, 2026 under CMS-0057-F.

### Analytical Questions Answered
- What is our final approval rate vs the KFF 92.3% MA benchmark?
- What is our final denial rate and how does it compare to industry?
- What percentage of denied requests went to appeal — and what share were overturned?
- Are we meeting the 7-day standard and 72-hour expedited SLA requirements?
- What is the overall volume split between Standard and Expedited requests?
- How do outcomes break down by plan type (HMO / PPO / SNP / PFFS)?

### Primary SQL Views Used
- `vw_cms_public_metrics` — KPI cards
- `vw_appeal_funnel` — Funnel chart
- `vw_monthly_volume_trend` — Trend line
- `vw_sla_compliance_summary` — SLA gauge
- `fact_prior_authorization` + `dim_member` — Plan type segmentation

### KPI Cards (top row)
| Card | Measure | Benchmark | Source |
|------|---------|-----------|--------|
| Final Approval Rate | 92.7% | 92.3% | KFF S3 |
| Final Denial Rate | 7.3% | 7.7% | KFF S3 |
| Appeal Overturn Rate | 79.4% | 80.7% | KFF S3 |
| Avg Standard TAT | 4.81 days | 5.0 days | CMS-0057-F |
| Avg Expedited TAT | 1.45 days | 1.5 days | CMS-0057-F |
| SLA Compliance (Overall) | ~81% | — | [ASSUMPTION A10/A11] |

### Visuals
1. 6× KPI cards with benchmark delta indicators (green/amber/red)
2. Line chart: Monthly total requests + final denial rate over 24 months
3. Donut chart: final_outcome distribution (5 categories)
4. Funnel chart: Total PA → Denied → Appealed → Overturned → Final Approved
5. Stacked bar: Request volume by plan type × year (2023 vs 2024)
6. Data table: CMS-0057-F 5 required metrics with benchmark comparison

### Recruiter Talking Point
"This page simulates the annual public metrics report every Medicare Advantage organization must file with CMS starting March 2026. I built it to show I understand what payers are accountable for — not just what's interesting analytically."

---

## Page 2: Delay & SLA Compliance

### Business Story
CMS-0057-F sets hard turnaround time requirements: 7 calendar days for standard requests, 72 hours for expedited. A utilization management operations manager uses this page to answer: "Where are we breaching SLA, how severe are the breaches, and what operational factors are driving delays?" This is not a compliance checkbox page — it is an operational triage tool.

### Analytical Questions Answered
- What percentage of Standard and Expedited requests breach SLA?
- How does submission channel (Electronic vs Fax) affect turnaround time?
- What is the turnaround time distribution — where is the tail?
- Does documentation completeness drive SLA breaches?
- Which service categories are most likely to breach SLA?
- What does P90 and P95 turnaround look like vs the SLA limit?

### Primary SQL Views Used
- `vw_sla_compliance_summary` — Gauge charts
- `vw_submission_channel_analysis` — Channel breakdown
- `vw_documentation_impact` — Doc completeness vs delay
- `vw_denial_by_service_category` — Service-level delay rates
- `fact_prior_authorization` — Raw TAT distribution histogram

### KPI Cards (top row)
| Card | Measure | Note |
|------|---------|------|
| Standard SLA Breach Rate | 21.0% | 7-day limit per CMS-0057-F |
| Expedited SLA Breach Rate | 6.2% | 3-day (72-hr) limit |
| Avg Standard TAT | 4.81 days | |
| Avg Expedited TAT | 1.45 days | |
| P95 TAT (Standard) | ~12 days | Tail risk indicator |
| Doc Incomplete Rate | 19.4% | Drives ~40% longer TAT |

### Visuals
1. 2× SLA compliance gauge charts (Standard 79% compliance / Expedited 94%)
2. Histogram: decision_time_days distribution with SLA threshold line overlay
3. Grouped bar: Avg TAT by submission channel (Electronic / Fax / Portal / Phone)
4. Grouped bar: SLA breach rate — complete vs incomplete documentation
5. Horizontal bar: SLA breach rate by service category (sorted high → low)
6. Stacked bar: SLA breach severity buckets (1-day over / 2-3 days / 4-7 days / 8+ days)
7. Line chart: Monthly SLA breach rate trend (2023–2024)

### Recruiter Talking Point
"This page shows I understand that CMS doesn't just set approval rate requirements — it sets time requirements. The SLA breach rate by submission channel directly maps to an operational recommendation: electronic submission reduces Fax's 1.25× delay multiplier. That's a concrete ROI story."

---

## Page 3: Denial & Appeal Intelligence

### Business Story
A medical director or denial management analyst uses this page to answer: "What is driving our denials, which services have the highest denial rates, and how effective is the appeals process?" This page connects the denial pipeline to operational intelligence — not just counting denials but understanding whether they are preventable (documentation failures) vs clinical (medical necessity) vs administrative.

### Analytical Questions Answered
- What is the denial reason distribution across all 5 categories?
- Which service categories have the highest denial rates?
- How does reviewer type (Automated / Clinical Staff / Medical Director) correlate with denial outcomes?
- What is the full denial-to-appeal-to-overturn funnel?
- Of denied requests, which denial reasons have the highest appeal overturn rates?
- What share of denials could be prevented by complete documentation?

### Primary SQL Views Used
- `vw_appeal_funnel` — Funnel chart
- `vw_denial_by_service_category` — Denial heatmap
- `vw_documentation_impact` — Preventable denials
- `vw_reviewer_type_outcomes` — Reviewer type table
- `fact_prior_authorization` + `fact_appeal` — Denial reason × appeal outcome cross-tab

### KPI Cards (top row)
| Card | Measure | Note |
|------|---------|------|
| Initial Denial Rate | 6.1% | Decision field — routing only |
| Final Denial Rate | 7.3% | final_outcome — benchmark metric |
| Top Denial Reason | Documentation Incomplete (34%) | |
| Appeal Rate | 11.5% | KFF benchmark: 11.5% |
| Appeal Overturn Rate | 79.4% | KFF benchmark: 80.7% |
| Preventable Doc Denials | ~520 est. | Denials with denial_reason='Documentation Incomplete' and documentation_complete=FALSE |

### Visuals
1. 5× KPI cards
2. Horizontal bar: Denial reason distribution (5 bars with % of all denials)
3. Heatmap / matrix: Service category × denial reason (count and rate)
4. Funnel: Total PA → Initial Denied → Appealed → Overturned → Final Denied
5. Bar: Denial rate by reviewer type (Automated / Clinical Staff / Medical Director)
6. Grouped bar: Denial rate — complete vs incomplete docs by service category
7. Stacked bar: Appeal outcome (Overturned / Partially Overturned / Upheld) by denial reason
8. Table: Top 5 service categories by preventable documentation denials

### Recruiter Talking Point
"The key insight on this page is that 34% of denials are Documentation Incomplete — and that's the most actionable denial reason because it's preventable. If I were presenting this to a VP of Medical Management, I'd use this page to recommend a provider documentation outreach program targeting high-friction service categories."

---

## Page 4: Provider Friction & Operational Action

### Business Story
A provider relations director or network management analyst uses this page to answer: "Which providers are generating the most PA friction, and what should we do about it?" This page reframes the provider analysis as an operational action list — not a ranking for its own sake but a prioritized outreach queue. The friction score combines denial rate, SLA breach rate, and documentation failure rate into one operational triage metric.

### Analytical Questions Answered
- Which provider types have the highest denial and delay rates?
- What is the impact of Out-of-Network status on PA outcomes?
- Which individual providers are highest-friction (top 10)?
- Where is documentation failure concentrated by provider type and region?
- How does provider risk segment (Low / Moderate / High) predict PA outcomes?
- What would be the first 10 providers to contact for documentation outreach?

### Primary SQL Views Used
- `vw_provider_scorecard` — Provider table + scatter plot
- `fact_prior_authorization` + `dim_provider` — Network status, region analysis
- `07_provider_friction_queries.sql` (P1–P8) — All provider-level aggregations

### KPI Cards (top row)
| Card | Measure | Note |
|------|---------|------|
| High-Risk Providers | ~200 (20%) | provider_risk_segment = 'High-Risk' |
| Out-of-Network Denial Rate | ~1.8× In-Network | ASSUMPTION G03 |
| Avg Doc Incomplete Rate | 19.4% | Across all providers |
| Top Friction Provider Type | (from live data) | Highest avg friction score |
| Providers Needing Outreach | Top 10 by friction score | Minimum 10 requests |

### Visuals
1. 5× KPI cards
2. Scatter plot: Provider friction score vs total volume (bubble size = denied count)
3. Horizontal bar: Denial rate by provider type (sorted high → low)
4. Grouped bar: In-Network vs Out-of-Network — denial rate / SLA breach / doc failure rate
5. Bar: Provider risk segment (Low / Moderate / High) × denial rate
6. Table: Top 10 highest-friction providers with friction score, denial rate, doc incomplete rate
7. Stacked bar: Documentation failure rate by provider type
8. Map visual: PA volume and denial rate by provider region (if geo data available)

### Recruiter Talking Point
"This page is what I'd show a Provider Relations VP. The friction score turns three operational metrics into a single prioritized outreach list. Every row in the top 10 table is a provider to call — and the column that matters most for the call is doc_incomplete_rate, because that's what the provider can actually fix."

---

## Dashboard Design Principles

**Color Palette:** Professional healthcare blue/grey with CMS-style clarity. No bright consumer dashboards.
- Primary blue: #0057A8 (deep federal blue — CMS color family)
- Alert red: #C0392B (SLA breaches, high denial rates)
- Success green: #27AE60 (within benchmark, SLA compliant)
- Amber: #F39C12 (approaching threshold, moderate friction)
- Background: #F4F6F9 (light grey — dashboard standard)

**Typography:** Segoe UI (Power BI default). Titles 14pt bold. KPI values 28-36pt bold. Footnotes 9pt italic.

**Filtering:** All pages share a global slicer panel: Year (2023 / 2024 / Both), Plan Type, Region, Request Type (Standard / Expedited).

**Navigation:** Tab-style page navigation bar at top. Each tab named for the page. Active tab highlighted in primary blue.

**Benchmark indicators:** Every KPI card that has a public benchmark shows a delta indicator (▲ above / ▼ below benchmark) in green or amber.

---

*Dashboard Page Plan — Phase 4. Last updated: 2026-05-31*
