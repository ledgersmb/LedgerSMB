package PageObject::App::ClosingConfirm;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'gl-yearend-confirm',
              './/h1[@id="gl-yearend-confirm"]',
              tag_name => 'h1',
              attributes => {
                  id => 'gl-yearend-confirm',
              });


sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
