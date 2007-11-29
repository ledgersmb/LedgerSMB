-- payment_get_open_accounts and the option to get all accounts need to be
-- refactored and redesigned.  -- CT
CREATE OR REPLACE FUNCTION payment_get_open_accounts(in_account_class int) 
returns SETOF entity AS
$$
DECLARE out_entity entity%ROWTYPE;
BEGIN
	FOR out_entity IN
		SELECT ec.id, e.name, e.entity_class, e.created 
		FROM entity e
		JOIN entity_credit_account ec ON (ec.entity_id = e.id)
			WHERE ec.entity_class = in_account_class
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

COMMENT ON FUNCTION payment_get_open_accounts(int) IS
$$ This function takes a single argument (1 for vendor, 2 for customer as 
always) and returns all entities with open accounts of the appropriate type. $$;

CREATE OR REPLACE FUNCTION payment_get_all_accounts(in_account_class int) 
RETURNS SETOF entity AS
$$
DECLARE out_entity entity%ROWTYPE;
BEGIN
	FOR out_entity IN
		SELECT  ec.id, 
			e.name, e.entity_class, e.created 
		FROM entity e
		JOIN entity_credit_account ec ON (ec.entity_id = e.id)
				WHERE e.entity_class = in_account_class
	LOOP
		RETURN NEXT out_entity;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_open_accounts(int) IS
$$ This function takes a single argument (1 for vendor, 2 for customer as 
always) and returns all entities with accounts of the appropriate type. $$;


CREATE TYPE payment_invoice AS (
	invoice_id int,
	invnumber text,
	invoice_date date,
	amount numeric,
	discount numeric,
	due numeric
);

CREATE OR REPLACE FUNCTION payment_get_open_invoices
(in_account_class int, in_entity_credit_id int, in_curr char(3))
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
		       AND a.amount - a.paid <> 0
		       AND a.curr = in_curr
		       AND a.entity_id = coalesce(in_entity_id, a.entity_id)
	LOOP
		RETURN NEXT payment_inv;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_open_invoices(int, int, char(3)) IS
$$ This function takes three arguments:
Type: 1 for vendor, 2 for customer
Entity_id:  The entity_id of the customer or vendor
Currency:  3 characters for currency ('USD' for example).
Returns all open invoices for the entity in question. $$;

CREATE TYPE payment_contact_invoice AS (
	contact_id int,
	contact_name text,
	account_number text,
	total_due numeric,
	invoices text[]
);

CREATE OR REPLACE FUNCTION payment_get_all_contact_invoices
(in_account_class int, in_business_type int, in_currency char(3),
	in_date_from date, in_date_to date, in_batch_id int, 
	in_ar_ap_accno text)
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
		              (CASE WHEN c.discount_terms 
		                        > extract('days' FROM age(a.transdate))
		                   THEN 0
		                   ELSE (a.amount - a.paid) * c.discount / 100
		              END))::text]]),
		              bool_and(lock_record(a.id, (select max(session_id) 				FROM "session" where users_id = (
					select id from users WHERE username =
					SESSION_USER))))
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
		    JOIN transactions t ON (a.id = t.id)
		   WHERE a.invoice_class = in_account_class
		         AND ((a.transdate >= in_date_from
		               AND a.transdate <= in_date_to)
		             OR a.id IN (select voucher.trans_id FROM voucher
		                          WHERE batch_id = in_batch_id))
		         AND c.entity_class = in_account_class
		         AND a.curr = in_currency
		         AND a.amount - a.paid <> 0
			 AND t.locked_by NOT IN 
				(select "session_id" FROM "session"
				WHERE users_id IN 
					(select id from users 
					where username <> SESSION_USER))
		         AND EXISTS (select trans_id FROM acc_trans
		                      WHERE trans_id = a.id AND
		                            chart_id = (SELECT id frOM chart
		                                         WHERE accno
		                                               = in_ar_ap_accno)
		                    )
		GROUP BY e.id, e.name, c.meta_number, c.threshold
		  HAVING sum(a.amount - a.paid) > c.threshold
	LOOP
		RETURN NEXT payment_item;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION payment_get_all_contact_invoices
(in_account_class int, in_business_type int, in_currency char(3),
        in_date_from date, in_date_to date, in_batch_id int, 
        in_ar_ap_accno text) IS
$$
This function takes the following arguments (all prefaced with in_ in the db):
account_class: 1 for vendor, 2 for customer
business_type: integer of business.id.
currency: char(3) of currency (for example 'USD')
date_from, date_to:  These dates are inclusive.
batch_id:  For payment batches, where fees are concerned.
ar_ap_accno:  The AR/AP account number.

This then returns a set of contact information with a 2 dimensional array 
cnsisting of outstanding invoices.
$$;

CREATE OR REPLACE FUNCTION payment_post 
(in_trans_id int, in_source text, in_amount numeric, in_ar_ap_accno text,
	in_cash_accno text, in_approved bool, in_payment_date date, 
	in_account_class int)
RETURNS INT AS
$$
DECLARE out_entry_id int;
BEGIN
	INSERT INTO acc_trans (chart_id, amount,
	            trans_id, transdate, approved, source)
	VALUES ((SELECT id FROM chart WHERE accno = in_ar_ap_accno), 
	        CASE WHEN in_account_class = 1 THEN in_amount * -1 
	             ELSE amount
	        END,
	        in_trans_id, in_payment_date, in_approved, in_source);

	INSERT INTO acc_trans (chart_id, amount,
	            trans_id, transdate, approved, source)
	VALUES ((SELECT id FROM chart WHERE accno = in_cash_accno), 
	        CASE WHEN in_account_class = 2 THEN in_amount * -1 
	             ELSE amount
	        END,
	        in_trans_id, in_payment_date, coalesce(in_approved, true), 
	        in_source);

	SELECT currval('acc_trans_entry_id_seq') INTO out_entry_id;
	RETURN out_entry_id;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_post 
(in_trans_id int, in_source text, in_amount numeric, in_ar_ap_accno text,
	in_cash_accno text, in_approved bool, in_payment_date date, 
        in_account_class int)
IS $$
This function takes the following arguments (prefaced with in_ in the db):
trans_id:  Id for ar/ap transaction.
source: text for source documnet identifier (for example, check number)
amount:  numeric for the amount of the transaction
ar_ap_accno:  AR/AP account number
cash_accno:  Cash Account number, i.e. the account where the payment will be 
held
approved:  False, for a voucher.

This function posts the payment or saves the payment voucher. 
$$;


-- Move this to the projects module when we start on that. CT
CREATE OR REPLACE FUNCTION project_list_open(in_date date) 
RETURNS SETOF project AS
$$
DECLARE out_project project%ROWTYPE;
BEGIN
	FOR out_project IN
		SELECT * from project
		WHERE startdate <= in_date AND enddate >= in_date
		      AND completed = 0
	LOOP
		return next out_project;
	END LOOP;
END;
$$ language plpgsql;

comment on function project_list_open(in_date date) is
$$ This function returns all projects that were open as on the date provided as
the argument.$$;



-- Move this to the projects module when we start on that. CT
CREATE OR REPLACE FUNCTION department_list(in_role char)
RETURNS SETOF department AS
$$
DECLARE out_department department%ROWTYPE;
BEGIN
       FOR out_department IN
               SELECT * from department
               WHERE role = in_role
       LOOP
               return next out_department;
       END LOOP;
END;
$$ language plpgsql;

comment on function department_list(in_role char) is
$$ This function returns all department that match the role provided as
the argument.$$;

CREATE OR REPLACE FUNCTION payments_get_open_currencies(in_account_class int)
RETURNS SETOF char(3) AS
$$
DECLARE resultrow record;
BEGIN
        FOR resultrow IN
          SELECT curr FROM ar
          WHERE amount <> paid
          OR paid IS NULL
          AND in_account_class=2 
          UNION
          SELECT curr FROM ap
          WHERE amount <> paid
          OR paid IS NULL
          AND in_account_class=1
          ORDER BY curr
          LOOP
         return next resultrow.curr;
        END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION currency_get_exchangerate(in_currency char(3), in_date date, in_account_class int) 
RETURNS NUMERIC AS
$$
DECLARE 
    out_exrate exchangerate.buy%TYPE;

    BEGIN 
        IF in_account_class = 1 THEN
          SELECT INTO out_exrate buy 
          FROM exchangerate
          WHERE transdate = in_date AND curr = in_currency;
        ELSE 
          SELECT INTO out_exrate sell 
          FROM exchangerate
          WHERE transdate = in_date AND curr = in_currency;   
        END IF;
        RETURN out_exrate;
    END;
$$ language plpgsql;                                                                  
COMMENT ON FUNCTION currency_get_exchangerate(in_currency char(3), in_date date, in_account_class int) IS
$$ This function return the exchange rate of a given currency, date and exchange rate class (buy or sell). $$;


CREATE OR REPLACE FUNCTION payment_get_vc_info(in_entity_id int) 
RETURNS SETOF entity AS
$$
DECLARE 
    out_info entity%ROWTYPE;

    BEGIN
        FOR out_info IN
  
            SELECT e.id, e.name FROM entity e
            JOIN company c ON (e.id = c.entity_id)
            WHERE e.id = in_entity_id
          
          --SELECT e.id, c.legal_name, l.line_one, l.city_province, cy.name FROM entity e
          --JOIN company c ON (e.id = c.entity_id)
          --JOIN company_to_location cl ON (c.id = cl.company_id)
          --JOIN location l ON (l.id = cl.location_id)
          --JOIN country cy ON (cy.id = l.country_id)
        LOOP
          return next out_info;
        END LOOP;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'ID % not found!!!!!', in_entity_id;
        END IF;                              
              
    END;
$$ language plpgsql;                                                                  
COMMENT ON FUNCTION payment_get_vc_info(in_entity_id int) IS
$$ This function return vendor or customer info, its under construction $$;
