BEGIN;

\echo This may fail on a fairly new database.  In these cases, failures and
\echo rollbacks are expected and normal.

alter table entity_credit_account drop cc;
alter table entity_credit_account drop bcc;

COMMIT;
