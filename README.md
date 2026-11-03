# Credit Card Customer & Risk Analytics

A beginner-friendly project that answers three questions about a credit card portfolio:

1. Are customers using their cards?
2. Is the bank making money?
3. Which customers might not pay back?

**Tools:** SQL Server | Power BI | Power Query | DAX | Excel

---

## Dataset

Two Excel files, one row per client, joined on `Client_Num` (10,108 clients, Jan to Dec 2023).

| File | What it holds |
|---|---|
| `credit_card2.xlsm` | Card type, credit limit, spend, revolving balance, utilization, interest, delinquency, week of activity |
| `customer_details.xlsm` | Age, job, education, income, home/car/loan status, state, satisfaction score |

Each client appears once, so "weekly" and "monthly" analysis means grouping clients by their `Week_Start_Date`.

---

## How I worked

1. **SQL first.** Checked the data (no duplicates or nulls) and wrote 15 questions to understand each metric.
2. **Power BI second.** Rebuilt the same logic in DAX and made a 4-page dashboard.

---

## What I learned

**SQL**
- Window functions: running total, `LAG()` for MoM and WoW, moving averages with `ROWS BETWEEN 3 PRECEDING AND CURRENT ROW`.
- `PERCENTILE_CONT ... OVER ()` for percentile thresholds.
- `CROSS JOIN` to attach a one-row value (a cutoff date or threshold) to every row.
- `SUM(COUNT(*)) OVER ()` to calculate a percentage of the total.

**DAX**
- A separate Calendar table with a month-sort column makes time charts work.
- Patterns: running total, MoM, WoW, 4-week moving average, `SWITCH(TRUE(), ...)` for risk scoring.
- Count a column with `CALCULATE(DISTINCTCOUNT(...), condition)`.

**Data lessons**
- Client IDs must be Text, or Power BI adds them up.
- `Week_Num` is text, so sort by the date instead.
- Trailing spaces in text columns can cause grouping surprises.

---

## Dashboard pages

| Page | Shows |
|---|---|
| Executive Overview | Total spend, running total, MoM growth, top clients, state map |
| Customer & Card Analysis | Utilization, satisfaction by card, interest earned, loan status |
| Credit Risk | Risk categories, delinquency, high-exposure clients, income vs credit limit |
| Customer & Loan Insights | Loan holders by job, education, home ownership and age |
| Moving Average | Weekly spend and credit limit with 4-week averages |

Screenshots: `Dashboard1.png` to `Dashboard4.png`.

---

## Key numbers

| Metric | Result |
|---|---|
| Total transaction amount | 44.52M |
| Total clients | 10,108 |
| Average credit limit | 8.64K |
| CAC ratio | 2.19% |
| Average utilization | 27.49% |
| Delinquency rate | 6.07% |
| Personal loan customers | 1,286 (12.72%) |

---

## Conclusions

- **Spending built steadily** through the year, reaching about 44.5M by December. Monthly changes move up and down, but the cumulative trend is positive.
- **Utilization is moderate** (27.49%). Only 466 clients use more than 80% of their limit.
- **Most clients are low risk.** 8,712 are Low, 1,382 Medium and 14 High on the composite risk score. 111 clients have a high-exposure profile (balance above 90% of limit and utilization above 80%).
- **About 6% of clients are delinquent**, a small but measurable share worth monitoring.
- **Platinum cards have the lowest satisfaction** (2.72), while Silver and Blue are about 3.2.
- **Income barely predicts credit limit** (correlation about 0.13), so limits depend on more than income.
- **Personal loans** are held by 12.7% of clients, mostly aged 40 to 49 and self-employed or in business. Loan holders have a similar average credit limit to non-holders, so there is room for cross-selling.
- **Three states (TX, NY, CA)** make up about 70% of clients.

---

## Limitations

- Each client has a single snapshot, so the data cannot show how one customer changes over time. Weekly swings partly reflect *which* clients fall in that week.
- The risk score weights and cutoffs are judgment calls, not tuned on real default data.
- Figures here come from the 10,108-row files. Other versions of this dataset may have extra rows, so totals can differ slightly.

---

## Author

Vinay Mehra | [LinkedIn](https://www.linkedin.com/in/vinaymehra19)
