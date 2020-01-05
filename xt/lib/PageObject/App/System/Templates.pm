package PageObject::App::System::Templates;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'system-templates',
              './/form[@id="system-templates"]',
              tag_name => 'form',
              attributes => {
                  id => 'system-templates',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
