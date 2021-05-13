/*
    08_seeding_progress.sql
    Run on: the primary replica (and the secondary for the target side).
    Automatic seeding history and failures. Only replicas created with
    SEEDING_MODE = AUTOMATIC show up here.
*/
SET NOCOUNT ON;

SELECT  ag.name AS ag_name,
        adc.database_name,
        ar.replica_server_name AS remote_replica,
        ar.seeding_mode_desc,
        s.start_time,
        s.completion_time,
        s.is_source,
        s.current_state,
        s.performed_seeding,
        s.failure_state_desc,
        s.error_code,
        s.number_of_attempts
FROM sys.dm_hadr_automatic_seeding AS s
JOIN sys.availability_groups AS ag ON ag.group_id = s.ag_id
JOIN sys.availability_replicas AS ar ON ar.replica_id = s.ag_remote_replica_id
LEFT JOIN sys.availability_databases_cluster AS adc ON adc.group_database_id = s.ag_db_id
ORDER BY s.start_time DESC;
