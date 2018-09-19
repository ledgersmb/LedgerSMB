package PageObject::App::Cash::Vouchers::Payments::Detail;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
    'cash-vouchers-payments-detail',
    './/div[@id="payments-detail"]',
    tag_name => 'div',
    attributes => {
        id => 'payments-detail',
    }
);


# payment_lines()
#
# Returns an arrayref of rows in the table of payment lines

sub payment_lines {
    my $self = shift;
    my $rows = $self->find_all('//table[@id="payments-table"]/tbody/tr');

    return $rows;
}


# parse_payment_line($tr_element)
#
# Given a tr element representing a payment row from the payment
# detail table, return a hashref representing the field text.

sub parse_payment_row {
    my $self = shift;
    my $row = shift;
    my $rv = {
        'Name' => $row->find('./td[@class="entity_name"]')->get_text,
        'Invoice Total' => $row->find('./td[@class="invoice"]')->get_text,
        'Source' => $row->find('//input[@title="Source"]')->get_attribute('value'),
    };

    return $rv;
}



sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
