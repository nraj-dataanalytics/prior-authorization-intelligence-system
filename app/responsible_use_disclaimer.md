# Responsible Use Disclaimer
## Prior Authorization Intelligence System (PAIS) — Phase 6
**Version 1.0 | Generated: 2026-06-01**

---

## This Tool's Purpose

The Prior Authorization Intelligence System (PAIS) is an **operational workflow decision-support tool** for prior authorization administrative operations in Medicare Advantage and commercial health plan environments.

This tool is designed to support:
- Workflow prioritization (which cases need coordinator attention first)
- Documentation follow-up (which cases are likely missing required documentation)
- SLA monitoring (which cases are at risk of missing CMS-0057-F turnaround time requirements)
- Provider outreach targeting (which providers have patterns of incomplete submissions)
- Operational escalation (which cases should go to senior reviewers or medical directors)

---

## What This Tool Does NOT Do

**This tool does NOT approve or deny care.**
Output from this tool is not a coverage determination. The tool produces risk scores and workflow routing recommendations — not clinical decisions.

**This tool does NOT replace clinical judgment.**
All clinical determinations must be made by qualified reviewers (licensed clinical staff, medical directors) in accordance with the payer's internal policies, plan benefit documentation, and applicable clinical guidelines.

**This tool is NOT a compliance certification.**
Output from this tool does not constitute compliance with CMS-0057-F, NCQA standards, state PA requirements, or any other regulatory framework. Compliance remains the responsibility of the payer organization and its qualified staff.

**This tool does NOT use real patient data.**
All models were trained on **synthetic, benchmark-calibrated data** (25,000 rows). No PHI (Protected Health Information) was used at any stage of this project. No real payer records, real member records, or real provider records were used.

**This tool does NOT guarantee model accuracy for your specific population.**
Model performance metrics (ROC-AUC 0.799 for delay, 0.713 for denial) are from a synthetic dataset. Real-world performance may differ significantly based on actual payer workflow, provider mix, service mix, and regional factors.

---

## Output Language Requirement

All outputs from this tool use the following language standards:

| Output Type | Required Language | Prohibited Language |
|---|---|---|
| Delay risk | "High delay risk — priority review recommended" | "Will be delayed", "Approved for expediting" |
| Denial risk | "Elevated documentation risk — follow-up recommended" | "Will be denied", "Claim rejected" |
| Fast-track | "Fast-track candidate for administrative processing" | "Approved", "Covered", "Guaranteed processing" |
| Overall | "Operational risk score" or "workflow triage flag" | "Denial score", "Rejection probability" |

Outputs must never use the words "approve," "deny," "reject," "authorize," or "refuse" as determinations. These words are permitted only in descriptions of what the tool does NOT do.

---

## Required Governance Controls for Production Deployment

If this tool were adapted for production use in a real payer environment, the following governance controls would be required before deployment:

1. **Clinical governance review:** Medical director and compliance review of all recommendation rules and output language
2. **Disparate impact assessment:** Statistical analysis of model outputs across protected classes (race, gender, age, disability) to detect and mitigate discriminatory patterns
3. **Model calibration:** Application of Platt scaling or isotonic regression so risk scores can be interpreted as calibrated probabilities
4. **Monitoring and drift detection:** Regular monitoring for feature distribution shift and model performance degradation
5. **Human oversight requirement:** Explicit policy that no coverage determination is made solely on model output — human reviewer in the loop at all times
6. **Provider appeal rights:** Payer must ensure providers retain full appeal rights regardless of model output
7. **Member rights protection:** Model output must never be communicated to members in a way that implies a coverage determination

---

## Regulatory Context

This tool is designed with awareness of the following regulatory framework:

- **CMS-0057-F** (finalized January 17, 2024): Requires Medicare Advantage organizations to report 5 PA metrics annually starting March 31, 2026, and to meet turnaround time requirements (7 days standard, 72 hours expedited)
- **NCQA PA Accreditation Standards**: Require documented, clinically-based PA criteria and qualified reviewer oversight
- **ADA Section 1557**: Prohibits discrimination in health programs — applies to AI tools used in coverage decisions

---

## Portfolio Use Statement

This project was built as a **healthcare analytics portfolio demonstration** targeting healthcare payer operations, utilization management, claims analytics, and health plan consulting roles. It demonstrates:

- Healthcare payer domain knowledge
- Responsible ML model development (leakage exclusion, ethical framing, threshold selection)
- CMS regulatory awareness
- Operational analytics translation (from model score to workflow action)

All data is synthetic. All claims about model performance are bounded to the synthetic dataset. No real payer, provider, or member data was used at any stage.

---

*Prior Authorization Intelligence System | Phase 6 | Portfolio Project*
*Raj Nandani | Healthcare Analytics | nandaniraj1509@gmail.com*
