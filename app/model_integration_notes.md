# Model Integration Notes
## Prior Authorization Intelligence System (PAIS) — Phase 6
**Generated: 2026-06-01 | Synthetic data only | No PHI**

---

## Overview

This document describes how Phase 5 predictive models are integrated into the Phase 6 Streamlit application. It covers model loading, feature preprocessing, prediction pipeline, and the boundary between ML model output and rule-based recommendation logic.

---

## Architecture

```
User Input (Streamlit form)
        ↓
Feature Dict (21 pre-decision features)
        ↓
┌─────────────────────────────────────┐
│     app/streamlit_app.py            │
│  predict() → pandas DataFrame       │
│  → delay_model.pkl.predict_proba()  │   → delay_score (float)
│  → denial_model.pkl.predict_proba() │   → denial_score (float)
└─────────────────────────────────────┘
        ↓
┌─────────────────────────────────────┐
│   app/recommendation_rules.py       │
│   apply_rules(inputs, scores)       │   → RecommendationResult
└─────────────────────────────────────┘
        ↓
Streamlit UI renders risk cards, drivers, actions, disclaimer
```

---

## Saved Model Files

| File | Model | Algorithm | Target | Threshold |
|------|-------|-----------|--------|-----------|
| `app/models/delay_model.pkl` | Delay Risk | GradientBoostingClassifier (200 trees, depth 4, lr 0.05) | `delayed_flag` | 0.193 |
| `app/models/denial_model.pkl` | Denial Risk | LogisticRegression (balanced, C=1.0) | `denied_flag` | 0.052 |
| `app/models/feature_metadata.json` | — | — | Feature lists, thresholds, LR coefficients, dropdown values | — |

Models are trained on the full 25,000-row synthetic dataset (not just the training split) to maximize coverage before deployment. This is the correct approach for a production-style final model artifact.

---

## Feature Preprocessing Inside Pickle

Each pickle file is a `sklearn.pipeline.Pipeline` object containing:

```
Pipeline([
    ('pre', ColumnTransformer([
        ('cat',  OneHotEncoder(handle_unknown='ignore', sparse_output=False), CAT_FEATURES),
        ('num',  StandardScaler(), NUM_FEATURES),
        ('bool', 'passthrough', BOOL_FEATURES)
    ])),
    ('clf', <model>)
])
```

Because the preprocessor is **inside** the pipeline, the app passes raw input values (string categories, float numerics, bool integers) directly to `predict_proba()`. No separate preprocessing step is needed in the app.

**Critical:** `handle_unknown='ignore'` in OneHotEncoder means the app gracefully handles any service category or region value not seen during training — it silently sets unseen categories to zero. This is correct behavior for a deployed app with flexible inputs.

---

## Feature Input Mapping

| App Input (Streamlit widget) | Feature Name | Type | Notes |
|---|---|---|---|
| Request Type | `request_type` | Categorical | Standard / Expedited |
| Submission Channel | `submission_channel` | Categorical | Electronic / Portal / Fax / Phone |
| Service Category | `service_category` | Categorical | 10 categories |
| Procedure Group | `procedure_group` | Categorical | 8 groups |
| Provider Type | `provider_type` | Categorical | 7 types |
| Network Status | `network_status` | Categorical | In-Network / Out-of-Network |
| Provider Risk Segment | `provider_risk_segment` | Categorical | Low / Moderate / High |
| Plan Type | `plan_type` | Categorical | HMO / PPO / SNP / PFFS |
| Age Band | `age_band` | Categorical | 5 bands |
| Member Risk Level | `risk_level` | Categorical | Low / Medium / High / Very High |
| Region | `region` | Categorical | 5 regions |
| Estimated Cost ($) | `estimated_cost` | Numeric | Float |
| Provider Incomplete Rate | `avg_incomplete_submission_rate` | Numeric | Float 0–1 |
| Provider Avg Response Days | `avg_response_time_days` | Numeric | Float |
| Documentation Complete | `documentation_complete` | Boolean → int | 0 or 1 |
| Auto-Eligible | `auto_eligible` | Boolean → int | 0 or 1 |
| Clinical Review Required | `clinical_review_required` | Boolean → int | 0 or 1 |
| Prior Denial History | `previous_denial_history` | Boolean → int | 0 or 1 |

**Fixed values (not surfaced in UI):**
- `submitted_day_of_week`: fixed to "Monday" (low impact feature; SHAP rank ~15)
- `chronic_condition_count`: fixed to 2 (median; not available in simplified intake form)
- `member_tenure_months`: fixed to 24 (median; not available in simplified intake form)

These fixed values were chosen as median/mode values from the training data distribution. Their SHAP importance is low relative to documentation status, auto_eligible, and submission channel.

---

## Leakage Exclusion — App Enforcement

The following fields from the dataset are **not exposed** as app inputs and are not passed to any model:

| Field | Reason excluded from app |
|-------|--------------------------|
| `decision` | IS the outcome for denial model |
| `decision_time_days` | IS the outcome for delay model |
| `denial_reason` | Known only after denial |
| `final_outcome` | Post-appeal |
| `appeal_id`, `appealed`, `appeal_outcome` | Post-decision |
| `action_recommended_initial` | Internal routing — post-intake |
| `reviewer_type`, `pended_flag` | Post-submission process fields |

The app's input form contains only the 17 features available at submission / early review, plus 3 fixed-median features. The app architecture enforces leakage exclusion at the UI level — a user cannot enter a leakage field even if they tried.

---

## Model Loading Strategy

```python
@st.cache_resource
def load_models():
    """Load pre-trained models once at app startup. Never retrained in app."""
    ...
```

`@st.cache_resource` ensures models are loaded once per app session, not re-loaded on every user interaction. This is the correct Streamlit pattern for heavyweight model artifacts.

**Anti-pattern avoided:** Model retraining inside the app. The app calls `predict_proba()` only — it never calls `fit()`.

---

## Output Interpretation

| Model Output | Interpretation | Threshold | Above Threshold |
|---|---|---|---|
| `delay_score` | Risk score (0–1) for SLA breach | 0.193 | High delay risk — priority review |
| `denial_score` | Risk score (0–1) for initial denial | 0.052 | High denial risk — documentation follow-up |

**Important:** These are **uncalibrated risk scores**, not calibrated probabilities. A `delay_score` of 0.25 does not mean "25% probability of delay." It means the request is above the operating threshold and should be routed to the priority queue. See `threshold_selection_notes.md` for full threshold logic.

---

## Recommendation Engine Boundary

The ML models produce a score. The recommendation rules (`recommendation_rules.py`) produce actions. These are two separate layers:

- ML layer: "This request has delay_score = 0.31"
- Rules layer: "delay_score >= 0.193 AND documentation_complete = False → R1: documentation checklist + SLA escalation"

This separation is intentional. It allows the recommendation rules to be updated (e.g., new SLA policy, new provider outreach workflow) without retraining the ML models.

---

*model_integration_notes.md — Phase 6 documentation. Last updated: 2026-06-01*
