--
alter table orderitems add notes text;
alter table invoice add notes text;
alter table acc_trans add invoice_id int;
--
update defaults set version = '2.6.4';
