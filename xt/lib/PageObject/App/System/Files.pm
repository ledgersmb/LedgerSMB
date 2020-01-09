package PageObject::App::System::Files;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'system-files',
              './/form[@id="system-files"]',
              tag_name => 'form',
              attributes => {
                  id => 'system-files',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
