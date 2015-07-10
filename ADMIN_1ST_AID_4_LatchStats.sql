/************************************************************
 * Code formatted by SoftTree SQL Assistant © v6.5.278
 * Time: 25.04.2014 13:57:23
 ************************************************************/

WITH [LATCHES] AS (
         SELECT latch_class,
                wait_time_ms / 1000.0   AS waits,
                waiting_requests_count  AS waitcount,
                100.0 * wait_time_ms / SUM(wait_time_ms) OVER() AS percentage,
                ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rownum
         FROM   sys.dm_os_latch_stats
         WHERE  latch_class NOT IN ('BUFFER')
     )

SELECT w1.latch_class AS latchclass,
CAST(w1.waits AS DECIMAL(14,2)) AS wait_s, 
w1.waitcount AS waitcount, 
CAST(w1.percentage AS DECIMAL(14,2)) AS Percentage,
CAST((w1.waits/w1.waitcount)AS DECIMAL(14,4)) AS avgWait_s
FROM   latches             AS w1
       INNER JOIN latches  AS w2
       ON w2.rownum <= w1.rownum
GROUP BY w1.rownum, w1.latch_class, 
w1.waits, w1.waitcount, w1.percentage
HAVING SUM(w2.percentage) - w1.percentage < 95;


                    
