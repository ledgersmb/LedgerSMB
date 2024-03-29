SELECT * FROM "xyz"."company__save"('C-0', 'Customer 1', NULL, NULL, NULL, '1', NULL, NULL);
SELECT * FROM "xyz"."eca__save"(NULL, '2', '2', NULL, NULL, NULL, NULL, NULL, NULL, 'Customer 1', NULL, NULL, NULL, 'USD', NULL, NULL, NULL, '3', NULL, NULL, NULL, NULL);

SELECT * FROM "xyz"."company__save"('C-1', 'Customer 2', NULL, NULL, NULL, '1', NULL, NULL);
SELECT * FROM "xyz"."eca__save"(NULL, '2', '3', NULL, NULL, NULL, NULL, NULL, NULL, 'Customer 2', NULL, NULL, NULL, 'USD', NULL, NULL, NULL, '3', NULL, NULL, NULL, NULL);

update defaults set value = 'USD' where setting_key = 'curr';

INSERT INTO parts (description,inventory_accno_id,expense_accno_id,sellprice,income_accno_id,partnumber,unit)
VALUES ('Part 1','5','37','30','33','p1','ea');

insert into partstax (parts_id, chart_id) values ('1', '15');
insert into eca_tax (eca_id, chart_id) values ('1', '15');
