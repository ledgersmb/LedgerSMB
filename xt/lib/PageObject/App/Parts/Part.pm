package PageObject::App::Parts::Part;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'part',
              './/div[@id="part"]',
              tag_name => 'div',
              attributes => {
                  id => 'part',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
