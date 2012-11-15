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
    account_category text,
    account_heading_id int,
    account_heading_number text,
    account_heading_description text,
    amount numeric
);

CREATE OR REPLACE FUNCTION pnl__product
(in_from_date date, in_to_date date, in_parts_id int, in_business_units int[])
RETURNS SETOF onl_line AS 
$$
WITH RECURSIVE bu_tree (id, parent) AS (
      SELECT id, null FROM business_unit
       WHERE id = any(in_business_units)
      UNION ALL
      SELECT id, parent 
        FROM business_unit bu
        JOIN bu_tree ON bu.parent = bu_tree.id
)
   SELECT a.id, a.accno, a.description, a.category, ah.id, ah.accno,
          ah.description, 
          ac.amount * -1 
     FROM account a
     JOIN account_heading ah on a.heading = ah.id
     JOIN acc_trans ac ON ac.chart_id = a.id
     JOIN invoice i ON i.id = ac.invoice_id
     JOIN account_link l ON l.account_id = a.id
     JOIN ar ON ar.id = ac.trans_id
    WHERE i.parts_id = $3
          AND (acc_trans.transdate >= $1 OR $1 IS NULL) 
          AND (acc_trans.transdate <= $2 OR $2 IS NULL)
          AND ar.approved
          AND l.description = 'IC_expense'
    UNION
   SELECT a.id, a.accno, a.description, a.category, ah.id, ah.accno,
          ah.description, 
          i.sellprice * i.qty * (1 - coalesce(i.disc, 0))
     FROM parts p
     JOIN invoice i ON i.id = p.id
     JOIN acc_trans ac ON ac.invoice_id = i.id
     JOIN account a ON p.income_accno_id = a.id
     JOIN ar ON ar.id = ac.trans_id
     JOIN account_heading ah on a.heading = ah.id
    WHERE i.parts_id = $3
          AND (acc_trans.transdate >= $1 OR $1 IS NULL) 
          AND (acc_trans.transdate <= $2 OR $2 IS NULL)
          AND ar.approved;
$$ language SQL;


CREATE OR REPLACE FUNCTION pnl__income_statement_accrual
(in_from_date date, in_to_date date, in_business_units int[])
RETURNS SETOF pnl_line AS
$$
WITH RECURSIVE bu_tree (id, parent) AS (
      SELECT id, null FROM business_unit
       WHERE id = any(in_business_units)
      UNION ALL
      SELECT id, parent 
        FROM business_unit bu
        JOIN bu_tree ON bu.parent = bu_tree.id
)
   SELECT a.id, a.accno, a.description, a.category, ah.id, ah.accno,
          ah.description, 
          CASE WHEN a.category = 'E' THEN -1 ELSE 1 END * sum(ac.amount)
     FROM account a
     JOIN acc_trans ac ON a.id = ac.chart_id AND ac.approved
     JOIN tx_report gl ON ac.trans_id = gl.id
LEFT JOIN (select array_agg(entry_id) 
             FROM business_unit_ac buac
             JOIN bu_tree ON bu_tree.id = buac.bu_id) bu 
          ON (ac.entry_id = any(b_unit_ids))
    WHERE ac.approved is true AND ac.transdate BETWEEN $1 AND $2
          AND (in_business_units = '{}' 
              OR in_business_units IS NULL OR ac.entry_id)
 GROUP BY a.id, a.accno, a.description, a.category, 
          ah.id, ah.accno, ah.description
 ORDER BY a.category DESC, a.accno ASC;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION pnl__income_statement_cash
(in_from_date date, in_to_date date, in_business_units int[])
RETURNS SETOF pnl_line AS
$$
WITH RECURSIVE bu_tree (id, parent) AS (
      SELECT id, null FROM business_unit
       WHERE id = any(in_business_units)
      UNION ALL
      SELECT id, parent 
        FROM business_unit bu
        JOIN bu_tree ON bu.parent = bu_tree.id
)
   SELECT a.id, a.accno, a.description, a.category, ah.id, ah.accno,
          ah.description, 
          CASE WHEN a.category = 'E' THEN -1 ELSE 1 END * sum(ac.amount) *
          ca.impact
     FROM account a
     JOIN acc_trans ac ON a.id = ac.chart_id AND ac.approved
     JOIN tx_report gl ON ac.trans_id = gl.id
     JOIN cash_impact ca ON gl.id = ca.id
LEFT JOIN (select array_agg(entry_id) 
             FROM business_unit_ac buac
             JOIN bu_tree ON bu_tree.id = buac.bu_id) bu 
          ON (ac.entry_id = any(b_unit_ids))
    WHERE ac.approved is true AND ac.transdate BETWEEN $1 AND $2
          AND (in_business_units = '{}' 
              OR in_business_units IS NULL OR ac.entry_id)
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
   SELECT id FROM ar approved is true AND entity_credit_account = $1
)
SELECT a.id, a.accno, a.description, a.category, 
       ah.id, ah.accno, ah.description,
       CASE WHEN a.category = 'E' THEN -1 ELSE 1 END * sum(ac.amount)
  FROM account a
  JOIN acc_trans ac ON a.id = ac.chart_id
  JOIN gl ON ac.trans_id = gl.id
 WHERE ac.approved is true AND ac.transdate BETWEEN $2 AND $3
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
  JOIN acc_trans ac ON a.id = ac.chart_id
 WHERE ac.approved is true AND ac.trans_id = $1
 GROUP BY a.id, a.accno, a.description, a.category, 
          ah.id, ah.accno, ah.description
 ORDER BY a.category DESC, a.accno ASC;
$$ LANGUAGE SQL;

COMMIT;
