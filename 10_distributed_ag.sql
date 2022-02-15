/*
    10_distributed_ag.sql
    Run on: the primary replica of the global primary AG (the forwarder shows the
    secondary side). A distributed availability group has two AGs as its "replicas":
    in sys.availability_replicas, replica_server_name holds the member AG name and
    endpoint_url points at that AG listener or primary.
*/
SET NOCOUNT ON;

SELECT  ag.name AS distributed_ag,
        ar.replica_server_name AS member_ag,
        ar.endpoint_url,
        ar.availability_mode_desc,
        ar.failover_mode_desc,
        ar.seeding_mode_desc,
        ars.role_desc,
        ars.connected_state_desc,
        ars.synchronization_health_desc
FROM sys.availability_groups AS ag
JOIN sys.availability_replicas AS ar ON ar.group_id = ag.group_id
LEFT JOIN sys.dm_hadr_availability_replica_states AS ars ON ars.replica_id = ar.replica_id
WHERE ag.is_distributed = 1
ORDER BY ag.name, ar.replica_server_name;

-- Database level view of the distributed AG: queues in KB, rates in KB/s.
SELECT  ag.name AS distributed_ag,
        DB_NAME(drs.database_id) AS database_name,
        drs.is_primary_replica,
        drs.synchronization_state_desc,
        drs.log_send_queue_size AS log_send_queue_kb,
        drs.log_send_rate AS log_send_rate_kb_per_sec,
        drs.redo_queue_size AS redo_queue_kb,
        drs.redo_rate AS redo_rate_kb_per_sec,
        drs.last_commit_time
FROM sys.dm_hadr_database_replica_states AS drs
JOIN sys.availability_groups AS ag ON ag.group_id = drs.group_id
WHERE ag.is_distributed = 1
ORDER BY ag.name, database_name;
