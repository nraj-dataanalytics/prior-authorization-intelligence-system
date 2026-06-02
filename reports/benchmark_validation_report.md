# Benchmark Validation Report — Prior Authorization Intelligence System
**Phase 2 | Generated: 2026-05-31 | Regenerated during Phase 2 audit**
**ALL DATA IS SYNTHETIC. No PHI. No real patient records.**

---

## Calibration Note: KFF Approval Rate Comparison

KFF's 92.3% approval rate and 7.7% denial rate (S3) are **final outcome rates** from CMS
formal determination data — after pend resolution. This generator uses 3-state initial
routing (Approved / Denied / Pended). The correct benchmark comparison is `final_outcome`.

| Measure | This Dataset | KFF Target (S3) |
|---------|-------------|----------------|
| Initial approval rate | 86.8% | N/A (routing, not final) |
| Initial denial rate | 6.1% | N/A (routing, not final) |
| **Final outcome approval** | **92.7%** | **92.3% (range 88–94.5%)** |
| Pend rate | 7.1% | Not separately reported in CMS data |

---

## Section 1: Volume Metrics (5 checks)

| # | Metric | Synthetic Value | Target | Range | Status |
|---|--------|----------------|--------|-------|--------|
| V1 | Total requests | 25,000 | 25,000 | 24,900–25,100 | ✅ PASS |
| V2 | Total members | 5,000 | 5,000 | 4,990–5,010 | ✅ PASS |
| V3 | Total providers | 1,000 | 1,000 | 990–1,010 | ✅ PASS |
| V4 | Total services | 40 | 40 | 38–42 | ✅ PASS |
| V5 | 2024 share (A25 YoY growth) | 53.0% | 53% | 51–55% | ✅ PASS |

---

## Section 2: Decision Outcome Metrics (4 checks)

| # | Metric | Synthetic Value | Target | Range | Source | Status |
|---|--------|----------------|--------|-------|--------|--------|
| D1 | Initial approval rate | 86.8% | ~85% | 80–92% | Generator design | ✅ PASS |
| D2 | Initial denial rate | 6.1% | ~6% | 4–9% | Generator design | ✅ PASS |
| D3 | Initial pend rate | 7.1% | ~9% | 4–12% | A14 [ASSUMPTION] | ✅ PASS |
| D4 | **Final outcome approval** | **92.7%** | **92.3%** | **88–94.5%** | **KFF S3** | **✅ PASS** |

---

## Section 3: Channel & Documentation Metrics (6 checks)

| # | Metric | Synthetic Value | Target | Range | Source | Status |
|---|--------|----------------|--------|-------|--------|--------|
| C1 | Expedited share | 15.2% | 15% | 13–17% | A23 [ASSUMPTION] | ✅ PASS |
| C2 | Incomplete docs rate | 19.4% | 22% | 16–28% | A13 [ASSUMPTION] | ✅ PASS |
| C3 | Electronic channel | 55.2% | 55% | 50–60% | A20 [ASSUMPTION] | ✅ PASS |
| C4 | Fax channel | 24.9% | 25% | 22–28% | A21 [ASSUMPTION] | ✅ PASS |
| C5 | Portal channel | 11.9% | 12% | 9–15% | A22 [ASSUMPTION] | ✅ PASS |
| C6 | Phone channel | 8.0% | 8% | 5–12% | A22 [ASSUMPTION] | ✅ PASS |

---

## Section 4: Turnaround Time & SLA Compliance (4 checks)

| # | Metric | Synthetic Value | Target | Range | Source | Status |
|---|--------|----------------|--------|-------|--------|--------|
| T1 | Avg standard TAT | 4.81 days | 5.0 days | 3.5–7.0 | A07 / CMS-0057-F S1 | ✅ PASS |
| T2 | Avg expedited TAT | 1.45 days | 1.5 days | 0.8–2.5 | A08 / CMS-0057-F S1 | ✅ PASS |
| T3 | SLA breach — standard | 21.0% | ~18% | 8–30% | A10 [ASSUMPTION] | ✅ PASS |
| T4 | SLA breach — expedited | 6.2% | ~10% | 3–18% | A11 [ASSUMPTION] | ✅ PASS |

---

## Section 5: Appeal Metrics (3 checks)

| # | Metric | Synthetic Value | Target | Range | Source | Status |
|---|--------|----------------|--------|-------|--------|--------|
| A1 | Appeal rate (of denied) | 11.5% | 11.5% | 9–14% | A04 / KFF S3 | ✅ PASS |
| A2 | Appeal overturn rate | 79.4% | 80.7% | 73–87% | A05 / KFF S3 | ✅ PASS |
| A3 | Total appeals | 175 | ~175 | 140–260 | Derived A04 | ✅ PASS |

---

## Section 6: Denial Reason Distribution (5 checks)

| # | Denial Reason | Synthetic % | Target % | Range | Source | Status |
|---|---------------|------------|----------|-------|--------|--------|
| R1 | Medical Necessity Not Met | 29.5% | 35% | 25–45% | A15 / OIG S5 + Commonwealth Fund | ✅ PASS |
| R2 | Documentation Incomplete | 34.0% | 28% | 18–36% | A16 / OIG S5 + AMA S8 | ✅ PASS |
| R3 | Clinical Criteria Not Met | 19.7% | 20% | 12–28% | A17 / OIG S5 | ✅ PASS |
| R4 | Not a Covered Benefit | 9.5% | 10% | 5–18% | A18 [ASSUMPTION] | ✅ PASS |
| R5 | Duplicate/Administrative Error | 7.3% | 7% | 3–14% | A19 [ASSUMPTION] | ✅ PASS |

---

## Section 7: Causal Pattern Validation (5 checks)

All encoded causal patterns must appear in the output data.

| # | Pattern | Result | Direction Confirmed | Status |
|---|---------|--------|---------------------|--------|
| P1 | Incomplete docs → higher denial rate | 13.2% vs 4.4% (complete) | 3.0x ratio | ✅ PASS |
| P2 | Post-Acute/SNF denial > Outpatient | 10.4% vs 2.4% | 4.3x ratio | ✅ PASS |
| P3 | Fax denial > Electronic denial | 7.3% vs 5.6% | Confirmed | ✅ PASS |
| P4 | Automated reviewer denial < Medical Director | 1.7% vs 7.7% | 4.5x ratio | ✅ PASS |
| P5 | High-Risk provider denial > Moderate > Low | 9.8% / 6.7% / 5.1% | Confirmed | ✅ PASS |

---

## Section 8: Service Category Breakdown

| Service Category | Requests | Share | Observed Denial Rate | Base Risk [ASSUMPTION] |
|-----------------|---------|-------|---------------------|----------------------|
| Advanced Imaging | 4,006 | 16.0% | 7.5% | 0.12 |
| Inpatient Hospital | 3,421 | 13.7% | 8.9% | 0.13 |
| Outpatient Procedures | 2,910 | 11.6% | 2.4% | 0.05 |
| Surgical Procedures | 2,701 | 10.8% | 7.3% | 0.10 |
| Durable Medical Equipment | 2,449 | 9.8% | 4.2% | 0.10 |
| Post-Acute / SNF | 2,071 | 8.3% | 10.4% | 0.16 |
| Physical/Occupational Therapy | 2,041 | 8.2% | 2.6% | 0.06 |
| Specialty Drugs | 1,992 | 8.0% | 7.3% | 0.09 |
| Home Health | 1,818 | 7.3% | 4.1% | 0.09 |
| Behavioral Health | 1,591 | 6.4% | 3.7% | 0.08 |

---

## Validation Summary

**Total benchmark checks: 32 | Pass: 32 | Fail: 0**

| Section | Checks | Pass | Fail |
|---------|--------|------|------|
| Volume Metrics | 5 | 5 | 0 |
| Decision Outcomes | 4 | 4 | 0 |
| Channel & Documentation | 6 | 6 | 0 |
| Turnaround & SLA | 4 | 4 | 0 |
| Appeal Metrics | 3 | 3 | 0 |
| Denial Reason Distribution | 5 | 5 | 0 |
| Causal Pattern Validation | 5 | 5 | 0 |
| **Total** | **32** | **32** | **0** |

---

## Phase 3 Notes

1. Use `final_outcome` (not `decision`) when benchmarking approval/denial rates against KFF S3.
2. Exclude `action_recommended_initial` from all predictive model feature matrices — leakage risk.
3. Exclude `appeal_id` and `appealed` from models predicting `decision`.
4. Service-category denial rates are [ASSUMPTION]-labeled — for pattern analysis only, not precise benchmarks.
5. OIG 13% finding (S5, OEI-09-18-00260, 2019 study period) is cited for context only.
6. Year-over-year denial rate differences (2023 vs 2024) reflect random variation — no modeled trend shift.

*Generated: generate_synthetic_data.py seed=42 | ALL DATA SYNTHETIC — NO PHI*
