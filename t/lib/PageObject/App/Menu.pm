package PageObject::App::Menu;

use strict;
use warnings;

use Carp;
use PageObject;
use MIME::Base64;

use Module::Runtime qw(use_module);

use Moose;
extends 'PageObject';


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
    "AR > Reports > Customer History" => '',

    "AP > Add Transaction" => 'PageObject::App::AP::Transaction',
    "AP > Import Batch" => 'PageObject::App::BatchImport',
    "AP > Vendor Invoice" => 'PageObject::App::AP::Invoice',
    "AP > Debit Note" => 'PageObject::App::AP::Note',
    "AP > Debit Invoice" => 'PageObject::App::AP::DebitInvoice',
    "AP > Search" => 'PageObject::App::Search::AP',
    "AP > Reports > Outstanding" => '',
    "AP > Reports > AP Aging" => '',
    "AP > Reports > Customer History" => '',
    "Budgets > Search" => 'PageObject::App::Search::Budget',
    "HR > Employees > Search" => 'PageObject::App::Search::Employee',
    "Order Entry > Sales Order" => "PageObject::App::Orders::Sales",
    "Order Entry > Purchase Order" => "PageObject::App::Orders::Purchase",    
    "Order Entry > Reports > Sales Orders" => 'PageObject::App::Search::SalesOrder',
    "Order Entry > Reports > Purchase Orders" => 'PageObject::App::Search::PurchaseOrder',
    "Order Entry > Generate > Sales Orders" => 'PageObject::App::Search::GenerateSalesOrder',
    "Order Entry > Generate > Purchase Orders" => 'PageObject::App::Search::GeneratePurchaseOrder',
    "Order Entry > Combine > Sales Orders" => 'PageObject::App::Search::CombineSalesOrder',
    "Order Entry > Combine > Purchase Orders" => 'PageObject::App::Search::CombinePurchaseOrder',
    "Quotations > Reports > Quotations" => 'PageObject::App::Search::Quotation',
    "Quotations > Reports > RFQs" => 'PageObject::App::Search::RFQ',
    "General Journal > Search and GL" => 'PageObject::App::Search::GL',
    "Goods and Services > Add Part" => 'PageObject::App::Parts::Part',
    "Goods and Services > Add Service" => 'PageObject::App::Parts::Service',
    "Goods and Services > Add Assembly" => 'PageObject::App::Parts::Assembly',
    "Goods and Services > Add Overhead" => 'PageObject::App::Parts::Overhead',
    "System > Defaults" => 'PageObject::App::System::Defaults',
    "System > Taxes" => 'PageObject::App::System::Taxes',
    );


sub verify {
    my ($self) = @_;
    my $driver = $self->driver;

    my @logged_in_found =
        $driver->find_elements_containing_text("Logged in as");
    my @logged_into_found =
        $driver->find_elements_containing_text("Logged into");

    return $self
        unless ((scalar(@logged_in_found) > 0)
                && scalar(@logged_into_found) > 0);
};


sub click_menu {
    my ($self, $path) = @_;
    my $root = $self->driver->find_element("//*[\@id='top_menu']");
    my $driver = $self->driver;

    my $item = $root;
    my $ul = '';

    do {
        $item = $driver->find_child_element($item,".$ul/li[./a[text()='$_']]");
        my $link = $driver->find_child_element($item,"./a");
        $driver->execute_script("arguments[0].scrollIntoView()", $link);
        $link->click
            unless ($item->get_attribute('class') =~ /\bmenu_open\b/);

        $ul = '/ul';
    } for @$path;

    my $tgt_class = $menu_path_pageobject_map{join(' > ', @$path)};
    use_module($tgt_class);
    return $driver->page->maindiv->content($tgt_class->new(%$self));
}


__PACKAGE__->meta->make_immutable;

1;
