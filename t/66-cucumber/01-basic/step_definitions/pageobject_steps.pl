#!perl


use lib 't/lib';
use strict;
use warnings;

use LedgerSMB::App_State;
use LedgerSMB::Database;
use LedgerSMB::Entity::Person::Employee;
use LedgerSMB::Entity::User;
use LedgerSMB::PGDate;


use Module::Runtime qw(use_module);
use PageObject::Driver;
use PageObject::App::Login;

use Test::More;
use Test::BDD::Cucumber::StepFile;


sub get_driver {
    my ($stash) = @_;

    return $stash->{feature}->{driver};
}

my $company_seq = 0;

Given qr/a standard test company/, sub {
    my $driver = get_driver(S);
    my $company = "standard-" . $company_seq++;
    S->{feature}->{"the company"} = $company;

    my $pgh = LedgerSMB::Database->new(
        dbname => 'postgres',
        usermame => $ENV{PGUSER},
        password => $ENV{PGPASSWORD},
        host => 'localhost')
        ->connect({ PrintError => 0, RaiseError => 1, AutoCommit => 1 });
    unless (S->{feature}->{"the template"}) {
        my $template = "standard-template";
        my $admin = 'test-user-admin';
        $pgh->do(qq(DROP DATABASE IF EXISTS "$template"));
        $pgh->do(qq(DROP ROLE IF EXISTS "$admin"));


        my $db = LedgerSMB::Database->new(
            dbname => $template,
            usermame => $ENV{PGUSER},
            password => $ENV{PGPASSWORD},
            host => 'localhost');
        $db->create_and_load;
        $db->load_coa({ country => 'us',
                          chart => 'General.sql' });

        my $dbh = $db->connect({ PrintError => 0, RaiseError => 1,
                                 AutoCommit => 0 });

        my $emp = LedgerSMB::Entity::Person::Employee->new(
            employeenumber => 'E-001',
            control_code => 'E-001',
            dob => LedgerSMB::PGDate->from_input('2006-09-01'),
            username => $admin,
            salutation_id => 1,
            first_name => 'First',
            last_name => 'Last',
            name => 'First Last',
            ssn => '0000010',
            country_id => 232, # United States
            _DBH => $dbh,
            );
        $emp->save;

        my $user = LedgerSMB::Entity::User->new(
            entity_id => $emp->entity_id,
            username => $admin,
            _DBH => $dbh,
            );
        $user->create('password');
        my $roles;
        @$roles = map { $_->{rolname} } @{$user->list_roles};
        $user->save_roles($roles);

        $dbh->do("INSERT INTO defaults
                     VALUES ('role_prefix', 'lsmb_${template}__')");
        $dbh->commit;
        $dbh->disconnect;
        S->{feature}->{"the template"} = $template;
        S->{feature}->{"the admin"} = 'test-user-admin';
        S->{feature}->{"the admin password"} = 'password';
    }
    my $template = S->{feature}->{"the template"};
    $pgh->do(qq(DROP DATABASE IF EXISTS "$company"));
    $pgh->do(qq(CREATE DATABASE "$company" TEMPLATE "$template"));
    $pgh->disconnect;
    S->{scenario}->{"the company"} = $company;
    S->{scenario}->{"the admin"} = S->{feature}->{"the admin"};
    S->{scenario}->{"the admin password"} =
        S->{feature}->{"the admin password"};
};


When qr/I navigate the menu and select the item at "(.*)"/, sub {
    my @path = split /[\n\s\t]*>[\n\s\t]*/, $1;

    get_driver(S)->page->menu->click_menu(\@path);
};


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


Given qr/a logged in admin/, sub {
    PageObject::App::Login->open(driver => get_driver(S));
    get_driver(S)->verify_page;
    get_driver(S)->page->login(S->{scenario}->{"the admin"},
                               S->{scenario}->{"the admin password"},
                               S->{scenario}->{"the company"});
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

my %screens = (
    'Contact search' => 'PageObject::App::Search::Contact',
    'AR transaction entry' => 'PageObject::App::AR::Transaction',
    'AR invoice entry' => 'PageObject::App::AR::Invoice',
    'AR note entry' => 'PageObject::App::AR::Note',
    'AR credit invoice entry' => 'PageObject::App::AR::CreditInvoice',
    'AR returns' => 'PageObject::App::AR::Return',
    'AR search' => 'PageObject::App::Search::AR',
    'AP transaction entry' => 'PageObject::App::AP::Transaction',
    'AP invoice entry' => 'PageObject::App::AP::Invoice',
    'AP note entry' => 'PageObject::App::AP::Note',
    'AP credit invoice entry' => 'PageObject::App::AP::DebitInvoice',
    'AP returns' => 'PageObject::App::AP::Return',
    'AP search' => 'PageObject::App::Search::AP',
    'Batch import' => 'PageObject::App::BatchImport',
    'Budget search' => 'PageObject::App::Search::Budget',
    'Employee search' => 'PageObject::App::Search::Employee',
    'Sales order search' => 'PageObject::App::Search::SalesOrder',
    'Purchase order search' => 'PageObject::App::Search::PurchaseOrder',
    'generate sales order' => 'PageObject::App::Search::GenerateSalesOrder',
    'generate purchase order' => 'PageObject::App::Search::GeneratePurchaseOrder',
    'combine sales order' => 'PageObject::App::Search::CombineSalesOrder',
    'combine purchase order' => 'PageObject::App::Search::CombinePurchaseOrder',
    'Quotation search' => 'PageObject::App::Search::Quotation',
    'RFQ search' => 'PageObject::App::Search::RFQ',
    'GL search' => 'PageObject::App::Search::GL',
    );

Then qr/I should see the (.*) screen/, sub {
    my $page_name = $1;
    die "Unknown screen '$page_name'"
        unless exists $screens{$page_name};

    my $page = get_driver(S)->verify_screen;
    ok($page, "the browser screen is the screen named '$page_name'");
    ok($screens{$page_name}, "the named screen maps to a class name");
    ok($page->isa($screens{$page_name}),
       "the screen is of expected class: " . ref $page);
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


Then qr/I should see all permission checkboxes checked/, sub {
    my $page = get_driver(S)->page;
    my $checkboxes = $page->get_perms_checkboxes(filter => 'all');
    my $checked_boxes = $page->get_perms_checkboxes(filter => 'checked');

    ok(scalar(@{ $checkboxes }) > 0,
       "there are checkboxes");
    ok(scalar(@{ $checkboxes }) == scalar(@{ $checked_boxes }),
       "all perms checkboxes checked");
};


Then qr/I should see no permission checkboxes checked/, sub {
    my $page = get_driver(S)->page;
    my $checked_boxes = $page->get_perms_checkboxes(filter => 'checked');

    ok(0 == scalar(@{ $checked_boxes }),
       "no perms checkboxes checked");
};


Then qr/I should see only these permission checkboxes checked:/, sub {
    my $page = get_driver(S)->page;
    my @data = map { $_->{"perms label"} } @{ C->data };
    my $checked_boxes = $page->get_perms_checkboxes(filter => 'checked');

    is(scalar(@{ $checked_boxes }), scalar(@data),
       "Expected number of perms checkboxes checked");
    ok($page->is_checked_perms_checkbox($_),
       "Expect perms checkbox with label '$_' to be checked")
        for (@data);
};



1;
