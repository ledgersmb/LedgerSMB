-- Copyright 2012 The LedgerSMB Core Team.  This file may be re-used in 
-- accordance with the GNU GPL version 2 or at your option any later version.  
-- Please see your included LICENSE.txt for details

BEGIN;

-- This holds general PNL type report definitions.  The idea is to gather them
-- here so that they share as many common types as possible.  Note that PNL 
-- reports do not return total and summary lines.  These must be done by the 
-- application handling this. 

DROP TYPE IF EXISTS pnl_line CASCADE;
CREATE TYPE pnl_line AS (
    id int,
    accno text,
    description text,
    category char,
    is_heading boolean,
    amount numeric,
    heading_path text[]
);

CREATE OR REPLACE FUNCTION pnl__product
(in_from_date date, in_to_date date, in_parts_id int, in_business_units int[])
RETURNS SETOF pnl_line AS
$$
WITH RECURSIVE bu_tree (id, parent, path) AS (
      SELECT id, null, row(array[id])::tree_record FROM business_unit
       WHERE id = any($4)
      UNION ALL
      SELECT bu.id, parent, row((path).t || bu.id)::tree_record
        FROM business_unit bu
        JOIN bu_tree ON bu.parent_id = bu_tree.id
),
account_balance AS (
-- Note that this function only differs by the "account_balance" CTE;
-- the rest of the function is the same as the other functions in this file
   SELECT a.id, a.accno, a.description, a.category,
          sum(ac.amount) * -1 as amount, at.path, a.heading
     FROM account a
     JOIN account_heading ah on a.heading = ah.id
     JOIN acc_trans ac ON ac.chart_id = a.id
     JOIN invoice i ON i.id = ac.invoice_id
     JOIN account_link l ON l.account_id = a.id
     JOIN account_heading_tree at ON a.heading = at.id
     JOIN ar ON ar.id = ac.trans_id 
LEFT JOIN (select as_array(bu.path) as bu_ids, entry_id
             from business_unit_inv bui 
             JOIN bu_tree bu ON bui.bu_id = bu.id
         GROUP BY entry_id) bui ON bui.entry_id = i.id
    WHERE i.parts_id = $3
          AND (ac.transdate >= $1 OR $1 IS NULL) 
          AND (ac.transdate <= $2 OR $2 IS NULL)
          AND ar.approved
          AND l.description = 'IC_expense'
          AND ($4 is null or $4 = '{}' OR in_tree($4, bu_ids))
 GROUP BY a.id, a.accno, a.description, a.category, ah.id, ah.accno,
          ah.description, at.path
    UNION
   SELECT a.id, a.accno, a.description, a.category,
          sum(i.sellprice * i.qty * (1 - coalesce(i.discount, 0))) as amount,
          at.path, a.heading
     FROM parts p
     JOIN invoice i ON i.id = p.id
     JOIN acc_trans ac ON ac.invoice_id = i.id
     JOIN account a ON p.income_accno_id = a.id
     JOIN ar ON ar.id = ac.trans_id
     JOIN account_heading_tree at ON a.heading = at.id
     JOIN account_heading ah on a.heading = ah.id
LEFT JOIN (select as_array(bu.path) as bu_ids, entry_id
             from business_unit_inv bui 
             JOIN bu_tree bu ON bui.bu_id = bu.id
         GROUP BY entry_id) bui ON bui.entry_id = i.id
    WHERE i.parts_id = $3
          AND (ac.transdate >= $1 OR $1 IS NULL) 
          AND (ac.transdate <= $2 OR $2 IS NULL)
          AND ar.approved
          AND ($4 is null or $4 = '{}' OR in_tree($4, bu_ids))
 GROUP BY a.id, a.accno, a.description, a.category, at.path, a.heading
),
merged AS (
SELECT *, 'f'::boolean as is_heading
  FROM account_balance
UNION
SELECT aht.id, aht.accno, ahc.description as description,
       ahc.category as category, sum(ab.amount) as amount,
       aht.path, null as heading, 't'::boolean as is_heading
  FROM account_balance ab
INNER JOIN account_heading_descendant ahd
        ON ab.heading = ahd.descendant_id
INNER JOIN account_heading_tree aht
       ON ahd.id = aht.id
INNER JOIN account_heading_derived_category ahc
        ON aht.id = ahc.id
GROUP BY aht.id, aht.accno, aht.path, ahc.description, ahc.category
)
   SELECT id, accno, description, category, is_heading,
          CASE WHEN category = 'E' THEN -1 ELSE 1 END * amount, path
     FROM  merged
ORDER BY array_to_string(path, '||||'), accno ASC;
$$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION pnl__income_statement_accrual(
       in_from_date date, in_to_date date, in_ignore_yearend text,
       in_business_units integer[])
RETURNS SETOF pnl_line AS
$$
WITH RECURSIVE bu_tree (id, parent, path) AS (
      SELECT id, null, row(array[id])::tree_record FROM business_unit
       WHERE id = any($4)
      UNION ALL
      SELECT bu.id, parent, row((path).t || bu.id)::tree_record
        FROM business_unit bu
        JOIN bu_tree ON bu.parent_id = bu_tree.id
),
account_balance AS (
-- Note that this function only differs by the "account_balance" CTE;
-- the rest of the function is the same as the other functions in this file
   SELECT a.id, a.accno, a.description, a.category,
          sum(ac.amount) as amount, 
          at.path, a.heading
     FROM account a
     JOIN acc_trans ac ON a.id = ac.chart_id AND ac.approved
     JOIN tx_report gl ON ac.trans_id = gl.id AND gl.approved
     JOIN account_heading_tree at ON a.heading = at.id
LEFT JOIN (select array_agg(path) as bu_ids, entry_id
             FROM business_unit_ac buac
             JOIN bu_tree ON bu_tree.id = buac.bu_id
        GROUP BY buac.entry_id) bu
          ON (ac.entry_id = bu.entry_id)
    WHERE ac.approved is true 
          AND ($1 IS NULL OR ac.transdate >= $1) 
          AND ($2 IS NULL OR ac.transdate <= $2)
          AND ($4 = '{}' 
              OR $4 is null or in_tree($4, bu_ids))
          AND a.category IN ('I', 'E')
          AND ($3 = 'none' 
               OR ($3 = 'all' 
                   AND NOT EXISTS (SELECT * FROM yearend
                                    WHERE trans_id = gl.id))
               OR ($3 = 'last'
                   AND NOT EXISTS (SELECT 1 FROM yearend 
                                   HAVING max(trans_id) = gl.id)))
 GROUP BY a.id, a.accno, a.description, a.category, 
          at.path
),
merged AS (
SELECT *, 'f'::boolean as is_heading
  FROM account_balance
UNION
SELECT aht.id, aht.accno, ahc.description as description,
       ahc.category as category, sum(ab.amount) as amount,
       aht.path, null as heading, 't'::boolean as is_heading
  FROM account_balance ab
INNER JOIN account_heading_descendant ahd
        ON ab.heading = ahd.descendant_id
INNER JOIN account_heading_tree aht
       ON ahd.id = aht.id
INNER JOIN account_heading_derived_category ahc
        ON aht.id = ahc.id
GROUP BY aht.id, aht.accno, aht.path, ahc.description, ahc.category
)
   SELECT id, accno, description, category, is_heading,
          CASE WHEN category = 'E' THEN -1 ELSE 1 END * amount, path
     FROM  merged
   ORDER BY array_to_string(path, '||||'), accno ASC;
$$ LANGUAGE sql;


COMMENT ON FUNCTION pnl__income_statement_accrual(
       in_from_date date, in_to_date date, in_ignore_yearend text,
       in_business_units integer[]) IS $$ Returns a set of lines that
together make up a PNL. Returned lines contain both accounts and
headings with their associated subtotals. Amounts have been
sign-converted to present both income and expenses as positive amounts.

Allowable values for 'ignore_yearend' parameter are:
 * 'none'
 * 'last'
 * 'all'
$$;


CREATE OR REPLACE FUNCTION pnl__income_statement_cash
(in_from_date date, in_to_date date, in_ignore_yearend text, 
in_business_units int[])
RETURNS SETOF pnl_line AS
$$
WITH RECURSIVE bu_tree (id, parent, path) AS (
      SELECT id, null, row(array[id])::tree_record FROM business_unit
       WHERE id = any($4)
      UNION ALL
      SELECT bu.id, parent, row((path).t || bu.id)::tree_record
        FROM business_unit bu
        JOIN bu_tree ON bu.parent_id = bu_tree.id
),
account_balance AS (
-- Note that this function only differs by the "account_balance" CTE;
-- the rest of the function is the same as the other functions in this file
   SELECT a.id, a.accno, a.description, a.category, 
          CASE WHEN a.category = 'E' THEN -1 ELSE 1 END 
               * sum(ac.amount * ca.portion) as amount,
          at.path, a.heading
     FROM account a
     JOIN account_heading ah on a.heading = ah.id
     JOIN acc_trans ac ON a.id = ac.chart_id AND ac.approved
     JOIN tx_report gl ON ac.trans_id = gl.id AND gl.approved
     JOIN account_heading_tree at ON a.heading = at.id
     JOIN (SELECT id, sum(portion) as portion
             FROM cash_impact ca 
            WHERE ($1 IS NULL OR ca.transdate >= $1)
                  AND ($2 IS NULL OR ca.transdate <= $2)
           GROUP BY id
          ) ca ON gl.id = ca.id 
LEFT JOIN (select array_agg(path) as bu_ids, entry_id
             FROM business_unit_ac buac
             JOIN bu_tree ON bu_tree.id = buac.bu_id
         GROUP BY entry_id) bu 
          ON (ac.entry_id = bu.entry_id)
    WHERE ac.approved is true 
          AND ($4 = '{}' 
              OR $4 is null or in_tree($4, bu_ids))
          AND a.category IN ('I', 'E')
          AND ($3 = 'none' 
               OR ($3 = 'all' 
                   AND NOT EXISTS (SELECT * FROM yearend WHERE trans_id = gl.id
                   ))
               OR ($3 = 'last'
                   AND NOT EXISTS (SELECT 1 FROM yearend 
                                   HAVING max(trans_id) = gl.id))
              )
 GROUP BY a.id, a.accno, a.description, a.category, at.path, a.heading),
merged AS (
SELECT *, 'f'::boolean as is_heading
  FROM account_balance
UNION
SELECT aht.id, aht.accno, ahc.description as description,
       ahc.category as category, sum(ab.amount) as amount,
       aht.path, null as heading, 't'::boolean as is_heading
  FROM account_balance ab
INNER JOIN account_heading_descendant ahd
        ON ab.heading = ahd.descendant_id
INNER JOIN account_heading_tree aht
       ON ahd.id = aht.id
INNER JOIN account_heading_derived_category ahc
        ON aht.id = ahc.id
GROUP BY aht.id, aht.accno, aht.path, ahc.description, ahc.category
)
   SELECT id, accno, description, category, is_heading,
          CASE WHEN category = 'E' THEN -1 ELSE 1 END * amount, path
     FROM  merged
ORDER BY array_to_string(path, '||||'), accno ASC;
$$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION pnl__invoice(in_id int) RETURNS SETOF pnl_line AS
$$
WITH account_balance AS (
-- Note that this function only differs by the "account_balance" CTE;
-- the rest of the function is the same as the other functions in this file
SELECT a.id, a.accno, a.description, a.category,
       CASE WHEN a.category = 'E' THEN -1 ELSE 1 END * sum(ac.amount) as amount,
       at.path, a.heading
  FROM account a
  JOIN account_heading ah on a.heading = ah.id
  JOIN acc_trans ac ON a.id = ac.chart_id
  JOIN account_heading_tree at ON a.heading = at.id
  JOIN account_heading_descendant ahd ON at.id = ahd.id
 WHERE ac.approved is true and ac.trans_id = $1
       and a.category in ('I', 'E')
 GROUP BY a.id, a.accno, a.description, a.category, 
          at.path, a.heading),
merged AS (
SELECT *, 'f'::boolean as is_heading
  FROM account_balance
UNION
SELECT aht.id, aht.accno, ahc.description as description,
       ahc.category as category, sum(ab.amount) as amount,
       aht.path, null as heading, 't'::boolean as is_heading
  FROM account_balance ab
INNER JOIN account_heading_descendant ahd
        ON ab.heading = ahd.descendant_id
INNER JOIN account_heading_tree aht
       ON ahd.id = aht.id
INNER JOIN account_heading_derived_category ahc
        ON aht.id = ahc.id
GROUP BY aht.id, aht.accno, aht.path, ahc.description, ahc.category
)
   SELECT id, accno, description, category, is_heading,
          CASE WHEN category = 'E' THEN -1 ELSE 1 END * amount, path
     FROM  merged
   ORDER BY array_to_string(path, '||||'), accno ASC;
$$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION pnl__customer
(in_id int, in_from_date date, in_to_date date)
RETURNS SETOF pnl_line AS
$$
WITH account_balance AS (
-- Note that this function only differs by the "account_balance" CTE;
-- the rest of the function is the same as the other functions in this file
  WITH gl (id) AS (
     SELECT id FROM ap WHERE approved is true AND entity_credit_account = $1
     UNION ALL
     SELECT id FROM ar WHERE approved is true AND entity_credit_account = $1
   )
   SELECT a.id, a.accno, a.description, a.category, 
       CASE WHEN a.category = 'E' THEN -1 ELSE 1 END * sum(ac.amount) as amount,
       at.path, a.heading
     FROM account a
     JOIN account_heading ah on a.heading = ah.id
     JOIN acc_trans ac ON a.id = ac.chart_id
     JOIN account_heading_tree at ON a.heading = at.id
     JOIN gl ON ac.trans_id = gl.id
    WHERE ac.approved is true 
          AND ($2 IS NULL OR ac.transdate >= $2) 
          AND ($3 IS NULL OR ac.transdate <= $3)
          AND a.category IN ('I', 'E')
   GROUP BY a.id, a.accno, a.description, a.category, at.path, a.heading),
merged AS (
SELECT *, 'f'::boolean as is_heading
  FROM account_balance
UNION
SELECT aht.id, aht.accno, ahc.description as description,
       ahc.category as category, sum(ab.amount) as amount,
       aht.path, null as heading, 't'::boolean as is_heading
  FROM account_balance ab
INNER JOIN account_heading_descendant ahd
        ON ab.heading = ahd.descendant_id
INNER JOIN account_heading_tree aht
       ON ahd.id = aht.id
INNER JOIN account_heading_derived_category ahc
        ON aht.id = ahc.id
GROUP BY aht.id, aht.accno, aht.path, ahc.description, ahc.category
)
   SELECT id, accno, description, category, is_heading,
          CASE WHEN category = 'E' THEN -1 ELSE 1 END * amount, path
     FROM  merged
   ORDER BY array_to_string(path, '||||'), accno ASC;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION pnl__invoice(in_id int) RETURNS SETOF pnl_line AS
$$
SELECT a.id, a.accno, a.description, a.category, 
       ah.id, ah.accno, ah.description,
       CASE WHEN a.category = 'E' THEN -1 ELSE 1 END * sum(ac.amount), at.path
  FROM account a
  JOIN account_heading ah on a.heading = ah.id
  JOIN acc_trans ac ON a.id = ac.chart_id
  JOIN account_heading_tree at ON a.heading = at.id
 WHERE ac.approved AND ac.trans_id = $1 AND a.category IN ('I', 'E')
 GROUP BY a.id, a.accno, a.description, a.category, 
          ah.id, ah.accno, ah.description, at.path
 ORDER BY a.category DESC, a.accno ASC;
$$ LANGUAGE SQL;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
