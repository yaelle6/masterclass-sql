# Directives

Start the container from [docker-compose](docker-compose.yml).

## Get container access

Connect to the container in terminal.

In container, get a database prompt (`psql`).

Get the database version.

## Get OS access

Get a database prompt from your terminal (`psql`).

[Use parameters](https://github.com/GradedJestRisk/db-training/wiki/CLI#connect) to make all connexion parameter explicit.

## Add healthcheck

Create a non-interactive shell command to check the database is up and running (returns 0 if OK).

Use this command to create a container healthcheck.

Create a command to start a detached container, waiting for healthcheck to succeed.

## Customize your instance

Specify in docker-compose :
- PostgreSQL version (use the last published)
- user : name and password
- database : name and port (exposed)

Use environment variables loaded from `env` file.

Bonus: store environment variable using direnv.

## Monitor execution time

### Create a query

Create a table.
```postgresql
CREATE TABLE foo(bar INTEGER);
```

Find a way to get the elapsed time of a massive data insertion.
```postgresql
INSERT INTO foo SELECT * FROM generate_series(1, 10000000);
```

You can run queries from command-line quickly this way.
```shell
export CONNECTION_STRING="host=<HOST_NAME> port=<PORT_NUMBER> dbname=<DATABASE_NAME> user=<USERNAME> password=<PASSWORD>";
psql --dbname $CONNECTION_STRING 
```

### Manually

How to get the elapsed time for the query ?

### In logs

#### Get configuration

##### From source
https://github.com/postgres/postgres/blob/master/src/backend/utils/misc/postgresql.conf.sample

##### From container

Find their location
```postgresql
SHOW config_file;
```

Then
```shell
docker cp postgresql:/opt/bitnami/postgresql/conf/postgresql.conf .
```

#### Modify it

Use volume
https://github.com/bitnami/containers/blob/main/bitnami/postgresql/README.md#configuration-file

## Restrict resource usage

Restrict:
- RAM to 512 Mo;
- CPU to 1;
- I/O to 50Mb/s ;
- tempfile storage to 1Gb;

https://docs.docker.com/engine/containers/resource_constraints/

## Explore fs (bonus)

Find how much space
- does a table data use
- does WAL use
- does tempfile use

https://www.postgresql.org/docs/current/storage-file-layout.html
