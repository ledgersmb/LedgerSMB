
CREATE OR REPLACE FUNCTION payment_get_open_accounts(in_account_class int) 
returns SETOF entity AS
$$
DECLARE out_entity entity%ROWTYPE;
BEGIN
	FOR out_entity IN
		SELECT * FROM entity 
		WHERE id IN (SELECT entity_id FROM entity_credit_account
				WHERE entity_class = in_account_class)
		      AND CASE WHEN in_account_class = 1 THEN
				id IN (SELECT entity_id FROM ap 
					WHERE amount <> paid
					GROUP BY entity_id)
			       WHEN in_account_class = 2 THEN
				id IN (SELECT entity_id FROM ar
					WHERE amount <> paid
					GROUP BY entity_id)
			  END
	LOOP
		RETURN NEXT out_entity;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION get_all_accounts(in_account_class int) 
RETURNS SETOF entity AS
$$
DECLARE out_entity entity%ROWTYPE;
BEGIN
	FOR out_entity IN
		SELECT * FROM entity
		WHERE id IN (seLECT entity_id FROM entity_credit_account
				WHERE entity_class = in_account_class)
	LOOP
		RETURN NEXT out_entity;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE TYPE payment_invoice AS (
	invoice_id int,
	invnumber text,
	invoice_date date,
	amount numeric,
	discount numeric,
	due numeric
);

CREATE OR REPLACE FUNCTION payment_get_open_invoices
(in_account_class int, in_entity_id int, in_currency char(3))
RETURNS SETOF payment_invoice AS
$$
DECLARE payment_inv payment_invoice;
BEGIN
	FOR payment_inv IN
		SELECT a.id AS invoice_id, a.invnumber, 
		       a.transdate AS invoice_date, a.amount, 
		       CASE WHEN discount_terms 
		                 > extract('days' FROM age(a.transdate))
		            THEN 0
		            ELSE (a.amount - a.paid) * c.discount / 100  
		       END AS discount,
		       a.amount - a.paid - 
		       CASE WHEN discount_terms 
		                 > extract('days' FROM age(a.transdate))
		            THEN 0
		            ELSE (a.amount - a.paid) * c.discount / 100  
		       END AS due
		  FROM (SELECT id, invnumber, transdate, amount, entity_id,
		               1 as invoice_class, paid, curr
		          FROM ap
                         UNION
		        SELECT id, invnumber, transdate, amount, entity_id,
		               2 AS invoice_class, paid, curr
		          FROM ar
		       ) a
		  JOIN entity_credit_account c USING (entity_id)
		 WHERE a.invoice_class = in_account_class
		       AND c.entity_class = in_account_class
		       AND a.curr = in_currency
	LOOP
		RETURN NEXT payment_inv;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE TYPE payment_contact_invoice AS (
	contact_id int,
	contact_name text,
	account_number text,
	total_due numeric,
	invoices text[]
);

CREATE OR REPLACE FUNCTION payment_get_all_contact_invoices
(in_account_class int, in_business_type int, in_currency char(3),
	in_date_from date, in_date_to date, in_batch_id int)
RETURNS SETOF payment_contact_invoice AS
$$
DECLARE payment_item payment_contact_invoice;
BEGIN
	FOR payment_item IN
		  SELECT e.id AS contact_id, e.name AS contact_name,
		         c.meta_number AS account_number,
		         sum(a.amount - a.paid) AS total_due, 
		         compound_array(ARRAY[[
		              a.id::text, a.invnumber, a.transdate::text, 
		              a.amount::text, 
		              (CASE WHEN c.discount_terms 
		                        > extract('days' FROM age(a.transdate))
		                   THEN 0
		                   ELSE (a.amount - a.paid) * c.discount / 100
		              END)::text, 
		              (a.amount - a.paid -
		              CASE WHEN c.discount_terms 
		                        > extract('days' FROM age(a.transdate))
		                   THEN 0
		                   ELSE (a.amount - a.paid) * c.discount / 100
		              END)::text]]) 
		    FROM entity e
		    JOIN entity_credit_account c ON (e.id = c.entity_id)
		    JOIN (SELECT id, invnumber, transdate, amount, entity_id, 
		                 paid, curr, 1 as invoice_class 
		            FROM ap
		           UNION
		          SELECT id, invnumber, transdate, amount, entity_id,
		                 paid, curr, 2 as invoice_class
		            FROM ar
		         ) a USING (entity_id)
		   WHERE a.invoice_class = in_account_class
		         AND ((a.transdate >= in_date_from
		               AND a.transdate <= in_date_to)
		             OR a.id IN (select voucher.trans_id FROM voucher
		                          WHERE batch_id = in_batch_id))
		         AND c.entity_class = in_account_class
		         AND a.curr = in_currency
		GROUP BY e.id, e.name, c.meta_number, c.threshold
		  HAVING sum(amount - a.paid) > c.threshold
	LOOP
		RETURN NEXT payment_item;
	END LOOP;
END;
$$ LANGUAGE plpgsql;


