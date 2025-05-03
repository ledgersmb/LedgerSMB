-- Our api and user interface enforce a validation constraint
-- on the format of a language code. The ui will fail to load and
-- display an error if a language code fails to match this format.
-- This adds an identical constraint to the database.
--
-- Given that the UI already enforces this constraint and the
-- initial values used to populate the languages table comply, this
-- is not expected to fail, unless the `languages` table has been
-- manually modified.

ALTER TABLE language
DROP CONSTRAINT IF EXISTS language_code_check;

ALTER TABLE language
ADD CONSTRAINT language_code_check
CHECK (code ~ '^[a-z]{2}(_[A-Z]{2})?$');
