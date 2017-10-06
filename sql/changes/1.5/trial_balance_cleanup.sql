BEGIN;

SET LOCAL client_min_messages=warning;
DROP TABLE IF EXISTS trial_balance__account_to_report;
DROP TABLE IF EXISTS trial_balance__heading_to_report;
DROP FUNCTION IF EXISTS trial_balance__list();
DROP TABLE IF EXISTS trial_balance;
RESET client_min_messages;

COMMIT;
