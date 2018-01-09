/* Clear an invalid password_duration settings,
 * which effectively sets 'infinity' as the password
 * expiry.
 * 
 * if current password_duration value is invalid, it
 * will do nothing other than prevent passwords
 * being changed on the system. There is therefore
 * no benefit in retaining the old value.
 */
UPDATE defaults
SET value = NULL
WHERE setting_key = 'password_duration' AND (
  value ~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$' OR
  value::numeric <= 0 OR
  value::numeric >= 3654
)


/* Add a constraint that enforces a valid
 * password duration and constrains its value
 * to a sane range.
 */
ALTER TABLE defaults
ADD CONSTRAINT defaults_password_duration_check
CHECK(
  setting_key != 'password_duration' OR
  value IS NULL OR
  value = '' OR
  (
    value ~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$' AND
    value::numeric > 0 AND
    value::numeric < 3654  /* abitrary maximum 10 years */
  )
);
