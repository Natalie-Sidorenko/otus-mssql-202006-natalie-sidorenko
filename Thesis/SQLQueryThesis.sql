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

