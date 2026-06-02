# Power BI Data Model Plan — Prior Authorization Intelligence System
**Phase 4 | Power BI Dashboard Design**
**Generated: 2026-05-31**

---

## Overview

This document specifies how to import the PAIS SQL layer into Power BI Desktop, configure the star schema relationships, create calculated columns, and prepare the model for all DAX measures defined in `dax_measures.md`.

**Two valid import paths:**
- **Path A (Recommended for portfolio):** Connect Power BI directly to a DuckDB or PostgreSQL instance running the PAIS schema. Views are pre-aggregated and optimized.
- **Path B (Portable/offline):** Import CSVs directly into Power BI and build the schema natively. No database server required.

This document covers both paths.

---

## Option A: Connect to DuckDB / PostgreSQL

### PostgreSQL Connection
1. Open Power BI Desktop → Get Data → PostgreSQL database
2. Server: `localhost` (or your server address), Database: `pais`
3. Select tables: `dim_member`, `dim_provider`, `dim_service`, `fact_prior_authorization`, `fact_appeal`
4. Select views: all 10 `vw_*` views
5. Import mode (not DirectQuery) for portfolio use — enables all DAX measures

### DuckDB Connection
1. Install the DuckDB ODBC driver (available at duckdb.org/docs/api/odbc)
2. Power BI Desktop → Get Data → ODBC
3. DSN pointing to your `.duckdb` file
4. Import the same tables and views as above

---

## Option B: Direct CSV Import (Portable)

### Import Order (must respect FK dependencies)
1. `members.csv` → rename query to `dim_member`
2. `providers.csv` → rename query to `dim_provider`
3. `services.csv` → rename query to `dim_service`
4. `prior_auth_requests.csv` → rename query to `fact_prior_authorization`
5. `appeals.csv` → rename query to `fact_appeal`

### Power Query Transformations (apply in Power Query Editor)

**For `fact_prior_authorization`:**

| Column | Action | Reason |
|--------|--------|--------|
| `submitted_date` | Change type → Date | Enables date hierarchy |
| `decision_date` | Change type → Date | |
| `documentation_complete` | Change type → True/False | CSV imports as text |
| `auto_eligible` | Change type → True/False | |
| `clinical_review_required` | Change type → True/False | |
| `previous_denial_history` | Change type → True/False | |
| `delayed_flag` | Change type → True/False | |
| `pended_flag` | Change type → True/False | |
| `appealed` | Change type → True/False | |
| `decision_time_days` | Change type → Decimal Number | |
| `estimated_cost` | Change type → Decimal Number | |
| `allowed_days` | Change type → Whole Number | |
| `denial_reason` | Replace "" with null | Blanks → proper null |
| `appeal_id` | Replace "" with null | Blanks → proper null |
| `action_recommended_initial` | **Mark as DO NOT USE in reports** | Leakage risk field |

**For `fact_appeal`:**

| Column | Action |
|--------|--------|
| `appeal_date` | Change type → Date |
| `appeal_decision_date` | Change type → Date |
| `additional_documentation_submitted` | Change type → True/False |
| `reason_overturned` | Replace "" with null |

**For `dim_provider`:**

| Column | Action |
|--------|--------|
| `avg_incomplete_submission_rate` | Change type → Decimal Number |
| `avg_response_time_days` | Change type → Decimal Number |

---

## Star Schema Relationships

Configure these relationships in Power BI Model view (drag-and-drop or Manage Relationships dialog):

| From Table | From Column | To Table | To Column | Cardinality | Direction |
|-----------|------------|---------|----------|-------------|-----------|
| `fact_prior_authorization` | `member_id` | `dim_member` | `member_id` | Many-to-One | Single (dim → fact) |
| `fact_prior_authorization` | `provider_id` | `dim_provider` | `provider_id` | Many-to-One | Single |
| `fact_prior_authorization` | `service_id` | `dim_service` | `service_id` | Many-to-One | Single |
| `fact_appeal` | `request_id` | `fact_prior_authorization` | `request_id` | Many-to-One | Single |

**Cross-filter direction:** All set to Single (dimension → fact). Do not use Both direction — it creates ambiguous filter paths with the two-fact-table design.

**Inactive relationship:** `fact_prior_authorization[appeal_id]` → `fact_appeal[appeal_id]` — do NOT activate this. The `request_id` FK is the correct join key. `appeal_id` in the fact table is a leakage-risk field.

---

## Date Table (Required for Time Intelligence)

Create a dedicated Date dimension table for time intelligence DAX measures. In Power Query, add a new blank query with this M code:

```m
let
    StartDate = #date(2023, 1, 1),
    EndDate   = #date(2024, 12, 31),
    Duration  = Duration.Days(EndDate - StartDate) + 1,
    DateList  = List.Dates(StartDate, Duration, #duration(1, 0, 0, 0)),
    DateTable = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}),
    TypedDate = Table.TransformColumnTypes(DateTable, {{"Date", type date}}),
    AddYear   = Table.AddColumn(TypedDate, "Year", each Date.Year([Date]), Int64.Type),
    AddMonth  = Table.AddColumn(AddYear, "Month", each Date.Month([Date]), Int64.Type),
    AddMonthName = Table.AddColumn(AddMonth, "Month Name", each Date.ToText([Date], "MMM"), type text),
    AddYearMonth = Table.AddColumn(AddMonthName, "Year-Month", each Date.ToText([Date], "yyyy-MM"), type text),
    AddQuarter   = Table.AddColumn(AddYearMonth, "Quarter", each "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
    AddDayOfWeek = Table.AddColumn(AddQuarter, "Day of Week", each Date.DayOfWeekName([Date]), type text)
in
    AddDayOfWeek
```

Name this query `dim_date`. Then add the relationship:
- `fact_prior_authorization[submitted_date]` → `dim_date[Date]` (Many-to-One, Single direction)

Mark `dim_date` as the Date Table (right-click → Mark as Date Table → Date column = `Date`).

---

## Calculated Columns

Add these calculated columns directly in the Power BI data model (not in Power Query), as they reference cross-table logic.

### In `fact_prior_authorization`:

**`Days Over SLA`** — how many days over the limit for delayed requests
```dax
Days Over SLA =
IF(
    fact_prior_authorization[delayed_flag] = TRUE,
    fact_prior_authorization[decision_time_days] - fact_prior_authorization[allowed_days],
    0
)
```

**`SLA Breach Severity`** — bucket for dashboard visual
```dax
SLA Breach Severity =
SWITCH(
    TRUE(),
    fact_prior_authorization[delayed_flag] = FALSE,                              "On Time",
    fact_prior_authorization[decision_time_days] - fact_prior_authorization[allowed_days] <= 1,  "1 Day Over",
    fact_prior_authorization[decision_time_days] - fact_prior_authorization[allowed_days] <= 3,  "2-3 Days Over",
    fact_prior_authorization[decision_time_days] - fact_prior_authorization[allowed_days] <= 7,  "4-7 Days Over",
    "8+ Days Over"
)
```

**`Outcome Group`** — simplified 3-category final outcome for donut chart
```dax
Outcome Group =
SWITCH(
    fact_prior_authorization[final_outcome],
    "Approved",                  "Approved",
    "Pended-Resolved-Approved",  "Approved",
    "Approved-After-Appeal",     "Approved After Appeal",
    "Denied",                    "Denied",
    "Pended-Resolved-Denied",    "Denied",
    "Other"
)
```

**`Is Final Approved`** — boolean flag for KPI measures
```dax
Is Final Approved =
IF(
    fact_prior_authorization[final_outcome] IN {
        "Approved", "Pended-Resolved-Approved", "Approved-After-Appeal"
    },
    1, 0
)
```

**`Is Final Denied`** — boolean flag for KPI measures
```dax
Is Final Denied =
IF(
    fact_prior_authorization[final_outcome] IN {"Denied", "Pended-Resolved-Denied"},
    1, 0
)
```

**`Doc Status Label`** — readable label for documentation_complete boolean
```dax
Doc Status Label =
IF(fact_prior_authorization[documentation_complete] = TRUE, "Complete", "Incomplete")
```

### In `dim_provider`:

**`Network Status Label`** — short label for visuals
```dax
Network Label =
IF(dim_provider[network_status] = "In-Network", "In-Network", "Out-of-Network")
```

---

## Fields to Hide from Report View

The following fields should be hidden in the Power BI field list to prevent accidental misuse. Right-click field → Hide in Report View.

| Table | Field | Reason |
|-------|-------|--------|
| `fact_prior_authorization` | `action_recommended_initial` | HIGH LEAKAGE RISK — post-decision proxy |
| `fact_prior_authorization` | `appeal_id` | LEAKAGE RISK — only use via fact_appeal relationship |
| `fact_prior_authorization` | `appealed` | LEAKAGE RISK — use appeal count DAX instead |
| `fact_prior_authorization` | `decision` | Hide to prevent confusion with final_outcome; expose via DAX measures only |
| `dim_service` | `base_denial_risk` | Assumption-based; expose via labeled DAX measure only |
| `dim_service` | `base_delay_risk` | Assumption-based |

**Rationale:** Hiding these fields prevents a future dashboard developer from accidentally dragging `decision` or `action_recommended_initial` onto a card and citing incorrect benchmark numbers.

---

## Data Model Validation Checklist

Before building any visuals, verify:

- [ ] All 5 tables imported, row counts match: dim_member=5,000 / dim_provider=1,000 / dim_service=40 / fact_prior_authorization=25,000 / fact_appeal=175
- [ ] All 4 relationships created (green connector lines in Model view)
- [ ] `dim_date` marked as Date Table
- [ ] `fact_prior_authorization[submitted_date]` linked to `dim_date[Date]`
- [ ] 5 calculated columns created in `fact_prior_authorization`
- [ ] Leakage-risk fields hidden in Report view
- [ ] `action_recommended_initial` does not appear in any field list visible to report builders
- [ ] Date hierarchy works: Year → Quarter → Month in submitted_date
- [ ] Cross-filter direction is Single for all relationships

---

*Power BI Data Model Plan — Phase 4. Last updated: 2026-05-31*
