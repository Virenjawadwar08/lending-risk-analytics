# Business Context & Objectives

**Project:** Personal Lending Risk Analytics
**Author:** Viren Jawadwar

## Scenario

A consumer lending business wants to understand which factors in a loan
application are associated with a higher risk of the loan not being
fully repaid, so that:

1. Underwriting policy can be tightened for the highest-risk segments.
2. Pricing (interest rate) can be better aligned with actual risk.
3. Risk/collections teams can prioritize monitoring of high-risk
   accounts already on the books.

## Stakeholders

- **Credit risk / underwriting team** — wants to see which policy
  rules correlate with lower default rates, to inform future rule
  changes.
- **Pricing team** — wants to see whether current interest-rate
  tiers actually track observed default risk by segment.
- **Portfolio / collections managers** — want a filterable view of
  individual applications flagged as high risk.

## Success criteria for this dashboard

- A single glance at the Summary dashboard should answer: "how many
  applications, what's the blended risk profile, and how big is the
  default problem right now?"
- The Overview dashboard should let an analyst drill into *why* —
  by purpose, credit band, and debt burden — without needing SQL access.
- The Details dashboard should let a risk manager pull a working list
  of flagged accounts for manual review.

## Out of scope

- Predictive modeling / machine learning risk scores (this project is
  descriptive analytics only — a natural "phase 2" extension).
- Loan servicing or payment-history time series (the dataset is a
  point-in-time snapshot at origination, not a payment ledger).
