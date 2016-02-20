ALTER TABLE ar DROP CONSTRAINT ar_invnumber_key;
ALTER TABLE ar ADD CHECK(invnumber is not null OR not approved);
CREATE UNIQUE INDEX ar_invnumber_key_p ON ar(invnumber) where invnumber is not null;
