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
    account_id int,
    account_number text,
    account_description text,
    account_category char,
    account_heading_id int,
    account_heading_number text,
    account_heading_description text,
    amount numeric
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
)
   SELECT a.id, a.accno, a.description, a.category, ah.id, ah.accno,
          ah.description, 
          sum(ac.amount) * -1 
     FROM account a
     JOIN account_heading ah on a.heading = ah.id
     JOIN acc_trans ac ON ac.chart_id = a.id
     JOIN invoice i ON i.id = ac.invoice_id
     JOIN account_link l ON l.account_id = a.id
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
          ah.description
    UNION
   SELECT a.id, a.accno, a.description, a.category, ah.id, ah.accno,
          ah.description, 
          sum(i.sellprice * i.qty * (1 - coalesce(i.discount, 0)))
     FROM parts p
     JOIN invoice i ON i.id = p.id
     JOIN acc_trans ac ON ac.invoice_id = i.id
     JOIN account a ON p.income_accno_id = a.id
     JOIN ar ON ar.id = ac.trans_id
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
 GROUP BY a.id, a.accno, a.description, a.category, ah.id, ah.accno,
          ah.description
$$ language SQL;


CREATE OR REPLACE FUNCTION pnl__income_statement_accrual
(in_from_date date, in_to_date date, in_business_units int[])
RETURNS SETOF pnl_line AS
$$
WITH RECURSIVE bu_tree (id, parent, path) AS (
      SELECT id, null, row(array[id])::tree_record FROM business_unit
       WHERE id = any($3)
      UNION ALL
      SELECT bu.id, parent, row((path).t || bu.id)::tree_record
        FROM business_unit bu
        JOIN bu_tree ON bu.parent_id = bu_tree.id
)
   SELECT a.id, a.accno, a.description, a.category, ah.id, ah.accno,
          ah.description, 
          CASE WHEN a.category = 'E' THEN -1 ELSE 1 END * sum(ac.amount)
     FROM account a
     JOIN account_heading ah on a.heading = ah.id
     JOIN acc_trans ac ON a.id = ac.chart_id AND ac.approved
     JOIN tx_report gl ON ac.trans_id = gl.id
LEFT JOIN (select array_agg(path) as bu_ids, entry_id
             FROM business_unit_ac buac
             JOIN bu_tree ON bu_tree.id = buac.bu_id
        GROUP BY buac.entry_id) bu
          ON (ac.entry_id = bu.entry_id)
    WHERE ac.approved is true 
          AND ($1 IS NULL OR ac.transdate >= $1) 
          AND ($2 IS NULL OR ac.transdate <= $2)
          AND ($3 = '{}' 
              OR $3 is null or in_tree($3, bu_ids))
          AND a.category IN ('I', 'E')
 GROUP BY a.id, a.accno, a.description, a.category, 
          ah.id, ah.accno, ah.description
 ORDER BY a.category DESC, a.accno ASC;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION pnl__income_statement_cash
(in_from_date date, in_to_date date, in_business_units int[])
RETURNS SETOF pnl_line AS
$$
WITH RECURSIVE bu_tree (id, parent, path) AS (
      SELECT id, null, row(array[id])::tree_record FROM business_unit
       WHERE id = any($3)
      UNION ALL
      SELECT bu.id, parent, row((path).t || bu.id)::tree_record
        FROM business_unit bu
        JOIN bu_tree ON bu.parent_id = bu_tree.id
)
   SELECT a.id, a.accno, a.description, a.category, ah.id, ah.accno,
          ah.description, 
          CASE WHEN a.category = 'E' THEN -1 ELSE 1 END 
               * sum(ac.amount * ca.portion)
     FROM account a
     JOIN account_heading ah on a.heading = ah.id
     JOIN acc_trans ac ON a.id = ac.chart_id AND ac.approved
     JOIN tx_report gl ON ac.trans_id = gl.id
     JOIN cash_impact ca ON gl.id = ca.id
LEFT JOIN (select array_agg(path) as bu_ids, entry_id
             FROM business_unit_ac buac
             JOIN bu_tree ON bu_tree.id = buac.bu_id
         GROUP BY entry_id) bu 
          ON (ac.entry_id = bu.entry_id)
    WHERE ac.approved is true 
          AND ($3 = '{}' 
              OR $3 is null or in_tree($3, bu_ids))
          AND ($1 IS NULL OR ac.transdate >= $1) 
          AND ($2 IS NULL OR ac.transdate <= $2)
          AND a.category IN ('I', 'E')
 GROUP BY a.id, a.accno, a.description, a.category, 
          ah.id, ah.accno, ah.description
 ORDER BY a.category DESC, a.accno ASC;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION pnl__invoice(in_id int) RETURNS SETOF pnl_line AS
$$
SELECT a.id, a.accno, a.description, a.category, 
       ah.id, ah.accno, ah.description,
       CASE WHEN a.category = 'E' THEN -1 ELSE 1 END * sum(ac.amount)
  FROM account a
  JOIN account_heading ah on a.heading = ah.id
  JOIN acc_trans ac ON a.id = ac.chart_id
 WHERE ac.approved is true and ac.trans_id = $1
 GROUP BY a.id, a.accno, a.description, a.category, 
          ah.id, ah.accno, ah.description
 ORDER BY a.category DESC, a.accno ASC;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION pnl__customer
(in_id int, in_from_date date, in_to_date date)
RETURNS SETOF pnl_line AS
$$
WITH gl (id) AS
 ( SELECT id FROM ap WHERE approved is true AND entity_credit_account = $1
UNION ALL
   SELECT id FROM ar WHERE approved is true AND entity_credit_account = $1
)
SELECT a.id, a.accno, a.description, a.category, 
       ah.id, ah.accno, ah.description,
       CASE WHEN a.category = 'E' THEN -1 ELSE 1 END * sum(ac.amount)
  FROM account a
  JOIN account_heading ah on a.heading = ah.id
  JOIN acc_trans ac ON a.id = ac.chart_id
  JOIN gl ON ac.trans_id = gl.id
 WHERE ac.approved is true 
          AND ($2 IS NULL OR ac.transdate >= $2) 
          AND ($3 IS NULL OR ac.transdate <= $3)
          AND a.category IN ('I', 'E')
 GROUP BY a.id, a.accno, a.description, a.category, 
          ah.id, ah.accno, ah.description
 ORDER BY a.category DESC, a.accno ASC;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION pnl__invoice(in_id int) RETURNS SETOF pnl_line AS
$$
SELECT a.id, a.accno, a.description, a.category, 
       ah.id, ah.accno, ah.description,
       CASE WHEN a.category = 'E' THEN -1 ELSE 1 END * sum(ac.amount)
  FROM account a
  JOIN account_heading ah on a.heading = ah.id
  JOIN acc_trans ac ON a.id = ac.chart_id
 WHERE ac.approved AND ac.trans_id = $1 AND a.category IN ('I', 'E')
 GROUP BY a.id, a.accno, a.description, a.category, 
          ah.id, ah.accno, ah.description
 ORDER BY a.category DESC, a.accno ASC;
$$ LANGUAGE SQL;

COMMIT;
