/****** 1. Vyberite sotrudnikov (Application.People), kotorye yavlyayutsya prodazhnikami (IsSalesPerson), 
i ne sdelali ni odnoj prodazhi 04 iyulya 2015 goda. 
Vyvesti ID sotrudnika i ego polnoe imya. Prodazhi smotret' v tablice Sales.Invoices. ******/
USE WideWorldImporters
GO
SELECT [PersonID], [FullName]
  FROM [Application].[People] Pe 
  WHERE Pe.[IsSalesperson]=1
  AND NOT EXISTS 
 (SELECT Inv.[SalespersonPersonID] 
  FROM [Sales].[Invoices] Inv 
  WHERE Inv.[SalespersonPersonID]=Pe.[PersonID]
  AND Inv.[InvoiceDate]='2015-07-04');