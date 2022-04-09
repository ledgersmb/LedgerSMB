
alter table new_shipto drop constraint new_shipto_trans_id_fkey;
alter table new_shipto add constraint new_shipto_trans_id_fkey
   foreign key (trans_id) references transactions(id) on delete cascade;

