/*
    16_dashboard_json.sql
    Run on: the primary replica.
    The per-replica summary as one JSON document (FOR JSON PATH, SQL Server 2016+),
    for a monitoring tool or a ticket attachment. Queues are in KB as the DMV
    reports them; field names carry the unit.
*/
SET NOCOUNT ON;

SELECT  ag.name AS [ag_name],
        ar.replica_server_name AS [replica],
        ars.role_desc AS [role],
        ars.connected_state_desc AS [connected_state],
        ars.synchronization_health_desc AS [synchronization_health],
        COUNT(drs.database_id) AS [database_count],
        SUM(CASE WHEN drs.is_suspended = 1 THEN 1 ELSE 0 END) AS [suspended_databases],
        MAX(drs.log_send_queue_size) AS [max_log_send_queue_kb],
        MAX(drs.redo_queue_size) AS [max_redo_queue_kb]
FROM sys.availability_groups AS ag
JOIN sys.availability_replicas AS ar ON ar.group_id = ag.group_id
LEFT JOIN sys.dm_hadr_availability_replica_states AS ars ON ars.replica_id = ar.replica_id
LEFT JOIN sys.dm_hadr_database_replica_states AS drs
       ON drs.replica_id = ar.replica_id AND drs.group_id = ar.group_id
GROUP BY ag.name, ar.replica_server_name, ars.role_desc, ars.connected_state_desc,
         ars.synchronization_health_desc
ORDER BY ag.name, ar.replica_server_name
FOR JSON PATH, ROOT('ag_health');
