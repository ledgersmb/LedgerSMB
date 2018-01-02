package PageObject::App::Parts::Service;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'service',
              './/div[@id="service"]',
              tag_name => 'div',
              attributes => {
                  id => 'service',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
