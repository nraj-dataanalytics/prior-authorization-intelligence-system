# Model Feature Dictionary
## Prior Authorization Intelligence System (PAIS)
**Phase 5 | Predictive Modeling and Model Explainability**
**Generated: 2026-06-01**
**ALL DATA IS SYNTHETIC. Benchmark-calibrated. No PHI.**

---

## Overview

This dictionary documents the 21 features used across the Phase 5 predictive models. Every feature listed here is:

1. **Available before or at the time of initial review** — no post-decision information is included
2. **Excluded from leakage** — see `model_leakage_audit.md` for explicit exclusion documentation
3. **Sourced from synthetic payer workflow data** calibrated to CMS and KFF public benchmarks

The same 21-feature set is used for the **Delay Risk Model** (05) and the **Denial Risk Model** (06). The **Appeal Overturn Model** (07) uses 18 of these features (excluding `procedure_group`, `member_tenure_months`, `submitted_day_of_week`) and adds one appeal-specific feature (`additional_documentation_submitted`).

---

## Feature Set

### Categorical Features (12)

| # | Feature | Source Table | Description | Business Relevance |
|---|---------|-------------|-------------|-------------------|
| C01 | `request_type` | fact_prior_authorization | Standard or Expedited | CMS-0057-F distinguishes by type (7-day vs 72-hr SLA). Expedited requests are prioritized in clinical review queues. |
| C02 | `submission_channel` | fact_prior_authorization | Electronic / Fax / Portal / Phone | Fax submissions add ~25% longer processing time per submission channel analysis. Delays correlate with channel. |
| C03 | `provider_type` | dim_provider | Physician / Specialist / Hospital / SNF / Therapy / Other | Different provider types have different PA documentation practices and denial patterns. |
| C04 | `network_status` | dim_provider | In-Network / Out-of-Network | OON requests have ~1.8× higher denial rate per ASSUMPTION G03. Network status is known at submission. |
| C05 | `provider_risk_segment` | dim_provider | Low-Risk / Moderate-Risk / High-Risk | Derived from provider's historical documentation and denial patterns. Available in provider master. |
| C06 | `plan_type` | dim_member | HMO / PPO / SNP / PFFS | Different plan types have different PA requirements and approval patterns. |
| C07 | `age_band` | dim_member | 18-44 / 45-64 / 65-74 / 75-84 / 85+ | Age correlates with service complexity and chronic condition burden. |
| C08 | `risk_level` | dim_member | Low / Medium / High / Very High | Member risk stratification based on chronic conditions and claims history. |
| C09 | `service_category` | dim_service | Imaging / Post-Acute / Outpatient Procedures / Surgical / etc. | Service category is the strongest single predictor of denial risk (after documentation status). |
| C10 | `procedure_group` | dim_service | More granular grouping within service category | Adds specificity within high-denial categories (e.g., distinguishes MRI from CT within Imaging). |
| C11 | `region` | dim_provider | Northeast / Southeast / Midwest / Southwest / West | Regional variation in provider documentation quality and processing capacity. |
| C12 | `submitted_day_of_week` | fact_prior_authorization | Monday–Friday / Weekend | Cases submitted Friday or over weekend may face processing delays due to reviewer availability. |

### Numeric Features (5)

| # | Feature | Source Table | Description | Business Relevance |
|---|---------|-------------|-------------|-------------------|
| N01 | `estimated_cost` | fact_prior_authorization | Estimated cost of requested service ($) | Higher-cost requests may trigger additional clinical review, increasing delay and denial risk. |
| N02 | `avg_incomplete_submission_rate` | dim_provider | Provider's historical incomplete submission rate (0–1) | Providers with high incomplete submission rates generate more documentation-related delays and denials. |
| N03 | `avg_response_time_days` | dim_provider | Provider's historical average response time to documentation requests (days) | Slow-responding providers increase delay risk when documentation follow-up is required. |
| N04 | `chronic_condition_count` | dim_member | Number of documented chronic conditions | Higher complexity members have more clinically complex PA requests, correlating with clinical review and denial risk. |
| N05 | `member_tenure_months` | dim_member | Months member has been enrolled in current plan | Longer-tenured members may have established prior authorization histories. Newer members may have more initial friction. |

### Boolean Features (4)

| # | Feature | Source Table | Description | Business Relevance |
|---|---------|-------------|-------------|-------------------|
| B01 | `documentation_complete` | fact_prior_authorization | Whether required documentation was submitted with initial request (True/False) | Single strongest predictor of both delay and denial risk. Incomplete documentation → pend → delay or denial. |
| B02 | `previous_denial_history` | fact_prior_authorization | Whether member has a prior PA denial history (True/False) | Prior denials signal recurring friction patterns. Members with denial history more likely to face documentation challenges. |
| B03 | `auto_eligible` | fact_prior_authorization | Whether request is eligible for automated adjudication (True/False) | Auto-eligible requests bypass clinical review queue → lowest delay and denial risk. Strongest SHAP feature in delay model. |
| B04 | `clinical_review_required` | fact_prior_authorization | Whether clinical review by a licensed reviewer is required (True/False) | Clinical review adds 1–3 days to processing time and increases denial risk for complex service categories. |

### Appeal-Specific Feature (Model 07 only)

| # | Feature | Source Table | Description | Business Relevance |
|---|---------|-------------|-------------|-------------------|
| A01 | `additional_documentation_submitted` | fact_appeal | Whether appellant submitted additional documentation with the appeal (True/False) | Additional documentation at appeal is associated with overturn. Available at appeal intake — not leakage. |

---

## Pre-Decision Flag

All features above are flagged as **PRE-DECISION** — they are known at or before the initial review determination.

The following fields are explicitly **NOT INCLUDED** and are documented in `model_leakage_audit.md`:

- `decision_time_days` (outcome for delay model — not an input)
- `decision_date` (reveals when decision was made)
- `denial_reason` (revealed only after denial)
- `final_outcome` (post-appeal)
- `appeal_id`, `appealed`, `appeal_outcome`, `final_status_after_appeal` (all post-decision)
- `action_recommended_initial` (internal routing flag, post-intake)
- `reviewer_type` (assigned during review process, post-submission)
- `pended_flag` (set during review process)

---

## Preprocessing Applied

| Feature Type | Preprocessing |
|---|---|
| Categorical (C01–C12) | OneHotEncoder (handle_unknown='ignore', sparse_output=False) |
| Numeric (N01–N05) | StandardScaler (mean=0, std=1) — fitted on train set only |
| Boolean (B01–B04, A01) | passthrough (already binary 0/1) |

Preprocessing is implemented via scikit-learn `ColumnTransformer` inside a `Pipeline` — fitted on training data only, applied to test data at inference time. No data leakage from test set to training.

---

*model_feature_dictionary.md — Phase 5 documentation. Last updated: 2026-06-01*
