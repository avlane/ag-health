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

The dashboard adapts to older versions. `14_contained_ag.sql` needs 2022.
