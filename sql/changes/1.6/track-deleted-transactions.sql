
delete from voucher v
 where exists (select 1 from transactions t
                where not exists (select 1 from ap where t.id = ap.id)
                      and not exists (select 1 from ar where t.id = ar.id)
                      and not exists (select 1 from gl where t.id = gl.id)
                      and v.trans_id = t.id);

delete from recurring r
 where exists (select 1 from transactions t
                where not exists (select 1 from ap where t.id = ap.id)
                      and not exists (select 1 from ar where t.id = ar.id)
                      and not exists (select 1 from gl where t.id = gl.id)
                      and r.id = t.id);

update new_shipto ns
   set trans_id = null
 where exists (select 1 from transactions t
                where not exists (select 1 from ap where t.id = ap.id)
                      and not exists (select 1 from ar where t.id = ar.id)
                      and not exists (select 1 from gl where t.id = gl.id)
                      and ns.trans_id = t.id);

delete from new_shipto
 where trans_id is null and oe_id is null;

delete from transactions t
 where not exists (select 1 from ap where t.id = ap.id)
       and not exists (select 1 from ar where t.id = ar.id)
       and not exists (select 1 from invoice where t.id = invoice.trans_id)
       and not exists (select 1 from gl where t.id = gl.id);


CREATE TRIGGER ap_track_deleted_transaction
  AFTER DELETE
  ON ap
  FOR EACH ROW
  EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER ar_track_deleted_transaction
  AFTER DELETE
  ON ar
  FOR EACH ROW
  EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER gl_track_deleted_transaction
  AFTER DELETE
  ON gl
  FOR EACH ROW
  EXECUTE PROCEDURE track_global_sequence();
