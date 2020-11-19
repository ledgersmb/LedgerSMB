

ALTER TABLE transactions
   ADD COLUMN transdate date;

UPDATE transactions AS trn
   SET transdate = (select ar.transdate from ar where ar.id = trn.id
                     union
                    select ap.transdate from ap where ap.id = trn.id
                     union
                    select gl.transdate from gl where gl.id = trn.id);

DROP TRIGGER ar_track_global_sequence ON ar;
DROP TRIGGER ap_track_global_sequence ON ap;
DROP TRIGGER gl_track_global_sequence ON gl;

CREATE OR REPLACE FUNCTION track_global_sequence()
  RETURNS trigger AS
$BODY$
BEGIN
        IF tg_op = 'INSERT' THEN
                INSERT INTO transactions (id, table_name, transdate, approved)
                VALUES (new.id, TG_RELNAME, new.transdate, new.approved);
        ELSEIF tg_op = 'UPDATE' THEN
                IF new.id = old.id
                   AND new.approved  = old.approved
                   AND new.transdate = old.transdate THEN
                        return new;
                ELSE
                        UPDATE transactions SET id = new.id,
                                                approved = new.approved,
                                                transdate = new.transdate
                         WHERE id = old.id;
                END IF;
        ELSE
                DELETE FROM transactions WHERE id = old.id;
        END IF;
        RETURN new;
END;
$BODY$
  LANGUAGE plpgsql;

COMMENT ON FUNCTION track_global_sequence() IS
' This trigger is used to track the id sequence entries across the
transactions table, and with the ar, ap, and gl tables.  This is necessary
because these have not been properly refactored yet.
';


CREATE TRIGGER ap_track_global_sequence
  BEFORE INSERT OR UPDATE
  ON ap
  FOR EACH ROW
  EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER ar_track_global_sequence
  BEFORE INSERT OR UPDATE
  ON ar
  FOR EACH ROW
  EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER gl_track_global_sequence
  BEFORE INSERT OR UPDATE
  ON gl
  FOR EACH ROW
  EXECUTE PROCEDURE track_global_sequence();
