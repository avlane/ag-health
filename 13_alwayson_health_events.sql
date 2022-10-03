/*
    13_alwayson_health_events.sql
    Run on: any replica.
    Reads the AlwaysOn_health Extended Events session files and lists role changes,
    lease expirations and the AG error messages that explain them.
*/
SET NOCOUNT ON;

-- The session files live in the instance log directory. Derive it from the error log
-- path so the script works for named instances, other versions and Linux.
DECLARE @errorlog nvarchar(260) = CONVERT(nvarchar(260), SERVERPROPERTY(N'ErrorLogFileName'));
DECLARE @sep nchar(1) = CASE WHEN @errorlog LIKE N'%/%' THEN N'/' ELSE N'\' END;
DECLARE @path nvarchar(300) =
    LEFT(@errorlog, LEN(@errorlog) - CHARINDEX(@sep, REVERSE(@errorlog)) + 1) + N'AlwaysOn_health*.xel';

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
WHERE ev.object_name <> N'error_reported'
   OR ev.d.value('(event/data[@name="error_number"]/value)[1]', 'int')
      IN (1480, 35201, 35202, 35206, 35264, 35265, 41142, 41144)
ORDER BY ev.timestamp_utc DESC;
