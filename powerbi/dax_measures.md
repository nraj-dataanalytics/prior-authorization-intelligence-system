# DAX Measures — Prior Authorization Intelligence System
**Phase 4 | Power BI Dashboard Design**
**Generated: 2026-05-31**

---

## Critical Design Rule

All approval and denial rate measures use `final_outcome`, not `decision`.

`[Decision] = 'Approved'` produces 86.8% — this is the initial routing rate and is NOT comparable to any published benchmark.

`final_outcome IN {"Approved", "Pended-Resolved-Approved", "Approved-After-Appeal"}` produces 92.7% — this is the final administrative determination rate that matches KFF's reported 92.3% (Source S3).

Every measure below follows this rule. Measures that intentionally use `decision` (initial routing) are explicitly labeled `[ROUTING ONLY — NOT FOR BENCHMARKS]`.

---

## Measure Organization

All DAX measures should be stored in a dedicated measure table. Create a blank table in Power BI named `_Measures` (the underscore keeps it at the top of the field list). Group measures by category using Display Folders.

Display Folders:
- `CMS-0057-F Metrics`
- `Decision & Outcome Rates`
- `Turnaround & SLA`
- `Denial Analysis`
- `Appeal Analysis`
- `Provider Metrics`
- `Benchmarks & Deltas`
- `Volume & Trend`

---

## Group 1: CMS-0057-F Metrics

These five measures correspond directly to the five public metrics payers must report under CMS-0057-F starting March 31, 2026.

```dax
-- M1: PA Approval Rate (CMS-0057-F)
-- Uses final_outcome — matches KFF MA 2024 benchmark of 92.3%
CMS M1 - Final Approval Rate % =
DIVIDE(
    COUNTROWS(
        FILTER(
            fact_prior_authorization,
            fact_prior_authorization[final_outcome] IN {
                "Approved", "Pended-Resolved-Approved", "Approved-After-Appeal"
            }
        )
    ),
    COUNTROWS(fact_prior_authorization)
) * 100
```

```dax
-- M2: PA Denial Rate (CMS-0057-F)
-- Uses final_outcome — matches KFF MA 2024 benchmark of 7.7%
CMS M2 - Final Denial Rate % =
DIVIDE(
    COUNTROWS(
        FILTER(
            fact_prior_authorization,
            fact_prior_authorization[final_outcome] IN {"Denied", "Pended-Resolved-Denied"}
        )
    ),
    COUNTROWS(fact_prior_authorization)
) * 100
```

```dax
-- M3: Percentage of Denied PAs Approved After Appeal (CMS-0057-F)
-- KFF benchmark: 80.7% overturn rate
CMS M3 - Appeal Overturn Rate % =
DIVIDE(
    COUNTROWS(
        FILTER(
            fact_appeal,
            fact_appeal[appeal_outcome] IN {"Overturned", "Partially Overturned"}
        )
    ),
    COUNTROWS(fact_appeal)
) * 100
```

```dax
-- M4a: Average Time to PA Decision — Standard Requests (CMS-0057-F)
-- SLA threshold: 7 calendar days (CMS-0057-F)
-- Industry benchmark: 5.0 days mean
CMS M4a - Avg Standard TAT Days =
CALCULATE(
    AVERAGE(fact_prior_authorization[decision_time_days]),
    fact_prior_authorization[request_type] = "Standard"
)
```

```dax
-- M4b: Average Time to PA Decision — Expedited Requests (CMS-0057-F)
-- SLA threshold: 3 calendar days / 72 hours (CMS-0057-F)
-- Industry benchmark: 1.5 days mean
CMS M4b - Avg Expedited TAT Days =
CALCULATE(
    AVERAGE(fact_prior_authorization[decision_time_days]),
    fact_prior_authorization[request_type] = "Expedited"
)
```

```dax
-- M5: Count of PA-Required Services (CMS-0057-F)
-- Payers must disclose the list of services requiring PA
CMS M5 - PA Required Services Count =
COUNTROWS(
    FILTER(dim_service, dim_service[prior_auth_required] = TRUE)
)
```

---

## Group 2: Decision & Outcome Rates

```dax
-- Total PA Requests (denominator for all rate measures)
Total PA Requests =
COUNTROWS(fact_prior_authorization)
```

```dax
-- Initial Approval Rate [ROUTING ONLY — NOT FOR BENCHMARKS]
-- Uses decision field — initial 3-state routing, NOT final outcome
-- Do not compare this to KFF 92.3% benchmark
Initial Approval Rate % [ROUTING ONLY] =
DIVIDE(
    COUNTROWS(FILTER(fact_prior_authorization, fact_prior_authorization[decision] = "Approved")),
    COUNTROWS(fact_prior_authorization)
) * 100
```

```dax
-- Initial Denial Rate [ROUTING ONLY — NOT FOR BENCHMARKS]
Initial Denial Rate % [ROUTING ONLY] =
DIVIDE(
    COUNTROWS(FILTER(fact_prior_authorization, fact_prior_authorization[decision] = "Denied")),
    COUNTROWS(fact_prior_authorization)
) * 100
```

```dax
-- Pend Rate [ROUTING ONLY]
Pend Rate % [ROUTING ONLY] =
DIVIDE(
    COUNTROWS(FILTER(fact_prior_authorization, fact_prior_authorization[decision] = "Pended")),
    COUNTROWS(fact_prior_authorization)
) * 100
```

```dax
-- Final Approved Count
Final Approved Count =
COUNTROWS(
    FILTER(
        fact_prior_authorization,
        fact_prior_authorization[final_outcome] IN {
            "Approved", "Pended-Resolved-Approved", "Approved-After-Appeal"
        }
    )
)
```

```dax
-- Final Denied Count
Final Denied Count =
COUNTROWS(
    FILTER(
        fact_prior_authorization,
        fact_prior_authorization[final_outcome] IN {"Denied", "Pended-Resolved-Denied"}
    )
)
```

```dax
-- Approved After Appeal Count
Approved After Appeal Count =
COUNTROWS(
    FILTER(
        fact_prior_authorization,
        fact_prior_authorization[final_outcome] = "Approved-After-Appeal"
    )
)
```

---

## Group 3: Turnaround & SLA

```dax
-- Overall Average TAT (all request types combined)
Avg TAT Days =
AVERAGE(fact_prior_authorization[decision_time_days])
```

```dax
-- SLA Breach Count (all requests)
SLA Breach Count =
COUNTROWS(
    FILTER(fact_prior_authorization, fact_prior_authorization[delayed_flag] = TRUE)
)
```

```dax
-- Overall SLA Breach Rate %
SLA Breach Rate % =
DIVIDE(
    [SLA Breach Count],
    [Total PA Requests]
) * 100
```

```dax
-- Standard SLA Breach Rate %
-- SLA threshold: 7 days per CMS-0057-F
Standard SLA Breach Rate % =
CALCULATE(
    DIVIDE(
        COUNTROWS(FILTER(fact_prior_authorization, fact_prior_authorization[delayed_flag] = TRUE)),
        COUNTROWS(fact_prior_authorization)
    ) * 100,
    fact_prior_authorization[request_type] = "Standard"
)
```

```dax
-- Expedited SLA Breach Rate %
-- SLA threshold: 3 days (72 hours) per CMS-0057-F
Expedited SLA Breach Rate % =
CALCULATE(
    DIVIDE(
        COUNTROWS(FILTER(fact_prior_authorization, fact_prior_authorization[delayed_flag] = TRUE)),
        COUNTROWS(fact_prior_authorization)
    ) * 100,
    fact_prior_authorization[request_type] = "Expedited"
)
```

```dax
-- Standard SLA Compliance Rate %
Standard SLA Compliance Rate % =
100 - [Standard SLA Breach Rate %]
```

```dax
-- Expedited SLA Compliance Rate %
Expedited SLA Compliance Rate % =
100 - [Expedited SLA Breach Rate %]
```

```dax
-- P95 Standard TAT Days (95th percentile — tail risk indicator for compliance exposure)
-- Use this, not the mean, to understand worst-case Standard request turnaround
P95 Standard TAT Days =
CALCULATE(
    PERCENTILEX.INC(
        fact_prior_authorization,
        fact_prior_authorization[decision_time_days],
        0.95
    ),
    fact_prior_authorization[request_type] = "Standard"
)
```

```dax
-- P95 Expedited TAT Days
P95 Expedited TAT Days =
CALCULATE(
    PERCENTILEX.INC(
        fact_prior_authorization,
        fact_prior_authorization[decision_time_days],
        0.95
    ),
    fact_prior_authorization[request_type] = "Expedited"
)
```

```dax
-- Average Days Over SLA (for delayed requests only)
Avg Days Over SLA =
CALCULATE(
    AVERAGE(fact_prior_authorization[Days Over SLA]),
    fact_prior_authorization[delayed_flag] = TRUE
)
```

```dax
-- Expedited Request Share %
Expedited Request Share % =
DIVIDE(
    COUNTROWS(FILTER(fact_prior_authorization, fact_prior_authorization[request_type] = "Expedited")),
    [Total PA Requests]
) * 100
```

---

## Group 4: Denial Analysis

```dax
-- Documentation Incomplete Rate %
Doc Incomplete Rate % =
DIVIDE(
    COUNTROWS(FILTER(fact_prior_authorization, fact_prior_authorization[documentation_complete] = FALSE)),
    [Total PA Requests]
) * 100
```

```dax
-- Denial Rate When Documentation Incomplete
-- [OPERATIONAL — uses initial decision field, not final_outcome.
--  Denominator = initial denials. Not used for KFF/CMS benchmark comparison.
--  Rationale: denial_reason is only populated on initial decision = 'Denied';
--  comparing doc-complete vs incomplete denial rates requires the initial decision field.]
Denial Rate - Incomplete Docs % =
CALCULATE(
    DIVIDE(
        COUNTROWS(FILTER(fact_prior_authorization, fact_prior_authorization[decision] = "Denied")),
        COUNTROWS(fact_prior_authorization)
    ) * 100,
    fact_prior_authorization[documentation_complete] = FALSE
)
```

```dax
-- Denial Rate When Documentation Complete
-- [OPERATIONAL — uses initial decision field, not final_outcome.
--  Denominator = initial denials. Not used for KFF/CMS benchmark comparison.
--  Rationale: denial_reason is only populated on initial decision = 'Denied';
--  comparing doc-complete vs incomplete denial rates requires the initial decision field.]
Denial Rate - Complete Docs % =
CALCULATE(
    DIVIDE(
        COUNTROWS(FILTER(fact_prior_authorization, fact_prior_authorization[decision] = "Denied")),
        COUNTROWS(fact_prior_authorization)
    ) * 100,
    fact_prior_authorization[documentation_complete] = TRUE
)
```

```dax
-- Documentation Denial Multiplier (ratio of incomplete vs complete denial rate)
Doc Denial Multiplier =
DIVIDE(
    [Denial Rate - Incomplete Docs %],
    [Denial Rate - Complete Docs %]
)
```

```dax
-- Preventable Documentation Denials
-- Denials where documentation was incomplete AND reason was Documentation Incomplete
Preventable Doc Denials =
COUNTROWS(
    FILTER(
        fact_prior_authorization,
        fact_prior_authorization[decision] = "Denied"
            && fact_prior_authorization[documentation_complete] = FALSE
            && fact_prior_authorization[denial_reason] = "Documentation Incomplete"
    )
)
```

```dax
-- Denial Count for selected denial_reason (used in bar chart context)
Denial Count =
COUNTROWS(
    FILTER(fact_prior_authorization, fact_prior_authorization[decision] = "Denied")
)
```

```dax
-- Denial Reason Share % (used in denial reason bar chart — denominator = all denials)
Denial Reason Share % =
DIVIDE(
    COUNTROWS(
        FILTER(fact_prior_authorization, fact_prior_authorization[decision] = "Denied")
    ),
    CALCULATE(
        COUNTROWS(fact_prior_authorization),
        fact_prior_authorization[decision] = "Denied"
    )
) * 100
```

---

## Group 5: Appeal Analysis

```dax
-- Total Appeals
Total Appeals =
COUNTROWS(fact_appeal)
```

```dax
-- Appeal Rate % (of denied requests)
Appeal Rate % =
DIVIDE(
    [Total Appeals],
    CALCULATE(COUNTROWS(fact_prior_authorization), fact_prior_authorization[decision] = "Denied")
) * 100
```

```dax
-- Appeals Overturned Count
Appeals Overturned =
COUNTROWS(
    FILTER(
        fact_appeal,
        fact_appeal[appeal_outcome] IN {"Overturned", "Partially Overturned"}
    )
)
```

```dax
-- Appeals Upheld Count
Appeals Upheld =
COUNTROWS(
    FILTER(fact_appeal, fact_appeal[appeal_outcome] = "Upheld")
)
```

```dax
-- Appeal Overturn Rate % (same as CMS M3, available standalone)
Appeal Overturn Rate % =
DIVIDE([Appeals Overturned], [Total Appeals]) * 100
```

```dax
-- Average Appeal Decision Days
Avg Appeal Decision Days =
AVERAGE(fact_appeal[appeal_decision_days])
```

```dax
-- Additional Documentation Submitted With Appeal %
Additional Doc Submitted % =
DIVIDE(
    COUNTROWS(
        FILTER(fact_appeal, fact_appeal[additional_documentation_submitted] = TRUE)
    ),
    [Total Appeals]
) * 100
```

---

## Group 6: Provider Metrics

```dax
-- Provider Friction Score (composite — matches vw_provider_scorecard formula)
-- [ASSUMPTION] Weights: 40% denial + 30% SLA breach + 30% doc failure
-- Requires provider-level context (use in table/matrix visual with provider_id)
Provider Friction Score =
(
    DIVIDE(
        COUNTROWS(FILTER(fact_prior_authorization, fact_prior_authorization[decision] = "Denied")),
        COUNTROWS(fact_prior_authorization)
    ) * 0.40
  + DIVIDE(
        COUNTROWS(FILTER(fact_prior_authorization, fact_prior_authorization[delayed_flag] = TRUE)),
        COUNTROWS(fact_prior_authorization)
    ) * 0.30
  + DIVIDE(
        COUNTROWS(FILTER(fact_prior_authorization, fact_prior_authorization[documentation_complete] = FALSE)),
        COUNTROWS(fact_prior_authorization)
    ) * 0.30
) * 100
```

```dax
-- Out-of-Network Denial Rate %
OON Denial Rate % =
CALCULATE(
    DIVIDE(
        COUNTROWS(FILTER(fact_prior_authorization, fact_prior_authorization[decision] = "Denied")),
        COUNTROWS(fact_prior_authorization)
    ) * 100,
    dim_provider[network_status] = "Out-of-Network"
)
```

```dax
-- In-Network Denial Rate %
In-Network Denial Rate % =
CALCULATE(
    DIVIDE(
        COUNTROWS(FILTER(fact_prior_authorization, fact_prior_authorization[decision] = "Denied")),
        COUNTROWS(fact_prior_authorization)
    ) * 100,
    dim_provider[network_status] = "In-Network"
)
```

```dax
-- OON vs In-Network Denial Multiplier
OON Denial Multiplier =
DIVIDE([OON Denial Rate %], [In-Network Denial Rate %])
```

---

## Group 7: Benchmarks & Deltas

```dax
-- KFF Approval Rate Benchmark (static reference value)
Benchmark - KFF Approval Rate =
92.3
```

```dax
-- KFF Denial Rate Benchmark
Benchmark - KFF Denial Rate =
7.7
```

```dax
-- KFF Overturn Rate Benchmark
Benchmark - KFF Overturn Rate =
80.7
```

```dax
-- KFF Appeal Rate Benchmark
Benchmark - KFF Appeal Rate =
11.5
```

```dax
-- Approval Rate vs KFF Benchmark (delta — positive = above benchmark)
Delta vs KFF - Approval Rate =
[CMS M1 - Final Approval Rate %] - [Benchmark - KFF Approval Rate]
```

```dax
-- Denial Rate vs KFF Benchmark (delta — negative = better than benchmark)
Delta vs KFF - Denial Rate =
[CMS M2 - Final Denial Rate %] - [Benchmark - KFF Denial Rate]
```

```dax
-- Approval Rate Benchmark Status (for conditional formatting)
-- Returns "Above", "At", or "Below" benchmark
Approval Rate Status =
SWITCH(
    TRUE(),
    [Delta vs KFF - Approval Rate] >= 0.5,   "Above Benchmark",
    [Delta vs KFF - Approval Rate] >= -0.5,  "At Benchmark",
    "Below Benchmark"
)
```

---

## Group 8: Volume & Trend

```dax
-- Request Volume for selected year (used in year-over-year card)
Volume 2023 =
CALCULATE(
    COUNTROWS(fact_prior_authorization),
    YEAR(fact_prior_authorization[submitted_date]) = 2023
)
```

```dax
-- Request Volume 2024
Volume 2024 =
CALCULATE(
    COUNTROWS(fact_prior_authorization),
    YEAR(fact_prior_authorization[submitted_date]) = 2024
)
```

```dax
-- YoY Volume Change %
-- NOTE: Within-dataset growth is ~12.8% (11,750 → 13,250 rows).
-- This reflects the 47/53 distribution modeled from KFF national volume growth.
-- Do not present as a measured payer growth rate.
YoY Volume Change % [SYNTHETIC DISTRIBUTION] =
DIVIDE([Volume 2024] - [Volume 2023], [Volume 2023]) * 100
```

```dax
-- Monthly Denial Rate % (for trend line — uses submitted_date month context)
Monthly Final Denial Rate % =
DIVIDE(
    COUNTROWS(
        FILTER(
            fact_prior_authorization,
            fact_prior_authorization[final_outcome] IN {"Denied", "Pended-Resolved-Denied"}
        )
    ),
    COUNTROWS(fact_prior_authorization)
) * 100
```

---

## Formatting Standards

| Measure Type | Format | Example |
|-------------|--------|---------|
| Rate (%) | `0.0"%"` | 92.7% |
| Day count | `0.00" days"` | 4.81 days |
| Count (whole) | `#,0` | 25,000 |
| Delta (signed) | `+0.0%;-0.0%;0.0%"` | +0.4% |
| Multiplier | `0.0"×"` | 3.0× |
| Score (0-100) | `0.0` | 18.4 |

---

*DAX Measures — Phase 4. Last updated: 2026-05-31*
