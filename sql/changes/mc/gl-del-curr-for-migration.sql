
-- Drop the column that we *only* needed to run the acc_trans migration.
ALTER TABLE gl DROP COLUMN curr;
