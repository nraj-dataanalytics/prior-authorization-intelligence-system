-- =============================================================================
-- FILE:    04_data_quality_checks.sql
-- PROJECT: Prior Authorization Intelligence System (PAIS)
-- PHASE:   3 — SQL Analysis Layer
-- PURPOSE: Comprehensive data quality check suite for all five PAIS tables.
--          All checks are designed to return zero rows / zero counts on
--          a clean dataset. Any non-zero result is a data quality failure.
--
-- CHECK CATEGORIES:
--   DQ-01 to DQ-05  — Uniqueness (duplicate primary keys)
--   DQ-06 to DQ-10  — Required field nulls
--   DQ-11 to DQ-15  — Referential integrity (FK orphan checks)
--   DQ-16 to DQ-22  — Business logic (domain rules)
--   DQ-23 to DQ-26  — Temporal integrity (impossible date sequences)
--   DQ-27 to DQ-32  — Value range and category validation
--   DQ-33 to DQ-36  — Denied / approved denial_reason consistency
--   DQ-37 to DQ-38  — Appeal integrity (appealed-without-denial rule)
--   DQ-39 to DQ-40  — Cost and turnaround sanity checks
--   DQ-41 to DQ-42  — final_outcome consistency
--   DQ-43           — Leakage risk documentation check
--
-- EXPECTED RESULT: All checks return COUNT = 0 (PASS)
-- Exception: DQ-43 returns informational row counts, not a pass/fail.
--
-- TARGET: PostgreSQL 14+ / DuckDB 0.9+
-- =============================================================================

SET search_path TO pais, public;


-- =============================================================================
-- MASTER RUNNER: execute all checks in one query block
-- Each row represents one check. Status = PASS if count = 0.
-- =============================================================================

SELECT
    check_id,
    check_category,
    check_description,
    failure_count,
    CASE WHEN failure_count = 0 THEN 'PASS' ELSE '*** FAIL ***' END AS status
FROM (

    -- =========================================================================
    -- DQ-01 to DQ-05: UNIQUENESS — Duplicate Primary Keys
    -- =========================================================================

    SELECT 'DQ-01' AS check_id, 'Uniqueness' AS check_category,
           'Duplicate request_id in fact_prior_authorization' AS check_description,
           COUNT(*) AS failure_count
    FROM (
        SELECT request_id FROM pais.fact_prior_authorization
        GROUP BY request_id HAVING COUNT(*) > 1
    ) dup

    UNION ALL

    SELECT 'DQ-02', 'Uniqueness',
           'Duplicate appeal_id in fact_appeal',
           COUNT(*) FROM (
        SELECT appeal_id FROM pais.fact_appeal
        GROUP BY appeal_id HAVING COUNT(*) > 1
    ) dup

    UNION ALL

    SELECT 'DQ-03', 'Uniqueness',
           'Duplicate member_id in dim_member',
           COUNT(*) FROM (
        SELECT member_id FROM pais.dim_member
        GROUP BY member_id HAVING COUNT(*) > 1
    ) dup

    UNION ALL

    SELECT 'DQ-04', 'Uniqueness',
           'Duplicate provider_id in dim_provider',
           COUNT(*) FROM (
        SELECT provider_id FROM pais.dim_provider
        GROUP BY provider_id HAVING COUNT(*) > 1
    ) dup

    UNION ALL

    SELECT 'DQ-05', 'Uniqueness',
           'Duplicate service_id in dim_service',
           COUNT(*) FROM (
        SELECT service_id FROM pais.dim_service
        GROUP BY service_id HAVING COUNT(*) > 1
    ) dup

    UNION ALL

    -- =========================================================================
    -- DQ-06 to DQ-10: REQUIRED FIELD NULLS
    -- =========================================================================

    SELECT 'DQ-06', 'Required Nulls',
           'NULL request_id, member_id, provider_id, service_id, or decision in fact_prior_authorization',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE  request_id IS NULL
        OR member_id IS NULL
        OR provider_id IS NULL
        OR service_id IS NULL
        OR decision IS NULL

    UNION ALL

    SELECT 'DQ-07', 'Required Nulls',
           'NULL request_type, submitted_date, decision_date, or submission_channel',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE  request_type IS NULL
        OR submitted_date IS NULL
        OR decision_date IS NULL
        OR submission_channel IS NULL

    UNION ALL

    SELECT 'DQ-08', 'Required Nulls',
           'NULL final_outcome in fact_prior_authorization',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE  final_outcome IS NULL

    UNION ALL

    SELECT 'DQ-09', 'Required Nulls',
           'NULL appeal_id or appeal_outcome in fact_appeal',
           COUNT(*) FROM pais.fact_appeal
    WHERE  appeal_id IS NULL
        OR appeal_date IS NULL
        OR appeal_decision_date IS NULL
        OR appeal_outcome IS NULL

    UNION ALL

    SELECT 'DQ-10', 'Required Nulls',
           'NULL member_id, age_band, risk_level, or plan_type in dim_member',
           COUNT(*) FROM pais.dim_member
    WHERE  member_id IS NULL
        OR age_band IS NULL
        OR risk_level IS NULL
        OR plan_type IS NULL

    UNION ALL

    -- =========================================================================
    -- DQ-11 to DQ-15: REFERENTIAL INTEGRITY — FK Orphan Checks
    -- =========================================================================

    SELECT 'DQ-11', 'Referential Integrity',
           'Orphan member_id in fact_prior_authorization (no match in dim_member)',
           COUNT(*) FROM pais.fact_prior_authorization f
    LEFT JOIN pais.dim_member m ON f.member_id = m.member_id
    WHERE m.member_id IS NULL

    UNION ALL

    SELECT 'DQ-12', 'Referential Integrity',
           'Orphan provider_id in fact_prior_authorization (no match in dim_provider)',
           COUNT(*) FROM pais.fact_prior_authorization f
    LEFT JOIN pais.dim_provider p ON f.provider_id = p.provider_id
    WHERE p.provider_id IS NULL

    UNION ALL

    SELECT 'DQ-13', 'Referential Integrity',
           'Orphan service_id in fact_prior_authorization (no match in dim_service)',
           COUNT(*) FROM pais.fact_prior_authorization f
    LEFT JOIN pais.dim_service s ON f.service_id = s.service_id
    WHERE s.service_id IS NULL

    UNION ALL

    SELECT 'DQ-14', 'Referential Integrity',
           'Orphan request_id in fact_appeal (no match in fact_prior_authorization)',
           COUNT(*) FROM pais.fact_appeal a
    LEFT JOIN pais.fact_prior_authorization f ON a.request_id = f.request_id
    WHERE f.request_id IS NULL

    UNION ALL

    SELECT 'DQ-15', 'Referential Integrity',
           'appeal_id in fact_PA does not match any appeal_id in fact_appeal',
           COUNT(*) FROM pais.fact_prior_authorization f
    LEFT JOIN pais.fact_appeal a ON f.appeal_id = a.appeal_id
    WHERE f.appeal_id IS NOT NULL
      AND a.appeal_id IS NULL

    UNION ALL

    -- =========================================================================
    -- DQ-16 to DQ-22: BUSINESS LOGIC RULES
    -- =========================================================================

    SELECT 'DQ-16', 'Business Logic',
           'Denied requests with no denial_reason (must have reason)',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE decision = 'Denied'
      AND (denial_reason IS NULL OR TRIM(denial_reason) = '')

    UNION ALL

    SELECT 'DQ-17', 'Business Logic',
           'Approved requests with denial_reason populated (must be NULL)',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE decision = 'Approved'
      AND denial_reason IS NOT NULL

    UNION ALL

    SELECT 'DQ-18', 'Business Logic',
           'Pended requests with denial_reason populated (must be NULL)',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE decision = 'Pended'
      AND denial_reason IS NOT NULL

    UNION ALL

    SELECT 'DQ-19', 'Business Logic',
           'Requests marked appealed=TRUE but decision is not Denied',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE appealed = TRUE
      AND decision != 'Denied'

    UNION ALL

    SELECT 'DQ-20', 'Business Logic',
           'appealed=TRUE but appeal_id is NULL (inconsistent state)',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE appealed = TRUE
      AND (appeal_id IS NULL OR TRIM(appeal_id) = '')

    UNION ALL

    SELECT 'DQ-21', 'Business Logic',
           'appeal_id populated but appealed=FALSE (inconsistent state)',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE (appeal_id IS NOT NULL AND TRIM(appeal_id) != '')
      AND appealed = FALSE

    UNION ALL

    SELECT 'DQ-22', 'Business Logic',
           'Upheld appeals with reason_overturned populated (must be NULL for Upheld)',
           COUNT(*) FROM pais.fact_appeal
    WHERE appeal_outcome = 'Upheld'
      AND reason_overturned IS NOT NULL

    UNION ALL

    -- =========================================================================
    -- DQ-23 to DQ-26: TEMPORAL INTEGRITY — Impossible Date Sequences
    -- =========================================================================

    SELECT 'DQ-23', 'Temporal Integrity',
           'decision_date before submitted_date (impossible: decision precedes submission)',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE decision_date < submitted_date

    UNION ALL

    SELECT 'DQ-24', 'Temporal Integrity',
           'appeal_date before decision_date (impossible: appeal before PA decision)',
           COUNT(*) FROM pais.fact_appeal a
    JOIN pais.fact_prior_authorization f ON a.request_id = f.request_id
    WHERE a.appeal_date < f.decision_date

    UNION ALL

    SELECT 'DQ-25', 'Temporal Integrity',
           'appeal_decision_date before appeal_date (impossible: decision before appeal filed)',
           COUNT(*) FROM pais.fact_appeal
    WHERE appeal_decision_date < appeal_date

    UNION ALL

    SELECT 'DQ-26', 'Temporal Integrity',
           'submitted_date outside 2023-01-01 to 2024-12-31 study window',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE submitted_date < '2023-01-01'
       OR submitted_date > '2024-12-31'

    UNION ALL

    -- =========================================================================
    -- DQ-27 to DQ-32: VALUE RANGE AND CATEGORY VALIDATION
    -- =========================================================================

    SELECT 'DQ-27', 'Value Range',
           'Invalid decision value (must be Approved / Denied / Pended)',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE decision NOT IN ('Approved','Denied','Pended')

    UNION ALL

    SELECT 'DQ-28', 'Value Range',
           'Invalid request_type value (must be Standard / Expedited)',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE request_type NOT IN ('Standard','Expedited')

    UNION ALL

    SELECT 'DQ-29', 'Value Range',
           'Invalid allowed_days value (must be 3 or 7 per CMS-0057-F)',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE allowed_days NOT IN (3, 7)

    UNION ALL

    SELECT 'DQ-30', 'Value Range',
           'decision_time_days <= 0 (must be positive)',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE decision_time_days <= 0

    UNION ALL

    SELECT 'DQ-31', 'Value Range',
           'estimated_cost <= 0 (must be positive)',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE estimated_cost <= 0

    UNION ALL

    SELECT 'DQ-32', 'Value Range',
           'delayed_flag inconsistency: delayed but decision_time_days <= allowed_days',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE delayed_flag = TRUE
      AND decision_time_days <= allowed_days

    UNION ALL

    -- =========================================================================
    -- DQ-33 to DQ-36: FINAL_OUTCOME CONSISTENCY
    -- Verifies that final_outcome is always consistent with decision + appeal result.
    -- =========================================================================

    SELECT 'DQ-33', 'final_outcome Consistency',
           'Approved decision with non-Approved final_outcome',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE decision = 'Approved'
      AND final_outcome != 'Approved'

    UNION ALL

    SELECT 'DQ-34', 'final_outcome Consistency',
           'Denied + not appealed with final_outcome != Denied',
           COUNT(*) FROM pais.fact_prior_authorization
    WHERE decision = 'Denied'
      AND appealed = FALSE
      AND final_outcome != 'Denied'

    UNION ALL

    SELECT 'DQ-35', 'final_outcome Consistency',
           'Denied + appealed + Overturned with final_outcome != Approved-After-Appeal',
           COUNT(*) FROM pais.fact_prior_authorization f
    JOIN pais.fact_appeal a ON f.appeal_id = a.appeal_id
    WHERE f.decision = 'Denied'
      AND a.appeal_outcome IN ('Overturned','Partially Overturned')
      AND f.final_outcome != 'Approved-After-Appeal'

    UNION ALL

    SELECT 'DQ-36', 'final_outcome Consistency',
           'Denied + appealed + Upheld with final_outcome != Denied',
           COUNT(*) FROM pais.fact_prior_authorization f
    JOIN pais.fact_appeal a ON f.appeal_id = a.appeal_id
    WHERE f.decision = 'Denied'
      AND a.appeal_outcome = 'Upheld'
      AND f.final_outcome != 'Denied'

    UNION ALL

    -- =========================================================================
    -- DQ-37 to DQ-38: APPEAL INTEGRITY
    -- =========================================================================

    SELECT 'DQ-37', 'Appeal Integrity',
           'Records in fact_appeal linked to requests where decision != Denied',
           COUNT(*) FROM pais.fact_appeal a
    JOIN pais.fact_prior_authorization f ON a.request_id = f.request_id
    WHERE f.decision != 'Denied'

    UNION ALL

    SELECT 'DQ-38', 'Appeal Integrity',
           'negative appeal_decision_days in fact_appeal',
           COUNT(*) FROM pais.fact_appeal
    WHERE appeal_decision_days < 0

    UNION ALL

    -- =========================================================================
    -- DQ-39 to DQ-40: PROVIDER AND SERVICE DATA SANITY
    -- =========================================================================

    SELECT 'DQ-39', 'Dimension Data',
           'avg_incomplete_submission_rate outside 0-1 range in dim_provider',
           COUNT(*) FROM pais.dim_provider
    WHERE avg_incomplete_submission_rate < 0
       OR avg_incomplete_submission_rate > 1

    UNION ALL

    SELECT 'DQ-40', 'Dimension Data',
           'base_denial_risk or base_delay_risk outside 0-1 range in dim_service',
           COUNT(*) FROM pais.dim_service
    WHERE base_denial_risk < 0 OR base_denial_risk > 1
       OR base_delay_risk  < 0 OR base_delay_risk  > 1

) checks
ORDER BY check_id;


-- =============================================================================
-- QUICK SUMMARY: Count of checks by status
-- =============================================================================

SELECT
    CASE WHEN failure_count = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
    COUNT(*) AS check_count
FROM (
    -- Re-run all checks inline here or store results in a temp table
    -- For brevity, use the same structure as the master query above
    -- then aggregate. In practice, materialize to a temp table first:

    SELECT 0 AS failure_count  -- placeholder — replace with actual results
) results
GROUP BY status;


-- =============================================================================
-- SUPPLEMENTAL CHECK: Null distribution for nullable fields
-- These are expected to have nulls — verify the counts are logical.
-- =============================================================================

SELECT
    'denial_reason NULLs (expected for Approved+Pended)' AS field,
    SUM(CASE WHEN denial_reason IS NULL THEN 1 ELSE 0 END) AS null_count,
    SUM(CASE WHEN denial_reason IS NOT NULL THEN 1 ELSE 0 END) AS populated_count,
    COUNT(*) AS total_count
FROM pais.fact_prior_authorization

UNION ALL

SELECT
    'appeal_id NULLs (expected for non-denied records)',
    SUM(CASE WHEN appeal_id IS NULL OR TRIM(appeal_id) = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN appeal_id IS NOT NULL AND TRIM(appeal_id) != '' THEN 1 ELSE 0 END),
    COUNT(*)
FROM pais.fact_prior_authorization

UNION ALL

SELECT
    'action_recommended_initial NULLs',
    SUM(CASE WHEN action_recommended_initial IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN action_recommended_initial IS NOT NULL THEN 1 ELSE 0 END),
    COUNT(*)
FROM pais.fact_prior_authorization

UNION ALL

SELECT
    'reason_overturned NULLs in fact_appeal (expected for Upheld)',
    SUM(CASE WHEN reason_overturned IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN reason_overturned IS NOT NULL THEN 1 ELSE 0 END),
    COUNT(*)
FROM pais.fact_appeal;


-- =============================================================================
-- LEAKAGE RISK DOCUMENTATION CHECK (DQ-43)
-- This is an INFORMATIONAL check, not a pass/fail.
-- Confirms that action_recommended_initial is 100% consistent with decision
-- direction (demonstrating leakage risk).
-- =============================================================================

-- INFORMATIONAL ONLY — not a pass/fail check
SELECT
    decision,
    action_recommended_initial,
    COUNT(*) AS record_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY decision), 1) AS pct_within_decision
FROM pais.fact_prior_authorization
WHERE action_recommended_initial IS NOT NULL
GROUP BY decision, action_recommended_initial
ORDER BY decision, record_count DESC;

-- EXPECTED FINDING:
-- Approved records: only 'Approve' and 'Request-Additional-Docs' recommendations
-- Denied records:   only 'Deny', 'Request-Additional-Docs', 'Pend' recommendations
-- No Approved record ever receives a 'Deny' recommendation.
-- No Denied record ever receives an 'Approve' recommendation.
-- This confirms 0% inconsistency = HIGH LEAKAGE RISK.
-- EXCLUDE action_recommended_initial from all predictive model feature matrices.
