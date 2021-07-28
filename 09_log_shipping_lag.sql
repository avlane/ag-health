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
        CASE WHEN DATEDIFF(MINUTE, p.last_backup_date_utc, SYSUTCDATETIME()) > p.backup_threshold
             THEN N'BEHIND' ELSE N'OK' END AS backup_status
FROM msdb.dbo.log_shipping_monitor_primary AS p
ORDER BY p.primary_database;
