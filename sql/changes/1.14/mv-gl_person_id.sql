
update transactions txn
   set entered_by = gl.person_id
       from gl
 where txn.id = gl.id
   and gl.person_id is not null;

alter table gl
  drop column person_id;
