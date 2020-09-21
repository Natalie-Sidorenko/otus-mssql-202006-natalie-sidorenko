/**** CREATE DATABASE ****/
CREATE DATABASE SortingCenter
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = SortingCenter, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\SortingCenter.mdf' , 
	SIZE = 8MB , 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 65536KB )
 LOG ON 
( NAME = SortingCenter_log, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\SortingCenter_log.ldf' , 
	SIZE = 8MB , 
	MAXSIZE = 10GB , 
	FILEGROWTH = 65536KB )
GO
USE SortingCenter
GO
CREATE SCHEMA Reference
GO
CREATE SCHEMA Invoices
GO
CREATE SCHEMA History
GO
CREATE TABLE Reference.Storerooms (
	storeroom_id  int NOT NULL IDENTITY(1, 1) PRIMARY KEY CLUSTERED,
	storeroom     varchar(20) NOT NULL
	);
CREATE TABLE Reference.States (
	state_id	int NOT NULL IDENTITY(1, 1) PRIMARY KEY CLUSTERED,
	[state]     varchar(20) NOT NULL
	);
CREATE TABLE Reference.Delivery_results (
    result_id  int NOT NULL IDENTITY(1, 1)  PRIMARY KEY CLUSTERED,
    result     varchar(50) NOT NULL,
    rate       varchar(5) NOT NULL
    );
CREATE TABLE Reference.Clients (
	client_id 		bigint NOT NULL PRIMARY KEY CLUSTERED,
	client_name     varchar(20) NOT NULL
	);
GO
CREATE SEQUENCE primary_numbers
  AS bigint
  START WITH 15000000001
  INCREMENT BY 1
  MINVALUE 15000000000
  MAXVALUE 15099999999
  CYCLE;
  CREATE SEQUENCE return_numbers
  AS bigint
  START WITH 4000000001
  INCREMENT BY 1
  MINVALUE 4000000000
  MAXVALUE 4099999999
  CYCLE;
  GO
CREATE TABLE Invoices.Primary_invoices (
  invoice BIGINT NOT NULL PRIMARY KEY CLUSTERED, 
  [order] VARCHAR(20) ,
  client_id bigint NOT NULL REFERENCES Reference.Clients ,
  return_invoice BIGINT SPARSE NULL ,
  creation_date DATETIME2(7) NOT NULL,
  shelf_life DATE NOT NULL,
  current_delivery_date DATE ,
  result_id int REFERENCES Reference.Delivery_results,
  state_id int NOT NULL REFERENCES Reference.States,
  storeroom_id int NOT NULL REFERENCES Reference.Storerooms
  ); 
CREATE TABLE Invoices.Return_invoices (
  invoice BIGINT NOT NULL PRIMARY KEY CLUSTERED, 
  primary_invoice BIGINT NOT NULL REFERENCES Invoices.Primary_invoices,
  client_id bigint NOT NULL REFERENCES Reference.Clients ,
  creation_date DATETIME2(7) NOT NULL,
  current_delivery_date DATE ,
  result_id int REFERENCES Reference.Delivery_results,
  state_id int NOT NULL REFERENCES Reference.States,
  storeroom_id int NOT NULL REFERENCES Reference.Storerooms
  ); 
GO
CREATE TABLE History.Delivery_history (
 [id]              bigint NOT NULL IDENTITY(1, 1) PRIMARY KEY CLUSTERED ,
 [invoice]         bigint NOT NULL REFERENCES Invoices.Primary_invoices,
 [delivery_date]   date NOT NULL ,
 [delivery_result] int NOT NULL ,
 [rate]            int NOT NULL 
);
GO

ALTER TABLE Invoices.Primary_invoices ADD CONSTRAINT FK_return FOREIGN KEY (return_invoice) REFERENCES Invoices.Return_invoices;
ALTER TABLE Invoices.Primary_invoices ADD CONSTRAINT constr_defaultddate DEFAULT (CAST (GETDATE()+1 AS DATE)) FOR current_delivery_date;
ALTER TABLE Invoices.Primary_invoices ADD CONSTRAINT constr_ddate 
        CHECK (DATEDIFF(dd, current_delivery_date, GETDATE()) <=0);
GO
ALTER TABLE Invoices.Return_invoices ADD CONSTRAINT constr_defaultrddate DEFAULT (CAST (GETDATE()+1 AS DATE)) FOR current_delivery_date;
ALTER TABLE Invoices.Return_invoices ADD CONSTRAINT constr_rddate 
        CHECK (DATEDIFF(dd, current_delivery_date, GETDATE()) <=0);
GO
ALTER TABLE Invoices.Primary_invoices ADD CONSTRAINT constr_storeroom DEFAULT (1) FOR storeroom_id;
ALTER TABLE Invoices.Return_invoices ADD CONSTRAINT constr_rstoreroom DEFAULT (1) FOR storeroom_id;
ALTER TABLE Invoices.Primary_invoices ADD CONSTRAINT constr_state DEFAULT (1) FOR state_id;
ALTER TABLE Invoices.Return_invoices ADD CONSTRAINT constr_rstate DEFAULT (1) FOR state_id;
GO
CREATE INDEX IX_I_Primary_Invoices_Current_Storeroom ON Invoices.Primary_invoices (storeroom_id);
CREATE INDEX IX_I_Primary_Invoices_Current_State ON Invoices.Primary_invoices (state_id);
CREATE INDEX IX_I_Return_Invoices_Current_Storeroom ON Invoices.Return_invoices (storeroom_id);
CREATE INDEX IX_I_Return_Invoices_Current_State ON Invoices.Return_invoices (state_id);
GO
/**** INSERT REFERENCE DATA ****/
INSERT INTO Reference.States ([state]) VALUES ('at storeroom'), ('with courier'), ('delivered');
SELECT * FROM Reference.States;
INSERT INTO Reference.Storerooms (storeroom) VALUES ('delivery'), ('call-center'), ('return');
SELECT * FROM Reference.Storerooms;
INSERT INTO Reference.Delivery_results (result, rate) VALUES ('delivered','good'), ('refuse - return','good'), 
('not delivered - customer unavailable', 'good'), ('not delivered - date postponed', 'good'), ('not delivered - courier failed', 'bad');
SELECT * FROM Reference.Delivery_results;
INSERT INTO Reference.Clients (client_id, client_name) VALUES (7700000001, 'Aliexpress'), (7700000002, 'H&M'), (7700000003, 'INDITEX');
SELECT * FROM Reference.Clients;

/**** CREATE ORDERS (INVOICES) FROM CLIENT'S FILES ****/
CREATE TABLE #OrdersForBulkInsert (
client_id bigint,
[order] varchar (20)
);

--Aliexpress
DECLARE @docHandle int
DECLARE @xmlDocument  xml
SET @xmlDocument = ( 
 SELECT * FROM OPENROWSET
  (BULK 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Aliexpress.xml',
   SINGLE_BLOB)
   as s)
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
INSERT INTO #OrdersForBulkInsert
SELECT *
FROM OPENXML(@docHandle, 'Client/Order', 3)       --works incorrectly
WITH ( 
	client_id bigint '../@ID',
	[order] varchar (20) '../Order')

EXEC sp_xml_removedocument @docHandle;

--H&M
DECLARE @docHandle int
DECLARE @xmlDocument  xml
SET @xmlDocument = ( 
 SELECT * FROM OPENROWSET
  (BULK 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\H&M.xml',
   SINGLE_BLOB)
   as s)
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
INSERT INTO #OrdersForBulkInsert
SELECT *
FROM OPENXML(@docHandle, 'Client/Order', 3)      --works incorrectly
WITH ( 
	client_id bigint '../@ID',
	[order] varchar (20) '../Order')

EXEC sp_xml_removedocument @docHandle;

--INDITEX
DECLARE @docHandle int
DECLARE @xmlDocument  xml
SET @xmlDocument = ( 
 SELECT * FROM OPENROWSET
  (BULK 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\INDITEX.xml',
   SINGLE_BLOB)
   as s)
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
INSERT INTO #OrdersForBulkInsert
SELECT *
FROM OPENXML(@docHandle, 'Client/Order', 3)      --works incorrectly
WITH ( 
	client_id bigint '../@ID',
	[order] varchar (20) '../Order')

EXEC sp_xml_removedocument @docHandle;

SELECT * FROM #OrdersForBulkInsert;

/**** MERGE (FAILED): 
      NEXT VALUE FOR function can only be used with MERGE if it is defined within a default constraint on the target table for insert actions. ****/
MERGE Invoices.Primary_invoices AS target
USING #OrdersForBulkInsert AS source
ON (target.[order]=source.[order])
WHEN NOT MATCHED THEN INSERT 
(
  invoice, 
  [order],
  client_id,
  creation_date,
  shelf_life
  )
  VALUES (NEXT VALUE FOR dbo.primary_numbers, source.[order], source.client_id, GETDATE(), GETDATE()+14); 

  --INSERT HARDCODED
INSERT INTO Invoices.Primary_invoices
(
  invoice, 
  [order],
  client_id,
  creation_date,
  shelf_life
  )
  VALUES (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193690RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193577RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193640RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193660RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193748RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193766RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193615RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193661RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193782RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193578RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193641RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193679RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193680RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193691RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193711RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193749RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193750RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193767RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193579RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, 'AECA0002193616RU1', 7700000001, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '31611301060220', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '11611301061137', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '21611301061138', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '31611301061139', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '51611301061140', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '61611301061141', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '71611301061142', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '81611301061143', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '91611301061144', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '01611301061145', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '11611301061146', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '21611301061147', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '31611301061148', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '41611301061149', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '61611301061150', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '71611301061151', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '81611301061152', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '91611301061153', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '01611301061154', 7700000002, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006636945', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006730362', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006730684', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006733518', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006733784', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006737366', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006737622', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006745346', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006751917', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006753656', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006755728', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006759668', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006759888', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006766754', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006770722', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006779193', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006784669', 7700000003, GETDATE(), GETDATE()+14),
  (NEXT VALUE FOR dbo.primary_numbers, '113006786059', 7700000003, GETDATE(), GETDATE()+14); 

  SELECT * FROM Invoices.Primary_invoices;

GO

/**** STORED PROCEDURES: GIVE TO COURIER ****/
CREATE PROCEDURE Invoices.GiveToCourierPrimary
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE Invoices.Primary_invoices
SET 
	state_id = 2
WHERE storeroom_id = 1 AND state_id = 1;

END
GO

CREATE PROCEDURE Invoices.GiveToCourierReturn
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE Invoices.Return_invoices
SET 
	state_id = 2
WHERE storeroom_id = 1 AND state_id = 1;

END
GO

EXEC Invoices.GiveToCourierPrimary;
GO
EXEC Invoices.GiveToCourierReturn;
GO

/**** COURIER'S SCRIPT (PRIMARY) ****/
SELECT invoice FROM Invoices.Primary_invoices
WHERE state_id = 2;
GO

CREATE PROCEDURE Invoices.Couriersscript @invoice bigint, @result int, @date date = NULL
AS
IF @result = 1
BEGIN
UPDATE Invoices.Primary_invoices
SET
    result_id = @result,
	state_id = 3
WHERE invoice = @invoice;
END
ELSE
BEGIN
UPDATE Invoices.Primary_invoices
SET
    result_id = @result,
	state_id = 1,
	current_delivery_date = @date
WHERE invoice = @invoice;
END
GO

EXEC Invoices.Couriersscript @invoice=15000000019, @result=1;
EXEC Invoices.Couriersscript @invoice=15000000022, @result=4, @date='2020-09-22';
GO

/**** COURIER'S SCRIPT (RETURN) ****/
SELECT invoice FROM Invoices.Return_invoices
WHERE state_id = 2;
GO

CREATE PROCEDURE Invoices.CouriersscriptReturn @invoice bigint, @result int
AS
IF @result = 1
BEGIN
UPDATE Invoices.Return_invoices
SET
    result_id = @result,
	state_id = 3
WHERE invoice = @invoice;
UPDATE Invoices.Primary_invoices
SET
   state_id = 3
   WHERE return_invoice = @invoice;
END
IF @result = 5
BEGIN
UPDATE Invoices.Return_invoices
SET
    result_id = @result,
	current_delivery_date = DATEADD (d, 1, current_delivery_date),
	state_id=1
WHERE invoice = @invoice;
END
ELSE
BEGIN
PRINT 'ERROR'                  --works incorrectly
END
GO

EXEC Invoices.CouriersscriptReturn @invoice=4000000002, @result=1;
EXEC Invoices.CouriersscriptReturn @invoice=4000000003, @result=5;
GO

/**** CALL-CENTER OPERATOR'S SCRIPT ****/
SELECT invoice FROM Invoices.Primary_invoices
WHERE storeroom_id = 2;
GO

CREATE PROCEDURE Invoices.Callcenterscript @invoice bigint, @result int, @date date
AS
IF @result = 2
BEGIN
UPDATE Invoices.Primary_invoices
SET
    result_id = @result,
	current_delivery_date = NULL
WHERE invoice = @invoice;
END
IF @result = 4
BEGIN
UPDATE Invoices.Primary_invoices
SET
    result_id = @result,
	current_delivery_date = @date
WHERE invoice = @invoice;
END
ELSE
BEGIN
PRINT 'ERROR'
END
GO

EXEC Invoices.Callcenterscript @invoice=15000000055, @result=4, @date='2020-09-23';
GO

/**** INVENTORY (PRIMARY) ****/
SELECT invoice FROM Invoices.Primary_invoices
WHERE state_id = 1;
GO

CREATE PROCEDURE Invoices.PrimaryInventory @invoice bigint
AS
IF DATEDIFF(d, GETDATE(), (SELECT current_delivery_date FROM Invoices.Primary_invoices WHERE invoice=@invoice)) = 1 --non working
BEGIN
UPDATE Invoices.Primary_invoices
SET
storeroom_id=1
WHERE invoice=@invoice;
END
IF (SELECT result_id FROM Invoices.Primary_invoices WHERE invoice=@invoice) = 2 OR 
DATEDIFF(d, GETDATE(), (SELECT shelf_life FROM Invoices.Primary_invoices WHERE invoice=@invoice)) = 0
BEGIN
UPDATE Invoices.Primary_invoices
SET
   storeroom_id=3
   WHERE invoice=@invoice;
END
ELSE
BEGIN
UPDATE Invoices.Primary_invoices
SET
   storeroom_id=2
   WHERE invoice=@invoice;
END
GO

EXEC Invoices.PrimaryInventory @invoice=15000000019;
GO

SELECT DATEDIFF(d, GETDATE(), (SELECT current_delivery_date FROM Invoices.Primary_invoices WHERE invoice=15000000019))
SELECT DATEDIFF(d, GETDATE(), '2020-09-20')

/**** INVENTORY (RETURN) ****/
SELECT a.invoice FROM Invoices.Primary_invoices a
WHERE a.storeroom_id = 3 AND NOT EXISTS (SELECT b.return_invoice FROM Invoices.Primary_invoices b WHERE a.invoice=b.invoice);
GO

CREATE PROCEDURE Invoices.ReturnInventory @invoice bigint
AS
BEGIN
INSERT INTO Invoices.Return_invoices (
                                       invoice, 
                                       primary_invoice, 
                                       client_id, 
                                       creation_date)
VALUES (
         NEXT VALUE FOR dbo.return_numbers, 
         @invoice,
         (SELECT client_id FROM Invoices.Primary_invoices WHERE invoice=@invoice), 
         GETDATE()); 
UPDATE Invoices.Primary_invoices
SET
return_invoice=(SELECT invoice FROM Invoices.Return_invoices WHERE primary_invoice=@invoice)
WHERE invoice=@invoice;
END
GO

EXEC Invoices.ReturnInventory @invoice=15000000054;
 GO

SELECT * FROM Invoices.Return_invoices
SELECT * FROM Invoices.Primary_invoices;
GO

UPDATE Invoices.Primary_invoices             --inventory hardcoded
SET
storeroom_id=1 WHERE invoice = 15000000019;

SELECT invoice FROM Invoices.Primary_invoices
WHERE state_id=1 AND storeroom_id=1
UNION ALL
SELECT invoice FROM Invoices.Return_invoices
WHERE state_id=1 AND storeroom_id=1;