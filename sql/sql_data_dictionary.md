# SQL Data Dictionary — Prior Authorization Intelligence System
**Phase 3 | SQL Analysis Layer**
**Generated: 2026-05-31**
**ALL DATA IS SYNTHETIC. No PHI. No real patient or provider records.**

---

## Overview

This document describes every table, view, column, and design decision in the PAIS SQL layer. It is the authoritative reference for Phase 4 (Power BI dashboard), Phase 5 (predictive modeling), and portfolio review.

**Schema:** `pais`
**Target database:** PostgreSQL 14+ or DuckDB 0.9+
**Tables:** 5 (3 dimension + 2 fact)
**Views:** 10 (dashboard-ready aggregations)
**SQL files:** 8 (01 through 08)

---

## Critical Design Rules

**Rule 1 — `decision` vs `final_outcome`**

These two fields are frequently confused. The distinction is essential for correct benchmark comparisons.

`decision` is the **initial 3-state routing** assigned by the reviewer. It takes three values: `Approved`, `Denied`, or `Pended`. This field reflects the immediate administrative action before pend resolution or appeal. Using `decision='Approved'` to compute approval rates yields ~86.8% — which is NOT comparable to published benchmarks.

`final_outcome` is the **final administrative determination** after pend cases are resolved and denied cases may have been appealed. This field maps directly to how CMS and KFF measure Medicare Advantage prior authorization outcomes. Using `final_outcome` to compute the approval rate yields ~92.7%, which aligns with KFF's reported 92.3% (Source S3). **Always use `final_outcome` for CMS-0057-F benchmark comparisons.**

**Rule 2 — Leakage-risk fields**

Three fields in `fact_prior_authorization` must never be used as predictors in any model that predicts `decision`, `final_outcome`, or `delayed_flag`. They are documented in every relevant file and flagged in this dictionary with `[LEAKAGE RISK]`.

**Rule 3 — Assumption labeling**

Fields derived from documented assumptions (rather than directly measured public data) are labeled `[ASSUMPTION]` with the relevant assumption ID from `synthetic_assumption_table.csv`. This applies especially to `base_denial_risk` in `dim_service` and the `friction_score` in `vw_provider_scorecard`.

---

## Table Reference

### `pais.dim_member`
**Source file:** `members.csv` (5,000 rows)
**Purpose:** Member demographic and risk profile dimension. Used to segment PA outcomes by age band, plan type, and clinical risk level.

| Column | Type | Nullable | Values / Range | Notes |
|--------|------|----------|----------------|-------|
| `member_id` | VARCHAR(20) | No | `MBR-XXXXX` | Primary key |
| `age_band` | VARCHAR(20) | No | Under 65, 65-74, 75-84, 85+ | Calibrated to CMS MA enrollment demographics (S10) |
| `gender` | VARCHAR(10) | No | Male, Female | |
| `plan_type` | VARCHAR(30) | No | HMO, PPO, PFFS, SNP | Medicare Advantage plan types |
| `region` | VARCHAR(20) | No | Northeast, Southeast, Midwest, Southwest, West | 5-region U.S. synthetic geography |
| `risk_level` | VARCHAR(20) | No | Low, Moderate, High | Synthetic risk classification; High = 1.2x denial probability |
| `chronic_condition_count` | SMALLINT | No | 0–8 | Number of simulated chronic conditions |
| `member_tenure_months` | SMALLINT | No | 1–120 | Months enrolled in the plan |

---

### `pais.dim_provider`
**Source file:** `providers.csv` (1,000 rows)
**Purpose:** Provider characteristics affecting PA submission patterns and denial risk.

| Column | Type | Nullable | Values / Range | Notes |
|--------|------|----------|----------------|-------|
| `provider_id` | VARCHAR(20) | No | `PRV-XXXXX` | Primary key. No real NPIs. |
| `provider_type` | VARCHAR(30) | No | Hospital, Physician Group, Specialist, SNF, Home Health Agency, DME Supplier, Outpatient Clinic, Behavioral Health | |
| `region` | VARCHAR(20) | No | Northeast, Southeast, Midwest, Southwest, West | |
| `network_status` | VARCHAR(20) | No | In-Network, Out-of-Network | 88% In-Network, 12% OON; OON has 1.8x denial multiplier [ASSUMPTION G03] |
| `prior_auth_volume_band` | VARCHAR(20) | No | Low, Medium, High, Very High | Relative submission volume tier |
| `avg_incomplete_submission_rate` | NUMERIC(5,4) | No | 0.00–1.00 | Key driver of provider_risk_segment classification |
| `avg_response_time_days` | NUMERIC(5,2) | No | 0.5–30.0 | Average days for provider to respond to additional-info requests |
| `provider_risk_segment` | VARCHAR(20) | No | Low-Risk, Moderate-Risk, High-Risk | Derived from above two fields; High-Risk = 1.5x denial multiplier [ASSUMPTION G02] |

---

### `pais.dim_service`
**Source file:** `services.csv` (40 rows)
**Purpose:** Service and procedure reference dimension. Defines which services require PA, clinical review eligibility, and assumption-based denial risk profiles.

| Column | Type | Nullable | Values / Range | Notes |
|--------|------|----------|----------------|-------|
| `service_id` | VARCHAR(20) | No | `SVC-XX` | Primary key |
| `service_category` | VARCHAR(50) | No | Advanced Imaging, Inpatient Hospital, Post-Acute / SNF, Surgical Procedures, Specialty Drugs, Durable Medical Equipment, Outpatient Procedures, Behavioral Health, Physical/Occupational Therapy, Home Health | 10 categories × 4 procedures each |
| `procedure_group` | VARCHAR(100) | No | Specific procedure description | |
| `prior_auth_required` | BOOLEAN | No | TRUE/FALSE | All 40 rows are TRUE in this dataset |
| `clinical_review_required` | BOOLEAN | No | TRUE/FALSE | Drives `clinical_review_required` in fact table |
| `automation_eligible` | BOOLEAN | No | TRUE/FALSE | Eligible for automated fast-track review |
| `base_cost_min` | NUMERIC(10,2) | No | > 0 | Cost range minimum |
| `base_cost_max` | NUMERIC(10,2) | No | ≥ base_cost_min | Cost range maximum |
| `base_denial_risk` | NUMERIC(5,4) | No | 0.05–0.16 | **[ASSUMPTION C01-C10]** Base denial probability by category. No CMS public data provides this breakdown. See `synthetic_assumption_table.csv`. |
| `base_delay_risk` | NUMERIC(5,4) | No | 0.05–0.25 | **[ASSUMPTION]** Base SLA delay probability |

---

### `pais.fact_prior_authorization`
**Source file:** `prior_auth_requests.csv` (25,000 rows)
**Purpose:** Core fact table. One row per prior authorization request. Star schema center. Date range: 2023-01-01 to 2024-12-31.

#### Pre-Decision Fields (safe as model features)

| Column | Type | Nullable | Values / Range | Notes |
|--------|------|----------|----------------|-------|
| `request_id` | VARCHAR(20) | No | `PA-XXXXXXXX` | Primary key |
| `member_id` | VARCHAR(20) | No | FK → dim_member | |
| `provider_id` | VARCHAR(20) | No | FK → dim_provider | |
| `service_id` | VARCHAR(20) | No | FK → dim_service | |
| `request_type` | VARCHAR(15) | No | Standard, Expedited | Expedited = 72-hour SLA per CMS-0057-F |
| `submitted_date` | DATE | No | 2023-01-01 – 2024-12-31 | |
| `submitted_day_of_week` | VARCHAR(10) | No | Monday–Sunday | |
| `submission_channel` | VARCHAR(15) | No | Electronic, Fax, Portal, Phone | Fax = 1.25x delay multiplier [ASSUMPTION G05] |
| `documentation_complete` | BOOLEAN | No | TRUE/FALSE | FALSE = 2.5x denial multiplier [ASSUMPTION G01]. ~19.4% incomplete. |
| `estimated_cost` | NUMERIC(10,2) | No | > 0 | Simulated procedure cost |
| `previous_denial_history` | BOOLEAN | No | TRUE/FALSE | Member has prior PA denial on record |
| `auto_eligible` | BOOLEAN | No | TRUE/FALSE | Eligible for automated review = 0.4x denial multiplier [ASSUMPTION G04] |
| `clinical_review_required` | BOOLEAN | No | TRUE/FALSE | Requires clinical staff or medical director review |

#### Decision Outcome Fields

| Column | Type | Nullable | Values / Range | Notes |
|--------|------|----------|----------------|-------|
| `reviewer_type` | VARCHAR(25) | No | Automated, Clinical Staff, Medical Director | |
| `decision` | VARCHAR(10) | No | Approved, Denied, Pended | **Initial routing only. DO NOT use for KFF benchmark comparisons.** Approved: 86.8%, Denied: 6.1%, Pended: 7.1% |
| `decision_date` | DATE | No | ≥ submitted_date | |
| `decision_time_days` | NUMERIC(6,2) | No | > 0 | Calendar days from submitted_date to decision_date |
| `allowed_days` | SMALLINT | No | 3 (Expedited), 7 (Standard) | CMS-0057-F SLA thresholds |
| `delayed_flag` | BOOLEAN | No | TRUE/FALSE | TRUE when decision_time_days > allowed_days |
| `denial_reason` | VARCHAR(50) | Yes | Medical Necessity Not Met, Documentation Incomplete, Clinical Criteria Not Met, Not a Covered Benefit, Duplicate/Administrative Error | NULL for Approved and Pended. See [ASSUMPTION A15-A19]. |
| `pended_flag` | BOOLEAN | No | TRUE/FALSE | Mirrors decision='Pended' |
| `final_outcome` | VARCHAR(40) | No | Approved, Denied, Pended-Resolved-Approved, Pended-Resolved-Denied, Approved-After-Appeal | **USE THIS for CMS-0057-F / KFF benchmarks.** Final approval rate: 92.7% (KFF benchmark: 92.3%). |

#### Post-Decision Fields — **LEAKAGE RISK**

| Column | Type | Nullable | Values / Range | Notes |
|--------|------|----------|----------------|-------|
| `appealed` | BOOLEAN | No | TRUE/FALSE | **[LEAKAGE RISK]** TRUE only when decision=Denied. Reveals decision. Exclude from models predicting decision. |
| `appeal_id` | VARCHAR(20) | Yes | FK → fact_appeal | **[LEAKAGE RISK]** Populated only for denied+appealed records. Exclude from models predicting decision. |
| `action_recommended_initial` | VARCHAR(30) | Yes | Approve, Request-Additional-Docs, Deny, Pend | **[HIGH LEAKAGE RISK]** Post-decision field. 0% inconsistency with decision direction. Near-perfect label proxy. **Exclude from ALL predictive model feature matrices.** Use for workflow analytics only. |

---

### `pais.fact_appeal`
**Source file:** `appeals.csv` (175 rows)
**Purpose:** Appeal records for denied PA requests. 11.5% of 1,525 denials = 175 appeals. One row per appeal.

| Column | Type | Nullable | Values / Range | Notes |
|--------|------|----------|----------------|-------|
| `appeal_id` | VARCHAR(20) | No | `APP-XXXXX` | Primary key |
| `request_id` | VARCHAR(20) | No | FK → fact_prior_authorization | Always links to a denied request |
| `appeal_date` | DATE | No | ≥ decision_date | Filed 1–30 days after denial; mean 15 days [ASSUMPTION G08] |
| `appeal_decision_date` | DATE | No | ≥ appeal_date | |
| `appeal_decision_days` | SMALLINT | No | ≥ 0 | Days from appeal_date to decision; mean 17 days [ASSUMPTION G09] |
| `appeal_outcome` | VARCHAR(30) | No | Overturned, Partially Overturned, Upheld | Overturn rate: 79.4% (KFF 2024 benchmark: 80.7%) |
| `reason_overturned` | VARCHAR(200) | Yes | Text description | NULL when appeal_outcome='Upheld' |
| `additional_documentation_submitted` | BOOLEAN | No | TRUE/FALSE | Whether provider submitted additional docs with appeal |
| `final_status_after_appeal` | VARCHAR(10) | No | Approved, Denied | Approved when Overturned/Partially Overturned; Denied when Upheld |

---

## View Reference

### `pais.vw_cms_public_metrics`
**Dashboard component:** KPI Summary Cards (top of dashboard)
**Purpose:** CMS-0057-F five required public metrics in one consolidated view. One row per metric with metric_value and kff_2024_benchmark for gap analysis.

**Key fields:** `cms_metric_id`, `metric_name`, `metric_value`, `unit`, `kff_2024_benchmark`, `source_field`, `benchmark_source`

**Metrics covered:** M1 (approval rate), M2 (denial rate), M3 (appeal overturn rate), M4a/M4b (avg decision time), M6 (appeal rate), M7 (SLA breach rate)

---

### `pais.vw_monthly_volume_trend`
**Dashboard component:** Monthly Trend Line Chart
**Purpose:** Time-series of PA volume, denial rate, SLA breach rate, and average turnaround by calendar month (24 data points, Jan 2023–Dec 2024).

**Key fields:** `year_month`, `total_requests`, `final_denied_count`, `final_denial_rate_pct`, `sla_breach_rate_pct`, `avg_turnaround_days`

**Limitation:** Year-over-year denial rate differences reflect random variation only. No trend shift is modeled between 2023 and 2024. Volume growth (~6%) IS modeled.

---

### `pais.vw_denial_by_service_category`
**Dashboard component:** Service Category Denial Rate Bar Chart
**Purpose:** Denial rate, SLA breach rate, and documentation failure rate by service category (10 rows). Supports the CMS-0057-F M2 drill-down.

**Key fields:** `service_category`, `total_requests`, `final_denial_rate_pct`, `sla_breach_rate_pct`, `doc_incomplete_rate_pct`, `assumption_base_risk_pct`

**Note:** `assumption_base_risk_pct` values are [ASSUMPTION C01-C10] — not measured rates from public data.

---

### `pais.vw_provider_scorecard`
**Dashboard component:** Provider Scorecard Table + Scatter Plot
**Purpose:** One row per provider with denial rate, SLA breach rate, documentation failure rate, and composite friction score. Supports provider outreach prioritization.

**Key fields:** `provider_id`, `provider_type`, `network_status`, `provider_risk_segment`, `denial_rate_pct`, `doc_incomplete_rate_pct`, `sla_breach_rate_pct`, `friction_score`

**Friction score formula:** `(denial_rate × 0.40) + (sla_breach_rate × 0.30) + (doc_incomplete_rate × 0.30)`. Weights are illustrative [ASSUMPTION]. Minimum 5 requests to be included.

---

### `pais.vw_appeal_funnel`
**Dashboard component:** Appeal Funnel Chart
**Purpose:** Single-row summary of the complete PA funnel from total requests to final determination. Includes KFF benchmarks at each stage.

**Key fields:** `total_pa_requests`, `initial_denials`, `appeals_filed`, `overturned_count`, `final_denied`, `final_approved`, all with `_rate_pct` companions and KFF benchmarks.

---

### `pais.vw_sla_compliance_summary`
**Dashboard component:** SLA Compliance Gauge Charts
**Purpose:** SLA compliance and breach rates by request type with median and P95 turnaround times.

**Key fields:** `request_type`, `sla_threshold_days`, `sla_compliance_rate_pct`, `sla_breach_rate_pct`, `median_turnaround_days`, `p95_turnaround_days`

---

### `pais.vw_documentation_impact`
**Dashboard component:** Documentation Impact Grouped Bar Chart
**Purpose:** Side-by-side comparison of PA outcomes for complete vs incomplete documentation submissions.

**Key fields:** `documentation_complete`, `total_requests`, `initial_denial_rate_pct`, `final_denial_rate_pct`, `avg_turnaround_days`, `doc_incomplete_denials`

---

### `pais.vw_submission_channel_analysis`
**Dashboard component:** Submission Channel Stacked Bar Chart
**Purpose:** Denial rate, SLA breach rate, and documentation failure rate by submission channel (Electronic, Fax, Portal, Phone).

**Key fields:** `submission_channel`, `total_requests`, `pct_of_total`, `denial_rate_pct`, `sla_breach_rate_pct`, `doc_incomplete_rate_pct`

---

### `pais.vw_member_risk_profile`
**Dashboard component:** Member Risk Profile Segmented Bar Chart
**Purpose:** PA outcome segmentation by member risk level, age band, and plan type.

**Key fields:** `risk_level`, `age_band`, `plan_type`, `total_requests`, `denial_rate_pct`, `sla_breach_rate_pct`

---

### `pais.vw_reviewer_type_outcomes`
**Dashboard component:** Reviewer Type Outcomes Table + Bar
**Purpose:** Denial rate, turnaround time, and SLA breach rate by reviewer type (Automated, Clinical Staff, Medical Director).

**Key fields:** `reviewer_type`, `pct_of_volume`, `denial_rate_pct`, `avg_turnaround_days`, `sla_breach_rate_pct`, `incomplete_doc_escalations`

---

## SQL File Reference

| File | Purpose | Key Output |
|------|---------|-----------|
| `01_create_database.sql` | Create `pais` database and schema | Schema setup, search path |
| `02_create_tables.sql` | DDL for all 5 tables | Tables with PKs, FKs, CHECK constraints |
| `03_load_data.sql` | Ingest CSVs into tables | PostgreSQL COPY / DuckDB read_csv_auto |
| `04_data_quality_checks.sql` | 43-check DQ validation suite | Pass/fail per check; leakage informational |
| `05_business_kpi_queries.sql` | CMS-0057-F KPIs + operational metrics | M1–M12 metric queries |
| `06_delay_denial_analysis_queries.sql` | Delay and denial deep-dives (D1–D10) | Multi-factor analysis queries |
| `07_provider_friction_queries.sql` | Provider-level performance (P1–P8) | Provider scorecard + friction ranking |
| `08_dashboard_views.sql` | 10 Power BI–ready views | CREATE VIEW statements |

---

## Leakage Risk Summary

The following fields in `fact_prior_authorization` must be excluded from any predictive model feature matrix that predicts `decision`, `final_outcome`, or `delayed_flag`:

| Field | Leakage Type | Risk Level | Safe Use |
|-------|-------------|-----------|---------|
| `action_recommended_initial` | Post-decision label proxy. 0% inconsistency with decision direction. | HIGH | Workflow analytics only (how often reviewers request additional docs before finalizing) |
| `appeal_id` | Populated only when decision=Denied. Directly reveals outcome. | HIGH | Appeal-specific analyses after filtering to denied records |
| `appealed` | TRUE only when decision=Denied. Structurally reveals decision. | HIGH | Appeal-specific analyses after filtering to denied records |

All three fields are excluded from the 10 dashboard views except where appeal_id is used within its correct appeal-specific context in `vw_appeal_funnel`.

---

## Source and Assumption Summary

All synthetic data is calibrated against public benchmarks. Key calibration targets and their sources:

| Metric | Achieved | Benchmark | Source |
|--------|---------|-----------|--------|
| Final approval rate | 92.7% | 92.3% | KFF 2024 (S3) |
| Final denial rate | 7.3% | 7.7% | KFF 2024 (S3) |
| Appeal rate of denied | 11.5% | 11.5% | KFF 2024 (S3) |
| Appeal overturn rate | 79.4% | 80.7% | KFF 2024 (S3) |
| Standard TAT mean | 4.81 days | 5.0 days | CMS-0057-F + industry |
| Expedited TAT mean | 1.45 days | 1.5 days | CMS-0057-F + industry |

Service-category denial risk values (`base_denial_risk` in `dim_service`) are **[ASSUMPTION C01-C10]** — no CMS public data provides PA denial rates broken down by service type. These values are informed by OIG narrative context (S5) but are not measured rates. They are clearly labeled throughout all project documentation.

---

## Phase 4 Usage Notes

When connecting Power BI to this SQL layer:

1. Use `vw_cms_public_metrics` as the source for KPI summary cards.
2. Use `vw_monthly_volume_trend` for all time-series line charts (24 monthly data points).
3. Use `vw_provider_scorecard` for provider drillthrough — set minimum friction_score threshold for highlighting.
4. Use `vw_appeal_funnel` for the funnel chart — all stages and benchmarks are pre-computed.
5. Never connect directly to `fact_prior_authorization.action_recommended_initial` in any analytical visual — it is a leakage field.
6. Filter all plan-level segmentation through `dim_member.plan_type` — there is no plan_id in this dataset (known limitation, see phase_2_self_audit.md).

---

*SQL Data Dictionary — Phase 3 complete. Last updated: 2026-05-31*
