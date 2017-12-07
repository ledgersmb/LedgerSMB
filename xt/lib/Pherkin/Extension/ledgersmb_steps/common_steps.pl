#!perl


use strict;
use warnings;

use LedgerSMB::IR;
use LedgerSMB::Form;
use LedgerSMB::DBObject::Account;

use LedgerSMB::Entity::Company;
use LedgerSMB::Entity::Credit_Account;

use Test::More;
use Test::BDD::Cucumber::StepFile;


my $company_seq = 0;

Given qr/a (fresh )?standard test company/, sub {
    my $fresh_required = $1;

    S->{ext_lsmb}->ensure_template;

    if (! S->{"the company"} || $fresh_required) {
        my $company = "standard-" . $company_seq++;
        S->{ext_lsmb}->create_from_template($company);
    }
};

Given qr/(a nonexistent|an existing) company named "(.*)"/, sub {
    my $company = $2;
    S->{"the company"} = $company;
    S->{"nonexistent company"} = ($1 eq 'a nonexistent');

    S->{ext_lsmb}->ensure_nonexisting_company($company)
        if S->{'nonexistent company'};
};

Given qr/(a nonexistent|an existing) user named "(.*)"/, sub {
    my $role = $2;
    S->{"the user"} = $role;
    S->{'nonexistent user'} = ($1 eq 'a nonexistent');

    S->{ext_lsmb}->ensure_nonexisting_user($role)
        if S->{'nonexistent user'};
};

Given qr/books closed as per (.{10})/, sub {
    my $closing_date = $1;

    my $dbh = S->{ext_lsmb}->admin_dbh;
    $dbh->do("SELECT eoy_reopen_books_at(?)", {}, $closing_date)
        or die $dbh->errstr;
    $dbh->do("SELECT eoy_create_checkpoint(?)", {}, $closing_date)
        or die $dbh->errstr;
};

Then qr/I can't post a transaction on (.{10})/, sub {
    my $posting_date = $1;

    S->{ext_lsmb}->assert_closed_posting_date($posting_date);
};

Given qr/the following GL transaction posted on (.{10})/, sub {
    S->{ext_lsmb}->post_transaction($1, C->data);
};

When qr/I post the following GL transaction on (.{10})/, sub {
    S->{ext_lsmb}->post_transaction($1, C->data);
};

Given qr/a logged in user with '(.*)' rights/, sub {
    my $role = $1;

    my $emp = S->{ext_lsmb}->create_employee;
    my $user = S->{ext_lsmb}->create_user(
        entity_id => $emp->entity_id,
        password => 'password123'
    );

    S->{"the user"} = $user->username;
    S->{"the password"} = 'password123';

    my @roles =
        grep { $_ eq $role }
        map { $_->{rolname} }
        @{$user->list_roles};
    is(scalar @roles, 1, "The requested role ($role) exists");
    $user->save_roles(\@roles);

    PageObject::App::Login->open(S->{ext_wsl});
    S->{ext_wsl}->page->body->login(
        user => S->{"the user"},
        password => S->{"the password"},
        company => S->{"the company"});
};

Given qr/a logged in user with these rights:/, sub {
    my $emp = S->{ext_lsmb}->create_employee;
    my $user = S->{ext_lsmb}->create_user(
        entity_id => $emp->entity_id,
        password => 'password123'
    );
    S->{"the user"} = $user->username;
    S->{"the password"} = 'password123';

    my %roles = map { $_->{role} => 1 } @{C->data};
    my @roles =
        grep { $roles{$_} }
        map { $_->{rolname} }
        @{$user->list_roles};
    is(scalar @roles, scalar @{C->data},
       'The requested roles have not all been found to be available');
    $user->save_roles(\@roles);

    PageObject::App::Login->open(S->{ext_wsl});
    S->{ext_wsl}->page->body->login(
        user => S->{"the user"},
        password => S->{"the password"},
        company => S->{"the company"});
};


my $entity_counter = 0;
my $vendor_counter = 0;
my $customer_counter = 0;

Given qr/a vendor '(.*)'$/, sub {
    my $vendor_name = $1;
    my $control_code = 'V-' . ($vendor_counter++);
    my $admin_dbh = S->{ext_lsmb}->admin_dbh;
    my $company = LedgerSMB::Entity::Company->new(
        country_id => 1,
        control_code => $control_code,
        legal_name => $vendor_name,
        name => $vendor_name,
        entity_class => 1,
        _dbh => $admin_dbh,
        );
    $company = $company->save;

    local $LedgerSMB::App_State::DBH = $admin_dbh;
    my @accounts = LedgerSMB::DBObject::Account->new()->list();
    my %accno_ids = map { $_->{accno} => $_->{id} } @accounts;

    my $vendor = LedgerSMB::Entity::Credit_Account->new(
        entity_id => $company->entity_id,
        entity_class => 1,
        _dbh => $admin_dbh,
        ar_ap_account_id => $accno_ids{'2100'},
        meta_number => $vendor_name,
        );
    $vendor->save;
};

my $part_count = 0;

my %part_props = (
    inventory_accno => '1510',
    income_accno => '4010',
    expense_accno => '5010',
    );

Given qr/a part with these properties:$/, sub {
    my %props = map { $_->{name} => $_->{value} } @{C->data};
    my %total_props = (%part_props, %props);

    local $LedgerSMB::App_State::DBH = S->{ext_lsmb}->admin_dbh;
    my @accounts = LedgerSMB::DBObject::Account->new()->list();
    my %accno_ids = map { $_->{accno} => $_->{id} } @accounts;

    $total_props{partnumber} //= 'P-' . ($part_count++);
    my $dbh = S->{ext_lsmb}->admin_dbh;
    my @keys;
    my @values;
    my @placeholders;

    $total_props{$_} = $accno_ids{$total_props{$_}}
       for grep { m/accno/ } keys %total_props;

    for my $key (keys %total_props) {
        push @values, $total_props{$key};
        $key =~ s/accno$/accno_id/g;
        push @keys, $key;
        push @placeholders, '?';
    }
    my $keys = join ',', @keys;
    my $placeholders = join ',', @placeholders;

    $dbh->do(qq|
      INSERT INTO parts ($keys)
        VALUES ($placeholders)
|, undef, @values);
};

my $invnumber = 0;

Given qr/inventory has been built up for '(.*)' from these transactions:$/, sub {
    my $part = $1;

    local $LedgerSMB::App_State::DBH = S->{ext_lsmb}->admin_dbh;
    local $LedgerSMB::App_State::User = {
        numberformat => '1000.00'
    };

    my $part_props = S->{ext_lsmb}->admin_dbh->selectrow_hashref(
        qq|SELECT * FROM parts WHERE partnumber = ?|, undef, $part);

    for my $trans (@{C->data}) {
        $trans->{invnumber} //= 'I-' . $invnumber++;
        my $vendor = LedgerSMB::Entity::Credit_Account->new(
            entity_class => 1);
        $vendor = $vendor->get_by_meta_number($trans->{vendor}, 1);

        my $form = Form->new();
        $form->{dbh} = S->{ext_lsmb}->admin_dbh;
        $form->{rowcount} = 2;
        $form->{transdate} = $trans->{transdate};
        $form->{qty_1} = $trans->{amount};
        $form->{sellprice_1} = $trans->{price} / $trans->{amount};
        $form->{linetotal_1} = $trans->{price};
        $form->{discount_1} = 0;
        $form->{id_1} = $part_props->{id};
        $form->{"${_}_1"} = $part_props->{$_}
            for (qw( inventory_accno_id income_accno_id expense_accno_id ));
        $form->{vendor_id} = $vendor->id;
        $form->{AP} = '2100';
        $form->{currency} = 'USD';
        $form->{defaultcurrency} = 'USD';

        IR->post_invoice({}, $form);
    }
    S->{ext_lsmb}->admin_dbh->commit
        if ! S->{ext_lsmb}->admin_dbh->{AutoCommit};
};


1;
