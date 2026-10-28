use BankLoanAnalytics
GO


--Identifying Null Values for Each Column
SELECT
    COUNT(*) AS TotalRows,

    SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS Null_ID,
    SUM(CASE WHEN address_state IS NULL THEN 1 ELSE 0 END) AS Null_State,
    SUM(CASE WHEN application_type IS NULL THEN 1 ELSE 0 END) AS Null_ApplicationType,
    SUM(CASE WHEN emp_length IS NULL THEN 1 ELSE 0 END) AS Null_EmpLength,
    SUM(CASE WHEN emp_title IS NULL THEN 1 ELSE 0 END) AS Null_EmpTitle,
    SUM(CASE WHEN grade IS NULL THEN 1 ELSE 0 END) AS Null_Grade,
    SUM(CASE WHEN home_ownership IS NULL THEN 1 ELSE 0 END) AS Null_HomeOwnership,
    SUM(CASE WHEN issue_date IS NULL THEN 1 ELSE 0 END) AS Null_IssueDate,
    SUM(CASE WHEN last_credit_pull_date IS NULL THEN 1 ELSE 0 END) AS Null_CreditPullDate,
    SUM(CASE WHEN last_payment_date IS NULL THEN 1 ELSE 0 END) AS Null_LastPaymentDate,
    SUM(CASE WHEN loan_status IS NULL THEN 1 ELSE 0 END) AS Null_LoanStatus,
    SUM(CASE WHEN next_payment_date IS NULL THEN 1 ELSE 0 END) AS Null_NextPaymentDate,
    SUM(CASE WHEN member_id IS NULL THEN 1 ELSE 0 END) AS Null_MemberID,
    SUM(CASE WHEN purpose IS NULL THEN 1 ELSE 0 END) AS Null_Purpose,
    SUM(CASE WHEN sub_grade IS NULL THEN 1 ELSE 0 END) AS Null_SubGrade,
    SUM(CASE WHEN term IS NULL THEN 1 ELSE 0 END) AS Null_Term,
    SUM(CASE WHEN verification_status IS NULL THEN 1 ELSE 0 END) AS Null_VerificationStatus,
    SUM(CASE WHEN annual_income IS NULL THEN 1 ELSE 0 END) AS Null_AnnualIncome,
    SUM(CASE WHEN dti IS NULL THEN 1 ELSE 0 END) AS Null_DTI,
    SUM(CASE WHEN installment IS NULL THEN 1 ELSE 0 END) AS Null_Installment,
    SUM(CASE WHEN int_rate IS NULL THEN 1 ELSE 0 END) AS Null_InterestRate,
    SUM(CASE WHEN loan_amount IS NULL THEN 1 ELSE 0 END) AS Null_LoanAmount,
    SUM(CASE WHEN total_acc IS NULL THEN 1 ELSE 0 END) AS Null_TotalAccounts,
    SUM(CASE WHEN total_payment IS NULL THEN 1 ELSE 0 END) AS Null_TotalPayment

FROM dbo.Financial_Loan_Stagging;


--Checking For Null Values in emp_title
SELECT *
FROM dbo.Financial_Loan_Stagging
WHERE emp_title IS NULL;
GO

--Checking Blank values in text strings
SELECT
    SUM(CASE WHEN LTRIM(RTRIM(address_state)) = '' THEN 1 ELSE 0 END) AS Blank_State,
    SUM(CASE WHEN LTRIM(RTRIM(application_type)) = '' THEN 1 ELSE 0 END) AS Blank_ApplicationType,
    SUM(CASE WHEN LTRIM(RTRIM(emp_length)) = '' THEN 1 ELSE 0 END) AS Blank_EmpLength,
    SUM(CASE WHEN LTRIM(RTRIM(emp_title)) = '' THEN 1 ELSE 0 END) AS Blank_EmpTitle,
    SUM(CASE WHEN LTRIM(RTRIM(grade)) = '' THEN 1 ELSE 0 END) AS Blank_Grade,
    SUM(CASE WHEN LTRIM(RTRIM(home_ownership)) = '' THEN 1 ELSE 0 END) AS Blank_HomeOwnership,
    SUM(CASE WHEN LTRIM(RTRIM(loan_status)) = '' THEN 1 ELSE 0 END) AS Blank_LoanStatus,
    SUM(CASE WHEN LTRIM(RTRIM(purpose)) = '' THEN 1 ELSE 0 END) AS Blank_Purpose,
    SUM(CASE WHEN LTRIM(RTRIM(sub_grade)) = '' THEN 1 ELSE 0 END) AS Blank_SubGrade,
    SUM(CASE WHEN LTRIM(RTRIM(term)) = '' THEN 1 ELSE 0 END) AS Blank_Term,
    SUM(CASE WHEN LTRIM(RTRIM(verification_status)) = '' THEN 1 ELSE 0 END) AS Blank_VerificationStatus
FROM dbo.Financial_Loan_Stagging;

--Checking Duplicate loan ID
SELECT
    id,
    COUNT(*) AS RecordCount
FROM dbo.Financial_Loan_Stagging
GROUP BY id
HAVING COUNT(*) > 1;

--Checking Borrower with more than one loan
SELECT
    member_id,
    COUNT(*) AS LoanCount
FROM dbo.Financial_Loan_Stagging
GROUP BY member_id
HAVING COUNT(*) > 1;


-- Checking for Zero or Negative Values in Metric Fields
SELECT
    -- fields that should generally be strictly greater than 0
    SUM(CASE WHEN loan_amount <= 0 THEN 1 ELSE 0 END) AS Inv_LoanAmount,
    SUM(CASE WHEN annual_income <= 0 THEN 1 ELSE 0 END) AS Inv_AnnualIncome,
    SUM(CASE WHEN installment <= 0 THEN 1 ELSE 0 END) AS Inv_Installment,
    
    -- total_payment could legitimately be 0 if no payments have been made yet
    SUM(CASE WHEN total_payment <= 0 THEN 1 ELSE 0 END) AS Inv_TotalPayment,
    
    -- Rates and counts that should be greater than 0
    SUM(CASE WHEN int_rate <= 0 THEN 1 ELSE 0 END) AS Inv_InterestRate,
    SUM(CASE WHEN total_acc <= 0 THEN 1 ELSE 0 END) AS Inv_TotalAccounts,
    
    -- DTI 
    SUM(CASE WHEN dti < 0 THEN 1 ELSE 0 END) AS Negative_DTI

FROM dbo.Financial_Loan_Stagging;

-- Checking data type of each column
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Financial_Loan_Stagging'
    AND TABLE_SCHEMA = 'dbo'
ORDER BY ORDINAL_POSITION;


--Creating clean Loan Table(replacing null with "Unknown",and changing datatypes as needed)

SELECT
    id,
    address_state,
    application_type,
    emp_length,

    CAST(COALESCE(emp_title, 'Unknown') AS NVARCHAR(255)) AS emp_title,

    grade,
    home_ownership,
    issue_date,
    last_credit_pull_date,
    last_payment_date,
    loan_status,
    next_payment_date,
    member_id,
    purpose,
    sub_grade,

    LTRIM(RTRIM(term)) AS term,

    verification_status,

    CAST(annual_income AS DECIMAL(18,2)) AS annual_income,
    CAST(dti AS DECIMAL(10,4)) AS dti,
    CAST(installment AS DECIMAL(18,2)) AS installment,
    CAST(int_rate AS DECIMAL(10,4)) AS int_rate,

    loan_amount,
    total_acc,
    total_payment

INTO dbo.Financial_Loan_Clean

FROM dbo.Financial_Loan_Stagging;

--Validating Cleaned table
SELECT *
From dbo.Financial_Loan_Clean;

--Checking Null Value in EMP TITLE
SELECT
    *
FROM dbo.Financial_Loan_Clean
WHERE emp_title IS NULL;

