package PageObject::App::Orders::Purchase;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'purchase-order',
              './/div[@id="purchase-order"]',
              tag_name => 'div',
              attributes => {
                  id => 'purchase-order',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
