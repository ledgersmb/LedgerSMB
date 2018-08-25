
alter table account_checkpoint
  add column amount_bc numeric,
  add column amount_tc numeric,
  add column curr char(3);

alter table journal_line
  add column amount_tc numeric,
  add column curr char(3);

alter table acc_trans
  add column amount_bc numeric,
  add column amount_tc numeric,
  add column amount numeric;

alter table ar
  add column amount_bc numeric,
  add column amount_tc numeric,
  add column netamount_bc numeric,
  add column netamount_tc numeric;

COMMENT ON COLUMN ar.amount_bc IS
$$ This stores the total amount (including taxes) for the transaction
in base currency.$$;

COMMENT ON COLUMN ar.netamount_bc IS
$$ Total amount excluding taxes for the transaction in base currency.$$;


alter table ap
  add column amount_bc numeric,
  add column amount_tc numeric,
  add column netamount_bc numeric,
  add column netamount_tc numeric;

COMMENT ON COLUMN ap.amount_bc IS
$$ This stores the total amount (including taxes) for the transaction
in base currency.$$;

COMMENT ON COLUMN ap.netamount_bc IS
$$ Total amount excluding taxes for the transaction in base currency.$$;


alter table budget_line
  add column amount_tc numeric,
  add column curr char(3);

