#!perl


use strict;
use warnings;

use LedgerSMB::Entity::Company;
use LedgerSMB::Entity::Credit_Account;

use Test::More;
use Test::BDD::Cucumber::StepFile;


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
        host => $ENV{PGHOST} // 'localhost')
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
        _dbh => $dbh,
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
    #     _dbh => $dbh,
    #     );
    # $eca->save;

    $dbh->do(qq(INSERT INTO
        entity_credit_account (entity_id, entity_class, ar_ap_account_id,
                               curr, meta_number)
        VALUES (?, ?, ?, ?, ?)), {}, $company->id, 2, 3, 'USD', 'M001');
    $dbh->commit;

};


Given qr/a service "(.*)"/, sub {


};


1;
