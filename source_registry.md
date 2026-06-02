# Source Registry — Prior Authorization Intelligence System
**Phase 1 | Last Updated: 2026-05-31**

> This registry documents every public source used to ground the project in real-world evidence. Each source is verified, linked, and mapped to a specific project purpose. No synthetic data is cited here.

---

## How to Read This Registry

| Column | Meaning |
|--------|---------|
| Source ID | Short reference code used throughout all project files |
| Source | Title and organization |
| URL | Direct link to the primary document or page |
| Publication Date | Year/month published or last updated |
| Source Type | Federal rule / Federal report / Research / Industry / Survey |
| Relevance to Project | Specific claim(s) or metric(s) this source supports |

---

## Source Table

### S1 — CMS-0057-F Final Rule (Primary Regulatory Anchor)

| Field | Detail |
|-------|--------|
| **Source ID** | S1 |
| **Title** | CMS Interoperability and Prior Authorization Final Rule (CMS-0057-F) |
| **Organization** | Centers for Medicare & Medicaid Services (CMS) |
| **URL** | https://www.cms.gov/cms-interoperability-and-prior-authorization-final-rule-cms-0057-f |
| **Full Rule PDF** | https://www.cms.gov/files/document/cms-0057-f.pdf |
| **Publication Date** | January 17, 2024 |
| **Source Type** | Federal Final Rule |
| **Relevance** | Regulatory mandate driving payer PA data transparency obligations; establishes 72-hour/7-day decision timeframe standards; defines required public metrics payers must post beginning 2026; creates the Prior Authorization API requirement |

**Key Facts Extracted:**
- Published January 17, 2024; finalized from proposed rule CMS-0057-P
- Impacted payers: Medicare Advantage (MA) organizations, Medicaid FFS, Medicaid managed care plans, CHIP, QHP issuers on Federally Facilitated Exchanges
- Operational compliance: January 1, 2026
- API compliance: January 1, 2027
- Decision timeframes required: **72 hours** (urgent/expedited), **7 calendar days** (standard/non-urgent)
- Annual public metrics posting required starting March 31, 2026 (covering CY2025)
- Metrics reporting level: MA at contract level; Medicaid at state/plan level; QHPs at issuer level

---

### S2 — CMS-0057-F Fact Sheet

| Field | Detail |
|-------|--------|
| **Source ID** | S2 |
| **Title** | Fact Sheet: CMS Interoperability and Prior Authorization Final Rule (CMS-0057-F) |
| **Organization** | Centers for Medicare & Medicaid Services (CMS) |
| **URL** | https://www.cms.gov/newsroom/fact-sheets/cms-interoperability-prior-authorization-final-rule-cms-0057-f |
| **PDF** | https://www.cms.gov/files/document/fact-sheet-cms-interoperability-and-prior-authorization-final-rule-cms-0057-f.pdf |
| **Publication Date** | January 2024 |
| **Source Type** | Federal Fact Sheet / Implementation Guidance |
| **Relevance** | Plain-language summary of CMS-0057-F requirements; confirms required public metrics payers must report; provides compliance timeline detail |

**Key Facts Extracted:**
- Confirms required metrics: percent of PA requests approved, denied, approved after appeal; average time between submission and decision; list of all items/services requiring PA
- First reporting deadline: March 31, 2026 for CY2025 data
- Builds on prior rule CMS-9115-F (2020)

---

### S3 — KFF Medicare Advantage PA Analysis (2024 Data)

| Field | Detail |
|-------|--------|
| **Source ID** | S3 |
| **Title** | Medicare Advantage Insurers Made Nearly 53 Million Prior Authorization Determinations in 2024 |
| **Organization** | Kaiser Family Foundation (KFF) |
| **URL** | https://www.kff.org/medicare/medicare-advantage-insurers-made-nearly-53-million-prior-authorization-determinations-in-2024/ |
| **Publication Date** | 2025 (covering 2024 CMS data) |
| **Source Type** | Independent Research / Policy Analysis |
| **Relevance** | PA volume benchmarks; approval/denial rate baselines; appeal rate and overturn rate benchmarks for MA plans |

**Key Facts Extracted:**
- 52.8 million PA determinations in MA in 2024
- 90%+ (48.7M) fully favorable (approved)
- 4.1M (7.7%) denied in full or in part
- Only 11.5% of denials are appealed (very low appeal uptake)
- Of those appealed, 80.7% were partially or fully overturned
- Denial rate trend (CMS appeal data): 24.8% (2021) → 27.6% (2022) → 28.8% (2023) → 22.9% (2024)

---

### S4 — KFF Medicare Advantage PA Analysis (2023 Data)

| Field | Detail |
|-------|--------|
| **Source ID** | S4 |
| **Title** | Medicare Advantage Insurers Made Nearly 50 Million Prior Authorization Determinations in 2023 |
| **Organization** | Kaiser Family Foundation (KFF) |
| **URL** | https://www.kff.org/medicare/nearly-50-million-prior-authorization-requests-were-sent-to-medicare-advantage-insurers-in-2023/ |
| **Publication Date** | 2024 (covering 2023 CMS data) |
| **Source Type** | Independent Research / Policy Analysis |
| **Relevance** | Year-over-year PA volume and denial rate trends; 2023 baseline for benchmark assumptions |

**Key Facts Extracted:**
- 49.8 million PA determinations in MA in 2023
- 90%+ (46.6M) fully favorable
- 3.2M (6.4%) denied in full or in part
- Appeals share: 11.7% of denied requests appealed in 2023

---

### S5 — HHS OIG Report: MA Prior Authorization Denials (2022)

| Field | Detail |
|-------|--------|
| **Source ID** | S5 |
| **Title** | Some Medicare Advantage Organization Denials of Prior Authorization Requests Raise Concerns About Beneficiary Access to Medically Necessary Care |
| **Organization** | U.S. Department of Health and Human Services, Office of Inspector General (HHS OIG) |
| **URL** | https://oig.hhs.gov/reports/all/2022/some-medicare-advantage-organization-denials-of-prior-authorization-requests-raise-concerns-about-beneficiary-access-to-medically-necessary-care/ |
| **Full PDF** | https://oig.hhs.gov/oei/reports/OEI-09-18-00260.pdf |
| **Publication Date** | 2022 (study period: June 2019; published 2022) |
| **Source Type** | Federal Oversight Report |
| **Relevance** | Core finding that 13% of MA PA denials met Medicare coverage rules (i.e., were inappropriate); establishes that denial reason classification is analytically meaningful; motivates denial-reason analysis in this project |

**Key Facts Extracted:**
- Stratified random sample of 250 PA denials from 15 largest MAOs (June 1-7, 2019)
- **13% of PA denials met Medicare coverage rules** — meaning they should have been approved
- Primary denial cause types: (1) use of non-Medicare clinical criteria by MAOs; (2) lack of CMS guidance clarity
- Report ID: OEI-09-18-00260

---

### S6 — HHS OIG Report: Medicaid Managed Care PA Denials (2023)

| Field | Detail |
|-------|--------|
| **Source ID** | S6 |
| **Title** | High Rates of Prior Authorization Denials by Some Plans and Limited State Oversight Raise Concerns About Access to Care in Medicaid Managed Care |
| **Organization** | HHS OIG |
| **URL** | https://oig.hhs.gov/reports/all/2023/high-rates-of-prior-authorization-denials-by-some-plans-and-limited-state-oversight-raise-concerns-about-access-to-care-in-medicaid-managed-care/ |
| **Publication Date** | 2023 |
| **Source Type** | Federal Oversight Report |
| **Relevance** | Extends MA findings to Medicaid managed care context; shows that denial rate variation across plans is analytically significant — supports plan-level comparisons in analytics layer |

---

### S7 — Aetna/CVS Health PA Simplification Progress (2025-2026)

| Field | Detail |
|-------|--------|
| **Source ID** | S7 |
| **Title** | Aetna Announces Progress on Industry Leading Efforts to Simplify Prior Authorization |
| **Organization** | CVS Health / Aetna |
| **URL** | https://www.cvshealth.com/news/company-news/aetna-announces-progress-on-industry-leading-efforts-to-simplify-prior-authorization.html |
| **Investor Relations URL** | https://investors.cvshealth.com/news/news-details/2026/Aetna-Announces-Progress-on-Industry-Leading-Efforts-to-Simplify-Prior-Authorization/default.aspx |
| **Publication Date** | 2025-2026 |
| **Source Type** | Industry / Payer Press Release |
| **Relevance** | Real-world payer operational benchmark: 88% PA volume standardized; 95%+ approved within 24 hours; 83% processed in real time; supports automation rate and approval speed assumptions |

**Key Facts Extracted:**
- 88% of Aetna PA volume is standardized (exceeds industry commitments)
- 95%+ of eligible PAs approved within 24 hours
- 83% processed in real time (exceeds AHIP 2027 industry commitment of 80%)
- Eliminated 1M+ provider calls through automation
- Aetna first national payer to integrate bundled medical + pharmacy PA decisions

---

### S8 — AMA Prior Authorization Physician Survey (2024/2025)

| Field | Detail |
|-------|--------|
| **Source ID** | S8 |
| **Title** | 2025 AMA Prior Authorization Physician Survey |
| **Organization** | American Medical Association (AMA) |
| **URL** | https://www.ama-assn.org/system/files/prior-authorization-survey.pdf |
| **Survey Results Hub** | https://www.ama-assn.org/topics/prior-authorization-survey |
| **Publication Date** | 2024-2025 |
| **Source Type** | Physician Survey |
| **Relevance** | Provider-side burden: ~39 PA requests per physician per week; ~13 staff hours/week consumed; 94% of physicians report PA-related care delays; supports framing of PA as an operational workflow problem |

**Key Facts Extracted:**
- ~39-43 PA requests per physician per week (2024 survey)
- ~13 hours of physician and staff time consumed per week per physician
- 94% of physicians reported PA-related care delays
- 33% reported PA delays resulted in poor patient outcomes

---

### S9 — CMS Press Release: Finalizing CMS-0057-F

| Field | Detail |
|-------|--------|
| **Source ID** | S9 |
| **Title** | CMS Finalizes Rule to Expand Access to Health Information and Improve the Prior Authorization Process |
| **Organization** | CMS |
| **URL** | https://www.cms.gov/newsroom/press-releases/cms-finalizes-rule-expand-access-health-information-and-improve-prior-authorization-process |
| **Publication Date** | January 17, 2024 |
| **Source Type** | Federal Press Release |
| **Relevance** | Official CMS framing of the PA problem; confirms the policy intent; useful for project narrative |

---

### S10 — CMS Medicare Advantage/Part D Contract and Enrollment Data

| Field | Detail |
|-------|--------|
| **Source ID** | S10 |
| **Title** | Medicare Advantage/Part D Contract and Enrollment Data |
| **Organization** | CMS |
| **URL** | https://www.cms.gov/data-research/statistics-trends-and-reports/medicare-advantagepart-d-contract-and-enrollment-data |
| **Publication Date** | Ongoing (updated annually) |
| **Source Type** | CMS Public Use Data |
| **Relevance** | Public enrollment data for MA plans; supports plan-level analysis framing in project; provides contract-level reference for metric reporting context |

---

## Source Coverage Summary

| Project Layer | Supporting Sources |
|--------------|-------------------|
| Regulatory mandate / why this project matters | S1, S2, S9 |
| PA volume and approval/denial rate benchmarks | S3, S4 |
| Inappropriate denial evidence | S5, S6 |
| Payer operational benchmarks (turnaround, automation) | S7, S1 (timeframes) |
| Provider burden (volume, delays) | S8 |
| CMS public data infrastructure | S10 |

---

## Sources NOT Used (and Why)

| Source Type | Why Excluded |
|------------|-------------|
| Real payer-level PA claim records | Private/PHI — not publicly available; will use synthetic data in Phase 2 |
| State insurance commissioner complaints data | Valuable but not uniformly available across states |
| EHR or EMR system data | Proprietary; not publicly accessible |

---

*All sources verified as of May 2026. URLs checked and confirmed active.*
