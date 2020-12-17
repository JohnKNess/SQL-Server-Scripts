/*
-- =============================================================================
        ADMIN_Retrieve_Statistics_Info_Outdated_and_Update.sql 
        
        Small non-parameterized statement to retrieve statistics that have 
        become outdated and may or may not be triggered by SQL Server's 
        "auto update statistics" algorithm.
        
        The script will also list whether or not the trigger value has
        been reached or not for both the newer 2016 and the older 2014 
        algorithm.
        
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
 Version.....:    1.0
 Server......:    SERVERNAME\<INSTANCE> (first created for)
 Database....:    master
 Owner.......:    -
 Table.......:    -
 Type........:    Script
 Name........:    ADMIN_Retrieve_Statistics_Info_Outdated_and_Update.sql 
 ............:    
 Description.:    Script to retrieve statistics information
 ............     
 ............     
 History.....:    0.1    2018xxxx    JN    First created
 ............     0.9    20201217    JN    Release to GIT Repository SQL-Server-Scripts
 ............     
 To Do ......:    parameterize table name and other possible parameters
 ............     
================================================================================================= */
 
SELECT 'DBCC SHOW_STATISTICS ([' + [sch].[NAME] + '.' +[so].[NAME] + '] , [' + [ss].[NAME] + ']) WITH STAT_HEADER'       AS [SHOW_STATISTICS],
	   'update statistics ' + [sch].[name] + '.' + [so].[name] + ' ' + [ss].[name] + ' WITH FULLSCAN'                    AS [UPDATE_STATISTICS] -- PAGECOUNT=100, ROWCOUNT=100 | FULLSCAN
	   'DBCC UPDATEUSAGE(' + DB_NAME() + ', ''' + [sch].[NAME] + '.' +[so].[NAME] + ''')'                                AS [UPDATE_USAGE],
       [sch].[name] + '.' + [so].[name]                        AS [TableName],
       [ss].[name]                                             AS [Statistic],
       [sp].[last_updated]                                     AS [StatsLastUpdated],
       [sp].[rows]                                             AS [RowsInTable],
       [sp].[rows_sampled]                                     AS [RowsSampled],
       [sp].[modification_counter]                             AS [RowModifications],
       100 / (1.0 * [sp].[rows]) * [sp].[modification_counter] AS [PercentChanged],
       SQRT(1000 * [sp].[rows])                                AS [> 2014 Algorithm Change Value],
       CASE 
            WHEN SQRT(1000 * [sp].[rows]) < [sp].[modification_counter] THEN 1
            ELSE 0
       END                                                     AS [Auto Update > 2014 Triggered],
       [sp].[rows] * 1.0 / 100 * 20 + 500                      AS [<=2014 Algorithm Change Value],
       CASE 
            WHEN [sp].[rows] * 1.0 / 100 * 20 + 500 < [sp].[modification_counter] THEN 1
            ELSE 0
       END                                                     AS [Auto Update <= 2014 Triggered]
FROM   [sys].[stats] [ss]
       JOIN [sys].[objects] [so]
            ON  [ss].[object_id] = [so].[object_id]
       JOIN [sys].[schemas] [sch]
            ON  [so].[schema_id] = [sch].[schema_id]
       OUTER APPLY [sys].[dm_db_stats_properties]([so].[object_id], [ss].[stats_id]) sp
WHERE  1 = 1
       AND [so].[type] = 'U'
           -- AND [sp].[modification_counter] > 0
           -- AND 100/(1.0*[sp].[rows])*[sp].[modification_counter] < 10.0     -- maximum percentage change (certain tables have a high volatility)
           -- AND 100/(1.0*[sp].[rows])*[sp].[modification_counter] > 0.001    -- minimum percentage change (we aren't going to be looking at statistics with a very low percentage of change)
           -- AND [sp].[rows] > 1000000                                        -- only look at statistics which contain more than 1'000'000 rows.
           -- AND [sp].[last_updated] < dateadd(hh,-1,getdate())               -- only look at statistics which have been updated more than an hour ago
       AND [sch].[name] = 'dbo'
       AND [so].[name] = 'RCH_DM_PRINTHISTORY'
       -- AND [ss].[name] NOT LIKE '_WA_Sys%'                                  -- Exclude automatically create statistics
	   -- AND [ss].[name] not like '_dta_stat%'                                -- Exclude statistics crete by the Database Tuning Advisor
	   -- AND (SQRT(1000 * [sp].[rows]) < [sp].[modification_counter] OR [sp].[rows] * 1.0 / 100 * 20 + 500 < [sp].[modification_counter])
ORDER BY
       [sch].[name] + '.' + [so].[name] ASC,
       [ss].[name] ASC,
       [sp].[last_updated] DESC;
       