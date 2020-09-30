/*
-- =============================================================================
        ADMIN_Backup_Script_Multi_Database.sql 
        
        Backup script for multiple databases. Just when you need a simple script
        to dump one or more databases to a disk drive and don't want to install
        any other of the great scripts out there.
        
        Copyright (C) 2020  hot2use / JohnKNess

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
/* =================================================================================================
 Author......:    John Ness (JohnKNess)
 Date........:    03.10.2016
 Version.....:    0.9
 Server......:    SERVERNAME\<INSTANCE> (first created for)
 Database....:    msdb
 Owner.......:    -
 Table.......:    -
 Type........:    Script
 Name........:    ADMIN_Backup_Script_Multi_Database.sql
 ............:    
 Description.:    Backup script for multiple databases
 ............     
 ............     
 History.....:    0.1    20160927    JN    First created
 ............     0.2    20160929    JN    Parameterized backup script    
 ............     0.3    20161003    JN    Modified backup directory, added XP Cmd Shell on/off
 ............     0.4    20161221    JN    Inserted Execution Flag, inserted DEBUG flag
 ............     0.5    20170700    JN    Various modifications (compressions, ...)
 ............     0.6    20170726    JN    Added TLog Backup option
 ............     0.7    20190520    JN    Modified output to show more details in Text mode
 ............     0.9    20200930    JN    Release to GIT Repository SQL-Server-Scripts
 ............     
 To Do ......:    parameterize backup part --> sp-executesql                         
 ............     parameterize backup check --> sp_executesql
 ............     introduce database OFFLINE / ONLINE to kick out all sessions
================================================================================================= */
GO
/*
select d.database_id, d.name + ',' from sys.databases as d where d.name not in ('master','msdb', 'model', 'tempdb', 'TVDTools') 
and d.name not like 'DOKUMENT%' 
order by name
*/
GO
/* ==
select 'kill ' + cast(des.session_id as nvarchar(10)), des.host_name, des.login_time, des.login_name, db_name(des.database_id) as [database], des.*, sdec.* 
from sys.dm_exec_sessions as des join sys.dm_exec_connections as sdec on sdec.session_id = des.session_id
where des.database_id in (select database_id from sys.databases as sd where sd.name like 'DIA%')  and des.is_user_process = 1
and des.login_name not like '%tuafines%' and des.login_name not like '%saKNDSQLServices%'
== */
GO
/***************************************************************************************************
 * @nvDatabases  :  A list of databases seperated by commas (no spaces)        example N'Base,MyData'
 * @nvRootDir    :  The Root directory where the backups will be stored        example N'H:\backup\'
 * @nvInstance   :  The instance the backups is running on.                    example N'MSSQLSERVER'
 *                  Will be used to create a sub-directory in the Root directory
 *                  This value is only required if @iAutoInstance = 0
 *
 * @iAutoInstance:  1 = retrieve instance from current connection               (DEFAULT)
 * (1|0)            0 = do NOT retrieve instance from current connection
 *
 * @iBackOffline :  0 = backup database(s) even if users connected              (DEFAULT)
 * (0|1)            1 = do NOT backup database(s) if users connected
 * 
 * @iCopyOnly    :  n = will create a CopyOnly backup of the database           (DEFAULT)
 * (n|256)          256 = will create a sequenced backup (non CopyOnly) of the database
 *
 * @NoExecBackup :  0 = execute backup                                          (DEFAULT)
 * (0|1)            1 = do NOT execute backup, only displays commands
 *
 * @iDebug       :  0 = do NOT debug anything                                   (DEFAULT)
 * (BITWISE)        1 = debug basic features / display position markers
 *                  2 = debug detailed features / display detailed text
 *                  4 = turn on transactional execution for some statements
 * 
 * @iInclTransLog:  0 = Do NOT include Transaction Log Backup                   (DEFAULT)
 * (0|1)            1 = Include a Tranaction Log Backup of the database(s).
 *                      NOTE:
 *                      If set to 1 and backing up a mirrored database, 
 *                      set @iCopyOnly to 256 otherwise your restore will fail 
 *                      on the mirrored database.
 *
 ***************************************************************************************************/
--WAITFOR TIME '07:25:00'

DECLARE @nvDatabases    AS NVARCHAR(300) = N'DATABASENAME'
DECLARE @nvRootDir      AS NVARCHAR(50) = N'H:\adhoc'
DECLARE @iAutoInstance  AS INT = 1
DECLARE @nvInstance     AS NVARCHAR(20) = N''
DECLARE @iCopyOnly      AS INT = 1
DECLARE @iBackOffline   AS INT = 0 -- not yet implemented
DECLARE @NoExecBackup   AS INT = 1
DECLARE @iDebug         AS INT = 0
DECLARE @iNoCompression AS INT = 0
DECLARE @iInclTransLog  AS INT = 0
DECLARE @nvIncrement    AS NVARCHAR(2) = N'10'
--DECLARE @dtRunTime        AS    DATETIME    = '00:00:00'

/*******************************************************************************
 * Variables used during execution
 *******************************************************************************/
DECLARE @nvBackupDate   AS NVARCHAR(8) = N''
DECLARE @nvBackupTime   AS NVARCHAR(6) = N''
DECLARE @nvDB2Backup    AS NVARCHAR(30) = N''
DECLARE @iDBState       AS INT = 0
DECLARE @nvCopyOnly     AS NVARCHAR(15) = N''
DECLARE @nvCopyOnlyTxt  AS NVARCHAR(10) = N''
DECLARE @nvCompression  AS NVARCHAR(20) = N''
DECLARE @iBackOfflineRet AS INT = 0

DECLARE @nvSQLStatement AS NVARCHAR(2000) = N''
DECLARE @iSQLStmtRet    AS INT = 0

DECLARE @nvCommand      AS NVARCHAR(1000) = N''
DECLARE @iCommandRet    AS INT = 0

DECLARE @nvDirectory    AS NVARCHAR(100) = N''

DECLARE @iXPCmdShellRet AS INT = 0
DECLARE @iResetXPCmdShell AS INT = 0

DECLARE @iContinue      AS INT = 0

DECLARE @iLen           AS INT = 0
DECLARE @iComma         AS INT = 0


/*******************************************************************************
 * Code execution. 
 * No modifications required past this point.
 *******************************************************************************/
IF @iAutoInstance = 1
    BEGIN
        SELECT @nvInstance = CONVERT(NVARCHAR(20), SERVERPROPERTY('InstanceName'))
    END
ELSE
    BEGIN
        SET @nvInstance = @nvInstance
    END

    
PRINT '@nvInstance......: ' + CONVERT(NVARCHAR(20), @nvInstance)    

/*******************************************************************************
 * Determine if XP Cmd Shell is turned on otherwise enable it
 *******************************************************************************/

SELECT @iXPCmdShellRet = CONVERT(INT, value_in_use)
FROM   sys.configurations
WHERE  configuration_id = '16390'

PRINT '@iXPCmdShellRet..: ' + CONVERT(NVARCHAR(10), @iXPCmdShellRet)
IF @iXPCmdShellRet = 0
    BEGIN
        SET @iResetXPCmdShell = 1 -- Set to remember to turn off
        PRINT '@iResetXPCmdShell: ' + CONVERT(NVARCHAR(10), @iResetXPCmdShell)
        GOTO TurnOnXPCmdShell; --  Jump to section to turn on xp_cmdshell
    END
       
       NormalExecution:

/*******************************************************************************
 * Create directory string to check availability
 *******************************************************************************/
SET @nvDirectory = @nvRootDir
IF @nvInstance != ''
    BEGIN
        SET @nvDirectory = @nvDirectory + N'\' + @nvInstance
    END
                                  
SET @nvCommand = 'dir ' + @nvDirectory
EXEC @iCommandRet = xp_cmdshell @nvCommand
PRINT '@iCommandRet.....: ' + CONVERT(NVARCHAR(10), @iCommandRet)
IF @iCommandRet != 0
    BEGIN
        /*******************************************************************************
        * Create directory string to make directory
        *******************************************************************************/
        SET @nvCommand = 'md ' + @nvDirectory
        EXEC @iCommandRet = xp_cmdshell @nvCommand
        IF @iCommandRet != 0
            BEGIN
                GOTO DirectoryError;
            END
        ELSE
            BEGIN
                SET @iContinue = 1
            END
    END
ELSE
    BEGIN
        SET @iContinue = 1
    END


/*******************************************************************************
 * If directory could be read or created continue... (2)
 *******************************************************************************/
IF @iContinue = 1
    BEGIN
        DatabaseLoop:
        SELECT @iLen = LEN(@nvDatabases)
        WHILE @iLen > 0
        BEGIN
            SELECT @iComma = PATINDEX('%,%', @nvDatabases)
            --PRINT @iComma
            IF @iComma > 0
                BEGIN
                    SELECT @nvDB2Backup = LEFT(@nvDatabases, @iComma -1)
                    SELECT @nvDatabases = RIGHT(@nvDatabases, @iLen -@iComma)
                    SELECT @iLen = LEN(@nvDatabases)
                END
            ELSE
                BEGIN
                    SELECT @nvDB2Backup = @nvDatabases
                    SELECT @nvDatabases = ''
                    SELECT @iLen = LEN(@nvDatabases)
                END
            
            
            /*******************************************************************************
             * Check if database is available
             *******************************************************************************/
            SELECT @iDBState = STATE
            FROM   sys.databases
            WHERE  NAME = @nvDB2Backup
            
            IF @iDBState != 0
                   OR @@ROWCOUNT = 0
                BEGIN
                    PRINT '-------------------------------------------------'
                    PRINT 'DB unavailable...: ' + @nvDB2Backup
                    PRINT '-------------------------------------------------'
                    SELECT 'DB unavailable...: ' + @nvDB2Backup
                    GOTO DatabaseLoop; --skip backup
                END
            
            /*******************************************************************************
             * Check if database has to be Offline
             *******************************************************************************/
            -- SELECT @iBackOfflineRet = COUNT(*) from sys.dm_exec_sessions as des join sys.databases as d on des.database_id = d.database_id where d.database_name = @nvDB2Backup
            -- IF @iBackOfflineRet > 0 and @iBackOffline = 1 
            
            
            /*******************************************************************************
             * Start preparing the backup components/variables
             *******************************************************************************/
            SET @nvBackupDate = SUBSTRING(CONVERT(NVARCHAR(30), GETDATE(), 20), 1, 4) + SUBSTRING(CONVERT(NVARCHAR(30), GETDATE(), 20), 6, 2) 
                + SUBSTRING(CONVERT(NVARCHAR(30), GETDATE(), 20), 9, 2)
            
            SET @nvBackupTime = SUBSTRING(CONVERT(NVARCHAR(30), GETDATE(), 20), 12, 2) + SUBSTRING(CONVERT(NVARCHAR(30), GETDATE(), 20), 15, 2) 
                + SUBSTRING(CONVERT(NVARCHAR(30), GETDATE(), 20), 18, 2)
            
            IF @iCopyOnly & 256 != 256
                BEGIN
                    SET @nvCopyOnly = N'COPY_ONLY, ' 
                    SET @nvCopyOnlyTxt = N'CopyOnly_'
                END
            ELSE
                BEGIN
                    SET @nvCopyOnly = N'' 
                    SET @nvCopyOnlyTxt = N''
                END
            
            
            IF @iNoCompression != 0
                SET @nvCompression = N'NO_COMPRESSION, '
            ELSE
                SET @nvCompression = N'COMPRESSION, '
            
            PRINT '------------------------------------------------3'
            PRINT '@iLen............: ' + CONVERT(NVARCHAR(10), @iLen)
            PRINT '@iComma..........: ' + CONVERT(NVARCHAR(10), @iComma)
            PRINT '@nvDirectory.....: ' + @nvDirectory
            PRINT '@nvDB2Backup.....: ' + @nvDB2Backup
            PRINT '@nvDatabases.....: ' + @nvDatabases
            PRINT '@nvCopyOnly......: ' + @nvCopyOnly
            PRINT '-------------------------------------------------'
            
            /*******************************************************************************
             * This is the actual backup section
             *******************************************************************************/
            
            SET @nvSQLStatement = N'BACKUP DATABASE [' + @nvDB2Backup + N'] TO  DISK = ''' + @nvDirectory + N'\' +
                @nvDB2Backup + N'_Full_' + @nvCopyOnlyTxt + @nvBackupDate + N'_' + @nvBackupTime +
                N'.bak'' 
                WITH ' + @nvCopyOnly + '' + @nvCompression + 'RETAINDAYS = 3, NOFORMAT, NOINIT, NAME = N''' +
                @nvDB2Backup +
                N'-Full Backup Sichern'', SKIP, NOREWIND, 
                     NOUNLOAD, STATS = ' + @nvIncrement + N', CHECKSUM'
            
            PRINT @nvSQLStatement
            IF @NoExecBackup = 0
                BEGIN
                    PRINT '-------------------------------------------------'
                    EXEC @iSQLStmtRet = sp_executesql @nvSQLStatement
                    PRINT '-------------------------------------------------'
                END
            ELSE
                BEGIN
                    PRINT '-------------------------------------------------'
                    PRINT ' !!!!! No actual backup of ' + @nvDB2Backup + ' performed !!!!!'
                    PRINT '-------------------------------------------------'
                    SELECT ' !!!!! No actual backup of ' + @nvDB2Backup + ' performed !!!!!'
                END
            
            
            IF @iSQLStmtRet != 0
                BEGIN
                    PRINT '-------------------------------------------------'
                    PRINT ' Error during backup of ' + @nvDB2Backup + '!'
                    PRINT ' Errocode: ' + CAST(@iSQLStmtRet AS NVARCHAR(20))
                    PRINT '-------------------------------------------------'
                    SELECT ' Error during backup of ' + @nvDB2Backup + '!'
                    SELECT ' Errocode: ' + CAST(@iSQLStmtRet AS NVARCHAR(20))
                END
            ELSE
                BEGIN
                        IF @NoExecBackup = 1
                            BEGIN
                        PRINT '-------------------------------------------------'
                        PRINT ' DB Backup test run complete...: ' + @nvDB2Backup
                        PRINT '-------------------------------------------------'
                        SELECT ' DB Backup test run complete...: ' + @nvDB2Backup
                            END
                        ELSE
                            BEGIN
                                PRINT '-------------------------------------------------'
                        PRINT ' DB Backup complete...: ' + @nvDB2Backup
                        PRINT '-------------------------------------------------'
                        SELECT ' DB Backup complete...: ' + @nvDB2Backup

                            END
                  END
            
            
            SET @nvSQLStatement = N''
            
            /*******************************************************************************
             * This is the actual backup section for the Transaction Log
             *******************************************************************************/
            IF @iInclTransLog = 1
                BEGIN
                    SET @nvSQLStatement = N'BACKUP LOG [' + @nvDB2Backup + N'] TO  DISK = ''' + @nvDirectory + N'\' +
                        @nvDB2Backup + N'_TLog_' + @nvCopyOnlyTxt + @nvBackupDate + N'_' + @nvBackupTime +
                        N'.trn'' 
            WITH ' + @nvCopyOnly + '' + @nvCompression + 'RETAINDAYS = 3, NOFORMAT, NOINIT, NAME = N''' + @nvDB2Backup +
                        N'-Transaktion Log Sichern'', SKIP, NOREWIND, 
               NOUNLOAD, STATS = ' + @nvIncrement + N', CHECKSUM'
                    
                    PRINT @nvSQLStatement
                    IF @NoExecBackup = 0
                        BEGIN
                            PRINT '-------------------------------------------------'
                            EXEC @iSQLStmtRet = sp_executesql @nvSQLStatement
                            PRINT '-------------------------------------------------'
                        END
                    ELSE
                        BEGIN
                            PRINT '-------------------------------------------------'
                            PRINT ' !!!!! No actual backup performed !!!!!'
                            PRINT '-------------------------------------------------'
                            SELECT ' !!!!! No actual backup performed !!!!!'
                        END
                    
                    
                    IF @iSQLStmtRet != 0
                        BEGIN
                            PRINT '-------------------------------------------------'
                            PRINT ' Error during backup of ' + @nvDB2Backup + '!'
                            PRINT ' Errocode: ' + CAST(@iSQLStmtRet AS NVARCHAR(20))
                            PRINT '-------------------------------------------------'
                            SELECT ' Error during backup of ' + @nvDB2Backup + '!'
                            SELECT ' Errocode: ' + CAST(@iSQLStmtRet AS NVARCHAR(20))
                        END
                    
                    SET @nvSQLStatement = N''
                END
            
            SET @nvSQLStatement = N''
                
                
                /*******************************************************************************
                * This is the backup verfication (to be continued)
                *******************************************************************************/ 
                /*DECLARE @backupSetId AS INT
                SET @nvSQLStatement = N'SELECT @backupSetID = position
                FROM   msdb..backupset
                WHERE  database_name                    = N''' + @nvDB2Backup + N'''
                AND backup_set_id                = (
                SELECT MAX(backup_set_id)
                FROM   msdb..backupset
                WHERE  database_name     = N''' + @nvDB2Backup + N'''
                )'
                PRINT @nvSQLStatement
                IF @backupSetId IS NULL
                BEGIN
                RAISERROR(
                N'Fehler beim Überprüfen. Sicherungsinformationen für die Basis-Datenbank wurden nicht gefunden.',
                16,
                1
                )
                END
                
                RESTORE VERIFYONLY FROM  DISK = 'H:\adhoc\NEST\Matzingen\Basis_Full_20160927_083000.bak' 
                WITH FILE = @backupSetId, NOUNLOAD, NOREWIND
                */
        END
    END
ELSE
    /*******************************************************************************
     * (2) ...otherwise state error
     *******************************************************************************/
    BEGIN
        GOTO DirectoryError;
    END

-- Finished Case / If


/*******************************************************************************
  * If XPCmdShell was OFF before this script started, then turn it back OFF
  *******************************************************************************/
IF @iResetXPCmdShell = 1
    BEGIN
        GOTO TurnOffXPCmdShell;
    END
       
       NormalExecution2:   
--SELECT 1
GOTO EndProc;

/*******************************************************************************
 * Section for turning on XP Cmd Shell in SQL Server
 *******************************************************************************/
TurnOnXPCmdShell:

SET @nvSQLStatement = N'sp_configure ''show advanced options'',1'
PRINT @nvSQLStatement
EXEC @iSQLStmtRet = sp_executesql @nvSQLStatement
IF @iSQLStmtRet != 0
    BEGIN
        PRINT 'Error setting environment (1)!'
    END

SET @nvSQLStatement = N''

SET @nvSQLStatement = N'RECONFIGURE'
PRINT @nvSQLStatement
EXEC @iSQLStmtRet = sp_executesql @nvSQLStatement
IF @iSQLStmtRet != 0
    BEGIN
        PRINT 'Error setting environment (1)!'
    END

SET @nvSQLStatement = N''

SET @nvSQLStatement = N'sp_configure ''xp_cmdshell'',1 '
PRINT @nvSQLStatement
EXEC @iSQLStmtRet = sp_executesql @nvSQLStatement
IF @iSQLStmtRet != 0
    BEGIN
        PRINT 'Error setting environment (1)!'
    END

SET @nvSQLStatement = N''

SET @nvSQLStatement = N'RECONFIGURE'
PRINT @nvSQLStatement
EXEC @iSQLStmtRet = sp_executesql @nvSQLStatement
IF @iSQLStmtRet != 0
    BEGIN
        PRINT 'Error setting environment (1)!'
    END

SET @nvSQLStatement = N''

SET @nvSQLStatement = N'sp_configure ''show advanced options'',0'
PRINT @nvSQLStatement
EXEC @iSQLStmtRet = sp_executesql @nvSQLStatement
IF @iSQLStmtRet != 0
    BEGIN
        PRINT 'Error setting environment (1)!'
    END

SET @nvSQLStatement = N''

GOTO NormalExecution;

/*******************************************************************************
 * Section for turning off XP Cmd Shell in SQL Server
 *******************************************************************************/
TurnOffXPCmdShell:

SET @nvSQLStatement = N'sp_configure ''show advanced options'',1'
PRINT @nvSQLStatement
EXEC @iSQLStmtRet = sp_executesql @nvSQLStatement
IF @iSQLStmtRet != 0
    BEGIN
        PRINT 'Error setting environment (1)!'
    END

SET @nvSQLStatement = N''

SET @nvSQLStatement = N'RECONFIGURE'
PRINT @nvSQLStatement
EXEC @iSQLStmtRet = sp_executesql @nvSQLStatement
IF @iSQLStmtRet != 0
    BEGIN
        PRINT 'Error setting environment (1)!'
    END

SET @nvSQLStatement = N''

SET @nvSQLStatement = N'sp_configure ''xp_cmdshell'',0 '
PRINT @nvSQLStatement
EXEC @iSQLStmtRet = sp_executesql @nvSQLStatement
IF @iSQLStmtRet != 0
    BEGIN
        PRINT 'Error setting environment (1)!'
    END

SET @nvSQLStatement = N''

SET @nvSQLStatement = N'RECONFIGURE'
PRINT @nvSQLStatement
EXEC @iSQLStmtRet = sp_executesql @nvSQLStatement
IF @iSQLStmtRet != 0
    BEGIN
        PRINT 'Error setting environment (1)!'
    END

SET @nvSQLStatement = N''

SET @nvSQLStatement = N'sp_configure ''show advanced options'',0'
PRINT @nvSQLStatement
EXEC @iSQLStmtRet = sp_executesql @nvSQLStatement
IF @iSQLStmtRet != 0
    BEGIN
        PRINT 'Error setting environment (1)!'
    END

SET @nvSQLStatement = N''

GOTO NormalExecution2;

/*******************************************************************************
 * Section when directory error occurs
 *******************************************************************************/
DirectoryError:
PRINT 'Unable to access/create directory: ' + @nvRootDir

/*******************************************************************************
 * Section for end of procedure
 *******************************************************************************/
EndProc:
PRINT 'Finished'

