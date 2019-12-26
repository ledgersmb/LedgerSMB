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
    # OH doesn't have a field to be queried; map to the TD's class
    'OH'            => 'onhand',
    'Price'         => 'sellprice',
    '%'             => 'discount',
    # Extended doesn't have a field to be queried; map to the TD's class
    'Extended'      => 'linetotal',
    'TaxForm'       => 'taxformcheck',
    'Delivery Date' => 'deliverydate',
    'Notes'         => 'notes',
    'Serial No.'    => 'serialnumber',
    );

sub field {
    my ($self, $label) = @_;

    my $id = $self->get_attribute('id');
    $id =~ s/^line-//;
    return $self->find(qq{.//*[\@id="$field_map{$label}_${id}"]});
}

sub field_value {
    my ($self, $label, $new_value) = @_;

    my $id = $self->get_attribute('id');
    $id =~ s/^line-//;

    if ($label eq 'OH' || $label eq 'Extended') {
        if (defined $new_value) {
            die "Invoice field OH is read-only; can't set value $new_value";
        }

        my $oh = $self->find(qq{.//td[\@class="$field_map{$label}"]});
        return $oh->get_text;
    }

    my $field = $self->find(qq{.//*[\@id="$field_map{$label}_${id}"]
           | .//input[\@type="hidden" and
                      \@name="$field_map{$label}_${id}"]});
    die "Invoice line column $field_map{$label}_${id} not found"
        if not defined $field;
    my $rv = $field->value;

    $rv = ''
        if ($field->tag_name eq 'input'
            && $field->get_attribute('type') eq 'checkbox'
            && ! $field->selected);

    if (defined $new_value) {
        $field->click;
        $field->clear;
        $field->send_keys($new_value);
    }

    return $rv;
}


sub is_empty {
    my ($self) = @_;
    return ($self->field_value('Number') eq '');
}


__PACKAGE__->meta->make_immutable;

1;
