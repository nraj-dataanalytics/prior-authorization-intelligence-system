"""
streamlit_app.py
Prior Authorization Intelligence System (PAIS) — Phase 6
Recommendation Engine, What-If Simulator & Decision-Support Tool

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
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from recommendation_rules import apply_rules, DISCLAIMER, get_risk_color

# ── Page config ─────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="PAIS — Prior Authorization Decision Support",
    page_icon="🏥",
    layout="wide",
    initial_sidebar_state="expanded"
)

PRIMARY  = "#0057A8"
SUCCESS  = "#27AE60"
WARNING  = "#F39C12"
DANGER   = "#C0392B"

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
                  padding: 12px 16px; border-radius: 6px; margin: 6px 0; font-size: 0.95rem;
                  color: #2C3E50; }
    .disclaimer-box { background: #FFF3CD; border: 1px solid #F39C12;
                      border-radius: 8px; padding: 16px; margin-top: 16px;
                      color: #2C3E50; }
    .fast-track-badge { background: #D5F5E3; border: 2px solid #27AE60;
                        border-radius: 20px; padding: 6px 16px; color: #1E8449;
                        font-weight: 700; display: inline-block; }
    .scenario-card { background: #FFFFFF; border: 1px solid #D5D8DC;
                     border-radius: 8px; padding: 14px; margin: 8px 0;
                     color: #2C3E50; }
    .whatif-box { background: #EBF5FB; border: 1px solid #2E86C1;
                  border-radius: 8px; padding: 14px; margin: 8px 0;
                  color: #2C3E50; }
    .compare-card { background: #FFFFFF; border: 1px solid #D5D8DC;
                    border-radius: 8px; padding: 14px; text-align: center;
                    color: #2C3E50; }
    .delta-improve { color: #1E8449; font-weight: 700; font-size: 1.1rem; }
    .delta-worse   { color: #C0392B; font-weight: 700; font-size: 1.1rem; }
    .delta-neutral { color: #7F8C8D; font-weight: 700; font-size: 1.1rem; }
</style>
""", unsafe_allow_html=True)


# ── Model loading ────────────────────────────────────────────────────────────
@st.cache_resource
def load_models():
    base      = os.path.dirname(os.path.abspath(__file__))
    model_dir = os.path.join(base, "models")
    with open(os.path.join(model_dir, "delay_model.pkl"),  "rb") as f: dm  = pickle.load(f)
    with open(os.path.join(model_dir, "denial_model.pkl"), "rb") as f: denm = pickle.load(f)
    with open(os.path.join(model_dir, "feature_metadata.json"))   as f: m   = json.load(f)
    return dm, denm, m

@st.cache_data
def load_model_docs():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    metrics  = pd.read_csv(os.path.join(root, "models", "model_metrics.csv"))
    feat_imp = pd.read_csv(os.path.join(root, "models", "feature_importance.csv"))
    return metrics, feat_imp

delay_model, denial_model, meta = load_models()
model_metrics_df, feat_imp_df   = load_model_docs()

FEATS     = meta["all_features"]
BOOL      = meta["bool_features"]
DROPDOWNS = meta["dropout_values"]   # single source of truth for all categorical options
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VISUAL_DIR   = os.path.join(PROJECT_ROOT, "assets", "model_visuals")


# ── Core functions ───────────────────────────────────────────────────────────
def predict(inputs: dict) -> tuple:
    row = {f: inputs.get(f, 0) for f in FEATS}
    df  = pd.DataFrame([row])
    for c in BOOL:
        df[c] = df[c].astype(int)
    return (
        float(delay_model.predict_proba(df)[0, 1]),
        float(denial_model.predict_proba(df)[0, 1]),
    )

def risk_card(title, score, label, threshold):
    color = get_risk_color(label)
    pct   = min(int(score / max(threshold * 2, 0.001) * 100), 100)
    return f"""
    <div class="risk-card" style="border-color:{color};background:#FFF">
        <div style="font-size:0.85rem;color:#666;font-weight:600;margin-bottom:4px">{title}</div>
        <div style="font-size:2.2rem;font-weight:800;color:{color}">{score:.3f}</div>
        <div style="font-size:1rem;font-weight:700;color:{color};margin:4px 0">{label} Risk</div>
        <div style="background:#E8EAED;border-radius:4px;height:8px;margin-top:8px">
            <div style="background:{color};width:{pct}%;height:8px;border-radius:4px"></div>
        </div>
        <div style="font-size:0.75rem;color:#888;margin-top:4px">Threshold: {threshold}</div>
    </div>"""

def delta_html(before, after):
    d   = after - before
    pct = (d / before * 100) if before > 0.001 else 0
    if d < -0.001:
        return f'<span class="delta-improve">▼ {abs(d):.3f} ({abs(pct):.0f}% lower)</span>'
    elif d > 0.001:
        return f'<span class="delta-worse">▲ {abs(d):.3f} ({abs(pct):.0f}% higher)</span>'
    return '<span class="delta-neutral">— No change</span>'


# ══════════════════════════════════════════════════════════════════════════════
# HEADER
# ══════════════════════════════════════════════════════════════════════════════
st.markdown(f"""
<div style="background:{PRIMARY};padding:20px 28px;border-radius:10px;margin-bottom:20px">
  <h1 style="color:white;margin:0;font-size:1.6rem">🏥 Prior Authorization Intelligence System</h1>
  <p style="color:#BDC3C7;margin:6px 0 0 0;font-size:0.95rem">
    Workflow Decision-Support Tool &nbsp;|&nbsp; Recommendation Engine &amp; What-If Simulator
    &nbsp;|&nbsp; <em>Portfolio Project — Synthetic Data Only</em>
  </p>
</div>
""", unsafe_allow_html=True)

with st.expander("📖 About this tool", expanded=False):
    st.markdown("""
**What this tool does:**
Predicts PA **delay risk** and **denial/documentation risk** via pre-trained ML models,
applies rule-based workflow recommendations, and simulates the operational impact of
documentation and channel improvements through the What-If Simulator.

**What this tool does NOT do:**
- ❌ Does not approve or deny care
- ❌ Does not replace clinical judgment
- ❌ Does not use real patient data (trained on synthetic benchmark-calibrated data)
- ❌ Does not guarantee CMS compliance

**CMS-0057-F alignment:** SLA requirements — 7 calendar days (Standard), 72 hours / 3 calendar days (Expedited).

| Model | ROC-AUC | PR-AUC | Threshold |
|-------|---------|--------|-----------|
| Delay Risk (GBM) | 0.799 | 0.440 | 0.193 (recall 0.75) |
| Denial Risk (LR) | 0.713 | 0.131 | 0.052 (recall 0.71) |
""")


# ══════════════════════════════════════════════════════════════════════════════
# SIDEBAR — dropdown values sourced directly from feature_metadata.json
# ══════════════════════════════════════════════════════════════════════════════
st.sidebar.markdown("<div class='section-header'>📝 PA Request Details</div>", unsafe_allow_html=True)
st.sidebar.caption("Enter pre-decision attributes. No outcome fields included.")

with st.sidebar:
    st.markdown("**Request Attributes**")
    request_type = st.selectbox("Request Type", DROPDOWNS["request_type"],
        help="CMS-0057-F: Standard = 7-day SLA, Expedited = 72-hour SLA")
    submission_channel = st.selectbox("Submission Channel", DROPDOWNS["submission_channel"],
        help="Fax/Phone add ~25% processing delay vs Electronic")

    sc_opts = DROPDOWNS["service_category"]
    service_category = st.selectbox("Service Category", sc_opts,
        index=sc_opts.index("Advanced Imaging"),
        help="Primary service category — key predictor of denial risk")

    pg_opts = DROPDOWNS["procedure_group"]
    procedure_group = st.selectbox("Procedure Group", pg_opts,
        index=pg_opts.index("MRI Brain/Spine"),
        help="Specific procedure within service category")

    estimated_cost = st.number_input("Estimated Cost ($)", min_value=0, max_value=500000,
        value=5000, step=500)

    st.markdown("**Provider Profile**")
    pt_opts = DROPDOWNS["provider_type"]
    provider_type = st.selectbox("Provider Type", pt_opts,
        index=pt_opts.index("Specialist"))
    network_status = st.selectbox("Network Status", DROPDOWNS["network_status"],
        help="OON providers have ~1.8x higher denial rate")
    provider_risk_segment = st.selectbox("Provider Risk Segment", DROPDOWNS["provider_risk_segment"])
    region = st.selectbox("Region", DROPDOWNS["region"])
    avg_incomplete_rate = st.slider("Provider Avg Incomplete Rate",
        min_value=0.0, max_value=1.0, value=0.15, step=0.01, format="%.0f%%")
    avg_response_days = st.number_input("Provider Avg Response Time (days)",
        min_value=0.0, max_value=30.0, value=3.0, step=0.5)

    st.markdown("**Member Profile**")
    plan_type  = st.selectbox("Plan Type", DROPDOWNS["plan_type"])
    ab_opts    = DROPDOWNS["age_band"]
    age_band   = st.selectbox("Age Band", ab_opts, index=ab_opts.index("65-74"))
    rl_opts    = DROPDOWNS["risk_level"]
    risk_level = st.selectbox("Member Risk Level", rl_opts)

    st.markdown("**Clinical Flags**")
    documentation_complete   = st.checkbox("Documentation Complete", value=True)
    auto_eligible            = st.checkbox("Auto-Eligible", value=False)
    clinical_review_required = st.checkbox("Clinical Review Required", value=False)
    previous_denial_history  = st.checkbox("Member Has Prior Denial History", value=False)

    st.markdown("---")
    run_button = st.button("🔍 Analyze This Request", use_container_width=True)


# ── Default / landing page ───────────────────────────────────────────────────
if not run_button:
    st.info("👈 Fill in the PA request details in the sidebar and click **'Analyze This Request'**.")
    st.markdown("---")
    st.markdown("<div class='section-header'>💡 Example Scenarios</div>", unsafe_allow_html=True)
    scenarios = [
        {"title": "🚨 High-Risk: Fax + Incomplete Docs",
         "desc": "Specialist submits Post-Acute / SNF via Fax. Documentation incomplete. Expedited.",
         "expected": "SLA escalation + doc checklist + channel conversion"},
        {"title": "✅ Fast-Track Candidate",
         "desc": "Auto-eligible Advanced Imaging, complete docs, low-risk, Electronic channel.",
         "expected": "Fast-track badge + standard administrative processing"},
        {"title": "⚠ Denial Risk: OON + Prior Denial",
         "desc": "OON Specialist, prior denial history, high-cost Surgical Procedures.",
         "expected": "Senior review + clinical route + provider outreach"},
        {"title": "📋 Documentation Follow-Up",
         "desc": "Provider with 38% incomplete rate. Incomplete docs on current submission.",
         "expected": "Documentation follow-up + provider education outreach"},
    ]
    cols = st.columns(2)
    for i, s in enumerate(scenarios):
        with cols[i % 2]:
            st.markdown(f"""
            <div class="scenario-card">
                <strong style="color:#2C3E50">{s['title']}</strong><br>
                <span style="font-size:0.9rem;color:#2C3E50">{s['desc']}</span><br>
                <span style="font-size:0.82rem;color:#0057A8;font-style:italic">Expected: {s['expected']}</span>
            </div>""", unsafe_allow_html=True)
    st.markdown("---")
    st.markdown(f"<div class='disclaimer-box'>{DISCLAIMER}</div>", unsafe_allow_html=True)
    st.stop()


# ── Build inputs + run models ────────────────────────────────────────────────
inputs = {
    "request_type": request_type,
    "submission_channel": submission_channel,
    "service_category": service_category,
    "procedure_group": procedure_group,
    "provider_type": provider_type,
    "network_status": network_status,
    "provider_risk_segment": provider_risk_segment,
    "plan_type": plan_type,
    "age_band": age_band,
    "risk_level": risk_level,
    "region": region,
    "submitted_day_of_week": "Monday",
    "documentation_complete":         int(documentation_complete),
    "auto_eligible":                  int(auto_eligible),
    "clinical_review_required":       int(clinical_review_required),
    "previous_denial_history":        int(previous_denial_history),
    "estimated_cost":                 float(estimated_cost),
    "avg_incomplete_submission_rate": float(avg_incomplete_rate),
    "avg_response_time_days":         float(avg_response_days),
    "chronic_condition_count":        2,
    "member_tenure_months":           24,
}

with st.spinner("Running risk models..."):
    delay_score, denial_score = predict(inputs)
    rec = apply_rules(inputs, delay_score, denial_score,
                      denial_coef=meta.get("denial_lr_coefficients", {}))


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 1 — RISK SCORE CARDS
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("<div class='section-header'>📊 Risk Assessment</div>", unsafe_allow_html=True)

if rec.is_fast_track:
    st.markdown(
        "<div class='fast-track-badge'>✅ FAST-TRACK CANDIDATE — Low risk across all dimensions</div>",
        unsafe_allow_html=True)
    st.markdown("")

c1, c2, c3 = st.columns(3)
with c1:
    st.markdown(risk_card("Delay Risk Score", delay_score, rec.delay_risk_label, meta["delay_threshold"]),
                unsafe_allow_html=True)
with c2:
    st.markdown(risk_card("Denial / Doc Risk Score", denial_score, rec.denial_risk_label, meta["denial_threshold"]),
                unsafe_allow_html=True)
with c3:
    oc = get_risk_color(rec.overall_risk_label)
    sla = "72 hrs" if request_type == "Expedited" else "7 days"
    st.markdown(f"""
    <div class="risk-card" style="border-color:{oc}">
        <div style="font-size:0.85rem;color:#666;font-weight:600;margin-bottom:4px">Overall Risk</div>
        <div style="font-size:2.2rem;font-weight:800;color:{oc}">{rec.overall_risk_label}</div>
        <div style="font-size:0.9rem;color:#888;margin-top:8px">SLA Limit: {sla}</div>
        <div style="font-size:0.85rem;color:#888">Rules applied: {len(rec.rules_fired)}</div>
    </div>""", unsafe_allow_html=True)


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 2 — TOP RISK DRIVERS
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("---")
st.markdown("<div class='section-header'>🔍 Top Risk Drivers</div>", unsafe_allow_html=True)
st.caption("Based on model feature importance (SHAP / LR coefficients) and current input values.")
if rec.top_risk_drivers:
    for d in rec.top_risk_drivers:
        st.markdown(f"- {d}")
else:
    st.success("No major risk drivers identified — low risk profile.")


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 3 — RECOMMENDED WORKFLOW ACTIONS
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("---")
st.markdown("<div class='section-header'>⚡ Recommended Workflow Actions</div>", unsafe_allow_html=True)
st.caption("Rule-based recommendations for operations coordinators. Not clinical determinations.")
if rec.actions:
    for i, action in enumerate(rec.actions):
        border = PRIMARY if i == 0 else "#D5D8DC"
        st.markdown(f'<div class="action-box" style="border-left-color:{border}">{action}</div>',
                    unsafe_allow_html=True)
    if rec.rules_fired:
        with st.expander("📋 Rules applied (for transparency)", expanded=False):
            for r in rec.rules_fired:
                st.markdown(f"- `{r}`")


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 4 — SLA & COMPLIANCE STATUS
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("---")
st.markdown("<div class='section-header'>📅 SLA & CMS Compliance Status</div>", unsafe_allow_html=True)
if "SLA RISK" in rec.sla_note or "⚠" in rec.sla_note:
    st.warning(rec.sla_note)
elif "WATCH" in rec.sla_note:
    st.info(rec.sla_note)
else:
    st.success(rec.sla_note)

ma, mb, mc = st.columns(3)
ma.metric("Delay Risk Score",  f"{delay_score:.3f}",  f"Threshold: {meta['delay_threshold']}")
mb.metric("Denial Risk Score", f"{denial_score:.3f}", f"Threshold: {meta['denial_threshold']}")
mc.metric("SLA Window", "72 hours" if request_type == "Expedited" else "7 days", "CMS-0057-F")

flags = {
    "🚀 SLA Escalation":        rec.sla_escalation,
    "📋 Documentation Needed":  rec.doc_checklist_required,
    "✅ Fast-Track":             rec.is_fast_track,
    "📣 Provider Outreach":      rec.provider_outreach,
    "👨‍⚕️ Senior Review":         rec.senior_review,
    "🏥 Clinical Route":         rec.clinical_route,
    "🖥 Convert Channel":        rec.convert_channel,
    "📞 Doc Follow-up":          rec.doc_followup,
}
active = {k: v for k, v in flags.items() if v}
if active:
    st.markdown("**Active workflow flags:**")
    fcols = st.columns(min(len(active), 4))
    for i, lbl in enumerate(active):
        with fcols[i % 4]:
            st.success(lbl)


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 5 — WHAT-IF RISK REDUCTION SIMULATOR
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("---")
st.markdown("<div class='section-header'>🔬 What-If Risk Reduction Simulator</div>",
            unsafe_allow_html=True)
st.caption(
    "Simulate operational improvements before determination. "
    "This is NOT a clinical decision tool — it models workflow changes only.")

st.markdown(
    "<div class='disclaimer-box' style='margin-bottom:12px'>"
    "⚕️ <strong>Operational triage only.</strong> This simulator models the estimated risk "
    "impact of documentation completion, channel changes, and auto-eligibility. "
    "It does not constitute approval, denial, or any clinical coverage determination. "
    "Final determinations remain with qualified reviewers and medical directors."
    "</div>", unsafe_allow_html=True)

wi_left, wi_right = st.columns([1, 2])

with wi_left:
    st.markdown("**Simulate Operational Interventions:**")
    wi_doc = st.checkbox("📄 Documentation Complete",
        value=bool(documentation_complete), key="wi_doc",
        help="Simulate completing documentation before determination")

    ch_opts = DROPDOWNS["submission_channel"]
    wi_channel = st.selectbox("📤 Submission Channel", ch_opts,
        index=ch_opts.index(submission_channel) if submission_channel in ch_opts else 0,
        key="wi_channel", help="Simulate switching to Electronic/Portal")

    wi_auto = st.checkbox("⚡ Auto-Eligible",
        value=bool(auto_eligible), key="wi_auto",
        help="Simulate flagging for automated adjudication")

    wi_inc = st.slider("📊 Provider Incomplete Rate (improved)",
        min_value=0.0, max_value=1.0, value=float(avg_incomplete_rate),
        step=0.01, format="%.0f%%", key="wi_inc",
        help="Simulate provider improving submission quality after outreach")

# Build modified inputs and run prediction
modified_inputs = {
    **inputs,
    "documentation_complete":         int(wi_doc),
    "submission_channel":             wi_channel,
    "auto_eligible":                  int(wi_auto),
    "avg_incomplete_submission_rate": float(wi_inc),
}
wi_delay, wi_denial = predict(modified_inputs)
wi_rec = apply_rules(modified_inputs, wi_delay, wi_denial,
                     denial_coef=meta.get("denial_lr_coefficients", {}))

changed = []
if wi_doc  != bool(documentation_complete): changed.append(("documentation_complete",
    f"Documentation: {'Incomplete' if not documentation_complete else 'Complete'} → {'Complete' if wi_doc else 'Incomplete'}"))
if wi_channel != submission_channel: changed.append(("submission_channel",
    f"Channel: {submission_channel} → {wi_channel}"))
if wi_auto != bool(auto_eligible): changed.append(("auto_eligible",
    f"Auto-Eligible: {'Off' if not auto_eligible else 'On'} → {'On' if wi_auto else 'Off'}"))
if abs(wi_inc - avg_incomplete_rate) > 0.005: changed.append(("avg_incomplete_submission_rate",
    f"Provider incomplete rate: {avg_incomplete_rate:.0%} → {wi_inc:.0%}"))

rules_eliminated = [r for r in rec.rules_fired    if r not in wi_rec.rules_fired]
rules_new        = [r for r in wi_rec.rules_fired  if r not in rec.rules_fired]

with wi_right:
    st.markdown("**Before vs. After Comparison:**")
    bc1, bc2, bc3 = st.columns(3)
    with bc1:
        st.markdown(f"""
        <div class="compare-card">
            <div style="font-size:0.8rem;color:#2C3E50;font-weight:600">BEFORE</div>
            <div style="font-size:1.5rem;font-weight:800;color:{get_risk_color(rec.delay_risk_label)};margin-top:4px">{delay_score:.3f}</div>
            <div style="font-size:0.82rem;color:#2C3E50">Delay — {rec.delay_risk_label}</div>
            <hr style="margin:8px 0">
            <div style="font-size:1.5rem;font-weight:800;color:{get_risk_color(rec.denial_risk_label)}">{denial_score:.3f}</div>
            <div style="font-size:0.82rem;color:#2C3E50">Denial — {rec.denial_risk_label}</div>
            <hr style="margin:8px 0">
            <div style="font-size:0.82rem;color:#888">{len(rec.rules_fired)} rule(s) active</div>
        </div>""", unsafe_allow_html=True)
    with bc2:
        st.markdown(f"""
        <div class="compare-card" style="background:#F8F9FA">
            <div style="font-size:0.8rem;color:#2C3E50;font-weight:600">CHANGE</div>
            <div style="margin-top:10px">{delta_html(delay_score, wi_delay)}</div>
            <div style="font-size:0.78rem;color:#2C3E50;margin-bottom:10px">Delay risk</div>
            <hr style="margin:8px 0">
            <div>{delta_html(denial_score, wi_denial)}</div>
            <div style="font-size:0.78rem;color:#2C3E50">Denial risk</div>
            <hr style="margin:8px 0">
            <div style="font-size:0.82rem;color:#888">{len(rules_eliminated)} rule(s) eliminated</div>
        </div>""", unsafe_allow_html=True)
    with bc3:
        st.markdown(f"""
        <div class="compare-card">
            <div style="font-size:0.8rem;color:#2C3E50;font-weight:600">AFTER</div>
            <div style="font-size:1.5rem;font-weight:800;color:{get_risk_color(wi_rec.delay_risk_label)};margin-top:4px">{wi_delay:.3f}</div>
            <div style="font-size:0.82rem;color:#2C3E50">Delay — {wi_rec.delay_risk_label}</div>
            <hr style="margin:8px 0">
            <div style="font-size:1.5rem;font-weight:800;color:{get_risk_color(wi_rec.denial_risk_label)}">{wi_denial:.3f}</div>
            <div style="font-size:0.82rem;color:#2C3E50">Denial — {wi_rec.denial_risk_label}</div>
            <hr style="margin:8px 0">
            <div style="font-size:0.82rem;color:#888">{len(wi_rec.rules_fired)} rule(s) active</div>
        </div>""", unsafe_allow_html=True)

    st.markdown("")
    if not changed:
        st.info("Adjust the intervention controls on the left to simulate operational improvements.")
    else:
        st.markdown("**Interventions simulated:**")
        for _, label in changed:
            st.markdown(f"  ✓ {label}")

        if rules_eliminated:
            st.success(f"**{len(rules_eliminated)} escalation rule(s) eliminated:**")
            for r in rules_eliminated:
                st.markdown(f"  ✅ `{r}` — no longer triggered")
        if rules_new:
            st.warning(f"**{len(rules_new)} new rule(s) activated:**")
            for r in rules_new:
                st.markdown(f"  ⚠ `{r}`")

        dr = delay_score - wi_delay
        denr = denial_score - wi_denial
        parts = []
        if dr > 0.005:   parts.append(f"delay risk ▼ {dr:.3f} ({dr/max(delay_score,0.001)*100:.0f}%)")
        if denr > 0.005: parts.append(f"denial risk ▼ {denr:.3f} ({denr/max(denial_score,0.001)*100:.0f}%)")
        if parts:
            st.markdown(
                f"<div class='whatif-box'>💡 <strong>Operational Impact:</strong> "
                f"These workflow changes reduce {' and '.join(parts)}, "
                f"eliminating {len(rules_eliminated)} escalation trigger(s).</div>",
                unsafe_allow_html=True)
        elif changed:
            st.markdown(
                "<div class='whatif-box'>📊 Scores updated. Minimal additional impact on risk "
                "beyond the current profile — this request's risk is driven by other factors.</div>",
                unsafe_allow_html=True)


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 6 — MODEL PERFORMANCE & EXPLAINABILITY (expandable)
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("---")
with st.expander("📊 Model Performance & Explainability", expanded=False):
    st.caption(
        "All metrics from held-out test split of synthetic, benchmark-calibrated data (25,000 rows). "
        "Performance on real payer data will differ. Outputs are risk scores, not calibrated probabilities.")

    st.markdown("**Summary Metrics**")
    display_cols = ["model", "target", "roc_auc", "pr_auc",
                    "recall_at_threshold", "precision_at_threshold", "threshold"]
    mask = model_metrics_df["illustrative"].fillna(False).astype(bool) == False
    tbl  = (model_metrics_df[mask][display_cols]
            .rename(columns={"model": "Algorithm", "target": "Target",
                             "roc_auc": "ROC-AUC", "pr_auc": "PR-AUC",
                             "recall_at_threshold": "Recall@Thresh",
                             "precision_at_threshold": "Precision@Thresh",
                             "threshold": "Threshold"})
            .reset_index(drop=True))
    st.dataframe(tbl, use_container_width=True)

    st.markdown("""
- **Delay model (GBM):** ROC-AUC 0.799 | 5-fold CV 0.813 ± 0.008
- **Denial model (LR):** ROC-AUC 0.713 | 5-fold CV 0.715 ± 0.009
- Thresholds tuned for recall ≥ 0.75 (delay) and ≥ 0.70 (denial)
""")

    st.markdown("**Feature Importances (SHAP mean |value|)**")
    t1, t2 = st.tabs(["Delay Risk Model (GBM)", "Denial Risk Model (LR)"])

    with t1:
        dfi = (feat_imp_df[feat_imp_df["target"] == "delayed_flag"]
               .nlargest(12, "importance").sort_values("importance"))
        fig, ax = plt.subplots(figsize=(7, 4))
        ax.barh(dfi["feature"], dfi["importance"], color="#0057A8", alpha=0.85)
        ax.set_xlabel("SHAP Mean |Value|", fontsize=9)
        ax.set_title("Top 12 Features — Delay Risk (GBM)", fontsize=10, fontweight="bold")
        ax.tick_params(labelsize=8)
        ax.xaxis.set_major_formatter(mticker.FormatStrFormatter("%.2f"))
        plt.tight_layout()
        st.pyplot(fig, use_container_width=True)
        plt.close(fig)

    with t2:
        denfi = (feat_imp_df[feat_imp_df["target"] == "denied_flag"]
                 .nlargest(12, "importance").sort_values("importance"))
        fig2, ax2 = plt.subplots(figsize=(7, 4))
        ax2.barh(denfi["feature"], denfi["importance"], color="#C0392B", alpha=0.85)
        ax2.set_xlabel("SHAP Mean |Value|", fontsize=9)
        ax2.set_title("Top 12 Features — Denial Risk (LR)", fontsize=10, fontweight="bold")
        ax2.tick_params(labelsize=8)
        ax2.xaxis.set_major_formatter(mticker.FormatStrFormatter("%.2f"))
        plt.tight_layout()
        st.pyplot(fig2, use_container_width=True)
        plt.close(fig2)

    st.markdown("**Precision-Recall & Calibration Curves**")
    ic1, ic2 = st.columns(2)
    for path, caption, col in [
        (os.path.join(VISUAL_DIR, "delay_pr_curve.png"),    "Delay Risk — PR Curve",       ic1),
        (os.path.join(VISUAL_DIR, "denial_pr_curve.png"),   "Denial Risk — PR Curve",      ic2),
    ]:
        if os.path.exists(path):
            with col:
                st.image(path, caption=caption, use_container_width=True)

    ic3, ic4 = st.columns(2)
    for path, caption, col in [
        (os.path.join(VISUAL_DIR, "cv_summary.png"),        "Cross-Validation Summary",    ic3),
        (os.path.join(VISUAL_DIR, "calibration_diagrams.png"), "Calibration Diagrams",     ic4),
    ]:
        if os.path.exists(path):
            with col:
                st.image(path, caption=caption, use_container_width=True)

    st.markdown("""
**Leakage exclusion:** Fields known only after PA determination (`decision`,
`decision_time_days` as feature, `denial_reason`, `final_outcome`,
`action_recommended_initial`, appeal fields, `pended_flag`, `reviewer_type`)
are excluded from all model inputs. See `models/model_leakage_audit.md`.
""")


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 7 — RESPONSIBLE-USE DISCLAIMER
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("---")
st.markdown("<div class='section-header'>⚖️ Responsible Use Disclaimer</div>",
            unsafe_allow_html=True)
st.markdown(f"<div class='disclaimer-box'>{DISCLAIMER}</div>", unsafe_allow_html=True)


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 8 — EXAMPLE SCENARIOS
# ══════════════════════════════════════════════════════════════════════════════
st.markdown("---")
with st.expander("💡 Test with pre-built example scenarios", expanded=False):
    st.markdown("""
**Scenario A — High-Risk SLA Breach** *(tests R1, R3, R8 + what-if: complete docs + switch to Electronic)*
- Request Type: Expedited | Channel: Fax | Service: Post-Acute / SNF | Procedure: Skilled Nursing Facility Stay
- Provider Type: Post-Acute Facility | Risk: High-Risk | Incomplete Rate: 45% | Docs: ❌ | Auto: ❌
- Clinical Review: ✅ | Prior Denial: ✅ | Cost: $28,000

**Scenario B — Fast-Track** *(tests R4)*
- Request Type: Standard | Channel: Electronic | Service: Advanced Imaging | Procedure: MRI Brain/Spine
- Provider Type: Imaging Center | Risk: Low-Risk | Incomplete Rate: 5% | Docs: ✅ | Auto: ✅
- Clinical Review: ❌ | Prior Denial: ❌ | Cost: $1,200

**Scenario C — Documentation Follow-Up** *(tests R1, R2, R5 + what-if: complete docs)*
- Request Type: Standard | Channel: Portal | Service: Outpatient Procedures | Procedure: Endoscopy / Colonoscopy
- Provider Type: Surgery Center | Risk: Moderate-Risk | Incomplete Rate: 38% | Docs: ❌ | Auto: ❌
- Clinical Review: ❌ | Prior Denial: ❌ | Cost: $4,500

**Scenario D — Senior Review Before Denial** *(tests R6, R7)*
- Request Type: Standard | Channel: Electronic | Service: Surgical Procedures | Procedure: Spine Surgery
- Network: Out-of-Network | Provider Type: Specialist | Risk: High-Risk
- Clinical Review: ✅ | Prior Denial: ✅ | Cost: $22,000
""")


# ── Footer ───────────────────────────────────────────────────────────────────
st.markdown("---")
st.caption(
    "Prior Authorization Intelligence System | Phase 6 | Portfolio Project | "
    "Raj Nandani | nandaniraj1509@gmail.com | "
    "Synthetic data only — no PHI — no real payer records | "
    "Model does not approve or deny care"
)
