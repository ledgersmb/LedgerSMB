--Setup

-- With help of a few conditional statements handled by the Template toolkit,
-- this migration file handles migration from all SQL-Ledger version up to 3.0
-- to all Ledgersmb up to 1.6

-- When moved to an interface, these will all be specified and preprocessed.
\set default_country '''[% default_country %]'''
\set ar '''[% default_ar %]'''
\set ap '''[% default_ap %]'''
/* NOTE: PostgreSQL doesn't allow variable interpolation within $$ blocks
         so we will need to rely on the Template to substitude the proper schema
         for those. Elsewhere we will use :slschema for lisibility
 */
\set slschema '[% slschema %]'
\set lsmbversion '[% lsmbversion %]'

BEGIN;

ALTER TABLE :slschema.acc_trans DROP COLUMN IF EXISTS lsmb_entry_id;
ALTER TABLE :slschema.acc_trans add column lsmb_entry_id SERIAL UNIQUE;

-- Migration functions
-- TODO: Can we do without?

CREATE OR REPLACE FUNCTION pg_temp.account__save
(in_id int, in_accno text, in_description text, in_category char(1),
in_gifi_accno text, in_heading int, in_contra bool, in_tax bool,
in_link text[], in_obsolete bool, in_is_temp bool)
RETURNS int AS $$
DECLARE
        t_heading_id int;
        t_link record;
        t_id int;
        t_tax bool;
BEGIN

    SELECT count(*) > 0 INTO t_tax FROM tax WHERE in_id = chart_id;
    t_tax := t_tax OR in_tax;
    -- check to ensure summary accounts are exclusive
    -- necessary for proper handling by legacy code
    FOR t_link IN SELECT description
                    FROM account_link_description
                   WHERE summary='t'
    LOOP
        IF t_link.description = ANY (in_link) and array_upper(in_link, 1) > 1 THEN
                RAISE EXCEPTION 'Invalid link settings:  Summary';
        END IF;
    END LOOP;

    -- heading settings
    IF in_heading IS NULL THEN
            SELECT id INTO t_heading_id FROM account_heading
            WHERE accno < in_accno order by accno desc limit 1;
    ELSE
            t_heading_id := in_heading;
    END IF;

    -- don't remove custom links.
    DELETE FROM account_link
    WHERE account_id = in_id
          and description in ( select description
                                from  account_link_description
                                where custom = 'f');

    INSERT INTO account (accno, description, category, gifi_accno,
                heading, contra, tax, is_temp)
    VALUES (in_accno, in_description, in_category, in_gifi_accno,
            t_heading_id, in_contra, in_tax, coalesce(in_is_temp, 'f'));

    t_id := currval('account_id_seq');

    FOR t_link IN
        SELECT in_link[generate_series] AS val
        FROM generate_series(array_lower(in_link, 1),
                array_upper(in_link, 1))
    LOOP
        INSERT INTO account_link (account_id, description)
        VALUES (t_id, t_link.val);
    END LOOP;

    RETURN t_id;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.location_save
(in_location_id int, in_address1 text, in_address2 text, in_address3 text,
        in_city text, in_state text, in_zipcode text, in_country int)
returns integer AS
$$
DECLARE
        location_id integer;
        location_row RECORD;
BEGIN

        IF in_location_id IS NULL THEN
            SELECT id INTO location_id FROM location
            WHERE line_one = in_address1 AND line_two = in_address2
                  AND line_three = in_address3 AND in_city = city
                  AND in_state = state AND in_zipcode = mail_code
                  AND in_country = country_id
            LIMIT 1;

            IF NOT FOUND THEN
            -- Straight insert.
            location_id = nextval('location_id_seq');
            INSERT INTO location (
                id,
                line_one,
                line_two,
                line_three,
                city,
                state,
                mail_code,
                country_id)
            VALUES (
                location_id,
                in_address1,
                in_address2,
                in_address3,
                in_city,
                in_state,
                in_zipcode,
                in_country
                );
            END IF;
            return location_id;
        ELSE
            RAISE NOTICE 'Overwriting location id %', in_location_id;
            -- Test it.
            SELECT * INTO location_row FROM location WHERE id = in_location_id;
            IF NOT FOUND THEN
                -- Tricky users are lying to us.
                RAISE EXCEPTION 'location_save called with nonexistant location ID %', in_location_id;
            ELSE
                -- Okay, we're good.

                UPDATE location SET
                    line_one = in_address1,
                    line_two = in_address2,
                    line_three = in_address3,
                    city = in_city,
                    state = in_state,
                    mail_code = in_zipcode,
                    country_id = in_country
                WHERE id = in_location_id;
                return in_location_id;
            END IF;
        END IF;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION pg_temp.setting__increment_base(in_raw_var text)
returns varchar language plpgsql as $$
declare raw_value VARCHAR;
       base_value VARCHAR;
       increment  INTEGER;
       inc_length INTEGER;
       new_value VARCHAR;
begin
    raw_value := in_raw_var;
    base_value := substring(raw_value from
                                '(' || E'\\' || 'd*)(' || E'\\' || 'D*|<'
                                    || E'\\' || '?lsmb [^<>] ' || E'\\'
                                    || '?>)*$');
    IF base_value like '0%' THEN
         increment := base_value::integer + 1;
         inc_length := char_length(increment::text);
         new_value := overlay(base_value placing increment::varchar
                              from (char_length(base_value)
                                    - inc_length + 1)
                              for inc_length);
    ELSE
         new_value := base_value::integer + 1;
    END IF;
    return regexp_replace(raw_value, base_value, new_value);
end;
$$;

CREATE OR REPLACE FUNCTION pg_temp.setting_increment (in_key varchar) returns varchar
AS
$$
        UPDATE defaults SET value = pg_temp.setting__increment_base(value)
        WHERE setting_key = in_key
        RETURNING value;

$$ LANGUAGE SQL;

create type recon_accounts as (
    name text,
    accno text,
    id int
);

create or replace function pg_temp.reconciliation__account_list () returns setof recon_accounts as $$
    SELECT DISTINCT
        coa.accno || ' ' || coa.description as name,
        coa.accno, coa.id as id
    FROM account coa
    JOIN cr_coa_to_account cta ON cta.chart_id = coa.id
    ORDER BY coa.accno;
$$ language sql;

CREATE OR REPLACE FUNCTION reconciliation__add_entry(
    in_report_id INT,
    in_scn TEXT,
    in_type TEXT,
    in_date TIMESTAMP,
    in_amount numeric
) RETURNS INT AS $$

    DECLARE
        in_account int;
        la RECORD;
        t_errorcode INT;
        our_value NUMERIC;
        lid INT;
        in_count int;
        t_scn TEXT;
        t_uid int;
        t_prefix text;
        t_amount numeric;
    BEGIN
        SELECT CASE WHEN a.category in ('A', 'E') THEN in_amount * -1
                                                  ELSE in_amount
               END into t_amount
          FROM cr_report r JOIN account a ON r.chart_id = a.id
         WHERE r.id = in_report_id;

        SELECT value into t_prefix FROM defaults WHERE setting_key = 'check_prefix';

        t_uid := person__get_my_entity_id();
        IF t_uid IS NULL THEN
                t_uid = pg_temp.robot__get_my_entity_id();
        END IF;
        IF in_scn = '' THEN
                t_scn := NULL;
        ELSIF in_scn !~ '^[0-9]+$' THEN
                t_scn := in_scn;
        ELSE
                t_scn := t_prefix || in_scn;
        END IF;
        IF t_scn IS NOT NULL THEN
                -- could this be changed to update, if not found insert?
                SELECT count(*) INTO in_count FROM cr_report_line
                WHERE scn ilike t_scn AND report_id = in_report_id
                        AND their_balance = 0 AND post_date = in_date;

                IF in_count = 0 THEN
                        -- YLA - Where does our_balance comes from?
                        INSERT INTO cr_report_line
                        (report_id, scn, their_balance, our_balance, clear_time,
                                "user", trans_type)
                        VALUES
                        (in_report_id, t_scn, t_amount, 0, in_date, t_uid,
                                in_type)
                        RETURNING id INTO lid;
                ELSIF in_count = 1 THEN
                        SELECT id INTO lid FROM cr_report_line
                        WHERE t_scn = scn AND report_id = in_report_id
                                AND their_balance = 0 AND post_date = in_date;
                        UPDATE cr_report_line
                        SET their_balance = t_amount, clear_time = in_date,
                                cleared = true
                        WHERE id = lid;
                ELSE
                        SELECT count(*) INTO in_count FROM cr_report_line
                        WHERE t_scn ilike scn AND report_id = in_report_id
                                AND our_value = t_amount and their_balance = 0
                                AND post_date = in_date;

                        IF in_count = 0 THEN -- no match among many of values
                                SELECT id INTO lid FROM cr_report_line
                                WHERE t_scn ilike scn
                                      AND report_id = in_report_id
                                      AND post_date = in_date
                                ORDER BY our_balance ASC limit 1;

                                UPDATE cr_report_line
                                SET their_balance = t_amount,
                                        clear_time = in_date,
                                        trans_type = in_type,
                                        cleared = true
                                WHERE id = lid;

                        ELSIF in_count = 1 THEN -- EXECT MATCH
                                SELECT id INTO lid FROM cr_report_line
                                WHERE t_scn = scn AND report_id = in_report_id
                                        AND our_value = t_amount
                                        AND their_balance = 0
                                        AND post_date = in_date;
                                UPDATE cr_report_line
                                SET their_balance = t_amount,
                                        trans_type = in_type,
                                        clear_time = in_date,
                                        cleared = true
                                WHERE id = lid;
                        ELSE -- More than one match
                                SELECT id INTO lid FROM cr_report_line
                                WHERE t_scn ilike scn AND report_id = in_report_id
                                        AND our_value = t_amount
                                        AND post_date = in_date
                                ORDER BY id ASC limit 1;

                                UPDATE cr_report_line
                                SET their_balance = t_amount,
                                        trans_type = in_type,
                                        cleared = true,
                                        clear_time = in_date
                                WHERE id = lid;

                        END IF;
                END IF;
        ELSE -- scn IS NULL, check on amount instead
                SELECT count(*) INTO in_count FROM cr_report_line
                WHERE report_id = in_report_id AND our_balance = t_amount
                        AND their_balance = 0 AND post_date = in_date
                        and scn NOT LIKE t_prefix || '%';

                IF in_count = 0 THEN -- no match
                        INSERT INTO cr_report_line
                        (report_id, scn, their_balance, our_balance, clear_time,
                        "user", trans_type)
                        VALUES
                        (in_report_id, t_scn, t_amount, 0, in_date, t_uid,
                        in_type)
                        RETURNING id INTO lid;
                ELSIF in_count = 1 THEN -- perfect match
                        SELECT id INTO lid FROM cr_report_line
                        WHERE report_id = in_report_id
                                AND our_balance = t_amount
                                AND their_balance = 0
                                AND post_date = in_date
                                AND in_scn NOT LIKE t_prefix || '%';
                        UPDATE cr_report_line SET their_balance = t_amount,
                                        trans_type = in_type,
                                        clear_time = in_date,
                                        cleared = true
                        WHERE id = lid;
                ELSE -- more than one match
                        SELECT min(id) INTO lid FROM cr_report_line
                        WHERE report_id = in_report_id AND our_balance = t_amount
                                AND their_balance = 0 AND post_date = in_date
                                AND scn NOT LIKE t_prefix || '%'
                        LIMIT 1;

                        UPDATE cr_report_line SET their_balance = t_amount,
                                        trans_type = in_type,
                                        clear_time = in_date,
                                        cleared = true
                        WHERE id = lid;

                END IF;
        END IF;
        return lid;

    END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__get_cleared_balance(in_chart_id int,
   in_report_date date DEFAULT date_trunc('second', now()))
RETURNS numeric AS
$$
    SELECT sum(ac.amount_bc) * CASE WHEN c.category in('A', 'E') THEN -1 ELSE 1 END
        FROM account c
        JOIN acc_trans ac ON (ac.chart_id = c.id)
        JOIN transactions t ON t.id = ac.trans_id AND t.approved
    WHERE c.id = $1 AND cleared
      AND ac.approved IS true
      AND ac.transdate <= in_report_date
    GROUP BY c.id, c.category;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION pg_temp.robot__get_my_entity_id() RETURNS INT AS
$$
        SELECT entity_id from users where username = SESSION_USER OR username = 'Migrator';
$$ LANGUAGE SQL;

-- adding mapping info for import.

ALTER TABLE :slschema.vendor ADD COLUMN entity_id int;
ALTER TABLE :slschema.vendor ADD COLUMN company_id int;
ALTER TABLE :slschema.vendor ADD COLUMN credit_id int;

ALTER TABLE :slschema.customer ADD COLUMN entity_id int;
ALTER TABLE :slschema.customer ADD COLUMN company_id int;
ALTER TABLE :slschema.customer ADD COLUMN credit_id int;

-- Speed optimizations
ALTER TABLE :slschema.acc_trans DROP COLUMN IF EXISTS lsmb_entry_id;
ALTER TABLE :slschema.acc_trans ADD COLUMN lsmb_entry_id INTEGER;
ALTER TABLE :slschema.acc_trans ADD COLUMN type CHAR(2);
ALTER TABLE :slschema.acc_trans ADD COLUMN accno TEXT;
ALTER TABLE :slschema.acc_trans ADD transdate_month DATE;
ALTER TABLE :slschema.acc_trans ADD cleared_month DATE;
UPDATE :slschema.acc_trans SET transdate_month = date_trunc('MONTH', transdate)::DATE,
                               cleared_month = date_trunc('MONTH', cleared)::DATE;
CREATE INDEX transdate_month_i ON :slschema.acc_trans USING btree(transdate_month);
CREATE INDEX cleared_month_i ON :slschema.acc_trans USING btree(cleared_month);

update :slschema.acc_trans
  set lsmb_entry_id = nextval('acc_trans_entry_id_seq');

UPDATE :slschema.acc_trans SET type = 'AP'
 WHERE trans_id IN (SELECT id FROM :slschema.ap);
UPDATE :slschema.acc_trans SET type = 'AR'
 WHERE trans_id IN (SELECT id FROM :slschema.ar);
UPDATE :slschema.acc_trans SET type = 'GL'
 WHERE trans_id IN (SELECT id FROM :slschema.gl);
UPDATE :slschema.acc_trans SET accno = (SELECT accno
                           FROM :slschema.chart
                          WHERE chart.id = :slschema.acc_trans.chart_id);

--Accounts

INSERT INTO gifi
SELECT * FROM :slschema.gifi;

insert into account_link_description values ('CT_tax', false, false);

INSERT INTO account_heading(id, accno, description)
SELECT id, accno, description
  FROM :slschema.chart WHERE charttype = 'H';

SELECT pg_temp.account__save(id, accno, description, category,
                    CASE WHEN gifi_accno ~ '^[\s\t]*$' THEN NULL
                    ELSE gifi_accno END, NULL::int,
                    contra,
                    CASE WHEN link like '%tax%' THEN true ELSE false END,
                    string_to_array(link,':'), 'f', 'f')
  FROM :slschema.chart
 WHERE charttype = 'A';

delete from account_link where description = 'CT_tax';

-- Business

INSERT INTO business SELECT * FROM :slschema.business;

--Entity

INSERT INTO entity (name, control_code, entity_class, country_id)
SELECT name, 'V-' || vendornumber, 1,
       (select id from country
         where lower(short_name)  = lower(:default_country))
FROM :slschema.vendor
GROUP BY name, vendornumber;

INSERT INTO entity (name, control_code, entity_class, country_id)
SELECT name, 'C-' || customernumber, 2,
       (select id from country
         where lower(short_name)  =  lower(:default_country))
FROM :slschema.customer
GROUP BY name, customernumber;

INSERT INTO entity (name, control_code, entity_class, country_id)
SELECT 'Migrator', 'R-1', 10, (select id from country
         where lower(short_name)  =  lower(:default_country));

UPDATE :slschema.vendor SET entity_id = (SELECT id FROM entity WHERE 'V-' || vendornumber = control_code);

UPDATE :slschema.customer SET entity_id = coalesce((SELECT min(id) FROM entity WHERE 'C-' || customernumber = control_code), entity_id);

INSERT INTO defaults(setting_key,value)
    SELECT 'curr',curr
    FROM :slschema.curr
    WHERE rn=1;

INSERT INTO currency(curr,description)
    SELECT curr,curr
    FROM  :slschema.curr;

-- Make sure currency table is complete
INSERT INTO currency(curr,description)
    SELECT DISTINCT curr, curr
    FROM (
              SELECT DISTINCT curr FROM :slschema.ar
        UNION SELECT DISTINCT curr FROM :slschema.ap
        UNION SELECT DISTINCT curr FROM :slschema.gl
    ) xx
    WHERE curr IS NOT null
      AND NOT EXISTS (
        SELECT 1 FROM :slschema.curr c
        WHERE c.curr = xx.curr
    );

--Entity Credit Account

UPDATE :slschema.vendor SET business_id = NULL WHERE business_id = 0;
INSERT INTO entity_credit_account
(entity_id, meta_number, business_id, creditlimit, ar_ap_account_id,
        cash_account_id, startdate, enddate, threshold, entity_class, curr)
SELECT entity_id, vendornumber, business_id, creditlimit,
       (select id
          from account
         where accno = coalesce((select accno from :slschema.chart
                                  where id = arap_accno_id) ,:ap)),
        (select id
           from account
           where accno = (select accno from :slschema.chart
                           where id = payment_accno_id)),
         startdate, enddate, threshold, 1, curr
FROM :slschema.vendor WHERE entity_id IS NOT NULL;

UPDATE :slschema.vendor SET credit_id =
        (SELECT id FROM entity_credit_account e
        WHERE e.meta_number = vendornumber and entity_class = 1
        and e.entity_id = vendor.entity_id);

UPDATE :slschema.customer SET business_id = NULL WHERE business_id = 0;
INSERT INTO entity_credit_account
(entity_id, meta_number, business_id, creditlimit, ar_ap_account_id,
        cash_account_id, startdate, enddate, threshold, entity_class, curr)
SELECT entity_id, customernumber, business_id, creditlimit,
       (select id
          from account
         where accno = coalesce((select accno from :slschema.chart
                                  where id = arap_accno_id) ,:ar)),
        (select id
           from account
           where accno = (select accno from :slschema.chart
                           where id = payment_accno_id)),
        startdate, enddate, threshold, 2, curr
FROM :slschema.customer WHERE entity_id IS NOT NULL;

UPDATE :slschema.customer SET credit_id =
        (SELECT id FROM entity_credit_account e
        WHERE e.meta_number = customernumber and entity_class = 2
        and e.entity_id = customer.entity_id);

--Company

INSERT INTO company (entity_id, legal_name, tax_id)
SELECT entity_id, name, max(taxnumber) FROM :slschema.vendor
WHERE entity_id IS NOT NULL AND entity_id IN (select id from entity) GROUP BY entity_id, name;

UPDATE :slschema.vendor SET company_id = (select id from company c where entity_id = vendor.entity_id);

INSERT INTO company (entity_id, legal_name, tax_id)
SELECT entity_id, name, max(taxnumber) FROM :slschema.customer
WHERE entity_id IS NOT NULL AND entity_id IN (select id from entity) GROUP BY entity_id, name;

UPDATE :slschema.customer SET company_id = (select id from company c where entity_id = customer.entity_id);

-- Contact

insert into eca_to_contact (credit_id, contact_class_id, contact,description)
select v.credit_id, 1, v.phone, 'Primary phone: '||max(v.contact) as description
from :slschema.vendor v
where v.company_id is not null and v.phone is not null
       and v.phone ~ '[[:alnum:]_]'::text
group by v.credit_id, v.phone
UNION
select v.credit_id, 12, v.email,
       'email address: '||max(v.contact) as description
from :slschema.vendor v
where v.company_id is not null and v.email is not null
       and v.email ~ '[[:alnum:]_]'::text
group by v.credit_id, v.email
UNION
select v.credit_id, 12, v.cc, 'Carbon Copy email address' as description
from :slschema.vendor v
where v.company_id is not null and v.cc is not null
      and v.cc ~ '[[:alnum:]_]'::text
group by v.credit_id, v.cc
UNION
select v.credit_id, 12, v.bcc, 'Blind Carbon Copy email address' as description
from :slschema.vendor v
where v.company_id is not null and v.bcc is not null
       and v.bcc ~ '[[:alnum:]_]'::text
group by v.credit_id, v.bcc
UNION
    select v.credit_id, 9, v.fax, 'Fax number' as description
from :slschema.vendor v
where v.company_id is not null and v.fax is not null
      and v.fax ~ '[[:alnum:]_]'::text
group by v.credit_id, v.fax;

insert into eca_to_contact (credit_id, contact_class_id, contact,description)
select v.credit_id, 1, v.phone, 'Primary phone: '||max(v.contact) as description
from :slschema.customer v
where v.company_id is not null and v.phone is not null
       and v.phone ~ '[[:alnum:]_]'::text
group by v.credit_id, v.phone
UNION
select v.credit_id, 12, v.email,
       'email address: '||max(v.contact) as description
from :slschema.customer v
where v.company_id is not null and v.email is not null
       and v.email ~ '[[:alnum:]_]'::text
group by v.credit_id, v.email
UNION
select v.credit_id, 12, v.cc, 'Carbon Copy email address' as description
from :slschema.customer v
where v.company_id is not null and v.cc is not null
      and v.cc ~ '[[:alnum:]_]'::text
group by v.credit_id, v.cc
UNION
select v.credit_id, 12, v.bcc, 'Blind Carbon Copy email address' as description
from :slschema.customer v
where v.company_id is not null and v.bcc is not null
       and v.bcc ~ '[[:alnum:]_]'::text
group by v.credit_id, v.bcc
UNION
    select v.credit_id, 9, v.fax, 'Fax number' as description
from :slschema.customer v
where v.company_id is not null and v.fax is not null
      and v.fax ~ '[[:alnum:]_]'::text
group by v.credit_id, v.fax;


-- addresses

INSERT INTO country (id, name, short_name) VALUES (-1, 'Invalid Country', 'XX');

INSERT INTO eca_to_location(credit_id, location_class, location_id)
SELECT eca.id, 1,
    min(pg_temp.location_save(NULL,

    case
        when oa.address1 !~ '[[:alnum:]_]' then 'Null'
        when oa.address1 is null then 'Null'
        else oa.address1
    end,
    oa.address2,
    NULL,
    case
        when oa.city !~ '[[:alnum:]_]' then 'Invalid'
        when oa.city is null then 'Null'
        else oa.city
    end,
    case
        when oa.state !~ '[[:alnum:]_]' then 'Invalid'
        when oa.state is null then 'Null'
        else oa.state
    end,
    case
        when oa.zipcode !~ '[[:alnum:]_]' then 'Invalid'
        when oa.zipcode is null then 'Null'
        else oa.zipcode
    end,
    coalesce(c.id, -1)
    ))
FROM country c
RIGHT OUTER JOIN
     :slschema.address oa
ON
    lower(trim(both ' ' from c.name)) = lower( trim(both ' ' from oa.country))
OR

    lower(trim(both ' ' from c.short_name)) = lower( trim(both ' ' from oa.country))
JOIN (select credit_id, id from :slschema.vendor
          union
           select credit_id, id from :slschema.customer) v ON oa.trans_id = v.id
JOIN entity_credit_account eca ON (v.credit_id = eca.id)
GROUP BY eca.id;

-- Shipto

INSERT INTO eca_to_location(credit_id, location_class, location_id)
SELECT eca.id, 2,
    min(pg_temp.location_save(NULL,

    case
        when oa.shiptoaddress1 !~ '[[:alnum:]_]' then 'Null'
        when oa.shiptoaddress1 is null then 'Null'
        else oa.shiptoaddress1
    end,
    oa.shiptoaddress2,
    NULL,
    case
        when oa.shiptocity !~ '[[:alnum:]_]' then 'Invalid'
        when oa.shiptocity is null then 'Null'
        else oa.shiptocity
    end,
    case
        when oa.shiptostate !~ '[[:alnum:]_]' then 'Invalid'
        when oa.shiptostate is null then 'Null'
        else oa.shiptostate
    end,
    case
        when oa.shiptozipcode !~ '[[:alnum:]_]' then 'Invalid'
        when oa.shiptozipcode is null then 'Null'
        else oa.shiptozipcode
    end,
    coalesce(c.id, -1)
    ))
FROM country c
RIGHT OUTER JOIN
     :slschema.shipto oa
ON
    lower(trim(both ' ' from c.name)) = lower( trim(both ' ' from oa.shiptocountry))
OR

    lower(trim(both ' ' from c.short_name)) = lower( trim(both ' ' from oa.shiptocountry))
JOIN (select credit_id, id from :slschema.vendor
          union
           select credit_id, id from :slschema.customer) v ON oa.trans_id = v.id
JOIN entity_credit_account eca ON (v.credit_id = eca.id)
GROUP BY eca.id;

INSERT INTO eca_note(note_class, ref_key, note, vector)
SELECT 3, credit_id, notes, '' FROM :slschema.vendor
WHERE notes IS NOT NULL AND credit_id IS NOT NULL;

INSERT INTO eca_note(note_class, ref_key, note, vector)
SELECT 3, credit_id, notes, '' FROM :slschema.customer
WHERE notes IS NOT NULL AND credit_id IS NOT NULL;

UPDATE entity SET country_id =
(select country_id FROM location l
   JOIN eca_to_location e2l ON l.id = e2l.location_id
        AND e2l.location_class = 1
   JOIN entity_credit_account eca ON e2l.credit_id = eca.id
  WHERE eca.entity_id = entity_id
        AND l.country_id > -1
  LIMIT 1)
WHERE id IN
(select eca.entity_id FROM location l
   JOIN eca_to_location e2l ON l.id = e2l.location_id
        AND e2l.location_class = 1
   JOIN entity_credit_account eca ON e2l.credit_id = eca.id
  WHERE eca.entity_id = entity_id
       aND l.country_id > -1);

INSERT INTO pricegroup
SELECT * FROM :slschema.pricegroup;

ALTER TABLE :slschema.employee ADD entity_id int;

INSERT INTO entity(control_code, entity_class, name, country_id)
select 'E-' || employeenumber, 3, name,
        (select id from country where lower(short_name) = lower(:default_country))
FROM :slschema.employee;

UPDATE :slschema.employee set entity_id =
       (select id from entity where 'E-'||employeenumber = control_code);

INSERT INTO person (first_name, last_name, entity_id)
SELECT name, name, entity_id FROM :slschema.employee;

INSERT INTO robot  (first_name, last_name, entity_id)
SELECT '', name, id
FROM entity
WHERE entity_class = 10 AND control_code = 'R-1';

-- users in SL2.8 have to be re-created using the 1.4 user interface
-- Intentionally do *not* migrate the users table to prevent later conflicts
--INSERT INTO users (entity_id, username)
--     SELECT entity_id, login FROM :slschema.employee em
--      WHERE login IS NOT NULL;

INSERT INTO entity_employee(entity_id, startdate, enddate, role, ssn, sales,
            employeenumber, dob, manager_id)
    SELECT entity_id, startdate, enddate, r.description, ssn, sales,
       employeenumber, dob,
       (SELECT entity_id FROM :slschema.employee WHERE id = em.acsrole_id)
    FROM :slschema.employee em
    LEFT JOIN :slschema.acsrole r ON em.acsrole_id = r.id;

-- must rebuild this table due to changes since 1.2

INSERT INTO partsgroup (id, partsgroup) SELECT id, partsgroup FROM :slschema.partsgroup;

INSERT INTO parts (id, partnumber, description, unit,
listprice, sellprice, lastcost, priceupdate, weight, onhand, notes,
makemodel, assembly, alternate, rop, inventory_accno_id,
income_accno_id, expense_accno_id, bin, obsolete, bom, image,
drawing, microfiche, partsgroup_id, avgcost)
 SELECT id, partnumber, description, unit,
listprice, sellprice, lastcost, priceupdate, weight, onhand, notes,
makemodel, assembly, alternate, rop, (select id
          from account
         where accno = (select accno from :slschema.chart
                         where id = inventory_accno_id)),
(select id
          from account
         where accno = (select accno from :slschema.chart
                         where id = income_accno_id)), (select id
          from account
         where accno = (select accno from :slschema.chart
                         where id = expense_accno_id)),
 bin, obsolete, bom, image,
drawing, microfiche, partsgroup_id, avgcost FROM :slschema.parts;


INSERT INTO makemodel (parts_id, make, model)
SELECT parts_id, make, model FROM :slschema.makemodel;

/* TODO -- can't be solved this easily: a freshly created defaults
table contains 30 keys, one after having saved the System->Defaults
screen contains 58. Also, there are account IDs here, which should
be migrated using queries, not just copied over.

To watch out for: keys which are semantically the same, but have
different names

UPDATE defaults
   SET value = (select fldvalue from :slschema.defaults src
                 WHERE src.fldname = defaults.setting_key)
 WHERE setting_key IN (select fldvalue FROM :slschema.defaults
                        where );
*/
/* May have to move this downward*/

CREATE OR REPLACE FUNCTION pg_temp.f_insert_default(skey varchar(20),slname varchar(20)) RETURNS VOID AS
$$
BEGIN
    UPDATE defaults SET value = (
        SELECT fldvalue FROM "[% slschema %]".defaults AS def
        WHERE def.fldname = slname
    )
    WHERE setting_key = skey AND value IS NULL;
    INSERT INTO defaults (setting_key, value)
        SELECT skey,fldvalue FROM "[% slschema %]".defaults AS def
        WHERE def.fldname = slname
        AND NOT EXISTS ( SELECT 1 FROM defaults WHERE setting_key = skey);
END
$$
  LANGUAGE 'plpgsql';

SELECT pg_temp.f_insert_default('company_name','company');
SELECT pg_temp.f_insert_default('company_address','address');
SELECT pg_temp.f_insert_default('company_fax','fax');
SELECT pg_temp.f_insert_default('company_phone','tel');
SELECT pg_temp.f_insert_default('audittrail','audittrail');
SELECT pg_temp.f_insert_default('businessnumber','businessnumber');
SELECT pg_temp.f_insert_default('decimal_places','precision');
SELECT pg_temp.f_insert_default('weightunit','weightunit');
-- Should we count the actual transferred entries instead?
CREATE OR REPLACE FUNCTION pg_temp.f_insert_count(slname varchar(20)) RETURNS VOID AS
$$
BEGIN
    UPDATE defaults SET value = (
        SELECT fldvalue FROM "[% slschema %]".defaults AS def
        WHERE def.fldname = slname
    )
    WHERE setting_key = slname AND (value IS NULL OR value = '1');
    INSERT INTO defaults (setting_key, value)
        SELECT fldname,fldvalue FROM "[% slschema %]".defaults AS def
        WHERE def.fldname = slname
        AND NOT EXISTS ( SELECT 1 FROM defaults WHERE setting_key = slname);
END
$$
  LANGUAGE 'plpgsql';

SELECT pg_temp.f_insert_count('customernumber');
SELECT pg_temp.f_insert_count('employeenumber');
SELECT pg_temp.f_insert_count('glnumber');
SELECT pg_temp.f_insert_count('partnumber');
SELECT pg_temp.f_insert_count('partnumber');
SELECT pg_temp.f_insert_count('projectnumber');
SELECT pg_temp.f_insert_count('rfqnumber');
SELECT pg_temp.f_insert_count('sinumber');
SELECT pg_temp.f_insert_count('sonumber');
SELECT pg_temp.f_insert_count('sqnumber');
SELECT pg_temp.f_insert_count('vendornumber');
SELECT pg_temp.f_insert_count('vinumber');

CREATE OR REPLACE FUNCTION pg_temp.f_insert_account(skey varchar(20)) RETURNS VOID AS
$$
BEGIN
    UPDATE defaults SET value = (
        SELECT id FROM account
        WHERE account.accno IN (
            SELECT accno FROM "[% slschema %]".chart
            WHERE id = ( SELECT CAST(fldvalue AS INT) FROM "[% slschema %]".defaults WHERE fldname = skey ))
    )
    WHERE setting_key = skey AND value IS NULL;
    INSERT INTO defaults (setting_key, value)
        SELECT skey,id FROM account
        WHERE account.accno IN (
            SELECT accno FROM "[% slschema %]".chart
            WHERE id = ( SELECT CAST(fldvalue AS INT) FROM "[% slschema %]".defaults WHERE fldname = skey ))
        AND NOT EXISTS ( SELECT value FROM defaults WHERE setting_key = skey);
END
$$
  LANGUAGE 'plpgsql';

SELECT pg_temp.f_insert_account('inventory_accno_id');
SELECT pg_temp.f_insert_account('income_accno_id');
SELECT pg_temp.f_insert_account('expense_accno_id');
SELECT pg_temp.f_insert_account('fxgain_accno_id');
SELECT pg_temp.f_insert_account('fxloss_accno_id');
-- = ":slschema.cashovershort_accno_id" ?
-- "earn_id" = ?

INSERT INTO assembly (id, parts_id, qty, bom, adj)
SELECT id, parts_id, qty, bom, adj  FROM :slschema.assembly;

INSERT INTO business_unit (id, class_id, control_code, description)
SELECT id, 1, id, description
  FROM :slschema.department;
UPDATE business_unit_class
   SET active = true
 WHERE id = 1
   AND EXISTS (select 1 from :slschema.department);

INSERT INTO business_unit (id, class_id, control_code, description,
       start_date, end_date, credit_id)
SELECT 1000+id, 2, projectnumber, description, startdate, enddate,
       (select credit_id
          from :slschema.customer c
         where c.id = p.customer_id)
  FROM :slschema.project p;
UPDATE business_unit_class
   SET active = true
 WHERE id = 2
   AND EXISTS (select 1 from :slschema.project);

INSERT INTO gl(id, reference, description, transdate, person_id, notes)
    SELECT gl.id, reference, description, transdate, p.id, gl.notes
      FROM :slschema.gl
 LEFT JOIN :slschema.employee em ON gl.employee_id = em.id
 LEFT JOIN person p ON em.entity_id = p.id;

--TODO: Handle amount_tc and netamount_tc
insert into ar
        (entity_credit_account, person_id,
        id, invnumber, transdate, crdate, taxincluded,
        amount_bc, netamount_bc,
        amount_tc, netamount_tc,
        duedate, invoice, ordnumber, curr, notes, quonumber, intnotes,
        shipvia, language_code, ponumber, shippingpoint,
        on_hold, approved, reverse, terms, description)
SELECT
        customer.credit_id,
        (select entity_id from :slschema.employee WHERE id = ar.employee_id),
        ar.id, invnumber, transdate, transdate, ar.taxincluded, amount, netamount,
        CASE WHEN exchangerate IS NOT NULL THEN amount/exchangerate ELSE amount END,
        CASE WHEN exchangerate IS NOT NULL THEN netamount/exchangerate ELSE netamount END,
        duedate, invoice, ordnumber, ar.curr, ar.notes, quonumber, intnotes,
        shipvia, ar.language_code, ponumber, shippingpoint,
        onhold, approved, case when amount < 0 then true else false end,
        ar.terms, description
FROM :slschema.ar
JOIN :slschema.customer ON (ar.customer_id = customer.id) ;

insert into ap
(entity_credit_account, person_id,
        id, invnumber, transdate, crdate, taxincluded, amount_bc, netamount_bc,
        amount_tc, netamount_tc,
        duedate, invoice, ordnumber, curr, notes, quonumber, intnotes,
        shipvia, language_code, ponumber, shippingpoint,
        on_hold, approved, reverse, terms, description)
SELECT
        vendor.credit_id,
        (select entity_id from :slschema.employee
                WHERE id = ap.employee_id),
        ap.id, invnumber, transdate, transdate, ap.taxincluded, amount, netamount,
        CASE WHEN exchangerate IS NOT NULL THEN amount/exchangerate ELSE amount END,
        CASE WHEN exchangerate IS NOT NULL THEN netamount/exchangerate ELSE netamount END,
        duedate, invoice, ordnumber,
        CASE WHEN exchangerate IS NOT NULL THEN ap.curr ELSE NULL END,
        ap.notes, quonumber, intnotes,
        shipvia, ap.language_code, ponumber, shippingpoint,
        onhold, approved, case when amount < 0 then true else false end,
        ap.terms, description
FROM :slschema.ap JOIN :slschema.vendor ON (ap.vendor_id = vendor.id) ;

-- ### TODO: there used to be projects here!
-- ### Move those to business_units

INSERT INTO invoice (id, trans_id, parts_id, description, qty, allocated,
            sellprice, fxsellprice, discount, assemblyitem, unit,
            deliverydate, serialnumber)
    SELECT  id, trans_id, parts_id, description, qty, allocated,
            sellprice, fxsellprice, discount, assemblyitem, unit,
            deliverydate, serialnumber
       FROM :slschema.invoice;

ALTER TABLE :slschema.acc_trans ADD COLUMN lsmb_entry_id integer;

update :slschema.acc_trans
  set lsmb_entry_id = nextval('acc_trans_entry_id_seq');

INSERT INTO acc_trans (entry_id, trans_id, chart_id, amount_bc, amount_tc, curr,
                       transdate, source, cleared,
                       memo, approved, cleared_on, voucher_id, invoice_id)
 SELECT lsmb_entry_id, ac.trans_id,
        (select id
           from account
          where accno = (select accno
                           from :slschema.chart
                          where chart.id = ac.chart_id)),
        ac.amount, ac.amount / coalesce(y.exchangerate, xx.exchangerate, 1),
        xx.curr,
        transdate, source,
        CASE WHEN cleared IS NOT NULL THEN TRUE ELSE FALSE END,
        memo, approved, cleared, vr_id, invoice.id
   FROM :slschema.acc_trans ac
   JOIN (
                    SELECT id,exchangerate,curr
                    FROM (      SELECT id,exchangerate,curr FROM :slschema.ap
                          UNION SELECT id,exchangerate,curr FROM :slschema.ar
                          UNION SELECT id,exchangerate,curr FROM :slschema.gl) xx
   ) xx ON xx.id=ac.trans_id
   LEFT JOIN :slschema.invoice ON ac.id = invoice.id
                              AND ac.trans_id = invoice.trans_id
 LEFT JOIN :slschema.payment y ON (y.trans_id = ac.trans_id AND ac.id = y.id)
 WHERE chart_id IS NOT NULL
    AND ac.trans_id IN (SELECT id FROM transactions);

--Payments

CREATE OR REPLACE FUNCTION pg_temp.payment_migrate
(in_id                            int,      -- Payment id
 in_trans_id                      int,      -- Transaction id
 in_exchangerate                  numeric,  -- Exchange rate
 in_paymentmethod_id              int)      -- Payment method
RETURNS INT AS $$
    DECLARE var_payment_id int;
    DECLARE var_employee int;
    DECLARE var_account_class int;
    DECLARE var_datepaid date;
    DECLARE var_curr char(3);
    DECLARE var_notes text;
    DECLARE var_source text[];
    DECLARE var_memo text[];
    DECLARE var_lsmb_entry_id int;
    DECLARE var_entity_credit_account int;
BEGIN
    var_account_class = 1; -- AP

    SELECT INTO var_employee p.id
    FROM users u
    JOIN person p ON (u.entity_id=p.entity_id)
    WHERE username = SESSION_USER LIMIT 1;

    SELECT sl_ac.transdate, sl_ac.source, sl_ac.lsmb_entry_id,
           ap.entity_credit_account
    INTO var_datepaid, var_notes, var_lsmb_entry_id,
         var_entity_credit_account
    FROM [% slschema %].payment sl_p
    JOIN [% slschema %].acc_trans sl_ac ON (sl_p.trans_id = sl_ac.trans_id AND sl_p.id=sl_ac.id)
    JOIN [% slschema %].chart sl_c on (sl_c.id = sl_ac.chart_id)
    JOIN acc_trans ac ON ac.entry_id = sl_ac.lsmb_entry_id
    JOIN ap ON ap.id=ac.trans_id
    WHERE sl_c.link ~ 'AP' AND link ~ 'paid'
    AND sl_ac.trans_id=in_trans_id
    AND sl_ac.id=in_id;

    -- Handle regular transaction
    INSERT INTO payment (reference, payment_class, payment_date,
                         employee_id, currency, notes, entity_credit_id)
    VALUES (pg_temp.setting_increment('paynumber'),
            var_account_class, var_datepaid, var_employee,
            var_curr, var_notes, var_entity_credit_account);
    SELECT currval('payment_id_seq') INTO var_payment_id; -- WE'LL NEED THIS VALUE TO USE payment_link table

    INSERT INTO payment_links
    VALUES (var_payment_id, var_lsmb_entry_id, 1);

    RETURN var_payment_id;
END;
$$ LANGUAGE PLPGSQL;

SELECT pg_temp.payment_migrate(p.id, p.trans_id, cast(p.exchangerate as numeric), p.paymentmethod_id)
FROM :slschema.payment p;

-- Reconciliations
-- Serially reuseable
INSERT INTO cr_coa_to_account(chart_id, account)
SELECT DISTINCT pc.id, c.description FROM :slschema.acc_trans ac
JOIN :slschema.chart c ON ac.chart_id = c.id
JOIN account pc on pc.accno = c.accno
WHERE ac.cleared IS NOT NULL
AND c.link ~ 'paid'
AND NOT EXISTS (SELECT 1 FROM cr_coa_to_account WHERE chart_id=pc.id);

-- Log in the Migrator Robot
INSERT INTO users(username, notify_password, entity_id)
SELECT last_name, '1 day', entity_id
FROM robot
WHERE last_name = 'Migrator';

-- Compute last day of the month
CREATE OR REPLACE FUNCTION pg_temp.last_day(DATE)
RETURNS DATE AS
$$
  SELECT (date_trunc('MONTH', $1) + INTERVAL '1 MONTH - 1 day')::DATE;
$$ LANGUAGE 'sql' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION PG_TEMP.is_cleared(clear_time DATE,end_date DATE) RETURNS BOOLEAN LANGUAGE PLPGSQL IMMUTABLE AS $$
BEGIN
  RETURN CASE WHEN $1::DATE IS NOT NULL AND $1 <= $2 THEN TRUE ELSE FALSE END;
EXCEPTION WHEN OTHERS THEN
  RETURN FALSE;
END;$$;

-- The computation of their_total is wrong at this time
INSERT INTO cr_report(chart_id, their_total, submitted, end_date, updated, entered_by, entered_username)
  SELECT coa.id, 0, TRUE,
            a.end_date,max(a.updated),
            (SELECT entity_id FROM robot WHERE last_name = 'Migrator'),
            'Migrator'
        FROM (
          SELECT chart_id,
                 cleared,fx_transaction,approved,transdate,pg_temp.last_day(transdate) as end_date,
                 coalesce(cleared,transdate) as updated, amount
          FROM :slschema.acc_trans
          WHERE (
            cleared IS NOT NULL
            AND chart_id IN (
              SELECT DISTINCT chart_id FROM :slschema.acc_trans ac
              JOIN :slschema.chart c ON ac.chart_id = c.id
              WHERE ac.cleared IS NOT NULL
              AND c.link ~ 'paid'
            ) OR transdate > (
              SELECT MAX(cleared) FROM :slschema.acc_trans
            )
          )
        ) a
        JOIN :slschema.chart s ON chart_id=s.id
        JOIN pg_temp.reconciliation__account_list() coa ON coa.accno=s.accno
        GROUP BY coa.id, a.end_date
        ORDER BY coa.id, a.end_date;

-- cr_report_line will insert the entry and return the ID of the upsert entry.
-- The ID and matching post_date are entered in a temp table to pull the back into cr_report_line immediately after.
-- Temp table will be dropped automatically at the end of the transaction.
WITH cr_entry AS (
SELECT cr.id::INT, cr.end_date, a.source, a.type, a.cleared::TIMESTAMP, a.amount::NUMERIC, a.transdate AS post_date, a.lsmb_entry_id
    FROM cr_coa_to_account cta
    JOIN account c on cta.chart_id = c.id
    JOIN cr_report cr ON cr.chart_id = c.id
    JOIN :slschema.acc_trans a ON c.accno=a.accno
   WHERE a.type IS NOT NULL
     AND ( a.cleared IS NOT NULL OR a.transdate > (SELECT MAX(cleared) FROM :slschema.acc_trans))
     AND a.transdate_month <= date_trunc('MONTH', cr.end_date)::DATE
     AND a.cleared_month   >= date_trunc('MONTH', cr.end_date)::DATE
ORDER BY post_date,cr.id,a.type,a.source ASC NULLS LAST,a.amount
)
SELECT reconciliation__add_entry(id, source, type, cleared, amount) AS id, cr_entry.end_date, cr_entry.post_date, cr_entry.lsmb_entry_id
INTO TEMPORARY _cr_report_line
FROM cr_entry;

UPDATE cr_report_line cr SET post_date = cr1.post_date,
                             ledger_id = cr1.lsmb_entry_id,
                             cleared = pg_temp.is_cleared(clear_time,cr1.end_date),
                             insert_time = date_trunc('second',cr1.post_date),
                             our_balance = their_balance
FROM (
  SELECT id,post_date,end_date,lsmb_entry_id
  FROM _cr_report_line
) cr1
WHERE cr.id = cr1.id;

-- Patch their_total, now that we have all the data in cr_report_line
UPDATE cr_report SET their_total=reconciliation__get_cleared_balance(cr.chart_id,cr.end_date)
FROM (
    SELECT id, chart_id, end_date
    FROM cr_report
) cr WHERE cr_report.id = cr.id;

-- Patch for suspect clear dates
-- The UI should reflect this
-- Unsubmit the suspect report to allow easy edition
UPDATE cr_report SET submitted = false
WHERE id IN (
    SELECT DISTINCT report_id FROM cr_report_line
    WHERE clear_time - post_date > 150
);
-- Approve valid reports.
UPDATE cr_report SET approved = true
WHERE submitted;

-- Log out the Migrator
DELETE FROM users
WHERE username = 'Migrator';

INSERT INTO business_unit_ac (entry_id, class_id, bu_id)
SELECT ac.entry_id, 1, gl.department_id
  FROM acc_trans ac
  JOIN (SELECT id, department_id FROM :slschema.ar UNION ALL
        SELECT id, department_id FROM :slschema.ap UNION ALL
        SELECT id, department_id FROM :slschema.gl) gl ON gl.id = ac.trans_id
 WHERE department_id > 0;

INSERT INTO business_unit_ac (entry_id, class_id, bu_id)
SELECT ac.entry_id, 2, slac.project_id+1000
  FROM acc_trans ac
  JOIN :slschema.acc_trans slac ON slac.lsmb_entry_id = ac.entry_id
 WHERE project_id > 0;

INSERT INTO business_unit_inv (entry_id, class_id, bu_id)
SELECT inv.id, 1, gl.department_id
  FROM invoice inv
  JOIN (SELECT id, department_id FROM :slschema.ar UNION ALL
        SELECT id, department_id FROM :slschema.ap UNION ALL
        SELECT id, department_id FROM :slschema.gl) gl ON gl.id = inv.trans_id
 WHERE department_id > 0;

INSERT INTO business_unit_inv (entry_id, class_id, bu_id)
SELECT id, 2, project_id + 1000 FROM :slschema.invoice
 WHERE project_id > 0 and  project_id in (select id from :slschema.project);

INSERT INTO partstax (parts_id, chart_id)
     SELECT parts_id, a.id
       FROM :slschema.partstax pt
       JOIN :slschema.chart ON chart.id = pt.chart_id
       JOIN account a ON chart.accno = a.accno;

INSERT INTO tax(chart_id, rate, taxnumber, validto, pass, taxmodule_id)
     SELECT a.id, t.rate, t.taxnumber,
            coalesce(t.validto::timestamp, 'infinity'), 1, 1
       FROM :slschema.tax t
       JOIN :slschema.chart c ON (t.chart_id = c.id)
       JOIN account a ON (a.accno = c.accno);

INSERT INTO eca_tax (eca_id, chart_id)
  SELECT c.credit_id, (select id from account
                      where accno = (select accno from :slschema.chart sc
                                      where sc.id = ct.chart_id))
   FROM :slschema.customertax ct
   JOIN :slschema.customer c
     ON ct.customer_id = c.id
  UNION
  SELECT v.credit_id, (select id from account
                      where accno = (select accno from :slschema.chart sc
                                      where sc.id = vt.chart_id))
   FROM :slschema.vendortax vt
   JOIN :slschema.vendor v
     ON vt.vendor_id = v.id;

INSERT
  INTO oe(id, ordnumber, transdate, amount_tc, netamount_tc, reqdate, taxincluded,
       shippingpoint, notes, curr, person_id, closed, quotation, quonumber,
       intnotes, shipvia, language_code, ponumber, terms,
       entity_credit_account, oe_class_id)
SELECT oe.id,  ordnumber, transdate, amount, netamount, reqdate, oe.taxincluded,
       shippingpoint, oe.notes, oe.curr, p.id, closed, quotation, quonumber,
       intnotes, shipvia, oe.language_code, ponumber, oe.terms,
       coalesce(c.credit_id, v.credit_id),
       case
           when c.id is not null and quotation is not true THEN 1
           WHEN v.id is not null and quotation is not true THEN 2
           when c.id is not null and quotation is true THEN 3
           WHEN v.id is not null and quotation is true THEN 4
       end
  FROM :slschema.oe
  LEFT JOIN :slschema.customer c ON c.id = oe.customer_id
  LEFT JOIN :slschema.vendor v ON v.id = oe.vendor_id
  LEFT JOIN :slschema.employee e ON oe.employee_id = e.id
  LEFT JOIN person p ON e.entity_id = p.id;

INSERT INTO orderitems(id, trans_id, parts_id, description, qty, sellprice,
            discount, unit, reqdate, ship, serialnumber)
     SELECT id, trans_id, parts_id, description, qty, sellprice,
            discount, unit, reqdate, ship, serialnumber
       FROM :slschema.orderitems;

INSERT INTO business_unit_oitem (entry_id, class_id, bu_id)
SELECT oi.id, 1, oe.department_id
  FROM orderitems oi
  JOIN :slschema.oe ON oi.trans_id = oe.id AND department_id > 0;

INSERT INTO business_unit_oitem (entry_id, class_id, bu_id)
SELECT id, 2, project_id + 1000 FROM :slschema.orderitems
 WHERE project_id > 0  and  project_id in (select id from :slschema.project);

INSERT INTO status SELECT * FROM :slschema.status; -- may need to comment this one out sometimes

INSERT INTO sic SELECT * FROM :slschema.sic;

INSERT INTO warehouse SELECT * FROM :slschema.warehouse;

INSERT INTO warehouse_inventory(entity_id, warehouse_id, parts_id, trans_id,
            orderitems_id, qty, shippingdate)
     SELECT e.entity_id, warehouse_id, parts_id, trans_id,
            orderitems_id, qty, shippingdate
       FROM :slschema.inventory i
       JOIN :slschema.employee e ON i.employee_id = e.id;

INSERT INTO yearend (trans_id, transdate)
  SELECT * FROM :slschema.yearend
   WHERE :slschema.yearend.trans_id IN (SELECT id FROM gl);

INSERT INTO partsvendor(credit_id, parts_id, partnumber, leadtime, lastcost,
            curr)
     SELECT v.credit_id, parts_id, partnumber, leadtime, lastcost,
            pv.curr
       FROM :slschema.partsvendor pv
       JOIN :slschema.vendor v ON v.id = pv.vendor_id;

INSERT INTO partscustomer(parts_id, credit_id, pricegroup_id, pricebreak,
            sellprice, validfrom, validto, curr)
     SELECT parts_id, credit_id, pv.pricegroup_id, pricebreak,
            sellprice, validfrom, validto, pv.curr
       FROM :slschema.partscustomer pv
       JOIN :slschema.customer v ON v.id = pv.customer_id
      WHERE pv.pricegroup_id <> 0;

INSERT INTO language
SELECT OVERLAY(code PLACING LOWER(SUBSTRING(code FROM '^..')) FROM 1 FOR 2 ) AS code,description FROM :slschema.language sllang
 WHERE NOT EXISTS (SELECT 1
                     FROM language l WHERE l.code = OVERLAY(sllang.code PLACING LOWER(SUBSTRING(sllang.code FROM '^..')) FROM 1 FOR 2 ));

INSERT INTO audittrail(trans_id, tablename, reference, formname, action,
            transdate, person_id)
     SELECT trans_id, tablename, reference, formname, action,
            transdate, p.entity_id
       FROM :slschema.audittrail a
       JOIN :slschema.employee e ON a.employee_id = e.id
       JOIN person p on e.entity_id = p.entity_id;

INSERT INTO user_preference(id)
     SELECT id from users;

INSERT INTO recurring(id, reference, startdate, nextdate, enddate,
            recurring_interval, howmany, payment)
     SELECT id, reference, startdate, nextdate, enddate,
            (repeat || ' ' || unit)::interval,
            howmany, payment
       FROM :slschema.recurring;

INSERT INTO recurringemail SELECT * FROM :slschema.recurringemail;

INSERT INTO recurringprint SELECT * FROM :slschema.recurringprint;

INSERT INTO jcitems(id, parts_id, description, qty, total, allocated,
            sellprice, fxsellprice, serialnumber, checkedin, checkedout,
            person_id, notes, business_unit_id, jctype, curr)
     SELECT j.id,  j.parts_id, j.description, qty, qty*sellprice, allocated,
            sellprice, fxsellprice, serialnumber, checkedin, checkedout,
            p.id, j.notes, j.project_id+1000, 1,
            CASE WHEN curr IS NOT NULL
                                 THEN curr
                                 ELSE (SELECT curr FROM :slschema.curr WHERE rn=1)
                        END
       FROM :slschema.jcitems j
       JOIN :slschema.employee e ON j.employee_id = e.id
       JOIN person p ON e.entity_id = p.entity_id
  LEFT JOIN :slschema.project pr on (pr.id = j.project_id)
  LEFT JOIN :slschema.customer c on (c.id = pr.customer_id);

INSERT INTO parts_translation SELECT * FROM :slschema.translation where trans_id in (select id from parts);

INSERT INTO partsgroup_translation SELECT * FROM :slschema.translation where trans_id in
 (select id from partsgroup);

--  ### TODO: To translate to business_units
-- INSERT INTO project_translation SELECT * FROM :slschema.translation where trans_id in
--  (select id from project);

SELECT setval('id', max(id)) FROM transactions;

SELECT setval('acc_trans_entry_id_seq', max(entry_id)) FROM acc_trans;
SELECT setval('partsvendor_entry_id_seq', max(entry_id)) FROM partsvendor;
SELECT setval('warehouse_inventory_entry_id_seq', max(entry_id)) FROM warehouse_inventory;
SELECT setval('partscustomer_entry_id_seq', max(entry_id)) FROM partscustomer;
SELECT setval('audittrail_entry_id_seq', max(entry_id)) FROM audittrail;
SELECT setval('account_id_seq', max(id)) FROM account;
SELECT setval('account_heading_id_seq', max(id)) FROM account_heading;
SELECT setval('account_checkpoint_id_seq', max(id)) FROM account_checkpoint;
SELECT setval('pricegroup_id_seq', max(id)) FROM pricegroup;
SELECT setval('country_id_seq', max(id)) FROM country;
SELECT setval('country_tax_form_id_seq', max(id)) FROM country_tax_form;
SELECT setval('asset_dep_method_id_seq', max(id)) FROM asset_dep_method;
SELECT setval('asset_class_id_seq', max(id)) FROM asset_class;
SELECT setval('entity_class_id_seq', max(id)) FROM entity_class;
SELECT setval('asset_item_id_seq', max(id)) FROM asset_item;
SELECT setval('asset_disposal_method_id_seq', max(id)) FROM asset_disposal_method;
SELECT setval('users_id_seq', max(id)) FROM users;
SELECT setval('entity_id_seq', max(id)) FROM entity;
SELECT setval('company_id_seq', max(id)) FROM company;
SELECT setval('location_id_seq', max(id)) FROM location;
SELECT setval('location_class_id_seq', max(id)) FROM location_class;
SELECT setval('asset_report_id_seq', max(id)) FROM asset_report;
SELECT setval('salutation_id_seq', max(id)) FROM salutation;
SELECT setval('person_id_seq', max(id)) FROM person;
SELECT setval('contact_class_id_seq', max(id)) FROM contact_class;
SELECT setval('entity_credit_account_id_seq', max(id)) FROM entity_credit_account;
SELECT setval('entity_bank_account_id_seq', max(id)) FROM entity_bank_account;
SELECT setval('note_class_id_seq', max(id)) FROM note_class;
SELECT setval('note_id_seq', max(id)) FROM note;
SELECT setval('batch_class_id_seq', max(id)) FROM batch_class;
SELECT setval('batch_id_seq', max(id)) FROM batch;
SELECT setval('invoice_id_seq', max(id)) FROM invoice;
SELECT setval('voucher_id_seq', max(id)) FROM voucher;
SELECT setval('parts_id_seq', max(id)) FROM parts;
SELECT setval('taxmodule_taxmodule_id_seq', max(taxmodule_id)) FROM taxmodule;
SELECT setval('taxcategory_taxcategory_id_seq', max(taxcategory_id)) FROM taxcategory;
SELECT setval('oe_id_seq', max(id)) FROM oe;
SELECT setval('orderitems_id_seq', max(id)) FROM orderitems;
SELECT setval('business_id_seq', max(id)) FROM business;
SELECT setval('warehouse_id_seq', max(id)) FROM warehouse;
SELECT setval('partsgroup_id_seq', max(id)) FROM partsgroup;
SELECT setval('jcitems_id_seq', max(id)) FROM jcitems;
SELECT setval('payment_type_id_seq', max(id)) FROM payment_type;
SELECT setval('menu_node_id_seq', max(id)) FROM menu_node;
SELECT setval('menu_attribute_id_seq', max(id)) FROM menu_attribute;
SELECT setval('menu_acl_id_seq', max(id)) FROM menu_acl;
-- SELECT setval('pending_job_id_seq', max(id)) FROM pending_job;
SELECT setval('new_shipto_id_seq', max(id)) FROM new_shipto;
SELECT setval('payment_id_seq', max(id)) FROM payment;
SELECT setval('cr_report_id_seq', max(id)) FROM cr_report;
SELECT setval('cr_report_line_id_seq', max(id)) FROM cr_report_line;
SELECT setval('business_unit_id_seq', max(id)) FROM business_unit;

--UPDATE defaults SET value = (
--    SELECT MAX(CAST(???number AS NUMERIC))+1 FROM :slschema.??? WHERE ???number ~ '^[0-9]+$'
--) WHERE setting_key = 'rcptnumber';

--UPDATE defaults SET value = (
--    SELECT MAX(CAST(???number AS NUMERIC))+1 FROM :slschema.??? WHERE ???number ~ '^[0-9]+$'
--) WHERE setting_key = 'rfqnumber';

--UPDATE defaults SET value = (
--    SELECT MAX(CAST(???number AS NUMERIC))+1 FROM :slschema.??? WHERE ???number ~ '^[0-9]+$'
--) WHERE setting_key = 'paynumber';

UPDATE defaults SET value = 'yes' where setting_key = 'migration_ok';

COMMIT;
--TODO:  Translation migration.  Partsgroups?
--TODO:  User/password Migration
