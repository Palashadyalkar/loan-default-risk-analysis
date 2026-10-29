-- Default renamed to default_status because DEFAULT is a reserved SQL keyword
CREATE TABLE loans (
    loan_id          VARCHAR(20) PRIMARY KEY,
    age               INTEGER,
    income            INTEGER,
    loan_amount       INTEGER,
    credit_score      INTEGER,
    months_employed   INTEGER,
    num_credit_lines  INTEGER,
    interest_rate     NUMERIC(5,2),
    loan_term         INTEGER,
    dti_ratio         NUMERIC(4,2),
    education         VARCHAR(20),
    employment_type   VARCHAR(20),
    marital_status    VARCHAR(20),
    has_mortgage      VARCHAR(5),
    has_dependents    VARCHAR(5),
    loan_purpose      VARCHAR(20),
    has_cosigner      VARCHAR(5),
    default_status    INTEGER
);

SELECT * FROM loans;

-- Checking for missing values across all columns
SELECT 
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(age) AS missing_age,
    COUNT(*) - COUNT(income) AS missing_income,
    COUNT(*) - COUNT(credit_score) AS missing_credit_score,
    COUNT(*) - COUNT(loan_amount) AS missing_loan_amount,
    COUNT(*) - COUNT(interest_rate) AS missing_interest_rate,
    COUNT(*) - COUNT(default_status) AS missing_default_status
FROM loans;

-- Checking if loan_id (primary key) has any duplicates, and if any
-- full rows repeat
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT loan_id) AS unique_loan_ids
FROM loans;

-- Checking for values that would be logically invalid for a loan dataset:
-- negative or zero income/loan amount, credit score outside the standard
-- 300-850 range, and DTI ratio outside 0 to 1
SELECT 
    SUM(CASE WHEN income <= 0 THEN 1 ELSE 0 END) AS invalid_income,
    SUM(CASE WHEN loan_amount <= 0 THEN 1 ELSE 0 END) AS invalid_loan_amount,
    SUM(CASE WHEN credit_score < 300 OR credit_score > 850 THEN 1 ELSE 0 END) AS invalid_credit_score,
    SUM(CASE WHEN dti_ratio < 0 OR dti_ratio > 1 THEN 1 ELSE 0 END) AS invalid_dti_ratio,
    SUM(CASE WHEN age < 18 THEN 1 ELSE 0 END) AS invalid_age
FROM loans;

-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------

-- Q1. How many loans are there in total, and what is the overall default rate?
SELECT
    COUNT(*) AS total_loans,
    SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) AS defaulted,
    SUM(CASE WHEN default_status = 0 THEN 1 ELSE 0 END) AS not_defaulted,
    ROUND(SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct
FROM loans;


-- Q2. Which employment type has the highest default rate?
SELECT
    employment_type,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) AS defaulted,
    ROUND(SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct
FROM loans
GROUP BY employment_type
ORDER BY default_rate_pct DESC;


-- Q3. Does credit score actually predict default risk?
SELECT
    CASE
        WHEN credit_score < 580 THEN '1. Poor (<580)'
        WHEN credit_score < 670 THEN '2. Fair (580-669)'
        WHEN credit_score < 740 THEN '3. Good (670-739)'
        WHEN credit_score < 800 THEN '4. Very Good (740-799)'
        ELSE '5. Exceptional (800+)'
    END AS credit_score_band,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) AS defaulted,
    ROUND(SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct
FROM loans
GROUP BY 1
ORDER BY 1;


-- Q4. Does a higher debt-to-income (DTI) ratio lead to more defaults?
SELECT
    CASE
        WHEN dti_ratio < 0.3 THEN '1. Low (<0.3)'
        WHEN dti_ratio < 0.5 THEN '2. Medium (0.3-0.49)'
        WHEN dti_ratio < 0.7 THEN '3. High (0.5-0.69)'
        ELSE '4. Very High (0.7+)'
    END AS dti_band,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) AS defaulted,
    ROUND(SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct
FROM loans
GROUP BY 1
ORDER BY 1;


-- Q5. Does loan purpose affect the default rate?
SELECT
    loan_purpose,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) AS defaulted,
    ROUND(AVG(loan_amount), 0) AS avg_loan_amount,
    ROUND(SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct
FROM loans
GROUP BY loan_purpose
ORDER BY default_rate_pct DESC;


-- Q6. Which age group has the highest default rate?
SELECT
    CASE
        WHEN age BETWEEN 18 AND 25 THEN '1. 18-25'
        WHEN age BETWEEN 26 AND 35 THEN '2. 26-35'
        WHEN age BETWEEN 36 AND 45 THEN '3. 36-45'
        WHEN age BETWEEN 46 AND 55 THEN '4. 46-55'
        ELSE '5. 56+'
    END AS age_group,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) AS defaulted,
    ROUND(SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct
FROM loans
GROUP BY 1
ORDER BY 1;


-- Q7. Does having a co-signer or mortgage reduce the default rate?
SELECT
    has_cosigner,
    has_mortgage,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) AS defaulted,
    ROUND(SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct
FROM loans
GROUP BY has_cosigner, has_mortgage
ORDER BY default_rate_pct DESC;


-- Q8. Which education level has the lowest default rate?
SELECT
    education,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) AS defaulted,
    ROUND(AVG(income), 0) AS avg_income,
    ROUND(SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct
FROM loans
GROUP BY education
ORDER BY default_rate_pct DESC;


-- Q9. Is there a combined risk score pattern? Which risk segment (young + unemployed + poor credit) has the highest default rate?
SELECT
    CASE
        WHEN age <= 25 AND employment_type = 'Unemployed' AND credit_score < 580
        THEN 'High risk (young + unemployed + poor credit)'
        ELSE 'Rest of borrowers'
    END AS risk_segment,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) AS defaulted,
    ROUND(SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct
FROM loans
GROUP BY 1;


-- Q10. Within each employment type, which loan purpose has the highest default rate? (window function)
WITH purpose_risk AS (
    SELECT
        employment_type,
        loan_purpose,
        COUNT(*) AS total_loans,
        SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) AS defaulted,
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


-- Q11. Which segments have a default rate well above the overall average? (CTE)
WITH overall AS (
    SELECT ROUND(SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS avg_default_rate
    FROM loans
),
segment AS (
    SELECT
        employment_type,
        CASE WHEN credit_score < 580 THEN 'Poor' ELSE 'Fair or better' END AS credit_band,
        COUNT(*) AS total_loans,
        ROUND(SUM(CASE WHEN default_status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct
    FROM loans
    GROUP BY employment_type, credit_band
)
SELECT s.*, o.avg_default_rate
FROM segment s
CROSS JOIN overall o
WHERE s.default_rate_pct > o.avg_default_rate
ORDER BY s.default_rate_pct DESC;

