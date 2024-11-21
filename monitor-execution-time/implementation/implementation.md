# Implementation

## Track query in progress

Add in environment variables `CLIENT_APPLICATION_NAME`.

Add in configuration `track_activity_query_size`.

Run idle query
```shell
psql --dbname $CONNECTION_STRING --command "SELECT pg_sleep(10)"
```

Check it appears
```postgresql
SELECT query, * FROM pg_stat_activity ssn
WHERE ssn.application_name = 'batch-queries-postgresql'
```

## Track query in debug mode

### Single query, from console

Activate `track_io_timing` in [postgresql.conf](configuration/postgresql.conf)

```postgresql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM foo WHERE bar = 45;
```

### All queries, in database log

https://www.postgresql.org/docs/current/auto-explain.html

Add `auto_explain` to `shared_preload_libraries`.

Activate extension
```shell
psql --dbname $CONNECTION_STRING_ADMIN --command "GRANT SET ON PARAMETER auto_explain.log_min_duration to \"user\";"
```

Add settings
```text
auto_explain.log_parameter_max_length = 10000
auto_explain.log_analyze = on
auto_explain.log_buffers = on
auto_explain.log_wal = on
auto_explain.log_timing = on
auto_explain.log_verbose = on
```

Activate it for the session.
```postgresql
SET auto_explain.log_min_duration = 0;
-- SET auto_explain.log_min_duration = '1s';
```

Run a long-query in the same session.
```postgresql
SELECT * FROM foo ORDER BY foo DESC LIMIT 3;
```

Check logs
```text
	Query Text: SELECT * FROM foo ORDER BY foo DESC LIMIT 3
	Limit  (cost=14977.03..14977.38 rows=3 width=32) (actual time=719.403..719.405 rows=3 loops=1)
	  Output: bar, foo.*
	  Buffers: shared hit=4425
	  ->  Gather Merge  (cost=14977.03..112206.12 rows=833334 width=32) (actual time=719.402..719.403 rows=3 loops=1)
	        Output: bar, foo.*
	        Workers Planned: 2
	        Workers Launched: 0
	        Buffers: shared hit=4425
	        ->  Sort  (cost=13977.01..15018.68 rows=416667 width=32) (actual time=719.401..719.401 rows=3 loops=1)
	              Output: bar, foo.*
	              Sort Key: foo.* DESC
	              Sort Method: top-N heapsort  Memory: 25kB
	              Buffers: shared hit=4425
	              ->  Parallel Seq Scan on public.foo  (cost=0.00..8591.67 rows=416667 width=32) (actual time=0.010..120.565 rows=1000000 loops=1)
	                    Output: bar, foo.*
	                    Buffers: shared hit=4425
	Query Identifier: 4152398976584522036

```

## Track executed queries

Activate extension
```shell
psql --dbname $CONNECTION_STRING_ADMIN --command "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;";
psql --dbname $CONNECTION_STRING_ADMIN --command "GRANT pg_monitor TO \"user\";";
```

Run a query
```postgresql
psql --dbname $CONNECTION_STRING --file generate-activity.sql
```

Then get results
```postgresql
SELECT 
    stt.query,
    stt.calls,
    stt.rows,
    'time:' head,
    TRUNC(stt.min_exec_time) min,
    TRUNC(stt.mean_exec_time) mean,
    TRUNC(stt.max_exec_time) max,
    stt.shared_blks_hit,
    stt.shared_blks_read,
    stt.shared_blks_written,
    stt.temp_blks_read,
    stt.wal_records    
FROM pg_stat_statements stt
WHERE stt.query ILIKE '%foo%'
ORDER BY max_exec_time DESC
```

## Execute many queries programmatically

Create dataset
```shell
psql --dbname $CONNECTION_STRING --file create-dataset.sql
```

Launch queries
```shell
pgbench --client=$CLIENTS --jobs=$JOBS --transactions=$TRANSACTIONS --no-vacuum --progress=5 --file=query-dataset.sql
```

You'll get
```shell
pgbench (14.13 (Ubuntu 14.13-0ubuntu0.22.04.1), server 17.0)
transaction type: query-dataset.sql
scaling factor: 1
query mode: simple
number of clients: 2
number of threads: 2
number of transactions per client: 4
number of transactions actually processed: 8/8
latency average = 6976.478 ms
initial connection time = 398.017 ms
tps = 0.286678 (without initial connection time)
```

Activity parameters:
- `client` : Number of clients simulated, that is, number of concurrent database sessions
- `transaction`: Number of transactions each client runs

Internal parameters:
- `job` : Number of worker threads within pgbench. Using more than one thread can be helpful on multi-CPU machines. Clients are distributed as evenly as possible among available threads.


https://www.postgresql.org/docs/current/pgbench.html

## More
If 100000000
Table size is 3Gb, smaller than cache - check stats (blocks_hit, etc..)
```postgresql
SELECT
    pg_size_pretty (pg_relation_size ('foo'))
```

## Limit cache size, tempfile, work_mem, maintenance
https://github.com/GradedJestRisk/db-training/blob/65d665373648a368f665650a5b7caa54adca919b/RDBMS/PostgreSQL/performance/memory/database-setup/postgresql.conf#L4-L4

## Auto-explain
https://github.com/GradedJestRisk/db-training/blob/65d665373648a368f665650a5b7caa54adca919b/RDBMS/PostgreSQL/performance/memory/database-setup/postgresql.conf#L4-L4


Overview on logging
https://www.tangramvision.com/blog/how-to-benchmark-postgresql-queries-well#pg_bench