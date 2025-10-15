/*
    18_collect_samples.sql
    Creates dbo.usp_collect_ag_health_sample in the utility database. Run it on
    the primary on a schedule (see 22_create_collection_job.sql). One row per
    secondary database; the estimates use the same formulas as 04_rpo_rto.sql.
*/
USE [DbaUtil];
GO

CREATE OR ALTER PROCEDURE dbo.usp_collect_ag_health_sample
AS
BEGIN
    SET NOCOUNT ON;

    -- Nothing to record unless this replica is the primary of at least one AG database.
    IF NOT EXISTS (SELECT 1 FROM sys.dm_hadr_database_replica_states
                   WHERE is_local = 1 AND is_primary_replica = 1)
        RETURN;

    INSERT INTO dbo.ag_health_samples
           (ag_name, replica_server_name, database_name, synchronization_state_desc, is_suspended,
            log_send_queue_kb, log_send_rate_kb_per_sec, redo_queue_kb, redo_rate_kb_per_sec,
            est_data_loss_seconds, est_recovery_seconds)
    SELECT  ag.name,
            ar.replica_server_name,
            DB_NAME(s.database_id),
            s.synchronization_state_desc,
            s.is_suspended,
            s.log_send_queue_size,
            s.log_send_rate,
            s.redo_queue_size,
            s.redo_rate,
            DATEDIFF(SECOND, s.last_commit_time, p.last_commit_time),
            TRY_CONVERT(int, s.redo_queue_size / NULLIF(s.redo_rate, 0))
    FROM sys.dm_hadr_database_replica_states AS p
    JOIN sys.dm_hadr_database_replica_states AS s
      ON s.group_id = p.group_id
     AND s.group_database_id = p.group_database_id
     AND s.is_primary_replica = 0
    JOIN sys.availability_replicas AS ar ON ar.replica_id = s.replica_id
    JOIN sys.availability_groups AS ag ON ag.group_id = s.group_id
    WHERE p.is_primary_replica = 1
      AND p.is_local = 1;

    -- Log shipping lag, when this instance is a log shipping monitor.
    INSERT INTO dbo.log_shipping_samples (side, server_name, database_name, minutes_behind, threshold_minutes)
    SELECT 'P', lp.primary_server, lp.primary_database,
           DATEDIFF(MINUTE, lp.last_backup_date_utc, SYSUTCDATETIME()), lp.backup_threshold
    FROM msdb.dbo.log_shipping_monitor_primary AS lp
    UNION ALL
    SELECT 'S', ls.secondary_server, ls.secondary_database,
           DATEDIFF(MINUTE, ls.last_restored_date_utc, SYSUTCDATETIME()), ls.restore_threshold
    FROM msdb.dbo.log_shipping_monitor_secondary AS ls;
END
GO
