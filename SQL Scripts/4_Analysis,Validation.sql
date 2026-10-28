
USE BankLoanAnalytics;
GO

--0:-DATA QUALITY CHECK: NULLS IN KPI / GROUPING FIELDS
SELECT
    SUM(CASE WHEN loan_id IS NULL THEN 1 ELSE 0 END) AS Null_Loan_IDs,
    SUM(CASE WHEN loan_amount IS NULL THEN 1 ELSE 0 END) AS Null_Loan_Amounts,
    SUM(CASE WHEN loan_status IS NULL THEN 1 ELSE 0 END) AS Null_Loan_Statuses,
    SUM(CASE WHEN issue_date IS NULL THEN 1 ELSE 0 END) AS Null_Issue_Dates,
    SUM(CASE WHEN state_key IS NULL THEN 1 ELSE 0 END) AS Null_State_Keys,
    SUM(CASE WHEN purpose_key IS NULL THEN 1 ELSE 0 END) AS Null_Purpose_Keys,
    SUM(CASE WHEN credit_grade_key IS NULL THEN 1 ELSE 0 END) AS Null_Credit_Grade_Keys
FROM analytics.Fact_Loan;
GO

--1.1:- Calcualting and Valadating KPI
SELECT
    COUNT(*) AS Fact_Rows,
    COUNT(DISTINCT loan_id) AS Total_Loans,
    SUM(loan_amount) AS Total_Loan_Amount,
    AVG(CAST(loan_amount AS DECIMAL(18,2))) AS Average_Loan_Amount,

    SUM(CASE WHEN loan_status = 'Fully Paid' THEN 1 ELSE 0 END) AS Good_Loans,
    CAST(100.0 * SUM(CASE WHEN loan_status = 'Fully Paid' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT loan_id), 0) AS DECIMAL(10,2)) AS Good_Loan_Share_Pct,

    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS Charged_Off_Loans,
    CAST(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT loan_id), 0) AS DECIMAL(10,2)) AS Charge_Off_Rate_Pct,

    SUM(CASE WHEN loan_status = 'Current' THEN 1 ELSE 0 END) AS Current_Loans,
    CAST(100.0 * SUM(CASE WHEN loan_status = 'Current' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT loan_id), 0) AS DECIMAL(10,2)) AS Current_Loan_Share_Pct,

    SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END) AS Charged_Off_Loan_Amount,
    CAST(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END)
        / NULLIF(SUM(loan_amount), 0) AS DECIMAL(10,2)) AS Charged_Off_Amount_Share_Pct,

    CAST(AVG(CASE WHEN loan_status = 'Charged Off'
                  THEN CAST(loan_amount AS DECIMAL(18,2)) END) AS DECIMAL(18,2))
        AS Average_Loan_Amount_Of_Charged_Off_Loans,

    CAST(AVG(CAST(int_rate AS DECIMAL(18,6))) * 100 AS DECIMAL(10,2)) AS Average_Interest_Rate_Pct,
    CAST(AVG(CAST(dti AS DECIMAL(18,6))) * 100 AS DECIMAL(10,2)) AS Average_DTI_Pct,
    MIN(CAST(issue_date AS DATE)) AS Earliest_Issue_Date,
    MAX(CAST(issue_date AS DATE)) AS Latest_Issue_Date
FROM analytics.Fact_Loan;
GO

-- 1.2 STATUS RECONCILIATION
-- Counts and amounts should reconcile to the overall KPIs above.
SELECT
    loan_status,
    COUNT(DISTINCT loan_id) AS Total_Loans,
    SUM(loan_amount) AS Total_Loan_Amount,
    CAST(100.0 * COUNT(DISTINCT loan_id)
        / NULLIF((SELECT COUNT(DISTINCT loan_id) FROM analytics.Fact_Loan), 0)
        AS DECIMAL(10,2)) AS Share_Of_All_Loans_Pct,
    CAST(100.0 * SUM(loan_amount)
        / NULLIF((SELECT SUM(loan_amount) FROM analytics.Fact_Loan), 0)
        AS DECIMAL(10,2)) AS Share_Of_Total_Loan_Amount_Pct
FROM analytics.Fact_Loan
GROUP BY loan_status
ORDER BY Total_Loans DESC;
GO

-- 1.3 KPI VALIDATION FOR CREDIT RISK PAGE
-- Count-based rates use ALL loans in each segment, including Current loans.
SELECT
    COUNT(DISTINCT loan_id) AS Total_Loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS Charged_Off_Loans,
    CAST(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT loan_id), 0) AS DECIMAL(10,2)) AS Charge_Off_Rate_Pct,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END) AS Charged_Off_Loan_Amount,
    CAST(AVG(CASE WHEN loan_status = 'Charged Off'
                  THEN CAST(loan_amount AS DECIMAL(18,2)) END) AS DECIMAL(18,2))
        AS Average_Loan_Amount_Of_Charged_Off_Loans,
    CAST(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END)
        / NULLIF(SUM(loan_amount), 0) AS DECIMAL(10,2)) AS Charged_Off_Amount_Share_Pct
FROM analytics.Fact_Loan;
GO

-- 1.4 GEOGRAPHIC KPI VALIDATION
SELECT
    COUNT(DISTINCT F.state_key) AS Geographies_Represented_In_Fact,
    COUNT(DISTINCT S.state_name) AS Distinct_Geography_Names,
    COUNT(DISTINCT F.loan_id) AS Total_Loans,
    SUM(F.loan_amount) AS Total_Loan_Amount,
    SUM(CASE WHEN F.loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS Charged_Off_Loans,
    CAST(100.0 * SUM(CASE WHEN F.loan_status = 'Charged Off' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT F.loan_id), 0) AS DECIMAL(10,2)) AS Charge_Off_Rate_Pct
FROM analytics.Fact_Loan AS F
INNER JOIN analytics.Dim_State AS S
    ON F.state_key = S.state_key;
GO


--2:- Fully Paid Vs Charged off Loan
SELECT
    Loan_Type,
    COUNT(*) AS Total_Loans,
    SUM(loan_amount) as Total_Fund,
    CAST(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER()
        AS DECIMAL(10,2)
    ) AS Loan_Percentage
FROM
    (SELECT
        CASE
            WHEN loan_status = 'Fully Paid'  THEN 'Good Loan'
            WHEN loan_status = 'Charged Off'  THEN 'Bad Loan'
            WHEN loan_status = 'Current'  THEN 'Current Loan'   
         END AS Loan_Type,
         loan_amount
    FROM analytics.Fact_Loan) AS p

GROUP BY Loan_Type
ORDER BY Loan_Percentage desc;
GO


--3:- grades with higher charge of rates
SELECT
    G.grade,
    COUNT(*) AS Total_Loans,
    SUM(CASE
        WHEN F.loan_status = 'Charged Off' THEN 1
        ELSE 0
    END) AS Charged_Off_Loans,
    CAST(
        100.0 * SUM(CASE
            WHEN F.loan_status = 'Charged Off' THEN 1
            ELSE 0
        END) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS Charge_Off_Rate
FROM analytics.Fact_Loan AS F
INNER JOIN analytics.Dim_CreditGrade AS G
    ON F.credit_grade_key = G.credit_grade_key
GROUP BY G.grade
ORDER BY G.grade;
GO

--4:-Loan Term Analysis

SELECT
    term,
    COUNT(*) AS Total_Loans,
    SUM(loan_amount) AS Total_Loan_Amount,
    AVG(loan_amount) AS Average_Loan_Amount,

    SUM(CASE
        WHEN loan_status = 'Charged Off' THEN 1
        ELSE 0
    END) AS Charged_Off_Loans,

    CAST(
        100.0 * SUM(CASE
            WHEN loan_status = 'Charged Off' THEN 1
            ELSE 0
        END) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS Charge_Off_Rate

FROM analytics.Fact_Loan
GROUP BY term
ORDER BY term;
GO

--5:-Loan Purpose Risk Analysis

SELECT
    P.purpose,
    COUNT(*) AS Total_Loans,
    SUM(F.loan_amount) AS Total_Loan_Amount,

    SUM(CASE
        WHEN F.loan_status = 'Charged Off' THEN 1
        ELSE 0
    END) AS Charged_Off_Loans,

    CAST(
        100.0 * SUM(CASE
            WHEN F.loan_status = 'Charged Off' THEN 1
            ELSE 0
        END) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS Charge_Off_Rate

FROM analytics.Fact_Loan AS F
INNER JOIN analytics.Dim_LoanPurpose AS P
    ON F.purpose_key = P.purpose_key

GROUP BY P.purpose
ORDER BY Charge_Off_Rate DESC;
GO

--6:-Geographic Loan Exposure

SELECT
    S.state_name,
    COUNT(*) AS Total_Loans,
    SUM(F.loan_amount) AS Total_Loan_Amount,

    SUM(CASE
        WHEN F.loan_status = 'Charged Off' THEN 1
        ELSE 0
    END) AS Charged_Off_Loans,

    CAST(
        100.0 * SUM(CASE
            WHEN F.loan_status = 'Charged Off' THEN 1
            ELSE 0
        END) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS Charge_Off_Rate

FROM analytics.Fact_Loan AS F
INNER JOIN analytics.Dim_State AS S
    ON F.state_key = S.state_key
GROUP BY S.state_name
ORDER BY Charge_Off_Rate DESC;
GO

/*7:- MONTHLY CHART VALIDATION (Page 1 / time-based visuals)
  Monthly counts should sum to Total_Loans, and monthly amounts should sum
  to Total_Loan_Amount. Use these results to validate the Power BI combo chart.*/
SELECT
    YEAR(issue_date) AS Issue_Year,
    MONTH(issue_date) AS Issue_Month_Number,
    DATENAME(MONTH, issue_date) AS Issue_Month_Name,
    COUNT(DISTINCT loan_id) AS Monthly_Loans_Issued,
    SUM(loan_amount) AS Monthly_Loan_Amount,
    CAST(AVG(CAST(loan_amount AS DECIMAL(18,2))) AS DECIMAL(18,2)) AS Average_Loan_Amount
FROM analytics.Fact_Loan
GROUP BY YEAR(issue_date), MONTH(issue_date), DATENAME(MONTH, issue_date)
ORDER BY Issue_Year, Issue_Month_Number;
GO

-- 5.6 DATA QUALITY CHECK: DUPLICATED LOAN IDS
-- Expected result: zero rows returned.
SELECT
    loan_id,
    COUNT(*) AS Rows_Per_Loan
FROM analytics.Fact_Loan
GROUP BY loan_id
HAVING COUNT(*) > 1;
GO









