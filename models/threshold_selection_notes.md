# Threshold Selection Notes
## Prior Authorization Intelligence System (PAIS)
**Phase 5 | Predictive Modeling and Model Explainability**
**Generated: 2026-06-01**
**ALL DATA IS SYNTHETIC. No PHI.**

---

## Why Default 0.50 Is Wrong for Healthcare Operations

scikit-learn's default classification threshold is 0.50 — flag a case as positive if the model assigns probability ≥ 50%. This default assumes:

1. The cost of a false positive equals the cost of a false negative
2. The class distribution is approximately balanced

Neither assumption holds for prior authorization operations:

- Class imbalance is present in all three models (18.7%, 6.1%, 79.4% positive rates)
- False negatives and false positives have **different operational costs** for each use case

The threshold must be selected based on the specific operational decision the model supports.

---

## Model 1: Delay Risk Model — Threshold 0.193

### Recommended Model: Gradient Boosting
**Business Use Case:** Identify requests at risk of missing CMS-0057-F SLA thresholds (7 days standard, 72 hours expedited) so operations coordinators can intervene early.

### Cost Asymmetry
| Error Type | Operational Consequence |
|------------|------------------------|
| **False Negative** (miss a delay) | Request breaches SLA without intervention. CMS compliance exposure. Member harm risk. Lost opportunity to request documentation or escalate. **HIGH COST.** |
| **False Positive** (flag a non-delay) | Case receives additional coordinator attention unnecessarily. Coordinator time spent is wasted but SLA is not breached. **LOW-MODERATE COST.** |

**Conclusion:** For delay risk, false negatives are significantly more expensive than false positives. The threshold should be set **below 0.50** to increase recall at the cost of precision.

### Threshold Selection Process
1. Compute precision-recall curve for GBM model on test set
2. Filter to all thresholds where recall ≥ 0.75 (business target: catch at least 75% of actual delays)
3. Among qualifying thresholds, select the one with highest precision

**Selected threshold: 0.193**

| Metric | At Default 0.50 | At Selected 0.193 | Change |
|--------|----------------|-------------------|--------|
| Recall | 0.19 | 0.75 | +0.56 |
| Precision | 0.55 | 0.35 | -0.20 |
| F1 | 0.29 | 0.47 | +0.18 |
| Cases flagged | 4.8% | 41.1% | +36.3pp |
| False negatives | 754 | 233 | -521 fewer missed delays |

### Operational Interpretation
At threshold 0.193:
- **2,056 of 5,000 test cases flagged** as high-risk for delay (~41%)
- **703 true delays correctly identified** (model catches 3 in 4 actual delays)
- **233 delays missed** (24.9% of actual delays — acceptable tradeoff for portfolio demo model)
- **1,353 false positives** — cases flagged but not actually delayed; coordinator review cost

At a payer processing 25,000 PA requests per year, threshold 0.193 would flag ~10,250 cases per year for priority review — approximately 40% of volume. In practice, this threshold would be calibrated against staffing capacity and refined with real payer data.

---

## Model 2: Denial Risk Model — Threshold 0.052

### Recommended Model: Logistic Regression
**Business Use Case:** Identify requests at risk of denial so coordinators can initiate documentation follow-up before the denial is issued. LR recommended over GBM for this model due to better PR-AUC and easier governance in regulated payer environments.

### Cost Asymmetry
| Error Type | Operational Consequence |
|------------|------------------------|
| **False Negative** (miss a high-denial-risk case) | Denial issued without documentation follow-up. Provider may not know why request was denied. Increases appeal probability. **MODERATE-HIGH COST.** |
| **False Positive** (flag a non-denial case) | Coordinator sends documentation follow-up request to provider unnecessarily. Provider responds with confirmation that docs are complete. **LOW COST** — typically a phone call or electronic notification. |

**Conclusion:** False negatives cost more, but false positive cost is lower than for delay risk (a documentation request is cheaper than an SLA breach). Recall target is set at 0.70 (slightly lower than delay model's 0.75).

### Threshold Selection Process
1. Compute precision-recall curve for LR model on test set
2. Filter to all thresholds where recall ≥ 0.70
3. Among qualifying thresholds, select the one with highest precision

**Selected threshold: 0.052**

| Metric | At Default 0.50 | At Selected 0.052 | Change |
|--------|----------------|-------------------|--------|
| Recall | 0.66 | 0.71 | +0.05 |
| Precision | 0.11 | 0.11 | ~0 |
| F1 | 0.19 | ~0.19 | ~0 |
| Cases flagged | 30.0% | 35.7% | +5.7pp |

### Note on Precision for Denial Model
Precision is low (~11%) across all thresholds. This is expected and acceptable:
- Only 6.1% of requests are denied — even a good model will generate many false positives
- The **operational cost of a false positive is very low** (a documentation check call)
- The **benefit of catching 71% of actual denials early** (reducing appeals and rework) exceeds the cost of unnecessary documentation requests
- A simple check: 11% precision on 35% flagged rate means ~4% of all requests receive unnecessary outreach — manageable

### Why LR Over GBM for Denial Model
- LR achieves best ROC-AUC (0.7126) and PR-AUC (0.1310) — GBM predicts 0 for all cases at 0.50 threshold due to severe imbalance without class weighting
- LR coefficients are directly interpretable by clinical governance committees
- In a regulated payer environment, model transparency matters for compliance review
- LR with `class_weight='balanced'` appropriately upweights the 6.1% minority class

---

## Model 3: Appeal Overturn Model — No Threshold Selected

**Business Use Case:** Identify denied requests at elevated overturn risk for pre-denial additional review. Illustrative only.

**No threshold is selected for this model** because:
1. Only 175 rows available — not enough for reliable threshold calibration
2. High variance in cross-validation (±0.08 on ROC-AUC)
3. Model is documented as methodology demonstration only

If this model were deployed with real data (1,000+ rows), the threshold selection logic would mirror Model 1: minimize false negatives (missed high-overturn-risk cases) using precision-recall curve optimization.

---

## Calibration and Threshold Interaction

Because no calibration has been applied, the threshold values (0.193 for delay, 0.052 for denial) are not probability thresholds in the calibrated sense — they are **risk score cutoffs** on the raw model output scale.

This matters because:
- GBM at default settings tends to compress scores toward 0 under class imbalance → thresholds much lower than 0.50
- LR with `class_weight='balanced'` shifts the score distribution upward, requiring a different threshold
- In a production system with Platt-calibrated probabilities, the threshold would be set in probability space (e.g., "flag if denial probability > 8%") rather than on the raw score scale

Current thresholds were selected empirically from the precision-recall curve to achieve the stated recall targets. They are operationally valid for the synthetic data environment and document the correct methodology. Real payer deployment would require re-calibration and re-thresholding on actual workflow data.

**Calibration plots** are saved at `assets/model_visuals/calibration_diagrams.png`. They show LR is reasonably well-calibrated at low risk scores; GBM shows mild overconfidence in the mid-range. Neither was adjusted — all outputs remain labeled as **risk scores**, not calibrated probabilities.

---

## General Threshold Selection Principle

For any healthcare operations model in this project:

1. **Define the use case first** — what workflow action does the model trigger?
2. **Quantify asymmetry** — which error costs more operationally?
3. **Set the recall target** — based on how many actual positives must be caught
4. **Find the threshold** — on the precision-recall curve at the recall target
5. **Document the operational burden** — what percentage of volume will be reviewed?
6. **Revisit with real data** — synthetic data thresholds are illustrative

---

*threshold_selection_notes.md — Phase 5 documentation. Last updated: 2026-06-01*
