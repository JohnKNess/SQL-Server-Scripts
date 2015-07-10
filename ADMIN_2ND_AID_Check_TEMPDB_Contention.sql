/*
 * If you see a lot of lines of output where the wait_type is PAGELATCH_UP or PAGELATCH_EX, 
 * and the resource_description is 2:1:1 then that’s the PFS page (database ID 2 – tempdb, file ID 1, page ID 1), 
 * and if you see 2:1:3 then that’s another allocation page called an SGAM (more info here).
 * 
 * http://www.sqlskills.com/blogs/paul/the-accidental-dba-day-27-of-30-troubleshooting-tempdb-contention/
 * 
 * Uncomment the commented lines for more information. Works only on SQL 2005 SP4 and above.
 * 
 * [...]
 * The best guidance I’ve seen is from a great friend of mine, Bob Ward, who’s the top Escalation Engineer in Microsoft SQL Product Support. 
 * Figure out the number of logical processor cores you have 
 * (e.g. two CPUS, with 4 physical cores each, plus hyperthreading enabled = 2 (cpus) x 4 (cores) x 2 (hyperthreading) = 16 logical cores.)
 *  
 * Then if you have less than 8 logical cores, create the same number of data files as logical cores. 
 * If you have more than 8 logical cores, create 8 data files and then add more in chunks of 4 if you still see PFS contention. 
 * Make sure all the tempdb data files are the same size too.
 * [...]
 */

SELECT
    [owt].session_id,
    [owt].[exec_context_id],
    [owt].[wait_duration_ms],
    [owt].[wait_type],
    [owt].[blocking_session_id],
    [owt].[resource_description],
    CASE [owt].[wait_type]
        WHEN N'CXPACKET' THEN
            RIGHT ([owt].[resource_description],
            CHARINDEX (N'=', REVERSE ([owt].[resource_description])) - 1)
        ELSE NULL
    END AS [Node ID],
    es.[program_name]
    /* comment ou the next four lines to enhance compatability with older versions of SQL Server */
    ,[est].text,
    er.[database_id],
    [eqp].[query_plan],
    er.[cpu_time]
FROM sys.dm_os_waiting_tasks [owt]
INNER JOIN sys.dm_exec_sessions es ON [owt].session_id = es.session_id
/* comment out the next three lines to enhance compatability with older versions of SQL Server */
INNER JOIN sys.dm_exec_requests er ON es.session_id = er.session_id
OUTER APPLY sys.dm_exec_sql_text (er.sql_handle) [est]
OUTER APPLY sys.dm_exec_query_plan (er.plan_handle) [eqp]
WHERE
    es.[is_user_process] = 1
ORDER BY
    [owt].session_id,
    [owt].[exec_context_id];
GO
