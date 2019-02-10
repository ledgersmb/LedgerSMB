package PageObject::App::AR::Invoice;

use strict;
use warnings;

use Carp;
use PageObject;
use PageObject::App::Invoices::Lines;
use PageObject::App::Invoices::Header;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'ar-invoice',
              './/div[@id="AR-invoice"]',
              tag_name => 'div',
              attributes => {
                  id => 'AR-invoice',
              });



sub _verify {
    my ($self) = @_;

    return $self;
}

sub select_customer {
    my ($self, $customer) = @_;

    $self->verify;
    my $elem = $self->find("*labeled", text => "Customer");

    $elem->clear;
    $elem->send_keys($customer);

    $self->find("*button", text => "Update")->click;
}

sub header {
    my ($self) = @_;

    $self->verify;
    return $self->find('*invoice-header',
                       widget_args => [ counterparty_type => 'customer' ]);
}

sub lines {
    my ($self) = @_;

    $self->verify;
    return $self->find('*invoice-lines');
}

__PACKAGE__->meta->make_immutable;

1;
