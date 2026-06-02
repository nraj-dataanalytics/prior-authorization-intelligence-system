# Dashboard Wireframe — Prior Authorization Intelligence System
**Phase 4 | Power BI Dashboard Design**
**Generated: 2026-05-31**

All wireframes are text-based layout diagrams showing the position, size, and type of each visual on each dashboard page. Canvas size: 1280 × 720px (16:9 widescreen). Each wireframe represents one Power BI report page.

---

## Global Layout Elements (All Pages)

```
┌──────────────────────────────────────────────────────────────────────────┐
│  HEADER BAR (full width, 48px tall)                                      │
│  [PAIS Logo / Title] "Prior Authorization Intelligence System"  [Synthetic Data Badge]  │
├──────────────────────────────────────────────────────────────────────────┤
│  NAVIGATION TABS (full width, 36px)                                      │
│  [ Executive Overview ] [ Delay & SLA ] [ Denial & Appeal ] [ Provider Friction ] │
├──────────────────────────────────────────────────────────────────────────┤
│  GLOBAL SLICER PANEL (right edge, vertical, 180px wide)                  │
│  Year: [2023] [2024] [Both]                                              │
│  Plan Type: [All ▼]                                                      │
│  Region: [All ▼]                                                         │
│  Request Type: [All ▼]                                                   │
└──────────────────────────────────────────────────────────────────────────┘
```

Active tab highlighted in #0057A8. Synthetic Data Badge: small amber label — "Synthetic • Benchmark-Calibrated • No PHI"

---

## Page 1: Executive Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ PAGE TITLE: "Executive Overview — CMS-0057-F Compliance Summary"│
├─────────────────────────────────────────────────────────────────┤
│  ROW 1: KPI CARDS  (6 cards, equal width, ~180px each)          │
│                                                                 │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│ │ Final   │ │ Final   │ │Appeal   │ │ Avg Std │ │ Avg Exp │ │  SLA    │ │
│ │Approval │ │ Denial  │ │Overturn │ │  TAT    │ │  TAT    │ │Compli-  │ │
│ │  Rate   │ │  Rate   │ │  Rate   │ │  Days   │ │  Days   │ │  ance   │ │
│ │         │ │         │ │         │ │         │ │         │ │  Rate   │ │
│ │  92.7%  │ │  7.3%   │ │  79.4%  │ │  4.81d  │ │  1.45d  │ │  ~81%  │ │
│ │ ▲+0.4%  │ │ ▼-0.4%  │ │ ▼-1.3%  │ │benchmark│ │benchmark│ │ overall │ │
│ │ vs KFF  │ │ vs KFF  │ │ vs KFF  │ │  5.0d   │ │  1.5d   │ │         │ │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘ │
│                                                                 │
├────────────────────────────┬────────────────────────────────────┤
│                            │                                    │
│  ROW 2 LEFT (55% width):   │  ROW 2 RIGHT (45% width):          │
│                            │                                    │
│  LINE CHART                │  DONUT CHART                       │
│  "Monthly PA Volume &      │  "Final Outcome Distribution"      │
│   Final Denial Rate"       │                                    │
│                            │  ○ Approved (86.4%)                │
│  [bars = volume]           │  ○ Pended-Resolved-Approved (5.7%) │
│  [line = denial rate %]    │  ○ Approved After Appeal (0.7%)    │
│  x-axis: Jan 2023–Dec 2024 │  ○ Denied (6.8%)                   │
│  dual y-axis               │  ○ Pended-Resolved-Denied (0.5%)   │
│  SLA threshold marker      │                                    │
│                            │                                    │
├────────────────────────────┴────────────────────────────────────┤
│                                                                 │
│  ROW 3 LEFT (40%): FUNNEL CHART                                 │
│  "PA to Final Outcome Funnel"                                   │
│                                                                 │
│  ████████████████████████ 25,000  Total PA Requests             │
│  ████████████████        1,525   Initial Denials (6.1%)         │
│  █████████               175     Appeals Filed (11.5% of denied)│
│  ███████                 139     Appeals Overturned (79.4%)     │
│  ██                      ~386    Final Denied After All Steps   │
│                                                                 │
│  ROW 3 MIDDLE (30%): STACKED BAR                                │
│  "Volume by Plan Type — 2023 vs 2024"                           │
│  (HMO / PPO / PFFS / SNP, color = year)                        │
│                                                                 │
│  ROW 3 RIGHT (30%): CMS-0057-F METRICS TABLE                   │
│  Metric | Value | Benchmark | Status                           │
│  M1 Approval Rate | 92.7% | 92.3% | ✅                          │
│  M2 Denial Rate   |  7.3% |  7.7% | ✅                          │
│  M3 Overturn Rate | 79.4% | 80.7% | ⚠️                          │
│  M4a Std TAT      | 4.81d |  5.0d | ✅                          │
│  M4b Exp TAT      | 1.45d |  1.5d | ✅                          │
│  M5 PA Services   |    40 |   N/A | —                           │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  FOOTNOTE BAR (full width, 32px)  FN-1 | FN-2 | FN-3           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Page 2: Delay & SLA Compliance

```
┌─────────────────────────────────────────────────────────────────┐
│ PAGE TITLE: "Delay & SLA Compliance — CMS-0057-F Turnaround     │
│              Time Analysis"                                     │
├─────────────────────────────────────────────────────────────────┤
│  ROW 1: KPI CARDS  (6 cards)                                    │
│                                                                 │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│ │  Std SLA │ │  Exp SLA │ │  Avg Std │ │  Avg Exp │ │   P95    │ │   Doc    │ │
│ │  Breach  │ │  Breach  │ │   TAT    │ │   TAT    │ │   TAT    │ │Incomplete│ │
│ │  20.96%  │ │   6.23%  │ │  4.81d   │ │  1.45d   │ │  ~12.0d  │ │  19.4%  │ │
│ │ 7-day SLA│ │ 3-day SLA│ │          │ │          │ │ (Std)    │ │  rate   │ │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘ │
│                                                                 │
├──────────────────────────────┬──────────────────────────────────┤
│  ROW 2 LEFT (50%):           │  ROW 2 RIGHT (50%):              │
│                              │                                  │
│  GAUGE CHARTS (2 side by side)│  HISTOGRAM                      │
│  "SLA Compliance"            │  "Decision Time Distribution"    │
│                              │  x-axis: days (0–20+)           │
│  [Standard]    [Expedited]   │  bars: count per day bucket      │
│   79.0%         93.8%        │  vertical line: 7-day SLA limit  │
│   compliance    compliance   │  vertical line: 3-day SLA limit  │
│   gauge         gauge        │  color: on-time=green            │
│                              │         delayed=red              │
│                              │  separate series: Std vs Exp     │
│                              │                                  │
├────────────┬─────────────────┴──────────────────┬───────────────┤
│            │                                    │               │
│ROW 3 (33%) │  ROW 3 (34%):                      │  ROW 3 (33%): │
│            │                                    │               │
│GROUPED BAR │  GROUPED BAR                       │  STACKED BAR  │
│"Avg TAT by │  "SLA Breach Rate —                │  "SLA Breach  │
│ Submission │   Complete vs Incomplete Docs"     │  Severity"    │
│ Channel"   │                                    │               │
│            │  x-axis: service category          │  x: Std / Exp │
│Electronic  │  2 bars per category:              │  segments:    │
│Fax         │  [complete docs] [incomplete docs] │  On Time      │
│Portal      │  color: green vs red               │  1 Day Over   │
│Phone       │  SLA breach rate on y-axis         │  2-3 Days     │
│            │                                    │  4-7 Days     │
│y: avg days │                                    │  8+ Days      │
│            │                                    │               │
├────────────┴────────────────────────────────────┴───────────────┤
│  ROW 4: LINE CHART (full width)                                 │
│  "Monthly SLA Breach Rate Trend — 2023 vs 2024"                 │
│  x-axis: month  y-axis: breach %  two lines: Std / Expedited   │
│  Reference lines: 18% target (Std) / 10% target (Exp)          │
│  [ASSUMPTION A10/A11 label on reference lines]                  │
├─────────────────────────────────────────────────────────────────┤
│  FOOTNOTE BAR:  FN-1 | FN-2 | FN-3 | FN-5                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Page 3: Denial & Appeal Intelligence

```
┌─────────────────────────────────────────────────────────────────┐
│ PAGE TITLE: "Denial & Appeal Intelligence — Reason Analysis &   │
│              Overturn Funnel"                                   │
├─────────────────────────────────────────────────────────────────┤
│  ROW 1: KPI CARDS  (5 cards)                                    │
│                                                                 │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│ │  Final   │ │  Top     │ │ Appeal   │ │ Overturn │ │Preventabl│ │
│ │ Denial   │ │ Denial   │ │  Rate    │ │  Rate    │ │e Doc     │ │
│ │  Rate    │ │  Reason  │ │          │ │          │ │ Denials  │ │
│ │   7.3%   │ │ Doc Inc. │ │  11.5%   │ │  79.4%   │ │  ~520   │ │
│ │vs KFF 7.7│ │  (34%)   │ │ vs 11.5% │ │vs 80.7%  │ │ estimated│ │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘ │
│                                                                 │
├──────────────────────────────────────┬──────────────────────────┤
│  ROW 2 LEFT (55%):                   │  ROW 2 RIGHT (45%):      │
│                                      │                          │
│  HORIZONTAL BAR CHART                │  FUNNEL CHART            │
│  "Denial Reason Distribution"        │  "Denial-to-Appeal       │
│   (% of all denials)                 │   Funnel"                │
│                                      │                          │
│  Documentation Incomplete  ████ 34%  │  25,000 Total PA         │
│  Medical Necessity Not Met ███  30%  │  1,525  Initial Denied   │
│  Clinical Criteria Not Met ██   20%  │  175    Appeals Filed    │
│  Not a Covered Benefit     █    10%  │  139    Overturned       │
│  Admin/Duplicate Error     █     7%  │  ~386   Final Denied     │
│                                      │                          │
│  Benchmark band on each bar          │  KFF benchmarks shown    │
│  color: preventable=amber            │  at each stage           │
│         non-preventable=blue         │                          │
│                                      │                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ROW 3 LEFT (35%):         ROW 3 MID (35%):    ROW 3 RIGHT(30%)│
│                                                                 │
│  MATRIX / HEATMAP          GROUPED BAR          STACKED BAR     │
│  "Denial Rate by           "Doc Impact on       "Appeal Outcome │
│   Service Category ×       Denial Rate by       by Denial       │
│   Denial Reason"           Service Category"    Reason"         │
│                                                                 │
│  rows: service category    x: service cat.      x: denial reason│
│  cols: denial reason       2 bars: complete /   seg: Overturned │
│  cell: denial rate %       incomplete docs      Partial         │
│  color scale:              y: denial rate %     Upheld          │
│  white=low, red=high       delta annotation                     │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ROW 4 (full width): BAR CHART                                  │
│  "Denial Rate by Reviewer Type"                                 │
│  3 bars: Automated | Clinical Staff | Medical Director          │
│  Annotation: "Automated = 0.4× denial probability [Assumption G04]" │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  FOOTNOTE BAR:  FN-1 | FN-2 | FN-3 | FN-4                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Page 4: Provider Friction & Operational Action

```
┌─────────────────────────────────────────────────────────────────┐
│ PAGE TITLE: "Provider Friction & Operational Action —           │
│              Documentation Outreach Prioritization"            │
├─────────────────────────────────────────────────────────────────┤
│  ROW 1: KPI CARDS  (5 cards)                                    │
│                                                                 │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│ │ High-Risk│ │  OON     │ │  OON vs  │ │  Avg Doc │ │  Top     │ │
│ │Providers │ │ Denial   │ │ In-Net   │ │Incomplete│ │ Friction │ │
│ │          │ │  Rate    │ │ Denial   │ │  Rate    │ │ Provider │ │
│ │  ~200    │ │  ~9.8%   │ │  1.8×    │ │  19.4%  │ │  Type    │ │
│ │  (20%)   │ │          │ │multiplier│ │          │ │ (live)   │ │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘ │
│                                                                 │
├────────────────────────────┬────────────────────────────────────┤
│  ROW 2 LEFT (55%):         │  ROW 2 RIGHT (45%):                │
│                            │                                    │
│  SCATTER PLOT              │  GROUPED BAR                       │
│  "Provider Friction Score  │  "In-Network vs Out-of-Network     │
│   vs PA Volume"            │   PA Outcome Comparison"           │
│                            │                                    │
│  x-axis: total PA requests │  3 metric groups:                  │
│  y-axis: friction score    │  Denial Rate %                     │
│  bubble size: denied count │  SLA Breach %                      │
│  color: risk segment       │  Doc Incomplete %                  │
│  (Low=green/Mod=amber/     │                                    │
│   High=red)                │  2 bars each: In-Net / OON         │
│  hover: provider_id, type  │  annotation: "1.8× multiplier      │
│                            │  [Assumption G03]"                 │
│                            │                                    │
├────────────────────────────┴────────────────────────────────────┤
│                                                                 │
│  ROW 3: FULL-WIDTH PROVIDER SCORECARD TABLE                     │
│  "Top 10 Highest-Friction Providers — Operational Outreach List"│
│                                                                 │
│  provider_id | type | network | risk_segment | volume | denial% │
│  | delay% | doc_incomplete% | friction_score                    │
│                                                                 │
│  Columns: sortable  Conditional formatting:                     │
│  friction_score → color gradient (green < 10, amber 10-20,     │
│                                   red > 20)                     │
│  doc_incomplete% → red if > 25%                                 │
│  denial_rate% → red if > 10%                                    │
│                                                                 │
│  Title annotation: "Friction Score = 40% Denial + 30% Delay    │
│  + 30% Doc Failure [Illustrative weights — Assumption]"         │
│                                                                 │
├────────────────────────────┬────────────────────────────────────┤
│  ROW 4 LEFT (50%):         │  ROW 4 RIGHT (50%):                │
│                            │                                    │
│  HORIZONTAL BAR            │  GROUPED BAR                       │
│  "Denial Rate by           │  "Documentation Failure Rate by    │
│   Provider Type"           │   Provider Type"                   │
│                            │                                    │
│  sorted high → low         │  2 bars per type:                  │
│  color by risk segment     │  doc incomplete rate %             │
│                            │  denial rate among incomplete %    │
│                            │                                    │
├─────────────────────────────────────────────────────────────────┤
│  FOOTNOTE BAR:  FN-3 | FN-4 | FN-5 | FN-6                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Visual Count Summary

| Page | KPI Cards | Charts/Visuals | Total Visuals |
|------|-----------|---------------|---------------|
| 1 – Executive Overview | 6 | 5 | 11 |
| 2 – Delay & SLA | 6 | 5 | 11 |
| 3 – Denial & Appeal | 5 | 6 | 11 |
| 4 – Provider Friction | 5 | 5 | 10 |
| **Total** | **22** | **21** | **43** |

---

*Dashboard Wireframe — Phase 4. Last updated: 2026-05-31*
