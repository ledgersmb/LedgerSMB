
-- The caching of the max_ac_id value was removed
-- in 1.6; now also remove the column.

-- We didn't remove the column in 1.6 in order for
-- the schema to remain backward compatible with
-- earlier 1.6 versions. Now, in 1.7, this change
-- will be in the 1.7.0 base schema.
ALTER TABLE cr_report
  DROP COLUMN max_ac_id;
