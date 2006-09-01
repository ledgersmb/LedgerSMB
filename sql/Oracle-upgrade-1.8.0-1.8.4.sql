--
ALTER TABLE chart ADD gifi_accno VARCHAR2(20);
--
CREATE TABLE gifi (
  accno VARCHAR2(20),
  description VARCHAR2(100)
);
--
CREATE UNIQUE INDEX chart_accno_key ON chart (accno);
--
CREATE TABLE mtemp (
  parts_id INTEGER,
  name VARCHAR2(100)
);
INSERT INTO mtemp SELECT parts_id, name FROM makemodel;
DROP TABLE makemodel;
ALTER TABLE mtemp RENAME TO makemodel;
--
ALTER TABLE defaults ADD closedto DATE;
ALTER TABLE defaults ADD revtrans CHAR(1);
--
ALTER TABLE ap ADD notes VARCHAR2(4000);
--
ALTER TABLE customer ADD businessnumber VARCHAR2(40);
ALTER TABLE vendor ADD businessnumber VARCHAR2(40);
--
UPDATE defaults SET version = '1.8.4', revtrans = '0';
--
