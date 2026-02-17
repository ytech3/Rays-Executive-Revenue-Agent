CREATE OR REPLACE SEMANTIC VIEW TBRDP_DW_PROD.IM_RPT.EXECUTIVE_SEMANTIC_VIEW
  TABLES (
    ticket_sales AS TBRDP_DW_PROD.IM_RPT.V_TDC_TICKET_SALES_UNIFIED
  )
  
  DIMENSIONS (
    ticket_sales.season_year AS SEASON_YEAR,
    ticket_sales.ticket_type AS TICKET_TYPE_GROUPING,
    ticket_sales.data_source AS DATA_SOURCE,
    ticket_sales.purchase_date AS PURCHASE_DATE
      WITH SYNONYMS = ('date', 'sale date', 'transaction date', 'purchase day', 'when'),
    ticket_sales.purchase_year AS YEAR(PURCHASE_DATE),
    ticket_sales.purchase_month AS MONTHNAME(PURCHASE_DATE),
    ticket_sales.purchase_quarter AS CONCAT('Q', QUARTER(PURCHASE_DATE)),
    ticket_sales.purchase_week AS WEEKOFYEAR(PURCHASE_DATE)
      WITH SYNONYMS = ('week number', 'week of year', 'calendar week', 'week'),
    ticket_sales.purchase_day_of_week AS DAYNAME(PURCHASE_DATE)
      WITH SYNONYMS = ('day of week', 'weekday', 'day name'),
    ticket_sales.is_2024_ytd AS IS_2024_YTD,
    ticket_sales.is_2023_ytd AS IS_2023_YTD,
    ticket_sales.is_current_ytd AS IS_CURRENT_YTD
  )
  
  METRICS (
    -- ========================================
    -- CORE REVENUE METRICS
    -- ========================================
    ticket_sales.total_revenue AS SUM(PRICE)
      WITH SYNONYMS = ('revenue', 'sales', 'total', 'total sales', 'gross revenue', 'ticket revenue', 'all revenue'),
    
    ticket_sales.tickets_sold AS COUNT(*)
      WITH SYNONYMS = ('count', 'volume', 'ticket count', 'number of tickets', 'tickets', 'quantity'),
    
    ticket_sales.unique_patrons AS COUNT(DISTINCT FINANCIAL_PATRON_ACCOUNT_ID)
      WITH SYNONYMS = ('customers', 'patron count', 'unique customers', 'buyers', 'customer count', 'patrons', 'unique buyers'),
    
    ticket_sales.avg_price AS AVG(PRICE)
      WITH SYNONYMS = ('average price', 'avg ticket price', 'average ticket price', 'mean price'),
    
    -- ========================================
    -- CATEGORY-SPECIFIC REVENUE (ALL TIME)
    -- ========================================
    ticket_sales.traditional_season_revenue AS SUM(CASE WHEN TICKET_TYPE_GROUPING = 'Traditional Seasons' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('season ticket revenue', 'traditional revenue', 'season tickets', 'full season', 'half season', 'partial season', 'sth revenue', 'season ticket holder revenue'),
    
    ticket_sales.single_game_revenue AS SUM(CASE WHEN TICKET_TYPE_GROUPING = 'Single Game' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('single game', 'individual game', 'game day revenue', 'single ticket revenue', 'walk up', 'advance sales'),
    
    ticket_sales.flex_revenue AS SUM(CASE WHEN TICKET_TYPE_GROUPING = 'Flex Season' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('flex', 'flexible', 'flex plan', 'flex membership', 'flexible membership', 'membership revenue'),
    
    ticket_sales.suite_revenue AS SUM(CASE WHEN TICKET_TYPE_GROUPING = 'Suite' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('luxury revenue', 'suite sales', 'premium revenue', 'luxury suite', 'premium seating', 'suites'),
    
    ticket_sales.group_revenue AS SUM(CASE WHEN TICKET_TYPE_GROUPING = 'Group' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('group sales', 'groups', 'bulk sales', 'corporate groups', 'party areas', 'group tickets'),
    
    ticket_sales.sponsor_revenue AS SUM(CASE WHEN TICKET_TYPE_GROUPING = 'Sponsor' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('sponsorship', 'sponsor tickets', 'corporate sponsor', 'sponsored tickets'),
    
    ticket_sales.comps_value AS SUM(CASE WHEN TICKET_TYPE_GROUPING = 'Comps' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('complimentary value', 'comps', 'complimentary', 'free tickets', 'comp tickets'),
    
    -- ========================================
    -- 2026 CURRENT YEAR METRICS
    -- ========================================
    ticket_sales.revenue_2026 AS SUM(CASE WHEN SEASON_YEAR = 2026 THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('current year revenue', 'this year revenue', '2026 revenue', '2026 sales', 'current season'),
    
    -- ========================================
    -- 2024 YTD METRICS (Total and by Category)
    -- YTD = Year-to-date at equivalent point in sales cycle
    -- ========================================
    ticket_sales.revenue_2024_ytd AS SUM(CASE WHEN IS_2024_YTD = TRUE THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2024 ytd', 'last year ytd', '2024 year to date', 'ytd 2024', '2024 ytd revenue', '2024 ytd sales'),
    
    ticket_sales.traditional_2024_ytd AS SUM(CASE WHEN IS_2024_YTD = TRUE AND TICKET_TYPE_GROUPING = 'Traditional Seasons' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2024 ytd traditional', 'traditional ytd 2024', '2024 season ticket ytd'),
    
    ticket_sales.single_game_2024_ytd AS SUM(CASE WHEN IS_2024_YTD = TRUE AND TICKET_TYPE_GROUPING = 'Single Game' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2024 ytd single game', 'single game ytd 2024'),
    
    ticket_sales.flex_2024_ytd AS SUM(CASE WHEN IS_2024_YTD = TRUE AND TICKET_TYPE_GROUPING = 'Flex Season' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2024 ytd flex', 'flex ytd 2024', '2024 flex membership ytd'),
    
    ticket_sales.suite_2024_ytd AS SUM(CASE WHEN IS_2024_YTD = TRUE AND TICKET_TYPE_GROUPING = 'Suite' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2024 ytd suite', 'suite ytd 2024', '2024 luxury ytd'),
    
    ticket_sales.group_2024_ytd AS SUM(CASE WHEN IS_2024_YTD = TRUE AND TICKET_TYPE_GROUPING = 'Group' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2024 ytd group', 'group ytd 2024', '2024 group sales ytd'),
    
    ticket_sales.sponsor_2024_ytd AS SUM(CASE WHEN IS_2024_YTD = TRUE AND TICKET_TYPE_GROUPING = 'Sponsor' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2024 ytd sponsor', 'sponsor ytd 2024'),
    
    ticket_sales.comps_2024_ytd AS SUM(CASE WHEN IS_2024_YTD = TRUE AND TICKET_TYPE_GROUPING = 'Comps' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2024 ytd comps', 'comps ytd 2024'),
    
    -- ========================================
    -- 2023 YTD METRICS (Total and by Category)
    -- ========================================
    ticket_sales.revenue_2023_ytd AS SUM(CASE WHEN IS_2023_YTD = TRUE THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2023 ytd', '2023 year to date', 'ytd 2023', '2023 ytd revenue', '2023 ytd sales'),
    
    ticket_sales.traditional_2023_ytd AS SUM(CASE WHEN IS_2023_YTD = TRUE AND TICKET_TYPE_GROUPING = 'Traditional Seasons' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2023 ytd traditional', 'traditional ytd 2023'),
    
    ticket_sales.single_game_2023_ytd AS SUM(CASE WHEN IS_2023_YTD = TRUE AND TICKET_TYPE_GROUPING = 'Single Game' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2023 ytd single game', 'single game ytd 2023'),
    
    ticket_sales.flex_2023_ytd AS SUM(CASE WHEN IS_2023_YTD = TRUE AND TICKET_TYPE_GROUPING = 'Flex Season' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2023 ytd flex', 'flex ytd 2023'),
    
    ticket_sales.suite_2023_ytd AS SUM(CASE WHEN IS_2023_YTD = TRUE AND TICKET_TYPE_GROUPING = 'Suite' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2023 ytd suite', 'suite ytd 2023'),
    
    ticket_sales.group_2023_ytd AS SUM(CASE WHEN IS_2023_YTD = TRUE AND TICKET_TYPE_GROUPING = 'Group' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2023 ytd group', 'group ytd 2023'),
    
    ticket_sales.sponsor_2023_ytd AS SUM(CASE WHEN IS_2023_YTD = TRUE AND TICKET_TYPE_GROUPING = 'Sponsor' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2023 ytd sponsor', 'sponsor ytd 2023'),
    
    ticket_sales.comps_2023_ytd AS SUM(CASE WHEN IS_2023_YTD = TRUE AND TICKET_TYPE_GROUPING = 'Comps' THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('2023 ytd comps', 'comps ytd 2023'),
    
    -- ========================================
    -- YEAR-OVER-YEAR GROWTH METRICS
    -- ========================================
    ticket_sales.yoy_growth_vs_2024 AS CASE WHEN SUM(CASE WHEN IS_2024_YTD = TRUE THEN PRICE ELSE 0 END) = 0 THEN 0 ELSE (SUM(CASE WHEN SEASON_YEAR = 2026 THEN PRICE ELSE 0 END) - SUM(CASE WHEN IS_2024_YTD = TRUE THEN PRICE ELSE 0 END)) / SUM(CASE WHEN IS_2024_YTD = TRUE THEN PRICE ELSE 0 END) END
      WITH SYNONYMS = ('growth vs last year', 'yoy percent', 'yoy growth 2024', 'year over year 2024', 'yoy vs 2024', '2024 growth rate', 'compared to last year'),
    
    ticket_sales.yoy_growth_vs_2023 AS CASE WHEN SUM(CASE WHEN IS_2023_YTD = TRUE THEN PRICE ELSE 0 END) = 0 THEN 0 ELSE (SUM(CASE WHEN SEASON_YEAR = 2026 THEN PRICE ELSE 0 END) - SUM(CASE WHEN IS_2023_YTD = TRUE THEN PRICE ELSE 0 END)) / SUM(CASE WHEN IS_2023_YTD = TRUE THEN PRICE ELSE 0 END) END
      WITH SYNONYMS = ('growth vs 2023', 'yoy growth 2023', 'year over year 2023', 'yoy vs 2023', '2023 growth rate', 'compared to 2023'),
    
    ticket_sales.yoy_dollar_diff_vs_2024 AS SUM(CASE WHEN SEASON_YEAR = 2026 THEN PRICE ELSE 0 END) - SUM(CASE WHEN IS_2024_YTD = TRUE THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('revenue difference', 'dollar change', 'dollar difference vs 2024', 'revenue change vs 2024', 'difference from last year'),
    
    ticket_sales.yoy_dollar_diff_vs_2023 AS SUM(CASE WHEN SEASON_YEAR = 2026 THEN PRICE ELSE 0 END) - SUM(CASE WHEN IS_2023_YTD = TRUE THEN PRICE ELSE 0 END)
      WITH SYNONYMS = ('dollar difference vs 2023', 'revenue change vs 2023', 'difference from 2023')
  );


ALTER CORTEX SEARCH SERVICE TBRDP_DW_PROD.IM_RPT.TICKET_SALES_AGENT 
RENAME TO EXECUTIVE_TICKETING_PARTNERSHIP_REVENUE_AGENT;

ALTER CORTEX ANALYST TBRDP_DW_PROD.IM_RPT.TICKET_SALES_AGENT 
RENAME TO EXECUTIVE_TICKETING_PARTNERSHIP_REVENUE_AGENT;