--Setup

-- When moved to an interface, these will all be specified and preprocessed.
\set default_country '''<?lsmb default_country ?>'''
\set ar '''<?lsmb default_ar ?>'''
\set ap '''<?lsmb default_ap ?>'''

BEGIN;

-- adding mapping info for import.

ALTER TABLE lsmb12.vendor ADD COLUMN entity_id int;
ALTER TABLE lsmb12.vendor ADD COLUMN company_id int;
ALTER TABLE lsmb12.vendor ADD COLUMN credit_id int;

ALTER TABLE lsmb12.customer ADD COLUMN entity_id int;
ALTER TABLE lsmb12.customer ADD COLUMN company_id int;
ALTER TABLE lsmb12.customer ADD COLUMN credit_id int;

-- Buisness Reporting Units

INSERT INTO business_unit (class_id, id, control_code, description)
     SELECT 1, id, role || id::text, description FROM lsmb12.department;


--Accounts
INSERT INTO account_heading(id, accno, description)
SELECT id, accno, description
  FROM lsmb12.chart WHERE charttype = 'H';

SELECT account__save(id, accno, description, category, gifi_accno, NULL, contra,
                    (CASE WHEN link like '%tax%' THEN true ELSE false END),
                    string_to_array(link,':'), false, false)
  FROM lsmb12.chart
 WHERE charttype = 'A';
--Entity

INSERT INTO entity (name, control_code, entity_class, country_id)
SELECT name, 'V-' || vendornumber, 1,
       (select id from country
         where lower(short_name)  = lower(:default_country))
FROM lsmb12.vendor
GROUP BY name, vendornumber;

INSERT INTO entity (name, control_code, entity_class, country_id)
SELECT name, 'C-' || customernumber, 2,
       (select id from country
         where lower(short_name)  =  lower(:default_country))
FROM lsmb12.customer
GROUP BY name, customernumber;

UPDATE lsmb12.vendor SET entity_id = (SELECT id FROM entity WHERE 'V-' || vendornumber = control_code);

UPDATE lsmb12.customer SET entity_id = coalesce((SELECT min(id) FROM entity WHERE 'C-' || customernumber = control_code), entity_id);

--Entity Credit Account

INSERT INTO entity_credit_account
(entity_id, meta_number, business_id, creditlimit, ar_ap_account_id,
	cash_account_id, startdate, enddate, threshold, entity_class,
        taxincluded)
SELECT entity_id, vendornumber, business_id, creditlimit,
       (select id from account where accno = :ap),
	NULL, startdate, enddate, 0, 1, taxincluded
FROM lsmb12.vendor WHERE entity_id IS NOT NULL;

UPDATE lsmb12.vendor SET credit_id =
	(SELECT id FROM entity_credit_account e
	WHERE e.meta_number = vendornumber and entity_class = 1
        and e.entity_id = vendor.entity_id);


INSERT INTO entity_credit_account
(entity_id, meta_number, business_id, creditlimit, ar_ap_account_id,
	cash_account_id, startdate, enddate, threshold, entity_class,
        taxincluded)
SELECT entity_id, customernumber, business_id, creditlimit,
       (select id from account where accno = :ar),
	NULL, startdate, enddate, 0, 2, taxincluded
FROM lsmb12.customer WHERE entity_id IS NOT NULL;

UPDATE lsmb12.customer SET credit_id =
	(SELECT id FROM entity_credit_account e
	WHERE e.meta_number = customernumber AND customer.entity_id = e.entity_id and entity_class = 2);

UPDATE entity_credit_account SET curr = defaults_get_defaultcurrency()
 WHERE curr IS NULL;
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
select v.credit_id, 13, v.cc, 'Carbon Copy email address' as description
from lsmb12.vendor v
where v.company_id is not null and v.cc is not null
      and v.cc ~ '[[:alnum:]_]'::text
group by v.credit_id, v.cc
UNION
select v.credit_id, 14, v.bcc, 'Blind Carbon Copy email address' as description
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
select v.credit_id, 13, v.cc, 'Carbon Copy email address' as description
from lsmb12.customer v
where v.company_id is not null and v.cc is not null
      and v.cc ~ '[[:alnum:]_]'::text
group by v.credit_id, v.cc
UNION
select v.credit_id, 14, v.bcc, 'Blind Carbon Copy email address' as description
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

INSERT INTO pricegroup
SELECT * FROM lsmb12.pricegroup;

ALTER TABLE lsmb12.employee ADD entity_id int;

INSERT INTO entity(control_code, entity_class, name, country_id)
select 'E-' || employeenumber, 3, name,
        (select id from country where lower(short_name) = lower(:default_country))
FROM lsmb12.employee;

UPDATE lsmb12.employee set entity_id =
       (select id from entity where 'E-'||employeenumber = control_code);

INSERT INTO person (first_name, last_name, entity_id)
select name, name, entity_id FROM lsmb12.employee;

INSERT
  INTO entity_employee(entity_id, startdate, enddate, role, ssn, sales,
       employeenumber, dob, manager_id)
SELECT entity_id, startdate, enddate, role, ssn, sales, employeenumber, dob,
       (select entity_id from lsmb12.employee where id = em.managerid)
  FROM lsmb12.employee em
 WHERE id IN (select min(id) from lsmb12.employee group by entity_id);


-- I would prefer stronger passwords here but the exposure is very short, since
-- the passwords time out after 24 hours anyway.  These are not assumed to be
-- usable passwords. --CT

SELECT admin__save_user(null, max(entity_id), login, random()::text, true)
  FROM lsmb12.employee
 WHERE login IN (select rolname FROM pg_roles)
 GROUP BY login;

SELECT 	admin__save_user(null, max(entity_id), login, random()::text, false)
  FROM lsmb12.employee
 WHERE login NOT IN (select rolname FROM pg_roles)
 GROUP BY login;



-- must rebuild this table due to changes since 1.2

-- needed to handle null values
UPDATE lsmb12.makemodel set model = '' where model is null;

--barcode will throw off SELECT * FROM makemodel
INSERT INTO makemodel (parts_id, make, model)
SELECT * FROM lsmb12.makemodel;

INSERT INTO gifi
SELECT * FROM lsmb12.gifi;

UPDATE defaults
   SET value = (select value from lsmb12.defaults src
                 WHERE src.setting_key = defaults.setting_key)
 WHERE setting_key IN (select setting_key FROM lsmb12.defaults);


INSERT INTO parts (
  id,
  partnumber,
  description,
  unit,
  listprice,
  sellprice,
  lastcost,
  priceupdate,
  weight,
  onhand,
  notes,
  makemodel,
  assembly,
  alternate,
  rop,
  inventory_accno_id,
  income_accno_id ,
  expense_accno_id,
  bin,
  obsolete,
  bom,
  image,
  drawing,
  microfiche,
  partsgroup_id,
  avgcost
)
SELECT
  p.id,
  partnumber,
  p.description,
  unit,
  listprice,
  sellprice,
  lastcost,
  priceupdate,
  weight,
  onhand,
  notes,
  makemodel,
  assembly,
  alternate,
  rop,
  inventory_accno.id,
  income_accno.id ,
  expense_accno.id,
  bin,
  p.obsolete,
  bom,
  image,
  drawing,
  microfiche,
  partsgroup_id,
  avgcost
 FROM lsmb12.parts p
 LEFT JOIN lsmb12.chart invc ON p.inventory_accno_id = invc.id
 LEFT JOIN lsmb12.chart incc ON p.income_accno_id = incc.id
 LEFT JOIN lsmb12.chart expc ON p.expense_accno_id = expc.id
 LEFT JOIN account inventory_accno ON invc.accno = inventory_accno.accno
 LEFT JOIN account income_accno ON incc.accno = income_accno.accno
 LEFT JOIN account expense_accno ON expc.accno = expense_accno.accno;

INSERT INTO assembly SELECT * FROM lsmb12.assembly;

ALTER TABLE gl DISABLE TRIGGER gl_audit_trail;

INSERT INTO gl(id, reference, description, transdate, person_id, notes)
    SELECT gl.id, reference, description, transdate, p.id, gl.notes
      FROM lsmb12.gl
 LEFT JOIN lsmb12.employee em ON gl.employee_id = em.id
 LEFT JOIN person p ON em.entity_id = p.id;

ALTER TABLE gl ENABLE TRIGGER gl_audit_trail;

ALTER TABLE ar DISABLE TRIGGER ar_audit_trail;

INSERT INTO ar(id, invnumber, transdate, taxincluded, amount,
            netamount, paid, datepaid, duedate, invoice, shippingpoint, terms,
            notes, curr, ordnumber, person_id, till, quonumber, intnotes,
            shipvia, language_code, ponumber,
            entity_credit_account)
     SELECT ar.id, invnumber, transdate, ar.taxincluded, amount, netamount,
            paid, datepaid, duedate, invoice, shippingpoint, ar.terms, ar.notes,
            ar.curr, ordnumber, em.entity_id, till, quonumber, intnotes,
            shipvia, ar.language_code, ponumber, credit_id
       FROM lsmb12.ar
       JOIN lsmb12.customer c ON c.id = ar.customer_id
  LEFT JOIN lsmb12.employee em ON em.id = ar.employee_id;

ALTER TABLE ar ENABLE TRIGGER ar_audit_trail;

ALTER TABLE ap DISABLE TRIGGER ap_audit_trail;

INSERT INTO ap(id, invnumber, transdate, taxincluded, amount,
            netamount, paid, datepaid, duedate, invoice, shippingpoint, terms,
            notes, curr, ordnumber, person_id, till, quonumber, intnotes,
            shipvia, language_code, ponumber,
            entity_credit_account)
     SELECT ap.id, invnumber, transdate, ap.taxincluded, amount, netamount,
            paid, datepaid, duedate, invoice, shippingpoint, ap.terms, ap.notes,
            ap.curr, ordnumber, em.entity_id, till, quonumber, intnotes,
            shipvia, ap.language_code, ponumber, credit_id
       FROM lsmb12.ap
       JOIN lsmb12.vendor c ON c.id = ap.vendor_id
  LEFT JOIN lsmb12.employee em ON em.id = ap.employee_id;

ALTER TABLE ap ENABLE TRIGGER ap_audit_trail;

INSERT INTO business_unit (id,control_code, description, start_date, end_date,
            credit_id, class_id)
     SELECT p.id + 1000, projectnumber, description, p.startdate, p.enddate,
            c.credit_id, 2
       FROM lsmb12.project p
  LEFT JOIN lsmb12.customer c ON p.customer_id = c.id;

INSERT INTO acc_trans(trans_id, chart_id, amount, transdate, source, cleared,
            fx_transaction, memo, invoice_id, entry_id)
     SELECT trans_id, a.id, amount, transdate, source, cleared,
            fx_transaction, memo, invoice_id, entry_id
       FROM lsmb12.acc_trans
       JOIN lsmb12.chart ON acc_trans.chart_id = chart.id
       JOIN account a ON chart.accno = a.accno;

INSERT INTO business_unit_ac (entry_id, class_id, bu_id)
     SELECT ac.entry_id, 1, gl.department_id
       FROM acc_trans ac
       JOIN (select id, department_id from lsmb12.gl
              UNION
             SELECT id, department_id FROM lsmb12.ar
              UNION
             SELECT id, department_id FROM lsmb12.ap) gl ON ac.trans_id = gl.id
      WHERE gl.department_id is not null and gl.department_id <> 0
      UNION
     SELECT ac.entry_id, 2, ac.project_id + 1000
       FROM lsmb12.acc_trans ac
      WHERE ac.project_id IS NOT NULL;

INSERT INTO invoice (id, trans_id, parts_id, description, qty, allocated,
            sellprice, fxsellprice, discount, assemblyitem, unit,
            deliverydate, serialnumber, notes)
    SELECT  id, trans_id, parts_id, description, qty, allocated,
            sellprice, fxsellprice, discount, assemblyitem, unit,
            deliverydate, serialnumber, notes
       FROM lsmb12.invoice;

INSERT INTO partstax (parts_id, chart_id)
     SELECT parts_id, a.id
       FROM lsmb12.partstax pt
       JOIN lsmb12.chart ON chart.id = pt.chart_id
       JOIN account a ON chart.accno = a.accno;

INSERT INTO business_unit_inv (entry_id, class_id, bu_id)
     SELECT inv.id, 1, gl.department_id
       FROM invoice inv
       JOIN (select id, department_id from lsmb12.gl
              UNION
             SELECT id, department_id FROM lsmb12.ar
              UNION
             SELECT id, department_id FROM lsmb12.ap) gl ON inv.trans_id = gl.id
      WHERE gl.department_id is not null and gl.department_id <> 0
      UNION
     SELECT inv.id, 2, inv.project_id + 1000
       FROM lsmb12.invoice inv
      WHERE inv.project_id IS NOT NULL;

INSERT INTO tax(chart_id, rate, taxnumber, validto, pass, taxmodule_id)
     SELECT a.id, t.rate, t.taxnumber,
            coalesce(t.validto::timestamp, 'infinity'), pass, taxmodule_id
       FROM lsmb12.tax t
       JOIN lsmb12.chart c ON (t.chart_id = c.id)
       JOIN account a ON (a.accno = c.accno);

INSERT INTO eca_tax (eca_id, chart_id)
     SELECT c.credit_id,  a.id
       FROM lsmb12.customertax pt
       JOIN lsmb12.customer c ON (pt.customer_id = c.id)
       JOIN lsmb12.chart ON chart.id = pt.chart_id
       JOIN account a ON chart.accno = a.accno
      UNION
     SELECT c.credit_id,  a.id
       FROM lsmb12.vendortax pt
       JOIN lsmb12.vendor c ON (pt.vendor_id = c.id)
       JOIN lsmb12.chart ON chart.id = pt.chart_id
       JOIN account a ON chart.accno = a.accno;

INSERT
  INTO oe(id, ordnumber, transdate, amount, netamount, reqdate, taxincluded,
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
  FROM lsmb12.oe
  LEFT JOIN lsmb12.customer c ON c.id = oe.customer_id
  LEFT JOIN lsmb12.vendor v ON v.id = oe.vendor_id
  LEFT JOIN lsmb12.employee e ON oe.employee_id = e.id
  LEFT JOIN person p ON e.entity_id = p.id;

INSERT INTO orderitems(id, trans_id, parts_id, description, qty, sellprice,
            discount, unit, reqdate, ship, serialnumber, notes)
     SELECT id, trans_id, parts_id, description, qty, sellprice,
            discount, unit, reqdate, ship, serialnumber, notes
       FROM lsmb12.orderitems;

INSERT INTO business_unit_oitem (entry_id, class_id, bu_id)
     SELECT oi.id, 1, gl.department_id
       FROM orderitems oi
       JOIN lsmb12.oe gl ON oi.trans_id = gl.id
      WHERE gl.department_id is not null and gl.department_id <> 0
      UNION
     SELECT oi.id, 2, oi.project_id + 1000
       FROM lsmb12.orderitems oi
      WHERE oi.project_id IS NOT NULL;

INSERT INTO exchangerate select * from lsmb12.exchangerate;

INSERT INTO partsgroup SELECT * FROM lsmb12.partsgroup;

INSERT INTO status SELECT * FROM lsmb12.status;

INSERT INTO business SELECT * FROM lsmb12.business;

INSERT INTO sic SELECT * FROM lsmb12.sic;

INSERT INTO warehouse SELECT * FROM lsmb12.warehouse;

INSERT INTO inventory(entity_id, warehouse_id, parts_id, trans_id,
            orderitems_id, qty, shippingdate, entry_id)
     SELECT e.entity_id, warehouse_id, parts_id, trans_id,
            orderitems_id, qty, shippingdate, i.entry_id
       FROM lsmb12.inventory i
       JOIN lsmb12.employee e ON i.employee_id = e.id;

INSERT INTO yearend (trans_id, transdate) SELECT * FROM lsmb12.yearend;

INSERT INTO partsvendor(credit_id, parts_id, partnumber, leadtime, lastcost,
            curr, entry_id)
     SELECT v.credit_id, parts_id, partnumber, leadtime, lastcost,
            pv.curr, entry_id
       FROM lsmb12.partsvendor pv
       JOIN lsmb12.vendor v ON v.id = pv.vendor_id;

INSERT INTO partscustomer(parts_id, credit_id, pricegroup_id, pricebreak,
            sellprice, validfrom, validto, curr, entry_id)
     SELECT parts_id, credit_id, pv.pricegroup_id, pricebreak,
            sellprice, validfrom, validto, pv.curr, entry_id
       FROM lsmb12.partscustomer pv
       JOIN lsmb12.customer v ON v.id = pv.customer_id;

INSERT INTO language SELECT * FROM lsmb12.language;

INSERT INTO audittrail(trans_id, tablename, reference, formname, action,
            transdate, person_id, entry_id)
     SELECT trans_id, tablename, reference, formname, action,
            transdate, p.entity_id, entry_id
       FROM lsmb12.audittrail a
       JOIN lsmb12.employee e ON a.employee_id = e.id
       JOIN person p on e.entity_id = p.entity_id;

INSERT INTO recurring SELECT * FROM lsmb12.recurring;

INSERT INTO recurringemail SELECT * FROM lsmb12.recurringemail;

INSERT INTO recurringprint SELECT * FROM lsmb12.recurringprint;

INSERT INTO jcitems(id, business_unit_id, parts_id, description, qty, allocated,
            sellprice, fxsellprice, serialnumber, checkedin, checkedout,
            person_id, notes, total, jctype, curr)
     SELECT j.id,  project_id + 1000, parts_id, description, qty, allocated,
            sellprice, fxsellprice, serialnumber, checkedin, checkedout,
            p.id, j.notes, coalesce(qty, 0), 1,
            (SELECT (string_to_array(value, ':'))[1]
               FROM lsmb12.defaults WHERE setting_key = 'curr')
       FROM lsmb12.jcitems j
       JOIN lsmb12.employee e ON j.employee_id = e.id
       JOIN person p ON e.entity_id = p.entity_id;

INSERT INTO  custom_table_catalog  SELECT * FROM lsmb12. custom_table_catalog;

INSERT INTO  custom_field_catalog  SELECT * FROM lsmb12. custom_field_catalog;

INSERT INTO parts_translation SELECT * FROM lsmb12.translation where trans_id in (select id from parts);

INSERT INTO partsgroup_translation SELECT * FROM lsmb12.translation where trans_id in
 (select id from partsgroup);

INSERT INTO business_unit_translation (trans_id, description, language_code)
SELECT trans_id + 1000, description, language_code
FROM lsmb12.translation where trans_id in (select id from lsmb12.project);

SELECT setval('id', max(id)) FROM transactions;

 SELECT setval('acc_trans_entry_id_seq', max(entry_id)) FROM acc_trans;
 SELECT setval('partsvendor_entry_id_seq', max(entry_id)) FROM partsvendor;
 SELECT setval('inventory_entry_id_seq', max(entry_id)) FROM inventory;
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
 SELECT setval('open_forms_id_seq', max(id)) FROM open_forms;
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
 SELECT setval('custom_table_catalog_table_id_seq', max(table_id)) FROM custom_table_catalog;
 SELECT setval('custom_field_catalog_field_id_seq', max(field_id)) FROM custom_field_catalog;
 SELECT setval('menu_node_id_seq', max(id)) FROM menu_node;
 SELECT setval('menu_attribute_id_seq', max(id)) FROM menu_attribute;
 SELECT setval('menu_acl_id_seq', max(id)) FROM menu_acl;
 SELECT setval('new_shipto_id_seq', max(id)) FROM new_shipto;
 SELECT setval('payment_id_seq', max(id)) FROM payment;
 SELECT setval('cr_report_id_seq', max(id)) FROM cr_report;
 SELECT setval('cr_report_line_id_seq', max(id)) FROM cr_report_line;

update defaults set value = 'yes' where setting_key = 'migration_ok';

COMMIT;
--TODO:  Translation migratiion.  Partsgroups?
-- TODO:  User/password Migration
