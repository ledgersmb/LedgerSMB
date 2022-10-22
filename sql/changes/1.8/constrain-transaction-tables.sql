-- After manually adjusting ar, ap, and gl entries, try again to get the correct transaction dates.
UPDATE transactions AS trn
    SET transdate = (SELECT COALESCE(
                (select ar.transdate from ar where ar.id = trn.id),
                (select ap.transdate from ap where ap.id = trn.id),
                (select gl.transdate from gl where gl.id = trn.id),
                trn.approved_at
                ))
WHERE transdate IS NULL;

ALTER TABLE gl
ALTER COLUMN transdate SET NOT NULL,
ALTER COLUMN approved SET NOT NULL;

ALTER TABLE ar
ALTER COLUMN transdate SET NOT NULL,
ALTER COLUMN approved SET NOT NULL;

ALTER TABLE ap
ALTER COLUMN transdate SET NOT NULL,
ALTER COLUMN approved SET NOT NULL;

ALTER TABLE acc_trans
ALTER COLUMN transdate SET NOT NULL,
ALTER COLUMN approved SET NOT NULL;

ALTER TABLE transactions
ALTER COLUMN transdate SET NOT NULL,
ALTER COLUMN approved SET NOT NULL;

