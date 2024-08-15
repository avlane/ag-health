/*
    09_log_shipping_lag.sql
    Run on: the log shipping monitor server (the primary when no separate monitor
    is configured). Thresholds in the monitor tables are in MINUTES.
*/
SET NOCOUNT ON;

SELECT  p.primary_server,
        p.primary_database,
        p.last_backup_file,
        p.last_backup_date_utc,
        DATEDIFF(MINUTE, p.last_backup_date_utc, SYSUTCDATETIME()) AS minutes_since_backup,
        p.backup_threshold AS backup_threshold_minutes,
        p.threshold_alert_enabled AS alert_enabled,
        CASE WHEN DATEDIFF(MINUTE, p.last_backup_date_utc, SYSUTCDATETIME()) > p.backup_threshold
             THEN N'BEHIND' ELSE N'OK' END AS backup_status
FROM msdb.dbo.log_shipping_monitor_primary AS p
ORDER BY p.primary_database;


-- Copy and restore side. last_restored_latency is in minutes (time between the
-- backup being taken and it being restored).
SELECT  s.secondary_server,
        s.secondary_database,
        s.primary_server,
        s.primary_database,
        s.last_copied_date_utc,
        s.last_restored_date_utc,
        DATEDIFF(MINUTE, s.last_restored_date_utc, SYSUTCDATETIME()) AS minutes_since_restore,
        s.last_restored_latency AS restore_latency_minutes,
        s.restore_threshold AS restore_threshold_minutes,
        s.threshold_alert_enabled AS alert_enabled,
        CASE WHEN DATEDIFF(MINUTE, s.last_restored_date_utc, SYSUTCDATETIME()) > s.restore_threshold
             THEN N'BEHIND' ELSE N'OK' END AS restore_status
FROM msdb.dbo.log_shipping_monitor_secondary AS s
ORDER BY s.secondary_database;
