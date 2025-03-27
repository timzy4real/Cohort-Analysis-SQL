--TOPIC: COHORT RETENTION ANALYSIS (EXPLORING DATA)

--Cleaning Data

--Total Records = 541909
--135080 Records have no CustomerID (we don't want those in our Dataset).
--406829 Records have CustomerID

WITH online_retail AS
(
SELECT  [InvoiceNo]
	   ,[StockCode]
	   ,[Description]
	   ,[Quantity]
	   ,[InvoiceDate]
	   ,[UnitPrice]
	   ,[CustomerID]
	   ,[Country]
FROM [Portfolio].[dbo].[online_retail]
WHERE CustomerID > 0
),
quantity_unit_price AS
(
--397884 Records with Quantity and Unit Price (Reduced Data)
	SELECT *
	FROM online_retail
	WHERE Quantity > 0 AND UnitPrice > 0
),
dup_check AS
(
		--check for duplicate
		SELECT *, ROW_NUMBER() OVER(PARTITION BY InvoiceNo, StockCode, Quantity ORDER BY InvoiceDate) dup_flag
		FROM quantity_unit_price
)
--392669 Clean Data
--5215 Duplicate Records
SELECT *
INTO #online_retail_main
FROM dup_check
WHERE dup_flag = 1;

--CLEAN DATA
--BEGIN COHORT ANALYSIS
SELECT *
FROM #online_retail_main

--Data required for COHORT ANALYSIS are:
	--Unique Identifier (CustomerID)
	--Initial Start Date (First invoice Date)
	--Revenue Data

	--When was the last time a certain customer made a purchase, we will create a COHORT GROUP for that
SELECT CustomerID,
	   MIN(InvoiceDate) First_Purchase_Date,
	   DATEFROMPARTS(YEAR(MIN(InvoiceDate)), MONTH(MIN(InvoiceDate)),1) Cohort_Date
INTO #Cohort
FROM #online_retail_main
GROUP BY CustomerID;

--Create COHORT INDEX
--Is an integer representation of the number of Months that has passed since the customer first purchase
SELECT m.*,
	   c.Cohort_Date, 
	YEAR(m.InvoiceDate) Invoice_Year,
	MONTH(m.InvoiceDate) Invoice_Month,
	YEAR(c.Cohort_Date) Cohort_Year,
	MONTH(c.Cohort_Date) Cohort_Date
FROM #online_retail_main m
LEFT JOIN #Cohort c
	ON m.CustomerID = c.CustomerID

--Next is to get the Year and Month Diff to get us to the formular where we can create a Cohort Index
--We'll create a Sub-Query
SELECT mmm.*,
	Cohort_Index = Year_Diff * 12 + Month_Diff + 1 --The Cohort Index 1... means a customer purchased it's second purchase in the same month after it's first
INTO #Cohort_Retention
FROM
	(	
			SELECT mm.*,
				Year_Diff = Invoice_Year - Cohort_Year,
				Month_Diff = Invoice_Month - Cohort_Month
			FROM
				(
					SELECT m.*,
						   c.Cohort_Date, 
						YEAR(m.InvoiceDate) Invoice_Year,
						MONTH(m.InvoiceDate) Invoice_Month,
						YEAR(c.Cohort_Date) Cohort_Year,
						MONTH(c.Cohort_Date) Cohort_Month
					FROM #online_retail_main m
					LEFT JOIN #Cohort c
						ON m.CustomerID = c.CustomerID
				) mm
	)mmm;
--WHERE CustomerID = 14733

--we save this data for Tableau
SELECT *
FROM #Cohort_Retention; 

--we are about to pivot this data and selecthow many customers returned in a given Cohort month
SELECT DISTINCT
	   CustomerID,
	   Cohort_Date,
	   Cohort_Index
FROM #Cohort_Retention 






