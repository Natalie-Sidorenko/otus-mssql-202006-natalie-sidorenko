USE WideWorldImporters;
GO
/****** 1. Napishite zapros s vremennoj tablicej i perepishite ego s tablichnoj peremennoj. Sravnite plany.
V kachestve zaprosa s vremennoj tablicej i tablichnoj peremennoj mozhno vzyat' svoj zapros ili sleduyushchij zapros:
Sdelat' raschet summy prodazh narastayushchim itogom po mesyacam s 2015 goda (v ramkax odnogo mesyaca on budet odinakovyj, 
narastat' budet v techenie vremeni vyborki)
Vyvedite id prodazhi, nazvanie klienta, datu prodazhi, summu prodazhi, summu narastayushchim itogom
Prodazhi mozhno vzyat' iz tablicy Invoices.
Narastayushchij itog dolzhen byt' bez okonnoj funkcii. ******/
CREATE TABLE #temptable 
([InvoiceID] int PRIMARY KEY CLUSTERED, 
 [CustomerName] nvarchar(100), 
 [InvoiceDate] date, 
 SalesSum decimal(18,2),
 IncreasingMonthlySalesSum decimal(18,2));

INSERT INTO #temptable
([InvoiceID], [CustomerName], [InvoiceDate], SalesSum, IncreasingMonthlySalesSum)
SELECT I.[InvoiceID]
      ,C.[CustomerName]
      ,I.[InvoiceDate]
	  ,SUM(IL.[Quantity]*IL.[UnitPrice])
	  ,(SELECT SUM (InvLin.[Quantity]*InvLin.[UnitPrice]) 
	  FROM [Sales].[Invoices] Inv JOIN [Sales].[InvoiceLines] InvLin
	  ON Inv.[InvoiceID]=InvLin.[InvoiceID]
	  WHERE Inv.[InvoiceDate] BETWEEN '01-01-2015'
	  AND EOMONTH (I.[InvoiceDate]))
  FROM [Sales].[Invoices] I
  JOIN [Sales].[Customers] C ON C.[CustomerID]=I.[CustomerID]
  JOIN [Sales].[InvoiceLines] IL ON I.[InvoiceID]=IL.[InvoiceID]
  WHERE I.[InvoiceDate]>='01-01-2015'
  GROUP BY I.[InvoiceID],C.[CustomerName],I.[InvoiceDate]
  ORDER BY I.[InvoiceDate];

DECLARE @tablevar TABLE
([InvoiceID] int PRIMARY KEY CLUSTERED, 
 [CustomerName] nvarchar(100), 
 [InvoiceDate] date, 
 SalesSum decimal(18,2),
 IncreasingMonthlySalesSum decimal(18,2));

INSERT INTO @tablevar
([InvoiceID], [CustomerName], [InvoiceDate], SalesSum, IncreasingMonthlySalesSum)
SELECT I.[InvoiceID]
      ,C.[CustomerName]
      ,I.[InvoiceDate]
	  ,SUM(IL.[Quantity]*IL.[UnitPrice])
	  ,(SELECT SUM (InvLin.[Quantity]*InvLin.[UnitPrice]) 
	  FROM [Sales].[Invoices] Inv JOIN [Sales].[InvoiceLines] InvLin
	  ON Inv.[InvoiceID]=InvLin.[InvoiceID]
	  WHERE Inv.[InvoiceDate] BETWEEN '01-01-2015'
	  AND EOMONTH (I.[InvoiceDate]))
  FROM [Sales].[Invoices] I
  JOIN [Sales].[Customers] C ON C.[CustomerID]=I.[CustomerID]
  JOIN [Sales].[InvoiceLines] IL ON I.[InvoiceID]=IL.[InvoiceID]
  WHERE I.[InvoiceDate]>='01-01-2015'
  GROUP BY I.[InvoiceID],C.[CustomerName],I.[InvoiceDate]
  ORDER BY I.[InvoiceDate];

  /****** TEMPTABLE AND TABLE VARIABLE PLANS ARE IDENTICAL. ******/

  /****** 2. Esli vy brali predlozhennyj vyshe zapros, to sdelajte raschet summy narastayushchim itogom s pomoshch'yu okonnoj funkcii.
Sravnite 2 varianta zaprosa - cherez windows function i bez nix. Napisat' kakoj bystree vypolnyaetsya, sravnit' po set statistics time on; ******/
set statistics time on;
--WITHOUT WINDOWED FUNCTION
SELECT I.[InvoiceID]
      ,C.[CustomerName]
      ,I.[InvoiceDate]
	  ,SUM(IL.[Quantity]*IL.[UnitPrice]) AS SalesSum
	  ,(SELECT SUM (InvLin.[Quantity]*InvLin.[UnitPrice]) 
	  FROM [Sales].[Invoices] Inv JOIN [Sales].[InvoiceLines] InvLin
	  ON Inv.[InvoiceID]=InvLin.[InvoiceID]
	  WHERE Inv.[InvoiceDate] BETWEEN '01-01-2015'
	  AND EOMONTH (I.[InvoiceDate])) AS IncreasingMonthlySalesSum
  FROM [Sales].[Invoices] I
  JOIN [Sales].[Customers] C ON C.[CustomerID]=I.[CustomerID]
  JOIN [Sales].[InvoiceLines] IL ON I.[InvoiceID]=IL.[InvoiceID]
  WHERE I.[InvoiceDate]>='01-01-2015'
  GROUP BY I.[InvoiceID],C.[CustomerName],I.[InvoiceDate]
  ORDER BY I.[InvoiceDate];
/******   SQL Server parse and compile time: 
   CPU time = 172 ms, elapsed time = 604 ms.
          SQL Server Execution Times:
   CPU time = 79266 ms,  elapsed time = 83336 ms.******/

  --WITH WINDOWED FUNCTION
  SELECT I.[InvoiceID]
      ,C.[CustomerName]
      ,I.[InvoiceDate]
	  ,SUM(IL.[Quantity]*IL.[UnitPrice]) AS SalesSum
	  ,SUM(SUM(IL.[Quantity]*IL.[UnitPrice])) OVER(ORDER BY YEAR(I.[InvoiceDate]),MONTH(I.[InvoiceDate])) AS IncreasingMonthlySalesSum
  FROM [Sales].[Invoices] I
  JOIN [Sales].[Customers] C ON C.[CustomerID]=I.[CustomerID]
  JOIN [Sales].[InvoiceLines] IL ON I.[InvoiceID]=IL.[InvoiceID]
  WHERE I.[InvoiceDate]>='01-01-2015'
  GROUP BY I.[InvoiceID], C.[CustomerName], I.[InvoiceDate]
  ORDER BY I.[InvoiceDate];
  /******   SQL Server parse and compile time: 
   CPU time = 140 ms, elapsed time = 495 ms.
            SQL Server Execution Times:
   CPU time = 438 ms,  elapsed time = 4246 ms.******/
  /****** CPU TIME WITH WINDOWED FUNCTION IS 181 TIMES LESS, ELAPSED TIME - 20 TIMES LESS. ******/
  set statistics time off;

  /****** 3. Vyvesti spisok 2x samyx populyarnyx produktov (po kol-vu prodannyx) v kazhdom mesyace za 2016j god 
  (po 2 samyx populyarnyx produkta v kazhdom mesyace) ******/
 
 --WITH WINDOWED FUNCTION
 WITH CTE AS (
  SELECT MONTH(I.[InvoiceDate]) AS Mnth, SI.[StockItemName], SUM(IL.[Quantity]) AS Quantity,
  ROW_NUMBER () OVER (PARTITION BY MONTH(I.[InvoiceDate]) ORDER BY SUM(IL.[Quantity]) DESC) AS Rnk
  FROM [Sales].[Invoices] I
  JOIN [Sales].[InvoiceLines] IL ON I.[InvoiceID]=IL.[InvoiceID]
  JOIN [Warehouse].[StockItems] SI ON IL.[StockItemID]=SI.[StockItemID]
  WHERE YEAR(I.[InvoiceDate])=2016
  GROUP BY MONTH(I.[InvoiceDate]), SI.[StockItemName]
  )
  SELECT * FROM CTE
  WHERE CTE.Rnk < 3
  ORDER BY CTE.Mnth;
  /****** SQL Server parse and compile time: 
   CPU time = 91 ms, elapsed time = 91 ms.
        SQL Server Execution Times:
   CPU time = 280 ms,  elapsed time = 16445 ms. ******/
 
 --WITHOUT WINDOWED FUNCTION
SELECT MONTH(Inv.[InvoiceDate]) AS Mnth, CR.[StockItemName], CR.Quantity
FROM [Sales].[Invoices] Inv
CROSS APPLY (SELECT TOP 2 MONTH(I.[InvoiceDate]) AS Mnth, SI.[StockItemName], SUM(IL.[Quantity]) AS Quantity
  FROM [Sales].[Invoices] I
  JOIN [Sales].[InvoiceLines] IL ON I.[InvoiceID]=IL.[InvoiceID]
  JOIN [Warehouse].[StockItems] SI ON IL.[StockItemID]=SI.[StockItemID]
  WHERE YEAR(I.[InvoiceDate])=2016 AND MONTH(I.[InvoiceDate])=MONTH(Inv.[InvoiceDate])
  GROUP BY MONTH(I.[InvoiceDate]), SI.[StockItemName]
  ORDER BY Quantity DESC) AS CR
WHERE YEAR(Inv.[InvoiceDate])=2016
ORDER BY Mnth;
/****** SQL Server parse and compile time: 
   CPU time = 125 ms, elapsed time = 130 ms.
        SQL Server Execution Times:
   CPU time = 22063 ms,  elapsed time = 24999 ms
        
		Without 'DISTINCT':
        SQL Server parse and compile time: 
   CPU time = 78 ms, elapsed time = 85 ms.
        SQL Server Execution Times:
   CPU time = 41828 ms,  elapsed time = 14049 ms.******/

/****** 4. Poschitajte po tablice tovarov, v vyvod takzhe dolzhen popast' id tovara, nazvanie, bre'nd i cena
pronumerujte zapisi po nazvaniyu tovara, tak chtoby pri izmenenii bukvy alfavita numeraciya nachinalas' zanovo
poschitajte obshchee kolichestvo tovarov i vyvedete polem v e'tom zhe zaprose
poschitajte obshchee kolichestvo tovarov v zavisimosti ot pervoj bukvy nazvaniya tovara
otobrazite sleduyushchij id tovara isxodya iz togo, chto poryadok otobrazheniya tovarov po imeni
predydushchij id tovara s tem zhe poryadkom otobrazheniya (po imeni)
nazvaniya tovara 2 stroki nazad, v sluchae esli predydushchej stroki net nuzhno vyvesti "No items"
sformirujte 30 grupp tovarov po polyu ves tovara na 1 sht ******/

SELECT i.[StockItemID]
      ,i.[StockItemName]
	  ,ROW_NUMBER() OVER (PARTITION BY LEFT(i.[StockItemName],1) ORDER BY i.[StockItemName]) AS RowNumberPerLetter
	  ,COUNT(i.[StockItemID]) OVER() AS TotalItems
	  ,COUNT(i.[StockItemID]) OVER(PARTITION BY LEFT(i.[StockItemName],1)) AS ItemsPerLetter
	  ,LAG (i.[StockItemID]) OVER (ORDER BY i.[StockItemName]) AS Previous
	  ,LEAD (i.[StockItemID]) OVER (ORDER BY i.[StockItemName]) AS Nxt
	  ,COALESCE(LAG (i.[StockItemName],2) OVER (ORDER BY i.[StockItemName]),'No items') AS TwoRowsEarlier
	  --,[TypicalWeightPerUnit]
	  ,NTILE(30) OVER (PARTITION BY [TypicalWeightPerUnit] ORDER BY i.[StockItemName]) AS GroupNumber
      ,s.[SupplierName]
      ,i.[UnitPrice]
  FROM [Warehouse].[StockItems] i
  JOIN [Purchasing].[Suppliers] s
  ON i.[SupplierID]=s.[SupplierID];

  /****** 5. Po kazhdomu sotrudniku vyvedite poslednego klienta, kotoromu sotrudnik chto-to prodal
V rezul'tatax dolzhny byt' id i familiya sotrudnika, id i nazvanie klienta, data prodazhi, summu sdelki ******/
 
 --WITH WINDOWED FUNCTION
WITH CTE AS
(
SELECT p.[PersonID]
      ,p.[FullName]
	  ,c.[CustomerID]
	  ,c.[CustomerName]
      ,o.[OrderDate]
	  ,SUM (ol.[Quantity]*ol.[UnitPrice]) AS OrderSum
	  ,RANK() OVER (PARTITION BY p.[PersonID] ORDER BY o.[OrderDate] DESC) AS Rnk
  FROM [Application].[People] p
  LEFT JOIN [Sales].[Orders] o ON p.[PersonID]=o.[SalespersonPersonID]
  LEFT JOIN [Sales].[Customers] c ON c.[CustomerID]=o.[CustomerID]
  LEFT JOIN [Sales].[OrderLines] ol ON ol.[OrderID]=o.[OrderID]
  WHERE p.[IsEmployee]=1
  GROUP BY p.[PersonID], p.[FullName], c.[CustomerID], c.[CustomerName], o.[OrderID], o.[OrderDate]
  )
  SELECT CTE.[PersonID], CTE.[FullName], CTE.[CustomerID], CTE.[CustomerName], CTE.[OrderDate], CTE.[OrderSum]
	 FROM CTE WHERE CTE.Rnk=1;
/****** SQL Server parse and compile time: 
   CPU time = 31 ms, elapsed time = 287 ms.
        SQL Server Execution Times:
   CPU time = 313 ms,  elapsed time = 671 ms. ******/

 --WITHOUT WINDOWED FUNCTION
SELECT pe.[PersonID], pe.[FullName], cr.[CustomerID], cr.[CustomerName], cr.[OrderDate], cr.[OrderSum]
FROM [Application].[People] pe
OUTER APPLY (SELECT TOP 1 WITH TIES o.[SalespersonPersonID]
	        ,c.[CustomerID]
	        ,c.[CustomerName]
            ,o.[OrderDate]
	        ,SUM (ol.[Quantity]*ol.[UnitPrice]) AS OrderSum
	        FROM [Sales].[Orders] o
            JOIN [Sales].[Customers] c ON c.[CustomerID]=o.[CustomerID]
            JOIN [Sales].[OrderLines] ol ON ol.[OrderID]=o.[OrderID]
            WHERE pe.[PersonID]=o.[SalespersonPersonID]
            GROUP BY o.[SalespersonPersonID], c.[CustomerID], c.[CustomerName], o.[OrderID], o.[OrderDate]
			ORDER BY o.[OrderDate] DESC) AS cr
WHERE pe.[IsEmployee]=1
/****** SQL Server parse and compile time: 
   CPU time = 141 ms, elapsed time = 289 ms.
        SQL Server Execution Times:
   CPU time = 3422 ms,  elapsed time = 4323 ms. ******/

   /****** 6. Vyberite po kazhdomu klientu 2 samyx dorogix tovara, kotorye on pokupal
V rezul'tatax dolzhno byt' id klienta, ego nazvanie, id tovara, cena, data pokupki ******/

 -- ONLY WITH WINDOWED FUNCTION
WITH CTE AS
(
SELECT c.[CustomerID]
	  ,c.[CustomerName]
      ,ol.[StockItemID]
	  ,ol.[UnitPrice]
	  ,o.[OrderDate]
	  ,DENSE_RANK () OVER (PARTITION BY c.[CustomerID] ORDER BY ol.[UnitPrice] DESC) AS Rnk
  FROM [Sales].[Orders] o 
  JOIN [Sales].[Customers] c ON c.[CustomerID]=o.[CustomerID]
  JOIN [Sales].[OrderLines] ol ON ol.[OrderID]=o.[OrderID]
  )
SELECT * FROM CTE WHERE CTE.Rnk<3
ORDER BY CTE.[CustomerID];