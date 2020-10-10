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
	storeroom_name nvarchar(20) NOT NULL
	);
CREATE TABLE Reference.States (
	state_id	int NOT NULL IDENTITY(1, 1) PRIMARY KEY CLUSTERED,
	state_name  nvarchar(20) NOT NULL
	);
CREATE TABLE Reference.Delivery_results (
    result_id  int NOT NULL IDENTITY(1, 1)  PRIMARY KEY CLUSTERED,
    result_name  nvarchar(50) NOT NULL,
    rate       nvarchar(5) NOT NULL
    );
CREATE TABLE Reference.Clients (
	client_id 		bigint NOT NULL PRIMARY KEY CLUSTERED,
	client_name     nvarchar(20) NOT NULL
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
CREATE TABLE Invoices.Invoices (
  invoice_id BIGINT NOT NULL IDENTITY(1, 1) PRIMARY KEY CLUSTERED, 
  invoice_number BIGINT NOT NULL UNIQUE, 
  is_return BIT NOT NULL,
  order_number NVARCHAR(20),
  client_id BIGINT NOT NULL REFERENCES Reference.Clients,
  return_invoice_number BIGINT SPARSE NULL REFERENCES Invoices.Invoices (invoice_number),
  creation_date DATETIME2(7) NOT NULL,
  shelf_life DATE NOT NULL,
  current_delivery_date DATE,
  result_id INT REFERENCES Reference.Delivery_results,
  state_id INT NOT NULL REFERENCES Reference.States,
  storeroom_id INT NOT NULL REFERENCES Reference.Storerooms
  ); 
GO
CREATE TABLE History.Delivery_history (
 [id]              bigint NOT NULL IDENTITY(1, 1) PRIMARY KEY CLUSTERED ,
 [invoice_number]  bigint NOT NULL REFERENCES Invoices.Invoices (invoice_number),
 [delivery_date]   date NOT NULL ,
 [delivery_result] int NOT NULL 
);
GO
ALTER TABLE Invoices.Invoices ADD CONSTRAINT constr_invoice_numbers_sequence  DEFAULT (NEXT VALUE FOR dbo.primary_numbers) FOR invoice_number;
ALTER TABLE Invoices.Invoices ADD CONSTRAINT constr_defaultddate DEFAULT (CAST (GETDATE()+1 AS DATE)) FOR current_delivery_date;
ALTER TABLE Invoices.Invoices ADD CONSTRAINT constr_ddate 
        CHECK (DATEDIFF(dd, current_delivery_date, GETDATE()) <=0);
GO
ALTER TABLE Invoices.Invoices ADD CONSTRAINT constr_storeroom DEFAULT (1) FOR storeroom_id;
ALTER TABLE Invoices.Invoices ADD CONSTRAINT constr_state DEFAULT (1) FOR state_id;
GO
/**** INSERT REFERENCE DATA ****/
INSERT INTO Reference.States (state_name) VALUES ('at storeroom'), ('with courier'), ('delivered');
SELECT * FROM Reference.States;
INSERT INTO Reference.Storerooms (storeroom_name) VALUES ('delivery'), ('call-center'), ('return');
SELECT * FROM Reference.Storerooms;
INSERT INTO Reference.Delivery_results (result_name, rate) VALUES ('delivered','good'), ('refuse - return','good'), 
('not delivered - customer unavailable', 'good'), ('not delivered - date postponed', 'good'), ('not delivered - courier failed', 'bad');
SELECT * FROM Reference.Delivery_results;
INSERT INTO Reference.Clients (client_id, client_name) VALUES (7700000001, 'Aliexpress'), (7700000002, 'H&M'), (7700000003, 'INDITEX');
SELECT * FROM Reference.Clients;

/**** CREATE ORDERS (INVOICES) FROM CLIENT'S FILES ****/
CREATE TABLE #OrdersForBulkInsert (
client_id bigint,
[order] nvarchar (20)
);

--Aliexpress
DECLARE @docHandle int
DECLARE @xmlDocument  xml
SET @xmlDocument = ( 
 SELECT * FROM OPENROWSET
  (BULK 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Aliexpress.xml',
   SINGLE_BLOB)
   as s)
   SELECT @xmlDocument
   --SELECT 
   --       TypeNode.value('(.)[1]', 'nvarchar(150)')
   -- from @xmlDocument.nodes('Client/Order') as XTbl(TypeNode)

EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
INSERT INTO #OrdersForBulkInsert
SELECT *
FROM OPENXML(@docHandle, 'Client/Order', 3)       
WITH ( 
	client_id bigint '../@ID',
	[order] varchar (20) '.')

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
FROM OPENXML(@docHandle, 'Client/Order', 3)     
WITH ( 
	client_id bigint '../@ID',
	[order] varchar (20) '.')

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
FROM OPENXML(@docHandle, 'Client/Order', 3)     
WITH ( 
	client_id bigint '../@ID',
	[order] varchar (20) '.')

EXEC sp_xml_removedocument @docHandle;

SELECT * FROM #OrdersForBulkInsert;

/**** INSERT INTO Invoices.Invoices ****/
INSERT INTO Invoices.Invoices (client_id, order_number, is_return, creation_date, shelf_life)
SELECT * , 0, GETDATE(), (GETDATE()+14) FROM #OrdersForBulkInsert; 
SELECT * FROM Invoices.Invoices;
GO

/**** CREATE TRIGGER ON Invoices.Invoices FOR INSERT INTO History.Delivery_history ****/
CREATE TRIGGER Delivery_result_Update
ON Invoices.Invoices
 AFTER UPDATE
 AS   
IF ( UPDATE (result_id))  
BEGIN  
 INSERT INTO History.Delivery_history(invoice_number, delivery_date, delivery_result)
	SELECT invoice_number, current_delivery_date, result_id
	FROM INSERTED
END;  
GO 
SELECT * FROM History.Delivery_history;
GO

/**** STORED PROCEDURES: GIVE TO COURIER ****/
CREATE PROCEDURE Invoices.GiveToCourier
AS
BEGIN
	SET NOCOUNT ON;
UPDATE Invoices.Invoices
SET state_id = 2
WHERE storeroom_id = 1 AND state_id = 1;
END
GO
EXEC Invoices.GiveToCourier;
GO

/**** COURIER'S SCRIPT ****/
SELECT invoice_number FROM Invoices.Invoices
WHERE state_id = 2;
GO

CREATE PROCEDURE Invoices.Couriersscript @invoice bigint, @result int, @date date = NULL
AS
SET NOCOUNT ON;
IF 2 = (SELECT state_id FROM Invoices.Invoices WHERE invoice_number=@invoice)
BEGIN
 IF 1 = (SELECT is_return FROM Invoices.Invoices WHERE invoice_number=@invoice)
 BEGIN
 UPDATE Invoices.Invoices
 SET result_id = CASE WHEN @result=1 THEN @result ELSE 4 END
 WHERE invoice_number=@invoice;
 UPDATE Invoices.Invoices
 SET state_id = CASE WHEN @result=1 THEN 3 ELSE 1 END
 WHERE invoice_number=@invoice;
 UPDATE Invoices.Invoices
 SET current_delivery_date = CASE WHEN @result=1 THEN NULL ELSE (GETDATE()+1) END
 WHERE invoice_number=@invoice;
 END
 ELSE
 BEGIN
 UPDATE Invoices.Invoices
 SET result_id=@result
 WHERE invoice_number=@invoice;
 UPDATE Invoices.Invoices
 SET state_id = CASE WHEN @result=1 THEN 3 WHEN @result IN (2, 3, 4, 5) THEN 1 END
 WHERE invoice_number=@invoice;
 UPDATE Invoices.Invoices
 SET current_delivery_date= CASE WHEN @result IN (1, 2, 3, 4, 5) THEN @date ELSE GETDATE() END
 WHERE invoice_number=@invoice;
 END
END
GO

EXEC Invoices.Couriersscript @invoice=15000000114, @result=1;
EXEC Invoices.Couriersscript @invoice=15000000100, @result=4, @date='2020-10-11';
GO


/**** CALL-CENTER OPERATOR'S SCRIPT ****/
SELECT invoice FROM Invoices.Primary_invoices
WHERE storeroom_id = 2;
GO

CREATE PROCEDURE Invoices.Callcenterscript @invoice bigint, @result int, @date date
AS
BEGIN
SET NOCOUNT ON;
UPDATE Invoices.Invoices
SET current_delivery_date = GETDATE()
WHERE invoice_number=@invoice
UPDATE Invoices.Invoices
SET result_id = CASE WHEN @result=2 THEN @result ELSE 4 END
WHERE invoice_number=@invoice
UPDATE Invoices.Invoices
SET current_delivery_date = CASE WHEN @result=2 THEN NULL ELSE @date END
WHERE invoice_number=@invoice
END
GO

EXEC Invoices.Callcenterscript @invoice=15000000101, @result=5, @date='2020-10-12';
GO

/**** INVENTORY ****/
SELECT invoice_number FROM Invoices.Invoices
WHERE state_id = 1;
GO

CREATE PROCEDURE Invoices.Inventory @invoice bigint
AS
SET NOCOUNT ON;
IF 1 = (SELECT state_id FROM Invoices.Invoices WHERE invoice_number=@invoice)
BEGIN
UPDATE Invoices.Invoices
SET storeroom_id = CASE WHEN DATEDIFF(d, GETDATE(),current_delivery_date) = 1 THEN 1
WHEN DATEDIFF(d, shelf_life, GETDATE())>=0 THEN 3
WHEN result_id=2 THEN 3
ELSE 2 END
WHERE invoice_number=@invoice
END
GO

EXEC Invoices.Inventory @invoice=15000000101;
GO

/**** RETURN INVOICES CREATION ****/
SELECT invoice_number FROM Invoices.Invoices
WHERE storeroom_id = 3;
GO

CREATE PROCEDURE Invoices.ReturnInvoiceCreation @invoice bigint
AS
SET NOCOUNT ON;
IF 3 = (SELECT storeroom_id FROM Invoices.Invoices WHERE invoice_number=@invoice)
AND 0 =(SELECT is_return FROM Invoices.Invoices WHERE invoice_number=@invoice)
BEGIN
UPDATE Invoices.Invoices
SET state_id=3
WHERE invoice_number=@invoice;
UPDATE Invoices.Invoices
SET return_invoice_number = NEXT VALUE FOR dbo.return_numbers
WHERE invoice_number=@invoice;
INSERT INTO Invoices.Invoices (client_id, order_number, invoice_number, is_return, creation_date, shelf_life)
VALUES ((SELECT client_id FROM Invoices.Invoices WHERE invoice_number=@invoice),
         CAST (@invoice AS nvarchar), 
        (SELECT return_invoice_number FROM Invoices.Invoices WHERE invoice_number=@invoice),
		 1,
		 GETDATE(),
		 '9999-12-31');
END
GO

EXEC Invoices.ReturnInvoiceCreation @invoice=15000000098;
GO

SELECT * FROM Invoices.Invoices;
GO
