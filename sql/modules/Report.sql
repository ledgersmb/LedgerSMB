-- Unused currently and untested.  This is expected to be a basis for 1.4 work
-- not recommended for current usage.  Not documenting yet.  --CT
BEGIN;

DROP TYPE IF EXISTS report_aging_item CASCADE;

CREATE TYPE report_aging_item AS (
	entity_id int,
	account_number varchar(24),
	name text,
	address1 text,
	address2 text,
	address3 text,
	city_province text,
	mail_code text,
	country text,
	contact_name text,
	email text,
	phone text,
	fax text,
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
	line_items text[][]
);


CREATE OR REPLACE FUNCTION 
report__invoice_aging(in_entity_id int, in_entity_class int) 
RETURNS SETOF report_aging_item
AS
$$
DECLARE
	item report_aging_item;
BEGIN
	IF in_entity_class = 1 THEN
		FOR item IN
			SELECT c.entity_id, 
			       c.meta_number, e.name,
			       l.line_one as address1, l.line_two as address2, 
			       l.line_three as address3,
			       l.city_province, l.mail_code,
			       country.name as country, 
			       '' as contact_name, '' as email,
		               '' as phone, '' as fax, 
		               a.invnumber, a.transdate, a.till, a.ordnumber, 
			       a.ponumber, a.notes, 
			       CASE WHEN 
			                 EXTRACT(days FROM age(a.transdate)/30) 
			                 = 0
			                 THEN (a.amount - a.paid) ELSE 0 END
			            as c0, 
			       CASE WHEN EXTRACT(days FROM age(a.transdate)/30)
			                 = 1
			                 THEN (a.amount - a.paid) ELSE 0 END
			            as c30, 
			       CASE WHEN EXTRACT(days FROM age(a.transdate)/30)
			                 = 2
			                 THEN (a.amount - a.paid) ELSE 0 END
			            as c60, 
			       CASE WHEN EXTRACT(days FROM age(a.transdate)/30)
			                 > 2
			                 THEN (a.amount - a.paid) ELSE 0 END
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
					WHERE i.trans_id = a.id) AS line_items
			  FROM ap a
			  JOIN entity_credit_account c USING (entity_id)
			  JOIN entity e ON (e.id = c.entity_id)
			 CROSS JOIN location l
			  JOIN country ON (country.id = l.country_id)
			 WHERE a.entity_id like coalesce(in_entity_id::text, '%')
				AND l.id = (SELECT min(location_id) 
					FROM company_to_location 
					WHERE company_id = (select min(id) 
						FROM company
						WHERE entity_id = c.entity_id))
			ORDER BY entity_id, curr, transdate, invnumber
		LOOP
			return next item;
		END LOOP;
	ELSIF in_entity_class = 2 THEN
		FOR item IN 
			SELECT c.entity_id, 
			       c.meta_number, e.name,
			       l.line_one as address1, l.line_two as address2, 
			       l.line_three as address3,
			       l.city_province, l.mail_code,
			       country.name as country, 
			       '' as contact_name, '' as email,
		               '' as phone, '' as fax, 
		               a.invnumber, a.transdate, a.till, a.ordnumber, 
			       a.ponumber, a.notes, 
			       CASE WHEN 
			                 EXTRACT(days FROM age(a.transdate)/30) 
			                 = 0
			                 THEN (a.amount - a.paid) ELSE 0 END
			            as c0, 
			       CASE WHEN EXTRACT(days FROM age(a.transdate)/30)
			                 = 1
			                 THEN (a.amount - a.paid) ELSE 0 END
			            as c30, 
			       CASE WHEN EXTRACT(days FROM age(a.transdate)/30)
			                 = 2
			                 THEN (a.amount - a.paid) ELSE 0 END
			            as c60, 
			       CASE WHEN EXTRACT(days FROM age(a.transdate)/30)
			                 > 2
			                 THEN (a.amount - a.paid) ELSE 0 END
			            as c90, 
			       a.duedate, a.id, a.curr,
			       (SELECT buy FROM exchangerate ex
			         WHERE a.curr = ex.curr
			              AND ex.transdate = a.transdate) 
			       AS exchangerate,
				(SELECT compound_array(ARRAY[[p.partnumber,
						i.description, i.qty::text]])
					FROM parts p 
					JOIN invoice i ON (i.parts_id = p.id)
					WHERE i.trans_id = a.id) AS line_items
			  FROM ar a
			  JOIN entity_credit_account c USING (entity_id)
			  JOIN entity e ON (e.id = c.entity_id)
			 CROSS JOIN location l
			  JOIN country ON (country.id = l.country_id)
			 WHERE a.entity_id like coalesce(in_entity_id::text, '%')
				AND l.id = (SELECT min(location_id) 
					FROM company_to_location 
					WHERE company_id = (select min(id) 
						FROM company
						WHERE entity_id = c.entity_id))
			ORDER BY entity_id, curr, transdate, invnumber
		LOOP
			return next item;
		END LOOP;
	ELSE
		RAISE EXCEPTION 'Entity Class % unsupported in aging report', 
			in_entity_class;
	END IF;
END;
$$ language plpgsql;

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
(in_reference text, in_accno text, in_source text, in_memo text, 
in_description text, in_date_from date, in_date_to date, in_approved bool,
in_amount_from numeric, in_amount_to numeric, in_business_units int[])
RETURNS SETOF gl_report_item AS
$$
DECLARE 
         retval gl_report_item;
         t_balance numeric;
         t_chart_id int;
BEGIN

IF in_date_from IS NULL THEN
   t_balance := 0;
ELSIF in_accno IS NOT NULL THEN
   SELECT id INTO t_chart_id FROM account WHERE accno  = in_accno;
   t_balance := account__obtain_balance(in_date_from, t_accno);
ELSE
   t_balance := null;
END IF;

FOR retval IN
       SELECT g.id, g.type, g.invoice, g.reference, g.description, ac.transdate,
              ac.source, ac.amount, c.accno, c.gifi_accno, 
              g.till, ac.cleared, ac.memo, c.description AS accname, 
              ac.chart_id, ac.entry_id, 
              sum(ac.amount) over (rows unbounded preceding) + t_balance 
                as running_balance,
              compound_array(ARRAY[ARRAY[bac.class_id, bac.bu_id]])
         FROM (select id, 'gl', false, reference, description, 
                      null::text as till 
                 FROM gl
               UNION
               SELECT id, 'ar', invoice, invnumber, e.name, till
                 FROM ar
                 JOIN entity_credit_account eca ON ar.entity_credit_account
                      = eca.id
                 JOIN entity e ON e.id = eca.entity_id
               UNION
               SELECT id, 'ap', invoice, invnumber, e.name, null as till
                 FROM ap
                 JOIN entity_credit_account eca ON ap.entity_credit_account 
                      = eca.id
                 JOIN entity e ON e.id = eca.entity_id) g
         JOIN acc_trans ac ON ac.trans_id = g.id
         JOIN chart c ON ac.chart_id = c.id
        WHERE (g.reference ilike in_reference || '%' or in_reference is null)
              AND (c.accno = in_accno OR in_accno IS NULL)
              AND (ac.source ilike '%' || in_source || '%' 
                   OR in_source is null)
              AND (ac.memo ilike '%' || in_memo || '%' OR in_memo is null)
              AND (in_description IS NULL OR
                  to_tsvector(get_default_lang()::name, g.description)
                  @@
                  plainto_tsquery(get_default_lang()::name, in_description))
              AND (transdate BETWEEN in_date_from AND in_date_to
                   OR (transdate >= in_date_from AND in_date_to IS NULL)
                   OR (transdate <= in_date_to AND in_date_from IS NULL))
              AND (in_approved is false OR (g.approved AND ac.approved))
              AND (in_amount_from IS NULL OR ac.amount >= in_amount_from)
              AND (in_amount_to IS NULL OR ac_amount <= in_amount_to)
     GROUP BY g.id, g.type, g.invoice, g.reference, g.description, ac.transdate,
              ac.source, ac.amount, c.accno, c.gifi_accno,
              g.till, ac.cleared, ac.memo, c.description,
              ac.chart_id, ac.entry_id
       HAVING in_business_units <@ as_array(bac.bu_id)
     ORDER BY ac.transdate, g.trans_id, c.accno
LOOP
   RETURN NEXT retval;
END LOOP;


END;
$$ language plpgsql;

COMMIT;
