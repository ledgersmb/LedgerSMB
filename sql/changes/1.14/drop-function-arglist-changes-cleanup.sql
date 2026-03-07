drop function if exists tax_form_summary_report(int,date,date);
drop function if exists tax_form_details_report(int, date, date, text);
drop function if exists tax_form_summary_report_accrual(int, date, date);
drop function if exists tax_form_details_report_accrual(int, date, date, text);
DROP FUNCTION IF EXISTS chart_list_all();
drop function if exists chart_get_ar_ap(int);
DROP FUNCTION IF EXISTS account_get(int);
DROP FUNCTION IF EXISTS account__list_translations(int);
DROP FUNCTION IF EXISTS account_heading__list_translations(int);
DROP FUNCTION IF EXISTS account__save
(in_id int, in_accno text, in_description text, in_category char(1),
in_gifi_accno text, in_heading int, in_contra bool, in_tax bool,
in_link text[], in_obsolete bool, in_is_temp bool);
DROP FUNCTION IF EXISTS account__get_by_accno(text);
DROP FUNCTION IF EXISTS get_link_descriptions();
DROP FUNCTION IF EXISTS account__save_tax
(in_chart_id int, in_validto date, in_rate numeric, in_taxnumber text,
in_pass int, in_taxmodule_id int, in_old_validto date);
DROP FUNCTION IF EXISTS  admin__get_user(in_entity_id INT);
DROP FUNCTION IF EXISTS admin__get_user_by_entity(in_entity_id INT);
DROP FUNCTION IF EXISTS admin__get_roles_for_user(in_entity_id INT);
DROP FUNCTION IF EXISTS admin__save_user(int, int, text, text, bool);
DROP FUNCTION IF EXISTS admin__get_roles();
DROP FUNCTION IF EXISTS user__get_preferences (in_user_id int);
DROP FUNCTION IF EXISTS ar_ap__transaction_search
(in_account_id int, in_name_part text, in_meta_number text, in_invnumber text,
 in_ordnumber text, in_ponumber text, in_source text, in_description text,
 in_notes text, in_shipvia text, in_from_date date, in_to_date date,
 in_on_hold bool, in_inc_open bool, in_inc_closed bool, in_as_of date,
 in_entity_class int);
DROP FUNCTION IF EXISTS ar_ap__transaction_search_summary
(in_account_id int, in_name_part text, in_meta_number text, in_invnumber text,
 in_ordnumber text, in_ponumber text, in_source text, in_description text,
 in_notes text, in_shipvia text, in_from_date date, in_to_date date,
 in_on_hold bool, in_inc_open bool, in_inc_closed bool, in_as_of date,
 in_entity_class int);
DROP FUNCTION IF EXISTS asset_dep__straight_line_base
                        (numeric, numeric, numeric, numeric, numeric)
     CASCADE;
DROP FUNCTION IF EXISTS asset__save
(in_id int, in_asset_class int, in_description text, in_tag text,
in_purchase_date date, in_purchase_value numeric,
in_usable_life numeric, in_salvage_value numeric,
in_start_depreciation date, in_warehouse_id int,
in_department_id int, in_invoice_id int,
in_asset_account_id int, in_dep_account_id int, in_exp_account_id int);
DROP FUNCTION IF EXISTS asset_report__approve(int, int, int, int);
DROP FUNCTION IF EXISTS asset_report__disposal_gl(int, int, int);
DROP FUNCTION IF EXISTS budget__get_details(int) CASCADE;
DROP FUNCTION IF EXISTS eca__history
(in_name text, in_meta_number text, in_contact_info text, in_address_line text,
 in_city text, in_state text, in_zip text, in_salesperson text, in_notes text,
 in_country_id int, in_from_date date, in_to_date date, in_type char(1),
 in_start_from date, in_start_to date, in_entity_class int,
 in_inc_open bool, in_inc_closed bool);
DROP FUNCTION IF EXISTS eca__history_summary
(in_name text, in_meta_number text, in_contact_info text, in_address_line text,
 in_city text, in_state text, in_zip text, in_salesperson text, in_notes text,
 in_country_id int, in_from_date date, in_to_date date, in_type char(1),
 in_start_from date, in_start_to date, in_entity_class int,
 in_inc_open bool, in_inc_closed bool);
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
DROP FUNCTION IF EXISTS eca__get_taxes(in_credit_id int);
DROP FUNCTION IF EXISTS eca__set_taxes(int, int[]);
DROP FUNCTION if exists entity__save_notes(integer,text,text);
DROP FUNCTION if exists eca__save_notes(integer,text,text);
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
DROP FUNCTION IF EXISTS entity__save_bank_account
(in_entity_id int, in_credit_id int, in_bic text, in_iban text,
in_bank_account_id int);
drop function if exists entity__save_bank_account
(in_entity_id int, in_credit_id int, in_bic text, in_iban text, in_remark text,
in_bank_account_id int);
DROP FUNCTION IF EXISTS entity__save_contact
(in_entity_id int, in_class_id int, in_description text, in_contact text,
in_old_contact text, in_old_class_id int);
DROP FUNCTION IF EXISTS entity__location_save (
    in_entity_id int, in_id int,
    in_location_class int, in_line_one text, in_line_two text,
    in_city TEXT, in_state TEXT, in_mail_code text, in_country_id int,
    in_created date
);
DROP FUNCTION IF EXISTS eca__save_contact(int, int, text, text, text, int);
DROP FUNCTION IF EXISTS currency__delete(in_curr text);
DROP FUNCTION IF EXISTS currency__list();
DROP FUNCTION IF EXISTS exchangerate_type__list();
DROP FUNCTION IF EXISTS draft__search(in_type text, in_with_accno text,
in_from_date date, in_to_date date, in_amount_lt numeric, in_amount_gt numeric);
DROP FUNCTION IF EXISTS employee__save
(in_entity_id int, in_start_date date, in_end_date date, in_dob date,
        in_role text, in_ssn text, in_sales bool, in_manager_id int,
        in_employeenumber text);
drop function if exists  employee__get_user(in_entity_id int);
DROP FUNCTION IF EXISTS employee__search
(in_employeenumber text, in_startdate_from date, in_startdate_to date,
in_first_name text, in_middle_name text, in_last_name text,
in_notes text, in_is_user bool);
DROP FUNCTION IF EXISTS file__get_mime_type(int, text);
DROP FUNCTION IF EXISTS pnl__product(in_from_date date, in_to_date date, in_parts_id integer, in_business_units integer[]);
DROP FUNCTION IF EXISTS pnl__income_statement_accrual(in_from_date date, in_to_date date, in_ignore_yearend text, in_business_units integer[]);
DROP FUNCTION IF EXISTS pnl__income_statement_accrual(in_from_date date, in_to_date date, in_ignore_yearend text, in_business_units integer[], in_language text);
DROP FUNCTION IF EXISTS pnl__income_statement_cash(in_from_date date, in_to_date date, in_ignore_yearend text, in_business_units integer[]);
DROP FUNCTION IF EXISTS pnl__income_statement_cash(in_from_date date, in_to_date date, in_ignore_yearend text, in_business_units integer[], in_language text);
DROP FUNCTION IF EXISTS pnl__invoice(in_id integer);
DROP FUNCTION IF EXISTS pnl__customer(in_id integer, in_from_date date, in_to_date date);
DROP FUNCTION IF EXISTS report__balance_sheet(in_to_date date);
DROP FUNCTION IF EXISTS report__balance_sheet(in_to_date date, in_language text);
DROP FUNCTION IF EXISTS goods__search
(in_partnumber text, in_description text,
 in_partsgroup_id int, in_serial_number text, in_make text,
 in_model text, in_drawing text, in_microfiche text,
 in_status text, in_date_from date, in_date_to date,
 in_sales_invoices bool, in_purchase_invoices bool,
 in_sales_orders bool, in_purchase_orders bool, in_quotations bool,
 in_rfqs bool);
DROP FUNCTION IF EXISTS goods__search
(in_partnumber text, in_description text,
 in_partsgroup_id int, in_serial_number text, in_make text,
 in_model text, in_drawing text, in_microfiche text,
 in_status text, in_date_from date, in_date_to date);
DROP FUNCTION IF EXISTS goods__search
(in_parttype text, in_partnumber text, in_description text,
 in_partsgroup_id int, in_serial_number text, in_make text,
 in_model text, in_drawing text, in_microfiche text,
 in_status text, in_date_from date, in_date_to date);
DROP FUNCTION IF EXISTS inventory_adjust__approve(int);
DROP FUNCTION IF EXISTS inventory_adjust__get(in_id int);
DROP FUNCTION IF EXISTS goods__history(
  in_date_from date, in_date_to date,
  in_partnumber text, in_description text, in_serial_number text,
  in_inc_po bool, in_inc_so bool, in_inc_quo bool, in_inc_rfq bool,
  in_inc_is bool, in_inc_ir bool
);
DROP FUNCTION IF EXISTS location_list_class();
DROP FUNCTION IF EXISTS payment_get_entity_accounts (int, text, text);
DROP FUNCTION IF EXISTS payment_get_open_accounts(int);
DROP FUNCTION IF EXISTS payment_get_open_accounts(int, date, date);
DROP FUNCTION if exists payment_get_all_accounts(int);
DROP FUNCTION IF EXISTS payment_get_open_invoices
(in_account_class int,
 in_entity_credit_id int,
 in_curr char(3),
 in_datefrom date,
 in_dateto date,
 in_amountfrom numeric,
 in_amountto   numeric);
DROP FUNCTION IF EXISTS payment_get_open_invoice
(in_account_class int,
 in_entity_credit_id int,
 in_curr char(3),
 in_datefrom date,
 in_dateto date,
 in_amountfrom numeric,
 in_amountto   numeric,
 in_invnumber text);
DROP FUNCTION IF EXISTS payment_get_all_contact_invoices
(in_account_class int, in_business_id int, in_currency char(3),
        in_date_from date, in_date_to date, in_batch_id int,
        in_ar_ap_accno text, in_meta_number text, in_payment_date date);
DROP FUNCTION IF EXISTS payment_bulk_post
(in_transactions numeric[], in_batch_id int, in_source text, in_total numeric,
        in_ar_ap_accno text, in_cash_accno text,
        in_payment_date date, in_account_class int,
        in_exchangerate numeric, in_curr text);
DROP FUNCTION IF EXISTS payment_bulk_post
(in_transactions numeric[], in_batch_id int, in_source text, in_total numeric,
        in_ar_ap_accno text, in_cash_accno text,
        in_payment_date date, in_account_class int,
        in_exchangerate numeric, in_currency text);
DROP FUNCTION IF EXISTS payment_post
(in_datepaid                      date,
 in_account_class                 int,
 in_entity_credit_id              int,
 in_curr                          char(3),
 in_notes                         text,
 in_gl_description                text,
 in_cash_account_id               int[],
 in_amount                        numeric[],
 in_cash_approved                 bool[],
 in_source                        text[],
 in_memo                          text[],
 in_transaction_id                int[],
 in_op_amount                     numeric[],
 in_op_cash_account_id            int[],
 in_op_source                     text[],
 in_op_memo                       text[],
 in_op_account_id                 int[],
 in_ovp_payment_id                int[],
 in_approved                      bool);
DROP FUNCTION IF EXISTS payment_post
(in_datepaid                      date,
 in_account_class                 int,
 in_entity_credit_id                     int,
 in_curr                          char(3),
 in_exchangerate          numeric,
 in_notes                         text,
 in_gl_description                text,
 in_cash_account_id               int[],
 in_amount                        numeric[],
 in_cash_approved                 bool[],
 in_source                        text[],
 in_memo                          text[],
 in_transaction_id                int[],
 in_op_amount                     numeric[],
 in_op_cash_account_id            int[],
 in_op_source                     text[],
 in_op_memo                       text[],
 in_op_account_id                 int[],
 in_ovp_payment_id                int[],
 in_approved                      bool);
DROP FUNCTION IF EXISTS payment__search(text, date, date, int, text, int, char(3));
DROP FUNCTION IF EXISTS payment__reverse
(in_source text, in_date_paid date, in_credit_id int, in_cash_accno text,
        in_date_reversed date, in_account_class int, in_batch_id int,
        in_voucher_id int, in_exchangerate numeric, in_currency char(3));
DROP FUNCTION IF EXISTS payment__reverse
(in_source text, in_date_paid date, in_credit_id int, in_cash_accno text,
        in_date_reversed date, in_account_class int, in_batch_id int,
        in_voucher_id int);
DROP FUNCTION IF EXISTS overpayment__reverse
(in_id int, in_transdate date, in_batch_id int, in_account_class int,
in_cash_accno text, in_exchangerate numeric, in_curr char(3));
DROP FUNCTION IF EXISTS overpayment__reverse
(in_id int, in_transdate date, in_batch_id int, in_account_class int, in_exchangerate numeric, in_curr char(3));
DROP FUNCTION IF EXISTS wage__save
(in_rate numeric, in_entity_id int, in_type_id int);
DROP FUNCTION IF EXISTS deduction__save
(in_rate numeric, in_entity_id int, in_type_id int);
DROP FUNCTION IF EXISTS person__save (int, int, text, text, text, int);
DROP FUNCTION IF EXISTS  person__save_contact
(in_entity_id int, in_contact_class int, in_contact_orig text, in_contact_new TEXT);
DROP FUNCTION IF EXISTS pricematrix__for_customer
(in_credit_id int, in_parts_id int, in_transdate date, in_qty numeric);
DROP FUNCTION IF exists reconciliation__submit_set(in_report_id integer, in_line_ids integer[]);
DROP FUNCTION IF EXISTS reconciliation__get_cleared_balance(int);
DROP FUNCTION IF EXISTS reconciliation__get_cleared_balance(int,date);
DROP FUNCTION IF EXISTS reconciliation__new_report(
    in_chart_id int,
    in_total numeric,
    in_end_date date,
    in_recon_fx bool
);
DROP FUNCTION IF EXISTS
  reconciliation__pending_transactions(in_end_date date,
                                       in_chart_id integer,
                                       in_report_id integer,
                                       in_their_total numeric);
DROP FUNCTION IF EXISTS report__invoice_aging_detail
(in_entity_id int, in_entity_class int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool);
DROP FUNCTION IF EXISTS report__invoice_aging_detail
(in_entity_id int, in_entity_class int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool, in_name_part text);
DROP FUNCTION IF EXISTS report__invoice_aging_summary
(in_entity_id int, in_entity_class int, in_credit_id int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool);
DROP FUNCTION IF EXISTS report__invoice_aging_summary
(in_entity_id int, in_entity_class int, in_accno text, in_to_date date,
 in_business_units int[], in_use_duedate bool, in_name_part text);
DROP FUNCTION IF EXISTS report__gl
(in_reference text, in_accno text, in_category char(1),
in_source text, in_memo text,  in_description text, in_from_date date,
in_to_date date, in_approved bool, in_from_amount numeric, in_to_amount numeric,
in_business_units int[]);
DROP FUNCTION IF EXISTS report__aa_transactions
(in_entity_class int, in_account_id int, in_entity_name text,
 in_meta_number text,
 in_employee_id int, in_manager_id int, in_invnumber text, in_ordnumber text,
 in_ponumber text, in_source text, in_description text, in_notes text,
 in_shipvia text, in_from_date date, in_to_date date, in_on_hold bool,
 in_taxable bool, in_tax_account_id int, in_open bool, in_closed bool);
DROP FUNCTION IF EXISTS report__aa_transactions
(in_entity_class int, in_account_id int, in_entity_name text,
 in_meta_number text,
 in_employee_id int, in_manager_id int, in_invnumber text, in_ordnumber text,
 in_ponumber text, in_source text, in_description text, in_notes text,
 in_shipvia text, in_from_date date, in_to_date date, in_on_hold bool,
 in_taxable bool, in_tax_account_id int, in_open bool, in_closed bool,
 in_approved bool);
DROP FUNCTION IF EXISTS report__aa_transactions
(in_entity_class int, in_account_id int, in_entity_name text,
 in_meta_number text,
 in_employee_id int, in_manager_id int, in_invnumber text, in_ordnumber text,
 in_ponumber text, in_source text, in_description text, in_notes text,
 in_shipvia text, in_from_date date, in_to_date date, in_on_hold bool,
 in_taxable bool, in_tax_account_id int, in_open bool, in_closed bool,
 in_approved bool, in_partnumber text);
DROP FUNCTION IF EXISTS robot__save (int, text, text, text, int);
DROP FUNCTION IF EXISTS lsmb__create_role(text);
DROP FUNCTION IF EXISTS lsmb__grant_role(text, text);
DROP FUNCTION IF EXISTS defaults_get_defaultcurrency();
DROP FUNCTION IF EXISTS setting__set(varchar, varchar);
DROP FUNCTION IF EXISTS tax_form__save(in_id int, in_country_id int,
                          in_form_name text, in_default_reportable bool);
DROP FUNCTION IF EXISTS tax_form__list_all();
DROP FUNCTION IF EXISTS journal__add(text, text, int, date, bool, bool);
DROP FUNCTION IF EXISTS journal__add_line(integer, integer, numeric,
    boolean, text, integer[]);
DROP FUNCTION IF EXISTS  journal__search(
in_reference text,
in_description text,
in_entry_type int,
in_transaction_date date,
in_approved bool,
in_department_id int,
in_is_template bool,
in_meta_number text,
in_entity_class int,
in_recurring bool
);
DROP FUNCTION IF EXISTS trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[]);
DROP FUNCTION IF EXISTS trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[], in_balance_sign int);
DROP FUNCTION IF EXISTS trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[], in_balance_sign int,
 in_all_accounts boolean);
DROP FUNCTION IF EXISTS trial_balance__generate
(in_from_date DATE, in_to_date DATE, in_heading INT, in_accounts INT[],
 in_ignore_yearend TEXT, in_business_units int[], in_balance_sign int,
 in_all_accounts boolean, in_approved boolean);
DROP FUNCTION IF EXISTS invoice__get_by_vendor_number(text, text);
