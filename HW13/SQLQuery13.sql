USE WideWorldImporters;
GO
SET STATISTICS TIME ON;
GO
/****** 1) Napisat' xranimuyu proceduru vozvrashchayushchuyu Klienta s naibol'shej razovoj summoj pokupki.
Napisat' funkciyu vozvrashchayushchuyu Klienta s naibol'shej summoj pokupki. ******/

CREATE PROCEDURE Sales.uspSelectClientWithMaxPurchase AS
SET NOCOUNT ON;
WITH T AS (SELECT C.CustomerName,
                  SUM(L.Quantity*L.UnitPrice) AS Purchase
FROM Sales.InvoiceLines L JOIN Sales.Invoices I
ON L.InvoiceID=I.InvoiceID
JOIN Sales.Customers C
ON C.CustomerID=I.CustomerID
GROUP BY L.InvoiceID, C.CustomerName
)
SELECT CustomerName
FROM T
WHERE Purchase = (SELECT MAX(Purchase) FROM T)
RETURN;
GO

EXEC Sales.uspSelectClientWithMaxPurchase;
GO 

CREATE FUNCTION Sales.udfClientWithMaxPurchase ()
RETURNS TABLE AS
RETURN(
WITH T AS (SELECT C.CustomerName,
                  SUM(L.Quantity*L.UnitPrice) AS Purchase
FROM Sales.InvoiceLines L JOIN Sales.Invoices I
ON L.InvoiceID=I.InvoiceID
JOIN Sales.Customers C
ON C.CustomerID=I.CustomerID
GROUP BY L.InvoiceID, C.CustomerName
)
SELECT CustomerName
FROM T
WHERE Purchase = (SELECT MAX(Purchase) FROM T)
);
GO

SELECT * FROM Sales.udfClientWithMaxPurchase ();
GO

/****** 2) Napisat' xranimuyu proceduru s vxodyashchim parametrom CustomerID, vyvodyashchuyu summu pokupki po e'tomu klientu. ******/

CREATE PROCEDURE Sales.uspSelectSumPurchaseForClient @CustomerID int
AS
SET NOCOUNT ON;
WITH T AS (SELECT I.CustomerID,
       SUM(L.Quantity*L.UnitPrice) AS Purchase
FROM Sales.InvoiceLines L JOIN Sales.Invoices I
ON L.InvoiceID=I.InvoiceID
GROUP BY L.InvoiceID, I.CustomerID)
SELECT SUM(Purchase) AS SumPurchase
FROM T
GROUP BY CustomerID
HAVING CustomerID=@CustomerID
RETURN;
GO

EXEC Sales.uspSelectSumPurchaseForClient @CustomerID=403;
GO

/****** 3) Sozdat' odinakovuyu funkciyu i xranimuyu proceduru, posmotret' v chem raznica v proizvoditel'nosti i pochemu. ******/

CREATE FUNCTION Sales.udfSelectSumPurchaseForClient (@CustomerID int) --function, identical to procedure from 2)
RETURNS TABLE AS
RETURN(
WITH T AS (SELECT I.CustomerID,
       SUM(L.Quantity*L.UnitPrice) AS Purchase
FROM Sales.InvoiceLines L JOIN Sales.Invoices I
ON L.InvoiceID=I.InvoiceID
GROUP BY L.InvoiceID, I.CustomerID)
SELECT SUM(Purchase) AS SumPurchase
FROM T
GROUP BY CustomerID
HAVING CustomerID=@CustomerID
);
GO

SELECT * FROM Sales.udfSelectSumPurchaseForClient (403);

/****** 4) Sozdajte tablichnuyu funkciyu pokazhite kak ee mozhno vyzvat' dlya kazhdoj stroki result set'a bez ispol'zovaniya cikla.  ******/