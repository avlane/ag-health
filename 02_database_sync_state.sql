/*
    02_database_sync_state.sql
    Run on: the primary replica.
    Synchronization state of every database on every replica.
    synchronization_state: 0 not synchronizing, 1 synchronizing, 2 synchronized,
                           3 reverting, 4 initializing
*/
SET NOCOUNT ON;

SELECT  ag.name AS ag_name,
        ar.replica_server_name,
        DB_NAME(drs.database_id) AS database_name,
        drs.is_local,
        drs.synchronization_state_desc,
        drs.synchronization_health_desc,
        drs.database_state_desc,
        drs.is_suspended,
        drs.suspend_reason_desc,
        drs.last_sent_time,
        drs.last_received_time,
        drs.last_hardened_time,
        drs.last_redone_time,
        drs.last_commit_time
FROM sys.dm_hadr_database_replica_states AS drs
JOIN sys.availability_replicas AS ar
  ON ar.replica_id = drs.replica_id
 AND ar.group_id = drs.group_id
JOIN sys.availability_groups AS ag
  ON ag.group_id = drs.group_id
ORDER BY ag.name, database_name, ar.replica_server_name;
