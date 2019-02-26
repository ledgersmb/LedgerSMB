package PageObject::App::Invoices::Line;

use strict;
use warnings;

use Carp;
use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';

use PageObject::App;

__PACKAGE__->self_register(
              'invoice-line',
              './/tbody[@data-dojo-type="lsmb/InvoiceLine"]',
              tag_name => 'tbody',
              attributes => {
                  'data-dojo-type' => 'lsmb/InvoiceLine',
              });

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

    my $id = $self->get_attribute('id');
    $id =~ s/^line-//;

    my $field = $self->find(
        qq{.//*[\@id="$field_map{$label}_${id}"]});
    my $rv = $field->value;

    if (defined $new_value) {
        $field->click;
        $field->clear;
        $field->send_keys($new_value);
    }

    return $rv;
}


__PACKAGE__->meta->make_immutable;

1;
