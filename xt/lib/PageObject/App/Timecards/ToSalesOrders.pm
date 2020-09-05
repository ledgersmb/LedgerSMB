package PageObject::App::Timecards::ToSalesOrders;

use strict;
use warnings;

use Carp;
use PageObject;
use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
    'timecards-generate-salesorders',
    './/form[@id="timecard-generate-salesorders"]',
    tag_name => 'form',
    attributes => {
        id => 'timecard-generate-salesorders',
    }
);

sub _verify {
    my ($self) = @_;

    return $self;
}


__PACKAGE__->meta->make_immutable;
1;
