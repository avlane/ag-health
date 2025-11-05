/*
    23_sample_column_descriptions.sql
    Documents the units of the sample columns as MS_Description extended
    properties so they show in SSMS and schema documentation tools.
*/
USE [DbaUtil];
GO

DECLARE @cols TABLE (column_name sysname, description nvarchar(200));
INSERT INTO @cols VALUES
    (N'log_send_queue_kb', N'Log not yet sent to the secondary, KB'),
    (N'log_send_rate_kb_per_sec', N'Log send rate, KB per second'),
    (N'redo_queue_kb', N'Log hardened but not yet redone, KB'),
    (N'redo_rate_kb_per_sec', N'Redo rate, KB per second'),
    (N'est_data_loss_seconds', N'Primary last commit time minus secondary last commit time, seconds'),
    (N'est_recovery_seconds', N'Redo queue divided by redo rate, seconds');

DECLARE @c sysname, @d nvarchar(200);
DECLARE col_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT column_name, description FROM @cols;
OPEN col_cursor;
FETCH NEXT FROM col_cursor INTO @c, @d;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description', N'SCHEMA', N'dbo',
                                                              N'TABLE', N'ag_health_samples', N'COLUMN', @c))
        EXEC sys.sp_addextendedproperty
             @name = N'MS_Description', @value = @d,
             @level0type = N'SCHEMA', @level0name = N'dbo',
             @level1type = N'TABLE',  @level1name = N'ag_health_samples',
             @level2type = N'COLUMN', @level2name = @c;

    FETCH NEXT FROM col_cursor INTO @c, @d;
END
CLOSE col_cursor;
DEALLOCATE col_cursor;
GO
