# Implementation

## Start

```shell
docker compose up --renew-anon-volumes --force-recreate
```

## Connect

```shell
psql --dbname "host=localhost port=5432 dbname=database user=user password=password" --command "SELECT VERSION()"
```

## Healthcheck

Start container
```shell
docker compose up --detach --renew-anon-volumes --force-recreate --wait
```

Debug
```shell
docker inspect --format "{{json .State.Health }}" batch-queries-postgresql-postgresql-1 | jq
```

## Customize your instance

See environment variables in [docker-compose.yml](docker-compose.yml)

## Monitor execution time

### Manually

Create a table
```shell
direnv allow
echo $CONNECTION_STRING
psql --dbname $CONNECTION_STRING
psql --dbname $CONNECTION_STRING --command "CREATE TABLE foo(bar INTEGER);"
```

#### In psql

```shell
psql --dbname $CONNECTION_STRING
```

Use `timing`
```postgresql
\timing
INSERT INTO foo SELECT * FROM generate_series(1, 10000000);
Time: 7313,829 ms (00:07,314)
```

But it's time elapsed on server, better use `time`
```shell
time psql --dbname $CONNECTION_STRING --command "INSERT INTO foo SELECT * FROM generate_series(1, 10000000);"
```

And use `--file` option
```shell
time psql --dbname $CONNECTION_STRING --file load-data.sql
```

### In logs

Change instance configuration and restart :
- volume in [docker-compose.yml](docker-compose.yml)
- `log_min_duration_statement`, `log_min_error_statement`,  `log_statement` in [docker-compose.yml](configuration/postgresql.conf)

Get logs.
```shell
docker logs --follow batch-queries-postgresql-postgresql-1
```

Run query again.

You'll get 7 seconds.
```shell
psql --dbname $CONNECTION_STRING --command   0,04s user 0,00s system 0% cpu 7,047 total

2024-11-21 15:41:53.329 GMT [250] LOG:  statement: INSERT INTO foo SELECT * FROM generate_series(1, 10000000);
2024-11-21 15:42:00.337 GMT [250] LOG:  duration: 7007.450 ms
```

## Restrict resource usage

Use `docker stats` or `glances` to get real-time resource consumption.
```shell
docker stats
```

### Compose: CPU, RAM

See `deploy` section in [docker-compose.yml](docker-compose.yml).

Change `POSTGRESQL_CPU_COUNT` and `POSTGRESQL_TOTAL_MEMORY_SIZE` in [.env](.env) and restart.

You can also overwrite it on-the-fly when starting the container.
```shell
POSTGRESQL_TOTAL_MEMORY_SIZE=128m docker compose up --detach --renew-anon-volumes --force-recreate --wait
```

Run the query
```shell
time psql --dbname $CONNECTION_STRING --file load-data.sql
```

Execution time :
- 128m : 10s
- 512m : 5s

If you're running too low (50m), you'll get an error and your query will be killed
```shell
2024-11-21 15:58:42.107 GMT [146] LOG:  statement: INSERT INTO foo SELECT * FROM generate_series(1, 10000000);
2024-11-21 15:58:44.366 GMT [1] LOG:  server process (PID 146) was terminated by signal 9: Killed
```

### Docker: CPU, RAM; I/O

You can't limit I/O using compose
https://superuser.com/questions/1306172/limit-usage-of-disk-i-o-by-docker-container-using-compose

You'll need to use `docker`
https://docs.docker.com/reference/cli/docker/container/run/
```shell
docker run --rm                         \
  --env-file .env.docker                \
  --volume ./configuration:/bitnami/postgresql/conf \
  --publish 5432:5432                   \
  --memory 512m                         \
  --shm-size 256m                       \
  --cpus 1                              \
  --device-write-bps /dev/nvme0n1:50Mb  \
  --name postgresql                     \
  bitnami/postgresql:17
```

You can change the value on-the-fly for CPU and RAM (but not IO).
```shell
docker update --cpuset-cpus "7" postgresql
```

https://docs.docker.com/reference/cli/docker/container/update/

[Glances](https://github.com/nicolargo/glances) displays:
- IO speed: IOR/s IOW/s
- network speed: Rx/s Tx/s


### tempfile storage

In docker volume
```shell
docker volume create -d flocker -o size=20GB my-named-volume
```

In docker-compose
```yaml
volumes: 
  postgresql_tempfile: 
    # For details, see:
    # https://docs.docker.com/engine/reference/commandline/volume_create/#driver-specific-options
    driver: local
    driver_opts:
      o: "size=$TMPFS_SIZE"
      device: tmpfs
      type: tmpfs
```


## Explore fs (bonus)


Add to docker-compose.yml

```yaml
    volumes:
      - ./data:/bitnami/postgresql
```

```shell
mkdir data
chmod o+rw data
# Start container

# CLI
sudo su
ls -ltr data

# GUI
nautilus admin://$PATH_TO_VOLUME
```

When finished
```shell
sudo rm -rf data
```

### Data

Generate data
```postgresql
DROP TABLE foo;
CREATE TABLE foo(bar INTEGER);
INSERT INTO foo
SELECT * FROM generate_series(1, 1000);
```

Find their location
```postgresql
SHOW data_directory;
```

Get their size
```shell
sudo su
du -sh ./data/data/base/
```

Make them grow
```postgresql
INSERT INTO foo
SELECT * FROM generate_series(1, 10000000);
```

Find the specific files
```postgresql
SELECT pg_relation_filepath('foo');
```

```shell
ls -ltr ./data/data/base/5/24576*
-rw------- 1 1001 root    221184 nov.  21 15:14 ./data/data/base/5/24576_fsm
-rw------- 1 1001 root     32768 nov.  21 15:14 ./data/data/base/5/24576_vm
-rw------- 1 1001 root 804708352 nov.  21 15:16 ./data/data/base/5/24576
```

### WAL

Check file size
```shell
du -sh ./data/data/pg_wal/
401M	./data/data/pg_wal/
```

Make them grow
```postgresql
INSERT INTO foo
SELECT * FROM generate_series(1, 10000000);
```

Check file size
```shell
du -sh ./data/data/pg_wal/
401M	./data/data/pg_wal/
```

Size is limited
```postgresql
SHOW max_wal_size;
```

### Tempfiles

```shell
ls -ltr ./data/data/base/pgsql_tmp/
```

### Easiest way

```postgresql
SELECT pg_size_pretty (pg_total_relation_size ('foo'))
```
