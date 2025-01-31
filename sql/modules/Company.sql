
set client_min_messages = 'warning';



-- Copyright (C) 2011 LedgerSMB Core Team.  Licensed under the GNU General
-- Public License v 2 or at your option any later version.

-- Docstrings already added to this file.

BEGIN;

DROP TYPE IF EXISTS company_entity CASCADE;

CREATE TYPE company_entity AS(
  entity_id int,
  legal_name text,
  tax_id text,
  sales_tax_id text,
  license_number text,
  sic_code varchar,
  control_code text,
  country_id int
);

DROP TYPE IF EXISTS eca__pricematrix CASCADE;

COMMENT ON TYPE company_entity IS
  $$ Return type to query companies, combining data from the 'entity'
  and 'company' tables.
  $$;

CREATE TYPE eca__pricematrix AS (
  parts_id int,
  int_partnumber text,
  description text,
  credit_id int,
  pricebreak numeric,
  sellprice numeric,
  lastcost numeric,
  leadtime int,
  partnumber text,
  validfrom date,
  validto date,
  curr char(3),
  entry_id int,
  qty numeric
);


DROP TYPE IF EXISTS  contact_search_result CASCADE;

CREATE TYPE contact_search_result AS (
        entity_id int,
        entity_control_code text,
        entity_credit_id int,
        meta_number text,
        credit_description text,
        entity_class int,
        name text,
        sic_code text,
        business_type text,
        curr text
);

DROP TYPE IF EXISTS eca_history_result CASCADE;

create type eca_history_result as (
   id int,
   name text,
   meta_number text,
   inv_id int,
   invnumber text,
   curr text,
   parts_id int,
   partnumber text,
   description text,
   qty numeric,
   unit text,
   sellprice numeric,
   discount numeric,
   delivery_date date,
   serialnumber text,
   exchangerate numeric,
   salesperson_id int,
   salesperson_name text,
   transdate date
);

CREATE OR REPLACE FUNCTION eca__get_by_meta_number
(in_meta_number text, in_entity_class int)
RETURNS entity_credit_account AS
$$
DECLARE
  t_retval entity_credit_account;
BEGIN
EXECUTE $sql$
SELECT * FROM entity_credit_account
 WHERE entity_class = $2 AND meta_number = $1
$sql$
INTO t_retval
USING in_meta_number, in_entity_class;
RETURN t_retval;
END
$$ LANGUAGE PLPGSQL;


DROP FUNCTION IF EXISTS eca__history
(in_name text, in_meta_number text, in_contact_info text, in_address_line text,
 in_city text, in_state text, in_zip text, in_salesperson text, in_notes text,
 in_country_id int, in_from_date date, in_to_date date, in_type char(1),
 in_start_from date, in_start_to date, in_entity_class int,
 in_inc_open bool, in_inc_closed bool);


CREATE OR REPLACE FUNCTION eca__history
(in_name_part text, in_meta_number text, in_contact_info text, in_address_line text,
 in_city text, in_state text, in_zip text, in_salesperson text, in_notes text,
 in_country_id int, in_from_date date, in_to_date date, in_type char(1),
 in_start_from date, in_start_to date, in_entity_class int,
 in_inc_open bool, in_inc_closed bool)
RETURNS SETOF  eca_history_result AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
     WITH arap AS (
       select  invnumber, ar.curr, ar.transdate, entity_credit_account, id,
                   person_id, notes
             FROM ar
             JOIN acc_trans ON ar.id  = acc_trans.trans_id
             JOIN account_link l ON acc_trans.chart_id = l.account_id
                  and l.description = 'AR'
            where $16 = 2 and $13 = 'i'
       GROUP BY 1, 2, 3, 4, 5, 6, 7
                  having (($17 and sum(acc_trans.amount_bc) = 0)
                      or ($18 and 0 <> sum(acc_trans.amount_bc)))
            UNION ALL
           select invnumber, ap.curr, ap.transdate, entity_credit_account, id,
                  person_id, notes
             FROM ap
             JOIN acc_trans ON ap.id  = acc_trans.trans_id
             JOIN account_link l ON acc_trans.chart_id = l.account_id
                  and l.description = 'AP'
            where $16 = 1 and $13 = 'i'
       GROUP BY 1, 2, 3, 4, 5, 6, 7
                  having (($17 and sum(acc_trans.amount_bc) = 0)
                      or ($18 and 0 <> sum(acc_trans.amount_bc)))
     )
     SELECT eca.id, e.name, eca.meta_number::text,
            a.id as invoice_id, a.invnumber, a.curr::text,
            p.id AS parts_id, p.partnumber,
            a.description,
            a.qty * case when eca.entity_class = 1 THEN -1 ELSE 1 END,
            a.unit::text, a.sellprice, a.discount,
            a.deliverydate,
            a.serialnumber,
            null::numeric as exchange_rate,
            ee.id as salesperson_id,
            ep.last_name || ', ' || ep.first_name as salesperson_name,
            a.transdate
     FROM (select * from entity_credit_account
            where ($2 is null or meta_number = $2)) eca
     join entity e on eca.entity_id = e.id
     JOIN (
           SELECT a.*, i.parts_id, i.qty, i.description, i.unit,
                  i.discount, i.deliverydate, i.serialnumber, i.sellprice
             FROM arap a
             JOIN invoice i ON a.id = i.trans_id
           union
           select o.ordnumber, o.curr, o.transdate, o.entity_credit_account,
                  o.id, o.person_id, o.notes, oi.parts_id, oi.qty,
                  oi.description, oi.unit, oi.discount, oi.reqdate,
                  oi.serialnumber, oi.sellprice
             from oe o
             join orderitems oi on o.id = oi.trans_id
            where (($13 = 'o' and quotation is not true)
                   or ($13 = 'q' and quotation is true))
              and (($16 = 1 and o.oe_class_id IN (2, 4))
                   or ($16 = 2 and o.oe_class_id IN (1, 3)))
              and (($17 and not closed)
                   or ($18 and closed))
          ) a ON (a.entity_credit_account = eca.id)
     JOIN parts p ON (p.id = a.parts_id)
LEFT JOIN entity ee ON (a.person_id = ee.id)
LEFT JOIN person ep ON (ep.entity_id = ee.id)
    WHERE (e.name ilike '%' || $1 || '%' or $1 is null)
      and ($3 is null
           or exists (select 1 from eca_to_contact
                       where credit_id = eca.id
                         and contact ilike '%' || $3 || '%'))
      and (($4 is null
            and $5 is null
            and $6 is null
            and $7 is null
            and $10 is null)
           or exists (select 1 from eca_to_location etl
                       where etl.credit_id = eca.id
                         and exists (select 1 from location l
                                      where l.id = etl.location_id
                                        and ($4 is null
                                             or line_one ilike '%' || $4 || '%'
                                             or line_two ilike '%' || $4 || '%')
                                        and ($5 is null
                                             or city ilike '%' || $5 || '%')
                                        and ($6 is null
                                             or state ilike '%' || $6 || '%')
                                        and ($7 is null
                                             or mail_code ilike '%' || $7 || '%')
                                        and ($10 is null
                                             or country_id = $10))
                     )
          )
          and (a.transdate >= $11 or $11 is null)
          and (a.transdate <= $12 or $12 is null)
          and (eca.startdate >= $14 or $14 is null)
          and (eca.startdate <= $15 or $15 is null)
          and (a.notes @@ plainto_tsquery($9) or $9 is null)
 ORDER BY eca.meta_number, p.partnumber
$sql$
USING in_name_part, in_meta_number, in_contact_info, in_address_line,
 in_city, in_state, in_zip, in_salesperson,
 in_notes, in_country_id, in_from_date, in_to_date,
 in_type, in_start_from, in_start_to, in_entity_class,
 in_inc_open, in_inc_closed;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION eca__history
(in_name_part text, in_meta_number text, in_contact_info text, in_address_line text,
 in_city text, in_state text, in_zip text, in_salesperson text, in_notes text,
 in_country_id int, in_from_date date, in_to_date date, in_type char(1),
 in_start_from date, in_start_to date, in_entity_class int,
 in_inc_open bool, in_inc_closed bool) IS
$$This produces a history detail report, i.e. a list of all products purchased by
a customer over a specific date range.

meta_number is an exact match, as are in_open and inc_closed.  All other fields
allow for partial matches.  NULL matches all values.$$;

DROP FUNCTION IF EXISTS eca__history_summary
(in_name text, in_meta_number text, in_contact_info text, in_address_line text,
 in_city text, in_state text, in_zip text, in_salesperson text, in_notes text,
 in_country_id int, in_from_date date, in_to_date date, in_type char(1),
 in_start_from date, in_start_to date, in_entity_class int,
 in_inc_open bool, in_inc_closed bool);
CREATE OR REPLACE FUNCTION eca__history_summary
(in_name_part text, in_meta_number text, in_contact_info text, in_address_line text,
 in_city text, in_state text, in_zip text, in_salesperson text, in_notes text,
 in_country_id int, in_from_date date, in_to_date date, in_type char(1),
 in_start_from date, in_start_to date, in_entity_class int,
 in_inc_open bool, in_inc_closed bool)
RETURNS SETOF  eca_history_result AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
SELECT id, name, meta_number::text, null::int, null::text, curr, parts_id, partnumber,
       description, sum(qty), unit, null::numeric, null::numeric, null::date,
       null::text, null::numeric,
       null::int, null::text, null::date
FROM   eca__history($1, $2, $3, $4, $5, $6, $7, $8, $9,
                   $10, $11, $12, $13, $14, $15, $16, $17, $18)
 group by id, name, meta_number, curr, parts_id, partnumber, description, unit,
          sellprice
 order by meta_number
$sql$
USING in_name_part, in_meta_number, in_contact_info, in_address_line,
 in_city, in_state, in_zip, in_salesperson,
 in_notes, in_country_id, in_from_date, in_to_date,
 in_type, in_start_from, in_start_to, in_entity_class,
 in_inc_open, in_inc_closed;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION eca__history_summary
(in_name text, in_meta_number text, in_contact_info text, in_address_line text,
 in_city text, in_state text, in_zip text, in_salesperson text, in_notes text,
 in_country_id int, in_from_date date, in_to_date date, in_type char(1),
 in_start_from date, in_start_to date, in_entity_class int,
 in_inc_open bool, in_inc_closed bool) IS
$$Creates a summary account (no quantities, just parts group by invoice).

meta_number must match exactly or be NULL.  inc_open and inc_closed are exact
matches too.  All other values specify ranges or may match partially.$$;

DROP FUNCTION IF EXISTS  contact__search
(in_entity_class int, in_contact text, in_contact_info text[],
        in_meta_number text, in_address text, in_city text, in_state text,
        in_mail_code text, in_country text, in_active_date_from date,
        in_active_date_to date,
        in_business_id int, in_name_part text, in_control_code text);

DROP FUNCTION IF EXISTS contact__search
(in_entity_class int, in_contact text, in_contact_info text[],
        in_meta_number text, in_address text, in_city text, in_state text,
        in_mail_code text, in_country text, in_active_date_from date,
        in_active_date_to date,
        in_business_id int, in_name_part text, in_control_code text,
        in_notes text);

CREATE OR REPLACE FUNCTION contact__search
(in_entity_class int, in_contact text, in_contact_info text[],
        in_meta_number text, in_address text, in_city text, in_state text,
        in_mail_code text, in_country text, in_active_date_from date,
        in_active_date_to date,
        in_business_id int, in_name_part text, in_control_code text,
        in_notes text, in_users bool)
RETURNS SETOF contact_search_result AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$

   WITH entities_matching_name AS (
                      SELECT legal_name, sic_code, entity_id
                        FROM company
                       WHERE $13 IS NULL
             OR legal_name @@ plainto_tsquery($13)
             OR legal_name ilike $13 || '%'
                      UNION ALL
                     SELECT coalesce(first_name, '') || ' '
             || coalesce(middle_name, '')
             || ' ' || coalesce(last_name, ''), null, entity_id
                       FROM person
       WHERE $13 IS NULL
             OR coalesce(first_name, '') || ' ' || coalesce(middle_name, '')
                || ' ' || coalesce(last_name, '')
                             @@ plainto_tsquery($13)
   ),
   matching_eca_contacts AS (
       SELECT credit_id
         FROM eca_to_contact
        WHERE ($3 IS NULL
               OR contact = ANY($3))
                        AND ($2 IS NULL
                   OR description @@ plainto_tsquery($2))
   ),
   matching_entity_contacts AS (
       SELECT entity_id
                                           FROM entity_to_contact
        WHERE ($3 IS NULL
               OR contact = ANY($3))
              AND ($2 IS NULL
                   OR description @@ plainto_tsquery($2))
   ),
   matching_locations AS (
       SELECT id
         FROM location
        WHERE ($5 IS NULL
               OR line_one @@ plainto_tsquery($5)
               OR line_two @@ plainto_tsquery($5)
               OR line_three @@ plainto_tsquery($5))
              AND ($6 IS NULL
                   OR city ILIKE '%' || $6 || '%')
              AND ($7 IS NULL
                   OR state ILIKE '%' || $7 || '%')
              AND ($8 IS NULL
                   OR mail_code ILIKE $8 || '%')
              AND ($9 IS NULL
                   OR EXISTS (select 1 from country
                               where name ilike '%' || $9 || '%'
                                  or short_name ilike '%' || $9 || '%'))
                       )
   SELECT e.id, e.control_code, ec.id, ec.meta_number::text,
          ec.description, ec.entity_class,
          c.legal_name, c.sic_code::text, b.description , ec.curr::text
     FROM entity e
     JOIN entities_matching_name c ON c.entity_id = e.id
LEFT JOIN entity_credit_account ec ON (ec.entity_id = e.id)
LEFT JOIN business b ON (ec.business_id = b.id)
    WHERE ($1 is null
           OR ec.entity_class = $1)
          AND ($14 IS NULL
               OR e.control_code like $14 || '%')
          AND (($3 IS NULL AND $2 IS NULL)
                OR EXISTS (select 1
                             from matching_eca_contacts mec
                            where mec.credit_id = ec.id)
                OR EXISTS (select 1
                             from matching_entity_contacts mec
                            where mec.entity_id = e.id))
           AND (($5 IS NULL AND $6 IS NULL
                 AND $7 IS NULL AND $8 IS NULL
                 AND $9 IS NULL)
                OR EXISTS (select 1
                             from matching_locations m
                             join eca_to_location etl ON m.id = etl.location_id
                            where etl.credit_id = ec.id)
                OR EXISTS (select 1
                             from matching_locations m
                             join entity_to_location etl
                                  ON m.id = etl.location_id
                            where etl.entity_id = e.id))
           AND ($12 IS NULL
                OR ec.business_id = $12)
           AND ($11 IS NULL
                OR ec.startdate <= $11)
           AND ($10 IS NULL
                OR ec.enddate >= ec.enddate)
           AND ($4 IS NULL
                OR ec.meta_number like $4 || '%')
           AND ($15 IS NULL
                OR EXISTS (select 1 from entity_note n
                            where e.id = n.entity_id
                                  and note @@ plainto_tsquery($15))
                OR EXISTS (select 1 from eca_note n
                            where ec.id = n.ref_key
                                  and note @@ plainto_tsquery($15)))
           AND ($16 IS NULL OR NOT $16
                OR EXISTS (select 1 from users where entity_id = e.id))
               ORDER BY legal_name
$sql$
USING in_entity_class, in_contact, in_contact_info, in_meta_number,
 in_address, in_city, in_state, in_mail_code,
 in_country, in_active_date_from, in_active_date_to, in_business_id,
 in_name_part, in_control_code, in_notes, in_users;
END
$$ LANGUAGE PLPGSQL;



DROP FUNCTION IF EXISTS eca__get_taxes(in_credit_id int);

CREATE OR REPLACE FUNCTION eca__get_taxes(in_id int)
returns setof eca_tax AS
$$
select * from eca_tax where eca_id = $1;
$$ language sql;

COMMENT ON FUNCTION eca__get_taxes(in_credit_id int) IS
$$ Returns a set of taxable account id's.$$; --'

DROP FUNCTION IF EXISTS eca__set_taxes(int, int[]);
CREATE OR REPLACE FUNCTION eca__set_taxes(in_id int, in_tax_ids int[])
RETURNS bool AS
$$
     DELETE FROM eca_tax WHERE eca_id = $1;
     INSERT INTO eca_tax (eca_id, chart_id)
     SELECT $1, tax_id
       FROM unnest($2) tax_id;
     SELECT TRUE;
$$ language sql;

comment on function eca__set_taxes(in_id int, in_tax_ids int[]) is
$$Sets the tax values for the customer or vendor.

The entity credit account must exist before calling this function, and must
have a type of either 1 or 2.
$$;

DROP FUNCTION if exists entity__save_notes(integer,text,text);
CREATE OR REPLACE FUNCTION entity__save_notes(in_entity_id int, in_note text, in_subject text)
RETURNS entity_note AS
$$
        -- TODO, change this to create vector too
        INSERT INTO entity_note (ref_key, note_class, entity_id, note, vector, subject)
        VALUES (in_entity_id, 1, in_entity_id, in_note, '', in_subject)
        RETURNING *;

$$ LANGUAGE SQL;

COMMENT ON FUNCTION entity__save_notes
(in_entity_id int, in_note text, in_subject text) IS
$$ Saves an entity-level note.  Such a note is valid for all credit accounts
attached to that entity.  Returns the id of the note.  $$;

DROP FUNCTION if exists eca__save_notes(integer,text,text);
CREATE OR REPLACE FUNCTION eca__save_notes(in_credit_id int, in_note text, in_subject text)
RETURNS eca_note AS
$$
        -- TODO, change this to create vector too
        INSERT INTO eca_note (ref_key, note_class, note, vector, subject)
        VALUES (in_credit_id, 3, in_note, '', in_subject)
        RETURNING *;

$$ LANGUAGE SQL;

COMMENT ON FUNCTION eca__save_notes
(in_entity_id int, in_note text, in_subject text) IS
$$ Saves an entity credit account-level note.  Such a note is valid for only one
credit account. Returns the id of the note.  $$;


CREATE OR REPLACE FUNCTION entity_credit_get_id_by_meta_number
(in_meta_number text, in_account_class int)
returns int AS
$$
        SELECT id
        FROM entity_credit_account
        WHERE meta_number = in_meta_number
                AND entity_class = in_account_class;

$$ LANGUAGE sql;

COMMENT ON FUNCTION entity_credit_get_id_by_meta_number
(in_meta_number text, in_account_class int) is
$$ Returns the credit id from the meta_number and entity_class.$$;

CREATE OR REPLACE FUNCTION entity_credit__get(in_id int)
RETURNS entity_credit_account AS
$$
SELECT * FROM entity_credit_account WHERE id = $1;
$$ language sql;

COMMENT ON FUNCTION entity_credit__get(in_id int) IS
$$ Returns the entity credit account info.$$;

CREATE OR REPLACE FUNCTION contact_class__list()
RETURNS SETOF contact_class AS
$$
                SELECT * FROM contact_class ORDER BY id;
$$ language sql;

COMMENT ON FUNCTION contact_class__list() IS
$$ Returns a list of contact classes ordered by ID.$$;

DROP TYPE IF EXISTS entity_credit_search_return CASCADE;
CREATE TYPE entity_credit_search_return AS (
        legal_name text,
        id int,
        entity_id int,
        entity_control_code text,
        entity_class int,
        discount numeric,
        taxincluded bool,
        creditlimit numeric,
        terms int2,
        meta_number text,
        credit_description text,
        business_id int,
        language_code text,
        pricegroup_id int,
        curr char(3),
        startdate date,
        enddate date,
        ar_ap_account_id int,
        cash_account_id int,
        tax_id text,
        threshold numeric
);

COMMENT ON TYPE entity_credit_search_return IS
$$ This may change in 1.4 and should not be relied upon too much $$;

CREATE OR REPLACE FUNCTION entity_credit_get_id
(in_entity_id int, in_entity_class int, in_meta_number text)
RETURNS int AS $$
        SELECT id FROM entity_credit_account
        WHERE entity_id = in_entity_id
                AND in_entity_class = entity_class
                AND in_meta_number = meta_number;

$$ language sql;

COMMENT ON FUNCTION entity_credit_get_id
(in_entity_id int, in_entity_class int, in_meta_number text) IS
$$ Returns an entity credit id, based on entity_id, entity_class,
and meta_number.  This is the preferred way to locate an account if all three of
these are known$$;

CREATE OR REPLACE FUNCTION company__get (in_entity_id int)
RETURNS company_entity AS
$$
        SELECT c.entity_id, c.legal_name, c.tax_id, c.sales_tax_id,
               c.license_number, c.sic_code, e.control_code, e.country_id
          FROM company c
          JOIN entity e ON e.id = c.entity_id
         WHERE entity_id = $1;
$$ language sql;

COMMENT ON FUNCTION company__get (in_entity_id int) IS
$$ Returns all attributes for the company attached to the entity.$$;

CREATE OR REPLACE FUNCTION company__get_by_cc (in_control_code text)
RETURNS company_entity AS
$$
        SELECT c.entity_id, c.legal_name, c.tax_id, c.sales_tax_id,
               c.license_number, c.sic_code, e.control_code, e.country_id
          FROM company c
          JOIN entity e ON e.id = c.entity_id
         WHERE e.control_code = $1;
$$ language sql;

COMMENT ON FUNCTION company__get_by_cc (in_control_code text) IS
$$ Returns the entity/company row attached to the control code. $$;

create or replace function save_taxform
(in_country_code int, in_taxform_name text)
RETURNS bool AS
$$
        INSERT INTO country_tax_form(country_id, form_name)
        values (in_country_code, in_taxform_name);

        SELECT true;
$$ LANGUAGE SQL;

COMMENT ON function save_taxform (in_country_code int, in_taxform_name text) IS
$$ Saves tax form information. Returns true or raises exception.$$;

CREATE OR REPLACE FUNCTION list_taxforms (in_entity_id int) RETURNS SETOF country_tax_form AS
$$
DECLARE t_country_tax_form country_tax_form;
BEGIN

        FOR t_country_tax_form IN

                      SELECT *
                            FROM country_tax_form where country_id in(SELECT country_id from entity where id=in_entity_id)
        LOOP

        RETURN NEXT t_country_tax_form;

        END LOOP;

END;
$$ language plpgsql;

COMMENT ON FUNCTION list_taxforms (in_entity_id int) IS
$$Returns a list of tax forms for the entity's country.$$; --'

DROP TYPE IF EXISTS company_billing_info CASCADE;
CREATE TYPE company_billing_info AS (
name text,
meta_number text,
control_code text,
cash_account_id int,
tax_id text,
street1 text,
street2 text,
street3 text,
city text,
state text,
mail_code text,
country text
);

CREATE OR REPLACE FUNCTION company_get_billing_info (in_id int)
returns company_billing_info as
$$
        select coalesce(eca.pay_to_name, c.legal_name), eca.meta_number,
                e.control_code, eca.cash_account_id, c.tax_id,
                a.line_one, a.line_two, a.line_three,
                a.city, a.state, a.mail_code, cc.name
        FROM (select legal_name, tax_id, entity_id
                FROM company
               UNION ALL
              SELECT last_name || ', ' || first_name, null, entity_id
                FROM person) c
        JOIN entity e ON (c.entity_id = e.id)
        JOIN entity_credit_account eca ON (eca.entity_id = e.id)
        LEFT JOIN eca_to_location cl ON (eca.id = cl.credit_id)
        LEFT JOIN location a ON (a.id = cl.location_id)
        LEFT JOIN country cc ON (cc.id = a.country_id)
        WHERE eca.id = in_id AND (location_class = 1 or location_class is null);

$$ language sql;

COMMENT ON FUNCTION company_get_billing_info (in_id int) IS
$$ Returns billing information (billing name and address) for a given credit
account.$$;


DROP FUNCTION IF EXISTS company_save (
    in_id int, in_control_code text, in_entity_class int,
    in_name text, in_tax_id TEXT,
    in_entity_id int, in_sic_code text,in_country_id int,
    in_sales_tax_id text, in_license_number text
);

DROP FUNCTION IF EXISTS company__save (
    in_id int, in_control_code text, in_entity_class int,
    in_legal_name text, in_tax_id TEXT,
    in_entity_id int, in_sic_code text,in_country_id int,
    in_sales_tax_id text, in_license_number text
);

DROP FUNCTION IF EXISTS company__save (
    in_control_code text, in_entity_class int,
    in_legal_name text, in_tax_id TEXT,
    in_entity_id int, in_sic_code text,in_country_id int,
    in_sales_tax_id text, in_license_number text
);

CREATE OR REPLACE FUNCTION company__save (
    in_control_code text,
    in_legal_name text, in_tax_id TEXT,
    in_entity_id int, in_sic_code text,in_country_id int,
    in_sales_tax_id text, in_license_number text
) RETURNS company AS $$
DECLARE t_entity_id INT;
        t_control_code TEXT;
        t_retval COMPANY;
BEGIN

        IF in_control_code IS NULL THEN
                t_control_code := setting_increment('entity_control');
        ELSE
                t_control_code := in_control_code;
        END IF;

        UPDATE entity
        SET name = in_legal_name,
                control_code = t_control_code,
                country_id   = in_country_id
        WHERE id = in_entity_id;

        IF FOUND THEN
                t_entity_id = in_entity_id;
        ELSE
                INSERT INTO entity (name, control_code,country_id)
                VALUES (in_legal_name, t_control_code,in_country_id);
                t_entity_id := currval('entity_id_seq');
        END IF;

        UPDATE company
        SET legal_name = in_legal_name,
                tax_id = in_tax_id,
                sic_code = in_sic_code,
                sales_tax_id = in_sales_tax_id,
                license_number = in_license_number
        WHERE entity_id = t_entity_id;


        IF NOT FOUND THEN
                INSERT INTO company(entity_id, legal_name, tax_id, sic_code,
                                    sales_tax_id, license_number)
                VALUES (t_entity_id, in_legal_name, in_tax_id, in_sic_code,
                        in_sales_tax_id, in_license_number);

        END IF;
        SELECT * INTO t_retval FROM company WHERE entity_id = t_entity_id;
        RETURN t_retval;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON  FUNCTION company__save (
    in_control_code text,
    in_legal_name text, in_tax_id TEXT,
    in_entity_id int, in_sic_code text,in_country_id int,
    in_sales_tax_id text, in_license_number text
 ) is
$$ Saves a company.  Returns the id number of the record stored.$$;

CREATE OR REPLACE FUNCTION pricegroup__list() RETURNS SETOF pricegroup AS
$$
SELECT * FROM pricegroup ORDER BY pricegroup;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION pricegroup__list() IS
$$ Returns an alphabetically ordered pricegroup list.$$;

DROP FUNCTION IF EXISTS entity_credit_save (
    in_credit_id int, in_entity_class int,
    in_entity_id int, in_description text,
    in_discount numeric, in_taxincluded bool, in_creditlimit numeric,
    in_discount_terms int,
    in_terms int, in_meta_number varchar(32), in_business_id int,
    in_language varchar(6), in_pricegroup_id int,
    in_curr char, in_startdate date, in_enddate date,
    in_threshold NUMERIC,
    in_ar_ap_account_id int,
    in_cash_account_id int,
    in_pay_to_name text,
    in_taxform_id int);

DROP FUNCTION IF EXISTS eca__save (
    in_credit_id int, in_entity_class int,
    in_entity_id int, in_description text,
    in_discount numeric, in_taxincluded bool, in_creditlimit numeric,
    in_discount_terms int,
    in_terms int, in_meta_number varchar(32), in_business_id int,
    in_language_code varchar(6), in_pricegroup_id int,
    in_curr char, in_startdate date, in_enddate date,
    in_threshold NUMERIC,
    in_ar_ap_account_id int,
    in_cash_account_id int,
    in_pay_to_name text,
    in_taxform_id int);

CREATE OR REPLACE FUNCTION eca__save (
    in_id int, in_entity_class int,
    in_entity_id int, in_description text,
    in_discount numeric, in_taxincluded bool, in_creditlimit numeric,
    in_discount_terms int,
    in_terms int, in_meta_number varchar(32), in_business_id int,
    in_language_code varchar(6), in_pricegroup_id int,
    in_curr char, in_startdate date, in_enddate date,
    in_threshold NUMERIC,
    in_ar_ap_account_id int,
    in_cash_account_id int,
    in_pay_to_name text,
    in_taxform_id int,
    in_discount_account_id int
) returns INT as $$

    DECLARE
        t_entity_class int;
        l_id int;
        t_meta_number text;
        t_mn_default_key text;
    BEGIN
        -- TODO:  Move to mapping table.
            IF in_entity_class = 1 THEN
               t_mn_default_key := 'vendornumber';
            ELSIF in_entity_class = 2 THEN
               t_mn_default_key := 'customernumber';
            END IF;
            IF in_meta_number IS NULL THEN
                t_meta_number := setting_increment(t_mn_default_key);
            ELSE
                t_meta_number := in_meta_number;
            END IF;
            update entity_credit_account SET
                discount = in_discount,
                taxincluded = in_taxincluded,
                creditlimit = in_creditlimit,
                description = in_description,
                terms = in_terms,
                ar_ap_account_id = in_ar_ap_account_id,
                cash_account_id = in_cash_account_id,
                discount_account_id = in_discount_account_id,
                meta_number = t_meta_number,
                business_id = in_business_id,
                language_code = in_language_code,
                pricegroup_id = in_pricegroup_id,
                curr = in_curr,
                startdate = in_startdate,
                enddate = in_enddate,
                threshold = in_threshold,
                discount_terms = in_discount_terms,
                pay_to_name = in_pay_to_name,
                taxform_id = in_taxform_id
            where id = in_id;

         IF FOUND THEN
            RETURN in_id;
         ELSE
            INSERT INTO entity_credit_account (
                entity_id,
                entity_class,
                discount,
                description,
                taxincluded,
                creditlimit,
                terms,
                meta_number,
                business_id,
                language_code,
                pricegroup_id,
                curr,
                startdate,
                enddate,
                discount_terms,
                threshold,
                ar_ap_account_id,
                pay_to_name,
                taxform_id,
                cash_account_id,
                discount_account_id
            )
            VALUES (
                in_entity_id,
                in_entity_class,
                in_discount,
                in_description,
                in_taxincluded,
                in_creditlimit,
                in_terms,
                t_meta_number,
                in_business_id,
                in_language_code,
                in_pricegroup_id,
                in_curr,
                in_startdate,
                in_enddate,
                in_discount_terms,
                in_threshold,
                in_ar_ap_account_id,
                in_pay_to_name,
                in_taxform_id,
                in_cash_account_id,
                in_discount_account_id
            );
            RETURN currval('entity_credit_account_id_seq');
       END IF;

    END;

$$ language 'plpgsql';

COMMENT ON  FUNCTION eca__save (
    in_id int, in_entity_class int,
    in_entity_id int, in_description text,
    in_discount numeric, in_taxincluded bool, in_creditlimit numeric,
    in_discount_terms int,
    in_terms int, in_meta_number varchar(32), in_business_id int,
    in_language_code varchar(6), in_pricegroup_id int,
    in_curr char, in_startdate date, in_enddate date,
    in_threshold NUMERIC,
    in_ar_ap_account_id int,
    in_cash_account_id int,
    in_pay_to_name text,
    in_taxform_id int,
    in_discount_account_id int
) IS
$$ Saves an entity credit account.  Returns the id of the record saved.  $$;

CREATE OR REPLACE FUNCTION entity__list_locations(in_entity_id int)
RETURNS SETOF location_result AS
$$
                SELECT l.id, l.line_one, l.line_two, l.line_three, l.city,
                        l.state, l.mail_code, c.id, c.name, lc.id, lc.class
                FROM location l
                JOIN entity_to_location ctl ON (ctl.location_id = l.id)
                JOIN location_class lc ON (ctl.location_class = lc.id)
                JOIN country c ON (c.id = l.country_id)
                WHERE ctl.entity_id = in_entity_id
                ORDER BY lc.id, l.id, c.name;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION entity__list_locations(in_entity_id int) IS
$$ Lists all locations for an entity.$$;

DROP TYPE IF EXISTS contact_list CASCADE;
CREATE TYPE contact_list AS (
        class text,
        class_id int,
        description text,
        contact text
);


CREATE OR REPLACE FUNCTION entity__list_contacts(in_entity_id int)
RETURNS SETOF contact_list AS $$
                SELECT cl.class, cl.id, c.description, c.contact
                FROM entity_to_contact c
                JOIN contact_class cl ON (c.contact_class_id = cl.id)
                WHERE c.entity_id = in_entity_id
$$ language sql;

COMMENT ON FUNCTION entity__list_contacts(in_entity_id int) IS
$$ Lists all contact info for the entity.$$;

CREATE OR REPLACE FUNCTION entity__list_bank_account(in_entity_id int)
RETURNS SETOF entity_bank_account AS
$$
SELECT * from entity_bank_account where entity_id = in_entity_id;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION entity__list_bank_account(in_entity_id int) IS
$$ Lists all bank accounts for the entity.$$;

DROP FUNCTION IF EXISTS entity__save_bank_account
(in_entity_id int, in_credit_id int, in_bic text, in_iban text,
in_bank_account_id int);

drop function if exists entity__save_bank_account
(in_entity_id int, in_credit_id int, in_bic text, in_iban text, in_remark text,
in_bank_account_id int);

CREATE OR REPLACE FUNCTION entity__save_bank_account
(in_entity_id int, in_credit_id int, in_bic text, in_iban text, in_remark text,
in_bank_account_id int)
RETURNS entity_bank_account AS
$$
DECLARE out_bank entity_bank_account;
BEGIN
        UPDATE entity_bank_account
           SET bic = coalesce(in_bic,''),
               iban = in_iban,
               remark = in_remark
         WHERE id = in_bank_account_id;

        IF FOUND THEN
             SELECT * INTO out_bank from entity_bank_account WHERE id = in_bank_account_id;

        ELSE
                INSERT INTO entity_bank_account(entity_id, bic, iban, remark)
                VALUES(in_entity_id, in_bic, in_iban, in_remark);
                SELECT * INTO out_bank from entity_bank_account WHERE id = CURRVAL('entity_bank_account_id_seq');
        END IF;

        IF in_credit_id IS NOT NULL THEN
                UPDATE entity_credit_account SET bank_account = out_bank.id
                WHERE id = in_credit_id;
        END IF;
        return out_bank;

END;
$$ LANGUAGE PLPGSQL;

COMMENT ON  FUNCTION entity__save_bank_account
(in_entity_id int, in_credit_id int, in_bic text, in_iban text, in_remark text,
in_bank_account_id int) IS
$$ Saves bank account to the credit account.$$;

CREATE OR REPLACE FUNCTION entity__delete_contact
(in_entity_id int, in_class_id int, in_contact text)
returns bool as $$
BEGIN

DELETE FROM entity_to_contact
 WHERE entity_id = in_entity_id
       and contact_class_id = in_class_id
       and contact= in_contact;
RETURN FOUND;

END;

$$ language plpgsql;

COMMENT ON FUNCTION entity__delete_contact
(in_company_id int, in_contact_class_id int, in_contact text) IS
$$ Returns true if at least one record was deleted.  False if no records were
affected.$$;

CREATE OR REPLACE FUNCTION eca__delete_contact
(in_credit_id int, in_class_id int, in_contact text)
returns bool as $$
BEGIN

DELETE FROM eca_to_contact
 WHERE credit_id = in_credit_id and contact_class_id = in_class_id
       and contact= in_contact;
RETURN FOUND;

END;

$$ language plpgsql;

COMMENT ON FUNCTION eca__delete_contact
(in_credit_id int, in_contact_class_id int, in_contact text) IS
$$ Returns true if at least one record was deleted.  False if no records were
affected.$$;

DROP FUNCTION IF EXISTS entity__save_contact
(in_entity_id int, in_class_id int, in_description text, in_contact text,
in_old_contact text, in_old_class_id int);

CREATE OR REPLACE FUNCTION entity__save_contact
(in_entity_id int, in_class_id int, in_description text, in_contact text,
 in_old_contact text, in_old_class_id int)
RETURNS entity_to_contact AS
$$
        DELETE FROM entity_to_contact
         WHERE entity_id = in_entity_id AND contact = in_old_contact
               AND contact_class_id = in_old_class_id;

        INSERT INTO entity_to_contact
               (entity_id, contact_class_id, description, contact)
        VALUES (in_entity_id, in_class_id, in_description, in_contact)
         RETURNING *;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION entity__save_contact
(in_entity_id int, in_contact_class int, in_description text, in_contact text,
in_old_contact text, in_old_class_id int) IS
$$ Saves company contact information.  The return value is meaningless. $$;

DROP TYPE IF EXISTS entity_note_list CASCADE;
CREATE TYPE entity_note_list AS (
        id int,
        note_class int,
        note text
);

CREATE OR REPLACE FUNCTION entity__list_notes(in_entity_id int)
RETURNS SETOF entity_note AS
$$
                SELECT *
                FROM entity_note
                WHERE ref_key = in_entity_id
                ORDER BY created
$$ LANGUAGE SQL;

COMMENT ON FUNCTION entity__list_notes(in_entity_id int) IS
$$ Returns a set of notes (including content) attached to the entity.$$;

CREATE OR REPLACE FUNCTION eca__list_notes(in_credit_id int)
RETURNS SETOF note AS
$$
DECLARE out_row record;
        t_entity_id int;
BEGIN
        -- ALERT: security definer function.  Be extra careful about EXECUTE
        -- in here. --CT
        SELECT entity_id INTO t_entity_id
        FROM entity_credit_account
        WHERE id = in_credit_id;

        FOR out_row IN
                SELECT *
                FROM note
                WHERE (note_class = 3 and ref_key = in_credit_id) or
                        (note_class = 1 and ref_key = t_entity_id)
                ORDER BY created
        LOOP
                RETURN NEXT out_row;
        END LOOP;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

COMMENT ON FUNCTION eca__list_notes(in_credit_id int) IS
$$Returns a list of notes attached to the entity credit account.$$;

REVOKE EXECUTE ON FUNCTION eca__list_notes(INT) FROM public;

CREATE OR REPLACE FUNCTION company__next_id() returns bigint as $$

    select nextval('company_id_seq');

$$ language 'sql';

DROP FUNCTION IF EXISTS entity__location_save (
    in_entity_id int, in_id int,
    in_location_class int, in_line_one text, in_line_two text,
    in_city TEXT, in_state TEXT, in_mail_code text, in_country_id int,
    in_created date
);

CREATE OR REPLACE FUNCTION entity__location_save (
    in_entity_id int, in_id int,
    in_location_class int, in_line_one text, in_line_two text,
    in_line_three text, in_city TEXT, in_state TEXT, in_mail_code text,
    in_country_id int, in_created date
) returns int AS $$
    BEGIN
    return _entity_location_save(
        in_entity_id, in_id,
        in_location_class, in_line_one, in_line_two,
        in_line_three, in_city , in_state, in_mail_code, in_country_id);
    END;

$$ language 'plpgsql';

COMMENT ON FUNCTION entity__location_save (
    in_entity_id int, in_id int,
    in_location_class int, in_line_one text, in_line_two text,
    in_line_three text, in_city TEXT, in_state TEXT, in_mail_code text,
    in_country_id int, in_created date
) IS
$$ Saves a location to a company.  Returns the location id.$$;

create or replace function _entity_location_save(
    in_entity_id int, in_location_id int,
    in_location_class int, in_line_one text, in_line_two text,
    in_line_three text, in_city TEXT, in_state TEXT, in_mail_code text,
    in_country_id int
) returns int AS $$

    DECLARE
        l_id INT;
    BEGIN
      SELECT location_save(
        NULL,
        in_line_one,
        in_line_two,
        in_line_three,
        in_city,
        in_state,
        in_mail_code,
        in_country_id
      )
        INTO l_id;

      UPDATE entity_to_location
         SET location_class = in_location_class,
             location_id = l_id
       WHERE entity_id = in_entity_id
         AND location_class = in_location_class
         AND location_id = in_location_id;

      IF NOT FOUND THEN
        INSERT INTO entity_to_location (entity_id, location_class, location_id)
        VALUES (in_entity_id, in_location_class, l_id);
      END IF;

        RETURN l_id;
    END;

$$ language 'plpgsql';


COMMENT ON FUNCTION _entity_location_save(
    in_entity_id int, in_location_id int,
    in_location_class int, in_line_one text, in_line_two text,
    in_line_three text, in_city TEXT, in_state TEXT, in_mail_code text,
    in_country_code int
) IS
$$ Private method for storing locations to an entity.  Do not call directly.
Returns the location id that was inserted or updated.$$;

create or replace function eca__location_save(
    in_credit_id int, in_id int,
    in_location_class int, in_line_one text, in_line_two text,
    in_line_three text, in_city TEXT, in_state TEXT, in_mail_code text,
    in_country_id int, in_old_location_class int
) returns int AS $$

    DECLARE
        l_id INT;
    BEGIN
        SELECT location_save(
          NULL,
          in_line_one,
          in_line_two,
          in_line_three,
          in_city,
          in_state,
          in_mail_code,
          in_country_id
        )
          INTO l_id;

        UPDATE eca_to_location
           SET location_class = in_location_class,
               location_id = l_id
         WHERE credit_id = in_credit_id
           AND location_class = in_old_location_class
           AND location_id = in_id;

         IF NOT FOUND THEN
            INSERT INTO eca_to_location
                        (credit_id, location_class, location_id)
                VALUES  (in_credit_id, in_location_class, l_id);

        END IF;

        RETURN l_id;
    END;

$$ language 'plpgsql';

COMMENT ON function eca__location_save(
    in_credit_id int, in_id int,
    in_location_class int, in_line_one text, in_line_two text,
    in_line_three text, in_city TEXT, in_state TEXT, in_mail_code text,
    in_country_code int, in_old_location_class int
) IS
$$ Saves a location to an entity credit account. Returns id of saved record.$$;

CREATE OR REPLACE FUNCTION eca__delete_location
(in_credit_id int, in_id int, in_location_class int)
RETURNS BOOL AS
$$
BEGIN

DELETE FROM eca_to_location
 WHERE credit_id = in_credit_id AND location_id = in_id
       AND location_class = in_location_class;

RETURN FOUND;

END;
$$ language plpgsql;

COMMENT ON FUNCTION eca__delete_location
(in_credit_id int, in_id int, in_location_class int) IS
$$ Deletes the record identified.  Returns true if successful, false if no record
found.$$;

CREATE OR REPLACE FUNCTION entity__delete_location
(in_entity_id int, in_id int, in_location_class int)
RETURNS BOOL AS
$$
BEGIN

DELETE FROM entity_to_location
 WHERE entity_id = in_entity_id AND location_id = in_id
       AND location_class = in_location_class;

RETURN FOUND;

END;
$$ language plpgsql;

COMMENT ON FUNCTION entity__delete_location
(in_entity_id int, in_id int, in_location_class int) IS
$$ Deletes the record identified.  Returns true if successful, false if no record
found.$$;

CREATE OR REPLACE FUNCTION eca__list_locations(in_credit_id int)
RETURNS SETOF location_result AS
$$
                SELECT l.id, l.line_one, l.line_two, l.line_three, l.city,
                        l.state, l.mail_code, c.id, c.name, lc.id, lc.class
                FROM location l
                JOIN eca_to_location ctl ON (ctl.location_id = l.id)
                JOIN location_class lc ON (ctl.location_class = lc.id)
                JOIN country c ON (c.id = l.country_id)
                WHERE ctl.credit_id = in_credit_id
                ORDER BY lc.id, l.id, c.name
$$ LANGUAGE SQL;

COMMENT ON FUNCTION eca__list_locations(in_credit_id int) IS
$$ Returns a list of locations attached to the credit account.$$;

CREATE OR REPLACE FUNCTION eca__list_contacts(in_credit_id int)
RETURNS SETOF contact_list AS $$
DECLARE out_row contact_list;
BEGIN
        FOR out_row IN
                SELECT cl.class, cl.id, c.description, c.contact
                FROM eca_to_contact c
                JOIN contact_class cl ON (c.contact_class_id = cl.id)
                WHERE credit_id = in_credit_id
        LOOP
                return next out_row;
        END LOOP;
END;
$$ language plpgsql;

COMMENT ON FUNCTION eca__list_contacts(in_credit_id int) IS
$$ Returns a list of contact info attached to the entity credit account.$$;

DROP FUNCTION IF EXISTS eca__save_contact(int, int, text, text, text, int);

CREATE OR REPLACE FUNCTION eca__save_contact
(in_credit_id int, in_class_id int, in_description text, in_contact text,
in_old_contact text, in_old_class_id int)
RETURNS eca_to_contact AS
$$
DECLARE out_contact eca_to_contact;
BEGIN

    PERFORM *
       FROM eca_to_contact
      WHERE credit_id = in_credit_id
        AND contact_class_id = in_old_class_id
        AND contact = in_old_contact;

    IF FOUND THEN
        UPDATE eca_to_contact
           SET contact = in_contact,
               description = in_description,
               contact_class_id = in_class_id
         WHERE credit_id = in_credit_id
           AND contact_class_id = in_old_class_id
           AND contact = in_old_contact
        returning * INTO out_contact;
        return out_contact;
    END IF;
        INSERT INTO eca_to_contact(credit_id, contact_class_id,
                description, contact)
        VALUES (in_credit_id, in_class_id, in_description, in_contact)
        RETURNING * into out_contact;
        return out_contact;

END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION eca__save_contact
(in_credit_id int, in_contact_class int, in_description text, in_contact text,
in_old_contact text, in_old_contact_class int) IS
$$ Saves the contact record at the entity credit account level.  Returns 1.$$;

-- pricematrix

CREATE OR REPLACE FUNCTION eca__get_pricematrix_by_pricegroup(in_credit_id int)
RETURNS SETOF eca__pricematrix AS
$$
SELECT pc.parts_id, p.partnumber, p.description, pc.credit_id, pc.pricebreak,
       pc.sellprice, NULL::numeric, NULL::int, NULL::text, pc.validfrom,
       pc.validto, pc.curr, pc.entry_id, pc.qty
  FROM partscustomer pc
  JOIN parts p on pc.parts_id = p.id
  JOIN entity_credit_account eca ON pc.pricegroup_id = eca.pricegroup_id
 WHERE eca.id = $1 AND eca.entity_class = 2
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION eca__get_pricematrix(in_credit_id int)
RETURNS SETOF eca__pricematrix AS
$$

SELECT pc.parts_id, p.partnumber, p.description, pc.credit_id, pc.pricebreak,
       pc.sellprice, NULL, NULL::int, NULL, pc.validfrom, pc.validto, pc.curr,
       pc.entry_id, pc.qty
  FROM partscustomer pc
  JOIN parts p on pc.parts_id = p.id
  JOIN entity_credit_account eca ON pc.credit_id = eca.id
 WHERE pc.credit_id = $1 AND eca.entity_class = 2
 UNION
SELECT pv.parts_id, p.partnumber, p.description, pv.credit_id, NULL, NULL,
       pv.lastcost, pv.leadtime::int, pv.partnumber, NULL, NULL, pv.curr,
       pv.entry_id, null
  FROM partsvendor pv
  JOIN parts p on pv.parts_id = p.id
  JOIN entity_credit_account eca ON pv.credit_id = eca.id
 WHERE pv.credit_id = $1 and eca.entity_class = 1
 ORDER BY partnumber, validfrom

$$ language sql;

COMMENT ON FUNCTION eca__get_pricematrix(in_credit_id int) IS
$$ This returns the pricematrix for the customer or vendor
(entity_credit_account identified by in_id), orderd by partnumber, validfrom
$$;

CREATE OR REPLACE FUNCTION eca__delete_pricematrix
(in_credit_id int, in_entry_id int)
RETURNS BOOL AS
$$
DECLARE retval bool;

BEGIN

retval := false;

DELETE FROM partsvendor
 WHERE entry_id = in_entry_id
       AND credit_id = in_credit_id;

retval := FOUND;

DELETE FROM partscustomer
 WHERE entry_id = in_entry_id
       AND credit_id = in_credit_id;

RETURN FOUND or retval;

END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION eca__save_pricematrix
(in_parts_id int, in_credit_id int, in_pricebreak numeric, in_price numeric,
 in_lead_time int2, in_partnumber text, in_validfrom date, in_validto date,
 in_curr char(3), in_entry_id int)
RETURNS eca__pricematrix AS
$$
DECLARE
   retval eca__pricematrix;
   t_insert bool;

BEGIN

t_insert := false;

PERFORM * FROM entity_credit_account
  WHERE id = in_credit_id AND entity_class = 1;

IF FOUND THEN -- VENDOR
    UPDATE partsvendor
       SET lastcost = in_price,
           leadtime = in_lead_time,
           partnumber = in_partnumber,
           curr = in_curr
     WHERE credit_id = in_credit_id AND entry_id = in_entry_id;

    IF NOT FOUND THEN
        INSERT INTO partsvendor
               (parts_id, credit_id, lastcost, leadtime, partnumber, curr)
        VALUES (in_parts_id, in_credit_id, in_price, in_lead_time::int2,
               in_partnumber, in_curr);
    END IF;

    SELECT pv.parts_id, p.partnumber, p.description, pv.credit_id, NULL, NULL,
           pv.lastcost, pv.leadtime::int, pv.partnumber, NULL, NULL, pv.curr,
           pv.entry_id, null
      INTO retval
      FROM partsvendor pv
      JOIN parts p ON p.id = pv.parts_id
     WHERE parts_id = in_parts_id and credit_id = in_credit_id;

    RETURN retval;
END IF;

PERFORM * FROM entity_credit_account
  WHERE id = in_credit_id AND entity_class = 2;

IF FOUND THEN -- CUSTOMER
    UPDATE partscustomer
       SET pricebreak = in_pricebreak,
           sellprice  = in_price,
           validfrom  = in_validfrom,
           validto    = in_validto,
           qty        = in_qty,
           curr       = in_curr
     WHERE entry_id = in_entry_id and credit_id = in_credit_id;

    IF NOT FOUND THEN
        INSERT INTO partscustomer
               (parts_id, credit_id, sellprice, validfrom, validto, curr, qty)
        VALUES (in_parts_id, in_credit_id, in_price, in_validfrom, in_validto,
                in_curr, in_qty);

        t_insert := true;
    END IF;

    SELECT pc.parts_id, p.partnumber, p.description, pc.credit_id,
           pc.pricebreak, pc.sellprice, NULL, NULL, NULL, pc.validfrom,
           pc.validto, pc.curr, pc.entry_id, pc.qty
      INTO retval
      FROM partscustomer pc
      JOIN parts p on pc.parts_id = p.id
     WHERE entry_id = CASE WHEN t_insert
                           THEN currval('partscustomer_entry_id_seq')
                           ELSE in_entry_id
                      END;

    RETURN retval;

END IF;

RAISE EXCEPTION 'No valid entity credit account found';

END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION eca__get_pricematrix(in_id int) IS
$$ This returns the pricematrix for the customer or vendor
(entity_credit_account identified by in_id), orderd by partnumber, validfrom
$$;

CREATE OR REPLACE FUNCTION eca__delete_pricematrix
(in_credit_id int, in_entry_id int)
RETURNS BOOL AS
$$
DECLARE retval bool;

BEGIN

retval := false;

DELETE FROM partsvendor
 WHERE entry_id = in_entry_id
       AND credit_id = in_credit_id;

retval := FOUND;

DELETE FROM partscustomer
 WHERE entry_id = in_entry_id
       AND credit_id = in_credit_id;

RETURN FOUND or retval;

END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION pricelist__save
(in_parts_id int, in_credit_id int, in_pricebreak numeric, in_price numeric,
 in_lead_time int2, in_partnumber text, in_validfrom date, in_validto date,
 in_curr char(3), in_entry_id int, in_qty numeric)
RETURNS eca__pricematrix AS
$$
DECLARE
   retval eca__pricematrix;
   t_insert bool;
   t_entity_class int;

BEGIN

t_insert := false;

SELECT entity_class INTO t_entity_class FROM entity_credit_account
  WHERE id = in_credit_id;

IF t_entity_class = 1 THEN -- VENDOR
    UPDATE partsvendor
       SET lastcost = in_price,
           leadtime = in_lead_time,
           partnumber = in_partnumber,
           curr = in_curr
     WHERE credit_id = in_credit_id AND entry_id = in_entry_id;

    IF NOT FOUND THEN
        INSERT INTO partsvendor
               (parts_id, credit_id, lastcost, leadtime, partnumber, curr)
        VALUES (in_parts_id, in_credit_id, in_price, in_leadtime::int2,
               in_partnumber, in_curr);
    END IF;

    SELECT pv.parts_id, p.partnumber, p.description, pv.credit_id, NULL, NULL,
           pv.lastcost, pv.leadtime::int, pv.partnumber, NULL, NULL, pv.curr,
           pv.entry_id
      INTO retval
      FROM partsvendor pv
      JOIN parts p ON p.id = pv.parts_id
     WHERE parts_id = in_parts_id and credit_id = in_credit_id;

    RETURN retval;

ELSIF t_entity_class = 2 THEN -- CUSTOMER
    UPDATE partscustomer
       SET pricebreak = in_pricebreak,
           sellprice  = in_price,
           validfrom  = in_validfrom,
           validto    = in_validto,
           qty        = in_qty,
           curr       = in_curr
     WHERE entry_id = in_entry_id and credit_id = in_credit_id;

    IF NOT FOUND THEN
        INSERT INTO partscustomer
               (parts_id, credit_id, sellprice, validfrom, validto, curr, qty)
        VALUES (in_parts_id, in_credit_id, in_price, in_validfrom, in_validto,
                in_curr, in_qty);

        t_insert := true;
    END IF;

    SELECT pc.parts_id, p.partnumber, p.description, pc.credit_id,
           pc.pricebreak, pc.sellprice, NULL, NULL, NULL, pc.validfrom,
           pc.validto, pc.curr, pc.entry_id, qty
      INTO retval
      FROM partscustomer pc
      JOIN parts p on pc.parts_id = p.id
     WHERE entry_id = CASE WHEN t_insert
                           THEN currval('partscustomer_entry_id_seq')
                           ELSE in_entry_id
                      END;

    RETURN retval;

ELSE

RAISE EXCEPTION 'No valid entity credit account found';

END IF;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION pricelist__delete(in_entry_id int, in_credit_id int)
returns bool as
$$
delete from partscustomer where entry_id = $1 and credit_id = $2;
delete from partsvendor where entry_id = $1 and credit_id = $2;
select true;
$$ language sql;

CREATE OR REPLACE FUNCTION sic__list()
RETURNS SETOF sic LANGUAGE SQL AS
$$
SELECT * FROM sic ORDER BY code;
$$;


update defaults set value = 'yes' where setting_key = 'module_load_ok';


COMMIT;
