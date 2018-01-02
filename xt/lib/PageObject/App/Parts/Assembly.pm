package PageObject::App::Parts::Assembly;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'assembly',
              './/div[@id="assembly"]',
              tag_name => 'div',
              attributes => {
                  id => 'assembly',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
