# Business Problem Statement — Prior Authorization Intelligence System
**Phase 1 | Last Updated: 2026-05-31**

---

## Project Framing Statement

Prior authorization is not primarily a policy controversy. It is an **operational data problem** — one that involves request volume, decision timelines, approval and denial patterns, denial reason classification, appeal outcomes, documentation completeness, provider behavior, workflow bottlenecks, and payer transparency requirements.

This project builds a healthcare payer analytics system that treats prior authorization as a **workflow intelligence challenge**: how can analytics surface the right patterns, risks, and operational signals to help payer operations teams work more efficiently, more fairly, and in compliance with federal transparency mandates?

---

## 1. What Is Prior Authorization?

Prior authorization (PA) is a utilization management process used by health insurers to determine whether a requested service, procedure, medication, or referral meets coverage criteria before the service is rendered. Payers require providers to submit PA requests, which are then reviewed — either by automated systems, clinical staff, or medical directors — before a decision (approval, denial, or pend for additional information) is issued.

PA applies to a wide range of services: advanced imaging (MRI, CT), specialty drugs, surgeries, inpatient admissions, durable medical equipment, and certain outpatient procedures. It is used by Medicare Advantage (MA) plans, Medicaid managed care plans, commercial insurers, and qualified health plans on the ACA exchanges.

---

## 2. Why It Is a Real Problem: Evidence From Public Sources

### 2a. Scale of PA Activity in Medicare Advantage

Medicare Advantage plans processed **52.8 million prior authorization determinations** in 2024 alone. Of those, approximately **4.1 million (7.7%) were denied** in full or in part. The prior year saw 49.8 million determinations with 3.2 million (6.4%) denied. [Source: S3, S4 — KFF analysis of CMS data]

This is not a rare edge case. At national scale, millions of patients annually face a denied PA request. The volume creates a real operational analytics problem: which denials are preventable? Which are patterns? Which represent documentation gaps vs. true coverage exclusions?

### 2b. A Significant Share of Denials Are Inappropriate

The HHS Office of Inspector General (OIG) examined a stratified random sample of PA denials from the 15 largest Medicare Advantage organizations and found that **13% of denied PA requests met Medicare coverage rules** — meaning they likely would have been approved under original Medicare. These were not borderline cases; they met established medical necessity standards. [Source: S5 — OIG Report OEI-09-18-00260, 2022]

This finding has direct operational significance: if a payer could identify the characteristics of requests that are at high risk of incorrect denial (due to documentation gaps, misapplied clinical criteria, or workflow errors), it could redirect review resources to prevent incorrect outcomes before they reach the patient.

### 2c. Appeal Rates Are Low, But Overturn Rates Are High — A System Signal

Only **11.5% of denied PA requests** in 2024 were appealed by patients or providers. Yet of those that were appealed, **80.7% were partially or fully overturned**. [Source: S3]

This pattern has a clear analytical interpretation: most incorrect denials are never appealed — either because patients give up, providers do not have bandwidth to pursue appeals, or the cost of the appeal process exceeds the benefit. The high overturn rate among those that are appealed suggests the original denial decision contained an error that could have been caught earlier with better workflow tooling.

### 2d. PA Creates Significant Provider Workflow Burden

Physicians complete approximately **39 prior authorization requests per week** and spend approximately **13 hours of physician and staff time per week** on PA-related administrative tasks. 94% of physicians report that PA requirements cause care delays, and 33% say those delays have resulted in poor patient outcomes. [Source: S8 — AMA PA Physician Survey]

This burden is partly a provider-side problem. But it also means that payer PA workflows generate enormous volumes of incomplete or resubmitted requests — requests with missing clinical notes, lacking supporting documentation, or submitted for the wrong code. These become rework events in payer operations that slow turnaround times and increase cost-per-determination.

### 2e. Turnaround Times Vary Widely and Fall Short of New Standards

Industry benchmarks show standard PA decisions currently take **3 to 7 calendar days**, with urgent/expedited requests taking **24 to 72 hours**. When a request is denied and rework begins, total end-to-end time can exceed **10 to 21 days**. [Source: AMA/industry]

Beginning January 1, 2026, the CMS-0057-F Final Rule requires impacted payers to process urgent requests within 72 hours and standard requests within 7 calendar days — timelines that many payers already struggle to meet consistently across all request types and provider channels. [Source: S1]

### 2f. Federal Regulation Is Driving a Transparency and Accountability Shift

The CMS Interoperability and Prior Authorization Final Rule (CMS-0057-F), published January 17, 2024, fundamentally changes the payer analytics landscape in three ways:

**1. Mandatory public metrics reporting (2026):** Impacted payers must publish annual PA metrics — approval rates, denial rates, appeal overturn rates, and average decision turnaround times — by contract/plan/issuer level. The first report is due March 31, 2026 covering CY2025. This means every major payer now has a regulatory obligation to produce, validate, and publish the exact metrics this project is designed to track. [Source: S1, S2]

**2. Decision timeframe mandates:** 72 hours for urgent, 7 days for standard — with implications for operations, staffing, and SLA tracking. [Source: S1]

**3. Prior Authorization API requirement (2027):** Payers must implement a FHIR-based PA API enabling electronic submission, status checking, and documentation exchange — making the data infrastructure behind PA increasingly structured and auditable. [Source: S1]

---

## 3. What This Project Is — And Is Not

### What This Project IS:
- A **payer operations analytics system** that tracks PA request volume, decision timelines, denial patterns, documentation completeness, and appeal outcomes
- A **workflow intelligence tool** that uses analytics and predictive modeling to help payer operations teams prioritize reviews, flag delay risks, and identify documentation gaps before they cause denials
- A **compliance analytics layer** directly mapped to CMS-0057-F mandatory metrics reporting requirements
- A **portfolio demonstration** of healthcare payer analytics skills applicable to roles at CVS Health/Aetna, UnitedHealthcare, Cigna, Humana, The Hartford, and healthcare consulting firms

### What This Project IS NOT:
- Not a system that approves or denies patient care — clinical decisions remain with licensed medical professionals
- Not trained on real patient data — all row-level data in this project is **synthetic**, generated from source-backed benchmark distributions
- Not a compliance system or legal advice tool
- Not a generic healthcare dashboard

---

## 4. The Core Analytical Questions This Project Answers

The following questions are directly grounded in the sources above and represent the analytical spine of this project:

| # | Analytical Question | Business Value | Source Anchor |
|---|---------------------|---------------|---------------|
| 1 | What is the overall PA approval, denial, and pend rate by plan, service type, and provider? | Benchmark against S3/S4 KFF rates; flag outlier plans | S3, S4 |
| 2 | Which PA requests are at highest risk of delay (missing the 72-hr / 7-day SLA)? | Operational prioritization; SLA compliance under CMS-0057-F | S1 |
| 3 | What proportion of denials are associated with documentation deficiencies vs. coverage exclusions? | Reduce rework; improve documentation completeness upstream | S5, S8 |
| 4 | What is the denial-to-appeal-to-overturn funnel? Where do inappropriate denials escape correction? | Identify systemic review issues; reduce appeal volume | S3, S5 |
| 5 | Which service categories or provider types drive the most volume and the most denials? | Resource allocation; clinical criteria review prioritization | S3, S5 |
| 6 | Are turnaround times improving or degrading over time, and which segments drive variance? | SLA management; support for CMS-0057-F metrics reporting | S1, S7 |
| 7 | What would a CMS-0057-F–compliant public metrics report look like for this plan? | Directly demonstrates compliance analytics capability | S1, S2 |

---

## 5. Why This Project Matters to Target Employers

Healthcare payers are under simultaneous pressure from three directions:

- **Regulatory pressure:** CMS-0057-F requires metrics transparency and faster decisions starting 2026
- **Operational pressure:** PA volumes are growing (50M+ determinations in MA alone); staff costs are rising; turnaround SLA compliance is increasingly scrutinized
- **Reputational/legal pressure:** OIG oversight, state legislation, and public attention to PA denial rates mean that inappropriate denial patterns carry real organizational risk

The analytics skills demonstrated in this project — metrics design, pipeline construction, operations dashboard development, predictive modeling for workflow prioritization, and compliance reporting — are directly applicable to the problems being actively worked on by analytics teams at CVS Health/Aetna, UnitedHealthcare, Cigna, Humana, and health plan analytics consulting firms.

---

## 6. Scope and Constraints

| Constraint | Decision |
|-----------|---------|
| Real PA records are private/PHI | Use synthetic data generated from source-backed benchmarks |
| Project covers MA context primarily | Benchmark data is richest for Medicare Advantage; Medicaid comparisons noted where available |
| No claims to clinical authority | All models framed as decision-support tools for operational staff |
| No overclaiming on model accuracy | Models evaluated against realistic baselines; limitations documented |

---

*Sources: S1 (CMS-0057-F), S2 (CMS Fact Sheet), S3 (KFF 2024), S4 (KFF 2023), S5 (OIG 2022), S7 (Aetna/CVS), S8 (AMA Survey). See source_registry.md for full citations.*
