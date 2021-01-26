/*
    05_failover_readiness.sql
    Run on: the primary replica.
    Is each secondary ready to take over? A replica is ready when it is connected
    and every database on it is SYNCHRONIZED and not suspended.
*/
SET NOCOUNT ON;

;WITH per_replica AS (
    SELECT  drs.group_id,
            drs.replica_id,
            COUNT(*) AS db_count,
            SUM(CASE WHEN drs.synchronization_state = 2 THEN 1 ELSE 0 END) AS synchronized_dbs,
            SUM(CASE WHEN drs.is_suspended = 1 THEN 1 ELSE 0 END) AS suspended_dbs
    FROM sys.dm_hadr_database_replica_states AS drs
    GROUP BY drs.group_id, drs.replica_id
)
SELECT  ag.name AS ag_name,
        ar.replica_server_name,
        ar.availability_mode_desc,
        ar.failover_mode_desc,
        ars.connected_state_desc,
        pr.db_count,
        pr.synchronized_dbs,
        pr.suspended_dbs,
        CASE WHEN ars.connected_state = 1
              AND pr.synchronized_dbs = pr.db_count
              AND pr.suspended_dbs = 0
             THEN N'READY' ELSE N'NOT READY' END AS failover_readiness
FROM sys.availability_groups AS ag
JOIN sys.availability_replicas AS ar ON ar.group_id = ag.group_id
JOIN sys.dm_hadr_availability_replica_states AS ars ON ars.replica_id = ar.replica_id
JOIN per_replica AS pr ON pr.replica_id = ar.replica_id
WHERE ars.role = 2                       -- secondaries only
ORDER BY ag.name, ar.replica_server_name;
