USE WideWorldImporters;

/****** 1. Trebuetsya napisat' zapros, kotoryj v rezul'tate svoego vypolneniya formiruet tablicu sleduyushchego vida:
Nazvanie klienta
MesyacGod Kolichestvo pokupok
Klientov vzyat' s ID 2-6, e'to vse podrazdelenie Tailspin Toys
imya klienta nuzhno pomenyat' tak chtoby ostalos' tol'ko utochnenie
naprimer isxodnoe Tailspin Toys (Gasport, NY) - vy vyvodite v imeni tol'ko Gasport,NY
data dolzhna imet' format dd.mm.yyyy naprimer 25.12.2019 ******/
SELECT * FROM 
(
 SELECT COUNT(o.[OrderID]) AS Orders
	   ,REPLACE(REPLACE(c.[CustomerName],'Tailspin Toys (',''),')','') AS Company
       ,FORMAT(DATEADD(month,-1,DATEADD(day,1,EOMONTH(o.[OrderDate]))),'d','de-de') AS Mnth
  FROM [Sales].[Orders] o
  JOIN [Sales].[Customers] c
  ON o.[CustomerID]=c.[CustomerID]
  GROUP BY o.[CustomerID] ,REPLACE(REPLACE(c.[CustomerName],'Tailspin Toys (',''),')',''), FORMAT(DATEADD(month,-1,DATEADD(day,1,EOMONTH(o.[OrderDate]))),'d','de-de')
  HAVING o.[CustomerID] BETWEEN 2 AND 6
  ) AS sel
  PIVOT (SUM(Orders)
  FOR Company IN([Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY],[Jessie, ND])) AS piv
  ORDER BY YEAR(Mnth), Mnth;

/****** 2. Dlya vsex klientov s imenem, v kotorom est' Tailspin Toys
vyvesti vse adresa, kotorye est' v tablice, v odnoj kolonke ******/
SELECT [CustomerName], [AddressLine] FROM (
SELECT [CustomerName]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
  FROM [Sales].[Customers]
  WHERE [CustomerName] LIKE '%Tailspin Toys%') AS CustomerAddresses
  UNPIVOT ([AddressLine] FOR [Address] IN ([DeliveryAddressLine1], [DeliveryAddressLine2], [PostalAddressLine1], [PostalAddressLine2])) AS un;

/****** 3. V tablice stran est' polya s kodom strany cifrovym i bukvennym
sdelajte vyborku ID strany, nazvanie, kod - chtoby v pole byl libo cifrovoj libo bukvennyj kod ******/
SELECT [CountryID], [CountryName], [Code]
 FROM (SELECT [CountryID]
      ,[CountryName]
      ,[IsoAlpha3Code]
      ,CAST([IsoNumericCode] AS nvarchar(3)) AS [IsoNumericCode]
  FROM [Application].[Countries]) AS qu
  UNPIVOT ([Code] FOR [Codes] IN ([IsoAlpha3Code],[IsoNumericCode])) AS un;

  /****** 4. Perepishite DZ iz okonnyx funkcij cherez CROSS APPLY
Vyberite po kazhdomu klientu 2 samyx dorogix tovara, kotorye on pokupal
V rezul'tatax dolzhno byt' id klienta, ego nazvanie, id tovara, cena, data pokupki ******/

SELECT cu.[CustomerID], cr.[CustomerName], cr.[StockItemID], cr.[UnitPrice], cr.[OrderDate]
FROM [Sales].[Customers] cu 
CROSS APPLY (SELECT TOP 2 WITH TIES c.[CustomerID]
	                               ,c.[CustomerName]
                                   ,ol.[StockItemID]
	                               ,ol.[UnitPrice]
	                               ,MAX(o.[OrderDate]) AS [OrderDate]
  FROM [Sales].[Orders] o 
  JOIN [Sales].[Customers] c ON c.[CustomerID]=o.[CustomerID]
  JOIN [Sales].[OrderLines] ol ON ol.[OrderID]=o.[OrderID]
  WHERE c.[CustomerID]=cu.[CustomerID]
  GROUP BY c.[CustomerID], c.[CustomerName], ol.[StockItemID], ol.[UnitPrice]
  ORDER BY ol.[UnitPrice] DESC) AS cr
  ORDER BY cu.[CustomerID];