# ag-health

T-SQL scripts for checking the health of SQL Server Always On Availability Groups.
Run them on the primary replica unless a script says otherwise (a secondary only
reports its own local rows in the `sys.dm_hadr_*` DMVs).

## Scripts

| script | what it does |
|---|---|
| `00_dashboard.sql` | one row per replica with health, suspended databases and worst queues |
| `01_ag_overview.sql` | groups, replicas, roles, connection and synchronization health |
| `02_database_sync_state.sql` | synchronization state of every database on every replica |
| `03_queues_and_rates.sql` | log send and redo queues (MB) with rates and drain time |
| `04_rpo_rto.sql` | estimated data loss and recovery time per secondary database |
| `05_failover_readiness.sql` | which secondaries could take over, with or without data loss |
| `06_listener_connectivity.sql` | listener names, ports and IP address state |
| `07_cluster_quorum.sql` | WSFC quorum state and member votes |
| `08_seeding_progress.sql` | automatic seeding history and running seeds |
| `09_log_shipping_lag.sql` | log shipping backup, copy and restore lag |
| `10_distributed_ag.sql` | distributed availability group members and database state |
| `11_read_only_routing.sql` | read-only routing lists |
| `12_backup_preference.sql` | backup preference, priorities and preferred replica |
| `13_alwayson_health_events.sql` | role changes, lease expirations and AG errors from `AlwaysOn_health` |
| `14_contained_ag.sql` | contained AGs and their system databases (2022 and later) |
| `15_commit_latency_counters.sql` | flow control, send rates and average synchronous commit delay |
| `16_dashboard_json.sql` | the per-replica summary as one JSON document |
| `17_sample_tables.sql` | tables for collected AG and log shipping samples (utility database) |
| `18_collect_samples.sql` | procedure that records one sample per secondary database |
| `19_purge_samples.sql` | batched purge of old samples |
| `20_trend_report.sql` | hourly worst queue and estimate values from the samples |
| `21_alert_check.sql` | threshold table and breaches in the last 10 minutes |
| `22_create_collection_job.sql` | Agent job that runs the collector every minute |

## Units

DMV columns are used as documented, and converted in the output where noted:

* `log_send_queue_size`, `redo_queue_size`: KB
* `log_send_rate`, `redo_rate`: KB per second
* estimated times in these scripts are in seconds

Server names are fictional (`SQLPROD01`, `SQLPROD02`, `SQLDR02`).

## Sample output

`04_rpo_rto.sql`

```
ag_name   secondary_replica availability_mode_desc synchronization_state_desc est_data_loss_seconds est_recovery_seconds
--------- ----------------- ---------------------- -------------------------- --------------------- --------------------
AG_Sales  SQLDR02           ASYNCHRONOUS_COMMIT    SYNCHRONIZING              12                    4
AG_Sales  SQLPROD02         SYNCHRONOUS_COMMIT     SYNCHRONIZED               0                     0
```

`05_failover_readiness.sql`

```
ag_name   replica_server_name availability_mode_desc failover_mode_desc connected_state_desc db_count synchronized_dbs suspended_dbs failover_readiness
--------- ------------------- ---------------------- ------------------ -------------------- -------- ---------------- ------------- ------------------------------------------------
AG_Sales  SQLPROD02           SYNCHRONOUS_COMMIT     AUTOMATIC          CONNECTED            12       12               0             READY: automatic failover, no data loss
AG_Sales  SQLDR02             ASYNCHRONOUS_COMMIT    MANUAL             CONNECTED            12       11               0             FORCED ONLY: asynchronous commit, data loss possible
```

## SQL Server versions

| feature | first version |
|---|---|
| `sys.dm_hadr_*` database and replica state, listeners | 2012 |
| `is_primary_replica` in `dm_hadr_database_replica_states` | 2014 |
| automatic seeding DMVs, `secondary_lag_seconds`, distributed AGs | 2016 |
| `cluster_type_desc`, configuration-only replicas | 2017 |
| contained AGs (`is_contained`) | 2022 |

The scripts need SQL Server 2017 or later (`cluster_type_desc` and
`required_synchronized_secondaries_to_commit`). The dashboard adapts to the
contained AG column that only 2022 has. `14_contained_ag.sql` needs 2022.

`00_dashboard.sql`

```
ag_name  is_contained replica_server_name role_desc connected_state_desc synchronization_health_desc db_count synchronized_dbs suspended_dbs max_log_send_queue_mb max_redo_queue_mb
-------- ------------ ------------------- --------- -------------------- --------------------------- -------- ---------------- ------------- --------------------- -----------------
AG_Sales 0            SQLPROD01           PRIMARY   CONNECTED            HEALTHY                     12       12               0             NULL                  NULL
AG_Sales 0            SQLPROD02           SECONDARY CONNECTED            HEALTHY                     12       12               0             0.0                   0.2
AG_Sales 0            SQLDR02             SECONDARY CONNECTED            PARTIALLY_HEALTHY           12       11               0             48.7                  3.9
```

## Permissions

* `VIEW SERVER STATE` for the `sys.dm_hadr_*` DMVs, performance counters and the
  `AlwaysOn_health` files (on SQL Server 2022 `VIEW SERVER PERFORMANCE STATE` is
  the narrower permission for the DMVs)
* `VIEW ANY DEFINITION` to read the availability group catalog views
* `db_datareader` in `msdb` for the log shipping monitor tables
