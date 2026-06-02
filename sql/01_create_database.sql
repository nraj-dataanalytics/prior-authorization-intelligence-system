-- =============================================================================
-- FILE:    01_create_database.sql
-- PROJECT: Prior Authorization Intelligence System (PAIS)
-- PHASE:   3 — SQL Analysis Layer
-- PURPOSE: Create the PAIS database and schema.
--          This script sets up the container for the mini data warehouse
--          that supports CMS-0057-F style prior authorization analytics.
--
-- TARGET DATABASE: PostgreSQL 14+ (also compatible with DuckDB 0.9+)
-- NOTE: For SQLite, skip this file — SQLite uses a single file as the database.
--       For DuckDB, run: CREATE DATABASE pais; USE pais;
--
-- DATA NOTE: ALL DATA IN THIS SYSTEM IS SYNTHETIC.
--            No PHI. No real patient records. No real payer data.
--            This is a portfolio analytics project built on calibrated
--            synthetic data to demonstrate healthcare payer analytics methodology.
--
-- CMS CONTEXT: CMS-0057-F (Interoperability and Prior Authorization Final Rule,
--              January 17, 2024) requires Medicare Advantage Organizations to
--              report prior authorization metrics publicly starting March 31, 2026
--              covering calendar year 2025. The PAIS SQL layer is designed to
--              produce all five required CMS-0057-F public metrics.
--
-- AUTHOR:  Raj Nandani — Healthcare Payer Analytics Portfolio Project
-- CREATED: 2026-05-31
-- =============================================================================


-- =============================================================================
-- SECTION 1: DATABASE CREATION
-- Run this block as a superuser or database owner.
-- Skip if the database already exists.
-- =============================================================================

-- PostgreSQL:
-- CREATE DATABASE pais
--     WITH
--     OWNER = postgres
--     ENCODING = 'UTF8'
--     LC_COLLATE = 'en_US.UTF-8'
--     LC_CTYPE = 'en_US.UTF-8'
--     TEMPLATE = template0
--     CONNECTION LIMIT = -1;

-- COMMENT ON DATABASE pais IS
--     'Prior Authorization Intelligence System — synthetic MA prior auth workflow data, 2023-2024';

-- DuckDB:
-- CREATE DATABASE IF NOT EXISTS pais;


-- =============================================================================
-- SECTION 2: SCHEMA CREATION
-- The "pais" schema isolates all project objects within the database.
-- Run connected to the pais database.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS pais
    AUTHORIZATION postgres;  -- change to your user if needed

COMMENT ON SCHEMA pais IS
    'Prior Authorization Intelligence System schema. '
    'Contains dim_member, dim_provider, dim_service, '
    'fact_prior_authorization, fact_appeal, and all analytical views. '
    'All data is synthetic. No PHI.';

-- Set default search path for this session
SET search_path TO pais, public;


-- =============================================================================
-- SECTION 3: SCHEMA INVENTORY (for documentation purposes)
-- =============================================================================

-- Tables to be created in 02_create_tables.sql:
--   pais.dim_member              (5,000 rows)  — Member dimension
--   pais.dim_provider            (1,000 rows)  — Provider dimension
--   pais.dim_service             (   40 rows)  — Service/procedure dimension
--   pais.fact_prior_authorization(25,000 rows) — Core PA workflow fact table
--   pais.fact_appeal             (  175 rows)  — Appeal fact table

-- Views to be created in 08_dashboard_views.sql:
--   pais.vw_cms_public_metrics          — CMS-0057-F five required metrics
--   pais.vw_monthly_volume_trend        — Request volume and denial rate by month
--   pais.vw_denial_by_service_category  — Denial rates by service type
--   pais.vw_provider_scorecard          — Provider-level PA performance metrics
--   pais.vw_appeal_funnel               — Denial-to-appeal-to-overturn funnel
--   pais.vw_sla_compliance_summary      — SLA breach rates by request type
--   pais.vw_documentation_impact        — Documentation completeness vs outcomes
--   pais.vw_submission_channel_analysis — Channel-level denial and delay rates
--   pais.vw_member_risk_profile         — Member risk level vs PA outcome
--   pais.vw_reviewer_type_outcomes      — Reviewer type vs decision patterns


-- =============================================================================
-- SECTION 4: UTILITY — VERIFY SETUP
-- =============================================================================

-- Run after executing this script to confirm schema was created:
SELECT schema_name, schema_owner
FROM information_schema.schemata
WHERE schema_name = 'pais';

-- Expected output:
-- schema_name | schema_owner
-- ------------+-------------
-- pais        | postgres
