-- DB2-remove.sql
-- 
-- 
-- Jim Rawlings modified for use with SL 2.0.8 and DB2 v7.2 
-- and higher August 27, 2003
--
--
---------------------------------------------------------
-- DDL Statements for object removal
---------------------------------------------------------
DROP TRIGGER partsgroupid;
DROP TRIGGER projectid;
DROP TRIGGER employeeid;
DROP TRIGGER oeid;
DROP TRIGGER apid;
DROP TRIGGER arid;
DROP TRIGGER partsid;
DROP TRIGGER customerid;
DROP TRIGGER vendorid;
DROP TRIGGER invoiceid;
DROP TRIGGER chartid;
DROP TRIGGER glid;
DROP SEQUENCE id RESTRICT;
DROP TABLE partsgroup;
DROP TABLE project;
DROP TABLE shipto;
DROP TABLE employee;
DROP TABLE exchangerate;
DROP TABLE orderitems;
DROP TABLE oe;
DROP TABLE vendortax;
DROP TABLE customertax;
DROP TABLE tax;
DROP TABLE partstax;
DROP TABLE ap;
DROP TABLE ar;
DROP TABLE assembly;
DROP TABLE parts;
DROP TABLE customer;
DROP TABLE vendor;
DROP TABLE invoice;
DROP TABLE acc_trans;
DROP TABLE defaults;
DROP TABLE gifi;
DROP TABLE chart;
DROP TABLE gl;
DROP TABLE makemodel;
