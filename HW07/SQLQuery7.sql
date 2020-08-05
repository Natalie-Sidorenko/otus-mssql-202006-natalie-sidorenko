USE WideWorldImporters;
GO
INSERT INTO [Purchasing].[Suppliers]
      ([SupplierID]
      ,[SupplierName]
      ,[SupplierCategoryID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[SupplierReference]
      ,[BankAccountName]
      ,[BankAccountBranch]
      ,[BankAccountCode]
      ,[BankAccountNumber]
      ,[BankInternationalCode]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy])
VALUES (NEXT VALUE FOR Sequences.SupplierID
      ,'Waterhouse Insurance'
	  ,9
	  ,3252
	  ,3253
	  ,NULL
	  ,35004
	  ,35004
	  ,'I676ET43'
	  ,'Waterhouse Insurance'
	  ,'Woodgrove Bank Los Angeles'
	  ,'476345'
	  ,'2834504947'
	  ,'63857'
	  ,14
	  ,'(385)555-0109'
	  ,'(385)555-0109'
	  ,'http://www.waterhouseinsurance.com'
	  ,''
	  ,'309 Henry Road'
	  ,'27653'
	  ,'PO Box 46'
	  ,'Hecksville'
	  ,'27653'
	  ,1),
	  (NEXT VALUE FOR Sequences.SupplierID
      ,'MO Designe'
	  ,2
	  ,3254
	  ,3255
	  ,2
	  ,26978
	  ,26978
	  ,'67GIYT75'
	  ,'MO Designe'
	  ,'Woodgrove Bank Seattle'
	  ,'309846'
	  ,'1097673849'
	  ,'08476'
	  ,30
	  ,'(565)555-0107'
	  ,'(565)555-0108'
	  ,'http://www.mo-designe.com'
	  ,''
	  ,'210 Church Road'
	  ,'45872'
	  ,'PO Box 397'
	  ,'Dunport'
	  ,'45872'
	  ,1),
	  (NEXT VALUE FOR Sequences.SupplierID
      ,'Takeda Electronics'
	  ,3
	  ,3256
	  ,3257
	  ,8
	  ,23145
	  ,23145
	  ,'2O45HI8'
	  ,'Takeda Electronics'
	  ,'Woodgrove Bank Sioux City'
	  ,'453465'
	  ,'2039464783'
	  ,'24076'
	  ,7
	  ,'(754)555-0102'
	  ,'(754)555-0103'
	  ,'http://www.takedaelectronics.com'
	  ,''
	  ,'45 Green Street'
	  ,'12465'
	  ,'PO Box 6979'
	  ,'Peermont'
	  ,'12465'
	  ,1),
	  (NEXT VALUE FOR Sequences.SupplierID
      ,'Knitting House'
	  ,4
	  ,3258
	  ,3259
	  ,7
	  ,1567
	  ,1567
	  ,'47J98F4'
	  ,'Knitting House'
	  ,'Woodgrove Bank New York'
	  ,'937766'
	  ,'2736805856'
	  ,'29754'
	  ,14
	  ,'(609)555-0104'
	  ,'(609)555-0105'
	  ,'http://www.knittinghouse.com'
	  ,''
	  ,'570 Lake Way'
	  ,'33099'
	  ,'PO Box 23'
	  ,'Fire Hills'
	  ,'33099'
	  ,1),
	  (NEXT VALUE FOR Sequences.SupplierID
      ,'Quick Pack, Inc.'
	  ,5
	  ,3260
	  ,3261
	  ,3
	  ,18302
	  ,18302
	  ,'0H8H47F'
	  ,'Quick Pack'
	  ,'Woodgrove Bank Boston'
	  ,'598765'
	  ,'2876569938'
	  ,'87353'
	  ,14
	  ,'(860)555-0100'
	  ,'(860)555-0101'
	  ,'http://www.quickpack.com'
	  ,''
	  ,'1201 Charity Street'
	  ,'72834'
	  ,'PO Box 745'
	  ,'Providence'
	  ,'72834'
	  ,1);

SELECT * FROM  [Purchasing].[Suppliers];

DELETE FROM [Purchasing].[Suppliers]
WHERE [SupplierName]='Waterhouse Insurance';

UPDATE [Purchasing].[Suppliers]
SET [PaymentDays]=7
WHERE [SupplierID]=18;

MERGE [Purchasing].[Suppliers] AS target
USING (SELECT 'Waterhouse Insurance'
	  ,9
	  ,3253
	  ,3252
	  ,NULL
	  ,35004
	  ,35004
	  ,'I676ET43'
	  ,'Waterhouse Insurance'
	  ,'Woodgrove Bank Los Angeles'
	  ,'476345'
	  ,'2834504947'
	  ,'63857'
	  ,14
	  ,'(385)555-0109'
	  ,'(385)555-0109'
	  ,'http://www.waterhouseinsurance.com'
	  ,'Level 1'
	  ,'309 Henry Road'
	  ,'27653'
	  ,'PO Box 46'
	  ,'Hecksville'
	  ,'27653'
	  ,1
	  )
	  AS source ([SupplierName]
      ,[SupplierCategoryID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[SupplierReference]
      ,[BankAccountName]
      ,[BankAccountBranch]
      ,[BankAccountCode]
      ,[BankAccountNumber]
      ,[BankInternationalCode]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
	  )
	  ON (target.[SupplierName]=source.[SupplierName])
WHEN MATCHED 
THEN UPDATE SET [SupplierCategoryID]=source.[SupplierCategoryID]
	           ,[PrimaryContactPersonID]=source.[PrimaryContactPersonID]
	           ,[AlternateContactPersonID]=source.[AlternateContactPersonID]
	           ,[DeliveryMethodID]=source.[DeliveryMethodID]
	           ,[DeliveryCityID]=source.[DeliveryCityID]
			   ,[PostalCityID]=source.[PostalCityID]
	           ,[SupplierReference]=source.[SupplierReference]
	           ,[BankAccountName]=source.[BankAccountName]
               ,[BankAccountBranch]=source.[BankAccountBranch]
	           ,[BankAccountCode]=source.[BankAccountCode]
	           ,[BankAccountNumber]=source.[BankAccountNumber]
	           ,[BankInternationalCode]=source.[BankInternationalCode]
	           ,[PaymentDays]=source.[PaymentDays]
	           ,[PhoneNumber]=source.[PhoneNumber]
	           ,[FaxNumber]=source.[FaxNumber]
	           ,[WebsiteURL]=source.[WebsiteURL]
	           ,[DeliveryAddressLine1]=source.[DeliveryAddressLine1]
	           ,[DeliveryAddressLine2]=source.[DeliveryAddressLine2]
	           ,[DeliveryPostalCode]=source.[DeliveryPostalCode]
	           ,[PostalAddressLine1]=source.[PostalAddressLine1]
	           ,[PostalAddressLine2]=source.[PostalAddressLine2]
	           ,[PostalPostalCode]=source.[PostalPostalCode]
	           ,[LastEditedBy]=source.[LastEditedBy] 
WHEN NOT MATCHED 
THEN INSERT ([SupplierName]
      ,[SupplierCategoryID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[SupplierReference]
      ,[BankAccountName]
      ,[BankAccountBranch]
      ,[BankAccountCode]
      ,[BankAccountNumber]
      ,[BankInternationalCode]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
	  )
VALUES (source.[SupplierName]
       ,source.[SupplierCategoryID]
	   ,source.[PrimaryContactPersonID]
	   ,source.[AlternateContactPersonID]
	   ,source.[DeliveryMethodID]
	   ,source.[DeliveryCityID]
       ,source.[PostalCityID]
	   ,source.[SupplierReference]
	   ,source.[BankAccountName]
       ,source.[BankAccountBranch]
	   ,source.[BankAccountCode]
	   ,source.[BankAccountNumber]
	   ,source.[BankInternationalCode]
	   ,source.[PaymentDays]
	   ,source.[PhoneNumber]
	   ,source.[FaxNumber]
	   ,source.[WebsiteURL]
	   ,source.[DeliveryAddressLine1]
	   ,source.[DeliveryAddressLine2]
	   ,source.[DeliveryPostalCode]
	   ,source.[PostalAddressLine1]
	   ,source.[PostalAddressLine2]
	   ,source.[PostalPostalCode]
	   ,source.[LastEditedBy]);

EXEC sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
RECONFIGURE;  
GO  

SELECT @@SERVERNAME;

exec master..xp_cmdshell 'bcp "[WideWorldImporters].[Purchasing].[Suppliers]" out  "C:\Users\hp\Documents\SQL Server Management Studio\Suppliers.csv" -T -w -t"&$&" -S DESKTOP-QFU3MTE'

