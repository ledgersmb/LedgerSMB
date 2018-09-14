package PageObject::App::Cash::Vouchers::Payments::Filter;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'cash-vouchers-payments-filter',
              './/div[@id="payments-filter"]',
              tag_name => 'div',
              attributes => {
                  id => 'payments-filter',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
