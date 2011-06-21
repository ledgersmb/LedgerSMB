CREATE TYPE tax_form_report_item AS (
    legal_name text, 
    entity_id integer, 
    entity_class integer, 
    control_code text, 
    meta_number character varying(32), 
    acc_sum numeric, 
    invoice_sum numeric, 
    total_sum numeric);

CREATE TYPE tax_form_report_detail_item AS (
    legal_name text, 
    entity_id integer, 
    entity_class integer, 
    control_code text, 
    meta_number character varying(32), 
    acc_sum numeric, 
    invoice_sum numeric, 
    total_sum numeric, 
    invnumber text, 
    duedate text);

CREATE OR REPLACE FUNCTION tax_form_summary_report(in_tax_form_id int, in_begin date, in_end date) 
RETURNS SETOF tax_form_report_item AS $BODY$
DECLARE
	out_row tax_form_report_item;
BEGIN
	FOR out_row IN 
              SELECT company.legal_name, company.entity_id, 
                     entity_credit_account.entity_class, entity.control_code, 
                     entity_credit_account.meta_number, 
                     sum(CASE WHEN relation = 'acc_trans' 
                          THEN ac.reportable_amount * pmt.amount
                                / ac.amount
                          ELSE 0
                      END * CASE WHEN gl.class = 'ar' THEN -1 else 1 end),
                     sum(CASE WHEN relation = 'invoice'
                          THEN ac.reportable_amount * pmt.amount
                               / ac.amount
                          ELSE 0
                      END * CASE WHEN gl.class = 'ar' THEN -1 else 1 end)
                         
		FROM (select id, transdate, entity_credit_account, 'ar' as class FROM ar 
                       UNION 
                      select id, transdate, entity_credit_account, 'ap' as class from ap
                     ) gl
               JOIN (select trans_id, 'acc_trans' as relation, 
                             sum(amount) as amount,
                             sum(case when atf.reportable then amount else 0
                                 end) as reportable_amount
                        FROM  acc_trans
                        JOIN ac_tax_form atf
                          ON (acc_trans.entry_id = atf.entry_id)
                       GROUP BY trans_id
                       UNION
                      select trans_id, 'invoice' as relation, 
                             sum(sellprice * qty) as amount,
                             sum(case when itf.reportable 
                                      then sellprice * qty
                                      else 0
                                 end) as reportable_amount
                        FROM invoice
                        JOIN invoice_tax_form itf
                          ON (invoice.id = itf.invoice_id)
                       GROUP BY trans_id
                     ) ac ON (ac.trans_id = gl.id)
                JOIN (SELECT ac.trans_id, sum(ac.amount) as amount,
                             as_array(entry_id) as entry_ids, 
                             as_array(chart_id) as chart_ids,
                             count(*) as num
                        FROM acc_trans ac
                       where chart_id in (select account_id
                                            from account_link
                                           where description like '%paid')
                          AND transdate BETWEEN in_begin AND in_end
                     group by ac.trans_id
                     ) pmt ON  (pmt.trans_id = gl.id)
		JOIN entity_credit_account 
                  ON (gl.entity_credit_account = entity_credit_account.id) 
		JOIN entity ON (entity.id = entity_credit_account.entity_id) 
		JOIN company ON (entity.id = company.entity_id)
		JOIN country_tax_form ON (entity_credit_account.taxform_id = country_tax_form.id)
               WHERE country_tax_form.id = in_tax_form_id
             GROUP BY legal_name, meta_number, company.entity_id, entity_credit_account.entity_class, entity.control_code 
    LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$BODY$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION tax_form_details_report(in_tax_form_id int, in_begin date, in_end date, in_meta_number text) 
RETURNS SETOF tax_form_report_detail_item AS $BODY$
DECLARE
	out_row tax_form_report_detail_item;
BEGIN
	FOR out_row IN 
              SELECT company.legal_name, company.entity_id, 
                     entity_credit_account.entity_class, entity.control_code, 
                     entity_credit_account.meta_number, 
                     sum(CASE WHEN relation = 'acc_trans'
                          THEN ac.reportable_amount * pmt.amount
                                / ac.amount
                          ELSE 0
                      END * CASE WHEN gl.class = 'ar' THEN -1 else 1 end),
                     sum(CASE WHEN relation = 'invoice'
                          THEN ac.reportable_amount * pmt.amount
                               / ac.amount
                          ELSE 0
                      END * CASE WHEN gl.class = 'ar' THEN -1 else 1 end),
                     gl.invnumber, gl.duedate::text
                FROM (select id, entity_credit_account, invnumber, duedate, transdate, 'ar' as class
                        FROM ar 
                       UNION 
                      select id, entity_credit_account, invnumber, duedate, transdate, 'ap' as class
                        FROM ap
                     ) gl 
                JOIN (select trans_id, 'acc_trans' as relation, 
                             sum(amount) as amount,
                             sum(case when atf.reportable then amount else 0
                                 end) as reportable_amount
                        FROM  acc_trans
                        JOIN ac_tax_form atf
                          ON (acc_trans.entry_id = atf.entry_id)
                       GROUP BY trans_id
                       UNION
                      select trans_id, 'invoice' as relation, 
                             sum(sellprice * qty) as amount,
                             sum(case when itf.reportable 
                                      then sellprice * qty
                                      else 0
                                 end) as reportable_amount
                        FROM invoice
                        JOIN invoice_tax_form itf
                          ON (invoice.id = itf.invoice_id)
                       GROUP BY trans_id
                     ) ac ON (ac.trans_id = gl.id)
		JOIN entity_credit_account ON (gl.entity_credit_account = entity_credit_account.id) 
		JOIN entity ON (entity.id = entity_credit_account.entity_id) 
		JOIN company ON (entity.id = company.entity_id)
		JOIN country_tax_form ON (entity_credit_account.taxform_id = country_tax_form.id)
                JOIN (SELECT ac.trans_id, sum(ac.amount) as amount,
                             as_array(entry_id) as entry_ids, 
                             as_array(chart_id) as chart_ids,
                             count(*) as num
                        FROM acc_trans ac
                       where chart_id in (select account_id
                                            from account_link
                                           where description like '%paid')
                          AND transdate BETWEEN in_begin AND in_end
                     group by ac.trans_id
                     ) pmt ON  (pmt.trans_id = gl.id)
		WHERE country_tax_form.id = in_tax_form_id AND meta_number = in_meta_number
		GROUP BY legal_name, meta_number, company.entity_id, entity_credit_account.entity_class, entity.control_code, gl.invnumber, gl.duedate, gl.id
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$BODY$ LANGUAGE PLPGSQL;
