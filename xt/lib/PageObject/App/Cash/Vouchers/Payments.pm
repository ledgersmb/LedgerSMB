package PageObject::App::Cash::Vouchers::Payments;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'cash-vouchers-payments',
              './/div[@id="create-new-batch"]',
              tag_name => 'div',
              attributes => {
                  id => 'create-new-batch',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
