
package mc_migration_checks;

use LedgerSMB::Database::ChangeChecks;

check q|Assert that the migration was succesfull by verifying trial balances|,
    query => q|CREATE TEMPORARY TABLE verify_mc_trial_balances AS
 SELECT (select max(transdate) from acc_trans)::date as balance_date, *
  FROM trial_balance__generate(null, null, null, null,
                               'none', null, null, 't'::boolean,
                               't'::boolean);

alter table verify_mc_trial_balances
   add primary key (balance_date, account_id);

INSERT INTO verify_mc_trial_balances
SELECT cp.end_date, tb.*
  FROM account_checkpoint cp,
       trial_balance__generate((select max(end_date) from account_checkpoint c
                                 where c.end_date < cp.end_date),
                               cp.end_date, null, null,
                               'none', null, null, 't'::boolean,
                               't'::boolean) tb;


SELECT coalesce(otb.balance_date, vtb.balance_date) as balance_date,
       coalesce(otb.account_id, vtb.account_id) as account_id,
       coalesce(otb.starting_balance,0) - coalesce(vtb.starting_balance,0) as starting_balance_diff,
       coalesce(otb.debits,0) - coalesce(vtb.debits,0) as debits_diff,
       coalesce(otb.credits,0) - coalesce(vtb.credits,0) as credits_diff,
       coalesce(otb.ending_balance,0) - coalesce(vtb.ending_balance,0) as ending_balance_diff
  FROM verify_trial_balances vtb
FULL OUTER JOIN mc_migration_validation_data.trial_balances otb
  ON vtb.balance_date = otb.balance_date AND vtb.account_id = otb.account_id
 WHERE (starting_balance_diff <> 0
        OR debits_diff <> 0
        OR credits_diff <> 0
        OR ending_balance_diff <> 0)
       AND NOT ((select value from defaults where setting_key = 'accept_mc') = 'yes')
  ORDER BY balance_date, account_id;
|,
    description => q|
The migration checks found differences between the original trial balances
and the migrated trial balances. The table below shows all non-matching
lines. To accept the differences and continue with the migration, click
the Accept button.

In case the migration has resulted in unacceptable differences,
please contact the developers on devel@lists.ledgersmb.org or
contact a commercial vendor as listed on
https://ledgersmb.org/content/commercial-support
|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;

        grid $rows,
            name => 'balance_diff',
            columns => [ qw( balance_date account_id starting_balance_diff
                         debits_diff credits_diff ending_balance_diff ) ],
            dropdowns => {
                account_id => dropdown_sql($dbh, q|select id as account_id, description from account|),
            };
        confirm accept => 'Accept';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm = 'accept') {
            # Cause the query above to return zero rows, indicating success
            # to the caller.
            $dbh->do(q{INSERT INTO defaults (setting_key, value) VALUES ('accept_mc', 'yes');});
        }
    };
