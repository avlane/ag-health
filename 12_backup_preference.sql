/*
    12_backup_preference.sql
    Run on: each replica. Shows the AG backup preference, the backup priority of
    every replica, and whether THIS replica is the preferred backup replica for
    each of its availability databases right now.
*/
SET NOCOUNT ON;

SELECT  ag.name AS ag_name,
        ag.automated_backup_preference_desc,
        ar.replica_server_name,
        ar.backup_priority,              -- 0 = never back up here, 1..100 higher wins
        ars.role_desc
FROM sys.availability_groups AS ag
JOIN sys.availability_replicas AS ar ON ar.group_id = ag.group_id
LEFT JOIN sys.dm_hadr_availability_replica_states AS ars ON ars.replica_id = ar.replica_id
ORDER BY ag.name, ar.backup_priority DESC, ar.replica_server_name;

SELECT  ag.name AS ag_name,
        d.name AS database_name,
        sys.fn_hadr_backup_is_preferred_replica(d.name) AS this_replica_is_preferred_for_backup
FROM sys.availability_databases_cluster AS adc
JOIN sys.availability_groups AS ag ON ag.group_id = adc.group_id
JOIN sys.databases AS d ON d.name = adc.database_name
ORDER BY ag.name, d.name;
