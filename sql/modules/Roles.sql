GRANT ALL ON SCHEMA public TO public; -- required for Pg 8.2

-- Basic file attachments

CREATE ROLE "lsmb_<?lsmb dbname ?>__file_read"
WITH INHERIT NOLOGIN;

GRANT SELECT ON file_base, file_secondary_attachment, file_transaction,
file_order, file_links, file_part
      TO "lsmb_<?lsmb dbname ?>__file_read";

CREATE ROLE "lsmb_<?lsmb dbname ?>__file_attach_tx"
WITH INHERIT NOLOGIN;

GRANT INSERT, UPDATE ON file_transaction, file_order_to_tx TO
 "lsmb_<?lsmb dbname ?>__file_attach_tx";


CREATE ROLE "lsmb_<?lsmb dbname ?>__file_attach_order"
WITH INHERIT NOLOGIN;

GRANT INSERT, UPDATE 
      ON file_order, 
         file_order_to_order,
         file_tx_to_order
      TO "lsmb_<?lsmb dbname ?>__file_attach_order";

GRANT INSERT, UPDATE ON file_transaction, file_order_to_tx TO
 "lsmb_<?lsmb dbname ?>__file_attach_tx";


CREATE ROLE "lsmb_<?lsmb dbname ?>__file_attach_part"
WITH INHERIT NOLOGIN;

GRANT INSERT, UPDATE 
      ON file_part
      TO "lsmb_<?lsmb dbname ?>__file_attach_part";


GRANT ALL ON file_base_id_seq TO "lsmb_<?lsmb dbname ?>__file_attach_tx";
GRANT ALL ON file_base_id_seq TO "lsmb_<?lsmb dbname ?>__file_attach_part";
GRANT ALL ON file_base_id_seq TO "lsmb_<?lsmb dbname ?>__file_attach_order";
-- Contacts

CREATE ROLE "lsmb_<?lsmb dbname ?>__contact_read"
WITH INHERIT NOLOGIN;

GRANT SELECT ON partsvendor, partscustomer, taxcategory
TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON entity TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON company TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON location TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON person TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON entity_credit_account TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON company_to_contact TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON company_to_entity TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON company_to_location TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON customertax TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON contact_class TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON entity_class TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON entity_bank_account TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON entity_note TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON entity_class_to_entity TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON entity_other_name TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON location_class TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON person_to_company TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON person_to_contact TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON person_to_contact TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON person_to_location TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON person_to_location TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON company_to_location TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON vendortax TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON eca_to_location TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT SELECT ON eca_to_contact TO "lsmb_<?lsmb dbname ?>__contact_read";
GRANT EXECUTE ON FUNCTION eca__list_notes(int)  TO "lsmb_<?lsmb dbname ?>__contact_read";


INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (1, 'allow', 'lsmb_<?lsmb dbname ?>__contact_read');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (11, 'allow', 'lsmb_<?lsmb dbname ?>__contact_read');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (14, 'allow', 'lsmb_<?lsmb dbname ?>__contact_read');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (21, 'allow', 'lsmb_<?lsmb dbname ?>__contact_read');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (30, 'allow', 'lsmb_<?lsmb dbname ?>__contact_read');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (33, 'allow', 'lsmb_<?lsmb dbname ?>__contact_read');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (49, 'allow', 'lsmb_<?lsmb dbname ?>__contact_read');


CREATE ROLE "lsmb_<?lsmb dbname ?>__contact_create"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT INSERT ON entity TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT ALL ON entity_id_seq TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON company TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT ALL ON company_id_seq TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON location TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT ALL ON location_id_seq TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON person TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT ALL ON person_id_seq TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON entity_credit_account TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT ALL ON entity_credit_account_id_seq TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON company_to_contact TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON company_to_entity TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT ALL ON note_id_seq TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON company_to_location TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON customertax TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON entity_bank_account TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT ALL ON entity_bank_account_id_seq TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON entity_note TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON entity_class_to_entity TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON entity_other_name TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON person_to_company TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON person_to_contact TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON person_to_contact TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON person_to_location TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON person_to_location TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON company_to_location TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT DELETE ON company_to_location TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON vendortax TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON eca_to_location TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT DELETE ON eca_to_location TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON eca_to_contact TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT DELETE ON eca_to_contact TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT UPDATE ON eca_to_contact TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT INSERT ON eca_note TO "lsmb_<?lsmb dbname ?>__contact_create";
GRANT ALL ON customertax TO"lsmb_<?lsmb dbname ?>__contact_create";
GRANT ALL ON vendortax TO"lsmb_<?lsmb dbname ?>__contact_create";


INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (1, 'allow', 'lsmb_<?lsmb dbname ?>__contact_create');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (11, 'allow', 'lsmb_<?lsmb dbname ?>__contact_create');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (12, 'allow', 'lsmb_<?lsmb dbname ?>__contact_create');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (21, 'allow', 'lsmb_<?lsmb dbname ?>__contact_create');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (30, 'allow', 'lsmb_<?lsmb dbname ?>__contact_create');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (31, 'allow', 'lsmb_<?lsmb dbname ?>__contact_create');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (48, 'allow', 'lsmb_<?lsmb dbname ?>__contact_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__contact_edit"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT UPDATE ON entity TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON company TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON location TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON person TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON entity_credit_account TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON company_to_contact TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON company_to_entity TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON company_to_location TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON customertax TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON entity_bank_account TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON entity_note TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON entity_class_to_entity TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON entity_other_name TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON person_to_company TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON person_to_contact TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON person_to_contact TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON person_to_location TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT UPDATE ON eca_to_location TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT DELETE, INSERT  ON vendortax TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT DELETE, INSERT  ON entity_bank_account TO "lsmb_<?lsmb dbname ?>__contact_edit";
GRANT ALL ON customertax TO"lsmb_<?lsmb dbname ?>__contact_edit";
GRANT ALL ON vendortax TO"lsmb_<?lsmb dbname ?>__contact_edit";

CREATE ROLE "lsmb_<?lsmb dbname ?>__contact_all_rights"
WITH INHERIT NOLOGIN 
in role "lsmb_<?lsmb dbname ?>__contact_create", 
"lsmb_<?lsmb dbname ?>__contact_edit",
"lsmb_<?lsmb dbname ?>__contact_read";

-- Batches and VOuchers
CREATE ROLE "lsmb_<?lsmb dbname ?>__batch_create"
WITH INHERIT NOLOGIN;

GRANT INSERT ON batch TO "lsmb_<?lsmb dbname ?>__batch_create";
GRANT ALL ON batch_id_seq TO "lsmb_<?lsmb dbname ?>__batch_create";
GRANT SELECT ON batch_class TO "lsmb_<?lsmb dbname ?>__batch_create";
GRANT INSERT ON voucher TO "lsmb_<?lsmb dbname ?>__batch_create";
GRANT ALL ON voucher_id_seq TO "lsmb_<?lsmb dbname ?>__contact_create";

-- No menu acls

CREATE ROLE "lsmb_<?lsmb dbname ?>__batch_post"
WITH INHERIT NOLOGIN;

GRANT EXECUTE ON FUNCTION batch_post(int) TO "lsmb_<?lsmb dbname ?>__batch_post";

INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (206, 'allow', 'lsmb_<?lsmb dbname ?>__contact_create');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (210, 'allow', 'lsmb_<?lsmb dbname ?>__contact_create');

-- AR
CREATE ROLE "lsmb_<?lsmb dbname ?>__ar_transaction_create"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT INSERT ON ar, invoice_note 
TO "lsmb_<?lsmb dbname ?>__ar_transaction_create";

GRANT ALL ON id TO "lsmb_<?lsmb dbname ?>__ar_transaction_create";
GRANT INSERT ON acc_trans TO "lsmb_<?lsmb dbname ?>__ar_transaction_create";
GRANT ALL ON acc_trans_entry_id_seq TO "lsmb_<?lsmb dbname ?>__ar_transaction_create";
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (1, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (2, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (194, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_create');

CREATE ROLE "lsmb_<?lsmb dbname ?>__ar_transaction_create_voucher"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read",
"lsmb_<?lsmb dbname ?>__batch_create";

GRANT INSERT ON ar TO "lsmb_<?lsmb dbname ?>__ar_transaction_create_voucher";
GRANT ALL ON id TO "lsmb_<?lsmb dbname ?>__ar_transaction_create_voucher";
GRANT INSERT ON acc_trans TO "lsmb_<?lsmb dbname ?>__ar_transaction_create_voucher";
GRANT ALL ON acc_trans_entry_id_seq TO "lsmb_<?lsmb dbname ?>__ar_transaction_create_voucher";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (4, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_create');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (198, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_create_voucher');


CREATE ROLE "lsmb_<?lsmb dbname ?>__ar_invoice_create"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__ar_transaction_create";

--### oldcode: UPDATE granted because old code wants it
GRANT INSERT, UPDATE ON invoice, new_shipto 
TO "lsmb_<?lsmb dbname ?>__ar_invoice_create";
GRANT ALL ON invoice_id_seq TO "lsmb_<?lsmb dbname ?>__ar_invoice_create";
GRANT INSERT ON inventory TO "lsmb_<?lsmb dbname ?>__ar_invoice_create";
GRANT ALL ON inventory_entry_id_seq TO "lsmb_<?lsmb dbname ?>__ar_invoice_create";
GRANT INSERT ON tax_extended TO "lsmb_<?lsmb dbname ?>__ar_invoice_create";


INSERT INTO menu_acl (node_id, acl_type, role_name)
values (3, 'allow', 'lsmb_<?lsmb dbname ?>__ar_invoice_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (195, 'allow', 'lsmb_<?lsmb dbname ?>__ar_invoice_create');


--CREATE ROLE "lsmb_<?lsmb dbname ?>__ar_invoice_create_voucher"
--WITH INHERIT NOLOGIN
--IN ROLE "lsmb_<?lsmb dbname ?>__contact_read",
--"lsmb_<?lsmb dbname ?>__batch_create",
--"lsmb_<?lsmb dbname ?>__ar_transaction_create_voucher";

--GRANT INSERT ON invoice TO "lsmb_<?lsmb dbname ?>__ar_invoice_create_voucher";
--GRANT ALL ON invoice_id_seq TO "lsmb_<?lsmb dbname ?>__ar_invoice_create_voucher";
--GRANT INSERT ON inventory TO "lsmb_<?lsmb dbname ?>__ar_invoice_create_voucher";
--GRANT ALL ON inventory_entry_id_seq TO "lsmb_<?lsmb dbname ?>__ar_invoice_create_voucher";

-- TODO add Menu ACLs

CREATE ROLE "lsmb_<?lsmb dbname ?>__ar_transaction_list"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read",
"lsmb_<?lsmb dbname ?>__file_read";

GRANT SELECT ON ar TO "lsmb_<?lsmb dbname ?>__ar_transaction_list";
GRANT SELECT ON acc_trans TO "lsmb_<?lsmb dbname ?>__ar_transaction_list";
GRANT SELECT ON invoice TO "lsmb_<?lsmb dbname ?>__ar_transaction_list";
GRANT SELECT ON inventory TO "lsmb_<?lsmb dbname ?>__ar_transaction_list";
GRANT SELECT ON tax_extended TO "lsmb_<?lsmb dbname ?>__ar_transaction_list";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (1, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (4, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (5, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (6, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (7, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (9, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (10, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (11, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (13, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (15, 'allow', 'lsmb_<?lsmb dbname ?>__ar_transaction_list');

--CREATE ROLE "lsmb_<?lsmb dbname ?>__ar_voucher_all"
--WITH INHERIT NOLOGIN 
--IN ROLE "lsmb_<?lsmb dbname ?>__ar_transaction_create_voucher",
--"lsmb_<?lsmb dbname ?>__ar_invoice_create_voucher";

CREATE ROLE "lsmb_<?lsmb dbname ?>__ar_transaction_all"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__ar_transaction_create",
"lsmb_<?lsmb dbname ?>__ar_invoice_create",
"lsmb_<?lsmb dbname ?>__ar_transaction_list",
"lsmb_<?lsmb dbname ?>__file_attach_tx";

CREATE ROLE "lsmb_<?lsmb dbname ?>__sales_order_create"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT INSERT, UPDATE ON oe TO "lsmb_<?lsmb dbname ?>__sales_order_create";
GRANT ALL ON oe_id_seq TO "lsmb_<?lsmb dbname ?>__sales_order_create";
GRANT INSERT, UPDATE ON orderitems TO "lsmb_<?lsmb dbname ?>__sales_order_create";
GRANT ALL ON orderitems_id_seq TO "lsmb_<?lsmb dbname ?>__sales_order_create";
GRANT ALL on inventory TO "lsmb_<?lsmb dbname ?>__sales_order_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (50, 'allow', 'lsmb_<?lsmb dbname ?>__sales_order_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (51, 'allow', 'lsmb_<?lsmb dbname ?>__sales_order_create');

CREATE ROLE "lsmb_<?lsmb dbname ?>__sales_order_edit";
GRANT DELETE ON orderitems TO "lsmb_<?lsmb dbname ?>__sales_order_edit";
GRANT DELETE ON new_shipto TO "lsmb_<?lsmb dbname ?>__sales_order_edit";

CREATE ROLE "lsmb_<?lsmb dbname ?>__sales_quotation_create"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT INSERT, UPDATE ON oe TO "lsmb_<?lsmb dbname ?>__sales_quotation_create";
GRANT ALL ON oe_id_seq TO "lsmb_<?lsmb dbname ?>__sales_quotation_create";
GRANT INSERT, UPDATE ON orderitems TO "lsmb_<?lsmb dbname ?>__sales_quotation_create";
GRANT ALL ON orderitems_id_seq TO "lsmb_<?lsmb dbname ?>__sales_quotation_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (67, 'allow', 'lsmb_<?lsmb dbname ?>__sales_quotation_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (68, 'allow', 'lsmb_<?lsmb dbname ?>__sales_quotation_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__sales_order_list"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read",
"lsmb_<?lsmb dbname ?>__file_read";

GRANT SELECT ON oe TO "lsmb_<?lsmb dbname ?>__sales_order_list";
GRANT SELECT ON orderitems TO "lsmb_<?lsmb dbname ?>__sales_order_list";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (50, 'allow', 'lsmb_<?lsmb dbname ?>__sales_order_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (53, 'allow', 'lsmb_<?lsmb dbname ?>__sales_order_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (54, 'allow', 'lsmb_<?lsmb dbname ?>__sales_order_list');


CREATE ROLE "lsmb_<?lsmb dbname ?>__sales_quotation_list"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read",
"lsmb_<?lsmb dbname ?>__file_read";

GRANT SELECT ON oe TO "lsmb_<?lsmb dbname ?>__sales_quotation_list";
GRANT SELECT ON orderitems TO "lsmb_<?lsmb dbname ?>__sales_quotation_list";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (67, 'allow', 'lsmb_<?lsmb dbname ?>__sales_quotation_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (70, 'allow', 'lsmb_<?lsmb dbname ?>__sales_quotation_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (71, 'allow', 'lsmb_<?lsmb dbname ?>__sales_quotation_list');


CREATE ROLE "lsmb_<?lsmb dbname ?>__ar_all"
WITH INHERIT NOLOGIN 
IN ROLE
--### "lsmb_<?lsmb dbname ?>__ar_voucher_all",
"lsmb_<?lsmb dbname ?>__ar_transaction_all",
"lsmb_<?lsmb dbname ?>__sales_order_create",
"lsmb_<?lsmb dbname ?>__sales_quotation_create",
"lsmb_<?lsmb dbname ?>__sales_order_list",
"lsmb_<?lsmb dbname ?>__sales_quotation_list",
"lsmb_<?lsmb dbname ?>__file_attach_tx";

-- AP
CREATE ROLE "lsmb_<?lsmb dbname ?>__ap_transaction_create"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT INSERT ON ap, invoice_note 
TO "lsmb_<?lsmb dbname ?>__ap_transaction_create";
GRANT ALL ON id TO "lsmb_<?lsmb dbname ?>__ap_transaction_create";
GRANT INSERT ON acc_trans TO "lsmb_<?lsmb dbname ?>__ap_transaction_create";
GRANT ALL ON acc_trans_entry_id_seq TO "lsmb_<?lsmb dbname ?>__ap_transaction_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (21, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (22, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (196, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_create');

CREATE ROLE "lsmb_<?lsmb dbname ?>__ap_transaction_create_voucher"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read",
"lsmb_<?lsmb dbname ?>__batch_create";

GRANT SELECT,INSERT, UPDATE ON ap TO "lsmb_<?lsmb dbname ?>__ap_transaction_create_voucher";
GRANT ALL ON id TO "lsmb_<?lsmb dbname ?>__ap_transaction_create_voucher";
GRANT INSERT ON acc_trans TO "lsmb_<?lsmb dbname ?>__ap_transaction_create_voucher";
GRANT ALL ON acc_trans_entry_id_seq TO "lsmb_<?lsmb dbname ?>__ap_transaction_create_voucher";

INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (199, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_create_voucher');

CREATE ROLE "lsmb_<?lsmb dbname ?>__ap_invoice_create"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__ap_transaction_create";

GRANT INSERT ON invoice TO "lsmb_<?lsmb dbname ?>__ap_invoice_create";
GRANT INSERT ON inventory TO "lsmb_<?lsmb dbname ?>__ap_invoice_create";
GRANT ALL ON invoice_id_seq TO "lsmb_<?lsmb dbname ?>__ap_invoice_create";
GRANT ALL ON inventory_entry_id_seq TO "lsmb_<?lsmb dbname ?>__ap_invoice_create";
GRANT INSERT ON tax_extended TO "lsmb_<?lsmb dbname ?>__ap_invoice_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (23, 'allow', 'lsmb_<?lsmb dbname ?>__ap_invoice_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (197, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__ap_invoice_create_voucher"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read",
"lsmb_<?lsmb dbname ?>__batch_create";

GRANT INSERT ON invoice TO "lsmb_<?lsmb dbname ?>__ap_invoice_create_voucher";
GRANT INSERT ON inventory TO "lsmb_<?lsmb dbname ?>__ap_invoice_create_voucher";
GRANT ALL ON invoice_id_seq TO "lsmb_<?lsmb dbname ?>__ap_invoice_create_voucher";
GRANT ALL ON inventory_entry_id_seq TO "lsmb_<?lsmb dbname ?>__ap_invoice_create_voucher";

-- TODO add Menu ACLs


CREATE ROLE "lsmb_<?lsmb dbname ?>__ap_transaction_list"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read",
"lsmb_<?lsmb dbname ?>__file_read";

GRANT SELECT ON ap TO "lsmb_<?lsmb dbname ?>__ap_transaction_list";
GRANT SELECT ON acc_trans TO "lsmb_<?lsmb dbname ?>__ap_transaction_list";
GRANT SELECT ON invoice TO "lsmb_<?lsmb dbname ?>__ap_transaction_list";
GRANT SELECT ON inventory TO "lsmb_<?lsmb dbname ?>__ap_transaction_list";
GRANT SELECT ON tax_extended TO "lsmb_<?lsmb dbname ?>__ap_transaction_list";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (21, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (24, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (25, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (26, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (27, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (28, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (29, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (30, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (32, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (34, 'allow', 'lsmb_<?lsmb dbname ?>__ap_transaction_list');


CREATE ROLE "lsmb_<?lsmb dbname ?>__ap_all_vouchers"
WITH INHERIT NOLOGIN 
IN ROLE "lsmb_<?lsmb dbname ?>__ap_transaction_create_voucher",
"lsmb_<?lsmb dbname ?>__ap_invoice_create_voucher";

CREATE ROLE "lsmb_<?lsmb dbname ?>__ap_all_transactions"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__ap_transaction_create",
"lsmb_<?lsmb dbname ?>__ap_invoice_create",
"lsmb_<?lsmb dbname ?>__ap_transaction_list";

CREATE ROLE "lsmb_<?lsmb dbname ?>__purchase_order_create"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT INSERT, UPDATE ON oe TO "lsmb_<?lsmb dbname ?>__purchase_order_create";
GRANT INSERT, UPDATE ON orderitems TO "lsmb_<?lsmb dbname ?>__purchase_order_create";
GRANT ALL ON oe_id_seq TO "lsmb_<?lsmb dbname ?>__purchase_order_create";
GRANT ALL ON orderitems_id_seq TO "lsmb_<?lsmb dbname ?>__purchase_order_create";
GRANT ALL on inventory TO "lsmb_<?lsmb dbname ?>__purchase_order_create";

CREATE ROLE "lsmb_<?lsmb dbname ?>__purchase_order_edit";
GRANT DELETE ON orderitems TO "lsmb_<?lsmb dbname ?>__purchase_order_edit";
GRANT DELETE ON new_shipto TO "lsmb_<?lsmb dbname ?>__purchase_order_edit";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (50, 'allow', 'lsmb_<?lsmb dbname ?>__purchase_order_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (52, 'allow', 'lsmb_<?lsmb dbname ?>__purchase_order_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__rfq_create"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT INSERT, UPDATE ON oe TO "lsmb_<?lsmb dbname ?>__rfq_create";
GRANT INSERT, UPDATE ON orderitems TO "lsmb_<?lsmb dbname ?>__rfq_create";
GRANT ALL ON oe_id_seq TO "lsmb_<?lsmb dbname ?>__rfq_create";
GRANT ALL ON orderitems_id_seq TO "lsmb_<?lsmb dbname ?>__rfq_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (67, 'allow', 'lsmb_<?lsmb dbname ?>__rfq_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (69, 'allow', 'lsmb_<?lsmb dbname ?>__rfq_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__purchase_order_list"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT SELECT ON oe TO "lsmb_<?lsmb dbname ?>__purchase_order_list";
GRANT SELECT ON orderitems TO "lsmb_<?lsmb dbname ?>__purchase_order_list";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (50, 'allow', 'lsmb_<?lsmb dbname ?>__purchase_order_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (53, 'allow', 'lsmb_<?lsmb dbname ?>__purchase_order_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (55, 'allow', 'lsmb_<?lsmb dbname ?>__purchase_order_list');


CREATE ROLE "lsmb_<?lsmb dbname ?>__rfq_list"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT SELECT ON oe TO "lsmb_<?lsmb dbname ?>__rfq_list";
GRANT SELECT ON orderitems TO "lsmb_<?lsmb dbname ?>__rfq_list";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (67, 'allow', 'lsmb_<?lsmb dbname ?>__rfq_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (70, 'allow', 'lsmb_<?lsmb dbname ?>__rfq_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (72, 'allow', 'lsmb_<?lsmb dbname ?>__rfq_list');


CREATE ROLE "lsmb_<?lsmb dbname ?>__ap_all"
WITH INHERIT NOLOGIN 
IN ROLE "lsmb_<?lsmb dbname ?>__ap_all_vouchers",
"lsmb_<?lsmb dbname ?>__ap_all_transactions",
"lsmb_<?lsmb dbname ?>__purchase_order_create",
"lsmb_<?lsmb dbname ?>__rfq_create",
"lsmb_<?lsmb dbname ?>__purchase_order_list",
"lsmb_<?lsmb dbname ?>__rfq_list";

-- POS
CREATE ROLE "lsmb_<?lsmb dbname ?>__pos_enter"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT INSERT ON invoice TO "lsmb_<?lsmb dbname ?>__pos_enter";
GRANT INSERT ON inventory TO "lsmb_<?lsmb dbname ?>__pos_enter";
GRANT INSERT ON ar TO "lsmb_<?lsmb dbname ?>__pos_enter";
GRANT INSERT ON acc_trans TO "lsmb_<?lsmb dbname ?>__pos_enter";
GRANT ALL ON id TO "lsmb_<?lsmb dbname ?>__pos_enter";
GRANT ALL ON acc_trans_entry_id_seq TO "lsmb_<?lsmb dbname ?>__pos_enter";
GRANT ALL ON invoice_id_seq TO "lsmb_<?lsmb dbname ?>__pos_enter";
GRANT ALL ON inventory_entry_id_seq TO "lsmb_<?lsmb dbname ?>__pos_enter";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (16, 'allow', 'lsmb_<?lsmb dbname ?>__pos_enter');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (17, 'allow', 'lsmb_<?lsmb dbname ?>__pos_enter');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (18, 'allow', 'lsmb_<?lsmb dbname ?>__pos_enter');


CREATE ROLE "lsmb_<?lsmb dbname ?>__close_till"
WITH INHERIT NOLOGIN;

GRANT INSERT ON gl TO "lsmb_<?lsmb dbname ?>__close_till";
GRANT INSERT ON acc_trans TO "lsmb_<?lsmb dbname ?>__close_till";
GRANT ALL ON id TO "lsmb_<?lsmb dbname ?>__close_till";
GRANT ALL ON acc_trans_entry_id_seq TO "lsmb_<?lsmb dbname ?>__close_till";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (16, 'allow', 'lsmb_<?lsmb dbname ?>__close_till');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (20, 'allow', 'lsmb_<?lsmb dbname ?>__close_till');


CREATE ROLE "lsmb_<?lsmb dbname ?>__list_all_open"
WITH INHERIT NOLOGIN;

GRANT SELECT ON ar TO "lsmb_<?lsmb dbname ?>__list_all_open";
GRANT SELECT ON acc_trans TO "lsmb_<?lsmb dbname ?>__list_all_open";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (16, 'allow', 'lsmb_<?lsmb dbname ?>__list_all_open');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (18, 'allow', 'lsmb_<?lsmb dbname ?>__list_all_open');


CREATE ROLE "lsmb_<?lsmb dbname ?>__pos_cashier"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__pos_enter",
"lsmb_<?lsmb dbname ?>__close_till";

CREATE ROLE "lsmb_<?lsmb dbname ?>__pos_all"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__pos_cashier",
"lsmb_<?lsmb dbname ?>__list_all_open";

-- CASH
CREATE ROLE "lsmb_<?lsmb dbname ?>__reconciliation_enter"
WITH INHERIT NOLOGIN;

GRANT SELECT ON recon_payee 
TO "lsmb_<?lsmb dbname ?>__reconciliation_enter";

GRANT UPDATE ON cr_report TO "lsmb_<?lsmb dbname ?>__reconciliation_enter";
GRANT ALL ON cr_report_line_id_seq TO "lsmb_<?lsmb dbname ?>__reconciliation_enter";
 
 GRANT INSERT, SELECT ON cr_report, cr_report_line 
TO "lsmb_<?lsmb dbname ?>__reconciliation_enter";
GRANT DELETE, UPDATE ON cr_report_line
TO "lsmb_<?lsmb dbname ?>__reconciliation_enter";
GRANT SELECT ON acc_trans, account_checkpoint 
TO "lsmb_<?lsmb dbname ?>__reconciliation_enter";

 GRANT ALL ON cr_report_id_seq TO "lsmb_<?lsmb dbname ?>__reconciliation_enter";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (35, 'allow', 'lsmb_<?lsmb dbname ?>__reconciliation_enter');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (45, 'allow', 'lsmb_<?lsmb dbname ?>__reconciliation_enter');


CREATE ROLE "lsmb_<?lsmb dbname ?>__reconciliation_approve"
WITH INHERIT NOLOGIN;

GRANT SELECT ON recon_payee 
TO "lsmb_<?lsmb dbname ?>__reconciliation_approve";

GRANT EXECUTE ON FUNCTION reconciliation__delete_unapproved(in_report_id int)
TO "lsmb_<?lsmb dbname ?>__reconciliation_approve";

GRANT DELETE ON cr_report_line TO "lsmb_<?lsmb dbname ?>__reconciliation_approve";
GRANT UPDATE ON cr_report TO "lsmb_<?lsmb dbname ?>__reconciliation_approve";
GRANT SELECT ON acc_trans, account_checkpoint TO 
"lsmb_<?lsmb dbname ?>__reconciliation_approve";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (35, 'allow', 'lsmb_<?lsmb dbname ?>__reconciliation_approve');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (41, 'allow', 'lsmb_<?lsmb dbname ?>__reconciliation_approve');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (44, 'allow', 'lsmb_<?lsmb dbname ?>__reconciliation_approve');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (211, 'allow', 'lsmb_<?lsmb dbname ?>__reconciliation_approve');



CREATE ROLE "lsmb_<?lsmb dbname ?>__reconciliation_all"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__reconciliation_enter",
"lsmb_<?lsmb dbname ?>__reconciliation_approve";

CREATE ROLE "lsmb_<?lsmb dbname ?>__payment_process"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__ap_transaction_list";

GRANT INSERT, SELECT ON payment, payment_links, overpayments
TO "lsmb_<?lsmb dbname ?>__payment_process";

GRANT SELECT, INSERT ON acc_trans TO "lsmb_<?lsmb dbname ?>__payment_process";
GRANT ALL ON acc_trans_entry_id_seq TO "lsmb_<?lsmb dbname ?>__payment_process";
GRANT UPDATE ON ap TO "lsmb_<?lsmb dbname ?>__payment_process";
GRANT ALL ON payment, payment_id_seq TO "lsmb_<?lsmb dbname ?>__payment_process";



INSERT INTO menu_acl (node_id, acl_type, role_name)
values (35, 'allow', 'lsmb_<?lsmb dbname ?>__payment_process');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (38, 'allow', 'lsmb_<?lsmb dbname ?>__payment_process');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (43, 'allow', 'lsmb_<?lsmb dbname ?>__payment_process');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (201, 'allow', 'lsmb_<?lsmb dbname ?>__payment_process');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (202, 'allow', 'lsmb_<?lsmb dbname ?>__payment_process');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (223, 'allow', 'lsmb_<?lsmb dbname ?>__payment_process');


CREATE ROLE "lsmb_<?lsmb dbname ?>__receipt_process"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__ar_transaction_list";

GRANT INSERT, SELECT ON payment, payment_links, overpayments
TO "lsmb_<?lsmb dbname ?>__receipt_process";

GRANT INSERT ON acc_trans TO "lsmb_<?lsmb dbname ?>__receipt_process";
GRANT ALL ON acc_trans_entry_id_seq TO "lsmb_<?lsmb dbname ?>__receipt_process";
GRANT UPDATE ON ar TO "lsmb_<?lsmb dbname ?>__receipt_process";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (35, 'allow', 'lsmb_<?lsmb dbname ?>__receipt_process');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (36, 'allow', 'lsmb_<?lsmb dbname ?>__receipt_process');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (37, 'allow', 'lsmb_<?lsmb dbname ?>__receipt_process');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (42, 'allow', 'lsmb_<?lsmb dbname ?>__receipt_process');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (47, 'allow', 'lsmb_<?lsmb dbname ?>__receipt_process');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (203, 'allow', 'lsmb_<?lsmb dbname ?>__receipt_process');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (204, 'allow', 'lsmb_<?lsmb dbname ?>__receipt_process');


CREATE ROLE "lsmb_<?lsmb dbname ?>__cash_all"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__reconciliation_all",
"lsmb_<?lsmb dbname ?>__payment_process",
"lsmb_<?lsmb dbname ?>__receipt_process";

-- Inventory Control
CREATE ROLE "lsmb_<?lsmb dbname ?>__part_create"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT ALL ON partsvendor, partscustomer TO "lsmb_<?lsmb dbname ?>__part_create";
GRANT INSERT ON parts, makemodel TO "lsmb_<?lsmb dbname ?>__part_create";
GRANT ALL ON parts_id_seq TO "lsmb_<?lsmb dbname ?>__part_create";
GRANT INSERT ON partstax TO "lsmb_<?lsmb dbname ?>__part_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (77, 'allow', 'lsmb_<?lsmb dbname ?>__part_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (78, 'allow', 'lsmb_<?lsmb dbname ?>__part_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (79, 'allow', 'lsmb_<?lsmb dbname ?>__part_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (80, 'allow', 'lsmb_<?lsmb dbname ?>__part_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (81, 'allow', 'lsmb_<?lsmb dbname ?>__part_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (82, 'allow', 'lsmb_<?lsmb dbname ?>__part_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__part_edit"
WITH INHERIT NOLOGIN;

GRANT UPDATE ON parts TO "lsmb_<?lsmb dbname ?>__part_edit";
GRANT ALL ON makemodel TO "lsmb_<?lsmb dbname ?>__part_edit";
--###oldcode: Should have been UPDATE
GRANT ALL ON partstax TO "lsmb_<?lsmb dbname ?>__part_edit";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (77, 'allow', 'lsmb_<?lsmb dbname ?>__part_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (85, 'allow', 'lsmb_<?lsmb dbname ?>__part_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (86, 'allow', 'lsmb_<?lsmb dbname ?>__part_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (87, 'allow', 'lsmb_<?lsmb dbname ?>__part_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (88, 'allow', 'lsmb_<?lsmb dbname ?>__part_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (89, 'allow', 'lsmb_<?lsmb dbname ?>__part_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (90, 'allow', 'lsmb_<?lsmb dbname ?>__part_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (91, 'allow', 'lsmb_<?lsmb dbname ?>__part_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (93, 'allow', 'lsmb_<?lsmb dbname ?>__part_edit');


CREATE ROLE "lsmb_<?lsmb dbname ?>__inventory_reports"
WITH INHERIT NOLOGIN;

GRANT SELECT ON ar TO "lsmb_<?lsmb dbname ?>__inventory_reports";
GRANT SELECT ON ap TO "lsmb_<?lsmb dbname ?>__inventory_reports";
GRANT SELECT ON inventory TO "lsmb_<?lsmb dbname ?>__inventory_reports";
GRANT SELECT ON invoice TO "lsmb_<?lsmb dbname ?>__inventory_reports";
GRANT SELECT ON acc_trans TO "lsmb_<?lsmb dbname ?>__inventory_reports";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (77, 'allow', 'lsmb_<?lsmb dbname ?>__inventory_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (85, 'allow', 'lsmb_<?lsmb dbname ?>__inventory_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (88, 'allow', 'lsmb_<?lsmb dbname ?>__inventory_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (94, 'allow', 'lsmb_<?lsmb dbname ?>__inventory_reports');


CREATE ROLE "lsmb_<?lsmb dbname ?>__pricegroup_create"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT INSERT ON pricegroup TO "lsmb_<?lsmb dbname ?>__pricegroup_create";
GRANT ALL ON pricegroup_id_seq TO "lsmb_<?lsmb dbname ?>__pricegroup_create";
GRANT UPDATE ON entity_credit_account TO "lsmb_<?lsmb dbname ?>__pricegroup_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (77, 'allow', 'lsmb_<?lsmb dbname ?>__pricegroup_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (83, 'allow', 'lsmb_<?lsmb dbname ?>__pricegroup_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__pricegroup_edit"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT UPDATE ON pricegroup TO "lsmb_<?lsmb dbname ?>__pricegroup_edit";
GRANT UPDATE ON entity_credit_account TO "lsmb_<?lsmb dbname ?>__pricegroup_edit";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (77, 'allow', 'lsmb_<?lsmb dbname ?>__pricegroup_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (85, 'allow', 'lsmb_<?lsmb dbname ?>__pricegroup_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (92, 'allow', 'lsmb_<?lsmb dbname ?>__pricegroup_edit');

CREATE ROLE "lsmb_<?lsmb dbname ?>__assembly_stock"
WITH INHERIT NOLOGIN;

GRANT UPDATE ON parts TO "lsmb_<?lsmb dbname ?>__assembly_stock";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (77, 'allow', 'lsmb_<?lsmb dbname ?>__assembly_stock');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (84, 'allow', 'lsmb_<?lsmb dbname ?>__assembly_stock');


CREATE ROLE "lsmb_<?lsmb dbname ?>__inventory_ship"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__sales_order_list";

GRANT INSERT ON inventory TO "lsmb_<?lsmb dbname ?>__inventory_ship";
GRANT ALL ON inventory_entry_id_seq TO "lsmb_<?lsmb dbname ?>__inventory_ship";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (63, 'allow', 'lsmb_<?lsmb dbname ?>__inventory_ship');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (64, 'allow', 'lsmb_<?lsmb dbname ?>__inventory_ship');


CREATE ROLE "lsmb_<?lsmb dbname ?>__inventory_receive"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__purchase_order_list";

GRANT INSERT ON inventory TO "lsmb_<?lsmb dbname ?>__inventory_receive";
GRANT ALL ON inventory_entry_id_seq TO "lsmb_<?lsmb dbname ?>__inventory_receive";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (63, 'allow', 'lsmb_<?lsmb dbname ?>__inventory_receive');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (65, 'allow', 'lsmb_<?lsmb dbname ?>__inventory_receive');


CREATE ROLE "lsmb_<?lsmb dbname ?>__inventory_transfer"
WITH INHERIT NOLOGIN;

GRANT INSERT ON inventory TO "lsmb_<?lsmb dbname ?>__inventory_transfer";
GRANT ALL ON inventory_entry_id_seq TO "lsmb_<?lsmb dbname ?>__inventory_transfer";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (63, 'allow', 'lsmb_<?lsmb dbname ?>__inventory_transfer');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (66, 'allow', 'lsmb_<?lsmb dbname ?>__inventory_transfer');

CREATE ROLE "lsmb_<?lsmb dbname ?>__warehouse_create"
WITH INHERIT NOLOGIN;

GRANT INSERT ON warehouse TO "lsmb_<?lsmb dbname ?>__warehouse_create";
GRANT ALL ON warehouse_id_seq TO "lsmb_<?lsmb dbname ?>__warehouse_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__warehouse_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (141, 'allow', 'lsmb_<?lsmb dbname ?>__warehouse_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (142, 'allow', 'lsmb_<?lsmb dbname ?>__warehouse_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__warehouse_edit"
WITH INHERIT NOLOGIN;

GRANT UPDATE ON warehouse TO "lsmb_<?lsmb dbname ?>__warehouse_edit";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__warehouse_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (141, 'allow', 'lsmb_<?lsmb dbname ?>__warehouse_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (143, 'allow', 'lsmb_<?lsmb dbname ?>__warehouse_edit');


CREATE ROLE "lsmb_<?lsmb dbname ?>__inventory_all"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__part_create",
"lsmb_<?lsmb dbname ?>__inventory_reports",
"lsmb_<?lsmb dbname ?>__assembly_stock",
"lsmb_<?lsmb dbname ?>__inventory_ship",
"lsmb_<?lsmb dbname ?>__inventory_receive",
"lsmb_<?lsmb dbname ?>__inventory_transfer",
"lsmb_<?lsmb dbname ?>__warehouse_edit",
"lsmb_<?lsmb dbname ?>__warehouse_create";

-- GL 
CREATE ROLE "lsmb_<?lsmb dbname ?>__gl_transaction_create"
WITH INHERIT NOLOGIN;

GRANT SELECT, INSERT, UPDATe ON gl 
TO "lsmb_<?lsmb dbname ?>__gl_transaction_create";
GRANT INSERT ON acc_trans TO "lsmb_<?lsmb dbname ?>__gl_transaction_create";
GRANT ALL ON id TO "lsmb_<?lsmb dbname ?>__gl_transaction_create";
GRANT ALL ON acc_trans_entry_id_seq TO "lsmb_<?lsmb dbname ?>__gl_transaction_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (73, 'allow', 'lsmb_<?lsmb dbname ?>__gl_transaction_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (74, 'allow', 'lsmb_<?lsmb dbname ?>__gl_transaction_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (75, 'allow', 'lsmb_<?lsmb dbname ?>__gl_transaction_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (35, 'allow', 'lsmb_<?lsmb dbname ?>__gl_transaction_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (40, 'allow', 'lsmb_<?lsmb dbname ?>__gl_transaction_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__gl_voucher_create"
WITH INHERIT NOLOGIN;

GRANT INSERT ON gl TO "lsmb_<?lsmb dbname ?>__gl_voucher_create";
GRANT INSERT ON acc_trans TO "lsmb_<?lsmb dbname ?>__gl_voucher_create";
GRANT ALL ON id TO "lsmb_<?lsmb dbname ?>__gl_voucher_create";
GRANT ALL ON acc_trans_entry_id_seq TO "lsmb_<?lsmb dbname ?>__gl_voucher_create";

-- TODO Add menu permissions

CREATE ROLE "lsmb_<?lsmb dbname ?>__gl_reports"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__ar_transaction_list",
"lsmb_<?lsmb dbname ?>__ap_transaction_list";

GRANT SELECT ON gl, acc_trans, account_checkpoint 
TO "lsmb_<?lsmb dbname ?>__gl_reports";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (73, 'allow', 'lsmb_<?lsmb dbname ?>__gl_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (76, 'allow', 'lsmb_<?lsmb dbname ?>__gl_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (105, 'allow', 'lsmb_<?lsmb dbname ?>__gl_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (114, 'allow', 'lsmb_<?lsmb dbname ?>__gl_reports');


CREATE ROLE "lsmb_<?lsmb dbname ?>__yearend_run"
WITH INHERIT NOLOGIN;

GRANT INSERT, SELECT ON acc_trans, account_checkpoint, yearend
TO "lsmb_<?lsmb dbname ?>__yearend_run";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__yearend_run');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (132, 'allow', 'lsmb_<?lsmb dbname ?>__yearend_run');


CREATE ROLE "lsmb_<?lsmb dbname ?>__batch_list"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__gl_reports";

GRANT SELECT ON batch TO "lsmb_<?lsmb dbname ?>__batch_list";
GRANT SELECT ON batch_class TO "lsmb_<?lsmb dbname ?>__batch_list";
GRANT SELECT ON voucher TO "lsmb_<?lsmb dbname ?>__batch_list";

CREATE ROLE "lsmb_<?lsmb dbname ?>__gl_all"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__gl_transaction_create",
"lsmb_<?lsmb dbname ?>__gl_voucher_create",
"lsmb_<?lsmb dbname ?>__yearend_run",
"lsmb_<?lsmb dbname ?>__gl_reports";

-- PROJECTS
CREATE ROLE "lsmb_<?lsmb dbname ?>__project_create"
WITH INHERIT NOLOGIN;

GRANT INSERT ON project TO "lsmb_<?lsmb dbname ?>__project_create";
GRANT ALL ON project_id_seq TO "lsmb_<?lsmb dbname ?>__project_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (98, 'allow', 'lsmb_<?lsmb dbname ?>__project_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (99, 'allow', 'lsmb_<?lsmb dbname ?>__project_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__project_edit"
WITH INHERIT NOLOGIN;

GRANT UPDATE ON project TO "lsmb_<?lsmb dbname ?>__project_edit";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (98, 'allow', 'lsmb_<?lsmb dbname ?>__project_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (103, 'allow', 'lsmb_<?lsmb dbname ?>__project_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (104, 'allow', 'lsmb_<?lsmb dbname ?>__project_edit');


CREATE ROLE "lsmb_<?lsmb dbname ?>__project_timecard_add"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT INSERT ON jcitems TO "lsmb_<?lsmb dbname ?>__project_timecard_add";
GRANT ALL ON jcitems_id_seq TO "lsmb_<?lsmb dbname ?>__project_timecard_add";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (98, 'allow', 'lsmb_<?lsmb dbname ?>__project_timecard_add');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (100, 'allow', 'lsmb_<?lsmb dbname ?>__project_timecard_add');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (103, 'allow', 'lsmb_<?lsmb dbname ?>__project_timecard_add');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (106, 'allow', 'lsmb_<?lsmb dbname ?>__project_timecard_add');

CREATE ROLE "lsmb_<?lsmb dbname ?>__project_timecard_list"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT SELECT ON jcitems TO "lsmb_<?lsmb dbname ?>__project_timecard_list";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (98, 'allow', 'lsmb_<?lsmb dbname ?>__project_timecard_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (103, 'allow', 'lsmb_<?lsmb dbname ?>__project_timecard_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (106, 'allow', 'lsmb_<?lsmb dbname ?>__project_timecard_list');



-- ORDER GENERATION
CREATE ROLE "lsmb_<?lsmb dbname ?>__orders_generate"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_read";

GRANT SELECT, INSERT, UPDATE ON oe TO "lsmb_<?lsmb dbname ?>__orders_generate";
GRANT SELECT, INSERT, UPDATE ON orderitems TO "lsmb_<?lsmb dbname ?>__orders_generate";
GRANT ALL ON oe_id_seq TO "lsmb_<?lsmb dbname ?>__orders_generate";
GRANT ALL ON orderitems_id_seq TO "lsmb_<?lsmb dbname ?>__orders_generate";

CREATE ROLE "lsmb_<?lsmb dbname ?>__project_order_generate"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__orders_generate",
"lsmb_<?lsmb dbname ?>__project_timecard_list";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (98, 'allow', 'lsmb_<?lsmb dbname ?>__project_order_generate');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (101, 'allow', 'lsmb_<?lsmb dbname ?>__project_order_generate');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (102, 'allow', 'lsmb_<?lsmb dbname ?>__project_order_generate');


CREATE ROLE "lsmb_<?lsmb dbname ?>__orders_sales_to_purchase"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__orders_generate";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (50, 'allow', 'lsmb_<?lsmb dbname ?>__orders_sales_to_purchase');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (56, 'allow', 'lsmb_<?lsmb dbname ?>__orders_sales_to_purchase');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (57, 'allow', 'lsmb_<?lsmb dbname ?>__orders_sales_to_purchase');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (58, 'allow', 'lsmb_<?lsmb dbname ?>__orders_sales_to_purchase');


CREATE ROLE "lsmb_<?lsmb dbname ?>__orders_purchase_consolidate"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__orders_generate";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (50, 'allow', 'lsmb_<?lsmb dbname ?>__orders_purchase_consolidate');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (60, 'allow', 'lsmb_<?lsmb dbname ?>__orders_purchase_consolidate');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (62, 'allow', 'lsmb_<?lsmb dbname ?>__orders_purchase_consolidate');


CREATE ROLE "lsmb_<?lsmb dbname ?>__orders_sales_consolidate"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__orders_generate";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (50, 'allow', 'lsmb_<?lsmb dbname ?>__orders_sales_consolidate');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (60, 'allow', 'lsmb_<?lsmb dbname ?>__orders_sales_consolidate');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (61, 'allow', 'lsmb_<?lsmb dbname ?>__orders_sales_consolidate');


CREATE ROLE "lsmb_<?lsmb dbname ?>__orders_manage"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__project_order_generate",
"lsmb_<?lsmb dbname ?>__orders_sales_to_purchase",
"lsmb_<?lsmb dbname ?>__orders_purchase_consolidate",
"lsmb_<?lsmb dbname ?>__orders_sales_consolidate";

-- FINANCIAL REPORTS
CREATE ROLE "lsmb_<?lsmb dbname ?>__financial_reports"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__gl_reports";

GRANT select ON yearend TO "lsmb_<?lsmb dbname ?>__financial_reports";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (109, 'allow', 'lsmb_<?lsmb dbname ?>__financial_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (110, 'allow', 'lsmb_<?lsmb dbname ?>__financial_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (111, 'allow', 'lsmb_<?lsmb dbname ?>__financial_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (112, 'allow', 'lsmb_<?lsmb dbname ?>__financial_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (113, 'allow', 'lsmb_<?lsmb dbname ?>__financial_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (114, 'allow', 'lsmb_<?lsmb dbname ?>__financial_reports');


-- RECURRING TRANSACTIONS
CREATE ROLE "lsmb_<?lsmb dbname ?>__recurring"
WITH INHERIT NOLOGIN;


INSERT INTO menu_acl (node_id, acl_type, role_name)
values (115, 'allow', 'lsmb_<?lsmb dbname ?>__print_jobs_list');

-- BATCH PRINTING
CREATE ROLE "lsmb_<?lsmb dbname ?>__print_jobs_list"
WITH INHERIT NOLOGIN;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (116, 'allow', 'lsmb_<?lsmb dbname ?>__print_jobs_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (117, 'allow', 'lsmb_<?lsmb dbname ?>__print_jobs_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (118, 'allow', 'lsmb_<?lsmb dbname ?>__print_jobs_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (119, 'allow', 'lsmb_<?lsmb dbname ?>__print_jobs_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (120, 'allow', 'lsmb_<?lsmb dbname ?>__print_jobs_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (121, 'allow', 'lsmb_<?lsmb dbname ?>__print_jobs_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (122, 'allow', 'lsmb_<?lsmb dbname ?>__print_jobs_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (123, 'allow', 'lsmb_<?lsmb dbname ?>__print_jobs_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (124, 'allow', 'lsmb_<?lsmb dbname ?>__print_jobs_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (125, 'allow', 'lsmb_<?lsmb dbname ?>__print_jobs_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (126, 'allow', 'lsmb_<?lsmb dbname ?>__print_jobs_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (127, 'allow', 'lsmb_<?lsmb dbname ?>__print_jobs_list');


CREATE ROLE "lsmb_<?lsmb dbname ?>__print_jobs"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__print_jobs_list";


--Tax Forms

CREATE ROLE "lsmb_<?lsmb dbname ?>__tax_form_save"
WITH INHERIT NOLOGIN;

GRANT ALL ON country_tax_form  TO "lsmb_<?lsmb dbname ?>__tax_form_save"; 
GRANT ALL ON country_tax_form_id_seq TO "lsmb_<?lsmb dbname ?>__tax_form_save";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (218, 'allow', 'lsmb_<?lsmb dbname ?>__tax_form_save');

INSERT INTO menu_acl (node_id, acl_type, role_name)
SELECT id, 'allow', 'lsmb_<?lsmb dbname ?>__tax_form_save'
  FROM menu_node WHERE parent = 217 and position in (2,3);
--

-- SYSTEM SETTINGS	
CREATE ROLE "lsmb_<?lsmb dbname ?>__system_settings_list"
WITH INHERIT NOLOGIN;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__system_settings_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (129, 'allow', 'lsmb_<?lsmb dbname ?>__system_settings_list');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (131, 'allow', 'lsmb_<?lsmb dbname ?>__system_settings_list');


CREATE ROLE "lsmb_<?lsmb dbname ?>__system_settings_change"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__system_settings_list";

CREATE ROLE "lsmb_<?lsmb dbname ?>__taxes_set"
WITH INHERIT NOLOGIN;

GRANT INSERT, UPDATE ON tax TO "lsmb_<?lsmb dbname ?>__taxes_set";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__taxes_set');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (130, 'allow', 'lsmb_<?lsmb dbname ?>__taxes_set');


CREATE ROLE "lsmb_<?lsmb dbname ?>__account_create"
WITH INHERIT NOLOGIN;

GRANT INSERT ON chart TO "lsmb_<?lsmb dbname ?>__account_create";
GRANT INSERT ON account, cr_coa_to_account 
TO "lsmb_<?lsmb dbname ?>__account_create";

GRANT ALL ON account_id_seq TO "lsmb_<?lsmb dbname ?>__account_create";
GRANT INSERT ON account_heading TO "lsmb_<?lsmb dbname ?>__account_create";
GRANT ALL ON account_heading_id_seq TO "lsmb_<?lsmb dbname ?>__account_create";
GRANT INSERT ON account_link TO "lsmb_<?lsmb dbname ?>__account_create";
-- account_link no longer appears to have a sequence and references account(id)
--GRANT ALL ON account_link_id_seq TO "lsmb_<?lsmb dbname ?>__account_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__account_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (136, 'allow', 'lsmb_<?lsmb dbname ?>__account_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (137, 'allow', 'lsmb_<?lsmb dbname ?>__account_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__account_edit"
WITH INHERIT NOLOGIN;

GRANT ALL ON account, account_heading, account_link, cr_coa_to_account 
TO "lsmb_<?lsmb dbname ?>__account_edit";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__account_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (136, 'allow', 'lsmb_<?lsmb dbname ?>__account_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (138, 'allow', 'lsmb_<?lsmb dbname ?>__account_edit');

CREATE ROLE "lsmb_<?lsmb dbname ?>__auditor"
WITH INHERIT NOLOGIN;

GRANT SELECT ON audittrail TO "lsmb_<?lsmb dbname ?>__auditor";

CREATE ROLE "lsmb_<?lsmb dbname ?>__audit_trail_maintenance"
WITH INHERIT NOLOGIN;

GRANT DELETE ON audittrail TO "lsmb_<?lsmb dbname ?>__audit_trail_maintenance";

CREATE ROLE "lsmb_<?lsmb dbname ?>__gifi_create"
WITH INHERIT NOLOGIN;

GRANT INSERT ON gifi TO "lsmb_<?lsmb dbname ?>__gifi_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__gifi_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (136, 'allow', 'lsmb_<?lsmb dbname ?>__gifi_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (139, 'allow', 'lsmb_<?lsmb dbname ?>__gifi_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__gifi_edit"
WITH INHERIT NOLOGIN;

GRANT UPDATE ON gifi TO "lsmb_<?lsmb dbname ?>__gifi_edit";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__gifi_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (136, 'allow', 'lsmb_<?lsmb dbname ?>__gifi_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (140, 'allow', 'lsmb_<?lsmb dbname ?>__gifi_edit');


CREATE ROLE "lsmb_<?lsmb dbname ?>__account_all"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__account_create",
"lsmb_<?lsmb dbname ?>__taxes_set",
"lsmb_<?lsmb dbname ?>__account_edit",
"lsmb_<?lsmb dbname ?>__gifi_create",
"lsmb_<?lsmb dbname ?>__gifi_edit";

CREATE ROLE "lsmb_<?lsmb dbname ?>__department_create"
WITH INHERIT NOLOGIN;

GRANT INSERT ON department TO "lsmb_<?lsmb dbname ?>__department_create";
GRANT ALL ON department_id_seq TO "lsmb_<?lsmb dbname ?>__department_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__department_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (144, 'allow', 'lsmb_<?lsmb dbname ?>__department_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (145, 'allow', 'lsmb_<?lsmb dbname ?>__department_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__department_edit"
WITH INHERIT NOLOGIN;

GRANT UPDATE ON department TO "lsmb_<?lsmb dbname ?>__department_edit";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__department_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (144, 'allow', 'lsmb_<?lsmb dbname ?>__department_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (146, 'allow', 'lsmb_<?lsmb dbname ?>__department_edit');


CREATE ROLE "lsmb_<?lsmb dbname ?>__department_all"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__department_create",
"lsmb_<?lsmb dbname ?>__department_edit";

CREATE ROLE "lsmb_<?lsmb dbname ?>__business_type_create"
WITH INHERIT NOLOGIN;

GRANT INSERT ON business TO "lsmb_<?lsmb dbname ?>__business_type_create";
GRANT ALL ON business_id_seq TO "lsmb_<?lsmb dbname ?>__business_type_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__business_type_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (147, 'allow', 'lsmb_<?lsmb dbname ?>__business_type_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (148, 'allow', 'lsmb_<?lsmb dbname ?>__business_type_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__business_type_edit"
WITH INHERIT NOLOGIN;

GRANT UPDATE, DELETE ON business TO "lsmb_<?lsmb dbname ?>__business_type_edit";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__business_type_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (147, 'allow', 'lsmb_<?lsmb dbname ?>__business_type_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (149, 'allow', 'lsmb_<?lsmb dbname ?>__business_type_edit');


CREATE ROLE "lsmb_<?lsmb dbname ?>__business_type_all"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__business_type_create",
"lsmb_<?lsmb dbname ?>__business_type_edit";

CREATE ROLE "lsmb_<?lsmb dbname ?>__sic_create"
WITH INHERIT NOLOGIN;

GRANT INSERT ON sic TO "lsmb_<?lsmb dbname ?>__sic_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__sic_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (153, 'allow', 'lsmb_<?lsmb dbname ?>__sic_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (154, 'allow', 'lsmb_<?lsmb dbname ?>__sic_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__sic_edit"
WITH INHERIT NOLOGIN;

GRANT UPDATE ON sic TO "lsmb_<?lsmb dbname ?>__sic_edit";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__sic_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (153, 'allow', 'lsmb_<?lsmb dbname ?>__sic_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (155, 'allow', 'lsmb_<?lsmb dbname ?>__sic_edit');


CREATE ROLE "lsmb_<?lsmb dbname ?>__sic_all"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__sic_create",
"lsmb_<?lsmb dbname ?>__sic_edit";


CREATE ROLE "lsmb_<?lsmb dbname ?>__template_edit"
WITH INHERIT NOLOGIN;


-- TODO Add db permissions as templates get moved into db.

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (156, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (157, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (158, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (159, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (160, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (161, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (162, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (163, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (164, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (165, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (166, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (167, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (168, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (169, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (170, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (171, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (172, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (173, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (174, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (175, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (176, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (177, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (178, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (179, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (180, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (181, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (182, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (183, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (184, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (185, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (186, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (187, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (188, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (189, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (190, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (241, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (242, 'allow', 'lsmb_<?lsmb dbname ?>__template_edit');

CREATE ROLE "lsmb_<?lsmb dbname ?>__users_manage"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__contact_edit",
"lsmb_<?lsmb dbname ?>__contact_create";

GRANT SELECT ON role_view TO "lsmb_<?lsmb dbname ?>__users_manage";
GRANT EXECUTE ON FUNCTION  admin__add_user_to_role(TEXT, TEXT) 
TO "lsmb_<?lsmb dbname ?>__users_manage";
GRANT EXECUTE ON FUNCTION  admin__remove_user_from_role(TEXT, TEXT)
TO "lsmb_<?lsmb dbname ?>__users_manage";
GRANT EXECUTE ON FUNCTION  admin__add_function_to_group(TEXT, TEXT)
TO "lsmb_<?lsmb dbname ?>__users_manage";
GRANT EXECUTE ON FUNCTION  admin__remove_function_from_group(text, text)
TO "lsmb_<?lsmb dbname ?>__users_manage";
GRANT EXECUTE ON FUNCTION  admin__get_roles_for_user(INT)
TO "lsmb_<?lsmb dbname ?>__users_manage";
GRANT EXECUTE ON FUNCTION  admin__save_user(int, INT, text, TEXT, BOOL) 
TO "lsmb_<?lsmb dbname ?>__users_manage";
GRANT EXECUTE ON FUNCTION  admin__create_group(TEXT)
TO "lsmb_<?lsmb dbname ?>__users_manage";
GRANT EXECUTE ON FUNCTION  admin__delete_user(text, bool)
TO "lsmb_<?lsmb dbname ?>__users_manage";
GRANT EXECUTE ON FUNCTION  admin__list_roles(text)
TO "lsmb_<?lsmb dbname ?>__users_manage";
GRANT EXECUTE ON FUNCTION  admin__delete_group(text)
TO "lsmb_<?lsmb dbname ?>__users_manage";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (220, 'allow', 'lsmb_<?lsmb dbname ?>__users_manage');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (221, 'allow', 'lsmb_<?lsmb dbname ?>__users_manage');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (222, 'allow', 'lsmb_<?lsmb dbname ?>__users_manage');

CREATE ROLE "lsmb_<?lsmb dbname ?>__backup"
WITH INHERIT NOLOGIN;

-- TODO GRANT SELECT ON ALL TABLES

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (134, 'allow', 'lsmb_<?lsmb dbname ?>__backup');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (135, 'allow', 'lsmb_<?lsmb dbname ?>__backup');


CREATE ROLE "lsmb_<?lsmb dbname ?>__system_admin"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__system_settings_change",
"lsmb_<?lsmb dbname ?>__account_all",
"lsmb_<?lsmb dbname ?>__department_all",
"lsmb_<?lsmb dbname ?>__business_type_all",
"lsmb_<?lsmb dbname ?>__sic_all",
"lsmb_<?lsmb dbname ?>__template_edit",
"lsmb_<?lsmb dbname ?>__users_manage",
"lsmb_<?lsmb dbname ?>__backup",
"lsmb_<?lsmb dbname ?>__tax_form_save";

-- Manual Translation
CREATE ROLE "lsmb_<?lsmb dbname ?>__language_create"
WITH INHERIT NOLOGIN;

GRANT INSERT ON language TO "lsmb_<?lsmb dbname ?>__language_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__language_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (150, 'allow', 'lsmb_<?lsmb dbname ?>__language_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (151, 'allow', 'lsmb_<?lsmb dbname ?>__language_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__language_edit"
WITH INHERIT NOLOGIN;

GRANT UPDATE ON language TO "lsmb_<?lsmb dbname ?>__language_edit";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__language_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (150, 'allow', 'lsmb_<?lsmb dbname ?>__language_edit');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (152, 'allow', 'lsmb_<?lsmb dbname ?>__language_edit');


CREATE ROLE "lsmb_<?lsmb dbname ?>__part_translation_create"
WITH INHERIT NOLOGIN;

GRANT ALL ON parts_translation 
TO "lsmb_<?lsmb dbname ?>__part_translation_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (77, 'allow', 'lsmb_<?lsmb dbname ?>__part_translation_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (95, 'allow', 'lsmb_<?lsmb dbname ?>__part_translation_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (96, 'allow', 'lsmb_<?lsmb dbname ?>__part_translation_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (97, 'allow', 'lsmb_<?lsmb dbname ?>__part_translation_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__project_translation_create"
WITH INHERIT NOLOGIN;

GRANT ALL ON project_translation 
TO "lsmb_<?lsmb dbname ?>__project_translation_create";

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (98, 'allow', 'lsmb_<?lsmb dbname ?>__project_translation_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (107, 'allow', 'lsmb_<?lsmb dbname ?>__project_translation_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (108, 'allow', 'lsmb_<?lsmb dbname ?>__project_translation_create');

CREATE ROLE "lsmb_<?lsmb dbname ?>__partsgroup_translation_create"
WITH INHERIT NOLOGIN;

GRANT ALL ON partsgroup_translation
TO "lsmb_<?lsmb dbname ?>__partsgroup_translation_create";
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (98, 'allow', 'lsmb_<?lsmb dbname ?>__partsgroup_translation_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (107, 'allow', 'lsmb_<?lsmb dbname ?>__partsgroup_translation_create');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (108, 'allow', 'lsmb_<?lsmb dbname ?>__partsgroup_translation_create');


CREATE ROLE "lsmb_<?lsmb dbname ?>__manual_translation_all"
WITH INHERIT NOLOGIN
IN ROLE "lsmb_<?lsmb dbname ?>__language_create",
"lsmb_<?lsmb dbname ?>__part_translation_create",
"lsmb_<?lsmb dbname ?>__partsgroup_translation_create",
"lsmb_<?lsmb dbname ?>__project_translation_create";

-- Fixed Assets

CREATE ROLE "lsmb_<?lsmb dbname ?>__assets_administer" NOLOGIN INHERIT;

GRANT INSERT, UPDATE, SELECT, DELETE ON asset_class 
TO "lsmb_<?lsmb dbname ?>__assets_administer";
GRANT SELECT, UPDATE ON asset_class_id_seq
TO "lsmb_<?lsmb dbname ?>__assets_administer";

INSERT INTO menu_acl(role_name, acl_type, node_id)
values('lsmb_<?lsmb dbname ?>__assets_enter', 'allow', 237);


CREATE ROLE "lsmb_<?lsmb dbname ?>__assets_enter" NOLOGIN INHERIT;

GRANT ALL ON asset_item_id_seq TO "lsmb_<?lsmb dbname ?>__assets_enter";
GRANT INSERT, UPDATE ON asset_item
TO "lsmb_<?lsmb dbname ?>__assets_enter";

GRANT INSERT, SELECT ON asset_note TO "lsmb_<?lsmb dbname ?>__assets_enter";

INSERT INTO menu_acl(role_name, acl_type, node_id)
values('lsmb_<?lsmb dbname ?>__assets_enter', 'allow', 230);
INSERT INTO menu_acl(role_name, acl_type, node_id)
values('lsmb_<?lsmb dbname ?>__assets_enter', 'allow', 231);
INSERT INTO menu_acl(role_name, acl_type, node_id)
values('lsmb_<?lsmb dbname ?>__assets_enter', 'allow', 232);
INSERT INTO menu_acl(role_name, acl_type, node_id)
values('lsmb_<?lsmb dbname ?>__assets_enter', 'allow', 233);
INSERT INTO menu_acl(role_name, acl_type, node_id)
values('lsmb_<?lsmb dbname ?>__assets_enter', 'allow', 235);

CREATE ROLE "lsmb_<?lsmb dbname ?>__assets_depreciate" NOLOGIN INHERIT;
GRANT SELECT, INSERT ON asset_report, asset_report_line, asset_item, asset_class
TO "lsmb_<?lsmb dbname ?>__assets_depreciate";

INSERT INTO menu_acl(role_name, acl_type, node_id)
values('lsmb_<?lsmb dbname ?>__assets_depreciate', 'allow', 238);
INSERT INTO menu_acl(role_name, acl_type, node_id)
values('lsmb_<?lsmb dbname ?>__assets_depreciate', 'allow', 234);

CREATE ROLE "lsmb_<?lsmb dbname ?>__assets_approve" NOLOGIN INHERIT;
GRANT SELECT ON asset_report, asset_report_line, asset_item, asset_class
TO "lsmb_<?lsmb dbname ?>__assets_approve";
GRANT EXECUTE ON FUNCTION  asset_report__approve(int, int, int, int)
TO "lsmb_<?lsmb dbname ?>__assets_approve";
GRANT SELECT ON asset_class, asset_item to public;
GRANT SELECT ON asset_unit_class TO public;
GRANT SELECT ON asset_dep_method TO public;

-- Grants to all users;
GRANT SELECT ON makemodel TO public;
GRANT SELECT ON custom_field_catalog TO public;
GRANT SELECT ON custom_table_catalog TO public;
GRANT SELECT ON oe_class TO public;
GRANT SELECT ON note_class TO public;
GRANT ALL ON defaults TO public;
GRANT ALL ON "session" TO public;
GRANT ALL ON session_session_id_seq TO PUBLIC;
GRANT SELECT ON users TO public;
GRANT ALL ON user_preference TO public;
GRANT SELECT ON user_listable TO public;
GRANT SELECT ON custom_table_catalog TO PUBLIC;
GRANT SELECT ON custom_field_catalog TO PUBLIC;
grant select on menu_node, menu_attribute, menu_acl to public;
GRANT select on chart, gifi, country to public;
GRANT SELECT ON parts, partsgroup TO public;
GRANT SELECT ON language, project TO public;
GRANT SELECT ON business, exchangerate, department, new_shipto, tax TO public;
GRANT ALL ON recurring, recurringemail, recurringprint, status TO public; 
GRANT ALL ON transactions, entity_employee TO public;
GRANT ALL ON pending_job, payments_queue TO PUBLIC;
GRANT ALL ON pending_job_id_seq TO public;
GRANT ALL ON invoice_tax_form TO public;
GRANT SELECT ON taxmodule TO public;
GRANT ALL ON ac_tax_form to public;
GRANT SELECT ON country_tax_form to public;
GRANT SELECT ON translation TO public;
GRANT SELECT ON pricegroup TO public;
GRANT SELECT ON partstax TO public;
GRANT SELECT ON salutation TO public;
GRANT SELECT ON partscustomer TO public;
GRANT SELECT ON assembly TO public;
GRANT SELECT ON jcitems TO public;
GRANT SELECT ON payment_type TO public;
GRANT SELECT ON lsmb_roles TO public;
GRANT SELECT ON employee_search TO PUBLIC;
GRANT SELECT ON warehouse TO public;
GRANT SELECT ON voucher TO public;
GRANT select ON account, account_link, account_link_description TO PUBLIC;
GRANT select ON sic TO public;
GRANT SELECT ON parts_translation,  partsgroup_translation, 
                project_translation TO public;
GRANT SELECT ON asset_report_class, asset_rl_to_disposal_method,
                asset_disposal_method TO PUBLIC;
GRANT SELECT ON mime_type, file_class TO PUBLIC;

GRANT EXECUTE ON FUNCTION user__get_all_users() TO public;

--TODO, lock recurring, pending_job, payment_queue down more
-- Roles with no db permissions:
CREATE ROLE "lsmb_<?lsmb dbname ?>__draft_edit" WITH INHERIT NOLOGIN;

-- CT:  The following grant is required for now, but will hopefully become less 
-- important when we get to 1.4 and can more sensibly lock things down.
GRANT ALL ON dpt_trans TO public;

-- Roles dependant on FUNCTIONS
CREATE ROLE "lsmb_<?lsmb dbname ?>__voucher_delete" 
WITH INHERIT NOLOGIN;

GRANT EXECUTE ON FUNCTION voucher__delete(int) 
TO "lsmb_<?lsmb dbname ?>__voucher_delete";

GRANT EXECUTE ON FUNCTION batch_delete(int) 
TO "lsmb_<?lsmb dbname ?>__voucher_delete";


INSERT INTO menu_acl (node_id, acl_type, role_name)
values (191, 'allow', 'public');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (192, 'allow', 'public');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (193, 'allow', 'public');
