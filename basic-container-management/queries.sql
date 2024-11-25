CREATE TABLE IF NOT EXISTS numbers(bar integer);
INSERT INTO numbers SELECT * FROM generate_series(1, 10000000);
SELECT COUNT(*) FROM numbers;

-- INSERT INTO numbers SELECT * FROM generate_series(1, 10000000);
