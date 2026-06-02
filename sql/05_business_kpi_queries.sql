-- =============================================================================
-- FILE:    05_business_kpi_queries.sql
-- PROJECT: Prior Authorization Intelligence System (PAIS)
-- PHASE:   3 — SQL Analysis Layer
-- PURPOSE: Core business KPI queries aligned with CMS-0057-F public reporting
--          requirements and standard payer operations metrics.
--
-- CMS-0057-F REQUIRED PUBLIC METRICS (all five computed here):
--   M1: Percentage of PA requests approved
--   M2: Percentage of PA requests denied
--   M3: Percentage of denied PAs approved after appeal
--   M4: Average time (in days) to reach a PA decision
--   M5: List of services/items requiring prior authorization (dim_service)
--
-- ADDITIONAL OPERATIONAL KPIs:
--   M6:  Appeal rate (% of denied requests that were appealed)
--   M7:  Appeal overturn rate (% of appeals that were overturned)
--   M8:  SLA breach rate by request type
--   M9:  Pend rate and pend resolution rate
--   M10: Denial reason distribution
--   M11: Year-over-year volume trend
--   M12: Expedited vs standard turnaround comparison
--
-- CRITICAL DESIGN RULE:
--   All approval/denial rate benchmarks use final_outcome, NOT decision.
--   - final_outcome = final administrative outcome after pend resolution and appeals
--   - decision = initial 3-state routing (Approved/Denied/Pended)
--   - KFF 2024 reports 92.3% approval rate as a final_outcome metric (S3)
--   - Using decision would show 86.8% — a 5.5-point gap that is NOT a data error
--
-- TARGET: PostgreSQL 14+ / DuckDB 0.9+
-- =============================================================================

SET search_path TO pais, public;


-- =============================================================================
-- KPI SECTION 1: CMS-0057-F REQUIRED PUBLIC METRICS
-- These five metrics are the mandatory annual public report per CMS-0057-F.
-- Payers must report these starting March 31, 2026 (covering CY2025).
-- =============================================================================

-- -------------------------------------------------------------------------
-- M1 + M2: PA Approval and Denial Rate (using final_outcome)
-- Source benchmark: KFF MA PA 2024 (S3) — 92.3% approval, 7.7% denial
-- PAIS synthetic data achieves: 92.7% approval, 7.3% denial
-- -------------------------------------------------------------------------

SELECT
    'M1+M2: CMS Final Approval and Denial Rates' AS metric_group,
    COUNT(*)                                              AS total_requests,

    -- Final approval rate (M1) — use final_outcome per design rule above
    SUM(CASE WHEN final_outcome IN (
        'Approved',
        'Pended-Resolved-Approved',
        'Approved-After-Appeal'
    ) THEN 1 ELSE 0 END)                                  AS final_approved_count,

    ROUND(
        SUM(CASE WHEN final_outcome IN (
            'Approved',
            'Pended-Resolved-Approved',
            'Approved-After-Appeal'
        ) THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                     AS final_approval_rate_pct,

    -- Final denial rate (M2)
    SUM(CASE WHEN final_outcome IN (
        'Denied',
        'Pended-Resolved-Denied'
    ) THEN 1 ELSE 0 END)                                  AS final_denied_count,

    ROUND(
        SUM(CASE WHEN final_outcome IN (
            'Denied',
            'Pended-Resolved-Denied'
        ) THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                     AS final_denial_rate_pct,

    -- For reference: initial decision routing (NOT for KFF comparison)
    ROUND(SUM(CASE WHEN decision = 'Approved' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2)
                                                          AS initial_approval_rate_pct,
    ROUND(SUM(CASE WHEN decision = 'Denied'   THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2)
                                                          AS initial_denial_rate_pct,
    ROUND(SUM(CASE WHEN decision = 'Pended'   THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2)
                                                          AS initial_pend_rate_pct,

    -- KFF benchmark for comparison
    92.3                                                  AS kff_benchmark_approval_pct,
    7.7                                                   AS kff_benchmark_denial_pct

FROM pais.fact_prior_authorization;

-- Expected (synthetic calibration targets):
-- final_approval_rate_pct: ~92.7%   | kff_benchmark: 92.3%  ✅
-- final_denial_rate_pct:   ~7.3%    | kff_benchmark:  7.7%  ✅
-- initial_approval_rate_pct: ~86.8% (NOT comparable to KFF)
-- initial_denial_rate_pct:   ~6.1%  (initial routing only)
-- initial_pend_rate_pct:     ~7.1%


-- -------------------------------------------------------------------------
-- M3: Percentage of Denied PAs Approved After Appeal
-- Source benchmark: KFF 2024 — 80.7% overturn rate (S3)
-- -------------------------------------------------------------------------

SELECT
    'M3: CMS Appeal Overturn Rate' AS metric_name,
    COUNT(*)                        AS total_appeals,
    SUM(CASE WHEN appeal_outcome IN ('Overturned','Partially Overturned')
        THEN 1 ELSE 0 END)          AS overturned_count,
    SUM(CASE WHEN appeal_outcome = 'Upheld'
        THEN 1 ELSE 0 END)          AS upheld_count,
    ROUND(
        SUM(CASE WHEN appeal_outcome IN ('Overturned','Partially Overturned')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                               AS overturn_rate_pct,
    80.7                            AS kff_benchmark_overturn_pct
FROM pais.fact_appeal;

-- Expected: overturn_rate_pct ~79.4% vs benchmark 80.7% ✅


-- -------------------------------------------------------------------------
-- M4: Average Time (Days) to PA Decision — by Request Type
-- Source benchmark: CMS-0057-F + industry (S1, A07, A08)
-- -------------------------------------------------------------------------

SELECT
    'M4: Average Decision Turnaround Time' AS metric_name,
    request_type,
    COUNT(*)                               AS request_count,
    ROUND(AVG(decision_time_days), 2)      AS avg_days,
    ROUND(MIN(decision_time_days), 2)      AS min_days,
    ROUND(MAX(decision_time_days), 2)      AS max_days,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY decision_time_days), 2)
                                           AS median_days,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY decision_time_days), 2)
                                           AS p90_days,
    CASE
        WHEN request_type = 'Standard'  THEN 5.0
        WHEN request_type = 'Expedited' THEN 1.5
    END                                    AS industry_benchmark_mean
FROM pais.fact_prior_authorization
GROUP BY request_type
ORDER BY request_type;

-- Expected:
-- Standard:  avg ~4.81 days | benchmark 5.0 days ✅
-- Expedited: avg ~1.45 days | benchmark 1.5 days ✅

-- NOTE: DuckDB may use PERCENTILE_CONT differently. Substitute APPROX_QUANTILE if needed.


-- -------------------------------------------------------------------------
-- M5: List of Services/Items Requiring Prior Authorization
-- This is the CMS-0057-F disclosure requirement — must be published annually.
-- -------------------------------------------------------------------------

SELECT
    'M5: PA-Required Services' AS metric_name,
    service_id,
    service_category,
    procedure_group,
    prior_auth_required,
    clinical_review_required,
    automation_eligible,
    ROUND(base_denial_risk * 100, 1) AS base_denial_risk_pct  -- [ASSUMPTION C01-C10]
FROM pais.dim_service
WHERE prior_auth_required = TRUE
ORDER BY service_category, procedure_group;


-- =============================================================================
-- KPI SECTION 2: OPERATIONAL METRICS
-- =============================================================================

-- -------------------------------------------------------------------------
-- M6: Appeal Rate (% of denied requests that were appealed)
-- Source benchmark: KFF 2024 — 11.5% of denials appealed (S3/A04)
-- -------------------------------------------------------------------------

SELECT
    'M6: Appeal Rate Among Denied Requests' AS metric_name,
    COUNT(*)                                AS total_denied,
    SUM(CASE WHEN appealed = TRUE THEN 1 ELSE 0 END)
                                            AS appealed_count,
    ROUND(
        SUM(CASE WHEN appealed = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                       AS appeal_rate_pct,
    11.5                                    AS kff_benchmark_appeal_rate_pct
FROM pais.fact_prior_authorization
WHERE decision = 'Denied';

-- Expected: appeal_rate_pct ~11.5% ✅


-- -------------------------------------------------------------------------
-- M7: SLA Breach Rate (Delayed Rate) by Request Type
-- Source benchmark: A10 (82% standard compliance), A11 (90% expedited compliance)
-- -------------------------------------------------------------------------

SELECT
    'M7: SLA Breach Rate' AS metric_name,
    request_type,
    COUNT(*)              AS total_requests,
    SUM(CASE WHEN delayed_flag = TRUE THEN 1 ELSE 0 END)
                          AS delayed_count,
    ROUND(
        SUM(CASE WHEN delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                     AS sla_breach_rate_pct,
    CASE
        WHEN request_type = 'Standard'  THEN 18.0  -- (100% - 82% compliance) [ASSUMPTION A10]
        WHEN request_type = 'Expedited' THEN 10.0  -- (100% - 90% compliance) [ASSUMPTION A11]
    END                   AS assumption_breach_rate_target,
    CASE
        WHEN request_type = 'Standard'  THEN 7    -- CMS-0057-F: 7-day SLA
        WHEN request_type = 'Expedited' THEN 3    -- CMS-0057-F: 72-hour SLA
    END                   AS cms_sla_days
FROM pais.fact_prior_authorization
GROUP BY request_type
ORDER BY request_type;

-- Expected:
-- Standard:  ~21.0% breach | allowed_days = 7
-- Expedited: ~6.2%  breach | allowed_days = 3


-- -------------------------------------------------------------------------
-- M8: Pend Rate and Pend Resolution Distribution
-- Source: A14 — 9% base pend rate (ASSUMPTION); actual achieved 7.1%
-- -------------------------------------------------------------------------

SELECT
    'M8: Pend Rate and Resolution' AS metric_name,
    COUNT(*)                        AS total_requests,
    SUM(CASE WHEN decision = 'Pended' THEN 1 ELSE 0 END)
                                    AS pended_count,
    ROUND(SUM(CASE WHEN decision = 'Pended' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2)
                                    AS pend_rate_pct,
    -- Of pended, how many resolved to Approved?
    SUM(CASE WHEN final_outcome = 'Pended-Resolved-Approved' THEN 1 ELSE 0 END)
                                    AS pended_resolved_approved,
    SUM(CASE WHEN final_outcome = 'Pended-Resolved-Denied' THEN 1 ELSE 0 END)
                                    AS pended_resolved_denied,
    ROUND(
        SUM(CASE WHEN final_outcome = 'Pended-Resolved-Approved' THEN 1.0 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN decision = 'Pended' THEN 1 ELSE 0 END), 0) * 100, 2
    )                               AS pend_to_approved_resolution_rate_pct
FROM pais.fact_prior_authorization;


-- -------------------------------------------------------------------------
-- M9: Denial Reason Distribution
-- Source: A15-A19 — OIG + Commonwealth Fund + documented assumptions
-- -------------------------------------------------------------------------

SELECT
    'M9: Denial Reason Distribution' AS metric_name,
    denial_reason,
    COUNT(*)                          AS denial_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)
                                      AS pct_of_all_denials,
    -- Benchmark targets from synthetic_assumption_table.csv
    CASE denial_reason
        WHEN 'Medical Necessity Not Met'   THEN 35.0  -- A15
        WHEN 'Documentation Incomplete'   THEN 28.0  -- A16
        WHEN 'Clinical Criteria Not Met'  THEN 20.0  -- A17
        WHEN 'Not a Covered Benefit'      THEN 10.0  -- A18 [ASSUMPTION]
        WHEN 'Duplicate/Administrative Error' THEN 7.0  -- A19 [ASSUMPTION]
        ELSE NULL
    END                               AS assumption_target_pct
FROM pais.fact_prior_authorization
WHERE decision = 'Denied'
  AND denial_reason IS NOT NULL
GROUP BY denial_reason
ORDER BY denial_count DESC;


-- -------------------------------------------------------------------------
-- M10: Year-Over-Year Volume Trend
-- Source: A25 — KFF 2024 vs 2023 = 6% YoY growth (S3/S4)
-- -------------------------------------------------------------------------

SELECT
    'M10: Annual Volume Trend' AS metric_name,
    EXTRACT(YEAR FROM submitted_date) AS year,
    COUNT(*)                           AS total_requests,
    SUM(CASE WHEN final_outcome IN ('Approved','Pended-Resolved-Approved','Approved-After-Appeal')
        THEN 1 ELSE 0 END)             AS final_approved,
    SUM(CASE WHEN final_outcome IN ('Denied','Pended-Resolved-Denied')
        THEN 1 ELSE 0 END)             AS final_denied,
    ROUND(
        SUM(CASE WHEN final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                  AS final_denial_rate_pct,
    ROUND(AVG(decision_time_days), 2)  AS avg_turnaround_days
FROM pais.fact_prior_authorization
GROUP BY EXTRACT(YEAR FROM submitted_date)
ORDER BY year;

-- NOTE: Year-over-year denial rate difference reflects random variation only.
-- The synthetic generator does NOT model a trend shift in denial rates between
-- 2023 and 2024. Do not interpret year differences as a measured trend.
-- Volume growth of ~6% between years IS explicitly modeled (A25).


-- -------------------------------------------------------------------------
-- M11: Monthly Volume and Denial Trend (for time-series dashboard)
-- -------------------------------------------------------------------------

SELECT
    EXTRACT(YEAR FROM submitted_date)  AS year,
    EXTRACT(MONTH FROM submitted_date) AS month,
    TO_CHAR(submitted_date, 'YYYY-MM') AS year_month,
    COUNT(*)                            AS total_requests,
    SUM(CASE WHEN final_outcome IN ('Denied','Pended-Resolved-Denied')
        THEN 1 ELSE 0 END)              AS final_denied,
    ROUND(
        SUM(CASE WHEN final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                   AS monthly_denial_rate_pct,
    SUM(CASE WHEN delayed_flag = TRUE THEN 1 ELSE 0 END)
                                        AS delayed_count,
    ROUND(AVG(decision_time_days), 2)   AS avg_turnaround_days
FROM pais.fact_prior_authorization
GROUP BY
    EXTRACT(YEAR FROM submitted_date),
    EXTRACT(MONTH FROM submitted_date),
    TO_CHAR(submitted_date, 'YYYY-MM')
ORDER BY year, month;


-- -------------------------------------------------------------------------
-- M12: Plan Type Breakdown (HMO vs PPO vs SNP vs PFFS)
-- Segments all core KPIs by member plan type.
-- -------------------------------------------------------------------------

SELECT
    m.plan_type,
    COUNT(*)                            AS total_requests,
    ROUND(
        SUM(CASE WHEN f.final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                   AS final_denial_rate_pct,
    ROUND(
        SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                   AS sla_breach_rate_pct,
    ROUND(AVG(f.decision_time_days), 2) AS avg_turnaround_days,
    SUM(CASE WHEN f.appealed = TRUE THEN 1 ELSE 0 END)
                                        AS total_appeals
FROM pais.fact_prior_authorization f
JOIN pais.dim_member m ON f.member_id = m.member_id
GROUP BY m.plan_type
ORDER BY total_requests DESC;


-- =============================================================================
-- KPI SECTION 3: COMPLETE CMS-0057-F PUBLIC METRICS SUMMARY
-- One-row summary suitable for the required annual public report.
-- =============================================================================

SELECT
    CURRENT_DATE                       AS report_generated_date,
    '2023-01-01'                       AS study_period_start,
    '2024-12-31'                       AS study_period_end,
    'Synthetic MA Plan (PAIS Portfolio)' AS organization_name,
    'ALL SYNTHETIC DATA — NO PHI'      AS data_note,

    -- M1: Approval rate
    ROUND(
        SUM(CASE WHEN final_outcome IN ('Approved','Pended-Resolved-Approved','Approved-After-Appeal')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                  AS cms_m1_approval_rate_pct,

    -- M2: Denial rate
    ROUND(
        SUM(CASE WHEN final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                  AS cms_m2_denial_rate_pct,

    -- M3: Approval after appeal rate (see fact_appeal for denominator)
    NULL::NUMERIC                      AS cms_m3_appeal_overturn_rate_pct,  -- computed in separate query

    -- M4: Average decision time
    ROUND(AVG(CASE WHEN request_type = 'Standard'  THEN decision_time_days END), 2)
                                       AS cms_m4_avg_standard_days,
    ROUND(AVG(CASE WHEN request_type = 'Expedited' THEN decision_time_days END), 2)
                                       AS cms_m4_avg_expedited_days,

    -- M5: Count of PA-required services (see dim_service query above)
    (SELECT COUNT(*) FROM pais.dim_service WHERE prior_auth_required = TRUE)
                                       AS cms_m5_pa_required_service_count,

    COUNT(*)                           AS total_pa_requests
FROM pais.fact_prior_authorization;
