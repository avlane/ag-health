/*
    15_commit_latency_counters.sql
    Run on: the primary replica (the send-side counters are only active there).
    Counters ending in /sec are cumulative counts in sys.dm_os_performance_counters,
    so this takes two samples and reports the per-second difference.
      Flow Control Time (ms/sec): milliseconds per second the sender was throttled
      Bytes Sent to Replica/sec : bytes per second (shown in KB)
*/
SET NOCOUNT ON;

DECLARE @SampleSeconds int = 10;
DECLARE @delay varchar(8) = CONVERT(varchar(8), DATEADD(SECOND, @SampleSeconds, 0), 108);

IF OBJECT_ID(N'tempdb..#s1') IS NOT NULL DROP TABLE #s1;
IF OBJECT_ID(N'tempdb..#s2') IS NOT NULL DROP TABLE #s2;

SELECT RTRIM(pc.object_name) AS object_name, RTRIM(pc.counter_name) AS counter_name,
       RTRIM(pc.instance_name) AS instance_name, pc.cntr_value
INTO #s1
FROM sys.dm_os_performance_counters AS pc
WHERE (RTRIM(pc.object_name) LIKE N'%:Availability Replica' OR RTRIM(pc.object_name) LIKE N'%:Database Replica')
  AND RTRIM(pc.counter_name) IN (N'Flow Control Time (ms/sec)', N'Flow Control/sec',
                                 N'Bytes Sent to Replica/sec', N'Resent Messages/sec',
                                 N'Log Bytes Received/sec', N'Redone Bytes/sec');

WAITFOR DELAY @delay;

SELECT RTRIM(pc.object_name) AS object_name, RTRIM(pc.counter_name) AS counter_name,
       RTRIM(pc.instance_name) AS instance_name, pc.cntr_value
INTO #s2
FROM sys.dm_os_performance_counters AS pc
WHERE (RTRIM(pc.object_name) LIKE N'%:Availability Replica' OR RTRIM(pc.object_name) LIKE N'%:Database Replica')
  AND RTRIM(pc.counter_name) IN (N'Flow Control Time (ms/sec)', N'Flow Control/sec',
                                 N'Bytes Sent to Replica/sec', N'Resent Messages/sec',
                                 N'Log Bytes Received/sec', N'Redone Bytes/sec');

SELECT  b.object_name,
        b.counter_name,
        b.instance_name,
        (b.cntr_value - a.cntr_value) / @SampleSeconds AS per_second
FROM #s2 AS b
JOIN #s1 AS a
  ON a.object_name = b.object_name
 AND a.counter_name = b.counter_name
 AND a.instance_name = b.instance_name
ORDER BY b.object_name, b.counter_name, b.instance_name;
