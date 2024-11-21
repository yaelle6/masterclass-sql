# Implementation

Configure monitoring
```shell
psql --dbname $CONNECTION_STRING_ADMIN --file configure-monitoring.sql
```

## Dig into the cache

https://www.postgresql.org/docs/current/pgbuffercache.html

Activate extension
```shell
psql --dbname $CONNECTION_STRING_ADMIN --command "CREATE EXTENSION IF NOT EXISTS pg_buffercache;";
psql --dbname $CONNECTION_STRING_ADMIN --command "GRANT pg_monitor TO \"user\";";
```

Cache summary
```postgresql
SELECT 
    '(used, unused, dirty, pinned,average)',
    pg_buffercache_summary();
```

Cache on foo
```postgresql
SELECT
      b.*
FROM pg_class c
         INNER JOIN pg_buffercache b
                    ON b.relfilenode = c.relfilenode
         INNER JOIN pg_database d
                    ON b.reldatabase = d.oid
WHERE 1=1
  AND d.datname = 'database'
  AND c.relname = 'foo'
```

Table with most cache entries
```postgresql
SELECT
       c.relname table,
       count(*)  buffers_count,
       pg_size_pretty(count(*) * 1024 * 8) buffer_size
FROM pg_class c
         INNER JOIN pg_buffercache b
                    ON b.relfilenode = c.relfilenode
         INNER JOIN pg_database d
                    ON b.reldatabase = d.oid
WHERE 1=1
  AND d.datname = 'database'
  AND c.relname NOT LIKE 'pg_%'
GROUP BY c.relname
ORDER BY 2 DESC
LIMIT 100;
```

Create 'foo'
```shell
psql --dbname $CONNECTION_STRING --file create-dataset.sql
```

Check
- 'foo' is in the cache
- 'foo' fits completely into the cache

Get table size
```postgresql
SELECT pg_size_pretty( pg_total_relation_size('foo') );
```

Create another bigger dataset that will evict foo
```shell
psql --dbname $CONNECTION_STRING --file create-another-dataset.sql
```

Check 
- 'foo' is not longer in the cache
- 'foobar' does not take more than 255Mb (cache size)
- 'foobar' total size exceeds 255Mb

Get table size
```postgresql
SELECT pg_size_pretty( pg_total_relation_size('foobar') );
```

## A SELECT query can force unwritten data (dirty buffer) to be written on the disk

Reset stats
```postgresql
SELECT pg_stat_reset_shared('bgwriter');
```

Create 4 small tables < 64mb
```postgresql
DROP TABLE IF EXISTS foo_one;
DROP TABLE IF EXISTS foo_two;
DROP TABLE IF EXISTS foo_three;
DROP TABLE IF EXISTS foo_four;

CREATE TABLE foo_one( bar INTEGER );
CREATE TABLE foo_two( bar INTEGER );
CREATE TABLE foo_three( bar INTEGER );
CREATE TABLE foo_four( bar INTEGER );

INSERT INTO foo_one SELECT * FROM generate_series(1, 1000000);
INSERT INTO foo_two SELECT * FROM generate_series(1, 1000000);
INSERT INTO foo_three SELECT * FROM generate_series(1, 1000000);
INSERT INTO foo_four SELECT * FROM generate_series(1, 1000000);
```

```postgresql
SELECT pg_size_pretty( pg_total_relation_size('foo_one') );
```

Create foo
```postgresql
DROP TABLE IF EXISTS foo;
CREATE TABLE foo( bar INTEGER );

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO foo SELECT * FROM generate_series(1, 1000000);
```


Check all is dirty
```postgresql
SELECT
    b.isdirty, 
    count(1) buffer_count,
    pg_size_pretty(count(*) * 1024 * 8) buffer_size
FROM pg_class c
         INNER JOIN pg_buffercache b
                    ON b.relfilenode = c.relfilenode
         INNER JOIN pg_database d
                    ON b.reldatabase = d.oid
WHERE 1=1
  AND d.datname = 'database'
  AND c.relname = 'foo'
GROUP BY b.isdirty
```

```text
false,4,32 kB
true,4425,35 MB
```

Check nothing has been written
```postgresql
select * from pg_stat_bgwriter;
```

Select on another table to evict him, check it causes writes
```postgresql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM foo_one ORDER BY bar DESC;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM foo_two ORDER BY bar DESC;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM foo_three ORDER BY bar DESC;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM foo_four ORDER BY bar DESC;
```

```postgresql
SELECT
    c.relname,
    b.isdirty, 
    count(1) buffer_count,
    pg_size_pretty(count(*) * 1024 * 8) buffer_size
FROM pg_class c
         INNER JOIN pg_buffercache b
                    ON b.relfilenode = c.relfilenode
         INNER JOIN pg_database d
                    ON b.reldatabase = d.oid
WHERE 1=1
  AND d.datname = 'database'
  AND c.relname LIKE 'foo%'
GROUP BY c.relname, b.isdirty
ORDER BY relname
```

Create 4 small tables < 64mb
```postgresql
DROP TABLE IF EXISTS foo;

CREATE TABLE foo( bar INTEGER );

INSERT INTO foo SELECT * FROM generate_series(1, 1000000);
```

But less than 64 Mb...
> When a relation whose size exceeds one-quarter of the buffer pool size (shared_buffers/4) is scanned.
https://www.interdb.jp/pg/pgsql08/05.html

