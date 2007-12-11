GRANT ALL ON SCHEMA public TO public; -- required for Pg 8.2
-- Contacts
CREATE ROLE lsmb_<?lsmb dbname ?>__read_contact
WITH INHERIT NOLOGIN;

GRANT SELECT ON entity TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON company TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON location TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON person TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON entity_credit_account TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON company_to_contact TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON company_to_entity TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON company_to_location TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON customertax TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON contact_class TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON entity_class TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON entity_bank_account TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON entity_note TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON entity_class_to_entity TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON entity_other_name TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON location_class TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON person_to_company TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON person_to_contact TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON person_to_contact TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON person_to_location TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON person_to_location TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON company_to_location TO lsmb_<?lsmb dbname ?>__read_contact;
GRANT SELECT ON vendortax TO lsmb_<?lsmb dbname ?>__read_contact;

INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (1, 'allow', 'lsmb_<?lsmb dbname ?>__read_contact');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (11, 'allow', 'lsmb_<?lsmb dbname ?>__read_contact');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (14, 'allow', 'lsmb_<?lsmb dbname ?>__read_contact');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (21, 'allow', 'lsmb_<?lsmb dbname ?>__read_contact');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (30, 'allow', 'lsmb_<?lsmb dbname ?>__read_contact');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (33, 'allow', 'lsmb_<?lsmb dbname ?>__read_contact');


CREATE ROLE lsmb_<?lsmb dbname ?>__create_contact
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT INSERT ON entity TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT ALL ON entity_id_seq TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON company TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT ALL ON company_id_seq TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT ALL ON location_id_seq TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON person TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT ALL ON person_id_seq TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON entity_credit_account TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT ALL ON entity_credit_account_id_seq TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON company_to_contact TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON company_to_entity TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON company_to_location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON customertax TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON entity_bank_account TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT ALL ON entity_bank_account_id_seq TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON entity_note TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON entity_class_to_entity TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON entity_other_name TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON person_to_company TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON person_to_contact TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON person_to_contact TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON person_to_location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON person_to_location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON company_to_location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT DELETE ON company_to_location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON vendortax TO lsmb_<?lsmb dbname ?>__create_contact;

INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (1, 'allow', 'lsmb_<?lsmb dbname ?>__create_contact');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (11, 'allow', 'lsmb_<?lsmb dbname ?>__create_contact');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (12, 'allow', 'lsmb_<?lsmb dbname ?>__create_contact');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (21, 'allow', 'lsmb_<?lsmb dbname ?>__create_contact');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (30, 'allow', 'lsmb_<?lsmb dbname ?>__create_contact');
INSERT INTO menu_acl (node_id, acl_type, role_name) 
values (31, 'allow', 'lsmb_<?lsmb dbname ?>__create_contact');


CREATE ROLE lsmb_<?lsmb dbname ?>__edit_contact
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT UPDATE ON entity TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON company TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON person TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON entity_credit_account TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON company_to_contact TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON company_to_entity TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON company_to_location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON customertax TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON entity_bank_account TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON entity_note TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON entity_class_to_entity TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON entity_other_name TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON person_to_company TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON person_to_contact TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON person_to_contact TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON person_to_location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON person_to_location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT DELETE, INSERT  ON vendortax TO lsmb_<?lsmb dbname ?>__create_contact;

CREATE ROLE lsmb_<?lsmb dbname ?>__contact_all_rights
WITH INHERIT NOLOGIN 
in role lsmb_<?lsmb dbname ?>__create_contact, 
lsmb_<?lsmb dbname ?>__edit_contact,
lsmb_<?lsmb dbname ?>__read_contact;

-- Batches and VOuchers
CREATE ROLE lsmb_<?lsmb dbname ?>__create_batch
WITH INHERIT NOLOGIN;

GRANT INSERT ON batch TO lsmb_<?lsmb dbname ?>__create_batch;
GRANT ALL ON batch_id_seq TO lsmb_<?lsmb dbname ?>__create_batch;
GRANT SELECT ON batch_class TO lsmb_<?lsmb dbname ?>__create_batch;
GRANT INSERT ON voucher TO lsmb_<?lsmb dbname ?>__create_batch;
GRANT ALL ON voucher_id_seq TO lsmb_<?lsmb dbname ?>__create_contact;

-- TODO add Menu ACLs

CREATE ROLE lsmb_<?lsmb dbname ?>__post_batches
WITH INHERIT NOLOGIN;

GRANT UPDATE ON ar TO lsmb_<?lsmb dbname ?>__post_batches;
GRANT UPDATE ON ap TO lsmb_<?lsmb dbname ?>__post_batches;
GRANT UPDATE ON acc_trans TO lsmb_<?lsmb dbname ?>__post_batches;
GRANT UPDATE ON batch TO lsmb_<?lsmb dbname ?>__post_batches;
GRANT UPDATE ON gl TO lsmb_<?lsmb dbname ?>__post_batches;

-- TODO add Menu ACLs

-- AR
CREATE ROLE lsmb_<?lsmb dbname ?>__create_ar_transaction
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT INSERT ON ar TO lsmb_<?lsmb dbname ?>__create_ar_transaction;
GRANT ALL ON id TO lsmb_<?lsmb dbname ?>__create_ar_transaction;
GRANT INSERT ON acc_trans TO lsmb_<?lsmb dbname ?>__create_ar_transaction;
GRANT ALL ON acc_trans_entry_id_seq TO lsmb_<?lsmb dbname ?>__create_ar_transaction;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (1, 'allow', 'lsmb_<?lsmb dbname ?>__create_ar_transaction');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (2, 'allow', 'lsmb_<?lsmb dbname ?>__create_ar_transaction');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (194, 'allow', 'lsmb_<?lsmb dbname ?>__create_ar_transaction');

CREATE ROLE lsmb_<?lsmb dbname ?>__create_ar_transaction_voucher
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact,
lsmb_<?lsmb dbname ?>__create_batch;

GRANT INSERT ON ar TO lsmb_<?lsmb dbname ?>__create_ar_transaction_voucher;
GRANT ALL ON id TO lsmb_<?lsmb dbname ?>__create_ar_transaction_voucher;
GRANT INSERT ON acc_trans TO lsmb_<?lsmb dbname ?>__create_ar_transaction_voucher;
GRANT ALL ON acc_trans_entry_id_seq TO lsmb_<?lsmb dbname ?>__create_ar_transaction_voucher;

-- TODO add Menu ACLs

CREATE ROLE lsmb_<?lsmb dbname ?>__create_ar_invoice
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact,
lsmb_<?lsmb dbname ?>__create_ar_transaction;

GRANT INSERT ON invoice TO lsmb_<?lsmb dbname ?>__create_ar_invoice;
GRANT ALL ON invoice_id_seq TO lsmb_<?lsmb dbname ?>__create_ar_invoice;
GRANT INSERT ON inventory TO lsmb_<?lsmb dbname ?>__create_ar_invoice;
GRANT ALL ON inventory_entry_id_seq TO lsmb_<?lsmb dbname ?>__create_ar_invoice;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (3, 'allow', 'lsmb_<?lsmb dbname ?>__create_ar_invoice');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (195, 'allow', 'lsmb_<?lsmb dbname ?>__create_ar_transaction');


CREATE ROLE lsmb_<?lsmb dbname ?>__create_ar_invoice_voucher
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact,
lsmb_<?lsmb dbname ?>__create_batch,
lsmb_<?lsmb dbname ?>__create_ar_transaction_voucher;

GRANT INSERT ON invoice TO lsmb_<?lsmb dbname ?>__create_ar_invoice_voucher;
GRANT ALL ON invoice_id_seq TO lsmb_<?lsmb dbname ?>__create_ar_invoice_voucher;
GRANT INSERT ON inventory TO lsmb_<?lsmb dbname ?>__create_ar_invoice_voucher;
GRANT ALL ON inventory_entry_id_seq TO lsmb_<?lsmb dbname ?>__create_ar_invoice_voucher;

-- TODO add Menu ACLs

CREATE ROLE lsmb_<?lsmb dbname ?>__list_ar_transactions
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT SELECT ON ar TO lsmb_<?lsmb dbname ?>__list_ar_transactions;
GRANT SELECT ON acc_trans TO lsmb_<?lsmb dbname ?>__list_ar_transactions;
GRANT SELECT ON invoice TO lsmb_<?lsmb dbname ?>__list_ar_transactions;
GRANT SELECT ON inventory TO lsmb_<?lsmb dbname ?>__list_ar_transactions;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (1, 'allow', 'lsmb_<?lsmb dbname ?>__list_ar_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (4, 'allow', 'lsmb_<?lsmb dbname ?>__list_ar_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (5, 'allow', 'lsmb_<?lsmb dbname ?>__list_ar_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (6, 'allow', 'lsmb_<?lsmb dbname ?>__list_ar_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (7, 'allow', 'lsmb_<?lsmb dbname ?>__list_ar_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (9, 'allow', 'lsmb_<?lsmb dbname ?>__list_ar_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (10, 'allow', 'lsmb_<?lsmb dbname ?>__list_ar_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (11, 'allow', 'lsmb_<?lsmb dbname ?>__list_ar_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (13, 'allow', 'lsmb_<?lsmb dbname ?>__list_ar_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (15, 'allow', 'lsmb_<?lsmb dbname ?>__list_ar_transactions');

CREATE ROLE lsmb_<?lsmb dbname ?>__ar_all_vouchers
WITH INHERIT NOLOGIN 
IN ROLE lsmb_<?lsmb dbname ?>__create_ar_transaction_voucher,
lsmb_<?lsmb dbname ?>__create_ar_invoice_voucher;

CREATE ROLE lsmb_<?lsmb dbname ?>__ar_all_transactions
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_ar_transaction,
lsmb_<?lsmb dbname ?>__create_ar_invoice,
lsmb_<?lsmb dbname ?>__list_ar_transactions;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_sales_order
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT INSERT ON oe TO lsmb_<?lsmb dbname ?>__create_sales_order;
GRANT ALL ON oe_id_seq TO lsmb_<?lsmb dbname ?>__create_sales_order;
GRANT INSERT ON orderitems TO lsmb_<?lsmb dbname ?>__create_sales_order;
GRANT ALL ON orderitems_id_seq TO lsmb_<?lsmb dbname ?>__create_sales_order;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (50, 'allow', 'lsmb_<?lsmb dbname ?>__create_sales_order');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (51, 'allow', 'lsmb_<?lsmb dbname ?>__create_sales_order');


CREATE ROLE lsmb_<?lsmb dbname ?>__create_sales_quotation
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT INSERT ON oe TO lsmb_<?lsmb dbname ?>__create_sales_quotation;
GRANT ALL ON oe_id_seq TO lsmb_<?lsmb dbname ?>__create_sales_quotation;
GRANT INSERT ON orderitems TO lsmb_<?lsmb dbname ?>__create_sales_quotation;
GRANT ALL ON orderitems_id_seq TO lsmb_<?lsmb dbname ?>__create_sales_quotation;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (67, 'allow', 'lsmb_<?lsmb dbname ?>__create_sales_quotation');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (68, 'allow', 'lsmb_<?lsmb dbname ?>__create_sales_quotation');


CREATE ROLE lsmb_<?lsmb dbname ?>__list_sales_orders
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT SELECT ON oe TO lsmb_<?lsmb dbname ?>__list_sales_orders;
GRANT SELECT ON orderitems TO lsmb_<?lsmb dbname ?>__list_sales_orders;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (50, 'allow', 'lsmb_<?lsmb dbname ?>__list_sales_orders');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (53, 'allow', 'lsmb_<?lsmb dbname ?>__list_sales_orders');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (54, 'allow', 'lsmb_<?lsmb dbname ?>__list_sales_orders');


CREATE ROLE lsmb_<?lsmb dbname ?>__list_sales_quotations
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT SELECT ON oe TO lsmb_<?lsmb dbname ?>__list_sales_quotations;
GRANT SELECT ON orderitems TO lsmb_<?lsmb dbname ?>__list_sales_quotations;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (67, 'allow', 'lsmb_<?lsmb dbname ?>__list_sales_quotations');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (70, 'allow', 'lsmb_<?lsmb dbname ?>__list_sales_quotations');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (71, 'allow', 'lsmb_<?lsmb dbname ?>__list_sales_quotations');


CREATE ROLE lsmb_<?lsmb dbname ?>__all_ar
WITH INHERIT NOLOGIN 
IN ROLE lsmb_<?lsmb dbname ?>__ar_all_vouchers,
lsmb_<?lsmb dbname ?>__ar_all_transactions,
lsmb_<?lsmb dbname ?>__create_sales_order,
lsmb_<?lsmb dbname ?>__create_sales_quotation,
lsmb_<?lsmb dbname ?>__list_sales_orders,
lsmb_<?lsmb dbname ?>__list_sales_quotations;

-- AP
CREATE ROLE lsmb_<?lsmb dbname ?>__create_ap_transaction
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT INSERT ON ap TO lsmb_<?lsmb dbname ?>__create_ap_transaction;
GRANT ALL ON id TO lsmb_<?lsmb dbname ?>__create_ap_transaction;
GRANT INSERT ON acc_trans TO lsmb_<?lsmb dbname ?>__create_ap_transaction;
GRANT ALL ON acc_trans_entry_id_seq TO lsmb_<?lsmb dbname ?>__create_ap_transaction;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (21, 'allow', 'lsmb_<?lsmb dbname ?>__create_ap_transaction');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (22, 'allow', 'lsmb_<?lsmb dbname ?>__create_ap_transaction');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (196, 'allow', 'lsmb_<?lsmb dbname ?>__create_ap_transaction');

CREATE ROLE lsmb_<?lsmb dbname ?>__create_ap_transaction_voucher
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact,
lsmb_<?lsmb dbname ?>__create_batch;

GRANT INSERT ON ar TO lsmb_<?lsmb dbname ?>__create_ap_transaction_voucher;
GRANT ALL ON id TO lsmb_<?lsmb dbname ?>__create_ap_transaction_voucher;
GRANT INSERT ON acc_trans TO lsmb_<?lsmb dbname ?>__create_ap_transaction_voucher;
GRANT ALL ON acc_trans_entry_id_seq TO lsmb_<?lsmb dbname ?>__create_ap_transaction_voucher;

-- TODO add Menu ACLs

CREATE ROLE lsmb_<?lsmb dbname ?>__create_ap_invoice
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact,
lsmb_<?lsmb dbname ?>__create_ap_transaction;

GRANT INSERT ON invoice TO lsmb_<?lsmb dbname ?>__create_ap_invoice;
GRANT INSERT ON inventory TO lsmb_<?lsmb dbname ?>__create_ap_invoice;
GRANT ALL ON invoice_id_seq TO lsmb_<?lsmb dbname ?>__create_ap_invoice;
GRANT ALL ON inventory_entry_id_seq TO lsmb_<?lsmb dbname ?>__create_ap_invoice;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (23, 'allow', 'lsmb_<?lsmb dbname ?>__create_ap_invoice');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (197, 'allow', 'lsmb_<?lsmb dbname ?>__create_ap_transaction');


CREATE ROLE lsmb_<?lsmb dbname ?>__create_ap_invoice_voucher
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact,
lsmb_<?lsmb dbname ?>__create_batch;

GRANT INSERT ON invoice TO lsmb_<?lsmb dbname ?>__create_ap_invoice_voucher;
GRANT INSERT ON inventory TO lsmb_<?lsmb dbname ?>__create_ap_invoice_voucher;
GRANT ALL ON invoice_id_seq TO lsmb_<?lsmb dbname ?>__create_ap_invoice_voucher;
GRANT ALL ON inventory_entry_id_seq TO lsmb_<?lsmb dbname ?>__create_ap_invoice_voucher;

-- TODO add Menu ACLs


CREATE ROLE lsmb_<?lsmb dbname ?>__list_ap_transactions
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT SELECT ON ap TO lsmb_<?lsmb dbname ?>__list_ap_transactions;
GRANT SELECT ON acc_trans TO lsmb_<?lsmb dbname ?>__list_ap_transactions;
GRANT SELECT ON invoice TO lsmb_<?lsmb dbname ?>__list_ap_transactions;
GRANT SELECT ON inventory TO lsmb_<?lsmb dbname ?>__list_ap_transactions;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (21, 'allow', 'lsmb_<?lsmb dbname ?>__list_ap_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (24, 'allow', 'lsmb_<?lsmb dbname ?>__list_ap_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (25, 'allow', 'lsmb_<?lsmb dbname ?>__list_ap_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (26, 'allow', 'lsmb_<?lsmb dbname ?>__list_ap_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (27, 'allow', 'lsmb_<?lsmb dbname ?>__list_ap_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (28, 'allow', 'lsmb_<?lsmb dbname ?>__list_ap_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (29, 'allow', 'lsmb_<?lsmb dbname ?>__list_ap_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (30, 'allow', 'lsmb_<?lsmb dbname ?>__list_ap_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (32, 'allow', 'lsmb_<?lsmb dbname ?>__list_ap_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (34, 'allow', 'lsmb_<?lsmb dbname ?>__list_ap_transactions');


CREATE ROLE lsmb_<?lsmb dbname ?>__ap_all_vouchers
WITH INHERIT NOLOGIN 
IN ROLE lsmb_<?lsmb dbname ?>__create_ap_transaction_voucher,
lsmb_<?lsmb dbname ?>__create_ap_invoice_voucher;

CREATE ROLE lsmb_<?lsmb dbname ?>__ap_all_transactions
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_ap_transaction,
lsmb_<?lsmb dbname ?>__create_ap_invoice,
lsmb_<?lsmb dbname ?>__list_ap_transactions;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_purchase_order
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT INSERT ON oe TO lsmb_<?lsmb dbname ?>__create_purchase_order;
GRANT INSERT ON orderitems TO lsmb_<?lsmb dbname ?>__create_purchase_order;
GRANT ALL ON oe_id_seq TO lsmb_<?lsmb dbname ?>__create_purchase_order;
GRANT ALL ON orderitems_id_seq TO lsmb_<?lsmb dbname ?>__create_purchase_order;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (50, 'allow', 'lsmb_<?lsmb dbname ?>__create_purchase_order');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (52, 'allow', 'lsmb_<?lsmb dbname ?>__create_purchase_order');


CREATE ROLE lsmb_<?lsmb dbname ?>__create_purchase_rfq
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT INSERT ON oe TO lsmb_<?lsmb dbname ?>__create_purchase_rfq;
GRANT INSERT ON orderitems TO lsmb_<?lsmb dbname ?>__create_purchase_rfq;
GRANT ALL ON oe_id_seq TO lsmb_<?lsmb dbname ?>__create_purchase_rfq;
GRANT ALL ON orderitems_id_seq TO lsmb_<?lsmb dbname ?>__create_purchase_rfq;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (67, 'allow', 'lsmb_<?lsmb dbname ?>__create_purchase_rfq');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (69, 'allow', 'lsmb_<?lsmb dbname ?>__create_purchase_rfq');


CREATE ROLE lsmb_<?lsmb dbname ?>__list_purchase_orders
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT SELECT ON oe TO lsmb_<?lsmb dbname ?>__list_purchase_orders;
GRANT SELECT ON orderitems TO lsmb_<?lsmb dbname ?>__list_purchase_orders;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (50, 'allow', 'lsmb_<?lsmb dbname ?>__list_purchase_orders');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (53, 'allow', 'lsmb_<?lsmb dbname ?>__list_purchase_orders');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (55, 'allow', 'lsmb_<?lsmb dbname ?>__list_purchase_orders');


CREATE ROLE lsmb_<?lsmb dbname ?>__list_purchase_rfqs
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT SELECT ON oe TO lsmb_<?lsmb dbname ?>__list_purchase_rfqs;
GRANT SELECT ON orderitems TO lsmb_<?lsmb dbname ?>__list_purchase_rfqs;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (67, 'allow', 'lsmb_<?lsmb dbname ?>__list_purchase_rfqs');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (70, 'allow', 'lsmb_<?lsmb dbname ?>__list_purchase_rfqs');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (72, 'allow', 'lsmb_<?lsmb dbname ?>__list_purchase_rfqs');


CREATE ROLE lsmb_<?lsmb dbname ?>__all_ap
WITH INHERIT NOLOGIN 
IN ROLE lsmb_<?lsmb dbname ?>__ap_all_vouchers,
lsmb_<?lsmb dbname ?>__ap_all_transactions,
lsmb_<?lsmb dbname ?>__create_purchase_order,
lsmb_<?lsmb dbname ?>__create_purchase_rfq,
lsmb_<?lsmb dbname ?>__list_purchase_orders,
lsmb_<?lsmb dbname ?>__list_purchase_rfqs;

-- POS
CREATE ROLE lsmb_<?lsmb dbname ?>__create_pos_invoice
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT INSERT ON invoice TO lsmb_<?lsmb dbname ?>__create_pos_invoice;
GRANT INSERT ON inventory TO lsmb_<?lsmb dbname ?>__create_pos_invoice;
GRANT INSERT ON ar TO lsmb_<?lsmb dbname ?>__create_pos_invoice;
GRANT INSERT ON acc_trans TO lsmb_<?lsmb dbname ?>__create_pos_invoice;
GRANT ALL ON id TO lsmb_<?lsmb dbname ?>__create_pos_invoice;
GRANT ALL ON acc_trans_entry_id_seq TO lsmb_<?lsmb dbname ?>__create_pos_invoice;
GRANT ALL ON invoice_id_seq TO lsmb_<?lsmb dbname ?>__create_pos_invoice;
GRANT ALL ON inventory_entry_id_seq TO lsmb_<?lsmb dbname ?>__create_pos_invoice;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (16, 'allow', 'lsmb_<?lsmb dbname ?>__create_pos_invoice');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (17, 'allow', 'lsmb_<?lsmb dbname ?>__create_pos_invoice');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (18, 'allow', 'lsmb_<?lsmb dbname ?>__create_pos_invoice');


CREATE ROLE lsmb_<?lsmb dbname ?>__close_till
WITH INHERIT NOLOGIN;

GRANT INSERT ON gl TO lsmb_<?lsmb dbname ?>__close_till;
GRANT INSERT ON acc_trans TO lsmb_<?lsmb dbname ?>__close_till;
GRANT ALL ON id TO lsmb_<?lsmb dbname ?>__close_till;
GRANT ALL ON acc_trans_entry_id_seq TO lsmb_<?lsmb dbname ?>__close_till;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (16, 'allow', 'lsmb_<?lsmb dbname ?>__close_till');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (19, 'allow', 'lsmb_<?lsmb dbname ?>__close_till');


CREATE ROLE lsmb_<?lsmb dbname ?>__list_all_open
WITH INHERIT NOLOGIN;

GRANT SELECT ON ar TO lsmb_<?lsmb dbname ?>__list_all_open;
GRANT SELECT ON acc_trans TO lsmb_<?lsmb dbname ?>__list_all_open;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (16, 'allow', 'lsmb_<?lsmb dbname ?>__list_all_open');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (18, 'allow', 'lsmb_<?lsmb dbname ?>__list_all_open');


CREATE ROLE lsmb_<?lsmb dbname ?>__pos_cashier
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_pos_invoice,
lsmb_<?lsmb dbname ?>__close_till;

CREATE ROLE lsmb_<?lsmb dbname ?>__all_pos
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__pos_cashier,
lsmb_<?lsmb dbname ?>__list_all_open;

-- CASH
CREATE ROLE lsmb_<?lsmb dbname ?>__reconcile
WITH INHERIT NOLOGIN;

-- GRANT INSERT ON pending_reports TO lsmb_<?lsmb dbname ?>__reconcile;
-- GRANT INSERT on report_corrections TO lsmb_<?lsmb dbname ?>__reconcile;
GRANT SELECT ON acc_trans TO lsmb_<?lsmb dbname ?>__reconcile;
-- GRANT ALL ON pending_reports_id_seq TO lsmb_<?lsmb dbname ?>__reconcile;
-- GRANT ALL ON report_corrections_id_seq TO lsmb_<?lsmb dbname ?>__reconcile;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (35, 'allow', 'lsmb_<?lsmb dbname ?>_reconcile');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (45, 'allow', 'lsmb_<?lsmb dbname ?>_reconcile');


CREATE ROLE lsmb_<?lsmb dbname ?>__approve_reconciliation
WITH INHERIT NOLOGIN;

-- GRANT UPDATE ON pending_reports TO lsmb_<?lsmb dbname ?>__reconcile;
GRANT SELECT ON acc_trans TO lsmb_<?lsmb dbname ?>__reconcile;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (35, 'allow', 'lsmb_<?lsmb dbname ?>_reconcile');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (41, 'allow', 'lsmb_<?lsmb dbname ?>_reconcile');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (44, 'allow', 'lsmb_<?lsmb dbname ?>_reconcile');


CREATE ROLE lsmb_<?lsmb dbname ?>__all_reconcile
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__reconcile,
lsmb_<?lsmb dbname ?>__approve_reconciliation;

CREATE ROLE lsmb_<?lsmb dbname ?>__process_payment
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__list_ap_transactions;

GRANT INSERT ON acc_trans TO lsmb_<?lsmb dbname ?>__process_payment;
GRANT ALL ON acc_trans_entry_id_seq TO lsmb_<?lsmb dbname ?>__process_payment;


INSERT INTO menu_acl (node_id, acl_type, role_name)
values (35, 'allow', 'lsmb_<?lsmb dbname ?>__process_payment');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (38, 'allow', 'lsmb_<?lsmb dbname ?>__process_payment');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (39, 'allow', 'lsmb_<?lsmb dbname ?>__process_payment');


CREATE ROLE lsmb_<?lsmb dbname ?>__process_receipt
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__ar_list_transactions;

GRANT INSERT ON acc_trans TO lsmb_<?lsmb dbname ?>__process_receipt;
GRANT ALL ON acc_trans_entry_id_seq TO lsmb_<?lsmb dbname ?>__process_receipt;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (35, 'allow', 'lsmb_<?lsmb dbname ?>__process_receipt');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (36, 'allow', 'lsmb_<?lsmb dbname ?>__process_receipt');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (47, 'allow', 'lsmb_<?lsmb dbname ?>__process_receipt');


CREATE ROLE lsmb_<?lsmb dbname ?>__cash_all
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__all_reconcile,
lsmb_<?lsmb dbname ?>__process_payment,
lsmb_<?lsmb dbname ?>__process_receipt;

-- Inventory Control
CREATE ROLE lsmb_<?lsmb dbname ?>__create_part
WITH INHERIT NOLOGIN;

GRANT INSERT ON parts TO lsmb_<?lsmb dbname ?>__create_part;
GRANT ALL ON parts_id_seq TO lsmb_<?lsmb dbname ?>__create_part;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (77, 'allow', 'lsmb_<?lsmb dbname ?>__create_part');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (78, 'allow', 'lsmb_<?lsmb dbname ?>__create_part');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (79, 'allow', 'lsmb_<?lsmb dbname ?>__create_part');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (80, 'allow', 'lsmb_<?lsmb dbname ?>__create_part');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (81, 'allow', 'lsmb_<?lsmb dbname ?>__create_part');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (82, 'allow', 'lsmb_<?lsmb dbname ?>__create_part');


CREATE ROLE lsmb_<?lsmb dbname ?>__edit_part
WITH INHERIT NOLOGIN;

GRANT UPDATE ON parts TO lsmb_<?lsmb dbname ?>__edit_part;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (77, 'allow', 'lsmb_<?lsmb dbname ?>__edit_part');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (85, 'allow', 'lsmb_<?lsmb dbname ?>__edit_part');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (86, 'allow', 'lsmb_<?lsmb dbname ?>__edit_part');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (87, 'allow', 'lsmb_<?lsmb dbname ?>__edit_part');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (88, 'allow', 'lsmb_<?lsmb dbname ?>__edit_part');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (89, 'allow', 'lsmb_<?lsmb dbname ?>__edit_part');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (90, 'allow', 'lsmb_<?lsmb dbname ?>__edit_part');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (91, 'allow', 'lsmb_<?lsmb dbname ?>__edit_part');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (93, 'allow', 'lsmb_<?lsmb dbname ?>__edit_part');


CREATE ROLE lsmb_<?lsmb dbname ?>__inventory_reports
WITH INHERIT NOLOGIN;

GRANT SELECT ON ar TO lsmb_<?lsmb dbname ?>__inventory_reports;
GRANT SELECT ON ap TO lsmb_<?lsmb dbname ?>__inventory_reports;
GRANT SELECT ON inventory TO lsmb_<?lsmb dbname ?>__inventory_reports;
GRANT SELECT ON invoice TO lsmb_<?lsmb dbname ?>__inventory_reports;
GRANT SELECT ON acc_trans TO lsmb_<?lsmb dbname ?>__inventory_reports;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (77, 'allow', 'lsmb_<?lsmb dbname ?>__inventory_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (85, 'allow', 'lsmb_<?lsmb dbname ?>__inventory_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (88, 'allow', 'lsmb_<?lsmb dbname ?>__inventory_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (94, 'allow', 'lsmb_<?lsmb dbname ?>__inventory_reports');


CREATE ROLE lsmb_<?lsmb dbname ?>__create_pricegroup
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT INSERT ON pricegroup TO lsmb_<?lsmb dbname ?>__create_pricegroup;
GRANT ALL ON pricegroup_id_seq TO lsmb_<?lsmb dbname ?>__create_pricegroup;
GRANT UPDATE ON entity_credit_account TO lsmb_<?lsmb dbname ?>__create_pricegroup;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (77, 'allow', 'lsmb_<?lsmb dbname ?>__create_pricegroup');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (83, 'allow', 'lsmb_<?lsmb dbname ?>__create_pricegroup');


CREATE ROLE lsmb_<?lsmb dbname ?>__edit_pricegroup
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT UPDATE ON pricegroup TO lsmb_<?lsmb dbname ?>__edit_pricegroup;
GRANT UPDATE ON entity_credit_account TO lsmb_<?lsmb dbname ?>__edit_pricegroup;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (77, 'allow', 'lsmb_<?lsmb dbname ?>__edit_pricegroup');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (85, 'allow', 'lsmb_<?lsmb dbname ?>__edit_pricegroup');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (92, 'allow', 'lsmb_<?lsmb dbname ?>__edit_pricegroup');

CREATE ROLE lsmb_<?lsmb dbname ?>__stock_assembly
WITH INHERIT NOLOGIN;

GRANT UPDATE ON parts TO lsmb_<?lsmb dbname ?>__stock_assembly;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (77, 'allow', 'lsmb_<?lsmb dbname ?>__stock_assembly');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (84, 'allow', 'lsmb_<?lsmb dbname ?>__stock_assembly');


CREATE ROLE lsmb_<?lsmb dbname ?>__ship_inventory
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__list_sales_orders;

GRANT INSERT ON inventory TO lsmb_<?lsmb dbname ?>__ship_inventory;
GRANT ALL ON inventory_entry_id_seq TO lsmb_<?lsmb dbname ?>__ship_inventory;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (63, 'allow', 'lsmb_<?lsmb dbname ?>__ship_inventory');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (64, 'allow', 'lsmb_<?lsmb dbname ?>__ship_inventory');


CREATE ROLE lsmb_<?lsmb dbname ?>__receive_inventory
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__list_purchase_orders;

GRANT INSERT ON inventory TO lsmb_<?lsmb dbname ?>__receive_inventory;
GRANT ALL ON inventory_entry_id_seq TO lsmb_<?lsmb dbname ?>__receive_inventory;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (63, 'allow', 'lsmb_<?lsmb dbname ?>__receive_inventory');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (65, 'allow', 'lsmb_<?lsmb dbname ?>__receive_inventory');


CREATE ROLE lsmb_<?lsmb dbname ?>__transfer_inventory
WITH INHERIT NOLOGIN;

GRANT INSERT ON inventory TO lsmb_<?lsmb dbname ?>__transfer_inventory;
GRANT ALL ON inventory_entry_id_seq TO lsmb_<?lsmb dbname ?>__transfer_inventory;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (63, 'allow', 'lsmb_<?lsmb dbname ?>__transfer_inventory');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (66, 'allow', 'lsmb_<?lsmb dbname ?>__transfer_inventory');

CREATE ROLE lsmb_<?lsmb dbname ?>__create_warehouse
WITH INHERIT NOLOGIN;

GRANT INSERT ON warehouse TO lsmb_<?lsmb dbname ?>__create_warehouse;
GRANT ALL ON warehouse_id_seq TO lsmb_<?lsmb dbname ?>__create_warehouse;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__create_warehouse');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (141, 'allow', 'lsmb_<?lsmb dbname ?>__create_warehouse');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (142, 'allow', 'lsmb_<?lsmb dbname ?>__create_warehouse');


CREATE ROLE lsmb_<?lsmb dbname ?>__edit_warehouse
WITH INHERIT NOLOGIN;

GRANT UPDATE ON warehouse TO lsmb_<?lsmb dbname ?>__edit_warehouse;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__edit_warehouse');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (141, 'allow', 'lsmb_<?lsmb dbname ?>__edit_warehouse');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (143, 'allow', 'lsmb_<?lsmb dbname ?>__edit_warehouse');


CREATE ROLE lsmb_<?lsmb dbname ?>__all_inventory
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_part,
lsmb_<?lsmb dbname ?>__inventory_reports,
lsmb_<?lsmb dbname ?>__stock_assembly,
lsmb_<?lsmb dbname ?>__ship_inventory,
lsmb_<?lsmb dbname ?>__receive_inventory,
lsmb_<?lsmb dbname ?>__transfer_inventory,
lsmb_<?lsmb dbname ?>__edit_warehouse,
lsmb_<?lsmb dbname ?>__create_warehouse;

-- GL 
CREATE ROLE lsmb_<?lsmb dbname ?>__create_transaction
WITH INHERIT NOLOGIN;

GRANT INSERT ON gl TO lsmb_<?lsmb dbname ?>__create_transaction;
GRANT INSERT ON acc_trans TO lsmb_<?lsmb dbname ?>__create_transaction;
GRANT ALL ON id TO lsmb_<?lsmb dbname ?>__create_transaction;
GRANT ALL ON acc_trans_entry_id_seq TO lsmb_<?lsmb dbname ?>__create_transaction;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (73, 'allow', 'lsmb_<?lsmb dbname ?>__create_transaction');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (74, 'allow', 'lsmb_<?lsmb dbname ?>__create_transaction');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (75, 'allow', 'lsmb_<?lsmb dbname ?>__create_transaction');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (35, 'allow', 'lsmb_<?lsmb dbname ?>__create_transaction');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (40, 'allow', 'lsmb_<?lsmb dbname ?>__create_transaction');


CREATE ROLE lsmb_<?lsmb dbname ?>__create_transaction_voucher
WITH INHERIT NOLOGIN;

GRANT INSERT ON gl TO lsmb_<?lsmb dbname ?>__create_transaction_voucher;
GRANT INSERT ON acc_trans TO lsmb_<?lsmb dbname ?>__create_transaction_voucher;
GRANT ALL ON id TO lsmb_<?lsmb dbname ?>__create_transaction_voucher;
GRANT ALL ON acc_trans_entry_id_seq TO lsmb_<?lsmb dbname ?>__create_transaction_voucher;

-- TODO Add menu permissions

CREATE ROLE lsmb_<?lsmb dbname ?>__list_transactions
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__list_ar_transactions,
lsmb_<?lsmb dbname ?>__list_ap_transactions;

GRANT SELECT ON gl TO lsmb_<?lsmb dbname ?>__list_transactions;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (73, 'allow', 'lsmb_<?lsmb dbname ?>__list_transactions');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (76, 'allow', 'lsmb_<?lsmb dbname ?>__list_transactions');


CREATE ROLE lsmb_<?lsmb dbname ?>__run_yearend
WITH INHERIT NOLOGIN;

GRANT INSERT, SELECT ON acc_trans TO lsmb_<?lsmb dbname ?>__run_yearend;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__run_yearend');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (132, 'allow', 'lsmb_<?lsmb dbname ?>__run_yearend');


CREATE ROLE lsmb_<?lsmb dbname ?>__list_batches
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__list_transactions;

GRANT SELECT ON batch TO lsmb_<?lsmb dbname ?>__list_batches;
GRANT SELECT ON batch_class TO lsmb_<?lsmb dbname ?>__list_batches;
GRANT SELECT ON voucher TO lsmb_<?lsmb dbname ?>__list_batches;

-- TODO:  Add menu items


CREATE ROLE lsmb_<?lsmb dbname ?>__all_gl
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_transaction,
lsmb_<?lsmb dbname ?>__create_transaction_voucher,
lsmb_<?lsmb dbname ?>__run_yearend,
lsmb_<?lsmb dbname ?>__list_transactions;

-- PROJECTS
CREATE ROLE lsmb_<?lsmb dbname ?>__create_project
WITH INHERIT NOLOGIN;

GRANT INSERT ON project TO lsmb_<?lsmb dbname ?>__create_project;
GRANT ALL ON project_id_seq TO lsmb_<?lsmb dbname ?>__create_project;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (98, 'allow', 'lsmb_<?lsmb dbname ?>__create_project');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (99, 'allow', 'lsmb_<?lsmb dbname ?>__create_project');


CREATE ROLE lsmb_<?lsmb dbname ?>__edit_project
WITH INHERIT NOLOGIN;

GRANT UPDATE ON project TO lsmb_<?lsmb dbname ?>__edit_project;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (98, 'allow', 'lsmb_<?lsmb dbname ?>__edit_project');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (103, 'allow', 'lsmb_<?lsmb dbname ?>__edit_project');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (104, 'allow', 'lsmb_<?lsmb dbname ?>__edit_project');


CREATE ROLE lsmb_<?lsmb dbname ?>__add_project_timecard
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT INSERT ON jcitems TO lsmb_<?lsmb dbname ?>__add_project_timecard;
GRANT ALL ON jcitems_id_seq TO lsmb_<?lsmb dbname ?>__add_project_timecard;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (98, 'allow', 'lsmb_<?lsmb dbname ?>__add_project_timecard');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (100, 'allow', 'lsmb_<?lsmb dbname ?>__add_project_timecard');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (103, 'allow', 'lsmb_<?lsmb dbname ?>__add_project_timecard');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (106, 'allow', 'lsmb_<?lsmb dbname ?>__add_project_timecard');

CREATE ROLE lsmb_<?lsmb dbname ?>__list_project_timecards
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT UPDATE ON project TO lsmb_<?lsmb dbname ?>__edit_project;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (98, 'allow', 'lsmb_<?lsmb dbname ?>__edit_project');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (103, 'allow', 'lsmb_<?lsmb dbname ?>__edit_project');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (106, 'allow', 'lsmb_<?lsmb dbname ?>__edit_project');



-- ORDER GENERATION
CREATE ROLE lsmb_<?lsmb dbname ?>__generate_orders
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT SELECT, INSERT, UPDATE ON oe TO lsmb_<?lsmb dbname ?>__generate_orders;
GRANT SELECT, INSERT, UPDATE ON orderitems TO lsmb_<?lsmb dbname ?>__generate_orders;
GRANT ALL ON oe_id_seq TO lsmb_<?lsmb dbname ?>__generate_orders;
GRANT ALL ON orderitems_id_seq TO lsmb_<?lsmb dbname ?>__generate_orders;

CREATE ROLE lsmb_<?lsmb dbname ?>__project_generate_orders
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__generate_orders;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (98, 'allow', 'lsmb_<?lsmb dbname ?>__project_generate_orders');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (101, 'allow', 'lsmb_<?lsmb dbname ?>__project_generate_orders');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (102, 'allow', 'lsmb_<?lsmb dbname ?>__project_generate_orders');


CREATE ROLE lsmb_<?lsmb dbname ?>__sales_to_purchase_orders
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__generate_orders;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (50, 'allow', 'lsmb_<?lsmb dbname ?>__sales_to_purchase_orders');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (56, 'allow', 'lsmb_<?lsmb dbname ?>__sales_to_purchase_orders');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (57, 'allow', 'lsmb_<?lsmb dbname ?>__sales_to_purchase_orders');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (58, 'allow', 'lsmb_<?lsmb dbname ?>__sales_to_purchase_orders');


CREATE ROLE lsmb_<?lsmb dbname ?>__consolidate_purchase_orders
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__generate_orders;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (50, 'allow', 'lsmb_<?lsmb dbname ?>__consolidate_purchase_orders');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (60, 'allow', 'lsmb_<?lsmb dbname ?>__consolidate_purchase_orders');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (62, 'allow', 'lsmb_<?lsmb dbname ?>__consolidate_purchase_orders');


CREATE ROLE lsmb_<?lsmb dbname ?>__consolidate_sales_orders
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__generate_orders;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (50, 'allow', 'lsmb_<?lsmb dbname ?>__consolidate_sales_orders');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (60, 'allow', 'lsmb_<?lsmb dbname ?>__consolidate_sales_orders');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (61, 'allow', 'lsmb_<?lsmb dbname ?>__consolidate_sales_orders');


CREATE ROLE lsmb_<?lsmb dbname ?>__manage_orders
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__project_generate_orders,
lsmb_<?lsmb dbname ?>__sales_to_purchase_orders,
lsmb_<?lsmb dbname ?>__consolidate_purchase_orders,
lsmb_<?lsmb dbname ?>__consolidate_sales_orders;

-- FINANCIAL REPORTS
CREATE ROLE lsmb_<?lsmb dbname ?>__run_financial_reports
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__list_transactions;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (109, 'allow', 'lsmb_<?lsmb dbname ?>__run_financial_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (110, 'allow', 'lsmb_<?lsmb dbname ?>__run_financial_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (111, 'allow', 'lsmb_<?lsmb dbname ?>__run_financial_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (112, 'allow', 'lsmb_<?lsmb dbname ?>__run_financial_reports');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (113, 'allow', 'lsmb_<?lsmb dbname ?>__run_financial_reports');


-- RECURRING TRANSACTIONS
-- TO ADD WHEN THIS IS REDESIGNED

-- BATCH PRINTING
CREATE ROLE lsmb_<?lsmb dbname ?>__list_print_jobs
WITH INHERIT NOLOGIN;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (116, 'allow', 'lsmb_<?lsmb dbname ?>__list_print_jobs');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (117, 'allow', 'lsmb_<?lsmb dbname ?>__list_print_jobs');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (118, 'allow', 'lsmb_<?lsmb dbname ?>__list_print_jobs');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (119, 'allow', 'lsmb_<?lsmb dbname ?>__list_print_jobs');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (120, 'allow', 'lsmb_<?lsmb dbname ?>__list_print_jobs');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (121, 'allow', 'lsmb_<?lsmb dbname ?>__list_print_jobs');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (122, 'allow', 'lsmb_<?lsmb dbname ?>__list_print_jobs');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (123, 'allow', 'lsmb_<?lsmb dbname ?>__list_print_jobs');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (124, 'allow', 'lsmb_<?lsmb dbname ?>__list_print_jobs');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (125, 'allow', 'lsmb_<?lsmb dbname ?>__list_print_jobs');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (126, 'allow', 'lsmb_<?lsmb dbname ?>__list_print_jobs');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (127, 'allow', 'lsmb_<?lsmb dbname ?>__list_print_jobs');


CREATE ROLE lsmb_<?lsmb dbname ?>__print_jobs
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__list_print_jobs;


-- SYSTEM SETTINGS	
CREATE ROLE lsmb_<?lsmb dbname ?>__list_system_settings
WITH INHERIT NOLOGIN;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__list_system_settings');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (129, 'allow', 'lsmb_<?lsmb dbname ?>__list_system_settings');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (131, 'allow', 'lsmb_<?lsmb dbname ?>__list_system_settings');


CREATE ROLE lsmb_<?lsmb dbname ?>__change_system_settings
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__list_system_settings;

CREATE ROLE lsmb_<?lsmb dbname ?>__set_taxes
WITH INHERIT NOLOGIN;

GRANT INSERT, UPDATE ON tax TO lsmb_<?lsmb dbname ?>__set_taxes;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__set_taxes');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (130, 'allow', 'lsmb_<?lsmb dbname ?>__set_taxes');


CREATE ROLE lsmb_<?lsmb dbname ?>__create_account
WITH INHERIT NOLOGIN;

GRANT INSERT ON chart TO lsmb_<?lsmb dbname ?>__create_account;
GRANT ALL ON chart_id_seq TO lsmb_<?lsmb dbname ?>__create_account;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__create_account');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (136, 'allow', 'lsmb_<?lsmb dbname ?>__create_account');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (137, 'allow', 'lsmb_<?lsmb dbname ?>__create_account');


CREATE ROLE lsmb_<?lsmb dbname ?>__edit_account
WITH INHERIT NOLOGIN;

GRANT UPDATE ON chart TO lsmb_<?lsmb dbname ?>__edit_account;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__edit_account');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (136, 'allow', 'lsmb_<?lsmb dbname ?>__edit_account');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (138, 'allow', 'lsmb_<?lsmb dbname ?>__edit_account');


CREATE ROLE lsmb_<?lsmb dbname ?>__create_gifi
WITH INHERIT NOLOGIN;

GRANT INSERT ON gifi TO lsmb_<?lsmb dbname ?>__create_gifi;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__create_gifi');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (136, 'allow', 'lsmb_<?lsmb dbname ?>__create_gifi');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (139, 'allow', 'lsmb_<?lsmb dbname ?>__create_gifi');


CREATE ROLE lsmb_<?lsmb dbname ?>__edit_gifi
WITH INHERIT NOLOGIN;

GRANT UPDATE ON gifi TO lsmb_<?lsmb dbname ?>__edit_gifi;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__edit_account');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (136, 'allow', 'lsmb_<?lsmb dbname ?>__edit_account');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (140, 'allow', 'lsmb_<?lsmb dbname ?>__edit_account');


CREATE ROLE lsmb_<?lsmb dbname ?>__all_accounts
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_account,
lsmb_<?lsmb dbname ?>__set_taxes,
lsmb_<?lsmb dbname ?>__edit_account,
lsmb_<?lsmb dbname ?>__create_gifi,
lsmb_<?lsmb dbname ?>__edit_gifi;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_department
WITH INHERIT NOLOGIN;

GRANT INSERT ON department TO lsmb_<?lsmb dbname ?>__create_department;
GRANT ALL ON department_id_seq TO lsmb_<?lsmb dbname ?>__create_department;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__create_department');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (144, 'allow', 'lsmb_<?lsmb dbname ?>__create_department');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (145, 'allow', 'lsmb_<?lsmb dbname ?>__create_department');


CREATE ROLE lsmb_<?lsmb dbname ?>__edit_department
WITH INHERIT NOLOGIN;

GRANT UPDATE ON department TO lsmb_<?lsmb dbname ?>__edit_department;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__edit_department');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (144, 'allow', 'lsmb_<?lsmb dbname ?>__edit_department');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (146, 'allow', 'lsmb_<?lsmb dbname ?>__edit_department');


CREATE ROLE lsmb_<?lsmb dbname ?>__all_department
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_department,
lsmb_<?lsmb dbname ?>__edit_department;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_business_type
WITH INHERIT NOLOGIN;

GRANT INSERT ON business TO lsmb_<?lsmb dbname ?>__create_business_type;
GRANT ALL ON business_id_seq TO lsmb_<?lsmb dbname ?>__create_business_type;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__create_business_type');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (147, 'allow', 'lsmb_<?lsmb dbname ?>__create_business_type');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (148, 'allow', 'lsmb_<?lsmb dbname ?>__create_business_type');


CREATE ROLE lsmb_<?lsmb dbname ?>__edit_business_type
WITH INHERIT NOLOGIN;

GRANT UPDATE ON business TO lsmb_<?lsmb dbname ?>__edit_business_type;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__edit_business_type');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (147, 'allow', 'lsmb_<?lsmb dbname ?>__edit_business_type');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (149, 'allow', 'lsmb_<?lsmb dbname ?>__edit_business_type');


CREATE ROLE lsmb_<?lsmb dbname ?>__all_business_type
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_business_type,
lsmb_<?lsmb dbname ?>__edit_business_type;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_sic
WITH INHERIT NOLOGIN;

GRANT INSERT ON sic TO lsmb_<?lsmb dbname ?>__create_sic;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__create_sic');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (153, 'allow', 'lsmb_<?lsmb dbname ?>__create_sic');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (154, 'allow', 'lsmb_<?lsmb dbname ?>__create_sic');


CREATE ROLE lsmb_<?lsmb dbname ?>__edit_sic
WITH INHERIT NOLOGIN;

GRANT UPDATE ON sic TO lsmb_<?lsmb dbname ?>__edit_sic;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__edit_sic');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (153, 'allow', 'lsmb_<?lsmb dbname ?>__edit_sic');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (155, 'allow', 'lsmb_<?lsmb dbname ?>__edit_sic');


CREATE ROLE lsmb_<?lsmb dbname ?>__all_sic
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_sic,
lsmb_<?lsmb dbname ?>__edit_sic;

CREATE ROLE lsmb_<?lsmb dbname ?>__edit_template
WITH INHERIT NOLOGIN;

-- TODO Add db permissions as templates get moved into db.

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (156, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (157, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (158, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (159, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (160, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (161, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (162, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (163, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (164, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (165, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (166, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (167, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (168, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (169, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (170, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (171, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (172, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (173, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (174, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (175, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (176, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (177, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (178, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (179, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (180, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (181, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (182, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (183, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (184, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (185, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (186, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (187, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (188, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (189, 'allow', 'lsmb_<?lsmb dbname ?>__edit_template');


CREATE ROLE lsmb_<?lsmb dbname ?>__manage_system
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__change_system_settings,
lsmb_<?lsmb dbname ?>__all_accounts,
lsmb_<?lsmb dbname ?>__all_department,
lsmb_<?lsmb dbname ?>__all_business_type,
lsmb_<?lsmb dbname ?>__all_sic,
lsmb_<?lsmb dbname ?>__edit_template;

-- Manual Translation
CREATE ROLE lsmb_<?lsmb dbname ?>__create_language
WITH INHERIT NOLOGIN;

GRANT INSERT ON language TO lsmb_<?lsmb dbname ?>__create_language;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__create_language');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (150, 'allow', 'lsmb_<?lsmb dbname ?>__create_language');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (151, 'allow', 'lsmb_<?lsmb dbname ?>__create_language');


CREATE ROLE lsmb_<?lsmb dbname ?>__edit_language
WITH INHERIT NOLOGIN;

GRANT UPDATE ON language TO lsmb_<?lsmb dbname ?>__edit_language;

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (128, 'allow', 'lsmb_<?lsmb dbname ?>__edit_language');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (150, 'allow', 'lsmb_<?lsmb dbname ?>__edit_language');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (152, 'allow', 'lsmb_<?lsmb dbname ?>__edit_language');


CREATE ROLE lsmb_<?lsmb dbname ?>__create_part_translation
WITH INHERIT NOLOGIN;

-- TODO add db permissions

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (77, 'allow', 'lsmb_<?lsmb dbname ?>__create_part_translation');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (95, 'allow', 'lsmb_<?lsmb dbname ?>__create_part_translation');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (96, 'allow', 'lsmb_<?lsmb dbname ?>__create_part_translation');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (97, 'allow', 'lsmb_<?lsmb dbname ?>__create_part_translation');


CREATE ROLE lsmb_<?lsmb dbname ?>__create_project_translation
WITH INHERIT NOLOGIN;

-- TODO add db permissions

INSERT INTO menu_acl (node_id, acl_type, role_name)
values (98, 'allow', 'lsmb_<?lsmb dbname ?>__create_project_translation');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (107, 'allow', 'lsmb_<?lsmb dbname ?>__create_project_translation');
INSERT INTO menu_acl (node_id, acl_type, role_name)
values (108, 'allow', 'lsmb_<?lsmb dbname ?>__create_project_translation');


CREATE ROLE lsmb_<?lsmb dbname ?>__all_manual_translation
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_language,
lsmb_<?lsmb dbname ?>__create_part_translation,
lsmb_<?lsmb dbname ?>__create_project_translation;

GRANT SELECT ON custom_field_catalog TO public;
GRANT SELECT ON custom_table_catalog TO public;

-- Grants to all users;
GRANT ALL ON defaults TO public;
GRANT ALL ON "session" TO public;
GRANT ALL ON session_session_id_seq TO PUBLIC;
GRANT SELECT ON users TO public;
GRANT ALL ON user_preference TO public;
GRANT SELECT ON custom_table_catalog TO PUBLIC;
GRANT SELECT ON custom_field_catalog TO PUBLIC;
grant select on menu_node, menu_attribute, menu_acl to public;
GRANT select on chart, gifi, country to public;
grant select on employee to public;
GRANT SELECT ON parts, partsgroup TO public;
GRANT SELECT ON language, project TO public;
GRANT SELECT ON business, exchangerate, department, shipto, tax TO public;
GRANT ALL ON recurring, recurringemail, recurringprint, status TO public; 
GRANT ALL ON transactions, entity_employee, customer, vendor TO public;
--TODO, lock recurring down more

-- CT:  The following grant is required for now, but will hopefully become less 
-- important when we get to 1.4 and can more sensibly lock things down.
GRANT ALL ON dpt_trans TO public;
