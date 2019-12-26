package PageObject::App::AR::Transaction;

use strict;
use warnings;

use Carp;
use PageObject;
use PageObject::App::Transactions::Lines;
use PageObject::App::Invoices::Header;
#use PageObject::App::Invoices::Payments;

use Moose;
use namespace::autoclean;
extends 'PageObject';

my $page_heading = 'Add AR Transaction';

__PACKAGE__->self_register(
              'ar-transaction',
              './/div[@id="AR-transaction"]',
              tag_name => 'div',
              attributes => {
                  id => 'AR-transaction',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

sub _counterparty {
    return 'customer';
}

sub header {
    my ($self) = @_;

    $self->verify;
    return $self->find('*invoice-header',
                       widget_args => [ counterparty_type => $self->_counterparty ]);
}

sub lines {
    my ($self) = @_;

    $self->verify;
    return $self->find('*transaction-lines');
}

sub select_customer {
    my ($self, $customer) = @_;

    $self->verify;
    my $elem =
        $self->find("*labeled", text => "Customer");

    $elem->clear;
    $elem->send_keys($customer);

    $self->find("*button", text => "Update")->click;
    $self->session->page->body->maindiv->wait_for_content(replaces => $elem);
}



__PACKAGE__->meta->make_immutable;

1;
