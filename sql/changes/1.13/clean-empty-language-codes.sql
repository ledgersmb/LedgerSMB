-- Some very old databases have an empty string stored
-- rather than null where the language_code is unspecified.
-- An empty string is never a valid language code in lsmb,
-- as it gets interpreted as no language having been
-- defined or selected.

UPDATE ar SET language_code=NULL WHERE language_code='';
UPDATE ap SET language_code=NULL WHERE language_code='';
UPDATE oe SET language_code=NULL WHERE language_code='';

