
package mc_migration_checks;

use LedgerSMB::Database::ChangeChecks;

check q|Assert that the migration was succesfull by verifying trial balances|,
    # the SQL below contains pipe characters; use an exclamation mark as
    # the delimiter instead.
    query => q!
-- creating in pg_temp is similar to "CREATE TEMPORARY"
-- except that the latter doesn't exist for types
create type pg_temp.tb_row AS (
   account_id int,
   account_number text,
   account_desc text,
   gifi_accno   text,
   starting_balance numeric,
   debits numeric,
   credits numeric,
   ending_balance numeric,
   ending_balance_debit numeric,
   ending_balance_credit numeric
);

-- pg_temp.trial_balance__generate is a simple copy
-- of the trial_balance module's function. It has much more
-- functionality than we need, but it's tested and refacting
-- might break the code in unexpected ways. We're copying the
-- function because in new some schemas (new, migrated from
-- other software), it will not exist.

-- NOTE this is /not/ the same function as in
-- create-migration-validation-data.sql ; this here is the /post/-MC
-- version whereas the one in create-* is the /pre/-MC version
CREATE OR REPLACE FUNCTION pg_temp.trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[], in_balance_sign int,
 in_all_accounts boolean, in_approved boolean)
returns setof tb_row AS
$$
DECLARE
        out_row         tb_row;
        t_roll_forward  date;
        t_cp            account_checkpoint;
        ignore_trans    int[];
        t_start_date    date;
        t_end_date      date;
        t_balance_sign  int;
BEGIN
    IF in_balance_sign IS NULL OR in_balance_sign = 0 THEN
       t_balance_sign = null;
    ELSIF in_balance_sign = -1 OR in_balance_sign = 1 THEN
       t_balance_sign = in_balance_sign;
    ELSE
       RAISE EXCEPTION 'Invalid Balance Type';
    END IF;

    IF in_from_date IS NULL AND in_ignore_yearend = 'none' THEN
       SELECT max(end_date) INTO t_roll_forward
         FROM account_checkpoint;
    ELSIF in_from_date IS NULL AND in_ignore_yearend = 'last' THEN
       SELECT max(end_date) INTO t_roll_forward
         FROM account_checkpoint
        WHERE end_date < (select max(gl.transdate)
                            FROM gl JOIN yearend y ON y.trans_id = gl.id
                           WHERE y.transdate < coalesce(in_to_date, gl.transdate)
                         );
    ELSIF in_from_date IS NULL THEN
       SELECT min(transdate) - 1 INTO t_roll_forward
         FROM (select min(transdate) as transdate from ar
                union ALL
               select min(transdate) from ap
                union all
               select min(transdate) from gl
                union all
               select min(transdate) from acc_trans) gl;

    ELSE
      SELECT max(end_date) INTO t_roll_forward
         FROM account_checkpoint
        WHERE end_date < in_from_date;
    END IF;

    IF t_roll_forward IS NULL
       OR array_upper(in_business_units, 1) > 0
    THEN
       SELECT min(transdate) - '1 day'::interval
         INTO t_roll_forward
         FROM acc_trans;
    END IF;

    IF in_ignore_yearend = 'last' THEN
       SELECT ARRAY[trans_id] INTO ignore_trans FROM yearend
     ORDER BY transdate DESC LIMIT 1;
    ELSIF in_ignore_yearend = 'all' THEN
       SELECT array_agg(trans_id) INTO ignore_trans FROM yearend;
    ELSE
       ignore_trans := '{}';
    END IF;

    IF in_to_date IS NULL THEN
        SELECT max(transdate) INTO t_end_date FROM acc_trans;
    ELSE
        t_end_date := in_to_date;
    END IF;


    RETURN QUERY
       WITH ac (transdate, amount_bc, chart_id) AS (
           WITH RECURSIVE bu_tree (id, path) AS (
            SELECT id, id::text AS path
              FROM business_unit
             WHERE parent_id = any(in_business_units)
            UNION
            SELECT bu.id, bu_tree.path || ',' || bu.id
              FROM business_unit bu
              JOIN bu_tree ON bu_tree.id = bu.parent_id
            )
       SELECT ac.transdate, ac.amount_bc, ac.chart_id
         FROM acc_trans ac
         JOIN (SELECT id, approved FROM ar UNION ALL
               SELECT id, approved FROM ap UNION ALL
               SELECT id, approved FROM gl) gl
                   ON ac.trans_id = gl.id
                     AND (in_approved is null
                          OR (gl.approved = in_approved
                             and (ac.approved OR in_approved is false)))
    LEFT JOIN business_unit_ac buac ON ac.entry_id = buac.entry_id
    LEFT JOIN bu_tree ON buac.bu_id = bu_tree.id
        WHERE ac.transdate BETWEEN t_roll_forward + '1 day'::interval
                                    AND t_end_date
              AND (ignore_trans is null or ac.trans_id <> ALL(ignore_trans))
              AND ((in_business_units = '{}' OR in_business_units IS NULL)
               OR bu_tree.id IS NOT NULL)
       )
       SELECT a.id, a.accno,
         COALESCE(at.description, a.description) as description, a.gifi_accno,
         CASE WHEN in_from_date IS NULL THEN 0 ELSE
              COALESCE(t_balance_sign,
                      CASE WHEN a.category IN ('A', 'E') THEN -1 ELSE 1 END )
              * (COALESCE(cp.amount_bc, 0)
              + SUM(CASE WHEN ac.transdate < coalesce(in_from_date,
                                                      t_roll_forward)
                         THEN ac.amount_bc ELSE 0 END)) end,
         SUM(CASE WHEN ac.transdate BETWEEN coalesce(in_from_date,
                                                     t_roll_forward)
                                        AND coalesce(in_to_date, ac.transdate)
                                    AND ac.amount_bc < 0 THEN ac.amount_bc * -1
                                                      ELSE 0 END)
            - CASE WHEN in_from_date IS NULL THEN COALESCE(cp.debits, 0)
                                             ELSE 0 END,
         SUM(CASE WHEN ac.transdate BETWEEN COALESCE(in_from_date,
                                                         t_roll_forward)
                                            AND COALESCE(in_to_date,
                                                         ac.transdate)
                                    AND ac.amount_bc > 0 THEN ac.amount_bc
                                                      ELSE 0 END) +
              CASE WHEN in_from_date IS NULL THEN COALESCE(cp.credits, 0)
                                             ELSE 0 END,
         COALESCE(t_balance_sign,
                  CASE WHEN a.category IN ('A', 'E') THEN -1 ELSE 1 END)
            * (COALESCE(cp.amount_bc, 0) + SUM(COALESCE(ac.amount_bc, 0))),
         CASE WHEN SUM(ac.amount_bc) + COALESCE(cp.amount_bc, 0) < 0
                 THEN (SUM(ac.amount_bc) + COALESCE(cp.amount_bc, 0)) * -1
              ELSE NULL END,
         CASE WHEN SUM(ac.amount_bc) + COALESCE(cp.amount_bc, 0) > 0
                   THEN sum(ac.amount_bc) + COALESCE(cp.amount_bc, 0)
              ELSE NULL END
         FROM account a
    LEFT JOIN ac ON ac.chart_id = a.id
    LEFT JOIN (
         select end_date, account_id, sum(amount_bc) as amount_bc,
                sum(debits) as debits, sum(credits) as credits
         from account_checkpoint
          where end_date = t_roll_forward
        group by end_date, account_id) cp ON cp.account_id = a.id
    LEFT JOIN (SELECT trans_id, description
                 FROM account_translation at
              INNER JOIN user_preference up ON up.language = at.language_code
              INNER JOIN users ON up.id = users.id
                WHERE users.username = SESSION_USER) at ON a.id = at.trans_id
        WHERE (in_accounts IS NULL OR in_accounts = '{}'
               OR a.id = ANY(in_accounts))
              AND (in_heading IS NULL OR in_heading = a.heading)
     GROUP BY a.id, a.accno, COALESCE(at.description, a.description),
              a.category, a.gifi_accno, cp.end_date, cp.account_id,
              cp.amount_bc, cp.debits, cp.credits
       HAVING ABS(cp.amount_bc) > 0 or COUNT(ac) > 0 or in_all_accounts
     ORDER BY a.accno;
END;
$$ language plpgsql;




CREATE TEMPORARY TABLE verify_mc_trial_balances AS
 SELECT (select max(transdate) from acc_trans)::date as balance_date, *
  FROM pg_temp.trial_balance__generate(null, null, null, null,
                               'none', null, null, 't'::boolean,
                               't'::boolean);

alter table verify_mc_trial_balances
   add primary key (balance_date, account_id);

INSERT INTO verify_mc_trial_balances
SELECT cp.end_date, tb.*
  FROM (select distinct end_date from account_checkpoint) cp,
       pg_temp.trial_balance__generate((select max(end_date) from account_checkpoint c
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
  FROM verify_mc_trial_balances vtb
FULL OUTER JOIN mc_migration_validation_data.trial_balances otb
  ON vtb.balance_date = otb.balance_date AND vtb.account_id = otb.account_id
 WHERE ((coalesce(otb.starting_balance,0) - coalesce(vtb.starting_balance,0)) <> 0
        OR (coalesce(otb.debits,0) - coalesce(vtb.debits,0)) <> 0
        OR (coalesce(otb.credits,0) - coalesce(vtb.credits,0)) <> 0
        OR (coalesce(otb.ending_balance,0) - coalesce(vtb.ending_balance,0)) <> 0)
       AND NOT ((select value from defaults where setting_key = 'accept_mc') = 'yes')
  ORDER BY balance_date, account_id;
!,
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
