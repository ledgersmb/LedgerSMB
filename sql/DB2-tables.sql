-- DB2-tables.sql
-- Bill Ott modified from Oracle tables, March 02, 2002
-- 
-- Jim Rawlings modified for use with SL 2.0.8 and DB2 v7.2 
-- and higher August 27, 2003
--
--
---------------------------------------------------------
-- DDL Statements for sequence id
---------------------------------------------------------
CREATE SEQUENCE id AS INTEGER START WITH 10000      
INCREMENT BY 1 MAXVALUE 2147483647 MINVALUE 1 CACHE 5
@
---------------------------------------------------------
-- DDL Statements for table makemodel
---------------------------------------------------------
CREATE TABLE makemodel (                               
  parts_id INTEGER,                                   
  name VARCHAR(100)                                  
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table gl
---------------------------------------------------------
CREATE TABLE gl (                                       
  id INTEGER,                                          
  reference VARCHAR(50),                              
  description VARCHAR(100),                          
  transdate DATE WITH DEFAULT current date,         
  employee_id INTEGER,                             
  notes VARCHAR(4000)                              
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table chart
---------------------------------------------------------
CREATE TABLE chart (                                    
  id INTEGER,                                          
  accno VARCHAR(20) NOT NULL,                         
  description VARCHAR(100),                          
  charttype CHAR(1) WITH DEFAULT 'A',               
  category CHAR(1),                                
  link VARCHAR(100),                              
  gifi_accno VARCHAR(20)                         
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table gifi
---------------------------------------------------------
CREATE TABLE gifi (                                    
  accno VARCHAR(20),                                  
  description VARCHAR(100)                           
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table defaults
---------------------------------------------------------
CREATE TABLE defaults (                             
  inventory_accno_id INTEGER,                      
  income_accno_id INTEGER,                        
  expense_accno_id INTEGER,                            
  fxgain_accno_id INTEGER,                            
  fxloss_accno_id INTEGER,                           
  invnumber VARCHAR(30),                            
  sonumber  VARCHAR(30),                           
  yearend VARCHAR(5),                             
  weightunit VARCHAR(5),                         
  businessnumber VARCHAR(30),                   
  version VARCHAR(8),                          
  curr VARCHAR(500),                          
  closedto DATE,                            
  revtrans CHAR(1) WITH DEFAULT '0',       
  ponumber VARCHAR(30)                    
) IN LEDGER_TS
@
INSERT INTO defaults (version) VALUES ('2.0.10')
@
---------------------------------------------------------
-- DDL Statements for table acc_trans
---------------------------------------------------------
CREATE TABLE acc_trans (                                
  trans_id INTEGER,                                     
  chart_id INTEGER,                                     
  amount FLOAT,                                         
  transdate DATE WITH DEFAULT current date,             
  source VARCHAR(20),                                   
  cleared CHAR(1) WITH DEFAULT '0',                     
  fx_transaction CHAR(1) WITH DEFAULT '0',              
  project_id INTEGER                                    
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table invoice
---------------------------------------------------------
CREATE TABLE invoice (                                  
  id       INTEGER,                                     
  trans_id INTEGER,                                     
  parts_id INTEGER,                                     
  description VARCHAR(4000),                            
  qty FLOAT,                                            
  allocated FLOAT,                                      
  sellprice FLOAT,                                      
  fxsellprice FLOAT,                                    
  discount FLOAT,                                       
  assemblyitem CHAR(1) WITH DEFAULT '0',                
  unit VARCHAR(5),                                      
  project_id INTEGER,                                   
  deliverydate DATE                                     
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table vendor
---------------------------------------------------------
CREATE TABLE vendor (                                   
  id INTEGER,                                           
  name VARCHAR(35),                                     
  addr1 VARCHAR(35),                                    
  addr2 VARCHAR(35),                                    
  addr3 VARCHAR(35),                                    
  addr4 VARCHAR(35),                                    
  contact VARCHAR(35),                                  
  phone VARCHAR(20),                                    
  fax VARCHAR(20),                                      
  email VARCHAR(50),                                    
  notes VARCHAR(4000),                                  
  terms INTEGER WITH DEFAULT,                           
  taxincluded CHAR(1),                                  
  vendornumber VARCHAR(40),                             
  cc VARCHAR(50),                                       
  bcc VARCHAR(50)                                       
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table customer
---------------------------------------------------------
CREATE TABLE customer (                                
  id    INTEGER,                                        
  name  VARCHAR(35),                                    
  addr1 VARCHAR(35),                                    
  addr2 VARCHAR(35),                                    
  addr3 VARCHAR(35),                                    
  addr4 VARCHAR(35),                                    
  contact VARCHAR(35),                                  
  phone VARCHAR(20),                                    
  fax VARCHAR(20),                                      
  email VARCHAR(50),                                    
  notes VARCHAR(4000),                                  
  discount FLOAT,                                      
  taxincluded CHAR(1),                                  
  creditlimit FLOAT,                                    
  terms INTEGER WITH DEFAULT,                          
  customernumber VARCHAR(40),                           
  cc VARCHAR(50),                                       
  bcc VARCHAR(50)                                       
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table parts
---------------------------------------------------------
CREATE TABLE parts (                                    
  id INTEGER,                                           
  partnumber VARCHAR(30),                               
  description VARCHAR(4000),                            
  unit VARCHAR(5),                                      
  listprice FLOAT,                                      
  sellprice FLOAT,                                      
  lastcost FLOAT,                                       
  priceupdate DATE WITH DEFAULT current date,           
  weight FLOAT,                                         
  onhand FLOAT WITH DEFAULT 0,                          
  notes VARCHAR(1500),                                  
  makemodel CHAR(1) WITH DEFAULT '0',                   
  assembly CHAR(1) WITH DEFAULT '0',                    
  alternate CHAR(1) WITH DEFAULT '0',                   
  rop FLOAT,                                            
  inventory_accno_id INTEGER,                           
  income_accno_id    INTEGER,                           
  expense_accno_id   INTEGER,                           
  bin VARCHAR(20),                                      
  obsolete CHAR(1) WITH DEFAULT '0',                    
  bom CHAR(1) WITH DEFAULT '0',                          
  image VARCHAR(100),                                    
  drawing VARCHAR(100),                                 
  microfiche VARCHAR(100),                              
  partsgroup_id INTEGER                                 
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table assembly
---------------------------------------------------------
CREATE TABLE assembly (                                 
  id INTEGER,                                           
  parts_id INTEGER,                                     
  qty FLOAT,                                            
  bom CHAR(1)                                           
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table ar
---------------------------------------------------------
CREATE TABLE ar (                                       
  id INTEGER,                                           
  invnumber VARCHAR(30),                                
  transdate DATE WITH DEFAULT current date,             
  customer_id INTEGER,                                  
  taxincluded CHAR(1),                                  
  amount FLOAT,                                         
  netamount FLOAT,                                      
  paid FLOAT,                                           
  datepaid DATE,                                        
  duedate DATE,                                         
  invoice CHAR(1) WITH DEFAULT '0',                     
  shippingpoint VARCHAR(100),                           
  terms INTEGER WITH DEFAULT 0,                         
  notes VARCHAR(4000),                                  
  curr CHAR(3),                                         
  ordnumber VARCHAR(30),                                
  employee_id INTEGER                                      
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table ap
---------------------------------------------------------
CREATE TABLE ap (                                       
  id INTEGER,                                           
  invnumber VARCHAR(30),                                
  transdate DATE WITH DEFAULT current date,             
  vendor_id INTEGER,                                    
  taxincluded CHAR(1) WITH DEFAULT '0',                 
  amount FLOAT,                                         
  netamount FLOAT,                                      
  paid FLOAT,                                           
  datepaid DATE,                                        
  duedate DATE,                                         
  invoice CHAR(1) WITH DEFAULT '0',                     
  ordnumber VARCHAR(30),                                
  curr CHAR(3),                                         
  notes VARCHAR(4000),                                  
  employee_id INTEGER                                   
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table partstax
---------------------------------------------------------
CREATE TABLE partstax (                                 
  parts_id INTEGER,                                     
  chart_id INTEGER                                      
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table tax
---------------------------------------------------------
CREATE TABLE tax (                                      
  chart_id INTEGER,                                     
  rate FLOAT,                                           
  taxnumber VARCHAR(30)                                 
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table customertax
---------------------------------------------------------
CREATE TABLE customertax (                              
  customer_id INTEGER,                                  
  chart_id INTEGER                                      
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table vendortax
---------------------------------------------------------
CREATE TABLE vendortax (                                
  vendor_id INTEGER,                                    
  chart_id INTEGER                                      
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table oe
---------------------------------------------------------
CREATE TABLE oe (                                       
  id INTEGER,                                           
  ordnumber VARCHAR(30),                                
  transdate DATE WITH DEFAULT current date,             
  vendor_id INTEGER,                                    
  customer_id INTEGER,                                  
  amount FLOAT,                                         
  netamount FLOAT,                                      
  reqdate DATE,                                         
  taxincluded CHAR(1),                                  
  shippingpoint VARCHAR(100),                          
  notes VARCHAR(4000),                                  
  curr CHAR(3),                                         
  employee_id INTEGER,                                  
  closed CHAR(1) WITH DEFAULT '0'                       
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table orderitems
---------------------------------------------------------
CREATE TABLE orderitems (                               
  trans_id INTEGER,                                     
  parts_id INTEGER,                                     
  description VARCHAR(4000),                            
  qty FLOAT,                                            
  sellprice FLOAT,                                      
  discount FLOAT,                                       
  unit VARCHAR(5),                                      
  project_id INTEGER,                                   
  reqdate DATE                                          
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table exchangerate
---------------------------------------------------------
CREATE TABLE exchangerate (                             
  curr CHAR(3),                                         
  transdate DATE,                                       
  buy FLOAT,                                            
  sell FLOAT                                            
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table employee
---------------------------------------------------------
CREATE TABLE employee (                                 
  id INTEGER,                                           
  login VARCHAR(20),                                    
  name VARCHAR(35),                                     
  addr1 VARCHAR(35),                                    
  addr2 VARCHAR(35),                                    
  addr3 VARCHAR(35),                                    
  addr4 VARCHAR(35),                                    
  workphone VARCHAR(20),                                
  homephone VARCHAR(20),                                
  startdate DATE WITH DEFAULT current date,             
  enddate DATE,                                         
  notes VARCHAR(4000)                                   
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table shipto
---------------------------------------------------------
CREATE TABLE shipto (                                   
  trans_id INTEGER,                                     
  shiptoname VARCHAR(35),                               
  shiptoaddr1 VARCHAR(35),                              
  shiptoaddr2 VARCHAR(35),                              
  shiptoaddr3 VARCHAR(35),                              
  shiptoaddr4 VARCHAR(35),                              
  shiptocontact VARCHAR(35),                            
  shiptophone VARCHAR(20),                              
  shiptofax VARCHAR(20),                                
  shiptoemail VARCHAR(50)                               
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table project
---------------------------------------------------------
CREATE TABLE project (                                  
  id INTEGER,                                           
  projectnumber VARCHAR(50),                            
  description VARCHAR(4000)                             
) IN LEDGER_TS
@
---------------------------------------------------------
-- DDL Statements for table partsgroup
---------------------------------------------------------
CREATE TABLE partsgroup (                               
  id INTEGER,                                           
  partsgroup VARCHAR(100)                               
) IN LEDGER_TS
@
---------------------------------------------------------
--!#
--!# functions N/A
--!#
---------------------------------------------------------
--!#
--!# triggers
--!#
---------------------------------------------------------
-- DDL Statements for trigger glid
---------------------------------------------------------
CREATE TRIGGER glid                                     
NO CASCADE BEFORE INSERT ON gl                          
REFERENCING NEW AS new_id                               
FOR EACH ROW MODE DB2SQL                                
BEGIN ATOMIC                                            
set new_id.id = NEXTVAL FOR id;                     
END
@
---------------------------------------------------------
-- DDL Statements for trigger chartid
---------------------------------------------------------
CREATE TRIGGER chartid                                  
NO CASCADE BEFORE INSERT ON chart                       
REFERENCING NEW AS new_id                               
FOR EACH ROW MODE DB2SQL                                
BEGIN ATOMIC                                            
set new_id.id = NEXTVAL FOR id;                     
END
@
---------------------------------------------------------
-- DDL Statements for trigger invoiceid
---------------------------------------------------------
CREATE TRIGGER invoiceid                                
NO CASCADE BEFORE INSERT ON invoice                     
REFERENCING NEW AS new_id                               
FOR EACH ROW MODE DB2SQL                                
BEGIN ATOMIC                                            
set new_id.id = NEXTVAL FOR id;                     
END
@
---------------------------------------------------------
-- DDL Statements for trigger vendorid
---------------------------------------------------------
CREATE TRIGGER vendorid                                 
NO CASCADE BEFORE INSERT ON vendor                      
REFERENCING NEW AS new_id                               
FOR EACH ROW MODE DB2SQL                                
BEGIN ATOMIC                                            
set new_id.id = NEXTVAL FOR id;                     
END
@
---------------------------------------------------------
-- DDL Statements for trigger customerid
---------------------------------------------------------
CREATE TRIGGER customerid                               
NO CASCADE BEFORE INSERT ON customer                    
REFERENCING NEW AS new_id                               
FOR EACH ROW MODE DB2SQL                                
BEGIN ATOMIC                                            
set new_id.id = NEXTVAL FOR id;                     
END
@
---------------------------------------------------------
-- DDL Statements for trigger partsid
---------------------------------------------------------
CREATE TRIGGER partsid                                  
NO CASCADE BEFORE INSERT ON parts                       
REFERENCING NEW AS new_id                               
FOR EACH ROW MODE DB2SQL                                
BEGIN ATOMIC                                            
set new_id.id = NEXTVAL FOR id;                     
END
@
---------------------------------------------------------
-- DDL Statements for trigger arid
---------------------------------------------------------
CREATE TRIGGER arid                                     
NO CASCADE BEFORE INSERT ON ar                          
REFERENCING NEW AS new_id                               
FOR EACH ROW MODE DB2SQL                                
BEGIN ATOMIC                                            
set new_id.id = NEXTVAL FOR id;                     
END
@
---------------------------------------------------------
-- DDL Statements for trigger apid
---------------------------------------------------------
CREATE TRIGGER apid                                     
NO CASCADE BEFORE INSERT ON ap                          
REFERENCING NEW AS new_id                               
FOR EACH ROW MODE DB2SQL                                
BEGIN ATOMIC                                            
set new_id.id = NEXTVAL FOR id;                     
END
@
---------------------------------------------------------
-- DDL Statements for trigger oeid
---------------------------------------------------------
CREATE TRIGGER oeid                                     
NO CASCADE BEFORE INSERT ON oe                          
REFERENCING NEW AS new_id                               
FOR EACH ROW MODE DB2SQL                                
BEGIN ATOMIC                                            
set new_id.id = NEXTVAL FOR id;                     
END
@
---------------------------------------------------------
-- DDL Statements for trigger employeeid
---------------------------------------------------------
CREATE TRIGGER employeeid                               
NO CASCADE BEFORE INSERT ON employee                    
REFERENCING NEW AS new_id                               
FOR EACH ROW MODE DB2SQL                                
BEGIN ATOMIC                                            
set new_id.id = NEXTVAL FOR id;                     
END
@
---------------------------------------------------------
-- DDL Statements for trigger projectid
---------------------------------------------------------
CREATE TRIGGER projectid                                
NO CASCADE BEFORE INSERT ON project                     
REFERENCING NEW AS new_id                               
FOR EACH ROW MODE DB2SQL                                
BEGIN ATOMIC                                            
set new_id.id = NEXTVAL FOR id;                     
END
@
---------------------------------------------------------
-- DDL Statements for trigger partsgroupid
---------------------------------------------------------
CREATE TRIGGER partsgroupid                        
NO CASCADE BEFORE INSERT ON partsgroup              
REFERENCING NEW AS new_id                            
FOR EACH ROW MODE DB2SQL                              
BEGIN ATOMIC                                           
set new_id.id = NEXTVAL FOR id;                    
END@


