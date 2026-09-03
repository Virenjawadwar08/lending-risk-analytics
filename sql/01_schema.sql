-- =========================================================
-- 01_schema.sql
-- Personal Lending Risk Analytics
-- Author: Viren Jawadwar
--
-- Creates the database and staging/clean tables used for the
-- lending risk analysis. Designed for MySQL 8.x.
-- =========================================================

CREATE DATABASE IF NOT EXISTS lending_risk_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE lending_risk_db;

-- -------------------------------------------------
-- Raw staging table: mirrors the CSV export exactly,
-- so we can re-run the load without transforming on the way in.
-- -------------------------------------------------
DROP TABLE IF EXISTS loan_applications_staging;
CREATE TABLE loan_applications_staging (
    credit_policy          TINYINT,
    purpose                VARCHAR(30),
    interest_rate          DECIMAL(6,4),
    installment             DECIMAL(10,2),
    log_annual_income       DECIMAL(12,8),
    dti                     DECIMAL(6,2),
    fico                    SMALLINT,
    credit_line_age_days    DECIMAL(12,6),
    revolving_balance       INT,
    revolving_utilization   DECIMAL(6,2),
    inquiries_last_6mo      SMALLINT,
    delinquencies_2yr       SMALLINT,
    public_records          SMALLINT,
    not_fully_paid          TINYINT
);

-- -------------------------------------------------
-- Clean/analysis table: this is what Tableau connects to.
-- Populated from the staging table via 02_etl_transform.sql
-- (or directly from the Python-cleaned CSV — see README).
-- -------------------------------------------------
DROP TABLE IF EXISTS loan_applications;
CREATE TABLE loan_applications (
    application_id           INT AUTO_INCREMENT PRIMARY KEY,
    meets_credit_policy      TINYINT NOT NULL,
    loan_purpose              VARCHAR(30) NOT NULL,
    interest_rate_pct         DECIMAL(6,3) NOT NULL,
    monthly_installment        DECIMAL(10,2) NOT NULL,
    annual_income               DECIMAL(12,2) NOT NULL,
    debt_to_income              DECIMAL(6,2) NOT NULL,
    fico_score                   SMALLINT NOT NULL,
    fico_band                    VARCHAR(25) NOT NULL,
    credit_line_age_years        DECIMAL(6,1) NOT NULL,
    revolving_balance             INT NOT NULL,
    revolving_utilization_pct     DECIMAL(6,2) NOT NULL,
    inquiries_last_6mo             SMALLINT NOT NULL,
    delinquencies_2yr               SMALLINT NOT NULL,
    public_records                   SMALLINT NOT NULL,
    not_fully_paid                   TINYINT NOT NULL,
    repayment_status                  VARCHAR(20) NOT NULL,
    INDEX idx_purpose (loan_purpose),
    INDEX idx_fico_band (fico_band),
    INDEX idx_not_fully_paid (not_fully_paid)
);
