-- Warning: You can generate script only for one table/view at a time in your Free plan 
-- 
-- ****************** SqlDBM: Microsoft SQL Server ******************
-- ******************************************************************

-- ************************************** [dbo].[Clients]

CREATE TABLE [dbo].[Clients]
(
 [client_id]   bigint NOT NULL ,
 [client_name] varchar(50) NOT NULL ,


 CONSTRAINT [PK_clients] PRIMARY KEY CLUSTERED ([client_id] ASC)
);
GO

-- ****************** SqlDBM: Microsoft SQL Server ******************
-- ******************************************************************

-- ************************************** [dbo].[Delivery_results]

CREATE TABLE [dbo].[Delivery_results]
(
 [result_id] int NOT NULL ,
 [result]    varchar(50) NOT NULL ,
 [rate]      varchar(50) NOT NULL ,


 CONSTRAINT [PK_delivery_results] PRIMARY KEY CLUSTERED ([result_id] ASC)
);
GO


-- ****************** SqlDBM: Microsoft SQL Server ******************
-- ******************************************************************

-- ************************************** [dbo].[States]

CREATE TABLE [dbo].[States]
(
 [state_id] int NOT NULL ,
 [state]    varchar(50) NOT NULL ,


 CONSTRAINT [PK_states] PRIMARY KEY CLUSTERED ([state_id] ASC)
);
GO


-- ****************** SqlDBM: Microsoft SQL Server ******************
-- ******************************************************************

-- ************************************** [dbo].[Storerooms]

CREATE TABLE [dbo].[Storerooms]
(
 [storeroom_id] int NOT NULL ,
 [storeroom]    varchar(50) NOT NULL ,


 CONSTRAINT [PK_storerooms] PRIMARY KEY CLUSTERED ([storeroom_id] ASC)
);
GO


-- ****************** SqlDBM: Microsoft SQL Server ******************
-- ******************************************************************

-- ************************************** [Primary_invoices]

CREATE TABLE [Primary_invoices]
(
 [invoice]               bigint NOT NULL ,
 [order]                 varchar(50) NOT NULL ,
 [client_id]             bigint NOT NULL ,
 [return_invoice]        bigint NOT NULL ,
 [creation_date]         datetime2(7) NOT NULL ,
 [shelf_life]            date NOT NULL ,
 [current_delivery_date] date NOT NULL ,
 [result_id]             int NOT NULL ,
 [state_id]              int NOT NULL ,
 [storeroom_id]          int NOT NULL ,


 CONSTRAINT [PK_primary_invoices] PRIMARY KEY CLUSTERED ([invoice] ASC),
 CONSTRAINT [FK_51] FOREIGN KEY ([state_id])  REFERENCES [dbo].[States]([state_id]),
 CONSTRAINT [FK_57] FOREIGN KEY ([storeroom_id])  REFERENCES [dbo].[Storerooms]([storeroom_id]),
 CONSTRAINT [FK_63] FOREIGN KEY ([result_id])  REFERENCES [dbo].[Delivery_results]([result_id]),
 CONSTRAINT [FK_69] FOREIGN KEY ([client_id])  REFERENCES [dbo].[Clients]([client_id])
);
GO


CREATE NONCLUSTERED INDEX [fkIdx_51] ON [Primary_invoices] 
 (
  [state_id] ASC
 )

GO

CREATE NONCLUSTERED INDEX [fkIdx_57] ON [Primary_invoices] 
 (
  [storeroom_id] ASC
 )

GO

CREATE NONCLUSTERED INDEX [fkIdx_63] ON [Primary_invoices] 
 (
  [result_id] ASC
 )

GO

CREATE NONCLUSTERED INDEX [fkIdx_69] ON [Primary_invoices] 
 (
  [client_id] ASC
 )

GO


-- ****************** SqlDBM: Microsoft SQL Server ******************
-- ******************************************************************

-- ************************************** [Return_invoices]

CREATE TABLE [Return_invoices]
(
 [invoice]               bigint NOT NULL ,
 [primary_invoice]       bigint NOT NULL ,
 [client_id]             bigint NOT NULL ,
 [creation_date]         datetime2(7) NOT NULL ,
 [current_delivery_date] date NOT NULL ,
 [result_id]             int NOT NULL ,
 [state_id]              int NOT NULL ,
 [storeroom_id]          int NOT NULL ,


 CONSTRAINT [PK_return_invoices] PRIMARY KEY CLUSTERED ([invoice] ASC),
 CONSTRAINT [FK_54] FOREIGN KEY ([state_id])  REFERENCES [dbo].[States]([state_id]),
 CONSTRAINT [FK_60] FOREIGN KEY ([storeroom_id])  REFERENCES [dbo].[Storerooms]([storeroom_id]),
 CONSTRAINT [FK_66] FOREIGN KEY ([result_id])  REFERENCES [dbo].[Delivery_results]([result_id]),
 CONSTRAINT [FK_72] FOREIGN KEY ([client_id])  REFERENCES [dbo].[Clients]([client_id]),
 CONSTRAINT [FK_75] FOREIGN KEY ([primary_invoice])  REFERENCES [Primary_invoices]([invoice])
);
GO


CREATE NONCLUSTERED INDEX [fkIdx_54] ON [Return_invoices] 
 (
  [state_id] ASC
 )

GO

CREATE NONCLUSTERED INDEX [fkIdx_60] ON [Return_invoices] 
 (
  [storeroom_id] ASC
 )

GO

CREATE NONCLUSTERED INDEX [fkIdx_66] ON [Return_invoices] 
 (
  [result_id] ASC
 )

GO

CREATE NONCLUSTERED INDEX [fkIdx_72] ON [Return_invoices] 
 (
  [client_id] ASC
 )

GO

CREATE NONCLUSTERED INDEX [fkIdx_75] ON [Return_invoices] 
 (
  [primary_invoice] ASC
 )

GO



-- ****************** SqlDBM: Microsoft SQL Server ******************
-- ******************************************************************

-- ************************************** [Delivery_history]

CREATE TABLE [Delivery_history]
(
 [id]              bigint NOT NULL ,
 [invoice]         bigint NOT NULL ,
 [delivery_date]   date NOT NULL ,
 [delivery_result] int NOT NULL ,
 [rate]            int NOT NULL ,


 CONSTRAINT [PK_delivery_history] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_78] FOREIGN KEY ([invoice])  REFERENCES [Primary_invoices]([invoice])
);
GO


CREATE NONCLUSTERED INDEX [fkIdx_78] ON [Delivery_history] 
 (
  [invoice] ASC
 )

GO





