/*
    00_dashboard.sql
    Run on: the primary replica.
    One row per replica: role, connection, health, and the worst queue and
    suspension state across its databases. Queues are converted from KB to MB.
*/
SET NOCOUNT ON;

SELECT  ag.name AS ag_name,
        ar.replica_server_name,
        ars.role_desc,
        ar.availability_mode_desc,
        ar.failover_mode_desc,
        ars.connected_state_desc,
        ars.synchronization_health_desc,
        COUNT(drs.database_id) AS db_count,
        SUM(CASE WHEN drs.synchronization_state = 2 THEN 1 ELSE 0 END) AS synchronized_dbs,
        SUM(CASE WHEN drs.is_suspended = 1 THEN 1 ELSE 0 END) AS suspended_dbs,
        CONVERT(decimal(18, 1), MAX(drs.log_send_queue_size) / 1024.0) AS max_log_send_queue_mb,
        CONVERT(decimal(18, 1), MAX(drs.redo_queue_size) / 1024.0) AS max_redo_queue_mb
FROM sys.availability_groups AS ag
JOIN sys.availability_replicas AS ar ON ar.group_id = ag.group_id
LEFT JOIN sys.dm_hadr_availability_replica_states AS ars ON ars.replica_id = ar.replica_id
LEFT JOIN sys.dm_hadr_database_replica_states AS drs
       ON drs.replica_id = ar.replica_id AND drs.group_id = ar.group_id
GROUP BY ag.name, ar.replica_server_name, ars.role_desc, ar.availability_mode_desc,
         ar.failover_mode_desc, ars.connected_state_desc, ars.synchronization_health_desc
ORDER BY ag.name, ars.role_desc, ar.replica_server_name;
