
set client_min_messages = 'warning';


-- First a couple of notes about this file and what will probably change in the
-- future.
--
-- The current generation here of reports assumes that we are providing
-- reporting of purchases or sales to one country only.  If this ever changes
-- we will need an abstraction layer like we use with fixed assets.  I suspect
-- we will go that way anyway since it will make some things easier.
--
-- This file provides 1099 reporting (MISC and INT).  It does NOT provide 1099-K
-- and we'd need an abstraction layer for that. --CT

BEGIN;
DROP TYPE IF EXISTS tax_form_report_item CASCADE;
CREATE TYPE tax_form_report_item AS (
    credit_id integer,
    legal_name text,
    entity_id integer,
    entity_class integer,
    control_code text,
    meta_number character varying(32),
    acc_sum numeric,
    invoice_sum numeric,
    total_sum numeric);

DROP TYPE IF EXISTS tax_form_report_detail_item CASCADE;
CREATE TYPE tax_form_report_detail_item AS (
    credit_id integer,
    legal_name text,
    entity_id integer,
    entity_class integer,
    control_code text,
    meta_number character varying(32),
    acc_sum numeric,
    invoice_sum numeric,
    total_sum numeric,
    invnumber text,
    duedate text,
    invoice_id int);

CREATE OR REPLACE FUNCTION tax_form_summary_report(in_tax_form_id int, in_begin date, in_end date)
RETURNS SETOF tax_form_report_item AS $BODY$
              SELECT entity_credit_account.id,
                     company.legal_name, company.entity_id,
                     entity_credit_account.entity_class, entity.control_code,
                     entity_credit_account.meta_number,
                     sum(CASE WHEN gl.amount_bc = 0 THEN 0
                              WHEN relation = 'acc_trans'
                          THEN ac.reportable_amount_bc * pmt.amount_bc
                                / gl.amount_bc
                          ELSE 0
                      END * CASE WHEN gl.class = 'ap' THEN -1 else 1 end),
                     sum(CASE WHEN gl.amount_bc = 0 THEN 0
                              WHEN relation = 'invoice'
                          THEN ac.reportable_amount_bc * pmt.amount_bc
                               / gl.amount_bc
                          ELSE 0
                      END * CASE WHEN gl.class = 'ar' THEN -1 else 1 end),
                     sum(CASE WHEN gl.amount_bc = 0 THEN 0
                          ELSE ac.reportable_amount_bc * pmt.amount_bc
                                / gl.amount_bc
                      END * CASE WHEN gl.class = 'ap' THEN -1 else 1 end
                      * CASE WHEN ac.relation = 'invoice' then -1 else 1 end)

                FROM (select id, transdate, entity_credit_account, invoice,
                             amount_bc, 'ar' as class FROM ar
                       UNION
                      select id, transdate, entity_credit_account, invoice,
                              amount_bc, 'ap' as class from ap
                     ) gl
               JOIN (select trans_id, 'acc_trans' as relation,
                             sum(amount_bc) as amount_bc,
                             sum(case when atf.reportable then amount_bc else 0
                                 end) as reportable_amount_bc
                        FROM  acc_trans
                    LEFT JOIN ac_tax_form atf
                          ON (acc_trans.entry_id = atf.entry_id)
                       GROUP BY trans_id
                       UNION
                      select trans_id, 'invoice' as relation,
                             sum(sellprice * qty) as amount_bc,
                             sum(case when itf.reportable
                                      then sellprice * qty
                                      else 0
                                 end) as reportable_amount_bc
                        FROM invoice
                    LEFT JOIN invoice_tax_form itf
                          ON (invoice.id = itf.invoice_id)
                       GROUP BY trans_id
                     ) ac ON (ac.trans_id = gl.id
                             AND ((gl.invoice is true and ac.relation='invoice')
                                  OR (gl.invoice is false
                                     and ac.relation='acc_trans')))
                JOIN (SELECT ac.trans_id, sum(ac.amount_bc) as amount_bc,
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
             GROUP BY legal_name, meta_number, company.entity_id, entity_credit_account.entity_class, entity.control_code, entity_credit_account.id
$BODY$ LANGUAGE SQL;

COMMENT ON FUNCTION tax_form_summary_report
(in_tax_form_id int, in_begin date, in_end date) IS
$$This provides the total reportable value per vendor.  As per 1099 forms, these
are cash-basis documents and show amounts paid.$$;

CREATE OR REPLACE FUNCTION tax_form_details_report(in_tax_form_id int, in_begin date, in_end date, in_meta_number text)
RETURNS SETOF tax_form_report_detail_item AS $BODY$
              SELECT entity_credit_account.id,
                     company.legal_name, company.entity_id,
                     entity_credit_account.entity_class, entity.control_code,
                     entity_credit_account.meta_number,
                     sum(CASE WHEN gl.amount_bc = 0 then 0
                              when relation = 'acc_trans'
                          THEN ac.reportable_amount_bc * pmt.amount_bc
                                / gl.amount_bc
                          ELSE 0
                      END * CASE WHEN gl.class = 'ap' THEN -1 else 1 end),
                     sum(CASE WHEN gl.amount_bc = 0 then 0
                              WHEN relation = 'invoice'
                          THEN ac.reportable_amount_bc * pmt.amount_bc
                               / gl.amount_bc
                          ELSE 0
                      END * CASE WHEN gl.class = 'ar' THEN -1 else 1 end),
                     SUM(CASE WHEN gl.amount_bc = 0 THEN 0
                              ELSE ac.reportable_amount_bc * pmt.amount_bc
                               / gl.amount_bc
                              END
                         * CASE WHEN gl.class = 'ap' THEN -1 else 1 end
                         * CASE WHEN relation = 'invoice' THEN -1 ELSE 1 END),
                     gl.invnumber, gl.duedate::text, gl.id
                FROM (select id, entity_credit_account, invnumber, duedate,
                             amount_bc, transdate, 'ar' as class
                        FROM ar
                       UNION
                      select id, entity_credit_account, invnumber, duedate,
                             amount_bc, transdate, 'ap' as class
                        FROM ap
                     ) gl
                JOIN (select trans_id, 'acc_trans' as relation,
                             sum(amount_bc) as amount_bc,
                             sum(case when atf.reportable then amount_bc else 0
                                 end) as reportable_amount_bc
                        FROM  acc_trans
                   LEFT JOIN ac_tax_form atf
                          ON (acc_trans.entry_id = atf.entry_id)
                       GROUP BY trans_id
                       UNION
                      select trans_id, 'invoice' as relation,
                             sum(sellprice * qty) as amount_bc,
                             sum(case when itf.reportable
                                      then sellprice * qty
                                      else 0
                                 end) as reportable_amount_bc
                        FROM invoice
                   LEFT JOIN invoice_tax_form itf
                          ON (invoice.id = itf.invoice_id)
                       GROUP BY trans_id
                     ) ac ON (ac.trans_id = gl.id)
                JOIN entity_credit_account ON (gl.entity_credit_account = entity_credit_account.id)
                JOIN entity ON (entity.id = entity_credit_account.entity_id)
                JOIN company ON (entity.id = company.entity_id)
                JOIN country_tax_form ON (entity_credit_account.taxform_id = country_tax_form.id)
                JOIN (SELECT ac.trans_id, sum(ac.amount_bc) as amount_bc,
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
                GROUP BY legal_name, meta_number, company.entity_id, entity_credit_account.entity_class, entity.control_code, gl.invnumber, gl.duedate, gl.id, entity_credit_account.id
$BODY$ LANGUAGE SQL;

COMMENT ON FUNCTION tax_form_details_report
(in_tax_form_id int, in_begin date, in_end date, in_meta_number text) IS
$$ This provides a list of invoices and transactions that a report hits.  This
is intended to allow an organization to adjust what is reported on the 1099
before printing them.$$;

CREATE OR REPLACE FUNCTION tax_form_summary_report_accrual
(in_tax_form_id int, in_begin date, in_end date)
RETURNS SETOF tax_form_report_item AS $BODY$
              SELECT entity_credit_account.id,
                     company.legal_name, company.entity_id,
                     entity_credit_account.entity_class, entity.control_code,
                     entity_credit_account.meta_number,
                     sum(CASE WHEN gl.amount_bc = 0 THEN 0
                              WHEN relation = 'acc_trans'
                          THEN ac.reportable_amount_bc
                          ELSE 0
                      END * CASE WHEN gl.class = 'ap' THEN -1 else 1 end),
                     sum(CASE WHEN gl.amount_bc = 0 THEN 0
                              WHEN relation = 'invoice'
                          THEN ac.reportable_amount_bc
                          ELSE 0
                      END * CASE WHEN gl.class = 'ar' THEN -1 else 1 end),
                     sum(CASE WHEN gl.amount_bc = 0 THEN 0
                          ELSE ac.reportable_amount_bc
                      END * CASE WHEN gl.class = 'ap' THEN -1 else 1 end
                      * CASE WHEN ac.relation = 'invoice' then -1 else 1 end)

                FROM (select id, transdate, entity_credit_account, invoice,
                             amount_bc, 'ar' as class FROM ar
                       WHERE transdate BETWEEN in_begin AND in_end
                       UNION
                      select id, transdate, entity_credit_account, invoice,
                              amount_bc, 'ap' as class from ap
                       WHERE transdate BETWEEN in_begin AND in_end
                     ) gl
               JOIN (select trans_id, 'acc_trans' as relation,
                             sum(amount_bc) as amount_bc,
                             sum(case when atf.reportable then amount_bc else 0
                                 end) as reportable_amount_bc
                        FROM  acc_trans
                    LEFT JOIN ac_tax_form atf
                          ON (acc_trans.entry_id = atf.entry_id)
                       GROUP BY trans_id
                       UNION
                      select trans_id, 'invoice' as relation,
                             sum(sellprice * qty) as amount_bc,
                             sum(case when itf.reportable
                                      then sellprice * qty
                                      else 0
                                 end) as reportable_amount_bc
                        FROM invoice
                    LEFT JOIN invoice_tax_form itf
                          ON (invoice.id = itf.invoice_id)
                       GROUP BY trans_id
                     ) ac ON (ac.trans_id = gl.id
                             AND ((gl.invoice is true and ac.relation='invoice')
                                  OR (gl.invoice is false
                                     and ac.relation='acc_trans')))
                JOIN entity_credit_account
                  ON (gl.entity_credit_account = entity_credit_account.id)
                JOIN entity ON (entity.id = entity_credit_account.entity_id)
                JOIN company ON (entity.id = company.entity_id)
                JOIN country_tax_form ON (entity_credit_account.taxform_id = country_tax_form.id)
               WHERE country_tax_form.id = in_tax_form_id
             GROUP BY legal_name, meta_number, company.entity_id, entity_credit_account.entity_class, entity.control_code, entity_credit_account.id
$BODY$ LANGUAGE SQL;

COMMENT ON FUNCTION tax_form_summary_report_accrual
(in_tax_form_id int, in_begin date, in_end date) IS
$$This provides the total reportable value per vendor.  As per 1099 forms, these
are cash-basis documents and show amounts paid.$$;

CREATE OR REPLACE FUNCTION tax_form_details_report_accrual
(in_tax_form_id int, in_begin date, in_end date, in_meta_number text)
RETURNS SETOF tax_form_report_detail_item AS $BODY$
              SELECT entity_credit_account.id,
                     company.legal_name, company.entity_id,
                     entity_credit_account.entity_class, entity.control_code,
                     entity_credit_account.meta_number,
                     sum(CASE WHEN gl.amount_bc = 0 then 0
                              when relation = 'acc_trans'
                          THEN ac.reportable_amount_bc
                          ELSE 0
                      END * CASE WHEN gl.class = 'ap' THEN -1 else 1 end),
                     sum(CASE WHEN gl.amount_bc = 0 then 0
                              WHEN relation = 'invoice'
                          THEN ac.reportable_amount_bc
                          ELSE 0
                      END * CASE WHEN gl.class = 'ar' THEN -1 else 1 end),
                     SUM(CASE WHEN gl.amount_bc = 0
                                   THEN 0
                              ELSE ac.reportable_amount_bc
                              END
                         * CASE WHEN gl.class = 'ap' THEN -1 else 1 end
                         * CASE WHEN relation = 'invoice' THEN -1 ELSE 1 END),
                     gl.invnumber, gl.duedate::text, gl.id
                FROM (select id, entity_credit_account, invnumber, duedate,
                             amount_bc, transdate, 'ar' as class
                        FROM ar
                       WHERE transdate BETWEEN in_begin AND in_end
                       UNION
                      select id, entity_credit_account, invnumber, duedate,
                             amount_bc, transdate, 'ap' as class
                        FROM ap
                       WHERE transdate BETWEEN in_begin AND in_end
                     ) gl
                JOIN (select trans_id, 'acc_trans' as relation,
                             sum(amount_bc) as amount_bc,
                             sum(case when atf.reportable then amount_bc else 0
                                 end) as reportable_amount_bc
                        FROM  acc_trans
                   LEFT JOIN ac_tax_form atf
                          ON (acc_trans.entry_id = atf.entry_id)
                       GROUP BY trans_id
                       UNION
                      select trans_id, 'invoice' as relation,
                             sum(sellprice * qty) as amount_bc,
                             sum(case when itf.reportable
                                      then sellprice * qty
                                      else 0
                                 end) as reportable_amount_bc
                        FROM invoice
                   LEFT JOIN invoice_tax_form itf
                          ON (invoice.id = itf.invoice_id)
                       GROUP BY trans_id
                     ) ac ON (ac.trans_id = gl.id)
                JOIN entity_credit_account ON (gl.entity_credit_account = entity_credit_account.id)
                JOIN entity ON (entity.id = entity_credit_account.entity_id)
                JOIN company ON (entity.id = company.entity_id)
                JOIN country_tax_form ON (entity_credit_account.taxform_id = country_tax_form.id)
                WHERE country_tax_form.id = in_tax_form_id AND meta_number = in_meta_number
                GROUP BY legal_name, meta_number, company.entity_id, entity_credit_account.entity_class, entity.control_code, gl.invnumber, gl.duedate, gl.id, entity_credit_account.id
$BODY$ LANGUAGE SQL;

COMMENT ON FUNCTION tax_form_details_report_accrual
(in_tax_form_id int, in_begin date, in_end date, in_meta_number text) IS
$$ This provides a list of invoices and transactions that a report hits.  This
is intended to allow an organization to adjust what is reported on the 1099
before printing them.$$;


update defaults set value='yes' where setting_key='module_load_ok';

COMMIT;
