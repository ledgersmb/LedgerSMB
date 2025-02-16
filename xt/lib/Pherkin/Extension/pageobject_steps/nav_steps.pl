#!perl


use strict;
use warnings;

use Module::Runtime qw/ use_module /;

use Test::More;
use Test::BDD::Cucumber::StepFile;

my %pages = (
    "setup login"         => "PageObject::Setup::Login",
    "company creation"    => "PageObject::Setup::Admin",
    "user creation"       => "PageObject::Setup::CreateUser",
    "setup confirmation"  => "PageObject::Setup::OperationConfirmation",
    "application login"   => "PageObject::App::Login",
    "setup admin"         => "PageObject::Setup::Admin",
    "setup user list"     => "PageObject::Setup::UsersList",
    "edit user"           => "PageObject::Setup::EditUser",
);

When qr/I navigate to the application root/, sub {
    my $module = "PageObject::App::Login";

    use_module($module);
    S->{page} = $module->open(S->{ext_wsl})->verify;
};

When qr/I navigate to the (.*) page/, sub {
    my $page = $1;
    die "Unknown page '$page'"
        unless exists $pages{$page};

    use_module($pages{$page});
    S->{page} = $pages{$page}->open(S->{ext_wsl})->verify;
};

When qr/^I update the page$/, sub {
    my $button = S->{ext_wsl}->page->body->maindiv
        ->find('*button', text => 'Update');

    $button->click;
    S->{ext_wsl}->page->body->maindiv->wait_for_content(replaces => $button);
};

When qr/^I (click "(.+)" to )?save the page( as new)?$/, sub {
    my $text = ($3) ? 'Save as new' :
               ($1) ? $2
                    : 'Save';
    my $button = S->{ext_wsl}->page->body->maindiv
        ->find('*button', text => $text);
    $button->click;
    S->{ext_wsl}->page->body->maindiv->wait_for_content(replaces => $button);
};

Then qr/I should see the (.*) page/, sub {
    my $page_name = $1;
    die "Unknown page '$page_name'"
        unless exists $pages{$page_name};

    my $page = S->{ext_wsl}->page->body->verify;
    ok($page, "the browser page is the page named '$page_name'");
    ok($pages{$page_name}, "the named page maps to a class name");
    ok($page->isa($pages{$page_name}),
       "the page is of expected class: " . ref $page);
};

Then qr/I should see a(n error)? message "(.+)"/, sub {
    my $message = $2;
    S->{ext_wsl}->page->body->maindiv
        ->find('*button', text => 'Change Password')->click;
    S->{ext_wsl}->page->find(".//*[\@id='pwfeedback' and text()='$message']");
};

When qr/I navigate the menu and select the item at "(.*)"/, sub {
    my @path = split /[\n\s\t]*>[\n\s\t]*/, $1;

    S->{ext_wsl}->page->body->menu->click_menu(\@path);
};

my %screens = (
    'Account' => 'PageObject::App::GL::Account',
    'AP debit invoice entry' => 'PageObject::App::AP::DebitInvoice',
    'AP invoice entry' => 'PageObject::App::AP::Invoice',
    'AP note entry' => 'PageObject::App::AP::Note',
    'AP search' => 'PageObject::App::Search::AP',
    'AP transaction entry' => 'PageObject::App::AP::Transaction',
    'AR credit invoice entry' => 'PageObject::App::AR::CreditInvoice',
    'AR invoice entry' => 'PageObject::App::AR::Invoice',
    'AR note entry' => 'PageObject::App::AR::Note',
    'AR returns' => 'PageObject::App::AR::Return',
    'AR search' => 'PageObject::App::Search::AR',
    'AR transaction entry' => 'PageObject::App::AR::Transaction',
    'asset class edit' => 'PageObject::App::FixedAssets::EditClass',
    'asset class search' => 'PageObject::App::FixedAssets::SearchClass',
    'asset depreciate' => 'PageObject::App::FixedAssets::DepreciateStart',
    'asset edit' => 'PageObject::App::FixedAssets::Edit',
    'asset search' => 'PageObject::App::FixedAssets::Search',
    'Batch Search Report' => 'PageObject::App::Search::ReportDynatable',
    'Batch import' => 'PageObject::App::BatchImport',
    'Budget search' => 'PageObject::App::Search::Budget',
    'Budget' => 'PageObject::App::Budget',
    'Chart of Accounts' => 'PageObject::App::Search::ReportDynatable',
    'Contact Search Report' => 'PageObject::App::Search::ReportDynatable',
    'Contact Search' => 'PageObject::App::Search::Contact',
    'Create New Batch' => 'PageObject::App::Cash::Vouchers::Payments',
    'Edit Contact' => 'PageObject::App::Contacts::EditContact',
    'Edit currencies' => 'PageObject::App::System::Currency::EditCurrencies',
    'Edit Employee' => 'PageObject::App::Contacts::EditEmployee',
    'Edit rate types' => 'PageObject::App::System::Currency::EditRateTypes',
    'Edit rates' => 'PageObject::App::System::Currency::EditRates',
    'Employee Search Report' => 'PageObject::App::Search::ReportDynatable',
    'Employee Search' => 'PageObject::App::Search::Employee',
    'Enter Inventory' => ' PageObject::App::Parts::AdjustSetup',
    'Filtering Payments' => 'PageObject::App::Cash::Vouchers::Payments::Filter',
    'GL entry'  => 'PageObject::App::GL::JournalEntry',
    'GL search' => 'PageObject::App::Search::GL',
    'New Reconciliation Report' => 'PageObject::App::Cash::Reconciliation::NewReport',
    'Search AP Report' => 'PageObject::App::Search::ReportDynatable',
    'Single Payment Vendor Selection' => 'PageObject::App::Cash::SelectVC',
    'Single Payment Customer Selection' => 'PageObject::App::Cash::SelectVC',
    'Single Payment Entry' => 'PageObject::App::Cash::Entry',
    'Payment Batch Summary' => 'PageObject::App::Search::ReportDynatable',
    'Payments Detail' => 'PageObject::App::Cash::Vouchers::Payments::Detail',
    'Preferences' => 'PageObject::App::Preference',
    'Purchase History Report' => 'PageObject::App::Search::ReportDynatable',
    'Purchase History Search' => 'PageObject::App::AR::PurchaseHistorySearch',
    'Purchase order entry' => 'PageObject::App::Orders::Purchase',
    'Purchase order search' => 'PageObject::App::Search::Order',
    'Quotation search' => 'PageObject::App::Search::Order',
    'RFQ search' => 'PageObject::App::Search::Order',
    'Reconciliation Report' => 'PageObject::App::Cash::Reconciliation::Report',
    'Reconciliation Search Report' => 'PageObject::App::Search::ReportDynatable',
    'Sales order entry' => 'PageObject::App::Orders::Sales',
    'Sales order search' => 'PageObject::App::Search::Order',
    'Search Batches' => 'PageObject::App::TransactionApproval::Batches',
    'Search Reconciliation Reports' => 'PageObject::App::Search::Reconciliation',
    'assembly entry' => 'PageObject::App::Parts::Assembly',
    'balance sheet filter' => ' PageObject::App::Report::Filters::BalanceSheet',
    'combine purchase order' => 'PageObject::App::Search::Order',
    'combine sales order' => 'PageObject::App::Search::Order',
    'generate balance sheet' => 'PageObject::App::Report::Filters::BalanceSheet',
    'generate purchase order' => 'PageObject::App::Search::Order',
    'generate sales order' => 'PageObject::App::Search::Order',
    'overhead entry' => 'PageObject::App::Parts::Overhead',
    'part entry' => 'PageObject::App::Parts::Part',
    'search for goods & services' => ' PageObject::App::Search::GoodsServices',
    'service entry' => 'PageObject::App::Parts::Service',
    'system defaults' => 'PageObject::App::System::Defaults',
    'system files' => 'PageObject::App::System::Files',
    'system taxes' => 'PageObject::App::System::Taxes',
    'system templates' => 'PageObject::App::System::Templates',
    'timecard order generation' => 'PageObject::App::Timecards::ToSalesOrders',
    'unapproved inventory adjustments search screen' => ' PageObject::App::Parts::AdjustSearchUnapproved',
    'year-end confirmation' => 'PageObject::App::ClosingConfirm',
    'year-end' => ' PageObject::App::Closing',
);

Then qr/I should see the (.*) screen/, sub {
    my $page_name = $1;
    die "Unknown screen '$page_name'"
        unless exists $screens{$page_name};

    use_module($screens{$page_name});

    my $page;
    S->{ext_wsl}->wait_for(
        sub {
            $page = S->{ext_wsl}->page->body->maindiv->content;
            return $page && $page->isa($screens{$page_name});
        });
    ok($page, "the browser screen is the screen named '$page_name'");
    ok($screens{$page_name}, "the named screen maps to a class name");
    ok($page->isa($screens{$page_name}),
       "the screen is of expected class: " . ref $page);
};

When qr/I select the "(.*)" tab/, sub {
    S->{ext_wsl}->page->find(".//*[\@role='tab' and text()='$1']")->click;
};

When qr/^I click the "(.*)" link$/, sub {
    my $link_text = $1;
    S->{ext_wsl}->page->find(qq{.//a[normalize-space(.)="$link_text"]})->click;
};

When qr/I open the parts screen for '(.*)'/, sub {
    my $partnumber = $1;

    S->{ext_wsl}->page->body->menu->click_menu(
        ['Goods and Services', 'Search']
    );
    S->{ext_wsl}->page->body->maindiv->content->search(
        'Part Number' => $partnumber
    );
    S->{ext_wsl}->page->body->maindiv->content->find(
        qq|.//td[contains(concat(" ",normalize-space(\@class)," "),
                          " partnumber ")]//*[text()="$partnumber"]|)->click;

    use_module($screens{'part entry'});
    S->{ext_wsl}->page->body->maindiv->wait_for_content;
};

When qr/^I save the translations$/, sub {
    my $btn = S->{ext_wsl}->page->body->maindiv->find('*button', text => 'Save Translations');
    $btn->click;
    S->{ext_wsl}->page->body->maindiv->wait_for_content(replaces => $btn);
};

Then qr/I expect to see the '(.*)' value of '(.*)'/, sub {
    my $id = $1;
    my $value = $2;

    my $elm = S->{ext_wsl}->page->body->maindiv
        ->content->find(qq|.//*[\@id="$id" or \@title="$id"
                                or \@alt="$id"]
        |);
    ok(defined $elm, "value-defining element ($id) found");
    my $actual = $elm->get_text || $elm->get_attribute('value');
    $actual =~ s/^\s+|\s+$//g;
    is($actual, $value,
       "value for element ($id) equals expected value ($value):" .
        $actual
    );
};

Then qr/^I expect the "(.*)" field to contain "(.*)"$/, sub {
    my $label = $1;
    my $value = $2;
    my $element = S->{ext_wsl}->page->body->maindiv->find(
        "*labeled",
        text => $label
    );
    ok($element, "found element with label '$label'");
    is($element->value, $value, "element with label '$label' contains '$value'");
};

1;
