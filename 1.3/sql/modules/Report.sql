-- Unused currently and untested.  This is expected to be a basis for 1.4 work
-- not recommended for current usage.  Not documenting yet.  --CT


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
report_invoice_aging(in_entity_id int, in_entity_class int) 
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


