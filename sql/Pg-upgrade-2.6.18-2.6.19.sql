ALTER TABLE acc_trans ADD FOREIGN KEY (trans_id) REFERENCES transactions (id);

ALTER TABLE ap ADD PRIMARY KEY (id);

ALTER TABLE ar ADD PRIMARY KEY (id);

ALTER TABLE assembly ADD PRIMARY KEY (id, parts_id);

ALTER TABLE business ADD PRIMARY KEY (id);

ALTER TABLE customer ADD PRIMARY KEY (id);

ALTER TABLE customertax ADD PRIMARY KEY (customer_id, chart_id);

ALTER TABLE defaults ADD PRIMARY KEY (version);

ALTER TABLE department ADD PRIMARY KEY (id);

ALTER TABLE dpt_trans ADD PRIMARY KEY (trans_id);

ALTER TABLE employee ADD PRIMARY KEY (id);

ALTER TABLE exchangerate ADD PRIMARY KEY (curr, transdate);

ALTER TABLE gifi ADD PRIMARY KEY (accno);

ALTER TABLE gl ADD PRIMARY KEY (id);

ALTER TABLE invoice ADD PRIMARY KEY (id);

ALTER TABLE jcitems ADD PRIMARY KEY (id);

ALTER TABLE language ADD PRIMARY KEY (code);

ALTER TABLE makemodel ADD PRIMARY KEY (parts_id);

ALTER TABLE oe ADD PRIMARY KEY (id);

ALTER TABLE orderitems ADD PRIMARY KEY (id);

ALTER TABLE parts ADD PRIMARY KEY (id);

ALTER TABLE partsgroup ADD PRIMARY KEY (id);

ALTER TABLE partstax ADD PRIMARY KEY (parts_id, chart_id);

ALTER TABLE pricegroup ADD PRIMARY KEY (id);

ALTER TABLE project ADD PRIMARY KEY (id);

ALTER TABLE recurringemail ADD PRIMARY KEY (id);

ALTER TABLE recurring ADD PRIMARY KEY (id);

ALTER TABLE recurringprint ADD PRIMARY KEY (id);

ALTER TABLE sic ADD PRIMARY KEY (code);

ALTER TABLE status ADD PRIMARY KEY (trans_id);

ALTER TABLE tax ADD PRIMARY KEY (chart_id);
ALTER TABLE tax ADD FOREIGN KEY (chart_id) REFERENCES chart (id);

ALTER TABLE translation ADD PRIMARY KEY (trans_id, language_code);

ALTER TABLE vendor ADD PRIMARY KEY (id);

ALTER TABLE vendortax ADD PRIMARY KEY (vendor_id, chart_id);

ALTER TABLE warehouse ADD PRIMARY KEY (id);

ALTER TABLE yearend ADD PRIMARY KEY (trans_id);

LOCK inventory in EXCLUSIVE mode;
ALTER TABLE inventory ADD COLUMN entry_id bigint;
CREATE SEQUENCE inventory_entry_id_seq;

ALTER TABLE inventory ALTER COLUMN entry_id 
SET DEFAULT nextval('inventory_entry_id_seq');

UPDATE inventory SET entry_id = nextval('inventory_entry_id_seq');
ALTER TABLE inventory ADD PRIMARY key (entry_id);

LOCK partscustomer IN EXCLUSIVE MODE;
ALTER TABLE partscustomer ADD COLUMN entry_id int;
CREATE SEQUENCE partscustomer_entry_id_seq;

ALTER TABLE partscustomer ALTER COLUMN entry_id 
SET DEFAULT nextval('partscustomer_entry_id_seq');

UPDATE partscustomer SET entry_id = nextval('partscustomer_entry_id_seq');
ALTER TABLE partscustomer ADD PRIMARY KEY (entry_id);

LOCK partsvendor IN EXCLUSIVE MODE;
ALTER TABLE partsvendor ADD COLUMN entry_id int;
CREATE SEQUENCE partsvendor_entry_id_seq;

ALTER TABLE partsvendor ALTER COLUMN entry_id 
SET DEFAULT nextval('partsvendor_entry_id_seq');

UPDATE partsvendor SET entry_id = nextval('partsvendor_entry_id_seq');
ALTER TABLE partsvendor ADD PRIMARY KEY (entry_id);

LOCK audittrail IN EXCLUSIVE MODE;
ALTER TABLE audittrail ADD COLUMN entry_id int;
CREATE SEQUENCE audittrail_entry_id_seq ;

ALTER TABLE audittrail ALTER COLUMN entry_id 
SET DEFAULT nextval('audittrail_entry_id_seq');

UPDATE audittrail SET entry_id = nextval('audittrail_entry_id_seq');
ALTER TABLE audittrail ADD PRIMARY KEY (entry_id);

LOCK shipto IN EXCLUSIVE MODE;
ALTER TABLE shipto ADD COLUMN entry_id int;
CREATE SEQUENCE shipto_entry_id_seq ;

ALTER TABLE shipto ALTER COLUMN entry_id 
SET DEFAULT nextval('shipto_entry_id_seq');

UPDATE shipto SET entry_id = nextval('shipto_entry_id_seq');
ALTER TABLE shipto ADD PRIMARY KEY (entry_id);
