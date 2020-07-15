# SQL-Server-Scripts


<a name="header1"></a> 
![GitHub](https://img.shields.io/github/license/JohnKNess/SQL-Server-Scripts)
![GitHub](https://img.shields.io/github/issues-raw/JohnKNess/SQL-Server-Scripts)
![GitHub](https://img.shields.io/github/issues-pr-raw/JohnKNess/SQL-Server-Scripts)
![GitHub](https://img.shields.io/github/forks/JohnKNess/SQL-Server-Scripts)
![GitHub](https://img.shields.io/github/stars/JohnKNess/SQL-Server-Scripts)
![GitHub](https://img.shields.io/github/watchers/JohnKNess/SQL-Server-Scripts)


# Navigation

- [License](#license)
- [Others License](#others-license)
- [Purpose](#purpose)
- [Scripts](#scripts)
    - [ADMIN_1ST_Aid_1_Running_Tasks.sql](#admin_1st_aid_1_running_taskssql)
    - [ADMIN_2ND_AID_Check_Blocking_Quick.sql](#admin_2nd_aid_check_blocking_quicksql)
    - [ADMIN_Assign_DTS_Permissions.sql](#admin_assign_dts_permissionssql)
- [Stored Procedures](#stored-procedures)
    - [spdeletehistory.sql](#spedeletehistorysql)


## License

[The SQL-Server-Scripts use the GNU General Public License v3.0.](LICENSE)

## Others License

Some scripts are not my copyright or copyleft. If the scripts are the intellectual property of someone else, then the copyright/license is duely noted in the script/file/program.

## Purpose

The purpose of this repository it to enalbe me to find the scripts/procedures/programs I use most over and over again. I would also like to make these various scripts available to the community. 

## Scripts

Following is a list of scripts that may be of interest.

### [ADMIN_1ST_Aid_1_Running_Tasks.sql](ADMIN_1ST_Aid_1_Running_Tasks.sql)

The current script quickly checks the running tasks of a SQL Server instance. 

I've got a really good script coming soon, which retrieves various information based on the `LEFT JOIN`s used in the `JOIN` conditions. 

### [ADMIN_2ND_AID_Check_Blocking_Quick.sql](ADMIN_2ND_AID_Check_Blocking_Quick.sql)

This script quickly checks for blocks/blocking on a SQL Server instance.

### [ADMIN_Assign_DTS_Permissions.sql](ADMIN_Assign_DTS_Permissions.sql)

This script is a summary of permissions that can be assigend to SQL Server Logins (Windows Authenticated / Native) to facilitate the use of SSIS/DTS packages in a SQL Server instance.


## Stored Procedures

Following is a list of stored procedures that may be of interest.

### [spedeletehistory.sql](spedeletehistory.sql)

The stored procecdure I wrote here is a wrapper for the internal SQL Server stored procedure `sp_delete_backuphistory`. It uses `GET_DATE()` and `DATEADD()` to go back in time amd delete the backup history in lumps. 
The default is to go back 1080 days and delete the backup history in steps of 1 up until 180 days ago. 


[*Back to top*](#header1)



