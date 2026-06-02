# Dashboard Storytelling Guide — Prior Authorization Intelligence System
**Phase 4 | Power BI Dashboard Design**
**Generated: 2026-05-31**
**ALL DATA IS SYNTHETIC. Benchmark-calibrated. No PHI.**

---

## Purpose

This guide is the portfolio and recruiter-facing narrative layer of the PAIS dashboard. It answers three questions:

1. **What is the project about?** — The one-paragraph pitch for LinkedIn, a portfolio site, or an interview opener.
2. **How do I walk through the dashboard in an interview?** — Page-by-page talking scripts, including what to say, what to point at, and what insight to deliver.
3. **What does each design decision demonstrate?** — The analytical and domain knowledge signals each page sends to a payer operations, claims analytics, or healthcare consulting recruiter.

This guide is not meant to be sent to a recruiter. It is your preparation material.

---

## Section 1: The One-Paragraph Portfolio Pitch

Use this on LinkedIn, your portfolio site, or as your opening line in an interview.

> "I built a Prior Authorization Intelligence System — a healthcare payer analytics project targeting Medicare Advantage operations. I started from the real regulatory problem: CMS-0057-F requires Medicare Advantage plans to publicly report five PA metrics starting March 2026. I connected that requirement to a synthetic PA workflow dataset (25,000 requests, two years, calibrated to KFF benchmarks), built a full SQL analytics layer with 40 validated data quality checks, designed a four-page Power BI dashboard tracking compliance exposure and operational bottlenecks, and wrote all the DAX measures, data model documentation, and a simulated CMS transparency filing. The entire project is end-to-end — from source documentation through data generation, SQL validation, dashboard design, and business recommendations. Every design decision is explained and every assumption is labeled."

**What this pitch signals:**
- You know CMS-0057-F exists and what it requires — most candidates do not.
- You understand the difference between synthetic portfolio data and real payer data — and you handled it correctly.
- You built infrastructure (SQL, data model, DAX) not just a visualization.
- You connected the technical work to a business output (the simulated CMS filing).

---

## Section 2: Interview Walkthrough — Page by Page

### Opening (30 seconds before you open the dashboard)

> "Before I show you the dashboard, let me give you 30 seconds of context. Prior authorization is not just a policy issue — it's an operational data problem. Payers have to track request volume, decision timelines, denial reasons, appeal outcomes, and documentation completeness, and starting in 2026, they have to report five of those metrics publicly to CMS. I built this dashboard to show what payer-side PA analytics actually looks like: not a generic healthcare KPI view, but a specific compliance and operations tool built around what regulators are asking for."

---

### Page 1: Executive Overview

**Open with:**
> "This first page answers the question an MA compliance officer would ask first thing Monday morning: 'How are we performing against CMS requirements and where is our biggest risk?' Every number on this page is something payers must report publicly under CMS-0057-F."

**Walk through the KPI cards:**
> "The headline metric is the final approval rate — 92.7%. That's above the KFF Medicare Advantage 2024 benchmark of 92.3%. The delta indicator here shows +0.4 percentage points — a green flag. Now, the reason I'm saying 'final' approval rate is important — if I had used the initial routing field, I'd show 86.8%. That's a different field that doesn't include cases that were initially pended and then resolved. Using the wrong field would make this number look 6 points worse and incomparable to any published benchmark."

> "The denial rate is 7.3% — slightly below the 7.7% KFF benchmark, which is actually favorable. The appeal overturn rate is 79.4% against KFF's 80.7%. That gap — where nearly 80% of denied cases are reversed on appeal — is analytically interesting and I'll come back to it on page 3."

> "The SLA cards show average TAT of 4.81 days for standard requests and 1.45 days for expedited. Both are within CMS limits — 7 days and 72 hours respectively — but the standard breach rate is 21%, which means the mean is flattering. The tail is the story, not the average."

**Point to the trend line:**
> "The monthly trend shows 24 months of volume and denial rate side by side. What I'm looking for operationally is whether the denial rate trends upward as volume grows — that would suggest process strain. In this dataset it's stable, which is actually the right answer for a well-run UM operation."

**Point to the CMS metrics table:**
> "This panel at the bottom right is the most employer-relevant part of this page. It's a simulation of the actual public disclosure table CMS-0057-F requires payers to file. If I were hired at Aetna or UnitedHealthcare, this is the kind of report my team would be producing annually."

**Anticipated recruiter question:** *"Why did you choose to focus on CMS-0057-F specifically?"*
> "Because it's real, current, and has a specific effective date — March 31, 2026 for the first filing. It gave the project a concrete compliance anchor. I wasn't building a generic healthcare dashboard; I was building the reporting infrastructure a payer would need to meet a specific regulatory requirement."

---

### Page 2: Delay & SLA Compliance

**Open with:**
> "Page 2 is the operations manager's page. The question it answers is not 'are we compliant overall?' but 'where are requests getting stuck, and what operational factors are driving the delays?'"

**Walk through the gauge charts:**
> "The two gauges show SLA compliance rates split by request type. Standard compliance is 79% — below the 95% target zone I set. Expedited is 93.8% — amber. The CMS limits are hard: 7 days for standard, 72 hours for expedited. These aren't soft benchmarks."

**Walk through the histogram:**
> "This histogram is what I'd actually use in an operational review. The mean TAT of 4.81 days looks fine — it's within SLA. But the P95 is around 12 days, nearly double the limit. That tail is where compliance exposure lives. The red vertical line marks the 7-day limit; everything to the right of it is a breach."

**Walk through the channel and documentation charts:**
> "These two grouped bars show the main drivers of delay. Electronic submissions are significantly faster than Fax — roughly 0.8 days faster on average. And incomplete documentation is associated with about 40% longer TAT. Those two findings directly translate into operational recommendations: increase electronic submission rates, and build documentation completeness checks into the provider portal before submission."

**Anticipated recruiter question:** *"What would you actually do with this if you were in a UM operations role?"*
> "I'd take the SLA breach rate by submission channel to a provider relations meeting and show the Fax-to-Electronic conversion opportunity. I'd also take the SLA breach rate by service category to the clinical team — certain service categories consistently run long because the documentation requirements are more complex, and those categories need dedicated clinical reviewers, not a general queue."

---

### Page 3: Denial & Appeal Intelligence

**Open with:**
> "Page 3 is the medical director's page and the denial management analyst's page. It answers the question that matters most operationally: are our denials defensible, or are they preventable?"

**Point to the denial reason bar:**
> "The top denial reason is Documentation Incomplete at 34%. That's the most actionable finding in the entire dashboard — not because it's the most common, but because it's the most preventable. A documentation failure is something the provider could have fixed before submitting. Medical necessity denials are much harder to move. Administrative errors are a process fix. But documentation denials are a provider education and portal design problem."

**Walk through the appeal funnel:**
> "The appeal funnel shows the full workflow: 25,000 total requests, down to 1,525 initial denials, down to 175 appeals, 139 overturned, ending with 36 upheld final denials. What I want to draw attention to is the 79.4% overturn rate. Nearly 4 in 5 appeals result in approval. That's an insight, not just a number — it raises the question of whether the initial denial criteria are calibrated correctly, or whether there are structural barriers to submitting documentation that are being corrected at appeal."

**Point to the reviewer type chart:**
> "This bar shows denial rate by who reviewed the request. Automated reviews have the lowest denial rate — they're mostly catching administrative errors like wrong format or duplicate submissions. Clinical Staff handles the bulk of reviews. Medical Director reviews have a slightly higher denial rate, which makes sense — those are the escalated, complex cases."

**Anticipated recruiter question:** *"What's the business recommendation you'd make from this page?"*
> "Two recommendations. First: a provider documentation outreach program targeting the top 10 friction providers — specifically the ones with high documentation incomplete rates in the service categories where documentation failures are highest. Second: a clinical operations review of the denial criteria driving the highest appeal overturn rates. If 80% of appeals for a specific denial reason are overturned, the first-pass criteria for that reason may need recalibration."

---

### Page 4: Provider Friction & Operational Action

**Open with:**
> "Page 4 is the provider relations director's page. The question it answers is not 'which providers have high denial rates?' — that's a ranking. The question is: 'which providers should we call tomorrow, and what do we say when we call them?'"

**Walk through the friction score:**
> "I built a composite provider friction score that combines three metrics: 40% weight on denial rate, 30% on SLA breach rate, and 30% on documentation failure rate. The weights are labeled as assumption-based — I'm not claiming these are a real payer's weights. But the framework is real: payer provider relations teams do use composite metrics to prioritize outreach."

**Walk through the scatter plot:**
> "This scatter plot puts every provider on two axes: friction score and total request volume. Bubble size is denied request count. The action zone is the upper right — high volume, high friction. Those are the providers generating the most operational burden. A provider in the lower right with high friction but low volume is lower priority — their absolute impact is smaller."

**Walk through the top 10 table:**
> "This table is the operational output of the entire dashboard. Each row is a provider to call. The column that matters most for the call isn't the friction score — it's the documentation incomplete rate. That's the specific problem I can help the provider fix. 'Your documentation incomplete rate is 35% versus a network average of 19%. Here are the three service categories where it's highest. Here's the pre-submission checklist.'"

**Anticipated recruiter question:** *"How would you validate the friction score weights?"*
> "In a production environment, I'd back-test the weights against appeal overturn rates and final outcome distributions — does a high friction score predict higher appeal rates? I'd also consult with clinical operations leadership on whether denial rate or documentation failure is more actionable for provider outreach. In this portfolio project, the weights are clearly labeled as assumption-based. The framework demonstrates the methodology; real weights would require real payer outcome data."

---

## Section 3: What Each Page Demonstrates to Recruiters

### Page 1: Executive Overview
| Signal | What Recruiters See |
|--------|-------------------|
| CMS-0057-F metric alignment | You understand regulatory reporting requirements, not just analytics concepts |
| `final_outcome` vs `decision` distinction | You understand payer data structure and can catch benchmark comparison errors |
| Benchmark delta indicators | You know how to connect internal performance to external reference points |
| Simulated CMS filing format | You can translate analytics into compliance output |

### Page 2: Delay & SLA Compliance
| Signal | What Recruiters See |
|--------|-------------------|
| P90/P95 TAT focus over mean | You understand that the tail is what matters in SLA compliance, not the average |
| Submission channel analysis | You can identify operational levers — not just describe the problem |
| Documentation impact on TAT | You can connect documentation quality to turnaround performance |
| Severity bucketing | You can turn a binary breach flag into an actionable severity classification |

### Page 3: Denial & Appeal Intelligence
| Signal | What Recruiters See |
|--------|-------------------|
| Denial reason prioritization | You can distinguish preventable from structural denials |
| Overturn rate analysis | You understand the appeal process as a quality signal, not just a recovery mechanism |
| Reviewer type breakdown | You know how payer review workflows are structured |
| Preventable denial count | You can quantify operational improvement opportunities |

### Page 4: Provider Friction
| Signal | What Recruiters See |
|--------|-------------------|
| Composite friction score | You can build multi-factor operational metrics, not just single KPIs |
| Action-oriented framing | You think about the output of analytics — who does what with it |
| OON vs In-Network analysis | You understand network status as an operational variable, not just a billing one |
| Top 10 outreach list | You can translate a ranking into a work queue |

---

## Section 4: LinkedIn Post Framework

Use this structure for a LinkedIn post announcing the project.

**Hook (first line — visible before "see more"):**
> Starting in March 2026, every Medicare Advantage plan in the U.S. must publicly report five prior authorization metrics to CMS. I built the analytics system to track them.

**Body:**
> The Prior Authorization Intelligence System is a full-stack payer analytics capstone I built to demonstrate healthcare payer operations literacy — the kind of work I'm targeting in roles at CVS Health/Aetna, UnitedHealthcare, and similar organizations.

> What's in it:
> - 25,000 synthetic PA requests (2 years, calibrated to KFF Medicare Advantage benchmarks)
> - Full SQL analytics layer with 40 validated data quality checks
> - Power BI dashboard with 4 pages: CMS compliance overview, SLA operations, denial intelligence, and provider friction
> - Simulated CMS-0057-F public metrics filing
> - All assumptions labeled, all leakage risks documented, all benchmarks sourced

> The key design principle: every page answers a question a real payer operations team would actually ask — not what's analytically interesting, but what's operationally actionable.

**Closing:**
> Built for roles in payer operations analytics, utilization management, claims analytics, and healthcare consulting. Happy to connect with anyone working in this space.

**Tags:** #HealthcareAnalytics #MedicareAdvantage #PriorAuthorization #PowerBI #HealthcarePayer #CMS #DataAnalytics

---

## Section 5: GitHub README Key Sections

When uploading this project to GitHub, the README should include the following sections in this order:

1. **Project Summary** — One paragraph (use the portfolio pitch from Section 1)
2. **Regulatory Context** — 2-3 sentences on CMS-0057-F and why it matters
3. **Data Disclaimer** — Prominent statement that all data is synthetic, no PHI
4. **Project Architecture** — Phase 1 through 5 overview with file list
5. **Dashboard Pages** — Brief description of each page (4 bullets)
6. **Key Design Decisions** — `final_outcome` vs `decision`, leakage field handling, friction score methodology
7. **Sources** — KFF, CMS-0057-F rule, OIG report (with "narrative context only" note)
8. **How to Run** — DuckDB setup, CSV import path, Power BI connection options

---

## Section 6: Interview Questions and Suggested Answers

**Q: Why prior authorization specifically?**
> "Prior authorization sits at the intersection of clinical judgment, operational efficiency, and regulatory compliance — three domains that payer analytics teams have to navigate simultaneously. And CMS-0057-F made it immediately relevant: payers are filing these metrics for the first time in 2026. I wanted to build something connected to a real current regulatory moment, not a historical case study."

**Q: The data is synthetic — doesn't that limit what you can show?**
> "Actually, the synthetic data requirement made the project more rigorous, not less. I had to document every assumption, source every benchmark, and build a validation layer that confirms the data behaves the way real MA data would. A real payer dataset would do the heavy lifting for me — I had to do it explicitly. And the documentation transparency is actually a strength in an interview: I can show you exactly why every number is what it is."

**Q: What would you do differently if you had real payer data?**
> "Three things. First, I'd validate whether the 34% Documentation Incomplete share is consistent with the plan's actual claims data — that's a hypothesis I built into the synthetic data. Second, I'd run the friction score against actual member outcome data to validate the weights. Third, I'd add a member-level analysis: which member risk segments generate the most PA friction, and does that correlate with downstream utilization?"

**Q: How does this connect to what we do at [company]?**
> "Medicare Advantage payer operations teams are building exactly this kind of infrastructure right now — the CMS-0057-F filing deadline is March 2026. Whether it's at CVS Health, Aetna, UHC, or Humana, someone is building or validating the SQL views and reporting logic to produce those five public metrics. That's what I built — a documented, validated, end-to-end version of that workflow."

---

*Dashboard Storytelling Guide — Phase 4. Last updated: 2026-05-31*
