"""
streamlit_app.py
Prior Authorization Intelligence System (PAIS) — Phase 6
Recommendation Engine & Decision-Support Tool

Run: streamlit run app/streamlit_app.py

FRAMING:
- This app does not approve or deny care.
- This app supports workflow prioritization and operational decision-support only.
- All models are pre-trained on synthetic data. No real payer records. No PHI.
"""

import streamlit as st
import pandas as pd
import numpy as np
import pickle
import json
import os
import sys

# Allow imports from parent directory
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from recommendation_rules import apply_rules, DISCLAIMER, get_risk_color

# ── Page config ─────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="PAIS — Prior Authorization Decision Support",
    page_icon="🏥",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ── Theme colors ─────────────────────────────────────────────────────────────
PRIMARY    = "#0057A8"
SUCCESS    = "#27AE60"
WARNING    = "#F39C12"
DANGER     = "#C0392B"
BG         = "#F4F6F9"
TEXT       = "#2C3E50"

# ── Custom CSS ───────────────────────────────────────────────────────────────
st.markdown("""
<style>
    .main { background-color: #F4F6F9; }
    .stButton>button { background-color: #0057A8; color: white; border-radius: 6px;
                       border: none; padding: 0.5rem 1.5rem; font-weight: 600; }
    .stButton>button:hover { background-color: #1A5276; }
    .risk-card { padding: 16px; border-radius: 10px; text-align: center;
                 border: 2px solid; margin: 4px; }
    .section-header { color: #0057A8; font-weight: 700; font-size: 1.1rem;
                      border-bottom: 2px solid #0057A8; padding-bottom: 4px; margin-bottom: 12px; }
    .action-box { background: #FFFFFF; border-left: 4px solid #0057A8;
                  padding: 12px 16px; border-radius: 6px; margin: 6px 0;
                  font-size: 0.95rem; }
    .disclaimer-box { background: #FFF3CD; border: 1px solid #F39C12;
                      border-radius: 8px; padding: 16px; margin-top: 16px; }
    .fast-track-badge { background: #D5F5E3; border: 2px solid #27AE60;
                        border-radius: 20px; padding: 6px 16px; color: #1E8449;
                        font-weight: 700; display: inline-block; }
    .scenario-card { background: #FFFFFF; border: 1px solid #D5D8DC;
                     border-radius: 8px; padding: 14px; margin: 8px 0; }
</style>
""", unsafe_allow_html=True)


# ── Model loading (cached) ───────────────────────────────────────────────────
@st.cache_resource
def load_models():
    """Load pre-trained models once at app startup. Never retrained in app."""
    base = os.path.dirname(os.path.abspath(__file__))
    model_dir = os.path.join(base, "models")

    with open(os.path.join(model_dir, "delay_model.pkl"), "rb") as f:
        delay_model = pickle.load(f)
    with open(os.path.join(model_dir, "denial_model.pkl"), "rb") as f:
        denial_model = pickle.load(f)
    with open(os.path.join(model_dir, "feature_metadata.json")) as f:
        meta = json.load(f)

    return delay_model, denial_model, meta


delay_model, denial_model, meta = load_models()

CAT   = meta["cat_features"]
NUM   = meta["num_features"]
BOOL  = meta["bool_features"]
FEATS = meta["all_features"]


# ── Predict function ─────────────────────────────────────────────────────────
def predict(inputs: dict) -> tuple:
    """Run delay and denial models on a single input dict. Returns (delay_score, denial_score)."""
    row = {f: inputs.get(f, 0) for f in FEATS}
    df  = pd.DataFrame([row])
    for c in BOOL:
        df[c] = df[c].astype(int)
    delay_score  = float(delay_model.predict_proba(df)[0, 1])
    denial_score = float(denial_model.predict_proba(df)[0, 1])
    return delay_score, denial_score


# ── Risk score card HTML ─────────────────────────────────────────────────────
def risk_card(title: str, score: float, label: str, threshold: float) -> str:
    color = get_risk_color(label)
    pct   = min(int(score / max(threshold * 2, 0.001) * 100), 100)
    return f"""
    <div class="risk-card" style="border-color:{color}; background:{'#FFF' }">
        <div style="font-size:0.85rem; color:#666; font-weight:600; margin-bottom:4px">{title}</div>
        <div style="font-size:2.2rem; font-weight:800; color:{color}">{score:.3f}</div>
        <div style="font-size:1rem; font-weight:700; color:{color}; margin:4px 0">{label} Risk</div>
        <div style="background:#E8EAED; border-radius:4px; height:8px; margin-top:8px">
            <div style="background:{color}; width:{pct}%; height:8px; border-radius:4px"></div>
        </div>
        <div style="font-size:0.75rem; color:#888; margin-top:4px">Threshold: {threshold}</div>
    </div>
    """


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 1: HEADER & PROJECT CONTEXT
# ══════════════════════════════════════════════════════════════════════════════
st.markdown(f"""
<div style="background:{PRIMARY}; padding:20px 28px; border-radius:10px; margin-bottom:20px">
    <h1 style="color:white; margin:0; font-size:1.6rem">
        🏥 Prior Authorization Intelligence System
    </h1>
    <p style="color:#BDC3C7; margin:6px 0 0 0; font-size:0.95rem">
        Workflow Decision-Support Tool &nbsp;|&nbsp; Phase 6 — Recommendation Engine
        &nbsp;|&nbsp; <em>Portfolio Project — Synthetic Data Only</em>
    </p>
</div>
""", unsafe_allow_html=True)

with st.expander("📖 About this tool — click to expand", expanded=False):
    st.markdown("""
    **What this tool does:**
    This app predicts prior authorization **delay risk** and **denial/documentation risk** using
    pre-trained machine learning models (Gradient Boosting for delay, Logistic Regression for denial).
    It then applies rule-based logic to generate **workflow recommendations** for operations coordinators.

    **What this tool does NOT do:**
    - ❌ It does not approve or deny care
    - ❌ It does not replace clinical judgment
    - ❌ It does not use real patient data (all models trained on synthetic data)
    - ❌ It does not guarantee CMS compliance

    **Aligned with CMS-0057-F (effective 2024):**
    CMS requires Medicare Advantage organizations to meet prior authorization turnaround
    time requirements: 7 days (Standard) and 72 hours (Expedited). This tool supports
    SLA monitoring and documentation workflow prioritization.

    **Data:** All models were trained on synthetic, benchmark-calibrated data (25,000 rows).
    Delay positive rate: 18.7%. Denial positive rate: 6.1%. No PHI. No real payer records.

    **Model performance:**
    | Model | ROC-AUC | PR-AUC | Threshold |
    |-------|---------|--------|-----------|
    | Delay Risk (GBM) | 0.799 | 0.440 | 0.193 (recall 0.75) |
    | Denial Risk (LR) | 0.713 | 0.131 | 0.052 (recall 0.71) |
    """)


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 2: INPUT FORM (Sidebar)
# ══════════════════════════════════════════════════════════════════════════════
st.sidebar.markdown(f"<div class='section-header'>📝 PA Request Details</div>", unsafe_allow_html=True)
st.sidebar.caption("Enter prior authorization request attributes. All fields are pre-decision — no outcome fields included.")

with st.sidebar:
    st.markdown("**Request Attributes**")
    request_type = st.selectbox("Request Type", ["Standard", "Expedited"],
                                 help="CMS-0057-F: Standard = 7-day SLA, Expedited = 72-hour SLA")
    submission_channel = st.selectbox("Submission Channel",
                                       ["Electronic", "Portal", "Fax", "Phone"],
                                       help="Fax/Phone add ~25% processing delay")
    service_category = st.selectbox("Service Category",
                                     ["Imaging / Radiology", "Outpatient Procedures",
                                      "Post-Acute / SNF", "Surgical", "Durable Medical Equipment",
                                      "Behavioral Health", "Physical Therapy", "Home Health",
                                      "Specialty Pharmacy", "Other"],
                                     help="Service category — key predictor of denial risk")
    procedure_group = st.selectbox("Procedure Group",
                                    ["MRI/CT", "Surgery", "Infusion", "PT/OT", "SNF Admission",
                                     "DME", "Lab", "Other"],
                                    help="More granular classification within service category")
    estimated_cost = st.number_input("Estimated Cost ($)", min_value=0, max_value=500000,
                                      value=5000, step=500,
                                      help="Estimated cost of the requested service")

    st.markdown("**Provider Profile**")
    provider_type = st.selectbox("Provider Type",
                                  ["Physician", "Specialist", "Hospital", "SNF / Post-Acute",
                                   "Physical Therapy", "Home Health Agency", "Other"])
    network_status = st.selectbox("Network Status", ["In-Network", "Out-of-Network"],
                                   help="OON providers have ~1.8× higher denial rate")
    provider_risk_segment = st.selectbox("Provider Risk Segment",
                                          ["Low-Risk", "Moderate-Risk", "High-Risk"],
                                          help="Based on provider's historical documentation and denial patterns")
    region = st.selectbox("Region", ["Northeast", "Southeast", "Midwest", "Southwest", "West"])
    avg_incomplete_rate = st.slider("Provider Avg Incomplete Submission Rate",
                                     min_value=0.0, max_value=1.0, value=0.15, step=0.01,
                                     format="%.0f%%",
                                     help="Provider's historical incomplete documentation rate")
    avg_response_days = st.number_input("Provider Avg Response Time (days)",
                                         min_value=0.0, max_value=30.0, value=3.0, step=0.5,
                                         help="Provider's historical response time to documentation requests")

    st.markdown("**Member Profile**")
    plan_type = st.selectbox("Plan Type", ["HMO", "PPO", "SNP", "PFFS"])
    age_band = st.selectbox("Age Band", ["18-44", "45-64", "65-74", "75-84", "85+"])
    risk_level = st.selectbox("Member Risk Level", ["Low", "Medium", "High", "Very High"],
                               help="Member risk stratification from claims/chronic condition data")

    st.markdown("**Clinical Flags**")
    documentation_complete = st.checkbox("Documentation Complete", value=True,
                                          help="Was required documentation submitted with the initial request?")
    auto_eligible = st.checkbox("Auto-Eligible", value=False,
                                 help="Is this request eligible for automated adjudication?")
    clinical_review_required = st.checkbox("Clinical Review Required", value=False,
                                            help="Does this request require clinical review by a licensed reviewer?")
    previous_denial_history = st.checkbox("Member Has Prior Denial History", value=False,
                                           help="Does this member have a prior PA denial on record?")

    st.markdown("---")
    run_button = st.button("🔍 Analyze This Request", use_container_width=True)


# ══════════════════════════════════════════════════════════════════════════════
# DEFAULT STATE — instructions before first run
# ══════════════════════════════════════════════════════════════════════════════
if not run_button:
    st.info("👈 **Fill in the PA request details in the sidebar and click 'Analyze This Request'** to see delay risk, denial risk, and workflow recommendations.")

    # Show example scenarios
    st.markdown("---")
    st.markdown("<div class='section-header'>💡 Example Scenarios</div>", unsafe_allow_html=True)

    scenarios = [
        {
            "title": "🚨 High-Risk: Fax Submission + Incomplete Docs",
            "desc": "Specialist submits SNF admission request by Fax. Documentation incomplete. High-risk provider segment. Expedited request.",
            "expected": "SLA escalation + documentation checklist + channel conversion suggestion"
        },
        {
            "title": "✅ Fast-Track Candidate",
            "desc": "Auto-eligible imaging request, complete documentation, low-risk provider, Electronic channel.",
            "expected": "Fast-track badge + standard processing"
        },
        {
            "title": "⚠ Denial Risk: Out-of-Network + Prior Denial",
            "desc": "Out-of-network specialist with prior denial history. High-cost surgical procedure. Clinical review required.",
            "expected": "Senior review recommendation + clinical route + provider outreach"
        },
        {
            "title": "📋 Documentation Follow-up",
            "desc": "Provider with 40% historical incomplete rate. Incomplete docs on current submission. Moderate denial risk.",
            "expected": "Documentation follow-up + provider education outreach"
        },
    ]
    cols = st.columns(2)
    for i, s in enumerate(scenarios):
        with cols[i % 2]:
            st.markdown(f"""
            <div class="scenario-card">
                <strong>{s['title']}</strong><br>
                <span style="font-size:0.9rem; color:#555">{s['desc']}</span><br>
                <span style="font-size:0.82rem; color:#0057A8; font-style:italic">Expected: {s['expected']}</span>
            </div>
            """, unsafe_allow_html=True)

    st.markdown("---")
    st.markdown(f"<div class='disclaimer-box'>{DISCLAIMER}</div>", unsafe_allow_html=True)
    st.stop()


# ══════════════════════════════════════════════════════════════════════════════
# RUN PREDICTION
# ══════════════════════════════════════════════════════════════════════════════
inputs = {
    "request_type":                    request_type,
    "submission_channel":              submission_channel,
    "service_category":                service_category,
    "procedure_group":                 procedure_group,
    "provider_type":                   provider_type,
    "network_status":                  network_status,
    "provider_risk_segment":           provider_risk_segment,
    "plan_type":                       plan_type,
    "age_band":                        age_band,
    "risk_level":                      risk_level,
    "region":                          region,
    "submitted_day_of_week":           "Monday",
    "documentation_complete":          int(documentation_complete),
    "auto_eligible":                   int(auto_eligible),
    "clinical_review_required":        int(clinical_review_required),
    "previous_denial_history":         int(previous_denial_history),
    "estimated_cost":                  float(estimated_cost),
    "avg_incomplete_submission_rate":  float(avg_incomplete_rate),
    "avg_response_time_days":          float(avg_response_days),
    "chronic_condition_count":         2,
    "member_tenure_months":            24,
}

with st.spinner("Running risk models..."):
    delay_score, denial_score = predict(inputs)
    rec = apply_rules(inputs, delay_score, denial_score,
                      denial_coef=meta.get("denial_lr_coefficients", {}))


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 3: RISK SCORE CARDS
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("<div class='section-header'>📊 Risk Assessment</div>", unsafe_allow_html=True)

# Fast-track badge
if rec.is_fast_track:
    st.markdown("<div class='fast-track-badge'>✅ FAST-TRACK CANDIDATE — Low risk across all dimensions</div>",
                unsafe_allow_html=True)
    st.markdown("")

col1, col2, col3 = st.columns(3)

with col1:
    st.markdown(risk_card(
        "Delay Risk Score", delay_score, rec.delay_risk_label,
        meta["delay_threshold"]
    ), unsafe_allow_html=True)

with col2:
    st.markdown(risk_card(
        "Denial / Doc Risk Score", denial_score, rec.denial_risk_label,
        meta["denial_threshold"]
    ), unsafe_allow_html=True)

with col3:
    overall_color = get_risk_color(rec.overall_risk_label)
    sla_days = "72 hrs" if request_type == "Expedited" else "7 days"
    st.markdown(f"""
    <div class="risk-card" style="border-color:{overall_color}">
        <div style="font-size:0.85rem; color:#666; font-weight:600; margin-bottom:4px">Overall Risk</div>
        <div style="font-size:2.2rem; font-weight:800; color:{overall_color}">{rec.overall_risk_label}</div>
        <div style="font-size:0.9rem; color:#888; margin-top:8px">SLA Limit: {sla_days}</div>
        <div style="font-size:0.85rem; color:#888">Rules applied: {len(rec.rules_fired)}</div>
    </div>
    """, unsafe_allow_html=True)


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 4: TOP RISK DRIVERS
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("---")
st.markdown("<div class='section-header'>🔍 Top Risk Drivers</div>", unsafe_allow_html=True)
st.caption("Based on model feature importance (SHAP/LR coefficients) and input feature values.")

if rec.top_risk_drivers:
    for driver in rec.top_risk_drivers:
        st.markdown(f"- {driver}")
else:
    st.success("No major risk drivers identified — low risk profile.")


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 5: RECOMMENDED WORKFLOW ACTIONS
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("---")
st.markdown("<div class='section-header'>⚡ Recommended Workflow Actions</div>", unsafe_allow_html=True)
st.caption("Rule-based recommendations for operations coordinators. Not clinical determinations.")

if rec.actions:
    for i, action in enumerate(rec.actions):
        priority_border = PRIMARY if i == 0 else "#D5D8DC"
        st.markdown(f"""
        <div class="action-box" style="border-left-color:{priority_border}">
            {action}
        </div>
        """, unsafe_allow_html=True)
    if rec.rules_fired:
        with st.expander("📋 Rules applied (for transparency)", expanded=False):
            for r in rec.rules_fired:
                st.markdown(f"- `{r}`")


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 6: SLA / COMPLIANCE NOTE
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("---")
st.markdown("<div class='section-header'>📅 SLA & CMS Compliance Status</div>", unsafe_allow_html=True)

sla_note = rec.sla_note
if "⚠" in sla_note:
    st.warning(sla_note)
elif "📊" in sla_note:
    st.info(sla_note)
else:
    st.success(sla_note)

col_a, col_b, col_c = st.columns(3)
col_a.metric("Delay Risk Score",  f"{delay_score:.3f}",  f"Threshold: {meta['delay_threshold']}")
col_b.metric("Denial Risk Score", f"{denial_score:.3f}", f"Threshold: {meta['denial_threshold']}")
col_c.metric("SLA Window", "72 hours" if request_type == "Expedited" else "7 days",
             "CMS-0057-F requirement")

# Workflow flags summary
flags = {
    "🚀 SLA Escalation":      rec.sla_escalation,
    "📋 Documentation Needed": rec.doc_checklist_required,
    "✅ Fast-Track":           rec.is_fast_track,
    "📣 Provider Outreach":    rec.provider_outreach,
    "👨‍⚕️ Senior Review":       rec.senior_review,
    "🏥 Clinical Route":       rec.clinical_route,
    "🖥 Convert Channel":      rec.convert_channel,
    "📞 Doc Follow-up":        rec.doc_followup,
}
active_flags = {k: v for k, v in flags.items() if v}
if active_flags:
    st.markdown("**Active workflow flags:**")
    flag_cols = st.columns(min(len(active_flags), 4))
    for i, (label, _) in enumerate(active_flags.items()):
        with flag_cols[i % 4]:
            st.success(label)


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 7: RESPONSIBLE-USE DISCLAIMER
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("---")
st.markdown("<div class='section-header'>⚖️ Responsible Use Disclaimer</div>", unsafe_allow_html=True)
st.markdown(f"<div class='disclaimer-box'>{DISCLAIMER}</div>", unsafe_allow_html=True)


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 8: EXAMPLE SCENARIOS (results tab)
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("---")
with st.expander("💡 Test with pre-built example scenarios", expanded=False):
    st.markdown("""
    Use these scenarios to test the recommendation engine. Copy the values into the sidebar form.

    **Scenario A — High-Risk SLA Breach:**
    - Request Type: Expedited | Channel: Fax | Service: Post-Acute / SNF
    - Provider Risk: High-Risk | Incomplete Rate: 0.45 | Docs: ❌ Incomplete
    - Auto-Eligible: ❌ | Clinical Review: ✅ | Prior Denial: ✅ | Cost: $28,000

    **Scenario B — Fast-Track:**
    - Request Type: Standard | Channel: Electronic | Service: Imaging / Radiology
    - Provider Risk: Low-Risk | Incomplete Rate: 0.05 | Docs: ✅ Complete
    - Auto-Eligible: ✅ | Clinical Review: ❌ | Prior Denial: ❌ | Cost: $1,200

    **Scenario C — Documentation Follow-Up:**
    - Request Type: Standard | Channel: Portal | Service: Outpatient Procedures
    - Provider Risk: Moderate-Risk | Incomplete Rate: 0.38 | Docs: ❌ Incomplete
    - Auto-Eligible: ❌ | Clinical Review: ❌ | Prior Denial: ❌ | Cost: $4,500

    **Scenario D — Senior Review Before Denial:**
    - Request Type: Standard | Channel: Electronic | Service: Surgical
    - Network: Out-of-Network | Prior Denial: ✅ | Docs: ✅ Complete
    - Clinical Review: ✅ | Cost: $22,000 | Provider Risk: High-Risk
    """)


# ── Footer ───────────────────────────────────────────────────────────────────
st.markdown("---")
st.caption(
    "Prior Authorization Intelligence System | Phase 6 | Portfolio Project | "
    "Raj Nandani | nandaniraj1509@gmail.com | "
    "Synthetic data only — no PHI — no real payer records | "
    "Model does not approve or deny care"
)
