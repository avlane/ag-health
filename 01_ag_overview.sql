/*
    01_ag_overview.sql
    Run on: the primary replica. A secondary only returns its own state row.
    One row per replica of every availability group.
*/
SET NOCOUNT ON;

SELECT  ag.name AS ag_name,
        ar.replica_server_name,
        ars.role_desc,
        ar.availability_mode_desc,
        ar.failover_mode_desc,
        ars.connected_state_desc,
        ars.operational_state_desc,
        ars.synchronization_health_desc,
        ars.last_connect_error_number,
        ars.last_connect_error_description,
        ars.last_connect_error_timestamp,
        ars.is_local
FROM sys.availability_groups AS ag
JOIN sys.availability_replicas AS ar
  ON ar.group_id = ag.group_id
LEFT JOIN sys.dm_hadr_availability_replica_states AS ars
  ON ars.replica_id = ar.replica_id
 AND ars.group_id = ar.group_id
ORDER BY ag.name, ars.role, ar.replica_server_name;
