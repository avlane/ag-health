/*
    14_contained_ag.sql
    SQL Server 2022 and later only (sys.availability_groups.is_contained does not
    exist before that). Run on: any replica.
    Contained availability groups carry their own copies of master and msdb
    (named <ag>_master and <ag>_msdb) so logins and Agent jobs fail over with the AG.
*/
SET NOCOUNT ON;

SELECT  ag.name AS ag_name,
        ag.is_contained,
        ag.cluster_type_desc,
        ars.role_desc AS local_role,
        ars.synchronization_health_desc
FROM sys.availability_groups AS ag
LEFT JOIN sys.dm_hadr_availability_replica_states AS ars
       ON ars.group_id = ag.group_id AND ars.is_local = 1
WHERE ag.is_contained = 1
ORDER BY ag.name;
