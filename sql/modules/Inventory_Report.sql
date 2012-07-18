BEGIN;

DROP TYPE IF EXISTS inventory_adjustment_line CASCADE;

CREATE TYPE inventory_adjustment_line AS (
    parts_id int,
    partnumber text,
    description text,
    counted  numeric,
    expected numeric,
    variance numeric
);


DROP TYPE IF EXISTS inventory_adjustment_info CASCADE;

CREATE TYPE inventory_adjustment_info AS (
   id int,
   transdate date,
   source text,
   ar_trans_id int,
   ap_trans_id int,
   ar_invnumber text,
   ap_invnumber text  
);

CREATE OR REPLACE FUNCTION inventory_adj__search
(in_from_date date, in_to_date date, in_partnumber text, in_source text)
RETURNS SETOF inventory_adjustment_info AS 
$$

   SELECT r.id, r.transdate, r.source, r.ar_trans_id, r.ap_trans_id,
          ar.invnumber, ap.invnumber
     FROM inventory_report r
     JOIN inventory_report_line l ON l.report_id = r.id 
     JOIN parts p ON l.parts_id = p.id
LEFT JOIN ar ON ar.id = r.ar_trans_id
LEFT JOIN ap ON ap.id = r.ap_trans_id
    WHERE ($1 is null or $1 <= r.transdate) AND
          ($2 is null OR $2 >= r.transdate) AND
          ($3 IS NULL OR plainto_tsquery($3) @@ tsvector(p.partnumber)) AND
          ($4 IS NULL OR source LIKE $4 || '%');
 
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION inventory_adj__get(in_id int)
RETURNS SETOF inventory_adjustment_info AS
$$

   SELECT r.id, r.transdate, r.source, r.ar_trans_id, r.ap_trans_id,
          ar.invnumber, ap.invnumber
     FROM inventory_report r
     JOIN inventory_report_line l ON l.report_id = r.id 
LEFT JOIN ar ON ar.id = r.ar_trans_id
LEFT JOIN ap ON ap.id = r.ap_trans_id
    WHERE r.id = $1;

$$ language SQL;

CREATE OR REPLACE FUNCTION inventory_adj__details(in_id int)
RETURNS SETOF inventory_adjustment_line AS
$$ 

   SELECT l.parts_id, p.partnumber, p.description, l.counted, l.expected, 
          l.counted - l.expected
     FROM inventory_report_line l
     JOIN parts p ON l.parts_id = p.id
    WHERE l.report_id = $1;

$$ language sql;

COMMIT;
