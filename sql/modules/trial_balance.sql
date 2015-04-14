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
(in_date_from DATE, in_date_to DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[]);

CREATE OR REPLACE FUNCTION trial_balance__generate 
(in_date_from DATE, in_date_to DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[], in_balance_sign int) 
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

    IF in_date_from IS NULL AND in_ignore_yearend = 'none' THEN
       SELECT max(end_date) INTO t_roll_forward 
         FROM account_checkpoint;
    ELSIF in_date_from IS NULL AND in_ignore_yearend = 'last' THEN
       SELECT max(end_date) INTO t_roll_forward 
         FROM account_checkpoint 
        WHERE end_date < (select max(gl.transdate)
                            FROM gl JOIN yearend y ON y.trans_id = gl.id
                           WHERE y.transdate < coalesce(in_date_to, gl.transdate)
                         );
    ELSIF in_date_from IS NULL THEN
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
        WHERE end_date < in_date_from;
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

    IF in_date_to IS NULL THEN
        SELECT max(transdate) INTO t_end_date FROM acc_trans;
    ELSE
        t_end_date := in_date_to;
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
       SELECT a.id, a.accno, a.description, a.gifi_accno,
         case when in_date_from is null then 0 else
              COALESCE(t_balance_sign, 
                      CASE WHEN a.category IN ('A', 'E') THEN -1 ELSE 1 END )
              * (coalesce(cp.amount, 0) 
              + sum(CASE WHEN ac.transdate < coalesce(in_date_from, 
                                                      t_roll_forward)
                         THEN ac.amount ELSE 0 END)) end, 
              sum(CASE WHEN ac.transdate BETWEEN coalesce(in_date_from, 
                                                         t_roll_forward)
                                                 AND coalesce(in_date_to, 
                                                         ac.transdate)
                             AND ac.amount < 0 THEN ac.amount * -1 ELSE 0 END) -
              case when in_date_from is null then coalesce(cp.debits, 0) else 0 end, 
              sum(CASE WHEN ac.transdate BETWEEN coalesce(in_date_from, 
                                                         t_roll_forward) 
                                                 AND coalesce(in_date_to, 
                                                         ac.transdate)
                             AND ac.amount > 0 THEN ac.amount ELSE 0 END) + 
              case when in_date_from is null then coalesce(cp.credits, 0) else 0 end, 
              COALESCE(t_balance_sign, 
                       CASE WHEN a.category IN ('A', 'E') THEN -1 ELSE 1 END)
              * (coalesce(cp.amount, 0) + sum(coalesce(ac.amount, 0)))
         FROM account a
    LEFT JOIN ac ON ac.chart_id = a.id
    LEFT JOIN account_checkpoint cp ON cp.account_id = a.id
              AND end_date = t_roll_forward
        WHERE (in_accounts IS NULL OR in_accounts = '{}' 
               OR a.id = ANY(in_accounts))
              AND (in_heading IS NULL OR in_heading = a.heading)
     GROUP BY a.id, a.accno, a.description, a.category, a.gifi_accno,
              cp.end_date, cp.account_id, cp.amount, cp.debits, cp.credits
       HAVING abs(cp.amount) > 0 or count(ac) > 0
     ORDER BY a.accno;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION trial_balance__accounts (
    in_report_id INT
) RETURNS SETOF account AS $body$

    SELECT a.* 
      FROM account a
      JOIN trial_balance__account_to_report tbr ON a.id = tbr.account_id
     WHERE tbr.report_id = $1
     
     UNION
     
     SELECT a.*
       FROM account a
       JOIN trial_balance__heading_to_report tbhr ON a.heading = tbhr.heading_id
      WHERE tbhr.report_id = $1
      
      ORDER BY accno DESC;
$body$ LANGUAGE SQL;

-- Just lists all valid report_ids

CREATE OR REPLACE FUNCTION trial_balance__list (
) RETURNS SETOF trial_balance AS $body$
    SELECT * FROM trial_balance ORDER BY id ASC;
$body$ LANGUAGE SQL STABLE;

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


CREATE OR REPLACE FUNCTION trial_balance__delete (
    in_report_id int
) RETURNS boolean AS $body$

    BEGIN
        PERFORM id FROM trial_balance WHERE id = in_report_id;
        
        IF FOUND THEN
            DELETE FROM trial_balance__heading_to_report WHERE report_id = in_report_id;
            DELETE FROM trial_balance__account_to_report WHERE report_id = in_report_id;
            DELETE FROM trial_balance WHERE id = in_report_id;
            RETURN TRUE;
        END IF;
        RETURN FALSE;
    END;
$body$ LANGUAGE PLPGSQL;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
