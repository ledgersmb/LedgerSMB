package PageObject::App::Parts::Overhead;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'labor',
              './/div[@id="labor"]',
              tag_name => 'div',
              attributes => {
                  id => 'labor',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
