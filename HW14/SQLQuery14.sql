-- Включить CLR
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'clr enabled', 1;
EXEC sp_configure 'clr strict security', 0;
GO
RECONFIGURE;
GO

-- Подключить dll 
CREATE ASSEMBLY CLRFunctionAssembly
FROM 'C:\Users\hp\source\repos\SQLServerCLRSortString\SQLServerCLRSortString\bin\Debug\SQLServerCLRSortString.dll'
WITH PERMISSION_SET = SAFE;  
GO

-- Подключить функцию из dll
CREATE FUNCTION dbo.SortString(@name NVARCHAR(255))     
RETURNS NVARCHAR(255)    
AS EXTERNAL NAME [CLRFunctionAssembly].[SQLServerCLRSortString.Class1].SortString
GO 

-- Использование функции
WITH CTE AS (
SELECT [Subregion],  
	   STRING_AGG([CountryName],',') AS Countries
FROM [WideWorldImporters].[Application].[Countries]
GROUP BY [Subregion]
)
SELECT *, dbo.SortString (Countries) AS SortedCountries
FROM CTE;