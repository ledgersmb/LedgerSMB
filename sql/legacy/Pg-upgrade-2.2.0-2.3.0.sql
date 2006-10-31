--
alter table oe add column quotation bool;
alter table oe alter column quotation set default 'f';
update oe set quotation = '0';
alter table oe add column quonumber text;
--
alter table defaults add column sqnumber text;
alter table defaults add column rfqnumber text;
--
alter table invoice add column serialnumber text;
--
alter table ar add column quonumber text;
create index ar_quonumber_key on ar (lower(quonumber));
alter table ap add column quonumber text;
create index ap_quonumber_key on ap (lower(quonumber));
--
alter table employee add role text;
--
alter table makemodel add column make text;
alter table makemodel add column model text;
update makemodel set make = substr(name,1,strpos(name,':')-1);
update makemodel set model = substr(name,strpos(name,':')+1);
create table temp (parts_id int,make text,model text);
insert into temp (parts_id,make,model) select parts_id,make,model from makemodel;
drop table makemodel;
alter table temp rename to makemodel;
--
create index makemodel_parts_id_key on makemodel (parts_id);
create index makemodel_make_key on makemodel (lower(make));
create index makemodel_model_key on makemodel (lower(model));
--
create table status (trans_id int, formname text, printed bool default 'f', emailed bool default 'f', spoolfile text, chart_id int);
create index status_trans_id_key on status (trans_id);
--
create sequence invoiceid;
select setval('invoiceid', (select max(id) from invoice));
alter table invoice alter column id set default nextval('invoiceid');
--
alter table ar add column intnotes text;
alter table ap add column intnotes text;
alter table oe add column intnotes text;
--
create table department (id int default nextval('id'), description text, role char(1) default 'P');
create index department_id_key on department (id);
--
alter table ar add column department_id int;
alter table ar alter column department_id set default 0;
update ar set department_id = 0;
alter table ap add column department_id int;
alter table ap alter column department_id set default 0;
update ap set department_id = 0;
alter table gl add column department_id int;
alter table gl alter column department_id set default 0;
update gl set department_id = 0;
alter table oe add column department_id int;
alter table oe alter column department_id set default 0;
update oe set department_id = 0;
--
update defaults set version = '2.3.0';
