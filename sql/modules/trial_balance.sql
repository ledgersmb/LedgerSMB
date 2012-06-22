CREATE OR REPLACE FUNCTION unnest(anyarray)
  RETURNS SETOF anyelement AS
$BODY$
SELECT $1[i] FROM
    generate_series(array_lower($1,1),
                    array_upper($1,1)) i;
$BODY$
  LANGUAGE 'sql' IMMUTABLE;


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


CREATE OR REPLACE FUNCTION trial_balance__generate 
(in_date_from DATE, in_date_to DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_department INT, in_business_units int[]) 
returns setof tb_row AS
$$
DECLARE
	out_row         tb_row;
        t_roll_forward  date;
        t_cp            account_checkpoint;
        ignore_trans    int[];
        t_start_date    date; 
        t_end_date      date;
BEGIN

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
       SELECT min(transdate)  INTO t_roll_forward
         FROM (select min(transdate) as transdate from ar
                union ALL
               select min(transdate) from ap
                union all
               select min(transdate) from gl) gl;
                           
    ELSE
      SELECT max(end_date) INTO t_roll_forward
         FROM account_checkpoint 
        WHERE end_date < in_date_from;
    END IF;

    IF t_roll_forward IS NULL THEN
       SELECT min(transdate) INTO t_roll_forward FROM acc_trans;
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
                   OR (parent_id = IS NULL 
                       AND (in_business_units = '{}' 
                             OR in_business_units IS NULL))
            UNION
            SELECT bu.id, bu_tree.path || ',' || bu.id
              FROM business_unit bu
              JOIN bu_tree ON bu_tree.id = bu.parent_id
            )
       SELECT ac.transdate, ac.amount, ac.chart_id
         FROM acc_trans ac
         JOIN (SELECT id, approved, department_id FROM ar UNION ALL
               SELECT id, approved, department_id FROM ap UNION ALL
               SELECT id, approved, department_id FROM gl) gl
                   ON ac.approved and gl.approved and ac.trans_id = gl.id
    LEFT JOIN business_unit_ac buac ON ac.entry_id = buac.entry_id
    LEFT JOIN bu_tree ON buac.bu_id = bu_tree.id
        WHERE ac.transdate BETWEEN t_roll_forward + '1 day'::interval 
                                    AND t_end_date
              AND ac.trans_id <> ALL(ignore_trans)
              AND (in_department is null 
                 or gl.department_id = in_department)
              ((in_business_units = '{}' OR in_business_units IS NULL)
                OR bu_tree.id IS NOT NULL)
       )
       SELECT a.id, a.accno, a.description, a.gifi_accno,
         case when in_date_from is null then 0 else
              CASE WHEN a.category IN ('A', 'E') THEN -1 ELSE 1 END 
              * (coalesce(cp.amount, 0) 
              + sum(CASE WHEN ac.transdate <= coalesce(in_date_from, 
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
              CASE WHEN a.category IN ('A', 'E') THEN -1 ELSE 1 END 
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
     ORDER BY a.accno;
END;
$$ language plpgsql;


CREATE TABLE trial_balance__yearend_types (
    type text primary key
);
INSERT INTO trial_balance__yearend_types (type) VALUES ('none');
INSERT INTO trial_balance__yearend_types (type) VALUES ('all');
INSERT INTO trial_balance__yearend_types (type) VALUES ('last');


CREATE TABLE trial_balance (
    id serial primary key,
    date_from date, 
    date_to date,
    description text NOT NULL,
    yearend text not null references trial_balance__yearend_types(type)
);

CREATE TABLE trial_balance__account_to_report (
    report_id int not null references trial_balance(id),
    account_id int not null references account(id)
);

CREATE TABLE trial_balance__heading_to_report (
    report_id int not null references trial_balance(id),
    heading_id int not null references account_heading(id)
);

CREATE TYPE trial_balance__entry AS (
    id int,
    date_from date,
    date_to date,
    description text,
    yearend text,
    heading_id int,
    accounts int[]
);


CREATE OR REPLACE FUNCTION trial_balance__get (
    in_report_id int
) RETURNS trial_balance__entry AS $body$
    SELECT tb.id, 
           tb.date_from, 
           tb.date_to, 
           tb.description, 
           tb.yearend,
           tbh.heading_id,
           (ARRAY(SELECT account_id FROM trial_balance__account_to_report WHERE report_id = tb.id)) as accounts
     FROM trial_balance tb
     LEFT OUTER JOIN trial_balance__heading_to_report tbh ON tbh.report_id = tb.id
     WHERE tb.id = $1;
$body$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION trial_balance__save (
    in_id int,
    in_date_from date,
    in_date_to date,
    in_desc text,
    in_yearend text,
    in_heading int,
    in_accounts int[]
) RETURNS int AS $body$

    DECLARE
        old_heading_id int;
        new_report_id int;
        iter int;
        acc_id int;
    BEGIN
        PERFORM id 
           FROM trial_balance
          WHERE id = in_id;
          
        IF in_id IS NOT NULL AND FOUND THEN
            -- This is an edit.
            UPDATE trial_balance
               SET date_from   = in_date_from,
                   date_to     = in_date_to,
                   description = in_desc,
                   yearend     = in_yearend
             WHERE id = in_id;
            
            SELECT heading_id 
              INTO old_heading_id
              FROM trial_balance__heading_to_report
             WHERE heading_id = in_heading
               AND report_id = in_id;
            
            IF FOUND AND in_heading IS NULL THEN
                DELETE FROM trial_balance__heading_to_report
                      WHERE report_id = in_id
                        AND heading_id = old_heading_id;
                -- Expect to remove the heading ID.
            ELSIF FOUND AND in_heading <> old_heading_id THEN
                
                UPDATE trial_balance__heading_to_report
                   SET heading_id = in_heading
                 WHERE heading_id = old_heading_id
                   AND report_id = in_id;

            -- Else, do nothing.
            END IF;
            
            IF in_accounts IS NOT NULL AND in_accounts <> '{}' THEN
                -- First, we add the new ones.
                
                DELETE FROM trial_balance__account_to_report WHERE report_id = in_id;
                FOR 
                    iter IN array_lower(in_accounts, 1) .. array_upper(in_accounts, 1) 
                LOOP
                    INSERT INTO trial_balance__account_to_report (report_id, account_id)
                         VALUES (in_id, in_accounts[iter]);
                END LOOP;
                
            ELSE
                -- It's null.
                -- We can drop all the direct account entries.
                DELETE 
                  FROM trial_balance__account_to_report
                 WHERE report_id = in_id;
            END IF;
            return in_id;
        ELSE 
            -- We don't have a trial balance setup.
            -- We can just create a new one whole cloth. Woo!
            new_report_id := nextval('trial_balance_id_seq');
            INSERT INTO trial_balance (id, date_from, date_to, description, yearend)
                 VALUES (new_report_id, in_date_from, in_date_to, in_desc, in_yearend);
            
            IF in_heading IS NOT NULL THEN
                INSERT INTO trial_balance__heading_to_report (report_id, heading_id)
                     VALUES (new_report_id, in_heading);
            END IF;
            
            IF in_accounts IS NOT NULL and in_accounts <> '{}' THEN
                -- Iterate over the length of the array, and insert each one into the
                -- account-to-report table.
                -- Because this targets 8.2, we can't use the 8.4 function unnest();
                FOR 
                    iter IN array_lower(in_accounts, 1) .. array_upper(in_accounts, 1) 
                LOOP
                    INSERT INTO trial_balance__account_to_report (report_id, account_id)
                         VALUES (new_report_id, in_accounts[iter]);
                END LOOP;
            END IF;
            return new_report_id;
        END IF;
    END;
$body$ LANGUAGE PLPGSQL;

--

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
