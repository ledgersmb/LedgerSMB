BEGIN;

DROP TYPE IF EXISTS inventory_adjustment_line CASCADE;

CREATE TYPE inventory_adjustment_line AS (
    parts_id int,
    partnumber text,
    description text,
    counted  numeric,
    expected numeric,
    variance numeric,
    sellprice numeric,
    lastcost numeric
);

CREATE OR REPLACE FUNCTION inventory_report__approve
(in_id int, in_ar_trans_id int, in_ap_trans_id int)
RETURNS int LANGUAGE SQL AS
$$
update inventory_report
   SET ar_trans_id = $2, ap_trans_id = $3
 WHERE id = $1 AND ar_trans_id IS NULL AND ap_trans_id IS NULL
RETURNING id;
$$;

CREATE OR REPLACE FUNCTION inventory_report__delete(in_id int)
RETURNS int LANGUAGE SQL AS
$$
DELETE FROM inventory_report_line WHERE adjust_id = $1;
DELETE FROM inventory_report WHERE id = $1
RETURNING id;
$$;

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
     JOIN inventory_report_line l ON l.adjust_id = r.id
     JOIN parts p ON l.parts_id = p.id
LEFT JOIN ar ON ar.id = r.ar_trans_id
LEFT JOIN ap ON ap.id = r.ap_trans_id
    WHERE ($1 is null or $1 <= r.transdate) AND
          ($2 is null OR $2 >= r.transdate) AND
          ($3 IS NULL OR plainto_tsquery($3) @@ tsvector(p.partnumber)) AND
          ($4 IS NULL OR source LIKE $4 || '%')
 GROUP BY r.id, r.transdate, r.source, r.ar_trans_id, r.ap_trans_id,
          ar.invnumber, ap.invnumber
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION inventory_adj__get(in_id int)
RETURNS inventory_adjustment_info AS
$$

   SELECT r.id, r.transdate, r.source, r.ar_trans_id, r.ap_trans_id,
          ar.invnumber, ap.invnumber
     FROM inventory_report r
     JOIN inventory_report_line l ON l.adjust_id = r.id
LEFT JOIN ar ON ar.id = r.ar_trans_id
LEFT JOIN ap ON ap.id = r.ap_trans_id
    WHERE r.id = $1;

$$ language SQL;

CREATE OR REPLACE FUNCTION inventory_adj__details(in_id int)
RETURNS SETOF inventory_adjustment_line AS
$$

   SELECT l.parts_id, p.partnumber, p.description, l.counted, l.expected,
          l.counted - l.expected, p.sellprice, p.lastcost
     FROM inventory_report_line l
     JOIN parts p ON l.parts_id = p.id
    WHERE l.adjust_id = $1;

$$ language sql;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
