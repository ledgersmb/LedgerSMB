
-- New (missing) parts(id) references

-- Vendor-specific pricing for non-existing
-- parts is meaningless
delete from partsvendor
 where parts_id is not null
   and not exists (select 1
                     from parts p
                    where p.id = parts_id);
alter table partsvendor
  add constraint partsvendor_parts_id_fkey
  foreign key (parts_id) references parts(id)
  on update cascade;

-- Time&materials cards with non-existing parts may still
-- carry checkin & checkout times
update jcitems
   set parts_id = null
 where not exists (select 1
                     from parts p
                    where p.id = parts_id);
alter table jcitems
  add constraint jcitems_parts_id_fkey
  foreign key (parts_id) references parts(id)
  on update cascade;

-- jobs referring to non-existing parts are meaningless
-- (and there's next to no support for jobs anyway?)
delete from job
 where parts_id is not null
   and not exists (select 1
                     from parts p
                    where p.id = parts_id);
alter table job
  add constraint job_parts_id_fkey
  foreign key (parts_id) references parts(id)
  on update cascade;

-- References to parts should be cascading
--   when the parts(id) key changes

alter table assembly
  drop constraint assembly_parts_id_fkey;
alter table assembly
  add constraint assembly_parts_id_fkey
  foreign key (parts_id) references parts(id)
  on update cascade;

alter table file_part
  drop constraint file_part_ref_key_fkey;
alter table file_part
  add constraint file_part_ref_key_fkey
  foreign key (ref_key) references parts(id)
  on update cascade;

alter table inventory_report_line
  drop constraint inventory_report_line_parts_id_fkey;
alter table inventory_report_line
  add constraint inventory_report_line_parts_id_fkey
  foreign key (parts_id) references parts(id)
  on update cascade;

alter table invoice
  drop constraint invoice_parts_id_fkey;
alter table invoice
  add constraint invoice_parts_id_fkey
  foreign key (parts_id) references parts(id)
  on update cascade;

alter table makemodel
  drop constraint makemodel_parts_id_fkey;
alter table makemodel
  add constraint makemodel_parts_id_fkey
  foreign key (parts_id) references parts(id)
  on update cascade;

alter table mfg_lot
  drop constraint mfg_lot_parts_id_fkey;
alter table mfg_lot
  add constraint mfg_lot_parts_id_fkey
  foreign key (parts_id) references parts(id)
  on update cascade;

alter table mfg_lot_item
  drop constraint mfg_lot_item_parts_id_fkey;
alter table mfg_lot_item
  add constraint mfg_lot_item_parts_id_fkey
  foreign key (parts_id) references parts(id)
  on update cascade;

alter table orderitems
  drop constraint orderitems_parts_id_fkey;
alter table orderitems
  add constraint orderitems_parts_id_fkey
  foreign key (parts_id) references parts(id)
  on update cascade;

-- weird naming, but this is *really* the name of the column (trans_id)
alter table parts_translation
  drop constraint parts_translation_trans_id_fkey;
alter table parts_translation
  add constraint parts_translation_trans_id_fkey
  foreign key (trans_id) references parts(id)
  on update cascade;

alter table partscustomer
  drop constraint partscustomer_parts_id_fkey;
alter table partscustomer
  add constraint partscustomer_parts_id_fkey
  foreign key (parts_id) references parts(id)
  on update cascade;

alter table partstax
  drop constraint partstax_parts_id_fkey;
alter table partstax
  add constraint partstax_parts_id_fkey
  foreign key (parts_id) references parts(id)
  on update cascade;

alter table warehouse_inventory
  drop constraint warehouse_inventory_parts_id_fkey;
alter table warehouse_inventory
  add constraint warehouse_inventory_parts_id_fkey
  foreign key (parts_id) references parts(id)
  on update cascade;

