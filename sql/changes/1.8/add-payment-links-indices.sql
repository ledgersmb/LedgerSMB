

create index if not exists payment_links_entry_id_idx
       on payment_links (entry_id);
create index if not exists payment_links_payment_id_idx
       on payment_links (payment_id);
