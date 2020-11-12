USE WideWorldImporters;
GO
SET STATISTICS IO, TIME ON;
/*** Version 0 ***/
SELECT ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det
ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv
ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans
ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND (Select SupplierId
FROM Warehouse.StockItems AS It
Where It.StockItemID = det.StockItemID) = 12
AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
FROM Sales.OrderLines AS Total
JOIN Sales.Orders AS ordTotal
ON ordTotal.OrderID = Total.OrderID
WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID;

/*** Version 1 ***/
SELECT ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det
ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv
ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans
ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = det.StockItemID
JOIN Warehouse.StockItems AS It
ON It.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND It.SupplierId = 12
AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
FROM Sales.OrderLines AS Total
JOIN Sales.Orders AS ordTotal
ON ordTotal.OrderID = Total.OrderID
WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID;


/*** Version 2 ***/
DROP TABLE IF EXISTS #TempTable;
CREATE TABLE #TempTable (CustomerID int , SumPrice decimal (18,2));
INSERT INTO #TempTable 
SELECT ordTotal.CustomerID, SUM(Total.UnitPrice*Total.Quantity)
FROM Sales.OrderLines AS Total
JOIN Sales.Orders AS ordTotal
ON ordTotal.OrderID = Total.OrderID
GROUP BY ordTotal.CustomerID
HAVING SUM(Total.UnitPrice*Total.Quantity) > 250000;

SELECT ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det
ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv
ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans
ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = det.StockItemID
JOIN Warehouse.StockItems AS It
ON It.StockItemID = det.StockItemID
JOIN #TempTable a
ON a.CustomerID = Inv.CustomerID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND It.SupplierId = 12
AND Inv.InvoiceDate = ord.OrderDate
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID;


/*** Version 3 ***/
DROP TABLE IF EXISTS #TempTable;
CREATE TABLE #TempTable (CustomerID int , SumPrice decimal (18,2));
INSERT INTO #TempTable 
SELECT ordTotal.CustomerID, SUM(Total.UnitPrice*Total.Quantity)
FROM Sales.OrderLines AS Total
JOIN Sales.Orders AS ordTotal
ON ordTotal.OrderID = Total.OrderID
GROUP BY ordTotal.CustomerID
HAVING SUM(Total.UnitPrice*Total.Quantity) > 250000
ORDER BY ordTotal.CustomerID;

CREATE CLUSTERED INDEX IX_TT_CustID ON #TempTable (CustomerID);

SELECT ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.Invoices AS Inv
ON Inv.OrderID = ord.OrderID
JOIN #TempTable a
ON a.CustomerID = Inv.CustomerID
JOIN Sales.OrderLines AS det
ON det.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans
ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = det.StockItemID
JOIN Warehouse.StockItems AS It
ON It.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND It.SupplierId = 12
AND Inv.InvoiceDate = ord.OrderDate
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID;


/*** Version 4 ***/
DROP TABLE IF EXISTS #TempTable;
CREATE TABLE #TempTable (CustomerID int , SumPrice decimal (18,2));
INSERT INTO #TempTable 
SELECT ordTotal.CustomerID, SUM(Total.UnitPrice*Total.Quantity)
FROM Sales.OrderLines AS Total
JOIN Sales.Orders AS ordTotal
ON ordTotal.OrderID = Total.OrderID
GROUP BY ordTotal.CustomerID
HAVING SUM(Total.UnitPrice*Total.Quantity) > 250000
ORDER BY ordTotal.CustomerID;

CREATE CLUSTERED INDEX IX_TT_CustID ON #TempTable (CustomerID);
CREATE NONCLUSTERED INDEX IX_OrdDate ON Sales.Orders (OrderDate);
CREATE NONCLUSTERED INDEX IX_InvDate ON Sales.Invoices (InvoiceDate);

SELECT ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.Invoices AS Inv
ON Inv.OrderID = ord.OrderID
JOIN #TempTable a
ON a.CustomerID = Inv.CustomerID
JOIN Sales.OrderLines AS det
ON det.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans
ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = det.StockItemID
JOIN Warehouse.StockItems AS It
ON It.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND It.SupplierId = 12
AND Inv.InvoiceDate = ord.OrderDate
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID;