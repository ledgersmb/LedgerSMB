
-- There's a bit of trickery here: the standard 'gl' table doesn't have
-- a 'curr' column. However, due to the fact that pre-change-checks are
-- *always* run before a change is applied (but never when it has already
-- been applied), the pre-change script creates the 'curr' column instead
-- of this script, so it can store the result of the user input for the
-- 'curr' values
-- However, when the user chooses not to run the upgrade checks (which
-- happens on schema creation (as the schema is empty anyway), we still
-- need to create said column:

ALTER TABLE gl ADD COLUMN IF NOT EXISTS curr char(3);


-- Note that the aa-migration pre-checks made sure that any missing
-- 'curr' values have been filled out by the user, in so far the
-- transactions included lines marked as fx transactions

-- Remaining lines thus must be base/default currency transactions


-- Note that I sure hope that *nobody* *ever* *in their right mind*
-- used this functionality; we should provide a way out to those who
-- did though.


UPDATE gl
   SET curr = (select value from defaults where setting_key = 'curr')
 WHERE curr IS NULL;
