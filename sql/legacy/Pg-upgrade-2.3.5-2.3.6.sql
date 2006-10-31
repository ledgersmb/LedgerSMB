--
create table pricegroup (id int default nextval('id'), pricegroup text);
create index pricegroup_pricegroup_key on pricegroup (pricegroup);
create index pricegroup_id_key on pricegroup (id);
--
create table partscustomer (parts_id int, customer_id int, pricegroup_id int, pricebreak float4, sellprice float, validfrom date, validto date);
--
create table language (code varchar(6), description text);
alter table customer add language_code varchar(6);
alter table customer add pricegroup_id int;
--
alter table vendor add language_code varchar(6);
alter table vendor add pricegroup_id int;
--
update defaults set version = '2.3.6';
