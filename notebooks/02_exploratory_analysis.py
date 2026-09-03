"""
02_exploratory_analysis.py
---------------------------
Personal Lending Risk Analytics — Exploratory Data Analysis

Author: Viren Jawadwar

Generates the summary charts referenced in the project README:
  1. Default rate by loan purpose
  2. FICO band vs. default rate
  3. Interest rate distribution by repayment status
  4. Debt-to-income vs. default rate (binned)

Run with:  python 02_exploratory_analysis.py
"""

import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

DATA_PATH = Path(__file__).resolve().parent.parent / "data" / "processed" / "lending_data_clean.csv"
IMG_DIR = Path(__file__).resolve().parent.parent / "images"

plt.rcParams["figure.dpi"] = 120
plt.rcParams["font.size"] = 10


def load():
    df = pd.read_csv(DATA_PATH)
    df["fico_band"] = pd.Categorical(
        df["fico_band"],
        categories=["Poor (300-579)", "Fair (580-669)", "Good (670-739)",
                    "Very Good (740-799)", "Exceptional (800-850)"],
        ordered=True,
    )
    return df


def chart_default_by_purpose(df, out):
    rate = (df.groupby("loan_purpose")["not_fully_paid"]
              .mean().sort_values(ascending=False) * 100)
    fig, ax = plt.subplots(figsize=(7, 4.5))
    rate.plot(kind="barh", ax=ax, color="#2b6cb0")
    ax.set_xlabel("Default rate (%)")
    ax.set_ylabel("")
    ax.set_title("Default Rate by Loan Purpose")
    ax.invert_yaxis()
    fig.tight_layout()
    fig.savefig(out, bbox_inches="tight")
    plt.close(fig)


def chart_default_by_fico_band(df, out):
    rate = df.groupby("fico_band", observed=True)["not_fully_paid"].mean() * 100
    fig, ax = plt.subplots(figsize=(7, 4.5))
    rate.plot(kind="bar", ax=ax, color="#c53030")
    ax.set_ylabel("Default rate (%)")
    ax.set_xlabel("")
    ax.set_title("Default Rate by FICO Band")
    plt.xticks(rotation=30, ha="right")
    fig.tight_layout()
    fig.savefig(out, bbox_inches="tight")
    plt.close(fig)


def chart_interest_rate_by_status(df, out):
    fig, ax = plt.subplots(figsize=(7, 4.5))
    for status, color in [("Fully Paid", "#2f855a"), ("Not Fully Paid", "#c53030")]:
        subset = df[df["repayment_status"] == status]["interest_rate"] * 100
        ax.hist(subset, bins=30, alpha=0.6, label=status, color=color)
    ax.set_xlabel("Interest rate (%)")
    ax.set_ylabel("Number of loans")
    ax.set_title("Interest Rate Distribution by Repayment Status")
    ax.legend()
    fig.tight_layout()
    fig.savefig(out, bbox_inches="tight")
    plt.close(fig)


def chart_dti_vs_default(df, out):
    bins = [0, 5, 10, 15, 20, 25, 30]
    df = df.copy()
    df["dti_band"] = pd.cut(df["debt_to_income"], bins=bins)
    rate = df.groupby("dti_band", observed=True)["not_fully_paid"].mean() * 100
    fig, ax = plt.subplots(figsize=(7, 4.5))
    rate.plot(kind="line", marker="o", ax=ax, color="#805ad5")
    ax.set_ylabel("Default rate (%)")
    ax.set_xlabel("Debt-to-income band")
    ax.set_title("Default Rate vs. Debt-to-Income Ratio")
    plt.xticks(rotation=30, ha="right")
    fig.tight_layout()
    fig.savefig(out, bbox_inches="tight")
    plt.close(fig)


def main():
    IMG_DIR.mkdir(parents=True, exist_ok=True)
    df = load()

    chart_default_by_purpose(df, IMG_DIR / "default_rate_by_purpose.png")
    chart_default_by_fico_band(df, IMG_DIR / "default_rate_by_fico_band.png")
    chart_interest_rate_by_status(df, IMG_DIR / "interest_rate_distribution.png")
    chart_dti_vs_default(df, IMG_DIR / "dti_vs_default_rate.png")

    print(f"Saved 4 charts to {IMG_DIR}")


if __name__ == "__main__":
    main()
