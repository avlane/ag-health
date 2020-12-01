/*
    04_rpo_rto.sql
    Run on: the primary replica.
    Estimated data loss (RPO) and recovery time (RTO) per secondary database.
      est_data_loss_seconds : primary last_commit_time minus the secondary
                              last_commit_time (what a failover right now could lose)
      est_recovery_seconds  : redo_queue_size (KB) / redo_rate (KB/s), the time
                              the secondary needs to finish redo before it is online
    These are estimates: with no workload both commit times stop moving and the
    difference only shows the gap, not a growing loss.
*/
SET NOCOUNT ON;

SELECT  ag.name AS ag_name,
        ar.replica_server_name AS secondary_replica,
        DB_NAME(s.database_id) AS database_name,
        ar.availability_mode_desc,
        s.synchronization_state_desc,
        DATEDIFF(SECOND, s.last_commit_time, p.last_commit_time) AS est_data_loss_seconds,
        s.redo_queue_size / NULLIF(s.redo_rate, 0) AS est_recovery_seconds
FROM sys.dm_hadr_database_replica_states AS p
JOIN sys.dm_hadr_database_replica_states AS s
  ON s.group_id = p.group_id
 AND s.group_database_id = p.group_database_id
 AND s.is_primary_replica = 0
JOIN sys.availability_replicas AS ar ON ar.replica_id = s.replica_id
JOIN sys.availability_groups AS ag ON ag.group_id = s.group_id
WHERE p.is_primary_replica = 1
  AND p.is_local = 1
ORDER BY est_data_loss_seconds DESC;
