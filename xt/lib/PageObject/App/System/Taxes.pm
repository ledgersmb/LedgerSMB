package PageObject::App::System::Taxes;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'system-taxes',
              './/form[@id="system-taxes"]',
              tag_name => 'form',
              attributes => {
                  id => 'system-taxes',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
