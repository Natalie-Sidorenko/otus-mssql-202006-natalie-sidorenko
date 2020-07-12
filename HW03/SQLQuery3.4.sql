/****** 4. Vyberite goroda (id i nazvanie), v kotorye byli dostavleny tovary, vxodyashchie v trojku samyx dorogix tovarov,
a takzhe imya sotrudnika, kotoryj osushchestvlyal upakovku zakazov (PackedByPersonID).  ******/
USE WideWorldImporters
GO
WITH TopPrice AS 
(
SELECT TOP (3) WITH TIES
       [StockItemID]
      ,[UnitPrice]
  FROM [Warehouse].[StockItems]
  ORDER BY UnitPrice DESC
  )
  SELECT [Application].[People].FullName AS PackedBy,
         [Application].[Cities].CityID,
		 [Application].[Cities].CityName
		 FROM TopPrice JOIN [Sales].[InvoiceLines]
ON [Sales].[InvoiceLines].[StockItemID]=TopPrice.[StockItemID]
 JOIN [Sales].[Invoices]
ON [Sales].[Invoices].InvoiceID=[Sales].[InvoiceLines].InvoiceID
 JOIN [Sales].[Customers]
ON  [Sales].[Customers].CustomerID=[Sales].[Invoices].CustomerID
 JOIN [Application].[People]
ON [Application].[People].PersonID=[Sales].[Invoices].PackedByPersonID
 JOIN [Application].[Cities]
ON [Application].[Cities].CityID=[Sales].[Customers].DeliveryCityID


SELECT [Application].[People].FullName AS PackedBy,
         [Application].[Cities].CityID,
		 [Application].[Cities].CityName
		 FROM [Sales].[InvoiceLines]
 JOIN [Sales].[Invoices]
ON [Sales].[Invoices].InvoiceID=[Sales].[InvoiceLines].InvoiceID
 JOIN [Sales].[Customers]
ON  [Sales].[Customers].CustomerID=[Sales].[Invoices].CustomerID
 JOIN [Application].[People]
ON [Application].[People].PersonID=[Sales].[Invoices].PackedByPersonID
 JOIN [Application].[Cities]
ON [Application].[Cities].CityID=[Sales].[Customers].DeliveryCityID
 JOIN (
SELECT TOP (3) WITH TIES
       [StockItemID]
      ,[UnitPrice]
  FROM [Warehouse].[StockItems]
  ORDER BY UnitPrice DESC
  ) AS TopPrice
ON [Sales].[InvoiceLines].[StockItemID]=TopPrice.[StockItemID]