"""
recommendation_rules.py
Prior Authorization Intelligence System (PAIS) — Phase 6

Rule-based recommendation engine. Takes model risk scores and input features,
returns structured workflow recommendations for operations coordinators.

FRAMING:
- This module does NOT approve or deny care.
- All outputs are workflow prioritization suggestions only.
- No clinical determination is made.
- All data must be synthetic — no real payer records.
"""

from dataclasses import dataclass, field
from typing import List, Optional


# Thresholds
DELAY_HIGH   = 0.193
DELAY_MED    = 0.12
DENIAL_HIGH  = 0.052
DENIAL_MED   = 0.035

INCOMPLETE_RATE_HIGH = 0.30
COST_HIGH            = 15000


@dataclass
class RecommendationResult:
    delay_risk_score:   float = 0.0
    denial_risk_score:  float = 0.0
    delay_risk_label:   str   = "Low"
    denial_risk_label:  str   = "Low"
    overall_risk_label: str   = "Low"

    is_fast_track:          bool = False
    sla_escalation:         bool = False
    doc_checklist_required: bool = False
    provider_outreach:      bool = False
    senior_review:          bool = False
    convert_channel:        bool = False
    clinical_route:         bool = False
    doc_followup:           bool = False

    primary_action:     str         = ""
    actions:            List[str]   = field(default_factory=list)
    sla_note:           str         = ""
    top_risk_drivers:   List[str]   = field(default_factory=list)
    rules_fired:        List[str]   = field(default_factory=list)


def classify_risk(score: float, high_thresh: float, med_thresh: float) -> str:
    if score >= high_thresh:
        return "High"
    elif score >= med_thresh:
        return "Moderate"
    else:
        return "Low"


def get_risk_color(label: str) -> str:
    return {"High": "#C0392B", "Moderate": "#F39C12", "Low": "#27AE60"}.get(label, "#666666")


def compute_top_drivers(inputs: dict, denial_coef: dict, delay_score: float, denial_score: float) -> List[str]:
    drivers = []

    if not inputs.get('documentation_complete', True):
        drivers.append("Documentation incomplete — primary driver of both delay and denial risk")

    if not inputs.get('auto_eligible', False):
        drivers.append("Not auto-eligible — requires clinical review queue routing")
    else:
        drivers.append("Auto-eligible — lowest delay/denial risk pathway")

    if inputs.get('clinical_review_required', False):
        drivers.append("Clinical review required — adds 1-3 days processing time")

    ch = inputs.get('submission_channel', '')
    if ch in ('Fax', 'Phone'):
        drivers.append(f"{ch} submission — manual re-keying adds ~25% processing delay")

    inc_rate = inputs.get('avg_incomplete_submission_rate', 0)
    if inc_rate >= INCOMPLETE_RATE_HIGH:
        drivers.append(f"Provider incomplete submission rate: {inc_rate:.0%} — above 30% threshold")
    elif inc_rate >= 0.15:
        drivers.append(f"Provider incomplete submission rate: {inc_rate:.0%} — elevated")

    if inputs.get('request_type') == 'Standard' and delay_score >= DELAY_HIGH:
        drivers.append("Standard request (7-day SLA) — at risk of breach")
    elif inputs.get('request_type') == 'Expedited' and delay_score >= DELAY_HIGH:
        drivers.append("Expedited request (72-hr SLA) — SLA breach imminent")

    if inputs.get('previous_denial_history', False):
        drivers.append("Member has prior PA denial history — elevated friction pattern")

    if inputs.get('network_status', '') == 'Out-of-Network':
        drivers.append("Out-of-Network provider — ~1.8x denial rate vs in-network")

    cost = inputs.get('estimated_cost', 0)
    if cost >= COST_HIGH:
        drivers.append(f"High-cost service (${cost:,.0f}) — likely triggers additional clinical review")

    high_denial_cats = {'Post-Acute / SNF', 'Outpatient Procedures', 'Surgical', 'Durable Medical Equipment'}
    svc = inputs.get('service_category', '')
    if svc in high_denial_cats:
        drivers.append(f"Service category '{svc}' — elevated historical denial rate")

    return drivers[:5]


def apply_rules(inputs: dict, delay_score: float, denial_score: float,
                denial_coef: Optional[dict] = None) -> RecommendationResult:
    """
    Apply all 8 recommendation rules and return structured result.
    This function does NOT approve or deny care.
    All outputs are workflow prioritization recommendations only.
    """
    result = RecommendationResult(
        delay_risk_score  = delay_score,
        denial_risk_score = denial_score,
        delay_risk_label  = classify_risk(delay_score,  DELAY_HIGH,  DELAY_MED),
        denial_risk_label = classify_risk(denial_score, DENIAL_HIGH, DENIAL_MED),
    )

    risk_levels = {'High': 2, 'Moderate': 1, 'Low': 0}
    overall_level = max(risk_levels[result.delay_risk_label],
                        risk_levels[result.denial_risk_label])
    result.overall_risk_label = ['Low', 'Moderate', 'High'][overall_level]

    doc_complete    = inputs.get('documentation_complete', True)
    auto_eligible   = inputs.get('auto_eligible', False)
    request_type    = inputs.get('request_type', 'Standard')
    channel         = inputs.get('submission_channel', 'Electronic')
    clinical_req    = inputs.get('clinical_review_required', False)
    inc_rate        = inputs.get('avg_incomplete_submission_rate', 0.0)
    cost            = inputs.get('estimated_cost', 0)
    prev_denial     = inputs.get('previous_denial_history', False)

    actions = []
    rules_fired = []

    # R1: High delay + incomplete docs
    if delay_score >= DELAY_HIGH and not doc_complete:
        result.doc_checklist_required = True
        result.sla_escalation = True
        actions.append("REQUEST DOCUMENTATION: Send documentation checklist to provider — incomplete docs are the #1 delay driver")
        actions.append("PRIORITY ESCALATION: Move to Priority Review Queue — high delay risk with documentation gap")
        rules_fired.append("R1: High delay + incomplete docs")

    # R2: High denial + incomplete docs
    if denial_score >= DENIAL_HIGH and not doc_complete:
        result.doc_followup = True
        result.doc_checklist_required = True
        actions.append("DOCUMENTATION FOLLOW-UP: Contact provider for documentation before initial determination")
        rules_fired.append("R2: High denial + incomplete docs")

    # R3: High delay + expedited
    if delay_score >= DELAY_HIGH and request_type == 'Expedited':
        result.sla_escalation = True
        actions.append("SLA ESCALATION: Expedited request at high delay risk — 72-hour SLA exposure. Route to Senior UM Coordinator immediately")
        rules_fired.append("R3: High delay + expedited SLA")

    # R4: Low delay + auto-eligible + complete docs -> fast-track
    # Operational rationale: auto_eligible is a payer-designated classification for
    # automated adjudication. When delay risk is low and documentation is complete,
    # the request qualifies for fast-track administrative processing regardless of
    # the ML denial score, which reflects population-level denial rates by category.
    if delay_score < DELAY_MED and auto_eligible and doc_complete:
        result.is_fast_track = True
        actions.append("FAST-TRACK CANDIDATE: Low delay risk, auto-eligible, documentation complete — route to automated adjudication queue for administrative processing")
        rules_fired.append("R4: Fast-track — low delay + auto-eligible + complete docs")

    # R5: High provider incomplete rate
    if inc_rate >= INCOMPLETE_RATE_HIGH:
        result.provider_outreach = True
        actions.append(f"PROVIDER OUTREACH: Provider incomplete submission rate is {inc_rate:.0%} — above 30% threshold. Schedule documentation education session")
        rules_fired.append("R5: High provider incomplete submission rate")
    elif inc_rate >= 0.20 and denial_score >= DENIAL_HIGH:
        result.provider_outreach = True
        actions.append(f"PROVIDER EDUCATION: Elevated incomplete rate ({inc_rate:.0%}) + high denial risk — proactive outreach recommended")
        rules_fired.append("R5b: Elevated incomplete rate + high denial")

    # R6: High denial + prior denial history
    if denial_score >= DENIAL_HIGH and prev_denial:
        result.senior_review = True
        actions.append("SENIOR REVIEW: Prior denial history + high current denial risk — route to Medical Director for review before issuing denial")
        rules_fired.append("R6: High denial + prior denial history")

    # R7: High cost + clinical review
    if cost >= COST_HIGH and clinical_req:
        result.clinical_route = True
        actions.append(f"CLINICAL ROUTE: High-cost service (${cost:,.0f}) requiring clinical review — assign to Senior Clinical Reviewer")
        rules_fired.append("R7: High cost + clinical review required")
    elif cost >= COST_HIGH and denial_score >= DENIAL_HIGH:
        result.clinical_route = True
        actions.append(f"CLINICAL ATTENTION: High-cost service (${cost:,.0f}) with elevated denial risk — flag for clinical review before determination")
        rules_fired.append("R7b: High cost + high denial risk")

    # R8: Fax/phone + high risk
    if channel in ('Fax', 'Phone') and (delay_score >= DELAY_HIGH or denial_score >= DENIAL_HIGH):
        result.convert_channel = True
        actions.append(f"WORKFLOW IMPROVEMENT: {channel} submission with high risk — recommend Electronic/Portal submission. Estimated 25% reduction in processing time")
        rules_fired.append("R8: Fax/phone + high risk")

    # Default
    if not actions:
        if result.overall_risk_label == 'Low':
            actions.append("STANDARD PROCESSING: Low risk — process through standard review queue")
        else:
            actions.append("MONITOR: Moderate risk — assign to standard queue with coordinator awareness flag")

    # SLA note
    sla_label = "72-hour (Expedited)" if request_type == 'Expedited' else "7-day (Standard)"
    if result.delay_risk_label == 'High':
        result.sla_note = (
            f"SLA RISK: {sla_label} CMS-0057-F limit. "
            f"Delay risk score {delay_score:.3f} exceeds threshold {DELAY_HIGH}. "
            f"Immediate coordinator assignment recommended."
        )
    elif result.delay_risk_label == 'Moderate':
        result.sla_note = (
            f"SLA WATCH: {sla_label} CMS-0057-F limit. "
            f"Delay risk score {delay_score:.3f} is in moderate range."
        )
    else:
        result.sla_note = (
            f"SLA ON TRACK: {sla_label} CMS-0057-F limit. "
            f"Delay risk score {delay_score:.3f} below threshold. Standard processing timeline expected."
        )

    result.primary_action = actions[0] if actions else "Standard processing"
    result.actions        = actions
    result.rules_fired    = rules_fired

    result.top_risk_drivers = compute_top_drivers(
        inputs, denial_coef or {}, delay_score, denial_score
    )

    return result


DISCLAIMER = (
    "Responsible Use Disclaimer\n\n"
    "This tool is an operational workflow decision-support system for prior authorization "
    "administrative operations. It does not approve or deny care. It does not replace "
    "clinical judgment. All recommendations are for workflow prioritization, documentation "
    "follow-up, SLA monitoring, and operational escalation only.\n\n"
    "Model outputs are risk scores, not calibrated probabilities. All data used to train "
    "these models is synthetic and benchmark-calibrated (no PHI, no real payer records). "
    "Results reflect methodology demonstration on synthetic data only. Final determinations "
    "remain with qualified reviewers and medical directors. This tool must not be used as "
    "the sole basis for any coverage determination.\n\n"
    "CMS-0057-F Note: CMS requires Medicare Advantage organizations to meet PA turnaround "
    "time requirements (7 days standard, 72 hours expedited). This tool supports SLA "
    "compliance monitoring — it does not constitute compliance itself.\n\n"
    "Prior Authorization Intelligence System | Phase 6 | Portfolio Project\n"
    "Raj Nandani | nandaniraj1509@gmail.com"
)
