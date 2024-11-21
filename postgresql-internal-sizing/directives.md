# Directives

## Setup your local instance
Consider using PostgreSQL :
- 1Go memory ;
- 4 CPU;
- SSD ;
- for Datawarehouse.

Get configuration from [pgtune](https://pgtune.leopard.in.ua/).

Set size of :
- datafiles in cache: `shared buffers`
- process private memory chunk: `work_mem`
- PG internal process chunk: `maintenance_work_mem`

Compare to initial values.

## What does it mean ?

Memory:
- `shared_buffers`: datafiles in cache
- `effective_cache_size`: PostgreSQL cache + OS cache

Disk
- `random_page_cost` : cost to access a block of (4 for hard disks)
- `effective_io_concurrency` : capacity to return block from different local (2 for hard disks)

Process
- `max_connections` : how many queries can be run simultaneously
- `work_mem`: size chunk to join dataset, order and group them

Maintenance:
- `maintenance_work_mem`
- `max_worker_processes`
- `max_parallel_workers_per_gather`
- `max_parallel_workers`
- `max_parallel_maintenance_workers`

See "1.4 SERVEUR DE BASES DE DONNÉES" in `Dalibo PERF1`.