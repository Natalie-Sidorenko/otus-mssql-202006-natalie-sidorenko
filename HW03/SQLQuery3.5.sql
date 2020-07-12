USE WideWorldImporters
GO
SET STATISTICS IO, TIME ON
/****** Version 0  ******/
SELECT
Invoices.InvoiceID,
Invoices.InvoiceDate,
(SELECT People.FullName
FROM Application.People
WHERE People.PersonID = Invoices.SalespersonPersonID
) AS SalesPersonName,
SalesTotals.TotalSumm AS TotalSummByInvoice,
(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
FROM Sales.OrderLines
WHERE OrderLines.OrderId = (SELECT Orders.OrderId
FROM Sales.Orders
WHERE Orders.PickingCompletedWhen IS NOT NULL
AND Orders.OrderId = Invoices.OrderId)
) AS TotalSummForPickedItems
FROM Sales.Invoices
JOIN
(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
FROM Sales.InvoiceLines
GROUP BY InvoiceId
HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

/****** Version 1  ******/
;WITH SalesTotals AS
(
SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
FROM Sales.InvoiceLines
GROUP BY InvoiceId
HAVING SUM(Quantity*UnitPrice) > 27000
)
, PickedItems AS
(
SELECT OrderLines.OrderId,
SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) AS TotalSummForPickedItems
FROM Sales.OrderLines
GROUP BY OrderLines.OrderId
)
SELECT
Invoices.InvoiceID,
Invoices.InvoiceDate,
People.FullName AS SalesPersonName,
SalesTotals.TotalSumm AS TotalSummByInvoice,
PickedItems.TotalSummForPickedItems
FROM Sales.Invoices
JOIN
Application.People
ON People.PersonID = Invoices.SalespersonPersonID
JOIN Sales.Orders
ON Orders.OrderId = Invoices.OrderId
JOIN PickedItems
ON Orders.OrderId = PickedItems.OrderId
JOIN SalesTotals
ON Invoices.InvoiceID = SalesTotals.InvoiceID
WHERE Orders.PickingCompletedWhen IS NOT NULL
ORDER BY TotalSumm DESC