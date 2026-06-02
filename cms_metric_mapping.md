# CMS Metric Mapping — Prior Authorization Intelligence System
**Phase 1 | Last Updated: 2026-05-31**
**Regulatory Reference: CMS-0057-F (CMS Interoperability and Prior Authorization Final Rule, January 17, 2024)**

---

## Purpose of This Document

CMS-0057-F requires impacted payers to publish a defined set of prior authorization metrics annually, beginning with CY2025 data reported by March 31, 2026.

This document maps each CMS-required metric directly to:
1. The **analytics use case** it enables in this project
2. The **synthetic data field(s)** that will need to exist to calculate it
3. The **dashboard or report component** where it will appear
4. The **source** confirming the requirement

This document ensures the project is not building arbitrary KPIs — it is building the exact metrics real payers are now legally required to track and publish.

---

## Regulatory Context: Who Must Report?

Under CMS-0057-F, the following payer types must publish annual PA metrics publicly:

| Payer Type | Reporting Level | Compliance Date |
|-----------|----------------|----------------|
| Medicare Advantage (MA) organizations | Contract level | March 31, 2026 (CY2025) |
| State Medicaid FFS programs | State level | March 31, 2026 (CY2025) |
| Medicaid managed care plans | Plan level | March 31, 2026 (CY2025) |
| CHIP managed care entities | Plan level | March 31, 2026 (CY2025) |
| QHP issuers on Federally Facilitated Exchanges | Issuer level | March 31, 2026 (CY2025) |

**This project simulates the analytics infrastructure for a Medicare Advantage organization reporting at the contract level.**

---

## CMS-Required Metric → Project Mapping Table

### Metric 1: List of All Items and Services Requiring PA

| Field | Detail |
|-------|--------|
| **CMS Requirement** | Payers must publish a complete list of all medical items and services (excluding drugs) that require prior authorization |
| **Regulatory Source** | CMS-0057-F §422.122(h)(1); Fact Sheet (S2) |
| **Business Meaning** | Establishes the universe of PA-eligible service categories; needed to calculate rates correctly |
| **Project Use Case** | Service category dimension in all PA analyses; required for denominator calculation in approval/denial rates |
| **Synthetic Data Fields Required** | `service_category`, `service_code` (CPT/HCPCS), `pa_required_flag` |
| **Dashboard Component** | Service Category Overview panel; filtering dimension across all visualizations |
| **Notes** | Project will use a representative set of ~8-10 service categories (imaging, surgery, durable medical equipment, inpatient admission, etc.) calibrated to real PA-heavy service types |

---

### Metric 2: Percent of PA Requests Approved

| Field | Detail |
|-------|--------|
| **CMS Requirement** | Payers must report the percentage of prior authorization requests that were approved |
| **Regulatory Source** | CMS-0057-F; CMS Fact Sheet (S2) |
| **Business Meaning** | Approval rate is the primary payer PA performance benchmark; tracked annually and by plan/contract |
| **Project Use Case** | Primary KPI on executive summary dashboard; trend analysis over time; plan-level benchmark comparison |
| **Synthetic Data Fields Required** | `request_id`, `decision_outcome` (approved / denied / partially approved / pended), `decision_date` |
| **Dashboard Component** | KPI summary card: "Overall Approval Rate"; trend line chart by quarter; breakdown by service category and plan |
| **Benchmark** | ~90% approval rate in MA (KFF 2024: 92.3% fully favorable) [S3] |
| **Notes** | Distinguish fully approved vs. partially approved in synthetic data to enable richer analysis |

---

### Metric 3: Percent of PA Requests Denied

| Field | Detail |
|-------|--------|
| **CMS Requirement** | Payers must report the percentage of prior authorization requests that were denied (in full or in part) |
| **Regulatory Source** | CMS-0057-F; CMS Fact Sheet (S2) |
| **Business Meaning** | Denial rate is a key payer quality and access metric; high denial rates for certain categories trigger regulatory scrutiny |
| **Project Use Case** | Denial rate KPI; denial breakdown by reason code; denial rate trend; outlier detection by plan/provider |
| **Synthetic Data Fields Required** | `decision_outcome`, `denial_reason_code`, `denial_reason_category` |
| **Dashboard Component** | KPI card: "Overall Denial Rate"; denial reason distribution chart; denial rate heatmap by service × plan |
| **Benchmark** | ~7.7% denied (full or partial) in MA 2024 [S3]; 6.4% in 2023 [S4] |
| **Denial Reason Categories** | Documentation incomplete; medical necessity not established; not a covered benefit; clinical criteria not met; wrong plan/network; duplicate request |
| **Notes** | Denial reason classification is analytically critical — 13% of MA denials found to meet coverage rules (OIG S5); denial reason drives rework prediction |

---

### Metric 4: Percent of PA Requests Approved After Appeal

| Field | Detail |
|-------|--------|
| **CMS Requirement** | Payers must report the percentage of denied requests that were approved after appeal |
| **Regulatory Source** | CMS-0057-F; CMS Fact Sheet (S2) |
| **Business Meaning** | High appeal overturn rates signal that initial decisions were incorrect; indicates upstream process failure |
| **Project Use Case** | Appeal overturn rate KPI; funnel analysis (denied → appealed → overturned); identification of appeal-prone denial reason types |
| **Synthetic Data Fields Required** | `appeal_filed_flag`, `appeal_outcome` (upheld / overturned / partially overturned), `appeal_date`, `appeal_decision_date` |
| **Dashboard Component** | "Appeal Funnel" visualization; overturn rate by denial reason; time-to-appeal-decision analysis |
| **Benchmark** | 11.5% of denied PAs are appealed; 80.7% of appealed denials are overturned (KFF 2024) [S3] |
| **Notes** | Low appeal rate + high overturn rate = a significant population of incorrect denials that are never corrected. This is a core analytical insight the project highlights. |

---

### Metric 5: Average Time Between PA Submission and Decision

| Field | Detail |
|-------|--------|
| **CMS Requirement** | Payers must report the average number of days between PA submission and the decision |
| **Regulatory Source** | CMS-0057-F; CMS Fact Sheet (S2) |
| **Business Meaning** | Core SLA metric; directly tied to CMS-0057-F mandatory decision timeframes (72 hrs urgent; 7 days standard) |
| **Project Use Case** | SLA compliance dashboard; turnaround time distribution; delay risk prediction model; drill-down by urgency tier, service category, and submission channel |
| **Synthetic Data Fields Required** | `submission_date`, `submission_time`, `decision_date`, `urgency_flag` (urgent / standard), `submission_channel` (electronic / fax / phone / portal) |
| **Dashboard Component** | Average Turnaround KPI; SLA breach rate gauge; turnaround distribution histogram; delay risk heat map |
| **Benchmarks** | Standard: 3-7 calendar days industry current; Urgent: 24-72 hours; CMS mandate: ≤7 days standard, ≤72 hours urgent [S1, industry] |
| **Notes** | This metric directly feeds the delay-risk prediction model (Phase 3); turnaround time is the single most operationally actionable metric in the project |

---

## Additional Operational Metrics (Beyond CMS Minimums)

These metrics are not explicitly required by CMS-0057-F but are standard payer operations analytics KPIs that demonstrate deeper analytical capability:

### M6: Documentation Completeness Rate

| Field | Detail |
|-------|--------|
| **Business Meaning** | Percentage of PA requests submitted with complete required documentation on first submission |
| **Project Use Case** | Identify documentation deficiency patterns by provider, service type, or submission channel |
| **Synthetic Data Fields** | `docs_complete_on_submission_flag`, `missing_doc_types` (list), `resubmission_count` |
| **Analytical Value** | Leading indicator for denial risk; incomplete documentation is a primary cause of preventable denials [S5, S8] |

### M7: Pend/Pending Rate and Pend Resolution Time

| Field | Detail |
|-------|--------|
| **Business Meaning** | Percentage of requests pended (held for additional information) and average time to resolve |
| **Project Use Case** | Identify bottlenecks; pended requests consume operational bandwidth and delay care |
| **Synthetic Data Fields** | `decision_outcome` (pended), `pend_reason`, `pend_resolution_date` |

### M8: Provider Submission Volume and Denial Rate

| Field | Detail |
|-------|--------|
| **Business Meaning** | Volume and denial rate by submitting provider or provider group |
| **Project Use Case** | Identify providers with unusually high denial rates due to documentation patterns; target outreach |
| **Synthetic Data Fields** | `provider_npi`, `provider_specialty`, `provider_state` |

### M9: First-Pass Approval Rate

| Field | Detail |
|-------|--------|
| **Business Meaning** | Percentage of requests approved on first submission without additional documentation request or resubmission |
| **Project Use Case** | Operational efficiency KPI; Aetna benchmarks 95%+ approval within 24 hours [S7] |
| **Synthetic Data Fields** | `first_pass_approval_flag` |

---

## Decision Timeframe Compliance Mapping

CMS-0057-F mandates specific decision timeframes. This project tracks compliance against these as named SLA thresholds:

| Urgency Type | CMS-0057-F Mandate | Current Industry Range | SLA Label in Project |
|-------------|-------------------|----------------------|---------------------|
| Urgent / Expedited | ≤ 72 hours | 24–72 hours | `SLA_URGENT_72HR` |
| Standard / Non-Urgent | ≤ 7 calendar days | 3–7 calendar days | `SLA_STANDARD_7DAY` |
| Post-denial appeal decision | Not yet mandated | 10–21+ days | `APPEAL_RESOLUTION_TIME` |

**SLA Compliance Rate** = (Requests decided within SLA threshold) / (Total requests of that urgency type) × 100

---

## Summary: Project KPI Architecture

| KPI | CMS-Required? | Phase Where Built |
|-----|--------------|-------------------|
| Approval Rate | ✅ Yes | Phase 3 (Dashboard) |
| Denial Rate | ✅ Yes | Phase 3 (Dashboard) |
| Denial Rate by Reason Code | Partially (CMS requires rate; reasons are value-add) | Phase 3 |
| Appeal Rate | ✅ Yes (as % approved after appeal) | Phase 3 |
| Appeal Overturn Rate | ✅ Yes | Phase 3 |
| Average Turnaround Time | ✅ Yes | Phase 3 |
| SLA Breach Rate (Urgent / Standard) | Derived from #5 | Phase 3 |
| Documentation Completeness Rate | Operational best practice | Phase 3 |
| Delay Risk Score (predicted) | Decision-support tool | Phase 4 (Model) |
| Pend Rate and Resolution Time | Operational best practice | Phase 3 |
| Provider-Level Denial Rate | Operational best practice | Phase 3 |
| First-Pass Approval Rate | Operational best practice | Phase 3 |

---

*Regulatory source: CMS-0057-F (S1), CMS Fact Sheet (S2). Benchmark sources: KFF S3/S4, OIG S5, Aetna S7. See source_registry.md for full citations.*
