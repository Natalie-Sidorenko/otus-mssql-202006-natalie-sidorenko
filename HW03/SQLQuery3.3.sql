/****** 3. Vyberite informaciyu po klientam, kotorye pereveli kompanii pyat' maksimal'nyx platezhej iz Sales.CustomerTransactions.
Predstav'te neskol'ko sposobov (v tom chisle s CTE).   ******/
USE WideWorldImporters
GO
WITH T AS 
(
SELECT TOP (5) [CustomerID]
      ,[TransactionAmount]
  FROM [Sales].[CustomerTransactions]
  WHERE [TransactionTypeID]=3
  ORDER BY [TransactionAmount]
  )
SELECT Cu.[CustomerID]
      ,[CustomerName]
  FROM [Sales].[Customers] Cu 
  JOIN T 
  ON Cu.[CustomerID]=T.[CustomerID];

SELECT Cu.[CustomerID]
      ,[CustomerName]
  FROM [Sales].[Customers] Cu 
  JOIN 
  (SELECT TOP (5) [CustomerID]
      ,[TransactionAmount]
  FROM [Sales].[CustomerTransactions]
  WHERE [TransactionTypeID]=3
  ORDER BY [TransactionAmount]) AS T 
  ON Cu.[CustomerID]=T.[CustomerID];

SELECT [CustomerID]
      ,[CustomerName]
  FROM [Sales].[Customers] 
  WHERE [Sales].[Customers].[CustomerID] IN 
  (SELECT TOP (5) [CustomerID]
  FROM [Sales].[CustomerTransactions]
  WHERE [TransactionTypeID]=3
  ORDER BY [TransactionAmount])