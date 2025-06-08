package PageObject::App::Cash::Entry::OpenItemLine;

use strict;
use warnings;

use Carp;
use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'open-item-row',
              './/tr[contains(@class,"open-item-row")]',
              tag_name => 'tr',
              classes => [ 'open-item-row' ],
              );


sub _verify {
    my ($self) = @_;

    return $self;
}


my %column_map = (
    'Invoice'        => 'td.invoice-number',
    'Date'           => 'td.invoice-date',
    'Total'          => 'td.invoice-total',
    'Paid'           => 'td.invoice-paid',
    'Discount'       => 'td.invoice-discount',
    'Apply Discount' => 'td.apply-discount input[type="checkbox"]',
    'Memo'           => 'td.invoice-memo input',
    'Due'            => 'td.invoice-due',
    'To pay'         => '.topay_amount input[type="text"].dijitInputInner',
    'X'              => 'lsmb-checkbox.remove input[type="checkbox"]',
    );

sub get {
    my ($self, $column) = @_;

    my $elm = $self->find($column_map{$column}, scheme => 'css');
    if ($elm) {
        return ($elm->can('value') ? $elm->value : $elm->get_text );
    }
    return;
}

my %editable_columns = (
    'Apply Discount' => 'td.apply-discount input[type="checkbox"]',
    'Memo'           => 'td.invoice-memo input',
    'To pay'         => '.topay_amount input[type="text"].dijitInputInner',
    );

sub set {
    my ($self, $column, $value) = @_;

    my $elm = $self->find($column_map{$column}, scheme => 'css');
    if ($elm and $elm->can('value')) {
        $elm->value($value);
    }
    else {
        die "Can't locate editable open item column $column";
    }
    return;
}


__PACKAGE__->meta->make_immutable;

1;
