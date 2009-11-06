CREATE TYPE tax_form_report_item AS (legal_name text, entity_id integer, entity_class integer, control_code text, meta_number character varying(32), acc_sum numeric, invoice_sum numeric, total_sum numeric);
CREATE TYPE tax_form_report_detail_item AS (legal_name text, entity_id integer, entity_class integer, control_code text, meta_number character varying(32), acc_sum numeric, invoice_sum numeric, total_sum numeric, invnumber text, duedate text);

CREATE OR REPLACE FUNCTION tax_form__list_all()
RETURNS SETOF country_tax_form as
$$
select * from country_tax_form order by country_id;
$$ language sql;

CREATE OR REPLACE FUNCTION tax_form_summary_report(in_tax_form_id int, in_begin date, in_end date) RETURNS setof tax_form_report_item AS $$
DECLARE
	out_row tax_form_report_item;
BEGIN
	FOR out_row IN SELECT company.legal_name, company.entity_id, entity_credit_account.entity_class, entity.control_code, entity_credit_account.meta_number, sum(CASE WHEN ac_tax_form.reportable THEN acc_trans.amount ELSE 0 END), sum(CASE WHEN invoice_tax_form.reportable THEN invoice.sellprice * invoice.qty ELSE 0 END), sum(CASE WHEN ac_tax_form.reportable THEN acc_trans.amount ELSE 0 END) + sum(CASE WHEN invoice_tax_form.reportable THEN invoice.sellprice * invoice.qty ELSE 0 END)
		FROM acc_trans
		JOIN (select id, entity_credit_account FROM ar UNION select id, entity_credit_account from ap) gl ON (gl.id = acc_trans.trans_id)
		LEFT JOIN ac_tax_form ON (acc_trans.entry_id = ac_tax_form.entry_id AND ac_tax_form.reportable)
		LEFT JOIN invoice ON (invoice.id = acc_trans.invoice_id) 
		LEFT JOIN invoice_tax_form ON (invoice.id = invoice_tax_form.invoice_id AND invoice_tax_form.reportable)  
		JOIN entity_credit_account ON (gl.entity_credit_account = entity_credit_account.id) 
		JOIN entity ON (entity.id = entity_credit_account.entity_id) 
		JOIN company ON (entity.id = company.entity_id)
		JOIN country_tax_form ON (entity_credit_account.taxform_id = country_tax_form.id)
		WHERE country_tax_form.id = in_tax_form_id
		AND transdate BETWEEN in_begin AND in_end
		GROUP BY legal_name, meta_number, company.entity_id, entity_credit_account.entity_class, entity.control_code
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tax_form_details_report(in_tax_form_id int, in_begin date, in_end date, in_meta_number text) RETURNS setof tax_form_report_detail_item AS $$
DECLARE
	out_row tax_form_report_detail_item;
BEGIN
	FOR out_row IN SELECT company.legal_name, company.entity_id, entity_credit_account.entity_class, entity.control_code, entity_credit_account.meta_number, sum(CASE WHEN ac_tax_form.reportable THEN acc_trans.amount ELSE 0 END), sum(CASE WHEN invoice_tax_form.reportable THEN invoice.sellprice * invoice.qty ELSE 0 END), sum(CASE WHEN ac_tax_form.reportable THEN acc_trans.amount ELSE 0 END) + sum(CASE WHEN invoice_tax_form.reportable THEN invoice.sellprice * invoice.qty ELSE 0 END), gl.invnumber, gl.duedate::text
		FROM acc_trans
                JOIN (select id, entity_credit_account, invnumber, duedate FROM ar UNION select id, entity_credit_account, invnumber, duedate FROM ap) gl ON (gl.id = acc_trans.trans_id)
		LEFT JOIN ac_tax_form ON (acc_trans.entry_id = ac_tax_form.entry_id AND ac_tax_form.reportable)
		LEFT JOIN invoice ON (invoice.id = acc_trans.invoice_id) 
		LEFT JOIN invoice_tax_form ON (invoice.id = invoice_tax_form.invoice_id AND invoice_tax_form.reportable)  
		JOIN entity_credit_account ON (gl.entity_credit_account = entity_credit_account.id) 
		JOIN entity ON (entity.id = entity_credit_account.entity_id) 
		JOIN company ON (entity.id = company.entity_id)
		JOIN country_tax_form ON (entity_credit_account.taxform_id = country_tax_form.id)
		WHERE country_tax_form.id = in_tax_form_id AND meta_number = in_meta_number
		AND transdate BETWEEN in_begin AND in_end
		GROUP BY legal_name, meta_number, company.entity_id, entity_credit_account.entity_class, entity.control_code, gl.invnumber, gl.duedate
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE plpgsql;
