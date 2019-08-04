#!perl


use strict;
use warnings;

use LedgerSMB::Batch;
use LedgerSMB::IR;
use LedgerSMB::Form;
use LedgerSMB::DBObject::Account;
use LedgerSMB::DBObject::Reconciliation;
use LedgerSMB::Entity::Company;
use LedgerSMB::Entity::Credit_Account;
use PGObject::Simple;

use Test::More;
use Test::BDD::Cucumber::StepFile;



my $company_seq = 0;

Given qr/a (fresh )?standard test company(?: named "(.*)")?/, sub {
    my $fresh_required = $1;
    my $company = $2;

    S->{ext_lsmb}->ensure_template;

    if (! S->{"the company"} || $fresh_required) {
        $company //= "standard-" . $company_seq++;
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

my %company_settings_map = (
    'Max per dropdown' => 'vclimit',
    );

Given qr/the following company configuration settings:$/, sub {
    my $config = C->data;
    my $dbh = S->{ext_lsmb}->admin_dbh;
    my $sth = $dbh->prepare('select * from defaults');
    $sth->execute;
    my $active = $sth->fetchall_hashref('setting_key');

    for my $conf (@$config) {
        if (exists $company_settings_map{$conf->{setting}}) {
            $conf->{setting} = $company_settings_map{$conf->{setting}};
        }
    }

    my $stu =
        $dbh->prepare('update defaults set value = ? where setting_key = ?');
    my $sti =
        $dbh->prepare('insert into defaults (setting_key, value) values (?,?)');
    for my $conf (@$config) {
        if (exists $active->{$conf->{setting}}) {
            $stu->execute($conf->{value}, $conf->{setting});
        }
        else {
            $sti->execute($conf->{setting}, $conf->{value});
        }
    }
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
my $vc_counter = 0;
my $customer_counter = 0;

Given qr/a (vendor|customer) "(.*)"$/, sub {
    my $vc = $1;
    my $vc_name = $2;
    my $control_code = uc(substr($vc,0,1)) . '-' . ($vc_counter++);
    my $admin_dbh = S->{ext_lsmb}->admin_dbh;
    my $company = LedgerSMB::Entity::Company->new(
        country_id => 1,
        control_code => $control_code,
        legal_name => $vc_name,
        name => $vc_name,
        entity_class => ($vc eq 'vendor' ? 1 : 2),
        _dbh => $admin_dbh,
        );
    $company = $company->save;

    local $LedgerSMB::App_State::DBH = $admin_dbh;
    my $account = LedgerSMB::DBObject::Account->new();
    $account->set_dbh($admin_dbh);
    my @accounts = $account->list();
    my %accno_ids = map { $_->{accno} => $_->{id} } @accounts;

    LedgerSMB::Entity::Credit_Account->new(
        entity_id => $company->entity_id,
        entity_class => ($vc eq 'vendor' ? 1 : 2),
        _dbh => $admin_dbh,
        ar_ap_account_id => $accno_ids{($vc eq 'vendor' ? '2100' : '1200')},
        meta_number => $vc_name,
        curr => 'USD',
        )->save;
};


Given qr/a (\w+) batch with these properties:$/, sub {
    my $batch_class = $1;
    my %map = (
        'Batch Date' => 'batch_date',
        'Batch Number' => 'batch_number',
        'Description' => 'description',
        );

    my $batch_data = {
        dbh => S->{ext_lsmb}->admin_dbh,
        batch_class => $batch_class,
        map { $map{$_->{Property}} => $_->{Value} } @{C->data},
    };
    my $batch = LedgerSMB::Batch->new({base => $batch_data});
    $batch->create;
};


Given qr/an unpaid AP transaction with these values:$/, sub {
    # Expects data in the following form:
    # | Vendor   | Date       | Invoice Number | Amount |
    # | Vendor C | 2017-03-01 | INV103         | 250.00 |
    my $data = shift @{C->data};
    my $dbh = S->{ext_lsmb}->admin_dbh;

    my $q = $dbh->prepare("
        INSERT INTO ap (invnumber, transdate, amount_bc, netamount_bc,
                        duedate, curr, approved, entity_credit_account,
                        amount_tc, netamount_tc)
        SELECT ?, ?, ?, ?, ?, 'USD', TRUE,
               entity_credit_account.id, ?, ?
        FROM entity
        JOIN entity_credit_account ON (
            entity_credit_account.entity_id = entity.id
        )
        WHERE entity.name = ?
        AND entity.entity_class = 1
        LIMIT 1
        RETURNING ap.id
    ");
    $q->execute(
        $data->{'Invoice Number'},
        $data->{'Date'},
        $data->{'Amount'},
        $data->{'Amount'},
        $data->{'Date'},
        $data->{'Amount'},
        $data->{'Amount'},
        $data->{'Vendor'},
    );
    my $ap_id = $q->fetchrow_hashref->{id};

    $q = $dbh->prepare("
        INSERT INTO acc_trans (trans_id, chart_id, amount_bc,
                               curr, amount_tc, transdate)
        VALUES (?, ?, ?, 'USD', ?, ?)
    ");

    $q->execute(
        $ap_id,
        28, # 5700--Office Supplies
        $data->{'Amount'} * -1,
        $data->{'Amount'} * -1,
        $data->{'Date'},
    );

    $q->execute(
        $ap_id,
        10, # 2100--Accounts Payable account
        $data->{'Amount'},
        $data->{'Amount'},
        $data->{'Date'},
    );
};


my $part_count = 0;

my %part_props = (
    inventory_accno => '1510',
    income_accno => '4010',
    expense_accno => '5010',
    );


sub _create_part {
    my ($props) = @_;

    local $LedgerSMB::App_State::DBH = S->{ext_lsmb}->admin_dbh;
    my $account = LedgerSMB::DBObject::Account->new();
    $account->set_dbh(S->{ext_lsmb}->admin_dbh);
    my @accounts = $account->list();
    my %accno_ids = map { $_->{accno} => $_->{id} } @accounts;

    $props->{partnumber} //= 'P-' . ($part_count++);
    my $dbh = S->{ext_lsmb}->admin_dbh;
    my @keys;
    my @values;
    my @placeholders;

    $props->{$_} = $accno_ids{$props->{$_}}
       for grep { m/accno/ } keys %$props;

    for my $key (keys %$props) {
        push @values, $props->{$key};
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

}

Given qr/a part "([^\"]+)"$/, sub {
    my $partnumber = $1;
    my %total_props = (%part_props,
                       partnumber => $partnumber,
        );

    _create_part(\%total_props);
};

Given qr/a part with these properties:$/, sub {
    my %props = map { $_->{name} => $_->{value} } @{C->data};
    my %total_props = (%part_props, %props);

    _create_part(\%total_props);
};

Given qr/(?:part|service) "([^\"]+)" with (this tax|these taxes):$/, sub {
    my $partnumber = $1;
    my $dbh = S->{ext_lsmb}->admin_dbh;

    my ($row) = $dbh->selectall_array(
        q{select * from parts where partnumber = ?},
        { Slice => {} }, $partnumber);
    my $partid = $row->{id};
    $dbh->do(q{delete from partstax where parts_id = ?}, {}, $partid)
        or die $dbh->errstr;

    for my $tax (@{C->data}) {
        $tax = $tax->{'Tax account'} // $tax->{accno};
        if ($tax =~ m/--/) {
            ($tax) = split(/--/, $tax);
        }
        ($row) = $dbh->selectall_array(
            q{select * from account where accno = ?},
            { Slice => {} }, $tax);
        $dbh->do(q{insert into partstax (parts_id, chart_id) values (?, ?)},
                 undef, $partid, $row->{id})
            or die $dbh->errstr;
    }
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

Given qr/(a batch|batches) with these properties:$/, sub {
    foreach my $batch_spec (@{C->data}) {
        my $data = {
            dbh => S->{ext_lsmb}->admin_dbh,
            batch_number => $batch_spec->{'Batch Number'},
            batch_class => $batch_spec->{Type},
            batch_date => $batch_spec->{Date},
            description => $batch_spec->{Description},
        };
        my $batch = LedgerSMB::Batch->new({ base => $data });
        my $batch_id = $batch->create;

        if($batch_spec->{Approved} eq 'yes') {
            my $data = {
                dbh => S->{ext_lsmb}->admin_dbh,
                batch_id => $batch_id,
            };
            LedgerSMB::Batch->new({ base => $data })->post;
        }
    }
};

Given qr/^(a reconciliation report|reconciliation reports) with these properties:$/, sub {

    my $db = PGObject::Simple->new();
    $db->set_dbh(S->{ext_lsmb}->admin_dbh);

    foreach my $report_spec (@{C->data}) {

        my $account = $db->call_procedure(
            funcname => 'account__get_from_accno',
            args => [$report_spec->{'Account Number'}],
        ) or die 'Failed to find account number ' . $report_spec->{'Account Number'};

        my $recon_data = {
            dbh => S->{ext_lsmb}->admin_dbh,
            chart_id => $account->{id},
            total => $report_spec->{'Statement Balance'},
            end_date => $report_spec->{'Statement Date'},
        };

        my $recon = LedgerSMB::DBObject::Reconciliation->new({
            base => $recon_data,
        });

        my $recon_id = $recon->new_report();

        if ($report_spec->{'Submitted'} eq 'yes') {
            $recon->submit;
        }

        if ($report_spec->{'Approved'} eq 'yes') {
            $recon->approve;
        }
    }
};

Given qr/^GIFI entries with these properties:$/, sub {
    my $dbh = S->{ext_lsmb}->admin_dbh;
    my $q = $dbh->prepare("
        INSERT INTO gifi (accno, description)
        VALUES (?,?)
    ");

    foreach my $gifi_spec (@{C->data}) {
        $q->execute(
            $gifi_spec->{GIFI},
            $gifi_spec->{Description},
        ) or die "failed to insert GIFI $gifi_spec->{GIFI} :: $gifi_spec->{Description}";
    }
};

Given qr/^Custom Flags with these properties:$/, sub {
    my $dbh = S->{ext_lsmb}->admin_dbh;
    my $q = $dbh->prepare("
        INSERT INTO account_link_description (description, summary, custom)
        VALUES (?, ?, TRUE)
    ");

    foreach my $row (@{C->data}) {
        my $is_summary = (lc $row->{Summary} eq 'yes' ? 1 : 0);
        $q->execute(
            $row->{Description},
            $is_summary,
        ) or die "failed to insert account_link_description (Custom Flag) with description $row->{Description}";
    }
};

When qr/I wait (\d+) seconds?$/, sub {
    sleep $1
};

When qr/^I (select|deselect) checkbox "(.*)"$/, sub {
    my $wanted_status = ($1 eq 'select');
    my $label = $2;
    my $element = S->{ext_wsl}->page->find(
        "*labeled", text => $label
    );

    ok($element, "found element with label '$label'");
    is($element->tag_name, 'input', 'element is an <input>');
    is($element->get_attribute('type'), 'checkbox', 'element is an checkbox');

    my $checked = $element->get_attribute('checked');

    if($checked xor $wanted_status) {
        $element->click;
    }
};

Then qr/^I expect the "(.*)" checkbox to be (selected|not selected)/, sub {
    my $label = $1;
    my $wanted_status = $2;
    my $element = S->{ext_wsl}->page->find(
        "*labeled", text => $label
    );

    ok($element, "found element with label '$label'");
    is($element->tag_name, 'input', 'element is an <input>');
    is($element->get_attribute('type'), 'checkbox', 'element is an checkbox');

    my $checked = $element->get_attribute('checked');

    if($wanted_status eq 'selected') {
        ok($checked, 'checkbox is selected');
    }
    else {
        ok(!$checked, 'checkbox is not selected');
    }
};

Then qr/^I expect "(.*)" to be selected for "(.*)"$/, sub {
    my $option_text = $1;
    my $label_text = $2;

    my $element = S->{ext_wsl}->page->find(
        "*labeled", text => $label_text
    );
    ok($element, "found element labeled '$label_text'");

    my $option = $element->find(
        qq{//span[\@role="option" and \@aria-selected="true" and .="$option_text"]}
    );

    ok($option, "Found option '$option_text' of dropdown '$label_text'");
};

Given qr/a customer named "(.*)"/, sub {
    my $customer = $1;

    # The TODO below is a consequence of being unable to connect to
    # our database with different credentials in a single process:
    #  the environment contains PGUSER='postgres', but the username
    #  was set to 'test-user-admin' -- yet the postgres value is used
    my $dbh = LedgerSMB::Database->new(
        dbname => S->{"the company"},
        usermame => $ENV{PGUSER},     ###TODO: we had 'S->{"the admin"}
        password => $ENV{PGPASSWORD}, ### but that didn't work
        host => 'localhost')
        ->connect({ PrintError => 0, RaiseError => 1, AutoCommit => 0 });

    my $company = LedgerSMB::Entity::Company->new(
        # fields from Entity
        control_code => 'C001',
        name         => $customer,
        country_id   => 232, # United States
        entity_class => 2, # customers
        # fields from Company
        legal_name   => $customer,

        # internal fields
        _DBH         => $dbh,
        );
    $company = $company->save;


    # work around the fact that the ECA api is unusable outside of the
    # realm of the web-application: it depends on LedgerSMB::PGObject
    # which directly accesses LedgerSMB::App_State (which is global state
    # we don't want to use here.
    ###TODO: So, not using LedgerSMB::Entity::Credit_Account here...
    # my $eca = LedgerSMB::Entity::Credit_Account->new(
    #     entity_id        => $company->id,
    #     entity_class     => 2, # customers
    #     ar_ap_account_id => 3,
    #     curr             => 'USD',

    #     # internal fields
    #     _DBH             => $dbh,
    #     );
    # $eca->save;

    $dbh->do(qq(INSERT INTO
        entity_credit_account (entity_id, entity_class, ar_ap_account_id,
                               curr, meta_number)
        VALUES (?, ?, ?, ?, ?)), {}, $company->id, 2, 3, 'USD', 'M001');
    $dbh->commit;

};


Given qr/(customer|vendor) "([^\"]+)" with (this tax|these taxes):$/, sub {
    my $entity_type = $1;
    my $metanumber = $2;
    my $dbh = S->{ext_lsmb}->admin_dbh;

    my ($row) = $dbh->selectall_array(
        q{select * from entity_credit_account
           where meta_number = ? and entity_class = ?},
        { Slice => {} }, $metanumber, ($entity_type eq 'vendor') ? 1 : 2);
    my $eca_id = $row->{id};
    $dbh->do(q{delete from eca_tax where eca_id = ?}, {}, $eca_id)
        or die $dbh->errstr;

    for my $tax (@{C->data}) {
        $tax = $tax->{'Tax account'} // $tax->{accno};
        if ($tax =~ m/--/) {
            ($tax) = split(/--/, $tax);
        }
        ($row) = $dbh->selectall_array(
            q{select * from account where accno = ?},
            { Slice => {} }, $tax);
        $dbh->do(q{insert into eca_tax (eca_id, chart_id) values (?, ?)},
                 undef, $eca_id, $row->{id})
            or die $dbh->errstr;
    }
};


Given qr/a service "(.*)"/, sub {
    my $service = $1;

    my $dbh = S->{ext_lsmb}->admin_dbh;
    my $sth = $dbh->prepare(qq|
INSERT INTO parts (partnumber, description, unit, listprice, sellprice,
                   lastcost, weight, notes, income_accno_id,
                   expense_accno_id)
           VALUES (?, ?, '', 0, 0,
                   0, 0, '', (select id from account join account_link al
                                on account.id = al.account_id
                              where al.description = 'IC_income' limit 1),
                   (select id from account join account_link al
                                on account.id = al.account_id
                              where al.description = 'IC_expense' limit 1))
|);
    $sth->execute($service, $service);
};



Given qr/a part "(.*)"/, sub {
    my $part = $1;

    my $dbh = S->{ext_lsmb}->admin_dbh;
    my $sth = $dbh->prepare(qq|
INSERT INTO parts (partnumber, description, unit, listprice, sellprice,
                   lastcost, weight, notes, inventory_accno_id,
                   income_accno_id,
                   expense_accno_id)
           VALUES (?, ?, '', 0, 0,
                   0, 0, '',
                   (select id from account join account_link al
                                on account.id = al.account_id
                              where al.description = 'IC' limit 1),
                   (select id from account join account_link al
                                on account.id = al.account_id
                              where al.description = 'IC_income' limit 1),
                   (select id from account join account_link al
                                on account.id = al.account_id
                              where al.description = 'IC_expense' limit 1))
|);
    $sth->execute($part, $part);
};

Given qr/a gl account with these properties:$/, sub {
    my %map = (
        'Account Number' => 'accno',
        'Description' => 'description',
        'Category' => 'category',
        'Heading' => 'heading',
        );

    my $dbh = S->{ext_lsmb}->admin_dbh;
    for my $row (@{C->data}) {
        if ($row->{Property} eq 'Heading') {
            my ($headno) = split(/--/, $row->{Value});
            my ($heading) = $dbh->selectall_array(
                q{select id from account_heading where accno = ?},
                { Slice => {} }, $headno);
            $row->{Value} = $heading->{id};
        }
    }

    my $placeholders = join(', ', map { '?' } @{C->data});
    my $fieldnames = join(', ', map { $map{$_->{Property}} } @{C->data});
    $dbh->do(qq{insert into account ($fieldnames) values ($placeholders)},
             undef, map { $_->{Value} } @{C->data})
        or die $dbh->errstr;
};


Given qr/a gl account heading with these properties:$/, sub {
    my %map = (
        'Account Number' => 'accno',
        'Description' => 'description',
        'Heading' => 'heading',
        );

    my $dbh = S->{ext_lsmb}->admin_dbh;
    for my $row (@{C->data}) {
        if ($row->{Property} eq 'Heading') {
            my ($headno) = split(/--/, $row->{Value});
            my ($heading) = $dbh->selectall_array(
                q{select id from account_heading where accno = ?},
                { Slice => {} }, $headno);
            $row->{Value} = $heading->{id};
        }
    }

    my $placeholders = join(', ', map { '?' } @{C->data});
    my $fieldnames = join(', ', map { $map{$_->{Property}} } @{C->data});
    $dbh->do(qq{insert into account_heading ($fieldnames) values ($placeholders)},
             undef, map { $_->{Value} } @{C->data})
        or die $dbh->errstr;
};


1;
