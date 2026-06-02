# Data Dictionary — Prior Authorization Intelligence System
**Phase 2 | Last Updated: 2026-05-31**
**Synthetic Data Only — No PHI — No Real Patient Records**

---

## Overview

This dictionary defines every field in every table of the synthetic prior authorization dataset. For each field it specifies: data type, allowed values or range, nullability, source or assumption backing, and analytical purpose.

All data is synthetic. It is generated from benchmark-calibrated distributions derived from public sources (see source_registry.md). No real patient names, member IDs, provider NPIs, or claims records are used.

---

## Table 1: members.csv

**Description:** Simulated health plan members who submit or receive care requiring prior authorization. Member attributes influence PA request patterns (risk level, tenure, chronic conditions). No PHI.

| Field | Type | Nullable | Allowed Values / Range | Source / Assumption | Analytical Purpose |
|-------|------|----------|----------------------|--------------------|--------------------|
| `member_id` | STRING | No | MBR-00001 to MBR-05000 | Generated (zero-pad sequential) | Primary key; FK in prior_auth_requests |
| `age_band` | STRING | No | 18-44, 45-54, 55-64, 65-74, 75-84, 85+ | Documented assumption based on MA enrollment demographics | Member risk stratification |
| `gender` | STRING | No | M, F, U (unknown) | Documented assumption | Demographic dimension |
| `plan_type` | STRING | No | HMO, PPO, PFFS, SNP | CMS MA plan type taxonomy | Plan-level analysis |
| `region` | STRING | No | Northeast, Southeast, Midwest, Southwest, West | Standard US Census regions | Geographic analysis |
| `risk_level` | STRING | No | Low, Medium, High | Documented payer workflow assumption; risk level correlates with chronic conditions | PA frequency predictor |
| `chronic_condition_count` | INTEGER | No | 0–8 | Documented assumption; calibrated to MA population (avg ~2-3 chronic conditions) | Member complexity signal |
| `member_tenure_months` | INTEGER | No | 1–60 | Documented assumption | Longer tenure → slightly better documentation patterns |

**Member count:** 5,000 synthetic members

---

## Table 2: providers.csv

**Description:** Simulated healthcare providers (physicians, hospitals, specialist groups) who submit PA requests. Provider behavior attributes (documentation quality, response time) drive PA outcome patterns. No real NPIs used.

| Field | Type | Nullable | Allowed Values / Range | Source / Assumption | Analytical Purpose |
|-------|------|----------|----------------------|--------------------|--------------------|
| `provider_id` | STRING | No | PRV-0001 to PRV-1000 | Generated (zero-pad sequential) | Primary key; FK in prior_auth_requests |
| `provider_type` | STRING | No | Primary Care, Specialist, Hospital, Imaging Center, Surgery Center, DME Supplier, Home Health Agency, Behavioral Health, Post-Acute Facility | Standard CMS provider taxonomy groups | Service type alignment |
| `region` | STRING | No | Northeast, Southeast, Midwest, Southwest, West | Standard regions | Geographic analysis |
| `network_status` | STRING | No | In-Network, Out-of-Network | Standard payer network classification | Denial risk modifier |
| `prior_auth_volume_band` | STRING | No | Low (1-49/yr), Medium (50-199/yr), High (200-499/yr), Very High (500+/yr) | Documented payer workflow assumption; high-volume providers tend to have better documentation familiarity | Provider segmentation |
| `avg_incomplete_submission_rate` | FLOAT | No | 0.05–0.50 | Calibrated to assumption A13 (22% overall incomplete rate); varies by provider type | Core predictor of denial/delay risk |
| `avg_response_time_days` | FLOAT | No | 0.5–10.0 | Calibrated to assumptions A07/A08 | Provider-side turnaround contribution |
| `provider_risk_segment` | STRING | No | Low-Risk, Moderate-Risk, High-Risk | Derived from incomplete_rate and volume band | Operational risk segmentation |

**Provider count:** 1,000 synthetic providers

---

## Table 3: services.csv

**Description:** Catalog of medical services and procedures requiring prior authorization. Each service has a category, automation eligibility, cost range, and base denial/delay risk. These are not real CPT codes — they are representative procedure groups.

| Field | Type | Nullable | Allowed Values / Range | Source / Assumption | Analytical Purpose |
|-------|------|----------|----------------------|--------------------|--------------------|
| `service_id` | STRING | No | SVC-001 to SVC-040 | Generated | Primary key; FK in prior_auth_requests |
| `service_category` | STRING | No | Advanced Imaging, Inpatient Hospital, Post-Acute / SNF, Surgical Procedures, Specialty Drugs, Durable Medical Equipment, Outpatient Procedures, Behavioral Health, Physical / Occupational Therapy, Home Health | OIG-informed categories (S5 specifically names imaging and post-acute as high-denial); others are documented payer workflow assumptions | Core analytical dimension |
| `procedure_group` | STRING | No | Free text label (e.g., "MRI Brain", "Inpatient Rehab Admission") | Documented assumption | Drill-down dimension |
| `prior_auth_required` | BOOLEAN | No | TRUE | All records in this table require PA by definition | Table scope definition |
| `clinical_review_required` | BOOLEAN | No | TRUE / FALSE | Documented assumption: high-cost, high-risk services trigger clinical review | Reviewer type determination |
| `automation_eligible` | BOOLEAN | No | TRUE / FALSE | S7 (Aetna benchmark: 83% real-time); automation eligibility varies by service complexity | Fast-track routing flag |
| `base_cost_min` | INTEGER | No | 50–5,000 (USD) | Documented assumption based on service category cost ranges | Cost tier analysis |
| `base_cost_max` | INTEGER | No | base_cost_min to 50,000 (USD) | Same | Cost tier analysis |
| `base_denial_risk` | FLOAT | No | 0.03–0.20 | [ASSUMPTION] Service-category-level denial risk — see synthetic_assumption_table.csv rows C01-C10. No public CMS data breaks denial rates by service type; calibrated from OIG narrative (S5) and payer workflow knowledge | Denial probability weight in generator |
| `base_delay_risk` | FLOAT | No | 0.05–0.25 | [ASSUMPTION] Same source basis as base_denial_risk | Delay probability weight in generator |

**Service count:** 40 synthetic services across 10 categories

---

## Table 4: prior_auth_requests.csv

**Description:** The core fact table. One row per prior authorization request. Covers 25,000 requests over 24 months. Contains all decision, timing, denial, pend, and appeal linkage fields. **This is the primary table for all SQL analysis, dashboarding, and modeling.**

| Field | Type | Nullable | Allowed Values / Range | Source / Assumption | Analytical Purpose |
|-------|------|----------|----------------------|--------------------|--------------------|
| `request_id` | STRING | No | PAR-000001 to PAR-025000 | Generated (zero-pad sequential) | Primary key |
| `member_id` | STRING | No | FK → members.member_id | Referential integrity | Member-level analysis |
| `provider_id` | STRING | No | FK → providers.provider_id | Referential integrity | Provider-level analysis |
| `service_id` | STRING | No | FK → services.service_id | Referential integrity | Service-category analysis |
| `request_type` | STRING | No | Standard, Expedited | A23: 15% expedited (documented assumption) | SLA tier routing |
| `submitted_date` | DATE | No | 2023-01-01 to 2024-12-31 | 24-month window; trend-weighted for 6% YoY growth (A25) | Time-series analysis |
| `submitted_day_of_week` | STRING | No | Monday–Friday (90%), Saturday–Sunday (10%) | Documented payer workflow assumption | Volume pattern analysis |
| `submission_channel` | STRING | No | Electronic (55%), Fax (25%), Portal (12%), Phone (8%) | A20-A22 (assumptions labeled) | Channel impact on turnaround |
| `documentation_complete` | BOOLEAN | No | TRUE / FALSE | A13: ~22% incomplete (labeled assumption); influenced by provider's avg_incomplete_submission_rate | Primary delay/denial predictor |
| `estimated_cost` | INTEGER | No | Derived from service base_cost range | Documented assumption | Cost tier analysis |
| `previous_denial_history` | BOOLEAN | No | TRUE / FALSE | Documented assumption: ~18% of requests have prior denial history | Recidivism / complexity flag |
| `auto_eligible` | BOOLEAN | No | Derived from service.automation_eligible + documentation_complete | S7 (Aetna real-time benchmark) | Fast-track routing |
| `clinical_review_required` | BOOLEAN | No | Derived from service.clinical_review_required | Documented assumption | Reviewer workload |
| `reviewer_type` | STRING | No | Automated, Clinical Staff, Medical Director | Derived from auto_eligible and clinical_review_required | Operational resource tracking |
| `decision` | STRING | No | Approved, Denied, Pended | A01 (92.3% approval baseline), A02 (7.7% denial), A14 (12% pend — assumption) | PRIMARY OUTCOME — CMS metric |
| `decision_date` | DATE | No | submitted_date + decision_time_days | Derived | CMS metric: avg time to decision |
| `decision_time_days` | FLOAT | No | Standard: lognormal(mean=5, σ=1.5); Expedited: lognormal(mean=1.5, σ=0.5); modified by channel and documentation status | A07 (5 day mean), A08 (1.5 day mean) | **CMS-required metric** |
| `allowed_days` | INTEGER | No | Standard: 7; Expedited: 3 (≈72 hours) | CMS-0057-F mandate (S1) | SLA compliance denominator |
| `delayed_flag` | BOOLEAN | No | TRUE if decision_time_days > allowed_days | Derived from CMS thresholds | SLA breach tracking |
| `denial_reason` | STRING | Yes | Documentation Incomplete, Medical Necessity Not Met, Clinical Criteria Not Met, Not a Covered Benefit, Duplicate/Administrative Error, NULL (if not denied) | A15-A19; OIG S5 (denial reason taxonomy) | **Denial reason analysis** |
| `pended_flag` | BOOLEAN | No | TRUE if decision = Pended | Derived | Pend rate KPI |
| `final_outcome` | STRING | No | Approved, Denied, Approved-After-Appeal, Pended-Resolved-Approved, Pended-Resolved-Denied | Derived after appeal resolution | Overall outcome tracking |
| `appealed` | BOOLEAN | No | TRUE / FALSE | A04: 11.5% of denials appealed (KFF S3) | **CMS-required metric** |
| `appeal_id` | STRING | Yes | FK → appeals.appeal_id; NULL if not appealed | Referential integrity | Appeal linkage |
| `action_recommended_initial` | STRING | No | Approve, Deny, Pend, Request-Additional-Docs | Documented payer workflow assumption — this field simulates the initial reviewer recommendation before final decision | Workflow intelligence field; **NOT a target label** |

**⚠ Leakage note:** `action_recommended_initial` is a workflow process field, not a post-decision field. It must NOT be used as a predictor in any model predicting `decision` — it is derived from the same decision logic. Mark clearly in modeling phase.

---

## Table 5: appeals.csv

**Description:** One row per appeal filed on a denied PA request. Not all denials are appealed (only ~11.5% per KFF S3). Appeal outcome and timing are benchmark-calibrated.

| Field | Type | Nullable | Allowed Values / Range | Source / Assumption | Analytical Purpose |
|-------|------|----------|----------------------|--------------------|--------------------|
| `appeal_id` | STRING | No | APP-00001 onward | Generated | Primary key; FK in prior_auth_requests |
| `request_id` | STRING | No | FK → prior_auth_requests.request_id | Referential integrity | Parent PA request |
| `appeal_date` | DATE | No | decision_date + 1 to decision_date + 30 | Documented assumption: appeals filed within 30 days of denial | Appeal timing |
| `appeal_decision_date` | DATE | No | appeal_date + appeal_decision_days | Derived | Appeal turnaround |
| `appeal_decision_days` | INTEGER | No | 5–30 days | Documented payer workflow assumption; no CMS mandate yet for appeal turnaround | Appeal SLA analysis |
| `appeal_outcome` | STRING | No | Overturned, Partially Overturned, Upheld | A05: 80.7% overturned (KFF S3 — fully + partially combined) | **CMS-required metric** |
| `reason_overturned` | STRING | Yes | Additional Documentation Resolved Issue, Clinical Criteria Re-evaluated, Peer-to-Peer Review Changed Decision, Administrative Error Corrected, NULL (if Upheld) | Documented payer workflow assumption | Root cause of overturn |
| `additional_documentation_submitted` | BOOLEAN | No | TRUE / FALSE | Documented assumption: ~65% of overturned appeals include additional documentation | Documentation completeness impact |
| `final_status_after_appeal` | STRING | No | Approved, Denied | Derived from appeal_outcome | Final member outcome |

---

## Key Relationships Summary

```
members (1) ──────< prior_auth_requests (many)
providers (1) ──────< prior_auth_requests (many)
services (1) ──────< prior_auth_requests (many)
prior_auth_requests (1) ──── (0 or 1) appeals
```

---

## Fields Intentionally Excluded

| Excluded Field | Reason |
|---------------|--------|
| Real patient name | PHI — excluded by design |
| Real SSN / Medicare ID | PHI — excluded by design |
| Real provider NPI | PHI/PII — synthetic IDs used |
| Real diagnosis codes (ICD-10) | Would require clinical grounding beyond scope; diagnosis category used instead |
| Actual drug names | Drug PA is out of scope for CMS-0057-F initial coverage; noted for future phase |
| Network contract rates | Proprietary payer data; not publicly available |

---

*Synthetic data only. For modeling: see synthetic_data_generation_methodology.md. For validation targets: see validation_targets_table.csv.*
