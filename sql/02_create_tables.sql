-- =============================================================================
-- FILE:    02_create_tables.sql
-- PROJECT: Prior Authorization Intelligence System (PAIS)
-- PHASE:   3 — SQL Analysis Layer
-- PURPOSE: Create all five tables of the PAIS mini data warehouse.
--          Uses a star schema: three dimension tables + two fact tables.
--
-- SCHEMA DESIGN:
--   dim_member              — Who submitted the PA (member demographics)
--   dim_provider            — Who requested the PA (provider characteristics)
--   dim_service             — What service was requested (procedure/category)
--   fact_prior_authorization— Core PA workflow event (25,000 rows)
--   fact_appeal             — Appeal outcomes for denied requests (175 rows)
--
-- KEY DESIGN DECISIONS:
--   1. decision vs final_outcome:
--      - "decision" = initial 3-state routing (Approved / Denied / Pended)
--      - "final_outcome" = final administrative outcome after pend resolution
--        and appeals. Use final_outcome for CMS-0057-F benchmark comparisons.
--      - See: KFF MA PA 2024 (S3): 92.3% approval rate is a FINAL OUTCOME rate.
--
--   2. Leakage-risk columns are flagged with [LEAKAGE RISK] in comments.
--      These columns must NOT be used as features in any predictive model
--      that predicts decision, delayed_flag, or final_outcome.
--
--   3. All data is SYNTHETIC. No PHI. No real patient or provider records.
--
-- TARGET: PostgreSQL 14+ / DuckDB 0.9+
-- Run 01_create_database.sql first.
-- =============================================================================

SET search_path TO pais, public;


-- =============================================================================
-- DROP ORDER: child tables first, then parents (respects FK constraints)
-- =============================================================================

DROP TABLE IF EXISTS pais.fact_appeal             CASCADE;
DROP TABLE IF EXISTS pais.fact_prior_authorization CASCADE;
DROP TABLE IF EXISTS pais.dim_service             CASCADE;
DROP TABLE IF EXISTS pais.dim_provider            CASCADE;
DROP TABLE IF EXISTS pais.dim_member              CASCADE;


-- =============================================================================
-- TABLE 1: dim_member
-- Source CSV: members.csv (5,000 rows)
-- Purpose: Member demographic and risk profile attributes.
--          Used to segment PA outcomes by age, plan type, and risk level.
-- =============================================================================

CREATE TABLE pais.dim_member (
    member_id               VARCHAR(20)     NOT NULL,
    age_band                VARCHAR(20)     NOT NULL,   -- e.g. '65-74', '75-84', '85+'
    gender                  VARCHAR(10)     NOT NULL,   -- 'Male', 'Female'
    plan_type               VARCHAR(30)     NOT NULL,   -- 'HMO', 'PPO', 'PFFS', 'SNP'
    region                  VARCHAR(20)     NOT NULL,   -- 'Northeast', 'Southeast', etc.
    risk_level              VARCHAR(20)     NOT NULL,   -- 'Low', 'Moderate', 'High'
    chronic_condition_count SMALLINT        NOT NULL,   -- 0-8
    member_tenure_months    SMALLINT        NOT NULL,   -- months enrolled in plan

    -- Constraints
    CONSTRAINT pk_dim_member
        PRIMARY KEY (member_id),
    CONSTRAINT chk_dim_member_age_band
        CHECK (age_band IN ('Under 65','65-74','75-84','85+')),
    CONSTRAINT chk_dim_member_gender
        CHECK (gender IN ('Male','Female')),
    CONSTRAINT chk_dim_member_plan_type
        CHECK (plan_type IN ('HMO','PPO','PFFS','SNP')),
    CONSTRAINT chk_dim_member_risk_level
        CHECK (risk_level IN ('Low','Moderate','High')),
    CONSTRAINT chk_dim_member_chronic_count
        CHECK (chronic_condition_count >= 0 AND chronic_condition_count <= 15),
    CONSTRAINT chk_dim_member_tenure
        CHECK (member_tenure_months >= 0)
);

COMMENT ON TABLE pais.dim_member IS
    'Member dimension. 5,000 synthetic MA members calibrated to CMS enrollment demographics. '
    'No PHI. No real patient records.';
COMMENT ON COLUMN pais.dim_member.risk_level IS
    'Synthetic risk classification. High risk members have elevated PA denial probability '
    'due to documentation complexity and clinical review requirements.';


-- =============================================================================
-- TABLE 2: dim_provider
-- Source CSV: providers.csv (1,000 rows)
-- Purpose: Provider characteristics affecting PA patterns.
--          Used to identify high-friction providers and network effects.
-- =============================================================================

CREATE TABLE pais.dim_provider (
    provider_id                     VARCHAR(20)     NOT NULL,
    provider_type                   VARCHAR(30)     NOT NULL,   -- 'Hospital', 'Physician Group', etc.
    region                          VARCHAR(20)     NOT NULL,
    network_status                  VARCHAR(20)     NOT NULL,   -- 'In-Network', 'Out-of-Network'
    prior_auth_volume_band          VARCHAR(20)     NOT NULL,   -- 'Low', 'Medium', 'High', 'Very High'
    avg_incomplete_submission_rate  NUMERIC(5,4)    NOT NULL,   -- 0.00-1.00
    avg_response_time_days          NUMERIC(5,2)    NOT NULL,   -- average days to respond to additional doc requests
    provider_risk_segment           VARCHAR(20)     NOT NULL,   -- 'Low-Risk', 'Moderate-Risk', 'High-Risk'

    -- Constraints
    CONSTRAINT pk_dim_provider
        PRIMARY KEY (provider_id),
    CONSTRAINT chk_dim_provider_network_status
        CHECK (network_status IN ('In-Network','Out-of-Network')),
    CONSTRAINT chk_dim_provider_volume_band
        CHECK (prior_auth_volume_band IN ('Low','Medium','High','Very High')),
    CONSTRAINT chk_dim_provider_risk_segment
        CHECK (provider_risk_segment IN ('Low-Risk','Moderate-Risk','High-Risk')),
    CONSTRAINT chk_dim_provider_incomplete_rate
        CHECK (avg_incomplete_submission_rate >= 0 AND avg_incomplete_submission_rate <= 1),
    CONSTRAINT chk_dim_provider_response_time
        CHECK (avg_response_time_days >= 0)
);

COMMENT ON TABLE pais.dim_provider IS
    'Provider dimension. 1,000 synthetic providers. 88% In-Network, 12% Out-of-Network. '
    'provider_risk_segment is derived from avg_incomplete_submission_rate and avg_response_time_days. '
    'High-Risk providers have 1.5x denial probability multiplier (Assumption G02). No real NPIs.';
COMMENT ON COLUMN pais.dim_provider.provider_risk_segment IS
    'Synthetic risk tier: Low-Risk = low incomplete rate + fast response; '
    'High-Risk = high incomplete rate + slow response. '
    'Used for provider scorecard and friction analysis. [ASSUMPTION G02]';


-- =============================================================================
-- TABLE 3: dim_service
-- Source CSV: services.csv (40 rows)
-- Purpose: Service/procedure characteristics including clinical review requirements
--          and assumption-based denial risk profiles.
-- =============================================================================

CREATE TABLE pais.dim_service (
    service_id              VARCHAR(20)     NOT NULL,
    service_category        VARCHAR(50)     NOT NULL,   -- 'Advanced Imaging', 'Post-Acute / SNF', etc.
    procedure_group         VARCHAR(100)    NOT NULL,   -- specific procedure description
    prior_auth_required     BOOLEAN         NOT NULL,
    clinical_review_required BOOLEAN        NOT NULL,
    automation_eligible     BOOLEAN         NOT NULL,   -- eligible for automated approval
    base_cost_min           NUMERIC(10,2)   NOT NULL,   -- estimated cost range min
    base_cost_max           NUMERIC(10,2)   NOT NULL,   -- estimated cost range max
    base_denial_risk        NUMERIC(5,4)    NOT NULL,   -- [ASSUMPTION C01-C10] base denial probability
    base_delay_risk         NUMERIC(5,4)    NOT NULL,   -- [ASSUMPTION] base probability of SLA delay

    -- Constraints
    CONSTRAINT pk_dim_service
        PRIMARY KEY (service_id),
    CONSTRAINT chk_dim_service_base_denial_risk
        CHECK (base_denial_risk >= 0 AND base_denial_risk <= 1),
    CONSTRAINT chk_dim_service_base_delay_risk
        CHECK (base_delay_risk >= 0 AND base_delay_risk <= 1),
    CONSTRAINT chk_dim_service_cost_range
        CHECK (base_cost_min >= 0 AND base_cost_max >= base_cost_min)
);

COMMENT ON TABLE pais.dim_service IS
    'Service dimension. 40 synthetic service/procedure records across 10 categories. '
    'base_denial_risk values are ASSUMPTIONS (C01-C10) — no CMS public data provides '
    'PA denial rates broken down by service type. See synthetic_assumption_table.csv.';
COMMENT ON COLUMN pais.dim_service.base_denial_risk IS
    '[ASSUMPTION C01-C10] Service-category denial risk. Values informed by OIG S5 narrative '
    'context (Post-Acute/SNF and Advanced Imaging named as high-denial categories) but are '
    'NOT measured rates from public data. Range: 0.05 (Outpatient) to 0.16 (Post-Acute/SNF).';


-- =============================================================================
-- TABLE 4: fact_prior_authorization
-- Source CSV: prior_auth_requests.csv (25,000 rows)
-- Purpose: Core PA workflow event table. Central fact in the star schema.
--
-- CRITICAL FIELD NOTES:
--   decision     = Initial routing (Approved/Denied/Pended). NOT for KFF benchmarks.
--   final_outcome = Final administrative outcome after pend resolution + appeals.
--                   USE THIS for CMS-0057-F / KFF benchmark comparisons.
--
-- LEAKAGE-RISK FIELDS (must not be used as predictors in outcome models):
--   action_recommended_initial — [HIGH LEAKAGE RISK] Post-decision field. 0% inconsistency
--                                 with decision. Near-perfect label proxy. Workflow analytics only.
--   appeal_id                  — [LEAKAGE RISK] Only populated for denied requests. Reveals decision.
--   appealed                   — [LEAKAGE RISK] TRUE only when decision=Denied. Reveals decision.
-- =============================================================================

CREATE TABLE pais.fact_prior_authorization (
    -- Primary key
    request_id                  VARCHAR(20)     NOT NULL,

    -- Foreign keys to dimension tables
    member_id                   VARCHAR(20)     NOT NULL,
    provider_id                 VARCHAR(20)     NOT NULL,
    service_id                  VARCHAR(20)     NOT NULL,

    -- Request characteristics (pre-decision features — safe for modeling)
    request_type                VARCHAR(15)     NOT NULL,   -- 'Standard', 'Expedited'
    submitted_date              DATE            NOT NULL,
    submitted_day_of_week       VARCHAR(10)     NOT NULL,   -- 'Monday' ... 'Sunday'
    submission_channel          VARCHAR(15)     NOT NULL,   -- 'Electronic','Fax','Portal','Phone'
    documentation_complete      BOOLEAN         NOT NULL,   -- FALSE = higher denial risk (G01)
    estimated_cost              NUMERIC(10,2)   NOT NULL,
    previous_denial_history     BOOLEAN         NOT NULL,
    auto_eligible               BOOLEAN         NOT NULL,   -- eligible for automated fast-track (G04)
    clinical_review_required    BOOLEAN         NOT NULL,

    -- Decision fields
    reviewer_type               VARCHAR(25)     NOT NULL,   -- 'Automated','Clinical Staff','Medical Director'
    decision                    VARCHAR(10)     NOT NULL,   -- INITIAL ROUTING — NOT for KFF benchmarks
    decision_date               DATE            NOT NULL,
    decision_time_days          NUMERIC(6,2)    NOT NULL,   -- calendar days submitted_date → decision_date
    allowed_days                SMALLINT        NOT NULL,   -- SLA threshold: 7 (Standard), 3 (Expedited)
    delayed_flag                BOOLEAN         NOT NULL,   -- TRUE when decision_time_days > allowed_days
    denial_reason               VARCHAR(50)     NULL,       -- NULL for non-denied records
    pended_flag                 BOOLEAN         NOT NULL,

    -- Final outcome field — USE FOR KFF / CMS-0057-F BENCHMARKS
    final_outcome               VARCHAR(40)     NOT NULL,
    -- Values: 'Approved' | 'Denied' | 'Pended-Resolved-Approved' |
    --         'Pended-Resolved-Denied' | 'Approved-After-Appeal'

    -- Appeal linkage fields [LEAKAGE RISK — see notes above]
    appealed                    BOOLEAN         NOT NULL,   -- [LEAKAGE RISK] exclude from decision models
    appeal_id                   VARCHAR(20)     NULL,       -- [LEAKAGE RISK] exclude from decision models

    -- Workflow simulation field [HIGH LEAKAGE RISK — exclude from all predictive models]
    action_recommended_initial  VARCHAR(30)     NULL,       -- [HIGH LEAKAGE RISK] post-decision proxy

    -- Constraints
    CONSTRAINT pk_fact_prior_authorization
        PRIMARY KEY (request_id),
    CONSTRAINT fk_fpa_member
        FOREIGN KEY (member_id)   REFERENCES pais.dim_member(member_id),
    CONSTRAINT fk_fpa_provider
        FOREIGN KEY (provider_id) REFERENCES pais.dim_provider(provider_id),
    CONSTRAINT fk_fpa_service
        FOREIGN KEY (service_id)  REFERENCES pais.dim_service(service_id),

    CONSTRAINT chk_fpa_request_type
        CHECK (request_type IN ('Standard','Expedited')),
    CONSTRAINT chk_fpa_submission_channel
        CHECK (submission_channel IN ('Electronic','Fax','Portal','Phone')),
    CONSTRAINT chk_fpa_decision
        CHECK (decision IN ('Approved','Denied','Pended')),
    CONSTRAINT chk_fpa_allowed_days
        CHECK (allowed_days IN (3, 7)),  -- CMS-0057-F: 3 days expedited, 7 days standard
    CONSTRAINT chk_fpa_decision_time
        CHECK (decision_time_days > 0),
    CONSTRAINT chk_fpa_estimated_cost
        CHECK (estimated_cost > 0),
    CONSTRAINT chk_fpa_reviewer_type
        CHECK (reviewer_type IN ('Automated','Clinical Staff','Medical Director')),
    CONSTRAINT chk_fpa_final_outcome
        CHECK (final_outcome IN (
            'Approved',
            'Denied',
            'Pended-Resolved-Approved',
            'Pended-Resolved-Denied',
            'Approved-After-Appeal'
        )),
    CONSTRAINT chk_fpa_denial_reason_logic
        CHECK (
            (decision = 'Denied' AND denial_reason IS NOT NULL)
            OR
            (decision IN ('Approved','Pended') AND denial_reason IS NULL)
        )
);

COMMENT ON TABLE pais.fact_prior_authorization IS
    'Core PA workflow fact table. 25,000 synthetic prior authorization requests, '
    'Jan 2023 – Dec 2024. Star schema central fact. '
    'IMPORTANT: Use final_outcome (not decision) for CMS-0057-F / KFF benchmark metrics. '
    'decision = initial 3-state routing; final_outcome = administrative final determination. '
    'All data is SYNTHETIC. No PHI.';

COMMENT ON COLUMN pais.fact_prior_authorization.decision IS
    'Initial 3-state routing decision: Approved (86.8%), Denied (6.1%), Pended (7.1%). '
    'DO NOT USE for KFF 92.3% approval rate comparison — that is a final_outcome metric.';

COMMENT ON COLUMN pais.fact_prior_authorization.final_outcome IS
    'Final administrative outcome after pend resolution and appeal. '
    'USE THIS for CMS-0057-F and KFF benchmark comparisons. '
    'KFF 2024: 92.3% approval rate. PAIS achieves 92.7%. Source: S3.';

COMMENT ON COLUMN pais.fact_prior_authorization.action_recommended_initial IS
    '[HIGH LEAKAGE RISK] Post-decision workflow simulation field. '
    '0% inconsistency with decision direction. MUST BE EXCLUDED from any '
    'feature matrix predicting decision, final_outcome, or delayed_flag. '
    'Approved records always receive Approve/Request-Docs recommendation; '
    'Denied records always receive Deny/Request-Docs/Pend recommendation.';

COMMENT ON COLUMN pais.fact_prior_authorization.appealed IS
    '[LEAKAGE RISK] TRUE only when decision=Denied. '
    'Using this as a predictor of decision is structural leakage. '
    'Exclude from any model predicting decision.';

COMMENT ON COLUMN pais.fact_prior_authorization.appeal_id IS
    '[LEAKAGE RISK] Populated only when appealed=TRUE (i.e., decision=Denied). '
    'Using as a predictor of decision is direct leakage. '
    'May be used in appeal-specific analyses after filtering to denied records.';


-- =============================================================================
-- TABLE 5: fact_appeal
-- Source CSV: appeals.csv (175 rows)
-- Purpose: Appeal outcomes for denied PA requests.
--          Used to compute appeal overturn rate and denial-to-overturn funnel.
-- =============================================================================

CREATE TABLE pais.fact_appeal (
    appeal_id                       VARCHAR(20)     NOT NULL,
    request_id                      VARCHAR(20)     NOT NULL,   -- FK to fact_prior_authorization
    appeal_date                     DATE            NOT NULL,
    appeal_decision_date            DATE            NOT NULL,
    appeal_decision_days            SMALLINT        NOT NULL,   -- days from appeal_date to decision
    appeal_outcome                  VARCHAR(30)     NOT NULL,   -- 'Overturned','Partially Overturned','Upheld'
    reason_overturned               VARCHAR(200)    NULL,       -- NULL when Upheld
    additional_documentation_submitted BOOLEAN      NOT NULL,
    final_status_after_appeal       VARCHAR(10)     NOT NULL,   -- 'Approved', 'Denied'

    -- Constraints
    CONSTRAINT pk_fact_appeal
        PRIMARY KEY (appeal_id),
    CONSTRAINT fk_fa_request
        FOREIGN KEY (request_id) REFERENCES pais.fact_prior_authorization(request_id),
    CONSTRAINT chk_fa_appeal_outcome
        CHECK (appeal_outcome IN ('Overturned','Partially Overturned','Upheld')),
    CONSTRAINT chk_fa_final_status
        CHECK (final_status_after_appeal IN ('Approved','Denied')),
    CONSTRAINT chk_fa_decision_days
        CHECK (appeal_decision_days >= 0),
    CONSTRAINT chk_fa_date_order
        CHECK (appeal_decision_date >= appeal_date),
    CONSTRAINT chk_fa_reason_logic
        CHECK (
            (appeal_outcome IN ('Overturned','Partially Overturned') AND reason_overturned IS NOT NULL)
            OR
            (appeal_outcome = 'Upheld')
        )
);

COMMENT ON TABLE pais.fact_appeal IS
    'Appeal fact table. 175 synthetic appeal records — 11.5% of 1,525 denied requests. '
    'Overturn rate: 79.4% (KFF 2024 benchmark: 80.7%). Source: S3. '
    'All data is SYNTHETIC. No PHI.';

COMMENT ON COLUMN pais.fact_appeal.appeal_outcome IS
    'Overturned = full reversal; Partially Overturned = partial approval; Upheld = denial stands. '
    'KFF 2024: 80.7% combined overturn rate (Overturned + Partially Overturned). Source: S3.';


-- =============================================================================
-- SECTION: VERIFY TABLE CREATION
-- =============================================================================

-- Run this after executing the script to confirm all tables were created:
SELECT
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns c
     WHERE c.table_schema = t.table_schema AND c.table_name = t.table_name) AS column_count
FROM information_schema.tables t
WHERE table_schema = 'pais'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Expected:
-- table_name                  | column_count
-- ----------------------------+-------------
-- dim_member                  | 8
-- dim_provider                | 8
-- dim_service                 | 10
-- fact_appeal                 | 9
-- fact_prior_authorization    | 25
