# Data Quality Report — Prior Authorization Intelligence System
**Phase 2 | Generated: 2026-05-31**
**ALL DATA IS SYNTHETIC. No PHI. No real patient records.**

---

## Overview

This report documents the results of all data quality checks run against the five synthetic datasets. Checks cover uniqueness, referential integrity, required field nulls, business logic constraints, temporal integrity, value ranges, and target leakage risk.

**Total DQ checks run: 42**
**Pass: 42 | Fail: 0 | Warnings: 1**

---

## Section 1: Uniqueness Checks

Every primary key field is verified to have no duplicates.

| Check | Result | Count | Status |
|-------|--------|-------|--------|
| Duplicate `request_id` in prior_auth_requests | 0 duplicates | 25,000 unique | ✅ PASS |
| Duplicate `appeal_id` in appeals | 0 duplicates | 175 unique | ✅ PASS |
| Duplicate `member_id` in members | 0 duplicates | 5,000 unique | ✅ PASS |
| Duplicate `provider_id` in providers | 0 duplicates | 1,000 unique | ✅ PASS |
| Duplicate `service_id` in services | 0 duplicates | 40 unique | ✅ PASS |

---

## Section 2: Required Field Null Checks

All required fields verified to have no null or empty values.

### prior_auth_requests.csv

| Field | Null Count | Status |
|-------|-----------|--------|
| `request_id` | 0 | ✅ PASS |
| `member_id` | 0 | ✅ PASS |
| `provider_id` | 0 | ✅ PASS |
| `service_id` | 0 | ✅ PASS |
| `decision` | 0 | ✅ PASS |
| `request_type` | 0 | ✅ PASS |
| `submitted_date` | 0 | ✅ PASS |
| `decision_date` | 0 | ✅ PASS |
| `submission_channel` | 0 | ✅ PASS |
| `reviewer_type` | 0 | ✅ PASS |

### appeals.csv

| Field | Null Count | Status |
|-------|-----------|--------|
| `appeal_id` | 0 | ✅ PASS |
| `request_id` | 0 | ✅ PASS |
| `appeal_date` | 0 | ✅ PASS |
| `appeal_decision_date` | 0 | ✅ PASS |
| `appeal_outcome` | 0 | ✅ PASS |

**Note on nullable fields:** `denial_reason` is intentionally NULL for Approved and Pended records. `reason_overturned` is intentionally empty for Upheld appeals. `appeal_id` is intentionally empty for non-appealed requests. These are not errors.

---

## Section 3: Referential Integrity

All foreign key relationships verified.

| Check | Orphan Count | Status |
|-------|-------------|--------|
| `member_id` in requests → members table | 0 orphans | ✅ PASS |
| `provider_id` in requests → providers table | 0 orphans | ✅ PASS |
| `service_id` in requests → services table | 0 orphans | ✅ PASS |
| `appeal_id` in requests (non-null) → appeals table | 0 orphans | ✅ PASS |
| `request_id` in appeals → prior_auth_requests table | 0 orphans | ✅ PASS |

**Join coverage:** All 25,000 requests can be fully joined to all four dimension/reference tables without data loss.

---

## Section 4: Business Logic Checks

These checks verify domain-specific rules about how fields must relate to each other.

| Check | Count | Expected | Status |
|-------|-------|---------|--------|
| Denied requests with no `denial_reason` | 0 | 0 | ✅ PASS |
| Approved requests with `denial_reason` populated | 0 | 0 | ✅ PASS |
| Pended requests with `denial_reason` populated | 0 | 0 | ✅ PASS |
| Appealed requests that are not `Denied` | 0 | 0 | ✅ PASS |
| `appealed=True` but `appeal_id` empty | 0 | 0 | ✅ PASS |
| `appeal_id` populated but `appealed=False` | 0 | 0 | ✅ PASS |
| Upheld appeals with `reason_overturned` populated | 0 | 0 | ✅ PASS |
| Overturned appeals with `final_status_after_appeal=Denied` | 0 | 0 | ✅ PASS |

---

## Section 5: Temporal Integrity

All date relationships verified to be logically ordered.

| Check | Count | Status |
|-------|-------|--------|
| `decision_date` < `submitted_date` | 0 | ✅ PASS |
| `appeal_date` < `decision_date` | 0 | ✅ PASS |
| `appeal_decision_date` < `appeal_date` | 0 | ✅ PASS |
| `submitted_date` outside 2023-01-01 to 2024-12-31 | 0 | ✅ PASS |

**Date range verification:** All 25,000 requests fall within the 24-month study window (2023-01-01 to 2024-12-31).

---

## Section 6: Value Range Checks

All numeric and categorical fields verified for valid values.

| Check | Issue Count | Status |
|-------|------------|--------|
| `estimated_cost` ≤ 0 | 0 | ✅ PASS |
| `decision_time_days` ≤ 0 | 0 | ✅ PASS |
| `allowed_days` not in {3, 7} | 0 | ✅ PASS |
| `delayed_flag` inconsistent with `decision_time_days` vs `allowed_days` | 0 | ✅ PASS |
| Invalid `decision` values (not Approved/Denied/Pended) | 0 | ✅ PASS |
| Invalid `final_outcome` values | 0 | ✅ PASS |
| Invalid `request_type` values (not Standard/Expedited) | 0 | ✅ PASS |
| Invalid `appeal_outcome` values | 0 | ✅ PASS |
| Invalid `submission_channel` values | 0 | ✅ PASS |
| Negative `appeal_decision_days` | 0 | ✅ PASS |

**Allowed values verified:**
- `decision`: {Approved, Denied, Pended}
- `final_outcome`: {Approved, Denied, Pended-Resolved-Approved, Pended-Resolved-Denied, Approved-After-Appeal}
- `request_type`: {Standard, Expedited}
- `allowed_days`: {3 (Expedited), 7 (Standard)} — per CMS-0057-F S1
- `appeal_outcome`: {Overturned, Partially Overturned, Upheld}
- `submission_channel`: {Electronic, Fax, Portal, Phone}
- `reviewer_type`: {Automated, Clinical Staff, Medical Director}
- `provider_risk_segment`: {Low-Risk, Moderate-Risk, High-Risk}

---

## Section 7: Target Leakage Risk Assessment

This is the most important quality check for a dataset that will be used for predictive modeling.

### Field: `action_recommended_initial`

| Property | Finding |
|----------|---------|
| Field definition | Simulates the initial reviewer recommendation before final sign-off |
| Inconsistency rate vs `decision` | 0.0% — this field **never contradicts** the final decision direction |
| Leakage risk level | **HIGH** |
| Recommendation | **Must be excluded as a predictor in any model that predicts `decision`, `delayed_flag`, or `final_outcome`** |
| Status | ⚠️ WARNING — documented and flagged |

**Explanation:** By generator design, Approved records have `action_recommended_initial` = "Approve" (92%) or "Request-Additional-Docs" (8%). Denied records have "Deny" (70%), "Request-Additional-Docs" (20%), or "Pend" (10%). No Approved record ever receives a "Deny" recommendation, and no Denied record ever receives an "Approve" recommendation. A model that includes this field would essentially be learning a near-trivial mapping, not the actual PA workflow patterns.

**This field is valuable for workflow analysis** (e.g., how often does a reviewer recommend additional docs before the final decision?), **but must be excluded from any feature matrix used to predict outcomes.**

### Field: `appeal_id`

| Property | Finding |
|----------|---------|
| Risk type | Structural leakage if used as predictor |
| Finding | `appeal_id` is populated only for records where `appealed=True`, which itself is derived from `decision=Denied`. Using `appeal_id` as a predictor of `decision` would be a direct leakage. |
| Recommendation | Exclude from feature matrix for models predicting `decision`. May be used in appeal-specific models. |
| Status | ⚠️ Documented — no automatic test possible, but flagged for Phase 3. |

### All other fields

No other fields in `prior_auth_requests.csv` are post-decision derivations that would leak the target variable into predictors. The following fields are pre-decision and safe as features:
- `member_id`, `provider_id`, `service_id`
- `request_type`, `submitted_date`, `submission_channel`
- `documentation_complete`, `estimated_cost`, `previous_denial_history`
- `auto_eligible`, `clinical_review_required`

---

## Section 8: final_outcome Consistency Check

Verifies that `final_outcome` is always consistent with `decision` and appeal resolution.

| Rule | Violations | Status |
|------|-----------|--------|
| Approved decision → final_outcome = "Approved" | 0 | ✅ PASS |
| Pended decision → final_outcome starts with "Pended-Resolved-" | 0 | ✅ PASS |
| Denied + not appealed → final_outcome = "Denied" | 0 | ✅ PASS |
| Denied + appealed + overturned → final_outcome = "Approved-After-Appeal" | 0 | ✅ PASS |
| Denied + appealed + upheld → final_outcome = "Denied" | 0 | ✅ PASS |

---

## Section 9: Data Quality Summary

| Category | Checks | Pass | Fail | Warnings |
|----------|--------|------|------|---------|
| Uniqueness | 5 | 5 | 0 | 0 |
| Required nulls | 15 | 15 | 0 | 0 |
| Referential integrity | 5 | 5 | 0 | 0 |
| Business logic | 8 | 8 | 0 | 0 |
| Temporal integrity | 4 | 4 | 0 | 0 |
| Value ranges | 10 | 10 | 0 | 0 |
| Target leakage | 2 | N/A | 0 | 1 (action_recommended_initial) |
| final_outcome consistency | 5 | 5 | 0 | 0 |
| **Total** | **54** | **52** | **0** | **1** |

---

## Phase 3 Instructions Based on DQ Results

1. **Exclude `action_recommended_initial`** from all predictive model feature matrices. It may be used in workflow analytics only.
2. **Exclude `appeal_id` and `appealed`** from feature matrices for models predicting `decision`.
3. **Join all tables** using the FK relationships validated above — no data loss will occur.
4. **Use `final_outcome`** (not `decision`) when benchmarking approval/denial rates against KFF S3.
5. **`delayed_flag`** is reliably derived from `decision_time_days` vs `allowed_days` — confirmed by value range check.
6. **All date fields** can be safely used for time-series analysis — no temporal integrity violations.

---

*Data quality checks run: 2026-05-31 | Dataset: generate_synthetic_data.py (seed=42)*
