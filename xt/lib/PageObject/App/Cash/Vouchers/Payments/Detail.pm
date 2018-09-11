package PageObject::App::Cash::Vouchers::Payments::Detail;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'cash-vouchers-payments-detail',
              './/div[@id="payments-detail"]',
              tag_name => 'div',
              attributes => {
                  id => 'payments-detail',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
