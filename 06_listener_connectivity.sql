/*
    06_listener_connectivity.sql
    Run on: any replica.
    Listener name, port and state of each listener IP address.
    state_desc: ONLINE, OFFLINE, FAILED, ... (as reported by the cluster)
*/
SET NOCOUNT ON;

SELECT  ag.name AS ag_name,
        l.dns_name,
        l.port,
        l.is_conformant,
        lip.ip_address,
        lip.ip_subnet_mask,
        lip.network_subnet_ip,
        lip.state_desc
FROM sys.availability_group_listeners AS l
JOIN sys.availability_groups AS ag ON ag.group_id = l.group_id
JOIN sys.availability_group_listener_ip_addresses AS lip ON lip.listener_id = l.listener_id
ORDER BY ag.name, l.dns_name, lip.ip_address;
