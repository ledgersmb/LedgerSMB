-- Unused currently and untested.  This is expected to be a basis for 1.4 work
-- not recommended for current usage.  Not documenting yet.  --CT
BEGIN;

DROP TYPE IF EXISTS report_aging_item CASCADE;

CREATE TYPE report_aging_item AS (
	entity_id int,
	account_number varchar(24),
	name text,
	contact_name text,
	invnumber text,
	transdate date,
	till varchar(20),
	ordnumber text,
	ponumber text,
	notes text,
	c0 numeric,
	c30 numeric,
	c60 numeric,
	c90 numeric,
	duedate date,
	id int,
	curr varchar(3),
	exchangerate numeric,
	line_items text[][],
        age int
);


CREATE OR REPLACE FUNCTION report__invoice_aging_detail
(in_entity_id int, in_entity_class int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool) 
RETURNS SETOF report_aging_item
AS
$$
DECLARE
	item report_aging_item;
BEGIN
	FOR item IN
                  WITH RECURSIVE bu_tree (id, path) AS (
                SELECT id, id::text AS path
                  FROM business_unit
                 WHERE id = any(in_business_units)
                 UNION
                SELECT bu.id, bu_tree.path || ',' || bu.id
                  FROM business_unit bu
                  JOIN bu_tree ON bu_tree.id = bu.parent_id
                       )
		SELECT c.entity_id, c.meta_number, e.name,
		       e.name as contact_name, 
	               a.invnumber, a.transdate, a.till, a.ordnumber, 
		       a.ponumber, a.notes, 
		       CASE WHEN a.age/30 = 0
		                 THEN (a.sign * sum(ac.amount)) 
                            ELSE 0 END
		            as c0, 
		       CASE WHEN a.age/30 = 1
		                 THEN (a.sign * sum(ac.amount))
                            ELSE 0 END
		            as c30, 
		       CASE WHEN a.age/30 = 2
		            THEN (a.sign * sum(ac.amount))
                            ELSE 0 END
		            as c60, 
		       CASE WHEN a.age/30 > 2
		            THEN (a.sign * sum(ac.amount))
                            ELSE 0 END
		            as c90, 
		       a.duedate, a.id, a.curr,
		       COALESCE((SELECT sell FROM exchangerate ex
		         WHERE a.curr = ex.curr
		              AND ex.transdate = a.transdate), 1)
		       AS exchangerate,
			(SELECT compound_array(ARRAY[[p.partnumber,
					i.description, i.qty::text]])
				FROM parts p 
				JOIN invoice i ON (i.parts_id = p.id)
				WHERE i.trans_id = a.id) AS line_items,
                   (coalesce(in_to_date, now())::date - a.transdate) as age
		  FROM (select id, invnumber, till, ordnumber, amount, duedate,
                               curr, ponumber, notes, entity_credit_account,
                               -1 AS sign, transdate,
                               CASE WHEN in_use_duedate 
                                    THEN coalesce(in_to_date, now())::date
                                         - duedate
                                    ELSE coalesce(in_to_date, now())::date
                                         - transdate 
                               END as age
                          FROM ar
                         WHERE in_entity_class = 2
                         UNION 
                        SELECT id, invnumber, null, ordnumber, amount, duedate,
                               curr, ponumber, notes, entity_credit_account,
                               1 as sign, transdate,
                               CASE WHEN in_use_duedate 
                                    THEN coalesce(in_to_date, now())::date
                                         - duedate
                                    ELSE coalesce(in_to_date, now())::date
                                         - transdate 
                               END as age
                          FROM ap
                         WHERE in_entity_class = 1) a
                  JOIN acc_trans ac ON ac.trans_id = a.id
                  JOIN account acc ON ac.chart_id = acc.id
                  JOIN account_link acl ON acl.account_id = acc.id
                       AND ((in_entity_class = 1 
                              AND acl.description = 'AP')
                           OR (in_entity_class = 2
                              AND acl.description = 'AR'))
		  JOIN entity_credit_account c 
                       ON a.entity_credit_account = c.id
		  JOIN entity e ON (e.id = c.entity_id)
             LEFT JOIN business_unit_ac buac ON ac.entry_id = buac.entry_id
             LEFT JOIN bu_tree ON buac.bu_id = bu_tree.id
	     LEFT JOIN entity_to_location e2l 
                       ON e.id = e2l.entity_id 
                       AND e2l.location_class = 3
             LEFT JOIN location l ON l.id = e2l.location_id
	     LEFT JOIN country ON (country.id = l.country_id)
                 WHERE (e.id = in_entity_id OR in_entity_id IS NULL)
                       AND (in_accno IS NULL or acc.accno = in_accno)
              GROUP BY c.entity_id, c.meta_number, e.name,
                       l.line_one, l.line_two, l.line_three,
                       l.city, l.state, l.mail_code, country.name,
                       a.invnumber, a.transdate, a.till, a.ordnumber,
                       a.ponumber, a.notes, a.amount, a.sign,
                       a.duedate, a.id, a.curr, a.age
                HAVING in_business_units is null or in_business_units 
                       <@ compound_array(string_to_array(bu_tree.path, 
                                         ',')::int[])
	      ORDER BY entity_id, curr, transdate, invnumber
	LOOP
		return next item;
        END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION report__invoice_aging_summary
(in_entity_id int, in_entity_class int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool) 
RETURNS SETOF report_aging_item
AS $$
SELECT entity_id, account_number, name, contact_name, null::text, null::date, 
       null::text, null::text, null::text, null::text, 
       sum(c0), sum(c30), sum(c60), sum(c90), null::date, null::int, curr,
       null::numeric, null::text[], null::int
  FROM report__invoice_aging_detail($1, $2, $3, $4, $5, $6)
 GROUP BY entity_id, account_number, name, contact_name, curr
 ORDER BY account_number
$$ LANGUAGE SQL;


DROP TYPE IF EXISTS gl_report_item CASCADE;

CREATE TYPE gl_report_item AS (
    id int,
    type text,
    invoice bool,
    reference text,
    description text,
    transdate date,
    source text,
    amount numeric,
    accno text,
    gifi_accno text,
    till text,
    cleared bool,
    memo text,
    accname text,
    chart_id int,
    entry_id int,
    running_balance numeric,
    business_units int[]
);

CREATE OR REPLACE FUNCTION report__gl
(in_reference text, in_accno text, in_category char(1),
in_source text, in_memo text,  in_description text, in_from_date date, 
in_to_date date, in_approved bool, in_from_amount numeric, in_to_amount numeric,
in_business_units int[])
RETURNS SETOF gl_report_item AS
$$
DECLARE 
         retval gl_report_item;
         t_balance numeric;
         t_chart_id int;
BEGIN

IF in_from_date IS NULL THEN
   t_balance := 0;
ELSIF in_accno IS NOT NULL THEN
   SELECT id INTO t_chart_id FROM account WHERE accno  = in_accno;
   t_balance := account__obtain_balance(in_from_date , t_accno);
ELSE
   t_balance := null;
END IF;

FOR retval IN
       WITH RECURSIVE bu_tree (id, path) AS (
            SELECT id, id::text AS path
              FROM business_unit
             WHERE parent_id is null
            UNION
            SELECT bu.id, bu_tree.path || ',' || bu.id
              FROM business_unit bu
              JOIN bu_tree ON bu_tree.id = bu.parent_id
            )
       SELECT g.id, g.type, g.invoice, g.reference, g.description, ac.transdate,
              ac.source, ac.amount, c.accno, c.gifi_accno, 
              g.till, ac.cleared, ac.memo, c.description AS accname, 
              ac.chart_id, ac.entry_id, 
              sum(ac.amount) over (rows unbounded preceding) + t_balance 
                as running_balance,
              compound_array(ARRAY[ARRAY[bac.class_id, bac.bu_id]])
         FROM (select id, 'gl' as type, false as invoice, reference, 
                      description, approved,
                      null::text as till 
                 FROM gl
               UNION
               SELECT ar.id, 'ar', invoice, invnumber, e.name, approved, till
                 FROM ar
                 JOIN entity_credit_account eca ON ar.entity_credit_account
                      = eca.id
                 JOIN entity e ON e.id = eca.entity_id
               UNION
               SELECT ap.id, 'ap', invoice, invnumber, e.name, approved,
                      null as till
                 FROM ap
                 JOIN entity_credit_account eca ON ap.entity_credit_account 
                      = eca.id
                 JOIN entity e ON e.id = eca.entity_id) g
         JOIN acc_trans ac ON ac.trans_id = g.id
         JOIN account c ON ac.chart_id = c.id
    LEFT JOIN business_unit_ac bac ON ac.entry_id = bac.entry_id 
    LEFT JOIN bu_tree ON bac.bu_id = bu_tree.id
        WHERE (g.reference ilike in_reference || '%' or in_reference is null)
              AND (c.accno = in_accno OR in_accno IS NULL)
              AND (ac.source ilike '%' || in_source || '%' 
                   OR in_source is null)
              AND (ac.memo ilike '%' || in_memo || '%' OR in_memo is null)
             AND (in_description IS NULL OR
                  to_tsvector(get_default_lang()::name, g.description)
                  @@
                  plainto_tsquery(get_default_lang()::name, in_description))
              AND (transdate BETWEEN in_from_date AND in_to_date
                   OR (transdate >= in_from_date AND  in_to_date IS NULL)
                   OR (transdate <= in_to_date AND in_from_date IS NULL)
                   OR (in_to_date IS NULL AND in_from_date IS NULL))
              AND (in_approved is false OR (g.approved AND ac.approved))
              AND (in_from_amount IS NULL OR ac.amount >= in_from_amount)
              AND (in_to_amount IS NULL OR ac.amount <= in_to_amount)
              AND (in_category = c.category OR in_category IS NULL)
     GROUP BY g.id, g.type, g.invoice, g.reference, g.description, ac.transdate,
              ac.source, ac.amount, c.accno, c.gifi_accno,
              g.till, ac.cleared, ac.memo, c.description,
              ac.chart_id, ac.entry_id, ac.trans_id
       HAVING in_business_units is null or in_business_units 
                <@ compound_array(string_to_array(bu_tree.path, ',')::int[])
     ORDER BY ac.transdate, ac.trans_id, c.accno
LOOP
   RETURN NEXT retval;
END LOOP;
END;
$$ language plpgsql;


DROP TYPE IF EXISTS cash_summary_item CASCADE;

CREATE TYPE cash_summary_item AS (
   account_id int,
   accno text,
   is_heading bool,
   description text,
   document_type text,
   debits numeric,
   credits numeric
);

CREATE OR REPLACE FUNCTION report__cash_summary
(in_date_from date, in_date_to date, in_from_accno text, in_to_accno text)
RETURNS SETOF cash_summary_item AS 
$$
SELECT a.id, a.accno, a.is_heading, a.description, t.label, 
       sum(CASE WHEN ac.amount < 0 THEN ac.amount * -1 ELSE NULL END),
       sum(CASE WHEN ac.amount > 0 THEN ac.amount ELSE NULL END)
  FROM (select id, accno, false as is_heading, description FROM account
       UNION
        SELECT id, accno, true, description FROM account_heading) a
  LEFT
  JOIN acc_trans ac ON ac.chart_id = a.id 
  LEFT
  JOIN (select id, case when table_name ilike 'ar' THEN 'rcpt'
                        when table_name ilike 'ap' THEN 'pmt'
                        when table_name ilike 'gl' THEN 'xfer'
                    END AS label
          FROM transactions) t ON t.id = ac.trans_id
 WHERE accno BETWEEN $3 AND $4
        and ac.transdate BETWEEN $1 AND $2
GROUP BY a.id, a.accno, a.is_heading, a.description, t.label
ORDER BY accno;

$$ LANGUAGE SQL;

DROP TYPE IF EXISTS general_balance_line CASCADE;

CREATE TYPE general_balance_line AS (
   account_id int,
   account_accno text,
   account_description text,
   starting_balance numeric,
   debits numeric,
   credits numeric,
   final_balance numeric
);

CREATE OR REPLACE FUNCTION report__general_balance 
(in_date_from date, in_date_to date)
RETURNS SETOF general_balance_line AS
$$

SELECT a.id, a.accno, a.description,
      sum(CASE WHEN ac.transdate < $1 THEN abs(amount) ELSE null END),
      sum(CASE WHEN ac.transdate >= $1 AND ac.amount < 0 
               THEN ac.amount * -1 ELSE null END),
      SUM(CASE WHEN ac.transdate >= $1 AND ac.amount > 0
               THEN ac.amount ELSE null END),
      SUM(ABS(ac.amount))
 FROM account a 
 LEFT
 JOIN acc_trans ac ON ac.chart_id = a.id
 LEFT 
 JOIN (select id, approved from ar UNION
       SELECT id, approved from ap UNION
       SELECT id, approved FROM gl) gl ON ac.trans_id = gl.id
WHERE gl.approved and ac.approved
      and ac.transdate <= $2 
GROUP BY a.id, a.accno, a.description
ORDER BY a.accno;

$$ LANGUAGE SQL; 


COMMIT;
