package PageObject::App::System::Currency::EditRateTypes;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'system-ratetype',
              './/div[@id="system-ratetype"]',
              tag_name => 'div',
              attributes => {
                  id => 'system-ratetype',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
