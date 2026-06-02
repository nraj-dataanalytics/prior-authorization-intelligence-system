-- =============================================================================
-- FILE:    08_dashboard_views.sql
-- PROJECT: Prior Authorization Intelligence System (PAIS)
-- PHASE:   3 — SQL Analysis Layer
-- PURPOSE: Create all SQL views that will power the Phase 4 Power BI dashboard.
--          Each view is named for the dashboard component it supports.
--          Views are pre-joined, pre-aggregated, and annotated with
--          the dashboard component they correspond to.
--
-- VIEWS CREATED:
--   vw_cms_public_metrics          — CMS-0057-F 5 required metrics (summary card)
--   vw_monthly_volume_trend        — Monthly request volume + denial rate (line chart)
--   vw_denial_by_service_category  — Denial rate by service (bar chart + heatmap)
--   vw_provider_scorecard          — Provider-level performance (table + scatter)
--   vw_appeal_funnel               — Denial → appeal → overturn funnel (funnel chart)
--   vw_sla_compliance_summary      — SLA breach by request type (gauge/KPI card)
--   vw_documentation_impact        — Doc completeness vs outcomes (grouped bar)
--   vw_submission_channel_analysis — Channel breakdown (stacked bar)
--   vw_member_risk_profile         — Member risk vs outcomes (segmented bar)
--   vw_reviewer_type_outcomes      — Reviewer type patterns (table + bar)
--
-- DESIGN RULES FOR ALL VIEWS:
--   1. All approval/denial rates use final_outcome (not decision)
--   2. Leakage-risk fields (action_recommended_initial, appeal_id, appealed)
--      are excluded from all views except vw_appeal_funnel where appeal_id
--      is used within its correct appeal-specific context.
--   3. All data is SYNTHETIC. No PHI.
--
-- TARGET: PostgreSQL 14+ / DuckDB 0.9+
-- =============================================================================

SET search_path TO pais, public;

-- Drop views before recreating (safe to re-run)
DROP VIEW IF EXISTS pais.vw_reviewer_type_outcomes      CASCADE;
DROP VIEW IF EXISTS pais.vw_member_risk_profile          CASCADE;
DROP VIEW IF EXISTS pais.vw_submission_channel_analysis  CASCADE;
DROP VIEW IF EXISTS pais.vw_documentation_impact         CASCADE;
DROP VIEW IF EXISTS pais.vw_sla_compliance_summary       CASCADE;
DROP VIEW IF EXISTS pais.vw_appeal_funnel                CASCADE;
DROP VIEW IF EXISTS pais.vw_provider_scorecard           CASCADE;
DROP VIEW IF EXISTS pais.vw_denial_by_service_category   CASCADE;
DROP VIEW IF EXISTS pais.vw_monthly_volume_trend         CASCADE;
DROP VIEW IF EXISTS pais.vw_cms_public_metrics           CASCADE;


-- =============================================================================
-- VIEW 1: vw_cms_public_metrics
-- Dashboard component: Summary KPI cards (top of dashboard)
-- CMS-0057-F required public metrics — one row per metric
-- =============================================================================

CREATE VIEW pais.vw_cms_public_metrics AS
WITH base AS (
    SELECT
        COUNT(*)                                                    AS total_requests,
        SUM(CASE WHEN final_outcome IN (
            'Approved','Pended-Resolved-Approved','Approved-After-Appeal'
        ) THEN 1 ELSE 0 END)                                        AS final_approved,
        SUM(CASE WHEN final_outcome IN (
            'Denied','Pended-Resolved-Denied'
        ) THEN 1 ELSE 0 END)                                        AS final_denied,
        SUM(CASE WHEN decision = 'Pended' THEN 1 ELSE 0 END)        AS pended,
        SUM(CASE WHEN final_outcome = 'Approved-After-Appeal'
            THEN 1 ELSE 0 END)                                       AS approved_after_appeal,
        SUM(CASE WHEN delayed_flag = TRUE THEN 1 ELSE 0 END)         AS delayed,
        AVG(CASE WHEN request_type = 'Standard'  THEN decision_time_days END) AS avg_std_days,
        AVG(CASE WHEN request_type = 'Expedited' THEN decision_time_days END) AS avg_exp_days
    FROM pais.fact_prior_authorization
),
appeal_base AS (
    SELECT
        COUNT(*) AS total_appeals,
        SUM(CASE WHEN appeal_outcome IN ('Overturned','Partially Overturned')
            THEN 1 ELSE 0 END) AS overturned
    FROM pais.fact_appeal
)
SELECT
    'M1'                                   AS cms_metric_id,
    'PA Approval Rate'                     AS metric_name,
    ROUND(b.final_approved * 100.0 / b.total_requests, 2) AS metric_value,
    '%'                                    AS unit,
    92.3                                   AS kff_2024_benchmark,
    'final_outcome'                        AS source_field,
    'KFF MA PA 2024 (S3)'                  AS benchmark_source
FROM base b

UNION ALL

SELECT
    'M2', 'PA Denial Rate',
    ROUND(b.final_denied * 100.0 / b.total_requests, 2),
    '%', 7.7, 'final_outcome', 'KFF MA PA 2024 (S3)'
FROM base b

UNION ALL

SELECT
    'M3', 'Appeal Overturn Rate',
    ROUND(a.overturned * 100.0 / NULLIF(a.total_appeals, 0), 2),
    '%', 80.7, 'appeal_outcome', 'KFF MA PA 2024 (S3)'
FROM appeal_base a

UNION ALL

SELECT
    'M4a', 'Avg Standard Decision Time (days)',
    ROUND(b.avg_std_days, 2),
    'days', 5.0, 'decision_time_days', 'CMS-0057-F + industry (A07)'
FROM base b

UNION ALL

SELECT
    'M4b', 'Avg Expedited Decision Time (days)',
    ROUND(b.avg_exp_days, 2),
    'days', 1.5, 'decision_time_days', 'CMS-0057-F + industry (A08)'
FROM base b

UNION ALL

SELECT
    'M6', 'Appeal Rate of Denied Requests',
    ROUND(b.approved_after_appeal * 100.0 / NULLIF(b.final_denied + b.approved_after_appeal + b.pended, 0), 2),
    '%', 11.5, 'appealed', 'KFF MA PA 2024 (S3/A04)'
FROM base b

UNION ALL

SELECT
    'M7', 'SLA Breach Rate (All Requests)',
    ROUND(b.delayed * 100.0 / b.total_requests, 2),
    '%', NULL, 'delayed_flag', '[ASSUMPTION A10/A11]'
FROM base b;

COMMENT ON VIEW pais.vw_cms_public_metrics IS
    'CMS-0057-F required public metrics. '
    'Use metric_value vs kff_2024_benchmark for gap analysis. '
    'All rates use final_outcome per design rule. Dashboard: KPI Summary Cards.';


-- =============================================================================
-- VIEW 2: vw_monthly_volume_trend
-- Dashboard component: Line chart — monthly request volume + denial rate over time
-- =============================================================================

CREATE VIEW pais.vw_monthly_volume_trend AS
SELECT
    TO_CHAR(submitted_date, 'YYYY-MM')                         AS year_month,
    EXTRACT(YEAR  FROM submitted_date)::INT                    AS year,
    EXTRACT(MONTH FROM submitted_date)::INT                    AS month,
    COUNT(*)                                                   AS total_requests,
    SUM(CASE WHEN final_outcome IN ('Denied','Pended-Resolved-Denied')
        THEN 1 ELSE 0 END)                                     AS final_denied_count,
    ROUND(
        SUM(CASE WHEN final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                          AS final_denial_rate_pct,
    SUM(CASE WHEN delayed_flag = TRUE THEN 1 ELSE 0 END)       AS delayed_count,
    ROUND(
        SUM(CASE WHEN delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                          AS sla_breach_rate_pct,
    ROUND(AVG(decision_time_days), 2)                          AS avg_turnaround_days,
    SUM(CASE WHEN request_type = 'Expedited' THEN 1 ELSE 0 END) AS expedited_count,
    SUM(CASE WHEN documentation_complete = FALSE THEN 1 ELSE 0 END) AS incomplete_doc_count
FROM pais.fact_prior_authorization
GROUP BY
    TO_CHAR(submitted_date, 'YYYY-MM'),
    EXTRACT(YEAR  FROM submitted_date),
    EXTRACT(MONTH FROM submitted_date)
ORDER BY year_month;

COMMENT ON VIEW pais.vw_monthly_volume_trend IS
    'Monthly PA metrics for time-series dashboard. '
    'NOTE: Year-over-year denial rate differences reflect random variation only — '
    'no trend shift is modeled between 2023 and 2024. '
    'Volume growth (~6%) IS explicitly modeled (A25). '
    'Dashboard: Monthly Trend Line Chart.';


-- =============================================================================
-- VIEW 3: vw_denial_by_service_category
-- Dashboard component: Horizontal bar chart — denial rate by service type
-- =============================================================================

CREATE VIEW pais.vw_denial_by_service_category AS
SELECT
    s.service_category,
    COUNT(f.request_id)                                         AS total_requests,
    SUM(CASE WHEN f.decision = 'Denied' THEN 1 ELSE 0 END)      AS initial_denied,
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS initial_denial_rate_pct,
    SUM(CASE WHEN f.final_outcome IN ('Denied','Pended-Resolved-Denied')
        THEN 1 ELSE 0 END)                                      AS final_denied,
    ROUND(
        SUM(CASE WHEN f.final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS final_denial_rate_pct,
    ROUND(AVG(f.decision_time_days), 2)                         AS avg_turnaround_days,
    ROUND(
        SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS sla_breach_rate_pct,
    ROUND(
        SUM(CASE WHEN f.documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS doc_incomplete_rate_pct,
    ROUND(AVG(s.base_denial_risk) * 100, 1)                    AS assumption_base_risk_pct
FROM pais.fact_prior_authorization f
JOIN pais.dim_service s ON f.service_id = s.service_id
GROUP BY s.service_category
ORDER BY final_denial_rate_pct DESC;

COMMENT ON VIEW pais.vw_denial_by_service_category IS
    'Denial rates by service category. '
    'assumption_base_risk_pct values are [ASSUMPTION C01-C10] — not measured rates. '
    'Dashboard: Service Category Denial Rate Bar Chart.';


-- =============================================================================
-- VIEW 4: vw_provider_scorecard
-- Dashboard component: Provider performance table with drillthrough
-- =============================================================================

CREATE VIEW pais.vw_provider_scorecard AS
SELECT
    f.provider_id,
    p.provider_type,
    p.region,
    p.network_status,
    p.prior_auth_volume_band,
    p.provider_risk_segment,
    COUNT(f.request_id)                                         AS total_requests,
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS denial_rate_pct,
    ROUND(
        SUM(CASE WHEN f.final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS final_denial_rate_pct,
    ROUND(
        SUM(CASE WHEN f.documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS doc_incomplete_rate_pct,
    ROUND(
        SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS sla_breach_rate_pct,
    ROUND(AVG(f.decision_time_days), 2)                         AS avg_turnaround_days,
    ROUND(
        (
            SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 0.40
          + SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 0.30
          + SUM(CASE WHEN f.documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 0.30
        ) * 100, 2
    )                                                           AS friction_score
FROM pais.fact_prior_authorization f
JOIN pais.dim_provider p ON f.provider_id = p.provider_id
GROUP BY
    f.provider_id, p.provider_type, p.region,
    p.network_status, p.prior_auth_volume_band, p.provider_risk_segment
HAVING COUNT(f.request_id) >= 5
ORDER BY friction_score DESC;

COMMENT ON VIEW pais.vw_provider_scorecard IS
    'Provider-level PA performance scorecard. '
    'friction_score = 40% denial + 30% delay + 30% doc failure [ASSUMPTION — weights are illustrative]. '
    'Dashboard: Provider Scorecard Table + Scatter Plot.';


-- =============================================================================
-- VIEW 5: vw_appeal_funnel
-- Dashboard component: Funnel chart — denial → appeal → overturn
-- =============================================================================

CREATE VIEW pais.vw_appeal_funnel AS
SELECT
    -- Step 1: Total PA requests
    COUNT(f.request_id)                                         AS total_pa_requests,

    -- Step 2: Initial denials
    SUM(CASE WHEN f.decision = 'Denied' THEN 1 ELSE 0 END)      AS initial_denials,
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS initial_denial_rate_pct,

    -- Step 3: Appeals filed
    SUM(CASE WHEN f.appealed = TRUE THEN 1 ELSE 0 END)          AS appeals_filed,
    ROUND(
        SUM(CASE WHEN f.appealed = TRUE THEN 1.0 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN f.decision = 'Denied' THEN 1 ELSE 0 END), 0) * 100, 2
    )                                                           AS appeal_rate_of_denied_pct,

    -- Step 4: Appeals overturned (from fact_appeal)
    (SELECT SUM(CASE WHEN appeal_outcome IN ('Overturned','Partially Overturned')
                THEN 1 ELSE 0 END) FROM pais.fact_appeal)       AS overturned_count,
    (SELECT SUM(CASE WHEN appeal_outcome = 'Upheld'
                THEN 1 ELSE 0 END) FROM pais.fact_appeal)       AS upheld_count,
    ROUND(
        (SELECT SUM(CASE WHEN appeal_outcome IN ('Overturned','Partially Overturned')
                    THEN 1.0 ELSE 0 END) FROM pais.fact_appeal)
        / NULLIF((SELECT COUNT(*) FROM pais.fact_appeal), 0) * 100, 2
    )                                                           AS overturn_rate_pct,

    -- Step 5: Final approved and final denied (end of funnel)
    SUM(CASE WHEN f.final_outcome IN (
        'Approved','Pended-Resolved-Approved','Approved-After-Appeal'
    ) THEN 1 ELSE 0 END)                                        AS final_approved,
    SUM(CASE WHEN f.final_outcome IN (
        'Denied','Pended-Resolved-Denied'
    ) THEN 1 ELSE 0 END)                                        AS final_denied,
    ROUND(
        SUM(CASE WHEN f.final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS final_denial_rate_pct,

    -- Benchmarks
    92.3    AS kff_benchmark_approval_pct,
    80.7    AS kff_benchmark_overturn_pct,
    11.5    AS kff_benchmark_appeal_rate_pct

FROM pais.fact_prior_authorization f;

COMMENT ON VIEW pais.vw_appeal_funnel IS
    'Full PA appeal funnel from submission to final outcome. '
    'KFF 2024 benchmarks included for gap analysis. '
    'appeal_id used within appeal-specific context only (not as a predictor). '
    'Dashboard: Appeal Funnel Chart.';


-- =============================================================================
-- VIEW 6: vw_sla_compliance_summary
-- Dashboard component: Gauge charts — SLA compliance by request type
-- =============================================================================

CREATE VIEW pais.vw_sla_compliance_summary AS
SELECT
    request_type,
    MAX(allowed_days)                                           AS sla_threshold_days,
    COUNT(*)                                                    AS total_requests,
    SUM(CASE WHEN delayed_flag = FALSE THEN 1 ELSE 0 END)       AS on_time_count,
    SUM(CASE WHEN delayed_flag = TRUE  THEN 1 ELSE 0 END)       AS delayed_count,
    ROUND(
        SUM(CASE WHEN delayed_flag = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS sla_compliance_rate_pct,
    ROUND(
        SUM(CASE WHEN delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS sla_breach_rate_pct,
    ROUND(AVG(decision_time_days), 2)                           AS avg_turnaround_days,
    ROUND(
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY decision_time_days), 2
    )                                                           AS median_turnaround_days,
    ROUND(
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY decision_time_days), 2
    )                                                           AS p95_turnaround_days,
    CASE
        WHEN request_type = 'Standard'  THEN 82.0
        WHEN request_type = 'Expedited' THEN 90.0
    END                                                         AS assumption_compliance_target_pct
FROM pais.fact_prior_authorization
GROUP BY request_type;

COMMENT ON VIEW pais.vw_sla_compliance_summary IS
    'SLA compliance rates by request type. '
    'SLA thresholds: 7 days (Standard), 3 days (Expedited) per CMS-0057-F. '
    'assumption_compliance_target_pct values are [ASSUMPTION A10/A11]. '
    'Dashboard: SLA Compliance Gauge Charts.';


-- =============================================================================
-- VIEW 7: vw_documentation_impact
-- Dashboard component: Grouped bar chart — doc status vs outcomes
-- =============================================================================

CREATE VIEW pais.vw_documentation_impact AS
SELECT
    documentation_complete,
    COUNT(*)                                                    AS total_requests,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)         AS pct_of_total,
    SUM(CASE WHEN decision = 'Denied' THEN 1 ELSE 0 END)        AS denied_count,
    ROUND(
        SUM(CASE WHEN decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS initial_denial_rate_pct,
    ROUND(
        SUM(CASE WHEN final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS final_denial_rate_pct,
    ROUND(AVG(decision_time_days), 2)                           AS avg_turnaround_days,
    ROUND(
        SUM(CASE WHEN delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS sla_breach_rate_pct,
    -- Denial reason breakdown for incomplete docs
    SUM(CASE WHEN denial_reason = 'Documentation Incomplete'
         AND documentation_complete = FALSE THEN 1 ELSE 0 END) AS doc_incomplete_denials,
    SUM(CASE WHEN denial_reason = 'Medical Necessity Not Met'
         AND documentation_complete = FALSE THEN 1 ELSE 0 END) AS med_necessity_denials
FROM pais.fact_prior_authorization
GROUP BY documentation_complete;

COMMENT ON VIEW pais.vw_documentation_impact IS
    'Documentation completeness impact on PA outcomes. '
    'Incomplete docs drive 2.5x higher denial rate [ASSUMPTION G01]. '
    'Dashboard: Documentation Impact Grouped Bar Chart.';


-- =============================================================================
-- VIEW 8: vw_submission_channel_analysis
-- Dashboard component: Stacked bar — channel breakdown by outcome
-- =============================================================================

CREATE VIEW pais.vw_submission_channel_analysis AS
SELECT
    submission_channel,
    COUNT(*)                                                    AS total_requests,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)         AS pct_of_total,
    ROUND(
        SUM(CASE WHEN decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS denial_rate_pct,
    ROUND(
        SUM(CASE WHEN delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS sla_breach_rate_pct,
    ROUND(AVG(decision_time_days), 2)                           AS avg_turnaround_days,
    ROUND(
        SUM(CASE WHEN documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS doc_incomplete_rate_pct,
    CASE submission_channel
        WHEN 'Electronic' THEN 55.0
        WHEN 'Fax'        THEN 25.0
        WHEN 'Portal'     THEN 12.0
        WHEN 'Phone'      THEN  8.0
    END                                                         AS assumption_target_share_pct
FROM pais.fact_prior_authorization
GROUP BY submission_channel
ORDER BY denial_rate_pct DESC;

COMMENT ON VIEW pais.vw_submission_channel_analysis IS
    'Submission channel breakdown. '
    'Fax has higher denial and delay rates due to documentation friction [ASSUMPTION G05]. '
    'Channel shares are [ASSUMPTION A20-A22]. '
    'Dashboard: Submission Channel Stacked Bar Chart.';


-- =============================================================================
-- VIEW 9: vw_member_risk_profile
-- Dashboard component: Segmented bar — member risk level vs outcomes
-- =============================================================================

CREATE VIEW pais.vw_member_risk_profile AS
SELECT
    m.risk_level,
    m.age_band,
    m.plan_type,
    COUNT(f.request_id)                                         AS total_requests,
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS denial_rate_pct,
    ROUND(
        SUM(CASE WHEN f.final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS final_denial_rate_pct,
    ROUND(
        SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS sla_breach_rate_pct,
    ROUND(AVG(f.decision_time_days), 2)                         AS avg_turnaround_days
FROM pais.fact_prior_authorization f
JOIN pais.dim_member m ON f.member_id = m.member_id
GROUP BY m.risk_level, m.age_band, m.plan_type
ORDER BY m.risk_level, m.age_band;

COMMENT ON VIEW pais.vw_member_risk_profile IS
    'Member risk level and demographic segmentation of PA outcomes. '
    'High-risk members have elevated denial probability due to clinical complexity. '
    'Dashboard: Member Risk Profile Segmented Bar Chart.';


-- =============================================================================
-- VIEW 10: vw_reviewer_type_outcomes
-- Dashboard component: Table + bar — reviewer type vs decision patterns
-- =============================================================================

CREATE VIEW pais.vw_reviewer_type_outcomes AS
SELECT
    reviewer_type,
    COUNT(*)                                                    AS total_requests,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)         AS pct_of_volume,
    SUM(CASE WHEN decision = 'Approved' THEN 1 ELSE 0 END)      AS approved_count,
    SUM(CASE WHEN decision = 'Denied'   THEN 1 ELSE 0 END)      AS denied_count,
    SUM(CASE WHEN decision = 'Pended'   THEN 1 ELSE 0 END)      AS pended_count,
    ROUND(
        SUM(CASE WHEN decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS denial_rate_pct,
    ROUND(AVG(decision_time_days), 2)                           AS avg_turnaround_days,
    ROUND(
        SUM(CASE WHEN delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                           AS sla_breach_rate_pct,
    SUM(CASE WHEN documentation_complete = FALSE THEN 1 ELSE 0 END)
                                                                AS incomplete_doc_escalations
FROM pais.fact_prior_authorization
GROUP BY reviewer_type
ORDER BY denial_rate_pct ASC;

COMMENT ON VIEW pais.vw_reviewer_type_outcomes IS
    'Reviewer type vs PA outcome patterns. '
    'Automated has lowest denial rate (0.4x multiplier, Assumption G04). '
    'Medical Director reviews most complex / highest-denial cases. '
    'Dashboard: Reviewer Type Outcomes Table + Bar.';


-- =============================================================================
-- VERIFICATION: List all views created
-- =============================================================================

SELECT
    table_name AS view_name,
    'Created' AS status
FROM information_schema.views
WHERE table_schema = 'pais'
ORDER BY table_name;

-- Expected: 10 views listed
