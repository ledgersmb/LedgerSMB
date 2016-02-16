BEGIN;

CREATE OR REPLACE FUNCTION payment_type__list() RETURNS SETOF payment_type AS
$$
SELECT * FROM payment_type;
$$ LANGUAGE SQL;

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
SELECT * FROM payment_type where id=in_payment_type_id;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION payment_type__get_label(in_payment_type_id int) IS
$$ Returns all information on a payment type by the id.  This should be renamed
to account for its behavior in future versions.$$;

-- ### To be dropped in 1.4: it's imprecise
-- to return a set of entity accounts based on their names,
-- if we're going to use them for discount calculations...
DROP FUNCTION IF EXISTS payment_get_entity_accounts (int, text, text);
CREATE OR REPLACE FUNCTION payment_get_entity_accounts
(in_account_class int,
 in_vc_name text,
 in_vc_idn  text,
 in_datefrom date,
 in_dateto date)
 returns SETOF payment_vc_info AS
 $$
              SELECT ec.id, coalesce(ec.pay_to_name, e.name ||
                     coalesce(':' || ec.description,'')) as name,
                     e.entity_class, ec.discount_account_id, ec.meta_number
 		FROM entity_credit_account ec
 		JOIN entity e ON (ec.entity_id = e.id)
		WHERE ec.entity_class = in_account_class
		AND (e.name ilike coalesce('%'||in_vc_name||'%','%%')
                    OR EXISTS (select 1 FROM company
                                WHERE entity_id = e.id AND tax_id = in_vc_idn))
                AND (coalesce(ec.enddate, now()::date)
                     >= coalesce(in_datefrom, now()::date))
                AND (coalesce(ec.startdate, now()::date)
                     <= coalesce(in_dateto, now()::date))
 $$ LANGUAGE SQL;

COMMENT ON FUNCTION payment_get_entity_accounts
(in_account_class int,
 in_vc_name text,
 in_vc_idn  text,
 in_datefrom date,
 in_dateto date) IS
$$ Returns a minimal set of information about customer or vendor accounts
as needed for discount calculations and the like.$$;

CREATE OR REPLACE FUNCTION payment_get_entity_account_payment_info
(in_entity_credit_id int)
RETURNS payment_vc_info
AS $$
 SELECT ec.id, coalesce(ec.pay_to_name, cp.legal_name ||
        coalesce(':' || ec.description,'')) as name,
        e.entity_class, ec.discount_account_id, ec.meta_number
 FROM entity_credit_account ec
 JOIN entity e ON (ec.entity_id = e.id)
 JOIN company cp ON (cp.entity_id = e.id)
 WHERE ec.id = $1;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION payment_get_entity_account_payment_info
(in_entity_credit_id int)
IS $$ Returns payment information on the entity credit account as
  required to for discount calculations and payment processing. $$;

DROP TYPE IF EXISTS payment_open_account CASCADE;
CREATE TYPE payment_open_account AS (
  id int,
  name text,
  entity_class int
);


DROP FUNCTION IF EXISTS payment_get_open_accounts(int);
DROP FUNCTION IF EXISTS payment_get_open_accounts(int, date, date);
-- payment_get_open_accounts and the option to get all accounts need to be
-- refactored and redesigned.  -- CT
CREATE OR REPLACE FUNCTION payment_get_open_accounts
(in_account_class int, in_datefrom date, in_dateto date)
returns SETOF payment_open_account AS
$$
                SELECT ec.id, e.name, ec.entity_class
                FROM entity e
                JOIN entity_credit_account ec ON (ec.entity_id = e.id)
                        WHERE ec.entity_class = in_account_class
                        AND (coalesce(ec.enddate, now()::date)
                             <= coalesce(in_dateto, now()::date))
                        AND (coalesce(ec.startdate, now()::date)
                             >= coalesce(in_datefrom, now()::date))
                        AND CASE WHEN in_account_class = 1 THEN
                                ec.id IN
                                (SELECT entity_credit_account
                                   FROM acc_trans
                                   JOIN chart ON (acc_trans.chart_id = chart.id)
                                   JOIN ap ON (acc_trans.trans_id = ap.id)
                                   WHERE link = 'AP'
                                   GROUP BY chart_id,
                                         trans_id, entity_credit_account
                                   HAVING SUM(acc_trans.amount) <> 0)
                               WHEN in_account_class = 2 THEN
                                ec.id IN (SELECT entity_credit_account
                                   FROM acc_trans
                                   JOIN chart ON (acc_trans.chart_id = chart.id)
                                   JOIN ar ON (acc_trans.trans_id = ar.id)
                                   WHERE link = 'AR'
                                   GROUP BY chart_id,
                                         trans_id, entity_credit_account
                                   HAVING SUM(acc_trans.amount) <> 0)
                          END;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION payment_get_open_accounts(int, date, date) IS
$$ This function takes a single argument (1 for vendor, 2 for customer as
always) and returns all entities with open accounts of the appropriate type. $$;

DROP FUNCTION if exists payment_get_all_accounts(int);

CREATE OR REPLACE FUNCTION payment_get_all_accounts(in_account_class int)
RETURNS SETOF payment_open_account AS
$$
		SELECT  ec.id,
			e.name, ec.entity_class
		FROM entity e
		JOIN entity_credit_account ec ON (ec.entity_id = e.id)
				WHERE e.entity_class = in_account_class
$$ LANGUAGE SQL;

COMMENT ON FUNCTION payment_get_all_accounts(int) IS
$$ This function takes a single argument (1 for vendor, 2 for customer)
$$;

COMMENT ON FUNCTION payment_get_all_accounts(int) IS
$$ This function takes a single argument (1 for vendor, 2 for customer as
always) and returns all entities with accounts of the appropriate type. $$;

DROP TYPE IF EXISTS payment_invoice CASCADE;

CREATE TYPE payment_invoice AS (
	invoice_id int,
	invnumber text,
    invoice bool,
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
 in_amountto   numeric)
RETURNS SETOF payment_invoice AS
$$
		SELECT a.id AS invoice_id, a.invnumber AS invnumber,a.invoice AS invoice,
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
                 FROM  (SELECT id, invnumber, invoice, transdate, amount,
		               1 as invoice_class, curr,
		               entity_credit_account, approved
		          FROM ap
                         UNION
		         --SELECT id, invnumber, transdate, amount, entity_id,
		         SELECT id, invnumber, invoice, transdate, amount,
		               2 AS invoice_class, curr,
		               entity_credit_account, approved
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
                        --### short term: ignore fractional cent differences
		        AND a.curr = in_curr
		        AND (a.transdate >= in_datefrom
		             OR in_datefrom IS NULL)
		        AND (a.transdate <= in_dateto
		             OR in_dateto IS NULL)
		        AND (a.amount >= in_amountfrom
		             OR in_amountfrom IS NULL)
		        AND (a.amount <= in_amountto
		             OR in_amountto IS NULL)
		        AND due <> 0
		        AND a.approved = true
		        GROUP BY a.invnumber, a.transdate, a.amount, amount_fx, discount, discount_fx, ac.due, a.id, c.discount_terms, ex.buy, ex.sell, a.curr, a.invoice;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION payment_get_open_invoices(int, int, char(3), date, date, numeric, numeric) IS
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
 in_invnumber text)
RETURNS SETOF payment_invoice AS
$$
		SELECT * from payment_get_open_invoices(in_account_class, in_entity_credit_id, in_curr, in_datefrom, in_dateto, in_amountfrom,
		in_amountto)
		WHERE (invnumber like in_invnumber OR in_invnumber IS NULL);

$$ LANGUAGE SQL;

COMMENT ON FUNCTION payment_get_open_invoice(int, int, char(3), date, date, numeric, numeric, text) IS
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
        has_vouchers bigint,
        got_lock bool
);

CREATE OR REPLACE FUNCTION payment_get_all_contact_invoices
(in_account_class int, in_business_id int, in_currency char(3),
        in_date_from date, in_date_to date, in_batch_id int,
        in_ar_ap_accno text, in_meta_number text)
RETURNS SETOF payment_contact_invoice AS
$$
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
                                        < extract('days' FROM age(a.transdate))
                                   THEN 0
                                   ELSE (coalesce(p.due, 0) * coalesce(c.discount, 0) / 100)
                              END)::text,
                              (coalesce(p.due, 0) -
                              (CASE WHEN c.discount_terms
                                        < extract('days' FROM age(a.transdate))
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
                              bool_and(lock_record(a.id, (select max(session_id)
                                FROM "session" where users_id = (
                                        select id from users WHERE username =
                                        SESSION_USER))))

                    FROM entity e
                    JOIN entity_credit_account c ON (e.id = c.entity_id)
                    JOIN (SELECT ap.id, invnumber, transdate, amount, entity_id,
                                 curr, 1 as invoice_class,
                                 entity_credit_account, on_hold, v.batch_id,
                                 approved, paid
                            FROM ap
                       LEFT JOIN (select * from voucher where batch_class = 1) v
                                 ON (ap.id = v.trans_id)
                           WHERE in_account_class = 1
                                 AND (v.batch_class = 1 or v.batch_id IS NULL)
                           UNION
                          SELECT ar.id, invnumber, transdate, amount, entity_id,
                                 curr, 2 as invoice_class,
                                 entity_credit_account, on_hold, v.batch_id,
                                 approved, paid
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
                         AND due <> 0
                         AND NOT a.on_hold
                         AND a.curr = in_currency
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
                  HAVING  c.threshold is null or (sum(p.due) >= c.threshold
                        OR sum(case when a.batch_id = in_batch_id then 1
                                  else 0 END) > 0)
        ORDER BY c.meta_number ASC;
$$ LANGUAGE sql;

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

DROP FUNCTION IF EXISTS payment_bulk_post
(in_transactions numeric[], in_batch_id int, in_source text, in_total numeric,
        in_ar_ap_accno text, in_cash_accno text,
        in_payment_date date, in_account_class int,
        in_exchangerate numeric, in_curr text);

CREATE OR REPLACE FUNCTION payment_bulk_post
(in_transactions numeric[], in_batch_id int, in_source text, in_total numeric,
        in_ar_ap_accno text, in_cash_accno text,
        in_payment_date date, in_account_class int,
        in_exchangerate numeric, in_currency text)
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
        t_cash_sign int;
        t_batch batch;
BEGIN

        SELECT * INTO t_exchangerate FROM currency_get_exchangerate(
              in_currency, in_payment_date, in_account_class);

        IF in_batch_id IS NULL THEN
                -- t_voucher_id := NULL;
                RAISE EXCEPTION 'Bulk Post Must be from Batch!';
        ELSE
                SELECT * INTO t_batch FROM batch WHERE in_batch_id = id;
                IF t_batch.approved_by IS NOT NULL THEN
                    RAISE EXCEPTION 'Approved Batch';
                ELSIF t_batch.locked_by IS NOT NULL THEN
                    PERFORM * FROM session 
                       JOIN users ON (session.users_id = users.id)
                      WHERE session_id = t_batch.locked_by 
                            AND users.username = SESSION_USER;

                    IF NOT FOUND THEN
                        -- locked by someone else
                        RAISE EXCEPTION 'batch locked by %, I am %', t_batch.locked_by, session_user;
                    END IF;
                END IF;
                INSERT INTO voucher (batch_id, batch_class, trans_id)
                values (in_batch_id,
                (SELECT batch_class_id FROM batch WHERE id = in_batch_id),
                in_transactions[1][1]);

                t_voucher_id := currval('voucher_id_seq');
        END IF;

        SELECT string_to_array(value, ':') into t_currs
          from defaults
         where setting_key = 'curr';

        IF (in_currency IS NULL OR in_currency = t_currs[1]) THEN
                t_exchangerate := 1;
        ELSIF t_exchangerate IS NULL THEN
                t_exchangerate := in_exchangerate;
                PERFORM payments_set_exchangerate(in_account_class,
                                                  in_exchangerate,
                                                  in_currency,
                                                  in_payment_date);
        ELSIF t_exchangerate <> in_exchangerate THEN
                RAISE EXCEPTION 'Exchange rate different than on file';
        END IF;
        IF t_exchangerate IS NULL THEN
            RAISE EXCEPTION 'No exchangerate provided and not default currency';
        END IF;

        CREATE TEMPORARY TABLE bulk_payments_in
           (id int, amount numeric, fxrate numeric, gain_loss_accno int);

        select id into t_ar_ap_id from chart where accno = in_ar_ap_accno;
        select id into t_cash_id from chart where accno = in_cash_accno;

        FOR out_count IN
                        array_lower(in_transactions, 1) ..
                        array_upper(in_transactions, 1)
        LOOP
            -- Fill the bulk payments table
            INSERT INTO bulk_payments_in(id, amount)
            VALUES (in_transactions[out_count][1],
                    in_transactions[out_count][2]);
        END LOOP;

        IF in_account_class = 1 THEN
            t_cash_sign := 1;
        ELSE
            t_cash_sign := -1;
        END IF;

        IF (in_currency IS NULL OR in_currency = t_currs[1]) THEN
            UPDATE bulk_payments_in
               SET fxrate = 1;
        ELSE
            UPDATE bulk_payments_in
               SET fxrate =
                (SELECT CASE WHEN in_account_class = 1 THEN sell
                             ELSE buy
                        END
                   FROM exchangerate e
                   JOIN (SELECT transdate, id, curr FROM ar
                         UNION
                         SELECT transdate, id, curr FROM ap) a
                     ON (e.transdate = a.transdate
                         AND e.curr = a.curr)
                   WHERE a.id = bulk_payments_in.id);
            UPDATE bulk_payments_in
               SET gain_loss_accno =
                (SELECT value::int FROM defaults
                  WHERE setting_key = 'fxgain_accno_id')
             WHERE ((t_exchangerate - bulk_payments_in.fxrate) * t_cash_sign) < 0;
            UPDATE bulk_payments_in
               SET gain_loss_accno = (SELECT value::int FROM defaults
                  WHERE setting_key = 'fxloss_accno_id')
             WHERE ((t_exchangerate - bulk_payments_in.fxrate) * t_cash_sign) > 0;
            -- explicitly leave zero gain/loss accno_id entries at NULL
            -- so we have an easy check for which
        END IF;

        -- Insert cash side
        INSERT INTO acc_trans
             (trans_id, chart_id, amount, approved,
              voucher_id, transdate, source)
           SELECT id, t_cash_id, amount * t_cash_sign * t_exchangerate/fxrate,
                  CASE WHEN t_voucher_id IS NULL THEN true
                       ELSE false END,
                  t_voucher_id, in_payment_date, in_source
             FROM bulk_payments_in  where amount <> 0;

        -- early payment discounts
        IF t_cash_sign IS NULL THEN
             raise exception 't_cash_sign is null';
        ELSIF t_exchangerate IS NULL THEN
             raise exception 't_exchangerate is null';
        END IF;
        INSERT INTO acc_trans
               (trans_id, chart_id, amount, approved,
               voucher_id, transdate, source)
        SELECT bpi.id, eca.discount_account_id,
               amount * t_cash_sign * t_exchangerate/fxrate
               / (1 - discount::numeric/100)
               * (discount::numeric/100),
               CASE WHEN t_voucher_id IS NULL THEN true
                       ELSE false END,
               t_voucher_id, in_payment_date, in_source
          FROM bulk_payments_in bpi
          JOIN (select entity_credit_account, id, transdate FROM ar
                 WHERE in_account_class = 2
                 UNION
                SELECT entity_credit_account, id, transdate FROM ap
                 WHERE in_account_class = 1) gl ON gl.id = bpi.id
          JOIN entity_credit_account eca ON gl.entity_credit_account = eca.id
         WHERE bpi.amount <> 0
               AND extract('days' from age(gl.transdate)) < eca.discount_terms
               and eca.discount_terms is not null AND discount IS NOT NULL
               AND eca.discount_account_id IS NOT NULL;

        INSERT INTO acc_trans
               (trans_id, chart_id, amount, approved,
               voucher_id, transdate, source)
        SELECT bpi.id, t_ar_ap_id,
               amount * t_cash_sign * -1 * t_exchangerate/fxrate
               / (1 - discount::numeric/100)
               * (discount::numeric/100),
               CASE WHEN t_voucher_id IS NULL THEN true
                       ELSE false END,
               t_voucher_id, in_payment_date, in_source
          FROM bulk_payments_in bpi
          JOIN (select entity_credit_account, id, transdate FROM ar
                 WHERE in_account_class = 2
                 UNION
                SELECT entity_credit_account, id, transdate FROM ap
                 WHERE in_account_class = 1) gl ON gl.id = bpi.id
          JOIN entity_credit_account eca ON gl.entity_credit_account = eca.id
         WHERE bpi.amount <> 0
               AND extract('days' from age(gl.transdate)) < eca.discount_terms
               AND eca.discount_terms IS NOT NULL AND discount IS NOT NULL
               AND eca.discount_account_id IS NOT NULL;

        -- Insert ar/ap side
        INSERT INTO acc_trans
             (trans_id, chart_id, amount, approved,
              voucher_id, transdate, source)
           SELECT id, t_ar_ap_id,
                  amount * -1 * t_cash_sign,
                  CASE WHEN t_voucher_id IS NULL THEN true
                       ELSE false END,
                  t_voucher_id, in_payment_date, in_source
             FROM bulk_payments_in where amount <> 0;

        -- Insert fx gain/loss effects, if applicable
        INSERT INTO acc_trans
             (trans_id, chart_id, amount, approved,
              voucher_id, transdate, source)
           SELECT id, gain_loss_accno,
                  amount * t_cash_sign * (1 - t_exchangerate/fxrate),
                  CASE WHEN t_voucher_id IS NULL THEN true
                       ELSE false END,
                  t_voucher_id, in_payment_date, in_source
             FROM bulk_payments_in
            WHERE amount <> 0 AND gain_loss_accno IS NOT NULL;

        DROP TABLE bulk_payments_in;
        perform unlock_all();
        return out_count;
END;
$$ language plpgsql;

COMMENT ON FUNCTION payment_bulk_post
(in_transactions numeric[], in_batch_id int, in_source text, in_total numeric,
        in_ar_ap_accno text, in_cash_accno text,
        in_payment_date date, in_account_class int,
	in_exchangerate numeric, in_currency text)
IS
$$ This posts the payments for large batch workflows.

Note that in_transactions is a two-dimensional numeric array.  Of each
sub-array, the first element is the (integer) transaction id, and the second
is the amount for that transaction.  $$;

--TODO 1.5 parameter in_cash_approved not used in function, use it or drop it?
CREATE OR REPLACE FUNCTION payment_post
(in_datepaid      		  date,
 in_account_class 		  int,
 in_entity_credit_id                     int,
 in_curr        		  char(3),
 in_notes                         text,
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
DECLARE fx_gain_loss_amount numeric;
BEGIN
      IF array_upper(in_amount, 1) <> array_upper(in_cash_account_id, 1) THEN
          RAISE EXCEPTION 'Wrong number of accounts';
      END IF;

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
	                      employee_id, currency, notes, entity_credit_id)
	VALUES ((CASE WHEN in_account_class = 1 THEN
	                                setting_increment('rcptnumber') -- I FOUND THIS ON sql/modules/Settings.sql
			             ELSE 						-- and it is very usefull
			                setting_increment('paynumber')
			             END),
	         in_account_class, in_datepaid, var_employee,
                 in_curr, in_notes, in_entity_credit_id);
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
	-- ### BUG: we don't have a guarantee that the transaction is
	--          the same currency as in_curr, so, we can't use
	--          current_exchangerate as the basis for fx gain/loss
	--          calculations
        IF (in_curr = default_currency) THEN
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
        -- Lets set the gain/loss, if  fx_gain_loss_amount equals zero then we dont need to post
        -- any transaction
       fx_gain_loss_amount := in_amount[out_count]*current_exchangerate - in_amount[out_count]*old_exchangerate;
       IF (in_account_class = 1) THEN
         -- in case of vendor invoices, the invoice amounts have been negated, do the same with the diff
         fx_gain_loss_amount := fx_gain_loss_amount * -1;
       END IF;

       IF (fx_gain_loss_amount < 0) THEN
           INSERT INTO acc_trans (chart_id, amount, trans_id, transdate, approved, source)
            VALUES ((select value::int from defaults WHERE setting_key = 'fxgain_accno_id'),
                    fx_gain_loss_amount, in_transaction_id[out_count], in_datepaid, coalesce(in_approved, true),
                    in_source[out_count]);
        ELSIF (fx_gain_loss_amount > 0) THEN
            INSERT INTO acc_trans (chart_id, amount, trans_id, transdate, approved, source)
            VALUES ((select value::int from defaults WHERE setting_key = 'fxloss_accno_id'),
                    fx_gain_loss_amount, in_transaction_id[out_count], in_datepaid, coalesce(in_approved, true),
                    in_source[out_count]);
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
                       person_id, notes, approved)
              VALUES (setting_increment('glnumber'),
	              in_gl_description, in_datepaid, var_employee,
	              in_notes, in_approved);
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
                SELECT l.id, l.line_one, l.line_two, l.line_three, l.city,
                       l.state, l.mail_code, c.name, lc.class
                FROM location l
                JOIN entity_to_location ctl ON (ctl.location_id = l.id)
                JOIN entity cp ON (ctl.entity_id = cp.id)
                JOIN location_class lc ON (ctl.location_class = lc.id)
                JOIN country c ON (c.id = l.country_id)
                JOIN entity_credit_account ec ON (ec.entity_id = cp.id)
                WHERE ec.id = in_entity_credit_id AND
                      lc.id = in_location_class_id
                ORDER BY lc.id, l.id, c.name
$$ LANGUAGE SQL;

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

DROP FUNCTION IF EXISTS payment__search(text, date, date, int, text, int, char(3));

CREATE OR REPLACE FUNCTION payment__search
(in_source text, in_from_date date, in_to_date date, in_credit_id int,
	in_cash_accno text, in_entity_class int, in_currency char(3),
        in_meta_number text)
RETURNS SETOF payment_record AS
$$
		select sum(CASE WHEN c.entity_class = 1 then a.amount
				ELSE a.amount * -1 END), c.meta_number,
			c.id, e.name as legal_name,
			compound_array(ARRAY[ARRAY[ch.id::text, ch.accno,
				ch.description]]), a.source,
			b.control_code, b.description, a.voucher_id, a.transdate
		FROM entity_credit_account c
		JOIN ( select entity_credit_account, id, curr, approved
			FROM ar WHERE in_entity_class = 2
			UNION
			SELECT entity_credit_account, id, curr, approved
			FROM ap WHERE in_entity_class = 1
			) arap ON (arap.entity_credit_account = c.id)
		JOIN acc_trans a ON (arap.id = a.trans_id)
		JOIN chart ch ON (ch.id = a.chart_id)
		JOIN entity e ON (c.entity_id = e.id)
		LEFT JOIN voucher v ON (v.id = a.voucher_id)
		LEFT JOIN batch b ON (b.id = v.batch_id)
		WHERE (ch.accno = in_cash_accno OR ch.id IN (select account_id
                                                               FROM account_link
                                                              WHERE description
                                                                    IN(
                                                                     'AR_paid',
                                                                     'AP_paid'
                                                                    )))
                        AND (in_currency IS NULL OR in_currency = arap.curr)
			AND (c.id = in_credit_id OR in_credit_id IS NULL)
			AND (a.transdate >= in_from_date
				OR in_from_date IS NULL)
			AND (a.transdate <= in_to_date OR in_to_date IS NULL)
			AND (source = in_source OR in_source IS NULL)
                        AND arap.approved AND a.approved
                        AND (c.meta_number = in_meta_number
                                OR in_meta_number IS NULL)
		GROUP BY c.meta_number, c.id, e.name, a.transdate,
			a.source, a.memo, b.id, b.control_code, b.description,
                        voucher_id
		ORDER BY a.transdate, c.meta_number, a.source;
$$ language sql;

COMMENT ON FUNCTION payment__search
(in_source text, in_date_from date, in_date_to date, in_credit_id int,
        in_cash_accno text, in_entity_class int, char(3), text) IS
$$This searches for payments.  in_date_to and _date_from specify the acceptable
date range.  All other matches are exact except that null matches all values.

Currently (and to support earlier data) we define a payment as a collection of
acc_trans records against the same credit account and cash account, on the same
day with the same source number, and optionally the same voucher id.$$;

DROP FUNCTION IF EXISTS payment__reverse
(in_source text, in_date_paid date, in_credit_id int, in_cash_accno text,
        in_date_reversed date, in_account_class int, in_batch_id int,
        in_voucher_id int);

CREATE OR REPLACE FUNCTION payment__reverse
(in_source text, in_date_paid date, in_credit_id int, in_cash_accno text,
	in_date_reversed date, in_account_class int, in_batch_id int,
        in_voucher_id int, in_exchangerate numeric, in_currency char(3))
RETURNS INT
AS $$
DECLARE
	pay_row record;
        t_voucher_id int;
        t_voucher_inserted bool;
        t_currs text[];
        t_rev_fx numeric;
        t_fxgain_id int;
        t_fxloss_id int;
        t_paid_fx numeric;
BEGIN
        SELECT * INTO t_rev_fx FROM currency_get_exchangerate(
              in_currency, in_date_reversed, in_account_class);

        SELECT * INTO t_paid_fx FROM currency_get_exchangerate(
              in_currency, in_date_paid, in_account_class);

       select value::int INTO t_fxgain_id FROM setting_get('fxgain_accno_id');
       select value::int INTO t_fxloss_id FROM setting_get('fxloss_accno_id');

       SELECT string_to_array(value, ':') into t_currs
          from defaults
         where setting_key = 'curr';

        IF in_currency IS NULL OR in_currency = t_currs[1] THEN
                t_rev_fx := 1;
                t_paid_fx := 1;
        ELSIF t_rev_fx IS NULL THEN
                t_rev_fx := in_exchangerate;
                PERFORM payments_set_exchangerate(in_account_class,
                                                  in_exchangerate,
                                                  in_currency,
                                                  in_date_reversed);
        ELSIF t_rev_fx <> in_exchangerate THEN
                RAISE EXCEPTION 'Exchange rate different than on file';
        END IF;
        IF t_rev_fx IS NULL THEN
            RAISE EXCEPTION 'No exchangerate provided and not default currency';
        END IF;


        IF in_batch_id IS NOT NULL THEN
		t_voucher_id := nextval('voucher_id_seq');
		t_voucher_inserted := FALSE;
	END IF;
	FOR pay_row IN
		SELECT a.*, c.ar_ap_account_id, arap.curr, arap.fxrate
		FROM acc_trans a
		JOIN (select id, curr, entity_credit_account,
                             CASE WHEN curr = t_currs[1] THEN 1
                                   ELSE buy END as fxrate
			FROM ar
                   LEFT JOIN exchangerate USING (transdate, curr)
                       WHERE in_account_class = 2
			UNION
			SELECT id, curr, entity_credit_account,
                               CASE WHEN curr = t_currs[1] THEN 1
                                    ELSE sell END as fxrate
			FROM ap
                   LEFT JOIN exchangerate USING (transdate, curr)
                       WHERE in_account_class = 1
		) arap ON (a.trans_id = arap.id)
		JOIN entity_credit_account c
			ON (arap.entity_credit_account = c.id)
		JOIN account ch ON (a.chart_id = ch.id)
		WHERE coalesce(a.source, '') = coalesce(in_source, '')
			AND a.transdate = in_date_paid
			AND in_credit_id = arap.entity_credit_account
			AND in_cash_accno = ch.accno
                        and in_voucher_id IS NOT DISTINCT FROM voucher_id
	LOOP
                IF pay_row.curr = t_currs[1] THEN
                   pay_row.fxrate = 1;
                END IF;

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
		(pay_row.trans_id, pay_row.chart_id,
                        pay_row.amount / t_paid_fx * -1 * t_rev_fx,
			in_date_reversed, in_source, 'Reversing ' ||
			COALESCE(in_source, ''),
			case when in_batch_id is not null then false
			else true end, t_voucher_id),
                 (pay_row.trans_id, pay_row.ar_ap_account_id,
                        pay_row.amount / t_paid_fx * pay_row.fxrate,
			in_date_reversed, in_source, 'Reversing ' ||
			COALESCE(in_source, ''),
			case when in_batch_id is not null then false
			else true end, t_voucher_id),
                 (pay_row.trans_id,
                  case when pay_row.fxrate > t_rev_fx
                       THEN t_fxloss_id ELSE t_fxgain_id END,
                  pay_row.amount / t_paid_fx * (t_rev_fx - pay_row.fxrate),
                  in_date_reversed, in_source, 'Reversing ' ||
                                                COALESCE(in_source, ''),
                   case when in_batch_id is not null then false
                        else true end, t_voucher_id);


	END LOOP;
	RETURN 1;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment__reverse
(in_source text, in_date_paid date, in_credit_id int, in_cash_accno text,
        in_date_reversed date, in_account_class int, in_batch_id int,
        in_voucher_id int, in_exchangerate numeric, char(3)) IS $$
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
payment_reference text,
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
   WHERE p.id = in_payment_id;
 $$ language sql;


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
  memo text,
  invoice_id int,
  approved bool,
  cleared_on date,
  reconciled_on date
);

CREATE OR REPLACE FUNCTION payment_gather_line_info(in_account_class int, in_payment_id int)
 RETURNS SETOF payment_line_item AS
 $$
     SELECT pl.payment_id, ac.entry_id, pl.type as link_type, ac.trans_id, a.invnumber as invoice_number,
     ac.chart_id, ch.accno as chart_accno, ch.description as chart_description, ch.link as chart_link,
     ac.amount,  ac.transdate as trans_date, ac.source, ac.cleared, ac.fx_transaction,
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
     WHERE pl.payment_id = in_payment_id;
 $$ language sql;

COMMENT ON FUNCTION payment_gather_line_info(int,int) IS
$$ This function finds a payment based on the id and retrieves all the line records,
it is usefull for printing payments and build reports :) $$;

-- We will use a view to handle all the overpayments

DROP VIEW IF EXISTS overpayments CASCADE;
CREATE VIEW overpayments AS
SELECT p.id as payment_id, p.reference as payment_reference, p.payment_class, p.closed as payment_closed,
       p.payment_date, ac.chart_id, c.accno, c.description as chart_description,
       sum(ac.amount) * CASE WHEN eca.entity_class = 1 THEN -1 ELSE 1 END
          as available, cmp.legal_name,
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
      ac.chart_id, chart_description,legal_name, eca.id,
      eca.entity_id, eca.discount, eca.meta_number, eca.entity_class;

CREATE OR REPLACE FUNCTION payment_get_open_overpayment_entities(in_account_class int)
 returns SETOF payment_vc_info AS
 $$
    		SELECT DISTINCT entity_credit_id, legal_name, e.entity_class, null::int, o.meta_number
    		FROM overpayments o
    		JOIN entity e ON (e.id=o.entity_id)
    		WHERE available <> 0 AND in_account_class = payment_class;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION payment_get_unused_overpayment(
in_account_class int, in_entity_credit_id int, in_chart_id int)
returns SETOF overpayments AS
$$
              SELECT DISTINCT *
              FROM overpayments
              WHERE payment_class  = in_account_class
              AND entity_credit_id = in_entity_credit_id
              AND available <> 0
              AND (in_chart_id IS NULL OR chart_id = in_chart_id )
              ORDER BY payment_date;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION payment_get_unused_overpayment(
in_account_class int, in_entity_credit_id int, in_chart_id int)
returns SETOF overpayments AS
$$
              SELECT DISTINCT *
              FROM overpayments
              WHERE payment_class  = in_account_class
              AND entity_credit_id = in_entity_credit_id
              AND available <> 0
              AND (in_chart_id IS NULL OR chart_id = in_chart_id )
              ORDER BY payment_date;
$$ LANGUAGE SQL;

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
              SELECT chart_id, accno,   chart_description, available
              FROM overpayments
              WHERE payment_class  = in_account_class
              AND entity_credit_id = in_entity_credit_id
              AND available <> 0;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION payment_get_unused_overpayment(
in_account_class int, in_entity_credit_id int, in_chart_id int) IS
$$ Returns a list of available overpayments$$;

CREATE OR REPLACE FUNCTION payment__get_gl(in_payment_id int)
returns gl
language sql as
$$
SELECT * FROM gl WHERE id = (select id from payment where id = $1);
$$;


DROP TYPE IF EXISTS overpayment_list_item CASCADE;
CREATE TYPE overpayment_list_item AS (
  payment_id int,
  entity_name text,
  available numeric,
  transdate date,
  amount numeric
);
CREATE OR REPLACE FUNCTION payment__overpayments_list
(in_date_from date, in_date_to date, in_control_code text, in_meta_number text,
 in_name_part text)
RETURNS SETOF overpayment_list_item
LANGUAGE SQL AS
$$
-- I don't like the subquery below but we are looking for the first line, and
-- I can't think of a better way to do that. --CT

-- This should never hit an income statement-side account but I have handled it
-- in case of configuration error. --CT
SELECT o.payment_id, e.name, o.available, g.transdate,
       (select amount * CASE WHEN c.category in ('A', 'E') THEN -1 ELSE 1 END
          from acc_trans
         where g.id = trans_id
               AND chart_id = o.chart_id ORDER BY entry_id ASC LIMIT 1) as amount
  FROM overpayments o
  JOIN payment p ON o.payment_id = p.id
  JOIN gl g ON g.id = p.gl_id
  JOIN account c ON c.id = o.chart_id
  JOIN entity_credit_account eca ON eca.id = o.entity_credit_id
  JOIN entity e ON eca.entity_id = e.id
 WHERE ($1 IS NULL OR $1 <= g.transdate) AND
       ($2 IS NULL OR $2 >= g.transdate) AND
       ($3 IS NULL OR $3 = e.control_code) AND
       ($4 IS NULL OR $4 = eca.meta_number) AND
       ($5 IS NULL OR e.name @@ plainto_tsquery($5));
$$;

DROP FUNCTION IF EXISTS overpayment__reverse
(in_id int, in_transdate date, in_batch_id int, in_account_class int,
in_cash_accno text, in_exchangerate numeric, in_curr char(3));

CREATE OR REPLACE FUNCTION overpayment__reverse
(in_id int, in_transdate date, in_batch_id int, in_account_class int, in_exchangerate numeric, in_curr char(3))
returns bool LANGUAGE PLPGSQL AS
$$
declare t_id int;
        in_cash_accno text;
BEGIN

-- reverse overpayment gl

INSERT INTO gl (transdate, reference, description, approved)
SELECT transdate, reference || '-reversal', 'reversal of ' || description, '0'
  FROM gl WHERE id = (select gl_id from payment where id = in_id);

IF NOT FOUND THEN
   RETURN FALSE;
END IF;

t_id := currval('id');

INSERT INTO voucher (batch_id, trans_id, batch_class)
VALUES (in_batch_id, t_id, CASE WHEN in_account_class = 1 THEN 4 ELSE 7 END);

INSERT INTO acc_trans (transdate, trans_id, chart_id, amount)
SELECT in_transdate, t_id, chart_id, amount * -1
  FROM acc_trans
 WHERE trans_id = in_id;

-- reverse overpayment usage
PERFORM payment__reverse(ac.source, ac.transdate, eca.id, at.accno,
        in_transdate, eca.entity_class, in_batch_id, null,
        in_exchangerate, in_curr)
  FROM acc_trans ac
  JOIN account at ON ac.chart_id = at.id
  JOIN account_link al ON at.id = al.account_id AND al.description like 'A%paid'
  JOIN (select id, entity_credit_account FROM ar UNION
        select id, entity_credit_account from ap) a ON a.id = ac.trans_id
  JOIN entity_credit_account eca ON a.entity_credit_account = eca.id
  JOIN payment_links pl ON pl.entry_id = ac.entry_id
  JOIN overpayments op ON op.payment_id = pl.payment_id
  JOIN payment p ON p.id = op.payment_id
 WHERE p.gl_id = in_id
GROUP BY ac.source, ac.transdate, eca.id, eca.entity_class,
         at.accno, al.description;

RETURN TRUE;
END;
$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
