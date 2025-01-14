/*
    17_sample_tables.sql
    Run once, on the replica that will collect samples, in a utility database.
    Change the database name below. Times are stored in UTC; sizes in KB and
    rates in KB per second, exactly as the DMVs report them.
*/
USE [DbaUtil];
GO

IF OBJECT_ID(N'dbo.ag_health_samples', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ag_health_samples (
        sample_id                 bigint IDENTITY(1, 1) NOT NULL
            CONSTRAINT PK_ag_health_samples PRIMARY KEY CLUSTERED,
        sample_time_utc           datetime2(0) NOT NULL
            CONSTRAINT DF_ag_health_samples_time DEFAULT (SYSUTCDATETIME()),
        ag_name                   sysname NOT NULL,
        replica_server_name       sysname NOT NULL,
        database_name             sysname NOT NULL,
        synchronization_state_desc nvarchar(60) NULL,
        is_suspended              bit NULL,
        log_send_queue_kb         bigint NULL,
        log_send_rate_kb_per_sec  bigint NULL,
        redo_queue_kb             bigint NULL,
        redo_rate_kb_per_sec      bigint NULL,
        est_data_loss_seconds     int NULL,
        est_recovery_seconds      int NULL
    );
END
GO
