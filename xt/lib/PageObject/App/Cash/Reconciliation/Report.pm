package PageObject::App::Cash::Reconciliation::Report;

use strict;
use warnings;

use Carp;
use PageObject;
use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
    'cash-reconciliation-report',
    './/div[@id="reconciliation"]',
    tag_name => 'div',
    attributes => {
        id => 'reconciliation',
    }
);


sub _verify {
    my ($self) = @_;

    return $self;
}


__PACKAGE__->meta->make_immutable;
1;
