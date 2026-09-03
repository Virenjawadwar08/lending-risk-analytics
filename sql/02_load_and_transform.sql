-- =========================================================
-- 02_load_and_transform.sql
-- Personal Lending Risk Analytics
-- Author: Viren Jawadwar
--
-- Loads the raw CSV into the staging table, then transforms
-- it into the analysis-ready loan_applications table.
--
-- NOTE: Update the file path below to match your local
-- environment before running (MySQL's LOAD DATA INFILE needs
-- an absolute path, and 'secure_file_priv' restrictions may
-- apply — see the README for the workaround).
-- =========================================================

USE lending_risk_db;

-- -------------------------------------------------
-- 1. Load raw CSV into staging
-- -------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/data/raw/lending_data_raw.csv'
INTO TABLE loan_applications_staging
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(credit_policy, purpose, interest_rate, installment, log_annual_income,
 dti, fico, credit_line_age_days, revolving_balance, revolving_utilization,
 inquiries_last_6mo, delinquencies_2yr, public_records, not_fully_paid);

-- Sanity check row count
SELECT COUNT(*) AS staged_rows FROM loan_applications_staging;

-- -------------------------------------------------
-- 2. Transform into the clean analysis table
--    - convert log income back to dollars
--    - bucket FICO into bands
--    - add a readable repayment status label
-- -------------------------------------------------
TRUNCATE TABLE loan_applications;

INSERT INTO loan_applications (
    meets_credit_policy, loan_purpose, interest_rate_pct, monthly_installment,
    annual_income, debt_to_income, fico_score, fico_band,
    credit_line_age_years, revolving_balance, revolving_utilization_pct,
    inquiries_last_6mo, delinquencies_2yr, public_records,
    not_fully_paid, repayment_status
)
SELECT
    credit_policy,
    purpose,
    ROUND(interest_rate * 100, 3)                       AS interest_rate_pct,
    installment,
    ROUND(EXP(log_annual_income) - 1, 2)                AS annual_income,
    dti,
    fico,
    CASE
        WHEN fico BETWEEN 300 AND 579 THEN 'Poor (300-579)'
        WHEN fico BETWEEN 580 AND 669 THEN 'Fair (580-669)'
        WHEN fico BETWEEN 670 AND 739 THEN 'Good (670-739)'
        WHEN fico BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
        ELSE 'Exceptional (800-850)'
    END                                                  AS fico_band,
    ROUND(credit_line_age_days / 365, 1)                AS credit_line_age_years,
    revolving_balance,
    revolving_utilization,
    inquiries_last_6mo,
    delinquencies_2yr,
    public_records,
    not_fully_paid,
    CASE WHEN not_fully_paid = 1 THEN 'Not Fully Paid' ELSE 'Fully Paid' END
FROM loan_applications_staging
-- basic data-quality filter: drop impossible FICO / utilization values
WHERE fico BETWEEN 300 AND 850
  AND revolving_utilization BETWEEN 0 AND 150
  AND dti >= 0;

SELECT COUNT(*) AS clean_rows FROM loan_applications;
