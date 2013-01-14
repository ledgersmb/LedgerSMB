--Setup

-- When moved to an interface, these will all be specified and preprocessed.
\set default_country '''<?lsmb default_country ?>'''
\set ar '''<?lsmb default_ar ?>'''
\set ap '''<?lsmb default_ap ?>'''

BEGIN;

-- adding mapping info for import.

ALTER TABLE sl28.vendor ADD COLUMN entity_id int;
ALTER TABLE sl28.vendor ADD COLUMN company_id int;
ALTER TABLE sl28.vendor ADD COLUMN credit_id int;

ALTER TABLE sl28.customer ADD COLUMN entity_id int;
ALTER TABLE sl28.customer ADD COLUMN company_id int;
ALTER TABLE sl28.customer ADD COLUMN credit_id int;


--Accounts
INSERT INTO account_heading(id, accno, description)
SELECT id, accno, description
  FROM sl28.chart WHERE charttype = 'H';

SELECT account_save(id, accno, description, category, gifi_accno, NULL, contra, 
                    CASE WHEN link like '%tax%' THEN true ELSE false END, 
                    string_to_array(link,':'))
  FROM sl28.chart 
 WHERE charttype = 'A';
--Entity

INSERT INTO entity (name, control_code, entity_class, country_id)
SELECT name, 'V-' || vendornumber, 1, 
       (select id from country 
         where lower(short_name)  = lower(:default_country))
FROM sl28.vendor
GROUP BY name, vendornumber;

INSERT INTO entity (name, control_code, entity_class, country_id)
SELECT name, 'C-' || customernumber, 2, 
       (select id from country 
         where lower(short_name)  =  lower(:default_country))
FROM sl28.customer
GROUP BY name, customernumber;

UPDATE sl28.vendor SET entity_id = (SELECT id FROM entity WHERE 'V-' || vendornumber = control_code);

UPDATE sl28.customer SET entity_id = coalesce((SELECT min(id) FROM entity WHERE 'C-' || customernumber = control_code), entity_id);

--Entity Credit Account

INSERT INTO entity_credit_account
(entity_id, meta_number, business_id, creditlimit, ar_ap_account_id, 
	cash_account_id, startdate, enddate, threshold, entity_class)
SELECT entity_id, vendornumber, business_id, creditlimit, arap_accno_id, 
	payment_accno_id, startdate, enddate, threshold, 1
FROM orig.vendor WHERE entity_id IS NOT NULL);

UPDATE sl28.vendor SET credit_id = 
	(SELECT id FROM entity_credit_account e 
	WHERE e.meta_number = vendornumber and entity_class = 1
        and e.entity_id = vendor.entity_id);

INSERT INTO entity_credit_account
(entity_id, meta_number, business_id, creditlimit, ar_ap_account_id, 
	cash_account_id, startdate, enddate, threshold, entity_class)
SELECT entity_id, vendornumber, business_id, creditlimit, arap_accno_id, 
	payment_accno_id, startdate, enddate, threshold, 2
FROM orig.customer WHERE entity_id IS NOT NULL);

UPDATE sl28.customer SET credit_id = 
	(SELECT id FROM entity_credit_account e 
	WHERE e.meta_number = vendornumber and entity_class = 2
        and e.entity_id = vendor.entity_id);

--Company

INSERT INTO company (entity_id, legal_name, tax_id)
SELECT entity_id, name, max(taxnumber) FROM sl28.vendor 
WHERE entity_id IS NOT NULL AND entity_id IN (select id from entity) GROUP BY entity_id, name;

UPDATE sl28.vendor SET company_id = (select id from company c where entity_id = vendor.entity_id);

INSERT INTO company (entity_id, legal_name, tax_id)
SELECT entity_id, name, max(taxnumber) FROM sl28.customer
WHERE entity_id IS NOT NULL AND entity_id IN (select id from entity) GROUP BY entity_id, name;

UPDATE sl28.customer SET company_id = (select id from company c where entity_id = customer.entity_id);

-- Contact

insert into eca_to_contact (credit_id, contact_class_id, contact,description) 
select v.credit_id, 1, v.phone, 'Primary phone: '||max(v.contact) as description
from sl28.vendor v 
where v.company_id is not null and v.phone is not null 
       and v.phone ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.phone
UNION
select v.credit_id, 12, v.email, 
       'email address: '||max(v.contact) as description 
from sl28.vendor v 
where v.company_id is not null and v.email is not null 
       and v.email ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.email
UNION
select v.credit_id, 12, v.cc, 'Carbon Copy email address' as description 
from sl28.vendor v 
where v.company_id is not null and v.cc is not null 
      and v.cc ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.cc
UNION 
select v.credit_id, 12, v.bcc, 'Blind Carbon Copy email address' as description 
from sl28.vendor v 
where v.company_id is not null and v.bcc is not null 
       and v.bcc ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.bcc
UNION
    select v.credit_id, 9, v.fax, 'Fax number' as description 
from sl28.vendor v 
where v.company_id is not null and v.fax is not null 
      and v.fax ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.fax;

insert into eca_to_contact (credit_id, contact_class_id, contact,description) 
select v.credit_id, 1, v.phone, 'Primary phone: '||max(v.contact) as description
from sl28.customer v 
where v.company_id is not null and v.phone is not null 
       and v.phone ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.phone
UNION
select v.credit_id, 12, v.email, 
       'email address: '||max(v.contact) as description 
from sl28.customer v 
where v.company_id is not null and v.email is not null 
       and v.email ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.email
UNION
select v.credit_id, 12, v.cc, 'Carbon Copy email address' as description 
from sl28.customer v 
where v.company_id is not null and v.cc is not null 
      and v.cc ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.cc
UNION 
select v.credit_id, 12, v.bcc, 'Blind Carbon Copy email address' as description 
from sl28.customer v 
where v.company_id is not null and v.bcc is not null 
       and v.bcc ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.bcc
UNION
    select v.credit_id, 9, v.fax, 'Fax number' as description 
from sl28.customer v 
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
     sl28.address oa
ON
    lower(trim(both ' ' from c.name)) = lower( trim(both ' ' from oa.country))
OR

    lower(trim(both ' ' from c.short_name)) = lower( trim(both ' ' from oa.country))
JOIN entity_credit_account eca ON (v.credit_id = eca.id)
JOIN (select credit_id, id from vendor
          union
           select credit_id, id from customer) v ON oa.trans_id = v.id
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
     sl28.shipto oa
ON
    lower(trim(both ' ' from c.name)) = lower( trim(both ' ' from oa.shiptocountry))
OR

    lower(trim(both ' ' from c.short_name)) = lower( trim(both ' ' from oa.shiptocountry))
JOIN (select credit_id, id from vendor
          union
           select credit_id, id from customer) ov ON oa.trans_id = v.id
JOIN entity_credit_account eca ON (ov.credit_id = eca.id)
GROUP BY eca.id;

INSERT INTO eca_note(note_class, ref_key, note, vector)
SELECT 3, credit_id, notes, '' FROM sl28.vendor 
WHERE notes IS NOT NULL AND credit_id IS NOT NULL;

INSERT INTO eca_note(note_class, ref_key, note, vector)
SELECT 3, credit_id, notes, '' FROM sl28.customer
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
SELECT * FROM sl28.pricegroup;

ALTER TABLE sl28.employee ADD entity_id int;

INSERT INTO entity(control_code, entity_class, name, country_id)
select 'E-' || employeenumber, 3, name,
        (select id from country where lower(short_name) = lower(:default_country))
FROM sl28.employee;

UPDATE sl28.employee set entity_id = 
       (select id from entity where 'E-'||employeenumber = control_code);

INSERT INTO person (first_name, last_name, entity_id) 
select name, name, entity_id FROM sl28.employee;

INSERT INTO users (entity_id, username)
     SELECT entity_id, login FROM sl28.employee em
      WHERE login IS NOT NULL;

INSERT 
  INTO entity_employee(entity_id, startdate, enddate, role, ssn, sales,
       employeenumber, dob, manager_id)
SELECT entity_id, startdate, enddate, role, ssn, sales, employeenumber, dob,
       (select entity_id from sl28.employee where id = em.managerid)
  FROM sl28.employee em;



-- must rebuild this table due to changes since 1.2

INSERT INTO makemodel
SELECT * FROM sl28.makemodel;

INSERT INTO gifi
SELECT * FROM sl28.gifi;

UPDATE defaults 
   SET value = (select value from sl28.defaults src 
                 WHERE src.setting_key = defaults.setting_key)
 WHERE setting_key IN (select setting_key FROM sl28.defaults);


INSERT INTO parts SELECT * FROM sl28.parts;

INSERT INTO assembly SELECT * FROM sl28.assembly;

ALTER TABLE gl DISABLE TRIGGER gl_audit_trail;

INSERT INTO gl(id, reference, description, transdate, person_id, notes, 
               department_id)
    SELECT gl.id, reference, description, transdate, p.id, gl.notes, 
           department_id
      FROM sl28.gl 
 LEFT JOIN sl28.employee em ON gl.employee_id = em.id
 LEFT JOIN person p ON em.entity_id = p.id;

ALTER TABLE gl ENABLE TRIGGER gl_audit_trail;

ALTER TABLE ar DISABLE TRIGGER ar_audit_trail;

insert into ar 
(entity_credit_account, person_id,
	id, invnumber, transdate, taxincluded, amount, netamount, paid, 
	datepaid, duedate, invoice, ordnumber, curr, notes, quonumber, intnotes,
	department_id, shipvia, language_code, ponumber, shippingpoint, 
	on_hold, approved, reverse, terms, description)
SELECT 
	customer.credit_id,
	(select entity_id from orig.employee 
		WHERE id = ap.employee_id),
	ap.id, invnumber, transdate, ap.taxincluded, amount, netamount, paid, 
	datepaid, duedate, invoice, ordnumber, ap.curr, ap.notes, quonumber, 
	intnotes,
	department_id, shipvia, ap.language_code, ponumber, shippingpoint, 
	onhold, approved, case when amount < 0 then true else false end,
	ap.terms, description
FROM orig.ar JOIN orig.customer ON (ap.vendor_id = customer.id) ;

ALTER TABLE ar ENABLE TRIGGER ar_audit_trail;

ALTER TABLE ap DISABLE TRIGGER ap_audit_trail;

insert into ap 
(entity_credit_account, person_id,
	id, invnumber, transdate, taxincluded, amount, netamount, paid, 
	datepaid, duedate, invoice, ordnumber, curr, notes, quonumber, intnotes,
	department_id, shipvia, language_code, ponumber, shippingpoint, 
	on_hold, approved, reverse, terms, description)
SELECT 
	vendor.credit_id,
	(select entity_id from orig.employee 
		WHERE id = ap.employee_id),
	ap.id, invnumber, transdate, ap.taxincluded, amount, netamount, paid, 
	datepaid, duedate, invoice, ordnumber, ap.curr, ap.notes, quonumber, 
	intnotes,
	department_id, shipvia, ap.language_code, ponumber, shippingpoint, 
	onhold, approved, case when amount < 0 then true else false end,
	ap.terms, description
FROM orig.ap JOIN orig.vendor ON (ap.vendor_id = vendor.id) ;

ALTER TABLE ap ENABLE TRIGGER ap_audit_trail;

INSERT INTO acc_trans
(trans_id, chart_id, amount, transdate, source, cleared, fx_transaction, 
	project_id, memo, approved, cleared_on, reconciled_on, 
	voucher_id)
SELECT trans_id, chart_id, amount, transdate, source,
	CASE WHEN cleared IS NOT NULL THEN TRUE ELSE FALSE END, fx_transaction,
	project_id, memo, approved, cleared, reconciled, vr_id
	FROM orig.acc_trans ;

INSERT INTO invoice (id, trans_id, parts_id, description, qty, allocated,
            sellprice, fxsellprice, discount, assemblyitem, unit, project_id,
            deliverydate, serialnumber, notes)
    SELECT  id, trans_id, parts_id, description, qty, allocated,
            sellprice, fxsellprice, discount, assemblyitem, unit, project_id,
            deliverydate, serialnumber, notes
       FROM sl28.invoice;

INSERT INTO partstax (parts_id, chart_id)
     SELECT parts_id, a.id
       FROM sl28.partstax pt
       JOIN sl28.chart ON chart.id = pt.chart_id
       JOIN account a ON chart.accno = a.accno;

INSERT INTO tax(chart_id, rate, taxnumber, validto, pass, taxmodule_id)
     SELECT a.id, t.rate, t.taxnumber, 
            coalesce(t.validto::timestamp, 'infinity'), pass, taxmodule_id
       FROM sl28.tax t
       JOIN sl28.chart c ON (t.chart_id = c.id)
       JOIN account a ON (a.accno = c.accno);

INSERT INTO customertax (customer_id, chart_id)
     SELECT c.credit_id,  a.id
       FROM sl28.customertax pt
       JOIN sl28.customer c ON (pt.customer_id = c.id)
       JOIN sl28.chart ON chart.id = pt.chart_id
       JOIN account a ON chart.accno = a.accno; 

INSERT INTO vendortax (vendor_id, chart_id)
     SELECT c.credit_id,  a.id
       FROM sl28.vendortax pt       
       JOIN sl28.vendor c ON (pt.vendor_id = c.id)
       JOIN sl28.chart ON chart.id = pt.chart_id
       JOIN account a ON chart.accno = a.accno;

INSERT 
  INTO oe(id, ordnumber, transdate, amount, netamount, reqdate, taxincluded,
       shippingpoint, notes, curr, person_id, closed, quotation, quonumber,
       intnotes, department_id, shipvia, language_code, ponumber, terms,
       entity_credit_account, oe_class_id)
SELECT oe.id,  ordnumber, transdate, amount, netamount, reqdate, oe.taxincluded,
       shippingpoint, oe.notes, oe.curr, p.id, closed, quotation, quonumber,
       intnotes, department_id, shipvia, oe.language_code, ponumber, oe.terms,
       coalesce(c.credit_id, v.credit_id),
       case 
           when c.id is not null and quotation is not true THEN 1
           WHEN v.id is not null and quotation is not true THEN 2
           when c.id is not null and quotation is true THEN 3
           WHEN v.id is not null and quotation is true THEN 4
       end
  FROM sl28.oe
  LEFT JOIN sl28.customer c ON c.id = oe.customer_id
  LEFT JOIN sl28.vendor v ON v.id = oe.vendor_id
  LEFT JOIN sl28.employee e ON oe.employee_id = e.id
  LEFT JOIN person p ON e.entity_id = p.id;

INSERT INTO orderitems(id, trans_id, parts_id, description, qty, sellprice,
            discount, unit, project_id, reqdate, ship, serialnumber, notes)
     SELECT id, trans_id, parts_id, description, qty, sellprice,
            discount, unit, project_id, reqdate, ship, serialnumber, notes
       FROM sl28.orderitems;

INSERT INTO exchangerate select * from sl28.exchangerate;

INSERT INTO project (id, projectnumber, description, startdate, enddate,
            parts_id, production, completed, credit_id)
     SELECT p.id, projectnumber, description, p.startdate, p.enddate,
            parts_id, production, completed, c.credit_id
       FROM sl28.project p
       JOIN sl28.customer c ON p.customer_id = c.id;

INSERT INTO partsgroup SELECT * FROM sl28.partsgroup;

INSERT INTO status SELECT * FROM sl28.status;

INSERT INTO department SELECT * FROM sl28.department;

INSERT INTO business SELECT * FROM sl28.business;

INSERT INTO sic SELECT * FROM sl28.sic;

INSERT INTO warehouse SELECT * FROM sl28.warehouse;

INSERT INTO inventory(entity_id, warehouse_id, parts_id, trans_id,
            orderitems_id, qty, shippingdate, entry_id)
     SELECT e.entity_id, warehouse_id, parts_id, trans_id,
            orderitems_id, qty, shippingdate, i.entry_id
       FROM sl28.inventory i
       JOIN sl28.employee e ON i.employee_id = e.id;

INSERT INTO yearend (trans_id, transdate) SELECT * FROM sl28.yearend;

INSERT INTO partsvendor(credit_id, parts_id, partnumber, leadtime, lastcost,
            curr, entry_id)
     SELECT v.credit_id, parts_id, partnumber, leadtime, lastcost,
            pv.curr, entry_id
       FROM sl28.partsvendor pv
       JOIN sl28.vendor v ON v.id = pv.vendor_id;

INSERT INTO partscustomer(parts_id, credit_id, pricegroup_id, pricebreak,
            sellprice, validfrom, validto, curr, entry_id)
     SELECT parts_id, credit_id, pv.pricegroup_id, pricebreak,
            sellprice, validfrom, validto, pv.curr, entry_id
       FROM sl28.partscustomer pv
       JOIN sl28.customer v ON v.id = pv.customer_id;

INSERT INTO language SELECT * FROM sl28.language;

INSERT INTO audittrail(trans_id, tablename, reference, formname, action,
            transdate, person_id, entry_id)
     SELECT trans_id, tablename, reference, formname, action,
            transdate, p.entity_id, entry_id
       FROM sl28.audittrail a
       JOIN sl28.employee e ON a.employee_id = e.id
       JOIN person p on e.entity_id = p.entity_id;

INSERT INTO user_preference(id)
     SELECT id from users;

INSERT INTO recurring SELECT * FROM sl28.recurring;

INSERT INTO recurringemail SELECT * FROM sl28.recurringemail;

INSERT INTO recurringprint SELECT * FROM sl28.recurringprint;

INSERT INTO jcitems(id, project_id, parts_id, description, qty, allocated,
            sellprice, fxsellprice, serialnumber, checkedin, checkedout,
            person_id, notes)
     SELECT j.id,  project_id, parts_id, description, qty, allocated,
            sellprice, fxsellprice, serialnumber, checkedin, checkedout,
            p.id, j.notes
       FROM sl28.jcitems j
       JOIN sl28.employee e ON j.employee_id = e.id
       JOIN person p ON e.entity_id = p.entity_id;

INSERT INTO  custom_table_catalog  SELECT * FROM sl28. custom_table_catalog;

INSERT INTO  custom_field_catalog  SELECT * FROM sl28. custom_field_catalog;

INSERT INTO parts_translation SELECT * FROM sl28.translation where trans_id in (select id from parts);

INSERT INTO partsgroup_translation SELECT * FROM sl28.translation where trans_id in
 (select id from partsgroup);

INSERT INTO project_translation SELECT * FROM sl28.translation where trans_id in
 (select id from project);

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
 SELECT setval('project_id_seq', max(id)) FROM project;
 SELECT setval('department_id_seq', max(id)) FROM department;
 SELECT setval('jcitems_id_seq', max(id)) FROM jcitems;
 SELECT setval('payment_type_id_seq', max(id)) FROM payment_type;
 SELECT setval('custom_table_catalog_table_id_seq', max(table_id)) FROM custom_table_catalog;
 SELECT setval('custom_field_catalog_field_id_seq', max(field_id)) FROM custom_field_catalog;
 SELECT setval('menu_node_id_seq', max(id)) FROM menu_node;
 SELECT setval('menu_attribute_id_seq', max(id)) FROM menu_attribute;
 SELECT setval('menu_acl_id_seq', max(id)) FROM menu_acl;
 SELECT setval('pending_job_id_seq', max(id)) FROM pending_job;
 SELECT setval('new_shipto_id_seq', max(id)) FROM new_shipto;
 SELECT setval('payment_id_seq', max(id)) FROM payment;
 SELECT setval('cr_report_id_seq', max(id)) FROM cr_report;
 SELECT setval('cr_report_line_id_seq', max(id)) FROM cr_report_line;

UPDATE defaults SET value = '1.3.0' WHERE setting_key = 'version';


COMMIT;
--TODO:  Translation migratiion.  Partsgroups?
-- TODO:  User/password Migration
