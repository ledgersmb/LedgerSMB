#!perl


use lib 't/lib';
use strict;
use warnings;


use Module::Runtime qw(use_module);
use PageObject::Driver;
use PageObject::App::Login;

use Test::More;
use Test::BDD::Cucumber::StepFile;


sub get_driver {
    my ($context) = @_;

    return $context->stash->{feature}->{driver};
}

When qr/I navigate the menu and select the item at "(.*)"/, sub {
    my @path = split /[\n\s\t]*>[\n\s\t]*/, $1;

    get_driver(C)->page->menu->click_menu(\@path);
};

Given qr/a logged in admin/, sub {
    PageObject::App::Login->open(driver => get_driver(C));
    get_driver(C)->verify_page;
    get_driver(C)->page->login(S->{"the admin"},
                               S->{"the admin password"},
                               S->{"the company"});
};

When qr/I confirm database creation with these parameters:/, sub {
    my $data = C->data;
    my %data;

    $data{$_->{'parameter name'}} = $_->{value} for @$data;
    get_driver(C)->page->create_database(%data);
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
    $pages{$page}->open(stash => S);
    S->{page}->verify;
};

When qr/I log into ("(.*)"|(.*)) using the super-user credentials/, sub {
    my $company = $2 || S->{$3};

    if (S->{"non-existent"}) {
        get_driver(C)->page->login_non_existent(
            $ENV{PGUSER}, $ENV{PGPASSWORD}, $company);
    }
    else {
        get_driver(C)->page->login($ENV{PGUSER}, $ENV{PGPASSWORD}, $company);
    }
};

Then qr/I should see the (.*) page/, sub {
    my $page_name = $1;
    die "Unknown page '$page_name'"
        unless exists $pages{$page_name};

    my $page = S->{page}->verify;
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
    'AP debit invoice entry' => 'PageObject::App::AP::DebitInvoice',
    'AP search' => 'PageObject::App::Search::AP',
    'Batch import' => 'PageObject::App::BatchImport',
    'Budget search' => 'PageObject::App::Search::Budget',
    'Employee search' => 'PageObject::App::Search::Employee',
    'Sales order search' => 'PageObject::App::Search::SalesOrder',
    'Purchase order search' => 'PageObject::App::Search::PurchaseOrder',
    'Sales order entry' => 'PageObject::App::Orders::Sales',
    'Purchase order entry' => 'PageObject::App::Orders::Purchase',
    'generate sales order' => 'PageObject::App::Search::GenerateSalesOrder',
    'generate purchase order' => 'PageObject::App::Search::GeneratePurchaseOrder',
    'combine sales order' => 'PageObject::App::Search::CombineSalesOrder',
    'combine purchase order' => 'PageObject::App::Search::CombinePurchaseOrder',
    'Quotation search' => 'PageObject::App::Search::Quotation',
    'RFQ search' => 'PageObject::App::Search::RFQ',
    'GL search' => 'PageObject::App::Search::GL',
    'part entry' => 'PageObject::App::Parts::Part',
    'service entry' => 'PageObject::App::Parts::Service',
    'assembly entry' => 'PageObject::App::Parts::Assembly',
    'overhead entry' => 'PageObject::App::Parts::Overhead',
    'system defaults' => 'PageObject::App::System::Defaults',
    'system taxes' => 'PageObject::App::System::Taxes',
    );

Then qr/I should see the (.*) screen/, sub {
    my $page_name = $1;
    die "Unknown screen '$page_name'"
        unless exists $screens{$page_name};

    my $page = get_driver(C)->verify_screen;
    ok($page, "the browser screen is the screen named '$page_name'");
    ok($screens{$page_name}, "the named screen maps to a class name");
    ok($page->isa($screens{$page_name}),
       "the screen is of expected class: " . ref $page);
};

When qr/I create a user with these values:/, sub {
    my $data = C->data;
    my %data;

    $data{$_->{'label'}} = $_->{value} for @$data;
    get_driver(C)->page->create_user(%data);
};

When qr/I request the users list/, sub {
    get_driver(C)->page->list_users;
};

When qr/I request to add a user/, sub {
    get_driver(C)->page->add_user;
};

Then qr/I should see the table of available users:/, sub {
    my @data = map { $_->{'Username'} } @{ C->data };
    my $users = get_driver(C)->page->get_users_list;

    is_deeply($users, \@data, "Users on page correspond with expectation");
};

When qr/I copy the company to "(.*)"/, sub {
    my $target = $1;

    get_driver(C)->page->copy_company($target);
};

When qr/I request the user overview for "(.*)"/, sub {
    my $user = $1;

    get_driver(C)->page->edit_user($user);
};


Then qr/I should see all permission checkboxes checked/, sub {
    my $page = get_driver(C)->page;
    my $checkboxes = $page->get_perms_checkboxes(filter => 'all');
    my $checked_boxes = $page->get_perms_checkboxes(filter => 'checked');

    ok(scalar(@{ $checkboxes }) > 0,
       "there are checkboxes");
    ok(scalar(@{ $checkboxes }) == scalar(@{ $checked_boxes }),
       "all perms checkboxes checked");
};


Then qr/I should see no permission checkboxes checked/, sub {
    my $page = get_driver(C)->page;
    my $checked_boxes = $page->get_perms_checkboxes(filter => 'checked');

    ok(0 == scalar(@{ $checked_boxes }),
       "no perms checkboxes checked");
};


Then qr/I should see only these permission checkboxes checked:/, sub {
    my $page = get_driver(C)->page;
    my @data = map { $_->{"perms label"} } @{ C->data };
    my $checked_boxes = $page->get_perms_checkboxes(filter => 'checked');

    is(scalar(@{ $checked_boxes }), scalar(@data),
       "Expected number of perms checkboxes checked");
    ok($page->is_checked_perms_checkbox($_),
       "Expect perms checkbox with label '$_' to be checked")
        for (@data);
};



1;
