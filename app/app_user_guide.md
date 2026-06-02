# App User Guide
## Prior Authorization Intelligence System (PAIS) — Phase 6
**Generated: 2026-06-01 | Streamlit Decision-Support Tool**

---

## Quick Start

```bash
# 1. Install dependencies
pip install -r app/requirements.txt

# 2. From the project root directory, run:
streamlit run app/streamlit_app.py

# 3. App opens in browser at http://localhost:8501
```

**Python version:** 3.10+ recommended
**Minimum RAM:** 2GB (models are ~50MB each in memory)

---

## What the App Does

The PAIS Streamlit app is a **prior authorization workflow decision-support tool**. It:

1. Accepts a PA request's pre-decision attributes (17 features)
2. Runs pre-trained Gradient Boosting (delay) and Logistic Regression (denial) models
3. Returns delay risk score and denial/documentation risk score
4. Applies 8 rule-based recommendation rules
5. Displays risk cards, top drivers, workflow actions, SLA status, and disclaimer

The app does **not** approve or deny care. It is for operational triage only.

---

## Interface Walkthrough

### Sidebar — Input Form

Fill in all fields before clicking "Analyze This Request":

**Request Attributes**
- **Request Type:** Standard (7-day SLA) or Expedited (72-hour SLA) per CMS-0057-F
- **Submission Channel:** Electronic/Portal = faster; Fax/Phone = adds processing delay
- **Service Category:** Select the broadest match for the requested service
- **Procedure Group:** More specific classification within the service category
- **Estimated Cost:** Estimated dollar value of the service (used to flag high-cost routing)

**Provider Profile**
- **Provider Type:** Select the type of the submitting provider
- **Network Status:** In-Network or Out-of-Network (OON = ~1.8× higher denial rate)
- **Provider Risk Segment:** Low/Moderate/High — from provider's historical performance
- **Provider Incomplete Rate:** Slide to the provider's historical incomplete submission rate
- **Provider Avg Response Days:** Average days the provider takes to respond to doc requests

**Member Profile**
- **Plan Type:** HMO/PPO/SNP/PFFS — different PA requirements by plan type
- **Age Band:** Member's age range
- **Member Risk Level:** Derived from chronic conditions and claims history

**Clinical Flags (checkboxes)**
- **Documentation Complete:** ✅ if all required docs were submitted with initial request
- **Auto-Eligible:** ✅ if request qualifies for automated adjudication
- **Clinical Review Required:** ✅ if request requires licensed clinical reviewer
- **Prior Denial History:** ✅ if member has had a prior PA denial

### Main Panel — Results

After clicking "Analyze This Request":

**Section 3 — Risk Score Cards**
Three cards display: Delay Risk Score, Denial/Doc Risk Score, Overall Risk.
Color coding: 🟢 Low | 🟡 Moderate | 🔴 High
Progress bar shows score relative to threshold.

**Section 4 — Top Risk Drivers**
Up to 5 factors most contributing to the risk scores. Based on SHAP feature importance
(delay model) and LR coefficients (denial model) combined with input feature values.

**Section 5 — Recommended Workflow Actions**
Up to 7 actions listed in priority order. Each action corresponds to a named rule.
Click "Rules applied" to see which rules fired and why.

**Section 6 — SLA & Compliance Status**
SLA window (7 days or 72 hours), current risk vs threshold, and active workflow flags.
Green/yellow/red SLA status based on delay risk score.

**Section 7 — Responsible Use Disclaimer**
Always visible. Non-negotiable. This is not a coverage determination tool.

**Section 8 — Example Scenarios**
Expandable panel with 4 pre-built test scenarios. Use these to quickly test the full
range of recommendation engine outputs without manually entering all inputs.

---

## Understanding Risk Scores

| Score Range | Label | Meaning | Workflow Action |
|-------------|-------|---------|----------------|
| delay < 0.12 | Low | SLA breach unlikely | Standard processing queue |
| 0.12 ≤ delay < 0.193 | Moderate | Elevated delay risk | Coordinator awareness flag |
| delay ≥ 0.193 | High | SLA breach likely | Priority Review Queue |
| denial < 0.035 | Low | Denial unlikely | Standard processing |
| 0.035 ≤ denial < 0.052 | Moderate | Elevated denial risk | Watch queue |
| denial ≥ 0.052 | High | Denial likely | Documentation follow-up |

**These are risk scores, not calibrated probabilities.** A score of 0.25 does not mean
"25% probability." It means the request is above the operating threshold selected to
achieve 75%+ recall on actual delay/denial cases in the training data.

---

## Recommendation Rules Reference

| Rule | Trigger | Action |
|------|---------|--------|
| R1 | High delay + incomplete docs | Documentation checklist + priority escalation |
| R2 | High denial + incomplete docs | Documentation follow-up before denial |
| R3 | High delay + Expedited request | SLA escalation — 72-hour window |
| R4 | Low delay + low denial + auto-eligible + complete docs | Fast-track candidate |
| R5 | Provider incomplete rate ≥ 30% | Provider outreach / education |
| R6 | High denial + prior denial history | Senior review before final denial |
| R7 | Cost ≥ $15,000 + clinical review required | Clinical reviewer route |
| R8 | Fax/Phone + high risk | Convert to electronic/portal workflow |

Multiple rules can fire on a single request. Actions are listed in priority order.

---

## File Structure

```
app/
├── streamlit_app.py           ← Main app — run this
├── recommendation_rules.py    ← Rule engine (import by streamlit_app)
├── requirements.txt           ← pip install dependencies
├── app_user_guide.md          ← This document
├── model_integration_notes.md ← Technical architecture
├── responsible_use_disclaimer.md
├── sample_scenarios.md        ← 4 test scenarios with expected outputs
└── models/
    ├── delay_model.pkl         ← GBM pipeline (pre, clf)
    ├── denial_model.pkl        ← LR pipeline (pre, clf)
    └── feature_metadata.json  ← Feature lists, thresholds, LR coefficients
```

---

## Troubleshooting

**"ModuleNotFoundError: No module named 'recommendation_rules'"**
Run the app from the project root: `streamlit run app/streamlit_app.py`
Do not run from inside the `app/` directory.

**"FileNotFoundError: delay_model.pkl"**
The model files in `app/models/` must exist before running the app.
If missing, re-run the training script: `python3 app/train_models.py`

**Sklearn version mismatch warning**
Ensure the sklearn version used to train matches the version in requirements.txt.
Pickle files are sklearn-version-specific.

**App runs slowly on first load**
Models are loaded and cached on first run. Subsequent predictions are fast (milliseconds).

---

*app_user_guide.md — Phase 6 documentation. Last updated: 2026-06-01*
