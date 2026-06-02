# Limitations and Ethics
## Prior Authorization Intelligence System (PAIS)
**Version 1.0 | Generated: 2026-06-01 | Synthetic data only | No PHI**

---

## 1. Data Limitations

**This project uses entirely synthetic data.**

All 25,000 rows of prior authorization request data were generated programmatically
using a Python script (`data/synthetic_data_generator.py`). The data was designed
to be benchmark-calibrated against publicly available sources (KFF, HHS OIG, CMS),
but it is not real payer data, not real member data, and not real provider data.

Specific limitations:

- **Positive rates are approximate.** The delayed_flag positive rate (~18.7%) and
  denied_flag positive rate (~6.1%) were calibrated to published benchmarks but
  will differ from any specific payer's actual experience.

- **Feature correlations are simplified.** Real payer workflows contain complex,
  institution-specific correlations between provider type, service category, plan
  type, and decision outcomes that cannot be captured in a general synthetic dataset.

- **No real provider behavior.** Provider incomplete submission rates, response
  times, and risk segments are randomly generated within benchmark-informed ranges.
  They do not represent any actual provider's behavior.

- **No regional variation beyond labels.** Regional designations (Northeast, South,
  Midwest, West, Southwest) are present as features but are not calibrated to
  actual regional denial rate differences.

- **No temporal dynamics.** The dataset does not simulate year-over-year trends,
  seasonal patterns, or policy changes over time.

---

## 2. Model Limitations

**Model performance was measured on the same synthetic dataset used for training.**

Real-world performance will differ — potentially significantly — because:

- The synthetic data was generated from simplified rules, so models trained on it
  may not generalize to the complexity of real payer workflows.
- The GBM delay model achieved ROC-AUC 0.799 and the LR denial model achieved
  ROC-AUC 0.713 on a held-out test split of the synthetic data. These metrics do
  not represent expected performance on real payer records.
- Thresholds (delay: 0.193, denial: 0.052) were selected to achieve recall targets
  on the synthetic test split. Appropriate thresholds for real-world deployment
  would need to be re-derived from real data.

**Models are not calibrated.** Outputs are risk scores, not calibrated probabilities.
A delay score of 0.25 does not mean "25% probability of delay."

---

## 3. Ethical Constraints

**This tool does not and must not approve or deny care.**

The PAIS Streamlit application produces workflow routing recommendations only.
No output from this tool constitutes a coverage determination. Key ethical constraints:

**Non-discrimination:** The models were not evaluated for disparate impact across
protected classes (race, ethnicity, age, disability, sex) because the synthetic
dataset does not contain demographic variables aligned to protected class definitions.
Any production deployment would require a full disparate impact assessment before
use, per ADA Section 1557 requirements.

**Human oversight required:** No model output should be used as the sole basis
for any coverage decision. A qualified human reviewer must be in the loop for
all determinations. This is not optional — it is a regulatory and ethical requirement.

**Provider and member rights:** Model output does not affect a provider's right
to appeal a prior authorization denial. Member rights to appeals and grievances
are unaffected by any workflow prioritization tool.

**Transparency:** This project's methodology, assumptions, data generation approach,
and model limitations are fully documented and open-sourced precisely so that
reviewers, employers, and the public can evaluate its claims independently.

---

## 4. Responsible Deployment Requirements

If any component of this project were adapted for production use in a real payer
environment, the following would be required before deployment:

1. Clinical governance review (medical director + compliance officer)
2. Real data retraining with proper train/validation/test splits
3. Disparate impact assessment across protected classes
4. Model calibration (Platt scaling or isotonic regression)
5. Monitoring and drift detection pipeline
6. Explicit human-in-the-loop policy for all determinations
7. Legal review of output language and member communication standards
8. Compliance certification with CMS-0057-F, NCQA, and applicable state law

---

## 5. Portfolio Use Statement

This project was built exclusively as a portfolio demonstration targeting healthcare
payer analytics, utilization management, and health plan consulting roles. It is
not a deployed production system. It has never processed real patient data.
It is not affiliated with any health plan, insurer, or provider organization.

All performance claims are bounded to the synthetic dataset. No claim is made
about real-world payer performance, real denial rates, or real operational outcomes.

---

*Prior Authorization Intelligence System | limitations_and_ethics.md*
*Raj Nandani | Healthcare Analytics | nandaniraj1509@gmail.com*
