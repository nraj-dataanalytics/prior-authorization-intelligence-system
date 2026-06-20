# Prior Authorization Intelligence System (PAIS)

> A healthcare payer analytics capstone project analyzing prior authorization delays, denials, appeals, and operational friction — using CMS/KFF/OIG-informed benchmarks, synthetic workflow data, SQL, Power BI design, predictive modeling (GBM + LR), and a Streamlit decision-support application.

---

## Business Problem

Prior authorization is a payer-required administrative process in which providers must obtain approval before delivering certain medical services. It is one of the most operationally burdensome processes in U.S. healthcare.

**The data problem it creates:**

- Medicare Advantage plans processed **52.8 million** PA determinations in 2024, with approximately **4.1 million (7.7%)** denied — up from 49.8 million determinations and 3.2 million (6.4%) denials the prior year (KFF analysis of CMS data, 2025)
- **75% of denied requests that went to appeal were overturned** — suggesting a large fraction of denials are inappropriate at first determination (HHS OIG, 2022)
- **34% of Medicare Advantage denials** cited "insufficient documentation" — a preventable, operations-driven cause (HHS OIG, 2022)
- CMS finalized **CMS-0057-F** (January 17, 2024), requiring Medicare Advantage organizations to publicly report 5 PA metrics annually starting March 2026 and to meet 7-day (standard) / 72-hour (expedited) turnaround requirements

This is not just a policy issue. It is an **operational data problem** — one where workflow analytics, predictive modeling, and decision-support tooling can meaningfully reduce delays, prevent unnecessary denials, and improve SLA compliance.

---

## Why This Project Matters

For healthcare payer employers (CVS Health, Aetna, The Hartford, UnitedHealthcare, Cigna, Humana):

- Demonstrates end-to-end understanding of the PA workflow from submission to appeal
- Shows ability to translate CMS regulatory requirements into measurable KPIs
- Shows responsible ML development: leakage exclusion, ethical framing, threshold selection
- Produces actionable outputs (workflow routing recommendations, not "approve/deny" decisions)
- All modeling assumptions are source-backed or explicitly labeled

---

## Hybrid Data Strategy

**Why synthetic data?** Real prior authorization records are protected health information (PHI) under HIPAA and are not publicly available at the individual-request level.

**How this project handles it:** All modeling was done on a 25,000-row synthetic dataset generated using:
- Published benchmark rates from KFF, HHS OIG, CMS, NCQA, and CAQH as calibration targets
- Documented payer-workflow assumptions (clearly labeled in `data/public_benchmark_assumptions.csv`)
- A reproducible Python generator (`data/synthetic_data_generator.py`)
- A benchmark validation report confirming the synthetic data matches published targets

This approach mirrors how real payer analytics teams work when building internal tools: they use internal data that is not publicly shareable. The synthetic data allows full methodology transparency.

---

## Project Architecture

```
Problem Framing (Phase 1)
    ↓
Synthetic Data Generation + Validation (Phase 2)
    ↓
SQL Analytics Layer (Phase 3)
    ↓
Power BI Dashboard Design (Phase 4)
    ↓
Predictive Modeling: Delay + Denial + Appeal (Phase 5)
    ↓
Recommendation Engine + Streamlit App (Phase 6)
```

---

## Folder Structure

```
prior-authorization-intelligence-system/
├── README.md                          ← This file
├── .gitignore
├── business_problem.md                ← Full business problem statement
├── source_registry.md                 ← All public sources with URLs and dates
├── cms_metric_mapping.md              ← CMS-0057-F metric definitions and mapping
├── limitations_and_ethics.md          ← Data limitations, model constraints, ethics
│
├── data/                              ← Synthetic dataset (4 tables + documentation)
│   ├── prior_auth_requests.csv        ← 25,000 PA requests (main fact table)
│   ├── providers.csv                  ← Provider profiles with historical rates
│   ├── members.csv                    ← Member demographics and risk levels
│   ├── services.csv                   ← Service categories and procedure groups
│   ├── appeals.csv                    ← Appeal outcomes (175 records)
│   ├── public_benchmark_assumptions.csv
│   ├── synthetic_assumption_table.csv
│   ├── validation_targets_table.csv
│   ├── data_dictionary.md
│   ├── data_quality_report.md
│   ├── entity_relationship_design.md
│   └── synthetic_data_generation_methodology.md
│
├── sql/                               ← 8 SQL scripts + data dictionary
│   ├── 01_create_database.sql
│   ├── 02_create_tables.sql
│   ├── 03_load_data.sql
│   ├── 04_data_quality_checks.sql
│   ├── 05_business_kpi_queries.sql
│   ├── 06_delay_denial_analysis_queries.sql
│   ├── 07_provider_friction_queries.sql
│   ├── 08_dashboard_views.sql
│   └── sql_data_dictionary.md
│
├── notebooks/                         ← Jupyter notebooks for predictive modeling
│   ├── 05_delay_risk_model.ipynb      ← GBM delay risk model (ROC-AUC 0.799)
│   ├── 06_denial_risk_model.ipynb     ← LR denial risk model (ROC-AUC 0.713)
│   └── 07_appeal_overturn_model_optional.ipynb
│
├── powerbi/                           ← Power BI dashboard documentation
│   ├── powerbi_data_model_plan.md
│   ├── dax_measures.md
│   ├── dashboard_page_plan.md
│   ├── dashboard_wireframe.md
│   ├── dashboard_visual_specification.md
│   ├── dashboard_tooltip_and_footnote_guide.md
│   ├── dashboard_storytelling_guide.md
│   ├── cms_public_metrics_report_simulation.md
│   └── powerbi_theme.json
│
├── models/                            ← Model documentation
│   ├── model_metrics.csv              ← ROC-AUC, PR-AUC, recall, precision for all models
│   ├── feature_importance.csv         ← SHAP-based feature importance (delay model)
│   ├── model_feature_dictionary.md
│   ├── model_leakage_audit.md
│   ├── model_explainability_report.md
│   └── threshold_selection_notes.md
│
├── app/                               ← Streamlit decision-support application
│   ├── streamlit_app.py               ← Main app (run this)
│   ├── recommendation_rules.py        ← 8-rule recommendation engine
│   ├── train_models.py                ← Standalone retraining script
│   ├── requirements.txt
│   ├── app_user_guide.md
│   ├── model_integration_notes.md
│   ├── responsible_use_disclaimer.md
│   ├── sample_scenarios.md
│   └── models/                        ← Pre-trained model artifacts
│       ├── delay_model.pkl
│       ├── denial_model.pkl
│       └── feature_metadata.json
│
├── assets/                            ← Model visualizations
│   └── model_visuals/
│       ├── delay_pr_curve.png
│       ├── denial_pr_curve.png
│       ├── cv_summary.png
│       └── calibration_diagrams.png
│
└── reports/                           ← Phase audits and validation reports
    ├── phase_1_self_audit.md
    ├── phase_2_self_audit.md
    ├── phase_3_self_audit.md
    ├── phase_4_self_audit.md
    ├── phase_5_self_audit.md
    ├── phase_6_self_audit.md
    ├── benchmark_validation_report.md
    ├── project_authenticity_check.md
    └── github_repo_readiness_audit.md
```

---

## Tools and Technologies

| Layer | Tools |
|-------|-------|
| Data generation | Python (pandas, numpy, scipy) |
| SQL analytics | PostgreSQL-compatible SQL |
| Dashboard design | Power BI (documented in Markdown + JSON) |
| Predictive modeling | scikit-learn (GradientBoostingClassifier, LogisticRegression), SHAP |
| Application | Streamlit, pickle, pandas |
| Documentation | Markdown |
| Version control | Git / GitHub |

---

## SQL Layer

8 SQL scripts covering the full analytics pipeline:

- **01–03:** Database schema, table creation, data loading with validation
- **04:** 20+ data quality checks (null rates, referential integrity, benchmark conformance)
- **05:** Business KPIs — overall PA volume, SLA compliance rate, denial rate, appeal overturn rate
- **06:** Delay and denial analysis by service category, provider type, submission channel, request type
- **07:** Provider friction analysis — incomplete submission rates, response time distributions, risk segmentation
- **08:** 6 dashboard-ready views combining metrics from all prior scripts

All scripts include inline comments explaining the business logic behind each query.

---

## Power BI Dashboard

Four-page dashboard design documented in full detail:

- **Page 1 — Executive Summary:** Overall SLA compliance, denial rate, appeal overturn, top 5 denial service categories
- **Page 2 — Delay Analysis:** Delay rate by service category, request type, submission channel, provider type, time trend
- **Page 3 — Denial + Appeal Analysis:** Denial reasons, overturn rates by reason, provider-level denial patterns
- **Page 4 — CMS-0057-F Compliance:** The 5 required public metrics formatted for the CMS annual reporting template

Includes: 15 DAX measures, full wireframe specifications, visual-level tooltip and footnote standards, color palette, Power BI theme JSON, and a storytelling guide for recruiter walkthroughs.

---

## Predictive Models

### Delay Risk Model (GBM)
- **Target:** `delayed_flag` — 1 if decision_time_days > CMS SLA (7 standard, 3 expedited)
- **Algorithm:** GradientBoostingClassifier (200 trees, depth 4, lr 0.05)
- **ROC-AUC:** 0.799 (test) | CV: 0.813 ± 0.008 (5-fold, LR baseline)
- **PR-AUC:** 0.440 (2.4× naive baseline)
- **Operating threshold:** 0.193 (recall ≥ 0.75)
- **Top features (SHAP):** auto_eligible, documentation_complete, submission_channel, estimated_cost

### Denial / Documentation Risk Model (LR)
- **Target:** `denied_flag` — 1 if initial decision = Denied (leakage-safe target)
- **Algorithm:** LogisticRegression (class_weight=balanced, C=1.0)
- **ROC-AUC:** 0.713 (test) | CV: 0.715 ± 0.009 (5-fold)
- **PR-AUC:** 0.131 (2.1× naive baseline at 6.1% positive rate)
- **Operating threshold:** 0.052 (recall ≥ 0.70)
- **Top features:** documentation_complete, auto_eligible, network_status, service_category

### Appeal Overturn Model (Illustrative)
- **Note:** 175 appeal records only — labeled ILLUSTRATIVE throughout
- **LR ROC-AUC:** 0.695 ± 0.081 (5-fold CV, no train/test split at this sample size)
- **Purpose:** Demonstrates methodology; not used in production app

**All models exclude leakage fields** (decision_time_days as a feature, denial_reason, final_outcome, appeal outcomes) — documented in `models/model_leakage_audit.md`.

---

## Streamlit Decision-Support App

The `app/streamlit_app.py` application is a prior authorization workflow triage tool for UM coordinators.

**What it does:**
1. Takes 17 pre-decision PA request attributes as input
2. Runs pre-trained GBM + LR models to produce delay and denial risk scores
3. Applies 8 rule-based recommendation rules
4. Displays: risk score cards, top risk drivers, workflow action recommendations, SLA status, and responsible-use disclaimer
5. **What-If Risk Reduction Simulator:** Simulates operational interventions (documentation completion, channel switch, auto-eligibility) and shows Before vs. After risk scores with rules eliminated — enabling operational "what can we do now to reduce risk?" decision-making

**What it does NOT do:**
- It does not approve or deny care
- It does not replace clinical judgment
- It does not use real patient data
- It is not a compliance certification

### How to Run the App

```bash
# 1. Install dependencies
pip install -r app/requirements.txt

# 2. From the project root directory:
streamlit run app/streamlit_app.py

# 3. App opens at http://localhost:8501
```

**To retrain models from the synthetic data:**
```bash
python3 app/train_models.py
```

### 8 Recommendation Rules

| Rule | Trigger | Workflow Action |
|------|---------|-----------------|
| R1 | High delay + incomplete docs | Documentation checklist + priority escalation |
| R2 | High denial + incomplete docs | Documentation follow-up before determination |
| R3 | High delay + expedited request | SLA escalation — 72-hour window |
| R4 | Low delay + auto-eligible + complete docs | Fast-track administrative processing |
| R5 | Provider incomplete rate ≥ 30% | Provider outreach / education |
| R6 | High denial + prior denial history | Senior review before final denial |
| R7 | Cost ≥ $15,000 + clinical review | Clinical reviewer routing |
| R8 | Fax/phone + high risk | Channel conversion recommendation |

---

## Screenshots

Screenshots to be added after local deployment. Run `streamlit run app/streamlit_app.py`, test all 4 scenarios, and save to `assets/app_screenshots/`.

The app includes a **What-If Risk Reduction Simulator** — screenshots should capture the Before vs. After comparison for Scenario A (completing documentation + switching to Electronic eliminates 4 of 7 escalation rules).

| Scenario | Description |
|----------|-------------|
| Scenario A | High-Risk SLA Breach — 7 rules fire; What-If shows 4 rules eliminated by completing docs + Electronic channel |
| Scenario B | Fast-Track Candidate — R4 fires, fast-track badge shown |
| Scenario C | Documentation Follow-Up — provider with 38% incomplete rate |
| Scenario D | Senior Review Before Denial — prior denial history + OON + high cost |

---

## Responsible Use Disclaimer

This project was built as a **healthcare analytics portfolio demonstration**. It:

- Uses only synthetic data — no PHI, no real patient or provider records
- Does not approve or deny care at any stage
- Does not replace clinical judgment
- Is not a deployed production system
- Is not affiliated with any health plan, insurer, or provider

Model performance metrics are bounded to the synthetic dataset. Real-world performance requires real data, disparate impact assessment, model calibration, and clinical governance review. See `limitations_and_ethics.md` for full documentation.

---

## Portfolio / Article

*GitHub Pages portfolio article link — to be added.*

---

## Sources

| Source | Used For |
|--------|----------|
| CMS-0057-F (Jan 2024) | SLA requirements, 5 required metrics |
| KFF Medicare Advantage Denials Report (2023) | Denial volume, appeal overturn benchmarks |
| HHS OIG PA Report (2022) | Documentation denial rates, appeal overturn |
| NCQA PA Accreditation Standards | Clinical review requirements |
| CAQH Index (2022) | Electronic submission rates, processing efficiency |
| AMA PA Survey (2022) | Provider burden statistics |

Full citations with URLs: `source_registry.md`

---

## Author

**Raj Nandani**
Healthcare Analytics | Business Analytics | Data Analytics
nandaniraj1509@gmail.com

---

*Prior Authorization Intelligence System | Phase 6 Complete | 2026*
