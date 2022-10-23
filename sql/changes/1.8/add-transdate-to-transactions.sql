

ALTER TABLE transactions
   ADD COLUMN transdate date;

UPDATE transactions AS trn
   SET transdate = (select ar.transdate from ar where ar.id = trn.id
                     union
                    select ap.transdate from ap where ap.id = trn.id
                     union
                    select gl.transdate from gl where gl.id = trn.id);

