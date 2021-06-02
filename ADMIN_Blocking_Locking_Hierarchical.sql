/*
-- =============================================================================
        ADMIN_Blocking_Locking_Hierarchical.sql
        
        This script displays a hierarchical tree
        of locked/blocked processes on a SQL Server
        instance.
        
        Copyright (C) 2021  hot2use / JohnKNess

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
   Date........:  01.06.2021
   Version.....:  0.1
   Server......:  SQL Server 2012+ (first created for)
   Database....:  master
   Owner.......:  -
   Table.......:  -
   Type........:  Script
   Name........:  ADMIN_Blocking_Locking_Hierarchical.sql 
   Description.:  This script displays a hierarchical tree
   ............	  of locked/blocked processes on a SQL Server
   ............	  instance.
   ............		
   History.....:  01-Jun-2021    0.1    JN  First created
   ............   
   ............ 
   Editors.....:  UEStudio (IDM Computer Solutions, Inc.)   
   ............   SQLAssistant (SoftTree Technologies, Inc.)
   ............   SQL Server Management Studio 18.9.1 (Microsoft, Inc.)
-- ============================================================================= 
*/

SET LANGUAGE 'us_english'
GO
-- USE MASTER -- commanted out to allow for use on Azure SQL
-- GO 
-- Create a Temp Table with Base Data
SELECT sdes.session_id AS SESSION_ID,					-- SESSION_ID
       sder.blocking_session_id AS BLOCKING_SESSION_ID,	-- BLOCKED_SESSION_ID
       sder.wait_resource AS WAIT_RESSOURCE,			-- WAIT_RESOURCE
       dowt.wait_duration_ms AS WAIT_DURATION_MS,		-- WAIT_DURATION_MS
       dowt.wait_type AS WAIT_TYPE,						-- WAIT_TYPE
       dest.text AS SQL_TEXT,							-- SQL_TEXT
       deqp.query_plan AS QUERY_PLAN					-- PLAN_CACHE
INTO   #SESSION_BASE_DATA
FROM   sys.dm_exec_sessions									AS sdes
       JOIN sys.dm_exec_connections							AS sdec
            ON  sdes.session_id = sdec.session_id
       LEFT JOIN sys.dm_exec_requests						AS sder
            ON  sder.session_id = sdec.session_id
            AND sder.connection_id = sdec.connection_id
       LEFT JOIN sys.dm_os_waiting_tasks					AS dowt
            ON  sdes.session_id = dowt.session_id
       OUTER APPLY sys.dm_exec_sql_text(sder.sql_handle)	AS dest
	   OUTER APPLY sys.dm_exec_query_plan(sder.plan_handle)	AS deqp
GO
/*
SELECT * FROM #SESSION_BASE_DATA
go
*/
WITH DirectSessions(
         HIERARCHY,
         SESSION_ID,
         BLOCKING_SESSION_ID,
         WAIT_RESSOURCE,
         WAIT_DURATION_MS,
         WAIT_TYPE,
         BLOCKING_LEVEL,
         SQL_TEXT,
         QUERY_PLAN,
         SORTPATH
     )
     AS (
         -- Base Elements(s) of CTE
         SELECT CONVERT(NCHAR(50), '| ' + CAST(SESSION_ID AS NCHAR(4)) + '') 
                AS HIERARCHY,												-- HIERARCHY (Base Tree Design Element)
                SESSION_ID,													-- SESSION_ID
                BLOCKING_SESSION_ID,										-- BLOCKED_SESSION_ID
                WAIT_RESSOURCE,												-- WAIT_RESOURCE
                WAIT_DURATION_MS,											-- WAIT_DURATION_MS
                WAIT_TYPE,													-- WAIT_TYPE
                1 AS BLOCKING_LEVEL,										-- BLOCKING_LEVEL
                SQL_TEXT,													-- SQL_TEXT
                QUERY_PLAN,													-- PLAN_CACHE
                CAST(SESSION_ID AS NVARCHAR(200))							-- SORTPATH
         FROM   #SESSION_BASE_DATA
         WHERE  1 = 1
                AND (
                		BLOCKING_SESSION_ID = 0 
                		OR BLOCKING_SESSION_ID IS NULL
                    )														-- Base element(s) with a blocking process id = 0 or NULL
         UNION ALL
         -- Next Element(s) of CTE
         SELECT CONVERT(
                    NCHAR(50),
                    REPLICATE('|     ', BLOCKING_LEVEL -1) + '|----¬ ' + CAST(sbd.SESSION_ID AS NCHAR(4))
                ) AS HIERARCHY,												-- HIERARCHY (Extended Tree Design Elements)
                sbd.SESSION_ID,												-- SESSION_ID
                sbd.BLOCKING_SESSION_ID,									-- BLOCKED_SESSION_ID
                sbd.WAIT_RESSOURCE,											-- WAIT_RESOURCE
                sbd.WAIT_DURATION_MS,										-- WAIT_DURATION_MS
                sbd.WAIT_TYPE,												-- WAIT_TYPE
                BLOCKING_LEVEL + 1,											-- BLOCKING_LEVEL + 1 
                sbd.SQL_TEXT,												-- SQL_TEXT
                sbd.QUERY_PLAN,												-- PLAN_CACHE
                CAST(
                    CAST(ds.SORTPATH AS NVARCHAR(200)) + ' ' + CAST(sbd.SESSION_ID AS NVARCHAR(4)) AS NVARCHAR(200)
                )															-- SORTPATH = base SESSION_ID + CURRENT SESSION_ID from iteration in CTE
         FROM   #SESSION_BASE_DATA AS sbd
                JOIN DirectSessions AS ds
                     ON  ds.SESSION_ID = sbd.BLOCKING_SESSION_ID
         WHERE  1 = 1
                AND (
                        sbd.BLOCKING_SESSION_ID != 0
                        OR sbd.BLOCKING_SESSION_ID IS NOT NULL
                    ) -- All other elements with a blocking session_id
     )

SELECT HIERARCHY,
       SESSION_ID,
       BLOCKING_SESSION_ID,
       WAIT_RESSOURCE,
       WAIT_DURATION_MS,
       WAIT_TYPE,
       BLOCKING_LEVEL,
       SQL_TEXT,
       QUERY_PLAN
FROM   DirectSessions
ORDER BY
       SORTPATH
GO
DROP TABLE #SESSION_BASE_DATA
GO
