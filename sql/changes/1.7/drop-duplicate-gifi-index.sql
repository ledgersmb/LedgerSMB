-- There were two indexes on the gifi.accno column,
-- one being the primary key, the other a unique index.
-- As primary key implies unique, the unique index is not needed.
DROP INDEX IF EXISTS gifi_accno_key;
