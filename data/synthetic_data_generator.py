"""
generate_synthetic_data.py  —  Prior Authorization Intelligence System Phase 2
Synthetic Data Generator
ALL DATA IS SYNTHETIC. No PHI. No real patient records.
Random seed = 42 for reproducibility.

Calibration note:
  KFF 7.7% denial rate (S3) = FINAL OUTCOME rate, not initial routing rate.
  Initial routing targets: Denied~6%, Pended~9%, Approved~85%.
  Final outcome approval (incl pend + appeal overturns) targets ~91-93% (KFF 92.3%).
  DENIAL_CALIBRATION_SCALE = 0.32 brings raw stacked probability to ~6% initial denial.
"""

import random, math, csv, os
from datetime import date, timedelta

RANDOM_SEED = 42
random.seed(RANDOM_SEED)

DENIAL_CALIBRATION_SCALE = 0.32

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ── helpers ───────────────────────────────────────────────────────────────────
def lognormal_sample(mean_days, sigma):
    mu = math.log(mean_days) - 0.5 * sigma**2
    u1 = max(random.random(), 1e-10)
    u2 = random.random()
    z  = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return math.exp(mu + sigma * z)

def clamp(val, lo, hi): return max(lo, min(hi, val))

def weighted_choice(choices, weights):
    total = sum(weights); r = random.random() * total; cum = 0
    for c, w in zip(choices, weights):
        cum += w
        if r <= cum: return c
    return choices[-1]

def add_days(d, n): return d + timedelta(days=int(max(0, n)))

def write_csv(fname, rows, fields):
    path = os.path.join(OUTPUT_DIR, fname)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader(); w.writerows(rows)
    print(f"  OK {fname} ({len(rows):,} rows)")

# ── TABLE 1: services (40 rows) ───────────────────────────────────────────────
# [ASSUMPTION C01-C10] Service category denial/delay risk — see synthetic_assumption_table.csv
# No CMS public data breaks denial rates by service type (confirmed research 2026)
# OIG S5 narrative names imaging and post-acute as high-denial categories
SERVICE_CATALOG = [
    # (category, procedure_group, clin_review, auto_elig, cost_min, cost_max, deny_risk, delay_risk)
    ("Advanced Imaging","MRI Brain/Spine",True,False,800,3500,0.12,0.18),
    ("Advanced Imaging","CT Scan Abdomen/Pelvis",True,False,600,2800,0.11,0.17),
    ("Advanced Imaging","PET Scan Oncology",True,False,2500,8000,0.13,0.20),
    ("Advanced Imaging","Nuclear Medicine Study",True,False,1200,4500,0.12,0.18),
    ("Inpatient Hospital","Inpatient Medical Admission",True,False,5000,35000,0.13,0.20),
    ("Inpatient Hospital","Inpatient Surgical Admission",True,False,8000,50000,0.14,0.22),
    ("Inpatient Hospital","ICU / Critical Care Admission",True,False,10000,50000,0.12,0.19),
    ("Inpatient Hospital","Inpatient Psychiatric Admission",True,False,4000,20000,0.13,0.20),
    ("Post-Acute / SNF","Skilled Nursing Facility Stay",True,False,3000,15000,0.16,0.22),
    ("Post-Acute / SNF","Inpatient Rehabilitation",True,False,5000,25000,0.17,0.24),
    ("Post-Acute / SNF","Long-Term Acute Care (LTACH)",True,False,8000,40000,0.16,0.23),
    ("Post-Acute / SNF","Sub-Acute Rehabilitation",True,False,2500,12000,0.15,0.21),
    ("Surgical Procedures","Orthopedic Surgery (Knee/Hip)",True,False,10000,40000,0.10,0.15),
    ("Surgical Procedures","Spine Surgery",True,False,15000,60000,0.12,0.17),
    ("Surgical Procedures","Bariatric Surgery",True,False,12000,35000,0.11,0.16),
    ("Surgical Procedures","Cardiac Catheterization",True,False,8000,30000,0.09,0.14),
    ("Specialty Drugs","Biologic Infusion Therapy",True,False,3000,25000,0.09,0.13),
    ("Specialty Drugs","Chemotherapy Administration",True,False,5000,30000,0.08,0.12),
    ("Specialty Drugs","Specialty Injectable (non-chemo)",True,False,2000,15000,0.09,0.13),
    ("Specialty Drugs","Gene Therapy",True,False,50000,200000,0.10,0.15),
    ("Durable Medical Equipment","Power Wheelchair",False,True,3000,12000,0.10,0.14),
    ("Durable Medical Equipment","CPAP / BiPAP Device",False,True,500,2000,0.08,0.11),
    ("Durable Medical Equipment","Orthotics / Prosthetics",True,True,1000,8000,0.10,0.14),
    ("Durable Medical Equipment","Home Oxygen Equipment",False,True,200,1200,0.09,0.12),
    ("Outpatient Procedures","Ambulatory Surgery - Minor",False,True,500,5000,0.05,0.08),
    ("Outpatient Procedures","Endoscopy / Colonoscopy",False,True,800,3500,0.05,0.07),
    ("Outpatient Procedures","Outpatient Infusion",False,True,400,3000,0.05,0.08),
    ("Outpatient Procedures","Radiation Therapy Course",True,False,5000,25000,0.07,0.10),
    ("Behavioral Health","Residential Mental Health",True,False,2000,15000,0.08,0.12),
    ("Behavioral Health","Intensive Outpatient Program",False,True,500,4000,0.07,0.10),
    ("Behavioral Health","Substance Use Disorder Treatment",False,True,1000,8000,0.08,0.11),
    ("Behavioral Health","Applied Behavior Analysis (ABA)",True,True,2000,10000,0.09,0.13),
    ("Physical/Occupational Therapy","Physical Therapy Extended Course",False,True,500,4000,0.06,0.09),
    ("Physical/Occupational Therapy","Occupational Therapy Program",False,True,400,3500,0.06,0.08),
    ("Physical/Occupational Therapy","Speech-Language Pathology",False,True,300,3000,0.05,0.08),
    ("Physical/Occupational Therapy","Cardiac Rehabilitation Program",False,True,1000,5000,0.06,0.09),
    ("Home Health","Skilled Nursing Home Visits",False,True,500,5000,0.09,0.14),
    ("Home Health","Home Physical Therapy",False,True,300,3000,0.08,0.12),
    ("Home Health","Home Infusion Therapy",True,True,1000,10000,0.10,0.14),
    ("Home Health","Hospice Care Authorization",True,False,2000,12000,0.09,0.13),
]

def generate_services():
    rows=[]
    for i,(cat,proc,clin,auto,cmin,cmax,dr,dlr) in enumerate(SERVICE_CATALOG,1):
        rows.append({"service_id":f"SVC-{i:03d}","service_category":cat,"procedure_group":proc,
            "prior_auth_required":True,"clinical_review_required":clin,"automation_eligible":auto,
            "base_cost_min":cmin,"base_cost_max":cmax,"base_denial_risk":dr,"base_delay_risk":dlr})
    return rows

# ── TABLE 2: members (5,000) ──────────────────────────────────────────────────
def generate_members(n=5000):
    age_b  = ["18-44","45-54","55-64","65-74","75-84","85+"]
    age_w  = [0.03,0.06,0.18,0.35,0.28,0.10]
    gend   = ["M","F","U"]; gw=[0.47,0.51,0.02]
    plans  = ["HMO","PPO","SNP","PFFS"]; pw=[0.42,0.35,0.15,0.08]
    regs   = ["Northeast","Southeast","Midwest","Southwest","West"]; rw=[0.20,0.30,0.24,0.04,0.22]
    rows=[]
    for i in range(1,n+1):
        ch = min(8,max(0,int(round(random.gauss(2.5,1.5)))))
        risk = "High" if ch>=4 else ("Medium" if ch>=2 else "Low")
        rows.append({"member_id":f"MBR-{i:05d}","age_band":weighted_choice(age_b,age_w),
            "gender":weighted_choice(gend,gw),"plan_type":weighted_choice(plans,pw),
            "region":weighted_choice(regs,rw),"risk_level":risk,
            "chronic_condition_count":ch,"member_tenure_months":random.randint(1,60)})
    return rows

# ── TABLE 3: providers (1,000) ────────────────────────────────────────────────
PTYPE_CFG = {
    "Specialist":          (0.25,0.10,0.28,[0.10,0.30,0.40,0.20]),
    "Hospital":            (0.20,0.05,0.18,[0.02,0.08,0.35,0.55]),
    "Imaging Center":      (0.15,0.08,0.22,[0.08,0.30,0.42,0.20]),
    "Surgery Center":      (0.12,0.08,0.22,[0.05,0.25,0.45,0.25]),
    "Primary Care":        (0.10,0.12,0.30,[0.15,0.40,0.35,0.10]),
    "DME Supplier":        (0.08,0.20,0.45,[0.25,0.45,0.25,0.05]),
    "Post-Acute Facility": (0.05,0.12,0.30,[0.05,0.25,0.45,0.25]),
    "Home Health Agency":  (0.03,0.15,0.35,[0.20,0.45,0.30,0.05]),
    "Behavioral Health":   (0.02,0.12,0.28,[0.20,0.40,0.30,0.10]),
}
VOL_BANDS = ["Low (1-49/yr)","Medium (50-199/yr)","High (200-499/yr)","Very High (500+/yr)"]
REGIONS   = ["Northeast","Southeast","Midwest","Southwest","West"]
REG_W     = [0.20,0.30,0.24,0.04,0.22]

def generate_providers(n=1000):
    ptypes = list(PTYPE_CFG.keys())
    pw     = [PTYPE_CFG[t][0] for t in ptypes]
    rows=[]
    for i in range(1,n+1):
        pt  = weighted_choice(ptypes,pw)
        cfg = PTYPE_CFG[pt]
        inc = round(random.uniform(cfg[1],cfg[2]),3)
        vb  = weighted_choice(VOL_BANDS,cfg[3])
        seg = "High-Risk" if inc>0.30 else ("Moderate-Risk" if inc>0.15 else "Low-Risk")
        rows.append({"provider_id":f"PRV-{i:04d}","provider_type":pt,
            "region":weighted_choice(REGIONS,REG_W),
            "network_status":weighted_choice(["In-Network","Out-of-Network"],[0.88,0.12]),
            "prior_auth_volume_band":vb,"avg_incomplete_submission_rate":inc,
            "avg_response_time_days":round(random.uniform(0.5,10.0),2),"provider_risk_segment":seg})
    return rows

# ── TABLE 4: prior_auth_requests (25,000) ─────────────────────────────────────
CHANNELS   = ["Electronic","Fax","Portal","Phone"]
CHAN_W     = [0.55,0.25,0.12,0.08]
DENIAL_REASONS = [
    "Medical Necessity Not Met","Documentation Incomplete",
    "Clinical Criteria Not Met","Not a Covered Benefit","Duplicate/Administrative Error"
]
DR_BASE_W = [0.35,0.28,0.20,0.10,0.07]

def denial_reason_weights(doc_ok, chan, cat, net):
    w=list(DR_BASE_W)
    if not doc_ok: w[1]*=2.2
    if cat in ("Advanced Imaging","Post-Acute / SNF","Inpatient Hospital"): w[2]*=1.5
    if net=="Out-of-Network": w[3]*=2.0
    if chan in ("Fax","Phone"): w[4]*=1.8
    t=sum(w); return [x/t for x in w]

def denial_prob(svc, prov, mem, doc_ok, chan, rtype, auto_elig):
    p = svc["base_denial_risk"]
    if not doc_ok:    p *= 2.5   # G01
    if chan=="Fax":   p *= 1.30  # G05
    elif chan=="Phone":p*= 1.25
    seg = prov["provider_risk_segment"]
    if seg=="High-Risk":     p*=1.50  # G02
    elif seg=="Moderate-Risk":p*=1.20
    if prov["network_status"]=="Out-of-Network": p*=1.80  # G03
    if mem["risk_level"]=="High":   p*=1.20
    elif mem["risk_level"]=="Medium":p*=1.05
    if rtype=="Expedited": p*=1.10
    if auto_elig: p*=0.40  # G04
    return clamp(p * DENIAL_CALIBRATION_SCALE, 0.005, 0.35)

def pend_prob(doc_ok, auto_elig, deny_p):
    base = 0.04 if (doc_ok and auto_elig) else (0.14 if not doc_ok else 0.09)
    return clamp(base*(1-deny_p*2), 0.01, 0.20)

def decision_time(rtype, doc_ok, chan, auto_elig, decision):
    if rtype=="Expedited":
        t = clamp(lognormal_sample(1.5,0.4),0.25,4.0)
    else:
        t = clamp(lognormal_sample(5.0,0.5),0.5,25.0)
    if not doc_ok:  t*=1.40   # G06
    if chan=="Fax":  t*=1.25  # G05
    elif chan=="Phone":t*=1.20
    if auto_elig:   t*=0.35
    if decision=="Denied": t*=1.15
    if rtype=="Expedited": return clamp(round(t,2),0.25,5.0)
    return clamp(round(t,2),0.5,30.0)

def generate_requests(members, providers, services, n=25000):
    vol_w = []
    for p in providers:
        vb=p["prior_auth_volume_band"]
        vol_w.append(8 if "Very High" in vb else 4 if "High" in vb else 2 if "Medium" in vb else 1)
    svc_vol = {"Advanced Imaging":3.0,"Inpatient Hospital":2.5,"Post-Acute / SNF":1.5,
               "Surgical Procedures":2.0,"Specialty Drugs":1.5,"Durable Medical Equipment":1.8,
               "Outpatient Procedures":2.2,"Behavioral Health":1.2,
               "Physical/Occupational Therapy":1.5,"Home Health":1.3}
    svc_w = [svc_vol.get(s["service_category"],1.0) for s in services]
    n2024 = int(n*0.53); n2023=n-n2024  # A25 6% YoY growth

    def rdate(yr):
        s=date(yr,1,1); delta=(date(yr,12,31)-s).days
        return s+timedelta(days=random.randint(0,delta))

    DOWS=["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    rows=[]; denied_idx=[]; apc=[0]

    for idx in range(1,n+1):
        yr   = 2023 if idx<=n2023 else 2024
        sd   = rdate(yr); dow=DOWS[sd.weekday()]
        mem  = random.choice(members)
        prov = weighted_choice(providers,vol_w)
        svc  = weighted_choice(services,svc_w)
        rtype= "Expedited" if random.random()<0.15 else "Standard"
        chan = weighted_choice(CHANNELS,CHAN_W)
        # doc completeness — provider-driven, channel-adjusted [A13/G06]
        base_inc=prov["avg_incomplete_submission_rate"]
        if chan in ("Fax","Phone"): base_inc=clamp(base_inc+random.uniform(0.05,0.08),0,0.65)
        if mem["member_tenure_months"]<6: base_inc=clamp(base_inc+0.03,0,0.65)
        doc_ok = random.random()>base_inc
        # previous denial [ASSUMPTION]
        prev_den=random.random()<0.18
        if mem["risk_level"]=="High": prev_den=prev_den or random.random()<0.10
        cost=random.randint(svc["base_cost_min"],svc["base_cost_max"])
        auto_elig=bool(svc["automation_eligible"]) and doc_ok and cost<15000
        clin_rev =bool(svc["clinical_review_required"])
        reviewer =("Automated" if auto_elig else
                   ("Medical Director" if clin_rev and random.random()<0.35 else "Clinical Staff"))
        dp=denial_prob(svc,prov,mem,doc_ok,chan,rtype,auto_elig)
        if prev_den: dp=clamp(dp*1.4,0.005,0.35)
        pp=pend_prob(doc_ok,auto_elig,dp)
        r=random.random()
        if r<dp:      dec="Denied"
        elif r<dp+pp: dec="Pended"
        else:         dec="Approved"
        dt=decision_time(rtype,doc_ok,chan,auto_elig,dec)
        alw=3 if rtype=="Expedited" else 7  # CMS-0057-F S1
        delayed=dt>alw
        dd=sd+timedelta(days=max(1,int(math.ceil(dt))))
        dr=""
        if dec=="Denied":
            drw=denial_reason_weights(doc_ok,chan,svc["service_category"],prov["network_status"])
            dr=weighted_choice(DENIAL_REASONS,drw)
        if dec=="Approved":
            arec=weighted_choice(["Approve","Request-Additional-Docs"],[0.92,0.08])
        elif dec=="Denied":
            arec=weighted_choice(["Deny","Request-Additional-Docs","Pend"],[0.70,0.20,0.10])
        else:
            arec=weighted_choice(["Pend","Request-Additional-Docs"],[0.80,0.20])
        fo=("Approved" if dec=="Approved" else
            ("Pended-Resolved-Approved" if dec=="Pended" and random.random()<0.75
             else "Pended-Resolved-Denied" if dec=="Pended"
             else "Denied"))
        row={"request_id":f"PAR-{idx:06d}","member_id":mem["member_id"],
             "provider_id":prov["provider_id"],"service_id":svc["service_id"],
             "request_type":rtype,"submitted_date":sd.isoformat(),"submitted_day_of_week":dow,
             "submission_channel":chan,"documentation_complete":doc_ok,"estimated_cost":cost,
             "previous_denial_history":prev_den,"auto_eligible":auto_elig,
             "clinical_review_required":clin_rev,"reviewer_type":reviewer,"decision":dec,
             "decision_date":dd.isoformat(),"decision_time_days":dt,"allowed_days":alw,
             "delayed_flag":delayed,"denial_reason":dr,"pended_flag":(dec=="Pended"),
             "final_outcome":fo,"appealed":False,"appeal_id":"",
             "action_recommended_initial":arec,"_dd":dd}
        rows.append(row)
        if dec=="Denied": denied_idx.append(idx-1)

    # Appeals: A04 11.5% of denials [KFF S3]
    n_app=int(len(denied_idx)*0.115)
    app_idx=random.sample(denied_idx,min(n_app,len(denied_idx)))
    app_temp=[]
    for ac,ri in enumerate(app_idx,1):
        aid=f"APP-{ac:05d}"; rows[ri]["appealed"]=True; rows[ri]["appeal_id"]=aid
        app_temp.append((aid,rows[ri]["request_id"],rows[ri]["_dd"]))

    for row in rows: del row["_dd"]
    return rows, app_temp

# ── TABLE 5: appeals ──────────────────────────────────────────────────────────
OV_REASONS=["Additional Documentation Resolved Issue","Clinical Criteria Re-evaluated",
            "Peer-to-Peer Review Changed Decision","Administrative Error Corrected"]

def generate_appeals(app_temp, req_map):
    rows=[]
    for aid,rid,dd in app_temp:
        alag=random.randint(1,30)
        ad=dd+timedelta(days=alag)
        addays=random.randint(5,30)
        add_=ad+timedelta(days=addays)
        # A05: 80.7% overturned [KFF S3]
        outcome=weighted_choice(["Overturned","Partially Overturned","Upheld"],[0.65,0.157,0.193])
        if outcome in ("Overturned","Partially Overturned"):
            rov=weighted_choice(OV_REASONS,[0.40,0.30,0.20,0.10])
            adoc=random.random()<0.65; fs="Approved"
        else:
            rov=""; adoc=random.random()<0.15; fs="Denied"
        rows.append({"appeal_id":aid,"request_id":rid,"appeal_date":ad.isoformat(),
            "appeal_decision_date":add_.isoformat(),"appeal_decision_days":addays,
            "appeal_outcome":outcome,"reason_overturned":rov,
            "additional_documentation_submitted":adoc,"final_status_after_appeal":fs})
        if rid in req_map:
            if outcome in ("Overturned","Partially Overturned"):
                req_map[rid]["final_outcome"]="Approved-After-Appeal"
    return rows

# ── Calibration check ─────────────────────────────────────────────────────────
def calib(reqs, apps):
    n=len(reqs)
    den=sum(1 for r in reqs if r["decision"]=="Denied")
    app_r=sum(1 for r in reqs if r["decision"]=="Approved")
    pen=sum(1 for r in reqs if r["decision"]=="Pended")
    app_filed=sum(1 for r in reqs if r["appealed"])
    inc=sum(1 for r in reqs if not r["documentation_complete"])
    exp=sum(1 for r in reqs if r["request_type"]=="Expedited")
    ov=sum(1 for a in apps if a["appeal_outcome"] in ("Overturned","Partially Overturned"))
    st=[r["decision_time_days"] for r in reqs if r["request_type"]=="Standard"]
    ex=[r["decision_time_days"] for r in reqs if r["request_type"]=="Expedited"]
    avgst=sum(st)/len(st) if st else 0; avgex=sum(ex)/len(ex) if ex else 0
    ds=[r["decision_time_days"] for r in reqs if r["delayed_flag"] and r["request_type"]=="Standard"]
    de=[r["decision_time_days"] for r in reqs if r["delayed_flag"] and r["request_type"]=="Expedited"]
    nst=sum(1 for r in reqs if r["request_type"]=="Standard")
    nex=sum(1 for r in reqs if r["request_type"]=="Expedited")
    # final outcome approval rate (KFF comparison metric)
    fo_app=sum(1 for r in reqs if r["final_outcome"] in
               ("Approved","Pended-Resolved-Approved","Approved-After-Appeal"))
    print("\n── CALIBRATION ───────────────────────────────────────────────────")
    print(f"  Total requests:          {n:,}      target 25,000")
    print(f"  Initial approval rate:   {app_r/n*100:.1f}%   target ~85%")
    print(f"  Initial denial rate:     {den/n*100:.1f}%    target ~6%")
    print(f"  Initial pend rate:       {pen/n*100:.1f}%    target ~9%")
    print(f"  FINAL outcome approval:  {fo_app/n*100:.1f}%   KFF target 88-94.5%")
    print(f"  Expedited share:         {exp/n*100:.1f}%   target 13-17%")
    print(f"  Incomplete docs rate:    {inc/n*100:.1f}%   target 18-28%")
    print(f"  Appeal rate (of denied): {app_filed/den*100:.1f}%   target 9-14%")
    print(f"  Overturn rate:           {ov/len(apps)*100:.1f}%   target 75-86%")
    print(f"  Avg standard TAT:        {avgst:.2f} days  target 3.5-7.0")
    print(f"  Avg expedited TAT:       {avgex:.2f} days  target 0.8-2.5")
    print(f"  Total appeals:           {len(apps):,}      target 200-450")
    print(f"  SLA breach standard:     {len(ds)/nst*100:.1f}%   target 10-28%")
    print(f"  SLA breach expedited:    {len(de)/nex*100:.1f}%   target 5-18%")
    print("──────────────────────────────────────────────────────────────────\n")

# ── main ──────────────────────────────────────────────────────────────────────
def main():
    print("Prior Authorization Intelligence System — Phase 2 Data Generator")
    print(f"Seed={RANDOM_SEED}  |  ALL DATA SYNTHETIC — NO PHI\n")
    svcs=generate_services()
    write_csv("services.csv",svcs,["service_id","service_category","procedure_group",
        "prior_auth_required","clinical_review_required","automation_eligible",
        "base_cost_min","base_cost_max","base_denial_risk","base_delay_risk"])
    mems=generate_members(5000)
    write_csv("members.csv",mems,["member_id","age_band","gender","plan_type","region",
        "risk_level","chronic_condition_count","member_tenure_months"])
    provs=generate_providers(1000)
    write_csv("providers.csv",provs,["provider_id","provider_type","region","network_status",
        "prior_auth_volume_band","avg_incomplete_submission_rate",
        "avg_response_time_days","provider_risk_segment"])
    print("Generating 25,000 PA requests...")
    reqs,app_temp=generate_requests(mems,provs,svcs,25000)
    req_map={r["request_id"]:r for r in reqs}
    apps=generate_appeals(app_temp,req_map)
    write_csv("prior_auth_requests.csv",reqs,[
        "request_id","member_id","provider_id","service_id","request_type",
        "submitted_date","submitted_day_of_week","submission_channel","documentation_complete",
        "estimated_cost","previous_denial_history","auto_eligible","clinical_review_required",
        "reviewer_type","decision","decision_date","decision_time_days","allowed_days",
        "delayed_flag","denial_reason","pended_flag","final_outcome","appealed","appeal_id",
        "action_recommended_initial"])
    write_csv("appeals.csv",apps,["appeal_id","request_id","appeal_date","appeal_decision_date",
        "appeal_decision_days","appeal_outcome","reason_overturned",
        "additional_documentation_submitted","final_status_after_appeal"])
    calib(reqs,apps)
    print("Phase 2 complete.")

if __name__=="__main__":
    main()
