package PageObject::App::System::Defaults;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'system-settings',
              './/form[@id="system-settings"]',
              tag_name => 'form',
              attributes => {
                  id => 'system-settings',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
