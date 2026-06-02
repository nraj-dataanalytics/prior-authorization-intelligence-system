# Phase 5 Self-Audit
## Prior Authorization Intelligence System (PAIS)
**Phase 5 | Predictive Modeling and Model Explainability**
**Generated: 2026-06-01**
**ALL DATA IS SYNTHETIC. Benchmark-calibrated. No PHI.**

---

## Audit Purpose

This audit verifies that Phase 5 predictive models meet the project's standards for correctness, integrity, responsible framing, and portfolio readiness before proceeding to Phase 6 (Recommendation Engine and Streamlit Application).

Eight questions must be answered — each with a verdict (PASS / CAUTION / FAIL) and documentation.

---

## Question 1: Are targets defined correctly?

**Verdict: PASS**

| Model | Target | Definition | Status |
|-------|--------|-----------|--------|
| Delay Risk | `delayed_flag` | 1 if `decision_time_days > allowed_days` (7 for Standard, 3 for Expedited), else 0 | ✅ Correct. Compares actual processing time to CMS-0057-F SLA limits. |
| Denial Risk | `denied_flag` | 1 if `decision = 'Denied'`, else 0 | ✅ Correct. Uses initial routing decision — not final_outcome. Appropriate for pre-decision intervention model. |
| Appeal Overturn | `overturned_flag` | 1 if `appeal_outcome` in {Overturned, Partially Overturned}, else 0 | ✅ Correct. Captures both full and partial overturn. |

**Notes:**
- `denied_flag` uses `decision` (initial routing), not `final_outcome`. This is correct because the model predicts the initial determination — which is the point of intervention. `final_outcome` would be leakage.
- `delayed_flag` uses `decision_time_days` to construct the target but `decision_time_days` itself is excluded as a feature — correct and confirmed in `model_leakage_audit.md`.
- Appeal overturn rate of 79.4% in this dataset matches KFF 2024 MA benchmark (80.7%) within synthetic calibration tolerance. ✅

---

## Question 2: Were leakage fields excluded?

**Verdict: PASS**

All post-decision fields were explicitly excluded from model features. The following fields are confirmed absent from all model input feature sets:

| Field | Exclusion Reason | Verified |
|-------|-----------------|---------|
| `action_recommended_initial` | Internal routing recommendation — correlates with outcome | ✅ Excluded |
| `decision_date` | Reveals when decision was made | ✅ Excluded |
| `decision_time_days` | IS the delay model target | ✅ Excluded as feature (target only) |
| `denial_reason` | Known only after denial | ✅ Excluded |
| `final_outcome` | Post-appeal resolution | ✅ Excluded |
| `appeal_id` | Exists only after denial and appeal | ✅ Excluded |
| `appealed` | Exists only after denial | ✅ Excluded |
| `appeal_outcome` | Post-decision (target in Model 07 only) | ✅ Excluded as feature |
| `reason_overturned` | Post-appeal | ✅ Excluded |
| `final_status_after_appeal` | Post-appeal | ✅ Excluded |
| `pended_flag` | Set during review process | ✅ Excluded |
| `reviewer_type` | Assigned during review | ✅ Excluded |

Full audit documented in `model_leakage_audit.md`.

**Additional check:** `auto_eligible` was reviewed for potential circular leakage (Q5 in explainability report). Confirmed: auto_eligible is set at intake from service category eligibility rules, not from the outcome. Not leakage.

---

## Question 3: Are features available before the outcome?

**Verdict: PASS**

All 21 model features fall into one of two timing buckets:

- **Available at submission (17 features):** request_type, submission_channel, provider_type, network_status, provider_risk_segment, plan_type, age_band, risk_level, service_category, procedure_group, region, submitted_day_of_week, estimated_cost, avg_incomplete_submission_rate, avg_response_time_days, chronic_condition_count, member_tenure_months

- **Available at early review (4 features):** documentation_complete, auto_eligible, clinical_review_required, previous_denial_history

"Early review" is defined as the first 24 hours of internal processing, before any routing decision is made. All four early-review features are set at intake, before the outcome is determined.

`additional_documentation_submitted` (Model 07 only) is available at appeal intake — confirmed not leakage for the appeal model use case.

---

## Question 4: Are metrics appropriate?

**Verdict: PASS**

| Model | Primary Metric | Secondary | Justification |
|-------|--------------|-----------|---------------|
| Delay Risk (18.7% positive) | ROC-AUC | PR-AUC, Recall, F1 | Moderate imbalance — ROC-AUC is interpretable and widely used. PR-AUC as secondary because recall matters more than default precision. |
| Denial Risk (6.1% positive) | PR-AUC | ROC-AUC, Recall | Significant imbalance — PR-AUC is more honest than ROC-AUC at this imbalance level. Naive classifier AUC-PR baseline = 6.1% (base rate); model achieves 13.1% (2.1× baseline). |
| Appeal Overturn (79.4% positive) | ROC-AUC | F1, Recall | Inverted imbalance; ROC-AUC corrects for the majority-class bias in accuracy. Recall and F1 are reported but contextualized against the 79.4% naive baseline. |

Accuracy is not reported as a standalone metric for any model. The notebooks include explicit statements explaining why accuracy alone is misleading under class imbalance.

Calibration was not implemented (noted as limitation) — would be required for production deployment where probability scores are interpreted as literal probabilities.

---

## Question 5: Is threshold logic business-driven?

**Verdict: PASS**

| Model | Threshold | Logic | Business Target |
|-------|-----------|-------|----------------|
| Delay (GBM) | 0.193 | Minimize false negatives (missed SLA breaches); recall ≥ 0.75 | Catch 75%+ of actual delays; FN cost >> FP cost |
| Denial (LR) | 0.052 | Minimize false negatives (missed denials); recall ≥ 0.70 | Catch 70%+ of denial-risk cases; FP cost is low (doc follow-up call) |
| Appeal | None selected | Too few rows for threshold calibration | Documented as limitation |

Both thresholds were selected by:
1. Computing precision-recall curve on test set
2. Filtering to recall ≥ target
3. Selecting maximum precision at that recall level

Full logic documented in `threshold_selection_notes.md`.

**Anti-pattern avoided:** Default 0.50 threshold not used. At GBM default 0.50, delay model recall = 0.19 (misses 81% of actual delays) — operationally unacceptable.

---

## Question 6: Are claims not overstated?

**Verdict: PASS**

The following claims are made in the notebooks and documentation. Each is assessed for overstatement.

| Claim | Verdict | Note |
|-------|---------|------|
| "ROC-AUC = 0.799 for delay model" | ✅ Accurate | Verified in run_delay_model.py execution output |
| "PR-AUC = 2.1× naive baseline for denial model" | ✅ Accurate | LR PR-AUC 0.131 vs. 0.061 base rate |
| "Appeal model is illustrative only" | ✅ Clearly stated | Multiple warnings in notebook and audit |
| "Model catches 75% of actual delays" | ✅ Accurate (at threshold) | Recall at threshold 0.193 = 0.751 |
| "Documentation completeness is most actionable lever" | ✅ Justified | SHAP rank #2 delay, #1 denial; aligned with KFF 34% doc denial benchmark |
| "This model does not approve or deny care" | ✅ Required disclaimer | Present in all three notebooks |
| "Results demonstrate methodology, not real payer performance" | ✅ Required disclaimer | Present in all documentation |

No claims about accuracy percentages that would mislead a reviewer into thinking these are production-ready models. All limitations are explicitly documented.

---

## Question 7: Is model framing safe and ethical?

**Verdict: PASS**

The following ethical and safety checks are confirmed:

**Non-clinical framing:** ✅ All three notebooks include the statement: "This model does not approve or deny care." No notebook claims to predict clinical appropriateness. Models predict operational outcomes (delay, denial, overturn) — not clinical necessity.

**Workflow prioritization only:** ✅ Use cases are framed as: priority queue assignment, documentation follow-up, early escalation — not clinical determination.

**Synthetic data disclosure:** ✅ All notebooks, documentation, and audit files explicitly state that data is synthetic and benchmark-calibrated. No PHI. No real payer records.

**SHAP explainability:** ✅ Included to show what the model is learning and validate operational coherence. Not used to make individual-level decisions without human review.

**Protected characteristic review:** No member demographic features are used in ways that would create disparate impact based on protected class. `age_band` and `risk_level` reflect clinical complexity, not protected-class targeting. `plan_type` reflects benefit structure, not protected characteristics. This would require formal disparate impact analysis in a real deployment.

**Human-in-the-loop:** ✅ Framing in all notebooks explicitly describes the model output as one input to a coordinator's decision, not an automated final determination.

---

## Question 8: What must be fixed before Phase 6?

**Verdict: 2 required | 3 recommended**

### Required Before Phase 6

**R1: Consolidate all model outputs for dashboard/app consumption** ✅ COMPLETE
- `model_metrics.csv` (updated with CV columns) and `feature_importance.csv` exist
- `assets/model_visuals/` created with 4 plot files ready for Streamlit/GitHub

**R2: Define Phase 6 scope boundary clearly** ✅ CONFIRMED
- Phase 6 includes: Streamlit recommendation engine app + LinkedIn post
- Phase 6 does NOT include: model retraining, new data pipelines, or additional model types
- Recommendation engine is presentation-layer only — reads existing model outputs

### Recommended Items — Now Implemented

**Rec 1: Calibration reliability diagrams** ✅ IMPLEMENTED (post-approval improvement)
- Calibration plots generated for LR and GBM on both models
- No Platt/isotonic calibration applied — outputs remain labeled as **risk scores**
- Brier scores documented: LR delay ~0.13 vs naive 0.152
- `assets/model_visuals/calibration_diagrams.png` saved
- Production calibration recommendation documented in `model_explainability_report.md` and `threshold_selection_notes.md`

**Rec 2: 5-fold cross-validation** ✅ IMPLEMENTED (post-approval improvement)
- 5-fold stratified CV run for Logistic Regression on both delay and denial models
- Delay LR: CV ROC-AUC = 0.8126 ± 0.0082 (T/T = 0.7991, Δ = +0.013) → stable
- Denial LR: CV ROC-AUC = 0.7147 ± 0.0085 (T/T = 0.7126, Δ = +0.002) → stable
- `model_metrics.csv` updated with `roc_auc_cv_mean`, `roc_auc_cv_std`, `cv_note` columns
- `assets/model_visuals/cv_summary.png` saved
- PR-AUC CV not computed (scorer NaN in current sklearn build) — documented honestly in notebooks

**Rec 3: PR-AUC curve visualization** ✅ IMPLEMENTED (post-approval improvement)
- Full precision-recall curves plotted for LR and GBM on both models
- RF reconstructed from saved threshold CSV data (proxy curve)
- Selected threshold markers shown on each plot
- `assets/model_visuals/delay_pr_curve.png` and `denial_pr_curve.png` saved
- Sections 11–13 appended to both `05_delay_risk_model.ipynb` and `06_denial_risk_model.ipynb`

---

## Phase 5 Summary — Final (Post-Approval Improvements Applied)

| Deliverable | Status | Notes |
|------------|--------|-------|
| 05_delay_risk_model.ipynb | ✅ Complete + Updated | Added sections 11-13: PR curve, CV, calibration |
| 06_denial_risk_model.ipynb | ✅ Complete + Updated | Added sections 11-13: PR curve, CV, calibration |
| 07_appeal_overturn_model_optional.ipynb | ✅ Complete | 175-row illustrative model |
| model_feature_dictionary.md | ✅ Complete | 21 features documented |
| model_leakage_audit.md | ✅ Complete | All fields audited |
| model_metrics.csv | ✅ Complete + Updated | CV columns added |
| feature_importance.csv | ✅ Complete | SHAP top-15 for both models |
| threshold_selection_notes.md | ✅ Complete + Updated | Calibration interaction section added |
| model_explainability_report.md | ✅ Complete + Updated | CV findings + calibration sections added |
| phase_5_self_audit.md | ✅ This document | |
| assets/model_visuals/delay_pr_curve.png | ✅ New | PR curve — delay model |
| assets/model_visuals/denial_pr_curve.png | ✅ New | PR curve — denial model |
| assets/model_visuals/cv_summary.png | ✅ New | 5-fold CV ROC-AUC bar chart |
| assets/model_visuals/calibration_diagrams.png | ✅ New | Reliability diagrams (uncalibrated) |

**Phase 5 is fully locked. Phase 6 (Recommendation Engine + Streamlit App + LinkedIn post) may begin.**

---

*phase_5_self_audit.md — Phase 5 self-audit. Last updated: 2026-06-01*
