/*
    21_alert_check.sql
    Compares the most recent samples (last 10 minutes) with dbo.ag_health_thresholds
    and returns one row per breach. Wire the result into your alerting job.
*/
USE [DbaUtil];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.ag_health_thresholds', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ag_health_thresholds (
        metric     varchar(40) NOT NULL CONSTRAINT PK_ag_health_thresholds PRIMARY KEY,
        warn_value bigint NOT NULL,
        crit_value bigint NOT NULL,
        unit       varchar(20) NOT NULL
    );

    INSERT INTO dbo.ag_health_thresholds (metric, warn_value, crit_value, unit)
    VALUES ('est_data_loss_seconds', 30, 300, 'seconds'),
           ('est_recovery_seconds', 120, 600, 'seconds'),
           ('log_send_queue_kb', 512000, 2097152, 'KB'),
           ('redo_queue_kb', 512000, 2097152, 'KB');
END

;WITH latest AS (
    SELECT  s.*,
            ROW_NUMBER() OVER (PARTITION BY s.ag_name, s.replica_server_name, s.database_name
                               ORDER BY s.sample_time_utc DESC) AS rn
    FROM dbo.ag_health_samples AS s
    WHERE s.sample_time_utc >= DATEADD(MINUTE, -10, SYSUTCDATETIME())
)
SELECT  l.ag_name,
        l.replica_server_name,
        l.database_name,
        v.metric,
        v.metric_value,
        t.unit,
        CASE WHEN v.metric_value >= t.crit_value THEN N'CRITICAL' ELSE N'WARN' END AS severity
FROM latest AS l
CROSS APPLY (VALUES ('est_data_loss_seconds', CONVERT(bigint, l.est_data_loss_seconds)),
                    ('est_recovery_seconds', CONVERT(bigint, l.est_recovery_seconds)),
                    ('log_send_queue_kb', l.log_send_queue_kb),
                    ('redo_queue_kb', l.redo_queue_kb)) AS v(metric, metric_value)
JOIN dbo.ag_health_thresholds AS t ON t.metric = v.metric
WHERE l.rn = 1
  AND v.metric_value >= t.warn_value
ORDER BY severity, l.ag_name, l.database_name, v.metric;
