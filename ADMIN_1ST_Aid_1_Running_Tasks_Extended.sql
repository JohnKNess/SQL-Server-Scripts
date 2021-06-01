/*
-- =============================================================================
        ADMIN_1ST_Aid_1_Running_Tasks_Extended.sql 
        
        Display a list of running tasks in a given SQL Server instance.
        Comment out any of the various LEFT elements to reduce the amount
        of informaiton displayed.
        
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
/* 
-- =============================================================================
   Author......:  JohnKNess / hot2use
   Date........:  29.07.2020
   Version.....:  0.9
   Server......:  localhost (first created for)
   Database....:  master
   Owner.......:  -
   Table.......:  -
   Type........:  Script
   Name........:  ADMIN_1ST_Aid_1_Running_Tasks_Extended.sql 
   Description.:  This script retrieves currently running process on 
   ............   a SQL Server instance, depending on which LEFT JOINS 
   ............   are ommitted or not. 

   ............   Please run on the target computer.
   		
   History.....:  11-May-2015     0.1     JN  First created/adopted
   ............   29-Jul-2020     0.9     JN  Release to GitHub repository
   
   Editors.....:  UEStudio (IDM Computer Solutions, Inc.)   
                  SQLAssistant (SoftTree Technologies Inc.)
-- =============================================================================
*/


SELECT      des1.session_id             AS Session_ID_S,
            des1.context_info           AS Session_Contxt_Info,
            dec1.session_id             AS Session_ID_C,
            dowt.session_id             AS Session_ID_WT,
            dowt.exec_context_id        AS Exec_Contxt_ID,
            sdb.name                    AS DatabaseName,
            ssp.name                    AS SQL_Login_Name,
            des1.nt_user_name           AS NT_User_Name,           
            CASE  WHEN dowt.blocking_session_id  IS NOT NULL AND dowt.blocking_session_id != des1.session_id THEN '--kill ' + cast(dowt.blocking_session_id AS nvarchar(20)) ELSE ' ' END AS killcommand,
            dowt.wait_duration_ms       AS Wait_Duration_ms,
            dowt.wait_type              AS Wait_Type,
            dowt.blocking_session_id    AS Blocking_Session_ID,
            dowt.resource_description   AS Ressource_Description,
            des1.host_name              AS HostName,
            des1.program_name           AS Program_Name,
            dest.[text]                 AS SQL_Text,
            deqp.query_plan             AS Query_Plan,
            des1.cpu_time               AS CPU_Time,
            des1.memory_usage           AS RAM_Usage,
            'EOR'                       AS EOR
FROM        sys.dm_exec_sessions        AS des1
            LEFT 
            JOIN sys.dm_exec_connections    AS dec1    
                ON  des1.session_id         = dec1.session_id
            LEFT -- comment out LEFT to display only sessions that have gone parallel
            JOIN sys.dm_os_waiting_tasks    AS dowt 
                ON  des1.session_id         = dowt.session_id
            LEFT -- comment out LEFT to display only sessions currently executing statements
            JOIN sys.dm_exec_requests       AS der    
                ON  des1.session_id         = der.session_id
            LEFT -- comment out LEFT to ...... (I'm not telling)
            JOIN sys.server_principals      AS ssp  
                ON  des1.login_name         = ssp.name
            /* ==================== This is for SQL Server 2012 + =================== */
            LEFT 
            JOIN sys.databases              AS sdb
                ON des1.database_id         = sdb.database_id
             /* ==================== This is for SQL Server 2012 + ===================*/
            
            /* ==================== This is for SQL Server 2008 R2 ===================
            LEFT
            JOIN sys.sysprocesses as ss
                ON ss.spid = des1.session_id
            LEFT 
            JOIN sys.databases as sdb
                ON sdb.database_id = ss.dbid
             ==================== This is for SQL Server 2008 R2 ===================*/
             
            OUTER APPLY sys.dm_exec_sql_text(der.sql_handle)     AS dest -- Retrieve Actual SQL Text
            OUTER APPLY sys.dm_exec_query_plan(der.plan_handle)  AS deqp -- Retrieve Query Plan (XML)
WHERE       1=1
    -- AND      sdb.name in ('XPDATA', 'XPVDIR')
    AND        des1.is_user_process     = 1
    ORDER BY
           des1.session_id, dowt.exec_context_id           
       


/*
select 
--count(*), 
sdes.host_name, 
sdes.program_name, 
sdec.parent_connection_id,
sder.command,
sder.wait_type,
sder.last_wait_type,
sdes.*, 
sdec.*,
sder.*
from sys.dm_exec_connections AS sdec 
  join sys.dm_exec_sessions AS sdes 
    on sdes.session_id = sdec.session_id 
  left join sys.dm_exec_requests AS sder 
    on sdes.session_id = sder.session_id
    and sdes.database_id = sder.database_id
  -- group by sdes.host_name, sdes.program_name
order by sdec.session_id
*/