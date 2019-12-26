package PageObject::App::Invoices::Payments;

use strict;
use warnings;

use Carp;
use PageObject;
use PageObject::App::Invoices::Payment;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'invoice-payments',
              './/*[@id="invoice-payments-table"]',
              tag_name => 'table',
              attributes => {
                  id => 'invoice-payments-table',
              });

# counterparty_type IN ('customer', 'vendor')
has counterparty_type => (is => 'ro', isa => 'Str', required => 1);


sub _verify {
    my ($self) = @_;

    return $self;
}

sub payment_lines {
    my ($self) = @_;

    $self->verify;
    return $self->find_all('*invoice-payment',
                           widget_args => [ counterparty_type => $self->counterparty_type ]);
}


__PACKAGE__->meta->make_immutable;

1;
