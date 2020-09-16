USE WideWorldImporters
GO
/****** 1. Zagruzit' dannye iz fajla StockItems.xml v tablicu Warehouse.StockItems.
Sushchestvuyushchie zapisi v tablice obnovit', otsutstvuyushchie dobavit' (sopostavlyat' zapisi po polyu StockItemName). ******/

CREATE TABLE #StockItemsAddition(
	[StockItemName] nvarchar(100),
	[SupplierID] int,
	[UnitPackageID] int,
	[OuterPackageID] int,
	[LeadTimeDays] int,
	[QuantityPerOuter] int,
	[IsChillerStock] bit,
	[TaxRate] decimal(18,3),
	[UnitPrice] decimal (18,2),
	[TypicalWeightPerUnit] decimal(18,3))

DECLARE @docHandle int
DECLARE @xmlDocument  xml
SET @xmlDocument = ( 
 SELECT * FROM OPENROWSET
  (BULK 'C:\Users\hp\Strix\SQL&UML\OTUS\12. 12.09.2019 - 10.08.2020\StockItems-188-f89807.xml',
   SINGLE_BLOB)
   as s)
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
INSERT INTO #StockItemsAddition
SELECT *
FROM OPENXML(@docHandle, 'StockItems/Item', 3)
WITH ( 
	[StockItemName] nvarchar(100) '@Name',
	[SupplierID] int 'SupplierID',
	[UnitPackageID] int 'Package/UnitPackageID',
	[OuterPackageID] int 'Package/OuterPackageID',
	[LeadTimeDays] int 'LeadTimeDays',
	[QuantityPerOuter] int 'Package/QuantityPerOuter',
	[IsChillerStock] bit 'IsChillerStock',
	[TaxRate] decimal(18,3) 'TaxRate',
	[UnitPrice] decimal (18,2) 'UnitPrice',
	[TypicalWeightPerUnit] decimal(18,3) 'Package/TypicalWeightPerUnit')

EXEC sp_xml_removedocument @docHandle

SELECT * FROM #StockItemsAddition;
SELECT * FROM [Warehouse].[StockItems];

MERGE [Warehouse].[StockItems] AS target
USING #StockItemsAddition AS source
ON (target.[StockItemName]=source.[StockItemName] COLLATE Latin1_General_100_CI_AS)
WHEN MATCHED 
THEN UPDATE SET [SupplierID]=source.[SupplierID],
                [UnitPackageID]=source.[UnitPackageID],
				[OuterPackageID]=source.[OuterPackageID],
				[LeadTimeDays]=source.[LeadTimeDays],
				[QuantityPerOuter]=source.[QuantityPerOuter],
				[IsChillerStock]=source.[IsChillerStock],
				[TaxRate]=source.[TaxRate],
				[UnitPrice]=source.[UnitPrice],
				[TypicalWeightPerUnit]=source.[TypicalWeightPerUnit]
WHEN NOT MATCHED 
THEN INSERT ([SupplierID],
	         [UnitPackageID],
	         [OuterPackageID],
	         [LeadTimeDays],
	         [QuantityPerOuter],
	         [IsChillerStock],
	         [TaxRate],
	         [UnitPrice],
	         [TypicalWeightPerUnit])
VALUES (source.[SupplierID],
        source.[UnitPackageID],
	    source.[OuterPackageID],
		source.[LeadTimeDays],
		source.[QuantityPerOuter],
		source.[IsChillerStock],
		source.[TaxRate],
		source.[UnitPrice],
		source.[TypicalWeightPerUnit]);

--ERROR: Cannot insert the value NULL into column 'StockItemName', table 'WideWorldImporters.Warehouse.StockItems'; column does not allow nulls. UPDATE fails.

/****** 2. Vygruzit' dannye iz tablicy StockItems v takoj zhe xml-fajl, kak StockItems.xml ******/

CREATE TABLE [WideWorldImporters].[Warehouse].StockItemsXML (StockItemsX XML);
DECLARE @xml XML
SET @xml =
(SELECT StockItemName as [@Name], 
	   SupplierID AS [SupplierID], 
	   UnitPackageID AS [Package/UnitPackageID],
	   OuterPackageID AS [Package/OuterPackageID],
	   QuantityPerOuter AS [Package/QuantityPerOuter],
	   TypicalWeightPerUnit AS [Package/TypicalWeightPerUnit],
	   LeadTimeDays AS [LeadTimeDays],
	   IsChillerStock AS [IsChillerStock],
	   TaxRate AS [TaxRate],
	   UnitPrice AS [UnitPrice]
FROM [Warehouse].[StockItems]
FOR XML PATH('Item'), ROOT('StockItems'))

SELECT @xml;

INSERT INTO [WideWorldImporters].[Warehouse].StockItemsXML VALUES (@xml);
SELECT * FROM [WideWorldImporters].[Warehouse].StockItemsXML;

exec master..xp_cmdshell 'bcp "[WideWorldImporters].[Warehouse].StockItemsXML" out  "C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\StockItemsNew.xml" -T -w -t"&$&" -S DESKTOP-QFU3MTE'

/****** 3. V tablice Warehouse.StockItems v kolonke CustomFields est' dannye v JSON.
Napisat' SELECT dlya vyvoda:
- StockItemID
- StockItemName
- CountryOfManufacture (iz CustomFields)
- FirstTag (iz polya CustomFields, pervoe znachenie iz massiva Tags) ******/

SELECT [StockItemID]
      ,[StockItemName]
	  ,JSON_VALUE([CustomFields], '$.CountryOfManufacture') AS CountryOfManufacture
	  ,JSON_VALUE([CustomFields], '$.Tags[0]') AS FirstTag
  FROM [Warehouse].[StockItems];

/****** 4. Najti v StockItems stroki, gde est' te'g "Vintage".
Vyvesti:
- StockItemID
- StockItemName
- (opcional'no) vse tegi (iz CustomFields) cherez zapyatuyu v odnom pole ******/

SELECT [StockItemID]
      ,[StockItemName]
FROM [Warehouse].[StockItems]
OUTER APPLY OPENJSON(CustomFields, '$.Tags') j
WHERE j.value='Vintage'

/****** 5. Pishem dinamicheskij PIVOT.
Po zadaniyu iz zanyatiya “Operatory CROSS APPLY, PIVOT, CUBE”.
Trebuetsya napisat' zapros, kotoryj v rezul'tate svoego vypolneniya formiruet tablicu sleduyushchego vida:
Nazvanie klienta
MesyacGod Kolichestvo pokupok
Nuzhno napisat' zapros, kotoryj budet generirovat' rezul'taty dlya vsex klientov.
Imya klienta ukazyvat' polnost'yu iz CustomerName.
Data dolzhna imet' format dd.mm.yyyy naprimer 01.12.2019 ******/

DECLARE @columns NVARCHAR(MAX), @sql NVARCHAR(MAX);
SET @columns=(SELECT ', [' + REPLACE(REPLACE([CustomerName],'Tailspin Toys (',''),')','') + ']' AS 'data()' FROM [Sales].[Customers] WHERE [CustomerID] BETWEEN 1 AND 1053 FOR XML PATH(''));
SELECT @columns;
SET @sql = N'SELECT * FROM 
(
 SELECT COUNT(o.[OrderID]) AS Orders
	   ,REPLACE(REPLACE(c.[CustomerName],''Tailspin Toys ('',''''),'')'','''') AS Company
       ,FORMAT(DATEADD(month,-1,DATEADD(day,1,EOMONTH(o.[OrderDate]))),''d'',''de-de'') AS Mnth
  FROM [Sales].[Orders] o
  JOIN [Sales].[Customers] c
  ON o.[CustomerID]=c.[CustomerID]
  GROUP BY o.[CustomerID] ,REPLACE(REPLACE(c.[CustomerName],''Tailspin Toys ('',''''),'')'',''''), FORMAT(DATEADD(month,-1,DATEADD(day,1,EOMONTH(o.[OrderDate]))),''d'',''de-de'')
  ) AS sel
  PIVOT (SUM(Orders)
  FOR Company IN('
  + STUFF(@columns, 1, 2, '')
  + ')) AS piv
  ORDER BY YEAR(Mnth), Mnth';
PRINT @sql;
EXEC sp_executesql @sql;