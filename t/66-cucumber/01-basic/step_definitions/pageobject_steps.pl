#!perl


use lib 't/lib';
use strict;
use warnings;

use LedgerSMB::Database;

use Module::Runtime qw(use_module);
use PageObject::Driver;

use Test::More;
use Test::BDD::Cucumber::StepFile;


sub get_driver {
    my ($stash) = @_;

    return $stash->{feature}->{driver};
}

Given qr/(a non-existent|an existing) company named "(.*)"/, sub {
    my $company = $2;
    S->{scenario}->{"the company"} = $company;
    S->{scenario}->{"non-existent"} = ($1 eq 'a non-existent');

    if (S->{scenario}->{'non-existent'}) {
        my $dbh = LedgerSMB::Database->new(
            dbname => 'postgres',
            usermame => $ENV{PGUSER},
            password => $ENV{PGPASSWORD},
            host => 'localhost')
            ->connect({ PrintError => 0, RaiseError => 1, AutoCommit => 1 });
        $dbh->do(qq(DROP DATABASE IF EXISTS "$company"));
    }
};

Given qr/a non-existent user named "(.*)"/, sub {
    my $role = $1;
    S->{scenario}->{"the user"} = $role;

    my $dbh = LedgerSMB::Database->new(
        dbname => 'postgres',
        usermame => $ENV{PGUSER},
        password => $ENV{PGPASSWORD},
        host => 'localhost')
        ->connect({ PrintError => 0, RaiseError => 1, AutoCommit => 1 });
    $dbh->do(qq(DROP ROLE IF EXISTS "$role"));
};

When qr/I confirm database creation with these parameters:/, sub {
    my $data = C->data;
    my %data;

    $data{$_->{'parameter name'}} = $_->{value} for @$data;
    get_driver(S)->page->create_database(%data);
};

my %pages = (
    "setup login"         => "PageObject::Setup::Login",
    "company creation"    => "PageObject::Setup::CreateConfirm",
    "user creation"       => "PageObject::Setup::CreateUser",
    "setup confirmation"  => "PageObject::Setup::OperationConfirmation",
    "application login"   => "PageObject::App::Login",
    "setup admin"         => "PageObject::Setup::Admin",
    "setup user list"     => "PageObject::Setup::UsersList",
    "edit user"           => "PageObject::Setup::EditUser",
    );

When qr/I navigate to the (.*) page/, sub {
    my $page = $1;
    die "Unknown page '$page'"
        unless exists $pages{$page};

    use_module($pages{$page});
    $pages{$page}->open(driver => get_driver(S));
    get_driver(S)->verify_page;
};

When qr/I log into ("(.*)"|(.*)) using the super-user credentials/, sub {
    my $company = $2 || S->{scenario}->{$3};

    if (S->{scenario}->{"non-existent"}) {
        get_driver(S)->page->login_non_existent(
            $ENV{PGUSER}, $ENV{PGPASSWORD}, $company);
    }
    else {
        get_driver(S)->page->login($ENV{PGUSER}, $ENV{PGPASSWORD}, $company);
    }
};

Then qr/I should see the (.*) page/, sub {
    my $page_name = $1;
    die "Unknown page '$page_name'"
        unless exists $pages{$page_name};

    my $page = get_driver(S)->verify_page;
    ok($page, "the browser page is the page named '$page_name'");
    ok($pages{$page_name}, "the named page maps to a class name");
    ok($page->isa($pages{$page_name}),
       "the page is of expected class: " . ref $page);
};


When qr/I create a user with these values:/, sub {
    my $data = C->data;
    my %data;

    $data{$_->{'label'}} = $_->{value} for @$data;
    get_driver(S)->page->create_user(%data);
};

When qr/I request the users list/, sub {
    get_driver(S)->page->list_users;
};

When qr/I request to add a user/, sub {
    get_driver(S)->page->add_user;
};

Then qr/I should see the table of available users:/, sub {
    my @data = map { $_->{'Username'} } @{ C->data };
    my $users = get_driver(S)->page->get_users_list;

    is_deeply($users, \@data, "Users on page correspond with expectation");
};

When qr/I copy the company to "(.*)"/, sub {
    my $target = $1;

    get_driver(S)->page->copy_company($target);
};

When qr/I request the user overview for "(.*)"/, sub {
    my $user = $1;

    get_driver(S)->page->edit_user($user);
};


1;
