--Setup

\set default_country '''us'''
\set ar '''1200'''
\set ap '''2100'''

\i sql/modules/Setting.sql
\i sql/modules/Location.sql
\i sql/modules/Account.sql

BEGIN;

-- adding mapping info for import.

ALTER TABLE lsmb12.vendor ADD COLUMN entity_id int;
ALTER TABLE lsmb12.vendor ADD COLUMN company_id int;
ALTER TABLE lsmb12.vendor ADD COLUMN credit_id int;

ALTER TABLE lsmb12.customer ADD COLUMN entity_id int;
ALTER TABLE lsmb12.customer ADD COLUMN company_id int;
ALTER TABLE lsmb12.customer ADD COLUMN credit_id int;

--Entity

INSERT INTO entity (name, control_code, entity_class, country_id)
SELECT name, 'V-' || vendornumber, 1, 
       (select id from country 
         where lower(short_name)  = :default_country)
FROM lsmb12.vendor
GROUP BY name, vendornumber;

INSERT INTO entity (name, control_code, entity_class, country_id)
SELECT name, 'C-' || customernumber, 2, 
       (select id from country 
         where lower(short_name)  =  :default_country)
FROM lsmb12.customer
GROUP BY name, customernumber;

UPDATE lsmb12.vendor SET entity_id = (SELECT id FROM entity WHERE 'V-' || vendornumber = control_code);

UPDATE lsmb12.customer SET entity_id = coalesce((SELECT min(id) FROM entity WHERE 'C-' || customernumber = control_code), entity_id);

--Entity Credit Account

INSERT INTO entity_credit_account
(entity_id, meta_number, business_id, creditlimit, ar_ap_account_id, 
	cash_account_id, startdate, enddate, threshold, entity_class)
SELECT entity_id, vendornumber, business_id, creditlimit, 
       (select id from account where accno = :ap), 
	NULL, startdate, enddate, 0, 1
FROM lsmb12.vendor WHERE entity_id IS NOT NULL;

UPDATE lsmb12.vendor SET credit_id = 
	(SELECT id FROM entity_credit_account e 
	WHERE e.meta_number = vendornumber);


INSERT INTO entity_credit_account
(entity_id, meta_number, business_id, creditlimit, ar_ap_account_id, 
	cash_account_id, startdate, enddate, threshold, entity_class)
SELECT entity_id, customernumber, business_id, creditlimit,
       (select id from account where accno = :ar),
	NULL, startdate, enddate, 0, 2
FROM lsmb12.customer WHERE entity_id IS NOT NULL;

UPDATE lsmb12.customer SET credit_id = 
	(SELECT id FROM entity_credit_account e 
	WHERE e.meta_number = customernumber AND customer.entity_id = e.entity_id);

--Company

INSERT INTO company (entity_id, legal_name, tax_id)
SELECT entity_id, name, max(taxnumber) FROM lsmb12.vendor 
WHERE entity_id IS NOT NULL AND entity_id IN (select id from entity) GROUP BY entity_id, name;

UPDATE lsmb12.vendor SET company_id = (select id from company c where entity_id = vendor.entity_id);

INSERT INTO company (entity_id, legal_name, tax_id)
SELECT entity_id, name, max(taxnumber) FROM lsmb12.customer
WHERE entity_id IS NOT NULL AND entity_id IN (select id from entity) GROUP BY entity_id, name;

UPDATE lsmb12.customer SET company_id = (select id from company c where entity_id = customer.entity_id);

-- Contact

insert into eca_to_contact (credit_id, contact_class_id, contact,description) 
select v.credit_id, 1, v.phone, 'Primary phone: '||max(v.contact) as description
from lsmb12.vendor v 
where v.company_id is not null and v.phone is not null 
       and v.phone ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.phone
UNION
select v.credit_id, 12, v.email, 
       'email address: '||max(v.contact) as description 
from lsmb12.vendor v 
where v.company_id is not null and v.email is not null 
       and v.email ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.email
UNION
select v.credit_id, 12, v.cc, 'Carbon Copy email address' as description 
from lsmb12.vendor v 
where v.company_id is not null and v.cc is not null 
      and v.cc ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.cc
UNION 
select v.credit_id, 12, v.bcc, 'Blind Carbon Copy email address' as description 
from lsmb12.vendor v 
where v.company_id is not null and v.bcc is not null 
       and v.bcc ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.bcc
UNION
    select v.credit_id, 9, v.fax, 'Fax number' as description 
from lsmb12.vendor v 
where v.company_id is not null and v.fax is not null 
      and v.fax ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.fax;

insert into eca_to_contact (credit_id, contact_class_id, contact,description) 
select v.credit_id, 1, v.phone, 'Primary phone: '||max(v.contact) as description
from lsmb12.customer v 
where v.company_id is not null and v.phone is not null 
       and v.phone ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.phone
UNION
select v.credit_id, 12, v.email, 
       'email address: '||max(v.contact) as description 
from lsmb12.customer v 
where v.company_id is not null and v.email is not null 
       and v.email ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.email
UNION
select v.credit_id, 12, v.cc, 'Carbon Copy email address' as description 
from lsmb12.customer v 
where v.company_id is not null and v.cc is not null 
      and v.cc ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.cc
UNION 
select v.credit_id, 12, v.bcc, 'Blind Carbon Copy email address' as description 
from lsmb12.customer v 
where v.company_id is not null and v.bcc is not null 
       and v.bcc ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.bcc
UNION
    select v.credit_id, 9, v.fax, 'Fax number' as description 
from lsmb12.customer v 
where v.company_id is not null and v.fax is not null 
      and v.fax ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.fax;


-- addresses

INSERT INTO public.country (id, name, short_name) VALUES (-1, 'Invalid Country', 'XX');

INSERT INTO eca_to_location(credit_id, location_class, location_id)
SELECT eca.id, 1,
    min(location_save(NULL,

    case 
        when oa.address1 = '' then 'Null' 
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
     lsmb12.vendor oa
ON
    lower(trim(both ' ' from c.name)) = lower( trim(both ' ' from oa.country))
OR

    lower(trim(both ' ' from c.short_name)) = lower( trim(both ' ' from oa.country))
JOIN entity_credit_account eca ON (oa.credit_id = eca.id)
GROUP BY eca.id;

INSERT INTO eca_to_location(credit_id, location_class, location_id)
SELECT eca.id, 1,
    min(location_save(NULL,

    case 
        when oa.address1 = '' then 'Null' 
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
     lsmb12.customer oa
ON
    lower(trim(both ' ' from c.name)) = lower( trim(both ' ' from oa.country))
OR

    lower(trim(both ' ' from c.short_name)) = lower( trim(both ' ' from oa.country))
JOIN entity_credit_account eca ON (oa.credit_id = eca.id)
GROUP BY eca.id;

-- Shipto

INSERT INTO eca_to_location(credit_id, location_class, location_id)
SELECT eca.id, 2,
    min(location_save(NULL,

    case 
        when oa.shiptoaddress1 = '' then 'Null' 
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
     lsmb12.shipto oa
ON
    lower(trim(both ' ' from c.name)) = lower( trim(both ' ' from oa.shiptocountry))
OR

    lower(trim(both ' ' from c.short_name)) = lower( trim(both ' ' from oa.shiptocountry))
JOIN lsmb12.vendor ov ON (oa.trans_id = ov.id)
JOIN entity_credit_account eca ON (ov.credit_id = eca.id)
GROUP BY eca.id;

INSERT INTO eca_to_location(credit_id, location_class, location_id)
SELECT eca.id, 2,
    min(location_save(NULL,

    case 
        when oa.shiptoaddress1 = '' then 'Null' 
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
     lsmb12.shipto oa
ON
    lower(trim(both ' ' from c.name)) = lower( trim(both ' ' from oa.shiptocountry))
OR

    lower(trim(both ' ' from c.short_name)) = lower( trim(both ' ' from oa.shiptocountry))
JOIN lsmb12.customer ov ON (oa.trans_id = ov.id)
JOIN entity_credit_account eca ON (ov.credit_id = eca.id)
GROUP BY eca.id;
 
INSERT INTO eca_note(note_class, ref_key, note, vector)
SELECT 3, credit_id, notes, '' FROM lsmb12.vendor 
WHERE notes IS NOT NULL AND credit_id IS NOT NULL;

INSERT INTO eca_note(note_class, ref_key, note, vector)
SELECT 3, credit_id, notes, '' FROM lsmb12.customer
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

INSERT INTO account_heading(id, accno, description)
SELECT id, accno, description
  FROM lsmb12.chart WHERE charttype = 'H';

SELECT account_save(id, accno, description, category, gifi_accno, NULL, contra, 
                    CASE WHEN link like '%tax%' THEN true ELSE false END, 
                    string_to_array(link,':'))
  FROM chart 
 WHERE charttype = 'A';

INSERT INTO pricegroup
SELECT * FROM lsmb12.pricegroup;

ALTER TABLE lsmb12.employee ADD entity_id int;

INSERT INTO entity(control_code, entity_class, country_id)
select 'E-' || employeenumber, 3,
        (select id from country where lower(short_name) = :default_country)
FROM lsmb12.employee;

UPDATE lsmb12.employee set entity_id = 
       (select id from entity where 'E-'||employeenumber = control_code);

INSERT INTO person (first_name, last_name, entity_id) 
select name, name, entity_id FROM lsmb12.employee;

INSERT INTO users (entity_id, username)
     SELECT entity_id, login FROM lsmb12.employee em;

INSERT 
  INTO entity_employee(entity_id, startdate, enddate, role, ssn, sales,
       employeenumber, dob, manager_id)
SELECT entity_id, startdate, enddate, role, ssn, sales, employeenumber, dob,
       (select entity_id from lsmb12.employee where id = em.managerid)
  FROM lsmb12.employee em;



-- must rebuild this table due to changes since 1.2

INSERT INTO makemodel
SELECT * FROM lsmb12.makemodel;

INSERT INTO gl(id, reference, description, transdate, person_id, notes, 
               department_id)
    SELECT gl.id, reference, description, transdate, entity_id, gl.notes, 
           department_id
      FROM lsmb12.gl 
 LEFT JOIN lsmb12.employee em ON gl.employee_id = em.id;


COMMIT;
-- TODO:  User/password Migration
