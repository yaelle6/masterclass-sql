# Implementation

```text
# DB Version: 16
# OS Type: linux
# DB Type: dw
# Total Memory (RAM): 1 GB
# CPUs num: 4
# Data Storage: ssd

max_connections = 40
shared_buffers = 256MB
effective_cache_size = 768MB
maintenance_work_mem = 128MB
checkpoint_completion_target = 0.9
wal_buffers = 7864kB
default_statistics_target = 500
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 1638kB
huge_pages = off
min_wal_size = 4GB
max_wal_size = 16GB
max_worker_processes = 4
max_parallel_workers_per_gather = 2
max_parallel_workers = 4
max_parallel_maintenance_workers = 2
```

We'll use only these one on [postgresql.conf](configuration/postgresql.conf).
```text
max_connections = 40
shared_buffers = 256MB
effective_cache_size = 768MB
maintenance_work_mem = 128MB
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 1638kB
max_worker_processes = 4
max_parallel_workers_per_gather = 2
max_parallel_workers = 4
max_parallel_maintenance_workers = 2
```

You need to adjust in [Docker](.env)
```text
POSTGRESQL_SHARED_BUFFERS_SIZE=256m
POSTGRESQL_TOTAL_MEMORY_SIZE=1Gb
POSTGRESQL_CPU_COUNT=4
```
