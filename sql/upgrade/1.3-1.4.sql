BEGIN;

ALTER TABLE entity_credit_account DISABLE TRIGGER ALL;
DELETE FROM entity_credit_account;
ALTER TABLE entity_credit_account ENABLE TRIGGER ALL;
DELETE FROM person;
DELETE FROM company;
DELETE FROM entity;

--to preserve user modifications tshvr4
DELETE FROM country;
INSERT INTO country (id, name, short_name, itu)
SELECT id, name, short_name, itu FROM lsmb13.country;

INSERT INTO language SELECT * FROM lsmb13.language where code not in (select code from language);

INSERT INTO account_heading SELECT * FROM lsmb13.account_heading;
INSERT INTO account(
       id, accno, description, category, gifi_accno, heading, contra, tax
)
SELECT
       id, accno, description, category, gifi_accno, heading, contra, tax
FROM lsmb13.account;

INSERT INTO account_checkpoint SELECT * FROM lsmb13.account_checkpoint;
INSERT INTO account_link_description SELECT * FROM lsmb13.account_link_description WHERE lsmb13.account_link_description.description NOT IN (SELECT description FROM account_link_description);
INSERT INTO account_link SELECT * FROM lsmb13.account_link;
INSERT INTO pricegroup SELECT * FROM lsmb13.pricegroup;

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
  inventory_accno_id,
  income_accno_id ,
  expense_accno_id,
  bin,
  p.obsolete,
  bom,
  image,
  drawing,
  microfiche,
  partsgroup_id,
  avgcost
 FROM lsmb13.parts p;

INSERT INTO country_tax_form SELECT * FROM lsmb13.country_tax_form;

INSERT INTO entity (id, name, entity_class, control_code, created, country_id)
SELECT id, name, entity_class, control_code, created, country_id
  FROM lsmb13.entity;

INSERT INTO users SELECT * FROM lsmb13.users;
INSERT INTO lsmb_roles SELECT * FROM lsmb13.lsmb_roles;
INSERT INTO location SELECT * FROM lsmb13.location;
INSERT INTO company SELECT * FROM lsmb13.company;

INSERT INTO entity_to_location (entity_id, location_id, location_class)
SELECT c.entity_id, l.location_id, l.location_class
FROM lsmb13.company_to_location l
JOIN lsmb13.company c ON c.id = l.company_id;

INSERT INTO entity_to_location (entity_id, location_id, location_class)
SELECT p.entity_id, l.location_id, l.location_class
FROM lsmb13.person_to_location l
JOIN lsmb13.person p ON p.id = l.person_id AND p.entity_id IS NOT NULL;

INSERT INTO person SELECT * FROM lsmb13.person;
INSERT INTO entity_employee SELECT * FROM lsmb13.entity_employee;
UPDATE entity_employee
   SET ssn = 'invalid-' || entity_id::text
 WHERE ssn = '' or ssn is null;
UPDATE entity_employee
   SET employeenumber = 'invalid-' || entity_id::text
 WHERE employeenumber = '' or employeenumber is null;

INSERT INTO person_to_company SELECT * FROM lsmb13.person_to_company;
INSERT INTO entity_other_name SELECT * FROM lsmb13.entity_other_name;
INSERT INTO entity_to_contact
       (entity_id, contact_class_id, contact, description)
SELECT e.id, cc.contact_class_id, cc.contact, cc.description
   FROM lsmb13.company_to_contact cc
   JOIN lsmb13.company c ON c.id = cc.company_id
   JOIN lsmb13.entity e ON e.id = c.entity_id;
INSERT INTO entity_to_contact
       (entity_id, contact_class_id, contact, description)
SELECT e.id, pc.contact_class_id, pc.contact, pc.description
   FROM lsmb13.person_to_contact pc
   JOIN lsmb13.person p ON p.id = pc.person_id
   JOIN lsmb13.entity e ON e.id = p.entity_id;
INSERT INTO entity_bank_account (id, entity_id, bic, iban, remark)
SELECT id, entity_id, coalesce(bic,''), iban, remark FROM lsmb13.entity_bank_account;
INSERT INTO entity_credit_account SELECT * FROM lsmb13.entity_credit_account;
UPDATE entity_credit_account SET curr = defaults_get_defaultcurrency()
 WHERE curr IS NULL;
INSERT INTO eca_to_contact SELECT * FROM lsmb13.eca_to_contact;
INSERT INTO eca_to_location SELECT * FROM lsmb13.eca_to_location;
INSERT INTO entity_note SELECT * FROM lsmb13.entity_note;
INSERT INTO invoice_note SELECT * FROM lsmb13.invoice_note;
INSERT INTO eca_note SELECT * FROM lsmb13.eca_note;

INSERT INTO makemodel(parts_id, make, model)
SELECT parts_id, coalesce(make, ''), coalesce(model, '')
FROM lsmb13.makemodel;

ALTER TABLE gl DISABLE TRIGGER ALL;
INSERT INTO gl (
 id, reference, description, transdate, person_id, notes, approved
)
SELECT id, reference, description, transdate,
       coalesce(person_id, (select id from person
                            where id = (select min(entity_id) from users))),
       notes, approved
  FROM lsmb13.gl;
ALTER TABLE gl ENABLE TRIGGER ALL;

INSERT INTO gifi SELECT * FROM lsmb13.gifi;
SELECT setting__set(setting_key, value) FROM lsmb13.defaults
 where not setting_key = 'version';
INSERT INTO batch SELECT * FROM lsmb13.batch;

ALTER TABLE ar DISABLE TRIGGER ALL;
INSERT INTO ar (
 id,
 invnumber,
 transdate,
 --entity_id, --tshvr4 might may be dropped
 taxincluded,
 amount,
 netamount,
 paid,
 datepaid,
 duedate,
 invoice,
 shippingpoint,
 terms,
 notes,
 curr,
 ordnumber,
 person_id,
 till,
 quonumber,
 intnotes,
 shipvia,
 language_code,
 ponumber,
 on_hold,
 reverse,
 approved,
 entity_credit_account,
 force_closed,
 description
)
SELECT
 id,
 invnumber,
 transdate,
 --entity_id, --tshvr4 might may be dropped
 taxincluded,
 amount,
 netamount,
 paid,
 datepaid,
 duedate,
 invoice,
 shippingpoint,
 terms,
 notes,
 curr,
 ordnumber,
 person_id,
 till,
 quonumber,
 intnotes,
 shipvia,
 language_code,
 ponumber,
 on_hold,
 reverse,
 approved,
 entity_credit_account,
 force_closed,
 description
  FROM lsmb13.ar;
ALTER TABLE ar ENABLE TRIGGER ALL;

ALTER TABLE ap DISABLE TRIGGER ALL;
INSERT INTO ap (
 id,
 invnumber,
 transdate,
 --entity_id, --tshvr4 might may be dropped
 taxincluded ,
 amount,
 netamount,
 paid,
 datepaid,
 duedate,
 invoice,
 ordnumber,
 curr,
 notes,
 person_id,
 till,
 quonumber,
 intnotes,
 shipvia,
 language_code,
 ponumber,
 shippingpoint,
 on_hold,
 approved,
 reverse,
 terms,
 description,
 force_closed,
 entity_credit_account
)
SELECT
 id,
 invnumber,
 transdate,
 --entity_id, --tshvr4 might may be dropped
 taxincluded ,
 amount,
 netamount,
 paid,
 datepaid,
 duedate,
 invoice,
 ordnumber,
 curr,
 notes,
 person_id,
 till,
 quonumber,
 intnotes,
 shipvia,
 language_code,
 ponumber,
 shippingpoint,
 on_hold,
 approved,
 reverse,
 terms,
 description,
 force_closed,
 entity_credit_account
  FROM lsmb13.ap;
ALTER TABLE ap ENABLE TRIGGER ALL;

INSERT INTO transactions (id, table_name, locked_by)
SELECT id, table_name, locked_by FROM lsmb13.transactions;

INSERT INTO transactions (id, table_name)
SELECT id, 'ar' FROM ar WHERE id not in (select id from transactions);
INSERT INTO transactions (id, table_name)
SELECT id, 'ap' FROM ap WHERE id not in (select id from transactions);
INSERT INTO transactions (id, table_name)
SELECT id, 'gl' FROM gl WHERE id not in (select id from transactions);

INSERT INTO voucher SELECT * FROM lsmb13.voucher;

ALTER TABLE acc_trans DISABLE TRIGGER ALL;

INSERT INTO acc_trans (
 trans_id,
 chart_id,
 amount,
 transdate,
 source,
 cleared,
 fx_transaction,
 memo,
 invoice_id,
 approved,
 cleared_on,
 reconciled_on,
 voucher_id,
 entry_id
) SELECT
 trans_id,
 chart_id,
 amount,
 transdate,
 source,
 cleared,
 fx_transaction,
 memo,
 invoice_id,
 approved,
 cleared_on,
 reconciled_on,
 voucher_id,
 entry_id
   FROM lsmb13.acc_trans;

ALTER TABLE acc_trans enable TRIGGER ALL;

INSERT INTO invoice (
 id,
 trans_id,
 parts_id,
 description,
 qty,
 allocated,
 sellprice,
 precision,
 fxsellprice,
 discount,
 assemblyitem,
 unit,
 deliverydate,
 serialnumber,
 notes
)
SELECT
 id,
 trans_id,
 parts_id,
 description,
 qty,
 allocated,
 sellprice,
 precision,
 fxsellprice,
 discount,
 assemblyitem,
 unit,
 deliverydate,
 serialnumber,
 notes
  FROM lsmb13.invoice;

--INSERT INTO payment_map SELECT * FROM lsmb13.payment_map;
INSERT INTO assembly SELECT * FROM lsmb13.assembly;
INSERT INTO taxcategory SELECT * FROM lsmb13.taxcategory;
INSERT INTO partstax SELECT * FROM lsmb13.partstax;
INSERT INTO tax (
 chart_id,
 rate,
 taxnumber,
 validto,
 pass,
 taxmodule_id,
 minvalue,
 maxvalue
)
SELECT
 chart_id,
 rate,
 taxnumber,
 validto,
 pass,
 taxmodule_id,
 minvalue,
 maxvalue
  FROM lsmb13.tax;

INSERT INTO eca_tax SELECT * FROM lsmb13.customertax
UNION SELECT * FROM lsmb13.vendortax;
INSERT INTO oe (
 id,
 ordnumber,
 transdate,
 entity_id,
 amount,
 netamount,
 reqdate,
 taxincluded,
 shippingpoint,
 notes,
 curr,
 person_id,
 closed,
 quotation,
 quonumber,
 intnotes,
 shipvia,
 language_code,
 ponumber,
 terms,
 entity_credit_account,
 oe_class_id
)
SELECT
 id,
 ordnumber,
 transdate,
 entity_id,
 amount,
 netamount,
 reqdate,
 taxincluded,
 shippingpoint,
 notes,
 curr,
 person_id,
 closed,
 quotation,
 quonumber,
 intnotes,
 shipvia,
 language_code,
 ponumber,
 terms,
 entity_credit_account,
 oe_class_id
  FROM lsmb13.oe;

INSERT INTO orderitems(
 id,
 trans_id,
 parts_id,
 description,
 qty,
 sellprice,
 precision,
 discount,
 unit,
 reqdate,
 ship,
 serialnumber,
 notes
)
SELECT
 id,
 trans_id,
 parts_id,
 description,
 qty,
 sellprice,
 precision,
 discount,
 unit,
 reqdate,
 ship,
 serialnumber,
 notes
  FROM lsmb13.orderitems;

INSERT INTO exchangerate SELECT * FROM lsmb13.exchangerate;

INSERT INTO business_unit (id, class_id, control_code, description)
SELECT id, 1, id, description
  FROM lsmb13.department;

INSERT INTO business_unit
       (id, class_id, control_code, description, start_date, end_date,
       credit_id)
SELECT id + 1000, 2, projectnumber, description, startdate, enddate,
        credit_id from lsmb13.project;

INSERT INTO business_unit_ac (entry_id, class_id, bu_id)
SELECT ac.entry_id, 1, gl.department_id
  FROM acc_trans ac
  JOIN (SELECT id, department_id FROM lsmb13.ar UNION ALL
        SELECT id, department_id FROM lsmb13.ap UNION ALL
        SELECT id, department_id FROM lsmb13.gl) gl ON gl.id = ac.trans_id
 WHERE department_id > 0;

INSERT INTO business_unit_ac (entry_id, class_id, bu_id)
SELECT entry_id, 2, project_id + 1000 FROM lsmb13.acc_trans
 WHERE project_id > 0 and project_id in (select id from lsmb13.project);

INSERT INTO business_unit_inv (entry_id, class_id, bu_id)
SELECT inv.id, 1, gl.department_id
  FROM invoice inv
  JOIN (SELECT id, department_id FROM lsmb13.ar UNION ALL
        SELECT id, department_id FROM lsmb13.ap UNION ALL
        SELECT id, department_id FROM lsmb13.gl) gl ON gl.id = inv.trans_id
 WHERE department_id > 0;

INSERT INTO business_unit_inv (entry_id, class_id, bu_id)
SELECT id, 2, project_id + 1000 FROM lsmb13.invoice
 WHERE project_id > 0 and  project_id in (select id from lsmb13.project);

INSERT INTO business_unit_oitem (entry_id, class_id, bu_id)
SELECT oi.id, 1, oe.department_id
  FROM orderitems oi
  JOIN lsmb13.oe ON oi.trans_id = oe.id AND department_id > 0;

INSERT INTO business_unit_oitem (entry_id, class_id, bu_id)
SELECT id, 2, project_id + 1000 FROM lsmb13.orderitems
 WHERE project_id > 0  and  project_id in (select id from lsmb13.project);

INSERT INTO partsgroup SELECT * FROM lsmb13.partsgroup;
INSERT INTO status SELECT * FROM lsmb13.status;
INSERT INTO business SELECT * FROM lsmb13.business;
INSERT INTO sic SELECT * FROM lsmb13.sic;
INSERT INTO warehouse SELECT * FROM lsmb13.warehouse;
INSERT INTO inventory SELECT * FROM lsmb13.inventory;
INSERT INTO yearend SELECT * FROM lsmb13.yearend;
INSERT INTO partsvendor SELECT * FROM lsmb13.partsvendor;
INSERT INTO partscustomer SELECT * FROM lsmb13.partscustomer;

INSERT INTO audittrail SELECT * FROM lsmb13.audittrail where person_id is not null;
INSERT INTO translation SELECT * FROM lsmb13.translation;
INSERT INTO parts_translation SELECT * FROM lsmb13.parts_translation;
INSERT INTO user_preference
SELECT id, language, stylesheet, printer, dateformat, numberformat
  FROM lsmb13.user_preference;
update user_preference set dateformat = dateformat || 'yy' where length(dateformat) = 8;

INSERT INTO recurring (id, reference, startdate, nextdate,
                       enddate, howmany, payment, recurring_interval)
 SELECT id, reference, startdate, nextdate, enddate, howmany, payment,
        repeat || ' ' || unit as recurring_interval
   FROM lsmb13.recurring;
INSERT INTO payment_type SELECT * FROM lsmb13.payment_type;
INSERT INTO recurringemail SELECT * FROM lsmb13.recurringemail;
INSERT INTO recurringprint SELECT * FROM lsmb13.recurringprint;
INSERT INTO jcitems (
 id,
 business_unit_id,
 parts_id,
 description,
 qty,
 allocated,
 sellprice,
 fxsellprice,
 serialnumber,
 checkedin,
 checkedout,
 person_id,
 notes,
 total,
 non_billable,
 jctype,
 curr
)
SELECT
 id,
 project_id + 1000,
 parts_id,
 description,
 qty,
 allocated,
 sellprice,
 fxsellprice,
 serialnumber,
 checkedin,
 checkedout,
 person_id,
 notes,
 total,
 non_billable,
 1,
  (SELECT (string_to_array(value, ':'))[1]
     FROM lsmb13.defaults WHERE setting_key = 'curr')
  FROM lsmb13.jcitems
 WHERE project_id IN (select id from lsmb13.project);
INSERT INTO custom_table_catalog SELECT * FROM lsmb13.custom_table_catalog;
INSERT INTO custom_field_catalog SELECT * FROM lsmb13.custom_field_catalog;
INSERT INTO ac_tax_form SELECT * FROM lsmb13.ac_tax_form;
INSERT INTO invoice_tax_form SELECT * FROM lsmb13.invoice_tax_form;
INSERT INTO new_shipto SELECT * FROM lsmb13.new_shipto;
INSERT INTO tax_extended SELECT * FROM lsmb13.tax_extended;
INSERT INTO asset_class SELECT * FROM lsmb13.asset_class;
INSERT INTO asset_item SELECT * FROM lsmb13.asset_item;
INSERT INTO asset_note SELECT * FROM lsmb13.asset_note;
INSERT INTO asset_report SELECT * FROM lsmb13.asset_report;
INSERT INTO asset_report_line SELECT * FROM lsmb13.asset_report_line;
INSERT INTO asset_rl_to_disposal_method SELECT * FROM lsmb13.asset_rl_to_disposal_method;
DELETE FROM mime_type;
INSERT INTO mime_type SELECT * FROM lsmb13.mime_type;
INSERT INTO file_base SELECT * FROM lsmb13.file_base;
INSERT INTO file_transaction SELECT * FROM lsmb13.file_transaction;
INSERT INTO file_order SELECT * FROM lsmb13.file_order;
INSERT INTO file_secondary_attachment SELECT * FROM lsmb13.file_secondary_attachment;
INSERT INTO file_tx_to_order SELECT * FROM lsmb13.file_tx_to_order;
INSERT INTO file_order_to_order SELECT * FROM lsmb13.file_order_to_order;
INSERT INTO file_order_to_tx SELECT * FROM lsmb13.file_order_to_tx;
INSERT INTO payment (
 id,
 reference,
 gl_id,
 payment_class,
 payment_date,
 closed,
 entity_credit_id,
 employee_id,
 currency,
 notes
)
SELECT
 id,
 reference,
 gl_id,
 payment_class,
 payment_date,
 closed,
 entity_credit_id,
 employee_id,
 currency,
 notes
  FROM lsmb13.payment;

INSERT INTO payment_links SELECT * FROM lsmb13.payment_links;
INSERT INTO cr_report SELECT * FROM lsmb13.cr_report;
INSERT INTO cr_report_line SELECT * FROM lsmb13.cr_report_line;
INSERT INTO cr_coa_to_account SELECT * FROM lsmb13.cr_coa_to_account;

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

UPDATE defaults SET value = '1.4.0' WHERE setting_key = 'version';

update defaults set value = 'yes' where setting_key = 'migration_ok';

COMMIT;
