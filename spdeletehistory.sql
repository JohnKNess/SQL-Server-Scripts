    use msdb
    go
    

    CREATE PROCEDURE [dbo].[spdeletehistory]
    /*
        spdeletehistory - Wrapper for sp_delete_backuphistory stored procedure
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
    */
    
    /*
    -- ==================================================================
    -- Author......:    hot2use / JohnKNess
    -- Date........:    11-Jul-2020
    -- Version.....:    1.3
    -- Server......:    [server name here]
    -- Database....:    msdb
    -- Name........:    spdeletehistory
    -- Owner.......:    dbo
    -- Table.......:    
    -- Type........:    Stored Procedure
    -- Description.:    Delete old backup history on a server
    -- History.....:    04-Jan-2006    1.0    First created
    --                  07-Dec-2005    1.1    Modified seperators
    --                  04-Jul-2006    1.2    Modified Text Output for return value
    --                                        Added Constants for defaults
    --                  25-Jan-2017    1.3    Slight modifications regarding comments
    --
    -- Editor......:    UltraEdit 11.10a (using Syntax Highlighting)
    --                    Tabstop Values = 4                    
    -- ==================================================================
    */
    
    
    
        /*input variables*/
        @iDaysBackToStart int = 0,
        @iDaysToKeep int = 0,
        @iDayStep int = 0,
        @iDebug int = 0
        
        /*output variables*/
        
    AS
    BEGIN
         /* Turn off double quotes for text strings */
        set quoted_identifier off
          /* Dont return the count for any statment */
        set nocount on
         /* debugging configuration */    
        declare @debug int
         /* debug settings
        1 = turn on debug information
        2 = turn off all possible outputs
        4 = turn on transaction handling
         e.g.: Adding an @iDebug paramter of 6 will... 
        ... turn on transaction handling (4) 
        ... turn off all possible output information (2)
         e.g.: Adding an @iDebug value of 1 will turn on all debugging information
        */ 
    
        set @debug = @iDebug
    
        /* day constants */
        declare @iDaysBackToStart_CONST int
        declare @iDaysToKeep_CONST int
        declare @iDayStep_CONST int
    
        /* constant settings
        set the defaults here instead of in the input variables
        it makes for easier changing, when comparing the default values in the code
        */
        set @iDaysBackToStart_CONST = 1080
        set @iDaysToKeep_CONST = 180
        set @iDayStep_CONST = 1
    
        if @iDaysBackToStart = 0
            BEGIN
                set @iDaysBackToStart = @iDaysBackToStart_CONST
            END
        
        if @iDaysToKeep = 0
            BEGIN
                set @iDaysToKeep = @iDaysToKeep_CONST
            END
        
        if @iDayStep = 0
            BEGIN
                set @iDayStep = @iDayStep_CONST
            END
        /*
        return values
        0 Successful execution. 
        1 Required parameter value not specified. 
        2 Invalid parameter value specified. 
        3 not defined
        4 not defined
        */
        declare @iRetVal int

        declare @dtDateToDelete datetime
        declare @dtCurrentDate datetime
        declare @dtStartDate datetime
        declare @dtStopDate datetime
        declare @vSQL nvarchar(2000)
        
        if @debug & 1 = 1  print 'Checking variables...'
        if (@iDaysToKeep < @iDaysToKeep_CONST) 
            BEGIN
                PRINT 'Invalid parameter value specified (1)'
                PRINT 'e.g. spdeletehistory @iDaysBackToStart = 1080, @iDaysToKeep = 180, @iDayStep = 1 '
                PRINT 'The default values are the above values'
                PRINT '@iDaysBackToStart must be >= ' + convert(varchar(20), @iDaysBackToStart_CONST) + ''
                PRINT '@iDaysToKeep must be >= ' + convert(varchar(20), @iDaysToKeep_CONST) + ''
                PRINT '@iDayStep must be > ' + convert(varchar(20), @iDayStep_CONST - 1) + ''
                PRINT ''
                RETURN(2)
            END
        else if (@iDaysToKeep < @iDaysToKeep_CONST) or (@iDaysBackToStart < @iDaysBackToStart_CONST)
            BEGIN
                PRINT 'Invalid parameter value specified (2)'
                PRINT 'e.g. spdeletehistory @iDaysBackToStart = 1080, @iDaysToKeep = 180, @iDayStep = 1 '
                PRINT 'The default values are the above values'
                PRINT '@iDaysBackToStart must be >= ' + convert(varchar(20), @iDaysBackToStart_CONST) + ''
                PRINT '@iDaysToKeep must be >= ' + convert(varchar(20), @iDaysToKeep_CONST) + ''
                PRINT '@iDayStep must be > ' + convert(varchar(20), @iDayStep_CONST - 1) + ''
                PRINT ''
                RETURN(2)
            END
        else
            BEGIN
                if @debug & 1 = 1  print 'Checking if just defaults have been used...'
                if (@iDaysToKeep = @iDaysToKeep_CONST) and (@iDayStep = @iDayStep_CONST) and (@iDaysBackToStart = @iDaysBackToStart_CONST)
                    BEGIN
                        if @debug & 2 <> 2 
                            BEGIN
                                PRINT ''
                                PRINT 'Running with default parameters'
                                PRINT ''
                                PRINT '@iDaysBackToStart ='  + convert(varchar(20), @iDaysBackToStart_CONST) + ''
                                PRINT '@iDaysToKeep = ' + convert(varchar(20), @iDaysToKeep_CONST) + ''
                                PRINT '@iDayStep = ' + convert(varchar(20), @iDayStep_CONST) + ''
                                PRINT ''
                            END
                    END
                -- if @debug & 1 = 1 
                if @debug & 1 = 1  print 'Settings date variables...'
                select @dtCurrentDate = getdate()
                if @debug & 1 = 1  print '@dtCurrentDate..: ' + convert(varchar(60), @dtCurrentDate, 20)
                select @dtStartDate = @dtCurrentDate - @iDaysBackToStart
                if @debug & 1 = 1  print '@dtStartDate....: ' + convert(varchar(60), @dtStartDate, 20)
                select @dtStopDate = @dtCurrentDate - @iDaysToKeep
                if @debug & 1 = 1  print '@dtStopDate.....: ' + convert(varchar(60), @dtStopDate, 20)
                select @dtDateToDelete = @dtStartDate
                if @debug & 1 = 1  print '@dtDateToDelete.: ' + convert(varchar(60), @dtDateToDelete, 20)
                
                if @debug & 1 = 1  print 'Starting to loop...'
                while @dtDateToDelete < @dtStopDate begin
                    
                    set @vSQL = 'msdb.dbo.sp_delete_backuphistory ''' + convert(varchar(60), @dtDateToDelete, 20) + ''''
                    if @debug & 1 = 1  print '@vSQL.........: ' + @vSQL
                    if @debug & 4 = 4
                        BEGIN
                            begin tran john
                        END
                    exec @iRetVal = sp_executesql @vSQL
                    if @iRetVal <> 0 
                        BEGIN
                            /* Turn on double quotes for text strings */
                            set quoted_identifier on
                            
                             /* Return the count for any statment */
                            set nocount off    
                            
                            /* If transactions have been turned on then rollback if failed */
                            if @debug & 4 = 4
                                BEGIN
                                    rollback tran john                        
                                END
    
                            /* If general output has not been turned off print output*/ 
                            if @debug & 2 <> 2 
                                BEGIN
                                    PRINT 'Return Value: ' + convert(varchar(100), @iRetVal) + ' at current time: ' + convert(varchar(20),getdate())
                                end
                            RETURN(@iRetVal)
                        END
                        
                    /* If transactions have been turned on then commit on success */
                    if @debug & 4 = 4
                        BEGIN
                            commit tran john
                        END
                        
                    /* If general output has not been turned off print output*/ 
                    if @debug & 2 <> 2 
                        BEGIN
                            PRINT 'Return Value: ' + convert(varchar(100), @iRetVal) + ' at current time: ' + convert(varchar(20),getdate())
                        end
                    /* Get next date to delte history data */                    
                    select @dtDateToDelete = @dtDateToDelete + @iDayStep
                end
            END
        /* Turn on double quotes for text strings */
        set quoted_identifier on
         /* Return the count for any statment */
        set nocount off    
        /* If general output has not been turned off print output*/ 
        if @debug & 2 <> 2 
            BEGIN
                print 'Finished.'
            END
        RETURN(0)
    END
    GO    
