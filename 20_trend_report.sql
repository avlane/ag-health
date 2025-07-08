/*
    20_trend_report.sql
    Hourly worst values from the collected samples over the look-back window.
    Queues are shown in MB, estimates in seconds. Hours are UTC.
*/
USE [DbaUtil];
GO
SET NOCOUNT ON;

DECLARE @HoursBack int = 24;

SELECT  DATEADD(HOUR, DATEDIFF(HOUR, 0, s.sample_time_utc), 0) AS hour_utc,
        s.ag_name,
        s.replica_server_name,
        MAX(s.est_data_loss_seconds) AS max_est_data_loss_seconds,
        MAX(s.est_recovery_seconds) AS max_est_recovery_seconds,
        CONVERT(decimal(18, 1), MAX(s.log_send_queue_kb) / 1024.0) AS max_log_send_queue_mb,
        CONVERT(decimal(18, 1), MAX(s.redo_queue_kb) / 1024.0) AS max_redo_queue_mb,
        SUM(CASE WHEN s.is_suspended = 1 THEN 1 ELSE 0 END) AS suspended_samples
FROM dbo.ag_health_samples AS s
WHERE s.sample_time_utc >= DATEADD(HOUR, -@HoursBack, SYSUTCDATETIME())
GROUP BY DATEADD(HOUR, DATEDIFF(HOUR, 0, s.sample_time_utc), 0), s.ag_name, s.replica_server_name
ORDER BY hour_utc, s.ag_name, s.replica_server_name;

-- Narrow layout (one row per hour and metric) for charting tools.
SELECT  DATEADD(HOUR, DATEDIFF(HOUR, 0, s.sample_time_utc), 0) AS hour_utc,
        s.ag_name,
        v.metric,
        MAX(v.metric_value) AS max_value
FROM dbo.ag_health_samples AS s
CROSS APPLY (VALUES ('est_data_loss_seconds', CONVERT(bigint, s.est_data_loss_seconds)),
                    ('est_recovery_seconds', CONVERT(bigint, s.est_recovery_seconds)),
                    ('log_send_queue_kb', s.log_send_queue_kb),
                    ('redo_queue_kb', s.redo_queue_kb)) AS v(metric, metric_value)
WHERE s.sample_time_utc >= DATEADD(HOUR, -@HoursBack, SYSUTCDATETIME())
GROUP BY DATEADD(HOUR, DATEDIFF(HOUR, 0, s.sample_time_utc), 0), s.ag_name, v.metric
ORDER BY hour_utc, s.ag_name, v.metric;
