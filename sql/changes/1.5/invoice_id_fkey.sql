alter table acc_trans add foreign key (invoice_id) references invoice(id);
