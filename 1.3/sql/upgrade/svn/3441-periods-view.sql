
CREATE OR REPLACE VIEW periods AS
SELECT 'ytd' as id, 'Year to Date' as label, now()::date as date_to, 
       (extract('year' from now())::text || '-01-01')::date as date_from
UNION
SELECT 'last_year', 'Last Year', 
       ((extract('YEAR' from now()) - 1)::text || '-12-31')::date as date_to,
       ((extract('YEAR' from now()) - 1)::text || '-01-01')::date as date_from
;

GRANT SELECT ON periods TO public;

