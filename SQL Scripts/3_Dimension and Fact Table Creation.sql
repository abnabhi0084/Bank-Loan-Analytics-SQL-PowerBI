use BankLoanAnalytics;
GO

--CREATING DIMENSION AND FACT TABLES


--Checking total column and there type
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Financial_Loan_Clean'
ORDER BY ORDINAL_POSITION;
GO


--1:-Creating dimension table DIM_LoanPorpose
CREATE TABLE dbo.Dim_LoanPurpose
(
    purpose_key INT IDENTITY(1,1) PRIMARY KEY,
    purpose NVARCHAR(50) NOT NULL UNIQUE
);
GO

INSERT INTO dbo.Dim_LoanPurpose (purpose)
SELECT DISTINCT purpose
FROM dbo.Financial_Loan_Clean
WHERE purpose IS NOT NULL;
GO


--2:-Creating Dimension Grade Table

CREATE TABLE dbo.Dim_CreditGrade
(
    credit_grade_key INT IDENTITY(1,1) PRIMARY KEY,
    grade NVARCHAR(50) NOT NULL,
    sub_grade NVARCHAR(50) NOT NULL,

    CONSTRAINT UQ_Dim_CreditGrade
        UNIQUE (grade, sub_grade)
);
GO

INSERT INTO dbo.Dim_CreditGrade
    (grade, sub_grade)
SELECT DISTINCT
    grade,
    sub_grade
FROM dbo.Financial_Loan_Clean
WHERE grade IS NOT NULL
  AND sub_grade IS NOT NULL;
GO


--3:-Creating Address Dimension Table
CREATE TABLE dbo.Dim_State
(
    state_key INT IDENTITY(1,1) PRIMARY KEY,
    address_state NVARCHAR(50) NOT NULL UNIQUE
);
GO

INSERT INTO dbo.Dim_State (address_state)
SELECT DISTINCT address_state
FROM dbo.Financial_Loan_Clean
WHERE address_state IS NOT NULL;
GO


--Updating Ful State Name to dim_state
ALTER TABLE dbo.Dim_State
ADD state_name NVARCHAR(50);
GO


UPDATE dbo.Dim_State
SET state_name = CASE address_state
    WHEN 'AK' THEN 'Alaska'
    WHEN 'AL' THEN 'Alabama'
    WHEN 'AR' THEN 'Arkansas'
    WHEN 'AZ' THEN 'Arizona'
    WHEN 'CA' THEN 'California'
    WHEN 'CO' THEN 'Colorado'
    WHEN 'CT' THEN 'Connecticut'
    WHEN 'DC' THEN 'District of Columbia'
    WHEN 'DE' THEN 'Delaware'
    WHEN 'FL' THEN 'Florida'
    WHEN 'GA' THEN 'Georgia'
    WHEN 'HI' THEN 'Hawaii'
    WHEN 'IA' THEN 'Iowa'
    WHEN 'ID' THEN 'Idaho'
    WHEN 'IL' THEN 'Illinois'
    WHEN 'IN' THEN 'Indiana'
    WHEN 'KS' THEN 'Kansas'
    WHEN 'KY' THEN 'Kentucky'
    WHEN 'LA' THEN 'Louisiana'
    WHEN 'MA' THEN 'Massachusetts'
    WHEN 'MD' THEN 'Maryland'
    WHEN 'ME' THEN 'Maine'
    WHEN 'MI' THEN 'Michigan'
    WHEN 'MN' THEN 'Minnesota'
    WHEN 'MO' THEN 'Missouri'
    WHEN 'MS' THEN 'Mississippi'
    WHEN 'MT' THEN 'Montana'
    WHEN 'NC' THEN 'North Carolina'
    WHEN 'NE' THEN 'Nebraska'
    WHEN 'NH' THEN 'New Hampshire'
    WHEN 'NJ' THEN 'New Jersey'
    WHEN 'NM' THEN 'New Mexico'
    WHEN 'NV' THEN 'Nevada'
    WHEN 'NY' THEN 'New York'
    WHEN 'OH' THEN 'Ohio'
    WHEN 'OK' THEN 'Oklahoma'
    WHEN 'OR' THEN 'Oregon'
    WHEN 'PA' THEN 'Pennsylvania'
    WHEN 'RI' THEN 'Rhode Island'
    WHEN 'SC' THEN 'South Carolina'
    WHEN 'SD' THEN 'South Dakota'
    WHEN 'TN' THEN 'Tennessee'
    WHEN 'TX' THEN 'Texas'
    WHEN 'UT' THEN 'Utah'
    WHEN 'VA' THEN 'Virginia'
    WHEN 'VT' THEN 'Vermont'
    WHEN 'WA' THEN 'Washington'
    WHEN 'WI' THEN 'Wisconsin'
    WHEN 'WV' THEN 'West Virginia'
    WHEN 'WY' THEN 'Wyoming'
END;
GO

SELECT *
FROM DBO.Dim_State;
GO
/*
One more method to create a dimension tables
SELECT
    ROW_NUMBER() OVER (ORDER BY purpose) AS purpose_key,
    purpose
INTO dbo.Dim_LoanPurpose
FROM (
    SELECT DISTINCT purpose
    FROM dbo.Financial_Loan_Clean
) AS P;
*/



--4:-Creating fact_loan table
SELECT
    L.id AS loan_id,
    L.member_id,
    P.purpose_key,
    G.credit_grade_key,
    S.state_key,
    L.loan_amount,
    L.annual_income,
    L.installment,
    L.int_rate,
    L.dti,
    L.total_acc,
    L.term,
    L.loan_status,
    L.verification_status,
    L.application_type,
    L.emp_length,
    L.emp_title,
    L.home_ownership,
    L.issue_date,
    L.last_payment_date,
    L.next_payment_date,
    L.last_credit_pull_date
INTO dbo.Fact_Loan
FROM dbo.Financial_Loan_Clean AS L
INNER JOIN dbo.Dim_LoanPurpose AS P
    ON L.purpose = P.purpose
INNER JOIN dbo.Dim_CreditGrade AS G
    ON L.grade = G.grade
   AND L.sub_grade = G.sub_grade
INNER JOIN dbo.Dim_State AS S
    ON L.address_state = S.address_state;
GO


--Establishing Relationship between tables
-- Primary key
ALTER TABLE dbo.Fact_Loan
ADD CONSTRAINT PK_Fact_Loan
PRIMARY KEY (loan_id);

-- Foreign keys
ALTER TABLE dbo.Fact_Loan
ADD CONSTRAINT FK_Fact_Loan_Purpose
FOREIGN KEY (purpose_key)
REFERENCES dbo.Dim_LoanPurpose(purpose_key);
GO

ALTER TABLE dbo.Fact_Loan
ADD CONSTRAINT FK_Fact_Loan_CreditGrade
FOREIGN KEY (credit_grade_key)
REFERENCES dbo.Dim_CreditGrade(credit_grade_key);
GO

ALTER TABLE dbo.Fact_Loan
ADD CONSTRAINT FK_Fact_Loan_State
FOREIGN KEY (state_key)
REFERENCES dbo.Dim_State(state_key);


--Creating schema
CREATE SCHEMA analytics;
GO

ALTER SCHEMA analytics TRANSFER dbo.Dim_LoanPurpose;
ALTER SCHEMA analytics TRANSFER dbo.Dim_CreditGrade;
ALTER SCHEMA analytics TRANSFER dbo.Dim_State;
ALTER SCHEMA analytics TRANSFER dbo.Fact_Loan;
GO