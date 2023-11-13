/*
    run_all.sql
    Runs every check in order. From this folder, connected to the primary replica:

        sqlcmd -S SQLPROD01 -E -i run_all.sql -o ag_health.out

    Log shipping (09) reads msdb on the monitor server, so it reports nothing
    unless log shipping is configured on this instance.
*/
:r 00_dashboard.sql
:r 01_ag_overview.sql
:r 02_database_sync_state.sql
:r 03_queues_and_rates.sql
:r 04_rpo_rto.sql
:r 05_failover_readiness.sql
:r 06_listener_connectivity.sql
:r 07_cluster_quorum.sql
:r 08_seeding_progress.sql
:r 09_log_shipping_lag.sql
:r 10_distributed_ag.sql
:r 11_read_only_routing.sql
:r 12_backup_preference.sql
:r 13_alwayson_health_events.sql
