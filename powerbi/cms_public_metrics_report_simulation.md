# CMS-0057-F Annual Prior Authorization Public Metrics Report — Simulated
**Prior Authorization Intelligence System | Phase 4**
**Report Period: Calendar Year 2024**
**Generated: 2026-05-31**

---

> **SIMULATION NOTICE:** This document simulates the annual public metrics disclosure required under CMS-0057-F (Medicare Program; Prior Authorization and Utilization Management Reform in Medicare Advantage, Medicaid Managed Care, and CHIP Managed Care Programs; January 17, 2024). All data is synthetic and benchmark-calibrated. No PHI. No real patient, payer, or provider data. Generated for portfolio analytics purposes.

---

## What This Document Is

CMS-0057-F requires Medicare Advantage (MA) organizations to publicly report five standardized prior authorization metrics annually, beginning March 31, 2026 for CY2025 data. This simulated report demonstrates the format, content, and analytical depth that a payer analytics team would produce to support that compliance filing.

This document serves three purposes in the PAIS portfolio:

1. It shows that I understand what payers are actually required to report — not just what is analytically interesting.
2. It demonstrates the connection between the SQL pipeline, DAX measures, and the business output they were built to produce.
3. It provides a recruiter-facing artifact that is directly tied to a real regulatory requirement with a known effective date.

---

## Payer Information (Simulated)

| Field | Value |
|-------|-------|
| Organization Name | PAIS Analytics Health Plan (Simulated) |
| Plan Type | Medicare Advantage — Multi-product |
| Contract Number | H0000 (Simulated) |
| Reporting Period | January 1, 2024 — December 31, 2024 |
| Report Submission Date | March 31, 2026 (CMS Deadline for CY2025) |
| CMS Rule Reference | CMS-0057-F, 42 CFR §422.138 |
| Data Source | Synthetic PA workflow data, benchmark-calibrated |

---

## Part I: The Five Required Public Metrics

CMS-0057-F §422.138(b) requires MA organizations to publicly report the following five metrics annually. Each metric below shows the PAIS synthetic value, the applicable CMS definition, the KFF benchmark, and the assessment.

---

### Metric M1 — Prior Authorization Approval Rate

| | |
|--|--|
| **CMS Definition** | Percentage of prior authorization requests that resulted in an approval during the reporting period |
| **PAIS CY2024 Value** | **92.7%** |
| **DAX Measure** | `CMS M1 - Final Approval Rate %` |
| **Source Field** | `final_outcome IN ('Approved', 'Pended-Resolved-Approved', 'Approved-After-Appeal')` |
| **Denominator** | All PA requests submitted in CY2024 (13,250) |
| **Numerator** | Requests with a final approved outcome (12,281) |
| **KFF MA 2024 Benchmark** | 92.3% |
| **Delta vs Benchmark** | +0.4 pp (above benchmark — favorable) |
| **CMS Threshold** | No specific threshold — public transparency metric |
| **SQL Source** | `vw_cms_public_metrics` → `final_approval_rate` |

**Analytical Note:** The approval rate of 92.7% uses `final_outcome`, which reflects the true administrative disposition after all pend resolutions and appeals. Using the initial routing field (`decision`) would produce 86.8% — a materially different and non-comparable figure. See FN-1.

**Compliance Status:** ✅ Within benchmark range. No remediation required.

---

### Metric M2 — Prior Authorization Denial Rate

| | |
|--|--|
| **CMS Definition** | Percentage of prior authorization requests that resulted in a denial during the reporting period |
| **PAIS CY2024 Value** | **7.3%** |
| **DAX Measure** | `CMS M2 - Final Denial Rate %` |
| **Source Field** | `final_outcome IN ('Denied', 'Pended-Resolved-Denied')` |
| **Denominator** | All PA requests submitted in CY2024 (13,250) |
| **Numerator** | Requests with a final denied outcome (969) |
| **KFF MA 2024 Benchmark** | 7.7% |
| **Delta vs Benchmark** | −0.4 pp (below benchmark — favorable) |
| **CMS Threshold** | No specific threshold — public transparency metric |
| **SQL Source** | `vw_cms_public_metrics` → `final_denial_rate` |

**Denial Reason Breakdown (CY2024):**

| Denial Reason | Count | % of All Denials |
|--------------|-------|-----------------|
| Documentation Incomplete | 331 | 34.2% |
| Medical Necessity Not Met | 261 | 26.9% |
| Out-of-Network | 211 | 21.8% |
| Administrative Error | 117 | 12.1% |
| Duplicate Request | 49 | 5.1% |
| **Total** | **969** | **100%** |

**Analytical Note:** The top denial reason — Documentation Incomplete at 34.2% — represents the highest-priority operational improvement opportunity. These denials are preventable through provider-facing documentation checklists and pre-submission audits. [ASSUMPTION A07, FN-4]

**Compliance Status:** ✅ Below benchmark. No remediation required.

---

### Metric M3 — Percentage of Denied Prior Authorization Requests Approved After Appeal

| | |
|--|--|
| **CMS Definition** | Percentage of denied prior authorization requests that were approved after appeal during the reporting period |
| **PAIS CY2024 Value** | **79.4%** |
| **DAX Measure** | `CMS M3 - Appeal Overturn Rate %` |
| **Source Table** | `fact_appeal` |
| **Source Field** | `appeal_outcome IN ('Overturned', 'Partially Overturned')` |
| **Denominator** | Total appeals filed in CY2024 (approx. 90, proportional from 175 total) |
| **Numerator** | Appeals overturned or partially overturned |
| **KFF MA 2024 Benchmark** | 80.7% |
| **Delta vs Benchmark** | −1.3 pp (slightly below benchmark) |
| **CMS Threshold** | No specific threshold — public transparency metric |
| **SQL Source** | `vw_appeal_funnel` → `overturn_rate` |

**Appeal Outcome Breakdown:**

| Appeal Outcome | Count (All Periods) | % of Appeals |
|---------------|---------------------|-------------|
| Overturned | 95 | 54.3% |
| Partially Overturned | 44 | 25.1% |
| Upheld | 36 | 20.6% |
| **Total** | **175** | **100%** |

**Analytical Note:** A 79.4% overturn rate — meaning nearly 4 in 5 appeals result in at least a partial approval — raises a legitimate clinical operations question: if most denied requests are ultimately approved on appeal, what is driving the initial denial? In the PAIS dataset, the high overturn rate is partly explained by the high proportion of Documentation Incomplete denials (34.2%), which are frequently overturned when additional documentation is submitted at appeal. [FN-3]

**Compliance Status:** ⚠️ 1.3 pp below KFF benchmark. Monitor trend. Consider documentation improvement to reduce avoidable first-pass denials.

---

### Metric M4a — Average Time to Prior Authorization Decision — Standard Requests

| | |
|--|--|
| **CMS Definition** | Average number of calendar days from receipt of PA request to decision for standard (non-urgent) requests |
| **PAIS CY2024 Value** | **4.81 days** |
| **DAX Measure** | `CMS M4a - Avg Standard TAT Days` |
| **Source Field** | `decision_time_days` filtered to `request_type = 'Standard'` |
| **CMS SLA Limit** | 7 calendar days |
| **Industry Benchmark Mean** | 5.0 days |
| **Delta vs Benchmark** | −0.19 days (faster than benchmark — favorable) |
| **SLA Compliance Rate** | 79.0% (21.0% breach rate) |
| **SQL Source** | `vw_sla_compliance_summary` → `avg_standard_tat` |

**TAT Distribution Summary (Standard Requests):**

| Percentile | Days |
|-----------|------|
| P25 | 2.4 days |
| P50 (Median) | 4.2 days |
| P75 | 6.8 days |
| P90 | 9.1 days |
| P95 | ~12.0 days |
| Max | 14.0 days |

**SLA Breach Breakdown:**

| Breach Severity | Count | % of Standard Requests |
|----------------|-------|------------------------|
| On Time (≤7 days) | ~19,200 | 79.0% |
| 1 Day Over (8 days) | ~1,600 | 6.6% |
| 2–3 Days Over | ~2,200 | 9.1% |
| 4–7 Days Over | ~900 | 3.7% |
| 8+ Days Over | ~200 | 0.8% |

**Analytical Note:** The mean TAT of 4.81 days is within SLA and below the 5.0-day industry benchmark. However, the 21% breach rate signals a tail-distribution problem — the mean is flattering but the P95 tail at ~12 days represents real compliance exposure for the worst-performing 5% of requests. Electronic submission reduces TAT by approximately 0.8 days on average versus Fax submissions. [ASSUMPTION A08]

**Compliance Status:** ⚠️ Mean within SLA, but 21.0% breach rate requires operational attention. Priority: reduce Fax-submitted requests and incomplete documentation submissions.

---

### Metric M4b — Average Time to Prior Authorization Decision — Expedited Requests

| | |
|--|--|
| **CMS Definition** | Average number of calendar days from receipt of PA request to decision for expedited (urgent) requests |
| **PAIS CY2024 Value** | **1.45 days** |
| **DAX Measure** | `CMS M4b - Avg Expedited TAT Days` |
| **Source Field** | `decision_time_days` filtered to `request_type = 'Expedited'` |
| **CMS SLA Limit** | 3 calendar days (72 hours) |
| **Industry Benchmark Mean** | 1.5 days |
| **Delta vs Benchmark** | −0.05 days (on benchmark) |
| **SLA Compliance Rate** | 93.8% (6.2% breach rate) |
| **SQL Source** | `vw_sla_compliance_summary` → `avg_expedited_tat` |

**Expedited Volume:**
Expedited requests represent approximately 4% of total PA volume (~1,000 requests across 2023–2024). [ASSUMPTION A10]

**Analytical Note:** Expedited compliance at 93.8% is the stronger of the two SLA performance metrics. The 6.2% breach rate is operationally acceptable but warrants monitoring — any expedited breach represents an urgent case where a member's care was delayed beyond the 72-hour regulatory limit.

**Compliance Status:** ✅ Strong. Continue to monitor expedited breach rate for threshold approaching 10%.

---

### Metric M5 — List of Services Requiring Prior Authorization

| | |
|--|--|
| **CMS Definition** | A list of all services for which the plan requires prior authorization during the reporting period |
| **PAIS CY2024 Value** | **40 services** |
| **DAX Measure** | `CMS M5 - PA Required Services Count` |
| **Source Table** | `dim_service` where `prior_auth_required = TRUE` |
| **SQL Source** | `SELECT service_name FROM dim_service WHERE prior_auth_required = TRUE` |

**Services Requiring Prior Authorization (CY2024) — PAIS Synthetic List:**

| Service Category | Service Name | Base Denial Risk | Assumption Code |
|----------------|-------------|-----------------|----------------|
| Imaging | MRI — Brain | Moderate | C03 |
| Imaging | MRI — Spine | Moderate | C03 |
| Imaging | CT Scan — Chest | Moderate | C03 |
| Imaging | PET Scan | High | C03 |
| Imaging | Cardiac Imaging | High | C04 |
| Specialty Pharmacy | Specialty Drug — Oncology | High | C02 |
| Specialty Pharmacy | Specialty Drug — Rheumatology | High | C02 |
| Specialty Pharmacy | Specialty Drug — Neurology | High | C02 |
| Specialty Pharmacy | Specialty Drug — Immunology | High | C02 |
| Specialty Pharmacy | Specialty Drug — Endocrinology | Moderate | C02 |
| Surgical | Outpatient Surgery — Orthopedic | Moderate | C05 |
| Surgical | Outpatient Surgery — Cardiac | High | C05 |
| Surgical | Outpatient Surgery — General | Low | C05 |
| Surgical | Inpatient Elective Surgery | High | C05 |
| Behavioral Health | Inpatient Psychiatric Admission | High | C06 |
| Behavioral Health | Residential Mental Health | High | C06 |
| Behavioral Health | Intensive Outpatient Program | Moderate | C06 |
| Behavioral Health | Applied Behavior Analysis (ABA) | Moderate | C06 |
| Physical/Occupational | Physical Therapy — Extended | Low | C07 |
| Physical/Occupational | Occupational Therapy — Extended | Low | C07 |
| Physical/Occupational | Speech Therapy — Extended | Low | C07 |
| DME | Powered Wheelchair | High | C08 |
| DME | CPAP / BiPAP Device | Moderate | C08 |
| DME | Orthopedic Brace — Custom | Moderate | C08 |
| DME | Home Infusion Equipment | Moderate | C08 |
| Home Health | Skilled Nursing — Extended | Moderate | C09 |
| Home Health | Physical Therapy — Home | Low | C09 |
| Home Health | Home Health Aide — Extended | Low | C09 |
| Infusion | IV Antibiotics — Home | Moderate | C01 |
| Infusion | IVIG Therapy | High | C01 |
| Infusion | Chemotherapy — Home | High | C01 |
| Transplant | Solid Organ Transplant Evaluation | High | C10 |
| Transplant | Bone Marrow Transplant | High | C10 |
| Cardiac Procedures | Cardiac Catheterization | High | C04 |
| Cardiac Procedures | Implantable Cardiac Device | High | C04 |
| Cardiac Procedures | Cardiac Rehabilitation — Extended | Low | C04 |
| Neurology | Deep Brain Stimulation | High | C10 |
| Neurology | Spinal Cord Stimulator | High | C10 |
| Oncology | Radiation Therapy — Complex | High | C02 |
| Oncology | Proton Beam Therapy | High | C02 |

> **Note:** Service-category denial risk classifications (Low / Moderate / High) are assumption-based [C01–C10]. CMS public reporting does not provide service-level PA denial rates. These classifications are synthetic calibration inputs, not measured payer rates. [FN-4]

---

## Part II: Operational Performance Summary (Not CMS-Required — Analytics Supplement)

This section presents additional operational metrics that a payer analytics team would include as management context alongside the required CMS disclosure. These are not CMS-0057-F required metrics but provide the analytical depth needed for internal compliance review and recruiter demonstration.

### Appeal Performance Detail

| Metric | PAIS Value | KFF Benchmark | Delta |
|--------|-----------|--------------|-------|
| Total Appeals Filed | 175 (all periods) | — | — |
| Appeal Rate (% of denials) | 11.5% | 11.5% | 0.0 pp |
| Appeal Overturn Rate | 79.4% | 80.7% | −1.3 pp |
| Avg Appeal Decision Days | ~18 days | — | — |
| Additional Doc Submitted with Appeal | ~62% | — | — |

### Documentation Quality

| Metric | PAIS Value | Source |
|--------|-----------|--------|
| Documentation Complete Rate | 80.6% | `documentation_complete = TRUE` |
| Documentation Incomplete Rate | 19.4% | `documentation_complete = FALSE` |
| Denial Rate — Incomplete Docs | ~42% | CALCULATE with doc_complete=FALSE |
| Denial Rate — Complete Docs | ~14% | CALCULATE with doc_complete=TRUE |
| Documentation Denial Multiplier | ~3.0× | Incomplete ÷ Complete denial rate |

### Turnaround Time Benchmarks

| Request Type | Avg TAT | P90 TAT | P95 TAT | SLA Limit | Breach Rate |
|-------------|---------|---------|---------|-----------|-------------|
| Standard | 4.81 days | 9.1 days | ~12 days | 7 days | 21.0% |
| Expedited | 1.45 days | ~2.8 days | ~3.4 days | 3 days | 6.2% |
| Electronic | ~4.2 days | — | — | — | ~18% |
| Fax | ~5.0 days | — | — | — | ~26% |

### Provider Network Summary

| Metric | PAIS Value |
|--------|-----------|
| Total Providers in Network | 1,000 |
| In-Network Providers | ~850 (85%) |
| Out-of-Network Providers | ~150 (15%) |
| High-Risk Provider Segment | ~200 (20%) |
| OON vs In-Network Denial Multiplier | ~1.8× [ASSUMPTION G03] |

---

## Part III: CMS-0057-F Compliance Readiness Assessment

| Requirement | Status | Evidence |
|------------|--------|---------|
| M1 Approval Rate reported using final_outcome | ✅ Ready | `CMS M1 - Final Approval Rate %` uses correct field |
| M2 Denial Rate reported using final_outcome | ✅ Ready | `CMS M2 - Final Denial Rate %` uses correct field |
| M3 Appeal Overturn Rate | ✅ Ready | `CMS M3 - Appeal Overturn Rate %` from `fact_appeal` |
| M4a Standard TAT reported in calendar days | ✅ Ready | `decision_time_days` calculated at generation |
| M4b Expedited TAT reported in calendar days | ✅ Ready | `decision_time_days` with request_type filter |
| M5 List of PA-Required Services | ✅ Ready | `dim_service` — 40 services, prior_auth_required = TRUE |
| Public disclosure format | ✅ This document | Simulates the required public transparency filing |
| Data integrity | ✅ Verified | 40/40 DQ checks PASS in DuckDB (Phase 3 audit) |
| Leakage-risk field exclusion | ✅ Verified | `action_recommended_initial` excluded from all views |
| Synthetic disclaimer present | ✅ Required | FN-3 on all dashboard pages and this document |

---

## Part IV: Analytical Recommendations

These recommendations are what a payer analytics team would derive from this report and present to operational leadership. They are the portfolio-facing "so what" — translating metrics into action.

**Recommendation 1: Documentation Improvement Program**
34.2% of denials cite Documentation Incomplete as the reason. An estimated 520 of these are preventable (documentation was both incomplete AND the denial reason was documentation). A provider-facing pre-submission checklist program targeting the top 10 friction providers could reduce this by 40–60%, preventing 200–300 avoidable denials and appeals annually.

**Recommendation 2: Electronic Submission Incentive**
Fax-submitted requests have approximately 1.25× longer TAT than electronic submissions. The Standard SLA breach rate is 21%. Increasing electronic submission share from ~55% to ~75% would reduce Fax-related delays and could reduce the breach rate by an estimated 4–6 percentage points.

**Recommendation 3: Expedited Monitoring**
Expedited SLA compliance is 93.8% — strong, but the 6.2% breach rate represents urgent cases where members waited beyond the 72-hour regulatory limit. Any expedited breach warrants case-level review. Recommend automated escalation alerts when expedited requests approach hour 60 without a decision.

**Recommendation 4: Appeal Process Review**
A 79.4% appeal overturn rate raises a clinical management question: if most first-pass denials are reversed on appeal, are the initial denial criteria calibrated correctly? A clinical operations review of the top three denial reasons by overturn rate could identify criteria that are systematically too restrictive.

---

## Data Lineage and Source Traceability

| Metric | SQL View | DAX Measure | Source Field |
|--------|----------|------------|-------------|
| M1 Approval Rate | `vw_cms_public_metrics` | `CMS M1 - Final Approval Rate %` | `final_outcome` |
| M2 Denial Rate | `vw_cms_public_metrics` | `CMS M2 - Final Denial Rate %` | `final_outcome` |
| M3 Overturn Rate | `vw_appeal_funnel` | `CMS M3 - Appeal Overturn Rate %` | `fact_appeal[appeal_outcome]` |
| M4a Standard TAT | `vw_sla_compliance_summary` | `CMS M4a - Avg Standard TAT Days` | `decision_time_days` |
| M4b Expedited TAT | `vw_sla_compliance_summary` | `CMS M4b - Avg Expedited TAT Days` | `decision_time_days` |
| M5 Services List | Direct `dim_service` | `CMS M5 - PA Required Services Count` | `prior_auth_required` |

---

> **SIMULATION NOTICE (repeated):** This document is a portfolio simulation of a CMS-0057-F public metrics filing. All data is synthetic. No real payer, member, or provider data is represented. All benchmark comparisons use publicly available KFF Medicare Advantage data (Source S3, KFF Medicare Advantage 2024 Data Spotlight).

---

*CMS-0057-F Annual Prior Authorization Public Metrics Report (Simulated) — Phase 4. Last updated: 2026-05-31*
