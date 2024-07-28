
alter table oe
  add column shipto int references location (id);
alter table ar
  add column shipto int references location (id);
alter table
  ap add column shipto int references location (id);

update oe
   set shipto = ns.location_id
       from new_shipto ns
 where oe.id = ns.oe_id;

update ar
   set shipto = ns.location_id
       from new_shipto ns
 where ar.id = ns.trans_id;

update ap
   set shipto = ns.location_id
       from new_shipto ns
 where ap.id = ns.trans_id;

drop table new_shipto;
