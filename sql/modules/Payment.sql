
set client_min_messages = 'warning';


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
CREATE OR REPLACE FUNCTION payment_get_entity_accounts
(in_account_class int,
 in_vc_name text,
 in_vc_idn  text,
 in_datefrom date,
 in_dateto date)
 returns SETOF payment_vc_info AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
              SELECT ec.id, coalesce(ec.pay_to_name, e.name ||
                     coalesce(':' || ec.description,'')) as name,
                     ec.entity_class, ec.discount_account_id, ec.meta_number
                FROM entity_credit_account ec
                JOIN entity e ON (ec.entity_id = e.id)
                WHERE ec.entity_class = $1
                AND (e.name ilike coalesce('%'||$2||'%','%%')
                    OR EXISTS (select 1 FROM company
                                WHERE entity_id = e.id AND tax_id = $3))
                AND (
                  $4 is null
                  or ec.enddate is null
                  or ec.enddate >= $4
                )
                AND (
                  $5 is null
                  or ec.startdate is null
                  or ec.startdate <= $5
                )
$sql$
USING in_account_class, in_vc_name, in_vc_idn, in_datefrom, in_dateto;
END
$$ LANGUAGE PLPGSQL;

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
RETURNS payment_vc_info AS
$$
DECLARE
  t_retval payment_vc_info;
BEGIN
EXECUTE $sql$
 SELECT ec.id, coalesce(ec.pay_to_name, cp.name  || coalesce(':' || ec.description, ''), '') as name,
        ec.entity_class, ec.discount_account_id, ec.meta_number
 FROM entity_credit_account ec
 JOIN entity e ON (ec.entity_id = e.id)
 JOIN (
   select entity_id, legal_name as name
   from company
   union all
   select entity_id, first_name || coalesce(' ' || middle_name || ' ', '') || last_name
   from person
 ) cp ON (cp.entity_id = e.id)
 WHERE ec.id = $1
$sql$
INTO t_retval
USING in_entity_credit_id;
RETURN t_retval;
END
$$ LANGUAGE PLPGSQL;

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


-- payment_get_open_accounts and the option to get all accounts need to be
-- refactored and redesigned.  -- CT
CREATE OR REPLACE FUNCTION payment_get_open_accounts
(in_account_class int, in_datefrom date, in_dateto date)
returns SETOF payment_open_account AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
                SELECT ec.id, e.name, ec.entity_class
                FROM entity e
                JOIN entity_credit_account ec ON (ec.entity_id = e.id)
                        WHERE ec.entity_class = $1
                        AND (
                          $2 is null
                          or ec.enddate is null
                          or ec.enddate >= $2
                        )
                        AND (
                          $3 is null
                          or ec.startdate is null
                          or ec.startdate <= $3
                        )
                        AND CASE WHEN $1 = 1 THEN
                                ec.id IN
                                (SELECT entity_credit_account
                                   FROM acc_trans
                                   JOIN ap ON (acc_trans.open_item_id = ap.open_item_id)
                                   GROUP BY ap.open_item_id, entity_credit_account
                                   HAVING SUM(acc_trans.amount_bc) <> 0)
                               WHEN $1 = 2 THEN
                                ec.id IN (SELECT entity_credit_account
                                   FROM acc_trans
                                   JOIN ar ON (acc_trans.open_item_id = ar.open_item_id)
                                   GROUP BY ar.open_item_id, entity_credit_account
                                   HAVING SUM(acc_trans.amount_bc) <> 0)
                          END
$sql$
USING in_account_class, in_datefrom, in_dateto;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_open_accounts(int, date, date) IS
  $$ This function takes an argument (1 for vendor, 2 for customer)
  and 'from' and 'to' dates and returns all entities with open accounts of the appropriate type
  which have a validity interval (between 'start' and 'end' dates) which overlaps with the
  interval between 'from' and 'to' dates. $$;

CREATE OR REPLACE FUNCTION payment_get_all_accounts(in_account_class int)
RETURNS SETOF payment_open_account AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
                SELECT  ec.id,
                        e.name, ec.entity_class
                FROM entity e
                JOIN entity_credit_account ec ON (ec.entity_id = e.id)
                                WHERE ec.entity_class = $1
$sql$
USING in_account_class;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_all_accounts(int) IS
$$ This function takes a single argument (1 for vendor, 2 for customer)
$$;

COMMENT ON FUNCTION payment_get_all_accounts(int) IS
$$ This function takes a single argument (1 for vendor, 2 for customer as
always) and returns all entities with accounts of the appropriate type. $$;

DROP TYPE IF EXISTS payment_invoice CASCADE;

CREATE TYPE payment_invoice AS (
        invoice_id int,
        open_item_id int,
        invnumber text,
        invoice bool,
        invoice_date date,
        amount numeric,
        amount_tc numeric,
        discount numeric,
        discount_tc numeric,
        due numeric,
        due_fx numeric,
        exchangerate numeric,
        description text
);


CREATE OR REPLACE FUNCTION payment_get_open_invoices
(in_account_class int,
 in_entity_credit_id int,
 in_curr char(3),
 in_datefrom date,
 in_dateto date,
 in_amountfrom numeric,
 in_amountto   numeric,
 in_datepaid   date)
RETURNS SETOF payment_invoice AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
                SELECT a.id AS invoice_id, a.open_item_id, a.invnumber AS invnumber,a.invoice AS invoice,
                       a.transdate AS invoice_date, a.amount_bc AS amount,
                       a.amount_tc,
                       (CASE WHEN (c.discount_terms||' days')::interval < age(coalesce($8, current_date), a.transdate)
                        THEN 0
                        ELSE (coalesce(ac.due, a.amount_bc)) * coalesce(c.discount, 0) / 100
                        END) AS discount,
                       (CASE WHEN (c.discount_terms||' days')::interval < age(coalesce($8, current_date), a.transdate)
                        THEN 0
                        ELSE (coalesce(ac.due_fx, a.amount_tc)) * coalesce(c.discount, 0) / 100
                        END) AS discount_tc,
                       ac.due - (CASE WHEN (c.discount_terms||' days')::interval < age(coalesce($8, current_date), a.transdate)
                        THEN 0
                        ELSE (coalesce(ac.due, a.amount_bc)) * coalesce(c.discount, 0) / 100
                        END) AS due,
                       ac.due_fx - (CASE WHEN (c.discount_terms||' days')::interval < age(coalesce($8, current_date), a.transdate)
                        THEN 0
                        ELSE (coalesce(ac.due_fx, a.amount_tc)) * coalesce(c.discount, 0) / 100
                         END) AS due_fx,
                        null::numeric AS exchangerate,
                        a.description
                 FROM  (SELECT txn.id, open_item_id, invnumber, invoice, txn.transdate, amount_bc,
                       amount_tc,
                               1 as invoice_class, curr,
                               entity_credit_account, txn.approved, description
                          FROM ap JOIN transactions txn ON txn.id = ap.trans_id
                         UNION
                         SELECT txn.id, open_item_id, invnumber, invoice, txn.transdate, amount_bc,
                      amount_tc,
                               2 AS invoice_class, curr,
                               entity_credit_account, txn.approved, description
                         FROM ar JOIN transactions txn ON txn.id = ar.trans_id
                         ) a
                JOIN (SELECT open_item_id,
                             sum(CASE WHEN $1 = 1 THEN amount_bc
                                      WHEN $1 = 2 THEN amount_bc * -1
                                  END) as due,
                             sum(CASE WHEN $1 = 1 THEN amount_tc
                                      WHEN $1 = 2 THEN amount_tc * -1
                                 END) as due_fx
                        FROM acc_trans
                      GROUP BY open_item_id) ac ON (ac.open_item_id = a.open_item_id)
                        JOIN entity_credit_account c ON (c.id = a.entity_credit_account)
                        WHERE  a.invoice_class = $1
                        AND c.entity_class = $1
                        AND c.id = $2
                        --### short term: ignore fractional cent differences
                        AND a.curr = $3
                        AND (a.transdate >= $5
                             OR $5 IS NULL)
                        AND (a.transdate <= $5
                             OR $5 IS NULL)
                        AND (a.amount_bc >= $6
                             OR $6 IS NULL)
                        AND (a.amount_bc <= $7
                             OR $7 IS NULL)
                        AND due <> 0
                        AND a.approved = true
                        GROUP BY a.id, a.open_item_id, a.invnumber, a.transdate, a.amount_bc, amount_tc,
              discount, discount_tc, ac.due, ac.due_fx, c.discount_terms,
              a.curr, a.invoice, a.description
$sql$
USING in_account_class, in_entity_credit_id, in_curr, in_datefrom,
 in_dateto, in_amountfrom, in_amountto, in_datepaid;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_open_invoices(int, int, char(3),
date, date, numeric, numeric, date) IS
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
 in_invnumber text,
 in_datepaid  date)
RETURNS SETOF payment_invoice AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
                SELECT * from payment_get_open_invoices($1, $2, $3, $4, $5, $6,
                $7, $9)
                WHERE (invnumber like $8 OR $8 IS NULL)
$sql$
USING in_account_class, in_entity_credit_id, in_curr, in_datefrom,
 in_dateto, in_amountfrom, in_amountto, in_invnumber,
 in_datepaid;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_open_invoice(int, int, char(3), date, date, numeric, numeric, text, date) IS
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
        in_ar_ap_accno text, in_meta_number text, in_contact_name text,
        in_payment_date date)
RETURNS SETOF payment_contact_invoice AS
$$
  SELECT c.id AS contact_id, e.control_code as econtrol_code,
         c.description as eca_description,
         e.name AS contact_name,
         c.meta_number::text AS account_number,
         sum(
           case when u.username IS NULL or
                   u.username = SESSION_USER
             THEN coalesce(p.due::numeric, 0) -
             CASE WHEN (c.discount_terms||' days')::interval
                    > age(coalesce(in_payment_date, current_date), t.transdate)
             THEN 0
              ELSE (coalesce(p.due::numeric, 0)) *
              coalesce(c.discount::numeric, 0) / 100
              END
              ELSE 0::numeric
              END) AS total_due,
         array_agg(ARRAY[
           a.id::text, a.open_item_id::text, a.invnumber, t.transdate::text,
           a.amount_bc::text, (a.amount_bc - p.due)::text,
           (CASE WHEN (c.discount_terms||' days')::interval
                     < age(coalesce(in_payment_date, current_date), t.transdate)
             THEN 0
            ELSE (coalesce(p.due, 0) * coalesce(c.discount, 0) / 100)
            END)::text,
            (coalesce(p.due, 0) -
            (CASE WHEN (c.discount_terms||' days')::interval
                      < age(coalesce(in_payment_date, current_date), t.transdate)
              THEN 0
             ELSE (coalesce(p.due, 0)) * coalesce(c.discount, 0) / 100
             END))::text,
             case when u.username IS NOT NULL
             and u.username <> SESSION_USER
             THEN 0::text
             ELSE 1::text
             END,
             COALESCE(u.username, 0::text)
             ]),
         sum(case when a.batch_id = in_batch_id then 1
             else 0 END),
         bool_and(lock_record(a.id, (select max(session_id)
                                       FROM "session" where users_id = (
                                         select id from users WHERE username =
                                                                    SESSION_USER))))

    FROM entity e
           JOIN entity_credit_account c
               ON e.id = c.entity_id
           JOIN (
             SELECT ap.trans_id as id, ap.open_item_id, invnumber, amount_bc,
                    curr, 1 as invoice_class,
                    entity_credit_account, on_hold, v.batch_id
               FROM ap
                      LEFT JOIN voucher v
                          ON ap.trans_id = v.trans_id
              WHERE in_account_class = 1
              UNION ALL
             SELECT ar.trans_id, ar.open_item_id, invnumber, amount_bc,
                    curr, 2 as invoice_class,
                    entity_credit_account, on_hold, v.batch_id
               FROM ar
                      LEFT JOIN voucher v
                          ON ar.trans_id = v.trans_id
              WHERE in_account_class = 2
           ) a
               ON a.entity_credit_account = c.id
           JOIN transactions t
               ON a.id = t.id
           JOIN (
             SELECT acc_trans.open_item_id,
                    sum(CASE WHEN in_account_class = 1 THEN amount_bc
                        WHEN in_account_class = 2
                          THEN amount_bc * -1
                        END) AS due
               FROM acc_trans
              WHERE approved IS TRUE
              GROUP BY acc_trans.open_item_id
           ) p
               ON a.open_item_id = p.open_item_id
           LEFT JOIN "session" s
               ON s."session_id" = t.locked_by
           LEFT JOIN users u
               ON u.id = s.users_id
   WHERE (a.batch_id = in_batch_id
          OR (a.invoice_class = in_account_class
              AND t.approved
              AND due <> 0
              AND NOT a.on_hold
              AND a.curr = in_currency
              AND EXISTS (select 1
                            FROM acc_trans
                           WHERE trans_id = a.id AND
                                 chart_id = (SELECT id from account
                                              WHERE accno
                                                    = in_ar_ap_accno)
              )))
     AND (in_meta_number IS NULL OR
          in_meta_number = c.meta_number)
     AND (in_contact_name IS NULL OR
          e.name ilike '%' || in_contact_name || '%')
   GROUP BY c.id, e.name, c.meta_number, c.threshold,
            e.control_code, c.description
  HAVING  c.threshold is null or (sum(p.due) >= c.threshold
                                  OR sum(case when a.batch_id = in_batch_id then 1
                                         else 0 END) > 0)
   ORDER BY c.meta_number ASC;

$$ LANGUAGE SQL;

COMMENT ON FUNCTION payment_get_all_contact_invoices
(in_account_class int, in_business_id int, in_currency char(3),
        in_date_from date, in_date_to date, in_batch_id int,
        in_ar_ap_accno text, in_meta_number text, in_contact_name text,
        in_datepaid date) IS
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
(in_transactions numeric[], in_batch_id int, in_source text,
        in_ar_ap_accno text, in_cash_accno text,
        in_payment_date date, in_account_class int,
        in_exchangerate numeric, in_currency text)
RETURNS int AS
$$
DECLARE
  out_count int;
  t_amount numeric;
  t_ar_ap_id int;
  t_cash_id int;
  t_defaultcurr text;
  t_exchangerate numeric;
  t_cash_sign int;
  t_batch batch;
BEGIN
  t_exchangerate := in_exchangerate;

  IF in_batch_id IS NULL THEN
    -- t_voucher_id := NULL;
    RAISE EXCEPTION 'Bulk Post Must be from Batch!';
  ELSE
    SELECT * INTO t_batch FROM batch WHERE in_batch_id = id;
    IF t_batch.approved_by IS NOT NULL THEN
      RAISE EXCEPTION 'Approved Batch';
    ELSIF t_batch.locked_by IS NOT NULL THEN
      PERFORM *
         FROM session
              JOIN users ON (session.users_id = users.id)
        WHERE session_id = t_batch.locked_by
              AND users.username = SESSION_USER;

      IF NOT FOUND THEN
        -- locked by someone else
        RAISE EXCEPTION 'batch locked by %, I am %', t_batch.locked_by, session_user;
      END IF;
    END IF;
  END IF;

  SELECT * INTO t_defaultcurr
    FROM defaults_get_defaultcurrency();


  IF in_account_class = 1 THEN
    t_cash_sign := 1;
  ELSE
    t_cash_sign := -1;
  END IF;

  IF (in_currency IS NULL OR in_currency = t_defaultcurr) THEN
    t_exchangerate := 1;
  END IF;
  IF t_exchangerate IS NULL THEN
    RAISE EXCEPTION 'No exchangerate provided and not default currency';
  END IF;

  CREATE TEMPORARY TABLE bulk_payments_in (
    id int,                   -- AR/AP id
    trans_id int,             -- payment transaction id
    voucher_id int,           -- voucher id
    open_item_id int,         -- open_item.id
    payment_id int,           -- payment.id
    eca_id int,               -- entity_credit_account.id
    entry_id int,             -- acc_trans.entry_id
    amount_bc numeric,        -- amount in local currency (current rate)
    amount_tc numeric,        -- amount in foreign currency
    disc_amount_bc numeric,   -- discount amount in
    disc_amount_tc numeric,
    fxrate numeric,
    gain_loss_accno int,
    want_gain_loss_accno boolean,
    invoice_date date);

  FOR out_count IN
    array_lower(in_transactions, 1) ..
    array_upper(in_transactions, 1)
  LOOP
      -- Fill the bulk payments table
      IF in_transactions[out_count][2] <> 0 THEN
        INSERT INTO bulk_payments_in(id, open_item_id, amount_tc)
        VALUES (in_transactions[out_count][1],
                in_transactions[out_count][2],
                in_transactions[out_count][3]);
      END IF;
    END LOOP;

  UPDATE bulk_payments_in bpi
     SET eca_id =
         (SELECT entity_credit_account FROM ar
           WHERE in_account_class = 2
             AND bpi.id = ar.trans_id
           UNION
          SELECT entity_credit_account FROM ap
           WHERE in_account_class = 1
             AND bpi.id = ap.trans_id);

  CREATE TEMPORARY TABLE eca_payments_in AS
    WITH new_workflow (workflow_id) AS (
      INSERT INTO workflow (workflow_id, type, state)
      VALUES (nextval('workflow_seq'), 'Payment', 'SAVED')
             RETURNING workflow_id
    )
    SELECT eca_id, nextval('payment_id_seq') as payment_id,
           nextval('transactions_id_seq') as trans_id,
           nextval('voucher_id_seq') as voucher_id,
           -- this logic is reversed, but mirrors what's been
           -- incorrect in payment post since 12 years...
           case when in_account_class = 1
             then setting_increment('rcptnumber')
             else setting_increment('paynumber')
             end as reference,
           (select workflow_id
              from new_workflow) as workflow_id
      FROM bulk_payments_in
     GROUP BY eca_id;

  UPDATE bulk_payments_in bpi
     SET payment_id = ep.payment_id,
         trans_id = ep.trans_id,
         voucher_id = ep.voucher_id
    from eca_payments_in ep
   where bpi.eca_id = ep.eca_id;


  UPDATE bulk_payments_in bpi
     SET invoice_date = (select transdate from transactions trn
                          where trn.id = bpi.id);

  IF (in_currency IS NULL OR in_currency = t_defaultcurr) THEN
    UPDATE bulk_payments_in
    SET fxrate = 1;
  ELSE
    UPDATE bulk_payments_in
       SET fxrate =
           (SELECT fxrate

              FROM (SELECT id, CASE WHEN amount_tc<>0
                THEN amount_bc/amount_tc
                               ELSE NULL END as fxrate
                      FROM ar
                     UNION
                    SELECT id, CASE WHEN amount_tc<>0
                      THEN amount_bc/amount_tc
                               ELSE NULL END as fxrate
                      FROM ap) a
             WHERE a.id = bulk_payments_in.id);

    UPDATE bulk_payments_in
       SET want_gain_loss_accno = true,
           gain_loss_accno =
           (SELECT value::int FROM defaults
             WHERE setting_key = 'fxgain_accno_id')
     WHERE ((t_exchangerate - bulk_payments_in.fxrate)
            * t_cash_sign) < 0;

    UPDATE bulk_payments_in
       SET want_gain_loss_accno = true,
           gain_loss_accno = (SELECT value::int FROM defaults
                               WHERE setting_key = 'fxloss_accno_id')
     WHERE ((t_exchangerate - bulk_payments_in.fxrate)
            * t_cash_sign) > 0;
    -- explicitly leave zero gain/loss accno_id entries at NULL
    -- so we have an easy check later
  END IF;

  PERFORM * FROM bulk_payments_in
    WHERE want_gain_loss_accno AND gain_loss_accno IS NULL;
  IF FOUND THEN
    RAISE 'Missing gain/loss account while posting FX difference';
  END IF;

  UPDATE bulk_payments_in bpi
     SET disc_amount_tc = coalesce(
       (SELECT bpi.amount_tc
                 / (100 - eca.discount::numeric)
                 * eca.discount::numeric
          FROM entity_credit_account eca
         WHERE age(in_payment_date, bpi.invoice_date)
               < (eca.discount_terms||' days')::interval
           AND eca.discount_terms IS NOT NULL
           AND eca.discount IS NOT NULL
           AND eca.discount_account_id IS NOT NULL
           AND eca.id = bpi.eca_id),
           0);

  UPDATE bulk_payments_in
     SET amount_bc = amount_tc * t_exchangerate,
         disc_amount_bc = disc_amount_tc * t_exchangerate;


  select id into t_ar_ap_id from account where accno = in_ar_ap_accno;
  select id into t_cash_id from account where accno = in_cash_accno;



  -- Given an open item, created on an earlier date, at an FX rate of '2',
  -- the code below inserts this transaction (for each line in bulk_payments_in),
  -- with the FX rate of the current transaction being '3' and the terms of the
  -- transaction being 10/30 and the transaction being paid within the term.

  --                   |   Credits       |   Debits        |   FX  |
  --                   |   BC   |   TC   |   BC   |   TC   |  rate |
  --   ----------------+--------+--------+--------+--------+-------|
  --   Current account |     81 |     27 |        |        |  curr |
  --   Discounts       |      9 |      3 |        |        |  curr |
  --   ----------------+--------+--------+--------+--------+-------|
  --   Accounts rec    |        |        |     60 |     30 |  orig |
  --   FX effects      |        |        |     30 |      0 |   na  |
  --   ----------------+--------+--------+--------+--------+-------|
  --   Total           |     90 |     30 |     90 |     30 |       |
  --   ----------------+--------+--------+--------+--------|-------|

  -- Note: due to the fact that the discount is valued at the current rate,
  --   the revaluation is based on the accounts receivable amount.
  --   If the discount amount were to be valued at the original rate,
  --   the FX effect should be calculated based on the current payment amount

  INSERT INTO transactions (id, table_name, transdate, approved,
                            reference, trans_type_code, entered_by, workflow_id)
              OVERRIDING SYSTEM VALUE
  SELECT epi.trans_id, 'payment', in_payment_date, false,
         epi.reference, 'pa', person__get_my_entity_id(), workflow_id
    FROM eca_payments_in epi;

  INSERT INTO voucher (id, batch_id, trans_id, batch_class)
              OVERRIDING SYSTEM VALUE
  SELECT epi.voucher_id, in_batch_id, epi.trans_id,
         (SELECT batch_class_id FROM batch WHERE id = in_batch_id)
    FROM eca_payments_in epi;

  -- The 'id' values were allocated above
  INSERT INTO payment (id, trans_id, reference, payment_class, payment_date,
                       entity_credit_id, employee_id, currency, notes, account_id)
  SELECT epi.payment_id, epi.trans_id, epi.reference, in_account_class,
         in_payment_date, epi.eca_id, person__get_my_id(), in_currency,
         'generated from bulk payment', t_cash_id
    FROM eca_payments_in epi;

  -- Insert cash side @ current fx rate
  UPDATE bulk_payments_in
     SET entry_id = nextval('acc_trans_entry_id_seq')
   WHERE amount_tc <> 0;
  INSERT INTO acc_trans
              (trans_id, chart_id, amount_bc, curr, amount_tc, approved,
              voucher_id, transdate, source, entry_id)
  SELECT trans_id, t_cash_id, amount_bc * t_cash_sign,
         in_currency, amount_tc * t_cash_sign, false,
         voucher_id, in_payment_date, in_source, entry_id
    FROM bulk_payments_in  where amount_tc <> 0;

  -- Insert discount @ current fx rate
  UPDATE bulk_payments_in
     SET entry_id = nextval('acc_trans_entry_id_seq')
   WHERE disc_amount_bc <> 0;
  INSERT INTO acc_trans
              (trans_id, chart_id, amount_bc, curr, amount_tc, approved,
              voucher_id, transdate, source, entry_id)
  SELECT bpi.trans_id, eca.discount_account_id,
         disc_amount_bc * t_cash_sign, in_currency,
         disc_amount_tc * t_cash_sign, false,
         voucher_id, in_payment_date, in_source, entry_id
    FROM bulk_payments_in bpi
           JOIN entity_credit_account eca ON bpi.eca_id = eca.id
   WHERE bpi.disc_amount_bc <> 0;

  -- Insert AR/AP amount @ orginal rate
  UPDATE bulk_payments_in
     SET entry_id = nextval('acc_trans_entry_id_seq');
  INSERT INTO acc_trans
              (trans_id, chart_id, amount_bc, curr, amount_tc, approved,
              voucher_id, transdate, source, entry_id, open_item_id)
  SELECT bpi.trans_id, t_ar_ap_id,
         (bpi.amount_tc + bpi.disc_amount_tc)
           * t_cash_sign * -1 * bpi.fxrate, in_currency,
         (bpi.amount_tc + bpi.disc_amount_tc)
           * t_cash_sign * -1, false,
         voucher_id, in_payment_date, in_source, entry_id, open_item_id
    FROM bulk_payments_in bpi
           JOIN entity_credit_account eca ON bpi.eca_id = eca.id;

  -- Insert fx gain/loss effects, if applicable
  UPDATE bulk_payments_in
     SET entry_id = nextval('acc_trans_entry_id_seq')
   WHERE gain_loss_accno IS NOT NULL;
  INSERT INTO acc_trans
              (trans_id, chart_id, amount_bc, curr, amount_tc, approved,
              voucher_id, transdate, source, entry_id)
  SELECT trans_id, gain_loss_accno,
         amount_tc * t_cash_sign *
           (t_exchangerate - fxrate),
         in_currency, 0, false,
         voucher_id, in_payment_date, in_source, entry_id
    FROM bulk_payments_in
   WHERE gain_loss_accno IS NOT NULL;

  DROP TABLE bulk_payments_in;
  DROP TABLE eca_payments_in;
  perform unlock_all();
  return out_count;
END;

$$ language plpgsql;

COMMENT ON FUNCTION payment_bulk_post
(in_transactions numeric[], in_batch_id int, in_source text,
        in_ar_ap_accno text, in_cash_accno text,
        in_payment_date date, in_account_class int,
        in_exchangerate numeric, in_currency text)
IS
$$ This posts the payments for large batch workflows.



Note that in_transactions is a two-dimensional numeric array.  Of each
sub-array, the first element is the (integer) transaction id, and the second
is the amount for that transaction.  $$;


CREATE OR REPLACE FUNCTION payment_post
(in_datepaid                      date,
 in_account_class                 int,
 in_entity_credit_id              int,
 in_curr                          char(3),
 in_exchangerate                  numeric,
 in_notes                         text,
 in_gl_description                text,
 in_cash_account_id               int[],
 in_amount                        numeric[],
 in_source                        text[],
 in_memo                          text[],
 in_transaction_id                int[],
 in_open_item_id                  int[],
 in_op_amount                     numeric[],
 in_op_cash_account_id            int[],
 in_op_source                     text[],
 in_op_memo                       text[],
 in_op_account_id                 int[],
 in_ovp_payment_id                int[],
 in_approved                      bool)
RETURNS INT AS
$$
DECLARE
  var_cash_account_id int;
  var_payment_id int;
  var_txn_id int;
  var_entry record;
  var_entry_id int[];
  out_count int;
  coa_id record;
  var_employee int;
  var_account_id int;
  default_currency char(3);
  current_exchangerate numeric;
  old_exchangerate numeric;
  fx_gain_loss_amount numeric;
  gain_loss_accno_id int;
  sign int;
BEGIN
  IF array_upper(in_amount, 1) <> array_upper(in_cash_account_id, 1) THEN
    RAISE EXCEPTION 'Wrong number of accounts';
  END IF;
  IF (select count(distinct acct)
        from unnest(in_cash_account_id) as arr(acct)) > 1 THEN
    RAISE EXCEPTION 'Single payments only supported against a single payment account';
  ELSE
    var_cash_account_id := in_cash_account_id[array_lower(in_cash_account_id, 1)];
  END IF;

  current_exchangerate := in_exchangerate;
  IF in_account_class = 1 THEN
    sign := 1;
  ELSE
    sign := -1;
  END IF;
  SELECT * INTO default_currency  FROM defaults_get_defaultcurrency();

  SELECT INTO var_employee p.id
    FROM users u
           JOIN person p ON (u.entity_id=p.entity_id)
   WHERE username = SESSION_USER
   LIMIT 1;

  INSERT INTO workflow (workflow_id, type, last_update, state)
  VALUES (nextval('workflow_seq'), 'Payment', NOW(),
          CASE WHEN coalesce(in_approved, true) THEN 'POSTED' ELSE 'SAVED' END);

  INSERT INTO transactions (table_name, transdate, approved,
                            reference,
                            trans_type_code, entered_by, workflow_id)
  VALUES ('payment', in_datepaid, coalesce(in_approved, true),
          (
            CASE WHEN in_account_class = 1 THEN setting_increment('rcptnumber')
            ELSE setting_increment('paynumber')
            END
          ),
          'pa', person__get_my_entity_id(), currval('workflow_seq'))
  RETURNING id into var_txn_id;

  -- WE HAVE TO INSERT THE PAYMENT, USING THE GL INFORMATION
  -- THE ID IS GENERATED BY payment_id_seq
  INSERT INTO payment (trans_id, account_id, reference, payment_class, payment_date,
                       employee_id, currency, notes, entity_credit_id)
  VALUES (var_txn_id, var_cash_account_id,
          -- the rcptnumber and paynumber are reversed; have been for 12 years
          (CASE WHEN in_account_class = 1 THEN setting_increment('rcptnumber')
           ELSE setting_increment('paynumber')
           END),
           in_account_class, in_datepaid, var_employee,
           in_curr, in_notes, in_entity_credit_id);

  -- Assuming a transaction with foreign currency being recorded,
  -- at an exchangerate of 3 upon AR creation and an exchangerate of 2
  -- upon payment. The owed (and paid) amount is 20 in the foreign currency.

  -- 5000 = 'AR' account
  -- 5100 = 'Cash' account
  -- 9999 = fx gain/loss account

  -- +-------+----------+----------+----------+----------+
  -- | accno | Deb (bc) | Deb (tc) | Cre (bc) | Cre (tc) |
  -- +-------+----------+----------+----------+----------+
  -- | 5000  |          |          |    60.00 |    20.00 |
  -- +-------+----------+----------+----------+----------+
  -- | 5100  |    40.00 |    20.00 |          |          |
  -- +-------+----------+----------+----------+----------+
  -- | 9999  |    20.00 |    00.00 |          |          |
  -- +-------+----------+----------+----------+----------+

  -- +-------+----------+----------+----------+----------+
  -- | Total |    60.00 |    20.00 |    60.00 |    20.00 |
  -- +-------+----------+----------+----------+----------+


  SELECT currval('payment_id_seq') INTO var_payment_id;
  IF (array_upper(in_cash_account_id, 1) > 0) THEN
    DECLARE
      var_payment_bc numeric;
      var_payment_tc numeric;
      var_overpayment_id int;
    BEGIN
      IF (select count(distinct coalesce(opmt_id, -1))
            from unnest(in_ovp_payment_id) as arr(opmt_id)) > 1 THEN
        RAISE EXCEPTION 'Single payments do not support a mix of overpayments';
      ELSE
        var_overpayment_id := in_ovp_payment_id[array_lower(in_ovp_payment_id, 1)];
      END IF;

      var_payment_bc := 0;
      var_payment_tc := 0;
      FOR out_count IN
        array_lower(in_cash_account_id, 1) ..
        array_upper(in_cash_account_id, 1)
      LOOP
        var_payment_bc := var_payment_bc + in_amount[out_count]*current_exchangerate*sign;
        var_payment_tc := var_payment_tc + in_amount[out_count]*sign;
      END LOOP;

      -- If there's an overpayment creation involved, add those amounts too
      IF (array_upper(in_op_cash_account_id, 1) > 0) THEN
        FOR out_count IN
          array_lower(in_op_cash_account_id, 1) ..
          array_upper(in_op_cash_account_id, 1)
        LOOP
          var_payment_bc := var_payment_bc + in_op_amount[out_count]*current_exchangerate*sign;
          var_payment_tc := var_payment_tc + in_op_amount[out_count]*sign;
        END LOOP;
      END IF;

      -- Insert the side the allocation is coming from;
      -- which can be (a) a cash account; or (b) an overpayment account
      --
      -- When overpayments are posted, the source account must be posted
      -- with an open_item_id to attribute the transaction as change in
      -- the overpayment balance
      INSERT INTO acc_trans
                  (chart_id, amount_bc, curr, amount_tc, trans_id,
                  transdate, approved, source, memo, open_item_id)
      VALUES (var_cash_account_id,
              var_payment_bc,
              in_curr,
              var_payment_tc,
              var_txn_id,
              in_datepaid,
              coalesce(in_approved, true),
              in_source[array_lower(in_source, 1)],
              in_memo[array_lower(in_memo, 1)],
              var_overpayment_id);
    END;

    -- HANDLE THE AR/AP ACCOUNTS
    -- OBTAIN THE ACCOUNT AND EXCHANGERATE FROM THERE
    FOR out_count IN
        array_lower(in_transaction_id, 1) ..
        array_upper(in_transaction_id, 1)
    LOOP
      SELECT oi.account_id, amount_bc/amount_tc
        INTO var_account_id, old_exchangerate
        FROM (select open_item_id, amount_bc, amount_tc from ar
               union all
              select open_item_id, amount_bc, amount_tc from ap) aa
               JOIN open_item oi ON aa.open_item_id = oi.id
       WHERE open_item_id = in_open_item_id[out_count];

      -- Now we post the AP/AR account
      INSERT INTO acc_trans (chart_id, amount_bc, curr, amount_tc,
                             trans_id, transdate, approved, source, memo, open_item_id)
      VALUES (var_account_id,
              in_amount[out_count]*old_exchangerate*sign*-1,
              in_curr,
              in_amount[out_count]*sign*-1,
              var_txn_id,
              in_datepaid,
              coalesce(in_approved, true),
              in_source[out_count],
              in_memo[out_count],
              in_open_item_id[out_count]);

      -- Calculate the gain/loss on the transaction
      -- everything above depends on this being an AR/AP posting
      -- the PNL posting and decision to post a gain or loss does not
      --  --> incorporate sign here instead of when posting.
      fx_gain_loss_amount :=
        in_amount[out_count]*sign*(old_exchangerate-current_exchangerate);

      IF (fx_gain_loss_amount > 0) THEN
        SELECT value::int INTO gain_loss_accno_id
        FROM defaults
        WHERE setting_key = 'fxgain_accno_id';
      ELSIF (fx_gain_loss_amount < 0) THEN
        SELECT value::int INTO gain_loss_accno_id
        FROM defaults
        WHERE setting_key = 'fxloss_accno_id';
      END IF;
      IF fx_gain_loss_amount <> 0.00 THEN
        INSERT INTO acc_trans
        (chart_id, amount_bc, curr, amount_tc,
        trans_id, transdate, approved, source)
        -- In this transaction we can't use the default currency,
        -- because by definition the tc and bc amounts are the same.
        VALUES (gain_loss_accno_id,
                fx_gain_loss_amount,
                in_curr,
                0, -- the transaction currency side is zero by definition
                var_txn_id,
                in_datepaid,
                coalesce(in_approved, true),
                in_source[out_count]);

      END IF;
    END LOOP;
  END IF;


  --
  -- HANDLE THE OVERPAYMENTS NOW
  IF (array_upper(in_op_cash_account_id, 1) > 0) THEN
    -- HANDLE THE OVERPAYMENT ACCOUNTS
    -- The cash side was dealt with when we created the cash account journal line
    FOR out_count IN
      array_lower(in_op_account_id, 1) ..
      array_upper(in_op_account_id, 1)
    LOOP
      INSERT INTO open_item (
        item_number, item_type, account_id
      )
      VALUES ('overpay-' || var_txn_id, 'op', in_op_account_id[out_count]);

      INSERT INTO overpayment (
        open_item_id, eca_id
      )
      VALUES (currval('open_item_id_seq'), in_entity_credit_id);

      INSERT INTO acc_trans (chart_id, amount_bc, curr, amount_tc, trans_id,
                             transdate, approved, source, memo, open_item_id)
      VALUES (in_op_account_id[out_count],
              in_op_amount[out_count]*current_exchangerate*sign*-1,
              in_curr,
              in_op_amount[out_count]*sign*-1,
              var_txn_id,
              in_datepaid,
              coalesce(in_approved, true),
              in_op_source[out_count],
              in_op_memo[out_count],
              currval('open_item_id_seq'));
    END LOOP;
  END IF;
  return var_payment_id;
END;

$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_post
(in_datepaid                      date,
 in_account_class                 int,
 in_entity_credit_id                     int,
 in_curr                          char(3),
 in_exchangerate                  numeric,
 in_notes                         text,
 in_gl_description                text,
 in_cash_account_id               int[],
 in_amount                        numeric[],
 in_source                        text[],
 in_memo                          text[],
 in_transaction_id                int[],
 in_open_item_id                  int[],
 in_op_amount                     numeric[],
 in_op_cash_account_id            int[],
 in_op_source                     text[],
 in_op_memo                       text[],
 in_op_account_id                 int[],
 in_ovp_payment_id                int[],
 in_approved                      bool) IS
$$ Posts a payment.  in_op_* arrays are cross-indexed with eachother.
Other arrays are cross-indexed with eachother.

The 'in_cash_account_id's are the "cash side" of the payment; i.e. this can
be a bank current account, overpayment account or a suspense account associated
with a bank current account.
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
BEGIN
RETURN QUERY EXECUTE $sql$
                SELECT l.id, l.line_one, l.line_two, l.line_three, l.city,
                       l.state, l.mail_code, c.name, lc.class
                FROM location l
                JOIN entity_to_location ctl ON (ctl.location_id = l.id)
                JOIN entity cp ON (ctl.entity_id = cp.id)
                JOIN location_class lc ON (ctl.location_class = lc.id)
                JOIN country c ON (c.id = l.country_id)
                JOIN entity_credit_account ec ON (ec.entity_id = cp.id)
                WHERE ec.id = $1 AND
                      lc.id = $2
                ORDER BY lc.id, l.id, c.name
$sql$
USING in_entity_credit_id, in_location_class_id;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_vc_info(in_entity_id int, in_location_class_id int) IS
$$ This function returns vendor or customer info $$;

DROP TYPE IF EXISTS payment_record CASCADE;
CREATE TYPE payment_record AS (
        payment_id int,
        amount numeric,
        meta_number text,
        credit_id int,
        company_paid text,
        accounts text[],
        source text,
        batch_control text,
        batch_description text,
        voucher_id int,
        date_paid date,
        reversed_by int
);

CREATE OR REPLACE FUNCTION payment__search
(in_source text, in_from_date date, in_to_date date, in_credit_id int,
        in_cash_accno text, in_entity_class int, in_currency char(3),
        in_meta_number text)
RETURNS SETOF payment_record AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
   select p.id, sum(case when c.entity_class = 1 then a.amount_bc
                    else -1*a.amount_bc end),
          c.meta_number::text, c.id, e.name,
          array_agg(array[act.id::text, act.accno,
                                     act.description]),
          a.source, b.control_code, b.description,
          v.id, p.payment_date,
          (select r.id from payment r where r.reversing = p.id)
     from payment p
     join entity_credit_account c on p.entity_credit_id = c.id
     join entity e on e.id = c.entity_id
     join acc_trans a on p.trans_id = a.trans_id
     join account act on a.chart_id = act.id
     left join voucher v on a.voucher_id = v.id
     left join batch b on v.batch_id = b.id
    where ($2 is null
           or $2 <= p.payment_date)
          and ($3 is null
               or $3 >= p.payment_date)
          and ($4 is null
               or c.id = $4)
          and ($6 is null
               or c.entity_class = $6)
          and ($7 is null
               or p.currency = $7)
          and ($8 is null
               or c.meta_number = $8)
          and ($1 is null
               or a.source = $1)
          and (($5 is null
                and exists (select 1
                             from account_link al
                            where al.description in ('AR_paid', 'AP_paid')
                              and al.account_id = act.id))
               or a.chart_id = (select id from account
                                 where accno = $5))
        group by p.id, c.meta_number, c.id, e.name,
                 a.source, b.control_code, b.description,
                 v.id, p.payment_date
$sql$
USING in_source, in_from_date, in_to_date, in_credit_id,
 in_cash_accno, in_entity_class, in_currency, in_meta_number;
END
$$ LANGUAGE PLPGSQL;


COMMENT ON FUNCTION payment__search
(in_source text, in_date_from date, in_date_to date, in_credit_id int,
        in_cash_accno text, in_entity_class int, char(3), text) IS
$$This searches for payments.  in_date_to and _date_from specify the acceptable
date range.  All other matches are exact except that null matches all values.

Currently (and to support earlier data) we define a payment as a collection of
acc_trans records against the same credit account and cash account, on the same
day with the same source number, and optionally the same voucher id.$$;


CREATE OR REPLACE FUNCTION payment__reverse
(in_payment_id int, in_payment_date date, in_approved boolean,
in_batch_id int)
RETURNS INT
AS $$
DECLARE
  t_payment_id int;
BEGIN
  -- check against being an overpayment??
  INSERT INTO transactions (
    table_name, transdate, trans_type_code, reversing, approved
    )
  SELECT table_name, in_payment_date, 'pa', id, coalesce(in_approved, false)
    FROM transactions
   WHERE id = (select trans_id
                 from payment
                where id = in_payment_id);

  INSERT INTO payment (reference, trans_id, payment_class, account_id,
                       payment_date, closed, entity_credit_id,
                       employee_id, currency, reversing, notes)
    SELECT reference, currval('transactions_id_seq'), payment_class, account_id,
           in_payment_date, closed, entity_credit_id,
           person__get_my_id(), currency, in_payment_id,
           'This payment reverses ' || in_payment_id
      FROM payment
     WHERE id = in_payment_id
  RETURNING id INTO t_payment_id;

  IF in_batch_id IS NOT NULL THEN
    INSERT INTO voucher (trans_id, batch_id, batch_class)
    VALUES (
      currval('transactions_id_seq'),
      in_batch_id,
      (select case when payment_class = 1 then 4 else 7 end
         from payment
        where id = in_payment_id)
    );
  END IF;

  INSERT INTO acc_trans (trans_id, chart_id, transdate, source,
                         cleared, memo, invoice_id, approved,
                         amount_bc, amount_tc, curr,
                         voucher_id, open_item_id)
  SELECT currval('transactions_id_seq'), chart_id, in_payment_date, source,
         false, memo, null, coalesce(in_approved, true),
         -1 * amount_bc, -1 * amount_tc, curr,
         (select id from voucher v
           where currval('transactions_id_seq') = v.trans_id
             and v.batch_id = in_batch_id) as voucher_id,
         open_item_id
    FROM acc_trans a
   WHERE trans_id = (select trans_id
                       from payment
                      where id = in_payment_id);

  RETURN t_payment_id;
END;

$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment__reverse
(in_payment_id int, in_payment_date date, in_approved boolean,
 in_batch_id int) IS $$
Reverses the payment identified by `in_payment_id`, adding the resulting
transactions into `in_batch_id` if that''s not null.

Returns the `id` of the reversal payment generated.
$$;


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

CREATE OR REPLACE FUNCTION payment_gather_header_info(in_account_class int, in_payment_id int)
 RETURNS SETOF payment_header_item AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
   SELECT p.id as payment_id, p.reference as payment_reference, p.payment_date,
          c.legal_name as legal_name, sum(a.amount_bc) as amount, em.first_name,
          em.last_name, p.currency, p.notes
   FROM payment p
   JOIN entity_employee ent_em ON (ent_em.entity_id = p.employee_id)
   JOIN person em ON (ent_em.entity_id = em.entity_id)
   JOIN entity_credit_account eca ON (eca.id = p.entity_credit_id)
   JOIN company c ON   (c.entity_id  = eca.entity_id)
   LEFT JOIN acc_trans a ON (p.account_id = a.chart_id AND p.trans_id = a.trans_id)
   WHERE p.id = $2
   GROUP BY p.id, c.legal_name, em.first_name, em.last_name;
$sql$
USING in_account_class, in_payment_id;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_gather_header_info(int,int) IS
$$ This function finds a payment based on the id and retrieves the record,
it is usefull for printing payments :) $$;

DROP TYPE IF EXISTS payment_line_item CASCADE;
CREATE TYPE payment_line_item AS (
  payment_id int,
  entry_id int,
  trans_id int,
  invoice_number text,
  chart_id int,
  chart_accno text,
  chart_description text,
  amount numeric,
  trans_date date,
  source text,
  cleared bool,
  memo text,
  invoice_id int,
  approved bool
);

CREATE OR REPLACE FUNCTION payment_gather_line_info(in_account_class int, in_payment_id int)
 RETURNS SETOF payment_line_item AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
     SELECT pl.payment_id, ac.entry_id, ac.trans_id, a.invnumber as invoice_number,
     ac.chart_id, ch.accno as chart_accno, ch.description as chart_description,
     ac.amount_bc, ac.transdate as trans_date, ac.source, ac.cleared,
     ac.memo, ac.invoice_id, ac.approved
     FROM acc_trans ac
     JOIN payment p ON p.trans_id = ac.trans_id
     JOIN account ch ON (ch.id = ac.chart_id)
     LEFT JOIN (SELECT trans_id,invnumber
                 FROM ar WHERE $1 = 2
                 UNION
                 SELECT trans_id,invnumber
                 FROM ap WHERE $1 = 1
                ) a ON (ac.trans_id = a.trans_id)
     WHERE p.id = $2
$sql$
USING in_account_class, in_payment_id;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_gather_line_info(int,int) IS
$$ This function finds a payment based on the id and retrieves all the line records,
it is usefull for printing payments and build reports $$;

-- We will use a view to handle all the overpayments

DROP VIEW IF EXISTS overpayments CASCADE;
CREATE VIEW overpayments AS
  WITH opening_transactions AS (
    SELECT open_item_id, trans_id, amount_bc, amount_tc, curr
      FROM (
        SELECT open_item_id, trans_id, amount_bc, amount_tc, curr,
               (row_number() over (partition by open_item_id)) = 1 as opening
          FROM acc_trans
         WHERE open_item_id is not null
      ) x
     WHERE opening
  ),
  open_item_openings AS (
    SELECT otxn.open_item_id, otxn.amount_bc, otxn.amount_tc, otxn.curr, txn.transdate
      FROM transactions txn
             JOIN opening_transactions otxn
                 ON txn.id = otxn.trans_id
  )
  SELECT op.id as overpayment_id, oi.item_number as payment_reference,
         eca.entity_class as payment_class, oio.transdate as payment_date,
         oio.amount_bc as opening_balance_bc, oio.amount_tc as opening_balance_tc,
         oio.curr as curr, oi.account_id, c.accno, c.description as chart_description,
         sum(ac.amount_bc) * CASE WHEN eca.entity_class = 1 THEN -1 ELSE 1 END
           as available, cmp.legal_name,
         eca.id as entity_credit_id, eca.entity_id, eca.discount, eca.meta_number
    FROM overpayment op
           JOIN open_item oi
               ON op.open_item_id = oi.id
           JOIN open_item_openings oio
               ON oi.id = oio.open_item_id
           JOIN acc_trans ac
               ON ac.open_item_id = oi.id
           JOIN account c
               ON oi.account_id = c.id
           JOIN entity_credit_account eca
               ON eca.id = op.eca_id
           JOIN company cmp
               ON cmp.entity_id = eca.entity_id
   GROUP BY op.id, oi.item_number, eca.entity_class, oio.transdate,
            oio.amount_bc, oio.amount_tc, oio.curr,
            oi.account_id, c.accno, chart_description, legal_name, eca.id,
            eca.entity_id, eca.discount, eca.meta_number;

CREATE OR REPLACE FUNCTION payment_get_open_overpayment_entities(in_account_class int)
 returns SETOF payment_vc_info AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
  SELECT DISTINCT entity_credit_id, legal_name, ec.entity_class, null::int, o.meta_number
    FROM overpayments o
    JOIN entity e ON e.id = o.entity_id
    JOIN entity_credit_account ec ON o.entity_credit_id = ec.id
   WHERE available <> 0 AND $1 = payment_class
$sql$
USING in_account_class;
END
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION payment_get_unused_overpayment(
in_account_class int, in_entity_credit_id int, in_chart_id int)
returns SETOF overpayments AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
              SELECT DISTINCT *
              FROM overpayments
              WHERE payment_class  = $1
              AND entity_credit_id = $2
              AND available <> 0
              AND ($3 IS NULL OR chart_id = $3 )
              ORDER BY payment_date
$sql$
USING in_account_class, in_entity_credit_id, in_chart_id;
END
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
BEGIN
RETURN QUERY EXECUTE $sql$
              SELECT account_id, accno, chart_description, available
              FROM overpayments
              WHERE payment_class  = $1
              AND entity_credit_id = $2
              AND available <> 0;
$sql$
USING in_account_class, in_entity_credit_id;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION payment_get_unused_overpayment(
in_account_class int, in_entity_credit_id int, in_chart_id int) IS
$$ Returns a list of available overpayments$$;


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
SELECT o.overpayment_id, e.name, o.available, o.payment_date,
       opening_balance_bc * CASE WHEN c.category in ('A', 'E') THEN -1 ELSE 1 END as amount
  FROM overpayments o
  JOIN account c ON c.id = o.account_id
  JOIN entity_credit_account eca ON eca.id = o.entity_credit_id
  JOIN entity e ON eca.entity_id = e.id
 WHERE ($1 IS NULL OR $1 <= o.payment_date) AND
       ($2 IS NULL OR $2 >= o.payment_date) AND
       ($3 IS NULL OR $3 = e.control_code) AND
       ($4 IS NULL OR $4 = eca.meta_number) AND
       ($5 IS NULL OR e.name @@ plainto_tsquery($5));
$$;


CREATE OR REPLACE FUNCTION overpayment__reverse
(in_id int, in_transdate date, in_batch_id int, in_account_class int)
returns bool LANGUAGE PLPGSQL AS
$$
declare
  t_id int;
  t_curr_data record;
  in_cash_accno text;
BEGIN

  PERFORM * FROM payment__overpayments_list(null, null, null, null, null)
    WHERE available <> amount
          AND payment_id = in_id;
  IF FOUND THEN
    RAISE 'Cannot reverse used overpayment: reverse payments first';
  END IF;

SELECT *
  INTO t_curr_data
  FROM payment p
         JOIN transactions txn
             ON p.trans_id = txn.id
 WHERE p.id = in_id;

  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;

  -- reverse overpayment gl

  INSERT INTO transactions (transdate, reference,
              description, approved,
              trans_type_code, table_name)
  SELECT transdate, reference || '-reversal',
         'reversal of ' || description, false, 'op', 'payment'
    FROM transactions WHERE id = t_curr_data.trans_id;

  t_id := currval('transactions_id_seq');


  -- reverse payment record

  INSERT INTO payment (reference, trans_id, payment_class, payment_date,
              closed, entity_credit_id, employee_id, currency, reversing)
  VALUES (t_curr_data.reference, t_id, t_curr_data.payment_class,
         t_curr_data.payment_date, t_curr_data.closed,
         t_curr_data.entity_credit_id, person__get_my_id(),
         t_curr_data.currency, t_curr_data.id);


INSERT INTO voucher (batch_id, trans_id, batch_class)
VALUES (in_batch_id, t_id, CASE WHEN in_account_class = 1 THEN 4 ELSE 7 END);

INSERT INTO acc_trans (transdate, trans_id, chart_id,
                       amount_bc, curr, amount_tc)
SELECT in_transdate, t_id, chart_id, amount_bc * -1, curr, amount_tc * -1
  FROM acc_trans
 WHERE trans_id = in_id;


-- reverse overpayment usage
--
-- The query below should automatically do what the above simply bails out on.
-- However, it doesn't work.
-- PERFORM payment__reverse(ac.source, ac.transdate, eca.id, at.accno,
--         in_transdate, eca.entity_class, in_batch_id, null,
--         in_exchangerate, in_curr)
--   FROM acc_trans ac
--   JOIN account at ON ac.chart_id = at.id
--   JOIN account_link al ON at.id = al.account_id AND al.description like 'A%paid'
--   JOIN (select id, entity_credit_account FROM ar UNION
--         select id, entity_credit_account from ap) a ON a.id = ac.trans_id
--   JOIN entity_credit_account eca ON a.entity_credit_account = eca.id
--   JOIN payment_links pl ON pl.entry_id = ac.entry_id
--   JOIN overpayments op ON op.payment_id = pl.payment_id
--   JOIN payment p ON p.id = op.payment_id
--  WHERE p.trans_id = in_id
-- GROUP BY ac.source, ac.transdate, eca.id, eca.entity_class,
--          at.accno, al.description;

RETURN TRUE;
END;
$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
