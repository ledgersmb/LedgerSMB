ALTER TABLE ar DROP CONSTRAINT IF EXISTS ar_invnumber_key;
ALTER TABLE ar ADD CHECK(invnumber IS NOT NULL OR NOT approved);
CREATE UNIQUE INDEX ar_invnumber_key_p ON ar(invnumber)
       WHERE invnumber IS NOT NULL;
