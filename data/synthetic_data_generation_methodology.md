# Synthetic Data Generation Methodology — Prior Authorization Intelligence System
**Phase 2 | Last Updated: 2026-05-31**

---

## 1. Guiding Principles

1. **No PHI.** No real names, SSNs, NPIs, or identifiable records. All IDs are sequential synthetic codes.
2. **Benchmark-calibrated.** Every major distribution parameter is traceable to a source in public_benchmark_assumptions.csv or labeled `[ASSUMPTION]`.
3. **Pattern logic over random noise.** Relationships between fields (documentation → denial, channel → delay, provider behavior → friction) are deliberately encoded to create analytically meaningful variation.
4. **Reproducible.** Fixed random seed (SEED = 42) ensures identical output on re-run.
5. **No target leakage.** The field `action_recommended_initial` is a process simulation field and must not be used as a predictor of `decision`.

---

## 2. Generation Order

The generator must create tables in dependency order to maintain referential integrity:

```
1. services.csv       (no dependencies)
2. members.csv        (no dependencies)
3. providers.csv      (no dependencies)
4. prior_auth_requests.csv  (depends on 1, 2, 3)
5. appeals.csv        (depends on 4)
```

---

## 3. Table Generation Logic

### 3a. services.csv (40 rows)

10 service categories × ~4 services each.

| Service Category | Base Denial Risk | Base Delay Risk | Source |
|-----------------|-----------------|----------------|--------|
| Advanced Imaging | 0.12 | 0.18 | [ASSUMPTION] OIG S5 names imaging as frequent high-denial category |
| Inpatient Hospital | 0.13 | 0.20 | [ASSUMPTION] OIG S5 names inpatient stays as high-denial; post-acute context |
| Post-Acute / SNF | 0.16 | 0.22 | [ASSUMPTION] OIG S5 explicitly cites inpatient rehab/SNF; highest denial risk |
| Surgical Procedures | 0.10 | 0.15 | [ASSUMPTION] Moderate-high; surgery requires clinical review |
| Specialty Drugs | 0.09 | 0.13 | [ASSUMPTION] MA drug PA less studied; moderate assumption |
| Durable Medical Equipment | 0.10 | 0.14 | [ASSUMPTION] DME has historically high denial rates per OIG context |
| Outpatient Procedures | 0.05 | 0.08 | [ASSUMPTION] Lower complexity; more automation-eligible |
| Behavioral Health | 0.08 | 0.12 | [ASSUMPTION] Mental health parity law context; moderate denial |
| Physical/Occupational Therapy | 0.06 | 0.09 | [ASSUMPTION] High automation eligibility; lower denial |
| Home Health | 0.09 | 0.14 | [ASSUMPTION] Home health PA common in MA; moderate denial |

**All service-category denial risk values are documented payer workflow assumptions informed by OIG narrative (S5). No CMS public data breaks denial rates by service type (confirmed by 2026 research). These assumptions are labeled `[ASSUMPTION]` in synthetic_assumption_table.csv (rows C01-C10).**

Automation eligibility: Outpatient, PT/OT, Behavioral Health, Home Health = high automation eligible. Imaging, Surgical, Inpatient, Post-Acute, SNF = clinical review required.

Cost ranges assigned by service category complexity.

---

### 3b. members.csv (5,000 rows)

| Field | Distribution |
|-------|-------------|
| age_band | Calibrated to MA demographics: 65-74 (35%), 75-84 (28%), 55-64 (18%), 85+ (10%), 45-54 (6%), 18-44 (3%) |
| gender | M (47%), F (51%), U (2%) |
| plan_type | HMO (42%), PPO (35%), SNP (15%), PFFS (8%) |
| region | West (22%), South (30%), Midwest (24%), Northeast (20%), Southwest (4%) |
| risk_level | Derived from chronic_condition_count: 0-1 → Low, 2-3 → Medium, 4+ → High |
| chronic_condition_count | Poisson(λ=2.5); capped at 8. MA avg ~2-3 chronic conditions |
| member_tenure_months | Uniform(1, 60) |

---

### 3c. providers.csv (1,000 rows)

Provider type distribution calibrated to PA-active provider types:
- Specialist (25%), Hospital (20%), Imaging Center (15%), Surgery Center (12%), Primary Care (10%), DME Supplier (8%), Post-Acute Facility (5%), Home Health Agency (3%), Behavioral Health (2%)

`avg_incomplete_submission_rate` assigned by provider type:
- Hospitals and large practices: lower rate (0.05-0.18)
- DME Suppliers and small practices: higher rate (0.18-0.40)
- Overall mean: ~0.22 (calibrated to A13)

`prior_auth_volume_band` assigned by provider type (hospitals → Very High; specialists → High/Medium; home health → Low/Medium)

`provider_risk_segment` derived:
- avg_incomplete_submission_rate > 0.30 → High-Risk
- 0.15-0.30 → Moderate-Risk
- < 0.15 → Low-Risk

---

### 3d. prior_auth_requests.csv (25,000 rows)

This is the most complex generation step. The logic follows a **decision tree** where each field is computed based on upstream field values plus randomization within calibrated ranges.

#### Step 1: Base fields
- `request_id`: sequential PAR-000001 to PAR-025000
- `submitted_date`: random dates 2023-01-01 to 2024-12-31. Year 2024 gets 53% of volume (6% YoY growth from A25). Day of week: 90% Mon-Fri, 10% Sat-Sun.
- `member_id`, `provider_id`, `service_id`: randomly sampled from respective tables. Provider assignment weighted by volume band (high-volume providers get more requests).

#### Step 2: Request characteristics
- `request_type`: 15% Expedited, 85% Standard (A23)
- `submission_channel`: Electronic 55%, Fax 25%, Portal 12%, Phone 8% (A20-A22)
- `estimated_cost`: sampled from service base_cost_min to base_cost_max
- `previous_denial_history`: 18% TRUE (documented assumption; higher for high-risk members)
- `documentation_complete`: Base rate 78% complete (i.e., 22% incomplete per A13). Modified by:
  - Provider avg_incomplete_submission_rate (primary driver)
  - Submission channel: Fax/Phone adds +5-8% incomplete risk
  - Member tenure: shorter tenure adds +3% incomplete risk

#### Step 3: Review routing
- `auto_eligible`: TRUE if service.automation_eligible = TRUE AND documentation_complete = TRUE AND estimated_cost < threshold
- `clinical_review_required`: inherited from service.clinical_review_required
- `reviewer_type`: 
  - auto_eligible = TRUE → "Automated"
  - clinical_review_required = TRUE → "Medical Director" (35%) or "Clinical Staff" (65%)
  - else → "Clinical Staff"

#### Step 4: Decision logic (the core of the generator)

**Base denial probability** = service.base_denial_risk

**Adjustment multipliers applied:**
| Condition | Effect on denial probability |
|-----------|----------------------------|
| documentation_complete = FALSE | × 2.5 (incomplete docs major denial driver; S5, S8) |
| submission_channel = Fax or Phone | × 1.3 (higher error/incomplete rate) |
| previous_denial_history = TRUE | × 1.4 (prior denial increases scrutiny) |
| provider.provider_risk_segment = High-Risk | × 1.5 (high-risk providers have systemic documentation issues) |
| network_status = Out-of-Network | × 1.8 (out-of-network denials are much more common) |
| member.risk_level = High | × 1.2 (complex members → more scrutiny) |
| auto_eligible = TRUE | × 0.4 (automation fast-tracks approvals) |
| request_type = Expedited | × 1.1 (slightly higher denial risk due to urgency context) |

Adjusted denial probability capped at 0.60 to avoid unrealistic extremes.

**Pend probability** = 12% base (A14), reduced to 8% if documentation_complete, increased to 20% if documentation_complete = FALSE and not auto_eligible.

**Decision assignment:**
1. If random < deny_prob → `decision` = "Denied"
2. Else if random < deny_prob + pend_prob → `decision` = "Pended"
3. Else → `decision` = "Approved"

**Calibration check:** After generation, overall approval rate must fall between 88-94%. If outside range, apply post-hoc correction. Target: ~92%.

#### Step 5: Denial reason assignment (for denied records only)

| Denial Reason | Base Share | Modified by |
|--------------|-----------|-------------|
| Medical Necessity Not Met | 35% | Higher for High-Risk members and clinical review cases |
| Documentation Incomplete | 28% | Higher when documentation_complete = FALSE |
| Clinical Criteria Not Met | 20% | Higher for Post-Acute, Imaging categories; reflects OIG S5 finding |
| Not a Covered Benefit | 10% | Higher for Out-of-Network |
| Duplicate/Administrative Error | 7% | Higher for Fax/Phone channels |

**OIG S5 note (mandatory):** The 13% "inappropriate denial" finding from OIG OEI-09-18-00260 applies to a stratified random sample of 250 denials from 15 MAOs during a single week in June 2019. It is cited for context and to justify the inclusion of denial quality analytics — it is NOT used as a direct parameter in the generator and is NOT generalized as a current universal rate. The denial reason distribution above encodes the concept that some proportion of "Clinical Criteria Not Met" denials would be overturned on appeal (consistent with the OIG finding conceptually).

#### Step 6: Decision timing

**Standard requests:**
- Base: lognormal(mean=log(5), σ=0.5) — mean ~5 days (A07)
- If documentation_complete = FALSE: multiply by 1.4 (documentation back-and-forth adds delay)
- If submission_channel = Fax: multiply by 1.25
- If submission_channel = Phone: multiply by 1.20
- If auto_eligible = TRUE: multiply by 0.35 (fast-tracked)
- Minimum 0.5 days, maximum 25 days

**Expedited requests:**
- Base: lognormal(mean=log(1.5), σ=0.4) — mean ~1.5 days (A08)
- Same modifiers apply at 50% weight
- Minimum 0.25 days, maximum 4 days

`allowed_days` = 7 for Standard, 3 for Expedited (CMS-0057-F mandate, S1)
`delayed_flag` = TRUE if decision_time_days > allowed_days

#### Step 7: Appeal linkage

- Only denied records are eligible for appeal
- 11.5% of denied records get `appealed` = TRUE (A04, KFF S3)
- For appealed = TRUE: generate appeal_id, set as FK

#### Step 8: final_outcome
- Approved → "Approved"
- Pended → "Pended-Resolved-Approved" (75%) or "Pended-Resolved-Denied" (25%) — documented assumption
- Denied + not appealed → "Denied"
- Denied + appealed → updated after appeals table generation

#### Step 9: action_recommended_initial (workflow simulation)
- Simulates what the reviewer's initial recommendation was before final sign-off
- Approved records: ~92% "Approve", ~8% "Request-Additional-Docs"
- Denied records: ~70% "Deny", ~20% "Request-Additional-Docs", ~10% "Pend"
- Pended records: ~80% "Pend", ~20% "Request-Additional-Docs"
- **⚠ Leakage warning:** This field is DERIVED from the same logic that produces `decision`. It must NOT be included as a predictor in any model that predicts `decision` or `delayed_flag`.

---

### 3e. appeals.csv

- One row per appeal_id (all rows in prior_auth_requests where appealed = TRUE)
- `appeal_date` = decision_date + Uniform(1, 30) days
- `appeal_decision_days` = Uniform(5, 30) — documented payer workflow assumption
- `appeal_decision_date` = appeal_date + appeal_decision_days
- `appeal_outcome`:
  - 65% Overturned (full)
  - 15.7% Partially Overturned
  - 19.3% Upheld
  - Combined overturn rate: 80.7% (A05, KFF S3)
- `reason_overturned`: Assigned to overturned records from documented workflow categories
- `additional_documentation_submitted`: 65% TRUE for overturned, 15% TRUE for upheld
- `final_status_after_appeal`: "Approved" if Overturned/Partially Overturned, else "Denied"
- Update `prior_auth_requests.final_outcome` for appealed records accordingly

---

## 4. Calibration and Validation

After generation, the script runs an internal calibration check against validation_targets_table.csv. If any key metric is outside the acceptable range, a warning is printed and the metric is reported. The data is not regenerated automatically — any major drift is flagged for manual review.

---

## 5. Reproducibility

```python
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)
random.seed(RANDOM_SEED)
```

All outputs are deterministic. Re-running the script with the same seed produces identical CSVs.

---

*See generate_synthetic_data.py for implementation. All parameters defined in synthetic_assumption_table.csv.*
