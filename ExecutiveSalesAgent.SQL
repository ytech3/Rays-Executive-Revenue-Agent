-- ============================================================================
-- VIEW: V_TDC_TICKET_SALES_UNIFIED
-- PURPOSE: Unified ticket sales view combining transaction and membership data
--          FOR ALL YEARS (2023, 2024, 2025, 2026)
-- SCHEMA: TBRDP_DW_PROD.IM_RPT
-- LAST UPDATED: 2026-02-11
-- ============================================================================
-- 
-- CHANGE LOG:
-- 2026-02-11: Fixed YTD offsets - transaction data uses -729, membership uses -730
--             This aligns with Tableau boundary calculations for both data types
-- 2026-02-10: Added membership data for 2023 and 2024
-- 2026-02-09: Added YTD comparison flags
-- 2026-02-04: Fixed Sponsor category, changed schema to TBRDP_DW_PROD
-- 2026-02-03: Initial unified view creation
--
-- YTD OFFSET LOGIC:
-- Transaction data (timestamps vary throughout day): -729 days for 2024, -1094 for 2023
-- Membership data (timestamps at midnight): -730 days for 2024, -1095 for 2023
-- ============================================================================

CREATE OR REPLACE VIEW TBRDP_DW_PROD.IM_RPT.V_TDC_TICKET_SALES_UNIFIED AS

-- ========================================
-- PART 1: YEARS 2023-2025 - Transaction Detail
-- Uses -729 / -1094 day offsets for transaction data
-- ========================================
SELECT 
    t.SEASON_YEAR,
    t.PURCHASE_DATE,
    t.EVENT_DATE,
    t.EVENT_NAME,
    t.EVENT_ID,
    t.FINANCIAL_PATRON_ACCOUNT_ID,
    t.ATTENDING_PATRON_ACCOUNT_ID,
    t.PATRON_ACCOUNT_NAME,
    t.EMAIL,
    t.SECTION,
    t.ROW_,
    t.SEAT_NUMBER,
    t.SEAT_ID,
    t.PRICE,
    t.PAID_AMOUNT,
    t.BUYER_TYPE_GROUP_ID,
    t.BUYER_TYPE_GROUP_CODE,
    t.BUYER_TYPE_GROUP_DESCRIPTION,
    t.BUYER_TYPE_ID,
    t.BUYER_TYPE_CODE,
    t.BUYER_TYPE_DESCRIPTION,
    t.PAYMENT_TYPE_CODE,
    t.PAYMENT_METHOD_CODE,
    t.SYSTEM_VERSION,
    t.SYSTEM_CURRENT_FLAG,
    t.SYSTEM_CREATE_DATE,
    t.SYSTEM_UPDATE_DATE,
    t.LAST_UPDATE_RUN,
    
    NULL::TEXT AS MEMBERSHIP_TYPE,
    NULL::TEXT AS MEMBERSHIP_PLAN,
    NULL::NUMBER AS MEMBERSHIP_SEATS_PER_GAME,
    NULL::NUMBER AS MEMBERSHIP_TOTAL_GAMES,
    NULL::FLOAT AS REVENUE_TOTAL_MEMBERSHIP,
    
    CASE 
        WHEN t.BUYER_TYPE_GROUP_DESCRIPTION IN (
            'Full Season New', 'Full Season Renewals',
            'Half Season New', 'Half Season Renewals',
            'Partial Season New', 'Partial Season Renewal'
        ) THEN 'Traditional Seasons'
        WHEN t.BUYER_TYPE_GROUP_DESCRIPTION IN (
            'Advance Sales', 'Ticket Promotions and Specials'
        ) THEN 'Single Game'
        WHEN t.BUYER_TYPE_GROUP_DESCRIPTION IN (
            'Group Sales', 'Party Areas'
        ) THEN 'Group'
        WHEN t.BUYER_TYPE_GROUP_DESCRIPTION IN (
            'Suite Sales'
        ) THEN 'Suite'
        WHEN t.BUYER_TYPE_GROUP_DESCRIPTION IN (
            'Comps', 'Commissioner Initiative Ticket'
        ) THEN 'Comps'
        WHEN t.BUYER_TYPE_GROUP_DESCRIPTION IN (
            'Group Sponsor', 'Corporate Group Party Areas', 
            'Corporate Group', 'Half and Partial Season Sponso'
        ) THEN 'Sponsor'
        ELSE 'Other'
    END AS TICKET_TYPE_GROUPING,
    
    'Transaction Detail' AS DATA_SOURCE,
    'Historical Transaction' AS DATA_LOGIC,
    
    -- YTD Flags for TRANSACTION data: -729 for 2024, -1094 for 2023
    CASE WHEN t.SEASON_YEAR = 2024 AND t.PURCHASE_DATE <= DATEADD('day', -729, CURRENT_DATE()) THEN TRUE ELSE FALSE END AS IS_2024_YTD,
    CASE WHEN t.SEASON_YEAR = 2023 AND t.PURCHASE_DATE <= DATEADD('day', -1094, CURRENT_DATE()) THEN TRUE ELSE FALSE END AS IS_2023_YTD,
    FALSE AS IS_CURRENT_YTD,
    CASE 
        WHEN t.SEASON_YEAR = 2024 THEN DATEADD('day', -729, CURRENT_DATE())
        WHEN t.SEASON_YEAR = 2023 THEN DATEADD('day', -1094, CURRENT_DATE())
        ELSE NULL
    END AS YTD_CUTOFF_DATE

FROM TBRDP_DW_PROD.IM_RPT.V_SBL_GCP_TDC_REGULAR_SEASON_TICKET_DETAIL t

WHERE t.SEASON_YEAR IN (2023, 2024, 2025)
  AND t.SYSTEM_CURRENT_FLAG = 'Y'
  AND t.BUYER_TYPE_GROUP_DESCRIPTION NOT IN (
      'Member New',
      'Member Renewal',
      'Season Sponsors'
  )

UNION ALL

-- ========================================
-- PART 2: YEAR 2024 - Membership Detail
-- Uses -730 day offset for membership data
-- ========================================
SELECT 
    m.SEASON_YEAR,
    m.PURCHASE_DATE::TIMESTAMP_NTZ AS PURCHASE_DATE,
    NULL::TIMESTAMP_NTZ AS EVENT_DATE,
    NULL::TEXT AS EVENT_NAME,
    NULL::FLOAT AS EVENT_ID,
    m.FINANCIAL_PATRON_ACCOUNT_ID,
    NULL::FLOAT AS ATTENDING_PATRON_ACCOUNT_ID,
    NULL::TEXT AS PATRON_ACCOUNT_NAME,
    NULL::TEXT AS EMAIL,
    NULL::TEXT AS SECTION,
    NULL::TEXT AS ROW_,
    NULL::TEXT AS SEAT_NUMBER,
    NULL::FLOAT AS SEAT_ID,
    m.REVENUE AS PRICE,
    NULL::FLOAT AS PAID_AMOUNT,
    m.BUYER_TYPE_GROUP_ID,
    NULL::TEXT AS BUYER_TYPE_GROUP_CODE,
    m.BUYER_TYPE_GROUP_DESCRIPTION,
    m.BUYER_TYPE_ID,
    NULL::TEXT AS BUYER_TYPE_CODE,
    m.BUYER_TYPE_DESCRIPTION,
    NULL::TEXT AS PAYMENT_TYPE_CODE,
    NULL::TEXT AS PAYMENT_METHOD_CODE,
    NULL::NUMBER AS SYSTEM_VERSION,
    NULL::TEXT AS SYSTEM_CURRENT_FLAG,
    m.SYSTEM_CREATE_DATE,
    m.SYSTEM_UPDATE_DATE,
    m.LAST_UPDATE_RUN,
    
    m.MEMBERSHIP_TYPE,
    m.MEMBERSHIP_PLAN,
    m.SEATS AS MEMBERSHIP_SEATS_PER_GAME,
    m.GAMES AS MEMBERSHIP_TOTAL_GAMES,
    m.REVENUE AS REVENUE_TOTAL_MEMBERSHIP,
    
    CASE 
        WHEN m.MEMBERSHIP_TYPE = 'Traditional Sponsor' THEN 'Sponsor'
        WHEN m.MEMBERSHIP_TYPE = 'Flexible' AND m.BUYER_TYPE_GROUP_DESCRIPTION = 'Season Sponsors' THEN 'Sponsor'
        WHEN m.MEMBERSHIP_TYPE = 'Flexible' THEN 'Flex Season'
        ELSE 'Other'
    END AS TICKET_TYPE_GROUPING,
    
    'Membership Detail' AS DATA_SOURCE,
    '2024 Membership' AS DATA_LOGIC,
    
    -- YTD Flags for MEMBERSHIP data: -730 for 2024
    CASE WHEN m.PURCHASE_DATE <= DATEADD('day', -730, CURRENT_DATE()) THEN TRUE ELSE FALSE END AS IS_2024_YTD,
    FALSE AS IS_2023_YTD,
    FALSE AS IS_CURRENT_YTD,
    DATEADD('day', -730, CURRENT_DATE()) AS YTD_CUTOFF_DATE

FROM TBRDP_DW_PROD.IM_RPT.V_SBL_GCP_TDC_MEMBERSHIP_SALES_COMBINED m

WHERE m.SEASON_YEAR = 2024
  AND (m.MEMBERSHIP_TYPE = 'Flexible' OR m.MEMBERSHIP_TYPE = 'Traditional Sponsor')

UNION ALL

-- ========================================
-- PART 3: YEAR 2023 - Membership Detail
-- Uses -1095 day offset for membership data
-- ========================================
SELECT 
    m.SEASON_YEAR,
    m.PURCHASE_DATE::TIMESTAMP_NTZ AS PURCHASE_DATE,
    NULL::TIMESTAMP_NTZ AS EVENT_DATE,
    NULL::TEXT AS EVENT_NAME,
    NULL::FLOAT AS EVENT_ID,
    m.FINANCIAL_PATRON_ACCOUNT_ID,
    NULL::FLOAT AS ATTENDING_PATRON_ACCOUNT_ID,
    NULL::TEXT AS PATRON_ACCOUNT_NAME,
    NULL::TEXT AS EMAIL,
    NULL::TEXT AS SECTION,
    NULL::TEXT AS ROW_,
    NULL::TEXT AS SEAT_NUMBER,
    NULL::FLOAT AS SEAT_ID,
    m.REVENUE AS PRICE,
    NULL::FLOAT AS PAID_AMOUNT,
    m.BUYER_TYPE_GROUP_ID,
    NULL::TEXT AS BUYER_TYPE_GROUP_CODE,
    m.BUYER_TYPE_GROUP_DESCRIPTION,
    m.BUYER_TYPE_ID,
    NULL::TEXT AS BUYER_TYPE_CODE,
    m.BUYER_TYPE_DESCRIPTION,
    NULL::TEXT AS PAYMENT_TYPE_CODE,
    NULL::TEXT AS PAYMENT_METHOD_CODE,
    NULL::NUMBER AS SYSTEM_VERSION,
    NULL::TEXT AS SYSTEM_CURRENT_FLAG,
    m.SYSTEM_CREATE_DATE,
    m.SYSTEM_UPDATE_DATE,
    m.LAST_UPDATE_RUN,
    
    m.MEMBERSHIP_TYPE,
    m.MEMBERSHIP_PLAN,
    m.SEATS AS MEMBERSHIP_SEATS_PER_GAME,
    m.GAMES AS MEMBERSHIP_TOTAL_GAMES,
    m.REVENUE AS REVENUE_TOTAL_MEMBERSHIP,
    
    CASE 
        WHEN m.MEMBERSHIP_TYPE = 'Traditional Sponsor' THEN 'Sponsor'
        WHEN m.MEMBERSHIP_TYPE = 'Flexible' AND m.BUYER_TYPE_GROUP_DESCRIPTION = 'Season Sponsors' THEN 'Sponsor'
        WHEN m.MEMBERSHIP_TYPE = 'Flexible' THEN 'Flex Season'
        ELSE 'Other'
    END AS TICKET_TYPE_GROUPING,
    
    'Membership Detail' AS DATA_SOURCE,
    '2023 Membership' AS DATA_LOGIC,
    
    -- YTD Flags for MEMBERSHIP data: -1095 for 2023
    FALSE AS IS_2024_YTD,
    CASE WHEN m.PURCHASE_DATE <= DATEADD('day', -1095, CURRENT_DATE()) THEN TRUE ELSE FALSE END AS IS_2023_YTD,
    FALSE AS IS_CURRENT_YTD,
    DATEADD('day', -1095, CURRENT_DATE()) AS YTD_CUTOFF_DATE

FROM TBRDP_DW_PROD.IM_RPT.V_SBL_GCP_TDC_MEMBERSHIP_SALES_COMBINED m

WHERE m.SEASON_YEAR = 2023
  AND (m.MEMBERSHIP_TYPE = 'Flexible' OR m.MEMBERSHIP_TYPE = 'Traditional Sponsor')

UNION ALL

-- ========================================
-- PART 4: YEAR 2026 - Transaction Detail
-- ========================================
SELECT 
    t.SEASON_YEAR,
    t.PURCHASE_DATE,
    t.EVENT_DATE,
    t.EVENT_NAME,
    t.EVENT_ID,
    t.FINANCIAL_PATRON_ACCOUNT_ID,
    t.ATTENDING_PATRON_ACCOUNT_ID,
    t.PATRON_ACCOUNT_NAME,
    t.EMAIL,
    t.SECTION,
    t.ROW_,
    t.SEAT_NUMBER,
    t.SEAT_ID,
    t.PRICE,
    t.PAID_AMOUNT,
    t.BUYER_TYPE_GROUP_ID,
    t.BUYER_TYPE_GROUP_CODE,
    t.BUYER_TYPE_GROUP_DESCRIPTION,
    t.BUYER_TYPE_ID,
    t.BUYER_TYPE_CODE,
    t.BUYER_TYPE_DESCRIPTION,
    t.PAYMENT_TYPE_CODE,
    t.PAYMENT_METHOD_CODE,
    t.SYSTEM_VERSION,
    t.SYSTEM_CURRENT_FLAG,
    t.SYSTEM_CREATE_DATE,
    t.SYSTEM_UPDATE_DATE,
    t.LAST_UPDATE_RUN,
    
    NULL::TEXT AS MEMBERSHIP_TYPE,
    NULL::TEXT AS MEMBERSHIP_PLAN,
    NULL::NUMBER AS MEMBERSHIP_SEATS_PER_GAME,
    NULL::NUMBER AS MEMBERSHIP_TOTAL_GAMES,
    NULL::FLOAT AS REVENUE_TOTAL_MEMBERSHIP,
    
    CASE 
        WHEN t.BUYER_TYPE_GROUP_DESCRIPTION IN (
            'Full Season New', 'Full Season Renewals',
            'Half Season New', 'Half Season Renewals',
            'Partial Season New', 'Partial Season Renewal'
        ) THEN 'Traditional Seasons'
        WHEN t.BUYER_TYPE_GROUP_DESCRIPTION IN (
            'Advance Sales', 'Ticket Promotions and Specials'
        ) THEN 'Single Game'
        WHEN t.BUYER_TYPE_GROUP_DESCRIPTION IN (
            'Group Sales', 'Party Areas'
        ) THEN 'Group'
        WHEN t.BUYER_TYPE_GROUP_DESCRIPTION IN (
            'Suite Sales'
        ) THEN 'Suite'
        WHEN t.BUYER_TYPE_GROUP_DESCRIPTION IN (
            'Comps', 'Commissioner Initiative Ticket'
        ) THEN 'Comps'
        WHEN t.BUYER_TYPE_GROUP_DESCRIPTION IN (
            'Group Sponsor', 'Corporate Group Party Areas', 
            'Corporate Group', 'Half and Partial Season Sponso'
        ) THEN 'Sponsor'
        ELSE 'Other'
    END AS TICKET_TYPE_GROUPING,
    
    'Transaction Detail' AS DATA_SOURCE,
    '2026 Transaction' AS DATA_LOGIC,
    
    FALSE AS IS_2024_YTD,
    FALSE AS IS_2023_YTD,
    TRUE AS IS_CURRENT_YTD,
    CURRENT_DATE() AS YTD_CUTOFF_DATE

FROM TBRDP_DW_PROD.IM_RPT.V_SBL_GCP_TDC_REGULAR_SEASON_TICKET_DETAIL t

WHERE t.SEASON_YEAR = 2026
  AND t.SYSTEM_CURRENT_FLAG = 'Y'
  AND t.BUYER_TYPE_GROUP_DESCRIPTION NOT IN (
      'Member New',
      'Member Renewal',
      'Season Sponsors'
  )

UNION ALL

-- ========================================
-- PART 5: YEAR 2026 - Membership Detail
-- ========================================
SELECT 
    m.SEASON_YEAR,
    m.PURCHASE_DATE::TIMESTAMP_NTZ AS PURCHASE_DATE,
    NULL::TIMESTAMP_NTZ AS EVENT_DATE,
    NULL::TEXT AS EVENT_NAME,
    NULL::FLOAT AS EVENT_ID,
    m.FINANCIAL_PATRON_ACCOUNT_ID,
    NULL::FLOAT AS ATTENDING_PATRON_ACCOUNT_ID,
    NULL::TEXT AS PATRON_ACCOUNT_NAME,
    NULL::TEXT AS EMAIL,
    NULL::TEXT AS SECTION,
    NULL::TEXT AS ROW_,
    NULL::TEXT AS SEAT_NUMBER,
    NULL::FLOAT AS SEAT_ID,
    m.REVENUE AS PRICE,
    NULL::FLOAT AS PAID_AMOUNT,
    m.BUYER_TYPE_GROUP_ID,
    NULL::TEXT AS BUYER_TYPE_GROUP_CODE,
    m.BUYER_TYPE_GROUP_DESCRIPTION,
    m.BUYER_TYPE_ID,
    NULL::TEXT AS BUYER_TYPE_CODE,
    m.BUYER_TYPE_DESCRIPTION,
    NULL::TEXT AS PAYMENT_TYPE_CODE,
    NULL::TEXT AS PAYMENT_METHOD_CODE,
    NULL::NUMBER AS SYSTEM_VERSION,
    NULL::TEXT AS SYSTEM_CURRENT_FLAG,
    m.SYSTEM_CREATE_DATE,
    m.SYSTEM_UPDATE_DATE,
    m.LAST_UPDATE_RUN,
    
    m.MEMBERSHIP_TYPE,
    m.MEMBERSHIP_PLAN,
    m.SEATS AS MEMBERSHIP_SEATS_PER_GAME,
    m.GAMES AS MEMBERSHIP_TOTAL_GAMES,
    m.REVENUE AS REVENUE_TOTAL_MEMBERSHIP,
    
    CASE 
        WHEN m.MEMBERSHIP_TYPE = 'Traditional Sponsor' THEN 'Sponsor'
        WHEN m.MEMBERSHIP_TYPE = 'Flexible' AND m.BUYER_TYPE_GROUP_DESCRIPTION = 'Season Sponsors' THEN 'Sponsor'
        WHEN m.MEMBERSHIP_TYPE = 'Flexible' THEN 'Flex Season'
        ELSE 'Other'
    END AS TICKET_TYPE_GROUPING,
    
    'Membership Detail' AS DATA_SOURCE,
    '2026 Membership' AS DATA_LOGIC,
    
    FALSE AS IS_2024_YTD,
    FALSE AS IS_2023_YTD,
    TRUE AS IS_CURRENT_YTD,
    CURRENT_DATE() AS YTD_CUTOFF_DATE

FROM TBRDP_DW_PROD.IM_RPT.V_SBL_GCP_TDC_MEMBERSHIP_SALES_COMBINED m

WHERE m.SEASON_YEAR = 2026
  AND m.SOLD_FLAG_2026 = TRUE
  AND (m.MEMBERSHIP_TYPE = 'Flexible' OR m.MEMBERSHIP_TYPE = 'Traditional Sponsor');


  