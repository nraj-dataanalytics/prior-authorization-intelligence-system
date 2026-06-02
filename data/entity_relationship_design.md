# Entity Relationship Design — Prior Authorization Intelligence System
**Phase 2 | Last Updated: 2026-05-31**

---

## Schema Overview

The synthetic dataset uses a star-schema structure with `prior_auth_requests` as the central fact table and four supporting dimension/reference tables.

```
┌─────────────┐         ┌──────────────────────────┐         ┌─────────────┐
│   members   │────────▶│   prior_auth_requests     │◀────────│  providers  │
│  (5,000)    │  1:many │      (25,000 rows)        │  1:many │  (1,000)    │
└─────────────┘         │                          │         └─────────────┘
                        │  - request_id (PK)        │
                        │  - member_id (FK)         │
                        │  - provider_id (FK)       │         ┌─────────────┐
                        │  - service_id (FK)        │◀────────│  services   │
                        │  - appeal_id (FK, opt)    │  1:many │   (40)      │
                        │  - [all decision fields]  │         └─────────────┘
                        └──────────┬───────────────┘
                                   │ 1:(0 or 1)
                                   ▼
                        ┌──────────────────────────┐
                        │         appeals          │
                        │   (~320 rows expected)   │
                        │  - appeal_id (PK)        │
                        │  - request_id (FK, unique)│
                        └──────────────────────────┘
```

---

## Table Definitions

### members
- **Type:** Dimension
- **Grain:** One row per synthetic plan member
- **Primary Key:** `member_id`
- **Cardinality to prior_auth_requests:** 1:many (one member may have multiple PA requests over 24 months)
- **Expected rows:** 5,000
- **Join key in requests:** `member_id`

### providers
- **Type:** Dimension
- **Grain:** One row per synthetic provider entity
- **Primary Key:** `provider_id`
- **Cardinality to prior_auth_requests:** 1:many (one provider submits multiple PA requests)
- **Expected rows:** 1,000
- **Join key in requests:** `provider_id`

### services
- **Type:** Reference / Lookup
- **Grain:** One row per service type
- **Primary Key:** `service_id`
- **Cardinality to prior_auth_requests:** 1:many (one service type appears in many requests)
- **Expected rows:** 40
- **Join key in requests:** `service_id`

### prior_auth_requests
- **Type:** Fact (core)
- **Grain:** One row per prior authorization request
- **Primary Key:** `request_id`
- **Foreign Keys:** `member_id` → members, `provider_id` → providers, `service_id` → services, `appeal_id` → appeals (nullable)
- **Expected rows:** 25,000
- **Date range:** 2023-01-01 to 2024-12-31

### appeals
- **Type:** Fact (subordinate to prior_auth_requests)
- **Grain:** One row per filed appeal
- **Primary Key:** `appeal_id`
- **Foreign Key:** `request_id` → prior_auth_requests (unique — one appeal per request)
- **Expected rows:** ~320 (11.5% of ~2,800 denied requests)
- **Constraint:** appeal_date must be ≥ decision_date + 1; appeal_decision_date must be ≥ appeal_date + 1

---

## Referential Integrity Rules

| Rule | Description | Enforcement |
|------|-------------|-------------|
| RI-01 | Every member_id in prior_auth_requests exists in members | Validated in data_quality_report |
| RI-02 | Every provider_id in prior_auth_requests exists in providers | Validated in data_quality_report |
| RI-03 | Every service_id in prior_auth_requests exists in services | Validated in data_quality_report |
| RI-04 | Every appeal_id in prior_auth_requests (non-null) exists in appeals | Validated in data_quality_report |
| RI-05 | Every request_id in appeals exists in prior_auth_requests | Validated in data_quality_report |
| RI-06 | Only denied requests have appeal_id populated | Business logic constraint |
| RI-07 | appeal_date ≥ decision_date + 1 day | Temporal integrity |
| RI-08 | decision_date ≥ submitted_date | Temporal integrity |
| RI-09 | Denied requests have a non-null denial_reason | Business logic constraint |
| RI-10 | Approved/Pended requests have null denial_reason | Business logic constraint |

---

## Key Design Decisions

**1. Star schema over normalized snowflake**
The analytical use case (SQL queries, Power BI, pandas) benefits from a wide fact table. Denormalization of service category and denial reason directly into prior_auth_requests is intentional for query performance.

**2. appeal_id stored on prior_auth_requests**
Bidirectional FK allows joining in either direction without subqueries. Data quality check RI-04 ensures no orphan IDs.

**3. final_outcome derived field**
`final_outcome` on prior_auth_requests consolidates the end state after all appeal resolution. This enables single-table final outcome analysis without requiring a join to appeals. It is always consistent with appeal_outcome where an appeal exists.

**4. No diagnosis code dimension**
ICD-10 codes are excluded to avoid the need for clinical knowledge validation. Service category serves as the clinical complexity proxy.

**5. Temporal grain: daily dates, not timestamps**
Decision times are stored as decimal days (e.g., 1.5 days = 36 hours) for SLA math. Dates are stored as DATE type for partitioning and time-series analysis.

---

## Analytical Join Patterns

**Standard analysis joins:**
```sql
-- Full PA analysis with all dimensions
SELECT r.*, m.age_band, m.risk_level, p.provider_type, p.provider_risk_segment,
       s.service_category, s.base_denial_risk
FROM prior_auth_requests r
JOIN members m ON r.member_id = m.member_id
JOIN providers p ON r.provider_id = p.provider_id
JOIN services s ON r.service_id = s.service_id;

-- Appeal funnel analysis
SELECT r.denial_reason, a.appeal_outcome, COUNT(*) as count
FROM prior_auth_requests r
JOIN appeals a ON r.appeal_id = a.appeal_id
GROUP BY r.denial_reason, a.appeal_outcome;

-- SLA compliance by channel and urgency
SELECT r.submission_channel, r.request_type,
       SUM(CASE WHEN r.delayed_flag = TRUE THEN 1 ELSE 0 END) * 1.0 / COUNT(*) as breach_rate
FROM prior_auth_requests r
GROUP BY r.submission_channel, r.request_type;
```
