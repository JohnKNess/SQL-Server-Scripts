 /* ==================================================================
  Author......:	John Ness (JohnKNess)
  Date........:	09.08.2019
  Version.....:	0.1
  Server......:	localhost (first created for)
  Database....:	msdb
  Owner.......:	-
  Table.......:	-
  Type........:	Script
  Name........:	ADMIN_Assign_DTS_Permissions.sql 
  Description.:	After uncommenting one of the commented out EXEC lines
  ............	this script assigns the permissions to an account that
  ............	are required to run DTS or SSIS packages correctly.
  ............		
  ............	Please run on the target computer.
  ............		
  History.....:	 0.1	JKN	First documented
  ............		
  ............		
 ================================================================== */
 
USE [msdb]
GO
CREATE USER [DOMAIN\ACCOUNT] FOR LOGIN [DOMAIN\ACCOUNT]
GO
USE [msdb]
GO


/* ===================================================================
    DTS Package permissions
 ================================================================== */

/* ******************************************
  uncomment one of the permissions (admin not on Production!!) 
 ****************************************** */

----------------------
-- SQL Server >= 2005
----------------------
--exec sp_addrolemember @rolename='db_dtsadmin', @membername='DOMAIN\ACCOUNT'    -- Admin        = Enumerate All / View All / Execute All / Export All / Execute in SQL Agent / Import / Delete All / Change All
--exec sp_addrolemember @rolename='db_dtsltduser', @membername='DOMAIN\ACCOUNT'  -- LtdUser      = Enumerate All / View Own / Execute Own / Export Own /                      / Import / Delete Own / Change Own
--exec sp_addrolemember @rolename='db_dtsoperator', @membername='DOMAIN\ACCOUNT' -- Operator     = Enumerate All / View All / Execute All /            /                      /        /            /           


GO
USE [msdb]
GO
GRANT ALTER ON [dbo].[sysdtspackages] TO [DOMAIN\ACCOUNT]
GO
USE [msdb]
GO
GRANT DELETE ON [dbo].[sysdtspackages] TO [DOMAIN\ACCOUNT]
GO
USE [msdb]
GO
GRANT INSERT ON [dbo].[sysdtspackages] TO [DOMAIN\ACCOUNT]
GO
USE [msdb]
GO
GRANT SELECT ON [dbo].[sysdtspackages] TO [DOMAIN\ACCOUNT]
GO
USE [msdb]
GO
GRANT TAKE OWNERSHIP ON [dbo].[sysdtspackages] TO [DOMAIN\ACCOUNT]
GO
USE [msdb]
GO
GRANT UPDATE ON [dbo].[sysdtspackages] TO [DOMAIN\ACCOUNT]
GO
USE [msdb]
GO
GRANT VIEW DEFINITION ON [dbo].[sysdtspackages] TO [DOMAIN\ACCOUNT]
GO

/* ===================================================================
    SSIS Package permissions
 ================================================================== */

----------------------
-- SQL Server >= 2008
----------------------
-- exec sp_addrolemember @rolename='db_ssisadmin', @membername='DOMAIN\ACCOUNT'    -- Admin        = Enumerate All / View All / Execute All / Export All / Execute in SQL Agent / Import / Delete All / Change All
-- exec sp_addrolemember @rolename='db_ssisltduser', @membername='DOMAIN\ACCOUNT'  -- LtdUser      = Enumerate All / View Own / Execute Own / Export Own /                      / Import / Delete Own / Change Own
-- exec sp_addrolemember @rolename='db_ssisssisoperator', @membername='DOMAIN\ACCOUNT' -- Operator     = Enumerate All / View All / Execute All /            /                      /        /            /           


GO
USE [msdb]
GO
GRANT ALTER ON [dbo].[sysssispackages] TO [DOMAIN\ACCOUNT]
GO
USE [msdb]
GO
GRANT DELETE ON [dbo].[sysssispackages] TO [DOMAIN\ACCOUNT]
GO
USE [msdb]
GO
GRANT INSERT ON [dbo].[sysssispackages] TO [DOMAIN\ACCOUNT]
GO
USE [msdb]
GO
GRANT SELECT ON [dbo].[sysssispackages] TO [DOMAIN\ACCOUNT]
GO
USE [msdb]
GO
GRANT TAKE OWNERSHIP ON [dbo].[sysssispackages] TO [DOMAIN\ACCOUNT]
GO
USE [msdb]
GO
GRANT UPDATE ON [dbo].[sysssispackages] TO [DOMAIN\ACCOUNT]
GO
USE [msdb]
GO
GRANT VIEW DEFINITION ON [dbo].[sysssispackages] TO [DOMAIN\ACCOUNT]
GO