create index ac_trns_trans_id on acc_trans (trans_id)@
create index ac_trns_chart_id on acc_trans (chart_id)@
create index ac_trns_transdate on acc_trans (transdate)@
create index ac_trns_source on acc_trans (source)@
create index ap_id_x on ap (id)@
create index ap_transdate_x on ap (transdate)@
create index ap_invnumber_x on ap (invnumber)@
create index ap_ordnumber_x on ap (ordnumber)@
create index ap_vendor_id_x on ap (vendor_id)@
create index ap_emp_id_x on ap (employee_id)@
create index ar_id_x on ar (id)@
create index ar_transdate_x on ar (transdate)@
create index ar_invnumber_x on ar (invnumber)@
create index ar_ordnumber_x on ar (ordnumber)@
create index ar_cust_id_x on ar (customer_id)@
create index ar_emp_id_x on ar (employee_id)@
create index assembly_id_x on assembly (id)@
create index chart_id_x on chart (id)@
create unique index chart_accno_x on chart (accno)@
create index chart_category_x on chart (category)@
create index chart_link_x on chart (link)@
create index chart_gifi_accno on chart (gifi_accno)@
create index cust_id_x on customer (id)@
create index cust_customer_id_x on customertax (customer_id)@
create index cust_custnum_x on customer (customernumber)@
create index cust_name_x on customer (name)@
create index cust_contact_x on customer (contact)@
create index employee_id_x on employee (id)@
create unique index employee_login_x on employee (login)@
create index employee_name_x on employee (name)@
create index exchrate_ct_x on exchangerate (curr, transdate)@
create unique index gifi_accno_x on gifi (accno)@
create index gl_id_x on gl (id)@
create index gl_transdate_x on gl (transdate)@
create index gl_reference_x on gl (reference)@
create index gl_description_x on gl (description)@
create index gl_employee_id_x on gl (employee_id)@
create index invoi_id_x on invoice (id)@
create index invoi_trans_id_x on invoice (trans_id)@
create index makmod_parts_id on makemodel (parts_id)@
create index oe_id_x on oe (id)@
create index oe_transdate_x on oe (transdate)@
create index oe_ordnumber_x on oe (ordnumber)@
create index oe_emp_id_x on oe (employee_id)@
create index orditems_trans_id on orderitems (trans_id)@
create index parts_id_x on parts (id)@
create index parts_partnumber on parts (partnumber)@
-- create index parts_desc on parts (description)@
create index partstax_parts_id on partstax (parts_id)@
create index vend_id_x on vendor (id)@
create index vend_name_x on vendor (name)@
create index vend_vendnum_x on vendor (vendornumber)@
create index vend_contact_x on vendor (contact)@
create index vendtax_vendor_id on vendortax (vendor_id)@
create index shipto_trans_id on shipto (trans_id)@
create index project_id_x on project (id)@
create index partsgroup_id_x on partsgroup (id)@
