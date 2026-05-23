
set client_min_messages = 'warning';

BEGIN;

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
              trans_type_code)
  SELECT transdate, reference || '-reversal',
         'reversal of ' || description, false, 'op'
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
