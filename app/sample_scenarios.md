# Sample Scenarios
## Prior Authorization Intelligence System (PAIS) — Phase 6 App
**Generated: 2026-06-01 | Synthetic data only | No PHI**

---

These four scenarios demonstrate the full range of the recommendation engine's outputs.
Use them to test the Streamlit app or present in portfolio walkthroughs.

---

## Scenario A — 🚨 High-Risk SLA Escalation Case

**Business narrative:**
A High-Risk specialist submits an SNF admission request by Fax — the slowest channel —
with documentation missing. It is an Expedited request (72-hour SLA). The provider has a
45% historical incomplete submission rate. The member has a prior denial history. Cost is $28,000.

**Input values:**

| Field | Value |
|-------|-------|
| Request Type | Expedited |
| Submission Channel | Fax |
| Service Category | Post-Acute / SNF |
| Procedure Group | SNF Admission |
| Provider Type | SNF / Post-Acute |
| Network Status | In-Network |
| Provider Risk Segment | High-Risk |
| Region | Southeast |
| Plan Type | SNP |
| Age Band | 75-84 |
| Member Risk Level | High |
| Documentation Complete | ❌ No |
| Auto-Eligible | ❌ No |
| Clinical Review Required | ✅ Yes |
| Prior Denial History | ✅ Yes |
| Estimated Cost | $28,000 |
| Provider Incomplete Rate | 0.45 |
| Provider Avg Response Days | 4.5 |

**Expected model output:**
- Delay risk score: HIGH (above 0.193)
- Denial risk score: HIGH (above 0.052)
- Overall risk: HIGH

**Expected recommendations:**
- R1: Documentation checklist + priority escalation (high delay + incomplete docs)
- R2: Documentation follow-up (high denial + incomplete docs)
- R3: SLA escalation — Expedited 72-hour window at risk
- R5: Provider outreach — 45% incomplete rate exceeds 30% threshold
- R6: Senior review — prior denial history + high current denial risk
- R7: Clinical route — $28,000 cost with clinical review required
- R8: Channel conversion — Fax submission with high risk

**Recruiter talking point:**
"This is the worst-case scenario a UM coordinator faces — every flag fires at once.
The app shows exactly which 7 rules apply and what to do about each one."

---

## Scenario B — ✅ Fast-Track Candidate

**Business narrative:**
An auto-eligible imaging request arrives via Electronic submission from a Low-Risk provider.
Documentation is complete. The procedure is a routine MRI — auto-adjudication eligible.
No prior denial history, no clinical review required.

**Input values:**

| Field | Value |
|-------|-------|
| Request Type | Standard |
| Submission Channel | Electronic |
| Service Category | Imaging / Radiology |
| Procedure Group | MRI/CT |
| Provider Type | Specialist |
| Network Status | In-Network |
| Provider Risk Segment | Low-Risk |
| Region | Midwest |
| Plan Type | HMO |
| Age Band | 65-74 |
| Member Risk Level | Low |
| Documentation Complete | ✅ Yes |
| Auto-Eligible | ✅ Yes |
| Clinical Review Required | ❌ No |
| Prior Denial History | ❌ No |
| Estimated Cost | $1,200 |
| Provider Incomplete Rate | 0.04 |
| Provider Avg Response Days | 1.2 |

**Expected model output:**
- Delay risk score: LOW (0.004 — well below 0.193 threshold)
- Denial risk score: HIGH (0.113 — the denial model assigns elevated scores to imaging
  categories at the population level; however, auto-eligibility is a payer-designated
  administrative classification that overrides population-level denial scores for
  fast-track routing purposes)
- Overall risk: HIGH (driven by denial score)

**Expected recommendations:**
- R4: FAST-TRACK CANDIDATE — low delay risk + auto-eligible + complete docs
- Fast-track badge displayed
- SLA note: on track
- Note: R4 fires on delay risk + auto-eligibility + documentation completeness.
  The denial model's elevated score reflects the imaging category's population-level
  denial rate, not this specific request's eligibility status.

**Recruiter talking point:**
"The fast-track rule is as important as the escalation rules. If every case gets the same
treatment, you create unnecessary coordinator burden. The model identifies which cases
qualify for automated adjudication — and the rule engine respects the payer's auto-eligible
designation over the population-level ML score. That's intentional operational design."

---

## Scenario C — 📋 Documentation Follow-Up Case

**Business narrative:**
A standard outpatient procedure request arrives via Portal from a provider with a 38%
incomplete submission rate. Documentation is missing on this submission. Moderate denial
risk. Not expedited. No prior denial history. Cost is manageable.

**Input values:**

| Field | Value |
|-------|-------|
| Request Type | Standard |
| Submission Channel | Portal |
| Service Category | Outpatient Procedures |
| Procedure Group | Surgery |
| Provider Type | Physician |
| Network Status | In-Network |
| Provider Risk Segment | Moderate-Risk |
| Region | West |
| Plan Type | PPO |
| Age Band | 45-64 |
| Member Risk Level | Medium |
| Documentation Complete | ❌ No |
| Auto-Eligible | ❌ No |
| Clinical Review Required | ❌ No |
| Prior Denial History | ❌ No |
| Estimated Cost | $4,500 |
| Provider Incomplete Rate | 0.38 |
| Provider Avg Response Days | 2.8 |

**Expected model output:**
- Delay risk score: HIGH (incomplete docs + moderate-risk provider)
- Denial risk score: HIGH (incomplete docs is #1 denial driver)

**Expected recommendations:**
- R1: Documentation checklist (high delay + incomplete)
- R2: Documentation follow-up (high denial + incomplete)
- R5: Provider outreach/education (38% incomplete rate)

**Recruiter talking point:**
"This is the most common actionable case — documentation gap that's preventable. The
34% of MA denials that KFF attributes to incomplete documentation all look like this.
If a coordinator gets this flag early, they can call the provider before the denial goes out."

---

## Scenario D — 👨‍⚕️ Senior Review Before Final Denial

**Business narrative:**
A surgical request from an Out-of-Network specialist with prior denial history. Documentation
is complete — this is likely a medical necessity question, not a documentation problem. High
cost. Clinical review required. This pattern matches cases that frequently get overturned on appeal.

**Input values:**

| Field | Value |
|-------|-------|
| Request Type | Standard |
| Submission Channel | Electronic |
| Service Category | Surgical |
| Procedure Group | Surgery |
| Provider Type | Specialist |
| Network Status | Out-of-Network |
| Provider Risk Segment | High-Risk |
| Region | Northeast |
| Plan Type | PPO |
| Age Band | 55-64 |
| Member Risk Level | High |
| Documentation Complete | ✅ Yes |
| Auto-Eligible | ❌ No |
| Clinical Review Required | ✅ Yes |
| Prior Denial History | ✅ Yes |
| Estimated Cost | $22,000 |
| Provider Incomplete Rate | 0.12 |
| Provider Avg Response Days | 2.1 |

**Expected model output:**
- Delay risk score: MODERATE-HIGH
- Denial risk score: HIGH (OON + prior denial + clinical review + cost)

**Expected recommendations:**
- R6: Senior review — prior denial + high denial risk (appeal overturn pattern)
- R7: Clinical route — $22,000 + clinical review required
- Top drivers: OON network status, prior denial history, estimated cost, clinical review required

**Recruiter talking point:**
"The appeal model (Phase 5) showed 79.4% of denied requests get overturned on appeal —
matching the KFF benchmark. This scenario is the operational translation: if a case has
high denial risk AND prior denial history, route it to a medical director before the denial
goes out. It's cheaper to review once than to process an appeal."

---

## How to Use These Scenarios

1. Open the Streamlit app: `streamlit run app/streamlit_app.py`
2. Enter the input values from any scenario into the sidebar
3. Click "Analyze This Request"
4. Compare the output to the expected results above

All four scenarios demonstrate distinct recommendation engine behaviors and cover the full
range of workflow outcomes: escalation, fast-track, documentation follow-up, and senior review.

---

*sample_scenarios.md — Phase 6 documentation. Last updated: 2026-06-01*
