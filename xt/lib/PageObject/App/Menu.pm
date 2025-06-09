package PageObject::App::Menu;

use strict;
use warnings;

use Carp;
use PageObject;
use MIME::Base64;
use Test::More;

use Module::Runtime qw(use_module);

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
    'app-menu',
    './/div[@id="menudiv"]',
    tag_name => 'div',
    attributes => {
        id => 'menudiv',
    }
);


my %menu_path_pageobject_map = (
    "Contacts > Search" => 'PageObject::App::Search::Contact',
    "Contacts > Add Entity" => 'PageObject::App::Contacts::EditContact',

    "Accounts Receivable > Add Transaction" => 'PageObject::App::AR::Transaction',
    "Accounts Receivable > Import Batch" => 'PageObject::App::BatchImport',
    "Accounts Receivable > Sales Invoice" => 'PageObject::App::AR::Invoice',
    "Accounts Receivable > Credit Note" => 'PageObject::App::AR::Note',
    "Accounts Receivable > Credit Invoice" => 'PageObject::App::AR::CreditInvoice',
    "Accounts Receivable > Add Return" => 'PageObject::App::AR::Return',
    "Accounts Receivable > Search" => 'PageObject::App::Search::AR',
    "Accounts Receivable > Reports > Outstanding" => '',
    "Accounts Receivable > Reports > AR Aging" => '',
    "Accounts Receivable > Reports > Customer History" => 'PageObject::App::AR::PurchaseHistorySearch',

    "Accounts Payable > Add Transaction" => 'PageObject::App::AP::Transaction',
    "Accounts Payable > Import Batch" => 'PageObject::App::BatchImport',
    "Accounts Payable > Vendor Invoice" => 'PageObject::App::AP::Invoice',
    "Accounts Payable > Debit Note" => 'PageObject::App::AP::Note',
    "Accounts Payable > Debit Invoice" => 'PageObject::App::AP::DebitInvoice',
    "Accounts Payable > Search" => 'PageObject::App::Search::AP',
    "Accounts Payable > Reports > Outstanding" => '',
    "Accounts Payable > Reports > AP Aging" => '',
    "Accounts Payable > Reports > Customer History" => '',

    "Cash & Banking > Receipt" => 'PageObject::App::Cash::SelectVC',
    "Cash & Banking > Payment" => 'PageObject::App::Cash::SelectVC',
    "Cash & Banking > Vouchers > Payments" => 'PageObject::App::Cash::Vouchers::Payments',
    "Cash & Banking > Reconciliation" => 'PageObject::App::Cash::Reconciliation::NewReport',
    "Cash & Banking > Reports > Payments" => 'PageObject::App::Cash::PaymentSearch',
    "Cash & Banking > Reports > Receipts" => 'PageObject::App::Cash::PaymentSearch',
    "Cash & Banking > Reports > Reconciliation" => 'PageObject::App::Search::Reconciliation',

    "Fixed Assets > Asset Classes > Add Class" => 'PageObject::App::FixedAssets::EditClass',
    "Fixed Assets > Asset Classes > List Classes" => 'PageObject::App::FixedAssets::SearchClass',
    "Fixed Assets > Assets > Add Assets" => 'PageObject::App::FixedAssets::Edit',
#    "Fixed Assets > Assets > Depreciate" => 'PageObject::App::FixedAssets::DepreciationStart',
#    "Fixed Assets > Assets > Disposal" => '',
#    "Fixed Assets > Assets > Import" => '',
#    "Fixed Assets > Assets > Reports > Depreciation" => '',
#    "Fixed Assets > Assets > Reports > Disposal" => '',
#    "Fixed Assets > Assets > Reports > Net Book Value" => '',
    "Fixed Assets > Assets > Search Assets" => 'PageObject::App::FixedAssets::Search',


    "Transaction Approval > Batches" => 'PageObject::App::TransactionApproval::Batches',
    "Transaction Approval > Inventory" => 'PageObject::App::Parts::AdjustSearchUnapproved',

    "Budgets > Add Budget" => 'PageObject::App::Budget',
    "Budgets > Search" => 'PageObject::App::Search::Budget',
    "HR > Employees > Search" => 'PageObject::App::Search::Employee',

    "Order Entry > Sales Order" => "PageObject::App::Orders::Sales",
    "Order Entry > Purchase Order" => "PageObject::App::Orders::Purchase",
    "Order Entry > Reports > Sales Orders" => 'PageObject::App::Search::Order',
    "Order Entry > Reports > Purchase Orders" => 'PageObject::App::Search::Order',
    "Order Entry > Generate > Sales Orders" => 'PageObject::App::Search::Order',
    "Order Entry > Generate > Purchase Orders" => 'PageObject::App::Search::Order',
    "Order Entry > Combine > Sales Orders" => 'PageObject::App::Search::Order',
    "Order Entry > Combine > Purchase Orders" => 'PageObject::App::Search::Order',

    "Quotations > Reports > Quotations" => 'PageObject::App::Search::Order',
    "Quotations > Reports > RFQs" => 'PageObject::App::Search::Order',

    "General Journal > Journal Entry" => 'PageObject::App::GL::JournalEntry',
    "General Journal > Search" => 'PageObject::App::Search::GL',
    "General Journal > Chart of Accounts" => 'PageObject::App::Search::ReportDynatable',
    "General Journal > Year End" => 'PageObject::App::Closing',
    # Time cards
    "Reports > Balance Sheet" => 'PageObject::App::Report::Filters::BalanceSheet',

    "Goods & Services > Search" => 'PageObject::App::Search::GoodsServices',
    "Goods & Services > Add Part" => 'PageObject::App::Parts::Part',
    "Goods & Services > Add Service" => 'PageObject::App::Parts::Service',
    "Goods & Services > Add Assembly" => 'PageObject::App::Parts::Assembly',
    "Goods & Services > Add Overhead" => 'PageObject::App::Parts::Overhead',
    "Goods & Services > Enter Inventory" => 'PageObject::App::Parts::AdjustSetup',

    "Preferences" => 'PageObject::App::Preference',

    "Timecards > Generate > Sales Orders" => 'PageObject::App::Timecards::ToSalesOrders',
    "System > Currency > Edit currencies" => 'PageObject::App::System::Currency::EditCurrencies',
    "System > Currency > Edit rate types" => 'PageObject::App::System::Currency::EditRateTypes',
    "System > Currency > Edit rates" => 'PageObject::App::System::Currency::EditRates',
    "System > Defaults" => 'PageObject::App::System::Defaults',
    "System > Files" => 'PageObject::App::System::Files',
    "System > Taxes" => 'PageObject::App::System::Taxes',
    "System > Templates" => 'PageObject::App::System::Templates',
    );


sub _verify {
    my ($self) = @_;

    my @logged_in_company =
        $self->find_all("//*[\@id='company_info_header' and text() = 'Company']");
    my @logged_in_login =
        $self->find_all("//*[\@id='login_info_header' and text() = 'User']");

    return $self
        unless ((scalar(@logged_in_company) > 0)
              && scalar(@logged_in_login) > 0);
};

sub click_menu {
    my ($self, $paths) = @_;

    my $maindiv = $self->session->page->body->maindiv->content;
    subtest "Menu '" . join(' > ', @$paths) . "' useable" => sub {

        my $tgt_class = $menu_path_pageobject_map{join(' > ', @$paths)};
        if (!defined $tgt_class || $tgt_class eq '') {
            die join(' > ', @$paths) . ' not implemented';
        }
        # make sure the widget is registered before resolving the Weasel widget
        ok(use_module($tgt_class),
           "$tgt_class can be 'use'-d dynamically");

        my $item =
            $self->find(q{//*[@id='menudiv']//*[@role='tree']});
        ok($item, "Menu tree loaded");

        my @steps;
        for my $path (@$paths) {
            my $parent = ''; # 'and ./ancestor::*[@role="tree" and ./ancestor::*[@id="menudiv"]]';
            $parent = "and ./ancestor::*[.//*[\@role='treeitem' and normalize-space(string(.))=normalize-space('$_') $parent]]" for @steps;
            my $xpath =
                ".//*[\@role='treeitem' and normalize-space(string(.))=normalize-space('$path') $parent]";

            $self->session->wait_for(
                sub {
                    # The XPath also finds hidden tags, which we don't want to consider
                    my @elms = grep { $_->is_displayed } $item->find_all($xpath);
                    die "Too many elements found for $xpath"
                        unless scalar(@elms) < 2;

                    my $item1 = shift @elms;
                    my $valid = $item1 && ($item1->get_text ne '');

                    $item = $item1 if $valid;
                    return $valid;
                });

            # menu item found; held in $item
            my $expanded = $item->get_attribute('aria-expanded');
            $item->click unless ($expanded and $expanded eq 'true');

            # the node and its children are siblings in the DOM tree
            # continue the search from one level up...
            $item = $item->find('..');
            push @steps, $path;
        }
    };

    return $self->session->page->body->
        maindiv->wait_for_content(replaces => $maindiv);
}

sub close_menus {
    my ($self) = @_;

    my @nodes = $self->find_all(
        './/*[@role="treeitem" and @aria-expanded="true"]');
    $_->click for reverse @nodes;

    # wait for the transition to close, to complete
    $self->session->wait_for(
        sub {
            my @open = $self->find_all(
                './/*[@role="treeitem" and @aria-expanded="true"]');
            return scalar(@open) == 0;
        });
}

__PACKAGE__->meta->make_immutable;

1;
