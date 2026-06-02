-- =============================================================================
-- FILE:    03_load_data.sql
-- PROJECT: Prior Authorization Intelligence System (PAIS)
-- PHASE:   3 — SQL Analysis Layer
-- PURPOSE: Load the five synthetic CSV files into the PAIS schema tables.
--
-- PREREQUISITES:
--   1. Run 01_create_database.sql (database and schema must exist)
--   2. Run 02_create_tables.sql (tables must exist and be empty)
--   3. Update the file path variable below to match your environment
--
-- DIALECT NOTES:
--   PostgreSQL: Uses COPY command (server-side) or \copy (psql client-side)
--   DuckDB:     Uses INSERT INTO ... SELECT * FROM read_csv_auto(...)
--   SQLite:     Use .mode csv / .import commands in sqlite3 CLI
--
-- LOADING ORDER (respects foreign key constraints):
--   1. dim_member              (no FKs — load first)
--   2. dim_provider            (no FKs — load first)
--   3. dim_service             (no FKs — load first)
--   4. fact_prior_authorization (FKs to member, provider, service)
--   5. fact_appeal             (FK to fact_prior_authorization — load last)
--
-- ALL DATA IS SYNTHETIC. No PHI. No real patient or provider records.
-- =============================================================================

SET search_path TO pais, public;


-- =============================================================================
-- SECTION 0: SET YOUR FILE PATH
-- Update this path to the directory containing the CSV files.
-- =============================================================================

-- PostgreSQL: replace with your actual absolute path
-- Example Linux:   /home/user/pais/data/
-- Example Windows: C:/Users/YourName/Desktop/Project/data/
-- Used in COPY statements below as: :'data_path' || 'filename.csv'

-- For psql interactive session, set the variable:
-- \set data_path '/full/path/to/Prior Authorization Intelligence System/'

-- For DuckDB, set the path inline in read_csv_auto() calls (see Section 2).


-- =============================================================================
-- SECTION 1: POSTGRESQL LOAD (using COPY)
-- =============================================================================
-- If running via psql, replace the path placeholders with your actual directory.
-- If running from pgAdmin or another client, use absolute paths directly.

/*  -------- Uncomment and run in PostgreSQL environment --------

-- 1. Load dim_member
COPY pais.dim_member (
    member_id, age_band, gender, plan_type, region,
    risk_level, chronic_condition_count, member_tenure_months
)
FROM '/your/path/members.csv'
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',', NULL '');

-- 2. Load dim_provider
COPY pais.dim_provider (
    provider_id, provider_type, region, network_status,
    prior_auth_volume_band, avg_incomplete_submission_rate,
    avg_response_time_days, provider_risk_segment
)
FROM '/your/path/providers.csv'
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',', NULL '');

-- 3. Load dim_service
COPY pais.dim_service (
    service_id, service_category, procedure_group, prior_auth_required,
    clinical_review_required, automation_eligible, base_cost_min,
    base_cost_max, base_denial_risk, base_delay_risk
)
FROM '/your/path/services.csv'
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',', NULL '');

-- 4. Load fact_prior_authorization
-- NOTE: CSV column order must match table column order, or specify column list.
-- The CSV contains the following 25 columns in order:
--   request_id, member_id, provider_id, service_id, request_type,
--   submitted_date, submitted_day_of_week, submission_channel,
--   documentation_complete, estimated_cost, previous_denial_history,
--   auto_eligible, clinical_review_required, reviewer_type, decision,
--   decision_date, decision_time_days, allowed_days, delayed_flag,
--   denial_reason, pended_flag, final_outcome, appealed, appeal_id,
--   action_recommended_initial
COPY pais.fact_prior_authorization
FROM '/your/path/prior_auth_requests.csv'
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',', NULL '');

-- 5. Load fact_appeal
COPY pais.fact_appeal (
    appeal_id, request_id, appeal_date, appeal_decision_date,
    appeal_decision_days, appeal_outcome, reason_overturned,
    additional_documentation_submitted, final_status_after_appeal
)
FROM '/your/path/appeals.csv'
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',', NULL '');

*/  -------- End PostgreSQL block --------


-- =============================================================================
-- SECTION 2: DUCKDB LOAD (using read_csv_auto)
-- DuckDB can read CSVs directly with automatic type inference.
-- Replace the path placeholders with your actual directory.
-- =============================================================================

/*  -------- Uncomment and run in DuckDB environment --------

SET data_path = '/your/path/Prior Authorization Intelligence System/';

-- 1. Load dim_member
INSERT INTO pais.dim_member
SELECT * FROM read_csv_auto(
    '/your/path/Prior Authorization Intelligence System/members.csv',
    header = true,
    types = {
        'member_id': 'VARCHAR',
        'age_band': 'VARCHAR',
        'gender': 'VARCHAR',
        'plan_type': 'VARCHAR',
        'region': 'VARCHAR',
        'risk_level': 'VARCHAR',
        'chronic_condition_count': 'INTEGER',
        'member_tenure_months': 'INTEGER'
    }
);

-- 2. Load dim_provider
INSERT INTO pais.dim_provider
SELECT * FROM read_csv_auto(
    '/your/path/providers.csv',
    header = true
);

-- 3. Load dim_service
INSERT INTO pais.dim_service
SELECT * FROM read_csv_auto(
    '/your/path/services.csv',
    header = true
);

-- 4. Load fact_prior_authorization
INSERT INTO pais.fact_prior_authorization
SELECT
    request_id, member_id, provider_id, service_id,
    request_type,
    CAST(submitted_date AS DATE),
    submitted_day_of_week,
    submission_channel,
    CAST(documentation_complete AS BOOLEAN),
    CAST(estimated_cost AS NUMERIC),
    CAST(previous_denial_history AS BOOLEAN),
    CAST(auto_eligible AS BOOLEAN),
    CAST(clinical_review_required AS BOOLEAN),
    reviewer_type, decision,
    CAST(decision_date AS DATE),
    CAST(decision_time_days AS NUMERIC),
    CAST(allowed_days AS INTEGER),
    CAST(delayed_flag AS BOOLEAN),
    denial_reason,
    CAST(pended_flag AS BOOLEAN),
    final_outcome,
    CAST(appealed AS BOOLEAN),
    NULLIF(appeal_id, '') AS appeal_id,
    NULLIF(action_recommended_initial, '') AS action_recommended_initial
FROM read_csv_auto(
    '/your/path/prior_auth_requests.csv',
    header = true,
    nullstr = ''
);

-- 5. Load fact_appeal
INSERT INTO pais.fact_appeal
SELECT
    appeal_id, request_id,
    CAST(appeal_date AS DATE),
    CAST(appeal_decision_date AS DATE),
    CAST(appeal_decision_days AS INTEGER),
    appeal_outcome,
    NULLIF(reason_overturned, '') AS reason_overturned,
    CAST(additional_documentation_submitted AS BOOLEAN),
    final_status_after_appeal
FROM read_csv_auto(
    '/your/path/appeals.csv',
    header = true,
    nullstr = ''
);

*/  -------- End DuckDB block --------


-- =============================================================================
-- SECTION 3: POST-LOAD VERIFICATION
-- Run these counts after loading to confirm all rows were ingested correctly.
-- Expected: 5000 | 1000 | 40 | 25000 | 175
-- =============================================================================

SELECT 'dim_member'               AS table_name, COUNT(*) AS row_count FROM pais.dim_member
UNION ALL
SELECT 'dim_provider'             AS table_name, COUNT(*) AS row_count FROM pais.dim_provider
UNION ALL
SELECT 'dim_service'              AS table_name, COUNT(*) AS row_count FROM pais.dim_service
UNION ALL
SELECT 'fact_prior_authorization' AS table_name, COUNT(*) AS row_count FROM pais.fact_prior_authorization
UNION ALL
SELECT 'fact_appeal'              AS table_name, COUNT(*) AS row_count FROM pais.fact_appeal
ORDER BY table_name;

-- Expected result:
-- table_name                  | row_count
-- ----------------------------+----------
-- dim_member                  |     5,000
-- dim_provider                |     1,000
-- dim_service                 |        40
-- fact_prior_authorization    |    25,000
-- fact_appeal                 |       175


-- =============================================================================
-- SECTION 4: SPOT-CHECK JOINS
-- Verify that all FK relationships resolve cleanly (zero orphan records).
-- =============================================================================

-- Check 1: All member_ids in fact table join to dim_member
SELECT
    'member FK' AS check_name,
    COUNT(*) AS orphan_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM pais.fact_prior_authorization f
LEFT JOIN pais.dim_member m ON f.member_id = m.member_id
WHERE m.member_id IS NULL;

-- Check 2: All provider_ids in fact table join to dim_provider
SELECT
    'provider FK' AS check_name,
    COUNT(*) AS orphan_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM pais.fact_prior_authorization f
LEFT JOIN pais.dim_provider p ON f.provider_id = p.provider_id
WHERE p.provider_id IS NULL;

-- Check 3: All service_ids in fact table join to dim_service
SELECT
    'service FK' AS check_name,
    COUNT(*) AS orphan_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM pais.fact_prior_authorization f
LEFT JOIN pais.dim_service s ON f.service_id = s.service_id
WHERE s.service_id IS NULL;

-- Check 4: All appeal request_ids join to fact_prior_authorization
SELECT
    'appeal → PA FK' AS check_name,
    COUNT(*) AS orphan_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM pais.fact_appeal a
LEFT JOIN pais.fact_prior_authorization f ON a.request_id = f.request_id
WHERE f.request_id IS NULL;

-- Expected: all 4 checks return orphan_count = 0 and status = 'PASS'


-- =============================================================================
-- SECTION 5: DATE RANGE VERIFICATION
-- Confirm data covers exactly the expected 24-month study window.
-- =============================================================================

SELECT
    MIN(submitted_date)  AS earliest_request,
    MAX(submitted_date)  AS latest_request,
    COUNT(DISTINCT EXTRACT(YEAR FROM submitted_date)) AS year_count,
    SUM(CASE WHEN EXTRACT(YEAR FROM submitted_date) = 2023 THEN 1 ELSE 0 END) AS requests_2023,
    SUM(CASE WHEN EXTRACT(YEAR FROM submitted_date) = 2024 THEN 1 ELSE 0 END) AS requests_2024
FROM pais.fact_prior_authorization;

-- Expected:
-- earliest_request: 2023-01-01 (approximately)
-- latest_request:   2024-12-31 (approximately)
-- year_count:       2
-- requests_2023:    ~11,700  (47% of 25,000)
-- requests_2024:    ~13,300  (53% of 25,000 — 6% YoY growth per A25/KFF S3/S4)
