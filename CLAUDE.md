# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains Snowflake SQL definitions for the **Executive Sales Agent** — a Cortex-powered analytics agent for ticket sales and revenue reporting. The target schema is `TBRDP_DW_PROD.IM_RPT`.

There are no build, lint, or test commands. Changes are deployed by executing the SQL directly against Snowflake.

## Files

- **ExecutiveSalesAgent.SQL** — Defines `V_TDC_TICKET_SALES_UNIFIED`, a unified view that combines transaction detail and membership detail data across season years (2023–2026) via `UNION ALL`.
- **ExecutiveSalesAgentSemanticView.sql** — Defines `EXECUTIVE_SEMANTIC_VIEW`, a Snowflake Semantic View on top of the unified view, exposing dimensions, metrics, and synonyms for Cortex Analyst natural-language queries.

## Architecture

### Unified View (`V_TDC_TICKET_SALES_UNIFIED`)

A 5-part `UNION ALL` combining two upstream sources:

| Parts | Source View | Data Type | Years |
|-------|------------|-----------|-------|
| 1 | `V_SBL_GCP_TDC_REGULAR_SEASON_TICKET_DETAIL` | Transaction Detail | 2023–2025 |
| 2–3 | `V_SBL_GCP_TDC_MEMBERSHIP_SALES_COMBINED` | Membership Detail (Flexible + Traditional Sponsor) | 2023–2024 |
| 4 | `V_SBL_GCP_TDC_REGULAR_SEASON_TICKET_DETAIL` | Transaction Detail | 2026 |
| 5 | `V_SBL_GCP_TDC_MEMBERSHIP_SALES_COMBINED` | Membership Detail (Flexible + Traditional Sponsor) | 2026 |

Key design details:
- **Transaction data** filters on `SYSTEM_CURRENT_FLAG = 'Y'` and excludes `Member New`, `Member Renewal`, `Season Sponsors` buyer types (those come from membership source instead).
- **Membership data** filters to `Flexible` and `Traditional Sponsor` membership types only. 2026 membership additionally requires `SOLD_FLAG_2026 = TRUE`.
- **TICKET_TYPE_GROUPING** is a derived classification column. Transaction data maps `BUYER_TYPE_GROUP_DESCRIPTION` into categories (Traditional Seasons, Single Game, Group, Suite, Comps, Sponsor, Other). Membership data maps based on `MEMBERSHIP_TYPE`.

### YTD Offset Logic (Critical)

YTD (year-to-date) comparison flags use different day offsets depending on the data source:
- **Transaction data** (timestamps vary throughout day): `-729` days for 2024, `-1094` for 2023
- **Membership data** (timestamps at midnight): `-730` days for 2024, `-1095` for 2023

These offsets align with Tableau boundary calculations. When adding a new historical year, the offset must account for this 1-day difference between sources.

### Semantic View (`EXECUTIVE_SEMANTIC_VIEW`)

Built on `V_TDC_TICKET_SALES_UNIFIED` and provides:
- **Dimensions**: season year, ticket type grouping, data source, purchase date parts, YTD flags
- **Metrics**: core revenue (total, count, unique patrons, avg price), category-specific revenue breakdowns, per-year YTD metrics, and YoY growth calculations
- **Synonyms**: extensive natural-language synonyms on each metric for Cortex Analyst query resolution

## Conventions

- Column `ROW_` is used (trailing underscore) to avoid conflict with the SQL reserved word.
- NULL columns use explicit Snowflake type casts (e.g., `NULL::TEXT`, `NULL::FLOAT`) to maintain schema alignment across UNION ALL parts.
- The change log is maintained in SQL comments at the top of `ExecutiveSalesAgent.SQL`.
