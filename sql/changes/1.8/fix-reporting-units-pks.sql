
alter table business_unit_ac drop constraint business_unit_ac_pkey;
alter table business_unit_inv drop constraint business_unit_inv_pkey;
alter table business_unit_oitem drop constraint business_unit_oitem_pkey;
-- note that the table 'business_unit_jl' is already correctly "keyed"

alter table business_unit_ac add constraint business_unit_ac_pkey
   primary key (entry_id, class_id);
alter table business_unit_inv add constraint business_unit_inv_pkey
   primary key (entry_id, class_id);
alter table business_unit_oitem add constraint business_unit_oitem_pkey
   primary key (entry_id, class_id);

