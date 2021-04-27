
delete from voucher v
 where exists (select 1 from transactions t
                where not exists (select 1 from ap where t.id = ap.id)
                      and not exists (select 1 from ar where t.id = ar.id)
                      and not exists (select 1 from gl where t.id = gl.id)
                      and v.trans_id = t.id);

delete from invoice_tax_form itf
 where exists (select 1 from invoice i
                where itf.invoice_id = i.id
                      and exists (select 1 from transactions t
                                   where not exists (select 1 from ap where t.id = ap.id)
                                         and not exists (select 1 from ar where t.id = ar.id)
                                         and not exists (select 1 from gl where t.id = gl.id)
                                         and i.trans_id = t.id));

delete from invoice i
 where exists (select 1 from transactions t
                where not exists (select 1 from ap where t.id = ap.id)
                      and not exists (select 1 from ar where t.id = ar.id)
                      and not exists (select 1 from gl where t.id = gl.id)
                      and i.trans_id = t.id);

delete from transactions t
 where not exists (select 1 from ap where t.id = ap.id)
       and not exists (select 1 from ar where t.id = ar.id)
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
