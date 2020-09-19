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