/*
-- =============================================================================
        ADMIN_Set_Database_Recovery_Model_TEST_Server.sql - 
			This script modifies the Recovery Model of all user databases 
			based on the parameter @nvRecMod (we will modify model)
			or based on the setting of the model database.
			   
			We don't touch master, msdb, tempdb or %tempdb%	        
        Copyright (C) 2024  hot2use / JohnKNess

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.    
-- =============================================================================
*/
/* 
-- =============================================================================
   Author......:  hot2use / JohnKNess 
   Date........:  18.06.2024
   Version.....:  0.2
   Server......:  any server
   Database....:  master
   Owner.......:  -
   Table.......:  -
   Type........:  Script
   Name........:  ADMIN_Set_Database_Recovery_Model_TEST_Server.sql 
   Description.:  This script modifies the Recovery Model of all user databases 
   ............   based on the parameter @nvRecMod (we will modify model)
   ............	  or based on the setting of the model database.
   ............   
   ............   We don't touch master, msdb, tempdb or %tempdb%		
   ............		
   History.....:  18-Jun-2024    0.1    JN  First created
   ............   19-Jun-2024	 0.2	JN	Added GNU License and header
   ............ 
   Editors.....:  SQLAssistant (SoftTree Technologies, Inc.)
   ............   SSMS 19.3
-- ============================================================================= 
*/


/***************************************************************************************************
 * @nvRecMod     :  The recovery model you want to set for all database
 *                  NULL | '' 	= use Recovery Model set on model database
 *                  SIMPLE		= set SIMPLE Recovery Model			(includes model database)
 *                  FULL		= set FULL Recovery Model			(includes model database)
 *                  BULK_LOGGED = set BULK-LOGGED Recovery Model	(includes model database)
 *                  
 * @NoExec       :  0 = execute backup                                          (DEFAULT)
 * (0|1)            1 = do NOT execute backup, only displays commands
 *
 * @iDebug       :  0 = do NOT debug anything                                   (DEFAULT)
 * (BITWISE)        1 = debug basic features / display position markers
 *                  2 = debug detailed features / display detailed text
 *                  4 = turn on transactional execution for some statements
 * 
 ***************************************************************************************************/
DECLARE @iDebug			AS INT;
DECLARE @nvRecMod		AS NVARCHAR(20) = N''; -- NULL, SIMPLE, FULL, BULK_LOGGED; 
DECLARE @NoExec			AS BIT			= 1;

DECLARE @dtStarted AS DATETIME = GETDATE();
DECLARE @tblDatabase AS TABLE (dbid INT IDENTITY(1,1), nvDBName NVARCHAR(150), nvRecMod NVARCHAR(20), nvRecModModel NVARCHAR(20), dtStarted DATETIME, dtLogged DATETIME DEFAULT GETDATE());

/*******************************************************************************
 * Variables used during execution
 *******************************************************************************/

DECLARE @iDBid AS INT;
DECLARE @nvDBName AS NVARCHAR(150);
DECLARE @nvSQL AS NVARCHAR(1000);

/*******************************************************************************
 * Code execution. 
 * No modifications required past this point.
 *******************************************************************************/

IF @nvRecMod = '' OR @nvRecMod IS NULL 
	BEGIN
		SELECT @nvRecMod = sdb3.recovery_model_desc FROM sys.databases AS sdb3 WHERE sdb3.name = 'model';
		SELECT '@nvRecMod assigned from model database:' + @nvRecMod;
		INSERT INTO @tblDatabase (nvDBName, nvRecMod, nvRecModModel, dtStarted, dtLogged)
		SELECT sdb.name, sdb.recovery_model_desc, sdb2.recovery_model_desc, @dtStarted, GETDATE() 
		FROM sys.databases AS sdb  
		JOIN sys.databases AS sdb2 
		ON sdb2.recovery_model_desc != sdb.recovery_model_desc
		AND sdb2.name = 'model'
		WHERE 1=1 
		AND sdb.name NOT IN ('master','msdb','tempdb','model')
		AND LOWER(sdb.name) NOT LIKE '%tempdb%';
	END
ELSE
	BEGIN
		SELECT '@nvRecMod assigned by script input:' + @nvRecMod;
		INSERT INTO @tblDatabase (nvDBName, nvRecMod, nvRecModModel, dtStarted, dtLogged)
		SELECT sdb.name, sdb.recovery_model_desc, sdb2.recovery_model_desc, @dtStarted, GETDATE() 
		FROM sys.databases AS sdb  
		JOIN sys.databases AS sdb2 
		ON sdb2.name = 'model'
		WHERE 1=1 
		AND sdb.recovery_model_desc != @nvRecMod 
		AND sdb.name NOT IN ('master','msdb','tempdb')
		AND LOWER(sdb.name) NOT LIKE '%tempdb%';
	END

SELECT * FROM @tblDatabase;

DECLARE LoopDBs CURSOR FOR 
SELECT dbid, nvDBName FROM @tblDatabase WHERE dtStarted = @dtStarted;

OPEN LoopDBs

FETCH NEXT FROM LoopDBs
INTO @iDBid, @nvDBName;

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @nvSQL = 'ALTER DATABASE [' + @nvDBName + '] SET RECOVERY ' + @nvRecMod + ' WITH NO_WAIT;'
	IF @NoExec = 1
		BEGIN
			SELECT @nvSQL;
		END
	ELSE
		BEGIN
			EXEC sp_executesql @nvSQL;
		END
	
	UPDATE @tblDatabase SET nvRecMod = @nvRecMod WHERE dbid = @iDBid;
	SELECT * FROM @tblDatabase
	FETCH NEXT FROM LoopDBs
	INTO @iDBid, @nvDBName;
END
CLOSE LoopDBs;
DEALLOCATE LoopDBs;
DELETE FROM @tblDatabase WHERE dtStarted = @dtStarted;
	 