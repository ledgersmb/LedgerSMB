
set client_min_messages = 'warning';


BEGIN;

DROP TYPE IF EXISTS tb_row CASCADE;
create type tb_row AS (
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

DROP FUNCTION IF EXISTS trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[]);

DROP FUNCTION IF EXISTS trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[], in_balance_sign int);

DROP FUNCTION IF EXISTS trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[], in_balance_sign int,
 in_all_accounts boolean);

DROP FUNCTION IF EXISTS trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[], in_balance_sign int,
 in_all_accounts boolean, in_approved boolean);

CREATE OR REPLACE FUNCTION trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_business_units int[], in_balance_sign int,
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

     IF in_from_date IS NULL THEN
       SELECT max(end_date) INTO t_roll_forward
         FROM account_checkpoint
        WHERE end_date < (select max(txn.transdate)
                            FROM transactions txn
                                   JOIN yearend y ON y.trans_id = txn.id
                           WHERE y.transdate < coalesce(in_to_date, txn.transdate)
                         );
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

    SELECT ARRAY[trans_id] INTO ignore_trans FROM yearend
     ORDER BY transdate DESC LIMIT 1;

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
         FROM (select * from acc_trans
                where in_business_units = '{}' OR in_business_units IS NULL
                      OR EXISTS (
                            select 1 from business_unit_ac buac
                              join bu_tree on bu_tree.id = buac.bu_id
                             where buac.entry_id = acc_trans.entry_id
                           )) ac
         JOIN (SELECT id, approved FROM transactions
                WHERE (in_approved is null OR approved = in_approved)) txn
              ON ac.trans_id = txn.id
        WHERE ac.transdate BETWEEN t_roll_forward + '1 day'::interval AND t_end_date
              AND (in_approved is null or ac.approved or in_approved is false)
              AND (ignore_trans is null or ac.trans_id <> ALL(ignore_trans))
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
         select account_id, sum(amount_bc) as amount_bc,
                sum(debits) as debits, sum(credits) as credits
         from account_checkpoint
          where end_date = t_roll_forward
        group by account_id) cp ON cp.account_id = a.id
    LEFT JOIN (SELECT trans_id, description
                 FROM account_translation at
               WHERE language_code = preference__get('language')) at
           ON a.id = at.trans_id
        WHERE (in_accounts IS NULL OR in_accounts = '{}'
               OR a.id = ANY(in_accounts))
              AND (in_heading IS NULL OR in_heading = a.heading)
     GROUP BY a.id, a.accno, COALESCE(at.description, a.description),
              a.category, a.gifi_accno, cp.account_id,
              cp.amount_bc, cp.debits, cp.credits
       HAVING ABS(cp.amount_bc) > 0 or COUNT(ac) > 0 or in_all_accounts
     ORDER BY a.accno;
END;
$$ language plpgsql;


COMMENT ON FUNCTION trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_business_units int[], in_balance_sign int,
 in_all_accounts boolean, in_approved boolean) IS
$$Returns a row for each account which has transactions or a starting or
ending balance over the indicated period, except when in_all_accounts
is true, in which case a record is returned for all accounts, even ones
unused over the reporting period.$$;


DROP TYPE IF EXISTS trial_balance__heading CASCADE;
CREATE TYPE trial_balance__heading AS (
    id int,
    accno text,
    description text,
    accounts int[]
);

CREATE OR REPLACE FUNCTION trial_balance__list_headings (
) RETURNS SETOF trial_balance__heading AS $body$
    SELECT id, accno, description, ARRAY( SELECT id FROM account where heading = ah.id) FROM account_heading ah;
$body$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trial_balance__heading_accounts (
    in_accounts int[]
) RETURNS SETOF account AS $body$
    SELECT * FROM account WHERE id in (SELECT unnest($1));
$body$ LANGUAGE SQL IMMUTABLE;


update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
