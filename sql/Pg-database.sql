begin;
CREATE SEQUENCE id;
-- Central DB structure
-- This is the central database stuff which is used across all datasets
-- in the ledger-smb.conf it is called 'ledgersmb' by default, but obviously
-- can be named anything.


-- BEGIN new entity management
CREATE TABLE entity_class (
  id serial primary key,
  class text check (class ~ '[[:alnum:]_]') NOT NULL,
  active boolean not null default TRUE);
  
COMMENT ON TABLE entity_class IS $$ Defines the class type such as vendor, customer, contact, employee $$;
COMMENT ON COLUMN entity_class.id IS $$ The first 7 values are reserved and permanent $$;  

CREATE index entity_class_idx ON entity_class(lower(class));

CREATE TABLE entity (
  id serial UNIQUE,
  name text check (name ~ '[[:alnum:]_]'),
  entity_class integer references entity_class(id) not null ,
  created date not null default current_date,
  PRIMARY KEY(name,entity_class));
  
COMMENT ON TABLE entity IS $$ The primary entity table to map to all contacts $$;
COMMENT ON COLUMN entity.name IS $$ This is the common name of an entity. If it was a person it may be Joshua Drake, a company Acme Corp. You may also choose to use a domain such as commandprompt.com $$;


ALTER TABLE entity ADD FOREIGN KEY (entity_class) REFERENCES entity_class(id);

INSERT INTO entity_class (id,class) VALUES (1,'Vendor');
INSERT INTO entity_class (id,class) VALUES (2,'Customer');
INSERT INTO entity_class (id,class) VALUES (3,'Employee');
INSERT INTO entity_class (id,class) VALUES (4,'Contact');
INSERT INTO entity_class (id,class) VALUES (5,'Lead');
INSERT INTO entity_class (id,class) VALUES (6,'Referral');

SELECT setval('entity_class_id_seq',7);

CREATE TABLE entity_class_to_entity (
  entity_class_id integer not null references entity_class(id) ON DELETE CASCADE,
  entity_id integer not null references entity(id) ON DELETE CASCADE,
  PRIMARY KEY(entity_class_id,entity_id)
  );

COMMENT ON TABLE entity_class_to_entity IS $$ Relation builder for classes to entity $$;

-- USERS stuff --
CREATE TABLE users (
    id serial UNIQUE, 
    username varchar(30) primary key,
    entity_id int not null references entity(id) on delete cascade
);

COMMENT ON TABLE users IS $$username is the actual primary key here because we do not want duplicate users$$;

-- Session tracking table


CREATE TABLE session(
session_id serial PRIMARY KEY,
token VARCHAR(32) CHECK(length(token) = 32),
last_used TIMESTAMP default now(),
ttl int default 3600 not null,
users_id INTEGER NOT NULL references users(id),
transaction_id INTEGER NOT NULL
);

CREATE TABLE open_forms (
id SERIAL PRIMARY KEY,
session_id int REFERENCES session(session_id) ON DELETE CASCADE
);

--
CREATE TABLE transactions (
  id int PRIMARY KEY,
  table_name text,
  locked_by int references "session" (session_id) ON DELETE SET NULL,
  approved_by int references entity (id),
  approved_at timestamp
);

COMMENT on TABLE transactions IS 
$$ This table tracks basic transactions across AR, AP, and GL related tables.  
It provies a referential integrity enforcement mechanism for the financial data
and also some common features such as discretionary (and pessimistic) locking 
for long batch workflows. $$;

CREATE OR REPLACE FUNCTION lock_record (int, int) returns bool as 
$$
declare
   locked int;
begin
   SELECT locked_by into locked from transactions where id = $1;
   IF NOT FOUND THEN
	RETURN FALSE;
   ELSEIF locked is not null AND locked <> $2 THEN
        RETURN FALSE;
   END IF;
   UPDATE transactions set locked_by = $2 where id = $1;
   RETURN TRUE;
end;
$$ language plpgsql;

COMMENT ON column transactions.locked_by IS
$$ This should only be used in pessimistic locking measures as required by large
batch work flows. $$;

-- LOCATION AND COUNTRY
CREATE TABLE country (
  id serial PRIMARY KEY,
  name text check (name ~ '[[:alnum:]_]') NOT NULL,
  short_name text check (short_name ~ '[[:alnum:]_]') NOT NULL,
  itu text);
  
COMMENT ON COLUMN country.itu IS $$ The ITU Telecommunication Standardization Sector code for calling internationally. For example, the US is 1, Great Britain is 44 $$;

CREATE UNIQUE INDEX country_name_idx on country(lower(name));

CREATE TABLE location_class (
  id serial UNIQUE,
  class text check (class ~ '[[:alnum:]_]') not null,
  authoritative boolean not null,
  PRIMARY KEY (class,authoritative));
  
CREATE UNIQUE INDEX lower_class_unique ON location_class(lower(class));

INSERT INTO location_class(id,class,authoritative) VALUES ('1','Billing',TRUE);
INSERT INTO location_class(id,class,authoritative) VALUES ('2','Sales',TRUE);
INSERT INTO location_class(id,class,authoritative) VALUES ('3','Shipping',TRUE);

SELECT SETVAL('location_class_id_seq',4);
  
CREATE TABLE location (
  id serial PRIMARY KEY,
  line_one text check (line_one ~ '[[:alnum:]_]') NOT NULL,
  line_two text,
  line_three text,
  city text check (city ~ '[[:alnum:]_]') NOT NULL,
  state text check(state ~ '[[:alnum:]_]'),
  country_id integer not null REFERENCES country(id),
  mail_code text not null check (mail_code ~ '[[:alnum:]_]'),
  created date not null,
  inactive_date timestamp default null,
  active boolean not null default TRUE
);
  
CREATE TABLE company (
  id serial UNIQUE,
  entity_id integer not null references entity(id),
  legal_name text check (legal_name ~ '[[:alnum:]_]'),
  tax_id text,
  created date default current_date not null,
  PRIMARY KEY (entity_id,legal_name));
  
COMMENT ON COLUMN company.tax_id IS $$ In the US this would be a EIN. $$;  

CREATE TABLE company_to_location (
  location_id integer references location(id) not null,
  location_class integer not null references location_class(id),
  company_id integer not null references company(id) ON DELETE CASCADE,
  PRIMARY KEY(location_id,company_id));

CREATE TABLE salutation (
 id serial unique,
 salutation text primary key);

INSERT INTO salutation (id,salutation) VALUES ('1','Dr.');
INSERT INTO salutation (id,salutation) VALUES ('2','Miss.');
INSERT INTO salutation (id,salutation) VALUES ('3','Mr.');
INSERT INTO salutation (id,salutation) VALUES ('4','Mrs.');
INSERT INTO salutation (id,salutation) VALUES ('5','Ms.');
INSERT INTO salutation (id,salutation) VALUES ('6','Sir.');

SELECT SETVAL('salutation_id_seq',7);

CREATE TABLE person (
    id serial PRIMARY KEY,
    entity_id integer references entity(id) not null,
    salutation_id integer references salutation(id),
    first_name text check (first_name ~ '[[:alnum:]_]') NOT NULL,
    middle_name text,
    last_name text check (last_name ~ '[[:alnum:]_]') NOT NULL,
    created date not null default current_date
 );
 
COMMENT ON TABLE person IS $$ Every person, must have an entity to derive a common or display name. The correct way to get class information on a person would be person.entity_id->entity_class_to_entity.entity_id. $$;

create table entity_employee (
    
    person_id integer references person(id) not null,
    entity_id integer references entity(id) not null unique,
    startdate date not null default current_date,
    enddate date,
    role varchar(20),
    ssn text,
    sales bool default 'f',
    manager_id integer references entity(id),
    employeenumber varchar(32),
    dob date,
    PRIMARY KEY (person_id, entity_id)
);

CREATE TABLE person_to_location (
  location_id integer not null references location(id),
  location_class integer not null references location_class(id),
  person_id integer not null references person(id) ON DELETE CASCADE,
  PRIMARY KEY (location_id,person_id));

CREATE TABLE person_to_company (
  location_id integer references location(id) not null,
  person_id integer not null references person(id) ON DELETE CASCADE,
  company_id integer not null references company(id) ON DELETE CASCADE,
  PRIMARY KEY (location_id,person_id)); 

CREATE TABLE entity_other_name (
 entity_id integer not null references entity(id) ON DELETE CASCADE,
 other_name text check (other_name ~ '[[:alnum:]_]'),
 PRIMARY KEY (other_name, entity_id));
 
COMMENT ON TABLE entity_other_name IS $$ Similar to company_other_name, a person may be jd, Joshua Drake, linuxpoet... all are the same person. $$;

CREATE TABLE person_to_entity (
 person_id integer not null references person(id) ON DELETE CASCADE,
 entity_id integer not null check (entity_id != person_id) references entity(id) ON DELETE CASCADE,
 related_how text,
 created date not null default current_date,
 PRIMARY KEY (person_id,entity_id));
 
CREATE TABLE company_to_entity (
 company_id integer not null references company(id) ON DELETE CASCADE,
 entity_id integer check (company_id != entity_id) not null references entity(id) ON DELETE CASCADE,
 related_how text,
 created date not null default current_date,
 PRIMARY KEY (company_id,entity_id));
 
CREATE TABLE contact_class (
  id serial UNIQUE,
  class text check (class ~ '[[:alnum:]_]') NOT NULL, 
  PRIMARY KEY (class));
  
CREATE UNIQUE INDEX contact_class_class_idx ON contact_class(lower(class));

INSERT INTO contact_class (id,class) values (1,'Primary Phone');
INSERT INTO contact_class (id,class) values (2,'Secondary Phone');
INSERT INTO contact_class (id,class) values (3,'Cell Phone');
INSERT INTO contact_class (id,class) values (4,'AIM');
INSERT INTO contact_class (id,class) values (5,'Yahoo');
INSERT INTO contact_class (id,class) values (6,'Gtalk');
INSERT INTO contact_class (id,class) values (7,'MSN');
INSERT INTO contact_class (id,class) values (8,'IRC');
INSERT INTO contact_class (id,class) values (9,'Fax');
INSERT INTO contact_class (id,class) values (10,'Generic Jabber');
INSERT INTO contact_class (id,class) values (11,'Home Phone');
INSERT INTO contact_class (id,class) values (12,'Email');

SELECT SETVAL('contact_class_id_seq',12);

CREATE TABLE person_to_contact (
  person_id integer not null references person(id) ON DELETE CASCADE,
  contact_class_id integer references contact_class(id) not null,
  contact text check(contact ~ '[[:alnum:]_]') not null,
  PRIMARY KEY (person_id,contact_class_id,contact));
  
COMMENT ON TABLE person_to_contact IS $$ To keep track of the relationship between multiple contact methods and a single individual $$;
  
CREATE TABLE company_to_contact (
  company_id integer not null references company(id) ON DELETE CASCADE,
  contact_class_id integer references contact_class(id) not null,
  contact text check(contact ~ '[[:alnum:]_]') not null,
  description text,
  PRIMARY KEY (company_id, contact_class_id,  contact));  

COMMENT ON TABLE company_to_contact IS $$ To keep track of the relationship between multiple contact methods and a single company $$;
  
-- Begin rocking notes interface
CREATE TABLE note_class(id serial primary key, class text not null check (class ~ '[[:alnum:]_]'));
INSERT INTO note_class(id,class) VALUES (1,'Entity');
INSERT INTO note_class(id,class) VALUES (2,'Invoice');
CREATE UNIQUE INDEX note_class_idx ON note_class(lower(class));

CREATE TABLE note (id serial primary key, note_class integer not null references note_class(id), 
                   note text not null, vector tsvector not null, 
                   created timestamp not null default now(),
                   ref_key integer not null);

CREATE TABLE entity_note(entity_id int references entity(id)) INHERITS (note);
ALTER TABLE entity_note ADD CHECK (note_class = 1);
ALTER TABLE entity_note ADD FOREIGN KEY (ref_key) REFERENCES entity(id) ON DELETE CASCADE;
CREATE INDEX entity_note_id_idx ON entity_note(id);
CREATE UNIQUE INDEX entity_note_class_idx ON note_class(lower(class));
CREATE INDEX entity_note_vectors_idx ON entity_note USING gist(vector);
CREATE TABLE invoice_note() INHERITS (note);
CREATE INDEX invoice_note_id_idx ON invoice_note(id);
CREATE UNIQUE INDEX invoice_note_class_idx ON note_class(lower(class));
CREATE INDEX invoice_note_vectors_idx ON invoice_note USING gist(vector);

-- END entity   

--
CREATE TABLE makemodel (
  parts_id int PRIMARY KEY,
  make text,
  model text
);
--
CREATE TABLE gl (
  id int DEFAULT nextval ( 'id' ) PRIMARY KEY REFERENCES transactions(id),
  reference text,
  description text,
  transdate date DEFAULT current_date,
  person_id integer references person(id),
  notes text,
  approved bool default true,
  department_id int default 0
);
--
CREATE TABLE chart (
  id serial PRIMARY KEY,
  accno text NOT NULL,
  description text,
  charttype char(1) DEFAULT 'A',
  category char(1),
  link text,
  gifi_accno text,
  contra bool DEFAULT 'f'
);
--
CREATE TABLE gifi (
  accno text PRIMARY KEY,
  description text
);
--
CREATE TABLE defaults (
  setting_key text primary key,
  value text
);

\COPY defaults FROM stdin WITH DELIMITER |
sinumber|1
sonumber|1
yearend|1
businessnumber|1
version|1.2.0
closedto|\N
revtrans|1
ponumber|1
sqnumber|1
rfqnumber|1
audittrail|0
vinumber|1
employeenumber|1
partnumber|1
customernumber|1
vendornumber|1
glnumber|1
projectnumber|1
queue_payments|0
poll_frequency|1
rcptnumber|1
paynumber|1
separate_duties|1
\.

COMMENT ON TABLE defaults IS $$
Note that poll_frequency is in seconds.  poll_frequency and queue_payments 
are not exposed via the admin interface as they are advanced features best
handled via DBAs.  Also, separate_duties is not yet included in the admin 
interface.$$;
-- */
-- batch stuff

CREATE TABLE batch_class (
  id serial unique,
  class varchar primary key
);

insert into batch_class (id,class) values (1,'ap');
insert into batch_class (id,class) values (2,'ar');
insert into batch_class (id,class) values (3,'payment');
insert into batch_class (id,class) values (4,'payment_reversal');
insert into batch_class (id,class) values (5,'gl');
insert into batch_class (id,class) values (6,'receipt');

SELECT SETVAL('batch_class_id_seq',6);

CREATE TABLE batch (
  id serial primary key,
  batch_class_id integer references batch_class(id) not null,
  control_code text,
  description text,
  approved_on date default null,
  approved_by int references entity_employee(entity_id),
  created_by int references entity_employee(entity_id),
  locked_by int references session(session_id),
  created_on date default now()
);

COMMENT ON COLUMN batch.batch_class_id IS
$$ Note that this field is largely used for sorting the vouchers.  A given batch is NOT restricted to this type.$$;

CREATE TABLE voucher (
  trans_id int REFERENCES transactions(id) NOT NULL,
  batch_id int references batch(id) not null,
  id serial NOT NULL unique,
  batch_class int references batch_class(id) not null,
  PRIMARY KEY (batch_class, batch_id, trans_id)
);

COMMENT ON COLUMN voucher.batch_class IS $$ This is the authoritative class of the 
voucher. $$;

COMMENT ON COLUMN voucher.id IS $$ This is simply a surrogate key for easy reference.$$;

CREATE TABLE acc_trans (
  trans_id int NOT NULL REFERENCES transactions(id),
  chart_id int NOT NULL REFERENCES chart (id),
  amount NUMERIC,
  transdate date DEFAULT current_date,
  source text,
  cleared bool DEFAULT 'f',
  fx_transaction bool DEFAULT 'f',
  project_id int,
  memo text,
  invoice_id int,
  approved bool default true,
  cleared_on date,
  reconciled_on date,
  voucher_id int references voucher(id),
  entry_id SERIAL PRIMARY KEY
);

CREATE INDEX acc_trans_voucher_id_idx ON acc_trans(voucher_id);
--
CREATE TABLE invoice (
  id serial PRIMARY KEY,
  trans_id int,
  parts_id int,
  description text,
  qty integer,
  allocated integer,
  sellprice NUMERIC,
  fxsellprice NUMERIC,
  discount numeric,
  assemblyitem bool DEFAULT 'f',
  unit varchar(5),
  project_id int,
  deliverydate date,
  serialnumber text,
  notes text
);

-- Added for Entity but can't be added due to order
ALTER TABLE invoice_note ADD FOREIGN KEY (ref_key) REFERENCES invoice(id);

--

--

-- pricegroup added here due to references
CREATE TABLE pricegroup (
  id serial PRIMARY KEY,
  pricegroup text
);

CREATE TABLE entity_credit_account (
    id serial not null unique,
    entity_id int not null references entity(id) ON DELETE CASCADE,
    entity_class int not null references entity_class(id) check ( entity_class in (1,2) ),
    discount numeric, 
    discount_terms int default 0,
    discount_account_id int references chart(id),
    taxincluded bool default 'f',
    creditlimit NUMERIC default 0,
    terms int2 default 0,
    meta_number varchar(32),
    cc text,
    bcc text,
    business_id int,
    language_code varchar(6),
    pricegroup_id int references pricegroup(id),
    curr char(3),
    startdate date DEFAULT CURRENT_DATE,
    enddate date,
    threshold numeric default 0,
    employee_id int references entity_employee(entity_id),
    primary_contact int references person(id),
    ar_ap_account_id int references chart(id),
    cash_account_id int references chart(id),
    PRIMARY KEY(entity_id, meta_number, entity_class)
);

CREATE UNIQUE INDEX entity_credit_ar_accno_idx_u 
ON entity_credit_account(meta_number)
WHERE entity_class = 2;

COMMENT ON INDEX entity_credit_ar_accno_idx_u IS
$$This index is used to ensure that AR accounts are not reused.$$;

-- THe following credit accounts are used for inventory adjustments.
INSERT INTO entity (name, entity_class) values ('Inventory Entity', 1);

INSERT INTO company (legal_name, entity_id) 
values ('Inventory Entity', currval('entity_id_seq'));

INSERT INTO entity_credit_account (entity_id, meta_number, entity_class)
VALUES 
(currval('entity_id_seq'), '00000', 1);
INSERT INTO entity_credit_account (entity_id, meta_number, entity_class)
VALUES 
(currval('entity_id_seq'), '00000', 2);


-- notes are from entity_note
-- ssn, iban and bic are from entity_credit_account
-- 
-- The view below is broken.  Disabling for now.
CREATE VIEW employee AS
 SELECT s.salutation, p.first_name, p.last_name, ee.person_id, ee.entity_id, ee.startdate, ee.enddate, ee."role", ee.ssn, ee.sales, ee.manager_id, ee.employeenumber, ee.dob
   FROM person p
   JOIN entity_employee ee USING (entity_id)
   LEFT JOIN salutation s ON p.salutation_id = s.id;

/*
create view employee as
    SELECT 
        ente.entity_id,
        3,
        u.username,
        ente.startdate,
        ente.enddate,
        en.note,
        ente.ssn,
        eca.iban,
        eca.bic,
        ente.manager_id,
        ente.employeenumber,
        ente.dob
    FROM
        entity_employee ente
    JOIN 
        entity_credit_account eca on (eca.entity_id = ente.entity_id)
    JOIN
        entity_note en on (en.entity_id = ente.entity_id)
    JOIN
        users u on (u.entity_id = ente.entity_id);
*/


CREATE TABLE entity_bank_account (
    id serial not null,
    entity_id int not null references entity(id) ON DELETE CASCADE,
    bic varchar,
    iban varchar,
    UNIQUE (id),
    PRIMARY KEY (entity_id, bic, iban)
);

CREATE VIEW customer AS 
    SELECT 
        c.id,
        emd.entity_id, 
        emd.entity_class, 
        emd.discount,
        emd.taxincluded,
        emd.creditlimit,
        emd.terms,
        emd.meta_number as customernumber,
        emd.cc,
        emd.bcc,
        emd.business_id,
        emd.language_code,
        emd.pricegroup_id,
        emd.curr,
        emd.startdate,
        emd.enddate,
        eba.bic, 
        eba.iban, 
        ein.note as invoice_notes 
    FROM entity_credit_account emd 
    join entity_bank_account eba on emd.entity_id = eba.entity_id
    Left join entity_note ein on ein.ref_key = emd.entity_id
    join company c on c.entity_id = emd.entity_id
    where emd.entity_class = 2;
    
CREATE VIEW vendor AS 
    SELECT 
        c.id, 
        emd.entity_id, 
        emd.entity_class, 
        emd.discount,
        emd.taxincluded,
        emd.creditlimit,
        emd.terms,
        emd.meta_number as vendornumber,
        emd.cc,
        emd.bcc,
        emd.business_id,
        emd.language_code,
        emd.pricegroup_id,
        emd.curr,
        emd.startdate,
        emd.enddate,
        eba.bic, 
        eba.iban, 
        ein.note as 
        invoice_notes 
    FROM entity_credit_account emd 
    LEFT join entity_bank_account eba on emd.entity_id = eba.entity_id
    left join entity_note ein on ein.ref_key = emd.entity_id
    join company c on c.entity_id = emd.entity_id
    where emd.entity_class = 1;

COMMENT ON TABLE entity_credit_account IS $$ This is a metadata table for ALL entities in LSMB; it deprecates the use of customer and vendor specific tables (which were nearly identical and largely redundant), and replaces it with a single point of metadata. $$;

COMMENT ON COLUMN entity_credit_account.entity_id IS $$ This is the relationship between entities and their metadata. $$;
COMMENT ON COLUMN entity_credit_account.entity_class IS $$ A reference to entity_class, requiring that entity_credit_account only apply to vendors and customers, using the entity_class table as the Point Of Truth. $$;

ALTER TABLE company ADD COLUMN sic_code varchar;

--
--





-- COMMENT ON TABLE employee IS $$ Is a metadata table specific to employee $$;

CREATE TABLE parts (
  id serial PRIMARY KEY,
  partnumber text,
  description text,
  unit varchar(5),
  listprice NUMERIC,
  sellprice NUMERIC,
  lastcost NUMERIC,
  priceupdate date DEFAULT current_date,
  weight numeric,
  onhand numeric DEFAULT 0,
  notes text,
  makemodel bool DEFAULT 'f',
  assembly bool DEFAULT 'f',
  alternate bool DEFAULT 'f',
  rop numeric, -- SC: ReOrder Point
  inventory_accno_id int,
  income_accno_id int,
  expense_accno_id int,
  bin text,
  obsolete bool DEFAULT 'f',
  bom bool DEFAULT 'f',
  image text,
  drawing text,
  microfiche text,
  partsgroup_id int,
  project_id int,
  avgcost NUMERIC
);

CREATE UNIQUE INDEX parts_partnumber_index_u ON parts (partnumber) 
WHERE obsolete is false;
--
CREATE TABLE assembly (
  id int,
  parts_id int,
  qty numeric,
  bom bool,
  adj bool,
  PRIMARY KEY (id, parts_id)
);
--
CREATE TABLE ar (
  id int DEFAULT nextval ( 'id' ) PRIMARY KEY REFERENCES transactions(id),
  invnumber text,
  transdate date DEFAULT current_date,
  entity_id int REFERENCES entity(id),
  taxincluded bool,
  amount NUMERIC,
  netamount NUMERIC,
  paid NUMERIC,
  datepaid date,
  duedate date,
  invoice bool DEFAULT 'f',
  shippingpoint text,
  terms int2 DEFAULT 0,
  notes text,
  curr char(3),
  ordnumber text,
  person_id integer references entity_employee(entity_id),
  till varchar(20),
  quonumber text,
  intnotes text,
  department_id int default 0,
  shipvia text,
  language_code varchar(6),
  ponumber text,
  on_hold bool default false,
  reverse bool default false,
  approved bool default true,
  entity_credit_account int references entity_credit_account(id) not null,
  force_closed bool,
  description text
);

COMMENT ON COLUMN ar.entity_id IS $$ Used to be customer_id, but customer is now metadata. You need to push to entity $$;

--
CREATE TABLE ap (
  id int DEFAULT nextval ( 'id' ) PRIMARY KEY REFERENCES transactions(id),
  invnumber text,
  transdate date DEFAULT current_date,
  entity_id int REFERENCES entity(id),
  taxincluded bool DEFAULT 'f',
  amount NUMERIC,
  netamount NUMERIC,
  paid NUMERIC,
  datepaid date,
  duedate date,
  invoice bool DEFAULT 'f',
  ordnumber text,
  curr char(3),
  notes text,
  person_id integer references entity_employee(entity_id),
  till varchar(20),
  quonumber text,
  intnotes text,
  department_id int DEFAULT 0,
  shipvia text,
  language_code varchar(6),
  ponumber text,
  shippingpoint text,
  on_hold bool default false,
  approved bool default true,
  reverse bool default false,
  terms int2 DEFAULT 0,
  description text,
  force_closed bool,
  entity_credit_account int references entity_credit_account(id)
);

COMMENT ON COLUMN ap.entity_id IS $$ Used to be customer_id, but customer is now metadata. You need to push to entity $$;
--
CREATE TABLE taxmodule (
  taxmodule_id serial PRIMARY KEY,
  taxmodulename text NOT NULL
);
--
CREATE TABLE taxcategory (
  taxcategory_id serial PRIMARY KEY,
  taxcategoryname text NOT NULL,
  taxmodule_id int NOT NULL,
  FOREIGN KEY (taxmodule_id) REFERENCES taxmodule (taxmodule_id)
);
--
CREATE TABLE partstax (
  parts_id int,
  chart_id int,
  taxcategory_id int,
  PRIMARY KEY (parts_id, chart_id),
  FOREIGN KEY (parts_id) REFERENCES parts (id) on delete cascade,
  FOREIGN KEY (chart_id) REFERENCES chart (id),
  FOREIGN KEY (taxcategory_id) REFERENCES taxcategory (taxcategory_id)
);
--
CREATE TABLE tax (
  chart_id int,
  rate numeric,
  taxnumber text,
  validto timestamp default 'infinity',
  pass integer DEFAULT 0 NOT NULL,
  taxmodule_id int DEFAULT 1 NOT NULL,
  FOREIGN KEY (chart_id) REFERENCES chart (id),
  FOREIGN KEY (taxmodule_id) REFERENCES taxmodule (taxmodule_id),
  PRIMARY KEY (chart_id, validto)
);
--
CREATE TABLE customertax (
  customer_id int references entity_credit_account(id) on delete cascade,
  chart_id int,
  PRIMARY KEY (customer_id, chart_id)
);
--
CREATE TABLE vendortax (
  vendor_id int references entity_credit_account(id) on delete cascade,
  chart_id int,
  PRIMARY KEY (vendor_id, chart_id)
);
--

CREATE TABLE oe_class (
  id smallint unique check(id IN (1,2,3,4)),
  oe_class text primary key);
  
INSERT INTO oe_class(id,oe_class) values (1,'Sales Order');
INSERT INTO oe_class(id,oe_class) values (2,'Purchase Order');
INSERT INTO oe_class(id,oe_class) values (3,'Quotation');
INSERT INTO oe_class(id,oe_class) values (4,'RFQ');

COMMENT ON TABLE oe_class IS $$ This could probably be done better. But I need to remove the customer_id/vendor_id relationship and instead rely on a classification $$;


CREATE TABLE oe (
  id serial PRIMARY KEY,
  ordnumber text,
  transdate date default current_date,
  entity_id integer references entity(id),
  amount NUMERIC,
  netamount NUMERIC,
  reqdate date,
  taxincluded bool,
  shippingpoint text,
  notes text,
  curr char(3),
  person_id integer references person(id),
  closed bool default 'f',
  quotation bool default 'f',
  quonumber text,
  intnotes text,
  department_id int default 0,
  shipvia text,
  language_code varchar(6),
  ponumber text,
  terms int2 DEFAULT 0,
  oe_class_id int references oe_class(id) NOT NULL
);



--
CREATE TABLE orderitems (
  id serial PRIMARY KEY,
  trans_id int,
  parts_id int,
  description text,
  qty numeric,
  sellprice NUMERIC,
  discount numeric,
  unit varchar(5),
  project_id int,
  reqdate date,
  ship numeric,
  serialnumber text,
  notes text
);
--
CREATE TABLE exchangerate (
  curr char(3),
  transdate date,
  buy numeric,
  sell numeric,
  PRIMARY KEY (curr, transdate)
);
--

--
create table shipto (
  trans_id int,
  shiptoname varchar(64),
  shiptoaddress1 varchar(32),
  shiptoaddress2 varchar(32),
  shiptocity varchar(32),
  shiptostate varchar(32),
  shiptozipcode varchar(10),
  shiptocountry varchar(32),
  shiptocontact varchar(64),
  shiptophone varchar(20),
  shiptofax varchar(20),
  shiptoemail text,
  entry_id SERIAL PRIMARY KEY
);

-- SHIPTO really needs to be pushed into entities too

--

--
CREATE TABLE project (
  id serial PRIMARY KEY,
  projectnumber text,
  description text,
  startdate date,
  enddate date,
  parts_id int,
  production numeric default 0,
  completed numeric default 0,
  customer_id int
);
--
CREATE TABLE partsgroup (
  id serial PRIMARY KEY,
  partsgroup text
);
--
CREATE TABLE status (
  trans_id int,
  formname text,
  printed bool default 'f',
  emailed bool default 'f',
  spoolfile text,
  PRIMARY KEY (trans_id, formname)
);
--
CREATE TABLE department (
  id serial PRIMARY KEY,
  description text,
  role char(1) default 'P'
);
--
-- department transaction table
CREATE TABLE dpt_trans (
  trans_id int PRIMARY KEY,
  department_id int
);
--
-- business table
CREATE TABLE business (
  id serial PRIMARY KEY,
  description text,
  discount numeric
);
--
-- SIC
CREATE TABLE sic (
  code varchar(6) PRIMARY KEY,
  sictype char(1),
  description text
);
--
CREATE TABLE warehouse (
  id serial PRIMARY KEY,
  description text
);
--
CREATE TABLE inventory (
  entity_id integer references entity_employee(entity_id),
  warehouse_id int,
  parts_id int,
  trans_id int,
  orderitems_id int,
  qty numeric,
  shippingdate date,
  entry_id SERIAL PRIMARY KEY
);
--
CREATE TABLE yearend (
  trans_id int PRIMARY KEY,
  transdate date
);
--
CREATE TABLE partsvendor (
  entity_id int not null references entity_credit_account(id) on delete cascade,
  parts_id int,
  partnumber text,
  leadtime int2,
  lastcost NUMERIC,
  curr char(3),
  entry_id SERIAL PRIMARY KEY
);
--
CREATE TABLE partscustomer (
  parts_id int,
  customer_id int not null references entity_credit_account(id) on delete cascade,
  pricegroup_id int,
  pricebreak numeric,
  sellprice NUMERIC,
  validfrom date,
  validto date,
  curr char(3),
  entry_id SERIAL PRIMARY KEY
);

-- How does partscustomer.customer_id relate here?

--
CREATE TABLE language (
  code varchar(6) PRIMARY KEY,
  description text
);
--
CREATE TABLE audittrail (
  trans_id int,
  tablename text,
  reference text,
  formname text,
  action text,
  transdate timestamp default current_timestamp,
  person_id integer references person(id) not null,
  entry_id BIGSERIAL PRIMARY KEY
);
--
CREATE TABLE translation (
  trans_id int,
  language_code varchar(6),
  description text,
  PRIMARY KEY (trans_id, language_code)
);
--
CREATE TABLE user_preference (
    id int PRIMARY KEY REFERENCES users(id),
    language varchar(6) REFERENCES language(code),
    stylesheet text default 'ledgersmb.css' not null,
    printer text,
    dateformat text default 'yyyy-mm-dd' not null,
    numberformat text default '1000.00' not null
);

-- user_preference is here due to a dependency on language.code
COMMENT ON TABLE user_preference IS 
$$ This table sets the basic preferences for formats, languages, printers, and user-selected stylesheets.$$;

CREATE TABLE recurring (
  id int DEFAULT nextval ( 'id' ) PRIMARY KEY,
  reference text,
  startdate date,
  nextdate date,
  enddate date,
  repeat int2,
  unit varchar(6),
  howmany int,
  payment bool default 'f'
);
--
CREATE TABLE recurringemail (
  id int,
  formname text,
  format text,
  message text,
  PRIMARY KEY (id, formname)
);
--
CREATE TABLE recurringprint (
  id int,
  formname text,
  format text,
  printer text,
  PRIMARY KEY (id, formname)
);
--
CREATE TABLE jcitems (
  id serial PRIMARY KEY,
  project_id int,
  parts_id int,
  description text,
  qty numeric,
  allocated numeric,
  sellprice NUMERIC,
  fxsellprice NUMERIC,
  serialnumber text,
  checkedin timestamp with time zone,
  checkedout timestamp with time zone,
  person_id integer references person(id) not null,
  notes text
);


INSERT INTO transactions (id, table_name) SELECT id, 'ap' FROM ap;

INSERT INTO transactions (id, table_name) SELECT id, 'ar' FROM ap;

INSERT INTO transactions (id, table_name) SELECT id, 'gl' FROM gl;

CREATE OR REPLACE FUNCTION track_global_sequence() RETURNS TRIGGER AS
$$
BEGIN
	IF tg_op = 'INSERT' THEN
		INSERT INTO transactions (id, table_name) 
		VALUES (new.id, TG_RELNAME);
	ELSEIF tg_op = 'UPDATE' THEN
		IF new.id = old.id THEN
			return new;
		ELSE
			UPDATE transactions SET id = new.id WHERE id = old.id;
		END IF;
	ELSE 
		DELETE FROM transactions WHERE id = old.id;
	END IF;
	RETURN new;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER ap_track_global_sequence BEFORE INSERT OR UPDATE ON ap
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER ar_track_global_sequence BEFORE INSERT OR UPDATE ON ar
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER gl_track_global_sequence BEFORE INSERT OR UPDATE ON gl
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TABLE custom_table_catalog (
table_id SERIAL PRIMARY KEY,
extends TEXT,
table_name TEXT
);

CREATE TABLE custom_field_catalog (
field_id SERIAL PRIMARY KEY,
table_id INT REFERENCES custom_table_catalog,
field_name TEXT
);

INSERT INTO taxmodule (
  taxmodule_id, taxmodulename
  ) VALUES (
  1, 'Simple'
);

create index acc_trans_trans_id_key on acc_trans (trans_id);
create index acc_trans_chart_id_key on acc_trans (chart_id);
create index acc_trans_transdate_key on acc_trans (transdate);
create index acc_trans_source_key on acc_trans (lower(source));
--
create index ap_id_key on ap (id);
create index ap_transdate_key on ap (transdate);
create index ap_invnumber_key on ap (invnumber);
create index ap_ordnumber_key on ap (ordnumber);
create index ap_quonumber_key on ap (quonumber);
--
create index ar_id_key on ar (id);
create index ar_transdate_key on ar (transdate);
create index ar_invnumber_key on ar (invnumber);
create index ar_ordnumber_key on ar (ordnumber);
create index ar_quonumber_key on ar (quonumber);
--
create index assembly_id_key on assembly (id);
--
create index chart_id_key on chart (id);
create unique index chart_accno_key on chart (accno);
create index chart_category_key on chart (category);
create index chart_link_key on chart (link);
create index chart_gifi_accno_key on chart (gifi_accno);
--
create index customer_customer_id_key on customertax (customer_id);
--
create index exchangerate_ct_key on exchangerate (curr, transdate);
--
create unique index gifi_accno_key on gifi (accno);
--
create index gl_id_key on gl (id);
create index gl_transdate_key on gl (transdate);
create index gl_reference_key on gl (reference);
create index gl_description_key on gl (lower(description));
--
create index invoice_id_key on invoice (id);
create index invoice_trans_id_key on invoice (trans_id);
--
create index makemodel_parts_id_key on makemodel (parts_id);
create index makemodel_make_key on makemodel (lower(make));
create index makemodel_model_key on makemodel (lower(model));
--
create index oe_id_key on oe (id);
create index oe_transdate_key on oe (transdate);
create index oe_ordnumber_key on oe (ordnumber);
create index orderitems_trans_id_key on orderitems (trans_id);
create index orderitems_id_key on orderitems (id);
--
create index parts_id_key on parts (id);
create index parts_partnumber_key on parts (lower(partnumber));
create index parts_description_key on parts (lower(description));
create index partstax_parts_id_key on partstax (parts_id);
--
--
create index shipto_trans_id_key on shipto (trans_id);
--
create index project_id_key on project (id);
create unique index projectnumber_key on project (projectnumber);
--
create index partsgroup_id_key on partsgroup (id);
create unique index partsgroup_key on partsgroup (partsgroup);
--
create index status_trans_id_key on status (trans_id);
--
create index department_id_key on department (id);
--
create index partsvendor_parts_id_key on partsvendor (parts_id);
--
create index pricegroup_pricegroup_key on pricegroup (pricegroup);
create index pricegroup_id_key on pricegroup (id);
--
create index audittrail_trans_id_key on audittrail (trans_id);
--
create index translation_trans_id_key on translation (trans_id);
--
create unique index language_code_key on language (code);
--
create index jcitems_id_key on jcitems (id);

-- Popular some entity data

INSERT INTO country(short_name,name) VALUES ('AC','Ascension Island');
INSERT INTO country(short_name,name) VALUES ('AD','Andorra');
INSERT INTO country(short_name,name) VALUES ('AE','United Arab Emirates');
INSERT INTO country(short_name,name) VALUES ('AF','Afghanistan');
INSERT INTO country(short_name,name) VALUES ('AG','Antigua and Barbuda');
INSERT INTO country(short_name,name) VALUES ('AI','Anguilla');
INSERT INTO country(short_name,name) VALUES ('AL','Albania');
INSERT INTO country(short_name,name) VALUES ('AM','Armenia');
INSERT INTO country(short_name,name) VALUES ('AN','Netherlands Antilles');
INSERT INTO country(short_name,name) VALUES ('AO','Angola');
INSERT INTO country(short_name,name) VALUES ('AQ','Antarctica');
INSERT INTO country(short_name,name) VALUES ('AR','Argentina');
INSERT INTO country(short_name,name) VALUES ('AS','American Samoa');
INSERT INTO country(short_name,name) VALUES ('AT','Austria');
INSERT INTO country(short_name,name) VALUES ('AU','Australia');
INSERT INTO country(short_name,name) VALUES ('AW','Aruba');
INSERT INTO country(short_name,name) VALUES ('AX','Aland Islands');
INSERT INTO country(short_name,name) VALUES ('AZ','Azerbaijan');
INSERT INTO country(short_name,name) VALUES ('BA','Bosnia and Herzegovina');
INSERT INTO country(short_name,name) VALUES ('BB','Barbados');
INSERT INTO country(short_name,name) VALUES ('BD','Bangladesh');
INSERT INTO country(short_name,name) VALUES ('BE','Belgium');
INSERT INTO country(short_name,name) VALUES ('BF','Burkina Faso');
INSERT INTO country(short_name,name) VALUES ('BG','Bulgaria');
INSERT INTO country(short_name,name) VALUES ('BH','Bahrain');
INSERT INTO country(short_name,name) VALUES ('BI','Burundi');
INSERT INTO country(short_name,name) VALUES ('BJ','Benin');
INSERT INTO country(short_name,name) VALUES ('BM','Bermuda');
INSERT INTO country(short_name,name) VALUES ('BN','Brunei Darussalam');
INSERT INTO country(short_name,name) VALUES ('BO','Bolivia');
INSERT INTO country(short_name,name) VALUES ('BR','Brazil');
INSERT INTO country(short_name,name) VALUES ('BS','Bahamas');
INSERT INTO country(short_name,name) VALUES ('BT','Bhutan');
INSERT INTO country(short_name,name) VALUES ('BV','Bouvet Island');
INSERT INTO country(short_name,name) VALUES ('BW','Botswana');
INSERT INTO country(short_name,name) VALUES ('BY','Belarus');
INSERT INTO country(short_name,name) VALUES ('BZ','Belize');
INSERT INTO country(short_name,name) VALUES ('CA','Canada');
INSERT INTO country(short_name,name) VALUES ('CC','Cocos (Keeling) Islands');
INSERT INTO country(short_name,name) VALUES ('CD','Congo, Democratic Republic');
INSERT INTO country(short_name,name) VALUES ('CF','Central African Republic');
INSERT INTO country(short_name,name) VALUES ('CG','Congo');
INSERT INTO country(short_name,name) VALUES ('CH','Switzerland');
INSERT INTO country(short_name,name) VALUES ('CI','Cote D\'Ivoire (Ivory Coast)');
INSERT INTO country(short_name,name) VALUES ('CK','Cook Islands');
INSERT INTO country(short_name,name) VALUES ('CL','Chile');
INSERT INTO country(short_name,name) VALUES ('CM','Cameroon');
INSERT INTO country(short_name,name) VALUES ('CN','China');
INSERT INTO country(short_name,name) VALUES ('CO','Colombia');
INSERT INTO country(short_name,name) VALUES ('CR','Costa Rica');
INSERT INTO country(short_name,name) VALUES ('CS','Czechoslovakia (former)');
INSERT INTO country(short_name,name) VALUES ('CU','Cuba');
INSERT INTO country(short_name,name) VALUES ('CV','Cape Verde');
INSERT INTO country(short_name,name) VALUES ('CX','Christmas Island');
INSERT INTO country(short_name,name) VALUES ('CY','Cyprus');
INSERT INTO country(short_name,name) VALUES ('CZ','Czech Republic');
INSERT INTO country(short_name,name) VALUES ('DE','Germany');
INSERT INTO country(short_name,name) VALUES ('DJ','Djibouti');
INSERT INTO country(short_name,name) VALUES ('DK','Denmark');
INSERT INTO country(short_name,name) VALUES ('DM','Dominica');
INSERT INTO country(short_name,name) VALUES ('DO','Dominican Republic');
INSERT INTO country(short_name,name) VALUES ('DZ','Algeria');
INSERT INTO country(short_name,name) VALUES ('EC','Ecuador');
INSERT INTO country(short_name,name) VALUES ('EE','Estonia');
INSERT INTO country(short_name,name) VALUES ('EG','Egypt');
INSERT INTO country(short_name,name) VALUES ('EH','Western Sahara');
INSERT INTO country(short_name,name) VALUES ('ER','Eritrea');
INSERT INTO country(short_name,name) VALUES ('ES','Spain');
INSERT INTO country(short_name,name) VALUES ('ET','Ethiopia');
INSERT INTO country(short_name,name) VALUES ('FI','Finland');
INSERT INTO country(short_name,name) VALUES ('FJ','Fiji');
INSERT INTO country(short_name,name) VALUES ('FK','Falkland Islands (Malvinas)');
INSERT INTO country(short_name,name) VALUES ('FM','Micronesia');
INSERT INTO country(short_name,name) VALUES ('FO','Faroe Islands');
INSERT INTO country(short_name,name) VALUES ('FR','France');
INSERT INTO country(short_name,name) VALUES ('FX','France, Metropolitan');
INSERT INTO country(short_name,name) VALUES ('GA','Gabon');
INSERT INTO country(short_name,name) VALUES ('GB','Great Britain (UK)');
INSERT INTO country(short_name,name) VALUES ('GD','Grenada');
INSERT INTO country(short_name,name) VALUES ('GE','Georgia');
INSERT INTO country(short_name,name) VALUES ('GF','French Guiana');
INSERT INTO country(short_name,name) VALUES ('GH','Ghana');
INSERT INTO country(short_name,name) VALUES ('GI','Gibraltar');
INSERT INTO country(short_name,name) VALUES ('GL','Greenland');
INSERT INTO country(short_name,name) VALUES ('GM','Gambia');
INSERT INTO country(short_name,name) VALUES ('GN','Guinea');
INSERT INTO country(short_name,name) VALUES ('GP','Guadeloupe');
INSERT INTO country(short_name,name) VALUES ('GQ','Equatorial Guinea');
INSERT INTO country(short_name,name) VALUES ('GR','Greece');
INSERT INTO country(short_name,name) VALUES ('GS','S. Georgia and S. Sandwich Isls.');
INSERT INTO country(short_name,name) VALUES ('GT','Guatemala');
INSERT INTO country(short_name,name) VALUES ('GU','Guam');
INSERT INTO country(short_name,name) VALUES ('GW','Guinea-Bissau');
INSERT INTO country(short_name,name) VALUES ('GY','Guyana');
INSERT INTO country(short_name,name) VALUES ('HK','Hong Kong');
INSERT INTO country(short_name,name) VALUES ('HM','Heard and McDonald Islands');
INSERT INTO country(short_name,name) VALUES ('HN','Honduras');
INSERT INTO country(short_name,name) VALUES ('HR','Croatia (Hrvatska)');
INSERT INTO country(short_name,name) VALUES ('HT','Haiti');
INSERT INTO country(short_name,name) VALUES ('HU','Hungary');
INSERT INTO country(short_name,name) VALUES ('ID','Indonesia');
INSERT INTO country(short_name,name) VALUES ('IE','Ireland');
INSERT INTO country(short_name,name) VALUES ('IL','Israel');
INSERT INTO country(short_name,name) VALUES ('IM','Isle of Man');
INSERT INTO country(short_name,name) VALUES ('IN','India');
INSERT INTO country(short_name,name) VALUES ('IO','British Indian Ocean Territory');
INSERT INTO country(short_name,name) VALUES ('IQ','Iraq');
INSERT INTO country(short_name,name) VALUES ('IR','Iran');
INSERT INTO country(short_name,name) VALUES ('IS','Iceland');
INSERT INTO country(short_name,name) VALUES ('IT','Italy');
INSERT INTO country(short_name,name) VALUES ('JE','Jersey');
INSERT INTO country(short_name,name) VALUES ('JM','Jamaica');
INSERT INTO country(short_name,name) VALUES ('JO','Jordan');
INSERT INTO country(short_name,name) VALUES ('JP','Japan');
INSERT INTO country(short_name,name) VALUES ('KE','Kenya');
INSERT INTO country(short_name,name) VALUES ('KG','Kyrgyzstan');
INSERT INTO country(short_name,name) VALUES ('KH','Cambodia');
INSERT INTO country(short_name,name) VALUES ('KI','Kiribati');
INSERT INTO country(short_name,name) VALUES ('KM','Comoros');
INSERT INTO country(short_name,name) VALUES ('KN','Saint Kitts and Nevis');
INSERT INTO country(short_name,name) VALUES ('KP','Korea (North)');
INSERT INTO country(short_name,name) VALUES ('KR','Korea (South)');
INSERT INTO country(short_name,name) VALUES ('KW','Kuwait');
INSERT INTO country(short_name,name) VALUES ('KY','Cayman Islands');
INSERT INTO country(short_name,name) VALUES ('KZ','Kazakhstan');
INSERT INTO country(short_name,name) VALUES ('LA','Laos');
INSERT INTO country(short_name,name) VALUES ('LB','Lebanon');
INSERT INTO country(short_name,name) VALUES ('LC','Saint Lucia');
INSERT INTO country(short_name,name) VALUES ('LI','Liechtenstein');
INSERT INTO country(short_name,name) VALUES ('LK','Sri Lanka');
INSERT INTO country(short_name,name) VALUES ('LR','Liberia');
INSERT INTO country(short_name,name) VALUES ('LS','Lesotho');
INSERT INTO country(short_name,name) VALUES ('LT','Lithuania');
INSERT INTO country(short_name,name) VALUES ('LU','Luxembourg');
INSERT INTO country(short_name,name) VALUES ('LV','Latvia');
INSERT INTO country(short_name,name) VALUES ('LY','Libya');
INSERT INTO country(short_name,name) VALUES ('MA','Morocco');
INSERT INTO country(short_name,name) VALUES ('MC','Monaco');
INSERT INTO country(short_name,name) VALUES ('MD','Moldova');
INSERT INTO country(short_name,name) VALUES ('MG','Madagascar');
INSERT INTO country(short_name,name) VALUES ('MH','Marshall Islands');
INSERT INTO country(short_name,name) VALUES ('MK','F.Y.R.O.M. (Macedonia)');
INSERT INTO country(short_name,name) VALUES ('ML','Mali');
INSERT INTO country(short_name,name) VALUES ('MM','Myanmar');
INSERT INTO country(short_name,name) VALUES ('MN','Mongolia');
INSERT INTO country(short_name,name) VALUES ('MO','Macau');
INSERT INTO country(short_name,name) VALUES ('MP','Northern Mariana Islands');
INSERT INTO country(short_name,name) VALUES ('MQ','Martinique');
INSERT INTO country(short_name,name) VALUES ('MR','Mauritania');
INSERT INTO country(short_name,name) VALUES ('MS','Montserrat');
INSERT INTO country(short_name,name) VALUES ('MT','Malta');
INSERT INTO country(short_name,name) VALUES ('MU','Mauritius');
INSERT INTO country(short_name,name) VALUES ('MV','Maldives');
INSERT INTO country(short_name,name) VALUES ('MW','Malawi');
INSERT INTO country(short_name,name) VALUES ('MX','Mexico');
INSERT INTO country(short_name,name) VALUES ('MY','Malaysia');
INSERT INTO country(short_name,name) VALUES ('MZ','Mozambique');
INSERT INTO country(short_name,name) VALUES ('NA','Namibia');
INSERT INTO country(short_name,name) VALUES ('NC','New Caledonia');
INSERT INTO country(short_name,name) VALUES ('NE','Niger');
INSERT INTO country(short_name,name) VALUES ('NF','Norfolk Island');
INSERT INTO country(short_name,name) VALUES ('NG','Nigeria');
INSERT INTO country(short_name,name) VALUES ('NI','Nicaragua');
INSERT INTO country(short_name,name) VALUES ('NL','Netherlands');
INSERT INTO country(short_name,name) VALUES ('NO','Norway');
INSERT INTO country(short_name,name) VALUES ('NP','Nepal');
INSERT INTO country(short_name,name) VALUES ('NR','Nauru');
INSERT INTO country(short_name,name) VALUES ('NT','Neutral Zone');
INSERT INTO country(short_name,name) VALUES ('NU','Niue');
INSERT INTO country(short_name,name) VALUES ('NZ','New Zealand (Aotearoa)');
INSERT INTO country(short_name,name) VALUES ('OM','Oman');
INSERT INTO country(short_name,name) VALUES ('PA','Panama');
INSERT INTO country(short_name,name) VALUES ('PE','Peru');
INSERT INTO country(short_name,name) VALUES ('PF','French Polynesia');
INSERT INTO country(short_name,name) VALUES ('PG','Papua New Guinea');
INSERT INTO country(short_name,name) VALUES ('PH','Philippines');
INSERT INTO country(short_name,name) VALUES ('PK','Pakistan');
INSERT INTO country(short_name,name) VALUES ('PL','Poland');
INSERT INTO country(short_name,name) VALUES ('PM','St. Pierre and Miquelon');
INSERT INTO country(short_name,name) VALUES ('PN','Pitcairn');
INSERT INTO country(short_name,name) VALUES ('PR','Puerto Rico');
INSERT INTO country(short_name,name) VALUES ('PS','Palestinian Territory, Occupied');
INSERT INTO country(short_name,name) VALUES ('PT','Portugal');
INSERT INTO country(short_name,name) VALUES ('PW','Palau');
INSERT INTO country(short_name,name) VALUES ('PY','Paraguay');
INSERT INTO country(short_name,name) VALUES ('QA','Qatar');
INSERT INTO country(short_name,name) VALUES ('RE','Reunion');
INSERT INTO country(short_name,name) VALUES ('RO','Romania');
INSERT INTO country(short_name,name) VALUES ('RS','Serbia');
INSERT INTO country(short_name,name) VALUES ('RU','Russian Federation');
INSERT INTO country(short_name,name) VALUES ('RW','Rwanda');
INSERT INTO country(short_name,name) VALUES ('SA','Saudi Arabia');
INSERT INTO country(short_name,name) VALUES ('SB','Solomon Islands');
INSERT INTO country(short_name,name) VALUES ('SC','Seychelles');
INSERT INTO country(short_name,name) VALUES ('SD','Sudan');
INSERT INTO country(short_name,name) VALUES ('SE','Sweden');
INSERT INTO country(short_name,name) VALUES ('SG','Singapore');
INSERT INTO country(short_name,name) VALUES ('SH','St. Helena');
INSERT INTO country(short_name,name) VALUES ('SI','Slovenia');
INSERT INTO country(short_name,name) VALUES ('SJ','Svalbard & Jan Mayen Islands');
INSERT INTO country(short_name,name) VALUES ('SK','Slovak Republic');
INSERT INTO country(short_name,name) VALUES ('SL','Sierra Leone');
INSERT INTO country(short_name,name) VALUES ('SM','San Marino');
INSERT INTO country(short_name,name) VALUES ('SN','Senegal');
INSERT INTO country(short_name,name) VALUES ('SO','Somalia');
INSERT INTO country(short_name,name) VALUES ('SR','Suriname');
INSERT INTO country(short_name,name) VALUES ('ST','Sao Tome and Principe');
INSERT INTO country(short_name,name) VALUES ('SU','USSR (former)');
INSERT INTO country(short_name,name) VALUES ('SV','El Salvador');
INSERT INTO country(short_name,name) VALUES ('SY','Syria');
INSERT INTO country(short_name,name) VALUES ('SZ','Swaziland');
INSERT INTO country(short_name,name) VALUES ('TC','Turks and Caicos Islands');
INSERT INTO country(short_name,name) VALUES ('TD','Chad');
INSERT INTO country(short_name,name) VALUES ('TF','French Southern Territories');
INSERT INTO country(short_name,name) VALUES ('TG','Togo');
INSERT INTO country(short_name,name) VALUES ('TH','Thailand');
INSERT INTO country(short_name,name) VALUES ('TJ','Tajikistan');
INSERT INTO country(short_name,name) VALUES ('TK','Tokelau');
INSERT INTO country(short_name,name) VALUES ('TM','Turkmenistan');
INSERT INTO country(short_name,name) VALUES ('TN','Tunisia');
INSERT INTO country(short_name,name) VALUES ('TO','Tonga');
INSERT INTO country(short_name,name) VALUES ('TP','East Timor');
INSERT INTO country(short_name,name) VALUES ('TR','Turkey');
INSERT INTO country(short_name,name) VALUES ('TT','Trinidad and Tobago');
INSERT INTO country(short_name,name) VALUES ('TV','Tuvalu');
INSERT INTO country(short_name,name) VALUES ('TW','Taiwan');
INSERT INTO country(short_name,name) VALUES ('TZ','Tanzania');
INSERT INTO country(short_name,name) VALUES ('UA','Ukraine');
INSERT INTO country(short_name,name) VALUES ('UG','Uganda');
INSERT INTO country(short_name,name) VALUES ('UK','United Kingdom');
INSERT INTO country(short_name,name) VALUES ('UM','US Minor Outlying Islands');
INSERT INTO country(short_name,name) VALUES ('US','United States');
INSERT INTO country(short_name,name) VALUES ('UY','Uruguay');
INSERT INTO country(short_name,name) VALUES ('UZ','Uzbekistan');
INSERT INTO country(short_name,name) VALUES ('VA','Vatican City State (Holy See)');
INSERT INTO country(short_name,name) VALUES ('VC','Saint Vincent & the Grenadines');
INSERT INTO country(short_name,name) VALUES ('VE','Venezuela');
INSERT INTO country(short_name,name) VALUES ('VG','British Virgin Islands');
INSERT INTO country(short_name,name) VALUES ('VI','Virgin Islands (U.S.)');
INSERT INTO country(short_name,name) VALUES ('VN','Viet Nam');
INSERT INTO country(short_name,name) VALUES ('VU','Vanuatu');
INSERT INTO country(short_name,name) VALUES ('WF','Wallis and Futuna Islands');
INSERT INTO country(short_name,name) VALUES ('WS','Samoa');
INSERT INTO country(short_name,name) VALUES ('YE','Yemen');
INSERT INTO country(short_name,name) VALUES ('YT','Mayotte');
INSERT INTO country(short_name,name) VALUES ('YU','Yugoslavia (former)');
INSERT INTO country(short_name,name) VALUES ('ZA','South Africa');
INSERT INTO country(short_name,name) VALUES ('ZM','Zambia');
INSERT INTO country(short_name,name) VALUES ('ZR','Zaire');
INSERT INTO country(short_name,name) VALUES ('ZW','Zimbabwe');



--
CREATE FUNCTION del_yearend() RETURNS TRIGGER AS '
begin
  delete from yearend where trans_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_yearend AFTER DELETE ON gl FOR EACH ROW EXECUTE PROCEDURE del_yearend();
-- end trigger
--
CREATE FUNCTION del_department() RETURNS TRIGGER AS '
begin
  delete from dpt_trans where trans_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_department AFTER DELETE ON ar FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
CREATE TRIGGER del_department AFTER DELETE ON ap FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
CREATE TRIGGER del_department AFTER DELETE ON gl FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
CREATE TRIGGER del_department AFTER DELETE ON oe FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
--
CREATE FUNCTION del_exchangerate() RETURNS TRIGGER AS '

declare
  t_transdate date;
  t_curr char(3);
  t_id int;
  d_curr text;

begin

  select into d_curr substr(value,1,3) from defaults where setting_key = ''curr'';
  
  if TG_RELNAME = ''ar'' then
    select into t_curr, t_transdate curr, transdate from ar where id = old.id;
  end if;
  if TG_RELNAME = ''ap'' then
    select into t_curr, t_transdate curr, transdate from ap where id = old.id;
  end if;
  if TG_RELNAME = ''oe'' then
    select into t_curr, t_transdate curr, transdate from oe where id = old.id;
  end if;

  if d_curr != t_curr then

    select into t_id a.id from acc_trans ac
    join ar a on (a.id = ac.trans_id)
    where a.curr = t_curr
    and ac.transdate = t_transdate

    except select a.id from ar a where a.id = old.id
    
    union
    
    select a.id from acc_trans ac
    join ap a on (a.id = ac.trans_id)
    where a.curr = t_curr
    and ac.transdate = t_transdate
    
    except select a.id from ap a where a.id = old.id
    
    union
    
    select o.id from oe o
    where o.curr = t_curr
    and o.transdate = t_transdate
    
    except select o.id from oe o where o.id = old.id;

    if not found then
      delete from exchangerate where curr = t_curr and transdate = t_transdate;
    end if;
  end if;
return old;

end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_exchangerate BEFORE DELETE ON ar FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
CREATE TRIGGER del_exchangerate BEFORE DELETE ON ap FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
CREATE TRIGGER del_exchangerate BEFORE DELETE ON oe FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
CREATE FUNCTION check_department() RETURNS TRIGGER AS '

declare
  dpt_id int;

begin
 
  if new.department_id = 0 then
    delete from dpt_trans where trans_id = new.id;
    return NULL;
  end if;

  select into dpt_id trans_id from dpt_trans where trans_id = new.id;
  
  if dpt_id > 0 then
    update dpt_trans set department_id = new.department_id where trans_id = dpt_id;
  else
    insert into dpt_trans (trans_id, department_id) values (new.id, new.department_id);
  end if;
return NULL;

end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON ar FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON ap FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON gl FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON oe FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
--
CREATE FUNCTION del_recurring() RETURNS TRIGGER AS '
BEGIN
  DELETE FROM recurring WHERE id = old.id;
  DELETE FROM recurringemail WHERE id = old.id;
  DELETE FROM recurringprint WHERE id = old.id;
  RETURN NULL;
END;
' language 'plpgsql';
--end function
CREATE TRIGGER del_recurring AFTER DELETE ON ar FOR EACH ROW EXECUTE PROCEDURE del_recurring();
-- end trigger
CREATE TRIGGER del_recurring AFTER DELETE ON ap FOR EACH ROW EXECUTE PROCEDURE del_recurring();
-- end trigger
CREATE TRIGGER del_recurring AFTER DELETE ON gl FOR EACH ROW EXECUTE PROCEDURE del_recurring();
-- end trigger
--
CREATE FUNCTION avgcost(int) RETURNS FLOAT AS '

DECLARE

v_cost float;
v_qty float;
v_parts_id alias for $1;

BEGIN

  SELECT INTO v_cost, v_qty SUM(i.sellprice * i.qty), SUM(i.qty)
  FROM invoice i
  JOIN ap a ON (a.id = i.trans_id)
  WHERE i.parts_id = v_parts_id;
  
  IF v_cost IS NULL THEN
    v_cost := 0;
  END IF;

  IF NOT v_qty IS NULL THEN
    IF v_qty = 0 THEN
      v_cost := 0;
    ELSE
      v_cost := v_cost/v_qty;
    END IF;
  END IF;

RETURN v_cost;
END;
' language 'plpgsql';
-- end function
--
CREATE FUNCTION lastcost(int) RETURNS FLOAT AS '

DECLARE

v_cost float;
v_parts_id alias for $1;

BEGIN

  SELECT INTO v_cost sellprice FROM invoice i
  JOIN ap a ON (a.id = i.trans_id)
  WHERE i.parts_id = v_parts_id
  ORDER BY a.transdate desc, a.id desc
  LIMIT 1;

  IF v_cost IS NULL THEN
    v_cost := 0;
  END IF;

RETURN v_cost;
END;
' language plpgsql;
-- end function
--

CREATE OR REPLACE FUNCTION trigger_parts_short() RETURNS TRIGGER
AS
'
BEGIN
  IF NEW.onhand >= NEW.rop THEN
    NOTIFY parts_short;
  END IF;
  RETURN NEW;
END;
' LANGUAGE PLPGSQL;
-- end function

CREATE TRIGGER parts_short AFTER UPDATE ON parts 
FOR EACH ROW EXECUTE PROCEDURE trigger_parts_short();
-- end function

CREATE OR REPLACE FUNCTION add_custom_field (VARCHAR, VARCHAR, VARCHAR) 
RETURNS BOOL AS
'
DECLARE
table_name ALIAS FOR $1;
new_field_name ALIAS FOR $2;
field_datatype ALIAS FOR $3;

BEGIN
	EXECUTE ''SELECT TABLE_ID FROM custom_table_catalog 
		WHERE extends = '''''' || table_name || '''''' '';
	IF NOT FOUND THEN
		BEGIN
			INSERT INTO custom_table_catalog (extends) 
				VALUES (table_name);
			EXECUTE ''CREATE TABLE custom_''||table_name || 
				'' (row_id INT PRIMARY KEY)'';
		EXCEPTION WHEN duplicate_table THEN
			-- do nothing
		END;
	END IF;
	EXECUTE ''INSERT INTO custom_field_catalog (field_name, table_id)
	VALUES ( '''''' || new_field_name ||'''''', (SELECT table_id FROM custom_table_catalog
		WHERE extends = ''''''|| table_name || ''''''))'';
	EXECUTE ''ALTER TABLE custom_''||table_name || '' ADD COLUMN '' 
		|| new_field_name || '' '' || field_datatype;
	RETURN TRUE;
END;
' LANGUAGE PLPGSQL;
-- end function

CREATE OR REPLACE FUNCTION drop_custom_field (VARCHAR, VARCHAR) 
RETURNS BOOL AS
'
DECLARE
table_name ALIAS FOR $1;
custom_field_name ALIAS FOR $2;
BEGIN
	DELETE FROM custom_field_catalog 
	WHERE field_name = custom_field_name AND 
		table_id = (SELECT table_id FROM custom_table_catalog 
			WHERE extends = table_name);
	EXECUTE ''ALTER TABLE custom_'' || table_name || 
		'' DROP COLUMN '' || custom_field_name;
	RETURN TRUE;	
END;
' LANGUAGE PLPGSQL;
-- end function
CREATE TABLE menu_node (
    id serial NOT NULL,
    label character varying NOT NULL,
    parent integer,
    "position" integer NOT NULL
);


--ALTER TABLE public.menu_node OWNER TO ledgersmb;

--
-- Name: menu_node_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ledgersmb
--

SELECT pg_catalog.setval('menu_node_id_seq', 209, true);

--
-- Data for Name: menu_node; Type: TABLE DATA; Schema: public; Owner: ledgersmb
--

COPY menu_node (id, label, parent, "position") FROM stdin;
205	Transaction Approval	0	5
128	System	0	16
190	Stylesheet	0	17
191	Preferences	0	18
192	New Window	0	19
193	Logout	0	20
206	Batches	205	1
46	HR	0	6
50	Order Entry	0	7
63	Shipping	0	8
67	Quotations	0	9
73	General Journal	0	10
77	Goods and Services	0	11
0	Top-level	\N	0
1	AR	0	1
2	Add Transaction	1	1
144	Departments	128	8
5	Transactions	4	1
6	Outstanding	4	2
7	AR Aging	4	3
9	Taxable Sales	4	4
10	Non-Taxable	4	5
12	Add Customer	11	1
13	Reports	11	2
14	Search	13	1
15	History	13	2
16	Point of Sale	0	2
17	Sale	16	1
18	Open	16	2
19	Receipts	16	3
20	Close Till	16	4
21	AP	0	3
22	Add Transaction	21	1
145	Add Department	144	1
25	Transactions	24	1
26	Outstanding	24	2
27	AP Aging	24	3
28	Taxable	24	4
29	Non-taxable	24	5
31	Add Vendor	30	1
32	Reports	30	2
33	Search	32	1
34	History	32	2
35	Cash	0	4
36	Receipt	35	1
38	Payment	35	3
37	Receipts	35	2
146	List Departments	144	2
42	Receipts	41	1
43	Payments	41	2
44	Reconciliation	41	3
147	Type of Business	128	9
47	Employees	46	1
48	Add Employee	47	1
49	Search	47	2
51	Sales Order	50	1
52	Purchase Order	50	2
53	Reports	50	3
54	Sales Orders	53	1
55	Purchase Orders	53	2
57	Sales Orders	56	1
58	Purchase Orders	56	2
56	Generate	50	4
60	Consolidate	50	5
61	Sales Orders	60	1
62	Purchase Orders	60	2
64	Ship	63	1
65	Receive	63	2
66	Transfer	63	3
68	Quotation	67	1
69	RFQ	67	2
70	Reports	67	3
71	Quotations	70	1
72	RFQs	70	2
74	Journal Entry	73	1
75	Adjust Till	73	2
76	Reports	73	3
78	Add Part	77	1
79	Add Service	77	2
80	Add Assembly	77	3
81	Add Overhead	77	4
82	Add Group	77	5
83	Add Pricegroup	77	6
84	Stock Assembly	77	7
85	Reports	77	8
86	All Items	85	1
87	Parts	85	2
88	Requirements	85	3
89	Services	85	4
90	Labor	85	5
91	Groups	85	6
92	Pricegroups	85	7
93	Assembly	85	8
94	Components	85	9
95	Translations	77	9
96	Description	95	1
97	Partsgroup	95	2
99	Add Project	98	1
100	Add Timecard	98	2
101	Generate	98	3
102	Sales Orders	101	1
103	Reports	98	4
104	Search	103	1
105	Transactions	103	2
106	Time Cards	103	3
107	Translations	98	5
108	Description	107	1
110	Chart of Accounts	109	1
111	Trial Balance	109	2
112	Income Statement	109	3
113	Balance Sheet	109	4
114	Inventory Activity	109	5
117	Sales Invoices	116	1
118	Sales Orders	116	2
119	Checks	116	3
120	Work Orders	116	4
121	Quotations	116	5
122	Packing Lists	116	6
123	Pick Lists	116	7
124	Purchase Orders	116	8
125	Bin Lists	116	9
126	RFQs	116	10
127	Time Cards	116	11
129	Audit Control	128	1
130	Taxes	128	2
131	Defaults	128	3
132	Yearend	128	4
133	Backup	128	5
134	Send to File	133	1
135	Send to Email	133	2
136	Chart of Accounts	128	6
137	Add Accounts	136	1
138	List Accounts	136	2
139	Add GIFI	136	3
140	List GIFI	136	4
141	Warehouses	128	7
142	Add Warehouse	141	1
143	List Warehouse	141	2
148	Add Business	147	1
149	List Businesses	147	2
150	Language	128	10
151	Add Language	150	1
152	List Languages	150	2
153	SIC	128	11
154	Add SIC	153	1
155	List SIC	153	2
156	HTML Templates	128	12
157	Income Statement	156	1
158	Balance Sheet	156	2
159	Invoice	156	3
160	AR Transaction	156	4
161	AP Transaction	156	5
162	Packing List	156	6
163	Pick List	156	7
164	Sales Order	156	8
165	Work Order	156	9
166	Purchase Order	156	10
167	Bin List	156	11
168	Statement	156	12
169	Quotation	156	13
170	RFQ	156	14
171	Timecard	156	15
172	LaTeX Templates	128	13
173	Invoice	172	1
174	AR Transaction	172	2
175	AP Transaction	172	3
176	Packing List	172	4
177	Pick List	172	5
178	Sales Order	172	6
179	Work Order	172	7
180	Purchase Order	172	8
181	Bin List	172	9
182	Statement	172	10
183	Check	172	11
184	Receipt	172	12
185	Quotation	172	13
186	RFQ	172	14
187	Timecard	172	15
188	Text Templates	128	14
189	POS Invoice	188	1
198	AR Voucher	1	2
3	Sales Invoice	1	3
11	Customers	1	7
4	Reports	1	6
194	Credit Note	1	4
195	Credit Invoice	1	5
199	AP Voucher	21	2
23	Vendor Invoice	21	3
24	Reports	21	6
30	Vendors	21	7
196	Debit Note	21	4
197	Debit Invoice	21	5
200	Vouchers	35	5
40	Transfer	35	6
41	Reports	35	8
45	Reconciliation	35	7
203	Receipts	200	3
204	Reverse Receipts	200	4
201	Payments	200	1
202	Reverse Payment	200	2
98	Projects	0	12
109	Reports	0	13
115	Recurring Transactions	0	14
116	Batch Printing	0	15
\.


--
-- Name: menu_node_parent_key; Type: CONSTRAINT; Schema: public; Owner: ledgersmb; Tablespace: 
--

ALTER TABLE ONLY menu_node
    ADD CONSTRAINT menu_node_parent_key UNIQUE (parent, "position");


--
-- Name: menu_node_pkey; Type: CONSTRAINT; Schema: public; Owner: ledgersmb; Tablespace: 
--

ALTER TABLE ONLY menu_node
    ADD CONSTRAINT menu_node_pkey PRIMARY KEY (id);


--
-- Name: menu_node_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ledgersmb
--

ALTER TABLE ONLY menu_node
    ADD CONSTRAINT menu_node_parent_fkey FOREIGN KEY (parent) REFERENCES menu_node(id);



CREATE TABLE menu_attribute (
    node_id integer NOT NULL,
    attribute character varying NOT NULL,
    value character varying NOT NULL,
    id serial NOT NULL
);


--
-- Name: menu_attribute_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ledgersmb
--

SELECT pg_catalog.setval('menu_attribute_id_seq', 584, true);


--
-- Data for Name: menu_attribute; Type: TABLE DATA; Schema: public; Owner: ledgersmb
--

COPY menu_attribute (node_id, attribute, value, id) FROM stdin;
26	outstanding	1	584
205	menu	1	574
206	module	vouchers.pl	575
206	action	search_batch	576
1	menu	1	1
2	module	ar.pl	2
2	action	add	3
3	action	add	4
3	module	is.pl	5
3	type	invoice	6
4	menu	1	7
5	module	ar.pl	8
5	action	search	9
5	nextsub	transactions	10
6	module	ar.pl	12
6	action	search	13
6	nextsub	transactions	14
7	module	rp.pl	15
7	action	report	16
7	report	ar_aging	17
9	module	rp.pl	21
9	action	report	22
9	report	tax_collected	23
10	module	rp.pl	24
10	action	report	25
10	report	nontaxable_sales	26
11	menu	1	27
12	module	customer.pl	28
12	action	add	29
13	menu	1	31
14	module	customer.pl	32
14	action	search	36
15	module	ct.pl	35
15	db	customer	37
15	action	history	33
16	menu	1	38
17	module	ps.pl	39
17	action	add	40
17	nextsub	openinvoices	41
18	action	openinvoices	42
18	module	ps.pl	43
19	module	ps.pl	44
19	action	receipts	46
20	module	rc.pl	47
20	action	till_closing	48
20	pos	true	49
21	menu	1	50
22	action	add	52
22	module	ap.pl	51
23	action	add	53
23	type	invoice	55
23	module	ir.pl	54
24	menu	1	56
25	action	search	58
25	nextsub	transactions	59
25	module	ap.pl	57
26	action	search	61
26	nextsub	transactions	62
26	module	ap.pl	60
27	module	rp.pl	63
27	action	report	64
28	module	rp.pl	66
28	action	report	67
28	report	tax_collected	68
27	report	tax_paid	65
29	module	rp.pl	69
29	action	report	70
29	report	report	71
30	menu	1	72
31	module	vendor.pl	73
31	action	add	74
31	db	vendor	75
32	menu	1	76
33	module	vendor.pl	77
33	action	search	79
33	db	vendor	78
34	module	vendor.pl	80
34	action	history	81
34	db	vendor	82
35	menu	1	83
36	module	payment.pl	84
36	action	payment	85
36	type	receipt	86
37	module	cp.pl	87
38	module	cp.pl	90
38	action	payment	91
37	type	receipt	89
37	action	payments	88
38	type	check	92
194	module	ar.pl	538
194	action	add	539
40	module	gl.pl	96
40	action	add	97
40	transfer	1	98
41	menu	1	99
42	module	rp.pl	100
42	action	report	101
42	report	receipts	102
43	module	rp.pl	103
43	action	report	104
43	report	payments	105
45	module	rc.pl	106
45	action	reconciliation	107
44	module	rc.pl	108
44	action	reconciliation	109
44	report	1	110
46	menu	1	111
47	menu	1	112
48	module	employee.pl	113
48	action	add	114
48	db	employee	115
49	module	hr.pl	116
49	db	employee	118
49	action	search	117
50	menu	1	119
51	module	oe.pl	120
51	action	add	121
51	type	sales_order	122
52	module	oe.pl	123
52	action	add	124
52	type	purchase_order	125
53	menu	1	126
54	module	oe.pl	127
54	type	sales_order	129
54	action	search	128
55	module	oe.pl	130
55	type	purchase_order	132
55	action	search	131
56	menu	1	133
57	module	oe.pl	134
57	action	search	136
58	module	oe.pl	137
58	action	search	139
57	type	generate_sales_order	135
58	type	generate_purchase_order	138
60	menu	1	550
61	module	oe.pl	140
61	action	search	141
62	module	oe.pl	143
62	action	search	144
62	type	consolidate_purchase_order	145
61	type	consolidate_sales_order	142
63	menu	1	146
64	module	oe.pl	147
64	action	search	148
65	module	oe.pl	150
65	action	search	151
65	type	consolidate_sales_order	152
64	type	receive_order	149
66	module	oe.pl	153
66	action	search_transfer	154
67	menu	1	155
68	module	oe.pl	156
68	action	add	157
69	module	oe.pl	159
69	action	add	160
68	type	sales_quotation	158
69	type	request_quotation	161
70	menu	1	162
71	module	oe.pl	163
71	type	sales_quotation	165
71	action	search	164
72	module	oe.pl	166
72	action	search	168
72	type	request_quotation	167
73	menu	1	169
74	module	gl.pl	170
74	action	add	171
75	module	gl.pl	172
75	action	add_pos_adjust	174
75	rowcount	3	175
75	pos_adjust	1	176
75	reference	Adjusting Till: (Till)  Source: (Source)	177
75	descripton	Adjusting till due to data entry error	178
76	module	gl.pl	180
76	action	search	181
77	menu	1	182
78	module	ic.pl	183
78	action	add	184
78	item	part	185
79	module	ic.pl	186
79	action	add	187
79	item	service	188
80	module	ic.pl	189
80	action	add	190
81	module	ic.pl	192
81	action	add	193
81	item	part	194
80	item	labor	191
82	action	add	195
82	module	pe.pl	196
83	action	add	198
83	module	pe.pl	199
83	type	partsgroup	200
82	type	pricegroup	197
84	module	ic.pl	202
84	action	stock_assembly	203
85	menu	1	204
86	module	ic.pl	205
87	action	search	206
88	module	ic.pl	211
88	action	requirements	212
89	action	search	213
89	module	ic.pl	214
89	searchitems	service	215
87	searchitems	part	210
90	action	search	216
90	module	ic.pl	217
90	searchitems	labor	218
91	module	pe.pl	221
91	type	pricegroup	222
91	action	search	220
92	module	pe.pl	224
92	type	partsgroup	225
92	action	search	223
93	action	search	226
93	module	ic.pl	227
93	searchitems	assembly	228
94	action	search	229
94	module	ic.pl	230
94	searchitems	component	231
95	menu	1	232
96	module	pe.pl	233
96	action	translation	234
96	translation	description	235
97	module	pe.pl	236
97	action	translation	237
97	translation	partsgroup	238
98	menu	1	239
99	module	pe.pl	240
99	action	add	241
99	type	project	242
100	module	jc.pl	243
100	action	add	244
99	project	project	245
100	project	project	246
100	type	timecard	247
101	menu	1	248
102	module	pe.pl	249
102	action	project_sales_order	250
103	menu	1	255
104	module	pe.pl	256
104	type	project	258
104	action	search	257
105	action	report	260
105	report	projects	261
105	module	rp.pl	262
106	module	jc.pl	263
106	action	search	264
106	type	timecard	265
106	project	project	266
107	menu	1	268
108	module	pe.pl	269
108	action	translation	270
108	translation	project	271
109	menu	1	272
110	module	ca.pl	273
110	action	chart_of_accounts	274
111	action	report	275
111	module	rp.pl	276
111	report	trial_balance	277
112	action	report	278
112	module	rp.pl	279
112	report	income_statement	280
113	action	report	281
113	module	rp.pl	282
113	report	balance_sheet	283
114	action	report	284
114	module	rp.pl	285
114	report	inv_activity	286
115	action	recurring_transactions	287
115	module	am.pl	288
116	menu	1	289
119	module	bp.pl	290
119	action	search	291
119	type	check	292
119	vc	vendor	293
117	module	bp.pl	294
117	action	search	295
117	vc	customer	297
118	module	bp.pl	298
118	action	search	299
118	vc	customer	300
118	type	invoice	301
117	type	sales_order	296
120	module	bp.pl	302
120	action	search	303
120	vc	customer	304
121	module	bp.pl	306
121	action	search	307
121	vc	customer	308
122	module	bp.pl	310
122	action	search	311
122	vc	customer	312
120	type	work_order	305
121	type	sales_quotation	309
122	type	packing_list	313
123	module	bp.pl	314
123	action	search	315
123	vc	customer	316
123	type	pick_list	317
124	module	bp.pl	318
124	action	search	319
124	vc	vendor	321
124	type	purchase_order	320
125	module	bp.pl	322
125	action	search	323
125	vc	vendor	325
126	module	bp.pl	326
126	action	search	327
126	vc	vendor	329
127	module	bp.pl	330
127	action	search	331
127	type	timecard	332
125	type	bin_list	324
126	type	request_quotation	328
127	vc	employee	333
128	menu	1	334
129	module	am.pl	337
130	module	am.pl	338
131	module	am.pl	339
129	action	audit_control	340
130	taxes	audit_control	341
131	action	defaults	342
130	action	taxes	343
132	module	am.pl	346
132	action	yearend	347
133	menu	1	348
134	module	am.pl	349
135	module	am.pl	350
134	action	backup	351
135	action	backup	352
134	media	file	353
135	media	email	354
137	module	am.pl	355
138	module	am.pl	356
139	module	am.pl	357
140	module	am.pl	358
137	action	add_account	359
138	action	list_account	360
139	action	add_gifi	361
140	action	list_gifi	362
141	menu	1	363
142	module	am.pl	364
143	module	am.pl	365
142	action	add_warehouse	366
143	action	list_warehouse	367
145	module	am.pl	368
146	module	am.pl	369
145	action	add_department	370
146	action	list_department	371
147	menu	1	372
148	module	am.pl	373
149	module	am.pl	374
148	action	add_business	375
149	action	list_business	376
150	menu	1	377
151	module	am.pl	378
152	module	am.pl	379
151	action	add_language	380
152	action	list_language	381
153	menu	1	382
154	module	am.pl	383
155	module	am.pl	384
154	action	add_sic	385
155	action	list_sic	386
156	menu	1	387
157	module	am.pl	388
158	module	am.pl	389
159	module	am.pl	390
160	module	am.pl	391
161	module	am.pl	392
162	module	am.pl	393
163	module	am.pl	394
164	module	am.pl	395
165	module	am.pl	396
166	module	am.pl	397
167	module	am.pl	398
168	module	am.pl	399
169	module	am.pl	400
170	module	am.pl	401
171	module	am.pl	402
157	action	list_templates	403
158	action	list_templates	404
159	action	list_templates	405
160	action	list_templates	406
161	action	list_templates	407
162	action	list_templates	408
163	action	list_templates	409
164	action	list_templates	410
165	action	list_templates	411
166	action	list_templates	412
167	action	list_templates	413
168	action	list_templates	414
169	action	list_templates	415
170	action	list_templates	416
171	action	list_templates	417
157	template	income_statement	418
158	template	balance_sheet	419
159	template	invoice	420
160	template	ar_transaction	421
161	template	ap_transaction	422
162	template	packing_list	423
163	template	pick_list	424
164	template	sales_order	425
165	template	work_order	426
166	template	purchase_order	427
167	template	bin_list	428
168	template	statement	429
169	template	quotation	430
170	template	rfq	431
171	template	timecard	432
157	format	HTML	433
158	format	HTML	434
159	format	HTML	435
160	format	HTML	436
161	format	HTML	437
162	format	HTML	438
163	format	HTML	439
164	format	HTML	440
165	format	HTML	441
166	format	HTML	442
167	format	HTML	443
168	format	HTML	444
169	format	HTML	445
170	format	HTML	446
171	format	HTML	447
172	menu	1	448
173	action	list_templates	449
174	action	list_templates	450
175	action	list_templates	451
176	action	list_templates	452
177	action	list_templates	453
178	action	list_templates	454
179	action	list_templates	455
180	action	list_templates	456
181	action	list_templates	457
182	action	list_templates	458
183	action	list_templates	459
184	action	list_templates	460
185	action	list_templates	461
186	action	list_templates	462
187	action	list_templates	463
173	module	am.pl	464
174	module	am.pl	465
175	module	am.pl	466
176	module	am.pl	467
177	module	am.pl	468
178	module	am.pl	469
179	module	am.pl	470
180	module	am.pl	471
181	module	am.pl	472
182	module	am.pl	473
183	module	am.pl	474
184	module	am.pl	475
185	module	am.pl	476
186	module	am.pl	477
187	module	am.pl	478
173	format	LATEX	479
174	format	LATEX	480
175	format	LATEX	481
176	format	LATEX	482
177	format	LATEX	483
178	format	LATEX	484
179	format	LATEX	485
180	format	LATEX	486
181	format	LATEX	487
182	format	LATEX	488
183	format	LATEX	489
184	format	LATEX	490
185	format	LATEX	491
186	format	LATEX	492
187	format	LATEX	493
173	template	invoice	506
174	template	ar_transaction	507
175	template	ap_transaction	508
176	template	packing_list	509
177	template	pick_list	510
178	template	sales_order	511
179	template	work_order	512
180	template	purchase_order	513
181	template	bin_list	514
182	template	statement	515
185	template	quotation	518
186	template	rfq	519
187	template	timecard	520
183	template	check	516
184	template	receipt	517
188	menu	1	521
189	module	am.pl	522
189	action	list_templates	523
189	template	pos_invoice	524
189	format	TEXT	525
190	action	display_stylesheet	526
190	module	am.pl	527
191	module	am.pl	528
191	action	config	529
193	module	login.pl	532
193	action	logout	533
193	target	_top	534
192	menu	1	530
192	new	1	531
0	menu	1	535
136	menu	1	536
144	menu	1	537
195	action	add	540
195	module	is.pl	541
196	action	add	543
196	module	ap.pl	544
197	action	add	545
197	module	ir.pl	547
196	type	debit_note	549
194	type	credit_note	548
195	type	credit_invoice	542
197	type	debit_invoice	546
36	account_class	1	551
202	batch_type	payment_reversal	570
204	batch_type	receipt_reversal	573
200	menu	1	552
198	action	create_batch	554
198	batch_type	receivable	555
198	module	vouchers.pl	553
199	module	vouchers.pl	559
199	action	create_batch	560
199	batch_type	payable	561
201	module	vouchers.pl	562
201	action	create_batch	563
203	module	vouchers.pl	565
203	action	create_batch	566
203	batch_type	receipts	567
202	module	vouchers.pl	568
202	action	create_batch	569
204	module	vouchers.pl	571
204	action	create_batch	572
201	batch_type	payment	564
\.

--
-- Name: menu_attribute_id_key; Type: CONSTRAINT; Schema: public; Owner: ledgersmb; Tablespace: 
--

ALTER TABLE ONLY menu_attribute
    ADD CONSTRAINT menu_attribute_id_key UNIQUE (id);


--
-- Name: menu_attribute_pkey; Type: CONSTRAINT; Schema: public; Owner: ledgersmb; Tablespace: 
--

ALTER TABLE ONLY menu_attribute
    ADD CONSTRAINT menu_attribute_pkey PRIMARY KEY (node_id, attribute);


--
-- Name: menu_attribute_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ledgersmb
--

ALTER TABLE ONLY menu_attribute
    ADD CONSTRAINT menu_attribute_node_id_fkey FOREIGN KEY (node_id) REFERENCES menu_node(id);


--
-- PostgreSQL database dump complete
--

--

CREATE TABLE menu_acl (
    id serial NOT NULL,
    role_name character varying,
    acl_type character varying,
    node_id integer,
    CONSTRAINT menu_acl_acl_type_check CHECK ((((acl_type)::text = 'allow'::text) OR ((acl_type)::text = 'deny'::text)))
);



ALTER TABLE ONLY menu_acl
    ADD CONSTRAINT menu_acl_pkey PRIMARY KEY (id);


ALTER TABLE ONLY menu_acl
    ADD CONSTRAINT menu_acl_node_id_fkey FOREIGN KEY (node_id) REFERENCES menu_node(id);


--
-- PostgreSQL database dump complete
--

CREATE TYPE menu_item AS (
   position int,
   id int,
   level int,
   label varchar,
   path varchar,
   args varchar[]
);

CREATE OR REPLACE FUNCTION menu_generate() RETURNS SETOF menu_item AS 
$$
DECLARE 
	item menu_item;
	arg menu_attribute%ROWTYPE;
	
BEGIN
	FOR item IN 
		SELECT n.position, n.id, c.level, n.label, c.path, '{}' 
		FROM connectby('menu_node', 'id', 'parent', 'position', '0', 
				0, ',') 
			c(id integer, parent integer, "level" integer, 
				path text, list_order integer)
		JOIN menu_node n USING(id)
	LOOP
		FOR arg IN 
			SELECT *
			FROM menu_attribute
			WHERE node_id = item.id
		LOOP
			item.args := item.args || 
				(arg.attribute || '=' || arg.value)::varchar;
		END LOOP;
		RETURN NEXT item;
	END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION menu_children(in_parent_id int) RETURNS SETOF menu_item
AS $$
declare 
	item menu_item;
	arg menu_attribute%ROWTYPE;
begin
        FOR item IN
		SELECT n.position, n.id, c.level, n.label, c.path, '{}' 
		FROM connectby('menu_node', 'id', 'parent', 'position', 
				in_parent_id, 1, ',') 
			c(id integer, parent integer, "level" integer, 
				path text, list_order integer)
		JOIN menu_node n USING(id)
        LOOP
		FOR arg IN 
			SELECT *
			FROM menu_attribute
			WHERE node_id = item.id
		LOOP
			item.args := item.args || 
				(arg.attribute || '=' || arg.value)::varchar;
		END LOOP;
                return next item;
        end loop;
end;
$$ language plpgsql;

COMMENT ON FUNCTION menu_children(int) IS $$ This function returns all menu items which are children of in_parent_id (the only input parameter. $$;

CREATE OR REPLACE FUNCTION 
menu_insert(in_parent_id int, in_position int, in_label text)
returns int
AS $$
DECLARE
	new_id int;
BEGIN
	UPDATE menu_node 
	SET position = position * -1
	WHERE parent = in_parent_id
		AND position >= in_position;

	INSERT INTO menu_node (parent, position, label)
	VALUES (in_parent_id, in_position, in_label);

	SELECT INTO new_id currval('menu_node_id_seq');

	UPDATE menu_node 
	SET position = (position * -1) + 1
	WHERE parent = in_parent_id
		AND position < 0;

	RETURN new_id;
END;
$$ language plpgsql;

comment on function menu_insert(int, int, text) is $$
This function inserts menu items at arbitrary positions.  The arguments are, in
order:  parent, position, label.  The return value is the id number of the menu
item created. $$;


CREATE VIEW menu_friendly AS
    SELECT t."level", t.path, t.list_order, (repeat(' '::text, (2 * t."level")) || (n.label)::text) AS label, n.id, n."position" FROM (connectby('menu_node'::text, 'id'::text, 'parent'::text, 'position'::text, '0'::text, 0, ','::text) t(id integer, parent integer, "level" integer, path text, list_order integer) JOIN menu_node n USING (id));


--ALTER TABLE public.menu_friendly OWNER TO ledgersmb;

--
-- PostgreSQL database dump complete
--
CREATE AGGREGATE as_array (
	BASETYPE = ANYELEMENT,
	STYPE = ANYARRAY,
	SFUNC = ARRAY_APPEND,
	INITCOND = '{}'
);

CREATE AGGREGATE compound_array (
	BASETYPE = ANYARRAY,
	STYPE = ANYARRAY,
	SFUNC = ARRAY_CAT,
	INITCOND = '{}'
);

CREATE TABLE pending_reports (
    id bigserial primary key not null,
    report_id int,
    scn int,
    their_balance INT,
    our_balance INT,
    errorcode INT,
    entered_by int references entity(id) not null,
    corrections INT NOT NULL DEFAULT 0,
    clear_time TIMESTAMP NOT NULL,
    insert_time TIMESTAMPTZ NOT NULL DEFAULT now(),
    ledger_id int REFERENCES acc_trans(entry_id),
    overlook boolean not null default 'f'
);


CREATE TABLE report_corrections (
    id serial primary key not null,
    correction_id int not null default 1,
    entry_in int references pending_reports(id) not null,
    entered_by int not null,
    reason text not null,
    insert_time timestamptz not null default now()
);

CREATE INDEX company_name_gist__idx ON company USING gist(legal_name gist_trgm_ops);
CREATE INDEX location_address_one_gist__idx ON location USING gist(line_one gist_trgm_ops);
CREATE INDEX location_address_two_gist__idx ON location USING gist(line_two gist_trgm_ops);
CREATE INDEX location_address_three_gist__idx ON location USING gist(line_three gist_trgm_ops);
    
CREATE INDEX location_city_prov_gist_idx ON location USING gist(city gist_trgm_ops);
CREATE INDEX entity_name_gist_idx ON entity USING gist(name gist_trgm_ops);

CREATE TABLE pending_job (
	id serial not null unique,
	batch_class int references batch_class(id),
	entered_by text REFERENCES users(username)
		not null default SESSION_USER,
	entered_at timestamp default now(),
	batch_id int references batch(id),
	completed_at timestamp,
	success bool,
	error_condition text,
	CHECK (completed_at IS NULL OR success IS NOT NULL),
	CHECK (success IS NOT FALSE OR error_condition IS NOT NULL)
);
COMMENT ON table pending_job IS
$$ Purpose:  This table stores pending/queued jobs to be processed async.
Additionally, this functions as a log of all such processing for purposes of 
internal audits, performance tuning, and the like. $$;

CREATE INDEX pending_job_batch_id_pending ON pending_job(batch_id) where success IS NULL;

CREATE INDEX pending_job_entered_by ON pending_job(entered_by);

CREATE OR REPLACE FUNCTION trigger_pending_job() RETURNS TRIGGER
AS
$$
BEGIN
  IF NEW.success IS NULL THEN
    NOTIFY job_entered;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER notify_pending_jobs BEFORE INSERT OR UPDATE ON pending_job
FOR EACH ROW EXECUTE PROCEDURE trigger_pending_job();

CREATE TABLE payments_queue (
	transactions numeric[], 
	batch_id int, 
	source text, 
	total numeric,
	ar_ap_accno text, 
	cash_accno text, 
	payment_date date, 
	account_class int,
	job_id int references pending_job(id) 
		DEFAULT currval('pending_job_id_seq')
);

CREATE INDEX payments_queue_job_id ON payments_queue(job_id);

COMMENT ON table payments_queue IS 
$$ This is a holding table and hence not a candidate for normalization.
Jobs should be deleted from this table when they complete successfully.$$;

commit;
