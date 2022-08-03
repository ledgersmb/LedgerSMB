
-- Since 'status' is an annotation table for 'transactions', when there's no
-- transaction by this number, we could just as well delete the status too
delete from status s
  where not exists (select 1 from transactions t where s.trans_id = t.id);

alter table status
  add constraint status_trans_id_fkey
     foreign key ( trans_id )
      references transactions ( id )
       on delete cascade;


-- when there's no 'partsgroup' record (which exists to partition the set of parts)
-- then there's no need to retain the 'partsgroup_id' as it's not partitioning that way.
update parts p
   set partsgroup_id = null
 where not exists (select 1 from partsgroup pg where p.partsgroup_id = pg.id);

alter table parts
  add constraint parts_partsgroup_id_fkey
     foreign key ( partsgroup_id )
      references partsgroup ( id );


-- even today, I can't find any references in old/ to anything called 'jctype',
-- so it's not a loss to remove references to data that doesn't exist and isn't used...
update jcitems i
   set jctype = null
 where not exists (select 1 from jctype t where i.jctype = t.id);

alter table jcitems
  add constraint jcitems_jctype_fkey
     foreign key ( jctype )
      references jctype ( id );


-- create the gifi records that should have existed, but don't.
insert into gifi ( accno, description )
select distinct gifi_accno, gifi_accno
  from account a
 where not exists (select 1 from gifi g
                    where g.accno = a.gifi_accno and a.gifi_accno is not null);

alter table account
  add constraint account_gifi_accno_fkey
     foreign key ( gifi_accno )
      references gifi ( accno );
