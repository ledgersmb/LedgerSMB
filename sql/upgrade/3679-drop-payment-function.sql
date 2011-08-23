DROP FUNCTION payment_bulk_post
(in_transactions numeric[], in_batch_id int, in_source text, in_total numeric,
        in_ar_ap_accno text, in_cash_accno text,
        in_payment_date date, in_account_class int, in_payment_type int,
        in_exchangerate numeric, in_curr text);
