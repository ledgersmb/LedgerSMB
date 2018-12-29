

DROP SCHEMA IF EXISTS mc_migration_validation_data CASCADE;

CREATE SCHEMA mc_migration_validation_data;


CREATE TABLE mc_migration_validation_data.trial_balances AS
SELECT (select max(transdate) from acc_trans)::date as balance_date, *
  FROM trial_balance__generate(null, null, null, null,
                               'none', null, null, 't'::boolean,
                               't'::boolean);

alter table mc_migration_validation_data.trial_balances
   add primary key (balance_date, account_id);

INSERT INTO mc_migration_validation_data.trial_balances
SELECT cp.end_date, tb.*
  FROM account_checkpoint cp,
       trial_balance__generate((select max(end_date) from account_checkpoint c
                                 where c.end_date < cp.end_date),
                               cp.end_date, null, null,
                               'none', null, null, 't'::boolean,
                               't'::boolean) tb;


