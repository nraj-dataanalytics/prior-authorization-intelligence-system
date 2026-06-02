# Model Leakage Audit
## Prior Authorization Intelligence System (PAIS)
**Phase 5 | Predictive Modeling and Model Explainability**
**Generated: 2026-06-01**
**ALL DATA IS SYNTHETIC. No PHI.**

---

## Purpose

Data leakage occurs when features used to train a model contain information that would not be available at the time a real prediction is made. In a prior authorization workflow, leakage means using information that becomes known **after** the decision outcome — making the model appear to perform well in training but fail in production.

This audit explicitly documents every field in the dataset, classifies it as included or excluded, and explains the timing and leakage risk for each excluded field.

---

## Leakage Classification Framework

**Available at submission:** Known when the PA request is submitted by the provider.
**Available at early review:** Known within the first 24 hours of internal processing, before any decision is made.
**Available at decision:** Known only at the moment the decision is rendered — leakage if used to predict that decision.
**Available post-decision:** Known after the decision is made — always leakage.

---

## Field-by-Field Audit: fact_prior_authorization

| Field | Timing | Status | Reason |
|-------|--------|--------|--------|
| `request_id` | Submission | NOT USED | Identifier — no predictive value |
| `member_id` | Submission | NOT USED | Identifier — join key only |
| `provider_id` | Submission | NOT USED | Identifier — join key only; provider attributes used instead |
| `service_id` | Submission | NOT USED | Identifier — join key only; service attributes used instead |
| `request_type` | Submission | **INCLUDED** | C01 — known at submission |
| `submitted_date` | Submission | NOT USED | Date itself has no predictive value; day-of-week derived |
| `submitted_day_of_week` | Submission | **INCLUDED** | C12 — derived at submission |
| `submission_channel` | Submission | **INCLUDED** | C02 — known at submission |
| `documentation_complete` | Early review | **INCLUDED** | B01 — determined within first review (is documentation present?) |
| `estimated_cost` | Submission | **INCLUDED** | N01 — submitted by provider |
| `previous_denial_history` | Submission | **INCLUDED** | B02 — from member's historical record |
| `auto_eligible` | Early review | **INCLUDED** | B03 — determined by eligibility check at intake |
| `clinical_review_required` | Early review | **INCLUDED** | B04 — determined at intake routing |
| `decision` | **Decision** | **⛔ EXCLUDED from delay model** | IS the outcome for denial model / leakage for delay model |
| `decision_date` | Decision | **⛔ EXCLUDED** | Reveals when decision was made — leakage |
| `decision_time_days` | Decision | **⛔ EXCLUDED** | IS the outcome for delay model — direct leakage |
| `delayed_flag` | Decision | **TARGET ONLY** | Derived from decision_time_days — used as target, never as input |
| `action_recommended_initial` | Early review | **⛔ EXCLUDED** | Internal routing recommendation — post-intake, correlates with outcome |
| `pended_flag` | Decision | **⛔ EXCLUDED** | Set during review process — post-submission |
| `reviewer_type` | Decision | **⛔ EXCLUDED** | Assigned during review — not known at submission |
| `denial_reason` | Decision | **⛔ EXCLUDED** | Known only after denial decision — leakage for denial model |
| `final_outcome` | Post-decision | **⛔ EXCLUDED** | Post-appeal resolution — always leakage |

---

## Field-by-Field Audit: fact_appeal

| Field | Timing | Status | Reason |
|-------|--------|--------|--------|
| `appeal_id` | Post-decision | **⛔ EXCLUDED** | Exists only after denial and appeal filing |
| `request_id` | Post-decision | **JOIN KEY ONLY** | Used to link appeal to PA request |
| `appeal_date` | Post-decision | **⛔ EXCLUDED** | Date of appeal filing — post-decision |
| `appeal_decision_date` | Post-decision | **⛔ EXCLUDED** | Date of appeal decision — post-decision |
| `appeal_decision_days` | Post-decision | **⛔ EXCLUDED** | Duration of appeal — post-decision |
| `appeal_outcome` | Post-decision | **TARGET ONLY (Model 07)** | Used as target for overturn model — never as input |
| `reason_overturned` | Post-decision | **⛔ EXCLUDED** | Known only after appeal decision |
| `additional_documentation_submitted` | Appeal intake | **INCLUDED (Model 07 only)** | A01 — submitted with appeal packet, available at appeal intake |
| `final_status_after_appeal` | Post-decision | **⛔ EXCLUDED** | Post-appeal field — always leakage |

---

## Field-by-Field Audit: dim_provider

| Field | Timing | Status | Reason |
|-------|--------|--------|--------|
| `provider_id` | Submission | JOIN KEY | Not a feature |
| `provider_name` | Submission | NOT USED | Identifier — too high cardinality |
| `provider_type` | Submission | **INCLUDED** | C03 |
| `network_status` | Submission | **INCLUDED** | C04 |
| `provider_risk_segment` | Submission | **INCLUDED** | C05 — pre-computed from historical data, available in provider master |
| `avg_incomplete_submission_rate` | Submission | **INCLUDED** | N02 — historical rate from provider master, not computed from current request |
| `avg_response_time_days` | Submission | **INCLUDED** | N03 — historical average, not computed from current request |
| `region` | Submission | **INCLUDED** | C11 |
| `state` | Submission | NOT USED | Subsumed by region |

---

## Field-by-Field Audit: dim_member

| Field | Timing | Status | Reason |
|-------|--------|--------|--------|
| `member_id` | Submission | JOIN KEY | Not a feature |
| `age_band` | Submission | **INCLUDED** | C07 |
| `plan_type` | Submission | **INCLUDED** | C06 |
| `risk_level` | Submission | **INCLUDED** | C08 — from member's risk stratification file |
| `chronic_condition_count` | Submission | **INCLUDED** | N04 — from member's health record |
| `member_tenure_months` | Submission | **INCLUDED** | N05 |

---

## Field-by-Field Audit: dim_service

| Field | Timing | Status | Reason |
|-------|--------|--------|--------|
| `service_id` | Submission | JOIN KEY | Not a feature |
| `service_category` | Submission | **INCLUDED** | C09 |
| `procedure_group` | Submission | **INCLUDED** | C10 |
| `service_name` | Submission | NOT USED | Too high cardinality; service_category captures it |

---

## `action_recommended_initial` — Special Note

This field received particular scrutiny. It represents the initial internal routing recommendation (e.g., "Auto-Approve", "Clinical Review", "Escalate"). While it is set early in the workflow, it is set **after** submission intake and correlates strongly with the outcome because it IS the early proxy for the outcome.

**Decision: Excluded.** Including this feature would allow the model to learn "if the system already recommended approval, predict no delay" — which is not generalization, it is learning the system's own internal logic. In a production model, this field would be the **output** of a separate routing model, not an input to a delay or denial prediction model.

---

## Summary

| Category | Count | Status |
|----------|-------|--------|
| Features included in models | 21 (+1 appeal-specific) | ✅ All pre-decision |
| Fields excluded — post-decision | 9 | ⛔ Leakage |
| Fields excluded — identifiers / not useful | 8 | — |
| Target fields (used as targets only) | 3 | `delayed_flag`, `denied_flag`, `overturned_flag` |

**All 21 model features have been confirmed as available at submission or early review (before any outcome is determined). No post-decision fields are included in any model input.**

---

*model_leakage_audit.md — Phase 5 documentation. Last updated: 2026-06-01*
