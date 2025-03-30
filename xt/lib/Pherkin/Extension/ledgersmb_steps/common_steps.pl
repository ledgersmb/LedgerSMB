#!perl


use strict;
use warnings;

use LedgerSMB::Batch;
use LedgerSMB::IR;
use LedgerSMB::Form;
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
        my $job_name = $ENV{T2_HARNESS_JOB_NAME} // '';
        $company //= "standard-$$-$job_name-" . $company_seq++;
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


Given qr/a (vendor|customer) "(.*)"(?: from (.+))$/, sub {
    my $vc = $1;
    my $vc_name = $2;
    my $country = $3;
    my $vc_data = S->{ext_lsmb}->create_vc($vc, $vc_name, $country);
    S->{$_} = $vc_data->{$_} for %$vc_data;
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
    my $batch = LedgerSMB::Batch->new(%$batch_data);
    $batch->create;
};


Given qr/(an )?unpaid AP transactions? with these values:$/, sub {
    # Expects data in the following form:
    # | Vendor   | Date       | Invoice Number | Amount |
    # | Vendor C | 2017-03-01 | INV103         | 250.00 |
    my $dbh = S->{ext_lsmb}->admin_dbh;

    my $ap_query = $dbh->prepare("
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
        AND entity_credit_account.entity_class = 1
        LIMIT 1
        RETURNING ap.id
    ");

    my $acc_trans_query = $dbh->prepare("
        INSERT INTO acc_trans (trans_id, chart_id, amount_bc,
                               curr, amount_tc, transdate)
        VALUES (?, ?, ?, 'USD', ?, ?)
    ");

    foreach my $data (@{C->data}) {
        $ap_query->execute(
            $data->{'Invoice Number'},
            $data->{'Date'},
            $data->{'Amount'},
            $data->{'Amount'},
            $data->{'Date'},
            $data->{'Amount'},
            $data->{'Amount'},
            $data->{'Vendor'},
        );
        my $ap_id = $ap_query->fetchrow_hashref->{id};

        $acc_trans_query->execute(
            $ap_id,
            28, # 5700--Office Supplies
            $data->{'Amount'} * -1,
            $data->{'Amount'} * -1,
            $data->{'Date'},
        );

        $acc_trans_query->execute(
            $ap_id,
            10, # 2100--Accounts Payable account
            $data->{'Amount'},
            $data->{'Amount'},
            $data->{'Date'},
        );
    }
};


my %part_props = (
    inventory_accno => '1510',
    income_accno => '4010',
    expense_accno => '5010',
    );


Given qr/a part( "([^\"]+)")?$/, sub {
    my $partnumber = $1;
    $partnumber //= 'P01';
    my %total_props = (%part_props,
                       partnumber => $partnumber,
        );

    S->{ext_lsmb}->create_part(\%total_props);
    S->{'the part'} = $partnumber;
};

Given qr/a part with these properties:$/, sub {
    my %props = map { $_->{name} => $_->{value} } @{C->data};
    my %total_props = (%part_props, %props);

    S->{ext_lsmb}->create_part(\%total_props);
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
        $form->{_wire} = S->{ext_lsmb}->wire;
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

        IR->post_invoice({ numberformat => '1000.00' }, $form);
    }
    S->{ext_lsmb}->admin_dbh->commit
        if ! S->{ext_lsmb}->admin_dbh->{AutoCommit};
};

Given qr/^(\d+) units inventory of ((?:a|the) part|part "(.*)") purchased at (\d+) ([A-Z]{3,3}) each/, sub {
    my $count = $1;
    my $choice = $2;
    my $partnumber = $3;
    my $price = $4;
    my $curr = $5;

    if ($choice eq 'a part') {
        my %total_props =
            (%part_props,
             partnumber => $partnumber,
            );

        S->{'the part'} = S->{ext_lsmb}->create_part(\%total_props);
    }

    $partnumber = S->{'the part'}
         if ($choice eq 'a part' or $choice eq 'the part');

    # set up inventory in a single blow
    my $dbh = S->{ext_lsmb}->admin_dbh;
    $dbh->do(
        q{
        INSERT INTO gl (reference, description, transdate, person_id, approved)
               VALUES ('INV-INIT', 'Initial setup', '2020-01-01',
                       person__get_my_id(), true);
        })
        or die $dbh->errstr;

    $dbh->do(
        q{
        INSERT INTO invoice (trans_id, parts_id, qty, sellprice, precision,
                             fxsellprice, discount, unit, allocated)
            VALUES (currval('id'), (select id from parts where partnumber = ?),
                    ?, ?, 2, ?, 0, 'ea', 0);
        },
        {},
        $partnumber, -$count, $price, 0)
        or die $dbh->errstr;

    $dbh->do(
        q{
        INSERT INTO acc_trans (trans_id, chart_id,
                               transdate, invoice_id, approved,
                               amount_bc, amount_tc, curr)
            VALUES (currval('id'), (select id from account where accno='3350'),
                    '2020-01-01', currval('invoice_id_seq'), true,
                    ?, ?, ?),
                   (currval('id'), (select id from account where accno='1510'),
                    '2020-01-01', currval('invoice_id_seq'), true,
                    ?, ?, ?);
        },
        {},
        $count*$price, $count*$price, $curr,
        -$count*$price, -$count*$price, $curr)
        or die $dbh->errstr;
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
        my $batch = LedgerSMB::Batch->new(%$data);
        my $batch_id = $batch->create;

        if($batch_spec->{Approved} eq 'yes') {
            my $data = {
                dbh => S->{ext_lsmb}->admin_dbh,
                batch_id => $batch_id,
            };
            LedgerSMB::Batch->new(%$data)->post;
        }
    }
};

Given qr/^(a reconciliation report|reconciliation reports) with these properties:$/, sub {

    my $db = PGObject::Simple->new(
        dbh => S->{ext_lsmb}->admin_dbh,
        _funcschema => 'xyz',
        );

    foreach my $report_spec (@{C->data}) {

        my $account = $db->call_procedure(
            funcname => 'account__get_from_accno',
            args => [$report_spec->{'Account Number'}],
        ) or die 'Failed to find account number ' . $report_spec->{'Account Number'};

        local $LedgerSMB::App_State::DBH = S->{ext_lsmb}->admin_dbh;
        local $LedgerSMB::App_State::User = {
            numberformat => '1000.00'
        };
        my $wf = S->{ext_lsmb}->wire->get('workflows')->create_workflow(
            'reconciliation',
            Workflow::Context->new(
                account_id => $account->{id},
                ending_balance => $report_spec->{'Statement Balance'},
                end_date => $report_spec->{'Statement Date'},
            ));

        if ($report_spec->{'Submitted'} eq 'yes') {
            $wf->execute_action( 'submit' );
        }

        if ($report_spec->{'Approved'} eq 'yes') {
            $wf->execute_action( 'approve' );
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

    ok($element->get_text eq $option_text,
        "Found option '$option_text' of dropdown '$label_text'");
};

Given qr/a customer named "(.*)"/, sub {
    my $customer = $1;

    # The TODO below is a consequence of being unable to connect to
    # our database with different credentials in a single process:
    #  the environment contains PGUSER='postgres', but the username
    #  was set to 'test-user-admin' -- yet the postgres value is used
    my $dbh = LedgerSMB::Database->new(
        connect_data => {
            dbname => S->{"the company"},
            user     => $ENV{PGUSER},     ###TODO: we had 'S->{"the admin"}
            password => $ENV{PGPASSWORD}, ### but that didn't work
            host     => 'localhost',
        },
        schema => 'xyz')
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

Given qr/the following currenc(?:y|ies):$/, sub {
    # Expects data in the following form:
    # | currency | description   |
    # | SEK      | Swedish Krona |
    my $dbh = S->{ext_lsmb}->admin_dbh;

    my $q = $dbh->prepare('
        INSERT INTO currency (
            curr,
            description
        )
        VALUES (?,?)
    ');

    foreach my $row (@{C->data}) {
        $q->execute(
            $row->{'currency'},
            $row->{'description'},
        ) or die 'failed to insert currency';
    }
};

Given qr/the following exchange rates?:$/, sub {
    # Expects data in the following form:
    # | currency | rate type    | valid from | rate |
    # | EUR      | Default rate | 2020-01-01 | 1.1  |
    my $dbh = S->{ext_lsmb}->admin_dbh;

    my $q = $dbh->prepare('
        INSERT INTO exchangerate_default (
            rate_type,
            curr,
            valid_from,
            rate
        )
        SELECT id, ?, ?, ?
        FROM exchangerate_type
        WHERE description = ?
        LIMIT 1
    ');

    foreach my $row (@{C->data}) {
        $q->execute(
            $row->{'currency'},
            $row->{'valid from'},
            $row->{'rate'},
            $row->{'rate type'},
        ) or die 'failed to insert exchange rate';
    }
};

Given qr/the following exchange rate types?:$/, sub {
    # Expects data in the following form:
    # | description |
    # | Buy rate    |
    my $dbh = S->{ext_lsmb}->admin_dbh;

    my $q = $dbh->prepare('
        INSERT INTO exchangerate_type (description)
        VALUES (?)
    ');

    foreach my $row (@{C->data}) {
        $q->execute(
            $row->{'description'},
        ) or die 'failed to insert exchange rate type';
    }
};


Given qr/that standard payment terms apply for "(.+)"/, sub {

    my $vc = $1;
    # assert that the discount account exists (AR_discount/AP_discount)

    my $dbh = S->{ext_lsmb}->admin_dbh;

    if (not $dbh->selectall_array(
            q{SELECT 1 FROM account WHERE accno = 'DISC'})) {
        $dbh->do(q{
              SELECT account__save(NULL, 'DISC', 'Payment discounts',
                 'E', NULL, (select id from account_heading where accno='5600'),
                 null, false, false, ARRAY['AR_discount','AP_discount']::text[],
                 false, false);
            })
            or die $dbh->errstr;
    }

    # discount account; payment terms: 10%/15, net 30
    $dbh->do(qq{
          UPDATE entity_credit_account
             SET discount_account_id = (select id from account
                                         where accno='DISC'),
                 discount = 10,
                 discount_terms = 15,
                 terms = 30
           WHERE meta_number = '$vc';
    }) or die $dbh->errstr;

};

1;
