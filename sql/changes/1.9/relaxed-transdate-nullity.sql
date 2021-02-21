
ALTER TABLE transactions ALTER COLUMN transdate DROP NOT NULL;
ALTER TABLE ar ALTER COLUMN transdate DROP NOT NULL;
ALTER TABLE ap ALTER COLUMN transdate DROP NOT NULL;
ALTER TABLE acc_trans ALTER COLUMN transdate DROP NOT NULL;


ALTER TABLE transactions ADD CONSTRAINT transdate_nullity
      CHECK (not approved or transdate is not null);
ALTER TABLE ar ADD CONSTRAINT transdate_nullity
      CHECK (not approved or transdate is not null);
ALTER TABLE ap ADD CONSTRAINT transdate_nullity
      CHECK (not approved or transdate is not null);
ALTER TABLE acc_trans ADD CONSTRAINT transdate_nullity
      CHECK (not approved or transdate is not null);

