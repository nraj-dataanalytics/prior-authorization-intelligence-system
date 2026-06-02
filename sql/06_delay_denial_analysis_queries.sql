-- =============================================================================
-- FILE:    06_delay_denial_analysis_queries.sql
-- PROJECT: Prior Authorization Intelligence System (PAIS)
-- PHASE:   3 — SQL Analysis Layer
-- PURPOSE: Deep-dive analysis of what drives PA delays and denials.
--          These queries power the operational bottleneck diagnostics
--          in the Phase 4 Power BI dashboard.
--
-- ANALYTICAL QUESTIONS ANSWERED:
--   D1: How does documentation completeness affect denial rate?
--   D2: How does submission channel affect denial rate and turnaround time?
--   D3: How does service category drive denial patterns?
--   D4: How does reviewer type correlate with denial and delay rates?
--   D5: What is the combined effect of documentation + channel + service?
--   D6: How does request urgency (Standard vs Expedited) affect outcomes?
--   D7: What does the SLA breach distribution look like across all requests?
--   D8: What is the denial-to-appeal-to-overturn funnel in detail?
--   D9: How does member risk level affect PA outcomes?
--   D10: What is the documentation-to-denial pathway by service category?
--
-- DESIGN NOTE: Uses final_outcome for denial rates in all KPI summaries.
--   Uses decision for operational routing analysis (D1-D5) since the
--   question is "what causes initial routing decisions."
--
-- TARGET: PostgreSQL 14+ / DuckDB 0.9+
-- =============================================================================

SET search_path TO pais, public;


-- =============================================================================
-- D1: Documentation Completeness Impact on Denial Rate
-- Source: G01 — 2.5x denial multiplier for incomplete documentation
-- Expected: ~13% denial rate when incomplete vs ~4% when complete
-- =============================================================================

SELECT
    'D1: Documentation Impact on Denial Rate' AS analysis_name,
    documentation_complete,
    COUNT(*)                                   AS total_requests,
    SUM(CASE WHEN decision = 'Denied' THEN 1 ELSE 0 END)
                                               AS initial_denied,
    ROUND(
        SUM(CASE WHEN decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                          AS initial_denial_rate_pct,
    ROUND(AVG(decision_time_days), 2)          AS avg_turnaround_days,
    SUM(CASE WHEN delayed_flag = TRUE THEN 1 ELSE 0 END)
                                               AS delayed_count,
    ROUND(
        SUM(CASE WHEN delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                          AS sla_breach_rate_pct
FROM pais.fact_prior_authorization
GROUP BY documentation_complete
ORDER BY documentation_complete DESC;

-- Expected: documentation_complete=FALSE should show ~3x higher denial rate
-- and ~40% longer turnaround time than documentation_complete=TRUE


-- Denial multiplier ratio — quantifies the causal relationship
SELECT
    'D1b: Documentation Denial Multiplier' AS analysis_name,
    ROUND(
        MAX(CASE WHEN documentation_complete = FALSE
            THEN SUM(CASE WHEN decision='Denied' THEN 1.0 ELSE 0 END)/COUNT(*) END)
        /
        NULLIF(
            MAX(CASE WHEN documentation_complete = TRUE
                THEN SUM(CASE WHEN decision='Denied' THEN 1.0 ELSE 0 END)/COUNT(*) END),
            0
        ), 2
    ) AS incomplete_vs_complete_denial_multiplier
FROM pais.fact_prior_authorization;


-- =============================================================================
-- D2: Submission Channel Impact on Denial Rate and Turnaround
-- Source: G05 — Fax submissions have 1.25x turnaround multiplier [ASSUMPTION]
--         Electronic submissions represent modern workflow; fax = legacy friction
-- =============================================================================

SELECT
    'D2: Submission Channel Analysis' AS analysis_name,
    submission_channel,
    COUNT(*)                           AS total_requests,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)
                                       AS pct_of_total,
    SUM(CASE WHEN decision = 'Denied' THEN 1 ELSE 0 END)
                                       AS denied_count,
    ROUND(
        SUM(CASE WHEN decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                  AS denial_rate_pct,
    ROUND(AVG(decision_time_days), 2)  AS avg_turnaround_days,
    ROUND(
        SUM(CASE WHEN delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                  AS sla_breach_rate_pct,
    SUM(CASE WHEN documentation_complete = FALSE THEN 1 ELSE 0 END)
                                       AS incomplete_doc_count,
    ROUND(
        SUM(CASE WHEN documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                  AS incomplete_doc_rate_pct
FROM pais.fact_prior_authorization
GROUP BY submission_channel
ORDER BY denial_rate_pct DESC;


-- =============================================================================
-- D3: Service Category Denial Patterns
-- Source: C01-C10 — service category base denial risk [ASSUMPTION]
-- Expected: Post-Acute/SNF highest (~10-16%), Outpatient lowest (~2-5%)
-- =============================================================================

SELECT
    'D3: Denial Rate by Service Category' AS analysis_name,
    s.service_category,
    COUNT(*)                              AS total_requests,
    SUM(CASE WHEN f.decision = 'Denied' THEN 1 ELSE 0 END)
                                          AS denied_count,
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                     AS initial_denial_rate_pct,
    ROUND(
        SUM(CASE WHEN f.final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                     AS final_denial_rate_pct,
    ROUND(AVG(f.decision_time_days), 2)   AS avg_turnaround_days,
    ROUND(
        SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                     AS sla_breach_rate_pct,
    ROUND(AVG(s.base_denial_risk) * 100, 1) AS assumption_base_denial_risk_pct,
    -- [ASSUMPTION C01-C10] — not measured; see synthetic_assumption_table.csv
    SUM(CASE WHEN f.documentation_complete = FALSE THEN 1 ELSE 0 END)
                                          AS incomplete_doc_count
FROM pais.fact_prior_authorization f
JOIN pais.dim_service s ON f.service_id = s.service_id
GROUP BY s.service_category
ORDER BY initial_denial_rate_pct DESC;


-- Service category heatmap: denial rate × volume (for dashboard bubble chart)
SELECT
    s.service_category,
    s.procedure_group,
    COUNT(*)                            AS request_volume,
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                   AS denial_rate_pct,
    ROUND(AVG(f.estimated_cost), 2)     AS avg_estimated_cost,
    ROUND(AVG(f.decision_time_days), 2) AS avg_turnaround_days
FROM pais.fact_prior_authorization f
JOIN pais.dim_service s ON f.service_id = s.service_id
GROUP BY s.service_category, s.procedure_group
ORDER BY denial_rate_pct DESC, request_volume DESC;


-- =============================================================================
-- D4: Reviewer Type Impact on Denial and Turnaround
-- Source: G04 — Automated reviewers have 0.4x denial probability (lower)
-- Expected: Automated has lowest denial rate; Medical Director has highest
-- =============================================================================

SELECT
    'D4: Reviewer Type Analysis' AS analysis_name,
    reviewer_type,
    COUNT(*)                      AS total_requests,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)
                                  AS pct_of_volume,
    SUM(CASE WHEN decision = 'Denied' THEN 1 ELSE 0 END)
                                  AS denied_count,
    ROUND(
        SUM(CASE WHEN decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                             AS denial_rate_pct,
    ROUND(AVG(decision_time_days), 2) AS avg_turnaround_days,
    ROUND(
        SUM(CASE WHEN delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                             AS sla_breach_rate_pct,
    SUM(CASE WHEN documentation_complete = FALSE THEN 1 ELSE 0 END)
                                  AS incomplete_doc_escalations
FROM pais.fact_prior_authorization
GROUP BY reviewer_type
ORDER BY denial_rate_pct ASC;

-- Expected: Automated < Clinical Staff < Medical Director for denial rate
-- Medical Director cases are the most complex (highest denial + longest TAT)


-- =============================================================================
-- D5: Multi-Factor Denial Risk Matrix
-- Combines documentation completeness, submission channel, and service category
-- to identify the highest-risk combinations for operational intervention.
-- =============================================================================

SELECT
    'D5: High-Risk Combination Matrix' AS analysis_name,
    s.service_category,
    f.submission_channel,
    f.documentation_complete,
    COUNT(*)                            AS request_count,
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                   AS denial_rate_pct,
    ROUND(AVG(f.decision_time_days), 2) AS avg_turnaround_days
FROM pais.fact_prior_authorization f
JOIN pais.dim_service s ON f.service_id = s.service_id
GROUP BY s.service_category, f.submission_channel, f.documentation_complete
HAVING COUNT(*) >= 20  -- filter low-volume combinations for stability
ORDER BY denial_rate_pct DESC
LIMIT 20;  -- top 20 highest-risk combinations


-- =============================================================================
-- D6: Standard vs Expedited Request Outcome Comparison
-- =============================================================================

SELECT
    'D6: Standard vs Expedited Outcomes' AS analysis_name,
    request_type,
    COUNT(*)                              AS total_requests,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)
                                          AS pct_of_total,
    ROUND(
        SUM(CASE WHEN decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                     AS initial_denial_rate_pct,
    ROUND(
        SUM(CASE WHEN final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                     AS final_denial_rate_pct,
    ROUND(AVG(decision_time_days), 2)     AS avg_turnaround_days,
    ROUND(
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY decision_time_days), 2
    )                                     AS p95_turnaround_days,
    SUM(CASE WHEN delayed_flag = TRUE THEN 1 ELSE 0 END)
                                          AS sla_breach_count,
    ROUND(
        SUM(CASE WHEN delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                     AS sla_breach_rate_pct
FROM pais.fact_prior_authorization
GROUP BY request_type;


-- =============================================================================
-- D7: SLA Breach Distribution — Days Over Limit
-- How far over the SLA threshold are delayed requests?
-- Enables prioritization of worst offenders for operational intervention.
-- =============================================================================

SELECT
    'D7: SLA Breach Severity Distribution' AS analysis_name,
    request_type,
    CASE
        WHEN (decision_time_days - allowed_days) <= 1
            THEN '1 day over'
        WHEN (decision_time_days - allowed_days) <= 3
            THEN '2-3 days over'
        WHEN (decision_time_days - allowed_days) <= 7
            THEN '4-7 days over'
        ELSE '8+ days over'
    END AS breach_severity_bucket,
    COUNT(*) AS request_count,
    ROUND(AVG(decision_time_days - allowed_days), 2) AS avg_days_over_sla
FROM pais.fact_prior_authorization
WHERE delayed_flag = TRUE
GROUP BY request_type,
    CASE
        WHEN (decision_time_days - allowed_days) <= 1 THEN '1 day over'
        WHEN (decision_time_days - allowed_days) <= 3 THEN '2-3 days over'
        WHEN (decision_time_days - allowed_days) <= 7 THEN '4-7 days over'
        ELSE '8+ days over'
    END
ORDER BY request_type, avg_days_over_sla;


-- =============================================================================
-- D8: Denial-to-Appeal-to-Overturn Funnel
-- Full operational funnel: total PA → denied → appealed → overturned
-- Supports the appeal funnel dashboard component.
-- =============================================================================

SELECT
    'D8: PA Appeal Funnel' AS analysis_name,
    total_requests,
    initial_denied,
    ROUND(initial_denied * 100.0 / total_requests, 2) AS initial_denial_rate_pct,
    appealed_count,
    ROUND(appealed_count * 100.0 / initial_denied, 2)  AS appeal_rate_of_denied_pct,
    overturned_count,
    ROUND(overturned_count * 100.0 / appealed_count, 2) AS overturn_rate_of_appealed_pct,
    final_denied_after_full_process,
    ROUND(final_denied_after_full_process * 100.0 / total_requests, 2)
                                                        AS final_denial_rate_pct,
    final_approved_after_full_process,
    ROUND(final_approved_after_full_process * 100.0 / total_requests, 2)
                                                        AS final_approval_rate_pct
FROM (
    SELECT
        COUNT(*)                                                    AS total_requests,
        SUM(CASE WHEN decision = 'Denied' THEN 1 ELSE 0 END)       AS initial_denied,
        SUM(CASE WHEN appealed = TRUE THEN 1 ELSE 0 END)           AS appealed_count,
        SUM(CASE WHEN final_outcome = 'Approved-After-Appeal'
            THEN 1 ELSE 0 END)                                      AS overturned_count,
        SUM(CASE WHEN final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1 ELSE 0 END)                                      AS final_denied_after_full_process,
        SUM(CASE WHEN final_outcome IN ('Approved','Pended-Resolved-Approved','Approved-After-Appeal')
            THEN 1 ELSE 0 END)                                      AS final_approved_after_full_process
    FROM pais.fact_prior_authorization
) funnel;


-- =============================================================================
-- D9: Member Risk Level Impact on PA Outcomes
-- =============================================================================

SELECT
    'D9: Member Risk Level vs Outcomes' AS analysis_name,
    m.risk_level,
    m.age_band,
    COUNT(*)                             AS total_requests,
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                    AS initial_denial_rate_pct,
    ROUND(
        SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                    AS sla_breach_rate_pct,
    ROUND(AVG(f.decision_time_days), 2)  AS avg_turnaround_days
FROM pais.fact_prior_authorization f
JOIN pais.dim_member m ON f.member_id = m.member_id
GROUP BY m.risk_level, m.age_band
ORDER BY m.risk_level, m.age_band;


-- =============================================================================
-- D10: Documentation-to-Denial Pathway by Service Category
-- Identifies which service categories are most impacted by documentation issues.
-- Operational use: target documentation training to highest-impact categories.
-- =============================================================================

SELECT
    'D10: Doc Failure Impact by Service Category' AS analysis_name,
    s.service_category,
    COUNT(*)                                        AS total_requests,
    SUM(CASE WHEN f.documentation_complete = FALSE THEN 1 ELSE 0 END)
                                                    AS incomplete_doc_count,
    ROUND(
        SUM(CASE WHEN f.documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                               AS incomplete_doc_rate_pct,
    -- Denial rate when docs complete
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' AND f.documentation_complete = TRUE
            THEN 1.0 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN f.documentation_complete = TRUE THEN 1 ELSE 0 END), 0) * 100, 2
    )                                               AS denial_rate_complete_docs_pct,
    -- Denial rate when docs incomplete
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' AND f.documentation_complete = FALSE
            THEN 1.0 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN f.documentation_complete = FALSE THEN 1 ELSE 0 END), 0) * 100, 2
    )                                               AS denial_rate_incomplete_docs_pct,
    -- Implied operational opportunity: denials that might be avoided with complete docs
    SUM(CASE WHEN f.decision = 'Denied'
             AND f.documentation_complete = FALSE
             AND f.denial_reason = 'Documentation Incomplete'
        THEN 1 ELSE 0 END)                          AS preventable_doc_denials
FROM pais.fact_prior_authorization f
JOIN pais.dim_service s ON f.service_id = s.service_id
GROUP BY s.service_category
ORDER BY preventable_doc_denials DESC, incomplete_doc_rate_pct DESC;
