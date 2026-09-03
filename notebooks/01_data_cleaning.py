"""
01_data_cleaning.py
--------------------
Personal Lending Risk Analytics — Data Cleaning & Preparation

Author: Viren Jawadwar
Purpose: Load the raw lending applicant dataset, validate and clean it,
engineer a handful of analysis-ready fields, and write a cleaned CSV
that is later loaded into MySQL for the SQL analysis layer and used as
the Tableau Public data source.

Run with:  python 01_data_cleaning.py
"""

import pandas as pd
import numpy as np
from pathlib import Path

RAW_PATH = Path(__file__).resolve().parent.parent / "data" / "raw" / "lending_data_raw.csv"
OUT_PATH = Path(__file__).resolve().parent.parent / "data" / "processed" / "lending_data_clean.csv"


def load_raw(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    print(f"Loaded {len(df):,} rows, {df.shape[1]} columns from {path.name}")
    return df


def rename_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Give the source columns clearer, snake_case names for downstream
    SQL/Tableau work instead of the dotted originals (e.g. 'int.rate')."""
    rename_map = {
        "credit.policy": "meets_credit_policy",
        "purpose": "loan_purpose",
        "int.rate": "interest_rate",
        "installment": "monthly_installment",
        "log.annual.inc": "log_annual_income",
        "dti": "debt_to_income",
        "fico": "fico_score",
        "days.with.cr.line": "credit_line_age_days",
        "revol.bal": "revolving_balance",
        "revol.util": "revolving_utilization_pct",
        "inq.last.6mths": "inquiries_last_6mo",
        "delinq.2yrs": "delinquencies_2yr",
        "pub.rec": "public_records",
        "not.fully.paid": "not_fully_paid",
    }
    return df.rename(columns=rename_map)


def clean(df: pd.DataFrame) -> pd.DataFrame:
    before = len(df)

    # Drop exact duplicate applications
    df = df.drop_duplicates()

    # Basic range validation — FICO scores outside a plausible band and
    # negative/absurd utilization values are treated as data errors.
    df = df[(df["fico_score"] >= 300) & (df["fico_score"] <= 850)]
    df = df[df["revolving_utilization_pct"].between(0, 150)]
    df = df[df["debt_to_income"] >= 0]

    # No missing values in this source, but guard against future runs
    # with a different extract that might contain nulls.
    na_before = df.isna().sum().sum()
    df = df.dropna()
    na_after = na_before - df.isna().sum().sum()

    after = len(df)
    print(f"Cleaning: dropped {before - after:,} rows "
          f"(duplicates/out-of-range), fixed {na_after} missing values.")
    return df


def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    # Convert the log-transformed income back to a dollar figure — useful
    # for dashboard KPIs where "log annual income" means nothing to a
    # bank manager.
    df["annual_income"] = np.expm1(df["log_annual_income"]).round(0)

    # FICO band, used for grouped risk charts in Tableau.
    bins = [300, 579, 669, 739, 799, 850]
    labels = ["Poor (300-579)", "Fair (580-669)", "Good (670-739)",
              "Very Good (740-799)", "Exceptional (800-850)"]
    df["fico_band"] = pd.cut(df["fico_score"], bins=bins, labels=labels, include_lowest=True)

    # Human-readable outcome label for the target variable.
    df["repayment_status"] = np.where(df["not_fully_paid"] == 1, "Not Fully Paid", "Fully Paid")

    # Credit line age in years, easier to read than raw days.
    df["credit_line_age_years"] = (df["credit_line_age_days"] / 365).round(1)

    return df


def main():
    df = load_raw(RAW_PATH)
    df = rename_columns(df)
    df = clean(df)
    df = engineer_features(df)

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(OUT_PATH, index=False)
    print(f"Wrote cleaned dataset -> {OUT_PATH} ({len(df):,} rows, {df.shape[1]} columns)")

    # Quick sanity summary printed to console for the README screenshots.
    print("\nDefault rate overall: {:.1%}".format(df["not_fully_paid"].mean()))
    print("Default rate by credit policy:")
    print(df.groupby("meets_credit_policy")["not_fully_paid"].mean().round(3))


if __name__ == "__main__":
    main()
