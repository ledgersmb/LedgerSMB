BEGIN;

DROP TYPE IF EXISTS purchase_info CASCADE;

CREATE TYPE purchase_info AS (
    id int,
    invoice bool,
    invnumber text,
    ordnumber text,
    ponumber text,
    transdate date,
    entity_name text,
    meta_number text,
    entity_id int,
    amount numeric,
    amount_paid numeric,
    tax numeric,
    currency char(3),
    date_paid date,
    due_date date,
    notes text,
    shipping_point text,
    ship_via text,
    business_units text[]
);

CREATE OR REPLACE FUNCTION ar_ap__transaction_search
(in_account_id int, in_name_part text, in_meta_number text, in_invnumber text,
 in_ordnumber text, in_ponumber text, in_source text, in_description text,
 in_notes text, in_shipvia text, in_from_date date, in_to_date date,
 in_on_hold bool, in_inc_open bool, in_inc_closed bool, in_as_of date,
 in_entity_class int)
RETURNS SETOF purchase_info AS
$$
   SELECT gl.id, gl.invoice,
          gl.invnumber, gl.ordnumber, gl.ponumber, gl.transdate,
          e.name, eca.meta_number::text, e.id, gl.amount,
          gl.amount - sum(CASE WHEN l.description IN ('AR', 'AP')
                               THEN ac.amount ELSE 0
                           END),
          gl.amount - gl.netamount, gl.curr, gl.datepaid, gl.duedate,
          gl.notes, gl.shippingpoint, gl.shipvia,
          compound_array(bua.business_units || bui.business_units)
     FROM (select id, invoice, invnumber, ordnumber, ponumber, transdate, duedate,
                  description, notes, shipvia, shippingpoint, amount,
                  netamount, curr, datepaid, entity_credit_account, on_hold,
                  approved
             FROM ar WHERE in_entity_class = 2
            UNION
           select id, invoice, invnumber, ordnumber, ponumber, transdate, duedate,
                  description, notes, shipvia, shippingpoint, amount,
                  netamount, curr, datepaid, entity_credit_account, on_hold,
                  approved
             FROM ap WHERE in_entity_class = 1) gl
     JOIN entity_credit_account eca ON gl.entity_credit_account = eca.id
     JOIN entity e ON e.id = eca.entity_id
     JOIN acc_trans ac ON gl.id = ac.trans_id
     JOIN account act ON act.id = ac.chart_id
LEFT JOIN account_link l ON l.account_id = act.id
                          AND l.description IN ('AR', 'AP')
LEFT JOIN invoice inv ON gl.id = inv.trans_id
LEFT JOIN (SELECT compound_array(ARRAY[ARRAY[buc.label, bu.control_code]])
                  as business_units, entry_id
             FROM business_unit_class buc
             JOIN business_unit bu ON bu.class_id = buc.id
             JOIN business_unit_ac buac ON buac.bu_id = bu.id
         GROUP BY buac.entry_id) bua
                                 ON bua.entry_id = ac.entry_id
LEFT JOIN (SELECT compound_array(ARRAY[ARRAY[buc.label, bu.control_code]])
                  as business_units, entry_id
             FROM business_unit_class buc
             JOIN business_unit bu ON bu.class_id = buc.id
             JOIN business_unit_inv buinv ON buinv.bu_id = bu.id
         GROUP BY buinv.entry_id) bui
                                 ON bui.entry_id = inv.id
    WHERE (in_account_id IS NULL OR ac.chart_id = in_account_id)
          AND (in_name_part IS NULL
                OR to_tsvector(get_default_lang()::name, e.name)
                   @@ plainto_tsquery(get_default_lang()::name, in_name_part))
          AND (in_meta_number IS NULL
                OR eca.meta_number LIKE in_meta_number || '%')
          AND (in_invnumber IS NULL or gl.invnumber LIKE in_invnumber || '%')
          AND (in_ordnumber IS NULL or gl.ordnumber LIKE in_ordnumber || '%')
          AND (in_ponumber IS NULL or gl.ponumber LIKE in_ponumber || '%')
          AND (in_description IS NULL
                or to_tsvector(get_default_lang()::name, gl.description)
                  @@ plainto_tsquery(get_default_lang()::name, in_description))
          AND (in_notes IS NULL OR
                to_tsvector(get_default_lang()::name, gl.notes)
                 @@ plainto_tsquery(get_default_lang()::name, in_notes))
          AND (in_from_date IS NULL OR in_from_date <= gl.transdate)
          AND (in_to_date IS NULL OR in_to_date >= gl.transdate)
          AND (in_on_hold IS NULL OR in_on_hold = gl.on_hold)
          AND (in_as_of IS NULL OR in_as_of >= ac.transdate)
          AND gl.approved AND ac.approved
 GROUP BY gl.id, gl.invnumber, gl.ordnumber, gl.ponumber, gl.transdate,
          gl.duedate, e.name, eca.meta_number, gl.amount,
          gl.netamount, gl.curr, gl.datepaid, gl.duedate,
          gl.notes, gl.shippingpoint, gl.shipvia, e.id, gl.invoice
   HAVING in_source = ANY(array_agg(ac.source)) or in_source IS NULL;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION ar_ap__transaction_search_summary
(in_account_id int, in_name_part text, in_meta_number text, in_invnumber text,
 in_ordnumber text, in_ponumber text, in_source text, in_description text,
 in_notes text, in_shipvia text, in_from_date date, in_to_date date,
 in_on_hold bool, in_inc_open bool, in_inc_closed bool, in_as_of date,
 in_entity_class int)
RETURNS SETOF purchase_info AS
$$
       SELECT null::int, null::bool, null::text, null::text, null::text,
              null::date, entity_name, meta_number, entity_id, sum(amount),
              sum(amount_paid), sum(tax), currency, null::date, null::date,
              null::text, null::text, null::text, null::text[]
         FROM ar_ap__transaction_search
              (in_account_id, in_name_part, in_meta_number, in_invnumber,
              in_ordnumber, in_ponumber, in_source, in_description,
              in_notes, in_shipvia, in_from_date, in_to_date,
              in_on_hold, in_inc_open, in_inc_closed, in_as_of,
              in_entity_class)
     GROUP BY entity_name, meta_number, entity_id, currency;
$$ language sql;

--tshvr4 first attempt to mimic AA.pm,sub post_transaction in PLPGSQL function begin
--this is still trial and error
--see also sql/modules/Invoice.sql
--sql/modules/Journal.sql , example of SELECT .. into .. FROM expand(array_lines);
CREATE OR REPLACE FUNCTION AP_simple_post
(
 in_entity_credit_account int,in_ap_liablility_chartid int,in_invnumber text,in_transdate date,in_duedate date,in_curr char(3),in_description text,in_ordnumber text,in_notes text,in_intnotes text,in_ponumber text,in_memo text[],in_netamount numeric[],in_chartid numeric[],in_taxrate numeric[],in_taxchartid numeric[]
)
RETURNS INT AS
$$
DECLARE invnumber text;
DECLARE ap_id   int;
DECLARE entry_id   int;
DECLARE chartid int;
DECLARE tax_chartid int;
DECLARE invoice bool;
DECLARE separate_duties bool;
DECLARE approved bool;
DECLARE taxincluded bool;
DECLARE curr char(3);
DECLARE curr_default char(3);
DECLARE transdate date;
DECLARE duedate date;
DECLARE crdate date;
DECLARE memo text;
DECLARE netamount numeric;
DECLARE netamount_total numeric;
DECLARE taxrate numeric;
DECLARE taxamount numeric;
DECLARE taxamount_total numeric;
DECLARE amount_total numeric;
DECLARE person_id int;
DECLARE dp int;
DECLARE fx_transaction bool;
DECLARE cleared bool;
DECLARE taxform_id int;
DECLARE reportable bool;
DECLARE atf_count int;
DECLARE ect_count int;
BEGIN
 netamount_total=0.0;
 taxamount_total=0.0;
 invoice=false;
 approved=true;
 taxincluded=false;
 fx_transaction=false;
 cleared=false;

 select value::int       INTO dp FROM setting_get('decimal_places');
 select person__get_my_entity_id into person_id from person__get_my_entity_id();
 SELECT value::bool INTO separate_duties FROM defaults WHERE setting_key='separate_duties';
 IF separate_duties = true THEN
  --RAISE EXCEPTION 'separate_duties not yet treated';
  approved=false;
 END IF;
 select eca.taxform_id::int into taxform_id from entity_credit_account eca where eca.id=in_entity_credit_account;
 IF taxform_id <> 0 THEN
  --FOREIGN KEY (taxform_id) REFERENCES country_tax_form(id)
  RAISE EXCEPTION 'taxform not yet treated';
 END IF;

 transdate=coalesce(in_transdate,'today');
 duedate=coalesce(in_duedate,'today');
 crdate=now();

 --IF in_invnumber IS NULL OR (length(trim(in_invnumber))=0) THEN --NULL as only designator for "no value supplied"
 IF in_invnumber IS NULL THEN
  select setting_increment::text INTO invnumber FROM setting_increment('vinumber');
 ELSE
  invnumber=in_invnumber;
 END IF;

 select defaults_get_defaultcurrency into curr_default from defaults_get_defaultcurrency();
 IF in_curr IS NULL THEN
  curr=curr_default;
 ELSE
  curr=in_curr;
 END IF;
 IF curr <> curr_default THEN
  RAISE EXCEPTION 'curr <> curr_default not yet treated';
 END IF;

 FOR out_count IN array_lower(in_memo, 1) .. array_upper(in_memo, 1)
 LOOP
   netamount=in_netamount[out_count];
   netamount_total=netamount_total+netamount;
   taxrate=in_taxrate[out_count];
   IF taxrate IS NOT NULL THEN
    taxamount=netamount*taxrate;
   ELSE
    taxamount=0.0;
   END IF;
   taxamount_total=taxamount_total+taxamount;
 END LOOP;

 amount_total=netamount_total+taxamount_total;

 amount_total=round(amount_total,dp);
 netamount_total=round(netamount_total,dp);

 INSERT INTO ap (entity_credit_account,invnumber,transdate,invoice,approved,taxincluded,curr,duedate,crdate,netamount,amount,person_id,description,ordnumber,notes,intnotes,ponumber) VALUES(in_entity_credit_account,invnumber,transdate,invoice,approved,taxincluded,curr,duedate,crdate,netamount_total,amount_total,person_id,in_description,in_ordnumber,in_notes,in_intnotes,in_ponumber);

 SELECT currval('id') INTO ap_id;--NOT "id"!

 INSERT INTO acc_trans(trans_id,transdate,chart_id,amount,approved) values(ap_id,transdate,in_ap_liablility_chartid,amount_total,approved);

 FOR out_count IN array_lower(in_memo, 1) .. array_upper(in_memo, 1)
 LOOP
  memo=in_memo[out_count];
  chartid=in_chartid[out_count];
  tax_chartid=in_taxchartid[out_count];
  netamount=in_netamount[out_count];
  taxrate=in_taxrate[out_count];
  taxamount=0.0;
  IF taxrate IS NOT NULL THEN
   IF tax_chartid IS NOT NULL THEN
     select count(*) into ect_count from eca_tax ect where ect.eca_id=in_entity_credit_account and ect.chart_id=tax_chartid;
     IF ect_count = 0 THEN
      RAISE EXCEPTION 'tax_chartid NOT IN  eca_tax';
     END IF;
     taxamount=netamount*taxrate;
     taxamount=round(taxamount,dp);
     INSERT INTO acc_trans (trans_id,chart_id,amount,transdate,fx_transaction,memo) VALUES(ap_id,tax_chartid,taxamount*-1.0,transdate,fx_transaction,memo);
   ELSE --tax_chartid null
    RAISE EXCEPTION 'taxrate NOT NULL but tax_chartid NULL';
   END IF;--tax_chartid
  ELSE --taxrate null
   IF tax_chartid IS NOT NULL THEN
    RAISE EXCEPTION 'taxrate NULL but tax_chartid NOT NULL';
   END IF;
   --taxamount=0.0;
  END IF;--taxrate

  netamount=round(netamount,dp);
  INSERT INTO acc_trans (trans_id,chart_id,amount,transdate,memo,fx_transaction,cleared) VALUES(ap_id,chartid,netamount*-1.0,transdate,memo,fx_transaction,cleared);
  SELECT currval('acc_trans_entry_id_seq') INTO entry_id;

  IF taxform_id <> 0 THEN
   select count(*) into atf_count from ac_tax_form atf where atf.entry_id=entry_id;
   IF atf_count > 0 THEN
    update ac_tax_form atf set atf.reportable=reportable where atf.entry_id=entry_id;
   ELSE
    insert into ac_tax_form(entry_id,reportable) values(entry_id,reportable);
   END IF;
  END IF;--taxform_id

 END LOOP;

 PERFORM trans_id FROM acc_trans WHERE trans_id = ap_id GROUP BY trans_id HAVING sum(amount) <> 0;
 IF FOUND THEN
   RAISE EXCEPTION 'Out of balance';
 END IF;

 return ap_id;
END;
$$ LANGUAGE PLPGSQL;
--To Test:
--select * from AP_simple_post(4,66,null,null,null,'DL','descr','ordnr','notes','intnotes','ponr',ARRAY['a','b'],ARRAY[100.556,205.308],ARRAY[71,95],ARRAY[0.06,0.21],ARRAY[74,70]);
--select * from AP_simple_post(4,66,null,null,null,null,'descr','ordnr','notes','intnotes','ponr',ARRAY['a','b'],ARRAY[100.556,205.308],ARRAY[71,95],ARRAY[0.06,0.21],ARRAY[74,70]);
--select * from AP_simple_post(4,66,'',null,null,null,'descr','ordnr','notes','intnotes','ponr',ARRAY['a','b'],ARRAY[100.556,205.308],ARRAY[71,95],ARRAY[0.06,0.21],ARRAY[74,70]);
--select * from AP_simple_post(4,66,'test chartid not in ecatax',null,null,null,'descr','ordnr','notes','intnotes','ponr',ARRAY['a','b'],ARRAY[100.556,205.308],ARRAY[71,71],ARRAY[0.06,0.21],ARRAY[74,74]);
--select * from AP_simple_post(4,66,'test chartid in ecatax ',null,null,null,'descr','ordnr','notes','intnotes','ponr',ARRAY['a','b'],ARRAY[100.556,205.308],ARRAY[71,71],ARRAY[0.06,0.06],ARRAY[70,70]);
--select * from AP_simple_post(4,66,null,null,null,null,'descr','ordnr','notes','intnotes','ponr',ARRAY['a','b'],ARRAY[100.556,205.308],ARRAY[71,95],ARRAY[null,0.21],ARRAY[74,70]);
--select * from AP_simple_post(4,66,null,null,null,null,'descr','ordnr','notes','intnotes','ponr',ARRAY['a','b'],ARRAY[100.556,205.308],ARRAY[71,95],ARRAY[0.06,0.21],ARRAY[null,70]);
--tshvr4 first attempt to mimic AA.pm,sub post_transaction in PLPGSQL function end

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
