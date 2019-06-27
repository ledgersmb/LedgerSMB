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
    "Contacts > Add Contact" => '',
    "Contacts > Search" => 'PageObject::App::Search::Contact',

    "AR > Add Transaction" => 'PageObject::App::AR::Transaction',
    "AR > Import Batch" => 'PageObject::App::BatchImport',
    "AR > Sales Invoice" => 'PageObject::App::AR::Invoice',
    "AR > Credit Note" => 'PageObject::App::AR::Note',
    "AR > Credit Invoice" => 'PageObject::App::AR::CreditInvoice',
    "AR > Add Return" => 'PageObject::App::AR::Return',
    "AR > Search" => 'PageObject::App::Search::AR',
    "AR > Reports > Outstanding" => '',
    "AR > Reports > AR Aging" => '',
    "AR > Reports > Customer History" => 'PageObject::App::AR::PurchaseHistorySearch',

    "AP > Add Transaction" => 'PageObject::App::AP::Transaction',
    "AP > Import Batch" => 'PageObject::App::BatchImport',
    "AP > Vendor Invoice" => 'PageObject::App::AP::Invoice',
    "AP > Debit Note" => 'PageObject::App::AP::Note',
    "AP > Debit Invoice" => 'PageObject::App::AP::DebitInvoice',
    "AP > Search" => 'PageObject::App::Search::AP',
    "AP > Reports > Outstanding" => '',
    "AP > Reports > AP Aging" => '',
    "AP > Reports > Customer History" => '',

    "Cash > Vouchers > Payments" => 'PageObject::App::Cash::Vouchers::Payments',
    "Cash > Reconciliation" => 'PageObject::App::Cash::Reconciliation::NewReport',
    "Cash > Reports > Reconciliation" => 'PageObject::App::Search::Reconciliation',

    "Transaction Approval > Batches" => 'PageObject::App::TransactionApproval::Batches',
    "Transaction Approval > Inventory" => 'PageObject::App::Parts::AdjustSearchUnapproved',

    "Budgets > Add Budget" => 'PageObject::App::Budget',
    "Budgets > Search" => 'PageObject::App::Search::Budget',
    "HR > Employees > Search" => 'PageObject::App::Search::Contact',

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

    "General Journal > Search" => 'PageObject::App::Search::GL',
    "General Journal > Chart of Accounts" => 'PageObject::App::Search::ReportDynatable',
    "General Journal > Year End" => 'PageObject::App::Closing',
    # Time cards
    "Reports > Balance Sheet" => 'PageObject::App::Report::Filters::BalanceSheet',

    "Goods and Services > Search" => 'PageObject::App::Search::GoodsServices',
    "Goods and Services > Add Part" => 'PageObject::App::Parts::Part',
    "Goods and Services > Add Service" => 'PageObject::App::Parts::Service',
    "Goods and Services > Add Assembly" => 'PageObject::App::Parts::Assembly',
    "Goods and Services > Add Overhead" => 'PageObject::App::Parts::Overhead',
    "Goods and Services > Enter Inventory" => 'PageObject::App::Parts::AdjustSetup',

    "System > Defaults" => 'PageObject::App::System::Defaults',
    "System > Taxes" => 'PageObject::App::System::Taxes',
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

    my $maindiv = $self->session->page->body->maindiv->find('./*');
    subtest "Menu '" . join(' > ', @$paths) . "' useable" => sub {

        my $tgt_class = $menu_path_pageobject_map{join(' > ', @$paths)};
        if (!defined $tgt_class || $tgt_class eq '') {
            die join(' > ', @$paths) . ' not implemented';
        }
        # make sure the widget is registered before resolving the Weasel widget
        ok(use_module($tgt_class),
           "$tgt_class can be 'use'-d dynamically");

        my $item =
            $self->find("//*[\@id='top_menu']//*[\@role='tree']/parent::*");
        ok($item, "Menu tree loaded");

        my $role = 'tree';
        for my $path (@$paths) {
            $self->session->wait_for(
                sub {
                    my $xpath = "./*[\@role='$role']" .
                                "/*[\@role='presentation'" .
                                " and .//*[\@role='treeitem' and text()='$path']]";
                    my $item1 = $item->find($xpath);
                    my $valid = $item1 && ($item1->get_text ne '');
                    $item = $item1 if $valid;
                    return $valid;
                });

            my $label = $item->get_attribute('id') . '_label';
            ok($label,"Found label $label");

            my $submenu = $item->find(".//*[\@id='$label']");
            my $text = $submenu->get_text;

            ok($submenu && $text,"Submenu found '" . $text . "'");
            $submenu->click;
        }
    };

    return $self->session->page->body->
        maindiv->wait_for_content(replaces => $maindiv);
}


__PACKAGE__->meta->make_immutable;

1;
