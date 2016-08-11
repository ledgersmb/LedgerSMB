update acc_trans
   set invoice_id = null
 WHERE invoice_id NOT IN (select id from invoice);
