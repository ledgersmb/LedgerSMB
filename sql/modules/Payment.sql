BEGIN;

CREATE OR REPLACE FUNCTION payment_type__list() RETURNS SETOF payment_type AS
$$
DECLARE out_row payment_type%ROWTYPE;
BEGIN
	FOR out_row IN SELECT * FROM payment_type LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

DROP TYPE IF EXISTS payment_vc_info CASCADE;

CREATE TYPE payment_vc_info AS (
	id int,
	name text,
	entity_class int,
	discount int,
	meta_number character varying(32)
);

CREATE OR REPLACE FUNCTION payment_type__get_label(in_payment_type_id int) RETURNS SETOF payment_type AS
$$
DECLARE out_row payment_type%ROWTYPE;
BEGIN
	FOR out_row IN SELECT * FROM payment_type where id=in_payment_type_id LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_type__get_label(in_payment_type_id int) IS 
$$ Returns all information on a payment type by the id.  This should be renamed
to account for its behavior in future versions.$$;


CREATE OR REPLACE FUNCTION payment_get_entity_accounts
(in_account_class int,
 in_vc_name text,
 in_vc_idn  text)
 returns SETOF payment_vc_info AS
 $$
 DECLARE out_entity payment_vc_info;
 

 BEGIN
 	FOR out_entity IN
              SELECT ec.id, cp.legal_name || 
                     coalesce(':' || ec.description,'') as name, 
                     e.entity_class, ec.discount_account_id, ec.meta_number
 		FROM entity_credit_account ec
 		JOIN entity e ON (ec.entity_id = e.id)
 		JOIN company cp ON (cp.entity_id = e.id)
		WHERE ec.entity_class = in_account_class
		AND (cp.legal_name ilike coalesce('%'||in_vc_name||'%','%%') OR cp.tax_id = in_vc_idn)
	LOOP
		RETURN NEXT out_entity;
	END LOOP;
 END;
 $$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_entity_accounts
(in_account_class int,
 in_vc_name text,
 in_vc_idn  text) IS
$$ Returns a minimal set of information about customer or vendor accounts
as needed for discount calculations and the like.$$;

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
	           		ec.id IN (SELECT entity_credit_account FROM ap 
	           			WHERE amount <> paid
		   			GROUP BY entity_credit_account)
		    	       WHEN in_account_class = 2 THEN
		   		ec.id IN (SELECT entity_credit_account FROM ar
		   			WHERE amount <> paid
		   			GROUP BY entity_credit_account)
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

COMMENT ON FUNCTION payment_get_all_accounts(int) IS
$$ This function takes a single argument (1 for vendor, 2 for customer as 
always) and returns all entities with accounts of the appropriate type. $$;

DROP TYPE IF EXISTS payment_invoice CASCADE;

CREATE TYPE payment_invoice AS (
	invoice_id int,
	invnumber text,
	invoice_date date,
	amount numeric,
	amount_fx numeric,
	discount numeric,
	discount_fx numeric,
	due numeric,
	due_fx numeric,
	exchangerate numeric
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
		SELECT a.id AS invoice_id, a.invnumber AS invnumber, 
		       a.transdate AS invoice_date, a.amount AS amount, 
		       a.amount/
		       (CASE WHEN a.curr = (SELECT * from defaults_get_defaultcurrency())
                         THEN 1
		        ELSE
		        (CASE WHEN in_account_class = 2
		              THEN ex.buy
		              ELSE ex.sell END)
		        END) as amount_fx, 
		       (CASE WHEN c.discount_terms < extract('days' FROM age(a.transdate))
		        THEN 0
		        ELSE (coalesce(ac.due, a.amount)) * coalesce(c.discount, 0) / 100
		        END) AS discount,
		        (CASE WHEN c.discount_terms < extract('days' FROM age(a.transdate))
		        THEN 0
		        ELSE (coalesce(ac.due, a.amount)) * coalesce(c.discount, 0) / 100
		        END)/
		        (CASE WHEN a.curr = (SELECT * from defaults_get_defaultcurrency())
                         THEN 1
		        ELSE
		        (CASE WHEN in_account_class = 2
		              THEN ex.buy
		              ELSE ex.sell END)
		        END) as discount_fx,		        
		        ac.due - (CASE WHEN c.discount_terms < extract('days' FROM age(a.transdate))
		        THEN 0
		        ELSE (coalesce(ac.due, a.amount)) * coalesce(c.discount, 0) / 100
		        END) AS due,
		        (ac.due - (CASE WHEN c.discount_terms < extract('days' FROM age(a.transdate))
		        THEN 0 
		        ELSE (coalesce(ac.due, a.amount)) * coalesce(c.discount, 0) / 100
		        END))/
		        (CASE WHEN a.curr = (SELECT * from defaults_get_defaultcurrency())
                         THEN 1
		         ELSE
		         (CASE WHEN in_account_class = 2
		              THEN ex.buy
		              ELSE ex.sell END)
		         END) AS due_fx,
		        (CASE WHEN a.curr = (SELECT * from defaults_get_defaultcurrency())
		         THEN 1
		         ELSE
		        (CASE WHEN in_account_class = 2
		         THEN ex.buy
		         ELSE ex.sell END)
		         END) AS exchangerate
                 --TODO HV prepare drop entity_id from ap,ar
                 --FROM  (SELECT id, invnumber, transdate, amount, entity_id,
                 FROM  (SELECT id, invnumber, transdate, amount,
		               1 as invoice_class, paid, curr, 
		               entity_credit_account, department_id, approved
		          FROM ap
                         UNION
		         --SELECT id, invnumber, transdate, amount, entity_id,
		         SELECT id, invnumber, transdate, amount,
		               2 AS invoice_class, paid, curr,
		               entity_credit_account, department_id, approved
		         FROM ar
		         ) a 
		JOIN (SELECT trans_id, chart_id, sum(CASE WHEN in_account_class = 1 THEN amount
		                                  WHEN in_account_class = 2 
		                             THEN amount * -1
		                             END) as due
		        FROM acc_trans 
		        GROUP BY trans_id, chart_id) ac ON (ac.trans_id = a.id)
		        JOIN chart ON (chart.id = ac.chart_id)
		        LEFT JOIN exchangerate ex ON ( ex.transdate = a.transdate AND ex.curr = a.curr )         
		        JOIN entity_credit_account c ON (c.id = a.entity_credit_account)
                --        OR (a.entity_credit_account IS NULL and a.entity_id = c.entity_id))
	 	        WHERE ((chart.link = 'AP' AND in_account_class = 1)
		              OR (chart.link = 'AR' AND in_account_class = 2))
              	        AND a.invoice_class = in_account_class
		        AND c.entity_class = in_account_class
		        AND c.id = in_entity_credit_id
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
		        AND due <> 0 
		        AND a.approved = true         
		        GROUP BY a.invnumber, a.transdate, a.amount, amount_fx, discount, discount_fx, ac.due, a.id, c.discount_terms, ex.buy, ex.sell, a.curr
	LOOP
		RETURN NEXT payment_inv;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_open_invoices(int, int, char(3), date, date, numeric, numeric, int) IS
$$ This function is the base for get_open_invoice and returns all open invoices for the entity_credit_id
it has a lot of options to enable filtering and use the same logic for entity_class_id and currency. $$;

CREATE OR REPLACE FUNCTION payment_get_open_invoice
(in_account_class int,
 in_entity_credit_id int,
 in_curr char(3),
 in_datefrom date, 
 in_dateto date,
 in_amountfrom numeric,
 in_amountto   numeric,
 in_department_id int,
 in_invnumber text)
RETURNS SETOF payment_invoice AS
$$
DECLARE payment_inv payment_invoice;
BEGIN
	FOR payment_inv IN
		SELECT * from payment_get_open_invoices(in_account_class, in_entity_credit_id, in_curr, in_datefrom, in_dateto, in_amountfrom,
		in_amountto, in_department_id)
		WHERE (invnumber like in_invnumber OR in_invnumber IS NULL)
	LOOP
		RETURN NEXT payment_inv;
	END LOOP;
END;

$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_open_invoice(int, int, char(3), date, date, numeric, numeric, int, text) IS
$$ 
This function is based on payment_get_open_invoices and returns only one invoice if the in_invnumber is set. 
if no in_invnumber is passed this function behaves the same as payment_get_open_invoices
$$;

DROP TYPE IF EXISTS payment_contact_invoice CASCADE;
CREATE TYPE payment_contact_invoice AS (
	contact_id int,
	econtrol_code text,
	eca_description text,
	contact_name text,
	account_number text,
	total_due numeric,
	invoices text[],
        has_vouchers int
);

CREATE OR REPLACE FUNCTION payment_get_all_contact_invoices
(in_account_class int, in_business_id int, in_currency char(3),
	in_date_from date, in_date_to date, in_batch_id int, 
	in_ar_ap_accno text, in_meta_number text)
RETURNS SETOF payment_contact_invoice AS
$$
DECLARE payment_item payment_contact_invoice;
BEGIN
	FOR payment_item IN
		  SELECT c.id AS contact_id, e.control_code as econtrol_code, 
			c.description as eca_description, 
			e.name AS contact_name,
		         c.meta_number AS account_number,
			 sum( case when u.username IS NULL or 
				       u.username = SESSION_USER 
			     THEN 
		              coalesce(p.due::numeric, 0) -
		              CASE WHEN c.discount_terms 
		                        > extract('days' FROM age(a.transdate))
		                   THEN 0
		                   ELSE (coalesce(p.due::numeric, 0)) * 
					coalesce(c.discount::numeric, 0) / 100
		              END
			     ELSE 0::numeric
			     END) AS total_due,
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
		              END))::text,
			 	case when u.username IS NOT NULL 
				          and u.username <> SESSION_USER 
				     THEN 0::text
				     ELSE 1::text
				END,
				COALESCE(u.username, 0::text)
				]]),
                              sum(case when a.batch_id = in_batch_id then 1
		                  else 0 END),
		              bool_and(lock_record(a.id, (select max(session_id) 				FROM "session" where users_id = (
					select id from users WHERE username =
					SESSION_USER))))
                           
		    FROM entity e
		    JOIN entity_credit_account c ON (e.id = c.entity_id)
		    JOIN (SELECT ap.id, invnumber, transdate, amount, entity_id, 
				 paid, curr, 1 as invoice_class, 
		                 entity_credit_account, on_hold, v.batch_id,
				 approved
		            FROM ap
		       LEFT JOIN (select * from voucher where batch_class = 1) v 
			         ON (ap.id = v.trans_id)
			   WHERE in_account_class = 1
			         AND (v.batch_class = 1 or v.batch_id IS NULL)
		           UNION
		          SELECT ar.id, invnumber, transdate, amount, entity_id,
		                 paid, curr, 2 as invoice_class, 
		                 entity_credit_account, on_hold, v.batch_id,
				 approved
		            FROM ar
		       LEFT JOIN (select * from voucher where batch_class = 2) v 
			         ON (ar.id = v.trans_id)
			   WHERE in_account_class = 2
			         AND (v.batch_class = 2 or v.batch_id IS NULL)
			ORDER BY transdate
		         ) a ON (a.entity_credit_account = c.id)
		    JOIN transactions t ON (a.id = t.id)
		    JOIN (SELECT acc_trans.trans_id, 
		                 sum(CASE WHEN in_account_class = 1 THEN amount
		                          WHEN in_account_class = 2 
		                          THEN amount * -1
		                     END) AS due 
		            FROM acc_trans 
		            JOIN account coa ON (coa.id = acc_trans.chart_id)
                            JOIN account_link al ON (al.account_id = coa.id)
		       LEFT JOIN voucher v ON (acc_trans.voucher_id = v.id)
		           WHERE ((al.description = 'AP' AND in_account_class = 1)
		                 OR (al.description = 'AR' AND in_account_class = 2))
			   AND (approved IS TRUE or v.batch_class IN (3, 6))
		        GROUP BY acc_trans.trans_id) p ON (a.id = p.trans_id)
		LEFT JOIN "session" s ON (s."session_id" = t.locked_by)
		LEFT JOIN users u ON (u.id = s.users_id)
		   WHERE (a.batch_id = in_batch_id
		          OR (a.invoice_class = in_account_class
		             AND a.approved
			 AND (c.business_id = 
				coalesce(in_business_id, c.business_id)
				OR in_business_id is null)
		         AND ((a.transdate >= COALESCE(in_date_from, a.transdate)
		               AND a.transdate <= COALESCE(in_date_to, a.transdate)))
		         AND c.entity_class = in_account_class
		         AND a.curr = in_currency
		         AND a.entity_credit_account = c.id
			 AND p.due <> 0
		         AND a.amount <> a.paid 
			 AND NOT a.on_hold
		         AND EXISTS (select trans_id FROM acc_trans
		                      WHERE trans_id = a.id AND
		                            chart_id = (SELECT id from account
		                                         WHERE accno
		                                               = in_ar_ap_accno)
		                    )))
		         AND (in_meta_number IS NULL OR 
                             in_meta_number = c.meta_number)
		GROUP BY c.id, e.name, c.meta_number, c.threshold, 
			e.control_code, c.description
		  HAVING  (sum(p.due) >= c.threshold
			OR sum(case when a.batch_id = in_batch_id then 1
                                  else 0 END) > 0)
        ORDER BY c.meta_number ASC
	LOOP
		RETURN NEXT payment_item;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION payment_get_all_contact_invoices
(in_account_class int, in_business_id int, in_currency char(3),
	in_date_from date, in_date_to date, in_batch_id int, 
	in_ar_ap_accno text, in_meta_number text) IS
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

Note that the payment selection logic is that this returns all invoices which are
either approved or in the batch_id specified.  It also locks the invoices using 
the LedgerSMB discretionary locking framework, and if not possible, returns the 
username of the individual who has the lock.
$$;


CREATE OR REPLACE FUNCTION payment_bulk_post
(in_transactions numeric[], in_batch_id int, in_source text, in_total numeric,
	in_ar_ap_accno text, in_cash_accno text, 
	in_payment_date date, in_account_class int,
        in_exchangerate numeric, in_curr text)
RETURNS int AS
$$
DECLARE 
	out_count int;
	t_voucher_id int;
	t_trans_id int;
	t_amount numeric;
        t_ar_ap_id int;
	t_cash_id int;
        t_currs text[];
        t_exchangerate numeric;
BEGIN
	IF in_batch_id IS NULL THEN
		-- t_voucher_id := NULL;
		RAISE EXCEPTION 'Bulk Post Must be from Batch!';
	ELSE
		INSERT INTO voucher (batch_id, batch_class, trans_id)
		values (in_batch_id,
                (SELECT batch_class_id FROM batch WHERE id = in_batch_id),
                in_transactions[1][1]);

		t_voucher_id := currval('voucher_id_seq');
	END IF;

	SELECT string_to_array(value, ':') into t_currs 
          from defaults 
         where setting_key = 'curr';

        IF (in_curr IS NULL OR in_curr = t_currs[0]) THEN
                t_exchangerate := 1;
        ELSE 
                t_exchangerate := in_exchangerate;
        END IF;

	CREATE TEMPORARY TABLE bulk_payments_in (id int, amount numeric);

	select id into t_ar_ap_id from chart where accno = in_ar_ap_accno;
	select id into t_cash_id from chart where accno = in_cash_accno;

	FOR out_count IN 
			array_lower(in_transactions, 1) ..
			array_upper(in_transactions, 1)
	LOOP
		EXECUTE $E$
			INSERT INTO bulk_payments_in(id, amount)
			VALUES ($E$ || quote_literal(in_transactions[out_count][1])
				|| $E$, $E$ ||
				quote_literal(in_transactions[out_count][2])
				|| $E$)$E$;
	END LOOP;
	EXECUTE $E$ 
		INSERT INTO acc_trans 
			(trans_id, chart_id, amount, approved, voucher_id, transdate, 
			source)
		SELECT id, 
		case when $E$ || quote_literal(in_account_class) || $E$ = 1
			THEN $E$ || t_cash_id || $E$
			WHEN $E$ || quote_literal(in_account_class) || $E$ = 2 
			THEN $E$ || t_ar_ap_id || $E$
			ELSE -1 END, 
		amount * $E$|| quote_literal(t_exchangerate) || $E$,
		CASE 
			WHEN $E$|| t_voucher_id || $E$ IS NULL THEN true
			ELSE false END,
		$E$ || t_voucher_id || $E$, $E$|| quote_literal(in_payment_date) 
		||$E$ , $E$ ||COALESCE(quote_literal(in_source), 'NULL') || 
		$E$ 
		FROM bulk_payments_in  where amount <> 0 $E$;

	EXECUTE $E$ 
		INSERT INTO acc_trans 
			(trans_id, chart_id, amount, approved, voucher_id, transdate, 
			source)
		SELECT id, 
		case when $E$ || quote_literal(in_account_class) || $E$ = 1 
			THEN $E$ || t_ar_ap_id || $E$
			WHEN $E$ || quote_literal(in_account_class) || $E$ = 2 
			THEN $E$ || t_cash_id || $E$
			ELSE -1 END, 
		amount * -1 * $E$|| quote_literal(t_exchangerate) || $E$,
		CASE 
			WHEN $E$|| t_voucher_id || $E$ IS NULL THEN true
			ELSE false END,
		$E$ || t_voucher_id || $E$, $E$|| quote_literal(in_payment_date) 
		||$E$ , $E$ ||COALESCE(quote_literal(in_source), 'null') 
		||$E$ 
		FROM bulk_payments_in where amount <> 0 $E$;

        IF in_account_class = 1 THEN
        	EXECUTE $E$
	        	UPDATE ap 
		        set paid = paid + (select amount from bulk_payments_in b
		         	where b.id = ap.id),
                            datepaid = $E$ || quote_literal(in_payment_date) || $E$
		         where id in (select id from bulk_payments_in) $E$;
        ELSE
        	EXECUTE $E$
	        	UPDATE ar 
		        set paid = paid + (select amount from bulk_payments_in b 
		         	where b.id = ar.id),
                            datepaid = $E$ || quote_literal(in_payment_date) || $E$
		         where id in (select id from bulk_payments_in) $E$;
        END IF;
	EXECUTE $E$ DROP TABLE bulk_payments_in $E$;
	perform unlock_all();
	return out_count;
END;
$$ language plpgsql;

COMMENT ON FUNCTION payment_bulk_post
(in_transactions numeric[], in_batch_id int, in_source text, in_total numeric,
        in_ar_ap_accno text, in_cash_accno text, 
        in_payment_date date, in_account_class int, 
	in_exchangerate numeric, in_curr text)
IS
$$ This posts the payments for large batch workflows.

Note that in_transactions is a two-dimensional numeric array.  Of each 
sub-array, the first element is the (integer) transaction id, and the second
is the amount for that transaction.  $$;

CREATE OR REPLACE FUNCTION payment_post 
(in_datepaid      		  date,
 in_account_class 		  int,
 in_entity_credit_id                     int,
 in_curr        		  char(3),
 in_notes                         text,
 in_department_id                 int,
 in_gl_description                text,
 in_cash_account_id               int[],
 in_amount                        numeric[],
 in_cash_approved                 bool[],
 in_source                        text[],
 in_memo                          text[], 
 in_transaction_id                int[],
 in_op_amount                     numeric[],
 in_op_cash_account_id            int[],
 in_op_source                     text[], 
 in_op_memo                       text[],
 in_op_account_id                 int[], 
 in_ovp_payment_id		  int[],                  
 in_approved                      bool)
RETURNS INT AS
$$
DECLARE var_payment_id int;
DECLARE var_gl_id int;
DECLARE var_entry record;
DECLARE var_entry_id int[];
DECLARE out_count int;
DECLARE coa_id record;
DECLARE var_employee int;
DECLARE var_account_id int;
DECLARE default_currency char(3);
DECLARE current_exchangerate numeric;
DECLARE old_exchangerate numeric;
DECLARE tmp_amount numeric;
BEGIN
        
        SELECT * INTO default_currency  FROM defaults_get_defaultcurrency(); 
        SELECT * INTO current_exchangerate FROM currency_get_exchangerate(in_curr, in_datepaid, in_account_class);


        SELECT INTO var_employee p.id 
        FROM users u
        JOIN person p ON (u.entity_id=p.entity_id)
        WHERE username = SESSION_USER LIMIT 1;
        -- 
        -- WE HAVE TO INSERT THE PAYMENT, USING THE GL INFORMATION
        -- THE ID IS GENERATED BY payment_id_seq
        --
   	INSERT INTO payment (reference, payment_class, payment_date,
	                      employee_id, currency, notes, department_id, entity_credit_id) 
	VALUES ((CASE WHEN in_account_class = 1 THEN
	                                setting_increment('rcptnumber') -- I FOUND THIS ON sql/modules/Settings.sql 
			             ELSE 						-- and it is very usefull				
			                setting_increment('paynumber') 
			             END),
	         in_account_class, in_datepaid, var_employee,
                 in_curr, in_notes, in_department_id, in_entity_credit_id);
        SELECT currval('payment_id_seq') INTO var_payment_id; -- WE'LL NEED THIS VALUE TO USE payment_link table
        -- WE'LL NEED THIS VALUE TO JOIN WITH PAYMENT
        -- NOW COMES THE HEAVY PART, STORING ALL THE POSSIBLE TRANSACTIONS... 
        --
        -- FIRST WE SHOULD INSERT THE CASH ACCOUNTS
        --
        -- WE SHOULD HAVE THE DATA STORED AS (ACCNO, AMOUNT), SO
     IF (array_upper(in_cash_account_id, 1) > 0) THEN
	FOR out_count IN 
			array_lower(in_cash_account_id, 1) ..
			array_upper(in_cash_account_id, 1)
	LOOP
	        INSERT INTO acc_trans (chart_id, amount,
		                       trans_id, transdate, approved, source, memo)
		VALUES (in_cash_account_id[out_count], 
		        CASE WHEN in_account_class = 1 THEN in_amount[out_count]*current_exchangerate  
		        ELSE (in_amount[out_count]*current_exchangerate)* - 1
		        END,
		        in_transaction_id[out_count], in_datepaid, coalesce(in_approved, true), 
		        in_source[out_count], in_memo[out_count]);
                INSERT INTO payment_links 
		VALUES (var_payment_id, currval('acc_trans_entry_id_seq'), 1);
		IF (in_ovp_payment_id IS NOT NULL AND in_ovp_payment_id[out_count] IS NOT NULL) THEN
                	INSERT INTO payment_links
                	VALUES (in_ovp_payment_id[out_count], currval('acc_trans_entry_id_seq'), 0);
		END IF;
		
	END LOOP;
	-- NOW LETS HANDLE THE AR/AP ACCOUNTS
	-- WE RECEIVED THE TRANSACTIONS_ID AND WE CAN OBTAIN THE ACCOUNT FROM THERE
	FOR out_count IN
		     array_lower(in_transaction_id, 1) ..
		     array_upper(in_transaction_id, 1)
       LOOP
               SELECT INTO var_account_id chart_id FROM acc_trans as ac
	        JOIN chart as c ON (c.id = ac.chart_id) 
       	        WHERE 
       	        trans_id = in_transaction_id[out_count] AND
       	        ( c.link = 'AP' OR c.link = 'AR' );
        -- We need to know the exchangerate of this transaction
        IF (current_exchangerate = 1 ) THEN 
           old_exchangerate := 1;
        ELSIF (in_account_class = 2) THEN
           SELECT buy INTO old_exchangerate 
           FROM exchangerate e
           JOIN ar a ON (a.transdate = e.transdate)
                        AND (a.curr = e.curr)
           WHERE a.id = in_transaction_id[out_count];
        ELSE 
           SELECT sell INTO old_exchangerate 
           FROM exchangerate e
           JOIN ap a ON (a.transdate = e.transdate)
                        AND (a.curr = e.curr)
           WHERE a.id = in_transaction_id[out_count];
        END IF;
        -- Now we post the AP/AR transaction
        INSERT INTO acc_trans (chart_id, amount,
                                trans_id, transdate, approved, source, memo)
		VALUES (var_account_id, 
		        CASE WHEN in_account_class = 1 THEN 
		        
		        (in_amount[out_count]*old_exchangerate) * -1 
		        ELSE in_amount[out_count]*old_exchangerate
		        END,
		        in_transaction_id[out_count], in_datepaid,  coalesce(in_approved, true), 
		        in_source[out_count], in_memo[out_count]);
        -- Lets set the gain/loss, if tmp_amount equals zero then we dont need to post
        -- any transaction
        tmp_amount := in_amount[out_count]*current_exchangerate - in_amount[out_count]*old_exchangerate;
       IF (tmp_amount < 0) THEN
          IF (in_account_class  = 1) THEN
           INSERT INTO acc_trans (chart_id, amount, trans_id, transdate, approved, source)
            VALUES (CAST((select value from defaults where setting_key like 'fxloss_accno_id') AS INT),
                    tmp_amount, in_transaction_id[out_count], in_datepaid, coalesce(in_approved, true),
                    in_source[out_count]);
           ELSE
            INSERT INTO acc_trans (chart_id, amount, trans_id, transdate, approved, source)
            VALUES (CAST((select value from defaults where setting_key like 'fxgain_accno_id') AS INT),
                    tmp_amount, in_transaction_id[out_count], in_datepaid, coalesce(in_approved, true),
                    in_source[out_count]);
          END IF;
        ELSIF (tmp_amount > 0) THEN
          IF (in_account_class  = 1) THEN
            INSERT INTO acc_trans (chart_id, amount, trans_id, transdate, approved, source)
            VALUES (CAST((select value from defaults where setting_key like 'fxgain_accno_id') AS INT),
                    tmp_amount, in_transaction_id[out_count], in_datepaid, coalesce(in_approved, true),
                    in_source[out_count]);
           ELSE
            INSERT INTO acc_trans (chart_id, amount, trans_id, transdate, approved, source)
            VALUES (CAST((select value from defaults where setting_key like 'fxloss_accno_id') AS INT),
                    tmp_amount, in_transaction_id[out_count], in_datepaid, coalesce(in_approved, true),
                    in_source[out_count]);
          END IF; 
        END IF; 
        -- Now we set the links
         INSERT INTO payment_links 
		VALUES (var_payment_id, currval('acc_trans_entry_id_seq'), 1);
      END LOOP;
     END IF; -- END IF 
--
-- WE NEED TO HANDLE THE OVERPAYMENTS NOW
--
       --
       -- FIRST WE HAVE TO MAKE THE GL TO HOLD THE OVERPAYMENT TRANSACTIONS
       -- THE ID IS GENERATED BY gl_id_seq
       --
       
  IF (array_upper(in_op_cash_account_id, 1) > 0) THEN
       INSERT INTO gl (reference, description, transdate,
                       person_id, notes, approved, department_id) 
              VALUES (setting_increment('glnumber'),
	              in_gl_description, in_datepaid, var_employee,
	              in_notes, in_approved, in_department_id);
       SELECT currval('id') INTO var_gl_id;   
--
-- WE NEED TO SET THE GL_ID FIELD ON PAYMENT'S TABLE
--
       UPDATE payment SET gl_id = var_gl_id 
       WHERE id = var_payment_id;
       -- NOW COMES THE HEAVY PART, STORING ALL THE POSSIBLE TRANSACTIONS... 
       --
       -- FIRST WE SHOULD INSERT THE OVERPAYMENT CASH ACCOUNTS
       --
	FOR out_count IN 
			array_lower(in_op_cash_account_id, 1) ..
			array_upper(in_op_cash_account_id, 1)
	LOOP
	        INSERT INTO acc_trans (chart_id, amount,
		                       trans_id, transdate, approved, source, memo)
		VALUES (in_op_cash_account_id[out_count], 
		        CASE WHEN in_account_class = 1 THEN in_op_amount[out_count]  
		        ELSE in_op_amount[out_count] * - 1
		        END,
		        var_gl_id, in_datepaid, coalesce(in_approved, true), 
		        in_op_source[out_count], in_op_memo[out_count]);
	        INSERT INTO payment_links 
		VALUES (var_payment_id, currval('acc_trans_entry_id_seq'), 2);
		
	END LOOP;
	-- NOW LETS HANDLE THE OVERPAYMENT ACCOUNTS
	FOR out_count IN
		     array_lower(in_op_account_id, 1) ..
		     array_upper(in_op_account_id, 1)
	LOOP
         INSERT INTO acc_trans (chart_id, amount,
                                trans_id, transdate, approved, source, memo)
		VALUES (in_op_account_id[out_count], 
		        CASE WHEN in_account_class = 1 THEN in_op_amount[out_count] * -1 
		        ELSE in_op_amount[out_count]
		        END,
		        var_gl_id, in_datepaid,  coalesce(in_approved, true), 
		        in_op_source[out_count], in_op_memo[out_count]);
		INSERT INTO payment_links 
		VALUES (var_payment_id, currval('acc_trans_entry_id_seq'), 2);
	END LOOP;	        
 END IF;  
 return var_payment_id;
END;
$$ LANGUAGE PLPGSQL;
-- I HAVE TO MAKE A COMMENT ON THIS FUNCTION
COMMENT ON FUNCTION payment_post
(in_datepaid                      date,
 in_account_class                 int,
 in_entity_credit_id                     int,
 in_curr                          char(3),
 in_notes                         text,
 in_department_id                 int,
 in_gl_description                text,
 in_cash_account_id               int[],
 in_amount                        numeric[],
 in_cash_approved                 bool[],
 in_source                        text[],
 in_memo                          text[],
 in_transaction_id                int[],
 in_op_amount                     numeric[],
 in_op_cash_account_id            int[],
 in_op_source                     text[],
 in_op_memo                       text[],
 in_op_account_id                 int[],
 in_ovp_payment_id                int[],
 in_approved                      bool) IS
$$ Posts a payment.  in_op_* arrays are cross-indexed with eachother.
Other arrays are cross-indexed with eachother.

This API will probably change in 1.4 as we start looking at using more custom
complex types and arrays of those (requires Pg 8.4 or higher).
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
DECLARE result char(3);
BEGIN
select min(curr) into result from ar WHERE in_account_class = 2
union 
select min(curr) from ap WHERE in_account_class = 1;


LOOP
   EXIT WHEN result IS NULL;
   return next result;

   SELECT min(curr) INTO result from ar 
    where in_account_class = 2 and curr > result
            union 
   select min(curr) from ap 
    WHERE in_account_class = 1 and curr > result
    LIMIT 1;

END LOOP;
END;
$$ language plpgsql;

COMMENT ON FUNCTION payments_get_open_currencies(in_account_class int) IS
$$ This does a sparse scan to find currencies attached to open invoices.

It should scale per the number of currencies used rather than the size of the 
ar or ap tables.
$$;

CREATE OR REPLACE FUNCTION currency_get_exchangerate(in_currency char(3), in_date date, in_account_class int) 
RETURNS NUMERIC AS
$$
DECLARE 
    out_exrate exchangerate.buy%TYPE;
    default_currency char(3);
    
    BEGIN 
        SELECT * INTO default_currency  FROM defaults_get_defaultcurrency();
        IF default_currency = in_currency THEN
           RETURN 1;
        END IF; 
        IF in_account_class = 2 THEN
          SELECT buy INTO out_exrate 
          FROM exchangerate
          WHERE transdate = in_date AND curr = in_currency;
        ELSE 
          SELECT sell INTO out_exrate 
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

DROP TYPE IF EXISTS payment_location_result CASCADE;
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
CREATE OR REPLACE FUNCTION payment_get_vc_info(in_entity_credit_id int, in_location_class_id int)
RETURNS SETOF payment_location_result AS
$$
DECLARE out_row payment_location_result;
	BEGIN
		FOR out_row IN
                SELECT l.id, l.line_one, l.line_two, l.line_three, l.city,
                       l.state, l.mail_code, c.name, lc.class
                FROM location l
                JOIN company_to_location ctl ON (ctl.location_id = l.id)
                JOIN company cp ON (ctl.company_id = cp.id)
                JOIN location_class lc ON (ctl.location_class = lc.id)
                JOIN country c ON (c.id = l.country_id)
                JOIN entity_credit_account ec ON (ec.entity_id = cp.entity_id)
                WHERE ec.id = in_entity_credit_id AND
                      lc.id = in_location_class_id
                ORDER BY lc.id, l.id, c.name
                LOOP
                	RETURN NEXT out_row;
		END LOOP;
	END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_vc_info(in_entity_id int, in_location_class_id int) IS
$$ This function returns vendor or customer info $$;

DROP TYPE IF EXISTS payment_record CASCADE;
CREATE TYPE payment_record AS (
	amount numeric,
	meta_number text,
        credit_id int,
	company_paid text,
	accounts text[],
        source text,
	batch_control text,
	batch_description text,
        voucher_id int,
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
				ch.description]]), a.source, 
			b.control_code, b.description, a.voucher_id, a.transdate
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
		LEFT JOIN voucher v ON (v.id = a.voucher_id)
		LEFT JOIN batch b ON (b.id = v.batch_id)
		WHERE (ch.accno = in_cash_accno)
			AND (c.id = in_credit_id OR in_credit_id IS NULL)
			AND (a.transdate >= in_date_from 
				OR in_date_from IS NULL)
			AND (a.transdate <= in_date_to OR in_date_to IS NULL)
			AND (source = in_source OR in_source IS NULL)
		GROUP BY c.meta_number, c.id, co.legal_name, a.transdate, 
			a.source, a.memo, b.id, b.control_code, b.description, 
                        voucher_id
		ORDER BY a.transdate, c.meta_number, a.source
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ language plpgsql;

COMMENT ON FUNCTION payment__search
(in_source text, in_date_from date, in_date_to date, in_credit_id int,
        in_cash_accno text, in_account_class int) IS
$$This searches for payments.  in_date_to and _date_from specify the acceptable
date range.  All other matches are exact except that null matches all values.

Currently (and to support earlier data) we define a payment as a collection of
acc_trans records against the same credit account and cash account, on the same
day with the same source number, and optionally the same voucher id.$$;

CREATE OR REPLACE FUNCTION payment__reverse
(in_source text, in_date_paid date, in_credit_id int, in_cash_accno text, 
	in_date_reversed date, in_account_class int, in_batch_id int, 
        in_voucher_id int)
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
                        and coalesce (in_voucher_id, 0) 
                             = coalesce(voucher_id, 0)
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
				), 
                                force_closed = false 
			WHERE id = pay_row.trans_id;
		ELSIF in_account_class = 2 THEN
			update ar SET paid = amount - 
				(SELECT sum(a.amount) 
				FROM acc_trans a
				JOIN chart c ON (a.chart_id = c.id)
				WHERE c.link = 'AR'
					AND trans_id = pay_row.trans_id
				) * -1,
                                force_closed = false
			WHERE id = pay_row.trans_id;
		ELSE
			RAISE EXCEPTION 'Unknown account class for payments %',
				in_account_class;
		END IF;
	END LOOP;
	RETURN 1;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment__reverse
(in_source text, in_date_paid date, in_credit_id int, in_cash_accno text,
        in_date_reversed date, in_account_class int, in_batch_id int,
        in_voucher_id int) IS $$
Reverses a payment.  All fields are mandatory except batch_id and voucher_id
because they determine the identity of the payment to be reversed.
$$;

CREATE OR REPLACE FUNCTION payments_set_exchangerate(in_account_class int,
 in_exchangerate numeric, in_curr char(3), in_datepaid date )
RETURNS INT
AS $$
DECLARE current_exrate  exchangerate%ROWTYPE;
BEGIN
select  * INTO current_exrate
        FROM  exchangerate 
        WHERE transdate = in_datepaid
              AND curr = in_curr;
IF current_exrate.transdate = in_datepaid THEN
   IF in_account_class = 2 THEN 
      UPDATE exchangerate set buy = in_exchangerate  where transdate = in_datepaid;
   ELSE
      UPDATE exchangerate set sell = in_exchangerate where transdate = in_datepaid;
   END IF;
   RETURN 0; 
ELSE
    IF in_account_class = 2 THEN
     INSERT INTO exchangerate (curr, transdate, buy) values (in_curr, in_datepaid, in_exchangerate);
  ELSE   
     INSERT INTO exchangerate (curr, transdate, sell) values (in_curr, in_datepaid, in_exchangerate);
  END IF;                                       
RETURN 0;
END IF;
END;
$$ language plpgsql;

COMMENT ON FUNCTION payments_set_exchangerate(in_account_class int,
 in_exchangerate numeric, in_curr char(3), in_datepaid date ) IS
$$ 1.3 only.  This will be replaced by a more generic function in 1.4.

This sets the exchange rate for a class of transactions (payable, receivable) 
to a certain rate for a specific date.$$;

DROP TYPE IF EXISTS payment_header_item CASCADE;
CREATE TYPE payment_header_item AS (
payment_id int,
payment_reference int,
payment_date date,
legal_name text,
amount numeric,
employee_first_name text,
employee_last_name  text,
currency char(3),
notes text
);
-- I NEED TO PLACE THE COMPANY TELEPHONE AND ALL THAT STUFF
CREATE OR REPLACE FUNCTION payment_gather_header_info(in_account_class int, in_payment_id int)
 RETURNS SETOF payment_header_item AS
 $$
 DECLARE out_payment payment_header_item;
 BEGIN
 FOR out_payment IN 
   SELECT p.id as payment_id, p.reference as payment_reference, p.payment_date,  
          c.legal_name as legal_name, am.amount as amount, em.first_name, em.last_name, p.currency, p.notes
   FROM payment p
   JOIN entity_employee ent_em ON (ent_em.entity_id = p.employee_id)
   JOIN person em ON (ent_em.entity_id = em.entity_id)
   JOIN entity_credit_account eca ON (eca.id = p.entity_credit_id)
   JOIN company c ON   (c.entity_id  = eca.entity_id)
   JOIN payment_links pl ON (p.id = pl.payment_id)
   LEFT JOIN (  SELECT sum(a.amount) as amount
 		FROM acc_trans a
 		JOIN account acc ON (a.chart_id = acc.id)
                JOIN account_link al ON (acc.id =al.account_id)
 		JOIN payment_links pl ON (pl.entry_id=a.entry_id)
 		WHERE al.description in  
                       ('AP_paid', 'AP_discount', 'AR_paid', 'AR_discount') 
                       and ((in_account_class = 1 AND al.description like 'AP%')
                       or (in_account_class = 2 AND al.description like 'AR%'))
             ) am ON (true)
   WHERE p.id = in_payment_id
 LOOP
     RETURN NEXT out_payment;
 END LOOP;

 END;
 $$ language plpgsql;
                            

COMMENT ON FUNCTION payment_gather_header_info(int,int) IS
$$ This function finds a payment based on the id and retrieves the record, 
it is usefull for printing payments :) $$;

DROP TYPE IF EXISTS payment_line_item CASCADE;
CREATE TYPE payment_line_item AS (
  payment_id int,
  entry_id int,
  link_type int,
  trans_id int,
  invoice_number text,
  chart_id int,
  chart_accno text,
  chart_description text,
  chart_link text,
  amount numeric,
  trans_date date,	
  source text,
  cleared bool,
  fx_transaction bool,
  project_id int,
  memo text,
  invoice_id int,
  approved bool,
  cleared_on date,
  reconciled_on date
);
   
CREATE OR REPLACE FUNCTION payment_gather_line_info(in_account_class int, in_payment_id int)
 RETURNS SETOF payment_line_item AS
 $$
 DECLARE out_payment_line payment_line_item;
 BEGIN
   FOR out_payment_line IN 
     SELECT pl.payment_id, ac.entry_id, pl.type as link_type, ac.trans_id, a.invnumber as invoice_number,
     ac.chart_id, ch.accno as chart_accno, ch.description as chart_description, ch.link as chart_link,
     ac.amount,  ac.transdate as trans_date, ac.source, ac.cleared_on, ac.fx_transaction, ac.project_id,
     ac.memo, ac.invoice_id, ac.approved, ac.cleared_on, ac.reconciled_on
     FROM acc_trans ac
     JOIN payment_links pl ON (pl.entry_id = ac.entry_id )
     JOIN chart         ch ON (ch.id = ac.chart_id)
     LEFT JOIN (SELECT id,invnumber
                 FROM ar WHERE in_account_class = 2
                 UNION
                 SELECT id,invnumber
                 FROM ap WHERE in_account_class = 1
                ) a ON (ac.trans_id = a.id)
     WHERE pl.payment_id = in_payment_id
   LOOP
      RETURN NEXT out_payment_line;
   END LOOP;  
 END;
 $$ language plpgsql;

COMMENT ON FUNCTION payment_gather_line_info(int,int) IS
$$ This function finds a payment based on the id and retrieves all the line records, 
it is usefull for printing payments and build reports :) $$;

-- We will use a view to handle all the overpayments

DROP VIEW IF EXISTS overpayments CASCADE;
CREATE VIEW overpayments AS
SELECT p.id as payment_id, p.reference as payment_reference, p.payment_class, p.closed as payment_closed,
       p.payment_date, ac.chart_id, c.accno, c.description as chart_description,
       p.department_id, abs(sum(ac.amount)) as available, cmp.legal_name, 
       eca.id as entity_credit_id, eca.entity_id, eca.discount, eca.meta_number
FROM payment p
JOIN payment_links pl ON (pl.payment_id=p.id)
JOIN acc_trans ac ON (ac.entry_id=pl.entry_id)
JOIN chart c ON (c.id=ac.chart_id)
JOIN entity_credit_account eca ON (eca.id = p.entity_credit_id)
JOIN company cmp ON (cmp.entity_id=eca.entity_id) 
WHERE p.gl_id IS NOT NULL 
      AND (pl.type = 2 OR pl.type = 0)
      AND c.link LIKE '%overpayment%'
GROUP BY p.id, c.accno, p.reference, p.payment_class, p.closed, p.payment_date,
      ac.chart_id, chart_description, p.department_id,  legal_name, eca.id,
      eca.entity_id, eca.discount, eca.meta_number;

CREATE OR REPLACE FUNCTION payment_get_open_overpayment_entities(in_account_class int)
 returns SETOF payment_vc_info AS
 $$
 DECLARE out_entity payment_vc_info;
 BEGIN
	FOR out_entity IN
    		SELECT DISTINCT entity_credit_id, legal_name, e.entity_class, discount, o.meta_number
    		FROM overpayments o
    		JOIN entity e ON (e.id=o.entity_id)
    		WHERE available <> 0 AND in_account_class = payment_class
        LOOP
                RETURN NEXT out_entity;
        END LOOP;
 END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION payment_get_unused_overpayment(
in_account_class int, in_entity_credit_id int, in_chart_id int)
returns SETOF overpayments AS
$$
DECLARE out_overpayment overpayments%ROWTYPE;
BEGIN
      FOR out_overpayment IN
              SELECT DISTINCT * 
              FROM overpayments
              WHERE payment_class  = in_account_class 
              AND entity_credit_id = in_entity_credit_id 
              AND available <> 0
              AND (in_chart_id IS NULL OR chart_id = in_chart_id )
              ORDER BY payment_date
            
      LOOP
           RETURN NEXT out_overpayment;
      END LOOP;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_unused_overpayment(
in_account_class int, in_entity_credit_id int, in_chart_id int) IS
$$ Returns a list of available overpayments$$;

DROP TYPE IF EXISTS payment_overpayments_available_amount CASCADE;
CREATE TYPE payment_overpayments_available_amount AS (
        chart_id int,
        accno text,
        description text,
        available numeric 
);

CREATE OR REPLACE FUNCTION payment_get_available_overpayment_amount(
in_account_class int, in_entity_credit_id int)
returns SETOF payment_overpayments_available_amount AS
$$
DECLARE out_overpayment payment_overpayments_available_amount;
BEGIN
      FOR out_overpayment IN
              SELECT chart_id, accno,   chart_description, abs(sum(available))
              FROM overpayments
              WHERE payment_class  = in_account_class 
              AND entity_credit_id = in_entity_credit_id 
              AND available <> 0
              GROUP BY chart_id, accno, chart_description
      LOOP
           RETURN NEXT out_overpayment;
      END LOOP;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_unused_overpayment(
in_account_class int, in_entity_credit_id int, in_chart_id int) IS
$$ Returns a list of available overpayments$$;

COMMIT;
