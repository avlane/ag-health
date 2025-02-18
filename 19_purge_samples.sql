/*
    19_purge_samples.sql
    Deletes samples older than the retention period, in small batches so the
    log and locks stay manageable.
*/
USE [DbaUtil];
GO
SET NOCOUNT ON;

DECLARE @RetentionDays int = 30;
DECLARE @cutoff datetime2(0) = DATEADD(DAY, -@RetentionDays, SYSUTCDATETIME());
DECLARE @rows int = 1;

WHILE @rows > 0
BEGIN
    DELETE TOP (10000) FROM dbo.ag_health_samples
    WHERE sample_time_utc < @cutoff;

    SET @rows = @@ROWCOUNT;
END
GO
