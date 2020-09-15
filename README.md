# ag-health

T-SQL scripts for checking the health of SQL Server Always On Availability Groups.
Run them on the primary replica unless a script says otherwise (a secondary only
reports its own local rows in the `sys.dm_hadr_*` DMVs).

## Scripts

| script | what it does |
|---|---|
| `01_ag_overview.sql` | groups, replicas, roles, connection and synchronization health |

## Units

DMV columns are used as documented, and converted in the output where noted:

* `log_send_queue_size`, `redo_queue_size`: KB
* `log_send_rate`, `redo_rate`: KB per second
* estimated times in these scripts are in seconds

Server names are fictional (`SQLPROD01`, `SQLPROD02`, `SQLDR02`).
