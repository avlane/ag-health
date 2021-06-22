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


-- Seeds that are running right now. Times are UTC; sizes and rates are shown in MB.
SELECT  p.local_database_name,
        p.role_desc,
        p.remote_machine_name,
        CONVERT(decimal(18, 1), p.transferred_size_bytes / 1048576.0) AS transferred_mb,
        CONVERT(decimal(18, 1), p.database_size_bytes / 1048576.0) AS database_mb,
        CONVERT(decimal(5, 1), 100.0 * p.transferred_size_bytes / NULLIF(p.database_size_bytes, 0)) AS pct_done,
        CONVERT(decimal(18, 1), p.transfer_rate_bytes_per_second / 1048576.0) AS rate_mb_per_sec,
        p.is_compression_enabled,
        p.start_time_utc,
        p.estimate_time_complete_utc
FROM sys.dm_hadr_physical_seeding_stats AS p
ORDER BY p.start_time_utc DESC;
