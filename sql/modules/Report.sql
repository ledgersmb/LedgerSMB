-- Unused currently and untested.  This is expected to be a basis for 1.4 work
-- not recommended for current usage.  Not documenting yet.  --CT
BEGIN;

DROP TYPE IF EXISTS incoming_lot_cogs_line CASCADE;

CREATE TYPE incoming_lot_cogs_line AS (
       id int,
       trans_id int,
       invnumber text,
       transdate date,
       parts_id int,
       partnumber text,
       description text,
       qty numeric,
       allocated numeric,
       onhand numeric,
       sellprice numeric,
       total_value numeric,
       cogs_sold numeric
);

CREATE OR REPLACE FUNCTION report__incoming_cogs_line
(in_date_from date, in_date_to date, in_partnumber text,
in_parts_description text)
RETURNS SETOF incoming_lot_cogs_line
LANGUAGE SQL AS
$$
SELECT i.id, a.id, a.invnumber, a.transdate, i.parts_id, p.partnumber,
       i.description, i.qty * -1, i.allocated, p.onhand,
       i.sellprice, i.qty * i.sellprice * -1, i.allocated * i.sellprice
  FROM ap a
  JOIN invoice i ON a.id = i.trans_id
  JOIN parts p ON i.parts_id = p.id
 WHERE p.income_accno_id IS NOT NULL AND p.expense_accno_id IS NOT NULL
       AND (a.transdate >= $1 OR $1 IS NULL)
       AND (a.transdate <= $2 OR $2 IS NULL)
       AND (p.partnumber like $3 || '%' OR $3 IS NULL)
       AND (p.description @@ plainto_tsquery($4)
            OR p.description LIKE '%' || $4 || '%'
            OR $4 IS NULL)
 ORDER BY p.partnumber, a.invnumber;
$$;

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
	curr char(3),
	exchangerate numeric,
	line_items text[][],
        age int
);

DROP FUNCTION IF EXISTS report__invoice_aging_detail
(in_entity_id int, in_entity_class int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool);

CREATE OR REPLACE FUNCTION report__invoice_aging_detail
(in_entity_id int, in_entity_class int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool, in_name_part text)
RETURNS SETOF report_aging_item
AS
$$
                  WITH RECURSIVE bu_tree (id, path) AS (
                SELECT id, id::text AS path
                  FROM business_unit
                 WHERE id = any(in_business_units)
                       OR in_business_units IS NULL
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
                               -1 AS sign, transdate, force_closed,
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
                               1 as sign, transdate, force_closed,
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
                       AND a.force_closed IS NOT TRUE
                       AND (in_name_part IS NULL
                            OR e.name like '%' || in_name_part || '%')
              GROUP BY c.entity_id, c.meta_number, e.name,
                       l.line_one, l.line_two, l.line_three,
                       l.city, l.state, l.mail_code, country.name,
                       a.invnumber, a.transdate, a.till, a.ordnumber,
                       a.ponumber, a.notes, a.amount, a.sign,
                       a.duedate, a.id, a.curr, a.age
                HAVING (in_business_units is null or in_business_units
                       <@ compound_array(string_to_array(bu_tree.path,
                                         ',')::int[]))
                       AND sum(ac.amount::numeric(20,2)) <> 0
	      ORDER BY entity_id, curr, transdate, invnumber
$$ language sql;

DROP FUNCTION IF EXISTS report__invoice_aging_summary
(in_entity_id int, in_entity_class int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool);

CREATE OR REPLACE FUNCTION report__invoice_aging_summary
(in_entity_id int, in_entity_class int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool, in_name_part text)
RETURNS SETOF report_aging_item
AS $$
SELECT entity_id, account_number, name, contact_name, null::text, null::date,
       null::text, null::text, null::text, null::text,
       sum(c0), sum(c30), sum(c60), sum(c90), null::date, null::int, curr,
       null::numeric, null::text[], null::int
  FROM report__invoice_aging_detail($1, $2, $3, $4, $5, $6, $7)
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
   t_balance :=
      account__obtain_balance((in_from_date - '1 day'::interval)::date,
                              (select id from account
                                where accno = in_accno));
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
                  g.description
                  @@
                  plainto_tsquery(get_default_lang()::regconfig, in_description))
              AND (transdate BETWEEN in_from_date AND in_to_date
                   OR (transdate >= in_from_date AND  in_to_date IS NULL)
                   OR (transdate <= in_to_date AND in_from_date IS NULL)
                   OR (in_to_date IS NULL AND in_from_date IS NULL))
              AND (in_approved is false OR (g.approved AND ac.approved))
              AND (in_from_amount IS NULL OR abs(ac.amount) >= in_from_amount)
              AND (in_to_amount IS NULL OR abs(ac.amount) <= in_to_amount)
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
(in_from_date date, in_to_date date, in_from_accno text, in_to_accno text)
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
(in_from_date date, in_to_date date)
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

DROP TYPE IF EXISTS aa_transactions_line CASCADE;

CREATE TYPE aa_transactions_line AS (
    id int,
    invoice bool,
    entity_id int,
    meta_number text,
    entity_name text,
    transdate date,
    invnumber text,
    amount numeric,
    netamount numeric,
    tax numeric,
    paid numeric,
    due numeric,
    last_payment date,
    due_date date,
    notes text,
    till text,
    salesperson text,
    manager text,
    shpping_point text,
    ship_via text,
    business_units text[]
);

CREATE OR REPLACE FUNCTION report__aa_outstanding_details
(in_entity_class int, in_account_id int, in_entity_name text,
 in_meta_number text,
 in_employee_id int, in_business_units int[], in_ship_via text, in_on_hold bool,
 in_from_date date, in_to_date date, in_partnumber text, in_parts_id int)
RETURNS SETOF aa_transactions_line LANGUAGE SQL AS $$

SELECT a.id, a.invoice, eeca.id, eca.meta_number, eeca.name, a.transdate,
       a.invnumber, a.amount, a.netamount, a.netamount - a.amount as tax,
       a.amount - p.due as paid, p.due, p.last_payment, a.duedate, a.notes,
       a.till, ee.name, me.name, a.shippingpoint, a.shipvia,
       '{}'::text[] as business_units -- TODO
  FROM (select id, transdate, invnumber, amount, netamount, duedate, notes,
               till, person_id, entity_credit_account, invoice, shippingpoint,
               shipvia, ordnumber, ponumber, description, on_hold, force_closed
          FROM ar
         WHERE in_entity_class = 2 and approved
         UNION
        SELECT id, transdate, invnumber, amount, netamount, duedate, notes,
               null, person_id, entity_credit_account, invoice, shippingpoint,
               shipvia, ordnumber, ponumber, description, on_hold, force_closed
          FROM ap
         WHERE in_entity_class = 1 and approved) a
  LEFT
  JOIN (SELECT trans_id, sum(amount) *
               CASE WHEN in_entity_class = 1 THEN 1 ELSE -1 END AS due,
               max(transdate) as last_payment
          FROM acc_trans ac
          JOIN account_link al ON ac.chart_id = al.account_id
         WHERE approved AND al.description IN ('AR', 'AP')
               AND (in_to_date is null or transdate <= in_to_date)
      GROUP BY trans_id) p ON p.trans_id = a.id
  JOIN entity_credit_account eca ON a.entity_credit_account = eca.id
  JOIN entity eeca ON eca.entity_id = eeca.id
  LEFT
  JOIN entity_employee ON entity_employee.entity_id = a.person_id
  LEFT
  JOIN entity ee ON entity_employee.entity_id = ee.id
  LEFT
  JOIN entity me ON entity_employee.manager_id = me.id
 WHERE (in_account_id IS NULL
          OR EXISTS (select 1 FROM acc_trans
                      WHERE trans_id = a.id and chart_id = in_account_id))
       AND (in_entity_name IS NULL
           OR eeca.name @@ plainto_tsquery(in_entity_name)
           OR eeca.name ilike '%' || in_entity_name || '%')
       AND (in_meta_number IS NULL
          OR eca.meta_number ilike in_meta_number || '%')
       AND (in_employee_id IS NULL OR ee.id = in_employee_id)
       AND (in_ship_via IS NULL
          OR a.shipvia @@ plainto_tsquery(in_ship_via))
       AND (in_on_hold IS NULL OR in_on_hold = a.on_hold)
       AND (in_from_date IS NULL OR a.transdate >= in_from_date)
       AND (in_to_date IS NULL OR a.transdate <= in_to_date)
       AND p.due::numeric(100,2) <> 0
       AND a.force_closed IS NOT TRUE
       AND (in_partnumber IS NULL
          OR EXISTS(SELECT 1 FROM invoice inv
                      JOIN parts ON inv.parts_id = parts.id
                     WHERE inv.trans_id = a.id))
       AND (in_parts_id IS NULL
          OR EXISTS (select 1 FROM invoice
                      WHERE parts_id = in_parts_id AND trans_id = a.id))

$$;

CREATE OR REPLACE FUNCTION report__aa_outstanding
(in_entity_class int, in_account_id int, in_entity_name text,
 in_meta_number text,
 in_employee_id int, in_business_units int[], in_ship_via text, in_on_hold bool,
 in_from_date date, in_to_date date, in_partnumber text, in_parts_id int)
RETURNS SETOF aa_transactions_line LANGUAGE SQL AS $$

SELECT null::int as id, null::bool as invoice, entity_id, meta_number,
       entity_name, null::date as transdate, count(*)::text as invnumber,
       sum(amount) as amount, sum(netamount) as netamount, sum(tax) as tax,
       sum(paid) as paid, sum(due) as due, max(last_payment) as last_payment,
       null::date as duedate, null::text as notes, null::text as till,
       null::text as salesperson, null::text as manager,
       null::text as shipping_point, null::text as ship_via,
       null::text[] as business_units
  FROM report__aa_outstanding_details($1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
    $11, $12)
 GROUP BY meta_number, entity_name, entity_id;

$$;

CREATE OR REPLACE FUNCTION report__aa_transactions
(in_entity_class int, in_account_id int, in_entity_name text,
 in_meta_number text,
 in_employee_id int, in_manager_id int, in_invnumber text, in_ordnumber text,
 in_ponumber text, in_source text, in_description text, in_notes text,
 in_shipvia text, in_from_date date, in_to_date date, in_on_hold bool,
 in_taxable bool, in_tax_account_id int, in_open bool, in_closed bool)
RETURNS SETOF aa_transactions_line LANGUAGE SQL AS $$

SELECT a.id, a.invoice, eeca.id, eca.meta_number, eeca.name,
       a.transdate, a.invnumber, a.amount, a.netamount,
       a.amount - a.netamount as tax, a.amount - p.due, p.due, p.last_payment,
       a.duedate, a.notes,
       a.till, eee.name as employee, mee.name as manager, a.shippingpoint,
       a.shipvia, '{}'::text[]

  FROM (select id, transdate, invnumber, amount, netamount, duedate, notes,
               till, person_id, entity_credit_account, invoice, shippingpoint,
               shipvia, ordnumber, ponumber, description, on_hold, force_closed
          FROM ar
         WHERE in_entity_class = 2 and approved
         UNION
        SELECT id, transdate, invnumber, amount, netamount, duedate, notes,
               null, person_id, entity_credit_account, invoice, shippingpoint,
               shipvia, ordnumber, ponumber, description, on_hold, force_closed
          FROM ap
         WHERE in_entity_class = 1 and approved) a
  LEFT
  JOIN (select sum(amount) * case when in_entity_class = 1 THEN 1 ELSE -1 END
               as due, trans_id, max(transdate) as last_payment
          FROM acc_trans ac
          JOIN account_link l ON ac.chart_id = l.account_id
         WHERE l.description IN ('AR', 'AP')
      GROUP BY ac.trans_id
       ) p ON p.trans_id = a.id
  LEFT
  JOIN entity_employee ee ON ee.entity_id = a.person_id
  LEFT
  JOIN entity eee ON eee.id = ee.entity_id
  JOIN entity_credit_account eca ON a.entity_credit_account = eca.id
  JOIN entity eeca ON eca.entity_id = eeca.id
  LEFT
  JOIN entity mee ON ee.manager_id = mee.id
 WHERE (in_account_id IS NULL OR
       EXISTS (select * from acc_trans
               where trans_id = a.id AND chart_id = in_account_id))
       AND (in_entity_name IS NULL
           OR eeca.name ilike '%' || in_entity_name || '%'
           OR eeca.name @@ plainto_tsquery(in_entity_name))
       AND (in_meta_number IS NULL OR eca.meta_number ilike in_meta_number)
       AND (in_employee_id = ee.entity_id OR in_employee_id IS NULL)
       AND (in_manager_id = mee.id OR in_manager_id IS NULL)
       AND (a.invnumber ilike in_invnumber || '%' OR in_invnumber IS NULL)
       AND (a.ordnumber ilike in_ordnumber || '%' OR in_ordnumber IS NULL)
       AND (a.ponumber ilike in_ponumber || '%' OR in_ponumber IS NULL)
       AND (in_source IS NULL OR
           EXISTS (
              SELECT * from acc_trans where trans_id = a.id
                     AND source ilike in_source || '%'
           ))
       AND (in_description IS NULL
              OR a.description @@ plainto_tsquery(in_description))
       AND (in_notes IS NULL OR a.notes @@ plainto_tsquery(in_notes))
       AND (in_shipvia IS NULL OR a.shipvia @@ plainto_tsquery(in_shipvia))
       AND (in_from_date IS NULL OR a.transdate >= in_from_date)
       AND (in_to_date IS NULL OR a.transdate <= in_to_date)
       AND (in_on_hold IS NULL OR in_on_hold = a.on_hold)
       AND (in_taxable IS NULL
            OR (in_taxable
              AND (in_tax_account_id IS NULL
                 OR EXISTS (SELECT 1 FROM acc_trans
                             WHERE trans_id = a.id
                                   AND chart_id = in_tax_account_id)
            ))
            OR (NOT in_taxable
                  AND NOT EXISTS (SELECT 1
                                    FROM acc_trans ac
                                    JOIN account_link al
                                      ON al.account_id = ac.chart_id
                                   WHERE ac.trans_id = a.id
                                         AND al.description ilike '%tax'))
            )
            AND ( -- open/closed handling
              (in_open IS TRUE AND ( a.force_closed IS NOT TRUE AND
                 abs(p.due) > 0.005))                  -- threshold due to
                                                       -- impossibility to
                                                       -- collect below -CT
               OR (in_closed IS TRUE AND ( a.force_closed IS NOT TRUE AND
                 abs(p.due) > 0.005) IS NOT TRUE)
            )

$$;

DROP FUNCTION IF EXISTS report__balance_sheet(in_to_date date);
DROP TYPE IF EXISTS balance_sheet_line CASCADE;

CREATE TYPE balance_sheet_line AS (
    account_id int,
    account_number text,
    account_desc text,
    account_type char,
    account_category char,
    account_contra boolean,
    gifi_accno text,
    gifi_description text,
    balance numeric,
    heading_path int[]
);


CREATE OR REPLACE FUNCTION report__balance_sheet(in_to_date date,
                                                 in_language text)
RETURNS SETOF balance_sheet_line LANGUAGE SQL AS
$$
WITH hdr_meta AS (
   SELECT aht.id, aht.accno, coalesce(at.description, aht.description) as description,
          aht.path,
          ahc.derived_category as category, 'H'::char as account_type,
          'f'::boolean as contra
     FROM account_heading_tree aht
    INNER JOIN account_heading_derived_category ahc ON aht.id = ahc.id
    LEFT JOIN (SELECT trans_id, description
                 FROM account_translation
                WHERE language_code =
                       coalesce($2,
                         (SELECT up.language
                            FROM user_preference up
                      INNER JOIN users ON up.id = users.id
                           WHERE users.username = SESSION_USER))) at
              ON aht.id = at.trans_id
     WHERE array_endswith((SELECT value::int FROM defaults
                            WHERE setting_key = 'earn_id'), aht.path)
           -- legacy (no earn_id) returns all headers
           OR (NOT aht.path @> ARRAY[(SELECT value::int FROM defaults
                                      WHERE setting_key = 'earn_id')])
),
acc_meta AS (
  SELECT a.id, a.accno, coalesce(at.description, a.description) as description,
         aht.path, a.category, 'A'::char as account_type, contra,
         a.gifi_accno, gifi.description as gifi_description
     FROM account a
    INNER JOIN account_heading_tree aht on a.heading = aht.id
     LEFT JOIN gifi ON a.gifi_accno = gifi.accno
     LEFT JOIN (SELECT trans_id, description
                  FROM account_translation
                 WHERE language_code =
                        coalesce($2,
                          (SELECT up.language
                             FROM user_preference up
                       INNER JOIN users ON up.id = users.id
                            WHERE users.username = SESSION_USER))) at
               ON a.id = at.trans_id
     WHERE array_endswith((SELECT value::int FROM defaults
                            WHERE setting_key = 'earn_id'), aht.path)
           -- legacy (no earn_id) returns all accounts; bug?
           OR (NOT aht.path @> ARRAY[(SELECT value::int FROM defaults
                                      WHERE setting_key = 'earn_id')])
),
acc_balance AS (
   SELECT ac.chart_id as id, sum(ac.amount) as balance
     FROM acc_trans ac
     JOIN tx_report t ON t.approved AND t.id = ac.trans_id
    WHERE ac.transdate <= coalesce($1, (select max(transdate) from acc_trans))
 GROUP BY ac.chart_id
   HAVING sum(ac.amount) <> 0.00
),
hdr_balance AS (
   select ahd.id, sum(balance) as balance
     FROM acc_balance ab
    INNER JOIN account acc ON ab.id = acc.id
    INNER JOIN account_heading_descendant ahd
            ON acc.heading = ahd.descendant_id
    GROUP BY ahd.id
)
   SELECT hm.id, hm.accno, hm.description, hm.account_type, hm.category,
          hm.contra, null::text as gifi_accno,
          null::text as gifi_description, hb.balance, hm.path
     FROM hdr_meta hm
    INNER JOIN hdr_balance hb ON hm.id = hb.id
   UNION
   SELECT am.id, am.accno, am.description, am.account_type, am.category,
          am.contra, am.gifi_accno, am.gifi_description, ab.balance, am.path
     FROM acc_meta am
    INNER JOIN acc_balance ab on am.id = ab.id
$$;

COMMENT ON function report__balance_sheet(date, text) IS
$$ This produces a balance sheet and the paths (acount numbers) of all headings
necessary; output is generated in the language requested, or in the
users default language if not available. $$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
