SELECT log_reuse_wait_desc, * FROM sys.databases

select dest.text, dest.objectid, sp.spid, sp.program_name, *
  FROM sys.sysprocesses as sp 
CROSS APPLY sys.dm_exec_sql_text(sp.sql_handle) AS dest
WHERE sp.spid IN (
    select blocked FROM sys.sysprocesses WHERE blocked != 0
    ) 
OR sp.spid IN (
    SELECT spid FROM sys.sysprocesses WHERE blocked != 0
    )

select dest.text, dest.objectid, sp.spid, sp.program_name, * 
from sys.sysprocesses as sp
cross apply sys.dm_exec_sql_text(sp.sql_handle) as dest 
order by cpu desc
--where nt_username = 'USERNAME' and sp.spid != @@spid
--where db_name(sp.dbid) = 'DB_NAME'
