-- payment_get_open_accounts and the option to get all accounts need to be
-- refactored and redesigned.  -- CT
CREATE OR REPLACE FUNCTION payment_get_open_accounts(in_account_class int) 
returns SETOF entity AS
$$
DECLARE out_entity entity%ROWTYPE;
BEGIN
	FOR out_entity IN
		SELECT ec.id, cp.legal_name as name, e.entity_class, e.created 
		FROM entity e
		JOIN entity_credit_account ec ON (ec.entity_id = e.id)
		JOIN company cp ON (cp.entity_id = e.id)
			WHERE ec.entity_class = in_account_class
		      AND CASE WHEN in_account_class = 1 THEN
				e.id IN (SELECT entity_id FROM ap 
					WHERE amount <> paid
					GROUP BY entity_id)
			       WHEN in_account_class = 2 THEN
				e.id IN (SELECT entity_id FROM ar
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
(in_account_class int,
 in_entity_credit_id int,
 in_curr char(3),
 in_datefrom date, 
 in_dateto date,
 in_amountfrom numeric,
 in_amountto   numeric,
 in_department_id int)
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
		       END
		        AS due
		  FROM (SELECT id, invnumber, transdate, amount, entity_id,
		               1 as invoice_class, paid, curr, 
		               entity_credit_account, department_id
		          FROM ap
                         UNION
		        SELECT id, invnumber, transdate, amount, entity_id,
		               2 AS invoice_class, paid, curr,
		               entity_credit_account, department_id
		          FROM ar
		       ) a
		  JOIN entity_credit_account c ON (c.id = a.entity_credit_account
			OR (a.entity_credit_account IS NULL and 
				a.entity_id = c.entity_id))
		 WHERE a.invoice_class = in_account_class
		       AND c.entity_class = in_account_class
		       AND a.amount - a.paid <> 0
		       AND a.curr = in_curr
		       AND (a.transdate >= in_datefrom 
		            OR in_datefrom IS NULL)
		       AND (a.transdate <= in_dateto
		            OR in_dateto IS NULL)
		       AND (a.amount >= in_amountfrom 
		            OR in_amountfrom IS NULL)
		       AND (a.amount <= in_amountto
		            OR in_amountto IS NULL)
		       AND (a.department_id = in_department_id
		            OR in_department_id IS NULL)     
		                 
	LOOP
		RETURN NEXT payment_inv;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_open_invoices(int, int, char(3), date, date, numeric, numeric, int) IS
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
	invoices text[],
        has_vouchers int
);

CREATE OR REPLACE FUNCTION payment_get_all_contact_invoices
(in_account_class int, in_business_id int, in_currency char(3),
	in_date_from date, in_date_to date, in_batch_id int, 
	in_ar_ap_accno text)
RETURNS SETOF payment_contact_invoice AS
$$
DECLARE payment_item payment_contact_invoice;
BEGIN
	FOR payment_item IN
		  SELECT c.id AS contact_id, e.name AS contact_name,
		         c.meta_number AS account_number,
		         sum(p.due) AS total_due, 
		         compound_array(ARRAY[[
		              a.id::text, a.invnumber, a.transdate::text, 
		              a.amount::text, (a.amount - p.due)::text,
		              (CASE WHEN c.discount_terms 
		                        > extract('days' FROM age(a.transdate))
		                   THEN 0
		                   ELSE (a.amount - coalesce((a.amount - p.due), 0)) * coalesce(c.discount, 0) / 100
		              END)::text, 
		              (coalesce(p.due, 0) -
		              (CASE WHEN c.discount_terms 
		                        > extract('days' FROM age(a.transdate))
		                   THEN 0
		                   ELSE (coalesce(p.due, 0)) * coalesce(c.discount, 0) / 100
		              END))::text]]),
                              sum(case when a.batch_id = in_batch_id then 1
		                  else 0 END),
		              bool_and(lock_record(a.id, (select max(session_id) 				FROM "session" where users_id = (
					select id from users WHERE username =
					SESSION_USER))))
                           
		    FROM entity e
		    JOIN entity_credit_account c ON (e.id = c.entity_id)
		    JOIN (SELECT ap.id, invnumber, transdate, amount, entity_id, 
				 paid, curr, 1 as invoice_class, 
		                 entity_credit_account, on_hold, v.batch_id
		            FROM ap
		       LEFT JOIN (select * from voucher where batch_class = 1) v 
			         ON (ap.id = v.trans_id)
			   WHERE in_account_class = 1
			         AND (v.batch_class = 1 or v.batch_id IS NULL)
		           UNION
		          SELECT ar.id, invnumber, transdate, amount, entity_id,
		                 paid, curr, 2 as invoice_class, 
		                 entity_credit_account, on_hold, v.batch_id
		            FROM ar
		       LEFT JOIN (select * from voucher where batch_class = 2) v 
			         ON (ar.id = v.trans_id)
			   WHERE in_account_class = 2
			         AND (v.batch_class = 2 or v.batch_id IS NULL)
			ORDER BY transdate
		         ) a ON (a.entity_credit_account = c.id)
		    JOIN transactions t ON (a.id = t.id)
		    JOIN (SELECT trans_id, 
		                 sum(CASE WHEN in_account_class = 1 THEN amount
		                          WHEN in_account_class = 2 
		                          THEN amount * -1
		                     END) AS due 
		            FROM acc_trans 
		            JOIN chart ON (chart.id = acc_trans.chart_id)
		           WHERE ((chart.link = 'AP' AND in_account_class = 1)
		                 OR (chart.link = 'AR' AND in_account_class = 2))
		        GROUP BY trans_id) p ON (a.id = p.trans_id)
		   WHERE a.batch_id = in_batch_id
		          OR (a.invoice_class = in_account_class
			 AND c.business_id = 
				coalesce(in_business_id, c.business_id)
		         AND ((a.transdate >= COALESCE(in_date_from, a.transdate)
		               AND a.transdate <= COALESCE(in_date_to, a.transdate)))
		         AND c.entity_class = in_account_class
		         AND a.curr = in_currency
		         AND a.entity_credit_account = c.id
			 AND p.due <> 0
		         AND a.amount <> a.paid 
			 AND NOT a.on_hold
			 AND NOT (t.locked_by IS NOT NULL AND t.locked_by IN 
				(select "session_id" FROM "session"
				WHERE users_id IN 
					(select id from users 
					where username <> SESSION_USER)))
		         AND EXISTS (select trans_id FROM acc_trans
		                      WHERE trans_id = a.id AND
		                            chart_id = (SELECT id frOM chart
		                                         WHERE accno
		                                               = in_ar_ap_accno)
		                    ))
		GROUP BY c.id, e.name, c.meta_number, c.threshold
		  HAVING sum(p.due) > c.threshold
			OR sum(case when a.batch_id = in_batch_id then 1
                                  else 0 END) > 0
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
1;3B
batch_id:  For payment batches, where fees are concerned.
ar_ap_accno:  The AR/AP account number.

This then returns a set of contact information with a 2 dimensional array 
cnsisting of outstanding invoices.
$$;

CREATE OR REPLACE FUNCTION payment_bulk_queue
(in_transactions numeric[], in_batch_id int, in_source text, in_total numeric,
	in_ar_ap_accno text, in_cash_accno text, 
	in_payment_date date, in_account_class int)
returns int as
$$
BEGIN
	INSERT INTO payments_queue
	(transactions, batch_id, source, total, ar_ap_accno, cash_accno,
		payment_date, account_class)
	VALUES 
	(in_transactions, in_batch_id, in_source, in_total, in_ar_ap_accno,
		in_cash_accno, in_payment_date, in_account_class);

	RETURN array_upper(in_transactions, 1) - 
		array_lower(in_transactions, 1);
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION job__process_payment(in_job_id int)
RETURNS bool AS $$
DECLARE 
	queue_record RECORD;
	t_auth_name text;
	t_counter int;
BEGIN
	-- TODO:  Move the set session authorization into a utility function
	SELECT entered_by INTO t_auth_name FROM pending_job
	WHERE id = in_job_id;

	EXECUTE 'SET SESSION AUTHORIZATION ' || quote_ident(t_auth_name);

	t_counter := 0;
	
	FOR queue_record IN 
		SELECT * 
		FROM payments_queue WHERE job_id = in_job_id
	LOOP
		PERFORM payment_bulk_post
			(queue_record.transactions, queue_record.batch_id, 
				queue_record.source, queue_record.total, 
				queue_record.ar_ap_accno, 
				queue_record.cash_accno, 
				queue_record.payment_date, 
				queue_record.account_class);

		t_counter := t_counter + 1;
		RAISE NOTICE 'Processed record %, starting transaction %', 
			t_counter, queue_record.transactions[1][1];
	END LOOP;	
	DELETE FROM payments_queue WHERE job_id = in_job_id;

	UPDATE pending_job
	SET completed_at = timeofday()::timestamp,
	    success = true
	WHERE id = in_job_id;
	RETURN TRUE;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION job__create(in_batch_class int, in_batch_id int)
RETURNS int AS
$$
BEGIN
	INSERT INTO pending_job (batch_class, batch_id)
	VALUES (coalesce(in_batch_class, 3), in_batch_id);

	RETURN currval('pending_job_id_seq');
END;
$$ LANGUAGE PLPGSQL;

CREATE TYPE job__status AS (
	completed int, -- 1 for completed, 0 for no
	success int, -- 1 for success, 0 for no
	completed_at timestamp,
	error_condition text -- error if not successful
);

CREATE OR REPLACE FUNCTION job__status(in_job_id int) RETURNS job__status AS
$$
DECLARE out_row job__status;
BEGIN
	SELECT  (completed_at IS NULL)::INT, success::int, completed_at,
		error_condition
	INTO out_row 
	FROM pending_job
	WHERE id = in_job_id;

	RETURN out_row;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION payment_bulk_post
(in_transactions numeric[], in_batch_id int, in_source text, in_total numeric,
	in_ar_ap_accno text, in_cash_accno text, 
	in_payment_date date, in_account_class int)
RETURNS int AS
$$
DECLARE 
	out_count int;
	t_voucher_id int;
	t_trans_id int;
	t_amount numeric;
        t_ar_ap_id int;
	t_cash_id int;
BEGIN
	IF in_batch_id IS NULL THEN
		-- t_voucher_id := NULL;
		RAISE EXCEPTION 'Bulk Post Must be from Batch!';
	ELSE
		INSERT INTO voucher (batch_id, batch_class, trans_id)
		values (in_batch_id, 3, in_transactions[1][1]);

		t_voucher_id := currval('voucher_id_seq');
	END IF;

	select id into t_ar_ap_id from chart where accno = in_ar_ap_accno;
	select id into t_cash_id from chart where accno = in_cash_accno;

	FOR out_count IN 
			array_lower(in_transactions, 1) ..
			array_upper(in_transactions, 1)
	LOOP
		INSERT INTO acc_trans 
			(trans_id, chart_id, amount, approved, voucher_id,
			transdate, source)
		VALUES
			(in_transactions[out_count][1], 
				case when in_account_class = 1 THEN t_cash_id
				WHEN in_account_class = 2 THEN t_ar_ap_id
				ELSE -1 END,

				in_transactions[out_count][2],
	
				CASE WHEN t_voucher_id IS NULL THEN true
				ELSE false END,
				t_voucher_id, in_payment_date, in_source);

		INSERT INTO acc_trans 
			(trans_id, chart_id, amount, approved, voucher_id,
			transdate, source)
		VALUES
			(in_transactions[out_count][1], 
				case when in_account_class = 1 THEN t_ar_ap_id
				WHEN in_account_class = 2 THEN t_cash_id
				ELSE -1 END,

				in_transactions[out_count][2]* -1,

				CASE WHEN t_voucher_id IS NULL THEN true
				ELSE false END,
				t_voucher_id, in_payment_date, in_source);
		UPDATE ap 
		set paid = paid +in_transactions[out_count][2]
		where id =in_transactions[out_count][1];
	END LOOP;
	return out_count;
END;
$$ language plpgsql;

COMMENT ON FUNCTION payment_bulk_post
(in_transactions numeric[], in_batch_id int, in_source text, in_total numeric,
        in_ar_ap_accno text, in_cash_accno text, 
        in_payment_date date, in_account_class int)
IS
$$ Note that in_transactions is a two-dimensional numeric array.  Of each 
sub-array, the first element is the (integer) transaction id, and the second
is the amount for that transaction.  If the total of the amounts do not add up 
to in_total, then an error is generated. $$;


CREATE OR REPLACE FUNCTION payment_post 
(in_payment_date   date,
 in_account_class  int,
 in_person_id      int,
 in_currency       char(3),
 in_notes          text,
 in_department     int,
 in_gl_description text,
 in_cash_accno     int[],
 in_cash_amount    int[],
 in_cash_approved  bool[],
 in_cash_source    text[],
 in_accno          int[],
 in_amount         int[],
 in_approved       bool[],
 in_source         text[],
 in_transaction_id int[],
 in_type           int[],
 in_approved bool)
RETURNS INT AS
$$
DECLARE var_payment_id int;
DECLARE var_gl_id int;
DECLARE var_entry_id int[];
DECLARE out_count int;

BEGIN
        -- FIRST WE HAVE TO INSERT THE PAYMENT
        -- THE ID IS GENERATED BY payment_id_seq
        --
   	INSERT INTO payment (reference, payment_class, payment_date,
	                      person_id, currency, notes, department_id) 
	VALUES ((CASE WHEN in_account_class = 1 THEN
	                                setting_increment('rcptnumber') -- I FOUND THIS ON sql/modules/Settings.sql 
			             ELSE 						-- and it is very usefull				
			                setting_increment('paynumber') 
			             END),
	         in_account_class, in_payment_date, in_person_id,
                 in_currency, in_notes, in_department);
        SELECT currval('payment_id_seq') INTO var_payment_id; -- WE'LL NEED THIS VALUE TO USE payment_link table
        -- SECOND WE HAVE TO MAKE THE GL TO HOLD THE TRANSACTIONS
        -- THE ID IS GENERATED BY gl_id_seq
        --
        INSERT INTO gl (reference, description, transdate,
	                      person_id, notes, approved, department_id) 
	VALUES (setting_increment('glnumber'),
	         in_gl_description, in_payment_date, in_person_id,
                 in_notes, in_department, coalesce(in_approved, true));
        SELECT currval('id') INTO var_gl_id; -- WE'LL NEED THIS VALUE TO JOIN WITH PAYMENT
        -- NOW COMES THE HEAVY PART, STORING ALL THE POSSIBLE TRANSACTIONS... 
        --
        -- FIRST WE SHOULD INSERT THE CASH ACCOUNTS
        --
        -- WE SHOULD HAVE THE DATA STORED AS (ACCNO, AMOUNT), SO
	FOR out_count IN 
			array_lower(in_cash_accno, 1) ..
			array_upper(in_cash_accno, 1)
	LOOP
	        INSERT INTO acc_trans (chart_id, amount,
		                       trans_id, transdate, approved, source)
		VALUES ((SELECT id FROM chart WHERE accno = in_cash_accno[out_count]), 
		        CASE WHEN in_account_class = 2 THEN in_cash_amount[out_count] * -1 
		        ELSE in_cash_amount[out_count]
		        END,
		        var_gl_id, in_payment_date, coalesce(in_cash_approved[1], true), 
		        in_cash_source[out_count]);
		        --SELECT currval('acc_trans_entry_id_seq') INTO var_entry_id[out_count];--WE'LL NEED THIS FOR THE PAYMENT_LINK
	END LOOP;
	--
	-- NOW LETS HANDLE THE AR/AP/OVERPAYMENT ACCOUNT
	--
	FOR var_count IN
		     array_lower(in_accno, 1) ..
		     array_upper(in_accno, 1)
	LOOP
	        INSERT INTO acc_trans (chart_id, amount,
		                       trans_id, transdate, approved, source)
		VALUES ((SELECT id FROM chart WHERE accno = in_accno[out_count]), 
		        CASE WHEN in_account_class = 2 THEN in_amount[out_count] * -1 
		        ELSE in_amount[out_count]
		        END,
		        var_gl_id, in_payment_date, coalesce(in_approved[1], true), 
		        in_source[out_count]);
	-- 
	-- WE WILL INSERT THE LINK INTO PAYMENT_LINKS NOW
	--	        
		INSERT INTO payment_links 
		VALUES (var_payment_id, currval(acc_trans_entry_id_seq),
		                                  in_transaction_id[out_count], in_type[var_count]);
	END LOOP;
       return 0;
END;
$$ LANGUAGE PLPGSQL;
-- I HAVE TO MAKE A COMMENT ON THIS FUNCTION
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
               WHERE role = coalesce(in_role, role)
       LOOP
               return next out_department;
       END LOOP;
END;
$$ language plpgsql;
-- Move this into another module.

comment on function department_list(in_role char) is
$$ This function returns all department that match the role provided as
the argument.$$;

CREATE OR REPLACE FUNCTION payments_get_open_currencies(in_account_class int)
RETURNS SETOF char(3) AS
$$
DECLARE resultrow record;
BEGIN
        FOR resultrow IN
          SELECT curr AS curr FROM ar
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

--
--  payment_location_result has the same arch as location_result, except for one field 
--  This should be unified on the API when we get things working - David Mora
--
CREATE TYPE payment_location_result AS (
        id int,
        line_one text,
        line_two text,
        line_three text,
        city text,
        state text,
	mail_code text,
        country text,
        class text
);


--
--  payment_get_vc_info has the same arch as company__list_locations, except for the filtering capabilities 
--  This should be unified on the API when we get things working - David Mora
--
CREATE OR REPLACE FUNCTION payment_get_vc_info(in_entity_id int, in_location_class_id int)
RETURNS SETOF payment_location_result AS
$$
DECLARE out_row RECORD;
	BEGIN
		FOR out_row IN
                SELECT l.id, l.line_one, l.line_two, l.line_three, l.city,
                       l.state, l.mail_code, c.name, lc.class
                FROM location l
                JOIN company_to_location ctl ON (ctl.location_id = l.id)
                JOIN company cp ON (ctl.company_id = cp.id)
                JOIN location_class lc ON (ctl.location_class = lc.id)
                JOIN country c ON (c.id = l.country_id)
                WHERE cp.entity_id = in_entity_id AND
                      lc.id = in_location_class_id
                ORDER BY lc.id, l.id, c.name
                LOOP
                	RETURN NEXT out_row;
		END LOOP;
	END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_vc_info(in_entity_id int, in_location_class_id int) IS
$$ This function returns vendor or customer info $$;

CREATE TYPE payment_record AS (
	amount numeric,
	meta_number text,
        credit_id int,
	company_paid text,
	accounts text[],
        source text,
        date_paid date
);

CREATE OR REPLACE FUNCTION payment__search 
(in_source text, in_date_from date, in_date_to date, in_credit_id int, 
	in_cash_accno text, in_account_class int)
RETURNS SETOF payment_record AS
$$
DECLARE 
	out_row payment_record;
BEGIN
	FOR out_row IN 
		select sum(CASE WHEN c.entity_class = 1 then a.amount
				ELSE a.amount * -1 END), c.meta_number, 
			c.id, co.legal_name,
			compound_array(ARRAY[ARRAY[ch.id::text, ch.accno, 
				ch.description]]), a.source, a.transdate
		FROM entity_credit_account c
		JOIN ( select entity_credit_account, id
			FROM ar WHERE in_account_class = 2
			UNION
			SELECT entity_credit_account, id
			FROM ap WHERE in_account_class = 1
			) arap ON (arap.entity_credit_account = c.id)
		JOIN acc_trans a ON (arap.id = a.trans_id)
		JOIN chart ch ON (ch.id = a.chart_id)
		JOIN company co ON (c.entity_id = co.entity_id)
		WHERE (ch.accno = in_cash_accno)
			AND (c.id = in_credit_id OR in_credit_id IS NULL)
			AND (a.transdate >= in_date_from 
				OR in_date_from IS NULL)
			AND (a.transdate <= in_date_to OR in_date_to IS NULL)
			AND (source = in_source OR in_source IS NULL)
		GROUP BY c.meta_number, c.id, co.legal_name, a.transdate, 
			a.source
		ORDER BY a.transdate, c.meta_number, a.source
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION payment__reverse
(in_source text, in_date_paid date, in_credit_id int, in_cash_accno text, 
	in_date_reversed date, in_account_class int, in_batch_id int)
RETURNS INT 
AS $$
DECLARE
	pay_row record;
        t_voucher_id int;
        t_voucher_inserted bool;
BEGIN
        IF in_batch_id IS NOT NULL THEN
		t_voucher_id := nextval('voucher_id_seq');
		t_voucher_inserted := FALSE;
	END IF;
	FOR pay_row IN 
		SELECT a.*, c.ar_ap_account_id
		FROM acc_trans a
		JOIN (select id, entity_credit_account 
			FROM ar WHERE in_account_class = 2
			UNION
			SELECT id, entity_credit_account
			FROM ap WHERE in_account_class = 1
		) arap ON (a.trans_id = arap.id)
		JOIN entity_credit_account c 
			ON (arap.entity_credit_account = c.id)
		JOIN chart ch ON (a.chart_id = ch.id)
		WHERE coalesce(source, '') = coalesce(in_source, '')
			AND transdate = in_date_paid
			AND in_credit_id = c.id
			AND in_cash_accno = ch.accno
	LOOP
		IF in_batch_id IS NOT NULL 
			AND t_voucher_inserted IS NOT TRUE
		THEN
			INSERT INTO voucher 
			(id, trans_id, batch_id, batch_class)
			VALUES
			(t_voucher_id, pay_row.trans_id, in_batch_id,
				CASE WHEN in_account_class = 1 THEN 4
				     WHEN in_account_class = 2 THEN 7
				END);

			t_voucher_inserted := TRUE;
		END IF;

		INSERT INTO acc_trans
		(trans_id, chart_id, amount, transdate, source, memo, approved,
			voucher_id) 
		VALUES 
		(pay_row.trans_id, pay_row.chart_id, pay_row.amount * -1, 
			in_date_reversed, in_source, 'Reversing ' || 
			COALESCE(in_source, ''), 
			case when in_batch_id is not null then false 
			else true end, t_voucher_id);
		INSERT INTO acc_trans
		(trans_id, chart_id, amount, transdate, source, memo, approved,
			voucher_id) 
		VALUES 
		(pay_row.trans_id, pay_row.ar_ap_account_id, pay_row.amount,
			in_date_reversed, in_source, 'Reversing ' ||
			COALESCE(in_source, ''), 
			case when in_batch_id is not null then false 
			else true end, t_voucher_id);
		IF in_account_class = 1 THEN
			UPDATE ap SET paid = amount - 
				(SELECT sum(a.amount) 
				FROM acc_trans a
				JOIN chart c ON (a.chart_id = c.id)
				WHERE c.link = 'AP'
					AND trans_id = pay_row.trans_id
				) 
			WHERE id = pay_row.trans_id;
		ELSIF in_account_class = 2 THEN
			update ar SET paid = amount - 
				(SELECT sum(a.amount) 
				FROM acc_trans a
				JOIN chart c ON (a.chart_id = c.id)
				WHERE c.link = 'AR'
					AND trans_id = pay_row.trans_id
				) * -1
			WHERE id = pay_row.trans_id;
		ELSE
			RAISE EXCEPTION 'Unknown account class for payments %',
				in_account_class;
		END IF;
	END LOOP;
	RETURN 1;
END;
$$ LANGUAGE PLPGSQL;
