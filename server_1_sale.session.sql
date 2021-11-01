-- @block init database and table
-- @conn server_1_sale

USE [SALES];
GO
  
CREATE TABLE CUSTOMER([CustomerID] [int] NOT NULL, [SalesAmount] [decimal] NOT NULL);
GO
  
INSERT INTO CUSTOMER (CustomerID, SalesAmount) VALUES (1,100),(2,200),(3,300);
GO


-- @block configure the distributor
-- @conn server_1_master

USE [master];
GO
  
DECLARE @distributor AS SYSNAME;
DECLARE @distributorlogin AS SYSNAME;
DECLARE @distributorpassword AS SYSNAME;
DECLARE @Server SYSNAME;
  
SELECT @Server = @@servername;
  
SET @distributor = @Server;
SET @distributorlogin = N'SA';
SET @distributorpassword = N'Testing1234';
  
EXEC sp_adddistributor @distributor = @distributor;
  
EXEC sp_adddistributiondb @database = N'distribution'
    ,@log_file_size = 2
    ,@deletebatchsize_xact = 5000
    ,@deletebatchsize_cmd = 2000
    ,@security_mode = 0
    ,@login = @distributorlogin
    ,@password = @distributorpassword;
GO


 
-- @block configure the distributor 2
-- @conn server_1_master

USE [distribution];
GO
  
DECLARE @snapshotdirectory AS NVARCHAR(500);
  
SET @snapshotdirectory = N'/var/opt/mssql/ReplData/';
  
IF (NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'UIProperties' AND type = 'U '))
    CREATE TABLE UIProperties (id INT);
  
IF (EXISTS (SELECT * FROM::fn_listextendedproperty('SnapshotFolder', 'user', 'dbo', 'table', 'UIProperties', NULL, NULL)))
    EXEC sp_updateextendedproperty N'SnapshotFolder'
        ,@snapshotdirectory
        ,'user'
        ,dbo
        ,'table'
        ,'UIProperties'
ELSE
    EXEC sp_addextendedproperty N'SnapshotFolder'
        ,@snapshotdirectory
        ,'user'
        ,dbo
        ,'table'
        ,'UIProperties';
GO

 
-- @block configure the publisher
-- @conn server_1_master

USE [distribution];
GO
 
DECLARE @publisher AS SYSNAME;
DECLARE @distributorlogin AS SYSNAME;
DECLARE @distributorpassword AS SYSNAME;
DECLARE @Server SYSNAME;
 
SELECT @Server = @@servername;
 
SET @publisher = @Server;
SET @distributorlogin = N'SA';
SET @distributorpassword = N'Testing1234';
 
EXEC sp_adddistpublisher @publisher = @publisher
    ,@distribution_db = N'distribution'
    ,@security_mode = 0
    ,@login = @distributorlogin
    ,@password = @distributorpassword
    ,@working_directory = N'/var/opt/mssql/ReplData'
    ,@trusted = N'false'
    ,@thirdparty_flag = 0
    ,@publisher_type = N'MSSQLSERVER';
GO


-- @block configure the publication job run
-- @conn server_1_sale

USE [Sales];
GO
 
DECLARE @replicationdb AS SYSNAME;
DECLARE @publisherlogin AS SYSNAME;
DECLARE @publisherpassword AS SYSNAME;
 
SET @replicationdb = N'Sales';
SET @publisherlogin = N'SA';
SET @publisherpassword = N'Testing1234';
 
EXEC sp_replicationdboption @dbname = N'Sales'
    ,@optname = N'publish'
    ,@value = N'true';
 
EXEC sp_addpublication @publication = N'SnapshotRepl'
    ,@description = N'Snapshot publication of database ''Sales'' from Publisher ''''.'
    ,@retention = 0
    ,@allow_push = N'true'
    ,@repl_freq = N'snapshot'
    ,@status = N'active'
    ,@independent_agent = N'true';
 
EXEC sp_addpublication_snapshot @publication = N'SnapshotRepl'
    ,@frequency_type = 1
    ,@frequency_interval = 1
    ,@frequency_relative_interval = 1
    ,@frequency_recurrence_factor = 0
    ,@frequency_subday = 8
    ,@frequency_subday_interval = 1
    ,@active_start_time_of_day = 0
    ,@active_end_time_of_day = 235959
    ,@active_start_date = 0
    ,@active_end_date = 0
    ,@publisher_security_mode = 0
    ,@publisher_login = @publisherlogin
    ,@publisher_password = @publisherpassword;
GO


-- @block create the articles
-- @conn server_1_sale

USE [Sales];
GO
 
EXEC sp_addarticle @publication = N'SnapshotRepl'
    ,@article = N'customer'
    ,@source_owner = N'dbo'
    ,@source_object = N'customer'
    ,@type = N'logbased'
    ,@description = NULL
    ,@creation_script = NULL
    ,@pre_creation_cmd = N'drop'
    ,@schema_option = 0x000000000803509D
    ,@identityrangemanagementoption = N'manual'
    ,@destination_table = N'customer'
    ,@destination_owner = N'dbo'
    ,@vertical_partition = N'false';
GO


-- @block configure the subscription run
-- @conn server_1_qlvattu

USE [QL_VATTU];
GO
 
DECLARE @subscriber AS SYSNAME
DECLARE @subscriber_db AS SYSNAME
DECLARE @subscriberLogin AS SYSNAME
DECLARE @subscriberPassword AS SYSNAME
 
SET @subscriber = N'database-2'
SET @subscriber_db = N'QL_VATTU'
SET @subscriberLogin = N'SA'
SET @subscriberPassword = N'Testing1234'
 
EXEC sp_addsubscription @publication = N'SnapshotRepl'
    ,@subscriber = @subscriber
    ,@destination_db = @subscriber_db
    ,@subscription_type = N'Push'
    ,@sync_type = N'automatic'
    ,@article = N'all'
    ,@update_mode = N'read only'
    ,@subscriber_type = 0;
 
EXEC sp_addpushsubscription_agent @publication = N'SnapshotRepl'
    ,@subscriber = @subscriber
    ,@subscriber_db = @subscriber_db
    ,@subscriber_security_mode = 0
    ,@subscriber_login = @subscriberLogin
    ,@subscriber_password = @subscriberPassword
    ,@frequency_type = 1
    ,@frequency_interval = 0
    ,@frequency_relative_interval = 0
    ,@frequency_recurrence_factor = 0
    ,@frequency_subday = 0
    ,@frequency_subday_interval = 0
    ,@active_start_time_of_day = 0
    ,@active_end_time_of_day = 0
    ,@active_start_date = 0
    ,@active_end_date = 19950101;
GO


-- @block run the agent jobs 22
-- @conn server_1_msdb
SELECT name, date_modified FROM msdb.dbo.sysjobs order by date_modified desc


-- @block run the agent jobs
-- @conn server_1_msdb

USE [msdb]; 
GO
 
DECLARE @job1 SYSNAME;
 
SELECT @job1 = name FROM msdb.dbo.sysjobs
WHERE name LIKE '%-Sales-SnapshotRepl-1'
 |
EXEC dbo.sp_start_job @job1
GO


-- @block run the agent jobs 2
-- @conn server_1_msdb

DECLARE @job2 SYSNAME;
 
SELECT @job2 = name FROM msdb.dbo.sysjobs
WHERE name LIKE '%-Sales-SnapshotRepl-DATABASE-2-1'
  
EXEC dbo.sp_start_job @job2
GO
