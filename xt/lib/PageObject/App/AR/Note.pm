package PageObject::App::AR::Note;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'ar-transaction-reverse',
              './/div[@id="AR-transaction-reverse"]',
              tag_name => 'div',
              attributes => {
                  id => 'AR-transaction-reverse',
              });


sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
