package PageObject::App::Cash::Reconciliation::NewReport;

use strict;
use warnings;

use Carp;
use PageObject;
use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
    'cash-reconciliation-newreport',
    './/div[@id="recon1"]',
    tag_name => 'div',
    attributes => {
        id => 'recon1',
    }
);


sub _verify {
    my ($self) = @_;

    return $self;
}


__PACKAGE__->meta->make_immutable;
1;
