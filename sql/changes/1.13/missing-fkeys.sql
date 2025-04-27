
-- clean database: order items which are not linked to an order
-- are inaccessible...

delete from orderitems oi
 where not exists (select 1
                     from oe
                    where oi.trans_id = oe.id);

alter table orderitems
  add foreign key (trans_id) references oe(id);

-- clean database: warehouse inventory which isn't linked
-- to a part, doesn't make sense

delete from warehouse_inventory wi
 where not exists (select 1
                     from parts
                    where wi.parts_id = parts.id);

alter table warehouse_inventory
  add foreign key (parts_id) references parts(id);

-- clean database: warehouse inventory which isn't linked
-- to a valid order line, doesn't make sense

delete from warehouse_inventory wi
 where wi.orderitems_id is not null
   and not exists (select 1
                     from orderitems oi
                    where wi.orderitems_id = oi.id);

alter table warehouse_inventory
  add foreign key (orderitems_id) references orderitems(id);


-- clean database: warehouse inventory which isn't linked
-- to a valid warehouse, doesn't make sense

delete from warehouse_inventory wi
 where not exists (select 1
                     from warehouse w
                    where wi.warehouse_id = w.id);

alter table warehouse_inventory
  add foreign key (warehouse_id) references warehouse(id);


-- language references

insert into language (code, description)
select distinct language_code, 'created by migration'
  from (
    select language_code
      from account_heading_translation
             union
    select language_code
      from account_translation
             union
    select language_code
      from ap
             union
    select language_code
      from ar
             union
    select language_code
      from business_unit_translation
             union
    select language_code
      from oe
             union
    select language_code
      from parts_translation
             union
    select language_code
      from partsgroup_translation
  ) lc
         left join "language" l on lc.language_code = l.code
 where l.code is null
 and lc.language_code is not null;

alter table account_heading_translation
  add foreign key (language_code) references language (code);
alter table account_translation
  add foreign key (language_code) references language (code);
alter table ap
  add foreign key (language_code) references language (code);
alter table ar
  add foreign key (language_code) references language (code);
alter table business_unit_translation
  add foreign key (language_code) references language (code);
alter table oe
  add foreign key (language_code) references language (code);
alter table parts_translation
  add foreign key (language_code) references language (code);
alter table partsgroup_translation
  add foreign key (language_code) references language (code);
