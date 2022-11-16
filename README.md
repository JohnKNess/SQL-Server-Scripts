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
    - [ADMIN_1ST_Aid_1_Running_Tasks_Extended.sql](#admin_1st_aid_1_running_tasks_extendedsql)
    - [ADMIN_2ND_AID_Check_Blocking_Quick.sql](#admin_2nd_aid_check_blocking_quicksql)
    - [ADMIN_Assign_DTS_Permissions.sql](#admin_assign_dts_permissionssql)
    - [ADMIN_Backup_Script_Multi_Database.sql](#admin_backup_script_multi_databasesql)
    - [ADMIN_Retrieve_Statistics_Info_Outdated_and_Update.sql](#admin_retrieve_statistics_info_outdated_and_updatesql)
    - [ADMIN_Blocking_Locking_Hierarchical.sql](#admin_blocking_locking_hierarchicalsql)
- [Stored Procedures](#stored-procedures)
    - [spdeletehistory.sql](#spdeletehistorysql)


## License

[The SQL-Server-Scripts use the GNU General Public License v3.0.](LICENSE)

## Others License

Some scripts are not my copyright or copyleft. If the scripts are the intellectual property of someone else, then the copyright/license is duely noted in the script/file/program.

## Purpose

The purpose of this repository it to enable me to find the scripts/procedures/programs I use most over and over again. I would also like to make these various scripts available to the community. 

## Scripts

Following is a list of scripts that may be of interest.

### [ADMIN_1ST_Aid_1_Running_Tasks.sql](ADMIN_1ST_Aid_1_Running_Tasks.sql)

The current script quickly checks the running tasks of a SQL Server instance. 

### [ADMIN_1ST_Aid_1_Running_Tasks_Extended.sql](ADMIN_1ST_Aid_1_Running_Tasks_Extended.sql)

Display a list of running tasks in a given SQL Server instance. Comment out any of the various LEFT elements to reduce the amount of informaiton displayed.

### [ADMIN_2ND_AID_Check_Blocking_Quick.sql](ADMIN_2ND_AID_Check_Blocking_Quick.sql)

This script quickly checks for blocks/blocking on a SQL Server instance.

### [ADMIN_Assign_DTS_Permissions.sql](ADMIN_Assign_DTS_Permissions.sql)

This script is a summary of permissions that can be assigend to SQL Server Logins (Windows Authenticated / Native) to facilitate the use of SSIS/DTS packages in a SQL Server instance.

### [ADMIN_Backup_Script_Multi_Database.sql](ADMIN_Backup_Script_Multi_Database.sql)

Backup script for multiple databases. Just when you need a simple script to dump one or more databases to a disk drive and don't want to install any other of the great scripts out there.

### [ADMIN_Retrieve_Statistics_Info_Outdated_and_Update.sql](ADMIN_Retrieve_Statistics_Info_Outdated_and_Update.sql)

Small non-parameterized statement to retrieve statistics that have become outdated and may or may not be triggered by SQL Server's "auto update statistics" algorithm.

#### [ADMIN_Blocking_Locking_Hierarchical.sql](ADMIN_Blocking_Locking_Hierarchical.sql)

A script that displays a list of blocked/locked SQL Server sessions.

[*Back to top*](#header1)

## Stored Procedures

Following is a list of stored procedures that may be of interest.

### [spdeletehistory.sql](spdeletehistory.sql)

The stored procecdure I wrote here is a wrapper for the internal SQL Server stored procedure `sp_delete_backuphistory`. It uses some basic parameters to go back in time amd delete the backup history in lumps. 
The pre-defined default is to go back 1080 days and delete the backup history in steps of 1 up until 180 days ago. 

The **pre-defined default values** are specified in the code itself and are:

    set @iDaysBackToStart_CONST = 1080
    set @iDaysToKeep_CONST = 180
    set @iDayStep_CONST = 1

These pre-defined default values should be modified before you create the procedure in your environment to meet your requirements. I set them as fail-safes.

The **basic run-time parameters** to be used are:

    @iDaysBackToStart int = 0
    @iDaysToKeep int = 0
    @iDayStep int = 0
    @iDebug int = 0 

You could run the script with the follwoing values:

    spdeletehistory @iDaysBackToStart=3000, @iDaysToKeep = 200, @iDayStep = 5

If you specify **run-time values that are smaller** than the pre-defined defaults (set during stored procedure creation) then you **will receive an error message**.






[*Back to top*](#header1)


2020-12-21 Switched master branch to main
2020-12-23 Simple change to allow commit
