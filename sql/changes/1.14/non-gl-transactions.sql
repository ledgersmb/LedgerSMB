
insert into trans_type (code, description)
values ('ap', 'The transaction is a regular Accounts Payable item'),
       ('ar', 'The transaction is a regular Accounts Receivable item');

alter table transactions
  add column description text,
  add column trans_type_code char(2) references trans_type(code),
  add column entered_by int references entity(id),
  drop constraint transactions_table_name_check,
  add constraint transactions_table_name_check check(
    table_name = ANY (ARRAY['gl'::text, 'ap'::text, 'ar'::text,
                            'mfg_lot'::text, 'asset_report'::text,
                            'inventory_report'::text, 'yearend'::text,
                            'payment'::text
                            ]
    )
  );

update transactions txn
   set trans_type_code = 'ar'
 where txn.id in (select id from ar);

update transactions txn
   set trans_type_code = 'ap'
 where txn.id in (select id from ap);

update transactions txn
   set trans_type_code = gl.trans_type_code,
       entered_by = gl.person_id
  from gl
 where txn.id = gl.id;

alter table transactions
  alter column trans_type_code set not null;

update transactions txn
   set description = old.description,
       approved = old.approved
   from (
     select id, description, approved from ar
      union
     select id, description, approved from ap
      union
     select id, description, approved from gl
   ) old
   where txn.id = old.id;

alter table ar
  drop column approved,
  drop column description,
  drop constraint ar_id_fkey,
  -- the on delete cascade prevents deletion of approved lots (= transactions)
  add constraint ar_id_fkey foreign key (id) references transactions (id) on delete cascade;

alter table ap
  drop column approved,
  drop column description,
  drop constraint ap_id_fkey,
  -- the on delete cascade prevents deletion of approved lots (= transactions)
  add constraint ap_id_fkey foreign key (id) references transactions (id) on delete cascade;

alter table gl
  drop column approved,
  drop column description,
  drop column trans_type_code,
  drop constraint gl_id_fkey,
  -- the on delete cascade prevents deletion of approved lots (= transactions)
  add constraint gl_id_fkey foreign key (id) references transactions (id) on delete cascade;


alter table mfg_lot
  -- the on delete cascade prevents deletion of approved lots (= transactions)
  add column trans_id int references transactions(id) on delete cascade;

update mfg_lot
  set trans_id = (select id
                    from gl
                   where reference = 'mfg-' || mfg_lot.id::text);

update transactions
   set table_name = 'mfg_lot'
 where id in (select id
                from gl
               where reference like 'mfg-%');

delete from gl
 where exists (select *
                 from mfg_lot ml where gl.id = ml.trans_id);


alter table asset_report
  -- the on delete cascade prevents deletion of approved lots (= transactions)
  add column trans_id int references transactions(id) on delete cascade;

update asset_report
   set trans_id = gl_id;

alter table asset_report
  drop column gl_id;

update transactions
   set table_name = 'asset_report'
  from asset_report
 where asset_report.trans_id = transactions.id;

delete from gl
 where exists (select *
                 from asset_report ar where gl.id = ar.trans_id);


alter table inventory_report
  drop constraint inventory_report_trans_id_fkey,
  -- the on delete cascade prevents deletion of approved lots (= transactions)
  add constraint inventory_report_trans_id_fkey foreign key (trans_id) references transactions(id) on delete cascade;

update transactions
   set table_name = 'inventory_report'
  from inventory_report
 where inventory_report.trans_id = transactions.id;

delete from gl
 where exists (select *
                 from inventory_report ir where gl.id = ir.trans_id);


alter table payment
  add column trans_id int references transactions(id);

update payment
   set trans_id = gl_id;

alter table payment
  drop column gl_id;

update transactions
   set table_name = 'payment'
  from payment
 where payment.trans_id = transactions.id;

delete from gl
 where exists (select *
                 from payment p where gl.id = p.trans_id);

alter table yearend
  drop constraint yearend_trans_id_fkey,
  -- the on delete cascade prevents deletion of approved lots (= transactions)
  add constraint yearend_trans_id_fkey foreign key (trans_id) references transactions(id) on delete cascade;

update transactions
   set table_name = 'yearend'
  from yearend
 where yearend.trans_id = transactions.id;

delete from gl
 where exists (select *
                 from yearend ye where gl.id = ye.trans_id);


-- based on 'gl', 'ar' and 'ap', but those lost their roles
drop view if exists file_tx_links cascade;


create or replace trigger gl_track_global_sequence before INSERT OR UPDATE on gl
  for each row execute procedure track_global_sequence('gl');
create or replace trigger ap_track_global_sequence before INSERT OR UPDATE on ap
  for each row execute procedure track_global_sequence('ap');
create or replace trigger ar_track_global_sequence before INSERT OR UPDATE on ar
  for each row execute procedure track_global_sequence('ar');

