/*
    11_read_only_routing.sql
    Run on: any replica.
    Read-only routing lists: for each replica, which replicas it routes
    ApplicationIntent=ReadOnly connections to, in priority order (1 = first choice).
*/
SET NOCOUNT ON;

SELECT  ag.name AS ag_name,
        ar.replica_server_name AS routed_from_when_primary,
        ar.primary_role_allow_connections_desc,
        rl.routing_priority,
        ro.replica_server_name AS routed_to,
        ro.read_only_routing_url,
        ro.secondary_role_allow_connections_desc
FROM sys.availability_read_only_routing_lists AS rl
JOIN sys.availability_replicas AS ar ON ar.replica_id = rl.replica_id
JOIN sys.availability_replicas AS ro ON ro.replica_id = rl.read_only_replica_id
JOIN sys.availability_groups AS ag ON ag.group_id = ar.group_id
ORDER BY ag.name, ar.replica_server_name, rl.routing_priority;
