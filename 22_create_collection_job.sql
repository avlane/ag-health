/*
    22_create_collection_job.sql
    Creates a SQL Server Agent job that runs the sample collector every minute.
    Run on each replica that can become primary; the procedure records nothing
    on a secondary. Edit @owner_login_name and the database name first.
*/
USE msdb;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = N'AG health sample')
BEGIN
    EXEC dbo.sp_add_job
         @job_name = N'AG health sample',
         @enabled = 1,
         @description = N'Records AG queue and estimate samples into DbaUtil.dbo.ag_health_samples.',
         @owner_login_name = N'sa';

    EXEC dbo.sp_add_jobstep
         @job_name = N'AG health sample',
         @step_name = N'Collect',
         @subsystem = N'TSQL',
         @database_name = N'DbaUtil',
         @command = N'EXEC dbo.usp_collect_ag_health_sample;';

    EXEC dbo.sp_add_jobschedule
         @job_name = N'AG health sample',
         @name = N'Every minute',
         @freq_type = 4,                 -- daily
         @freq_interval = 1,
         @freq_subday_type = 4,          -- minutes
         @freq_subday_interval = 1;

    EXEC dbo.sp_add_jobserver @job_name = N'AG health sample';
END
GO
