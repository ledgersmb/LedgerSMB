ALTER SCHEMA public RENAME TO orig;
CREATE SCHEMA public;

\i /usr/local/src/postgresql-8.2.6/contrib/tsearch2/tsearch2.sql
\i /usr/local/src/postgresql-8.2.6/contrib/pg_trgm/pg_trgm.sql
\i /usr/local/src/postgresql-8.2.6/contrib/tablefunc/tablefunc.sql
\i /home/ledgersmb/ledger-smb/sql/Pg-database.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Account.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Session.sql
\i /home/ledgersmb/ledger-smb/sql/modules/chart.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Business_type.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Location.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Company.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Customer.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Date.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Defaults.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Settings.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Employee.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Entity.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Payment.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Person.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Report.sql
\i /home/ledgersmb/ledger-smb/sql/modules/Voucher.sql

GRANT EXECUTE ON FUNCTION eca__list_notes(int) TO lsmb_paycom_eu__read_contact;
GRANT INSERT ON eca_note TO lsmb_paycom_eu__edit_contact;

ALTER TABLE orig.vendor ADD COLUMN entity_id int;
ALTER TABLE orig.vendor ADD COLUMN company_id int;
ALTER TABLE orig.vendor ADD COLUMN credit_id int;

INSERT INTO chart SELECT * FROM orig.chart;
-- The blank entities are tests and not used for anything anyway.

INSERT INTO business SELECT * FROM orig.business;

-- Importing vendors

CREATE TEMPORARY TABLE entity_temp (name text, control_code text);

INSERT INTO entity_temp (name, control_code)
SELECT name, vendornumber
FROM orig.vendor
GROUP BY name, vendornumber;  


INSERT INTO entity (name, control_code, entity_class)
SELECT name, control_code, 1
FROM entity_temp
WHERE control_code IS NOT NULL
	AND name IS NOT NULL AND name <> ''
GROUP BY name, control_code;

UPDATE orig.vendor SET entity_id = coalesce((SELECT id FROM entity WHERE (vendornumber like control_code), entity_id);

insert into entity (id, name, entity_class) values (-1, 'UNKNOWN', 1);

DELETE FROM entity_credit_account; -- necessary because the builtin inventory
                                   -- control accounts have the same meta_number
                                   -- CT

INSERT INTO entity_credit_account
(entity_id, meta_number, business_id, creditlimit, ar_ap_account_id, 
	cash_account_id, startdate, enddate, threshold, entity_class)
SELECT entity_id, vendornumber, business_id, creditlimit, arap_accno_id, 
	payment_accno_id, startdate, enddate, threshold, 1
FROM orig.vendor;

create UNIQUE index entity_credit_account_meta_number_idx_u on entity_credit_account (meta_number );

UPDATE orig.vendor SET credit_id = 
	(SELECT id FROM entity_credit_account e 
	WHERE e.meta_number = vendornumber AND vendor.entity_id = e.entity_id);


-- companies

INSERT INTO company (entity_id, legal_name, tax_id)
SELECT entity_id, name, max(taxnumber) FROM orig.vendor 
WHERE entity_id IS NOT NULL AND entity_id IN (select id from entity) GROUP BY entity_id, name;

UPDATE orig.vendor SET company_id = (select id from company c where entity_id = vendor.entity_id);

-- Moving to a UNION query
insert into eca_to_contact (credit_id, contact_class_id, contact,description) 
select v.credit_id, 1, v.phone, 'Primary phone: '||max(v.contact) as description
from orig.vendor v 
where v.company_id is not null and v.phone is not null 
       and v.phone ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.phone
UNION
select v.credit_id, 12, v.email, 
       'email address: '||max(v.contact) as description 
from orig.vendor v 
where v.company_id is not null and v.email is not null 
       and v.email ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.email
UNION
select v.credit_id, 12, v.cc, 'Carbon Copy email address' as description 
from orig.vendor v 
where v.company_id is not null and v.cc is not null 
      and v.cc ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.cc
UNION 
select v.credit_id, 12, v.bcc, 'Blind Carbon Copy email address' as description 
from orig.vendor v 
where v.company_id is not null and v.bcc is not null 
       and v.bcc ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.bcc
UNION
    select v.credit_id, 9, v.fax, 'Fax number' as description 
from orig.vendor v 
where v.company_id is not null and v.fax is not null 
      and v.fax ~ '[[:alnum:]_]'::text 
group by v.credit_id, v.fax;
-- addresses

INSERT INTO public.country (id, name, short_name) VALUES (-1, 'Invalid Country', 'XX');

INSERT INTO eca_to_location(credit_id, location_class, location_id)
SELECT eca.id, 1,
    min(location_save(NULL,

    case 
        when oa.address1 = '' then 'Null' 
        when oa.address1 is null then 'Null'
        else oa.address1 
    end,
    oa.address2, 
    NULL,
    case 
        when oa.city !~ '[[:alnum:]_]' then 'Invalid' 
        when oa.city is null then 'Null' 
        else oa.city 
    end,
    case 
        when oa.state !~ '[[:alnum:]_]' then 'Invalid' 
        when oa.state is null then 'Null' 
        else oa.state 
    end,
    case 
        when oa.zipcode !~ '[[:alnum:]_]' then 'Invalid' 
        when oa.zipcode is null then 'Null' 
        else oa.zipcode 
    end,
    coalesce(c.id, -1)
    ))
FROM country c
RIGHT OUTER JOIN
    orig.address oa
ON
    lower(trim(both ' ' from c.name)) = lower( trim(both ' ' from oa.country))
OR

    lower(trim(both ' ' from c.short_name)) = lower( trim(both ' ' from oa.country))
JOIN orig.vendor ov ON ov.id = oa.trans_id
JOIN entity_credit_account eca ON (ov.credit_id = eca.id)
GROUP BY eca.id;


 -- notes 

INSERT INTO eca_note(note_class, ref_key, note, vector)
SELECT 3, credit_id, notes, '' FROM orig.vendor 
WHERE notes IS NOT NULL AND credit_id IS NOT NULL;

alter table orig.employee add entity_id int;

update orig.employee set entity_id = 
	(select entity_id from person where first_name = employee.name 
	UNION 
	select entity_id from users where username = lower(employee.login));

-- batches, transactions, and vouchers
insert into batch (id, control_code, description, approved_on, approved_by, 
	created_on, created_by, batch_class_id, default_date)
select b.id, b.batchnumber, b.description, b.apprdate, me.entity_id, transdate, 
	ee.entity_id, bc.id, b.transdate
FROM orig.br b
LEFT JOIN orig.employee me ON (b.managerid = me.id)
LEFT JOIN orig.employee ee ON (ee.id = b.employee_id)
JOIN public.batch_class bc ON (b.batch = bc.class);



insert into ap 
(entity_credit_account, person_id,
	id, invnumber, transdate, taxincluded, amount, netamount, paid, 
	datepaid, duedate, invoice, ordnumber, curr, notes, quonumber, intnotes,
	department_id, shipvia, language_code, ponumber, shippingpoint, 
	on_hold, approved, reverse, terms, description)
SELECT 
	vendor.credit_id,
	(select entity_id from orig.employee 
		WHERE id = ap.employee_id),
	ap.id, invnumber, transdate, ap.taxincluded, amount, netamount, paid, 
	datepaid, duedate, invoice, ordnumber, ap.curr, ap.notes, quonumber, 
	intnotes,
	department_id, shipvia, ap.language_code, ponumber, shippingpoint, 
	onhold, approved, case when amount < 0 then true else false end,
	ap.terms, description
FROM orig.ap JOIN orig.vendor ON (ap.vendor_id = vendor.id);

INSERT INTO gl
(id, reference, description, transdate, person_id, notes, approved, department_id)
SELECT id, reference, description, transdate, 
	(select max(id) from person where entity_id = (select entity_id from orig.employee
          WHERE id = gl.employee_id)),
	notes, approved, department_id FROM orig.gl;

insert into voucher(trans_id, batch_id, id, batch_class)
select min(v.trans_id), v.br_id, v.id, bc.id
from orig.vr v
JOIN orig.br b ON (v.br_id = b.id)
JOIN public.batch_class bc ON (b.batch = bc.class)
JOIN public.transactions t ON (t.id = v.trans_id)
group by v.br_id, bc.id, v.id;

-- acc_trans entries/financial line items

INSERT INTO acc_trans
(trans_id, chart_id, amount, transdate, source, cleared, fx_transaction, 
	project_id, memo, approved, cleared_on, reconciled_on, 
	voucher_id)
SELECT trans_id, chart_id, amount, transdate, source,
	CASE WHEN cleared IS NOT NULL THEN TRUE ELSE FALSE END, fx_transaction,
	project_id, memo, approved, cleared, reconciled, vr_id
	FROM orig.acc_trans;

-- sequences

select setval('voucher_id_seq', (select max(id) from orig.vr));

SELECT setval('batch_id_seq', (select max(id) from orig.br));

SELECT setval('id', max(id)) FROM transactions;

INSERT INTO defaults (setting_key, value)
SELECT fldname, fldvalue FROM orig.defaults
WHERE fldname = 'currencies';


