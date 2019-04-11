package PageObject::App::Invoices::Header;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'invoice-header',
              './/table[@id="invoice-header"]',
              tag_name => 'table',
              attributes => {
                  id => 'invoice-header',
              });

# counterparty_type IN ('customer', 'vendor')
has counterparty_type => (is => 'ro', isa => 'Str', required => 1);


sub _verify {
    my ($self) = @_;

    return $self;
}


sub field_value {
    my ($self, $label, $new_value) = @_;

    my %field_map = (
        'Customer'       => 'customer',
        'Vendor'         => 'vendor',
        'Record in'      => ($self->counterparty_type eq 'customer'
                             ? 'AR' : 'AP'),
        'Currency'       => 'currency',
        'Description'    => 'description',
        'Shipping Point' => 'shippingpoint',
        'Ship via'       => 'shipvia',
        'Salesperson'    => 'employee',
        'Invoice Number' => 'invnumber',
        'Order Number'   => 'ordnumber',
        'PO Number'      => 'ponumber',
        'SO Number'      => 'ponumber',
        'Invoice Created'=> 'crdate',
        'Invoice Date'   => 'transdate',
        'Due Date'       => 'duedate',
        );


    return $self->find(qq{.//*[\@name="$field_map{$label}"]})->value;
}


__PACKAGE__->meta->make_immutable;

1;
