BEGIN;

DROP TYPE IF EXISTS purchase_info CASCADE;

CREATE TYPE purchase_info AS (
    id int,
    invnumber text,
    ordnumber text,
    ponumber text,
    transdate date,
    entity_name text,
    meta_number text,
    entity_id int,
    amount numeric,
    amount_paid numeric,
    tax numeric,
    currency char(3),
    date_paid date,
    due_date date,
    notes text,
    shipping_point text,
    ship_via text,
    business_units text[]
);

CREATE OR REPLACE FUNCTION ar_ap__transaction_search
(in_account_id int, in_name_part text, in_meta_number text, in_invnumber text,
 in_ordnumber text, in_ponumber text, in_source text, in_description text,
 in_notes text, in_shipvia text, in_from_date date, in_to_date date, 
 in_on_hold bool, in_inc_open bool, in_inc_closed bool, in_as_of date, 
 in_entity_class int)
RETURNS SETOF purchase_info AS
$$
BEGIN
RETURN QUERY
   SELECT gl.id, gl.invnumber, gl.ordnumber, gl.ponumber, gl.transdate, 
          e.name, eca.meta_number::text, e.id, gl.amount, 
          gl.amount - sum(CASE WHEN l.description IN ('AR', 'AP')
                               THEN ac.amount ELSE 0 
                           END),
          gl.amount - gl.netamount, gl.curr, gl.datepaid, gl.duedate, 
          gl.notes, gl.shippingpoint, gl.shipvia, 
          compound_array(bua.business_units || bui.business_units)
     FROM (select id, invnumber, ordnumber, ponumber, transdate, duedate,
                  description, notes, shipvia, shippingpoint, amount, 
                  netamount, curr, datepaid, entity_credit_account, on_hold
             FROM ar WHERE in_entity_class = 2
            UNION
           select id, invnumber, ordnumber, ponumber, transdate, duedate,
                  description, notes, shipvia, shippingpoint, amount, 
                  netamount, curr, datepaid, entity_credit_account, on_hold
             FROM ap WHERE in_entity_class = 1) gl
     JOIN entity_credit_account eca ON gl.entity_credit_account = eca.id
     JOIN entity e ON e.id = eca.entity_id
     JOIN acc_trans ac ON gl.id = ac.trans_id
     JOIN account act ON act.id = ac.chart_id
LEFT JOIN account_link l ON l.account_id = act.id 
                          AND l.description IN ('AR', 'AP')
LEFT JOIN invoice inv ON gl.id = inv.trans_id
LEFT JOIN (SELECT compound_array(ARRAY[ARRAY[buc.label, bu.control_code]])
                  as business_units, entry_id
             FROM business_unit_class buc
             JOIN business_unit bu ON bu.class_id = buc.id
             JOIN business_unit_ac buac ON buac.bu_id = bu.id
         GROUP BY buac.entry_id) bua 
                                 ON bua.entry_id = ac.entry_id
LEFT JOIN (SELECT compound_array(ARRAY[ARRAY[buc.label, bu.control_code]])
                  as business_units, entry_id
             FROM business_unit_class buc
             JOIN business_unit bu ON bu.class_id = buc.id
             JOIN business_unit_inv buinv ON buinv.bu_id = bu.id
         GROUP BY buinv.entry_id) bui
                                 ON bui.entry_id = inv.id
    WHERE (in_account_id IS NULL OR ac.chart_id = in_account_id)
          AND (in_name_part IS NULL
                OR to_tsvector(get_default_lang()::name, e.name) 
                   @@ plainto_tsquery(get_default_lang()::name, in_name_part))
          AND (in_meta_number IS NULL
                OR eca.meta_number LIKE in_meta_number || '%')
          AND (in_invnumber IS NULL or gl.invnumber LIKE in_invnumber || '%')
          AND (in_ordnumber IS NULL or gl.ordnumber LIKE in_ordnumber || '%')
          AND (in_ponumber IS NULL or gl.ponumber LIKE in_ponumber || '%')
          AND (in_description IS NULL 
                or to_tsvector(get_default_lang()::name, gl.description) 
                  @@ plainto_tsquery(get_default_lang()::name, in_description))
          AND (in_notes IS NULL OR 
                to_tsvector(get_default_lang()::name, gl.notes) 
                 @@ plainto_tsquery(get_default_lang()::name, in_notes))
          AND (in_from_date IS NULL OR in_from_date <= gl.transdate)
          AND (in_to_date IS NULL OR in_to_date >= gl.transdate)
          AND (in_on_hold IS NULL OR in_on_hold = gl.on_hold)
          AND (in_as_of IS NULL OR in_as_of >= ac.transdate)
 GROUP BY gl.id, gl.invnumber, gl.ordnumber, gl.ponumber, gl.transdate,
          gl.duedate, e.name, eca.meta_number, gl.amount,
          gl.netamount, gl.curr, gl.datepaid, gl.duedate,
          gl.notes, gl.shippingpoint, gl.shipvia, e.id
   HAVING in_source = ANY(array_agg(ac.source));
END;
$$ LANGUAGE PLPGSQL;
CREATE OR REPLACE FUNCTION ar_ap__transaction_search_summary
(in_account_id int, in_name_part text, in_meta_number text, in_invnumber text,
 in_ordnumber text, in_ponumber text, in_source text, in_description text,
 in_notes text, in_shipvia text, in_from_date date, in_to_date date, 
 in_on_hold bool, in_inc_open bool, in_inc_closed bool, in_as_of date, 
 in_entity_class int)
RETURNS SETOF purchase_info AS
$$
BEGIN
   RETURN QUERY
       SELECT null::int, null::text, null::text, null::text, null::date
              entity_name, meta_number, entity_id, sum(amount), 
              sum(amount_paid), sum(tax), currency, null::date, null::date,
              tull::text, null::text, null::text, null::text[]
         FROM ar_ap__transaction_search
              (in_account_id, in_name_part, in_meta_number, in_invnumber,
              in_ordnumber, in_ponumber, in_source, in_description,
              in_notes, in_shipvia, in_from_date, in_to_date,
              in_on_hold, in_inc_open, in_inc_closed, in_as_of,  
              in_entity_class)
     GROUP BY entity_name, meta_number, entity_id;
END;
$$ language plpgsql;


COMMIT;
