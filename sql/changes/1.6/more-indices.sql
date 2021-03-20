
create index acc_trans_trans_id_idx on acc_trans(trans_id);
create index acc_trans_invoice_id_idx on acc_trans(invoice_id);
create index acc_trans_chart_id_idx on acc_trans(chart_id);

create index ar_entity_credit_account_idx on ar(entity_credit_account);
create index ap_entity_credit_account_idx on ap(entity_credit_account);

create index invoice_cogs_idx on invoice(parts_id)
   where (qty + allocated < 0) OR (qty + allocated > 0);
create index invoice_parts_id_idx on invoice(parts_id);

create index voucher_trans_id_idx on voucher(trans_id);
create index voucher_batch_id_idx on voucher(batch_id);
