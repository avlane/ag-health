/*
    15_commit_latency_counters.sql
    Run on: any replica.
    Current values of the Availability Replica and Database Replica performance
    counters. Counters ending in /sec are cumulative in this DMV, so a single
    read is not a rate; see the sampled version of this script.
*/
SET NOCOUNT ON;

SELECT  RTRIM(pc.object_name)   AS object_name,
        RTRIM(pc.counter_name)  AS counter_name,
        RTRIM(pc.instance_name) AS instance_name,
        pc.cntr_value
FROM sys.dm_os_performance_counters AS pc
WHERE RTRIM(pc.object_name) LIKE N'%:Availability Replica'
   OR RTRIM(pc.object_name) LIKE N'%:Database Replica'
ORDER BY object_name, counter_name, instance_name;
