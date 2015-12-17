BEGIN;

DROP TYPE IF EXISTS tb_row CASCADE;
create type tb_row AS (
   account_id int,
   account_number text,
   account_desc text,
   gifi_accno	text,
   starting_balance numeric,
   debits numeric,
   credits numeric,
   ending_balance numeric
);

DROP FUNCTION IF EXISTS trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[]);

DROP FUNCTION IF EXISTS trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[], in_balance_sign int);


CREATE OR REPLACE FUNCTION trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[], in_balance_sign int,
 in_all_accounts boolean)
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
       WITH ac (transdate, amount, chart_id) AS (
           WITH RECURSIVE bu_tree (id, path) AS (
            SELECT id, id::text AS path
              FROM business_unit
             WHERE parent_id = any(in_business_units)
            UNION
            SELECT bu.id, bu_tree.path || ',' || bu.id
              FROM business_unit bu
              JOIN bu_tree ON bu_tree.id = bu.parent_id
            )
       SELECT ac.transdate, ac.amount, ac.chart_id
         FROM acc_trans ac
         JOIN (SELECT id, approved FROM ar UNION ALL
               SELECT id, approved FROM ap UNION ALL
               SELECT id, approved FROM gl) gl
                   ON ac.approved and gl.approved and ac.trans_id = gl.id
    LEFT JOIN business_unit_ac buac ON ac.entry_id = buac.entry_id
    LEFT JOIN bu_tree ON buac.bu_id = bu_tree.id
        WHERE ac.transdate BETWEEN t_roll_forward + '1 day'::interval
                                    AND t_end_date
              AND (ignore_trans is null or ac.trans_id <> ALL(ignore_trans))
              AND ((in_business_units = '{}' OR in_business_units IS NULL)
               OR bu_tree.id IS NOT NULL)
       )
       SELECT a.id, a.accno,
         coalesce(at.description, a.description) as description, a.gifi_accno,
         case when in_from_date is null then 0 else
              COALESCE(t_balance_sign,
                      CASE WHEN a.category IN ('A', 'E') THEN -1 ELSE 1 END )
              * (coalesce(cp.amount, 0)
              + sum(CASE WHEN ac.transdate < coalesce(in_from_date,
                                                      t_roll_forward)
                         THEN ac.amount ELSE 0 END)) end,
              sum(CASE WHEN ac.transdate BETWEEN coalesce(in_from_date,
                                                         t_roll_forward)
                                                 AND coalesce(in_to_date,
                                                         ac.transdate)
                             AND ac.amount < 0 THEN ac.amount * -1 ELSE 0 END) -
              case when in_from_date is null then coalesce(cp.debits, 0) else 0 end,
              sum(CASE WHEN ac.transdate BETWEEN coalesce(in_from_date,
                                                         t_roll_forward)
                                                 AND coalesce(in_to_date,
                                                         ac.transdate)
                             AND ac.amount > 0 THEN ac.amount ELSE 0 END) +
              case when in_from_date is null then coalesce(cp.credits, 0) else 0 end,
              COALESCE(t_balance_sign,
                       CASE WHEN a.category IN ('A', 'E') THEN -1 ELSE 1 END)
              * (coalesce(cp.amount, 0) + sum(coalesce(ac.amount, 0))),
              CASE WHEN sum(ac.amount) + coalesce(cp.amount, 0) < 0
                   THEN (sum(ac.amount) + coalesce(cp.amount, 0)) * -1
                   ELSE NULL END,
              CASE WHEN sum(ac.amount) + coalesce(cp.amount, 0) > 0
                   THEN sum(ac.amount) + coalesce(cp.amount, 0) ELSE NULL END
         FROM account a
    LEFT JOIN ac ON ac.chart_id = a.id
    LEFT JOIN account_checkpoint cp ON cp.account_id = a.id
              AND end_date = t_roll_forward
    LEFT JOIN (SELECT trans_id, description
                 FROM account_translation at
              INNER JOIN user_preference up ON up.language = at.language_code
              INNER JOIN users ON up.id = users.id
                WHERE users.username = SESSION_USER) at ON a.id = at.trans_id
        WHERE (in_accounts IS NULL OR in_accounts = '{}'
               OR a.id = ANY(in_accounts))
              AND (in_heading IS NULL OR in_heading = a.heading)
     GROUP BY a.id, a.accno, coalesce(at.description, a.description),
              a.category, a.gifi_accno, cp.end_date, cp.account_id, cp.amount,
              cp.debits, cp.credits
       HAVING abs(cp.amount) > 0 or count(ac) > 0 or in_all_accounts
     ORDER BY a.accno;
END;
$$ language plpgsql;


COMMENT ON FUNCTION trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[], in_balance_sign int,
 in_all_accounts boolean) IS
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
