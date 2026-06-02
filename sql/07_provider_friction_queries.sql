-- =============================================================================
-- FILE:    07_provider_friction_queries.sql
-- PROJECT: Prior Authorization Intelligence System (PAIS)
-- PHASE:   3 — SQL Analysis Layer
-- PURPOSE: Provider-level PA performance analysis.
--          Identifies high-friction providers, network effects, and
--          documentation failure patterns at the provider level.
--          Supports the provider scorecard dashboard component.
--
-- ANALYTICAL QUESTIONS ANSWERED:
--   P1: Which provider types have the highest denial and delay rates?
--   P2: What is the impact of network status (In-Network vs Out-of-Network)?
--   P3: How does provider risk segment predict PA outcomes?
--   P4: What is the provider-level PA volume distribution?
--   P5: Which individual providers are highest-friction (top 10)?
--   P6: What is the documentation failure rate by provider type?
--   P7: How does provider region affect PA patterns?
--   P8: Combined provider risk scorecard (ranked, weighted)
--
-- FRAMING NOTE:
--   These queries are designed to support workflow prioritization and
--   targeted documentation outreach — NOT to make coverage or care decisions.
--   Provider friction scores are operational workflow metrics only.
--
-- TARGET: PostgreSQL 14+ / DuckDB 0.9+
-- =============================================================================

SET search_path TO pais, public;


-- =============================================================================
-- P1: Denial and Delay Rate by Provider Type
-- =============================================================================

SELECT
    'P1: Outcomes by Provider Type' AS analysis_name,
    p.provider_type,
    COUNT(f.request_id)              AS total_requests,
    ROUND(COUNT(f.request_id) * 100.0 / SUM(COUNT(f.request_id)) OVER (), 2)
                                     AS pct_of_total_volume,
    SUM(CASE WHEN f.decision = 'Denied' THEN 1 ELSE 0 END)
                                     AS denied_count,
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                AS initial_denial_rate_pct,
    ROUND(
        SUM(CASE WHEN f.final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                AS final_denial_rate_pct,
    ROUND(AVG(f.decision_time_days), 2) AS avg_turnaround_days,
    ROUND(
        SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                AS sla_breach_rate_pct,
    ROUND(
        SUM(CASE WHEN f.documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                AS doc_incomplete_rate_pct
FROM pais.fact_prior_authorization f
JOIN pais.dim_provider p ON f.provider_id = p.provider_id
GROUP BY p.provider_type
ORDER BY initial_denial_rate_pct DESC;


-- =============================================================================
-- P2: Network Status Impact (In-Network vs Out-of-Network)
-- Source: G03 — Out-of-Network requests have 1.8x denial probability [ASSUMPTION]
-- Expected: Out-of-Network denial rate materially higher than In-Network
-- =============================================================================

SELECT
    'P2: Network Status Impact' AS analysis_name,
    p.network_status,
    COUNT(f.request_id)          AS total_requests,
    ROUND(COUNT(f.request_id) * 100.0 / SUM(COUNT(f.request_id)) OVER (), 2)
                                 AS pct_of_volume,
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                            AS initial_denial_rate_pct,
    ROUND(
        SUM(CASE WHEN f.final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                            AS final_denial_rate_pct,
    ROUND(AVG(f.decision_time_days), 2) AS avg_turnaround_days,
    ROUND(
        SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                            AS sla_breach_rate_pct,
    ROUND(
        SUM(CASE WHEN f.documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                            AS doc_incomplete_rate_pct
FROM pais.fact_prior_authorization f
JOIN pais.dim_provider p ON f.provider_id = p.provider_id
GROUP BY p.network_status
ORDER BY p.network_status;

-- Out-of-Network denial rate should be ~1.8x In-Network rate (Assumption G03)


-- =============================================================================
-- P3: Provider Risk Segment Performance
-- Source: G02 — High-Risk providers have 1.5x denial probability [ASSUMPTION]
-- Risk segments derived from avg_incomplete_submission_rate + avg_response_time_days
-- =============================================================================

SELECT
    'P3: Provider Risk Segment Outcomes' AS analysis_name,
    p.provider_risk_segment,
    p.network_status,
    COUNT(f.request_id)                  AS total_requests,
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                    AS initial_denial_rate_pct,
    ROUND(
        SUM(CASE WHEN f.documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                    AS doc_incomplete_rate_pct,
    ROUND(AVG(f.decision_time_days), 2)  AS avg_turnaround_days,
    ROUND(
        SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                    AS sla_breach_rate_pct
FROM pais.fact_prior_authorization f
JOIN pais.dim_provider p ON f.provider_id = p.provider_id
GROUP BY p.provider_risk_segment, p.network_status
ORDER BY p.provider_risk_segment, p.network_status;


-- =============================================================================
-- P4: Provider Volume Distribution
-- Answers: Is PA volume concentrated among a small number of providers?
-- =============================================================================

SELECT
    'P4: Provider Volume Distribution' AS analysis_name,
    p.prior_auth_volume_band,
    COUNT(DISTINCT p.provider_id) AS provider_count,
    SUM(request_counts.request_count) AS total_requests,
    ROUND(AVG(request_counts.request_count), 1) AS avg_requests_per_provider,
    MIN(request_counts.request_count) AS min_requests,
    MAX(request_counts.request_count) AS max_requests
FROM pais.dim_provider p
JOIN (
    SELECT provider_id, COUNT(*) AS request_count
    FROM pais.fact_prior_authorization
    GROUP BY provider_id
) request_counts ON p.provider_id = request_counts.provider_id
GROUP BY p.prior_auth_volume_band
ORDER BY
    CASE p.prior_auth_volume_band
        WHEN 'Very High' THEN 1
        WHEN 'High'      THEN 2
        WHEN 'Medium'    THEN 3
        WHEN 'Low'       THEN 4
    END;


-- =============================================================================
-- P5: Top 10 Highest-Friction Providers (by combined denial + delay rate)
-- Operational use: Target these providers for documentation outreach.
-- FRAMING: This is a workflow prioritization tool — not a punitive ranking.
-- =============================================================================

SELECT
    'P5: Top 10 High-Friction Providers' AS analysis_name,
    f.provider_id,
    p.provider_type,
    p.provider_risk_segment,
    p.network_status,
    p.prior_auth_volume_band,
    COUNT(f.request_id)                  AS total_requests,
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                    AS denial_rate_pct,
    ROUND(
        SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                    AS sla_breach_rate_pct,
    ROUND(
        SUM(CASE WHEN f.documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                    AS doc_incomplete_rate_pct,
    -- Composite friction score: weighted average of denial + delay + doc failure
    ROUND(
        (
            SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 0.40
          + SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 0.30
          + SUM(CASE WHEN f.documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 0.30
        ) * 100, 2
    )                                    AS friction_score_0_to_100
FROM pais.fact_prior_authorization f
JOIN pais.dim_provider p ON f.provider_id = p.provider_id
GROUP BY f.provider_id, p.provider_type, p.provider_risk_segment,
         p.network_status, p.prior_auth_volume_band
HAVING COUNT(f.request_id) >= 10  -- minimum volume for stable rates
ORDER BY friction_score_0_to_100 DESC
LIMIT 10;

-- NOTE: Friction score = 40% denial weight + 30% delay weight + 30% doc failure weight.
-- Weights are illustrative [ASSUMPTION] — adjust in Phase 4 based on business priorities.
-- This score is for operational workflow prioritization only.


-- =============================================================================
-- P6: Documentation Failure Rate by Provider Type
-- Identifies which provider types need targeted documentation support.
-- =============================================================================

SELECT
    'P6: Documentation Failure Rate by Provider Type' AS analysis_name,
    p.provider_type,
    COUNT(f.request_id)                               AS total_requests,
    SUM(CASE WHEN f.documentation_complete = FALSE THEN 1 ELSE 0 END)
                                                      AS incomplete_count,
    ROUND(
        SUM(CASE WHEN f.documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                 AS incomplete_rate_pct,
    -- Of the incomplete submissions, what % led to denial?
    SUM(CASE WHEN f.documentation_complete = FALSE AND f.decision = 'Denied' THEN 1 ELSE 0 END)
                                                      AS incomplete_and_denied,
    ROUND(
        SUM(CASE WHEN f.documentation_complete = FALSE AND f.decision = 'Denied' THEN 1.0 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN f.documentation_complete = FALSE THEN 1 ELSE 0 END), 0) * 100, 2
    )                                                 AS denial_rate_among_incomplete_pct,
    ROUND(AVG(p.avg_incomplete_submission_rate) * 100, 2)
                                                      AS avg_provider_incomplete_rate_pct
FROM pais.fact_prior_authorization f
JOIN pais.dim_provider p ON f.provider_id = p.provider_id
GROUP BY p.provider_type
ORDER BY incomplete_rate_pct DESC;


-- =============================================================================
-- P7: Geographic Region Analysis
-- =============================================================================

SELECT
    'P7: PA Outcomes by Provider Region' AS analysis_name,
    p.region                              AS provider_region,
    COUNT(f.request_id)                   AS total_requests,
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                     AS denial_rate_pct,
    ROUND(
        SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                     AS sla_breach_rate_pct,
    ROUND(AVG(f.decision_time_days), 2)   AS avg_turnaround_days,
    ROUND(
        SUM(CASE WHEN f.documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                     AS doc_incomplete_rate_pct
FROM pais.fact_prior_authorization f
JOIN pais.dim_provider p ON f.provider_id = p.provider_id
GROUP BY p.region
ORDER BY denial_rate_pct DESC;


-- =============================================================================
-- P8: Complete Provider Scorecard
-- Full one-row-per-provider performance summary for dashboard drillthrough.
-- This is the source table for the provider scorecard visual in Phase 4.
-- =============================================================================

SELECT
    f.provider_id,
    p.provider_type,
    p.region,
    p.network_status,
    p.prior_auth_volume_band,
    p.provider_risk_segment,
    ROUND(p.avg_incomplete_submission_rate * 100, 2) AS provider_avg_incomplete_rate_pct,
    ROUND(p.avg_response_time_days, 2)               AS provider_avg_response_days,

    -- PA volume metrics
    COUNT(f.request_id)                              AS total_pa_requests,

    -- Decision outcomes
    SUM(CASE WHEN f.decision = 'Approved' THEN 1 ELSE 0 END) AS approved_count,
    SUM(CASE WHEN f.decision = 'Denied'   THEN 1 ELSE 0 END) AS denied_count,
    SUM(CASE WHEN f.decision = 'Pended'   THEN 1 ELSE 0 END) AS pended_count,

    -- Rates
    ROUND(
        SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                AS denial_rate_pct,
    ROUND(
        SUM(CASE WHEN f.final_outcome IN ('Denied','Pended-Resolved-Denied')
            THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                AS final_denial_rate_pct,
    ROUND(
        SUM(CASE WHEN f.documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                AS doc_incomplete_rate_pct,
    ROUND(
        SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                                AS sla_breach_rate_pct,

    -- Turnaround
    ROUND(AVG(f.decision_time_days), 2)             AS avg_turnaround_days,

    -- Appeals
    SUM(CASE WHEN f.appealed = TRUE THEN 1 ELSE 0 END) AS appeal_count,

    -- Friction score
    ROUND(
        (
            SUM(CASE WHEN f.decision = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 0.40
          + SUM(CASE WHEN f.delayed_flag = TRUE THEN 1.0 ELSE 0 END) / COUNT(*) * 0.30
          + SUM(CASE WHEN f.documentation_complete = FALSE THEN 1.0 ELSE 0 END) / COUNT(*) * 0.30
        ) * 100, 2
    )                                                AS friction_score

FROM pais.fact_prior_authorization f
JOIN pais.dim_provider p ON f.provider_id = p.provider_id
GROUP BY
    f.provider_id, p.provider_type, p.region, p.network_status,
    p.prior_auth_volume_band, p.provider_risk_segment,
    p.avg_incomplete_submission_rate, p.avg_response_time_days
HAVING COUNT(f.request_id) >= 5  -- minimum volume threshold
ORDER BY friction_score DESC;
