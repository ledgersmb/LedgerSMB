--
ALTER TABLE customer ADD (customernumber VARCHAR2(40));
UPDATE customer SET customernumber = businessnumber;
ALTER TABLE customer DROP COLUMN businessnumber;
CREATE INDEX customer_customernumber_key ON customer (customernumber);
--
ALTER TABLE vendor ADD (vendornumber VARCHAR2(40));
UPDATE vendor SET vendornumber = businessnumber;
ALTER TABLE vendor DROP COLUMN businessnumber;
CREATE INDEX vendor_vendornumber_key ON vendor (vendornumber);
--
CREATE TABLE employee (
  id INTEGER,
  login VARCHAR2(20),
  name VARCHAR2(35),
  addr1 VARCHAR2(35),
  addr2 VARCHAR2(35),
  addr3 VARCHAR2(35),
  addr4 VARCHAR2(35),
  workphone VARCHAR2(20),
  homephone VARCHAR2(20),
  startdate DATE DEFAULT SYSDATE,
  enddate DATE,
  notes VARCHAR2(4000)
);
--
CREATE OR REPLACE TRIGGER employeeid BEFORE INSERT ON employee FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE INDEX employee_id_key ON employee (id);
CREATE UNIQUE INDEX employee_login_key ON employee (login);
CREATE INDEX employee_name_key ON employee (name);
--
ALTER TABLE gl ADD (employee_id INTEGER);
CREATE INDEX gl_employee_id_key ON gl (employee_id);
ALTER TABLE ar ADD (employee_id INTEGER);
CREATE INDEX ar_employee_id_key ON ar (employee_id);
ALTER TABLE ap ADD (employee_id INTEGER);
CREATE INDEX ap_employee_id_key ON ap (employee_id);
ALTER TABLE oe ADD (employee_id INTEGER);
CREATE INDEX oe_employee_id_key ON oe (employee_id);
--
ALTER TABLE invoice ADD (unit VARCHAR2(5));
ALTER TABLE orderitems ADD (unit VARCHAR2(5));
--
UPDATE chart SET gifi_accno = '' WHERE gifi_accno = NULL;
ALTER TABLE chart RENAME TO chartold;
CREATE TABLE chart (
  id INTEGER,
  accno VARCHAR2(20) NOT NULL,
  description VARCHAR2(100),
  charttype CHAR(1) DEFAULT 'A',
  category CHAR(1),
  link VARCHAR2(100),
  gifi_accno VARCHAR2(20)
);
INSERT INTO chart (id, accno, description, charttype, category, link, gifi_accno) SELECT id, accno, description, charttype, category, link, gifi_accno from chartold;
DROP TABLE chartold;
CREATE INDEX chart_id_key ON chart (id);
CREATE UNIQUE INDEX chart_accno_key ON chart (accno);
CREATE INDEX chart_category_key ON chart (category);
CREATE INDEX chart_link_key ON chart (link);
CREATE INDEX chart_gifi_accno_key ON chart (gifi_accno);
--
ALTER TABLE parts MODIFY inventory_accno_id;
--
ALTER TABLE defaults ADD (sonumber VARCHAR2(30));
UPDATE defaults SET sonumber = ordnumber;
ALTER TABLE defaults DROP COLUMN ordnumber;
ALTER TABLE defaults ADD (ponumber VARCHAR2(30));
--
UPDATE defaults SET version = '1.8.5';
--
