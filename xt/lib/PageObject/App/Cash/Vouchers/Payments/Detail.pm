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

# find_payment_row($wanted)
#
# Returns the payment detail table <tr> element with fields
# matching those specified in supplied $wanted hashref.
#
# For example:
# my $element = find_payment({
#     'Source' => '1001',
#     'Name' => 'Acme Widgets',
#     'Invoice Total' => '100.00 USD'
# });

sub find_payment_row {
    my $self = shift;
    my $wanted = shift;

    ROW: foreach my $element(@{$self->payment_lines}) {
        my $row = $self->parse_payment_row($element);

        TEST: foreach my $key(keys %{$wanted}) {
            defined $row->{$key} && $row->{$key} eq $wanted->{$key}
                or next ROW;
        }

        # Stop searching as soon as we find a matching row
        return $element;
    }

    return;
}


sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
