


create function __create_fixed_asset_account() returns int
language plpgsql as $$
declare
    acc_id int;
begin
    insert into account ( accno, description, category, heading )
        values ( 'fa' || nextval('account_id_seq'), 'fixed asset account',
                 'A', (select id from account_heading
                        where accno = '000000000000000000000'))
    returning id into acc_id;

    insert into account_link (account_id, description)
    values (acc_id, 'Fixed_Asset');

    return acc_id;
end;
$$;

create function __create_asset_dep_account() returns int
language plpgsql as $$
declare
    acc_id int;
begin
    insert into account ( accno, description, category, heading, contra )
        values ( 'ad' || nextval('account_id_seq'), 'asset depreciation account',
                 'A', (select id from account_heading
                        where accno = '000000000000000000000'), 't')
    returning id into acc_id;

    insert into account_link (account_id, description)
    values (acc_id, 'Asset_Dep');

    return acc_id;
end;
$$;

create function __create_asset_exp_account() returns int
language plpgsql as $$
declare
    acc_id int;
begin
    insert into account ( accno, description, category, heading, contra )
        values ( 'ae' || nextval('account_id_seq'), 'asset expense',
                 'E', (select id from account_heading
                        where accno = '000000000000000000000'), 't')
    returning id into acc_id;

    insert into account_link (account_id, description)
    values (acc_id, 'asset_expense');

    return acc_id;
end;
$$;


create function __create_asset_loss_account() returns int
language plpgsql as $$
declare
    acc_id int;
begin
    insert into account ( accno, description, category, heading, contra )
        values ( 'al' || nextval('account_id_seq'), 'asset loss',
                 'E', (select id from account_heading
                        where accno = '000000000000000000000'), 't')
    returning id into acc_id;

    insert into account_link (account_id, description)
    values (acc_id, 'asset_loss');

    return acc_id;
end;
$$;


create function __create_asset_gain_account() returns int
language plpgsql as $$
declare
    acc_id int;
begin
    insert into account ( accno, description, category, heading, contra )
        values ( 'ag' || nextval('account_id_seq'), 'asset gain',
                 'I', (select id from account_heading
                        where accno = '000000000000000000000'), 't')
    returning id into acc_id;

    insert into account_link (account_id, description)
    values (acc_id, 'asset_gain');

    return acc_id;
end;
$$;


