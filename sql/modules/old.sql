

set client_min_messages = 'warning';


BEGIN;

--
-- Functions used in IR.pm
--

CREATE OR REPLACE FUNCTION avgcost(int) RETURNS FLOAT AS '

DECLARE

v_cost float;
v_qty float;
v_parts_id alias for $1;

BEGIN

  SELECT INTO v_cost, v_qty SUM(i.sellprice * i.qty), SUM(i.qty)
  FROM invoice i
  JOIN ap a ON (a.id = i.trans_id)
  WHERE i.parts_id = v_parts_id;

  IF v_cost IS NULL THEN
    v_cost := 0;
  END IF;

  IF NOT v_qty IS NULL THEN
    IF v_qty = 0 THEN
      v_cost := 0;
    ELSE
      v_cost := v_cost/v_qty;
    END IF;
  END IF;

RETURN v_cost;
END;
' language 'plpgsql';
-- end function
--


CREATE OR REPLACE FUNCTION lastcost(int) RETURNS FLOAT AS
$sql$
  DECLARE

  v_cost float;
  v_parts_id alias for $1;

BEGIN

  SELECT INTO v_cost sellprice
    FROM invoice i
           JOIN ap a ON (a.id = i.trans_id)
           JOIN transactions txn ON a.id = txn.id
   WHERE i.parts_id = v_parts_id
   ORDER BY txn.transdate desc, a.id desc
   LIMIT 1;

  IF v_cost IS NULL THEN
    v_cost := 0;
  END IF;

  RETURN v_cost;
END;
$sql$ language plpgsql;
-- end function
--


update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
