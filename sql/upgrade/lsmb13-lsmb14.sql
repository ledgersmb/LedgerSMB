INSERT INTO language SELECT * FROM lsmb13.language;
INSERT INTO account_heading SELECT * FROM lsmb13.account_heading;
INSERT INTO account SELECT * FROM lsmb13.account;
INSERT INTO account_checkpoint SELECT * FROM lsmb13.account_checkpoint;
INSERT INTO account_link_description SELECT * FROM lsmb13.account_link_description WHERE lsmb13.account_link_description.description NOT IN (SELECT description FROM account_link_description);
INSERT INTO account_link SELECT * FROM lsmb13.account_link;
INSERT INTO pricegroup SELECT * FROM lsmb13.pricegroup;
INSERT INTO country SELECT * FROM lsmb13.country;
INSERT INTO country_tax_form SELECT * FROM lsmb13.country_tax_form;
INSERT INTO entity SELECT * FROM lsmb13.entity;
INSERT INTO users SELECT * FROM lsmb13.users;
INSERT INTO lsmb_roles SELECT * FROM lsmb13.lsmb_roles;
INSERT INTO location SELECT * FROM lsmb13.location;
INSERT INTO company SELECT * FROM lsmb13.company;
INSERT INTO entity_to_location SELECT * FROM lsmb13.entity_to_location;
INSERT INTO salutation SELECT * FROM lsmb13.salutation;
INSERT INTO person SELECT * FROM lsmb13.person;
INSERT INTO entity_employee SELECT * FROM lsmb13.entity_employee;
INSERT INTO person_to_company SELECT * FROM lsmb13.person_to_company;
INSERT INTO entity_other_name SELECT * FROM lsmb13.entity_other_name;
INSERT INTO contact_class SELECT * FROM lsmb13.contact_class;
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
   JOIN lsmb13.person ON p.id = pc.person_id
   JOIN lsmb13.entity e ON e.id = p.entity_id;
   JOIN lsmb13.entity e ON e.id = c.entity_id;
INSERT INTO entity_bank_account SELECT * FROM lsmb13.entity_bank_account;
INSERT INTO entity_credit_account SELECT * FROM lsmb13.entity_credit_account;
INSERT INTO eca_to_contact SELECT * FROM lsmb13.eca_to_contact;
INSERT INTO eca_to_location SELECT * FROM lsmb13.eca_to_location;
INSERT INTO employee_class SELECT * FROM lsmb13.employee_class;
INSERT INTO employee_to_ec SELECT * FROM lsmb13.employee_to_ec;
INSERT INTO entity_note SELECT * FROM lsmb13.entity_note;
INSERT INTO invoice_note SELECT * FROM lsmb13.invoice_note;
INSERT INTO eca_note SELECT * FROM lsmb13.eca_note;
INSERT INTO makemodel SELECT * FROM lsmb13.makemodel;
INSERT INTO gl SELECT * FROM lsmb13.gl;
INSERT INTO gifi SELECT * FROM lsmb13.gifi;
INSERT INTO defaults SELECT * FROM lsmb13.defaults;
INSERT INTO batch SELECT * FROM lsmb13.batch;
INSERT INTO voucher SELECT * FROM lsmb13.voucher;
INSERT INTO acc_trans SELECT * FROM lsmb13.acc_trans;
INSERT INTO parts SELECT * FROM lsmb13.parts;
INSERT INTO invoice SELECT * FROM lsmb13.invoice;
INSERT INTO payment_map SELECT * FROM lsmb13.payment_map;
INSERT INTO assembly SELECT * FROM lsmb13.assembly;
INSERT INTO ar SELECT * FROM lsmb13.ar;
INSERT INTO ap SELECT * FROM lsmb13.ap;
INSERT INTO taxmodule SELECT * FROM lsmb13.taxmodule;
INSERT INTO taxcategory SELECT * FROM lsmb13.taxcategory;
INSERT INTO partstax SELECT * FROM lsmb13.partstax;
INSERT INTO tax SELECT * FROM lsmb13.tax;
INSERT INTO eca_tax SELECT * FROM lsmb13.customertax 
UNION SELECT * FROM lsmb13.vendortax;
INSERT INTO oe_class SELECT * FROM lsmb13.oe_class;
INSERT INTO oe SELECT * FROM lsmb13.oe;
INSERT INTO orderitems SELECT * FROM lsmb13.orderitems;
INSERT INTO exchangerate SELECT * FROM lsmb13.exchangerate;

INSERT INTO business_unit (id, class_id, control_code, description)
SELECT (id, 1, description, description) from department;
INSERT INTO business_unit 
       (id, class_id, control_code, description, start_date, end_date, 
       credit_id)
SELECT (id + 1000, 2, projectnumber, description, start_date, end_date,
        credit_id) from project;

INSERT INTO business_unit_ac (entry_id, class_id, bu_id)
SELECT ac.entry_id, 1, gl.department_id
  FROM acc_trans ac 
  JOIN (SELECT id, department_id FROM ar UNION ALL
        SELECT id, department_id FROM ap UNION ALL
        SELECT id, department_id FROM gl) gl;

INSERT INTO business_unit_ac (entry_id, class_id, bu_id)
SELECT entry_id, 2, project_id + 1000 FROM acc_trans;

INSERT INTO business_unit_inv (entry_id, class_id, bu_id)
SELECT inv.id, 1, gl.department_id
  FROM invoice inv 
  JOIN (SELECT id, department_id FROM ar UNION ALL
        SELECT id, department_id FROM ap UNION ALL
        SELECT id, department_id FROM gl) gl ON gl.id = ac.trans_id;

INSERT INTO business_unit_inv (entry_id, class_id, bu_id)
SELECT id, 2, project_id + 1000 FROM invoice

INSERT INTO business_unit_oitem (entry_id, class_id, bu_id)
SELECT oi.id, 1, oe.department_id 
  FROM orderitems oi
  JOIN oe ON oi.trans_id = oe.id;

INSERT INTO business_unit_oitem (entry_id, class_id, bu_id)
SELECT id, 2, project_id + 1000 FROM orderitems;

INSERT INTO partsgroup SELECT * FROM lsmb13.partsgroup;
INSERT INTO status SELECT * FROM lsmb13.status;
INSERT INTO business SELECT * FROM lsmb13.business;
INSERT INTO sic SELECT * FROM lsmb13.sic;
INSERT INTO warehouse SELECT * FROM lsmb13.warehouse;
INSERT INTO inventory SELECT * FROM lsmb13.inventory;
INSERT INTO yearend SELECT * FROM lsmb13.yearend;
INSERT INTO partsvendor SELECT * FROM lsmb13.partsvendor;
INSERT INTO partscustomer SELECT * FROM lsmb13.partscustomer;
INSERT INTO audittrail SELECT * FROM lsmb13.audittrail;
INSERT INTO translation SELECT * FROM lsmb13.translation;
INSERT INTO parts_translation SELECT * FROM lsmb13.parts_translation;
INSERT INTO business_unit_translation SELECT * FROM lsmb13.business_unit_translation;
INSERT INTO partsgroup_translation SELECT * FROM lsmb13.partsgroup_translation;
INSERT INTO user_preference SELECT * FROM lsmb13.user_preference;
INSERT INTO recurring SELECT * FROM lsmb13.recurring;
INSERT INTO payment_type SELECT * FROM lsmb13.payment_type;
INSERT INTO recurringemail SELECT * FROM lsmb13.recurringemail;
INSERT INTO recurringprint SELECT * FROM lsmb13.recurringprint;
INSERT INTO jcitems SELECT * FROM lsmb13.jcitems;
INSERT INTO custom_table_catalog SELECT * FROM lsmb13.custom_table_catalog;
INSERT INTO custom_field_catalog SELECT * FROM lsmb13.custom_field_catalog;
INSERT INTO ac_tax_form SELECT * FROM lsmb13.ac_tax_form;
INSERT INTO invoice_tax_form SELECT * FROM lsmb13.invoice_tax_form;
INSERT INTO new_shipto SELECT * FROM lsmb13.new_shipto;
INSERT INTO tax_extended SELECT * FROM lsmb13.tax_extended;
INSERT INTO asset_unit_class SELECT * FROM lsmb13.asset_unit_class;
INSERT INTO asset_dep_method SELECT * FROM lsmb13.asset_dep_method;
INSERT INTO asset_class SELECT * FROM lsmb13.asset_class;
INSERT INTO asset_disposal_method SELECT * FROM lsmb13.asset_disposal_method;
INSERT INTO asset_item SELECT * FROM lsmb13.asset_item;
INSERT INTO asset_note SELECT * FROM lsmb13.asset_note;
INSERT INTO asset_report_class SELECT * FROM lsmb13.asset_report_class;
INSERT INTO asset_report SELECT * FROM lsmb13.asset_report;
INSERT INTO asset_report_line SELECT * FROM lsmb13.asset_report_line;
INSERT INTO asset_rl_to_disposal_method SELECT * FROM lsmb13.asset_rl_to_disposal_method;
INSERT INTO mime_type SELECT * FROM lsmb13.mime_type;
INSERT INTO file_class SELECT * FROM lsmb13.file_class;
INSERT INTO file_base SELECT * FROM lsmb13.file_base;
INSERT INTO file_transaction SELECT * FROM lsmb13.file_transaction;
INSERT INTO file_order SELECT * FROM lsmb13.file_order;
INSERT INTO file_secondary_attachment SELECT * FROM lsmb13.file_secondary_attachment;
INSERT INTO file_tx_to_order SELECT * FROM lsmb13.file_tx_to_order;
INSERT INTO file_order_to_order SELECT * FROM lsmb13.file_order_to_order;
INSERT INTO file_order_to_tx SELECT * FROM lsmb13.file_order_to_tx;
INSERT INTO file_view_catalog SELECT * FROM lsmb13.file_view_catalog;
INSERT INTO payment SELECT * FROM lsmb13.payment;
INSERT INTO payment_links SELECT * FROM lsmb13.payment_links;
INSERT INTO cr_report SELECT * FROM lsmb13.cr_report;
INSERT INTO cr_report_line SELECT * FROM lsmb13.cr_report_line;
INSERT INTO cr_coa_to_account SELECT * FROM lsmb13.cr_coa_to_account;
