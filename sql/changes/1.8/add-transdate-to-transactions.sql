
ALTER TABLE transactions
   ADD COLUMN transdate date;

UPDATE transactions AS trn
   SET transdate = (SELECT COALESCE(
                (select ar.transdate from ar where ar.id = trn.id),
                (select ap.transdate from ap where ap.id = trn.id),
                (select gl.transdate from gl where gl.id = trn.id),
                trn.approved_at
                ));

