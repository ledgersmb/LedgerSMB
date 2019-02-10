package PageObject::App::Invoices::Lines;

use strict;
use warnings;

use Carp;
use PageObject;
use PageObject::App::Invoices::Line;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'invoice-lines',
              './/table[@id="invoice-lines"]',
              tag_name => 'table',
              attributes => {
                  id => 'invoice-lines',
              });



sub _verify {
    my ($self) = @_;

    return $self;
}

sub line {
    my ($self, $id, %opts) = @_;

    $opts{by} //= 'id';

    if ($opts{by} eq 'id') {
        $id = 'line-' . $id;
    }
    return $self->find('*invoice-line', $opts{by} => $id);
}

sub all_lines {
    my ($self) = @_;

    return $self->find_all('*invoice-line');
}


__PACKAGE__->meta->make_immutable;

1;
