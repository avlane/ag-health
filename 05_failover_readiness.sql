/*
    05_failover_readiness.sql
    Run on: the primary replica.
    Is each secondary ready to take over? A synchronous-commit replica is ready
    when it is connected and every database on it is SYNCHRONIZED and not
    suspended. An asynchronous-commit replica is never safe for a planned
    failover: it can only be failed over with possible data loss.
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
        ISNULL(pr.db_count, 0) AS db_count,
        ISNULL(pr.synchronized_dbs, 0) AS synchronized_dbs,
        ISNULL(pr.suspended_dbs, 0) AS suspended_dbs,
        CASE WHEN ar.availability_mode = 4
             THEN N'NOT A FAILOVER TARGET: configuration-only replica (quorum vote only)'
             WHEN ars.connected_state = 0 OR pr.suspended_dbs > 0
             THEN N'NOT READY'
             WHEN ar.availability_mode = 0
             THEN N'FORCED ONLY: asynchronous commit, data loss possible'
             WHEN pr.synchronized_dbs < pr.db_count
             THEN N'NOT READY'
             WHEN ar.failover_mode = 0
             THEN N'READY: automatic failover, no data loss'
             ELSE N'READY: manual failover, no data loss'
        END AS failover_readiness
FROM sys.availability_groups AS ag
JOIN sys.availability_replicas AS ar ON ar.group_id = ag.group_id
JOIN sys.dm_hadr_availability_replica_states AS ars ON ars.replica_id = ar.replica_id
LEFT JOIN per_replica AS pr ON pr.replica_id = ar.replica_id
WHERE ars.role = 2                       -- secondaries only
ORDER BY ag.name, ar.replica_server_name;

-- Synchronous replicas required to commit (SQL Server 2017 and later). When fewer
-- healthy synchronous secondaries than this are available, commits on the primary wait.
SELECT  ag.name AS ag_name,
        ag.required_synchronized_secondaries_to_commit AS required_sync_secondaries,
        SUM(CASE WHEN ar.availability_mode = 1 AND ars.role = 2 AND ars.synchronization_health = 2
                 THEN 1 ELSE 0 END) AS healthy_sync_secondaries,
        CASE WHEN SUM(CASE WHEN ar.availability_mode = 1 AND ars.role = 2 AND ars.synchronization_health = 2
                           THEN 1 ELSE 0 END) < ag.required_synchronized_secondaries_to_commit
             THEN N'CHECK: commits on the primary will wait for a secondary'
             ELSE N'OK' END AS commit_status
FROM sys.availability_groups AS ag
JOIN sys.availability_replicas AS ar ON ar.group_id = ag.group_id
JOIN sys.dm_hadr_availability_replica_states AS ars ON ars.replica_id = ar.replica_id
GROUP BY ag.name, ag.required_synchronized_secondaries_to_commit
ORDER BY ag.name;
