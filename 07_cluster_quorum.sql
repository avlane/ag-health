/*
    07_cluster_quorum.sql
    Run on: any replica of an AG hosted on a Windows Server failover cluster.
    Returns no rows when the instance is not clustered (cluster type NONE or EXTERNAL).
*/
SET NOCOUNT ON;

SELECT  c.cluster_name,
        c.quorum_type_desc,
        c.quorum_state_desc
FROM sys.dm_hadr_cluster AS c;

SELECT  m.member_name,
        m.member_type_desc,
        m.member_state_desc,
        m.number_of_quorum_votes,
        SUM(m.number_of_quorum_votes) OVER () AS total_votes
FROM sys.dm_hadr_cluster_members AS m
ORDER BY m.member_name;
