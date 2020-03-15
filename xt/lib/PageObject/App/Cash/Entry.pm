package PageObject::App::Cash::Entry;

use strict;
use warnings;

use Carp;
use PageObject;

use PageObject::App::Cash::Entry::OpenItems;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'payments',
              './/div[@id="payments"]',
              tag_name => 'div',
              attributes => {
                  id => 'payments',
              });


sub _verify {
    my ($self) = @_;

    return $self;
}

sub open_items {
    my ($self) = @_;

    return $self->find('*open-items');
}

__PACKAGE__->meta->make_immutable;

1;
