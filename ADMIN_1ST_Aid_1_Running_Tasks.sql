/************************************************************
 * Code formatted by SoftTree SQL Assistant © v7.1.246
 * Time: 11.05.2015 08:11:51
 ************************************************************/

SELECT dowt.session_id, 
       '--kill ' + cast(dowt.session_id as nvarchar(20)),
       db_name(dest.dbid),
       dowt.exec_context_id,
       dowt.wait_duration_ms,
       dowt.wait_type,
       dowt.blocking_session_id,
       dowt.resource_description,
       des1.program_name,
       --der.sql_handle,
       --der.plan_handle,
       dest.[text],
       dest.dbid,
       deqp.query_plan,
       des1.cpu_time,
       des1.memory_usage
FROM   sys.dm_os_waiting_tasks          AS dowt
       LEFT JOIN sys.dm_exec_sessions  AS des1
            ON  des1.session_id = dowt.session_id
       LEFT JOIN sys.dm_exec_requests  AS der
            ON  des1.session_id = der.session_id
       OUTER APPLY sys.dm_exec_sql_text(der.sql_handle) dest
OUTER APPLY sys.dm_exec_query_plan(der.plan_handle) deqp
WHERE  des1.is_user_process = 1
ORDER BY
       1,
       2
       
       
       
       --select   * from sys.databases where database_id = 12 