-- Contacts
CREATE ROLE lsmb_<?lsmb dbname ?>__read_contact
WITH INHERIT NOLOGIN;

GRANT SELECT ON entity TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON company TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON person TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON entity_credit_account TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON company_to_contact TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON company_to_entity TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON company_to_location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON customertax TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON employee TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON customer TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON contact_class TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON entity_class TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON entity_bank_account TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON entity_note TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON entity_class_to_entity TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON entity_other_name TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON location_class TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON person_to_company TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON person_to_contact TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON person_to_contact TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON person_to_location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON person_to_location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT SELECT ON vendortax TO lsmb_<?lsmb dbname ?>__create_contact;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_contact
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT INSERT ON entity TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON company TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON person TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON entity_credit_account TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON company_to_contact TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON company_to_entity TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON company_to_location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON customertax TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON employee TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON customer TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON entity_bank_account TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON entity_note TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON entity_class_to_entity TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON entity_other_name TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON person_to_company TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON person_to_contact TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON person_to_contact TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON person_to_location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON person_to_location TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT INSERT ON vendortax TO lsmb_<?lsmb dbname ?>__create_contact;

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
GRANT UPDATE ON employee TO lsmb_<?lsmb dbname ?>__create_contact;
GRANT UPDATE ON customer TO lsmb_<?lsmb dbname ?>__create_contact;
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
GRANT SELECT ON batch_class TO lsmb_<?lsmb dbname ?>__create_batch;
GRANT INSERT ON voucher TO lsmb_<?lsmb dbname ?>__create_batch;

CREATE ROLE lsmb_<?lsmb dbname ?>__post_batches
WITH INHERIT NOLOGIN;

GRANT UPDATE ON ar TO lsmb_<?lsmb dbname ?>__post_batches;
GRANT UPDATE ON ap TO lsmb_<?lsmb dbname ?>__post_batches;
GRANT UPDATE ON acc_trans TO lsmb_<?lsmb dbname ?>__post_batches;
GRANT UPDATE ON batch TO lsmb_<?lsmb dbname ?>__post_batches;
GRANT UPDATE ON gl TO lsmb_<?lsmb dbname ?>__post_batches;

-- AR
CREATE ROLE lsmb_<?lsmb dbname ?>__create_ar_transaction
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT INSERT ON ar TO lsmb_<?lsmb dbname ?>__create_ar_transaction;
GRANT INSERT ON acc_trans TO lsmb_<?lsmb dbname ?>__create_ar_transaction;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_ar_transaction_voucher
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact,
lsmb_<?lsmb dbname ?>__create_batch;

GRANT INSERT ON ar TO lsmb_<?lsmb dbname ?>__create_ar_transaction_voucher;
GRANT INSERT ON acc_trans TO lsmb_<?lsmb dbname ?>__create_ar_transaction_voucher;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_ar_invoice
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact,
lsmb_<?lsmb dbname ?>__create_ar_transaction;

GRANT INSERT ON invoice TO lsmb_<?lsmb dbname ?>__create_ar_invoice;
GRANT INSERT ON inventory TO lsmb_<?lsmb dbname ?>__create_ar_invoice;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_ar_invoice_voucher
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact,
lsmb_<?lsmb dbname ?>__create_batch,
lsmb_<?lsmb dbname ?>__create_ar_transaction_voucher;

GRANT INSERT ON invoice TO lsmb_<?lsmb dbname ?>__create_ar_invoice_voucher;
GRANT INSERT ON inventory TO lsmb_<?lsmb dbname ?>__create_ar_invoice_voucher;

CREATE ROLE lsmb_<?lsmb dbname ?>__list_ar_transactions
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT SELECT ON ar TO lsmb_<?lsmb dbname ?>__list_ar_transactions;
GRANT SELECT ON acc_trans TO lsmb_<?lsmb dbname ?>__list_ar_transactions;
GRANT SELECT ON invoice TO lsmb_<?lsmb dbname ?>__list_ar_transactions
GRANT SELECT ON inventory TO lsmb_<?lsmb dbname ?>__list_ar_transactions

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
GRANT INSERT ON orderitems TO lsmb_<?lsmb dbname ?>__create_sales_order;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_sales_quotation
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT INSERT ON oe TO lsmb_<?lsmb dbname ?>__create_sales_quotation;
GRANT INSERT ON orderitems TO lsmb_<?lsmb dbname ?>__create_sales_quotation;

CREATE ROLE lsmb_<?lsmb dbname ?>__list_sales_orders
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT SELECT ON oe TO lsmb_<?lsmb dbname ?>__list_sales_orders;
GRANT SELECT ON orderitems TO lsmb_<?lsmb dbname ?>__list_sales_orders;

CREATE ROLE lsmb_<?lsmb dbname ?>__list_sales_quotations
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

GRANT SELECT ON oe TO lsmb_<?lsmb dbname ?>__list_sales_quotations;
GRANT SELECT ON orderitems TO lsmb_<?lsmb dbname ?>__list_sales_quotations;

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

CREATE ROLE lsmb_<?lsmb dbname ?>__create_ap_transaction_voucher
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact,
lsmb_<?lsmb dbname ?>__create_batch;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_ap_invoice
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_ap_invoice_voucher
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact,
lsmb_<?lsmb dbname ?>__create_batch;

CREATE ROLE lsmb_<?lsmb dbname ?>__list_ap_transactions
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

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
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_purchase_rfq
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

CREATE ROLE lsmb_<?lsmb dbname ?>__list_purchase_orders
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

CREATE ROLE lsmb_<?lsmb dbname ?>__list_purchase_rfqs
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__read_contact;

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
IN ROLE lsmb_<?lsmb dbname ?>__create_sales_invoice,
lsmb_<?lsmb dbname ?>__create_ar_invoice;

CREATE ROLE lsmb_<?lsmb dbname ?>__close_till
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__list_all_open
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__pos_cashier
WITH INHERIT NOLOGIN
lsmb_<?lsmb dbname ?>__create_pos_invoice,
lsmb_<?lsmb dbname ?>__close_till;

CREATE ROLE lsmb_<?lsmb dbname ?>__all_pos
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__pos_cashier,
lsmb_<?lsmb dbname ?>__list_all_open;

-- CASH
CREATE ROLE lsmb_<?lsmb dbname ?>__reconcile
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__approve_reconciliation
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__all_reconcile
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__reconcile,
lsmb_<?lsmb dbname ?>__approve_reconciliation;

CREATE ROLE lsmb_<?lsmb dbname ?>__process_payment
WITH INHERIT NOLOGIN
IN ROLE ar_list_transactions;

CREATE ROLE lsmb_<?lsmb dbname ?>__process_receipt
WITH INHERIT NOLOGIN
IN ROLE ap_list_transactions;

CREATE ROLE lsmb_<?lsmb dbname ?>__cash_all
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__all_reconcile,
lsmb_<?lsmb dbname ?>__process_payment,
lsmb_<?lsmb dbname ?>__process_receipt;

-- Inventory Control
CREATE ROLE lsmb_<?lsmb dbname ?>__create_part
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__inventory_reports
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__stock_assembly
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__ship_inventory
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__receive_inventory
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_warehouse
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__all_inventory
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_part,
lsmb_<?lsmb dbname ?>__inventory_reports,
lsmb_<?lsmb dbname ?>__stock_assembly,
lsmb_<?lsmb dbname ?>__ship_inventory,
lsmb_<?lsmb dbname ?>__receive_inventory,
lsmb_<?lsmb dbname ?>__create_warehouse;

-- GL 
CREATE ROLE lsmb_<?lsmb dbname ?>__create_transaction
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_transaction_voucher
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__list_transactions
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__list_ar_transactions,
lsmb_<?lsmb dbname ?>__list_ap_transactions;

CREATE ROLE lsmb_<?lsmb dbname ?>__run_yearend
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_list_batches
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_list_transactions;

GRANT SELECT ON batch TO lsmb_<?lsmb dbname ?>__create_list_batches;
GRANT SELECT ON batch_class TO lsmb_<?lsmb dbname ?>__create_list_batches;
GRANT SELECT ON voucher TO lsmb_<?lsmb dbname ?>__create_list_batches;

CREATE ROLE lsmb_<?lsmb dbname ?>__all_gl
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_transaction,
lsmb_<?lsmb dbname ?>__create_transaction_voucher,
lsmb_<?lsmb dbname ?>__run_yearend,
lsmb_<?lsmb dbname ?>__list_transactions;

-- PROJECTS
CREATE ROLE lsmb_<?lsmb dbname ?>__create_project
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__add_project_timecard
WITH INHERIT NOLOGIN;

-- ORDER GENERATION
CREATE ROLE lsmb_<?lsmb dbname ?>__project_generate_orders
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__sales_to_purchase_orders
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__consolidate_purchase_orders
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__consolidate_sales_orders
WITH INHERIT NOLOGIN;

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

-- RECURRING TRANSACTIONS
-- TO ADD WHEN THIS IS REDESIGNED

-- BATCH PRINTING
CREATE ROLE lsmb_<?lsmb dbname ?>__list_print_jobs
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__print_jobs
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__all_batch_printing
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__list_print_jobs,
lsmb_<?lsmb dbname ?>__print_jobs;

-- SYSTEM SETTINGS	
CREATE ROLE lsmb_<?lsmb dbname ?>__list_system_settings
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__change_system_settings
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__list_system_settings;

CREATE ROLE lsmb_<?lsmb dbname ?>__set_taxes
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_account
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__edit_account
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_gifi
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__edit_gifi
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__all_accounts
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_account,
lsmb_<?lsmb dbname ?>__set_taxes,
lsmb_<?lsmb dbname ?>__edit_account,
lsmb_<?lsmb dbname ?>__create_gifi;
lsmb_<?lsmb dbname ?>__edit_gifi;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_department
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__edit_department
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__all_department
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_department,
lsmb_<?lsmb dbname ?>__edit_department;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_business_type
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__edit_business_type
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__all_business_type
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_business_type,
lsmb_<?lsmb dbname ?>__edit_business_type;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_sic
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__edit_sic
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__all_sic
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_sic,
lsmb_<?lsmb dbname ?>__edit_sic;

CREATE ROLE lsmb_<?lsmb dbname ?>__edit_template
WITH INHERIT NOLOGIN;

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

CREATE ROLE lsmb_<?lsmb dbname ?>__create_part_translation
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__create_project_translation
WITH INHERIT NOLOGIN;

CREATE ROLE lsmb_<?lsmb dbname ?>__all_manual_translation
WITH INHERIT NOLOGIN
IN ROLE lsmb_<?lsmb dbname ?>__create_language,
lsmb_<?lsmb dbname ?>__create_part_translation,
lsmb_<?lsmb dbname ?>__create_project_translation;

