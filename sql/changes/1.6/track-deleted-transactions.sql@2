
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
