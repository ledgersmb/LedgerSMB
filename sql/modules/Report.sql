
set client_min_messages = 'warning';


-- Unused currently and untested.  This is expected to be a basis for 1.4 work
-- not recommended for current usage.  Not documenting yet.  --CT
BEGIN;

DROP TYPE IF EXISTS incoming_lot_cogs_line CASCADE;

CREATE TYPE incoming_lot_cogs_line AS (
       id int,
       trans_id int,
       invnumber text,
       transdate date,
       parts_id int,
       partnumber text,
       description text,
       qty numeric,
       allocated numeric,
       onhand numeric,
       sellprice numeric,
       total_value numeric,
       cogs_sold numeric
);

CREATE OR REPLACE FUNCTION report__incoming_cogs_line
(in_date_from date, in_date_to date, in_partnumber text,
in_parts_description text)
RETURNS SETOF incoming_lot_cogs_line AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
SELECT i.id, a.id, a.invnumber, a.transdate, i.parts_id, p.partnumber,
       i.description, i.qty * -1, i.allocated, p.onhand,
       i.sellprice, i.qty * i.sellprice * -1, i.allocated * i.sellprice
  FROM ap a
  JOIN invoice i ON a.id = i.trans_id
  JOIN parts p ON i.parts_id = p.id
 WHERE p.income_accno_id IS NOT NULL AND p.expense_accno_id IS NOT NULL
       AND (a.transdate >= $1 OR $1 IS NULL)
       AND (a.transdate <= $2 OR $2 IS NULL)
       AND (p.partnumber like $3 || '%' OR $3 IS NULL)
       AND (p.description @@ plainto_tsquery($4)
            OR p.description LIKE '%' || $4 || '%'
            OR $4 IS NULL)
 ORDER BY p.partnumber, a.invnumber
$sql$
USING in_date_from, in_date_to, in_partnumber, in_parts_description;
END
$$ LANGUAGE PLPGSQL;


DROP TYPE IF EXISTS report_aging_item CASCADE;
CREATE TYPE report_aging_item AS (
        entity_id int,
        account_number text,
        name text,
        contact_name text,
        "language" text,
        invnumber text,
        transdate date,
        ordnumber text,
        ponumber text,
        notes text,
        c0 numeric,
        c30 numeric,
        c60 numeric,
        c90 numeric,
        c0_tc numeric,
        c30_tc numeric,
        c60_tc numeric,
        c90_tc numeric,
        duedate date,
        id int,
        curr char(3),
        exchangerate numeric,
        line_items text[][],
        age int
);

DROP FUNCTION IF EXISTS report__invoice_aging_detail
(in_entity_id int, in_entity_class int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool);

DROP FUNCTION IF EXISTS report__invoice_aging_detail
(in_entity_id int, in_entity_class int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool, in_name_part text);

CREATE OR REPLACE FUNCTION report__invoice_aging_detail
(in_entity_id int, in_entity_class int, in_credit_id int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool, in_name_part text)
RETURNS SETOF report_aging_item AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
     WITH RECURSIVE bu_tree (id, path) AS (
                SELECT id, ARRAY[id]::int[] AS path
                  FROM business_unit
                 WHERE id = any($6)
                       OR $6 IS NULL
                 UNION
                SELECT bu.id, array_append(bu_tree.path, bu.id)
                  FROM business_unit bu
                  JOIN bu_tree ON bu_tree.id = bu.parent_id
                       )
                SELECT c.entity_id, c.meta_number::text, e.name,
                       e.name as contact_name, c.language_code::text as "language",
                       a.invnumber, a.transdate, a.ordnumber,
                       a.ponumber, a.notes,
                       CASE WHEN a.age/30 = 0
                                 THEN (a.sign * sum(ac.amount_bc))
                            ELSE 0 END
                            as c0,
                       CASE WHEN a.age/30 = 1
                                 THEN (a.sign * sum(ac.amount_bc))
                            ELSE 0 END
                            as c30,
                       CASE WHEN a.age/30 = 2
                            THEN (a.sign * sum(ac.amount_bc))
                            ELSE 0 END
                            as c60,
                       CASE WHEN a.age/30 > 2
                            THEN (a.sign * sum(ac.amount_bc))
                            ELSE 0 END
                            as c90,
                       CASE WHEN a.age/30 = 0
                                 THEN (a.sign * sum(ac.amount_tc))
                            ELSE 0 END
                            as c0_tc,
                       CASE WHEN a.age/30 = 1
                                 THEN (a.sign * sum(ac.amount_tc))
                            ELSE 0 END
                            as c30_tc,
                       CASE WHEN a.age/30 = 2
                            THEN (a.sign * sum(ac.amount_tc))
                            ELSE 0 END
                            as c60_tc,
                       CASE WHEN a.age/30 > 2
                            THEN (a.sign * sum(ac.amount_tc))
                            ELSE 0 END
                            as c90_tc,
                       a.duedate, a.id, a.curr,
                       null::numeric AS exchangerate,
                        (SELECT array_agg(ARRAY[p.partnumber,
                                        i.description, i.qty::text])
                                FROM parts p
                                JOIN invoice i ON (i.parts_id = p.id)
                                WHERE i.trans_id = a.id) AS line_items,
                   (coalesce($5, now())::date - a.transdate) as age
                  FROM (select id, invnumber, ordnumber, amount_bc, duedate,
                               curr, ponumber, notes, entity_credit_account,
                               -1 AS sign, transdate, force_closed,
                               CASE WHEN $7
                                    THEN coalesce($5, now())::date
                                         - duedate
                                    ELSE coalesce($5, now())::date
                                         - transdate
                               END as age
                          FROM ar
                         WHERE $2 = 2
                         UNION
                        SELECT id, invnumber, ordnumber, amount_bc, duedate,
                               curr, ponumber, notes, entity_credit_account,
                               1 as sign, transdate, force_closed,
                               CASE WHEN $7
                                    THEN coalesce($5, now())::date
                                         - duedate
                                    ELSE coalesce($5, now())::date
                                         - transdate
                               END as age
                          FROM ap
                         WHERE $2 = 1) a
                  JOIN acc_trans ac ON ac.trans_id = a.id
                  JOIN account acc ON ac.chart_id = acc.id
                  JOIN account_link acl ON acl.account_id = acc.id
                       AND (($2 = 1
                              AND acl.description = 'AP')
                           OR ($2 = 2
                              AND acl.description = 'AR'))
                  JOIN entity_credit_account c
                       ON a.entity_credit_account = c.id
                  JOIN entity e ON (e.id = c.entity_id)
             LEFT JOIN business_unit_ac buac ON ac.entry_id = buac.entry_id
             LEFT JOIN bu_tree ON buac.bu_id = bu_tree.id
             LEFT JOIN entity_to_location e2l
                       ON e.id = e2l.entity_id
                       AND e2l.location_class = 3
             LEFT JOIN location l ON l.id = e2l.location_id
             LEFT JOIN country ON (country.id = l.country_id)
                 WHERE (e.id = $1 OR $1 IS NULL)
                       AND ($3 IS NULL or c.id = $3)
                       AND ($4 IS NULL or acc.accno = $4)
                       AND a.force_closed IS NOT TRUE
                       AND ($8 IS NULL
                            OR e.name like '%' || $8 || '%')
              GROUP BY c.entity_id, c.meta_number, e.name, c.language_code,
                       l.line_one, l.line_two, l.line_three,
                       l.city, l.state, l.mail_code, country.name,
                       a.invnumber, a.transdate, a.ordnumber,
                       a.ponumber, a.notes, a.amount_bc, a.sign,
                       a.duedate, a.id, a.curr, a.age
                HAVING ($6 is null
                        or $6 <@ compound_array(bu_tree.path))
                       AND sum(ac.amount_bc::numeric(20,2)) <> 0
              ORDER BY entity_id, meta_number, curr, transdate, invnumber
$sql$
USING in_entity_id, in_entity_class, in_credit_id, in_accno, in_to_date,
 in_business_units, in_use_duedate, in_name_part;
END
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS report__invoice_aging_summary
(in_entity_id int, in_entity_class int, in_credit_id int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool);

DROP FUNCTION IF EXISTS report__invoice_aging_summary
(in_entity_id int, in_entity_class int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool, in_name_part text);

CREATE OR REPLACE FUNCTION report__invoice_aging_summary
(in_entity_id int, in_entity_class int, in_credit_id int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool, in_name_part text)
RETURNS SETOF report_aging_item AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
SELECT entity_id, account_number, name, contact_name, "language",
       null::text, null::date,
       null::text, null::text, null::text,
       sum(c0), sum(c30), sum(c60), sum(c90),
       sum(c0_tc), sum(c30_tc), sum(c60_tc), sum(c90_tc),
       null::date, null::int, curr,
       null::numeric, null::text[], null::int
  FROM report__invoice_aging_detail($1, $2, $3, $4, $5, $6, $7, $8)
 GROUP BY entity_id, account_number, name, contact_name, "language", curr
 ORDER BY account_number
$sql$
USING in_entity_id, in_entity_class, in_credit_id, in_accno, in_to_date,
 in_business_units, in_use_duedate, in_name_part;
END
$$ LANGUAGE PLPGSQL;


DROP TYPE IF EXISTS gl_report_item CASCADE;

CREATE TYPE gl_report_item AS (
    id int,
    type text,
    invoice bool,
    reference text,
    eca_name text,
    description text,
    transdate date,
    source text,
    amount numeric,
    curr text,
    amount_tc numeric,
    accno text,
    gifi_accno text,
    cleared bool,
    memo text,
    accname text,
    chart_id int,
    entry_id int,
    running_balance numeric,
    business_units int[]
);

DROP FUNCTION IF EXISTS report__gl
(in_reference text, in_accno text, in_category char(1),
in_source text, in_memo text,  in_description text, in_from_date date,
in_to_date date, in_approved bool, in_from_amount numeric, in_to_amount numeric,
in_business_units int[]);

CREATE OR REPLACE FUNCTION report__gl
(in_reference text, in_accno text, in_category char(1),
in_source text, in_memo text,  in_description text, in_from_date date,
in_to_date date, in_approved bool, in_voided bool, in_from_amount numeric, in_to_amount numeric,
in_business_units int[])
RETURNS SETOF gl_report_item STABLE AS
$$
DECLARE
         retval gl_report_item;
         t_balance numeric;
         t_chart_id int;
BEGIN

IF in_from_date IS NULL THEN
   t_balance := 0;
ELSIF in_accno IS NOT NULL THEN
   SELECT id INTO t_chart_id FROM account WHERE accno  = in_accno;
   t_balance :=
      account__obtain_balance((in_from_date - '1 day'::interval)::date,
                                       (select id from account
                                         where accno = in_accno));
ELSE
   t_balance := null;
END IF;

FOR retval IN
       WITH RECURSIVE bu_tree (id, path) AS (
            SELECT id, ARRAY[id]::int[] AS path
              FROM business_unit
             WHERE parent_id is null
            UNION
            SELECT bu.id, array_append(bu_tree.path, bu.id)
              FROM business_unit bu
              JOIN bu_tree ON bu_tree.id = bu.parent_id
            )
       SELECT g.id, g.type, g.invoice, g.reference, g.eca_name, g.description, ac.transdate,
              ac.source, ac.amount_bc, ac.curr, ac.amount_tc, c.accno, c.gifi_accno,
              ac.cleared, ac.memo, c.description AS accname,
              ac.chart_id, ac.entry_id,
              sum(ac.amount_bc) over (order by ac.transdate, ac.trans_id,
                                            c.accno, ac.entry_id)
                + t_balance
                as running_balance,
              array_agg(ARRAY[bac.class_id, bac.bu_id])
         FROM (select txn.id, trans_type_code as type,
                      coalesce(ar.invoice, ap.invoice, false) as invoice,
                      coalesce(ar.invnumber, ap.invnumber, reference) as reference,
                      coalesce(ar.entity_name, ap.entity_name, null::text) as eca_name,
                      description, txn.approved
                 FROM transactions txn
                        LEFT JOIN (select ar.*, entity.name as entity_name
                                     from ar
                                            join entity_credit_account eca
                                                on ar.entity_credit_account = eca.id
                                            join entity
                                                on eca.entity_id = entity.id) ar
                            ON txn.id = ar.id
                        LEFT JOIN (select ap.*, entity.name as entity_name
                                     from ap
                                            join entity_credit_account eca
                                                on ap.entity_credit_account = eca.id
                                            join entity
                                                on eca.entity_id = entity.id) ap
                            ON txn.id = ap.id) g
           JOIN acc_trans ac ON ac.trans_id = g.id
         JOIN account c ON ac.chart_id = c.id
    LEFT JOIN business_unit_ac bac ON ac.entry_id = bac.entry_id
    LEFT JOIN bu_tree ON bac.bu_id = bu_tree.id
        WHERE (g.reference ilike in_reference || '%' or in_reference is null)
              AND (c.accno = in_accno OR in_accno IS NULL)
              AND (ac.source ilike '%' || in_source || '%'
                   OR in_source is null)
              AND (ac.memo ilike '%' || in_memo || '%' OR in_memo is null)
             AND (in_description IS NULL OR
                  g.description
                  @@
                  plainto_tsquery(get_default_lang()::regconfig, in_description))
              AND (transdate BETWEEN in_from_date AND in_to_date
                   OR (transdate >= in_from_date AND  in_to_date IS NULL)
                   OR (transdate <= in_to_date AND in_from_date IS NULL)
                   OR (in_to_date IS NULL AND in_from_date IS NULL))
              AND (in_approved is null
                   or (in_approved is true
                       and g.approved is true
                       AND ac.approved is true)
                   or (in_approved is false
                       and (g.approved is false
                            or ac.approved is false)))
              AND (in_voided is null
                   or in_voided is not distinct from (exists (select 1
                                                                from transactions t
                                                               where t.approved
                                                                 and t.reversing = g.id)))
              AND (in_from_amount IS NULL
                   OR abs(ac.amount_bc) >= in_from_amount)
              AND (in_to_amount IS NULL
                   OR abs(ac.amount_bc) <= in_to_amount)
              AND (in_category = c.category OR in_category IS NULL)
     GROUP BY g.id, g.type, g.invoice, g.reference, g.eca_name, g.description, ac.transdate,
              ac.source, ac.amount_bc, c.accno, c.gifi_accno,
              ac.cleared, ac.memo, c.description,
              ac.chart_id, ac.entry_id, ac.trans_id
       HAVING in_business_units is null
              or in_business_units <@ compound_array(bu_tree.path)
     ORDER BY ac.transdate, ac.trans_id, c.accno, ac.entry_id
LOOP
   RETURN NEXT retval;
END LOOP;
END;
$$ language plpgsql;


DROP TYPE IF EXISTS cash_summary_item CASCADE;

DROP TYPE IF EXISTS general_balance_line CASCADE;

CREATE TYPE general_balance_line AS (
   account_id int,
   account_accno text,
   account_description text,
   starting_balance numeric,
   debits numeric,
   credits numeric,
   final_balance numeric
);

CREATE OR REPLACE FUNCTION report__general_balance
(in_from_date date, in_to_date date)
RETURNS SETOF general_balance_line AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
SELECT a.id, a.accno, a.description,
      sum(CASE WHEN ac.transdate < $1 THEN abs(amount_bc) ELSE null END),
      sum(CASE WHEN ac.transdate >= $1 AND ac.amount_bc < 0
               THEN ac.amount_bc * -1 ELSE null END),
      SUM(CASE WHEN ac.transdate >= $1 AND ac.amount_bc > 0
               THEN ac.amount_bc ELSE null END),
      SUM(ABS(ac.amount_bc))
 FROM account a
LEFT JOIN acc_trans ac
  ON ac.chart_id = a.id
LEFT JOIN transactions txn
  ON ac.trans_id = txn.id
WHERE txn.approved and ac.approved
      and ac.transdate <= $2
GROUP BY a.id, a.accno, a.description
ORDER BY a.accno
$sql$
USING in_from_date, in_to_date;
END
$$ LANGUAGE PLPGSQL;

DROP TYPE IF EXISTS aa_transactions_line CASCADE;

CREATE TYPE aa_transactions_line AS (
    id int,
    invoice bool,
    entity_id int,
    meta_number text,
    entity_name text,
    transdate date,
    invnumber text,
    ordnumber text,
    ponumber text,
    curr char(3),
    amount numeric,
    netamount numeric,
    tax numeric,
    paid numeric,
    due numeric,
    last_payment date,
    due_date date,
    notes text,
    salesperson text,
    manager text,
    shipping_point text,
    ship_via text,
    business_units text[]
);

CREATE OR REPLACE FUNCTION report__aa_outstanding_details
(in_entity_class int, in_account_id int, in_entity_name text,
 in_meta_number text,
 in_employee_id int, in_business_units int[], in_ship_via text, in_on_hold bool,
 in_from_date date, in_to_date date, in_partnumber text, in_parts_id int)
RETURNS SETOF aa_transactions_line AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$

SELECT a.id, a.invoice, eeca.id, eca.meta_number::text, eeca.name, a.transdate,
       a.invnumber, a.ordnumber, a.ponumber, a.curr, a.amount_bc, a.netamount_bc,
       a.amount_bc - a.netamount_bc as tax,
       a.amount_bc - p.due as paid, p.due, p.last_payment, a.duedate, a.notes,
       ee.name, me.name, a.shippingpoint, a.shipvia,
       '{}'::text[] as business_units -- TODO
  FROM (select txn.id, txn.transdate, invnumber, curr, amount_bc, netamount_bc, duedate,
               notes, person_id, entity_credit_account, invoice,
               shippingpoint, shipvia, ordnumber, ponumber, description,
               on_hold, force_closed
          FROM ar JOIN transactions txn ON ar.id = txn.id
         WHERE $1 = 2 and txn.approved
         UNION
        SELECT txn.id, txn.transdate, invnumber, curr, amount_bc, netamount_bc, duedate,
               notes, person_id, entity_credit_account, invoice,
               shippingpoint, shipvia, ordnumber, ponumber, description,
               on_hold, force_closed
          FROM ap JOIN transactions txn ON ap.id = txn.id
         WHERE $1 = 1 and txn.approved) a
  LEFT
  JOIN (SELECT trans_id, sum(amount_bc) *
               CASE WHEN $1 = 1 THEN 1 ELSE -1 END AS due,
               max(transdate) as last_payment
          FROM acc_trans ac
          JOIN account_link al ON ac.chart_id = al.account_id
         WHERE approved AND al.description IN ('AR', 'AP')
               AND ($10 is null or transdate <= $10)
      GROUP BY trans_id) p ON p.trans_id = a.id
  JOIN entity_credit_account eca ON a.entity_credit_account = eca.id
  JOIN entity eeca ON eca.entity_id = eeca.id
  LEFT
  JOIN entity_employee ON entity_employee.entity_id = a.person_id
  LEFT
  JOIN entity ee ON entity_employee.entity_id = ee.id
  LEFT
  JOIN entity me ON entity_employee.manager_id = me.id
 WHERE ($2 IS NULL
          OR EXISTS (select 1 FROM acc_trans
                      WHERE trans_id = a.id and chart_id = $2))
       AND ($3 IS NULL
           OR eeca.name @@ plainto_tsquery($3)
           OR eeca.name ilike '%' || $3 || '%')
       AND ($4 IS NULL
          OR eca.meta_number ilike $4 || '%')
       AND ($5 IS NULL OR ee.id = $5)
       AND ($7 IS NULL
            OR a.shipvia @@ plainto_tsquery($7))
       -- DO NOT filter by transaction date: it's possible
       --   to pay transactions before their creation date.
       --   Those payments *will* end up in the balance sheet
       --   but with the filters below, *won't* appear in the
       --   outstanding report, making it fail to reconcile...
       -- AND ($8 IS NULL OR $8 = a.on_hold)
       -- AND ($9 IS NULL OR a.transdate >= $9)
       AND ($10 IS NULL OR a.transdate <= $10)
       AND p.due::numeric(100,2) <> 0
       AND a.force_closed IS NOT TRUE
       AND ($11 IS NULL
          OR EXISTS(SELECT 1 FROM invoice inv
                      JOIN parts ON inv.parts_id = parts.id
                     WHERE inv.trans_id = a.id))
       AND ($12 IS NULL
          OR EXISTS (select 1 FROM invoice
                      WHERE parts_id = $12 AND trans_id = a.id))
$sql$
USING in_entity_class, in_account_id, in_entity_name, in_meta_number,
 in_employee_id, in_business_units, in_ship_via, in_on_hold,
 in_from_date, in_to_date, in_partnumber, in_parts_id;
END
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION report__aa_outstanding
(in_entity_class int, in_account_id int, in_entity_name text,
 in_meta_number text,
 in_employee_id int, in_business_units int[], in_ship_via text, in_on_hold bool,
 in_from_date date, in_to_date date, in_partnumber text, in_parts_id int)
RETURNS SETOF aa_transactions_line AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$

SELECT null::int as id, null::bool as invoice, entity_id, meta_number::text,
       entity_name, null::date as transdate, count(*)::text as invnumber,
       null::text as ordnumber, null::text as ponumber, curr,
       sum(amount) as amount, sum(netamount) as netamount, sum(tax) as tax,
       sum(paid) as paid, sum(due) as due, max(last_payment) as last_payment,
       null::date as duedate, null::text as notes,
       null::text as salesperson, null::text as manager,
       null::text as shipping_point, null::text as ship_via,
       null::text[] as business_units
  FROM report__aa_outstanding_details($1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
    $11, $12)
 GROUP BY meta_number, entity_name, entity_id, curr
$sql$
USING in_entity_class, in_account_id, in_entity_name, in_meta_number,
 in_employee_id, in_business_units, in_ship_via, in_on_hold,
 in_from_date, in_to_date, in_partnumber, in_parts_id;
END
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS report__aa_transactions
(in_entity_class int, in_account_id int, in_entity_name text,
 in_meta_number text,
 in_employee_id int, in_manager_id int, in_invnumber text, in_ordnumber text,
 in_ponumber text, in_source text, in_description text, in_notes text,
 in_shipvia text, in_from_date date, in_to_date date, in_on_hold bool,
 in_taxable bool, in_tax_account_id int, in_open bool, in_closed bool);
DROP FUNCTION IF EXISTS report__aa_transactions
(in_entity_class int, in_account_id int, in_entity_name text,
 in_meta_number text,
 in_employee_id int, in_manager_id int, in_invnumber text, in_ordnumber text,
 in_ponumber text, in_source text, in_description text, in_notes text,
 in_shipvia text, in_from_date date, in_to_date date, in_on_hold bool,
 in_taxable bool, in_tax_account_id int, in_open bool, in_closed bool,
 in_approved bool);
DROP FUNCTION IF EXISTS report__aa_transactions
(in_entity_class int, in_account_id int, in_entity_name text,
 in_meta_number text,
 in_employee_id int, in_manager_id int, in_invnumber text, in_ordnumber text,
 in_ponumber text, in_source text, in_description text, in_notes text,
 in_shipvia text, in_from_date date, in_to_date date, in_on_hold bool,
 in_taxable bool, in_tax_account_id int, in_open bool, in_closed bool,
 in_approved bool, in_partnumber text);
CREATE OR REPLACE FUNCTION report__aa_transactions
(in_entity_class int, in_account_id int, in_entity_name text,
 in_meta_number text,
 in_employee_id int, in_manager_id int, in_invnumber text, in_ordnumber text,
 in_ponumber text, in_source text, in_description text, in_notes text,
 in_shipvia text, in_from_date date, in_to_date date, in_on_hold bool,
 in_taxable bool, in_tax_account_id int, in_open bool, in_closed bool,
 in_approved bool, in_voided bool, in_partnumber text)
RETURNS SETOF aa_transactions_line AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$

SELECT a.id, a.invoice, eeca.id, eca.meta_number::text, eeca.name,
       a.transdate, a.invnumber, a.ordnumber, a.ponumber, a.curr,
       a.amount_bc as amount, a.netamount_bc as netamount,
       a.amount_bc - a.netamount_bc as tax, a.amount_bc - p.due,
       p.due, p.last_payment,
       a.duedate, a.notes,
       eee.name as employee, mee.name as manager, a.shippingpoint,
       a.shipvia, '{}'::text[]

  FROM (select txn.id, txn.transdate, invnumber, curr, amount_bc, netamount_bc, duedate,
               notes,
               person_id, entity_credit_account, invoice, shippingpoint,
               shipvia, ordnumber, ponumber, description, on_hold, force_closed
          FROM ar JOIN transactions txn ON ar.id = txn.id
         WHERE $1 = 2
               and ($21 is null or ($21 = txn.approved))
         UNION
        SELECT txn.id, txn.transdate, invnumber, curr, amount_bc, netamount_bc, duedate,
               notes,
               person_id, entity_credit_account, invoice, shippingpoint,
               shipvia, ordnumber, ponumber, description, on_hold, force_closed
          FROM ap JOIN transactions txn ON ap.id = txn.id
         WHERE $1 = 1
               and ($21 is null or ($21 = txn.approved))) a
  LEFT
  JOIN (select sum(amount_bc) * case when $1 = 1 THEN 1 ELSE -1 END
               as due, trans_id, max(transdate) as last_payment
          FROM acc_trans ac
          JOIN account_link l ON ac.chart_id = l.account_id
         WHERE l.description IN ('AR', 'AP')
      GROUP BY ac.trans_id
       ) p ON p.trans_id = a.id
  LEFT
  JOIN entity_employee ee ON ee.entity_id = a.person_id
  LEFT
  JOIN entity eee ON eee.id = ee.entity_id
  JOIN entity_credit_account eca ON a.entity_credit_account = eca.id
  JOIN entity eeca ON eca.entity_id = eeca.id
  LEFT
  JOIN entity mee ON ee.manager_id = mee.id
 WHERE ($2 IS NULL OR
       EXISTS (select * from acc_trans
               where trans_id = a.id AND chart_id = $2))
       AND ($3 IS NULL
           OR eeca.name ilike '%' || $3 || '%'
           OR eeca.name @@ plainto_tsquery($3))
       AND ($4 IS NULL OR eca.meta_number ilike $4)
       AND ($5 = ee.entity_id OR $5 IS NULL)
       AND ($6 = mee.id OR $6 IS NULL)
       AND (a.invnumber ilike $7 || '%' OR $7 IS NULL)
       AND (a.ordnumber ilike $8 || '%' OR $8 IS NULL)
       AND (a.ponumber ilike $9 || '%' OR $9 IS NULL)
       AND ($10 IS NULL OR
           EXISTS (
              SELECT * from acc_trans where trans_id = a.id
                     AND source ilike $10 || '%'
           ))
       AND ($11 IS NULL
              OR a.description @@ plainto_tsquery($11))
       AND ($12 IS NULL OR a.notes @@ plainto_tsquery($12))
       AND ($13 IS NULL OR a.shipvia @@ plainto_tsquery($13))
       AND ($14 IS NULL OR a.transdate >= $14)
       AND ($15 IS NULL OR a.transdate <= $15)
       AND ($16 IS NULL OR $16 = a.on_hold)
       AND ($17 IS NULL
            OR ($17
              AND ($18 IS NULL
                 OR EXISTS (SELECT 1 FROM acc_trans
                             WHERE trans_id = a.id
                                   AND chart_id = $18)
            ))
            OR (NOT $17
                  AND NOT EXISTS (SELECT 1
                                    FROM acc_trans ac
                                    JOIN account_link al
                                      ON al.account_id = ac.chart_id
                                   WHERE ac.trans_id = a.id
                                         AND al.description ilike '%tax'))
            )
            AND ( -- open/closed handling
              ($19 IS TRUE AND ( a.force_closed IS NOT TRUE AND
                 abs(p.due) > 0.005))                  -- threshold due to
                                                       -- impossibility to
                                                       -- collect below -CT
               OR ($20 IS TRUE AND ( a.force_closed IS NOT TRUE AND
                 abs(p.due) > 0.005) IS NOT TRUE)
            )
            AND (
              $22 IS NULL
              OR $22 IS NOT DISTINCT FROM (EXISTS (SELECT 1
                                                     FROM transactions t
                                                    WHERE t.approved
                                                      AND t.reversing = a.id))
            )
            AND  -- by partnumber
              ($23 IS NULL
                 OR a.id IN (
                    select i.trans_id
                      FROM invoice i JOIN parts p ON i.parts_id = p.id
                     WHERE p.partnumber = $23))
$sql$
USING in_entity_class, in_account_id, in_entity_name, in_meta_number,
 in_employee_id, in_manager_id, in_invnumber, in_ordnumber,
 in_ponumber, in_source, in_description, in_notes,
 in_shipvia, in_from_date, in_to_date, in_on_hold,
 in_taxable, in_tax_account_id, in_open, in_closed,
 in_approved, in_voided, in_partnumber;
END
$$ LANGUAGE PLPGSQL;


update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
