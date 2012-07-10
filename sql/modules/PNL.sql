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

CREATE OR REPLACE FUNCTION pnl__customer(in_id int) RETURNS SETOF pnl_line AS
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
 WHERE ac.approved is true
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
