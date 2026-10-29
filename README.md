# Loan Default Risk Analysis with SQL

A SQL project on a lending dataset of 255,347 loans. I set up the database, validated the data, and wrote 11 questions in PostgreSQL to find out which borrower characteristics go along with loan default.

## Tools used
PostgreSQL, pgAdmin, SQL

## The problem

A lender wants to know which borrowers are more likely to default, so interest rates, approvals, and collections effort can be targeted instead of treating every applicant the same. This project looks at one loans table and asks: who defaults more, and is it one factor or a mix of factors?

## About the dataset

One table, `loans`, with 255,347 rows. The dataset doesn't specify which country or currency the amounts are in, so figures below are shown as plain numbers.

| Column | Meaning |
|---|---|
| loan_id | Unique ID for the loan |
| age, income, credit_score | Borrower details |
| loan_amount, interest_rate, loan_term, dti_ratio | Loan details |
| months_employed, num_credit_lines | Employment and credit history |
| education, employment_type, marital_status | Borrower demographics |
| has_mortgage, has_dependents, has_cosigner | Yes/No flags |
| loan_purpose | What the loan is for |
| default_status | 1 if the loan defaulted, 0 if not |

`Default` in the raw file is renamed to `default_status`, since DEFAULT is a reserved SQL keyword and can't be used as a column name.

## Data validation

My other SQL projects had real data problems to fix, like duplicate categories or prices stored wrong. This dataset turned out different: no missing values, no duplicate rows, no values outside a sensible range. I didn't just assume that from a glance, I checked it:

- Ran a null check on every column. Zero missing values anywhere.
- Compared total rows to distinct loan_id count. Both came out to 255,347, so loan_id is fully unique.
- Checked for impossible values: income or loan amount at zero or below, credit score outside 300-850, DTI ratio outside 0-1, age under 18. Zero rows failed any of these.

I kept this step in the project because confirming data is clean is still a decision an analyst has to make, not something to skip because nothing looks wrong at first glance.

## How to run this project

1. Create a database and connect to it.
2. Run the `CREATE TABLE loans (...)` statement in the SQL file.
3. Import the raw CSV into the table (header on, encoding UTF8).
4. Run the validation queries to confirm the row count, nulls, duplicates, and ranges.
5. Run the 11 analysis queries, in any order.

## What the 11 questions cover

Overall default rate, default rate by employment type, credit score band, DTI ratio band, loan purpose, age group, co-signer and mortgage status, and education level. Two questions combine multiple factors: ranking loan purposes by risk within each employment type with a window function, and finding which employment-type and credit-score combinations sit above the overall average default rate with a CTE.

## SQL concepts used

CASE WHEN for bucketing, GROUP BY with aggregation, CTEs, window functions (RANK() OVER PARTITION BY), CROSS JOIN to compare a segment against a benchmark, and validation queries with COUNT and conditional SUM.

Example, ranking loan purposes by default rate inside each employment type:

```sql
WITH purpose_risk AS (
    SELECT
        employment_type,
        loan_purpose,
        COUNT(*) AS total_loans,
        ROUND(SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct
    FROM loans
    GROUP BY employment_type, loan_purpose
)
SELECT
    employment_type,
    loan_purpose,
    total_loans,
    default_rate_pct,
    RANK() OVER (PARTITION BY employment_type ORDER BY default_rate_pct DESC) AS risk_rank
FROM purpose_risk
ORDER BY employment_type, risk_rank;
```

## Key findings

**Age is the strongest factor by itself.**
Default rate drops almost in a straight line as age goes up: 20.76% for 18-25 year olds, down to 5.50% for borrowers 56 and above. That's close to a 4x gap, wider than any other single factor in this data. Credit score, for comparison, only moves about 2.7 points across its whole range.

**Stacking risk factors adds up fast.**
Overall default rate is 11.34% once the highest-risk segment is excluded. Borrowers who are 25 or under, unemployed, and have a credit score below 580, all at once, default at 25.49%, more than double. Only 4,880 of the 255,347 loans fall in this group, but it's the single riskiest segment in the whole dataset.

**Employment status beats credit score once you combine them.**
Among the employment-type and credit-score combos that sit above the average default rate, "Unemployed with fair or better credit" (12.52%) is almost as risky as "Part-time with poor credit" (12.77%). Full-time employment never shows up above average at any credit score, making it the strongest protective factor found here.

**Credit score and DTI ratio move the right way, but not by much on their own.**
Default rate goes from 12.47% (poor credit) down to 9.81% (exceptional credit), and from 10.65% (low DTI) up to 12.29% (very high DTI). Both make sense directionally, but each only spans 2-3 points, far less than age or employment status.

**Loan purpose follows the same pattern in every employment type.**
Business loans default the most (12.33% overall), Home loans the least (10.23% overall). The window-function ranking confirms this holds inside every employment type too, not just overall. Average loan amount is nearly the same across purposes (around 127,000), so it's the purpose itself driving the gap, not the loan size.

**A co-signer and a mortgage each lower risk on their own, and even more together.**
Default rate drops from 13.68% (neither) to 9.70% (both). Each factor helps individually, and having both helps more than either alone.

**More education means lower default, even though income barely changes.**
Default rate goes from 12.88% (High School) to 10.59% (PhD), while average income stays flat across education levels (82,000-83,000). Since income isn't the explanation, something else tied to education level, maybe financial habits or job stability, is likely behind it.

## Limitations

- This dataset came pre-cleaned, so this project shows data validation, not data cleaning. My other SQL projects cover real cleaning work on messier data.
- Everything here is a correlation found by grouping and comparing default rates, not a causal claim.
- The dataset doesn't say which country, currency, or time period it's from, so these patterns are specific to this data, not a general lending rule.

## About me

Palash, data analyst. Skills: SQL, Power BI, Excel, basic Python.
LinkedIn: https://linkedin.com/in/palashadyalkar
