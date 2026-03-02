create database bank_file;

use bank_file;


-- Step 2: Create the table
CREATE TABLE bank_cleaned01 (
    age             INT,
    job             VARCHAR(50),
    marital         VARCHAR(20),
    education       VARCHAR(50),
    [default]       VARCHAR(10),
    housing         VARCHAR(10),
    loan            VARCHAR(10),
    contact         VARCHAR(20),
    month           VARCHAR(10),
    day_of_week     VARCHAR(10),
    duration        INT,
    campaign        INT,
    pdays           INT,
    previous        INT,
    poutcome        VARCHAR(20),
    emp_var_rate    FLOAT,
    cons_price_idx  FLOAT,
    cons_conf_idx   FLOAT,
    euribor3m       FLOAT,
    nr_employed     FLOAT,
    subscribed      VARCHAR(5),
    subscribed_flag INT,
    age_group       VARCHAR(20),
    call_bucket     VARCHAR(20),
    month_num       INT
);

-- Step 3: Verify table was created
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'bank_cleaned01';

BULK INSERT bank_cleaned01
FROM 'C:\Users\kirti\Downloads\bank_cleaned01.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

-- Verify data loaded
SELECT TOP 5 * FROM bank_cleaned01;
SELECT COUNT(*) AS total_rows FROM bank_cleaned01;


--  SQL Analysis in MS SQL Server
-- Bank Marketing Funnel & Conversion Performance Analysis

SELECT 
    COUNT(*) AS total_rows,
    SUM(subscribed_flag) AS total_converted,
    ROUND(SUM(subscribed_flag) * 100.0 / COUNT(*), 2) AS overall_conv_rate_pct
FROM bank_cleaned01;



-- QUERY 1: Overall Funnel KPIs
-- Business Question: What does our funnel look like top to bottom?
-- ============================================================
SELECT
    COUNT(*) AS total_contacts,
    SUM(CASE WHEN duration > 30 THEN 1 ELSE 0 END) AS engaged_leads,
    SUM(subscribed_flag)  AS converted_customers,

    ROUND(SUM(CASE WHEN duration > 30 THEN 1 ELSE 0 END) 
          * 100.0 / COUNT(*), 2)  AS engagement_rate_pct,

    ROUND(SUM(subscribed_flag) * 100.0 / COUNT(*), 1) AS overall_conv_rate_pct,

    ROUND(SUM(subscribed_flag) * 100.0 / 
          NULLIF(SUM(CASE WHEN duration > 30 THEN 1 ELSE 0 END), 0), 1)
          AS engaged_to_converted_pct
FROM bank_cleaned01;


-- ============================================================
-- QUERY 2: Conversion by Contact Channel
-- Business Question: Which channel (cellular vs telephone) performs better?
-- ============================================================
SELECT
    contact AS channel,
    COUNT(*)  AS total_contacts,
    SUM(subscribed_flag) AS converted,
    ROUND(SUM(subscribed_flag) * 100.0 / COUNT(*), 2)  AS conv_rate_pct
FROM bank_cleaned01
GROUP BY contact
ORDER BY conv_rate_pct DESC;


-- ============================================================
-- QUERY 3: Monthly Performance
-- Business Question: Which months have the best conversion rates?
-- ============================================================
SELECT
    month,
    month_num,
    COUNT(*) AS total_contacts,
    SUM(subscribed_flag)  AS converted,
    ROUND(SUM(subscribed_flag) * 100.0 / COUNT(*), 2)  AS conv_rate_pct
FROM bank_cleaned01
GROUP BY month, month_num
ORDER BY month_num ASC;


-- ============================================================
-- QUERY 4: Conversion by Job Type
-- Business Question: Which customer segments convert best?
-- ============================================================
SELECT
    job,
    COUNT(*)  AS total_contacts,
    SUM(subscribed_flag)  AS converted,
    ROUND(SUM(subscribed_flag) * 100.0 / COUNT(*), 2)  AS conv_rate_pct,
    -- Label high/low performers for easy reading
    CASE 
        WHEN SUM(subscribed_flag) * 100.0 / COUNT(*) > 20 THEN 'High Performer'
        WHEN SUM(subscribed_flag) * 100.0 / COUNT(*) > 10 THEN 'Average'
        ELSE 'Low Performer'
    END AS performance_label
FROM bank_cleaned01
GROUP BY job
ORDER BY conv_rate_pct DESC;


-- ============================================================
-- QUERY 5: Age Group Analysis
-- Business Question: Does age affect conversion?
-- ============================================================
SELECT
    age_group,
    COUNT(*)  AS total_contacts,
    SUM(subscribed_flag)  AS converted,
    ROUND(SUM(subscribed_flag) * 100.0 / COUNT(*), 2)  AS conv_rate_pct
FROM bank_cleaned01
GROUP BY age_group
ORDER BY conv_rate_pct DESC;


-- ============================================================
-- QUERY 6: Campaign Call Attempts vs Conversion (Drop-off)
-- Business Question: Does calling more times improve conversion?
-- ============================================================
SELECT
    call_bucket,
    COUNT(*)  AS total_contacts,
    SUM(subscribed_flag) AS converted,
    ROUND(SUM(subscribed_flag) * 100.0 / COUNT(*), 2)  AS conv_rate_pct
FROM bank_cleaned01
GROUP BY call_bucket
ORDER BY 
    CASE call_bucket
        WHEN '1 call'     THEN 1
        WHEN '2-3 calls'  THEN 2
        WHEN '4-5 calls'  THEN 3
        WHEN '6+ calls'   THEN 4
    END;


-- ============================================================
-- QUERY 7: Previous Campaign Outcome Impact
-- Business Question: Do past subscribers convert again?
-- ============================================================
SELECT
    poutcome   AS previous_outcome,
    COUNT(*)  AS total_contacts,
    SUM(subscribed_flag)  AS converted,
    ROUND(SUM(subscribed_flag) * 100.0 / COUNT(*), 2)  AS conv_rate_pct
FROM bank_cleaned01
GROUP BY poutcome
ORDER BY conv_rate_pct DESC;


-- ============================================================
-- QUERY 8: Channel × Month Cross Analysis
-- Business Question: Which channel works best in which month?
-- ============================================================
SELECT
    contact   AS channel,
    month,
    month_num,
    COUNT(*) AS total_contacts,
    SUM(subscribed_flag) AS converted,
    ROUND(SUM(subscribed_flag) * 100.0 / COUNT(*), 2)  AS conv_rate_pct
FROM bank_cleaned01
GROUP BY contact, month, month_num
ORDER BY month_num, conv_rate_pct DESC;


-- ============================================================
-- QUERY 9: Education Level Analysis
-- Business Question: Does education level affect conversion?
-- ============================================================
SELECT
    education,
    COUNT(*)  AS total_contacts,
    SUM(subscribed_flag)   AS converted,
    ROUND(SUM(subscribed_flag) * 100.0 / COUNT(*), 2)  AS conv_rate_pct
FROM bank_cleaned01
WHERE education IS NOT NULL
GROUP BY education
ORDER BY conv_rate_pct DESC;


-- ============================================================
-- QUERY 10: Call Quality Impact
-- Business Question: Do longer calls lead to more conversions?
-- ============================================================

SELECT                                              -- Categorizes calls by duration and measures conversion rate
    CASE 
        WHEN duration < 120  THEN '1. Short (<2 min)'
        WHEN duration < 300  THEN '2. Medium (2-5 min)'
        WHEN duration < 600  THEN '3. Long (5-10 min)'
        ELSE                      '4. Very Long (10+ min)'
    END AS call_quality,

    COUNT(*) AS total_calls,
    SUM(subscribed_flag)  AS conversions,
    ROUND(AVG(CAST(subscribed_flag AS FLOAT)) * 100, 2) AS conversion_rate_pct,
    ROUND(AVG(CAST(duration AS FLOAT)), 0)  AS avg_duration_sec

FROM bank_cleaned01
GROUP BY 
    CASE 
        WHEN duration < 120  THEN '1. Short (<2 min)'
        WHEN duration < 300  THEN '2. Medium (2-5 min)'
        WHEN duration < 600  THEN '3. Long (5-10 min)'
        ELSE                      '4. Very Long (10+ min)'
    END
ORDER BY call_quality;



