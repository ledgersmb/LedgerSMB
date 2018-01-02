package PageObject::App::Orders::Sales;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'sales-order',
              './/div[@id="sales-order"]',
              tag_name => 'div',
              attributes => {
                  id => 'sales-order',
              });


sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
