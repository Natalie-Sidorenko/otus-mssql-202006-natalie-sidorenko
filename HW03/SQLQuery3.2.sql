/****** 2. Vyberite tovary s minimal'noj cenoj (podzaprosom). Sdelajte dva varianta podzaprosa.
Vyvesti: ID tovara, naimenovanie tovara, cena.  ******/
USE WideWorldImporters
GO
SELECT [StockItemID]
      ,[StockItemName]
      ,[UnitPrice]
  FROM [Warehouse].[StockItems]
  WHERE [UnitPrice]=
  (SELECT MIN([UnitPrice]) FROM [Warehouse].[StockItems]);
  
SELECT [StockItemID]
      ,[StockItemName]
      ,[UnitPrice]
  FROM [Warehouse].[StockItems] a
  WHERE NOT EXISTS 
  (SELECT [UnitPrice]
  FROM [Warehouse].[StockItems] b 
  WHERE b.[UnitPrice]<a.[UnitPrice]);
