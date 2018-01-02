package PageObject::App::Invoices::Line;

use strict;
use warnings;

use Carp;
use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';

use PageObject::App;


sub _verify {
    my ($self) = @_;

    ###TODO

    return $self;
};

my %field_map = (
    'Item'          => 'runningnumber',
    'Number'        => 'partnumber',
    'Description'   => 'description',
    'Qty'           => 'qty',
    'Unit'          => 'unit',
    'Price'         => 'sellprice',
    '%'             => 'discount',
    'Delivery Date' => 'deliverydate',
    );

sub field_value {
    my ($self, $label, $new_value) = @_;

}


__PACKAGE__->meta->make_immutable;

1;
