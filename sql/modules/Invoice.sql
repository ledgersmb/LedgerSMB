BEGIN;
CREATE OR REPLACE FUNCTION invoice__start_ap
(in_invnumber text, in_transdate date, in_taxincluded bool,
 in_amount numeric, in_netamount numeric, in_paid numeric, in_datepaid date,
 in_duedate date, in_invoice bool, in_curr char(3), person_id int,
 in_till varchar(20), in_department_id int, in_approved bool,
 in_entity_credit_account int, in_ar_accno text)
RETURNS int LANGUAGE SQL AS
$$
 INSERT INTO ap
        (invnumber, transdate, taxincluded,
         amount, netamount, paid, datepaid,
         duedate, invoice, curr, person_id,
         till, department_id, approved, entity_credit_account)
 VALUES ($1, $2, coalesce($3, 'f'),
         $4,$5, $6, coalesce($7, 'today'),
         coalesce($8, 'today'), $9, coalesce($10,
         (select defaults_get_defaultcurrency from
          defaults_get_defaultcurrency())),
         coalesce($11, person__get_my_entity_id()),
         $12, $13, coalesce($14, true), $15);

 INSERT INTO acc_trans
        (trans_id, transdate, chart_id, amount, approved)
 SELECT currval('id')::int, $2, a.id, $4, true
   FROM account a WHERE accno = $16;

 SELECT currval('id')::int;
$$;

CREATE OR REPLACE FUNCTION invoice__start_ar
(in_invnumber text, in_transdate date, in_taxincluded bool,
 in_amount numeric, in_netamount numeric, in_paid numeric, in_datepaid date,
 in_duedate date, in_invoice bool, in_curr char(3), person_id int,
 in_till varchar(20), in_department_id int, in_approved bool,
 in_entity_credit_account int, in_ar_accno text)
RETURNS int LANGUAGE SQL AS
$$
 INSERT INTO ar
        (invnumber, transdate, taxincluded,
         amount, netamount, paid, datepaid,
         duedate, invoice, curr, person_id,
         till, department_id, approved, entity_credit_account)
 VALUES ($1, $2, coalesce($3, 'f'),
         $4,$5, $6, coalesce($7, 'today'),
         coalesce($8, 'today'), $9, coalesce($10,
         (select defaults_get_defaultcurrency from
          defaults_get_defaultcurrency())),
         coalesce($11, person__get_my_entity_id()),
         $12, $13, coalesce($14, true), $15);

 INSERT INTO acc_trans
        (trans_id, transdate, chart_id, amount, approved)
 SELECT currval('id')::int, $2, a.id, $4 * -1, true
   FROM account a WHERE accno = $16;

 SELECT currval('id')::int;
$$;

COMMENT ON FUNCTION invoice__start_ar
(in_invnumber text, in_transdate date, in_taxincluded bool,
 in_amount numeric, in_netamount numeric, in_paid numeric, in_datepaid date,
 in_duedate date, in_invoice bool, in_curr char(3), person_id int,
 in_till varchar(20), in_department_id int, in_approved bool,
 in_entity_credit_account int, in_ar_accno text)
IS $$ Saves an ar transaction header.  The following fields are optional:

1.  in_tax_included, defaults to false

2.  in_datepaid, defaults to 'today'

3.  in_duedate defaults to 'today',

4.  in_person_id defaults to the entity id of the current user.

5.  in_curr defaults to the default currency.

All other fields are mandatory.

Returns true on success, raises exception on failure.

$$;


CREATE OR REPLACE FUNCTION invoice__add_item_ap
(in_id int, in_parts_id int, in_qty numeric, in_discount numeric,
 in_unit text, in_sellprice numeric)
RETURNS BOOL LANGUAGE SQL AS
$$
INSERT INTO invoice(trans_id, parts_id, qty, discount, unit, allocated, sellprice)
SELECT $1, p.id, $3 * -1, $4, coalesce($5, p.unit), 0, $6
  FROM parts p WHERE id = $2;

SELECT TRUE;
$$;

CREATE OR REPLACE FUNCTION invoice__add_item_ar
(in_id int, in_parts_id int, in_qty numeric, in_discount numeric,
 in_unit text, in_sellprice numeric)
RETURNS BOOL LANGUAGE SQL AS
$$
INSERT INTO invoice(trans_id, parts_id, qty, discount, unit, allocated, sellprice)
SELECT $1, p.id, $3, $4, coalesce($5, p.unit), 0, $6
  FROM parts p WHERE id = $2;

SELECT TRUE;
$$;

COMMENT ON FUNCTION invoice__add_item_ar
(in_id int, in_parts_id int, in_qty numeric, in_discount numeric,
 in_unit text, in_sellprice numeric)
IS $$This adds an item to the invoice.  This is not safe to use alone.  If you
use it, you MUST also use invoice__finalize_ar.  In particular this function does
not add income, inventory, or COGS calculations. $$;

CREATE OR REPLACE FUNCTION invoice__add_payment_ar
(in_id int, in_ar_accno text, in_cash_accno text, in_transdate date,
in_source text, in_memo text, in_amount numeric)
RETURNS BOOL LANGUAGE SQL AS
$$
INSERT INTO acc_trans (trans_id, chart_id, transdate, source, memo, amount,
                       approved)
VALUES ($1, (select id from account where accno = $2), coalesce($4, 'today'), $5,
        $6, $7, true),
       ($1, (select id from account where accno = $3), coalesce($4, 'today'), $5,
        $6, $7 * -1, true);

SELECT TRUE;
$$;

CREATE OR REPLACE FUNCTION invoice__add_payment_ap
(in_id int, in_ap_accno text, in_cash_accno text, in_transdate date,
in_source text, in_memo text, in_amount numeric)
RETURNS BOOL LANGUAGE SQL AS
$$
INSERT INTO acc_trans (trans_id, chart_id, transdate, source, memo, amount,
                       approved)
VALUES ($1, (select id from account where accno = $2), coalesce($4, 'today'), $5,
        $6, $7 * -1, true),
       ($1, (select id from account where accno = $3), coalesce($4, 'today'), $5,
        $6, $7, true);

SELECT TRUE;
$$;

CREATE OR REPLACE FUNCTION invoice__finalize_ap(in_id int)
returns bool language plpgsql as
$$
BEGIN
   -- inventory
   INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, approved,
                         invoice_id)
   SELECT in_id, p.income_accno_id, a.transdate, i.qty * i.sellprice * -1, true, i.id
     FROM parts p
     JOIN invoice i ON i.parts_id = p.id
     JOIN ap a ON i.trans_id = a.id AND a.id = in_id;

   -- transaction should now be balanced if this was done with invoice__begin_ap
   -- add cogs
   PERFORM cogs__add_for_ap(parts_id, qty, sellprice)
      FROM invoice WHERE trans_id = in_id;

   -- check if transaction is balanced, else raise exception
   PERFORM trans_id FROM acc_trans
     WHERE trans_id = in_id
  GROUP BY trans_id
    HAVING sum(amount) <> 0;

   IF FOUND THEN
      RAISE EXCEPTION 'Out of balance';
   END IF;

   RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION invoice__finalize_ar(in_id int)
returns bool language plpgsql as
$$
DECLARE balance numeric;
BEGIN
   -- income
   INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, approved,
                         invoice_id)
   SELECT in_id, p.income_accno_id, a.transdate, i.qty * i.sellprice , true, i.id
     FROM parts p
     JOIN invoice i ON i.parts_id = p.id
     JOIN ar a ON i.trans_id = a.id AND a.id = in_id;

   -- transaction should now be balanced if this was done with invoice__begin_ar
   -- add cogs
   PERFORM cogs__add_for_ar(parts_id, qty)
      FROM invoice WHERE trans_id = in_id;

   -- check if transaction is balanced, else raise exception
   SELECT sum(amount) INTO balance FROM acc_trans
     WHERE trans_id = in_id
    HAVING sum(amount) <> 0;

   IF FOUND THEN
      RAISE WARNING 'Balance: %', balance;
      RAISE EXCEPTION 'Out of balance';
   END IF;

   RETURN TRUE;
END;
$$;

COMMIT;
