/****** 1. Poschitat' srednyuyu cenu tovara, obshchuyu summu prodazhi po mesyacam ******/
SELECT  YEAR (I.[InvoiceDate]) AS InvoiceYear
	  , MONTH (I.[InvoiceDate]) AS InvoiceMonth
	  , AVG (Il.[UnitPrice]) AS AveragePrice
	  , SUM (Il.[Quantity]*Il.[UnitPrice]) AS TotalSum
  FROM [WideWorldImporters].[Sales].[Invoices] I
  JOIN [WideWorldImporters].[Sales].[InvoiceLines] Il
  ON I.[InvoiceID]=Il.[InvoiceID]
  GROUP BY MONTH (I.[InvoiceDate]), YEAR (I.[InvoiceDate])
  ORDER BY YEAR (I.[InvoiceDate]), MONTH (I.[InvoiceDate])

/****** 2. Otobrazit' vse mesyacy, gde obshchaya summa prodazh prevysila 10 000 ******/
SELECT  YEAR (I.[InvoiceDate]) AS InvoiceYear
	  , MONTH (I.[InvoiceDate]) AS InvoiceMonth
	  , SUM (Il.[Quantity]*Il.[UnitPrice]) AS TotalSum
  FROM [WideWorldImporters].[Sales].[Invoices] I
  JOIN [WideWorldImporters].[Sales].[InvoiceLines] Il
  ON I.[InvoiceID]=Il.[InvoiceID]
  GROUP BY MONTH (I.[InvoiceDate]), YEAR (I.[InvoiceDate])
  HAVING SUM (Il.[Quantity]*Il.[UnitPrice])>10000
  ORDER BY YEAR (I.[InvoiceDate]), MONTH (I.[InvoiceDate])

/****** 3. Vyvesti summu prodazh, datu pervoj prodazhi i kolichestvo prodannogo po mesyacam, po tovaram, prodazhi kotoryx menee 50 ed v mesyac. ******/
SELECT  YEAR (I.[InvoiceDate]) AS InvoiceYear
	  , MONTH (I.[InvoiceDate]) AS InvoiceMonth
	  , Il.[Description]
	  , SUM (Il.[Quantity]*Il.[UnitPrice]) AS TotalSum
	  , MIN (I.[InvoiceDate]) AS FirstSalesDate
	  , SUM (Il.[Quantity]) AS StockItemQuantity
  FROM [WideWorldImporters].[Sales].[Invoices] I
  JOIN [WideWorldImporters].[Sales].[InvoiceLines] Il
  ON I.[InvoiceID]=Il.[InvoiceID]
  GROUP BY MONTH (I.[InvoiceDate]), YEAR (I.[InvoiceDate]), Il.[Description]
  HAVING SUM (Il.[Quantity])<50
  ORDER BY YEAR (I.[InvoiceDate]), MONTH (I.[InvoiceDate])

/****** 4. Написать рекурсивный CTE sql запрос и заполнить им временную таблицу и табличную переменную ******/
CREATE TABLE dbo.MyEmployees
(
EmployeeID smallint NOT NULL,
FirstName nvarchar(30) NOT NULL,
LastName nvarchar(40) NOT NULL,
Title nvarchar(50) NOT NULL,
DeptID smallint NOT NULL,
ManagerID int NULL,
CONSTRAINT PK_EmployeeID PRIMARY KEY CLUSTERED (EmployeeID ASC)
);

INSERT INTO dbo.MyEmployees VALUES
(1, N'Ken', N'Sánchez', N'Chief Executive Officer',16,NULL)
,(273, N'Brian', N'Welcker', N'Vice President of Sales',3,1)
,(274, N'Stephen', N'Jiang', N'North American Sales Manager',3,273)
,(275, N'Michael', N'Blythe', N'Sales Representative',3,274)
,(276, N'Linda', N'Mitchell', N'Sales Representative',3,274)
,(285, N'Syed', N'Abbas', N'Pacific Sales Manager',3,273)
,(286, N'Lynn', N'Tsoflias', N'Sales Representative',3,285)
,(16, N'David',N'Bradley', N'Marketing Manager', 4, 273)
,(23, N'Mary', N'Gibson', N'Marketing Specialist', 4, 16); 

CREATE TABLE #temptable 
(EmployeeID smallint PRIMARY KEY CLUSTERED, 
[Name] nvarchar(50), 
Title nvarchar(50), 
EmployeeLevel smallint);

WITH CTE AS (
SELECT EmployeeID, CAST (FirstName+' '+LastName AS nvarchar(50)) AS [Name], Title, 1 AS EmployeeLevel
FROM dbo.MyEmployees
WHERE ManagerID IS NULL
UNION ALL
SELECT e.EmployeeID, CAST (REPLICATE('|',ecte.EmployeeLevel)+e.FirstName+' '+e.LastName AS nvarchar(50)), e.Title, ecte.EmployeeLevel+1
FROM dbo.MyEmployees e
INNER JOIN CTE ecte ON ecte.EmployeeID = e.ManagerID
)
INSERT INTO #temptable
(EmployeeID, [Name], Title, EmployeeLevel) SELECT *
FROM CTE;

DECLARE @tablevar TABLE
(EmployeeID smallint PRIMARY KEY CLUSTERED, 
[Name] nvarchar(50), 
Title nvarchar(50), 
EmployeeLevel smallint);

WITH CTE AS (
SELECT EmployeeID, CAST (FirstName+' '+LastName AS nvarchar(50)) AS [Name], Title, 1 AS EmployeeLevel
FROM dbo.MyEmployees
WHERE ManagerID IS NULL
UNION ALL
SELECT e.EmployeeID, CAST (REPLICATE('|',ecte.EmployeeLevel)+e.FirstName+' '+e.LastName AS nvarchar(50)), e.Title, ecte.EmployeeLevel+1
FROM dbo.MyEmployees e
INNER JOIN CTE ecte ON ecte.EmployeeID = e.ManagerID
)
INSERT INTO @tablevar
(EmployeeID, [Name], Title, EmployeeLevel) SELECT *
FROM CTE;