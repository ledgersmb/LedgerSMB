package PageObject::App::Cash::Entry::OpenItems;

use strict;
use warnings;

use Carp;
use List::Util qw( first );
use PageObject;

use PageObject::App::Cash::Entry::OpenItemLine;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'open-items',
              './/table[@id="open-items"]',
              tag_name => 'table',
              attributes => {
                  id => 'open-items',
              });


sub _verify {
    my ($self) = @_;

    return $self;
}


sub rows {
    my ($self) = @_;
    return $self->find_all('*open-item-row');
}

sub row {
    my ($self, $invoice) = @_;

    return first { $_->get('Invoice') eq $invoice } $self->rows;
}


__PACKAGE__->meta->make_immutable;

1;
