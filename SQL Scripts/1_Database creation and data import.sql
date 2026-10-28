--Database Creation
IF DB_ID('BankLoanAnalytics') IS NULL
BEGIN
    CREATE DATABASE BankLoanAnalytics;
END
GO


--selecting database
use BankLoanAnalytics
GO

--import Finacial Loan data(using Flat File)

--Overview of Imported Loan Data
Select *
from Financial_Loan_Stagging
