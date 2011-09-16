ALTER TABLE file_secondary_attachment 
    ADD PRIMARY KEY(file_id, source_class, dest_class, ref_key);

ALTER TABLE  file_tx_to_order
    ADD PRIMARY KEY(file_id, source_class, dest_class, ref_key);

ALTER TABLE file_order_to_order 
    ADD PRIMARY KEY(file_id, source_class, dest_class, ref_key);

ALTER TABLE file_order_to_tx
    ADD PRIMARY KEY(file_id, source_class, dest_class, ref_key);

