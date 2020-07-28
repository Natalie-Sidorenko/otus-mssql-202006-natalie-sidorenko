CREATE DATABASE SortingCenter
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = SortingCenter, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\SortingCenter.mdf' , 
	SIZE = 8MB , 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 8MB )
 LOG ON 
( NAME = SortingCenter_log, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\SortingCenter_log.ldf' , 
	SIZE = 8MB , 
	MAXSIZE = 10GB , 
	FILEGROWTH = 8MB )
GO
USE SortingCenter
GO
CREATE SCHEMA Reference
GO
CREATE SCHEMA Invoices
GO
CREATE TABLE Reference.Storerooms (
	id_sr 		int NOT NULL IDENTITY(1, 1) PRIMARY KEY,
	storeroom   varchar(20)
	);

CREATE TABLE Reference.States (
	id_st 		int NOT NULL IDENTITY(1, 1) PRIMARY KEY,
	[state]     varchar(20)
	);
CREATE TABLE Reference.Delivery_results (
    id 	int NOT NULL IDENTITY(1, 1)  PRIMARY KEY,
    result varchar(50),
    rate varchar(5)
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
  Invoice BIGINT NOT NULL PRIMARY KEY , 
  [Creation date] DATETIME ,
  [Delivery date] DATE ,
  [Return invoice] BIGINT SPARSE NULL ,
  [Current storeroom] int REFERENCES Reference.Storerooms,
  [Current state] int REFERENCES Reference.States,
  [Last delivery result] int REFERENCES Reference.Delivery_results
  ); 
CREATE TABLE Invoices.Return_invoices (
  Invoice BIGINT NOT NULL PRIMARY KEY , 
  [Creation date] DATETIME ,
  [Delivery date] DATE ,
  [Primary invoice] BIGINT REFERENCES Invoices.Primary_invoices,
  [Current storeroom] int REFERENCES Reference.Storerooms,
  [Current state] int REFERENCES Reference.States,
  [Last delivery result] int REFERENCES Reference.Delivery_results
  ); 
GO
ALTER TABLE Invoices.Primary_invoices ADD CONSTRAINT FK_return FOREIGN KEY ([Return invoice]) REFERENCES Invoices.Return_invoices;
ALTER TABLE Invoices.Primary_invoices ADD CONSTRAINT constr_defaultddate DEFAULT (CAST (GETDATE()+1 AS DATE)) FOR [Delivery date];
ALTER TABLE Invoices.Primary_invoices ADD CONSTRAINT constr_ddate 
        CHECK (DATEDIFF(dd, [Delivery date], GETDATE()) <=0);
GO
ALTER TABLE Invoices.Return_invoices ADD CONSTRAINT constr_defaultrddate DEFAULT (CAST (GETDATE()+1 AS DATE)) FOR [Delivery date];
ALTER TABLE Invoices.Return_invoices ADD CONSTRAINT constr_rddate 
        CHECK (DATEDIFF(dd, [Delivery date], GETDATE()) <=0);
GO
ALTER TABLE Invoices.Primary_invoices ADD CONSTRAINT constr_storeroom DEFAULT (1) FOR [Current storeroom];
ALTER TABLE Invoices.Return_invoices ADD CONSTRAINT constr_rstoreroom DEFAULT (1) FOR [Current storeroom];
ALTER TABLE Invoices.Primary_invoices ADD CONSTRAINT constr_state DEFAULT (1) FOR [Current state];
ALTER TABLE Invoices.Return_invoices ADD CONSTRAINT constr_rstate DEFAULT (1) FOR [Current state];
GO
CREATE INDEX IX_I_Primary_Invoices_Current_Storeroom ON Invoices.Primary_invoices ([Current storeroom]);
CREATE INDEX IX_I_Primary_Invoices_Current_State ON Invoices.Primary_invoices ([Current state]);
CREATE INDEX IX_I_Return_Invoices_Current_Storeroom ON Invoices.Return_invoices ([Current storeroom]);
CREATE INDEX IX_I_Return_Invoices_Current_State ON Invoices.Return_invoices ([Current state]);
GO