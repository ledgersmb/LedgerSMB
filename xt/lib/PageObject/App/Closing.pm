package PageObject::App::Closing;

use strict;
use warnings;

use Carp;
use PageObject;

use PageObject::App::ClosingConfirm;
use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'gl-yearend',
              './/form[@id="gl-yearend"]',
              tag_name => 'form',
              attributes => {
                  id => 'gl-yearend',
              });


sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
