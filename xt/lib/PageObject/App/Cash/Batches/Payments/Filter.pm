package PageObject::App::Cash::Batches::Payments::Filter;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';
with 'PageObject::App::Roles::Dynatable';

__PACKAGE__->self_register(
              'cash-batches-payments-filter',
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
