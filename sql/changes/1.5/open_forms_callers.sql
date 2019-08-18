BEGIN;

ALTER TABLE open_forms ALTER COLUMN id SET DEFAULT floor(random()*(1000000))+1;
ALTER TABLE open_forms ADD COLUMN form_name character varying(100);
ALTER TABLE open_forms ADD COLUMN last_used timestamp without time zone;

COMMIT;
