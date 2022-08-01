

alter table cr_report_line
  -- drop columns that were never used (as far as I can tell)
  drop column overlook cascade,
  drop column errorcode,
  -- drop columns that were decommissioned in 1.8
  drop column ledger_id cascade,
  drop column voucher_id cascade;


alter table acc_trans
  -- delete columns which haven't been populated since 1.3
  drop column cleared_on,
  drop column reconciled_on;

