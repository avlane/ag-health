/*
    03_queues_and_rates.sql
    Run on: the primary replica.
    Log send queue = log on the primary not yet sent to the secondary.
    Redo queue     = log hardened on the secondary but not yet redone.
    DMV units: queue sizes are KB, rates are KB per second. Output shows MB.
*/
SET NOCOUNT ON;

SELECT  ag.name AS ag_name,
        ar.replica_server_name,
        DB_NAME(drs.database_id) AS database_name,
        drs.synchronization_state_desc,
        CONVERT(decimal(18, 1), drs.log_send_queue_size / 1024.0) AS log_send_queue_mb,
        drs.log_send_rate AS log_send_rate_kb_per_sec,
        CONVERT(decimal(18, 1), drs.redo_queue_size / 1024.0) AS redo_queue_mb,
        drs.redo_rate AS redo_rate_kb_per_sec
FROM sys.dm_hadr_database_replica_states AS drs
JOIN sys.availability_replicas AS ar
  ON ar.replica_id = drs.replica_id
 AND ar.group_id = drs.group_id
JOIN sys.availability_groups AS ag
  ON ag.group_id = drs.group_id
WHERE drs.is_local = 0           -- secondary rows as seen from the primary
ORDER BY drs.redo_queue_size DESC;
