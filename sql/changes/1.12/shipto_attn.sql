
insert into contact_class (class)
  values ('Ship to Attn');

alter table ar
  add column shipto_attn text;

comment on column ar.shipto_attn is $$
  Stores "At the attention of" information for shipping. Can be used
  to print information on a person to contact about the shipment between
  the (company) recipient name and the actual address.
  $$;

alter table oe
  add column shipto_attn text;

comment on column oe.shipto_attn is $$
  Stores "At the attention of" information for shipping. Can be used
  to print information on a person to contact about the shipment between
  the (company) recipient name and the actual address.
  $$;

alter table ap
  add column shipto_attn text;

comment on column ap.shipto_attn is $$
  This column exists to make sure the 'ar' and 'ap' tables have the same
  columns and therefor can be accessed with the same queries (except for
  the table name...).
  $$;

