CREATE TABLE tax_extended (
    account_id int references account(id),
    tx_id int references transactions(id),
    reference text not null,
    tax_basis numeric,
    rate numeric,
    tax_amount numeric,
    check (tax_amount = rate*tax_basis/100)
);

COMMENT ON TABLE tax_extended IS 
$$ This stores extended information for manual tax calculations.$$;

