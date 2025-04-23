
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
    tax_id text,
    sales_tax_id text,
    line_one text,
    line_two text,
    line_three text,
    city text,
    state text,
    mail_code text,
    country_id integer,
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
    tax_id text,
    sales_tax_id text,
    line_one text,
    line_two text,
    line_three text,
    city text,
    state text,
    mail_code text,
    country_id integer,
    acc_sum numeric,
    invoice_sum numeric,
    total_sum numeric,
    invnumber text,
    duedate text,
    invoice_id int);

drop function if exists tax_form_summary_report(int,date,date);
CREATE OR REPLACE FUNCTION tax_form_summary_report(in_tax_form_id int, in_from_date date, in_to_date date)
RETURNS SETOF tax_form_report_item AS $BODY$
              SELECT entity_credit_account.id,
                     company.legal_name, company.entity_id,
                     entity_credit_account.entity_class, entity.control_code,
                     entity_credit_account.meta_number,
                     company.tax_id, company.sales_tax_id,
                     addr.line_one, addr.line_two, addr.line_three,
                     addr.city, addr.state, addr.mail_code, addr.country_id,
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
                             amount_bc, 'ar' as class
                        FROM ar
                       WHERE approved
                       UNION
                      select id, transdate, entity_credit_account, invoice,
                             amount_bc, 'ap' as class
                        FROM ap
                       WHERE approved
                     ) gl
               JOIN (select trans_id, 'acc_trans' as relation,
                             sum(amount_bc) as amount_bc,
                             sum(case when atf.reportable then amount_bc else 0
                                 end) as reportable_amount_bc
                       FROM  acc_trans
                    LEFT JOIN ac_tax_form atf
                          ON (acc_trans.entry_id = atf.entry_id)
                      WHERE acc_trans.approved
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
                             array_agg(entry_id) as entry_ids,
                             array_agg(chart_id) as chart_ids,
                             count(*) as num
                        FROM acc_trans ac
                       WHERE approved
                         AND chart_id in (select account_id
                                            from account_link
                                           where description like '%paid')
                         AND transdate BETWEEN in_from_date AND in_to_date
                     group by ac.trans_id
                     ) pmt ON  (pmt.trans_id = gl.id)
                JOIN entity_credit_account
                  ON (gl.entity_credit_account = entity_credit_account.id)
                JOIN entity ON (entity.id = entity_credit_account.entity_id)
                JOIN company ON (entity.id = company.entity_id)
                JOIN country_tax_form ON (entity_credit_account.taxform_id = country_tax_form.id)
  LEFT JOIN LATERAL (
    SELECT * FROM (
      select * from (
        -- entity_credit_account.id ensures a 1-1 join with the left side
        select entity_credit_account.id as eca_id, l.*
          from eca_to_location eca2l
                 join location_class lc on lc.id = eca2l.location_class
                 join location l on l.id = eca2l.location_id
         where eca2l.credit_id = entity_credit_account.id -- this is the LATERAL!
           and lc.authoritative
         order by lc.id, eca2l.created
      ) y
       union all
      select * from (
        -- entity_credit_account.id ensures a 1-1 join with the left side
        -- and due to the join on the left side,
        -- entity_credit_account.entity_id = entity.id
        select entity_credit_account.id, l.*
          from entity_to_location e2l
                 join location_class lc on lc.id = e2l.location_class
                 join location l on l.id = e2l.location_id
         where e2l.entity_id = entity.id -- this is the LATERAL!
           and lc.authoritative
         order by lc.id, e2l.created
      ) z
    ) x
    LIMIT 1
  ) addr ON addr.eca_id = entity_credit_account.id
  WHERE country_tax_form.id = in_tax_form_id
  GROUP BY legal_name, meta_number, company.tax_id, company.sales_tax_id, company.entity_id,
           entity_credit_account.entity_class, entity.control_code, entity_credit_account.id,
           addr.line_one, addr.line_two, addr.line_three, addr.city, addr.state,
           addr.mail_code, addr.country_id;

$BODY$ LANGUAGE SQL;

COMMENT ON FUNCTION tax_form_summary_report
(in_tax_form_id int, in_from_date date, in_to_date date) IS
$$This provides the total reportable value per vendor.  As per 1099 forms, these
are cash-basis documents and show amounts paid.$$;

drop function if exists tax_form_details_report(int, date, date, text);
CREATE OR REPLACE FUNCTION tax_form_details_report(in_tax_form_id int, in_from_date date, in_to_date date, in_meta_number text)
RETURNS SETOF tax_form_report_detail_item AS $BODY$
              SELECT entity_credit_account.id,
                     company.legal_name, company.entity_id,
                     entity_credit_account.entity_class, entity.control_code,
                     entity_credit_account.meta_number,
                     company.tax_id, company.sales_tax_id,
                     addr.line_one, addr.line_two, addr.line_three,
                     addr.city, addr.state, addr.mail_code, addr.country_id,
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
                       WHERE approved
                       UNION
                      select id, entity_credit_account, invnumber, duedate,
                             amount_bc, transdate, 'ap' as class
                        FROM ap
                       WHERE approved
                     ) gl
                JOIN (select trans_id, 'acc_trans' as relation,
                             sum(amount_bc) as amount_bc,
                             sum(case when atf.reportable then amount_bc else 0
                                 end) as reportable_amount_bc
                        FROM  acc_trans
                   LEFT JOIN ac_tax_form atf
                          ON (acc_trans.entry_id = atf.entry_id)
                       WHERE acc_trans.approved
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
                             array_agg(entry_id) as entry_ids,
                             array_agg(chart_id) as chart_ids,
                             count(*) as num
                        FROM acc_trans ac
                       WHERE approved
                         AND chart_id in (select account_id
                                            from account_link
                                           where description like '%paid')
                          AND transdate BETWEEN in_from_date AND in_to_date
                     group by ac.trans_id
                     ) pmt ON  (pmt.trans_id = gl.id)
  LEFT JOIN LATERAL (
    SELECT * FROM (
      select * from (
      select entity_credit_account.entity_id, l.*
        from eca_to_location eca2l
               join location_class lc on lc.id = eca2l.location_class
               join location l on l.id = eca2l.location_id
       where eca2l.credit_id = entity_credit_account.id -- this is the LATERAL!
         and lc.authoritative
       order by lc.id, eca2l.created
      ) y
       union all
      select * from (
      select entity.id, l.*
        from entity_to_location e2l
               join location_class lc on lc.id = e2l.location_class
               join location l on l.id = e2l.location_id
       where e2l.entity_id = entity.id -- this is the LATERAL!
         and lc.authoritative
       order by lc.id, e2l.created
      ) z
    ) x
    LIMIT 1
  ) addr ON addr.entity_id = entity.id
                WHERE country_tax_form.id = in_tax_form_id AND meta_number = in_meta_number
  GROUP BY legal_name, meta_number, company.tax_id, company.sales_tax_id, company.entity_id,
           entity_credit_account.entity_class, entity.control_code, entity_credit_account.id,
           addr.line_one, addr.line_two, addr.line_three, addr.city, addr.state,
           addr.mail_code, addr.country_id,
           gl.invnumber, gl.duedate, gl.id
$BODY$ LANGUAGE SQL;

COMMENT ON FUNCTION tax_form_details_report
(in_tax_form_id int, in_from_date date, in_to_date date, in_meta_number text) IS
$$ This provides a list of invoices and transactions that a report hits.  This
is intended to allow an organization to adjust what is reported on the 1099
before printing them.$$;

drop function if exists tax_form_summary_report_accrual(int, date, date);
CREATE OR REPLACE FUNCTION tax_form_summary_report_accrual
(in_tax_form_id int, in_from_date date, in_to_date date)
RETURNS SETOF tax_form_report_item AS $BODY$
              SELECT entity_credit_account.id,
                     company.legal_name, company.entity_id,
                     entity_credit_account.entity_class, entity.control_code,
                     entity_credit_account.meta_number,
                     company.tax_id, company.sales_tax_id,
                     addr.line_one, addr.line_two, addr.line_three,
                     addr.city, addr.state, addr.mail_code, addr.country_id,
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
                             amount_bc, 'ar' as class
                        FROM ar
                       WHERE approved
                         AND transdate BETWEEN in_from_date AND in_to_date
                       UNION
                      select id, transdate, entity_credit_account, invoice,
                             amount_bc, 'ap' as class
                        FROM ap
                       WHERE approved
                         AND transdate BETWEEN in_from_date AND in_to_date
                     ) gl
               JOIN (select trans_id, 'acc_trans' as relation,
                             sum(amount_bc) as amount_bc,
                             sum(case when atf.reportable then amount_bc else 0
                                 end) as reportable_amount_bc
                       FROM  acc_trans
                    LEFT JOIN ac_tax_form atf
                          ON (acc_trans.entry_id = atf.entry_id)
                      WHERE acc_trans.approved
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
  LEFT JOIN LATERAL (
    SELECT * FROM (
      select * from (
      select entity_credit_account.entity_id, l.* from eca_to_location eca2l
                        join location_class lc on lc.id = eca2l.location_class
                        join location l on l.id = eca2l.location_id
       where eca2l.credit_id = entity_credit_account.id and lc.authoritative
       order by lc.id, eca2l.created
      ) y
       union all
      select * from (
      select entity.id, l.* from entity_to_location e2l
                        join location_class lc on lc.id = e2l.location_class
                        join location l on l.id = e2l.location_id
       where e2l.entity_id = entity.id and lc.authoritative
       order by lc.id, e2l.created
      ) z
    ) x
    LIMIT 1
  ) addr ON addr.entity_id = entity.id
  WHERE country_tax_form.id = in_tax_form_id
  GROUP BY legal_name, meta_number, company.tax_id, company.sales_tax_id, company.entity_id,
           entity_credit_account.entity_class, entity.control_code, entity_credit_account.id,
           addr.line_one, addr.line_two, addr.line_three, addr.city, addr.state,
           addr.mail_code, addr.country_id;

$BODY$ LANGUAGE SQL;

COMMENT ON FUNCTION tax_form_summary_report_accrual
(in_tax_form_id int, in_from_date date, in_to_date date) IS
$$This provides the total reportable value per vendor.  As per 1099 forms, these
are cash-basis documents and show amounts paid.$$;

drop function if exists tax_form_details_report_accrual(int, date, date, text);
CREATE OR REPLACE FUNCTION tax_form_details_report_accrual
(in_tax_form_id int, in_from_date date, in_to_date date, in_meta_number text)
RETURNS SETOF tax_form_report_detail_item AS $BODY$
              SELECT entity_credit_account.id,
                     company.legal_name, company.entity_id,
                     entity_credit_account.entity_class, entity.control_code,
                     entity_credit_account.meta_number,
                     company.tax_id, company.sales_tax_id,
                     addr.line_one, addr.line_two, addr.line_three,
                     addr.city, addr.state, addr.mail_code, addr.country_id,
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
                       WHERE approved
                         AND transdate BETWEEN in_from_date AND in_to_date
                       UNION
                      select id, entity_credit_account, invnumber, duedate,
                             amount_bc, transdate, 'ap' as class
                        FROM ap
                       WHERE approved
                         AND transdate BETWEEN in_from_date AND in_to_date
                     ) gl
                JOIN (select trans_id, 'acc_trans' as relation,
                             sum(amount_bc) as amount_bc,
                             sum(case when atf.reportable then amount_bc else 0
                                 end) as reportable_amount_bc
                        FROM  acc_trans
                             LEFT JOIN ac_tax_form atf
                          ON (acc_trans.entry_id = atf.entry_id)
                       WHERE acc_trans.approved
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
  LEFT JOIN LATERAL (
    SELECT * FROM (
      select * from (
      select entity_credit_account.entity_id, l.* from eca_to_location eca2l
                        join location_class lc on lc.id = eca2l.location_class
                        join location l on l.id = eca2l.location_id
       where eca2l.credit_id = entity_credit_account.id and lc.authoritative
       order by lc.id, eca2l.created
      ) y
       union all
      select * from (
      select entity.id, l.* from entity_to_location e2l
                        join location_class lc on lc.id = e2l.location_class
                        join location l on l.id = e2l.location_id
       where e2l.entity_id = entity.id and lc.authoritative
       order by lc.id, e2l.created
      ) z
    ) x
    LIMIT 1
  ) addr ON addr.entity_id = entity.id
  WHERE country_tax_form.id = in_tax_form_id AND meta_number = in_meta_number
  GROUP BY legal_name, meta_number, company.tax_id, company.sales_tax_id, company.entity_id,
           entity_credit_account.entity_class, entity.control_code, entity_credit_account.id,
           addr.line_one, addr.line_two, addr.line_three, addr.city, addr.state,
           addr.mail_code, addr.country_id,
           gl.invnumber, gl.duedate, gl.id
$BODY$ LANGUAGE SQL;

COMMENT ON FUNCTION tax_form_details_report_accrual
(in_tax_form_id int, in_from_date date, in_to_date date, in_meta_number text) IS
$$ This provides a list of invoices and transactions that a report hits.  This
is intended to allow an organization to adjust what is reported on the 1099
before printing them.$$;


update defaults set value='yes' where setting_key='module_load_ok';

COMMIT;
