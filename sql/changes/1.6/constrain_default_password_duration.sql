-- Clear an invalid password_duration setting,
-- which prevents user passwords from being changed.
--
-- Bad values are replaced with NULL, which sets
-- 'infinity' as the password expiry for future
-- password changes.
--
-- There is no benefit in retaining the old, bad
-- values as they do nothing other than prevent
-- passwords being changed.

UPDATE defaults
SET value = NULL
WHERE setting_key = 'password_duration' AND (
  value !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$' OR
  value::numeric <= 0 OR
  value::numeric >= 3654
);


-- Drop existing constraint if this change has
-- previously been applied.
ALTER TABLE defaults
DROP CONSTRAINT IF EXISTS defaults_password_duration_check;


-- Add a constraint that enforces a valid
-- password duration and constrains its value
-- to a sane range.
ALTER TABLE defaults
ADD CONSTRAINT defaults_password_duration_check
CHECK(
  setting_key != 'password_duration' OR
  value IS NULL OR
  value = '' OR
  (
    value ~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$' AND
    value::numeric > 0 AND
    value::numeric < 3654  -- abitrary maximum 10 years
  )
);
