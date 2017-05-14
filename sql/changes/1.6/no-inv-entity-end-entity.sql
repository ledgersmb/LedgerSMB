

-- We have 2 changes. The one following this one, deletes the accounts
-- However, that may fail (due to the accounts still being referenced).
-- Therefore, we set the accounts to 'ended' on 01 Jan 1900 in a separate
-- transaction before removal. If removal fails, the entity at least
-- shouldn't be visible anymore.

UPDATE entity_credit_account
   SET enddate = '1900-01-01'::date
 WHERE entity_id = 0;
