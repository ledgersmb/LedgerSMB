-- adding cascade deletes
alter table file_transaction
  drop constraint file_transaction_ref_key_fkey;

alter table file_transaction
  add constraint file_transaction_ref_key_fkey
     foreign key ( ref_key )
      references transactions( id )
       on delete cascade;
