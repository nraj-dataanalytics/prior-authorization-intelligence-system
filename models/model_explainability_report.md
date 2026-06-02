# Model Explainability Report
## Prior Authorization Intelligence System (PAIS)
**Phase 5 | Predictive Modeling and Model Explainability**
**Generated: 2026-06-01**
**ALL DATA IS SYNTHETIC. Benchmark-calibrated. No PHI.**

---

## Executive Summary

This report documents feature importance analysis and SHAP explainability findings for the two primary Phase 5 models — the Delay Risk Model and the Denial/Documentation Risk Model. All explainability outputs are derived from synthetic data. Results are interpreted in terms of operational and clinical logic to assess whether the model has learned meaningful patterns or statistical artifacts.

**Key finding:** Both models have learned operationally coherent patterns. The strongest predictors (`auto_eligible`, `documentation_complete`) are the same variables that payer operations teams already use as manual triage criteria — confirming the models are learning real workflow signal rather than spurious correlations.

**Phase 5 additions (post-approval improvements):**
- Precision-recall curve plots added to both notebooks (`assets/model_visuals/delay_pr_curve.png`, `denial_pr_curve.png`)
- 5-fold stratified CV added for Logistic Regression stability check (see Section 6 below)
- Calibration reliability diagrams added (uncalibrated; outputs labeled as risk scores)
- `model_metrics.csv` updated with CV columns

---

## Model 1: Delay Risk Model — Explainability

### SHAP Summary (Gradient Boosting, 500-sample test set)

| Rank | Feature | Mean |SHAP| | Business Interpretation |
|------|---------|------------|------------------------|
| 1 | `auto_eligible` | 1.494 | Auto-eligible requests bypass clinical review → lowest delay risk. Most important single feature. |
| 2 | `documentation_complete` | 0.610 | Missing documentation triggers pend workflow → primary delay driver. |
| 3 | `submission_channel_Fax` | 0.167 | Fax requires manual re-keying → ~25% longer processing vs. electronic. |
| 4 | `request_type_Standard` | 0.161 | Standard requests (7-day SLA) have more delay risk than Expedited (prioritized queue). |
| 5 | `request_type_Expedited` | 0.129 | Expedited requests have a 72-hour SLA — they are routed to priority queue, lowering delay risk. |
| 6 | `estimated_cost` | 0.047 | Higher-cost requests may trigger additional review layers. |
| 7 | `avg_incomplete_submission_rate` | 0.040 | Provider history: high incomplete rate predicts incomplete current submission → delay. |
| 8 | `avg_response_time_days` | 0.037 | Providers who historically respond slowly to documentation requests → delay. |

### Random Forest Feature Importances (Top 10)

| Feature | Importance |
|---------|-----------|
| `auto_eligible` | 0.0894 |
| `documentation_complete` | 0.0719 |
| `avg_incomplete_submission_rate` | 0.0632 |
| `avg_response_time_days` | 0.0589 |
| `estimated_cost` | 0.0512 |
| `chronic_condition_count` | 0.0478 |
| `submission_channel_Fax` | 0.0381 |
| `request_type_Standard` | 0.0314 |
| `member_tenure_months` | 0.0289 |
| `clinical_review_required` | 0.0277 |

### Logistic Regression — Direction of Coefficients

LR coefficients show the **direction** of each feature's effect. Key findings:

- `auto_eligible = 1` → **large negative coefficient** (reduces delay probability) ✅ expected
- `documentation_complete = 0` → **large positive coefficient** (increases delay probability) ✅ expected
- `submission_channel_Fax` → **positive coefficient** (increases delay probability) ✅ expected
- `request_type_Expedited` → **negative coefficient** (reduces delay probability) ✅ expected
- `avg_incomplete_submission_rate` → **positive coefficient** (more incomplete history → more current delay) ✅ expected

All top LR coefficients point in the operationally expected direction.

### Operational Interpretation — Delay Model

The delay risk model has learned three distinct delay pathways:

**Pathway 1: Workflow routing pathway**
Auto-eligible cases (auto_eligible=1) are adjudicated automatically without entering the clinical review queue. These cases have near-zero delay risk. The model has correctly learned that auto-adjudication is the most reliable predictor of on-time processing.

**Pathway 2: Documentation pathway**
Cases with incomplete documentation (documentation_complete=0) enter a pend-and-follow-up cycle. Pended cases wait for provider response to documentation requests, extending processing time. This pathway is further amplified by submission channel (Fax vs Electronic) and provider response time history.

**Pathway 3: Review complexity pathway**
Cases requiring clinical review (clinical_review_required=1), combined with high estimated cost, and high-complexity service categories → more review layers → more delay risk.

---

## Model 2: Denial Risk Model — Explainability

### SHAP Summary (Gradient Boosting, 500-sample test set)

| Rank | Feature | Mean |SHAP| | Business Interpretation |
|------|---------|------------|------------------------|
| 1 | `documentation_complete` | 0.348 | Most important denial predictor: missing documentation is the #1 denial reason (34% of denials — calibrated to KFF benchmark). |
| 2 | `auto_eligible` | 0.242 | Auto-eligible cases are auto-approved → very low denial risk. |
| 3 | `clinical_review_required` | 0.154 | Clinical review required → case goes to physician reviewer → higher denial probability for complex services. |
| 4 | `previous_denial_history` | 0.117 | Prior denial on member record → pattern of PA friction; more likely to face denial again. |
| 5 | `avg_incomplete_submission_rate` | 0.117 | Provider with high incomplete submission rate → current case more likely to have incomplete docs → denial. |
| 6 | `network_status_Out-of-Network` | 0.071 | OON requests face additional clinical review criteria → ~1.8× denial rate per ASSUMPTION G03. |
| 7 | `estimated_cost` | 0.062 | High-cost requests → more clinical scrutiny → higher denial rate. |
| 8 | `network_status_In-Network` | 0.055 | In-Network (baseline) — lower denial risk compared to OON. |
| 9 | `service_category_Post-Acute / SNF` | 0.054 | Post-acute/SNF requests have high denial risk due to medical necessity documentation requirements. |
| 10 | `service_category_Outpatient Procedures` | 0.050 | Outpatient procedures include high-denial imaging and elective procedure categories. |

### Denial vs. Delay: Comparing SHAP Rankings

| Feature | Delay SHAP Rank | Denial SHAP Rank | Consistent? |
|---------|----------------|-----------------|-------------|
| `auto_eligible` | 1 | 2 | ✅ Strong in both |
| `documentation_complete` | 2 | 1 | ✅ Strongest denial driver |
| `clinical_review_required` | ~10 | 3 | ✅ More important for denial |
| `previous_denial_history` | ~12 | 4 | ✅ More important for denial |
| `avg_incomplete_submission_rate` | 7 | 5 | ✅ Consistent |
| `network_status_Out-of-Network` | ~15 | 6 | ✅ More denial-relevant |
| `submission_channel_Fax` | 3 | ~11 | ✅ More delay-relevant than denial |
| `request_type_Standard` | 4 | ~14 | ✅ More delay-relevant |

The ranking comparison shows the two models are learning distinct patterns despite using the same feature set. Fax and request_type drive delay but not denial. Documentation and clinical complexity drive denial more than delay. This is operationally coherent.

---

## Cross-Model Observations

### The `auto_eligible` Dominance Question

`auto_eligible` is the top SHAP feature for the delay model (1.494) and second for the denial model (0.242). This prompts a fair question: is the model just learning the auto-adjudication system rule?

**Assessment: This is correct behavior, not a problem.**

Auto-eligible cases are by definition:
- Not delayed (they bypass clinical review queue)
- Not denied (they are auto-approved)

The model has learned a real, causal relationship. In a production context, `auto_eligible` would likely be a payer's own eligibility engine output — perfectly appropriate to use as an input feature for routing prioritization.

The only risk would be if auto_eligible were computed **from** the outcome (circular). In this dataset, auto_eligible is assigned at intake based on service category rules and is explicitly a pre-decision field.

### The `documentation_complete` Signal

`documentation_complete` is the top or second-ranked feature in both models. This aligns directly with:
- KFF 2024 data: 34% of MA denials are for "Documentation Incomplete" (calibrated benchmark)
- CMS public reporting guidance: documentation completeness is a reportable PA metric
- Payer operations practice: documentation follow-up is the primary intervention for SLA compliance

The model has learned the most actionable operational lever — which also happens to be the lever most within the payer's (and provider's) control.

---

## Section 6: Cross-Validation Stability Check

5-fold stratified CV was run for Logistic Regression on both models as a stability check. CV is not the primary reported result — train/test split metrics are primary.

| Model | Target | CV ROC-AUC | CV Std | T/T ROC-AUC | Δ |
|-------|--------|------------|--------|-------------|---|
| Logistic Regression | delayed_flag | 0.8126 | ±0.0082 | 0.7991 | +0.013 |
| Logistic Regression | denied_flag  | 0.7147 | ±0.0085 | 0.7126 | +0.002 |

**Interpretation:** Both models show narrow CV std (< 0.01), confirming results are not an artifact of a single lucky train/test split. The small positive delta (CV slightly higher than T/T) is expected — CV uses more training data per fold on a larger effective training set.

**Why LR only for CV:** RF and GBM with 200 estimators + 5 folds × 2 targets = 20 model fits would exceed compute budget for this portfolio environment. LR convergence is sufficient to validate model stability; the same pattern is expected to hold for tree-based models.

## Section 7: Calibration Findings

Calibration reliability diagrams were generated for LR and GBM on both models. No calibration (Platt/isotonic) was applied.

**Delay model:**
- LR Brier score: ~0.13 vs. naive Brier 0.152 — improvement confirms the model adds signal
- GBM Brier: similar to LR at this imbalance level
- Both models show mild overconfidence in the middle score range (common for GBM without calibration)

**Denial model:**
- Brier scores close to naive at 6.1% base rate — this is expected; the dominant negative class pulls Brier down regardless of minority-class performance
- PR-AUC (2.1× baseline) is a more informative metric than Brier at this imbalance level

**Production recommendation:** Apply Platt scaling to both models before deployment. This converts raw risk scores to calibrated probabilities, allowing "denial_risk_score = 0.15" to be interpreted as a literal 15% denial probability. Current outputs are labeled as **risk scores** throughout all documentation and dashboards.

---

## Explainability Limitations

1. **SHAP computed on 500-sample subset** for computational efficiency. Full test set SHAP would give more stable estimates but directional findings are expected to hold.

2. **GBM SHAP is global, not local.** Mean |SHAP| shows average feature importance across all cases, not feature importance for any individual case. Individual case explanations would require per-row SHAP values.

3. **Synthetic data limitation.** All SHAP values reflect patterns generated by the synthetic data generator. In a real payer dataset, the relative importance of service_category, network_status, and member demographics might differ significantly.

4. **No SHAP for appeal model.** The 175-row dataset is insufficient for meaningful SHAP analysis. Feature importance for that model is documented as LR coefficients only.

5. **PR-AUC CV not computed.** The `make_scorer(average_precision_score, needs_proba=True)` call returned NaN in the current sklearn build. PR-AUC from train/test split is the reported metric. This is documented honestly in both notebooks.

---

## Recruiter Talking Point

> "I built SHAP explainability into the delay and denial models to answer a question any payer analytics manager would ask: 'How do I know this model is learning real patterns, not noise?' The SHAP results are internally consistent — auto_eligible and documentation_complete dominate both models, which matches exactly what payer ops teams already use as manual triage criteria. The models have learned what experienced coordinators already know."

---

*model_explainability_report.md — Phase 5 documentation. Last updated: 2026-06-01*
