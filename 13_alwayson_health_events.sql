/*
    13_alwayson_health_events.sql
    Run on: any replica.
    Reads the AlwaysOn_health Extended Events session files and lists role changes,
    lease expirations and the AG error messages that explain them.
*/
SET NOCOUNT ON;

DECLARE @path nvarchar(300) =
    N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Log\AlwaysOn_health*.xel';

;WITH ev AS (
    SELECT  x.object_name,
            x.timestamp_utc,
            CONVERT(xml, x.event_data) AS d
    FROM sys.fn_xe_file_target_read_file(@path, NULL, NULL, NULL) AS x
    WHERE x.object_name IN (N'availability_replica_state_change',
                            N'availability_group_lease_expired',
                            N'error_reported')
)
SELECT  ev.timestamp_utc,
        ev.object_name AS event_name,
        ev.d.value('(event/data[@name="availability_group_name"]/value)[1]', 'nvarchar(256)') AS ag_name,
        ev.d.value('(event/data[@name="availability_replica_name"]/value)[1]', 'nvarchar(256)') AS replica_name,
        ev.d.value('(event/data[@name="previous_state"]/text)[1]', 'nvarchar(60)') AS previous_state,
        ev.d.value('(event/data[@name="current_state"]/text)[1]', 'nvarchar(60)') AS current_state,
        ev.d.value('(event/data[@name="error_number"]/value)[1]', 'int') AS error_number,
        ev.d.value('(event/data[@name="message"]/value)[1]', 'nvarchar(max)') AS message
FROM ev
ORDER BY ev.timestamp_utc DESC;
