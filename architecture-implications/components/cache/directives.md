# Directives

## Data should be loaded in cache, then evicted

Create a table foo with < 255 Mb of data (less cache) and check it is completely in the cache.

Create another table foobar with > 255Mb of data (more cache) and check it is completely in the cache.


## A SELECT query can force unwritten data (dirty buffer) to be written on the disk

You'll need to:
- disable bgwriter with `bgwriter_lru_maxpages` to 0
- disable checkpointer with `checkpoint_timeout` to 1d