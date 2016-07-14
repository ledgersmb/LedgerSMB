BEGIN;

ALTER TABLE public.open_forms ALTER COLUMN id SET DEFAULT floor(random()*(1000000))+1;
ALTER TABLE public.open_forms ADD COLUMN caller1 character varying(100);
ALTER TABLE public.open_forms ADD COLUMN caller2 character varying(100);
ALTER TABLE public.open_forms ADD COLUMN caller3 character varying(100);
ALTER TABLE public.open_forms ADD COLUMN caller4 character varying(100);
ALTER TABLE public.open_forms ADD COLUMN last_used timestamp without time zone;

COMMIT;
