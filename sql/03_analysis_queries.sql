-- =========================================================
-- 03_analysis_queries.sql
-- Personal Lending Risk Analytics
-- Author: Viren Jawadwar
--
-- Analytical queries backing the Tableau dashboard KPIs and
-- charts. Grouped by dashboard section.
-- =========================================================

USE lending_risk_db;

-- ---------------------------------------------------------
-- SECTION 1: Headline KPIs
-- ---------------------------------------------------------

-- Total applications, average interest rate, average DTI, default rate
SELECT
    COUNT(*)                                   AS total_applications,
    ROUND(AVG(interest_rate_pct), 2)           AS avg_interest_rate_pct,
    ROUND(AVG(debt_to_income), 2)              AS avg_dti,
    ROUND(AVG(annual_income), 0)               AS avg_annual_income,
    ROUND(SUM(not_fully_paid) / COUNT(*) * 100, 2) AS default_rate_pct
FROM loan_applications;

-- Applications that met the underwriting credit policy vs. not
SELECT
    meets_credit_policy,
    COUNT(*) AS applications,
    ROUND(SUM(not_fully_paid) / COUNT(*) * 100, 2) AS default_rate_pct
FROM loan_applications
GROUP BY meets_credit_policy;

-- ---------------------------------------------------------
-- SECTION 2: Risk by loan purpose
-- ---------------------------------------------------------
SELECT
    loan_purpose,
    COUNT(*)                                       AS applications,
    ROUND(AVG(interest_rate_pct), 2)               AS avg_interest_rate_pct,
    ROUND(SUM(not_fully_paid) / COUNT(*) * 100, 2) AS default_rate_pct
FROM loan_applications
GROUP BY loan_purpose
ORDER BY default_rate_pct DESC;

-- ---------------------------------------------------------
-- SECTION 3: Risk by FICO band
-- ---------------------------------------------------------
SELECT
    fico_band,
    COUNT(*)                                       AS applications,
    ROUND(AVG(interest_rate_pct), 2)               AS avg_interest_rate_pct,
    ROUND(SUM(not_fully_paid) / COUNT(*) * 100, 2) AS default_rate_pct
FROM loan_applications
GROUP BY fico_band
ORDER BY FIELD(fico_band,
    'Poor (300-579)', 'Fair (580-669)', 'Good (670-739)',
    'Very Good (740-799)', 'Exceptional (800-850)');

-- ---------------------------------------------------------
-- SECTION 4: Debt-to-income risk bands
-- ---------------------------------------------------------
SELECT
    CASE
        WHEN debt_to_income < 5  THEN '0-5'
        WHEN debt_to_income < 10 THEN '5-10'
        WHEN debt_to_income < 15 THEN '10-15'
        WHEN debt_to_income < 20 THEN '15-20'
        WHEN debt_to_income < 25 THEN '20-25'
        ELSE '25+'
    END                                             AS dti_band,
    COUNT(*)                                        AS applications,
    ROUND(SUM(not_fully_paid) / COUNT(*) * 100, 2)  AS default_rate_pct
FROM loan_applications
GROUP BY dti_band
ORDER BY MIN(debt_to_income);

-- ---------------------------------------------------------
-- SECTION 5: High-risk applicant flag (used for the DETAILS grid)
--   Flags applicants with 2+ delinquencies, 3+ recent inquiries,
--   or any public record, and did not meet credit policy.
-- ---------------------------------------------------------
SELECT
    application_id,
    loan_purpose,
    fico_score,
    interest_rate_pct,
    debt_to_income,
    delinquencies_2yr,
    inquiries_last_6mo,
    public_records,
    repayment_status,
    CASE
        WHEN meets_credit_policy = 0
          OR delinquencies_2yr >= 2
          OR inquiries_last_6mo >= 3
          OR public_records > 0
        THEN 'High Risk'
        ELSE 'Standard'
    END AS risk_flag
FROM loan_applications
ORDER BY fico_score ASC
LIMIT 200;
