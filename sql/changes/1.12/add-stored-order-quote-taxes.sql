

create table oe_tax (
  oe_id int not null references oe (id),
  tax_id int not null references account (id),
  basis numeric not null,
  exempt smallint not null default 0,
  rate numeric,
  amount numeric,
  source text,
  primary key (oe_id, tax_id),
  check (exempt = 0 or (rate is null and amount is null)),
  check (exempt <> 0 or (rate is not null and amount is not null))
);

create table tax_exempt_reason (
  id serial not null primary key,
  description text
);

insert into tax_exempt_reason (id, description)
values (0, 'Not tax exempt'),
       (1, 'Tax exempt');

select setval('tax_exempt_reason_id_seq', 1);

comment on table tax_exempt_reason is
  $$ Contains a list of tax exempt reasons.
  Users may add reasons applicable to their jurisdictions.

  Values zero (0) and (1) are reserved to mean 'Not exempt'
  (zero) and 'Exempt, no reason given' (one).
  $$;

comment on table oe_tax is
  $$ Stores calculated applicable taxes for orders and quotes ('oe' table rows),
  one row for each applicable tax rate, with tax basis (sum of the applicable
  line totals) and rate.$$;

comment on column oe_tax.basis is
  $$ The amount this tax specification applies to.$$;

comment on column oe_tax.exempt is
  $$ Indicates whether the record specifies a taxable or non-taxable
  'basis'; zero (0) indicates non-exemption, any other value
  indicates being exempt. Currently only the value one (1) is in use,
  but other values may indicate the reason for exemption in the future.$$;

comment on column oe_tax.rate is
  $$ A number between zero (0) and one (1) specifying the applicable
  tax rate as a fraction.

  Must be NULL when 'exempt' is true. Otherwise:
  Optionally specifies an applicable rate, or NULL if unspecified.
  Must be specified if 'amount' is NULL.$$;

comment on column oe_tax.amount is
  $$ Must be NULL when 'exempt' is true. Otherwise:
  Specifies the tax amount of the specified tax applicable to the
  order. If 'rate' is specified, must equal 'rate*basis'. $$;

comment on column oe_tax.source is
  $$ May be used to store reference to an (external) tax calculation.$$;
